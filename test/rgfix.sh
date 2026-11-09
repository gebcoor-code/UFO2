#!/bin/sh
# rg2.sh OUT [DIR]: the regression set with the locations' randomness fixed (FIXA/FIXS: the same terrain each run) -
# DIR's build (default test/ds) also into ub3 (its UFO2.BTL made by it first: mkbtl), then compare with rgcmp.py
P=/tmp/claude-0/-home-claude/1aea26be-28a6-5a6e-b0ff-e540c3320bb1/scratchpad
D0=${2:-$(dirname "$0")/ds}
O=$P/$1; rm -rf $O; mkdir -p $O; cd "$(dirname "$0")"
U=$O/ub; mkdir -p $U; cp $D0/UFO2.* $U/; cp $P/mt/SEA.FNT $D0/*.PT3 $U/ 2>/dev/null; rm -f $U/UFO2.BTL $U/UFO2.PNL; cp $P/ub495/UFO2.BTL $U/
export FIXA=5DBD:00,8891:00,9084:00,8C0A:00 FIXS=5DBD
mkdir $O/mkbtl
DISKW=1 TAIL=DEBUG timeout 1500 python3 ../tools/atmsim.py $U/UFO2.COM $U $P/mkbtl.txt $O/mkbtl > $O/mkbtl.log 2>&1
for t in enc g3e pk3 sal sc1 sgx2 smv uev ufv w1 xm3; do
  D=$D0; case $t in ufv|uev|sgx2) D=$U;; esac
  rm -rf $O/$t; mkdir $O/$t
  ( TAIL=DEBUG timeout 1500 python3 ../tools/atmsim.py $D/UFO2.COM $D $P/$t.txt $O/$t > $O/$t.log 2>&1 ) &
done
wait
