"""Per-level balance table from bot traces (loop 1).

Generate traces per seed into one directory, then summarize:
  MC_GOD=1 ./trace.sh "" out/god-42.txt 36000 42
  MC_NOCONT=1 ./trace.sh "" out/nocont-42.txt 36000 42
  python3 balance.py out 42 [more seeds...]

god-<seed>: seconds per level/phase, would-hits per minute (bullets a
non-dodging player would have taken), enemy bullets on screen, rank,
multiplier, and 1UP/bomb pickups. nocont-<seed>: where each one-credit game
ended and how long it lasted.
"""
import sys, collections

def parse(path):
    for line in open(path):
        t = line.split()
        if len(t) < 3 or not t[0].isdigit():
            continue
        d = {'f': int(t[0]), 'st': t[1]}
        for tok in t[2:]:
            if '=' in tok:
                k, v = tok.split('=', 1)
                d[k] = v
            elif tok.startswith('x'):
                d['mult'] = int(tok[1:].split('/')[0])
        if 'ph' not in d:
            continue
        d['phase'] = d['ph'].split('/')[0]
        d['eb'] = int(d['eb'].split(':')[0])
        for k in ('lvl', 'warp', 'loop', 'rank', 'hp', 'b', 'wh', 'used', 'kills'):
            d[k] = int(float(d[k])) if d[k] not in ('nil',) else 0
        yield d

def god(path):
    seg = collections.OrderedDict()
    prev = None
    gains = collections.Counter()
    for d in parse(path):
        if d['st'] != 'game' or d['warp'] > 0 or d['loop'] > 1:
            prev = d if d['st'] == 'game' else prev
            continue
        key = (d['lvl'], d['phase'])
        s = seg.setdefault(key, {'n': 0, 'wh0': d['wh'], 'wh1': d['wh'], 'eb': 0, 'ebmax': 0, 'rank': 0, 'mult': 0})
        s['n'] += 1; s['wh1'] = d['wh']; s['eb'] += d['eb']; s['ebmax'] = max(s['ebmax'], d['eb'])
        s['rank'] = d['rank']; s['mult'] = d['mult']
        if prev and prev['st'] == 'game':
            if d['hp'] > prev['hp']: gains['1up', d['lvl']] += 1
            if d['b'] > prev['b']: gains['bomb', d['lvl']] += 1
        prev = d
    return seg, gains

def nocont(path):
    games, cur, prev = [], None, None
    for d in parse(path):
        if d['st'] == 'game' and (prev is None or prev['st'] != 'game'):
            cur = {'start': d['f'], 'maxlvl': 1, 'phase': '', 'hits': 0, 'end': None}
            games.append(cur)
        if cur and d['st'] == 'game' and cur['end'] is None:
            cur['maxlvl'] = max(cur['maxlvl'], d['lvl'])
            if prev and prev['st'] == 'game' and d['hp'] < prev['hp']: cur['hits'] += 1
            if d['go'].startswith('true'):
                cur['end'] = d['f']; cur['phase'] = d['phase']
        prev = d
    return [g for g in games if g['end']]

for seed in sys.argv[2:]:
    p = sys.argv[1]
    seg, gains = god(f'{p}/god-{seed}.txt')
    print(f'== god seed {seed} (loop 1)')
    print(f'{"lvl/phase":24} {"secs":>6} {"wouldhit/min":>12} {"avg eb":>7} {"max eb":>7} {"rank":>5} {"mult":>5}')
    for (lvl, ph), s in seg.items():
        secs = s['n'] / 60
        print(f'{lvl}/{ph:22} {secs:6.1f} {(s["wh1"]-s["wh0"])/max(secs,1e-9)*60:12.1f} {s["eb"]/s["n"]:7.1f} {s["ebmax"]:7d} {s["rank"]:5d} {s["mult"]:5d}')
    print('pickups:', dict(gains))
    gs = nocont(f'{p}/nocont-{seed}.txt')
    print(f'== nocont seed {seed}: ' + '; '.join(f'L{g["maxlvl"]} {g["phase"]} after {(g["end"]-g["start"])/60:.0f}s' for g in gs))
