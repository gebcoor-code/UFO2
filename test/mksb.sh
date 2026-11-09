#!/bin/sh
# crew poke + LOC GO script for the current build -> sb.txt; GC -> stdout
AQU=$(grep "^l_AQU:" ../build/out/sym.txt | sed 's/.*0x0000//'); AQN=$(grep "^l_AQNAVT:" ../build/out/sym.txt | sed 's/.*0x0000//')
python3 - $AQU $AQN "$@" <<'PY'
import sys
aqu=int(sys.argv[1],16); aqn=int(sys.argv[2],16); extra=sys.argv[3:]
L=["wait 500","fill %04X 1 04"%aqu]
for i in range(4):
    rec=[i+1,0,0,50,50,50,0,50,50,255,255,255,255,0,0,0]
    for j,v in enumerate(rec): L.append("fill %04X 1 %02X"%(aqn+16*i+j,v))
L+=["at 288 22","wait 5","click","wait 400","shot B1","wait 200","shot B2","key enter 5","wait 200","shot B3"]+extra
open('sb.txt','w').write("\n".join(L)+"\n")
PY
grep G_COORD ../port/gaddr_src.inc | sed 's/.*#//'
