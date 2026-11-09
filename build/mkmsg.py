# mkmsg.py: port/encmsg.bin - the encyclopedia's picture shown when UFO2.ENC is not on the disk (enl.asm en_get):
# "IMAGE DATA NOT FOUND." / "INSERT DISK WITH UFO2.ENC" in a frame, 224 x 192, as UFO2.ENC's pictures are (mkenc.py:
# the plane's LZ, the colours' LZ). The font: below (7 x 9, two-pixel strokes). PNG beside it (out/encmsg.png) to see.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkenc

K, B, R, BB, BR, BC, BY, Y, WH = 0, 1, 2, 9, 10, 13, 14, 6, 15
F = {
 'A': ' ##### |##   ##|##   ##|##   ##|#######|##   ##|##   ##|##   ##|##   ##',
 'C': ' ##### |##   ##|##     |##     |##     |##     |##     |##   ##| ##### ',
 'D': '###### |##   ##|##   ##|##   ##|##   ##|##   ##|##   ##|##   ##|###### ',
 'E': '#######|##     |##     |##     |###### |##     |##     |##     |#######',
 'F': '#######|##     |##     |##     |###### |##     |##     |##     |##     ',
 'G': ' ##### |##   ##|##     |##     |## ####|##   ##|##   ##|##   ##| ##### ',
 'H': '##   ##|##   ##|##   ##|##   ##|#######|##   ##|##   ##|##   ##|##   ##',
 'I': ' #### |  ##  |  ##  |  ##  |  ##  |  ##  |  ##  |  ##  | #### ',
 'K': '##   ##|##  ## |## ##  |####   |###    |####   |## ##  |##  ## |##   ##',
 'M': '##   ##|### ###|#######|## # ##|##   ##|##   ##|##   ##|##   ##|##   ##',
 'N': '##   ##|###  ##|#### ##|## ####|##  ###|##   ##|##   ##|##   ##|##   ##',
 'O': ' ##### |##   ##|##   ##|##   ##|##   ##|##   ##|##   ##|##   ##| ##### ',
 'R': '###### |##   ##|##   ##|##   ##|###### |## ##  |##  ## |##   ##|##   ##',
 'S': ' ##### |##   ##|##     |##     | ##### |     ##|     ##|##   ##| ##### ',
 'T': '########|   ##   |   ##   |   ##   |   ##   |   ##   |   ##   |   ##   |   ##   ',
 'U': '##   ##|##   ##|##   ##|##   ##|##   ##|##   ##|##   ##|##   ##| ##### ',
 'W': '##   ##|##   ##|##   ##|##   ##|##   ##|## # ##|#######|### ###|##   ##',
 '2': ' ##### |##   ##|     ##|    ## |  ###  | ##    |##     |##     |#######',
 '.': '   |   |   |   |   |   |   |## |## ',
 ' ': '   ',
}
W, H = mkenc.W, mkenc.H
C = [[K] * W for _ in range(H)]
BAY = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
def ramp(cols, t, x, y):                        # t 0..1 along cols, dithered
    t = min(max(t, 0.0), 0.9999) * (len(cols) - 1); k = int(t); f = t - k
    return cols[k + 1] if k + 1 < len(cols) and f > (BAY[y % 4][x % 4] + 0.5) / 16 else cols[k]
def line(s, y, cols):
    wd = sum(len(F[c].split('|')[0]) + 1 for c in s) - 1; x = (W - wd) // 2
    for c in s:
        g = F[c].split('|')
        for j, r in enumerate(g):
            for i, v in enumerate(r):
                if v == '#':
                    C[y + j][x + i] = ramp(cols, j / (len(g) - 1), x + i, y + j)
                    if C[y + j + 1][x + i + 1] == K: C[y + j + 1][x + i + 1] = B      # (a shadow)
        x += len(g[0]) + 1
# the frame: two lines, the outer dark blue, the inner light; the inside a dark blue haze to its rim
X0, Y0, X1, Y1 = 10, 62, 213, 129
for y in range(Y0, Y1 + 1):
    for x in range(X0, X1 + 1):
        e = min(x - X0, X1 - x, y - Y0, Y1 - y)
        if e == 0: C[y][x] = B
        elif e == 2: C[y][x] = BC if (x + y) % 2 else BB
        elif e > 2 and e < 9 and ((BAY[y % 4][x % 4] + 0.5) / 16) < 0.4 * (9 - e) / 7: C[y][x] = B
line('IMAGE DATA NOT FOUND.', 76, [WH, BY, BR, R])
line('INSERT DISK WITH UFO2.ENC', 103, [WH, BC, BC, BB])
p, c, lc = mkenc.encode(C); assert mkenc.decode(p + c) == C
here = os.path.dirname(os.path.abspath(__file__))
open(os.path.join(here, '..', 'port', 'encmsg.bin'), 'wb').write(p + c)
os.makedirs(os.path.join(here, 'out'), exist_ok=True)
mkenc.png_write(os.path.join(here, 'out', 'encmsg.png'), [[mkenc.PAL[v] for v in r] for r in C])
print('encmsg.bin %d bytes' % len(p + c))
