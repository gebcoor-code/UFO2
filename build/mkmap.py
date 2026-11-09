# mkmap.py - the whole map of one fight location of UFO-2 ("НЛО-2", ZX 1996) as a PNG, in our EGA colours (UFO2.TIL's).
#   python3 mkmap.py LOCATION [OUT.png] [-s SEED] [-strip]       e.g.  mkmap.py x02   mkmap.py x7c   mkmap.py xl5a x.png
# LOCATION, one of:
#   X<nn>[v]  - the port's debug location ("UFO2 DEBUG Xnn", port/xpg.asm dbg_tb), nn 0..11 (x4, x04, X11); v = the
#               variant where the game picks one at random (A, the default .. D; X00: A..H = T_ML0's 8); out: x<nn>[v].png
#                 X00 sea floor (L_L0): XL2 | XL3 | XL14 | XL16 | XL17 | XL18 | XL19 | XL20     X06 colony I: XL15
#                 X01 ship I: XL6A..D      X02 city port: XL11       X03 the other port: XL4     X07 base I: XL5A..D
#                 X04 island: XL9          X05 our base: XL7         X08 Tleth: XL10A..D         X09 colony II: XL13
#                 X10 base II: XL12        X11 ship II: XL8A..D
#   XL<name>  - the map file XL<name>.LND itself (xl11, XL5A, xl6b.lnd, or a path to one); out: xl<name>.png.
#               NB: x11 (debug location 11 = ship II, XL8A) is not xl11 (the file XL11 = the city port, X02).
#   #<n>      - the game's file number (XDISK2.A80; the port's notes' "XL44" = #44 = XL11).
# XL<n> is always drawn with the tile set XM<n> (the sets' numbers are the files' names). The LND file used is printed.
# In (looked for beside this script first, then where the repo keeps them):
#   src/XL<name>.LND - the map (UFO2SRC/XMAP: 8192 bytes - the 2nd floor (4096), then the 1st; a byte = the tile id 0..95)
#   src/xmgame.bin   - the game's own tiles of XM0..XM20 (mkxmg.py made it from the game's disk)
#   XMnn_tiles.png   - our coloured tiles (beside this script, in the repo data/til; the originals src/XMnn.png -
#                      the format: mktil.py). A game tile gets the colours of the first coloured place its shape has
#                      in them (mktil.py's rule); one in none: light grey ink.
#   mkmap.py all [DIR]   - first the edits of DIR's (default maps/) x<nn>_map.png into XMnn_tiles.png (as apply), then
#                          all the typical maps, their sheets and MAPS.txt into DIR anew (and the sheets' copies into
#                          DIR/_orig: an edit = a point not as there, so the sets may be edited meanwhile too). Files are overwritten without
#                          asking: each one written is said in the console.
#   mkmap.py apply SHEET|DIR [SETS] - only the edits of x<nn>_map.png (one, or all in DIR) into the sets' sheets.
#   mkmap.py full [DIR]  - (0.65.3) all the maps into DIR (default full_maps/): every location's every variant, XL0 / XL1;
#                          FULL.txt - the sets' tiles on none of them.
# Out: OUT.png (default: <name>.png, lower case, beside this script) - 16-colour indexed, the fight's palette (mktil PAL),
# black ground; 2 x 1 panels when the 2nd floor has anything: left the 1st floor alone (what the game shows on it), right
# the 1st floor with the 2nd drawn over it 24 lines higher (what the game shows on the 2nd floor: ALLSPF).
# The game's ids (XLIB.A80, XLIF.A80): 0..15 XM0 (the interceptor; 0 = empty, 1 = the black "fill"), then either
# 16..95 = XM<n>'s 80 tiles (XL4, 5x, 6x, 7, 8x, 9, 10x, 11, 12, 13) or 16..63 = XM1 (the UFO) + 64..95 = XM<n>'s 32
# (the sea floor: XL2, 3, 14..20; XL0 / XL1 - the interceptor's and the UFOs' pieces - with XM2 for 64 = the ground).
# The field (ALLSP): cell (x, y)'s tile (16 x 32) at 8 (x - y), 4 (x + y); drawn by x + y ascending (ink / paper where its
# mask is, the rest transparent - also the few ink bits outside the mask); the 2nd floor after the whole 1st.
# The maps: XL5x, XL10x (64 x 64) and XL6x, XL8x (ships: 128 x 32) are the field as they are (the game takes one of the 4
# variants at random). The rest are 16 pieces of 16 x 16 a floor (128 x 32: 2 rows of 8) the game puts into the 64 x 64
# field at random at the fight's start (L_SWAP shuffles them, L_DUP (not XL7, 12, 13) copies 0..7 of them over others;
# its RND reads the ROM, seeded by LD A,R / the frame counter); then it puts the interceptor / a UFO (XL0 / XL1 pieces)
# in - not done here. Default: the pieces in order (piece k -> row k // 4, column k % 4); -s SEED: shuffled as the game
# does (Python's random, not the game's RND); -strip: the 128 x 32 as stored. XL0 / XL1: always as stored.
# Plain Python 3, nothing else needed.
import os, re, sys, struct, zlib, random, shutil
PAL = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (96, 0, 0), (96, 192, 96), (255, 96, 96), (192, 192, 0), (192, 192, 192),
       (192, 96, 0), (0, 0, 255), (255, 0, 0), (96, 192, 0), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
NONE, LONE = (48, 48, 48), (128, 128, 128)
SHAPE = [NONE, (0, 0, 0), (255, 255, 255), LONE]  # 0 not drawn, 1 paper, 2 ink, 3 an ink bit outside the mask
SETS = ['XM%02d' % n for n in range(21)] + ['XMMORE']
GAMEFILE = {20: '2', 22: '3', 23: '4', 33: '7', 38: '9', 44: '11', 45: '12', 46: '13', 47: '14', 48: '15', 49: '19',
            50: '17', 51: '18', 52: '16', 53: '20'}          # XDISK2.A80 (the rest: #24.. = 5A..D, #28 6A.., #34 8A.., #40 10A..)
for i, b in ((24, '5'), (28, '6'), (34, '8'), (40, '10')):
    for k in range(4): GAMEFILE[i + k] = b + 'ABCD'[k]
def ship(t):
    """XM0's tile t: the ship's - the location's floor is the commonest neighbour of these (port/enl.asm te_flr).
    0.66.1: not 10, 11, 15 - flat, floor-level (10: the white plate - the ship's floor, the UFO's 2nd floor, beds,
    catwalks...): beside rock, platforms they made a block the floor (x05 the hangar, x09 the colony's beds). 0.66.9:
    the floor still under all 3..15 (11's, 15's transparent parts: the wings' edge - the floor, not black) - on the 1st
    floor only (the 2nd's wings: in the air - the 1st seen through; port/xpnt.asm pl_fl)"""
    return 3 <= t <= 15 and t not in (10, 11, 15)
BG = [0]                                    # (the ground's index: mkpal.py's count - 16)
NODUP = {'7', '12', '13'}                                   # L_L4, L_L8, L_L9: no L_DUP
# the port's debug locations X00..X11 (port/xpg.asm dbg_tb: L_LAND n -> XLIF.A80 L_Ln; the port: L_L2's JR C patched)
DEBUG = {0: ('sea floor, L_L0', ['2', '3', '14', '16', '17', '18', '19', '20']),   # T_ML0 [RND & 7]: XL / XM
         1: ('ship I, L_L1', ['6A', '6B', '6C', '6D']), 2: ('city port, L_L2', ['11']), 3: ('the other port, L_L2', ['4']),
         4: ('island, L_L3', ['9']), 5: ('our base, L_L4', ['7']), 6: ('colony I, L_L5', ['15']),
         7: ('base I, L_L6', ['5A', '5B', '5C', '5D']), 8: ('Tleth, L_L7', ['10A', '10B', '10C', '10D']),
         9: ('colony II, L_L8', ['13']), 10: ('base II, L_L9', ['12']), 11: ('ship II, L_L10', ['8A', '8B', '8C', '8D'])}

# ---- PNG (mktil.py's)
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
def png_write(path, rows, pal):
    """rows: indices into pal (16 colours at most)"""
    import tilsheet
    h = len(rows); w = len(rows[0]); raw = bytearray()
    for r in rows:
        raw.append(0); raw.extend((r[i] << 4) | (r[i + 1] if i + 1 < w else 0) for i in range(0, w, 2))
    def chunk(t, c): return struct.pack('>I', len(c)) + t + c + struct.pack('>I', zlib.crc32(t + c) & 0xFFFFFFFF)
    hd = struct.pack('>IIBBBBB', w, h, 4, 3, 0, 0, 0)
    tilsheet.save(path, b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', hd) + chunk(b'PLTE', b''.join(bytes(c) for c in pal))
                  + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))
def near(c, pal, cache={}):
    k = (c, len(pal))
    if k not in cache: cache[k] = min(range(len(pal)), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c[:3], pal[i])), i))
    return cache[k]

# ---- the colours (mktil.py's read_set / plain / the first coloured one)
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
                            col[(cc * 8 + x, y)] = near(rows[r * 64 + y][X], PAL)
                    t += bytes([m, i])
            if any(t[k] for k in range(0, 128, 2)): out.append((bytes(t), col, r * 16 + c) if pos else (bytes(t), col))
    return out
def cls(t, x, y):
    m = t[y * 4 + (x >> 3) * 2]; i = t[y * 4 + (x >> 3) * 2 + 1]; b = 0x80 >> (x & 7)
    return 0 if not m & b else (2 if i & b else 1)
def plain(t, col): return all(v == (15 if cls(t, x, y) == 2 else 0) for (x, y), v in col.items())

def find(name, dirs):
    for d in dirs:
        f = os.path.join(d, name)
        if os.path.exists(f): return f
        for g in os.listdir(d) if os.path.isdir(d) else []:
            if g.lower() == name.lower(): return os.path.join(d, g)
    raise SystemExit('no %s (looked in %s)' % (name, ', '.join(dirs)))

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    a = sys.argv[1:]; seed = None; strip = False; pos = []; tsh = False
    while a:
        v = a.pop(0)
        if v == '-s': seed = int(a.pop(0))
        elif v == '-strip': strip = True
        elif v == '-t': tsh = True
        else: pos.append(v)
    if not pos: raise SystemExit(__doc__ or 'usage: mkmap.py XL<name> [OUT.png] [-s SEED] [-strip] [-t]')
    import tilsheet
    td = tilsheet.dirs(here)[0]
    if pos[0].lower() == 'all':                 # the maps' sheets' edits -> the sets, then the maps anew
        dst = pos[1] if len(pos) > 1 else os.path.join(td, 'maps')
        if any(re.fullmatch(r'x\d\d[a-h]?_map\.png', f) for f in (os.listdir(dst) if os.path.isdir(dst) else [])): apply(dst, td)
        od = tilsheet.dirs(here)[1]             # (0.60.4: the sets with a location's paper slot; 0.66.0: every location's
        for n in range(2, 21):                  #  set - PALETTE.txt's palette: the band, the colours drawn so; written
            f = os.path.join(td, 'XM%02d_tiles.png' % n)   # only if that changes them)
            if not os.path.exists(f): continue
            shf = tilsheet.find_shapes('XM%02d' % n, od); byp = {k: c for t, c, k in tilsheet.read_set(f, shf, PAL)}
            tilsheet.write_set(f, [byp.get(k) for k in range(len(tilsheet.shapes(shf)))], PAL)
        return run_all(dst)
    if pos[0].lower() == 'apply': return apply(pos[1], pos[2] if len(pos) > 2 else td)
    if pos[0].lower() == 'full': return run_full(pos[1] if len(pos) > 1 else os.path.join(td, 'full_maps'))
    run(pos, seed, strip, tsh)
def run(pos, seed=None, strip=False, tsh=False, quiet=False):
    here = os.path.dirname(os.path.abspath(__file__))
    import tilsheet
    import builtins; print = (lambda *a: None) if quiet else builtins.print
    XD = tilsheet.dirs(here)[1][:3] + [here, os.path.join(here, '../UFO2SRC/XMAP')]  # (the maps: src/ first)
    arg = pos[0]
    if arg.startswith('#'):
        n = int(arg[1:])
        if n not in GAMEFILE: raise SystemExit('#%d: not a location map file (#20, #22..#53 without #32, #39)' % n)
        key = GAMEFILE[n]; lnd = find('XL%s.LND' % key, XD)
    elif os.path.sep in arg or os.path.isfile(arg):
        lnd = arg; key = os.path.splitext(os.path.basename(arg))[0].upper()[2:]
    elif re.fullmatch(r'[xX]\d{1,2}[a-hA-H]?', arg):        # the port's debug location Xnn [variant]
        nn = int(re.sub(r'\D', '', arg)); v = arg[-1].upper() if arg[-1].isalpha() else 'A'
        if nn not in DEBUG: raise SystemExit('%s: debug locations are X00..X11' % arg)
        vs = DEBUG[nn][1]
        if len(vs) == 1 and v != 'A': raise SystemExit('%s: X%02d has no variants' % (arg, nn))
        if len(vs) > 1 and 'ABCDEFGH'.index(v) >= len(vs): raise SystemExit('%s: X%02d has %d variants (A..%s)' % (arg, nn, len(vs), 'ABCDEFGH'[len(vs) - 1]))
        key = vs['ABCDEFGH'.index(v) if len(vs) > 1 else 0]
        lnd = find('XL%s.LND' % key, XD)
        if not pos[1:]: pos.append(os.path.join(here, 'x%02d%s.png' % (nn, v.lower() if len(vs) > 1 else '')))
        print('X%02d (%s)%s -> XL%s.LND' % (nn, DEBUG[nn][0], ' variant ' + v if len(vs) > 1 else '', key))
    else:
        key = os.path.splitext(arg)[0].upper()
        if not key.startswith('XL'): raise SystemExit('%s: XL<name>, X<nn>[variant] or #<n>' % arg)
        key = key[2:]
        lnd = find('XL%s.LND' % key, XD)
    num = ''.join(ch for ch in key if ch.isdigit())
    if not num or int(num) > 20: raise SystemExit('%s: not XL0..XL20' % arg)
    num = int(num); out = pos[1] if len(pos) > 1 else os.path.join(here, 'xl%s.png' % key.lower())
    d = open(lnd, 'rb').read()
    if len(d) != 8192: raise SystemExit('%s: %d bytes, not 8192' % (lnd, len(d)))

    # the game's tiles: XM0, XM1, XM<n>
    g = zlib.decompress(open(find('xmgame.bin', XD), 'rb').read()); game = []; p = 0
    while p < len(g): k = g[p]; game.append([g[p + 1 + j * 128:p + 129 + j * 128] for j in range(k)]); p += 1 + k * 128
    ts = num if num >= 2 else 2
    ids = game[0] + (game[1] + game[ts] if len(game[ts]) == 32 else game[ts])
    assert len(ids) == 96

    # their colours
    td, od = tilsheet.dirs(here)                # (the sets' sheets; the originals: src/)
    col = {}; src = {}
    for s in SETS:
        f = os.path.join(td, s + '_tiles.png')
        if os.path.exists(f): rs = tilsheet.read_set(f, tilsheet.find_shapes(s, od), PAL)
        else: rs = read_set(tilsheet.find_shapes(s, od), True)      # (no sheet: the original's colours)
        for t, c, k in rs:
            if t not in col or (plain(t, col[t]) and not plain(t, c)): col[t] = c; src[t] = (s, k)
    spr = []                                    # per id: [(x, y, colour)]
    miss = 0
    for t in ids:
        if t in col: c = col[t]
        else:
            c = {(x, y): (7 if cls(t, x, y) == 2 else 0) for y in range(32) for x in range(16) if cls(t, x, y)}
            miss += bool(c)
        spr.append(sorted((x, y, v) for (x, y), v in c.items()))

    # the field
    f2, f1 = d[:4096], d[4096:]
    piece = num not in (5, 6, 8, 10) and num >= 2 and not strip
    if piece:                                   # 16 pieces of 16 x 16 (128 x 32 as stored) -> 64 x 64 (L_COPY)
        m16 = list(range(16))
        if seed is not None:
            r = random.Random(seed)
            for i in range(16): j = r.randrange(16); m16[i], m16[j] = m16[j], m16[i]          # L_SWAP
            if key not in NODUP:
                for _ in range(r.randrange(8)): m16[r.randrange(16)] = m16[r.randrange(16)]   # L_DUP: (dst) = (src)
        def asm(fl):
            o = bytearray(4096)
            for i, pc in enumerate(m16):
                for y in range(16):
                    s = (pc // 8 * 16 + y) * 128 + pc % 8 * 16
                    q = (i // 4 * 16 + y) * 64 + i % 4 * 16; o[q:q + 16] = fl[s:s + 16]
            return bytes(o)
        f1, f2 = asm(f1), asm(f2); W, H = 64, 64
    elif num in (5, 10): W, H = 64, 64
    else: W, H = 128, 32                        # XL6x, XL8x (SET8x2), XL0 / XL1 and -strip: as stored

    x0 = 8 * (H - 1); y0 = 24
    pw = 8 * (W - 1 + H - 1) + 16; ph = 4 * (W - 1 + H - 1) + 32 + 24
    two = any(f2)
    gap = 16 if two else 0
    img = [[BG[0]] * (pw * (2 if two else 1) + gap) for _ in range(ph)]
    import collections                          # (0.58.0: XM0's tiles 3..15 - the ship's - get the location's floor under
    fc = collections.Counter(f1[i + d] & 0x7F for i in range(1, len(f1) - 1)       # (0.66.1: of the 1st floor only;
                             if ship(f1[i] & 0x7F) for d in (-1, 1) if 16 <= f1[i + d] & 0x7F < 96)  # not 10, 11, 15)
    if not fc: fc = collections.Counter(b & 0x7F for b in f1 if 16 <= b & 0x7F < 96)  # (the floor next to them; none:
                                                                                     #  the commonest - lines 16..31,
                                                                                     #  as the game does)
    flo = fc.most_common(1)[0][0] if fc else None
    f1c = collections.Counter(b & 0x7F for b in f1 if 16 <= b & 0x7F < 96)
    if num < 2: del f1c[0x3F]                   # (0.67.5: XL0, XL1 - the pieces the game puts into a location: their
                                                #  #3F, the UFO's floor / the unused pieces' fill, is not that floor -
                                                #  the location's own is, the sea floor here: under the hulls' joints)
    flo1 = f1c.most_common(1)[0][0] if f1c else None              # (the location's floor: the commonest of the 1st)
    fpx = {(a, b): v for a, b, v in spr[flo1]} if flo1 is not None else {}
    def cell(fl, x, y, ox, dy):
        t = fl[y * W + x] & 0x7F
        if t >= 96: return
        px = ox + x0 + 8 * (x - y); py = y0 + 4 * (x + y) - dy
        if 3 <= t <= 15 and flo is not None and not dy:   # (0.66.9: all - ship() picks the floor; the 1st floor only)
            for a, b, v in spr[flo]:
                if v != 9 and b >= 16: img[py + b][px + a] = v
        elif t >= 16 and t != flo1 and flo1 is not None:        # (0.59.0: its own "none" pixels of lines
            for a, b, v in spr[t]:                              #  16..31 - the floor's there)
                if v == 9 and b >= 16 and fpx.get((a, b), 9) != 9: img[py + b][px + a] = fpx[(a, b)]
        for a, b, v in spr[t]:
            if v != 9: img[py + b][px + a] = v            # (9: "none" - not drawn)
    def floor(fl, ox, dy):
        for s in range(W + H - 1):
            for x in range(max(0, s - H + 1), min(W, s + 1)): cell(fl, x, s - x, ox, dy)
    floor(f1, 0, 0)
    if two:                                     # (the 2nd floor over the 1st - as the game: XLIB.A80 ALLSPF; its floor
        floor(f1, pw + gap, 0); floor(f2, pw + gap, 24)   # #3F - XM01 #47, black: covers the 1st under it)
    png_write(out, img, tilsheet.set_pal(PAL, ts))                # (its paper's slot: the ZX colour - tilsheet.py)
    print('%s: %s with XM0%s + XM%d, %s%s, %d x %d%s%s' % (
        out, os.path.normpath(lnd), ' + XM1' if len(game[ts]) == 32 else '', ts, '%d x %d cells' % (W, H),
        (' (pieces: seed %d)' % seed if seed is not None else ' (pieces in order)') if piece else '',
        len(img[0]), ph, ', floors 1 | 1 + 2' if two else ', 1 floor', ', %d tiles uncoloured (light grey)' % miss if miss else ''))
    used = sorted(set(b & 0x7F for b in f1 + f2) - {v for v in range(96, 128)})
    info = []                                   # per used id: (id, its colours' set, its place there)
    for t in used:
        st = src.get(ids[t]); info.append((t, st[0] if st else None, st[1] if st else None))
    if tsh:                                     # the tiles it uses, numbered (tilsheet.py: the game's ids)
        import tilsheet
        tf = os.path.splitext(out)[0] + '_map.png'
        def lb(t):                              # its id; below: where its colours are (the set, the place in its PNG)
            st = src.get(ids[t]); return str(t) + ('\n%s %d' % (st[0][2:] if st[0] != 'XMMORE' else 'MORE', st[1]) if st else '\n-')
        tilsheet.sheet(tf, [(lb(t), dict(((x, y), v) for x, y, v in spr[t])) for t in used], tilsheet.set_pal(PAL, ts))
    return out, lnd, ts, len(game[ts]) == 32, info, {ids[t] for t in used}
def apply(sheet, ai):
    """maps' tiles' sheets (x<nn>_map.png, edited; SHEET - one, or a folder: all its x<nn>_map.png) -> their tiles'
    colours into the sets' sheets AI/XMnn_tiles.png (where each tile takes them from: the label under it). Each sheet is
    compared with the sets as they were before (so an unedited sheet changes nothing, even where it shares tiles with
    an edited one); a point changed differently in two sheets: the later one's taken (said)"""
    import tilsheet, tempfile, glob
    if os.path.isdir(sheet):
        sheets = sorted(f for f in glob.glob(os.path.join(sheet, 'x*_map.png'))
                        if re.fullmatch(r'x\d\d[a-h]?_map\.png', os.path.basename(f)))
        if not sheets: raise SystemExit('no x<nn>_map.png in ' + sheet)
    else: sheets = [sheet]
    shd = [ai] + tilsheet.dirs(os.path.dirname(os.path.abspath(__file__)))[1]
    sets = {}; who = {}; clash = 0
    for sh in sheets:
        nm = os.path.basename(sh).split('_')[0]
        with tempfile.TemporaryDirectory() as td:
            tilsheet.QUIET[0] = True
            try: out, lnd, ts, sea, info, _ = run([nm, os.path.join(td, 'm.png')], quiet=True)
            finally: tilsheet.QUIET[0] = False
        w, h, rows = tilsheet.png_read(sh); n0 = 0; mp = tilsheet.set_pal(PAL, ts)     # (read with its location's palette)
        ob = os.path.join(os.path.dirname(sh), BASE, os.path.basename(sh))     # (the sheet as mkmap.py all wrote it)
        base = tilsheet.png_read(ob)[2] if os.path.exists(ob) else None
        if base is not None and len(base) != h: base = None
        for i, (t, s, k) in enumerate(info):
            if s is None: continue
            if s not in sets:
                f = os.path.join(ai, s + '_tiles.png'); shp = tilsheet.shapes(tilsheet.find_shapes(s, shd))
                cur = {kk: c for _, c, kk in tilsheet.read_set(f, tilsheet.find_shapes(s, shd), PAL)}
                sets[s] = (f, shp, [cur.get(kk) for kk in range(len(shp))], [0], {kk: dict(c) for kk, c in cur.items()})
            f, shp, cols, n, orig = sets[s]
            x0 = 4 + (i % 16) * 30; y0 = tilsheet.PH + (i // 16) * 48 + 12          # (tilsheet.sheet's: 16 a row, labels of 2 lines)
            if y0 + 32 > h: raise SystemExit('%s: not %s\'s sheet (or not 1:1)' % (sh, nm))
            if cols[k] is None: cols[k] = {}
            dr = shp[k][1]
            for y in range(32):                     # (0.57.0: its shape too - OUT: not its; a pixel painted there: added)
                for x in range(16):
                    p = rows[y0 + y][x0 + x]
                    if base is not None:            # edited = not as written (the set may be edited too, meanwhile)
                        if tuple(base[y0 + y][x0 + x][:3]) == tuple(p[:3]): continue
                    v = tilsheet.val(p, mp, (x, y) in dr)
                    if base is None and (orig.get(k) or {}).get((x, y)) == v: continue      # (no base: as the set now)
                    key = (s, k, x, y)
                    if key in who and who[key][1] != v: clash += 1
                    if cols[k].get((x, y)) != v:
                        if v is None: del cols[k][(x, y)]
                        else: cols[k][(x, y)] = v
                        n[0] += 1; n0 += 1
                    who[key] = (nm, v)
        if n0: print('%s: %d points edited' % (os.path.basename(sh), n0))
    ch = 0
    for s, (f, shp, cols, n, orig) in sorted(sets.items()):
        if n[0]: tilsheet.write_set(f, cols, PAL); print('  (%s: %d points changed)' % (os.path.basename(f), n[0])); ch += n[0]
    if clash: print(clash, 'points changed differently in several sheets: the later sheet\'s taken')
    if not ch: print('the maps\' sheets: no edits')
BASE = '_orig'                                  # maps/_orig: the sheets as written (what was edited in them: the difference)
def run_all(dst):
    """the typical maps (each debug location, variant A) and their tiles' sheets into DST, MAPS.txt: what each uses"""
    import tilsheet
    os.makedirs(dst, exist_ok=True); txt = []
    jobs = []                                   # (the name, the location, its variant: 0 = A)
    for nn in sorted(DEBUG):
        jobs.append(('x%02d' % nn, nn, 0))
        if nn == 0: jobs += [('x00' + 'abcdefgh'[v], 0, v) for v in range(1, 8)]   # (the sea floor's B..H: XM03, 14, 16..20)
    for nm, nn, var in jobs:
        out, lnd, ts, sea, info, _ = run([nm, os.path.join(dst, nm + '.png')], tsh=True, quiet=True)
        os.makedirs(os.path.join(dst, BASE), exist_ok=True)
        tilsheet.QUIET[0] = True                # (the copy: not said)
        try: tilsheet.save(os.path.join(dst, BASE, nm + '_map.png'), open(os.path.join(dst, nm + '_map.png'), 'rb').read())
        finally: tilsheet.QUIET[0] = False
        name, vs = DEBUG[nn]
        sets = 'XM00' + (' + XM01' if sea else '') + ' + XM%02d' % ts
        txt.append('%s.png, %s_map.png - X%02d (%s), %s; тайлы: %s' % (nm, nm, nn, name,
                   os.path.basename(lnd) + (' (вариант %s из %s)' % ('ABCDEFGH'[var], ', '.join('XL' + v for v in vs)) if len(vs) > 1 else ''), sets))
        by = {}
        for t, s, k in info:
            by.setdefault(s, []).append((t, k))
        for s in sorted(by, key=lambda v: (v is None, v or '')):
            if s is None: txt.append('  нет цвета нигде (светло-серые): ' + ' '.join(str(t) for t, _ in by[s])); continue
            b = tilsheet.base(s)
            txt.append('  %s.png: %s' % (s, ' '.join('%d=#%d' % (t, k) for t, k in by[s])))
        txt.append('')
    head = ['Карты локаций (mkmap.py all) - по одной на каждую X<nn> (как UFO2 DEBUG Xnn, вариант A), у морского дна',
            'X00 - все 8 вариантов: x00 (A, XM02), x00b (B, XM03), x00c (C, XM14), x00d..x00h (D..H, XM16..XM20):',
            '  x<nn>.png        - карта целиком (если есть 2-й этаж: слева 1-й, справа 1-й со 2-м поверх);',
            '  x<nn>_map.png  - все тайлы, которые есть на этой карте, по одному. Над тайлом крупно - его номер',
            '                     в карте (id тайла в игре: 0..95; на карте стоят не все, отсюда пропуски); под',
            '                     ним мелко - откуда берутся его цвета: набор и место в нём ("06 3" = XM06.png,',
            '                     тайл 3 - как в ../XM06_tiles.png). Править цвет тайла - там или прямо здесь (mkmap.py all перенесёт).',
            'Ниже то же списком: для каждой карты - её наборы и номера тайлов по файлам XMnn.png ("19=#3": тайл 19',
            'карты - место 3 в этом наборе). Тайл берёт цвета из первой своей раскрашенной копии (по порядку',
            'XM00..XM20, XMMORE), поэтому иногда - из набора другой локации.', '']
    tilsheet.save(os.path.join(dst, 'MAPS.txt'), '\n'.join(head + txt).encode('utf-8'))
def run_full(dst):
    """(0.65.3) all the maps: every location's every variant (pieces in order), XL0 / XL1 (the interceptor's, the
    UFOs' pieces); FULL.txt - the sets' tiles on none of them (not the dummies)"""
    import tilsheet
    here = os.path.dirname(os.path.abspath(__file__))
    os.makedirs(dst, exist_ok=True); seen = set(); txt = []
    jobs = []
    for nn in sorted(DEBUG):
        vs = DEBUG[nn][1]
        for v in range(len(vs)): jobs.append(('x%02d%s' % (nn, 'abcdefgh'[v] if len(vs) > 1 else ''), nn, v))
    jobs += [('xl0', None, 0), ('xl1', None, 0)]
    for nm, nn, v in jobs:
        out, lnd, ts, sea, info, ut = run([nm, os.path.join(dst, nm + '.png')], quiet=True)
        seen |= ut
        txt.append('%s.png - %s%s' % (nm, ('X%02d (%s), ' % (nn, DEBUG[nn][0])) if nn is not None else
                   ('корабль игрока (куски, игра ставит их в начале боя), ' if nm == 'xl0' else 'НЛО (куски, игра ставит их в начале боя), '),
                   os.path.basename(lnd)))
    td, od = tilsheet.dirs(here)
    rest = []
    for s in SETS:
        f = os.path.join(td, s + '_tiles.png')
        if not os.path.exists(f): continue
        shp = tilsheet.find_shapes(s, od); dm = tilsheet.dummies(shp)
        ks = [k for k, (t, dr) in enumerate(tilsheet.shapes(shp)) if any(t[j] for j in range(0, 128, 2)) and k not in dm and t not in seen]
        if ks: rest.append('  %s_tiles.png: %s' % (s, ' '.join(str(k) for k in ks)))
    head = ['Полные карты (mkmap.py full): все варианты всех локаций (у морского дна, колоний, портов, острова, нашей',
            'базы и базы II - 16 кусков по порядку: все куски есть), и куски корабля игрока и НЛО (XL0, XL1: игра ставит',
            'их на карту в начале боя). Каждый тайл, который есть в картах игры, есть здесь хотя бы раз.', '']
    tail = ['', 'Тайлы наборов, которых нет ни на одной карте (пустышки NOT USED - не в счёт): их игра ставит сама во время',
            'боя (открытая дверь, обломки после выстрела / взрыва, ...) или не ставит вовсе:'] + (rest or ['  (нет)'])
    tilsheet.save(os.path.join(dst, 'FULL.txt'), '\n'.join(head + txt + tail).encode('utf-8'))
if __name__ == '__main__': main()
