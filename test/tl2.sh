#!/bin/sh
# tl2.sh SCRIPT: for each click: release frame, last mk_all after it, the first flip after that
cd "$(dirname "$0")/../port"; ${SJASM:-sjasmplus} --nologo -DSRCB --sym=/tmp/zs2.txt zxl.asm >/dev/null 2>&1
cd ../test
MA=$(grep "^mk_all:" /tmp/zs2.txt | sed 's/.*0x0000//'); DF=$(grep "^do_flip:" /tmp/claude-0/zs2.txt | sed 's/.*0x0000//')
BPLOG=$MA,$DF GCOORD=4609 timeout 900 python3 ../tools/atmsim.py ds/UFO2.COM ds $1 out 2>&1 | grep -a "^hit\|^frames" | python3 -c "
import sys
ev=[]
for l in sys.stdin:
    f=l.split()
    if f[0]=='frames': ev.append(('L',int(f[1])))
    else: ev.append(('A' if f[1]=='$MA' else 'F', int(f[3])))
# for each log (click), take ALL events after it before next log; flip after last ALL
logs=[i for i,e in enumerate(ev) if e[0]=='L']
for k,i in enumerate(logs):
    end=logs[k+1] if k+1<len(logs) else len(ev)
    seg=ev[i+1:end]; alls=[f for t,f in seg if t=='A']
    if not alls: print('click',ev[i][1],'no mk_all'); continue
    la=alls[-1]; fl=[f for t,f in seg if t=='F' and f>la]
    print('click@%d: first mk_all +%d, last +%d, flip +%d' % (ev[i][1], alls[0]-ev[i][1], la-ev[i][1], (fl[0]-ev[i][1]) if fl else -1))
"
