# tilsheet.py - the numbered tile sheets (mktil.py, mkmap.py): each tile on its own, 1:1, its number above it.
# A set's sheet (XMnn_tiles.png - what the colours are edited in), 1:1: the fight's 16 colours on top (their
# numbers), then its tiles by their places (0, 1, 2.., 16 a row as in the original src/XMnn.png), each with its
# number above it; the dark grey - not drawn (the shape's). A map's sheet (mkmap.py -t): its tiles by their ids in the
# game (the map's bytes), below each where its colours are (the set, the place).
# Plain Python 3, nothing else needed.
import os, struct, zlib
GROUND, BACK, NUM, HEAD = (40, 40, 40), (60, 60, 70), (255, 255, 0), (255, 255, 255)
OUT = (96, 96, 96)      # (0.57.0) not the tile's (#606060): painted - the pixel added to its shape; a pixel of it painted
                        # so - taken off. GROUND on the tile's pixel: "none" (transparent - the tile's still)
# (0.60.4) a location's palette: the game (port/wideu.asm xp_fight) puts its colours into slots 8, 11, 4, 3, 5 - but
# not into the slot of the field's paper (the location's COLOR: XLIF.A80 C_tab, by its XM set): that one stays the ZX
# colour. Paper cyan (5): XM02, XM05, XM15, XM16 - slot 5 cyan, not pink; green (4): XM09, XM19 - slot 4 green, not
# grey-green. Their sheets and maps are drawn so; read: both colours of such a slot are taken as it (ALT).
PAPER = {2: 5, 5: 5, 15: 5, 16: 5, 9: 4, 19: 4}
ZXC = {4: (0, 192, 0), 5: (0, 192, 192)}
ALT = {(0, 192, 192): 5, (255, 96, 96): 5, (0, 192, 0): 4, (96, 192, 96): 4}
DEF = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (96, 0, 0), (96, 192, 96), (255, 96, 96), (192, 192, 0), (192, 192, 192),
       (192, 96, 0), (0, 0, 255), (255, 0, 0), (96, 192, 0), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
# (0.66.0) each location its own palette: PALETTE.txt beside the sheets (mkpal.py proposes it; edit it, then
# mkmap.py all, mktil.py): per set XM02..XM20 its 16 slots' colours - the ATM's 64, RGB as 3 digits 0..3 (0, 96, 192,
# 255). The slots the fight's panel, items, text, shots, cursor use (FIXED) are the same everywhere - only LOCAL ones
# (3, 4, 5, 8, 11) are the location's; its paper's slot (PAPER) is the ZX colour (the game's windows on the field).
# The sheets / maps are drawn and read with their set's palette. No PALETTE.txt: all as before (the fight's).
LEV = (0, 96, 192, 255)
FIXED = (0, 1, 2, 6, 7, 9, 10, 12, 13, 14, 15)
LOCAL = (3, 4, 5, 8, 11)
PALNAME = 'PALETTE.txt'
_LOC = [None, None]                             # (the folder it was read from, {set: [16 colours]})
def old_pal(pal, n):
    """the fight's palette as before 0.66.0: pal with set n's paper slot its ZX colour"""
    p = list(pal); k = PAPER.get(n)
    if k is not None and len(p) > k: p[k] = ZXC[k]
    return p
def rgb3(t): return tuple(LEV[int(ch)] for ch in t)
def code3(c): return ''.join(str(LEV.index(v)) for v in c)
def read_pals(d=None):
    """PALETTE.txt (in d; default: the sheets' folder) -> {set number: [16 colours]} ({}: none)"""
    if d is None: d = _LOC[0] or dirs(os.path.dirname(os.path.abspath(__file__)))[0]
    if _LOC[0] == d and _LOC[1] is not None: return _LOC[1]
    f = os.path.join(d, PALNAME); out = {}
    if os.path.exists(f):
        for ln, line in enumerate(open(f, encoding='utf-8'), 1):
            line = line.split('#')[0].split(';')[0].split()
            if not line: continue
            if not (line[0].upper().startswith('XM') and line[0][2:].isdigit()) or len(line) != 17 or \
               any(len(t) != 3 or any(ch not in '0123' for ch in t) for t in line[1:]):
                raise SystemExit('%s, line %d: "XMnn" and 16 colours (3 digits 0..3 each) wanted' % (f, ln))
            n = int(line[0][2:]); p = [rgb3(t) for t in line[1:]]
            fix = old_pal(DEF, n)
            for k in range(16):                 # (the fixed slots, the paper's: as they must be)
                if (k in FIXED or k == PAPER.get(n)) and p[k] != fix[k]:
                    print('%s: %s slot %d - %s kept (the fight\'s own: the same in every location)' % (PALNAME, line[0], k, code3(fix[k])))
                    p[k] = fix[k]
            if len(set(p)) != 16: print('%s: %s - two slots of the same colour' % (PALNAME, line[0]))
            out[n] = p
    _LOC[0], _LOC[1] = d, out
    return out
def use_dir(d):
    """the sets' folder (mktil.py / mkmap.py with a folder given): its PALETTE.txt"""
    _LOC[0] = d; _LOC[1] = None
def set_pal(pal, n):
    """set XMn's palette (n: its number or 'XMnn'): PALETTE.txt's, else pal with its paper slot (XM00, XM01, XMMORE:
    pal as it is)"""
    if isinstance(n, str): n = int(n[2:4]) if n[2:4].isdigit() else None
    L = read_pals()
    if n in L and len(pal) == 16: return list(L[n])
    return old_pal(pal, n)
def pix(px, x, y, pal):
    """a sheet's pixel of a tile: px - its {(x, y): colour}"""
    v = px.get((x, y)) if px else None
    return OUT if v is None else GROUND if v == 9 else pal[v]
def val(p, pal, inside):
    """a sheet's pixel -> its colour (9: none), None: not the tile's. inside: the game's own pixel (GROUND outside:
    not the tile's - the sheets before 0.57.0 had it there). pal: the set's palette - a colour of it: its slot; then
    the paper's two (ALT), the fight's default palette's (a sheet drawn before 0.66.0: the slot - the location may
    show another colour there), else the nearest"""
    p = tuple(p[:3])
    if p == OUT: return None
    if p == GROUND: return 9 if inside else None
    if p in pal: return pal.index(p)
    if p in ALT: return ALT[p]
    if p in DEF: return DEF.index(p)
    return near(p, pal)
def patched(t, col):
    """the game's tile (128 bytes: 32 lines x (mask, ink) x 2) with the shape its colours give: col's pixels drawn
    (an added one: ink, but black - paper), the others not"""
    t = bytearray(t)
    for y in range(32):
        for x in range(16):
            o = y * 4 + (x >> 3) * 2; b = 0x80 >> (x & 7); have = t[o] & b
            if (x, y) in col:
                if not have:
                    t[o] |= b
                    if col[(x, y)]: t[o + 1] |= b
                    else: t[o + 1] &= ~b
            elif have: t[o] &= ~b; t[o + 1] &= ~b
    return bytes(t)
FONT = {'0': '7 5 5 5 7', '1': '2 6 2 2 7', '2': '7 1 7 4 7', '3': '7 1 3 1 7', '4': '5 5 7 1 1', '5': '7 4 7 1 7',
        '6': '7 4 7 5 7', '7': '7 1 1 2 2', '8': '7 5 7 5 7', '9': '7 5 7 1 7', 'M': '5 7 7 5 5', 'O': '7 5 5 5 7',
        'R': '6 5 6 5 5', 'E': '7 4 6 4 7', 'X': '5 5 2 5 5', 'L': '4 4 4 4 7', 'A': '2 5 7 5 5', 'B': '6 5 6 5 6',
        'C': '7 4 4 4 7', 'D': '6 5 5 5 6', 'F': '7 4 6 4 4', 'G': '7 4 5 5 7', 'H': '5 5 7 5 5', '.': '0 0 0 0 2',
        ' ': '0 0 0 0 0', '-': '0 0 7 0 0', '+': '0 2 7 2 0', ':': '0 2 0 2 0', '#': '5 7 5 7 5', 'P': '6 5 6 4 4',
        'S': '7 4 7 1 7', 'T': '7 2 2 2 2', 'N': '6 5 5 5 5', 'I': '7 2 2 2 7', 'V': '5 5 5 5 2', 'U': '5 5 5 5 7',
        'Y': '5 5 2 2 2', 'W': '5 5 7 7 5', 'K': '5 6 4 6 5', 'J': '1 1 1 5 7', 'Q': '7 5 5 7 1', 'Z': '7 1 2 4 7',
        '(': '1 2 2 2 1', ')': '4 2 2 2 4', ',': '0 0 0 2 4'}
def base(name):
    """the game's id of the set's tile 0 (None: XMMORE)"""
    if name == 'XMMORE': return None
    n = int(name[2:])
    return 0 if n == 0 else 16 if n in (1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) else 64
def label(name, k): return str(k)
def text(img, x, y, s, col, k=3):
    for ch in s.upper():
        for j, r in enumerate(FONT.get(ch, FONT[' ']).split()):
            for i in range(3):
                if int(r) >> (2 - i) & 1:
                    for a in range(k):
                        for b in range(k):
                            if y + j * k + a < len(img) and x + i * k + b < len(img[0]): img[y + j * k + a][x + i * k + b] = col
        x += 4 * k
QUIET = [False]
def said(path):
    """before a file is written: says it in the console ("overwritten" - it was there, "written" - a new one)"""
    if QUIET[0]: return
    r = os.path.relpath(path)
    print(('overwritten: ' if os.path.exists(path) else 'written:     ') + (path if r.startswith('..') else r))
def save(path, data):
    """writes the file - only if it isn't so already (then nothing is said): only what changed is overwritten"""
    if os.path.exists(path):
        with open(path, 'rb') as f:
            if f.read() == data: return False
    said(path); open(path, 'wb').write(data); return True
def dirs(here):
    """where the files are: (the sets' sheets XMnn_tiles.png folder, [where the originals are looked for]) - the tools'
    folder: the sheets beside the scripts, the originals in src/; the repo (build/): data/til, data/til/src"""
    td = next((d for d in (here, os.path.join(here, 'data/til')) if os.path.exists(os.path.join(d, 'XM00_tiles.png'))), here)
    return td, [os.path.join(td, 'src'), os.path.join(here, 'src'), os.path.join(here, 'data/til/src'), here]
def write(path, img):
    h = len(img); w = len(img[0]); raw = bytearray()
    for r in img:
        raw.append(0)
        for v in r: raw.extend(v)
    def chunk(t, c): return struct.pack('>I', len(c)) + t + c + struct.pack('>I', zlib.crc32(t + c) & 0xFFFFFFFF)
    save(path, b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
         + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))
def sheet(path, items, pal, cols=16):
    """items: ('#', header text) - a new row with a header line; (label, {(x, y): colour index}) - a tile, 1:1 (16 x
    32; the pixels not in it: not drawn - the dark grey ground); a label's second line after a newline"""
    sub = any(it[0] != '#' and '\n' in it[0] for it in items)
    cw, ty = (30, 12) if sub else (20, 6)
    ch, hh = ty + 32 + 4, 9
    rows = []; cur = []
    for it in items:
        if it[0] == '#':
            if cur: rows.append(('t', cur)); cur = []
            rows.append(('h', it[1]))
        else:
            cur.append(it)
            if len(cur) == cols: rows.append(('t', cur)); cur = []
    if cur: rows.append(('t', cur))
    H = PH + sum(ch if k == 't' else hh for k, _ in rows); W = max(4 + cols * cw, 318)
    img = [[BACK] * W for _ in range(H)]; palband(img, pal); y = PH                  # (the palette on top, as a set's)
    for k, r in rows:
        if k == 'h': text(img, 4, y + 1, r, HEAD, 1); y += hh; continue
        for i, (lb, px) in enumerate(r):
            x0 = 4 + i * cw; a, _, b = lb.partition('\n'); text(img, x0, y, a, NUM, 1)
            if b: text(img, x0, y + 6, b, HEAD, 1)
            for yy in range(32):
                for xx in range(16): img[y + ty + yy][x0 + xx] = pix(px, xx, yy, pal)
        y += ch
    write(path, img)

# ---- the sets' sheets (1:1): written (from the colours) and read (the colours, with the shapes' XMnn.png)
COLS, CW, CH, LH, PH = 16, 20, 54, 6, 22        # 16 a row as in XMnn.png; LH: the number's line; PH: the palette's band
CH_OLD = 42                                     # (the sheets till 0.56.0's tools of 05.11: no room for "NOT USED")
# a tile of the set that is in none of the game's sets (xmgame.bin): a dummy - not used anywhere (the maps, UFO2.TIL);
# under it small "NOT / USED". (Cyrillic 5-line glyphs, ctext: rows of bits, their width = the string's length)
CYR = {'П': '111 101 101 101 101', 'У': '101 101 011 001 110', 'С': '111 100 100 100 111', 'Т': '111 010 010 010 010',
       'Ы': '1001 1001 1101 1011 1101', 'Ш': '10101 10101 10101 10101 11111', 'К': '101 101 110 101 101',
       'А': '010 101 111 101 101'}
DUMMY = (160, 160, 160)
def ctext(img, x, y, s, col):
    for ch in s:
        g = CYR[ch].split()
        for j, r in enumerate(g):
            for i, b in enumerate(r):
                if b == '1' and y + j < len(img) and x + i < len(img[0]): img[y + j][x + i] = col
        x += len(g[0]) + 1
_GAME = {}
def game_tiles(dl):
    """all the game's tiles (xmgame.bin: XM0..XM20 as the game has them) - None: no xmgame.bin"""
    for d in dl:
        f = os.path.join(d, 'xmgame.bin')
        if os.path.exists(f):
            if f not in _GAME:
                g = zlib.decompress(open(f, 'rb').read()); s = set(); p = 0
                while p < len(g): k = g[p]; s.update(g[p + 1 + j * 128:p + 129 + j * 128] for j in range(k)); p += 1 + k * 128
                _GAME[f] = s
            return _GAME[f]
    return None
def dummies(shp):
    """the original XMnn.png -> the places of its tiles the game hasn't (the dummies)"""
    d = os.path.dirname(os.path.abspath(shp)); here = os.path.dirname(os.path.abspath(__file__))
    gt = game_tiles([d, os.path.dirname(d)] + dirs(here)[1] + [os.path.join(here, '..')])
    if gt is None: return set()
    return {k for k, (t, dr) in enumerate(shapes(shp)) if any(t[j] for j in range(0, 128, 2)) and t not in gt}
SHAPE = [(48, 48, 48), (0, 0, 0), (255, 255, 255), (128, 128, 128)]   # not drawn, paper, ink, an ink bit outside the mask
def palband(img, pal):
    for i, c in enumerate(pal):
        x = 4 + i * 14
        for y in range(4, 12): img[y][x:x + 10] = [c] * 10
        text(img, x + (3 if i < 10 else 0), 14, str(i), HEAD, 1)
    for x, c, lb in ((236, OUT, 'NO DOT'), (270, GROUND, 'TRANSPARENT')):    # (0.57.0: the two greys - not the tile's,
        for y in range(4, 12): img[y][x:x + 10] = [c] * 10                    #  the tile's "none")
        text(img, x, 14, lb, HEAD, 1)
def cell(k, ch=CH): return 4 + (k % COLS) * CW, PH + (k // COLS) * ch
def write_set(path, tiles, pal, dummy=None):
    """tiles: per place {(x, y): colour index} (None: no tile there - an empty cell); dummy: the places to sign
    "NOT USED" (None: found by the original src/XMnn.png and xmgame.bin)"""
    if dummy is None:
        try: dummy = dummies(find_shapes(os.path.basename(path).split('_')[0], [os.path.dirname(os.path.abspath(path))]
                                         + dirs(os.path.dirname(os.path.abspath(__file__)))[1]))
        except SystemExit: dummy = set()
    pal = set_pal(pal, os.path.basename(path).split('_')[0])          # (its location's paper slot)
    n = len(tiles); H = PH + ((n + COLS - 1) // COLS) * CH; W = 4 + COLS * CW
    img = [[BACK] * W for _ in range(H)]; palband(img, pal)
    for k, px in enumerate(tiles):
        x0, y0 = cell(k); text(img, x0, y0, str(k), NUM, 1)
        if k in dummy: text(img, x0, y0 + LH + 33, 'NOT', DUMMY, 1); text(img, x0, y0 + LH + 39, 'USED', DUMMY, 1)
        for yy in range(32):
            for xx in range(16): img[y0 + LH + yy][x0 + xx] = pix(px, xx, yy, pal)
    write(path, img)
def png_read(path):
    d = open(path, 'rb').read(); assert d[:8] == b'\x89PNG\r\n\x1a\n', path + ': not a PNG'
    p = 8; idat = b''; pal = None
    while p < len(d):
        n = struct.unpack('>I', d[p:p + 4])[0]; t = d[p + 4:p + 8]; c = d[p + 8:p + 8 + n]; p += 12 + n
        if t == b'IHDR': w, h, depth, ct, _, _, il = struct.unpack('>IIBBBBB', c)
        elif t == b'PLTE': pal = [tuple(c[i:i + 3]) for i in range(0, len(c), 3)]
        elif t == b'IDAT': idat += c
        elif t == b'IEND': break
    assert il == 0 and (depth == 8 or (depth in (1, 2, 4) and ct in (0, 3))), path + ': 8-bit (or 1/2/4-bit palette), not interlaced'
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]; raw = zlib.decompress(idat)
    stride = w * bpp if depth == 8 else (w * depth + 7) // 8
    rows = []; prev = bytearray(stride); i = 0
    for y in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        if depth < 8:
            per = 8 // depth; m = (1 << depth) - 1
            v = [(line[k // per] >> (8 - depth * (k % per + 1))) & m for k in range(w)]
            rows.append([pal[q] for q in v] if ct == 3 else [(q * 255 // m,) * 3 for q in v])
        elif ct == 2: rows.append([tuple(line[k:k + 3]) for k in range(0, stride, 3)])
        elif ct == 6: rows.append([tuple(line[k:k + 3]) for k in range(0, stride, 4)])
        elif ct == 3: rows.append([pal[v] for v in line])
        elif ct == 0: rows.append([(v, v, v) for v in line])
        else: rows.append([(line[k],) * 3 for k in range(0, stride, 2)])
    return w, h, rows
def near(c, pal, cache={}):
    k = tuple(pal)
    if k not in cache: cache[k] = {}
    d = cache[k]
    if c not in d: d[c] = min(range(len(pal)), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c[:3], pal[i])), i))
    return d[c]
def shapes(path):
    """the shapes' XMnn.png (rows of 64 lines: 32 the colours - not used here -, 32 the shape) -> per place the game's
    128 bytes (mask, ink: 32 lines x 2 columns) and the drawn pixels {(x, y): class 1 paper / 2 ink}"""
    w, h, rows = png_read(path)
    if h % 64 and h % 64 % 9 == 0: rows = rows[h % 64:]; h -= h % 64
    out = []
    for r in range(h // 64):
        for c in range(16):
            t = bytearray(); dr = {}
            for y in range(32):
                for cc in range(2):
                    m = i = 0
                    for x in range(8):
                        s = near(rows[r * 64 + 32 + y][c * 16 + cc * 8 + x], SHAPE)
                        if s == 3: i |= 0x80 >> x
                        elif s:
                            m |= 0x80 >> x; dr[(cc * 8 + x, y)] = s
                            if s == 2: i |= 0x80 >> x
                    t += bytes([m, i])
            out.append((bytes(t), dr))
    return out
def read_set(path, shp, pal, forbid=None):
    """the set's sheet + the shapes' XMnn.png -> [(game bytes, {(x, y): colour}, place)] for every drawn tile (as
    mktil.py's read_set with pos); the colours' pixels: its shape now (patched(): the bytes with it)"""
    w, h, rows = png_read(path); out = []; sh = shapes(shp)
    pal = set_pal(pal, os.path.basename(path).split('_')[0])        # (its location's palette: 0.66.0)
    nr = (len(sh) + COLS - 1) // COLS; ch = CH_OLD if h == PH + nr * CH_OLD else CH      # (the old sheets: read so too)
    for k, (t, dr) in enumerate(sh):
        if not any(t[j] for j in range(0, 128, 2)): continue
        x0, y0 = cell(k, ch); y0 += LH
        if y0 + 32 > h or x0 + 16 > w: raise SystemExit('%s: tile %d not in it (%d x %d)' % (path, k, w, h))
        col = {}                                # (its shape as the sheet has it: OUT - not its; 0.57.0)
        for y in range(32):
            for x in range(16):
                v = val(rows[y0 + y][x0 + x], pal, (x, y) in dr)
                if v is not None: col[(x, y)] = v
        out.append((t, col, k))
    return out
def find_shapes(name, dirs):
    dirs = [x for d in dirs for x in (os.path.join(d, 'src'), d)]
    for d in dirs:
        f = os.path.join(d, name + '.png')
        if os.path.exists(f): return f
    raise SystemExit('no %s.png (the original: the game\'s tiles) in %s' % (name, ', '.join(dirs)))
