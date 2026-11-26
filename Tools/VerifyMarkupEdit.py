# -*- coding: utf-8 -*-
"""Did this edit change what the app EMITS?

    py Tools\\VerifyMarkupEdit.py AppSrc\\DashboardFT.vw [more files...]

Written 2026-08-25, during the sweep that replaced hand-written HTML in DataFlex string literals
with the FTMarkupBuilders vocabulary. Every one of those edits was supposed to be invisible at
runtime, and the DataFlex compiler cannot tell you whether it was: swap a tag for the wrong builder
and you get markup that compiles perfectly and renders wrongly.

HOW IT WORKS

Each builder has a definition, so the check is to substitute the definition back and see whether
the emitted text still matches:

    CellHtml(c, x)      ->  '<td class="c">' + x + '</td>'
    HelpParagraph(x)    ->  '<p>' + x + '</p>'
    CS_WarnSign         ->  '&#9888;'

Then concatenate every string literal on the statement and compare against the same statement at
HEAD. If the two agree, the emitted string cannot have moved.

The CONSTANTS are read out of RefactorConstants.h.pkg at run time, so adding a Define needs no edit
here. The BUILDERS are three small tables below - add a line when you add one, or this will accuse
your next correct change (it did that to me three times in one afternoon).

WHAT IT DELIBERATELY CANNOT SEE

  * GROUPING PARENTHESES. It ignores them, which is the point: moving content out of a group is how
    a tag pair straddling one gets folded, and that must compare equal. The cost is that it cannot
    tell you if you removed the WRONG parenthesis - a redundant one around a call means nothing, so
    the result stays correct, but you will not learn that you got it wrong. Read those diffs by eye.
  * A STRIPPED CALL PARENTHESIS. That is compiler error 4328; the compiler catches it.
  * ESCAPING. BoldText escapes and BoldHtml does not; both look identical here. Choosing between
    them is a decision this cannot check.

WHAT IT CAUGHT

24 lines where the text between two tags was lifted out of a parenthesis group it did not own; one
where a "(" inside the LITERAL "Move (" was counted as structure; one where ") * sVer + (" balanced
by tally while closing a group it never opened. None of the three was visible to the compiler.

Exit code is 1 if any statement emits different text.
"""
import io
import os
import re
import subprocess
import sys

SQ, DQ = chr(39), chr(34)
CR, LF = chr(13), chr(10)
CRLF = CR + LF

# Builders taking (class, inner). A blank class drops the attribute, which is OpenHtml's rule.
WITH_CLASS = {'CellHtml': 'td', 'HeadCellHtml': 'th', 'RowHtml': 'tr',
              'TableHtml': 'table', 'ParaHtml': 'p'}
# Builders taking (inner) alone.
INNER_ONLY = {'TheadHtml': 'thead', 'TbodyHtml': 'tbody',
              'HelpParagraph': 'p', 'BoldHtml': 'b', 'BoldText': 'b'}
# Builders taking (class, tip, inner).
WITH_TIP = {'CellTipHtml': 'td', 'HeadCellTipHtml': 'th'}

CONSTANTS_FILE = os.path.join('AppSrc', 'RefactorConstants.h.pkg')


def markup_constants():
    """Every CS_ Define whose value is a plain string, from the source of truth.

    Originally this took only values containing markup or a character entity. That was too narrow
    the moment click ids got constants - CS_IdReadLog is "readlog", with neither - and the tool
    reported 35 correct lines as differing. Any CS_ string constant can appear inside emitted text,
    so load them all; substitution matches the NAME, so a common-looking value is harmless.
    """
    found = {}
    for line in io.open(CONSTANTS_FILE, encoding='latin-1').read().split(LF):
        # EITHER delimiter. A value containing a double quote is written in single quotes -
        # CS_LinkWinMerge is '<A href="...">WinMerge</A>' - and matching only " missed all four
        # link constants, which then read as empty text.
        m = re.match(r'Define\s+(CS_\w+)\s+for\s+"([^"]*)"', line.strip()) \
            or re.match(r"Define\s+(CS_\w+)\s+for\s+'([^']*)'", line.strip())
        if m:
            found[m.group(1)] = m.group(2)
    return found


CONSTS = markup_constants()


def split_args(text, count):
    """Top-level comma split, so a call nested inside an argument stays whole."""
    out, depth, cur = [], 0, ''
    for ch in text:
        if ch == ',' and depth == 0 and len(out) < count - 1:
            out.append(cur)
            cur = ''
            continue
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        cur += ch
    out.append(cur)
    return [a.strip() for a in out]


def quoted(text):
    return SQ + text + SQ


def expand(line):
    """Substitute every known constant and builder for its own definition."""
    for name, text in CONSTS.items():
        # A replacement FUNCTION, not a string. Once every CS_ constant is loaded, some values hold
        # a backslash (CS_DirSeparator and the path constants) and re.sub reads it as an escape:
        # "bad escape \S". A function passes the text through untouched.
        line = re.sub(r'\b' + name + r'\b', lambda m, t=text: quoted(t), line)
    changed = True
    while changed:
        changed = False
        for fn, tag in list(WITH_CLASS.items()) + list(INNER_ONLY.items()) + list(WITH_TIP.items()):
            m = re.search(r'\b%s\(' % fn, line)
            if not m:
                continue
            depth, k = 1, m.end()
            while k < len(line) and depth:
                if line[k] == '(':
                    depth += 1
                elif line[k] == ')':
                    depth -= 1
                k += 1
            args = line[m.end():k - 1]
            if fn in INNER_ONLY:
                rep = quoted('<%s>' % tag) + ' + ' + args + ' + ' + quoted('</%s>' % tag)
            elif fn in WITH_TIP:
                cls, tip, inner = split_args(args, 3)
                open_tag = '<%s class=%s%s%s title=%s%s%s>' % (
                    tag, DQ, cls.strip(DQ + SQ), DQ, DQ, tip.strip(DQ + SQ), DQ)
                rep = quoted(open_tag) + ' + ' + inner + ' + ' + quoted('</%s>' % tag)
            else:
                cls, inner = split_args(args, 2)
                bare = cls.strip().strip(DQ + SQ)
                open_tag = '<%s class=%s%s%s>' % (tag, DQ, bare, DQ) if bare else '<%s>' % tag
                rep = quoted(open_tag) + ' + ' + inner + ' + ' + quoted('</%s>' % tag)
            line = line[:m.start()] + rep + line[k:]
            changed = True
            break
    return line


def emitted(line):
    """All string-literal text on the line, once the definitions are back in."""
    line = expand(line)
    out, i, n = [], 0, len(line)
    while i < n:
        ch = line[i]
        if ch in (SQ, DQ):
            j = line.find(ch, i + 1)
            if j == -1:
                break
            out.append(line[i + 1:j])
            i = j + 1
        else:
            i += 1
    return ''.join(out)


def statements(rows):
    """Join ';'-continued lines, so a rewrite that adds continuations still lines up."""
    out, buf = [], ''
    for row in rows:
        buf = (buf + ' ' + row.strip()) if buf else row
        if row.rstrip().endswith(';'):
            buf = buf.rstrip()[:-1]
            continue
        out.append(buf)
        buf = ''
    if buf:
        out.append(buf)
    return out


def check(path):
    blob = subprocess.check_output(['git', 'show', 'HEAD:' + path.replace(os.sep, '/')])
    old = statements(blob.decode('latin-1').replace(CRLF, LF).split(LF))
    new = statements(io.open(path, encoding='latin-1', newline='').read().replace(CRLF, LF).split(LF))
    name = os.path.basename(path)
    if len(old) != len(new):
        print('%-30s statement count changed (%d -> %d) - compare this one by hand'
              % (name, len(old), len(new)))
        return 0
    changed = bad = 0
    for i, (a, b) in enumerate(zip(old, new), 1):
        if a == b:
            continue
        changed += 1
        if emitted(a) != emitted(b):
            bad += 1
            if bad <= 3:
                print('  *** %s, statement %d' % (name, i))
                print('      was %r' % emitted(a)[:120])
                print('      now %r' % emitted(b)[:120])
    print('%-30s %d changed, %d emit different text' % (name, changed, bad))
    return bad


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: py Tools' + os.sep + 'VerifyMarkupEdit.py <file> [more files...]')
        sys.exit(2)
    print('%d markup constants read from %s' % (len(CONSTS), CONSTANTS_FILE))
    print()
    total = sum(check(p) for p in sys.argv[1:])
    print()
    print('statements emitting different text: %d' % total)
    sys.exit(1 if total else 0)
