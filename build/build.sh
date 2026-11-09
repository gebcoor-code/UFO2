#!/bin/sh
# UFO-2 from the sources for ATM CP/M: sources -> sjasmplus -> UFO2.SNA (+ UFO2.COM layer for this build)
set -e
cd "$(dirname "$0")"
mkdir -p out
rm -rf src; python3 conv.py ../UFO2SRC/ASM80 src XCOM.A80 >/dev/null
python3 mods.py src
python3 wide.py src
${SJASM:-sjasmplus} --nologo --lst=out/main.lst --sym=out/sym.txt main.asm > out/asm.log 2>&1; grep -E "error|Errors" out/asm.log
if grep -q "Negative BLOCK" out/asm.log; then echo "RESIDENT CODE OVERFLOW (#8F3F)"; exit 1; fi
python3 gen_gaddr.py >/dev/null
python3 mksna.py
python3 mktxr.py >/dev/null                      # port/txrb.bin: the text recognition's table (the game's font)
PANEL_OFF=1 python3 ../tools/mkpanel2.py out/pnl_base.bin >/dev/null   # (the game's look: mkpnl.py's base)
python3 ../tools/mkpanel2.py out/UFO2.PNL
python3 mktil.py data/til out >/dev/null
# (0.67.8) UFO2.TIL: til tools 0.67.8's (data/extra/UFO2.TIL - its sources are not in this tree; the code 0.67.6..0.67.8 -
# enl.asm te_flr, xpnt.asm pl_fl - is made for it)
if [ -f data/extra/UFO2.TIL ]; then cp data/extra/UFO2.TIL out/UFO2.TIL; fi
python3 mkico.py data/ico/AI out >/dev/null     # UFO2.ICO: the items' / signs' pictures (data/ico/AI)     # UFO2.TIL: the tiles' colours (data/til/AI: the sets' PNGs)
# UFO2.ENC: the encyclopedia's pictures (data/enc/AI; slow - only when they or mkenc.py changed)
if [ ! -f out/UFO2.ENC ] || [ mkenc.py -nt out/UFO2.ENC ] || [ -n "$(find data/enc/AI -newer out/UFO2.ENC)" ]; then python3 mkenc.py data/enc/AI out >/dev/null; fi
python3 mkmsg.py >/dev/null                    # port/encmsg.bin: the picture when UFO2.ENC is not found
cd ../port && ${SJASM:-sjasmplus} --nologo -DSRCB --sym=../build/out/zxl_sym.txt zxl.asm > /tmp/zxl.log 2>&1; grep -E "error:|code end" /tmp/zxl.log; if grep -q "error:" /tmp/zxl.log; then exit 1; fi
cp ufo2.com ../build/out/UFO2.COM
python3 ../build/mkdat.py
python3 ../build/mkimg.py
python3 ../build/mktxt.py
python3 ../build/mkins.py ../build/out/UFO2.INS                              # UFO2.INS: the instruction (the menu's "3")
python3 ../build/mkint.py ../build/out/UFO2.INT                              # UFO2.INT: the intro (the menu's "1"; data/intro.bin)
python3 ../build/mkspr.py ../build/data/spr ../build/out >/dev/null     # UFO2.SPR: the fighters / aliens (data/spr/XHERO_sheet.png)
python3 ../build/mkmnu.py ../build/out/UFO2.MNU                              # UFO2.MNU: the start menu (its code, its screens)
# NedoOS (Evo BaseConf): build/out_nedo/dist/ - UFO2.COM and its folder ufo2 (build/nedo.sh, -DNEDOOS)
sh ../build/nedo.sh > /dev/null
