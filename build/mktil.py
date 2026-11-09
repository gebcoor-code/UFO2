# mktil.py - UFO2.TIL: the location tiles' colours for UFO-2 EGA (ATM Turbo 2+, CP/M).
#   python3 mktil.py [FOLDER [OUT]]   (no arguments: the sheets XMnn_tiles.png beside this script, UFO2.TIL there too;
#                                     overwritten without asking - said in the console)
# In: XM00.png .. XM20.png (the tile sets of the locations), XMMORE.png (the game's tiles in none of them): 256 wide,
# 16 tiles a row (16 x 32 each); each row of tiles is two bands of 32 lines: the colours, then the shape. The shape is
# the game's (it draws the tiles itself, with their masks): dark grey - not drawn, black - its paper, white - its ink,
# light grey - an ink bit outside the mask (the game has some); it tells which game tile this is - don't change it. The colours: any of the fight's 16 (the sheet's palette) except
# bright blue (9: the layer's "none") for each drawn pixel; grey elsewhere (ignored). The same tile in several places:
# the first coloured one (not plain black / white) counts.
# In (since 0.56.0): FOLDER/XMnn_tiles.png - each set's colours in a sheet (tilsheet.py: the tiles one by one, 1:1, by
# their places, the palette on top) and the originals src/XMnn.png (the game's tiles: which pixels are drawn, paper /
# ink). A set with no XMnn_tiles.png: its src/XMnn.png's colours (the original ones) - made into FOLDER/XMnn_tiles.png.
# (0.57.0) A sheet's #606060 (tilsheet.OUT): not the tile's - a pixel painted there is added to the tile, one of it
# painted so taken off: the tile's shape as the sheet has it (tilsheet.patched) - its colours by it, and its bytes'
# changes in the patch table (xexp.asm / enl.asm te_pt puts them into the tile as the game has it).
# Out: UFO2.TIL (beside UFO2.COM).
# Plain Python 3, nothing else needed.
#
# UFO2.TIL (port/xtil.asm, xexp.asm tl_exp): a tile's colours are its drawn pixels (line by line, left to right) as
# changes - two colours now (paper's 0, ink's 15 at first), a byte each: skip G (high nibble) pixels with their
# class's colour now, then the next pixel's class (paper / ink) gets colour C (low nibble); C = 9: G > 0 skip G and
# go on, G = 0 the end. The file (31232 bytes): the index page's part (TIPG #2000..#3BFF; XPG's #E000.. till 0.55.1), page 2's (#A000..#BDFF), page 4's
# (#4000..#7FFF); XPG's: N, the hashes (N x 3, ascending: a tile's id = its place), per 8 ids where the first one's
# colours are (page - 0: XPG -, its address), then (0.57.0) the shapes' patch table ("SP", P, per patched tile its
# index (2 bytes), K, K x (its byte's offset 0..127, the byte)), then the colours.
import os, sys, struct, zlib
PAL = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (96, 0, 0), (96, 192, 96), (255, 96, 96), (192, 192, 0), (192, 192, 192),
       (192, 96, 0), (0, 0, 255), (255, 0, 0), (96, 192, 0), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
NONE, LONE = (48, 48, 48), (128, 128, 128)
PAL18 = PAL + [NONE, LONE]
SETS = ['XM%02d' % n for n in range(21)] + ['XMMORE']

# ---- PNG (read: 8-bit grey / RGB / RGBA / palette, 1/2/4-bit palette or grey; write: indexed / RGB)
# ---- LZ (bits and bytes in one stream, as ZX0: a bit is taken from a byte read when the last one's 8 are used, top
# bit first; numbers n >= 1 as 1, then per further bit of n "0, the bit", then "1" (n's bits after its top one)):
# at the start / after a match: bit 0 - literals (n, then n bytes), 1 - a match at a new offset; after literals: 0 - a
# match at the last offset, 1 - at a new one. New offset: n = its high byte + 1 (256: the end), its low byte, then the
# match's length - 1; last offset: the length - 1. (offset = high * 256 + low + 1)
def gbits(n): return 2 * n.bit_length() - 1
def lz(body):
    n = len(body); INF = 1 << 40
    cand = [None] * n; heads = {}
    for i in range(n):
        lst = []
        if i + 2 <= n:
            ch = heads.setdefault(body[i:i + 2], []); best = 1
            for p in reversed(ch[-48:]):
                L = 2
                while i + L < n and L < 512 and body[p + L] == body[i + L]: L += 1
                if L > best: lst.append((i - p, best + 1, L)); best = L
                if L >= 512: break
            ch.append(i)
        cand[i] = lst
    # forward: M[i] / T[i] = (bits, last offset, from, how) - the best way to i ending with a match / literals
    GB = [0] + [gbits(k) for k in range(1, 300)]
    def gb(k): return GB[k] if k < 300 else gbits(k)
    LIT = [0] + [1 + GB[L] + 8 * L for L in range(1, 256)]
    Mc = [INF] * (n + 1); Mo = [0] * (n + 1); Mf = [0] * (n + 1); Mh = [None] * (n + 1)
    Tc = [INF] * (n + 1); To = [0] * (n + 1); Tf = [0] * (n + 1); Th = [None] * (n + 1)
    Mc[0] = 0; Mo[0] = 1
    for i in range(n):
        mc = Mc[i]; tc = Tc[i]
        if mc < INF:
            mo = Mo[i]
            for L in range(1, min(n - i, 255) + 1):
                c = mc + LIT[L]
                if c < Tc[i + L]: Tc[i + L] = c; To[i + L] = mo; Tf[i + L] = i; Th[i + L] = ('l', L)
        for fromT, sc in ((False, mc), (True, tc)):
            if sc >= INF: continue
            for off, l0, l1 in cand[i]:
                base = sc + 1 + gb(((off - 1) >> 8) + 1) + 8
                for l in (range(l0, l1 + 1) if l1 - l0 < 24 else list(range(l0, l0 + 16)) + [l1]):
                    c = base + gb(l - 1)
                    if c < Mc[i + l]: Mc[i + l] = c; Mo[i + l] = off; Mf[i + l] = i; Mh[i + l] = ('n', l, off, fromT)
        if tc < INF:
            off = To[i]
            if off <= i:
                L = 0
                while i + L < n and L < 512 and body[i + L - off] == body[i + L]: L += 1
                for l in (range(2, L + 1) if L < 26 else list(range(2, 24)) + [L]):
                    c = tc + 1 + gb(l - 1)
                    if c < Mc[i + l]: Mc[i + l] = c; Mo[i + l] = off; Mf[i + l] = i; Mh[i + l] = ('r', l)
    # back: the tokens
    end_m = Mc[n] + 1 + gbits(256); end_t = Tc[n] + 1 + gbits(256)
    toks = []; i = n; inT = end_t < end_m
    while i > 0:
        how = Th[i] if inT else Mh[i]; j = Tf[i] if inT else Mf[i]
        toks.append(how)
        inT = False if how[0] == 'l' else True if how[0] == 'r' else how[3]
        i = j
    toks.reverse()
    out = bytearray(); bitpos = [None, 0]
    def bit(b):
        if bitpos[0] is None or bitpos[1] == 8: bitpos[0] = len(out); bitpos[1] = 0; out.append(0)
        if b: out[bitpos[0]] |= 0x80 >> bitpos[1]
        bitpos[1] += 1
    def num(v):
        k = v.bit_length() - 1
        for j in range(k - 1, -1, -1): bit(0); bit(v >> j & 1)
        bit(1)
    i = 0; after_lit = False
    for tk in toks:
        if tk[0] == 'l':
            bit(0); num(tk[1]); out.extend(body[i:i + tk[1]]); i += tk[1]; after_lit = True
        elif tk[0] == 'r':
            bit(0); num(tk[1] - 1); i += tk[1]; after_lit = False
        else:
            _, l, off, _ = tk; bit(1); num(((off - 1) >> 8) + 1); out.append((off - 1) & 255); num(l - 1); i += l
            after_lit = False
    bit(1); num(256)
    return bytes(out)
def unlz(s):                                    # (as enc.asm ep_lz) -> data, bytes used
    out = bytearray(); p = [0]; bb = [0, 8]
    def byte():
        v = s[p[0]]; p[0] += 1; return v
    def bit():
        if bb[1] == 8: bb[0] = byte(); bb[1] = 0
        v = bb[0] >> (7 - bb[1]) & 1; bb[1] += 1; return v
    def num():
        v = 1
        while not bit(): v = v * 2 + bit()
        return v
    off = 1; lit = False
    while True:
        if not lit and not bit():
            k = num(); out += bytes(byte() for _ in range(k)); lit = True; continue
        if lit and not bit():
            l = num() + 1
        else:
            h = num()
            if h == 256: break
            off = (h - 1) * 256 + byte() + 1; l = num() + 1
        for _ in range(l): out.append(out[-off])
        lit = False
    return bytes(out), p[0]

# ---- a packed file ("PK", then per 4096 bytes its length - bit 15: stored as is - and its LZ; 0: the end; port/mz.asm
# unpacks it while the game starts): UFO2.SPR, .ICO, .TIL, .IMG
def pk(data):
    out = bytearray(b'PK')
    for i in range(0, len(data), 4096):
        s = data[i:i + 4096]
        try: z = lz(s); assert unlz(z)[0] == s
        except TypeError: z = s                 # (no way: over 255 literals in a row with no match - stored)
        out += struct.pack('<H', len(z)) + z if len(z) < len(s) else struct.pack('<H', 0x8000 | len(s)) + s
    out += b'\0\0'
    return bytes(out)
def unpk(p):
    assert p[:2] == b'PK', 'not a packed file'
    out = bytearray(); i = 2
    while True:
        n = p[i] | p[i + 1] << 8; i += 2
        if n == 0: return bytes(out)
        if n & 0x8000: out += p[i:i + (n & 0x7FFF)]; i += n & 0x7FFF
        else: out += unlz(p[i:i + n])[0]; i += n
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
def png_write(path, rows, pal=None):
    """rows: palette indices (pal given) or RGB tuples"""
    h = len(rows); w = len(rows[0]); raw = bytearray()
    d = 8 if pal is None or len(pal) > 16 else 4
    for r in rows:
        raw.append(0)
        if pal is None:
            for v in r: raw.extend(v)
        elif d == 8: raw.extend(r)
        else: raw.extend((r[i] << 4) | (r[i + 1] if i + 1 < w else 0) for i in range(0, w, 2))
    def chunk(t, c): return struct.pack('>I', len(c)) + t + c + struct.pack('>I', zlib.crc32(t + c) & 0xFFFFFFFF)
    hd = struct.pack('>IIBBBBB', w, h, d, 2 if pal is None else 3, 0, 0, 0)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', hd) + (chunk(b'PLTE', b''.join(bytes(c) for c in pal)) if pal else b'')
                           + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))
def near(c, pal, cache={}):
    k = (c, len(pal))
    if k not in cache: cache[k] = min(range(len(pal)), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c[:3], pal[i])), i))
    return cache[k]
SHAPE = [NONE, (0, 0, 0), (255, 255, 255), LONE]  # 0 not drawn, 1 paper, 2 ink, 3 an ink bit outside the mask

def read_set(path, pos=False):
    """-> [(game bytes (mask, ink: 32 lines x 2 columns), {(x, y): colour})] for every drawn tile"""
    w, h, rows = png_read(path)
    if h % 64 and h % 64 % 9 == 0: rows = rows[h % 64:]; h -= h % 64          # (the palette's band on top: skipped)
    if w != 256 or h % 64: raise SystemExit('%s: %d x %d - must be 256 wide, rows of 64 lines' % (path, w, h))
    out = []
    for r in range(h // 64):
        for c in range(16):
            t = bytearray(); col = {}
            for y in range(32):
                for cc in range(2):
                    m = i = 0
                    for x in range(8):
                        X = c * 16 + cc * 8 + x; s = near(rows[r * 64 + 32 + y][X], SHAPE)
                        if s == 3: i |= 0x80 >> x
                        elif s:
                            m |= 0x80 >> x
                            if s == 2: i |= 0x80 >> x
                            v = near(rows[r * 64 + y][X], PAL)
                            if v == 9: raise SystemExit('%s: tile %d, pixel %d %d: bright blue (9) - not in a tile' % (path, r * 16 + c, cc * 8 + x, y))
                            col[(cc * 8 + x, y)] = v
                    t += bytes([m, i])
            if any(t[k] for k in range(0, 128, 2)): out.append((bytes(t), col, r * 16 + c) if pos else (bytes(t), col))
    return out
def cls(t, x, y):
    m = t[y * 4 + (x >> 3) * 2]; i = t[y * 4 + (x >> 3) * 2 + 1]; b = 0x80 >> (x & 7)
    return 0 if not m & b else (2 if i & b else 1)
def plain(t, col): return all(v == (15 if cls(t, x, y) == 2 else 0) for (x, y), v in col.items())
def enc(t, px):
    cur = {1: 0, 2: 15}; out = []; gap = 0; last = 1
    for y in range(32):
        for x in range(16):
            c = cls(t, x, y)
            if not c: continue
            v = px[(x, y)]
            if v == cur[c]: gap += 1; last = c; continue
            while gap >= 15: out.append(0xF9); gap -= 15
            if v == 9:                                          # (0.56.0: colour "none" - not drawn: #G9 = skip G - 1,
                if gap == 14:                                   #  then none; G 1..14 - no byte but the end is 9)
                    # (13 skipped, the 14th as it is - its own class's colour: the last skipped one's; 0.57.2 - was
                    # this pixel's class's, wrong when the 14th was of the other class)
                    out.append(0xE9 if cur[last] == 9 else 0xD0 | cur[last]); gap = 0
                out.append((gap + 1) << 4 | 9)
            else: out.append(gap << 4 | v)
            gap = 0; cur[c] = v
    return bytes(out) + b'\x09'
def thash(t):                                   # (xexp.asm's: H rotated left 1 + the word - low byte first; S the bytes' sum)
    h = 0
    for k in range(0, 128, 2): h = (((h << 1) | (h >> 15)) + (t[k] | t[k + 1] << 8)) & 0xFFFF
    return h << 8 | (sum(t) & 255)

# (0.66.0) the locations' palettes (port/wideu.asm lp_set): "PL" at #F540 (TIPG's #3540 - at W1 #7540), then per XL map
# file #20..#53 (the game's L_MOD: XDISK2.A80 - mkmap.py GAMEFILE) its set (#FF: none), then at #F570 per set 0..20
# 80 bytes: the sprites' logical colour -> slot (xspr.asm xs_lm), ours not in focus (xs_lf), slot -> the standard
# palette's nearest (textr.asm rb_n: after the fight), the 16 slots' values (textc.asm xr_pal: the ATM's bits inverted
# - D0 B, D1 R, D4 G, D5 b, D6 r, D7 g), ZX colour -> slot (xr_zx: the game's windows). A slot the location took for
# a colour of its own: the sprites' / windows' colour of it goes to the nearest of the others.
PL_A = 0xF540
LM0 = [0, 15, 6, 2, 10, 7, 11, 8, 0, 4, 3, 5, 1, 1, 14, 7]        # (as before 0.66.0: xspr.asm)
LF0 = [0, 15, 6, 1, 9, 7, 11, 8, 0, 4, 0, 9, 1, 1, 14, 7]
ROW1 = [0, 1, 2, 3, 4, 13, 6, 7, 0, 9, 10, 5, 12, 13, 14, 15]      # (ZX colour -> slot; ROW5: the paper cyan)
ROW5 = [0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 10, 12, 13, 14, 15]
RB0 = {3: 2, 4: 4, 5: 10, 8: 6, 11: 4}                             # (after the fight: brown -> dim yellow, ...)
STD = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (192, 0, 192), (0, 192, 0), (0, 192, 192), (192, 192, 0), (192, 192, 192),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
PREF = {8: [6, 2], 4: [11], 11: [4, 6, 12], 3: [2], 5: [10]}      # (ties: the nearer in spirit)
def d2(a, b): return sum((x - y) ** 2 for x, y in zip(a, b))
def port(c):
    import tilsheet
    r, g, bb = [tilsheet.LEV.index(v) for v in c]; b = 0
    b |= (2 if r & 2 else 0) | (0x40 if r & 1 else 0) | (0x10 if g & 2 else 0) | (0x80 if g & 1 else 0) | \
         (1 if bb & 2 else 0) | (0x20 if bb & 1 else 0)
    return ~b & 255
def loc_tables(n):
    """set n's 80 bytes (pl_block)"""
    import tilsheet
    dp = tilsheet.old_pal(PAL, n); lp = tilsheet.set_pal(PAL, n); paper = tilsheet.PAPER.get(n)
    ch = [lp[k] != dp[k] for k in range(16)]
    def remap(s):
        if not ch[s]: return s
        pr = PREF.get(s, [])
        return min((k for k in range(16) if k != 9), key=lambda k: (d2(lp[k], dp[s]), ch[k], pr.index(k) if k in pr else 9, k))
    lm = list(LM0)
    if paper == 4: lm[9] = 11
    if paper == 5: lm[11] = 10
    lm = [remap(s) for s in lm]; lf = [remap(s) for s in LF0]
    zx = [remap(s) for s in (ROW5 if paper == 5 else ROW1)]
    ok = [0, 1, 2, 4, 5, 6, 7, 9, 10, 12, 13, 14, 15]
    rb = []
    for k in range(16):
        if lp[k] == STD[k] or k == paper: rb.append(k)
        elif not ch[k]: rb.append(RB0.get(k, k))
        else: rb.append(min(ok, key=lambda j: (d2(STD[j], lp[k]), j)))
    return bytes(lm + lf + rb + [port(c) for c in lp] + zx)
def pl_block():
    import mkmap
    m = bytearray([255] * 34)
    for f, key in mkmap.GAMEFILE.items():
        m[f - 20] = int(''.join(ch for ch in key if ch.isdigit()))
    b = b'PL' + bytes(m)
    b += bytes(0x30 - len(b))
    for n in range(21): b += loc_tables(n)
    assert PL_A + len(b) <= 0xFC00
    return b

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    import tilsheet
    a = [v for v in sys.argv[1:] if v.lower() != 'all']     # (0.65.6: "mktil.py all" - as mkmap.py's: the same as none)
    src = a[0] if a else tilsheet.dirs(here)[0]
    if not os.path.isdir(src): raise SystemExit('%s: no such folder (python mktil.py [SETS_DIR [OUT_DIR]])' % src)
    dst = a[1] if len(a) > 1 else src
    os.makedirs(dst, exist_ok=True)
    tilsheet.use_dir(src)                       # (its PALETTE.txt: the locations' palettes - 0.66.0)
    tiles = {}; sets = []; clash = 0
    shd = [src] + tilsheet.dirs(here)[1]        # (the originals src/XMnn.png)
    gt = tilsheet.game_tiles(shd + [os.path.join(here, '..')])   # (the game's tiles: the dummies - in none - left out)
    dum = 0
    conv = []
    for name in SETS:
        f = os.path.join(src, name + '_tiles.png')
        if os.path.exists(f):                   # the set's sheet (tilsheet.py) + its shapes
            ts = [(t, c) for t, c, k in tilsheet.read_set(f, tilsheet.find_shapes(name, shd), PAL)]
        else:                                   # (the old way: XMnn.png, colours over the shapes - made into a sheet)
            f = tilsheet.find_shapes(name, shd)
            ts = read_set(f); conv.append((name, f))
        if gt is not None: dum += sum(t not in gt for t, c in ts); ts = [(t, c) for t, c in ts if t in gt]
        sets.append((name, ts))
        for t, col in ts:
            if t not in tiles or (plain(t, tiles[t]) and not plain(t, col)): tiles[t] = col
            elif tiles[t] != col and not plain(t, col): clash += 1
    tiles.setdefault(bytes(128), {})            # (the blank tile: the game has it in sets)
    if clash: print(clash, 'tiles coloured differently in several places: the first coloured one taken')
    if dum: print(dum, 'dummies (tiles the game hasn\'t: "NOT USED" in the sheets) left out')
    hs = sorted(tiles, key=thash); H = [thash(t) for t in hs]
    assert len(set(H)) == len(H), 'hash collision'
    T2 = [tilsheet.patched(t, tiles[t]) for t in hs]   # (0.57.0: the shapes as the sheets have them)
    N = len(hs); E = [enc(T2[i], tiles[t]) for i, t in enumerate(hs)]
    # the shapes' patch table (xexp.asm te_pt): "SP", P, then per patched tile its index (2 bytes), K, K x (offset, byte)
    pt = []
    for i, t in enumerate(hs):
        d = [(o, T2[i][o]) for o in range(128) if T2[i][o] != t[o]]
        if d: pt.append(bytes([i & 255, i >> 8, len(d)]) + b''.join(bytes(x) for x in d))
    if len(pt) > 255: raise SystemExit('UFO2.TIL: %d tiles with their shapes changed - 255 at most' % len(pt))
    ptab = b'SP' + bytes([len(pt)]) + b''.join(pt)
    idx = N.to_bytes(2, 'little') + b''.join(bytes([h >> 16 & 255, h >> 8 & 255, h & 255]) for h in H)
    NG = (N + 7) // 8
    REG = [(0, 0xE000 + len(idx) + 3 * NG + len(ptab), PL_A), (2, 0x6000, 0x7E00), (4, 0x4000, 0x8000)]
    mem = {0: bytearray(0xFC00 - 0xE000), 2: bytearray(0x7E00 - 0x6000), 4: bytearray(0x4000)}
    base = {0: 0xE000, 2: 0x6000, 4: 0x4000}
    ri = 0; ad = REG[0][1]; cp = b''
    for g in range(NG):
        blob = b''.join(E[g * 8:g * 8 + 8])
        while ad + len(blob) > REG[ri][2]:
            ri += 1
            if ri >= len(REG): raise SystemExit('UFO2.TIL: no room - too many colour changes')
            ad = REG[ri][1]
        pg = REG[ri][0]; mem[pg][ad - base[pg]:ad - base[pg] + len(blob)] = blob
        cp += bytes([pg, ad & 255, ad >> 8]); ad += len(blob)
    mem[0][:len(idx) + len(cp) + len(ptab)] = idx + cp + ptab
    pb = pl_block(); mem[0][PL_A - 0xE000:PL_A - 0xE000 + len(pb)] = pb
    data = bytes(mem[0]) + bytes(mem[2]) + bytes(mem[4])
    free = REG[ri][2] - ad + sum(r[2] - r[1] for r in REG[ri + 1:])
    tilsheet.save(os.path.join(dst, 'UFO2.TIL'), pk(data))           # (packed: port/mz.asm)
    print('UFO2.TIL: %d tiles, %d bytes of colours, %d free' % (N, sum(len(e) for e in E), free)
          + (', %d tiles with their shapes changed (%d bytes)' % (len(pt), len(ptab)) if pt else ''))
    for name, f in conv:                        # XMnn.png -> XMnn_tiles.png (the colours as they are in it)
        sh = tilsheet.shapes(f); byp = {k: c for t, c, k in read_set(f, True)}
        tilsheet.write_set(os.path.join(dst, name + '_tiles.png'), [byp.get(k) for k in range(len(sh))], PAL)
        print('  (%s_tiles.png: from the original %s)' % (name, f))
FONT = {'0': '7 5 5 5 7', '1': '2 6 2 2 7', '2': '7 1 7 4 7', '3': '7 1 3 1 7', '4': '5 5 7 1 1', '5': '7 4 7 1 7',
        '6': '7 4 7 5 7', '7': '7 1 1 2 2', '8': '7 5 7 5 7', '9': '7 5 7 1 7', 'M': '5 7 7 5 5', 'O': '7 5 5 5 7',
        'R': '6 5 6 5 5', 'E': '7 4 6 4 7'}
def text(rows, x, y, s, k=2):
    for ch in s:
        for j, r in enumerate(FONT[ch].split()):
            for i in range(3):
                if int(r) >> (2 - i) & 1:
                    for a in range(k):
                        rows[y + j * k + a][x + i * k:x + i * k + k] = [(255, 255, 255)] * k
        x += 4 * k
if __name__ == '__main__': main()
