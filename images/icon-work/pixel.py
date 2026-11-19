import sys, os
palette = {'K': '#4f3626', 'W': '#f4f1e7', 'S': '#d9cfc0', 'P': '#e8b9a4', 'B': '#2a1a12', 'T': '#c58e5c', 'D': '#8f5f38', 'L': '#e7d4af'}
C = [
"................",
"..K..........K..",
".KPK........KPK.",
".KPWK......KWPK.",
".KWWWKKKKKKWWWK.",
".KWWWWWWWWWWWWK.",
".KWWKWWWWWWKWWK.",
".KWWWWWBBWWWWWK.",
".KSWWWWBBWWWWSK.",
"..KSWWWKKWWWSK..",
"..KSSWWWWWWSSK..",
".KLKKKKKKKKKKKK.",
".KTTTTTTTTTTTTK.",
".KTTTDDTTTTTTTK.",
".KTTTTTTTTTTTTK.",
"..KKKKKKKKKKKK..",
]
D = [
"................",
".KK..........KK.",
".KPK........KPK.",
".KPPK......KPPK.",
".KPWWKKKKKKWWPK.",
".KWWWWWWWWWWWWK.",
".KWWKWWWWWWKWWK.",
".KWWWWWBBWWWWWK.",
".KSWWWWKKWWWWSK.",
"..KSWWWWWWWWSK..",
"..KSSWWWWWWSSK..",
".KLKKKKKKKKKKKK.",
".KTTTTTTTTTTTTK.",
".KTTTDDTTTTTTTK.",
".KTTTTTTTTTTTTK.",
"..KKKKKKKKKKKK..",
]
def svg(grid, path):
    assert len(grid) == 16 and all(len(r) == 16 for r in grid), [len(r) for r in grid]
    paths = {}
    for y, row in enumerate(grid):
        x = 0
        while x < 16:
            c = row[x]
            if c == '.': x += 1; continue
            e = x
            while e < 16 and row[e] == c: e += 1
            paths.setdefault(c, []).append('M%d %dh%dv1h-%dz' % (x, y, e - x, e - x)); x = e
    o = ['<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">']
    for c in 'LKTDWSPB':
        if c in paths: o.append('<path id="pixel-%s" d="%s" fill="%s"/>' % (c, ''.join(paths[c]), palette[c]))
    o.append('</svg>'); open(path, 'w').write('\n'.join(o))
svg(C, 'pxC.svg'); svg(D, 'pxD.svg')
