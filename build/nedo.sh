#!/bin/sh
# NedoOS (Evo BaseConf): build/out_nedo/dist/ - UFO2.COM and the game's folder ufo2 for NedoOS (the CP/M build first: build.sh - its data)
#   sh build/nedo.sh [NSTAGE]
set -e
cd "$(dirname "$0")"
O=out_nedo; D=$O/dist; rm -rf $O/ufo2 $D; mkdir -p $D/ufo2
ST=${1:-9}
cd $O
${SJASM:-sjasmplus} --nologo -DSRCB -DNEDOOS -DNSTAGE=$ST $NDEF --sym=zxl_sym.txt --lst=zxl.lst ../../port/zxl.asm > asm.log 2>&1 || { grep -i "error:" asm.log; exit 1; }
if grep -qi "error:" asm.log; then grep -i "error:" asm.log; exit 1; fi
cd ..
UFO_BIN=$O UFO_OUT=$O python3 mkdat.py > /dev/null
UFO_BIN=$O python3 mkmnu.py $O/UFO2.MNU > /dev/null
# the distribution (dist/): UFO2.COM next to the folder ufo2 - all the rest (nedo.asm n_start: CHDIR there)
cp $O/ufo2.com $D/UFO2.COM; cp $O/UFO2.DAT $O/UFO2.MNU $D/ufo2/
for f in UFO2.IMG UFO2.SPR UFO2.TIL UFO2.ICO UFO2.ENC UFO2.INS UFO2.INP UFO2.INT; do cp out/$f $D/ufo2/; done
python3 mktxt.py ../about_nedo.txt $D/ufo2/ABOUT.TXT          # (NedoOS's ABOUT.TXT)
cp data/extra/*.PT3 data/extra/SEA.FNT $D/ufo2/ 2>/dev/null || true
# the instruction's viewer: UFO2DOC.COM as the game's overlay (mkdocovl.py; nedo.asm n_doc)
python3 mkdocovl.py data/extra/UFO2DOC.COM $D/ufo2/UFO2DOC.OVL > /dev/null
# CP/M's records: each file padded to 128 bytes (#1A) - NedoOS's FCB reads give A = 128 XOR the bytes read
python3 -c "
import os,sys
d=sys.argv[1]
for f in os.listdir(d):
    p=os.path.join(d,f); b=open(p,'rb').read(); n=(-len(b))%128
    if n: open(p,'wb').write(b+b'\x1a'*n)
" $D/ufo2
python3 -c "
import sys; p=sys.argv[1]; b=open(p,'rb').read(); n=(-len(b))%128
open(p,'wb').write(b+b'\x1a'*n)
" $D/UFO2.COM
ls $D $D/ufo2
