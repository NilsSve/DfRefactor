"""Verify every Struct a conversion emitted against the harvested SDK catalogue.

Types come from the SDK, names from the author's legacy block - so the check is
positional on TYPE. Two catalogue flavours:
  DF|   a ready-made DataFlex declaration  -> compare types directly
  C     a C prototype                      -> map to DataFlex at EXACT width first
"""
import io, json, re, sys, os

CAT = r'C:\Projects\DF20\DfRefactor\Data\WinAPIStructCatalog.json'
rows = json.load(io.open(CAT, encoding='utf-8'))['asRows']
cat = {}
for r in rows:
    cat[r.split('|')[0].strip().lower()] = r

# the same exact-width rule the converter now uses for struct members
EXACT = {
    'word': 'ushort', 'ushort': 'ushort', 'unsigned short': 'ushort', 'atom': 'ushort',
    'langid': 'ushort', 'wchar': 'ushort', 'wchar_t': 'ushort', 'uint16': 'ushort',
    'short': 'short', 'int16': 'short', '__int16': 'short', 'short int': 'short',
    'byte': 'uchar', 'uchar': 'uchar', 'unsigned char': 'uchar', 'uint8': 'uchar',
    'char': 'char', 'int8': 'char', '__int8': 'char', 'signed char': 'char',
}
PTRISH = ('handle', 'pointer', 'longptr', 'ulongptr', 'address')

def sdk_key(n):
    n = n.lower()
    stems = {n}
    for p in ('vt', 'v', 't', '_'):
        if n.startswith(p) and len(n) > len(p):
            stems.add(n[len(p):])
    for s in list(stems):
        for cand in (s, s + 'a', s + 'w', 't' + s):
            if cand in cat:
                return cand
    return None

def sdk_member_types(key):
    """(types, flavour) - DataFlex types in order, fillers included for DF| rows."""
    payload = cat[key].split('|', 1)[1]
    if payload.startswith('DF|'):
        body = payload[3:]
        out = []
        for ln in body.replace('\r', '').split('\n'):
            s = ln.strip()
            if not s or s.lower().startswith('struct ') or s.lower() == 'end_struct' or s.startswith('//'):
                continue
            out.append(s.split()[0].lower())
        return out, 'DF'
    # C prototype:  { WORD a; WORD b; }
    inner = payload[payload.find('{') + 1: payload.rfind('}')]
    out = []
    for m in inner.split(';'):
        m = m.strip()
        if not m:
            continue
        m = re.sub(r'\[.*?\]', '', m).strip()
        ptr = m.count('*')
        m = m.replace('*', ' ').strip()
        bits = m.split()
        if len(bits) < 2:
            continue
        ctype = ' '.join(bits[:-1]).lower()
        out.append('pointer' if ptr else EXACT.get(ctype, '?' + ctype))
    return out, 'C'

def check(path):
    txt = io.open(path, encoding='latin-1', errors='replace').read()
    blocks = re.findall(r'^Struct\s+(\w+)\s*\n(.*?)^End_Struct', txt, re.S | re.M)
    if not blocks:
        return
    print('=== %s' % os.path.basename(path))
    for name, body in blocks:
        key = sdk_key(name)
        if not key:
            print('  %-24s  no catalogue entry - SKIPPED' % name)
            continue
        got = []
        for ln in body.split('\n'):
            s = ln.strip()
            if not s or s.startswith('//'):
                continue
            got.append(s.split()[0].lower())
        want, flavour = sdk_member_types(key)
        bad = []
        if len(got) != len(want):
            bad.append('member COUNT %d vs SDK %d' % (len(got), len(want)))
        else:
            for i, (g, w) in enumerate(zip(got, want)):
                if w.startswith('?'):
                    bad.append('member %d: SDK type %s unmapped by this checker' % (i + 1, w[1:]))
                elif g != w and not (g in PTRISH and w in PTRISH):
                    bad.append('member %d: emitted %s, SDK says %s' % (i + 1, g, w))
        if bad:
            print('  %-24s [%s]  MISMATCH' % (name, flavour))
            for b in bad:
                print('        %s' % b)
        else:
            print('  %-24s [%s]  ok  (%d members)' % (name, flavour, len(got)))

for root, dirs, files in os.walk(sys.argv[1] if len(sys.argv) > 1 else 'E:/LegacyApp4'):
    if '\\dfrefactor_backup' in root.lower():
        continue
    for f in sorted(files):
        if f.lower().endswith(('.pkg', '.inc', '.src')):
            check(os.path.join(root, f))
