# -*- coding: utf-8 -*-
r"""Is this run slow, or is it just a run?

    py Tools\RunTimeHistory.py "<workspace>\DFRefactor_Backup\DFRefactorLogFile.txt"
    py Tools\RunTimeHistory.py <log> --raw 3     # print one block verbatim, to check the labels

WHY THIS EXISTS

On 2026-07-29 I quoted a single 11:59 no-op pass to Nils as "the baseline". It was one draw from a
distribution: six runs over byte-identical inputs that day ranged 10:43 to 17:00, median 12:05,
normal spread about +/-9%, with one 1.41x excursion. A later 17:00 run therefore read as a
regression, and the hot path had not changed by one byte. The pass is disk-bound, so anything else
touching the disk - indexing, AV, backup, or an assistant running `find` over C: - moves it freely.

So: never compare a run against a number. Compare it against the spread of comparable runs. That
record already exists, unasked for, in DFRefactor_Backup\DFRefactorLogFile.txt - every run the tool
has ever done. Parse it FIRST, and never instrument the engine to answer this question.

COMPARABLE means same workspace, similar file count, same functions ticked. A pass over 1,796 files
tells you nothing about a pass over 300, so runs are also reported as seconds-per-file, which is the
only figure that survives a change of selection.

SCOPE IS THE WHOLE PROBLEM (learned 2026-08-26, on the first real log)

A campaign log is not a series of like runs. WinServ's held two full passes - 1,380 files in 27:35
and 1,626 files in 25:54 - and thirteen targeted fix-ups of 1 to 199 files, most finishing inside a
second. Fed that, the first version of this script announced the newest run was "10.54x the median",
having averaged a 27-minute pass together with a 0-second one.

So a peer is a run with a KNOWN file count within 25% of the one being judged, and when there is no
such run the answer is "no comparable run", never a ratio. A number that cannot be trusted is worse
than no number - the whole reason this file exists is one such number.

PARSING TRAPS

  * Split blocks on a run of 30+ '=' ONLY. A bare '=+' also matches the short '=====' rule under
    "Statistics:", which silently cuts every block in half and doubles the apparent run count.
  * Block timestamps are END times. A block's start is its timestamp minus its elapsed time; two
    runs that "overlap" by timestamp usually do not.

If a field comes back unparsed, the log's labels differ from what this expects - run --raw to see a
block and fix the patterns below rather than trusting a silent zero.
"""
import io
import os
import re
import sys

LF = chr(10)
BLOCK = re.compile(r'={30,}')
RE_ELAPSED = re.compile(r'Elapsed\s+Time\s*:\s*(\d+):(\d\d):(\d\d)(?:\.(\d+))?', re.I)
RE_CHANGED = re.compile(r'Total number of files changed\s*:\s*(\d+)\s+out of\s+(\d+)', re.I)
RE_STAMP = re.compile(r'(\d{4}[-/]\d\d[-/]\d\d[ T]+\d\d:\d\d(?::\d\d)?)')
RE_SWS = re.compile(r'([^\s\/:*?"<>|]+\.sws)', re.I)
# "- 912 lines Added '.pkg' extension to a Use statement (AddUseFileExtension)" -> the name in ().
RE_FN = re.compile(r'^\s*-\s.*\(([A-Za-z_]\w*)\)\s*$', re.M)


def blocks(path):
    text = io.open(path, encoding='latin-1').read()
    return [b for b in BLOCK.split(text) if b.strip()]


def parse(block):
    run = {'elapsed': None, 'files': 0, 'changed': None, 'stamp': '', 'sws': '', 'fns': 0}
    m = RE_ELAPSED.search(block)
    if m:
        run['elapsed'] = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3))
    m = RE_CHANGED.search(block)
    if m:
        run['changed'], run['files'] = int(m.group(1)), int(m.group(2))
    m = RE_STAMP.search(block)
    if m:
        run['stamp'] = m.group(1)
    m = RE_SWS.search(block)
    if m:
        run['sws'] = m.group(1)
    # THE FUNCTION SET IS THE SCOPE. File count alone is not: WinServ's Tidy Up and its
    # modernization sweep both cover ~1,600 files and share not one function, and comparing them
    # produced "0.49x" - a number about two different jobs (2026-08-26).
    run['fns'] = set(RE_FN.findall(block))
    return run


def median(xs):
    s = sorted(xs)
    n = len(s)
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2.0


def hms(sec):
    return '%d:%02d:%02d' % (sec // 3600, (sec % 3600) // 60, sec % 60)


def rows(paths):
    """Every run across every log given, oldest first.

    Several logs because a run's only true peer often lives in ANOTHER copy of the workspace: the
    answer to "did this get slower?" on 2026-08-26 was in WinServOLD's log, not the live one.
    """
    if isinstance(paths, str):
        paths = [paths]
    out = []
    for path in paths:
        for r in map(parse, blocks(path)):
            if r['elapsed'] is not None or r['files']:
                r['log'] = os.path.basename(path)
                out.append(r)
    out.sort(key=lambda r: r['stamp'])
    return out


def listing(paths):
    print('%-4s %-17s %8s %9s %10s %5s  %s' % ('#', 'ended', 'files', 'changed', 'elapsed', 'fns', 'log'))
    for i, r in enumerate(rows(paths), 1):
        print('%-4d %-17s %8s %9s %10s %5s  %s' % (
            i, r['stamp'] or '-', r['files'] or '-',
            '-' if r['changed'] is None else r['changed'], hms(r['elapsed'] or 0),
            len(r['fns']) or '-', r.get('log', '')))
    return 0


def report(path, near=0.25):
    runs = [r for r in rows(path) if r['elapsed']]
    if not runs:
        print('No run blocks parsed from %s - run with --raw 1 and check the labels.' % path)
        return 2
    newest = runs[-1]
    print('%d runs logged. Newest: %s, %s over %s files.'
          % (len(runs), newest['stamp'] or '(no timestamp)', hms(newest['elapsed']),
             newest['files'] or 'an unrecorded number of'))

    if not newest['files']:
        print()
        print('This run logged no file count - a report-only pass. Nothing to compare.')
        return 0

    # A peer must be of comparable SCOPE. Runs with no file count are report-only passes and are
    # not peers of anything; runs of a different size answer a different question.
    # A peer matches on BOTH counts: a similar file count AND essentially the same functions.
    # Either alone admits a different job wearing the right size.
    def same_job(r):
        if not r['fns'] or not newest['fns']:
            return False
        return len(r['fns'] ^ newest['fns']) <= 2
    sized = [r for r in runs[:-1]
             if r['files'] and abs(r['files'] - newest['files']) <= near * newest['files']]
    peers = [r for r in sized if same_job(r)]
    rejected = [r for r in sized if not same_job(r)]
    print()
    if not peers:
        sizes = sorted(set(r['files'] for r in runs[:-1] if r['files']))
        print('No comparable run: nothing given is within %d%% of %d files AND running the same '
              'functions.' % (int(near * 100), newest['files']))
        print('Other runs covered: %s files.' % (', '.join(str(x) for x in sizes) or '(none)'))
        print('A ratio against those would mix a full pass with a targeted fix-up. Not offered.')
        return 0
    if rejected:
        print('(%d run%s of a similar SIZE ignored - a different function set, so a different job.)'
              % (len(rejected), '' if len(rejected) == 1 else 's'))

    times = [r['elapsed'] for r in peers]
    per = [r['elapsed'] / float(r['files']) for r in peers]
    mid = median(times)
    print('%d comparable run%s (%d-%d files, same %d function(s)):'
          % (len(peers), '' if len(peers) == 1 else 's',
             min(r['files'] for r in peers), max(r['files'] for r in peers), len(newest['fns'])))
    for r in peers:
        print('    %-17s %5d files  %8s  %.3f s/file'
              % (r['stamp'] or '-', r['files'], hms(r['elapsed']),
                 r['elapsed'] / float(r['files'])))
    print('    %-17s %5d files  %8s  %.3f s/file   <- this run'
          % (newest['stamp'] or '-', newest['files'], hms(newest['elapsed']),
             newest['elapsed'] / float(newest['files'])))
    print()

    ratio = (newest['elapsed'] / float(newest['files'])) / (median(per) or 1)
    print('Per file, this run is %.2fx the median of those.' % ratio)
    if len(peers) < 3:
        print('  -> On %d comparison%s. Direction only; two runs cannot establish a spread.'
              % (len(peers), '' if len(peers) == 1 else 's'))
    if ratio < 0.85:
        print('  -> FASTER than the comparison, and outside its spread. Check the scope matches:')
        print('     a smaller function set over the same files looks exactly like this.')
    elif ratio <= 1.15:
        print('  -> Within 15% either way. The spread measured on identical inputs was +/-9%,')
        print('     so this band is deliberately wider than "normal" to avoid crying wolf.')
    elif ratio <= 1.45:
        print('  -> Slower, but a 1.41x draw was measured with a byte-identical hot path.')
        print('     Repeat the run before believing it.')
    else:
        print('  -> Beyond anything measured on identical inputs. Repeat it, then look.')
    return 0


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: py Tools' + os.sep + 'RunTimeHistory.py <log> [more logs...] [--list] [--raw N]')
        sys.exit(2)
    logs = [a for a in sys.argv[1:] if not a.startswith('--')]
    for log in logs:
        if not os.path.exists(log):
            print('No such log: %s' % log)
            sys.exit(2)
    log = logs[0]
    if '--list' in sys.argv:
        sys.exit(listing(logs))
    if '--raw' in sys.argv:
        n = int(sys.argv[sys.argv.index('--raw') + 1])
        bs = blocks(log)
        print('block %d of %d:' % (n, len(bs)))
        print(bs[n - 1][:4000])
        sys.exit(0)
    sys.exit(report(logs))
