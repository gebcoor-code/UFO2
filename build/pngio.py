# A little of what the scripts need from Pillow, in plain Python (zlib only): images as rows of values (RGB tuples
# or palette indices), PNG read (8-bit grey / RGB / RGBA / palette, any filter, not interlaced) and write (RGB),
# indexed PNG write (4 / 8-bit), BMP read (8-bit palette, uncompressed: the pixels' indices), nearest scaling, pasting, and a small 5 x 7 font for
# the sheets' labels (digits, Latin letters; others drawn as a box).
import struct, zlib

class Img:
    def __init__(self, w, h, fill=(0, 0, 0)):
        self.width, self.height = w, h; self.size = (w, h)
        self.rows = [[fill] * w for _ in range(h)]
    def load(self): return _Acc(self)
    def paste(self, other, xy):
        ox, oy = xy
        for y in range(other.height):
            if 0 <= oy + y < self.height:
                r = self.rows[oy + y]; s = other.rows[y]
                for x in range(other.width):
                    if 0 <= ox + x < self.width: r[ox + x] = s[x]
    def scaled(self, k):
        o = Img(self.width * k, self.height * k)
        o.rows = [[v for v in r for _ in range(k)] for r in self.rows for _ in range(k)]
        return o
    def crop(self, box):
        x0, y0, x1, y1 = box; o = Img(x1 - x0, y1 - y0)
        o.rows = [r[x0:x1] for r in self.rows[y0:y1]]; return o
    def save(self, path): write_png(path, self)
    def text(self, x, y, s, col, k=1):
        for ch in s:
            g = FONT.get(ch.upper(), FONT['?'])
            for j, row in enumerate(g):
                for i in range(5):
                    if row >> (4 - i) & 1:
                        for a in range(k):
                            for b in range(k):
                                X, Y = x + i * k + a, y + j * k + b
                                if 0 <= X < self.width and 0 <= Y < self.height: self.rows[Y][X] = col
            x += 6 * k

class _Acc:
    def __init__(self, im): self.r = im.rows
    def __getitem__(self, xy): return self.r[xy[1]][xy[0]]
    def __setitem__(self, xy, v): self.r[xy[1]][xy[0]] = v

def new(w, h, fill=(0, 0, 0)): return Img(w, h, fill)

def open_bmp(path):
    d = open(path, 'rb').read()
    off = struct.unpack('<I', d[10:14])[0]
    hs, w, h, _, bpp, comp = struct.unpack('<IiiHHI', d[14:34])
    assert bpp == 8 and comp == 0, 'only 8-bit uncompressed BMP'
    stride = (w + 3) & ~3; im = Img(w, abs(h), 0)
    for y in range(abs(h)):
        src = (abs(h) - 1 - y) if h > 0 else y
        im.rows[y] = list(d[off + src * stride:off + src * stride + w])
    return im

def open_png(path):
    d = open(path, 'rb').read(); assert d[:8] == b'\x89PNG\r\n\x1a\n', 'not a PNG'
    p = 8; idat = b''; pal = None
    while p < len(d):
        n = struct.unpack('>I', d[p:p + 4])[0]; t = d[p + 4:p + 8]; c = d[p + 8:p + 8 + n]; p += 12 + n
        if t == b'IHDR': w, h, depth, ct, _, _, il = struct.unpack('>IIBBBBB', c)
        elif t == b'PLTE': pal = [tuple(c[i:i + 3]) for i in range(0, len(c), 3)]
        elif t == b'IDAT': idat += c
        elif t == b'IEND': break
    assert il == 0 and (depth == 8 or (depth in (1, 2, 4) and ct in (0, 3))), 'only 8-bit (or 1/2/4-bit palette), not interlaced PNG'
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]; raw = zlib.decompress(idat)
    stride = w * bpp if depth == 8 else (w * depth + 7) // 8
    im = Img(w, h); prev = bytearray(stride); i = 0
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
            im.rows[y] = [pal[q] for q in v] if ct == 3 else [(q * 255 // m,) * 3 for q in v]
        elif ct == 2: im.rows[y] = [tuple(line[k:k + 3]) for k in range(0, stride, 3)]
        elif ct == 6: im.rows[y] = [tuple(line[k:k + 3]) for k in range(0, stride, 4)]
        elif ct == 3: im.rows[y] = [pal[v] for v in line]
        elif ct == 0: im.rows[y] = [(v, v, v) for v in line]
        else: im.rows[y] = [(line[k],) * 3 for k in range(0, stride, 2)]
    return im

def write_idx(path, rows, pal):
    """rows: lists of palette indices; pal: [(r, g, b)] - an indexed PNG (4-bit if 16 colours or fewer, else 8-bit)"""
    h = len(rows); w = len(rows[0]); d = 4 if len(pal) <= 16 else 8; raw = bytearray()
    for r in rows:
        raw.append(0)
        if d == 8: raw.extend(r)
        else: raw.extend((r[i] << 4) | (r[i + 1] if i + 1 < w else 0) for i in range(0, w, 2))
    def chunk(t, c): return struct.pack('>I', len(c)) + t + c + struct.pack('>I', zlib.crc32(t + c) & 0xFFFFFFFF)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, d, 3, 0, 0, 0))
                           + chunk(b'PLTE', b''.join(bytes(c) for c in pal))
                           + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))
def indices(im, pal):
    """an opened picture's pixels as the nearest of pal's colours (the first of equal ones)"""
    cache = {}
    def near(c):
        if c not in cache: cache[c] = min(range(len(pal)), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c[:3], pal[i])), i))
        return cache[c]
    return [[near(v) for v in r] for r in im.rows]

def write_png(path, im):
    raw = bytearray()
    for r in im.rows:
        raw.append(0)
        for v in r: raw.extend(v if isinstance(v, tuple) else (v, v, v))
    def chunk(t, c): return struct.pack('>I', len(c)) + t + c + struct.pack('>I', zlib.crc32(t + c) & 0xFFFFFFFF)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', im.width, im.height, 8, 2, 0, 0, 0))
                           + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))

_F = """0 70 88 98 a8 c8 88 70|1 20 60 20 20 20 20 70|2 70 88 08 30 40 80 f8|3 f8 10 20 10 08 88 70|4 10 30 50 90 f8 10 10
5 f8 80 f0 08 08 88 70|6 30 40 80 f0 88 88 70|7 f8 08 10 20 40 40 40|8 70 88 88 70 88 88 70|9 70 88 88 78 08 10 60
A 70 88 88 f8 88 88 88|B f0 88 88 f0 88 88 f0|C 70 88 80 80 80 88 70|D e0 90 88 88 88 90 e0|E f8 80 80 f0 80 80 f8
F f8 80 80 f0 80 80 80|G 70 88 80 b8 88 88 78|H 88 88 88 f8 88 88 88|I 70 20 20 20 20 20 70|J 38 10 10 10 10 90 60
K 88 90 a0 c0 a0 90 88|L 80 80 80 80 80 80 f8|M 88 d8 a8 a8 88 88 88|N 88 88 c8 a8 98 88 88|O 70 88 88 88 88 88 70
P f0 88 88 f0 80 80 80|Q 70 88 88 88 a8 90 68|R f0 88 88 f0 a0 90 88|S 78 80 80 70 08 08 f0|T f8 20 20 20 20 20 20
U 88 88 88 88 88 88 70|V 88 88 88 88 88 50 20|W 88 88 88 a8 a8 a8 50|X 88 88 50 20 50 88 88|Y 88 88 88 50 20 20 20
Z f8 08 10 20 40 80 f8|. 00 00 00 00 00 60 60|- 00 00 00 f8 00 00 00|( 10 20 40 40 40 20 10|) 40 20 10 10 10 20 40
: 00 60 60 00 60 60 00|/ 08 08 10 20 40 80 80|? f8 88 88 88 88 88 f8|, 00 00 00 00 60 20 40"""
FONT = {' ': [0] * 7}
for e in _F.replace('\n', '|').split('|'):
    k, *v = e.split(); FONT[k] = [int(b, 16) >> 3 for b in v]
