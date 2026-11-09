# The fight panels (state A) from ready blocks: writes UFO2.PNL (the static picture of the panels in the EGA page
# layout: OPG0 = parts 0, 2, OPG1 = parts 1, 3; then the atlas: pre-coloured variants of the changing slots) and
# port/pn2_tab.inc (the slots, the mouse areas). The layer (port/panel.asm) draws a slot when the game's state it
# shows changes. Sources: the game's graphics (UFO2.SNA, bank 3), a ZX screen 7 of a fight (build/data/pn_scr7.bin)
# for the panels' fixed parts. Layout: draft 7, centred (the name at the top, the bottom block in the middle of the
# bottom, the side column in the middle of the right edge).
import sys, os, re
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SNA = os.path.join(ROOT, 'build/out/UFO2.SNA'); SYM = os.path.join(ROOT, 'build/out/sym.txt')
REF = os.path.join(ROOT, 'build/data/pn_scr7.bin')
OUT_PNL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build/out/UFO2.PNL')
OUT_INC = os.path.join(ROOT, 'port/pn2_tab.inc')

def banks(path):
    d = open(path, 'rb').read(); m = d[27:27 + 49152]; n = d[27 + 49152 + 2] & 7
    b = {5: m[0:16384], 2: m[16384:32768], n: m[32768:]}; o = 27 + 49152 + 4
    for k in range(8):
        if k not in b: b[k] = d[o:o + 16384]; o += 16384
    return b
sym = {}
for l in open(SYM):
    m = re.match(r'(\S+): EQU 0x([0-9A-F]+)', l)
    if m: sym[m.group(1)] = int(m.group(2), 16)
B3 = banks(SNA)[3]
def g3(a, n): return B3[a - 0xC000:a - 0xC000 + n]

# ---- a ZX screen (pixels + attributes)
class ZX:
    def __init__(s, data): s.d = bytearray(data[:6912])
    def copy(s): return ZX(s.d)
    def adr(s, x, y): return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)
    def bit(s, x, y): return (s.d[s.adr(x, y)] >> (7 - (x & 7))) & 1
    def at(s, x, y): return s.d[0x1800 + (y >> 3) * 32 + (x >> 3)]
    def setat(s, c, r, a): s.d[0x1800 + r * 32 + c] = a
    def setbyte(s, c, y, v): s.d[s.adr(8 * c, y)] = v
    def col(s, x, y):
        a = s.at(x, y); c = (a & 7) if s.bit(x, y) else ((a >> 3) & 7)
        return br(c)
# the colours (CP/M's EGA palette: 0..7 dim, 8..15 bright): the fight's field is dim (its paper), all the rest -
# the fighters, the panels, the name - bright; black stays black (8 is the picture's transparency)
def br(c): return c | 8 if c & 7 else 0
def paper(a): return br((a >> 3) & 7)
def ink(a): return br(a & 7)
REFZ = ZX(open(REF, 'rb').read())

# ---- the EGA picture
class Img:
    def __init__(s): s.p = [[0] * 320 for _ in range(200)]
    def copy(s):
        n = Img(); n.p = [r[:] for r in s.p]; return n
    def put(s, x, y, c): s.p[y][x] = c
    def fill(s, x, y, w, h, c):
        for j in range(h):
            for i in range(w): s.p[y + j][x + i] = c
def tl(c): return (c & 7) | ((c & 8) << 3)
def tr(c): return ((c & 7) << 3) | ((c & 8) << 4)
def nk(c): return 0 if c == 8 else c     # (the slots: bright black is black - KEY is the picture's transparency)
def pairs(img, x, y, w, h):         # a block (x, w even): rows of pair bytes
    assert x % 2 == 0 and w % 2 == 0
    out = bytearray()
    for j in range(h):
        for i in range(0, w, 2): out.append(tl(nk(img.p[y + j][x + i])) | tr(nk(img.p[y + j][x + i + 1])))
    return out
def pages(img):                     # OPG0 (parts 0, 2), OPG1 (parts 1, 3)
    pg = [bytearray(16384), bytearray(16384)]
    for y in range(200):
        for p in range(160):
            part = p & 3; o = (0x2000 if part >= 2 else 0) + y * 40 + (p >> 2)
            pg[part & 1][o] = tl(img.p[y][2 * p]) | tr(img.p[y][2 * p + 1])
    return pg

# ---- the elements (as the old renderer did them: draft 7)
def blit(img, z, sx, sy, w, h, dx, dy):
    for y in range(h):
        for x in range(w): img.put(dx + x, dy + y, z.col(sx + x, sy + y))
def mono(img, z, sx, sy, w, h, dx, dy, c):
    for y in range(h):
        for x in range(w): img.put(dx + x, dy + y, c if z.bit(sx + x, sy + y) else 0)
def filla(img, z, ax, ay, w, h, dx, dy): img.fill(dx, dy, w, h, paper(z.at(ax, ay)))
def frame(img, z, ax, ay, x, y, w, h, ix, iy, iw, ih):
    c = paper(z.at(ax, ay))
    for j in range(h):
        for i in range(w):
            if not (ix <= i < ix + iw and iy <= j < iy + ih): img.put(x + i, y + j, c)

RED, BLUE, BLACK = 10, 9, 0
DX = 61                             # the bottom block: x 56..263 (its content 197 wide, centred)
SY0 = 19                            # the side column: y 20..180
NAME_X = 80
TY, WY = 161, 171
RX = 85 + DX
SX = 298                            # the side column's content: x 298..317 (its box 296..319: frame, gap)
PROW = 26                           # the game's l_PROW: the panels' cells are reported from this BY
CYAN = 13
YELLOW = 14
KEY = 8                             # the picture's "transparent" colour (the layer's keyed copy: the field shows)
# the panels' boxes: the bottom one x 61..257 (1 black pixel around its content), the side one x 296..319 (a frame,
# 1 pixel inside it to the content)
BOT = (61, 160, 197, 40)            # x, y, w, h
SIDE = (296, 18, 24, 163)
# the hide / show tabs: in the middle of their side; over its panel's middle when it is shown
# (x, y): the bottom tab shown / hidden, the side tab shown / hidden; the hidden ones' pictures at TBS2 / TSS2
TB = (147, 149); TB2 = (147, 190); TBS2 = (3, 40)
TS = (285, 86); TS2 = (310, 86); TSS2 = (38, 40)
def tab_img(kind):                  # V ^ > <: a yellow frame (as a cursor) with the chevron, a black edge round the
    w, h = (24, 8) if kind in 'V^' else (8, 24)         # yellow (seen on any field), the rest transparent
    g = [[YELLOW if i in (0, w - 1) or j in (0, h - 1) else KEY for i in range(w)] for j in range(h)]
    if kind in 'V^':
        rows = ['##.....##', '.##...##.', '..##.##..', '...###...']
        if kind == '^': rows = rows[::-1]
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch == '#': g[2 + j][7 + i] = YELLOW
    else:
        rows = ['#...', '##..', '.##.', '..##', '.##.', '##..', '#...']
        if kind == '<': rows = [r[::-1] for r in rows]
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch == '#': g[8 + j][2 + i] = YELLOW
    G = [[KEY] * (w + 2) for _ in range(h + 2)]
    for j in range(h):
        for i in range(w):
            if g[j][i] == YELLOW:
                G[j + 1][i + 1] = YELLOW
                for dj in (-1, 0, 1):
                    for di in (-1, 0, 1):
                        if G[j + 1 + dj][i + 1 + di] == KEY: G[j + 1 + dj][i + 1 + di] = BLACK
    for j in range(h + 2):                              # (black only where no yellow came later)
        for i in range(w + 2):
            if 1 <= j <= h and 1 <= i <= w and g[j - 1][i - 1] == YELLOW: G[j][i] = YELLOW
    return G
def put_tab(img, kind, x, y):
    g = tab_img(kind)
    for j in range(len(g)):
        for i in range(len(g[0])): img.put(x + i, y + j, g[j][i])

def draw_static(img, z):
    # transparent around the panels and the tabs (whole columns: the layer copies 8-pixel columns)
    img.fill(56, 160, 208, 40, KEY)
    img.fill(144, 149, 32, 10, KEY); img.fill(280, 86, 16, 26, KEY)
    img.fill(0, 40, 32, 10, KEY); img.fill(32, 40, 16, 26, KEY)
    img.fill(BOT[0], BOT[1], BOT[2], BOT[3], BLACK)
    x, y, w, h = SIDE; img.fill(x, y, w, h, BLACK)
    for i in range(w): img.put(x + i, y, CYAN); img.put(x + i, y + h - 1, CYAN)
    for j in range(h): img.put(x, y + j, CYAN); img.put(x + w - 1, y + j, CYAN)
    # the name's strip (blue) - its text is the name slot's
    img.fill(NAME_X, 0, 160, 8, ink(0x71))
    for j in range(3):
        for i in range(4): draw_button(img, z, i, j)
    img.fill(RX, TY, 20, 2, paper(z.at(105, 140)))
    for k in range(7): img.fill(RX + 21 + 13 * k, TY, 12, 9, paper(z.at(120 + 16 * k + 8, 140)))
    for k in range(4): draw_weapon(img, z, k)
    y = 1 + SY0
    for k in range(6):
        mono(img, z, 235, 24 * k + 2, 18, 11, SX + 1, y, RED); y += 20
    ys, ry, py = side_y()
    mono(img, z, 236, 146, 16, 20, SX + 2, ry, RED)
    mono(img, z, 236, 171, 16, 18, SX + 2, py, BLUE)
    put_tab(img, 'V', TB[0], TB[1]); put_tab(img, '^', TBS2[0], TBS2[1])
    put_tab(img, '>', TS[0], TS[1]); put_tab(img, '<', TSS2[0], TSS2[1])
def bpos(i, j): return 1 + 21 * i + DX, 161 + 13 * j
def draw_button(img, z, i, j):
    x, y = bpos(i, j)
    filla(img, z, 8 + 24 * i + 8, 136 + 16 * j + 4, 20, 12, x, y)
    blit(img, z, 8 + 24 * i + 3, 136 + 16 * j + 3, 18, 10, x + 1, y + 1)
def wpos(k): return RX + 28 * k, WY
def draw_weapon(img, z, k):
    x, y = wpos(k); ax, ay = 104 + 32 * k + 8, 160
    frame(img, z, ax, ay, x, y, 27, 28, 1, 1, 25, 18)
    blit(img, z, 104 + 32 * k + 4, 156, 25, 17, x + 1, y + 1)
    img.fill(x + 1, y + 1, 1, 17, 0)        # (UFO2.ICO: 24 x 17 from x + 2 - xtil.asm ico_load)
    filla(img, z, ax, ay, 25, 1, x + 1, y + 18)
    img.fill(x + 1, y + 19, 25, 8, 0)        # black: the ammo's digits are the slot's
    img.fill(x + 27, y, 1, 28, 0)
def side_y():                       # the icons every 20 lines from 20, the rank and the armour go on with that step
    ys = []; y = 1 + SY0
    for k in range(6): y += 11; ys.append(y + 1); y += 9
    ry = y; py = y + 21                 # (the rank's picture is 20 lines: a line between it and the armour)
    return ys, ry, py

# ---- PANEL.png (build/data/ico/AI - the art, as UFO2.ICO's pictures; optional): the bottom panel as shown (row A:
# BOT's 197 x 40 at 0, 0) and its 12 buttons active (row B, y 40: 20 x 12 each, x 20 k; k = 4 * row + column); the
# fight's 11 colours shared with CP/M's (build/mkico.py USE). Its pixels over the game's: the panel (but the slots
# the layer draws: the time bar's fills, the digits, the guns' pictures), the buttons both ways, the guns' cells'
# frames. PANEL_EXPORT=FILE: the game's look -> FILE (build/data/ico/PANEL.png: the template)
PANEL = os.path.join(ROOT, 'build/data/ico/AI/PANEL.png'); PW, PH = 240, 52
pan = None
if os.path.exists(PANEL) and not os.environ.get('PANEL_EXPORT') and not os.environ.get('PANEL_OFF'):
    import importlib.util
    _sp = importlib.util.spec_from_file_location('mkico', os.path.join(ROOT, 'build/mkico.py'))
    _mk = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(_mk)
    pan = _mk.read(PANEL, PW, PH)
def pan_button(img, i, j, active):
    x, y = bpos(i, j); k = 4 * j + i
    for yy in range(12):
        for xx in range(20):
            img.put(x + xx, y + yy, pan[40 + yy][20 * k + xx] if active else pan[y - BOT[1] + yy][x - BOT[0] + xx])
def pan_wframe(img, k):                 # a gun's cell: its frame (not the picture, not the ammo's digits)
    x, y = wpos(k)
    for yy in range(28):
        for xx in range(28):
            if 1 <= xx <= 25 and (1 <= yy <= 17 or 19 <= yy <= 26): continue
            img.put(x + xx, y + yy, pan[y - BOT[1] + yy][x - BOT[0] + xx])

base = Img(); draw_static(base, REFZ)
if pan:
    for yy in range(BOT[3]):
        for xx in range(BOT[2]): base.p[BOT[1] + yy][BOT[0] + xx] = pan[yy][xx]
def nokey(img):                     # (bright black inside the boxes is black, not transparent)
    for (x, y, w, h) in (BOT, SIDE, (NAME_X, 0, 160, 8)):
        for j in range(h):
            for i in range(w):
                if img.p[y + j][x + i] == KEY: img.p[y + j][x + i] = BLACK
nokey(base)

# ---- the atlas
atlas = bytearray(); alist = []
def add(block):
    global atlas
    if (len(atlas) & 0x3FFF) + len(block) > 0x4000: atlas += bytes(0x4000 - (len(atlas) & 0x3FFF))
    a = len(atlas); atlas += block; return a
def aaddr(a): return (a & 0x3FFF) | (0x4000 if a >= 0x4000 else 0)

SLOTS = []   # (t, s1, s2, s3, x, y, w, h, a, sz, c, m)
T_NAME, T_VAR, T_FILL, T_DIG, T_WPN = 1, 2, 3, 4, 5
NONE = 0xFF
# state bytes: 0 name, 1..12 the buttons' attributes, 13 CANF_B, 14 G_TIME, 15..21 LA_DIM, 22..25 guns, 26 the gun
# chosen, 27..30 ammo, 31..36 TU, EN, HEALTH, WOUND, MORAL, accuracy, 37 rank, 38 armour
SLOTS.append((T_NAME, 0, NONE, NONE, NAME_X, 0, 160, 8, 0, 0, 0, 0))
M = []; LAY_B = []
for j in range(3):
    for i in range(4):
        x, y = bpos(i, j); rx = x & ~1; rw = ((x + 20 + 1) & ~1) - rx
        grp = bytearray(); sz = rw // 2 * 12
        for attr in (0x68, 0x7A):
            z = REFZ.copy()
            for r in (17 + 2 * j, 18 + 2 * j):
                for c in range(1 + 3 * i, 4 + 3 * i): z.setat(c, r, attr)
            im = base.copy(); draw_button(im, z, i, j)
            if pan: pan_button(im, i, j, attr == 0x7A)
            grp += pairs(im, rx, y, rw, 12)
        a0 = add(grp); LAY_B.append((4 * j + i, x, y, rx, rw, a0))
        SLOTS.append((T_VAR, 1 + 4 * j + i, NONE, NONE, rx, y, rw, 12, aaddr(a0), sz, 0, 0))
        M.append((x, y, 20, 12, 1 + 3 * i + 1, 17 + 2 * j + PROW - 17))
SLOTS.append((T_FILL, 13, NONE, NONE, RX, TY, 20, 2, 0, 0, 0, 0))
SLOTS.append((T_DIG, 14, NONE, NONE, RX, TY + 3, 20, 6, 0, 0, paper(0x78), 1))
M.append((RX, TY, 20, 9, 13, PROW))
for k in range(7):
    x = RX + 21 + 13 * k                # (fills: their exact pixels)
    SLOTS.append((T_FILL, 15 + k, NONE, NONE, x, TY, 12, 9, 0, 0, 0, 1))
    M.append((x, TY, 12, 9, 15 + 2 * k, PROW))
# the weapons: the whole cell (28 x 28) per gun (0..14, 15: none) x chosen / not
wsz = 14 * 28; grp = bytearray()      # (one set for the 4 cells: the blocks go anywhere at an even x)
for g in range(16):
    bm = g3(sym['l_xWEAPO'] + 64 * g, 64) if g < 15 else g3(sym['l_xWBUTT'] + 16, 64)
    for sel in (0, 1):
        z = REFZ.copy()
        for l in range(16):
            for i in range(4): z.setbyte(13 + i, 156 + l, bm[4 * l + i])
        for r in (19, 20, 21):
            for c in range(13, 17): z.setat(c, r, 0x79 if sel else 0x68)
        im = base.copy(); draw_weapon(im, z, 0); x, y = wpos(0)
        if pan: pan_wframe(im, 0)
        if sel:                         # the chosen one: its face all bright yellow, the gun (the picture's paper) dark
            for j in range(17):         # yellow (no UFO2.ICO picture there: xtil.asm ico_load)
                for i in range(25): im.put(x + 1 + i, y + 1 + j, YELLOW if z.bit(108 + i, 156 + j) else 6)
        grp += pairs(im, x, y, 28, 28)
a0 = add(grp); A_W = a0
for k in range(4):
    x, y = wpos(k)
    SLOTS.append((T_WPN, 22 + k, 26, NONE, x, y, 28, 28, aaddr(a0), wsz, k, 0))
    SLOTS.append((T_DIG, 27 + k, 22 + k, 26, x + 1, y + 20, 25, 6, 0, 0, paper(REFZ.at(8 * (13 + 4 * k), 176)), 2))
    M.append((x, y, 27, 28, 13 + 4 * k + 1, 19 + PROW - 17))
ys, ry, py = side_y()
for k in range(6):
    SLOTS.append((T_DIG, 31 + k, NONE, NONE, SX, ys[k], 20, 6, 0, 0, paper(REFZ.at(232, 24 * k + 16)), 0))
A_S = {}
for (si, yy, h, sy, off, c, n) in ((37, ry, 20, 146, 0, RED, 8), (38, py, 18, 171, 576, BLUE, 4)):
    grp = bytearray(); sz = 8 * h
    for v in range(n):
        bm = g3(sym['l_xSIGN'] + off + 72 * v, 72)
        z = REFZ.copy()
        for l in range(24):
            for i in range(3): z.setbyte(29 + i, sy - (2 if si == 37 else 3) + l, bm[3 * l + i])
        im = Img(); mono(im, z, 236, sy, 16, h, SX + 2, yy, c)
        grp += pairs(im, SX + 2, yy, 16, h)
    a0 = add(grp); A_S[si] = a0
    SLOTS.append((T_VAR, si, NONE, NONE, SX + 2, yy, 16, h, aaddr(a0), sz, n - 1, 1))
assert len(atlas) <= 0x4800, len(atlas)     # (the second page's #0800..: UFO2.ICO - port/ico.asm)
# no two slots overlap
def rect(s): return (s[4] & ~1, s[5], (s[4] + s[6] + 1) & ~1, s[5] + s[7])
for i, a in enumerate(SLOTS):
    for b in SLOTS[i + 1:]:
        if a[0] == T_DIG or b[0] == T_DIG: continue
        ra, rb = rect(a), rect(b)
        assert not (ra[0] < rb[2] and rb[0] < ra[2] and ra[1] < rb[3] and rb[1] < ra[3]), (a, b)

# ---- the digits (the game's font: rows 1..6 of characters 0..9, paper = the digit; here 1 = the digit)
F = banks(SNA)[5][sym['l_FONT'] - 0x4000:]
digits = [bytes((~F[8 * d + 1 + r]) & 0xFF for r in range(6)) for d in range(10)]

pg = pages(base)
pnl = bytes(pg[0]) + bytes(pg[1]) + bytes(atlas) + bytes((-len(atlas)) % 128)
open(OUT_PNL, 'wb').write(pnl)
out = ['; generated by tools/mkpanel2.py: the fight panels (state A) from ready blocks; UFO2.PNL = OPG0, OPG1, atlas',
       'PN2_PNL equ %d                      ; UFO2.PNL: records' % (len(pnl) // 128),
       'PN2_NS  equ 41                     ; state bytes',
       'PN2_TBX equ %d\nPN2_TBY equ %d\nPN2_TBY2 equ %d   ; the bottom tab (26 x 10): x, y shown / hidden' % (TB[0], TB[1], TB2[1]),
       'PN2_TSX equ %d\nPN2_TSX2 equ %d\nPN2_TSY equ %d   ; the side tab (10 x 26): x shown / hidden, y' % (TS[0], TS2[0], TS[1]),
       'PN2_TBD equ %d   ; the hidden tabs\' pictures: offset of the place from the picture' % ((TB2[1] - TBS2[1]) * 40 + (TB2[0] - TBS2[0]) // 8),
       'PN2_TSD equ %d' % ((TS2[1] - TSS2[1]) * 40 + (TS2[0] - TSS2[0]) // 8),
       '; slots: type, state bytes (3), x (2), y, w, h, atlas (2: #4000 = the second page), its size (2), c, m, panel (0 name, 1 bottom, 2 side)']
out.append('PN2_AW  equ %d                    ; the atlas: the weapons\' cells (gun * 2 + chosen: 28 x 28, 14 bytes a line)' % A_W)
out.append('PN2_AR  equ %d                    ; the ranks (16 x 20, 8 bytes a line)' % A_S[37])
out.append('PN2_AA  equ %d                    ; the armours (16 x 18)' % A_S[38])
out.append('pn2_slots')
for s in SLOTS:
    if s[0] == T_DIG: s = s[:10] + (nk(s[10]),) + s[11:]
    pid = 0 if s[0] == T_NAME else (2 if s[4] >= 296 else 1)
    out.append('        db %d,%d,%d,%d : dw %d : db %d,%d,%d : dw #%04X,%d : db %d,%d' % s + ',%d' % pid)
out.append('        db #FF')
out.append('; digits 0..9: 6 rows (bit 7 = the left pixel; 1 = the digit)')
out.append('pn2_dig')
for d in digits: out.append('        db ' + ','.join('#%02X' % b for b in d))
out.append("; mouse: dx (2), dy, w, h -> the game's BX, BY")
out.append('pn_mouse')
for m in M: out.append('        dw %d : db %d,%d,%d,%d,%d' % m)
out.append('        dw #FFFF')
open(OUT_INC, 'w').write('\n'.join(out) + '\n')
# the layout for build/mkpnl.py (UFO2.PNL from a PANEL.png without the game's sources): beside UFO2.PNL
lay = ['# UFO2.PNL layout (tools/mkpanel2.py) for mkpnl.py', 'records %d' % (len(pnl) // 128),
       'hdr %d %d %d %d' % (len(pnl) // 128, A_W, A_S[37], A_S[38]), 'bot %d %d %d %d' % BOT,
       'weapons %d %d %d 32' % ((A_W,) + wpos(0))]
for b in LAY_B: lay.append('button %d %d %d %d %d %d' % b)
open(os.path.join(os.path.dirname(OUT_PNL), 'pnl_lay.txt'), 'w').write('\n'.join(lay) + '\n')
print('UFO2.PNL %d bytes (atlas %d), %d slots, %d mouse areas' % (len(pnl), len(atlas), len(SLOTS), len(M)))
if os.environ.get('PANEL_EXPORT'):          # the game's look as PANEL.png (with the palette's band on top)
    import importlib.util
    _sp = importlib.util.spec_from_file_location('mkico', os.path.join(ROOT, 'build/mkico.py'))
    _mk = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(_mk)
    nb = base.copy(); z = REFZ.copy()                   # (all the buttons as they are normally, the guns' cells too)
    for j in range(3):
        for i in range(4):
            for r in (17 + 2 * j, 18 + 2 * j):
                for c in range(1 + 3 * i, 4 + 3 * i): z.setat(c, r, 0x68)
            draw_button(nb, z, i, j)
    for r in (19, 20, 21):
        for c in range(13, 29): z.setat(c, r, 0x68)
    for k in range(4): draw_weapon(nb, z, k)
    nokey(nb)
    rows = [[nb.p[BOT[1] + y][BOT[0] + x] if x < BOT[2] else 0 for x in range(PW)] for y in range(40)]
    act = [[0] * PW for _ in range(12)]
    for j in range(3):
        for i in range(4):
            z = REFZ.copy()
            for r in (17 + 2 * j, 18 + 2 * j):
                for c in range(1 + 3 * i, 4 + 3 * i): z.setat(c, r, 0x7A)
            im = base.copy(); draw_button(im, z, i, j); x, y = bpos(i, j)
            for yy in range(12):
                for xx in range(20): act[yy][20 * (4 * j + i) + xx] = im.p[y + yy][x + xx]
    rows += act
    band = [[0] * PW for _ in range(9)]
    for n, c in enumerate(_mk.USE):
        for yy in range(8):
            for xx in range(8): band[yy][9 * n + xx] = c
    rows = [[v if v != KEY else 0 for v in r] for r in band + rows]
    _mk.png_write(os.environ['PANEL_EXPORT'], [[_mk.ALL[v] for v in r] for r in rows])
    print('PANEL.png', os.environ['PANEL_EXPORT'])
if os.environ.get('PNG'):
    from PIL import Image
    pal = [(0,0,0),(0,0,192),(192,0,0),(192,0,192),(0,192,0),(0,192,192),(192,192,0),(192,192,192),
           (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
    im = Image.new('RGB', (320, 200))
    for y in range(200):
        for x in range(320): im.putpixel((x, y), pal[base.p[y][x]])
    im.resize((960, 600), Image.NEAREST).save(os.environ['PNG'])
