# mkins.py - UFO2.INS: the original's instruction (UFO2SRC/DATA/XINSTR.TXT, CP866) for the start menu's "3"
# (port/mnu.asm: UFO2DOC.COM shows it - SEADOC's pages, ESC: back to the menu). As build/mktxt.py: KOI-8 with the
# Cyrillic cases swapped, CR LF, ^Z. The original's own lines kept (42 a line); the paragraph about its pictures
# (keys 1..4, E - its viewer's) said for this one; the text past the signature (the author's notes) left out.
# Its pictures beside it: UFO2.INP (0.61.1).
#   python3 mkins.py [OUT]
import os, re, sys
D = os.path.dirname(os.path.abspath(__file__))
s = open(os.path.join(D, '../UFO2SRC/DATA/XINSTR.TXT'), 'rb').read().decode('cp866').replace('\r\n', '\n')
end = s.index('С уважением, ВЯЧЕСЛАВ МЕДНОНОГОВ'); end = s.index('\n', end) + 1
s = s[:end]
old = ('  Описание включает в себя несколько иллю-\nстраций, поэтому, если вы видите ссылку на \n'
       'какой-либо рисунок, нажмите соответствую-\nщую клавишу: 1,2,3 или 4. Позиции рисунка \n'
       'указаны в тексте в круглых скобках. Для \nвозвращения в игру нажмите Е.\n')
assert old in s, 'XINSTR.TXT: the pictures\' paragraph not found'
new = ('  Описание включает в себя несколько иллю-\nстраций - они показаны в тексте, там, где\n'
       'на них ссылки (позиции на рисунке - числа\nв круглых скобках). Листать - любая кла-\n'
       'виша, вернуться в меню - ESC. Управление\nв версии для ATM Turbo 2+ - в ABOUT.TXT.\n')
s = s.replace(old, new).rstrip('\n') + '\n'
# (0.64.0) the text on the whole screen (UFO2DOC: 80 a line - 79 here, the 80th would wrap): the paragraphs (a line
# with 2 spaces first, the next ones with none) joined again - the words' "-" at a line's end gone (not before a part
# as -либо, -то, -нибудь, -ка, or after a word part with capitals / digits), wrapped at 79; the lines with more
# spaces first (titles) centred in 80; empty lines kept.
W = 79
KEEP = ('либо', 'нибудь', 'то', 'ка', 'таки')
KEEPL = ('эхо', 'кое')                                  # (left parts kept: эхо-радар, кое-что)
def join(a, b):
    if a.endswith('-') and len(a) > 1 and a[-2].isalpha() and b[:1].isalpha():
        w = b.split()[0]; left = re.split(r'\W', a.split()[-1][:-1])[-1]
        if any(w.lower().startswith(k) and not w[len(k):len(k)+1].isalpha() for k in KEEP) or any(c.isupper() or c.isdigit() for c in left[1:]) or left.lower() in KEEPL:
            return a + b
        return a[:-1] + b
    return a + ' ' + b
L = s.split('\n'); out = []; k = 0
start = L.index(new.split('\n')[-2]) + 1        # (the paragraph about the pictures)
refs = {}
for n in (1, 2, 3, 4):
    i0 = next(q for q in range(start, len(L)) if ('рис. %d' % n) in L[q]); refs.setdefault(i0, []).append(n)
pend = []
while k < len(L):
    t = L[k]
    if not t.strip(): out.append(''); k += 1; continue
    ind = len(t) - len(t.lstrip(' '))
    if ind >= 3 or t.strip().startswith('***'):
        out.append(t.strip().center(80).rstrip()); k += 1; continue
    par = t.strip(); first = k; k += 1
    while k < len(L) and L[k].strip() and not L[k].startswith(' '):
        par = join(par.rstrip(), L[k].strip()); k += 1
    # (a list's lines - "(1) ...", "- ..." - each a paragraph of its own already: they start with 2 spaces)
    line = '  ' if ind else ''
    words = par.split(' ')
    cur = line
    for w in words:
        if not w: continue
        if len(cur) + (1 if cur.strip() else 0) + len(w) > W:
            out.append(cur.rstrip()); cur = w
        else:
            cur = (cur + ' ' + w) if cur.strip() else cur + w
    out.append(cur.rstrip())
    for q in range(first, k):
        for n in refs.get(q, []): pend.append(n)
    if pend:                                    # the pictures referred to in it: after it
        for n in pend: out += [chr(0x0E + n)] + [''] * 9
        pend = []
# (0.61.1; 0.64.0 - in the text) the pictures: codes #0E (XN5 - the instruction's title, first), #0F..#12 (XN1..XN4:
# after the paragraph with its "рис. N"), a line of their own and 9 empty ones - the picture's 10 rows (port/mnu.asm
# dh_hk shows them: UFO2.INP)
s = '\n'.join([chr(0x0E)] + [''] * 9 + out)
s = s.replace('ё', 'е').replace('Ё', 'Е')
s = ''.join(c.swapcase() if 'А' <= c <= 'я' else c for c in s)
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, 'out/UFO2.INS')
open(out, 'wb').write(s.replace('\n', '\r\n').encode('koi8-r') + b'\x1a')
# UFO2.INP: XN5, XN1..XN4 (UFO2SRC/IMAGES/*.TIF: 256x192, 1 bit; white - the ink) as 256x80 (0.64.0: 640x200's
# points are 2.4 times as high as wide - the proportions kept: each line - 2.4 of the original's, a point set if 1/3
# of them is) - 32 bytes a line, bit 7 the left; XN5's lines about the original viewer's keys (Q, A, E, 1..4) left out
from PIL import Image
inp = bytearray()
for n in ('XN5', 'XN1', 'XN2', 'XN3', 'XN4'):
    im = Image.open(os.path.join(D, '../UFO2SRC/IMAGES/%s.TIF' % n)).convert('L'); assert im.size == (256, 192)
    px = im.load()
    def on(x, y): return px[x, y] > 127 and not (n == 'XN5' and 148 <= y <= 186)
    for y in range(80):
        y0, y1 = y * 192 / 80, (y + 1) * 192 / 80
        for xb in range(32):
            b = 0
            for k in range(8):
                x = xb * 8 + k; v = 0.0; yy = int(y0)
                while yy < y1:
                    if on(x, yy): v += min(yy + 1, y1) - max(yy, y0)
                    yy += 1
                if v / (y1 - y0) >= 0.34: b |= 0x80 >> k
            inp.append(b)
open(os.path.join(os.path.dirname(out), 'UFO2.INP'), 'wb').write(inp)
