"""Repeated declarations inside ONE scope - the shape where a later definition silently
replaces an earlier one (ChangeReplaceCommandToFunction, 2026-08-30).

NOT reported, because both are legal and intended:
  - the same name in a DERIVED class (an override - the point of the chain)
  - the same name inside two different Object blocks
Only a repeat in the same scope of the same file is a defect.
"""
import re, io, sys, collections, os

DECL = re.compile(r'^\s*(Function|Procedure)\s+([A-Za-z_][A-Za-z0-9_.]*)(.*)$', re.I)
OBJ  = re.compile(r'^[ \t]*(Object|End_Object|Class|End_Class)(?![A-Za-z0-9_])[ \t]*([A-Za-z_][A-Za-z0-9_]*)?', re.I)
NAME = re.compile(r'[ \t]*([A-Za-z_][A-Za-z0-9_.]*)(.*)$')
BLOCK = re.compile(r'/[*].*?[*]/', re.S)
LF = chr(10)


def blank_keep_lines(m):
    """Blank a block comment but KEEP its newlines - stripping them outright renumbers every
    line after the first /* */, and the reported positions stop matching the file."""
    return LF * m.group(0).count(LF)


def scan(path):
    raw = io.open(path, encoding='latin-1', errors='replace').read()
    raw = BLOCK.sub(blank_keep_lines, raw)
    stack = []
    seen = collections.defaultdict(list)
    for n, line in enumerate(raw.split(LF), 1):
        if line.lstrip().startswith('//'):
            continue
        m = OBJ.match(line)
        if m:
            # SIBLING objects share a depth, so a depth counter alone made five different
            # objects' OnExecute look like one name declared five times. Key on the object
            # PATH - each object owns its own namespace.
            if m.group(1).lower() in ('object', 'class'):
                stack.append(m.group(2) or '?')
            elif stack:
                stack.pop()
            continue
        d = DECL.match(line)
        if not d:
            continue
        name, rest = d.group(2), d.group(3)
        # "Procedure Set <Property> ..." - Set is the KEYWORD; the property is the identity.
        # Without this, every property setter in a file collides with every other.
        if name.lower() in ('set', 'get'):
            m2 = NAME.match(rest)
            if not m2:
                continue
            name, rest = name + ' ' + m2.group(1), m2.group(2)
        seen[('/'.join(stack), name.lower())].append((n, d.group(1), rest.strip()))
    return seen


total = 0
for f in sys.argv[1:]:
    if not os.path.isfile(f):
        continue
    for (scope, name), hits in sorted(scan(f).items()):
        if len(hits) < 2:
            continue
        # A DataFlex overload - same name, different kind or different parameters - is legal and
        # usually deliberate. The defect is a repeat the compiler cannot tell apart: same kind,
        # same parameter TYPES. Parameter names differ freely and mean nothing here.
        def shape(kind, sig):
            toks = re.findall(r'[A-Za-z_][A-Za-z0-9_]*(?:\[\])?', sig)
            keep = [t for i, t in enumerate(toks) if i % 2 == 0 or t.lower() == 'returns']
            return (kind.lower(), ' '.join(x.lower() for x in keep))
        shapes = set(shape(k, sg) for _, k, sg in hits)
        collide = len(shapes) < len(hits)
        if not collide:
            continue                      # every declaration is distinguishable: an overload
        total += 1
        print('%-28s %-30s x%d   %s' % (os.path.basename(f), name, len(hits), scope or '(file scope)'))
        for ln, kind, sig in hits:
            print('      line %-6d %s %s' % (ln, kind, (sig[:76] if sig else '(no args)')))
print()
print('repeated declarations in the same scope: %d' % total)
