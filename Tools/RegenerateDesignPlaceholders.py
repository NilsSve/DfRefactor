r"""Regenerate the Studio Designer placeholders of the FlexTron HTML boxes.

WHY. The Studio's Windows Designer models a cFTWebHtmlBox from the LAST literal `Set psHtml`
in its object body; an expression it cannot evaluate leaves the box blank. So every box whose
content is computed carries a literal copy of that content in its object body (for the Designer)
and sets the real expression in its End_Construct_Object (for the runtime). The literals go
stale when a builder changes. This script refreshes them from the running program.

HOW, in three steps (the middle one runs a copy of the program - ask before running it on a
desktop someone is working at, it constructs every dialog):

  1. py Tools\RegenerateDesignPlaceholders.py probe <scratch-dir>
        writes <scratch-dir>\DFRefactorFTProbe.src: DFRefactorFT.src with the dump flag set before
        any object constructs, no OnStartup, and - instead of Start_UI - FTDesignDumpAll, then Abort.
        FTDesignDumpAll (RDCFlexTron 0.9.1) writes each box's markup once every object is built: a box
        sets its runtime markup in its own End_Construct_Object, after the class's, and the dump the
        class wrote there until 0.9.1 held the stale literal instead (found 2026-09-29).
  2. Build it with df-cli:
        df-cli build-file <scratch-dir>\DFRefactorFTProbe.src --workspace DFRefactorFlexTron.sws
               --output-dir <scratch-dir> --toolchain 26.0+windows-64 --rebuild
     Put beside the exe, or the run stops with a dialog: Config.ws with an ABSOLUTE Home=,
     Scimage64.dll, SciLexer64.dll, TabControlShadow64.dll, DUFUpdateProgram64.exe, and the COM
     manifest the real exe carries (without it the Program Setup dialog's link controls raise
     4383/4384 boxes at construct). Run the exe: it constructs every object, writes
     C:\Temp\ftdesign.txt and exits.
  3. py Tools\RegenerateDesignPlaceholders.py paste [--apply]
        pastes each dumped string as the object-body literal of its box, moving the runtime
        expression into End_Construct_Object where a box still has it in the body. The literal is
        written as a triple-quoted multi-line string - one line per block tag, icon and icon path,
        indented by nesting, broken only between two tags (a break after a space would lose the
        space: the compiler strips each line's indent and keeps the line breaks, which HTML reads
        as whitespace between blocks). A line still wider than MAXCOL is wrapped at a space that is
        not inside a quoted attribute value - between attributes, in text, or in SVG path data - and
        the continuation is indented one step - approximately: a line up to MAXCOL + SLACK is left, and
        an icon path stays on its <svg> line when the pair fits, since each line costs its indent
        against the buffer limit below (a title= tooltip too long for that is cut inside; the
        newline is a line break in a hover the Designer never shows); a space becomes a newline, which HTML and path data
        both read as the same whitespace. Path data with no space in reach (an Illustrator export,
        commas only) is wrapped after a comma, which stays: the path parser reads a line break there as
        the same separator. Keep every line short - the one line left at 2,599 characters (the Analyze
        glyph's path) was in the one bar the Designer showed blank (2026-09-29). A `/*` or `//` inside the markup is entity-encoded so no
        source line opens a comment. The Windows Designer models this form (checked 2026-09-21).
        Dry run without --apply. Skipped on purpose: the two dashboards (hand-written samples that
        show a filled-in board, which the no-workspace seed does not), the Start Center (its recent
        list is the machine's own workspace paths - the sample there carries made-up entries, edit
        it by hand), the Browse packages dialog's two boxes (SKIP_BOX: hand-written package cards -
        the runtime seed is an empty frame that Activating fills), the Libraries dialog's body (a
        sample cut from a real workspace's cards; with no workspace the list is empty), Test Compile's
        analyze summary strip (a sample of what an analyze pushes; the seed is a plain dark bar) and any string over MAXLEN - the
        compiler's 4319 limit is on the whole statement: a 12.2 KB multi-line statement (9.3 KB of
        markup) compiles, 13.3 KB does not.

The cFTWebHtmlBox class writes the dump: see gbFTDesignDump / gsFTDesignDumpFile there.
"""
import glob, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DUMP = r"C:\Temp\ftdesign.txt"
MAXLEN = 9000                   # markup chars; measured: a 9.3 KB multi-line literal compiles, 10.7 KB raises 4319
MAXCOL = 200                    # widest source line, indent included (Nils 2026-09-21) - approximately:
SLACK = 40                      # a line up to MAXCOL + SLACK is left alone rather than wrapped
SKIP_DLG = {"oDashboard_vw", "oManualDashboard_vw",   # hand-written samples of a filled-in board
            "oStartCenter_vw"}                        # its recent list is THIS machine's own paths
SKIP_BOX = {"oBpHead_hb", "oBpBody_hb",               # Browse packages: hand-written cards; the seed is an empty frame
            "oMLPage",                                # Libraries: a real workspace's cards, cut to three (2026-09-29)
            "oAnalyzeSummary_htm"}                    # Test Compile: the strip an analyze pushes; the seed is a dark bar
NOTE = ["// DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal",
        "// psHtml it can parse. It is the string the runtime seeds (dumped by the cFTWebHtmlBox design",
        "// dump, no workspace loaded); the runtime expression sits in End_Construct_Object below."]

BLOCK = "div|details|summary|ul|ol|li|table|thead|tbody|tr|td|th|section|header|footer|nav|article|form|p|h[1-6]|hr|br|link|svg|path|label|button|pre|input|select"
NEST  = "div|details|summary|ul|ol|li|table|thead|tbody|tr|td|th|section|header|footer|nav|article|form|p|h[1-6]|svg|label|button|pre"
SPLIT = re.compile(r"(?<=>)(?=<(?:%s)[\s>/])" % BLOCK)
OPEN  = re.compile(r"<(%s)[\s>]" % NEST); CLOSE = re.compile(r"</(%s)>" % NEST); SELF = re.compile(r"<(%s)\b[^>]*/>" % NEST)


def breakable(s):
    """Offsets of the spaces in s that lie outside a quoted attribute value, or inside SVG path data."""
    out = []; q = None; attr = ""
    for i, c in enumerate(s):
        if q:
            if c == q: q = None
            elif c == " " and attr == "d": out.append(i)
        elif c in "\"'":
            q = c; m = re.search(r"([\w:-]+)=$", s[:i]); attr = m.group(1) if m else ""
        elif c == " ": out.append(i)
    return out


def in_path_data(s, pos):
    """Whether offset pos of s lies inside the value of an SVG path's d="..." attribute."""
    starts = [m.end() for m in re.finditer(r'(?<![\w:-])d="', s[:pos])]
    return bool(starts) and '"' not in s[starts[-1]:pos]


def path_norm(s):
    """s with the whitespace after each comma in SVG path data dropped - the path parser reads ",", ", " and a
    comma at a line end alike, so a wrap there changes nothing."""
    return re.sub(r'(?<![\w:-])d="[^"]*"', lambda m: re.sub(r",\s+", ",", m.group(0)), s)


def wrap(line, ind):
    """line (indent included) as one or more lines no wider than MAXCOL, continuations indented a step."""
    if len(line) <= MAXCOL + SLACK: return [line]
    out = []; cur = line; cind = ind; base = len(ind)     # base: where cur's text after cind starts in line
    while len(cur) > MAXCOL + SLACK:
        keep = 0
        cuts = [i for i in breakable(cur) if i <= MAXCOL and i > len(cind)]
        if not cuts:                    # only a long quoted value is left (a title= tooltip): cut inside it
            cuts = [i for i, c in enumerate(cur) if c == " " and len(cind) < i <= MAXCOL]
        if not cuts:                    # path data with no space in reach (an Illustrator export, commas only):
            keep = 1                    # after a comma, which stays - see path_norm
            cuts = [i for i, c in enumerate(cur) if c == "," and len(cind) < i < MAXCOL
                    and in_path_data(line, base + i - len(cind))]
        if not cuts: break
        i = cuts[-1]
        out.append(cur[:i + keep].rstrip()); base += i + 1 - len(cind); cind = ind + "    "; cur = cind + cur[i + 1:]
    out.append(cur)
    return out


def multiline(html, ind):
    """The literal as source lines: `Set psHtml to \"\"\"`, one line per block, the closing quotes."""
    html = html.replace("/*", "&#47;*").replace("//", "/&#47;")
    assert '\"\"\"' not in html
    parts = [p for p in SPLIT.split(html) if p]
    body = []; depth = 0
    for p in parts:
        body.append(ind + "    " * depth + p)
        depth += len(OPEN.findall(p)) - len(SELF.findall(p)) - len(CLOSE.findall(p))
    if depth != 0:                          # nesting the tag set does not follow: flat, still one line per block
        body = [ind + "    " + p for p in parts]
    merged = []                             # an icon path stays on its <svg> line when the pair fits the cap
    for l in body:
        if merged and l.lstrip().startswith("<path ") and merged[-1].lstrip().startswith("<svg ") \
                and len(merged[-1]) + len(l.strip()) <= MAXCOL + SLACK:
            merged[-1] += l.strip()
        else:
            merged.append(l)
    body = [w for l in merged for w in wrap(l, re.match(r"\s*", l).group(0))]
    got = re.sub(r"\s*\n\s*", " ", "\n".join(l.strip() for l in body)).replace("> <", "><")
    assert path_norm(got) == path_norm(html.replace("> <", "><"))
    return [ind + 'Set psHtml to \"\"\"'] + body + [ind + '\"\"\"']


def make_probe(outdir):
    src = open(os.path.join(ROOT, "AppSrc", "DFRefactorFT.src"), "rb").read()
    nl = b"\r\n"
    i = src.index(b"Use FTThemeSeed.pkg"); i = src.index(nl, i) + 2
    src = src[:i] + b"Use cFTWebHtmlBox.pkg" + nl + b"Move True to gbFTDesignDump" + nl + \
          b'Move "' + DUMP.encode() + b'" to gsFTDesignDumpFile' + nl + src[i:]
    src = src.replace(nl + b"Send OnStartup" + nl, nl + b"// probe: no OnStartup" + nl, 1)
    src = src.replace(nl + b"Start_UI" + nl, nl + b"Send FTDesignDumpAll   // probe: every object is built - each box's final markup" + nl +
                      b"Abort   // probe: the dump is complete" + nl, 1)
    assert b"Send FTDesignDumpAll" in src, "no Start_UI line to replace"
    os.makedirs(outdir, exist_ok=True)
    p = os.path.join(outdir, "DFRefactorFTProbe.src")
    open(p, "wb").write(src)
    if os.path.exists(DUMP):
        os.remove(DUMP)
    print("probe source:", p)


def paste(apply):
    os.chdir(ROOT)
    rows = [l.rstrip("\r\n").split("|", 1) for l in open(DUMP, encoding="utf-8")]
    roots = {}
    for f in glob.glob("AppSrc/*FT.dg") + glob.glob("AppSrc/*FT.vw"):
        t = open(f, "rb").read().decode("utf-8-sig", errors="replace")
        for m in re.finditer(r"^Object\s+(\w+)\s+is\s+an?\s+\w+", t, re.M | re.I):
            roots[m.group(1).lower()] = f
    touched = {}; done = 0
    for name, html in rows:
        parts = name.split("."); dlg = parts[2]; leaf = parts[-1]
        if dlg in SKIP_DLG or leaf in SKIP_BOX:
            continue
        f = roots.get(dlg.lower())
        if not f:
            print("SKIP", name, "- no file"); continue
        if len(html) > MAXLEN:
            print("SKIP", name, "-", len(html), "chars, over the compiler's line limit"); continue
        b = touched.get(f) or open(f, "rb").read()
        nl = "\r\n" if b.count(b"\r\n") else "\n"
        lines = b.decode("utf-8").split(nl)
        oi = [i for i, l in enumerate(lines) if re.match(r"\s*Object\s+" + re.escape(leaf) + r"\s+is\s+an?\s+cFTWebHtmlBox\b", l, re.I)]
        if len(oi) != 1:
            print("SKIP", name, "- object found", len(oi)); continue
        oi = oi[0]; ind = re.match(r"\s*", lines[oi]).group(0)
        ei = next(i for i in range(oi + 1, len(lines)) if lines[i].startswith(ind + "End_Object"))

        def in_proc(i):
            j = i - 1
            while j > oi:
                if re.match(r"\s*(Procedure|Function)\b", lines[j], re.I): return True
                if re.match(r"\s*End_(Procedure|Function)\b", lines[j], re.I): return False
                j -= 1
            return False
        body = [i for i in range(oi + 1, ei) if not in_proc(i)]
        lit_i = [i for i in body if re.match(r"\s*Set\s+psHtml\s+to\s+('|\"\"\")", lines[i], re.I)]
        exp_i = [i for i in body if re.match(r"\s*Set\s+psHtml\s+to\s+\(", lines[i], re.I)]
        if lit_i:                       # refresh an existing literal in place (either form)
            si = lit_i[0]; sind = re.match(r"\s*", lines[si]).group(0)
            ei2 = si if "'" in lines[si] else next(i for i in range(si + 1, ei) if lines[i].strip() == '\"\"\"')
            try:
                new = multiline(html, sind)
            except AssertionError:      # the markup does not survive the reflow - a box whose only content is its
                print("SKIP", name, "- its markup does not reflow (runs of spaces: a literal of its own?)"); continue
            lines[si:ei2 + 1] = new
        elif len(exp_i) == 1:           # first conversion: literal in the body, expression to End_Construct_Object
            si = exp_i[0]; sind = re.match(r"\s*", lines[si]).group(0)
            expr = re.match(r"\s*Set\s+psHtml\s+to\s+(.*)$", lines[si], re.I).group(1).rstrip()
            lines[si:si + 1] = [sind + n for n in NOTE] + multiline(html, sind) + ["",
                sind + "// RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.",
                sind + "Procedure End_Construct_Object",
                sind + "    Forward Send End_Construct_Object",
                sind + "    Set psHtml to " + expr,
                sind + "End_Procedure"]
        else:
            print("SKIP", name, "- no body Set psHtml"); continue
        touched[f] = nl.join(lines).encode("utf-8"); done += 1
        print(f"ok  {f:36s} {leaf:26s} {len(html):6d} chars")
    print(f"\n{done} sites in {len(touched)} files;", "APPLIED" if apply else "dry run")
    if apply:
        for f, b in touched.items():
            open(f, "wb").write(b)


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "probe":
        make_probe(sys.argv[2])
    elif len(sys.argv) >= 2 and sys.argv[1] == "paste":
        paste("--apply" in sys.argv)
    else:
        print(__doc__)
