# mkspr.py - UFO2.SPR: the fighters' / aliens' colours for UFO-2 EGA (ATM Turbo 2+, CP/M), from the sheet XHERO_sheet.png.
#   python mkspr.py [FOLDER [OUT]]   (no arguments: XHERO_sheet.png beside this script, UFO2.SPR there too; overwritten
#                                    without asking - said in the console, only when it changes)
#   python mkspr.py -s RAW           (made once: the sheet from UFO2.SPR's unpacked 26112 bytes)
# Also XHERO_game.png: the sheet as the fight shows it - our fighters not in focus (and the dead one) blue.
# The sheet: on top the colours (as the fight shows them), then the 136 frames 16 x 24, 16 a row: rows 0..7 - the
# races (0 our aquanauts, 1..7 the aliens; in a row: the poses, 16 each), row 8 - the deaths (128..135); each frame's
# number above it. #606060 (NONE) - no pixel (the field under it). UFO2.SPR (port/xspr.asm): a frame = 24 lines x 8
# bytes, a byte = 2 pixels (high nibble the left one), the LOGICAL colour - the game puts it on a slot of the fight's
# palette (xs_lm0); 8 = none. Our fighters not in focus are drawn with their red tones blue (xs_lf: the team's colour).
# Plain Python 3 (tilsheet.py, mktil.py beside it: the PNGs, the packer).
import os, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import tilsheet, mktil
PAL = mktil.PAL
LM0 = [0, 15, 6, 2, 10, 7, 11, 8, None, 4, 3, 5, 1, 1, 14, 7]     # logical -> the fight's slot (xspr.asm xs_lm0)
NONE = tilsheet.OUT                                                # (#606060)
SHOWN = [0, 1, 5, 2, 14, 7, 6, 9, 12, 3, 10, 4, 11]                # the band's order (5 = 15, 12 = 13 - the same)
TEAM = {3, 4, 10, 11}                                              # (our fighters not in focus: these blue / black)
NAMES = {0: 'BLACK', 1: 'WHITE', 5: 'GREY', 2: 'OLIVE', 14: 'ORANGE', 7: 'BROWN', 6: 'GREEN', 9: 'SAGE', 12: 'BLUE',
         3: 'RED', 10: 'MAROON', 4: 'B.RED', 11: 'PINK'}
def rgb(l): return NONE if l == 8 else PAL[LM0[l]]
BACK = {}
for l in SHOWN: BACK.setdefault(tuple(rgb(l)), l)
FW, FH, COLS, CW, LH, PH = 16, 24, 16, 20, 6, 30
CH = LH + FH + 4
def cell(k):
    r, c = (k // 16, k % 16) if k < 128 else (8, k - 128)
    return 4 + c * CW, PH + r * CH
LF = [0, 15, 6, 1, 9, 7, 11, 8, None, 4, 0, 9, 1, 1, 14, 7]      # (xs_lf: our fighters not in focus - the team blue)
def write_sheet(path, frames, game=False):
    W = 4 + COLS * CW; H = PH + 9 * CH
    img = [[tilsheet.BACK] * W for _ in range(H)]
    for i, l in enumerate(SHOWN + [8]):
        x = 4 + i * 22
        for y in range(4, 12): img[y][x:x + 10] = [tuple(rgb(l))] * 10
        tilsheet.text(img, x, 14, str(l) if l != 8 else 'NONE', tilsheet.NUM if l in TEAM else tilsheet.HEAD, 1)
    tilsheet.text(img, 4, 22, 'YELLOW NUMBERS - TEAM COLOURS: OUR FIGHTERS NOT IN FOCUS GET THEM BLUE', tilsheet.HEAD, 1)
    for k, f in enumerate(frames):
        x0, y0 = cell(k); tilsheet.text(img, x0, y0, str(k), tilsheet.NUM, 1)
        for y in range(FH):
            for x in range(FW):
                v = f[y][x]
                img[y0 + LH + y][x0 + x] = NONE if v == 8 else PAL[LF[v]] if game and (k < 16 or k == 128) else tuple(rgb(v))
    tilsheet.write(path, img)
def read_sheet(path):
    w, h, rows = tilsheet.png_read(path); out = []; odd = 0
    for k in range(136):
        x0, y0 = cell(k); f = []
        for y in range(FH):
            r = []
            for x in range(FW):
                p = tuple(rows[y0 + LH + y][x0 + x][:3])
                if p == NONE or p == tilsheet.GROUND: r.append(8); continue
                if p not in BACK:
                    odd += 1; p = min(BACK, key=lambda q: sum((a - b) ** 2 for a, b in zip(p, q)))
                r.append(BACK[p])
            f.append(r)
        out.append(f)
    if odd: print(odd, 'pixels of colours not in the band: the nearest taken')
    return out
def raw(frames):
    b = bytearray()
    for f in frames:
        for y in range(FH):
            for x in range(0, FW, 2): b.append(f[y][x] << 4 | f[y][x + 1])
    return bytes(b)
def unraw(d):
    return [[[d[k * 192 + y * 8 + x // 2] >> (4 if x % 2 == 0 else 0) & 15 for x in range(FW)] for y in range(FH)]
            for k in range(136)]
def main():
    if len(sys.argv) > 2 and sys.argv[1] == '-s':
        d = open(sys.argv[2], 'rb').read(); assert len(d) == 26112
        f = [[[{13: 12, 15: 5}.get(v, v) for v in r] for r in fr] for fr in unraw(d)]
        write_sheet(os.path.join(here, 'XHERO_sheet.png'), f); return
    src = sys.argv[1] if len(sys.argv) > 1 else here
    dst = sys.argv[2] if len(sys.argv) > 2 else src
    fr = read_sheet(os.path.join(src, 'XHERO_sheet.png')); d = raw(fr)
    tilsheet.save(os.path.join(dst, 'UFO2.SPR'), mktil.pk(d))
    write_sheet(os.path.join(dst, 'XHERO_game.png'), fr, True)      # (as the fight shows them: ours not in focus blue)
    print('UFO2.SPR: 136 frames')
if __name__ == '__main__': main()
