# mkenc.py - UFO2.ENC: the encyclopedia's 60 pictures in EGA for UFO-2 EGA (ATM Turbo 2+, CP/M).
#   python3 mkenc.py [FOLDER [OUT]]   (no arguments: the pictures beside this script, the results there too)
# In: ENC00.png .. ENC59.png - 224 x 192, the 16 colours of CP/M's EGA palette (an indexed PNG best; any PNG works:
# each pixel taken as the nearest of the 16). Picture N = the encyclopedia's article N.
# Out: UFO2.ENC (beside UFO2.COM) and enc_sheet.png - all 60 pictures as decoded from UFO2.ENC (to check).
# Plain Python 3, nothing else needed.
#
# The format (port/enc.asm, enl.asm - the game reads a picture from UFO2.ENC when its article's picture is opened):
# each picture is a plane (1 bit a pixel, 28 bytes a line) and colours over it - both LZ (the game's LPC with plain
# literals): a pixel's class (its bit) has a colour now (0: 15, 1: 0 at first); a byte per change: high nibble G
# 0..14 - G pixels keep their class's colour, then the next pixel's class gets colour C (low nibble); G = 15: skip
# C * 256 + the next byte pixels (C = 15: the next 2 bytes). The plane is chosen here: a new colour replaces the
# class colour needed again latest - any picture can be stored, the plane is not the game's.
# The file: record 0 (128 bytes): "E2", then 61 words - picture N's first record (N = 0..59), the file's records;
# each picture from a record of its own: its plane's LZ, its colours' LZ. The game reads one picture at a time
# (16384 bytes at most: 128 records; its colours 5632 bytes at most when unpacked) - the file's size is not limited.
import os, sys, struct, zlib

PAL = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (192, 0, 192), (0, 192, 0), (0, 192, 192), (192, 192, 0), (192, 192, 192),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
NP, W, H = 60, 224, 192

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
def colours(path, w, h):
    W_, H_, rows = png_read(path)
    if W_ == w and H_ > h and (H_ - h) % 9 == 0: rows = rows[H_ - h:]; H_ = h     # (the palette's band on top: skipped)
    if (W_, H_) != (w, h): raise SystemExit('%s: %d x %d, must be %d x %d' % (path, W_, H_, w, h))
    cache = {}
    def near(c):
        if c not in cache: cache[c] = min(range(16), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c, PAL[i])), i))
        return cache[c]
    return [[near(v) for v in r] for r in rows]

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

# ---- a picture -> plane + colours
def encode(C):
    cur = [15, 0]; bits = [[0] * W for _ in range(H)]; out = bytearray(); gap = 0
    flat = [v for r in C for v in r]; N = len(flat)
    nxt = [N] * N; seen = {}
    for i in range(N - 1, -1, -1): nxt[i] = seen.get(flat[i], N); seen[flat[i]] = i
    use = [seen.get(15, N), seen.get(0, N)]     # each class's colour: where it is next needed
    def skip(g):
        while g >= 15:
            if g > 0xEFF: k = min(g, 65535); out.extend([0xFF, k & 255, k >> 8])
            else: k = g; out.extend([0xF0 | k >> 8, k & 255])
            g -= k
        return g
    for i, v in enumerate(flat):                # (a new colour replaces the one needed latest: the fewest changes; no
                                                #  dark / light rule any more - two dark colours in turn changed each pixel)
        if cur[0] == v: b = 0
        elif cur[1] == v: b = 1
        else: b = 0 if use[0] > use[1] else 1
        bits[i // W][i % W] = b; use[b] = nxt[i]
        if cur[b] == v: gap += 1; continue
        gap = skip(gap); out.append(gap << 4 | v); gap = 0; cur[b] = v
    out.extend([0xF0, skip(gap)])
    plane = bytes(sum(bits[y][8 * k + j] << (7 - j) for j in range(8)) for y in range(H) for k in range(28))
    return lz(plane), lz(bytes(out)), len(out)
def decode(chunk):                              # (as enc.asm: ep_lz, then ep_dec) -> colours
    plane, used = unlz(chunk); s = unlz(chunk[used:])[0]
    cur = {0: 15, 1: 0}; i = 0; g = 0; pend = None; res = []
    def rd():
        nonlocal i, g, pend
        a = s[i]; i += 1
        if a == 0xFF: g = s[i] | s[i + 1] << 8; i += 2; pend = None
        elif a >= 0xF0: g = (a & 15) << 8 | s[i]; i += 1; pend = None
        else: g = a >> 4; pend = a & 15
    for y in range(H):
        for x in range(W):
            b = plane[y * 28 + x // 8] >> (7 - x % 8) & 1
            while True:
                if g: g -= 1; break
                if pend is None: rd(); continue
                cur[b] = pend; rd(); break
            res.append(cur[b])
    return [res[y * W:(y + 1) * W] for y in range(H)]

CMAX, PMAX = 5632, 16384                        # (the colours unpacked: PLA #2A00..#3FFF; a picture: one 16K page)

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    src = sys.argv[1] if len(sys.argv) > 1 else here
    dst = sys.argv[2] if len(sys.argv) > 2 else src
    CH = []
    for n in range(NP):
        f = os.path.join(src, 'ENC%02d.png' % n)
        if not os.path.exists(f): raise SystemExit('no ' + f)
        C = colours(f, W, H); p, c, lc = encode(C); ch = p + c
        assert decode(ch) == C, n
        CH.append((ch, lc, len(c))); print('\rENC%02d.png %5d bytes' % (n, len(ch)), end='', flush=True)
    print()
    sheet(CH, dst)
    data = bytearray(128); first = []
    for ch, lc, zc in CH:
        first.append(len(data) // 128); data += ch + bytes(-len(ch) % 128)
    first.append(len(data) // 128)
    head = b'E2' + b''.join(struct.pack('<H', r) for r in first); data[:len(head)] = head
    open(os.path.join(dst, 'UFO2.ENC'), 'wb').write(data)
    print('UFO2.ENC %d bytes (pictures %d bytes; the largest %d)' % (len(data), sum(len(c[0]) for c in CH), max(len(c[0]) for c in CH)))
    bad = [n for n in range(NP) if len(CH[n][0]) > PMAX or CH[n][1] > CMAX]
    for n in bad:                               # (the file made anyway: the game shows these pictures wrong)
        print('  ENC%02d.png: NOT FOR THE GAME - %d bytes (%d at most), colours %d bytes unpacked (%d at most)'
              % (n, len(CH[n][0]), PMAX, CH[n][1], CMAX))
def sheet(CH, dst):
    # the sheet: 6 x 10, each picture as decoded, its number above it
    CW, CHh = W + 8, H + 14
    rows = [[(40, 40, 40)] * (8 + 6 * CW) for _ in range(6 + 10 * CHh)]
    for n in range(NP):
        ox, oy = 8 + (n % 6) * CW, 16 + (n // 6) * CHh
        text(rows, ox, oy - 9, '%02d' % n)
        D = decode(CH[n][0])
        for y in range(H): rows[oy + y][ox:ox + W] = [PAL[v] for v in D[y]]
    png_write(os.path.join(dst, 'enc_sheet.png'), rows)
    print('enc_sheet.png')
FONT = {'0': '7 5 5 5 7', '1': '2 6 2 2 7', '2': '7 1 7 4 7', '3': '7 1 3 1 7', '4': '5 5 7 1 1', '5': '7 4 7 1 7',
        '6': '7 4 7 5 7', '7': '7 1 1 2 2', '8': '7 5 7 5 7', '9': '7 5 7 1 7'}
def text(rows, x, y, s):
    for ch in s:
        for j, r in enumerate(FONT[ch].split()):
            for i in range(3):
                if int(r) >> (2 - i) & 1: rows[y + j][x + i] = (255, 255, 255)
        x += 4
if __name__ == '__main__': main()
