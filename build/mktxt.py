# about.txt (UTF-8) -> out/ABOUT.TXT for CP/M on Turbo 2+ (or: mktxt.py in out - nedo.sh: about_nedo.txt): KOI-8 with the Cyrillic cases swapped (as SEA.DOC:
# lowercase at #E0..#FF), CR LF, ^Z at the end
import os
D = os.path.dirname(os.path.abspath(__file__))
import sys
src, dst = (sys.argv[1], sys.argv[2]) if len(sys.argv) > 2 else (os.path.join(D, '../about.txt'), os.path.join(D, 'out/ABOUT.TXT'))
s = open(src, encoding='utf-8').read().replace('ё', 'е').replace('Ё', 'Е')
s = ''.join(c.swapcase() if 'А' <= c <= 'я' else c for c in s)
open(dst, 'wb').write(s.replace('\n', '\r\n').encode('koi8-r') + b'\x1a')
