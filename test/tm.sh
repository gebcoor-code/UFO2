#!/bin/sh
# timing of menu open/close: shots every 2 frames after each click
cd "$(dirname "$0")"
{ printf "wait 500\nclick\nwait 300\ngoto 205 45\nwait 5\nclick\n"; for i in $(seq 1 40); do echo "shot T$i"; echo "wait 2"; done; printf "wait 100\ngoto 120 131\nwait 5\nclick\n"; for i in $(seq 1 50); do echo "shot U$i"; echo "wait 2"; done; } > st.txt
MEM512=$MEM512 GCOORD=4609 timeout 1500 python3 ../tools/atmsim.py ds/UFO2.COM ds st.txt out >/dev/null 2>&1
python3 - <<'PY'
from PIL import Image, ImageChops
def first(p,n):
    last=Image.open('out/%s%d.png'%(p,n)).convert('RGB')
    for i in range(1,n+1):
        im=Image.open('out/%s%d.png'%(p,i)).convert('RGB').crop((0,0,256,200))
        if ImageChops.difference(im,last.crop((0,0,256,200))).getbbox() is None: return i
    return None
print('menu open: frames', 2*(first('T',40)-1) if first('T',40) else '>80', ' close:', 2*(first('U',50)-1) if first('U',50) else '>100')
PY
