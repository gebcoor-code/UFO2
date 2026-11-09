# rgcmp.py OLD NEW [OUTDIR]: two regression runs' shots (OLD/<test>/*.png vs NEW/...) compared, telling small changes
# (a blinking mark, the mouse cursor, an animation's dots: each spot of changed points at most MAXS x MAXS points of
# 320 x 200) from large ones (stripes, a window or a picture different, garbage); OUTDIR (default NEW/cmp): for each
# image with a large change old | new | the changed points (red) as one PNG. Exit code 1 if any large change.
import os, sys
from PIL import Image
MAXS = int(os.environ.get('MAXS', '12'))
old, new = sys.argv[1], sys.argv[2]
out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(new, 'cmp')
os.makedirs(out, exist_ok=True)
def pix(path):
    im = Image.open(path).convert('RGB'); w, h = im.size; sx, sy = w // 320, h // 200
    return im, [[im.getpixel((x * sx + sx // 2, y * sy + sy // 2)) for x in range(320)] for y in range(200)]
bad = 0; lines = []
for t in sorted(os.listdir(new)):
    dn, do = os.path.join(new, t), os.path.join(old, t)
    if not os.path.isdir(dn) or not os.path.isdir(do): continue
    for f in sorted(os.listdir(dn)):
        if not f.endswith('.png'): continue
        fo = os.path.join(do, f)
        if not os.path.exists(fo): lines.append('%s/%s: new only' % (t, f)); continue
        if open(fo, 'rb').read() == open(os.path.join(dn, f), 'rb').read(): continue
        imo, a = pix(fo); imn, b = pix(os.path.join(dn, f))
        d = [[a[y][x] != b[y][x] for x in range(320)] for y in range(200)]
        seen = [[False] * 320 for _ in range(200)]; spots = []
        for y in range(200):
            for x in range(320):
                if d[y][x] and not seen[y][x]:
                    st = [(x, y)]; seen[y][x] = True; x0 = x1 = x; y0 = y1 = y; n = 0
                    while st:
                        cx, cy = st.pop(); n += 1
                        x0, x1, y0, y1 = min(x0, cx), max(x1, cx), min(y0, cy), max(y1, cy)
                        for dy in (-1, 0, 1):
                            for dx in (-1, 0, 1):
                                nx, ny = cx + dx, cy + dy
                                if 0 <= nx < 320 and 0 <= ny < 200 and d[ny][nx] and not seen[ny][nx]:
                                    seen[ny][nx] = True; st.append((nx, ny))
                    spots.append((x0, y0, x1 - x0 + 1, y1 - y0 + 1, n))
        if not spots: continue
        big = [s for s in spots if s[2] > MAXS or s[3] > MAXS]
        if big:
            bad += 1
            lines.append('%s/%s: LARGE %d (%s), small %d' % (t, f, len(big), ' '.join('%dx%d@%d,%d' % (s[2], s[3], s[0], s[1]) for s in big[:4]), len(spots) - len(big)))
            w, h = imn.size; c = Image.new('RGB', (w * 3, h))
            c.paste(imo, (0, 0)); c.paste(imn, (w, 0))
            m = Image.new('RGB', (320, 200))
            for y in range(200):
                for x in range(320): m.putpixel((x, y), (255, 0, 0) if d[y][x] else tuple(v // 4 for v in b[y][x]))
            c.paste(m.resize((w, h), Image.NEAREST), (2 * w, 0))
            c.resize((w * 3 // 2, h // 2)).save(os.path.join(out, '%s_%s' % (t, f)))
        else: lines.append('%s/%s: small %d' % (t, f, len(spots)))
print('\n'.join(lines)); print('large:', bad)
sys.exit(1 if bad else 0)
