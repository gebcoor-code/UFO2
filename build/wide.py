# The battlefield buffer's geometry as symbols (applied to src/*.asm after mods.py).
#   l_BDSC  - the battlefield buffer (was l_DSCR = #9000, also used as a scratch area elsewhere: that stays)
#   l_BW    - its bytes per line (was 32), l_BCELL - cells per half-row drawn (was 15)
# WIDE=0: the original values (the build must not change); WIDE=1: the layer's wide field (see port/NOTES)
import sys, os
D = sys.argv[1] if len(sys.argv) > 1 else 'src'
WIDE = int(os.environ.get('WIDE', '1'))
def mod(fn, old, new, count=1):
    p = os.path.join(D, fn); s = open(p, 'rb').read().decode('cp866')
    n = s.count(old)
    if n != count: raise SystemExit('wide.py %s: %r found %d times (want %d)' % (fn, old[:70], n, count))
    s = s.replace(old, new); open(p, 'wb').write(s.encode('cp866'))

# l_BROWS: double half-rows drawn (ALLSP), l_VISH: lines shown (from line 32), l_FROWS: character rows of the field
# (the map cursor's BY 1..l_FROWS); l_PROW: the panel's first BY (17 on the ZX; the layer's panel coordinates)
if WIDE:
    GEO = 'l_BDSC\tEQU #0F40\nl_BW\tEQU 44\nl_BCELL\tEQU 21\nl_BROWS\tEQU 29\nl_VISH\tEQU 200\nl_FROWS\tEQU 25\nl_PROW\tEQU 26\n'
else:
    GEO = 'l_BDSC\tEQU l_DSCR\nl_BW\tEQU 32\nl_BCELL\tEQU 15\nl_BROWS\tEQU 20\nl_VISH\tEQU 128\nl_FROWS\tEQU 16\nl_PROW\tEQU 17\n'
mod('xlib.asm', 'l_DSCR\tEQU #9000\n', 'l_DSCR\tEQU #9000\n' + GEO)

# ---- xlib: scrolls, sprite strides, the whole field
# right: everything 8 pixels to the left (lines 32..159), the new column at the right edge
mod('xlib.asm', '\tLD DE,l_DSCR+1024\t;скролл вправо\n\tLD HL,(l_DSCR+1024)+1\n\tLD BC,4095\n',
    '\tLD DE,l_BDSC+(32*l_BW)\t;скролл вправо\n\tLD HL,l_BDSC+(32*l_BW)+1\n\tLD BC,(l_VISH*l_BW)-1\n')
mod('xlib.asm', '\tLD A,14\n\tADD A,E\n\tLD E,A\n\tLD A,-14\n\tADD A,D\n',
    '\tLD A,l_BCELL-1\n\tADD A,E\n\tLD E,A\n\tLD A,1-l_BCELL\n\tADD A,D\n')
mod('xlib.asm', '\tLD HL,(l_DSCR+29)+128\n', '\tLD HL,l_BDSC+(2*l_BCELL)-1+(4*l_BW)\n')
mod('xlib.asm', '\tLD HL,l_DSCR+29\n', '\tLD HL,l_BDSC+(2*l_BCELL)-1\n')
# left
mod('xlib.asm', '\tLD DE,(l_DSCR+6143)-1024\t;Скролл влево\n\tLD HL,(l_DSCR+6142)-1024\n\tLD BC,4095\n',
    '\tLD DE,l_BDSC+((32+l_VISH)*l_BW)-1\t;Скролл влево\n\tLD HL,l_BDSC+((32+l_VISH)*l_BW)-2\n\tLD BC,(l_VISH*l_BW)-1\n')
mod('xlib.asm', '\tLD HL,(l_DSCR+128)+2\n\tJR l_LL1\nl_LL0\tLD HL,l_DSCR+2\n',
    '\tLD HL,l_BDSC+(4*l_BW)+2\n\tJR l_LL1\nl_LL0\tLD HL,l_BDSC+2\n')
mod('xlib.asm', 'l_LL_2\tLD DE,128\n', 'l_LL_2\tLD DE,4*l_BW\n')
mod('xlib.asm', 'l_LL_3\tLD DE,128\n', 'l_LL_3\tLD DE,4*l_BW\n')
# down / up: 8 lines
mod('xlib.asm', '\tLD DE,l_DSCR+1024\t;скролл вниз\n\tLD HL,(l_DSCR+256)+1024\n\tLD BC,4096-256\n',
    '\tLD DE,l_BDSC+(32*l_BW)\t;скролл вниз\n\tLD HL,l_BDSC+(40*l_BW)\n\tLD BC,(l_VISH-8)*l_BW\n')
mod('xlib.asm', '\tLD HL,((l_DSCR+4096)+768)+1\n', '\tLD HL,l_BDSC+((24+l_VISH)*l_BW)+1\n')
mod('xlib.asm', '\tLD DE,(l_DSCR+6143)-1024\t;скролл вверх\n\tLD HL,((l_DSCR+6143)-256)-1024\n\tLD BC,4096-256\n',
    '\tLD DE,l_BDSC+((32+l_VISH)*l_BW)-1\t;скролл вверх\n\tLD HL,l_BDSC+((24+l_VISH)*l_BW)-1\n\tLD BC,(l_VISH-8)*l_BW\n')
mod('xlib.asm', '\tLD HL,(l_DSCR+1024)+1\nl_UL_', '\tLD HL,l_BDSC+(32*l_BW)+1\nl_UL_')
mod('xlib.asm', '\tLD HL,(l_UDHL)\n\tLD DE,128\n\tADD HL,DE\n', '\tLD HL,(l_UDHL)\n\tLD DE,4*l_BW\n\tADD HL,DE\n')
mod('xlib.asm', 'l_UDL\tLD B,15\n', 'l_UDL\tLD B,l_BCELL\n')
mod('xlib.asm', 'l_UDL2\tLD B,15\n', 'l_UDL2\tLD B,l_BCELL\n')
# sprite strides
mod('xlib.asm', '\tADD A,31\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_MS20\n', '\tADD A,l_BW-1\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_MS20\n')
mod('xlib.asm', '\tADD A,32\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_LS20\n', '\tADD A,l_BW\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_LS20\n')
mod('xlib.asm', '\tADD A,32\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_RS20\n', '\tADD A,l_BW\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_RS20\n')
# the whole field
mod('xlib.asm', 'l_ALLSP\tLD HL,(l_DSCR+128)+2\n', 'l_ALLSP\tLD HL,l_BDSC+(4*l_BW)+2\n')
mod('xlib.asm', 'l_AP2\tLD B,15\n', 'l_AP2\tLD B,l_BCELL\n')
mod('xlib.asm', '\tLD (l_TX),DE\n\tLD C,20\nl_AP2', '\tLD (l_TX),DE\n\tLD C,l_BROWS\nl_AP2')
mod('xlib.asm', 'l_LL1\tLD (l_TX),DE\n\tLD B,20\n', 'l_LL1\tLD (l_TX),DE\n\tLD B,l_BROWS\n')
# the bottom strip after a scroll down: its first map row (X0 + 15 for 128 lines; one more per 8 lines)
mod('xlib.asm', 'l_DLN\tLD HL,l_X0\n\tLD A,#F\n\tADD A,(HL)\n\tLD (l_TTX),A\n\tINC HL\n\tLD A,#F\n', 'l_DLN\tLD HL,l_X0\n\tLD A,15+((l_VISH-128)/8)\n\tADD A,(HL)\n\tLD (l_TTX),A\n\tINC HL\n\tLD A,15+((l_VISH-128)/8)\n')
mod('xlib.asm', '\tPUSH DE\n\tLD B,15\nl_AP4', '\tPUSH DE\n\tLD B,l_BCELL\nl_AP4')
mod('xlib.asm', '\tLD DE,(128-30)-1\n', '\tLD DE,(4*l_BW)-(2*l_BCELL)-1\n')
mod('xlib.asm', '\tLD DE,(128-30)+1\n', '\tLD DE,(4*l_BW)-(2*l_BCELL)+1\n')

# ---- xlim: 3D cursor, in-view test, cell -> offset, sprites in front, hero marker, hero image, its background
mod('xlim.asm', 'l_PF0\tLDI\n\tLDI\n\tLD A,30\n', 'l_PF0\tLDI\n\tLDI\n\tLD A,l_BW-2\n')
mod('xlim.asm', 'l_PTN0\tLDI\n\tLDI\n\tLD A,30\n', 'l_PTN0\tLDI\n\tLDI\n\tLD A,l_BW-2\n')
mod('xlim.asm', '\tLD BC,l_DSCR+129\n', '\tLD BC,l_BDSC+(4*l_BW)+1\n', 2)
mod('xlim.asm', '\tLD DE,l_DSCR+129\n', '\tLD DE,l_BDSC+(4*l_BW)+1\n', 2)
mod('xlim.asm', '\tLD D,A\n\tCP 29\n\tRET\n', '\tLD D,A\n\tCP (2*l_BCELL)-1\n\tRET\n')          # INFR: columns
mod('xlim.asm', '\tADD A,L\n\tLD E,A\n\tCP 39\n\tRET NC\n', '\tADD A,L\n\tLD E,A\n\tCP (2*l_BROWS)-1\n\tRET NC\n')   # INFR: half-rows
if WIDE:
    # offset = row * 4 lines + column (BC kept)
    mod('xlim.asm', 'l_XYHL\tXOR A\n\tLD H,E\n\tSRL H\n\tRRA\n\tADD A,D\n\tLD L,A\n\tRET\n', 'l_XYHL\tJP LAY_XYHL\n')
mod('xlim.asm', '\tLD HL,(l_TXT)\n\tINC L\n\tCALL l_LSPB\n', '\tLD HL,(l_TXT)\n\tINC HL\n\tCALL l_LSPB\n')
mod('xlim.asm', 'l_PX2\tLD HL,(l_TXT)\n\tLD DE,128\n', 'l_PX2\tLD HL,(l_TXT)\n\tLD DE,4*l_BW\n')
mod('xlim.asm', '\tLD HL,(l_TXT)\n\tINC L\n\tCALL l_ASP\n', '\tLD HL,(l_TXT)\n\tINC HL\n\tCALL l_ASP\n')
mod('xlim.asm', '\tRET Z\n\tLD HL,(l_TXT)\n\tLD DE,128\n', '\tRET Z\n\tLD HL,(l_TXT)\n\tLD DE,4*l_BW\n')
mod('xlim.asm', '\tLD BC,l_DSCR+193\n', '\tLD BC,l_BDSC+(6*l_BW)+1\n')
mod('xlim.asm', '\tDJNZ l_CMR0\n\tLD BC,30\n', '\tDJNZ l_CMR0\n\tLD BC,l_BW-2\n')
mod('xlim.asm', 'l_HE1\tCALL 15635\n\tCALL 1010\n\tLD A,30\n', 'l_HE1\tCALL 15635\n\tCALL 1010\n\tLD A,l_BW-2\n')
mod('xlim.asm', '\tLDI\n\tLDI\n\tLDI\n\tLD BC,29\n\tADD HL,BC\n', '\tLDI\n\tLDI\n\tLDI\n\tLD BC,l_BW-3\n\tADD HL,BC\n')
mod('xmain.asm', '\tEX DE,HL\n\tLD BC,29\n\tADD HL,BC\n', '\tEX DE,HL\n\tLD BC,l_BW-3\n\tADD HL,BC\n')
mod('xlim.asm', 'l_xDHL\tDEFW -33,-65,-97,-1,-1,-2,31,63,95,64,128,192\n\tDEFW 32,64,96,0,1,1,-32,-64,-96,-64,-128,-192\n',
    'l_xDHL\tDEFW -l_BW-1,-2*l_BW-1,-3*l_BW-1,-1,-1,-2,l_BW-1,2*l_BW-1,3*l_BW-1,2*l_BW,4*l_BW,6*l_BW\n'
    '\tDEFW l_BW,2*l_BW,3*l_BW,0,1,1,-l_BW,-2*l_BW,-3*l_BW,-2*l_BW,-4*l_BW,-6*l_BW\n')
mod('xlim.asm', '\tLD BC,l_DSCR+257\n', '\tLD BC,l_BDSC+(8*l_BW)+1\n')
# CURHER: the selected aquanaut's frame - its lower corners 22 lines below (after the upper 3)
mod('xlim.asm', '\tCALL l_CMR_\n\tLD BC,704\n', '\tCALL l_CMR_\n\tLD BC,22*l_BW\n')
# ---- xlin: bullets, explosion skulls, flashes
mod('xlin.asm', 'l_PF_HL\tDEFW 0,64,63,128\n', 'l_PF_HL\tDEFW 0,2*l_BW,(2*l_BW)-1,4*l_BW\n')
mod('xlin.asm', '\tLD DE,l_DSCR+257\n', '\tLD DE,l_BDSC+(8*l_BW)+1\n')
mod('xlin.asm', '\tLD BC,l_DSCR+257\n', '\tLD BC,l_BDSC+(8*l_BW)+1\n', 2)
# ---- xlik: aliens moving
mod('xlik.asm', '\tLD BC,l_DSCR+257\n', '\tLD BC,l_BDSC+(8*l_BW)+1\n')

if WIDE:
    # a tile's empty top lines (vSIZE): skipped as lines of l_BW = 44 bytes (L = 8 v: 5.5 L; was A*32)
    mod('xlib.asm', '\tLD L,A\n\tRRCA\n\tADD A,E\n\tLD E,A\n\tADD HL,HL\n\tADD HL,HL\n\tLD A,(BC)\n\tPOP BC\n',
        '\tLD L,A\n\tRRCA\n\tADD A,E\n\tLD E,A\n\tPUSH DE\n\tLD D,H\n\tLD E,L\n\tADD HL,HL\n\tADD HL,HL\n\tADD HL,DE\n\tSRL D\n\tRR E\n\tADD HL,DE\n\tPOP DE\n\tLD A,(BC)\n\tPOP BC\n')
    # the layer's new vectors
    mod('xcom.asm', 'LAY_MKOFF\tEQU #0153\n', 'LAY_MKOFF\tEQU #0153\nLAY_XYHL\tEQU #0156\nLAY_BXY\tEQU #0159\nLAY_BAT\tEQU #015B\nLAY_RXE\tEQU #015E\n')
    # a location fight starts: the layer's wide battlefield (W0 #1C00..#39FF is the field from now on)
    mod('xlie.asm', '\tDI\n\tCALL LAY_GEO\n\tCALL l_NOKEY\n', '\tDI\n\tCALL LAY_BAT\n\tCALL l_NOKEY\n')
    # the map cursor's character cell: from the layer (the field is wider than the game's 8-bit X)
    mod('xlim.asm', '\tPUSH AF\n\tLD A,(l_MX)\n\tAND %11111000\n\tRRCA\n\tRRCA\n\tRRCA\n\tLD L,A\n\tLD A,(l_MY)\n\tAND %11111000\n\tRRCA\n\tRRCA\n\tRRCA\n\tLD H,A\n\tLD (l_BX),HL\n\tPOP AF\n\tRET\n',
        '\tLD HL,(LAY_BXY)\n\tLD (l_BX),HL\n\tRET\n')
    # zones: the field (rows 1..16) is wider than the panel's 29 columns
    mod('xlim.asm', '\tLD A,L\n\tOR A\n\tRET Z\n\tCP 29\n\tRET NC\n\tLD A,H\n\tOR A\n\tRET Z\n\tCP 23\n\tRET NC\n\tCP 17\n\tJR NC,l_GZ1\n\tXOR A\n\tLD (DE),A\n\tRET\n',
        '\tLD A,L\n\tOR A\n\tRET Z\n\tLD A,H\n\tOR A\n\tRET Z\n\tCP l_FROWS+1\n\tJR NC,l_GZ0\n\tLD A,L\n\tCP (2*l_BCELL)-1\n\tRET NC\n\tXOR A\n\tLD (DE),A\n\tRET\n'
        'l_GZ0\tCP l_PROW+6\n\tRET NC\n\tLD A,L\n\tCP 29\n\tRET NC\n\tJR l_GZ1\n')
    # the panel's rows: the layer reports them from l_PROW (the field has l_FROWS rows)
    mod('xlim.asm', 'l_GZ1\tLD A,L\n\tCP 13\n\tJR C,l_GZ2\n\tLD A,H\n\tCP 19\n', 'l_GZ1\tLD A,L\n\tCP 13\n\tJR C,l_GZ2\n\tLD A,H\n\tCP l_PROW+2\n')
    mod('xlim.asm', 'l_GZ2\tDEC L\n\tLD A,H\n\tSUB 17\n', 'l_GZ2\tDEC L\n\tLD A,H\n\tSUB l_PROW\n')
    mod('xlim.asm', '\tLD A,(l_BY)\n\tOR A\n\tJR Z,l_BO1\n\tCP 17\n\tJR NC,l_BO1\n', '\tLD A,(l_BY)\n\tOR A\n\tJR Z,l_BO1\n\tCP l_FROWS+1\n\tJR NC,l_BO1\n')
    mod('xlim.asm', '\tJR Z,l_MROTAT\n\tCP 23\n\tLD HL,l_DRT\n', '\tJR Z,l_MROTAT\n\tCP l_PROW+6\n\tLD HL,l_DRT\n')
    # the map cursor inside the field: wider; scroll right at the new right edge
    mod('xlim.asm', '\tOR A\n\tJR Z,l_BO1\n\tCP 29\n\tJR NC,l_BO1\n', '\tOR A\n\tJR Z,l_BO1\n\tCP (2*l_BCELL)-1\n\tJR NC,l_BO1\n')
    mod('xlim.asm', 'l_RA1\tCP 31\n', 'l_RA1\tLD HL,LAY_RXE\n\tCP (HL)\n')        # the right edge: the layer's (39 wide EGA, 31 ZX screen)
    # centring: the middle of the wider view (row 18, column 18)
    mod('xlim.asm', 'l_CENTRg\tLD A,D\n\tSUB 2\n\tLD D,A\n\tLD A,E\n\tSUB 16', 'l_CENTRg\tLD A,D\n\tSUB 4\n\tLD D,A\n\tLD A,E\n\tSUB 24')
    # the names: LAY_NAME after NWRDM printed one into DSCR (PANELM); all the crew's at a fight's start (NAMPRE)
    mod('xcom.asm', 'LAY_RXE\tEQU #015E\n', 'LAY_RXE\tEQU #015E\nLAY_NAME\tEQU #015F\n')
    # PANELM's name part as a routine (PNAM: HL = the man -> HL + 8), LAY_NAME after it printed the name into DSCR
    mod('xcom.asm', 'LAY_NAME\tEQU #015F\n', 'LAY_NAME\tEQU #015F\nLAY_NAMP\tEQU #0162\n')
    # the fight's SAVE / LOAD: also to / from the disk (UFO2.BTL; LAY_DSK: A = 0 after the RAM save, 1 before the RAM load)
    mod('xcom.asm', 'LAY_NAMP\tEQU #0162\n', 'LAY_NAMP\tEQU #0162\nLAY_DSK\tEQU #0165\nLAY_BDC\tEQU #0168\n')
    # a menu line inverted in DSCR (ONLINE / OFLINE): the layer's MRK1 bands compared again (it skips the places it saw)
    mod('xlic.asm', '\tDEC C\n\tJR NZ,l_ONOF1\n\tRET\n', '\tDEC C\n\tJR NZ,l_ONOF1\n\tJP l_ONOFX\n')   # ONOFL: the inverted line itself through LAY_BAND (mods.py l_ONOFX: MRK1's bands around the mouse missed it when the mouse moved far in a poll - a second bar left)
    mod('xlin.asm', '\tDEFW l_BYE,l_C_SAVE,l_C_LOAD,l_X_MAN\n', '\tDEFW l_BYE,l_CSAVd,l_CLODd,l_X_MAN\n')
    mod('xmain.asm', '\tDS #8F80-$,0\n', 'l_CSAVd\tCALL l_C_SAVE\n\tXOR A\n\tJP LAY_DSK\nl_CLODd\tLD A,1\n\tCALL LAY_DSK\n\tJP l_C_LOAD\n\tDS #8F80-$,0\n')
    mod('xlim.asm', '''\tCALL l_STD
\tLD A,#FF
\tCALL l_SIMBAR
\tPOP HL
\tINC L
\tINC L
\tINC L
\tINC L
\tLD A,(HL)
\tINC L
\tINC L
\tINC L
\tINC L
\tOR A
\tJR Z,l_LM78
\tADD A,20
\tJR l_LM79
l_LM78\tLD A,(HL)
\tDEC A
\tLD BC,l_NAMES
\tLD (l__words),BC
l_LM79\tPUSH HL
\tLD HL,6
\tLD (l_SX),HL
\tCALL l_NWRDM
\tLD HL,l_WORDS
\tLD (l__words),HL
\tCALL l_STS
''', '''\tPOP HL
\tCALL l_PNAM
\tPUSH HL
\tCALL l_STS
''')
    mod('xlim.asm', 'l_PANELG\t', '''l_PNAM\tPUSH HL	;the name (HL = the man; -> HL + 8) into DSCR, then LAY_NAME
\tCALL l_STD
\tLD HL,#5
\tLD BC,#1401
\tLD A,#FF
\tCALL l_SIMBAR
\tPOP HL
\tINC L
\tINC L
\tINC L
\tINC L
\tLD A,(HL)
\tINC L
\tINC L
\tINC L
\tINC L
\tOR A
\tJR Z,l_LM78
\tADD A,20
\tJR l_LM79
l_LM78\tLD A,(HL)
\tDEC A
\tLD BC,l_NAMES
\tLD (l__words),BC
l_LM79\tPUSH HL
\tLD HL,6
\tLD (l_SX),HL
\tPUSH AF
\tCALL l_NWRDM
\tPOP AF
\tCALL LAY_NAME
\tLD HL,l_WORDS
\tLD (l__words),HL
\tPOP HL
\tRET

l_PANELG\t''')
    # the aliens' turn's line (ALINXT: "ход пришельцев" into DSCR's row 0): the layer's name bar shows it (LAY_NAME)
    mod('xlik.asm', '\tLD A,202\n\tCALL l_NWRDM\n\tCALL l_S_COPY\n', '\tLD A,202\n\tPUSH AF\n\tCALL l_NWRDM\n\tPOP AF\n\tCALL LAY_NAME\n\tCALL l_S_COPY\n')
    # all the crew's names at a fight's start (the layer: PNAM for each)
    mod('xlim.asm', '\tCALL l_ALLSPF\n\tCALL l_PANELM\n', '\tCALL l_ALLSPF\n\tCALL LAY_NAMP\n\tCALL l_PANELM\n')
print('wide ok', WIDE)
