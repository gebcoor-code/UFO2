# mkpal.py - (0.66.0) the locations' palettes: what each fight location shows in which colour (PALETTE_AUDIT.txt,
# PALETTES.png) and a proposal (PALETTE.txt) - each location's free slots given colours of its own.
#   python mkpal.py        the audit with PALETTE.txt as it is (none: the fight's palette as before 0.66.0)
#   python mkpal.py new    the proposal: PALETTE.txt anew (the old one kept as PALETTE_old.txt), then the audit
# Then: python mkmap.py all (the sheets' palette bands, the maps), python mktil.py (UFO2.TIL: the palettes in it).
#
# A fight's screen has 16 colours of the ATM's 64 (each R, G, B: 0, 96, 192, 255). 11 slots are the same in every
# location (tilsheet.FIXED): the panel, the items, the ranks / armours (black, white, bright red, cyan), the shots and
# the explosions (yellow, white, red), the text, the cursor, our fighters out of focus (blues). The other 5
# (tilsheet.LOCAL: 3 maroon, 4 grey-green, 5 pink, 8 brown, 11 green) - the location's; its paper's slot (cyan 5 / green
# 4: the game's windows over the field) is the ZX colour. The sprites take their colours through the slots (their
# logical colours, mktil.py LM0): a slot the location took for a colour of its own - its sprites' pixels go to the
# nearest of the others (mktil.py loc_tables: green -> grey-green, brown -> olive...).
# The proposal: of 4, 8, 11 (3 and 5 - our fighters' maroon and pink - stay) the ones the location's tiles use less than
# 0.2% of their pixels (FREE) get a colour of the 64 not in the palette yet (at least 80 apart from each of the
# others) - the nearest in tone to the location's own colours (their shades: for the artist to paint with).
# Plain Python 3 (mkmap.py, tilsheet.py, mktil.py beside it).
import os, sys, math, itertools, collections
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import tilsheet, mkmap
FREE = 0.002
CAND = (4, 8, 11)
NAMES = {0: 'чёрный', 1: 'синий', 2: 'красный', 3: 'бордовый', 4: 'серо-зелёный', 5: 'розовый', 6: 'оливковый',
         7: 'серый', 8: 'коричневый', 9: 'ярко-синий', 10: 'ярко-красный', 11: 'зелёный', 12: 'ярко-зелёный',
         13: 'голубой', 14: 'жёлтый', 15: 'белый'}
WHO = {0: 'всё', 1: 'спрайты (сине-серый), наши не в фокусе', 2: 'спрайты (тёмно-красный), взрывы',
       6: 'спрайты (оливковый), значки', 7: 'текст, спрайты (серые)', 9: 'наши не в фокусе', 10: 'панель, спрайты, взрывы',
       12: 'текст', 13: 'панель, текст', 14: 'выстрелы, взрывы, спрайты (оранжевый)', 15: 'панель, значки, взрывы, текст',
       3: 'спрайты: наши (бордовый)', 4: 'спрайты (серо-зелёный)', 5: 'спрайты: наши (розовый)',
       8: 'спрайты (коричневый)', 11: 'спрайты (зелёный)'}
# the sprites' logical colours (XHERO_sheet.png, 0.65: % of their pixels) - mktil.py LM0's order
SPR = {0: 36.5, 10: 11.0, 6: 10.0, 2: 9.1, 7: 8.5, 9: 5.1, 3: 4.7, 14: 4.6, 12: 3.6, 11: 3.5, 1: 2.2, 4: 1.0, 5: 0.2}
LNAME = {0: 'BLACK', 1: 'WHITE', 2: 'OLIVE', 3: 'RED', 4: 'B.RED', 5: 'GREY', 6: 'GREEN', 7: 'BROWN', 9: 'SAGE',
         10: 'MAROON', 11: 'PINK', 12: 'BLUE', 14: 'ORANGE'}
LOCS = {2: 'морское дно A (X00)', 3: 'морское дно B (X00)', 14: 'морское дно C (X00)', 16: 'морское дно D (X00)',
        17: 'морское дно E (X00)', 18: 'морское дно F (X00)', 19: 'морское дно G (X00)', 20: 'морское дно H (X00)',
        6: 'корабль I (X01)', 11: 'город-порт (X02)', 4: 'другой порт (X03)', 9: 'остров (X04)', 7: 'наша база (X05)',
        15: 'колония I (X06)', 5: 'база I (X07)', 10: 'Тлет (X08)', 13: 'колония II (X09)', 12: 'база II (X10)',
        8: 'корабль II (X11)'}

def d2(a, b): return sum((x - y) ** 2 for x, y in zip(a, b))
def count():
    """per set (2..20): {slot: pixels} of its maps (all the variants; the ground not counted), XL0 / XL1's"""
    import tempfile
    cap = {}
    def pw(out, img, pal): cap['img'] = img
    old = mkmap.png_write; mkmap.png_write = pw; mkmap.BG[0] = 16; tilsheet.QUIET[0] = True
    loc = collections.defaultdict(collections.Counter)
    try:
        with tempfile.TemporaryDirectory() as td:
            jobs = []
            for nn in sorted(mkmap.DEBUG):
                vs = mkmap.DEBUG[nn][1]
                jobs += ['x%02d%s' % (nn, 'abcdefgh'[v] if len(vs) > 1 else '') for v in range(len(vs))]
            for nm in jobs + ['xl0', 'xl1']:
                r = mkmap.run([nm, os.path.join(td, 'm.png')], quiet=True)
                c = collections.Counter(p for row in cap['img'] for p in row); del c[16]
                loc[nm if nm.startswith('xl') else r[2]] += c
                print('.', end='', flush=True)
    finally:
        mkmap.png_write = old; mkmap.BG[0] = 0; tilsheet.QUIET[0] = False
    print()
    return loc
def share(c):
    t = sum(c.values()) or 1
    return {k: v / t for k, v in c.items()}
def propose(loc):
    """-> {set: (palette, the slots made its own)}"""
    ALL = list(itertools.product(tilsheet.LEV, repeat=3)); out = {}
    for n in range(2, 21):
        u = share(loc[n]); pal = tilsheet.old_pal(tilsheet.DEF, n); paper = tilsheet.PAPER.get(n)
        free = [s for s in CAND if s != paper and u.get(s, 0) < FREE]
        have = [pal[k] for k in range(16) if k not in free]
        def chroma(c): m = sum(c) / 3; return tuple(v - m for v in c)
        for s in free:
            best = None
            for c in ALL:
                if c in tilsheet.DEF or c in tilsheet.ZXC.values() or min(d2(c, e) for e in have) < 80 ** 2: continue
                sc = sum(w * (math.exp(-d2(c, pal[t]) / (2 * 100 ** 2)) + 0.8 * math.exp(-d2(chroma(c), chroma(pal[t])) / (2 * 40 ** 2)))
                         for t, w in u.items() if t not in (0, 9))
                if best is None or sc > best[0]: best = (sc, c)
            pal[s] = best[1]; have.append(best[1])
        out[n] = (pal, free)
    return out
def write_pal(path, pals, loc):
    L = ['# PALETTE.txt - палитры локаций UFO2 EGA (mkpal.py; правьте - потом mkmap.py all, mktil.py).',
         '# Строка: набор тайлов локации (XMnn) и 16 цветов слотов 0..15 - три цифры R G B, каждая 0..3 (0, 96, 192, 255:',
         '# 64 цвета ATM). Слоты 0, 1, 2, 6, 7, 9, 10, 12, 13, 14, 15 - общие для всех локаций (панель, значки, текст,',
         '# выстрелы, наши не в фокусе): их здесь не изменить. Слоты 3, 4, 5, 8, 11 - локации (слот её бумаги - 5 голубой',
         '# или 4 зелёный - цвет ZX: окна игры над полем). Спрайты, чей слот локация взяла под свой цвет, берут ближайший',
         '# из остальных. После "#" - пояснение.', '']
    for n in range(2, 21):
        p, free = pals[n]
        dp = tilsheet.old_pal(tilsheet.DEF, n)
        note = ', '.join('%d: %s -> %s' % (s, tilsheet.code3(dp[s]), tilsheet.code3(p[s])) for s in range(16) if p[s] != dp[s])
        L.append('XM%02d  %s   # %s%s' % (n, ' '.join(tilsheet.code3(c) for c in p), LOCS.get(n, ''), ('; свои: ' + note) if note else ''))
    tilsheet.save(path, ('\n'.join(L) + '\n').encode('utf-8'))
def audit(loc, path, png):
    import mktil
    pals = tilsheet.read_pals()
    T = ['Палитры локаций (mkpal.py): какие цвета на экране боя каждой локации и сколько их.', '',
         'Цифры: % точек тайлов этой локации (все варианты её карт; без пустой земли) в каждом слоте. Цвет: RGB 0..3',
         '(0, 96, 192, 255). Слоты: [о] общий (тот же во всех локациях), [л] локации, [б] её бумага (цвет ZX),',
         '[*] свой цвет локации (не как в палитре боя до 0.66.0) - тайлы, нарисованные им, тут показаны в нём.', '',
         'Общие слоты (не от локации): спрайты (бойцы, пришельцы), панель, значки предметов / званий / брони, выстрелы,',
         'взрывы, курсор, текст. Спрайты - % их точек по логическим цветам (XHERO_sheet.png):',
         '  ' + ', '.join('%s %.1f' % (LNAME[l], v) for l, v in sorted(SPR.items(), key=lambda a: -a[1])),
         'Панель боя: чёрный 51, голубой 28, белый 16, ярко-красный 5; значки (предметы, звания, броня) - чёрный и белый;',
         'выстрел - жёлтый; взрывы - белый, жёлтый, ярко-красный, красный.', '']
    rows = []
    for n in sorted(LOCS, key=lambda k: list(LOCS).index(k)):
        u = share(loc[n]); pal = tilsheet.set_pal(tilsheet.DEF, n); dp = tilsheet.old_pal(tilsheet.DEF, n)
        paper = tilsheet.PAPER.get(n); rec = mktil.loc_tables(n); lm = list(rec[:16])
        used = sum(1 for k in range(16) if u.get(k, 0) >= 0.001)
        T.append('XM%02d - %s: тайлы - %d цветов (>= 0.1%%)' % (n, LOCS[n], used))
        for k in sorted(range(16), key=lambda k: -u.get(k, 0)):
            tag = '[б]' if k == paper else '[*]' if pal[k] != dp[k] else '[л]' if k in tilsheet.LOCAL else '[о]'
            T.append('  %2d %s %s %6.2f%%  %-14s %s' % (k, tilsheet.code3(pal[k]), tag, 100 * u.get(k, 0),
                     NAMES[k] if pal[k] == tilsheet.DEF[k] else ('ZX ' + ('голубой' if k == 5 else 'зелёный')) if k == paper else 'свой',
                     WHO.get(k, '') if pal[k] == tilsheet.DEF[k] else ''))
        moved = ['%s -> %d %s' % (LNAME[l], lm[l], tilsheet.code3(pal[lm[l]])) for l in sorted(SPR) if lm[l] != mktil.LM0[l]]
        if moved: T.append('  спрайты здесь: ' + ', '.join(moved))
        T.append('')
        rows.append((n, pal, u, lm, paper, dp))
    for nm, title in (('xl0', 'куски корабля игрока (XL0, в любой локации)'), ('xl1', 'куски НЛО (XL1, в любой локации)')):
        u = share(loc[nm])
        T.append('%s: %s' % (nm.upper(), ', '.join('%d %.1f%%' % (k, 100 * v) for k, v in sorted(u.items(), key=lambda a: -a[1]) if v >= 0.001)))
    tilsheet.save(path, ('\n'.join(T) + '\n').encode('utf-8'))
    # PALETTES.png: per location its 16 slots (a band as the sheets'), under each the tiles' %, the sprites' colours
    W = 4 + 16 * 22 + 8 + 13 * 14 + 4; RH = 34; H = 38 + len(rows) * RH
    img = [[tilsheet.BACK] * W for _ in range(H)]
    tilsheet.text(img, 4, 4, 'LOCATION PALETTES: SLOTS 0..15, UNDER EACH - PERCENT OF THE TILES PIXELS; RIGHT: THE SPRITES', tilsheet.HEAD, 1)
    tilsheet.text(img, 4, 12, 'YELLOW FRAME - THE LOCATION OWN COLOUR, CYAN FRAME - ITS PAPER (ZX). SPRITES: 0 BLACK 1 WHITE 2 OLIVE', tilsheet.HEAD, 1)
    tilsheet.text(img, 4, 20, '3 RED 4 B.RED 5 GREY 6 GREEN 7 BROWN 9 SAGE 10 MAROON 11 PINK 12 BLUE 14 ORANGE - AS SHOWN THERE', tilsheet.HEAD, 1)
    for i in range(16): tilsheet.text(img, 4 + i * 22 + 4, 30, str(i), tilsheet.NUM, 1)
    sx = 4 + 16 * 22 + 8
    for j, l in enumerate(sorted(SPR)): tilsheet.text(img, sx + j * 14, 30, str(l), tilsheet.NUM, 1)
    for r, (n, pal, u, lm, paper, dp) in enumerate(rows):
        y = 38 + r * RH
        tilsheet.text(img, 4, y, 'XM%02d' % n, tilsheet.HEAD, 1)
        for i in range(16):
            x = 4 + i * 22; fr = (255, 255, 0) if pal[i] != dp[i] and i != paper else (0, 255, 255) if i == paper else None
            for yy in range(y + 7, y + 21):
                for xx in range(x, x + 18): img[yy][xx] = fr if fr and (yy in (y + 7, y + 20) or xx in (x, x + 17)) else pal[i]
            v = 100 * u.get(i, 0)
            if v >= 0.05: tilsheet.text(img, x, y + 23, ('%.0f' % v) if v >= 1 else '.%d' % round(v * 10) if v < 0.95 else '1', tilsheet.HEAD, 1)
        for j, l in enumerate(sorted(SPR)):
            x = sx + j * 14
            for yy in range(y + 7, y + 21): img[yy][x:x + 10] = [pal[lm[l]]] * 10
    tilsheet.write(png, img)

def main():
    a = [v.lower() for v in sys.argv[1:]]
    td = tilsheet.dirs(here)[0]; tilsheet.use_dir(td)
    print('the maps (all the locations\' variants): counting the colours', end='', flush=True)
    loc = count()
    if 'new' in a:
        f = os.path.join(td, tilsheet.PALNAME)
        if os.path.exists(f): tilsheet.save(os.path.join(td, 'PALETTE_old.txt'), open(f, 'rb').read())
        write_pal(f, propose(loc), loc); tilsheet.use_dir(td)
    audit(loc, os.path.join(td, 'PALETTE_AUDIT.txt'), os.path.join(td, 'PALETTES.png'))
if __name__ == '__main__': main()
