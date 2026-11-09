# mkico.py - UFO2.ICO: the items' and the signs' pictures in EGA for UFO-2 EGA (ATM Turbo 2+, CP/M).
#   python3 mkico.py [FOLDER [OUT]]   (no arguments: the pictures beside this script, the results there too)
# In: ITEM00.png .. ITEM14.png - the items (harpoon .. supervisor) in their buttons, ITEM15.png - an empty button
# (32 x 24: the item's 32 x 16 at lines 4..19), RANK0.png .. RANK7.png - the ranks, ARMOR0.png .. ARMOR3.png - the
# armours (24 x 24), PARAMS.png - the fighter's 6 parameters' signs (time units .. accuracy, 24 x 96), PARAMS2.png - the encyclopedia's weapon signs past them (damage, fire rate, ammo, price: 24 x 64). Colours: the 11 the fight's palette shares with CP/M's (the PNGs' palette: black, blue, red,
# yellow, grey, bright blue, bright red, green, cyan, bright yellow, white) - shown on the fighter's screen in and
# out of the fights; any PNG works: each pixel taken as the nearest of them.
# WORLDMAP.png - the geoscape's world map (192 x 120, CP/M's 16 colours: shown out of the fights only); where the
# game draws its marks (ships, bases, UFOs: pixels not its own map's) they are maroon over it.
# BUTTONS.png - the geoscape's 10 menu buttons and the encyclopedia's 4 (448 x 64: 32 x 32 each, MENU .. INFO, up,
# picture, text, down - the encyclopedia's MENU is the first one; row 1 as shown, row 2 the
# active one's look - the same pixels, each colour of row 1 always the same one in row 2; CP/M's 16 colours).
# PANEL.png - the fight's bottom panel and its buttons (240 x 52: the panel 197 x 40, then the 12 buttons active,
# 20 x 12 each; the fight's 11 colours as the items'): not in UFO2.ICO - the game's build puts it into UFO2.PNL
# (tools/mkpanel2.py); here only checked and shown on the sheet.
# Out: UFO2.ICO (beside UFO2.COM) and ico_sheet.png - all of them as in UFO2.ICO (4 x), to check.
# Where seen: the fighter's screen (all), the fight's panel: an item's 24 x 17 from x 4, line 4; a rank's 16 x 20 from x 4, line 2; an
# armour's 16 x 18 from x 4, line 3.
# Plain Python 3, nothing else needed.
# UFO2.ICO (port/ico.asm, xtil.asm ico_load): "I3" (0.54.13: BUTTONS2's 12th; "I2" 0.54.5; "IC" before: no PARAMS2), the 16 buttons, the 12 signs (ranks, armours), the parameters; per line the
# EGA buffers' 4 parts' bytes (part 0: pairs 4c, 1: 4c + 2, 2: 4c + 1, 3: 4c + 3; a pair's byte: left pixel bits
# 0-2, 6; right 3-5, 7); padded to 91 records; then "WM" and the world map (per line 24 x 4 pair bytes, LZ as
# mkenc.py's) - into page 58's tail, unpacked when the map is shown; then "FN" and the text font (port/text.asm).
# FONT.png - the font the port draws the game's text with (128 x 64: 16 x 8 characters of 8 x 8, as the game's font;
# 4 classes by colour: black - the cell, grey - the letter, white - the letter's light, blue - its shadow; the colours
# themselves come from the text's attribute): 2 bits a pixel (the class), 16 bytes a character. An empty cell (all
# black): that character is made at the start from the game's font (xtil.asm og_gen: the letter - its pixels, the
# light - its upper half of rows, the shadow - an empty pixel with the letter left or up-left of it); after the 128
# characters 16 bytes: bit k - character k drawn here.
import os, sys, struct, zlib
ALL = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (192, 0, 192), (0, 192, 0), (0, 192, 192), (192, 192, 0), (192, 192, 192),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
USE = [0, 1, 2, 6, 7, 9, 10, 12, 13, 14, 15]   # (the same in both palettes)
PAL = [ALL[i] for i in USE]
FILES = [('ITEM%02d' % k, 32, 24) for k in range(16)] + [('RANK%d' % k, 24, 24) for k in range(8)] + \
        [('ARMOR%d' % k, 24, 24) for k in range(4)] + [('PARAMS', 24, 96), ('PARAMS2', 24, 64)]

# ---- PNG (read: 8-bit grey / RGB / RGBA / palette, 1/2/4-bit palette or grey; write: indexed / RGB)
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
def read(path, w, h, use=USE):
    W_, H_, rows = png_read(path)
    if W_ == w and H_ > h and (H_ - h) % 9 == 0: rows = rows[H_ - h:]; H_ = h     # (the palette's band on top: skipped)
    if (W_, H_) != (w, h): raise SystemExit('%s: %d x %d, must be %d x %d' % (path, W_, H_, w, h))
    cache = {}
    def near(c):
        if c not in cache: cache[c] = use[min(range(len(use)), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c, ALL[use[i]])), i))]
        return cache[c]
    return [[near(v) for v in r] for r in rows]
def pair(l, r): return (l & 7) | (l & 8) << 3 | (r & 7) << 3 | (r & 8) << 4
def ega(img, w):
    out = bytearray(); nc = w // 8
    for r in img:
        P = [pair(r[2 * p], r[2 * p + 1]) for p in range(w // 2)]
        for q in (0, 2, 1, 3): out += bytes(P[4 * c + q] for c in range(nc))
    return bytes(out)
def main():
    here = os.path.dirname(os.path.abspath(__file__))
    src = sys.argv[1] if len(sys.argv) > 1 else here
    dst = sys.argv[2] if len(sys.argv) > 2 else src
    data = bytearray(b'I3'); imgs = []
    for name, w, h in FILES:
        f = os.path.join(src, name + '.png')
        if not os.path.exists(f): raise SystemExit('no ' + f)
        img = read(f, w, h); imgs.append((name, img)); data += ega(img, w)
    assert len(data) == 2 + 16 * 384 + 12 * 288 + 96 * 12 + 64 * 12
    data += bytes(91 * 128 - len(data))
    f = os.path.join(src, 'WORLDMAP.png')
    if not os.path.exists(f): raise SystemExit('no ' + f)
    wm = read(f, 192, 120, list(range(16)))         # (the geoscape: CP/M's palette, all 16)
    raw = bytes(pair(r[8 * c + 2 * q], r[8 * c + 2 * q + 1]) for r in wm for c in range(24) for q in range(4))
    z = lz(raw); assert unlz(z)[0] == raw
    NBT = 14                                        # (port/ico.asm OV_NB)
    # the geoscape's 10 menu buttons and the encyclopedia's 4 (32 x 32 each): row 1 as they are, row 2 - "active" (the game's cyan) - the same
    # pixels through one colour map (each colour of row 1 one of row 2's): kept as a pair bytes' table after them; LZ
    # at the second part's end (its last 2 bytes: where it starts in the part)
    f = os.path.join(src, 'BUTTONS.png')
    if not os.path.exists(f): raise SystemExit('no ' + f)
    bt = read(f, 32 * NBT, 64, list(range(16)))
    cm = {}
    for y in range(32):
        for x in range(32 * NBT):
            a, b = bt[y][x], bt[y + 32][x]
            if cm.setdefault(a, b) != b: raise SystemExit('BUTTONS.png: colour %d of row 1 is %d and %d in row 2 (x %d, y %d): one colour each' % (a, cm[a], b, x, y))
    braw = b''.join(ega([r[32 * i:32 * i + 32] for r in bt[:32]], 32) for i in range(NBT))
    tb = bytearray(256)
    for v in range(256):
        l = (v & 7) | (v >> 3 & 8); r = (v >> 3 & 7) | (v >> 4 & 8)
        tb[v] = pair(cm.get(l, l), cm.get(r, r))
    braw += bytes(tb)
    f = os.path.join(src, 'TOOLBAR.png')           # the buy / sell / hire windows' 4 buttons (96 x 16, after the table)
    if not os.path.exists(f): raise SystemExit('no ' + f)
    tbar = read(f, 96, 16, list(range(16))); braw += ega(tbar, 96)
    f = os.path.join(src, 'BUTTONS2.png')           # the target menu's 10 buttons, an empty one, the crew's "fighter" one (384 x 32: 32 x 32 each)
    if not os.path.exists(f): raise SystemExit('no ' + f)
    bt2 = read(f, 32 * 12, 32, list(range(16)))
    braw += b''.join(ega([r[32 * i:32 * i + 32] for r in bt2], 32) for i in range(12))
    assert len(braw) == 16 * 512 + 12 * 512
    bz = lz(braw); assert unlz(bz)[0] == braw
    room = 9472 - 2 - 2 - len(bz)
    if len(z) > room: raise SystemExit('WORLDMAP.png + BUTTONS.png: %d + %d bytes packed, %d at most - too varied' % (len(z), len(bz), 9468))
    part = b'WM' + z + bytes(room - len(z)) + bz + struct.pack('<H', 2 + room)
    assert len(part) == 9472
    data += part
    f = os.path.join(src, 'FONT.png')
    if not os.path.exists(f): raise SystemExit('no ' + f)
    FC = [0, 7, 15, 1]                              # (the classes: the cell, the letter, its light, its shadow)
    fn = read(f, 128, 64, FC)
    fb = bytearray(b'FN')
    for k in range(128):
        for y in range(8):
            r = fn[(k // 16) * 8 + y][(k % 16) * 8:(k % 16) * 8 + 8]; w = 0
            for v in r: w = w << 2 | FC.index(v)
            fb += bytes((w >> 8, w & 255))
    hand = bytearray(16)                            # (a character drawn in FONT.png - not all the cell: ours as drawn;
    for k in range(128):                            #  else xtil.asm og_gen makes it from the game's font at the start)
        if any(v != FC[0] for y in range(8) for v in fn[(k // 16) * 8 + y][(k % 16) * 8:(k % 16) * 8 + 8]): hand[k >> 3] |= 1 << (k & 7)
    fb += hand
    data += fb + bytes(33 * 128 - len(fb))
    open(os.path.join(dst, 'UFO2.ICO'), 'wb').write(pk(bytes(data)))     # (packed: port/mz.asm)
    print('UFO2.ICO', len(data), 'bytes, packed %d' % len(pk(bytes(data))), '(the world map %d, the buttons %d: %d of 9468)' % (len(z), len(bz), len(z) + len(bz)))
    imgs.append(('WORLDMAP', wm)); imgs.append(('BUTTONS', bt)); imgs.append(('BUTTONS2', bt2)); imgs.append(('TOOLBAR', tbar)); imgs.append(('FONT', fn))
    f = os.path.join(src, 'PANEL.png')             # the fight's bottom panel (tools/mkpanel2.py: into UFO2.PNL) - here
    if os.path.exists(f): imgs.append(('PANEL', read(f, 240, 52)))     # checked, on the sheet
    K = 4; rows = [[(40, 40, 40)] * (9 * 36 * K + 192 * K + 8) for _ in range(4 * 30 * K + 8 + 64 * K + 8 + 64 * K + 8 + 16 * K + 8 + 52 * K + 8 + 32 * K + 8)]
    for i, (name, img) in enumerate(imgs):
        if i < 16: ox, oy = 4 + (i % 8) * 36 * K, 4 + (i // 8) * 30 * K
        elif i < 28: ox, oy = 4 + ((i - 16) % 8) * 36 * K, 4 + (2 + (i - 16) // 8) * 30 * K
        elif name == 'PARAMS': ox, oy = 4 + 8 * 36 * K, 4
        elif name == 'PARAMS2': ox, oy = 4 + 8 * 36 * K, 4 + 96 * K + 8
        elif name == 'BUTTONS': ox, oy = 4, 4 + 4 * 30 * K + 8 + 64 * K + 8
        elif name == 'TOOLBAR': ox, oy = 4, 4 + 4 * 30 * K + 8 + 64 * K + 8 + 64 * K + 8
        elif name == 'FONT': ox, oy = 4 + 9 * 36 * K, 4 + 120 * K + 8
        elif name == 'BUTTONS2': ox, oy = 4, 4 + 4 * 30 * K + 8 + 64 * K + 8 + 64 * K + 8 + 16 * K + 8 + 52 * K + 8
        elif name == 'PANEL': ox, oy = 4, 4 + 4 * 30 * K + 8 + 64 * K + 8 + 64 * K + 8 + 16 * K + 8
        else: ox, oy = 4 + 9 * 36 * K, 4
        for y, r in enumerate(img):
            for x, v in enumerate(r):
                for a in range(K): rows[oy + y * K + a][ox + x * K:ox + x * K + K] = [ALL[v]] * K
    png_write(os.path.join(dst, 'ico_sheet.png'), rows)
    print('ico_sheet.png')
if __name__ == '__main__': main()
