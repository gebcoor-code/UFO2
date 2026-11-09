# Changes of the converted UFO-2 sources for the ATM CP/M build (applied to src/*.asm after conv.py).
# The CP/M layer (UFO2.COM) has a vector table at #0103: DREAD, DWRITE, MOUSE, YN, ALEXQ, VIEW.
import sys, os, re
D = sys.argv[1] if len(sys.argv) > 1 else 'src'
def mod(fn, old, new, count=1):
    p = os.path.join(D, fn); s = open(p, 'rb').read().decode('cp866')
    n = s.count(old)
    if n != count: raise SystemExit('%s: %r found %d times (want %d)' % (fn, old[:60], n, count))
    s = s.replace(old, new); open(p, 'wb').write(s.encode('cp866'))

def cut(fn, a, b, new):                 # the text from a (included) up to b (excluded) -> new
    p = os.path.join(D, fn); s = open(p, 'rb').read().decode('cp866')
    i = s.index(a); j = s.index(b, i); s = s[:i] + new + s[j:]; open(p, 'wb').write(s.encode('cp866'))

VEC = '''LAY_DREAD	EQU #0103
LAY_DWRITE	EQU #0106
LAY_MOUSE	EQU #0109
LAY_YN	EQU #010C
LAY_ALEXQ	EQU #010F
LAY_VIEW	EQU #0112
LAY_GEO	EQU #0115
LAY_ZXM	EQU #0118
LAY_EGA	EQU #011B
LAY_MKHL	EQU #011C
LAY_MKALL	EQU #011F
LAY_MKATR	EQU #0122
LAY_MKLN	EQU #0125
LAY_MKSC	EQU #0128
LAY_MKSIM	EQU #012B
LAY_MKSPR	EQU #012E
LAY_MKPSC	EQU #0131
LAY_SCRL	EQU #0134
LAY_SCRE	EQU #0137
LAY_BAND	EQU #013A
LAY_FD2	EQU #013D
LAY_FD1	EQU #0140
LAY_FDC	EQU #0143
LAY_FALL	EQU #0146
LAY_FPAD	EQU #0149
LAY_OUTD	EQU #014C
LAY_PROG	EQU #014F
LAY_TUINF	EQU #0152
LAY_MKOFF	EQU #0153
LAY_PMP	EQU #3DE0
'''
mod('xcom.asm', '\tINCLUDE "xpage.asm"', VEC + '\tINCLUDE "xpage.asm"')

# disk: the release's (cracked) logic on TR-DOS sectors of 256 bytes; the layer reads them from UFO2.DAT in RAM
mod('xiod.asm', 'l_READ1\tCALL l_D_READ\n', 'l_READ1\tJP l_D_READ\n\tCALL l_D_READ\n')
mod('xiod.asm', 'l_TR000\tCALL l_TR0\n', 'l_TR000\tRET\n\tCALL l_TR0\n')
mod('xiod.asm', 'l_D_WRIT\tDI\n', 'l_D_WRIT\tJP LAY_DWRITE\n\tDI\n')
mod('xiod.asm', 'l_D_READ\tDI\t;E-sec,D-trk,B-sec.num,HL-mem.adr\n', 'l_D_READ\tJP LAY_DREAD\t;E-sec 1..16, D-trk (TR-DOS), B-secs, HL\n\tDI\n')
# L_DSCR (the saved game from the disk): the source's D_READ added 4 pages a sector (then DEC H x 3); the layer's adds 1
mod('xlic.asm', '\tJR C,l_L_D_ER\n\tDEC H\n\tDEC H\n\tDEC H\n\tDJNZ l_L_D1\n', '\tJR C,l_L_D_ER\n\tDJNZ l_L_D1\n')
# READ: file No -> TR-DOS track/sector as the release does it (#4100: base track 55, sector 13)
s = open(os.path.join(D, 'xiod.asm'), 'rb').read().decode('cp866')
a = s.index('l_READ\t;A-No., HL - adr\n'); b = s.index('l_D_WRIT\t')
newread = '''l_READ\t;A-No., HL - adr (as in release 2.10: 256-byte TR-DOS sectors, 4 per 1K block)
	LD D,0
	CP 73
	JR C,l_REA0
	INC D
l_REA0	LD (l_X0),HL
	LD HL,l_X_LEN-2
	CALL l_WA
	PUSH AF
	PUSH HL
	CALL l_SECTR
	LD B,4
	LD HL,(l_X0)
	PUSH HL
	CALL l_READ1
	LD (l_FREE16),DE
	POP DE
	POP HL
	INC HL
	PUSH HL
	LD L,(HL)
	LD H,0
	ADD HL,HL
	ADD HL,HL
	PUSH HL
	ADD HL,DE
	LD BC,1024
	PUSH BC
	LDIR
	POP HL
	POP BC
	OR A
	SBC HL,BC
	LD BC,(l_X0)
	ADD HL,BC
	POP DE
	INC DE
	LD A,(DE)
	POP BC
	SUB B
	RET Z
	LD B,A
	LD C,4
	LD DE,(l_FREE16)
l_REA4	PUSH BC
	CALL l_READ1
	POP BC
	DEC C
	JR NZ,l_REA4
	RET
l_SECTR	LD H,D	;D:A = sector number (1K) -> D track, E sector (TR-DOS)
	LD L,A
	ADD HL,HL
	ADD HL,HL
	LD A,L
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	LD DE,#370C
	AND #0F
	ADD A,E
	LD L,A
	AND #0F
	INC A
	LD E,A
	LD A,L
	RRA
	RRA
	RRA
	RRA
	AND #0F
	ADD A,D
	ADD A,H
	LD D,A
	RET

'''
s = s[:a] + newread + s[b:]
open(os.path.join(D, 'xiod.asm'), 'wb').write(s.encode('cp866'))
# saved game: track 4 (as in UFO2.DAT, the release's place)
mod('xlic.asm', '\tLD DE,#201\n\tRET\n', '\tLD DE,#401\n\tRET\n')

# DELPC: the release's variant (literals are not rotated in place: the data can be unpacked again)
mod('xlid.asm', 'l_xpDRR\tLD C,A\n', 'l_xpDRR\tLD C,A\nl_xpDL2\tLD A,(HL)\n\tRRCA\n\tLD (DE),A\n\tINC HL\n\tINC DE\n\tDEC C\n\tJR NZ,l_xpDL2\n\tJR l_xpD0\n')
# mouse, YES_NO: the layer's (sensitivity, panel; mouse buttons for Y/N)
mod('xlid.asm', 'l_MOUSE\tLD HL,(l_COORD)\n', 'l_MOUSE\tJP LAY_MOUSE\n\tLD HL,(l_COORD)\n')
mod('xlie.asm', 'l_YES_NO\tLD BC,#DFFE', 'l_YES_NO\tJP LAY_YN\n\tLD BC,#DFFE')
# Kempston joystick off (port #1F is not a joystick on the ATM under CP/M)
# no keyboard control of the game's cursor (QAOP etc.): the mouse, the arrows, Sinclair 2 are ours (x_kb)
mod('xcom.asm', '\tLD A,(l_KEYJOY)\n\tOR A\n\tJR Z,l_CO1\n', '\tLD A,(l_KEYJOY)\n\tXOR A\n\tJR l_CO2\n')
# the mouse always (a game loaded from disk brings its own settings: PMOUSE = 0 there)
mod('xcom.asm', 'l_CO2\tLD (l_CONTRB),A\n\tLD A,(l_PMOUSE)\n\tOR A\n\tCALL NZ,l_MOUSE\n', 'l_CO2\tLD (l_CONTRB),A\n\tLD A,1\n\tLD (l_PMOUSE),A\n\tCALL l_MOUSE\n')
# 3D fight: "3D off" answers at once; the picture is converted after each copy to screen 7 (EGA view)
mod('xlesha.asm', 'l_ALEX\tLD HL,l_TAB1\t;My entry\n', 'l_ALEX\tCALL LAY_ALEXQ\n\tLD HL,l_TAB1\t;My entry\n')
mod('xlesha.asm', '\tNOP\n\tNOP\n\tNOP\n\tJP l_PT128\n', '\tNOP\n\tNOP\n\tNOP\n\tJP LAY_VIEW\n')
# start: no "insert disk 2" (the original came on two disks); the title waits for ENTER or a mouse button
mod('xcom.asm', '\tCALL l_BACK\n\tLD IX,l_MUST\n\tCALL l_MENUC\n\tCALL l_MU_ENT\n\tCALL l_NO_3D\n', '\tCALL l_BACK\n')
mod('xcom.asm', 'l_MU_ENT\tLD A,#BF', 'l_MU_ENT\tCALL l_MU_MS\n\tRET NC\n\tLD A,#BF')
mod('xcom.asm', 'l_MUST\tDEFW #202,#3412\n', '''l_MUST\tDEFW #202,#3412
l_MU_MS\tLD BC,#FADF\t;a mouse button: wait until released, NC
\tIN A,(C)
\tCPL
\tAND 3
\tSCF
\tRET Z
l_MU_M2\tIN A,(C)
\tCPL
\tAND 3
\tJR NZ,l_MU_M2
\tRET
''')
# EGA geoscape: MLOOP switches to the EGA view, the fights to ZX screen mode; no game arrow in the EGA view
mod('xlic.asm', 'l_MLOOP\tLD SP,#403E\n', 'l_MLOOP\tLD SP,#403E\n\tCALL LAY_GEO\n')
mod('xlic.asm', '\tCALL l_SAVMON\nl_SEB\t', '\tCALL LAY_ZXM\n\tCALL l_SAVMON\nl_SEB\t')
mod('xlie.asm', '\tDI\n\tCALL l_NOKEY\n\tLD A,R\n', '\tDI\n\tCALL LAY_GEO\n\tCALL l_NOKEY\n\tLD A,R\n')   # the location: EGA view too
mod('xlie.asm', '\tCALL l_LDASM2\n\tCALL l_MEM7\n\tPOP AF\n\tRET\n', '\tCALL l_LDASM2\n\tCALL LAY_GEO\n\tPOP AF\n\tRET\n')   # BATRET: the wide field off at once - the victory / defeat menus after it use lay_band, in the overlay BDSC covers (LDASM2 ends with MEM7 itself; same size)
mod('xlic.asm', 'l_MRK2\tCALL l_E_I\n\tCALL l_STD\n', 'l_MRK2\tCALL l_E_I\n\tCALL l_STD\n\tLD A,(LAY_EGA)\n\tOR A\n\tRET NZ\n')   # its band only shows the arrow
mod('xlic.asm', 'l_ARROW\tPUSH DE', 'l_ARROW\tLD A,(LAY_EGA)\n\tOR A\n\tRET NZ\n\tPUSH DE')
# screen 7 changed: rows to convert at once (the layer also scans the whole screen slowly)
mod('xlid.asm', '\tOR E\n\tLD L,A\n\tRET\n\nl_LINE', '\tOR E\n\tLD L,A\n\tJP LAY_MKSC\n\nl_LINE')                    # SCOORD (PRINT)
mod('xlid.asm', 'l_RETSIM\tm_POP_S\n\tRET\n', 'l_RETSIM\tm_POP_S\n\tJP LAY_MKSIM\n')
mod('xlid.asm', 'l_RETPSP\tm_POP_S\n\tRET\n', 'l_RETPSP\tm_POP_S\n\tJP LAY_MKSPR\n')
mod('xlid.asm', 'l_RETPTS\tm_POP_S\n\tRET\n', 'l_RETPTS\tm_POP_S\n\tJP LAY_MKPSC\n')
mod('xlid.asm', '\tRRA\n\tRR L\n\tRET\n\nl_DATA01', '\tRRA\n\tRR L\n\tJP LAY_MKHL\n\nl_DATA01')                 # PCOORD
mod('xlid.asm', 'l_RETPAT\tm_POP_S\n\tRET\n', 'l_RETPAT\tm_POP_S\n\tJP LAY_MKATR\n')
mod('xlid.asm', '\tLD DE,l_SCR\n\tLDIR\n\tRET\n\nl_COPYAT', '\tLD DE,l_SCR\n\tLDIR\n\tJP LAY_MKALL\n\nl_COPYAT')   # COPY, COPYAT (mku.asm mk_cy: the text map too)
mod('xlid.asm', '\tCALL l_SCOORD\n\tPOP DE\n\tLD B,8\nl_PRIN1', '\tCALL l_SCOORD\nl_PRINR\tPOP DE\n\tLD B,8\nl_PRIN1')   # PRINT: SCOORD's return (the text map's recorder knows its calls)
mod('xlid.asm', '\tCALL l_SCOORD\n\tPOP DE\n\tLD B,8\nl_WH1', '\tCALL l_SCOORD\nl_LETR\tPOP DE\n\tLD B,8\nl_WH1')   # LETTER (the menus' words): the same
mod('xlid.asm', '\tCALL l_SCOORD\n\tPOP DE\n\tLD B,4\nl_WH22', '\tCALL l_SCOORD\nl_TALR\tPOP DE\n\tLD B,4\nl_WH22')   # LETTER's tall letters: the same
mod('xlie.asm', 'l_BACK\tLD HL,l_SCR\n\tLD DE,l_DSCR\n\tLD BC,6912\n\tLDIR\n\tRET\n', 'l_BACK\tLD HL,l_SCR\n\tLD DE,l_DSCR\n\tLD BC,6912\n\tJP LAY_MKSC\n')   # BACK: its LDIR done by mk_sc (DE = DSCR), the text map too; the same size (UFO2.BTL keeps the game's code)
mod('xlid.asm', '\tLDDR\n\tRET\n\nl_COLOR', '\tLDDR\n\tJP LAY_MKOFF\n\nl_COLOR')                         # OFFS
mod('xlic.asm', '\tINC (HL)\n\tLD HL,l_DSCR+#10A0\n\tLD DE,l_SCR+#10A0\n\tLD B,8\n', '\tINC (HL)\n\tLD HL,l_DSCR+#10A0\n\tLD A,168\n\tLD B,24\n\tJP LAY_BAND\n\tLD DE,l_SCR+#10A0\n\tLD B,8\n')   # COPY21 (the menu's 3 bottom rows, each poll): as MRK1's band - the layer copies and marks only what changed (marked all each time, the picture was never complete: shown only by age)
cut('xlid.asm', 'l_GETATR\tm_PUSH_S\n', 'l_SELSCR\t', 'l_SELAT3\tDEFB 0,0\t; (GETATR: never called - room for xlie.asm HLINE; SELSCR still writes its operand)\n\n')
mod('xlin.asm', 'l_XDR4\tCALL l_LINE\n', 'l_XDR4\tCALL l_HLINE\n')   # the fight's soldier screen ('?', XN_DRW): its parameter bars as DRAW_P's (xlie.asm l_HLINE)
mod('xlie.asm', '\tLD B,11\nl_DR4\tCALL l_LINE\n', '\tLD B,11\nl_DR4\tCALL l_HLINE\n')   # DRAW_P's parameter bars: 11 horizontal XOR lines each - a byte loop, not LINE's dot by dot
# the words' table (#7E after each word): the B-th word found with CPIR, not a byte loop (the menus' lines: MTXT's Z4
# and the like; NWRD - names, menus). Same sizes (the addresses after them kept); BC, DE, A changed - as LETTER
# (l_WORD's printing) changes them anyway. CPIR's count: B = #7E (BC >= #7E00)
mod('xlie.asm', 'l_Z46\tLD A,(HL)\n\tINC HL\n\tCP 126\n\tJR NZ,l_Z46\n\tDJNZ l_Z46\n\tLD (l_TXT),HL\n\tLD B,-1\n',
    'l_Z46\tLD E,B\n\tLD A,126\n\tLD B,A\nl_Z46a\tCPIR\n\tDEC E\n\tJR NZ,l_Z46a\n\tPUSH HL\n\tLD B,-1\n')
mod('xlie.asm', '\tLD (l_SX),DE\n\tJP l_WORD\n\nl_Z4\t', '\tLD (l_SX),DE\n\tPOP HL\n\tJP l_WORDHL\n\nl_Z4\t')
mod('xlie.asm', 'l_NWRD\tLD B,A\n\tINC B\n\tLD HL,(l__words)\nl_NW0\tLD A,(HL)\n\tINC HL\n\tCP #7E\n\tJR NZ,l_NW0\n\tDJNZ l_NW0\n\tJP l_WORDHL\n',
    'l_NWRD\tLD E,A\n\tINC E\n\tLD HL,(l__words)\n\tLD A,#7E\n\tLD B,A\nl_NW0\tCPIR\n\tDEC E\n\tJR NZ,l_NW0\n\tJP l_WORDHL\n')
# DRAW_P's / XN_DRW's parameter bars: 11 / 9 horizontal XOR lines each - HLINE, not LINE's dot by dot: the pixels'
# mask gathered per byte, XORed once a byte (in GETATR's room, below DRAW_P: the addresses after it kept - obj.asm)
mod('xlie.asm', 'l_DRAW_P\tLD IX,(l_SOLD_D)\n',
    'l_HLINE\tPUSH HL\n\tPUSH BC\n\tLD A,L\n\tSUB E\n\tINC A\n\tLD B,A\n\tCALL l_PCOORD\n\tLD A,E\n\tAND 7\n\tINC A\n\tLD C,1\n'
    'l_HL1\tRRC C\n\tDEC A\n\tJR NZ,l_HL1\nl_HL2\tOR C\n\tRRC C\n\tJR NC,l_HL3\n\tXOR (HL)\n\tLD (HL),A\n\tINC L\n\tXOR A\n'
    'l_HL3\tDJNZ l_HL2\n\tXOR (HL)\n\tLD (HL),A\n\tPOP BC\n\tPOP HL\n\tRET\n\nl_DRAW_P\tLD IX,(l_SOLD_D)\n')   # (row D, x E .. L; DE kept - PCOORD, LAY_MKHL keep it)
mod('xlic.asm', '\tCALL l_BACK\nl_UP_XX\tLD IX,l_MU00\n', '\tCALL l_BACK\n\tCALL l_SAVE_6\n\tJR l_UP_XX\nl_UPX6\tCALL l_LOAD_6\nl_UP_XX\tLD IX,l_MU00\n')   # UPEDIA: the screen under the encyclopedia's menus kept (page 6, as the base menu's SAVE_6) ...
mod('xlic.asm', '\tCALL l_SELM\n\tJR NC,l_UP_XX\n', '\tCALL l_SELM\n\tJR NC,l_UPX6\n')   # ... and back before the sections' menu again: a subsection's menu higher than it (Weapons) left its frame above it
mod('xlic.asm', 'l_M10\tLD D,A\n\tLD E,0\n\tCALL l_BCOORD\n', 'l_M10\tLD D,A\n\tLD E,0\n\tCALL l_BCOORD\n\tLD A,D\n\tLD B,l_w_band\n\tJP LAY_BAND\n')    # MRK1 band: the layer copies (and marks only what changed)
mod('xlic.asm', '\tJP LAY_BAND\n\tPUSH HL\n\tLD BC,l_SCR-l_DSCR\n\tADD HL,BC\n\tPOP DE\n\tEX DE,HL\n\tLD B,l_w_band\nl_M12\tm_PUSH_S\n\tLD BC,32\n\tLDIR\n\tm_POP_S\n\tINC D\n\tINC H\n\tLD A,H\n\tAND %111\n\tJR NZ,l_M14\n\tLD A,H\n\tSUB 8\n\tLD H,A\n\tLD A,L\n\tADD A,32\n\tLD L,A\n\tLD E,A\n\tJR NC,l_M15\n\tLD A,8\n\tADD A,H\n\tLD H,A\nl_M15\tLD A,(l_SCR-l_DSCR)/256\n\tADD A,H\n\tLD D,A\nl_M14\tDJNZ l_M12\n\tRET\n',
    '\tJP LAY_BAND\nl_ONOFX\tLD DE,#FFFF\n\tLD (LAY_BDC),DE\n\tLD A,H\n\tSUB 8\n\tCP #C0\n\tRET NC\n\tLD H,A\n\tLD A,L\n\tAND #E0\n\tLD L,A\n\tRRCA\n\tRRCA\n\tLD C,A\n\tLD A,H\n\tSUB #90\n\tAND #18\n\tADD A,A\n\tADD A,A\n\tADD A,A\n\tADD A,C\n\tLD B,8\n\tCALL LAY_BAND\n\tLD HL,#FFFF\n\tLD (LAY_BDC),HL\n\tRET\n')   # (MRK1's old copy, unused) -> l_ONOFX (wide.py ONOFL): the line ONOFL inverted (HL: its 9th line, column; DSCR at #9000 - screen 7 #C000: marked by SCOORD itself) compared as a band of 8 lines; the bands' memo forgotten before and after
mod('xlic.asm', 'l_M210\tLD D,A\n\tLD E,0\n\tCALL l_BCOORD\n', 'l_M210\tLD D,A\n\tPUSH AF\n\tLD E,0\n\tCALL l_BCOORD\n')  # MRK2 band
mod('xlic.asm', 'l_M214\tDJNZ l_M212\n\tRET\n', 'l_M214\tDJNZ l_M212\n\tPOP AF\n\tLD BC,l_wB_ban*256+8\n\tJP LAY_MKLN\n')
mod('xlic.asm', '\tLD E,96+26\n\tCALL l_PD4\n\tRET\n', '\tLD E,96+26\n\tCALL l_PD4\n\tXOR A\n\tLD BC,32*256+8\n\tJP LAY_MKSC\n')   # clock (text.asm tx_dat: HL = TIM + 22 -> the text map, then LAY_MKLN's marks)
mod('xlix.asm', '\tLDIR\n\tCALL l_INT00\n\tPOP BC\n\tDJNZ l_MY90\n', '\tLDIR\n\tCALL LAY_SCRL\n\tLD A,(LAY_EGA)\n\tOR A\n\tJR Z,1F\n\tPUSH IX\n\tCALL l_INT0\n\tPOP IX\n\tJR 2F\n1\tCALL l_INT00\n2\tPOP BC\n\tDJNZ l_MY90\n')   # EGA: the text window scrolls at once (no HALT per line: one conversion at the end)   # SCROLL (text window)
mod('xlix.asm', '\tDJNZ l_MY95\nl_INT00', '\tDJNZ l_MY95\n\tCALL LAY_SCRE\n1\tLD B,1\n\tCALL LAY_SCRL\n\tJR Z,l_INT00\n\tCALL l_E_I\n\tJR 1B\nl_INT00')   # the console (EGA): the new line typed - wait (LAY_SCRL with B = 1: NZ while typing)
mod('xlix.asm', '\tDEC A\n\tJR NZ,l_Ux7\n\tCALL l_E_I\n', '\tDEC A\n\tJR NZ,l_Ux7\n\tCALL LAY_MKALL\n')   # UCOPY (the encyclopedia's page DSCR -> SCR, 28 columns): as COPY (HL, DE the same at its end) - the text map too
# the battlefield (DSCR): what its drawing routines change, OUTDSC through the layer
# the sprites (MS2 / LS2 / RS2) without SP (as NedoOS's UFO-2 by Alone Coder, MUSIC=1): the fights run with interrupts
# on (the music); HL = the sprite's bytes (mask, picture), DE = the field; Ainv: #AE (XOR (HL)) or 0 (the mask only)
def rblock(fn, a, b, new):
    pp = os.path.join(D, fn); t = open(pp, 'rb').read().decode('cp866')
    i = t.index(a); j = t.index(b, i)
    t = t[:i] + new + t[j:]; open(pp, 'wb').write(t.encode('cp866'))
rblock('xlib.asm', 'l_MS2\t', 'l_MSiRET\t', 'l_MS2\tCALL LAY_FD2\n\tEX DE,HL\nl_MS20\tLD A,(DE)\n\tOR (HL)\n\tINC HL\nl_Ainv1\tXOR (HL)\n\tINC HL\n\tLD (DE),A\n\tINC DE\n\tLD A,(DE)\n\tOR (HL)\n\tINC HL\nl_Ainv2\tXOR (HL)\n\tINC HL\n\tLD (DE),A\n\tLD A,E\n\tADD A,31\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_MS20\n\tEX DE,HL\n')
rblock('xlib.asm', 'l_LS2\t', '\tm_pop_S\n\tRET\n\nl_RSP\t', 'l_LS2\tCALL LAY_FD1\n\tEX DE,HL\nl_LS20\tLD A,(DE)\n\tOR (HL)\n\tINC HL\nl_Ainv3\tXOR (HL)\n\tINC HL\n\tLD (DE),A\n\tINC HL\n\tINC HL\n\tLD A,E\n\tADD A,32\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_LS20\n\tEX DE,HL\n')
rblock('xlib.asm', 'l_RS2\t', '\tm_pop_S\n\tRET\n\nl_RSPB\t', 'l_RS2\tCALL LAY_FD1\n\tEX DE,HL\nl_RS20\tINC HL\n\tINC HL\n\tLD A,(DE)\n\tOR (HL)\n\tINC HL\nl_Ainv4\tXOR (HL)\n\tINC HL\n\tLD (DE),A\n\tLD A,E\n\tADD A,32\n\tLD E,A\n\tJR NC,$+3\n\tINC D\n\tDJNZ l_RS20\n\tEX DE,HL\n')
mod('xlib.asm', '\tJR NZ,l_A22P\n\tLD A,#AA\n', '\tJR NZ,l_A22P\n\tLD A,#AE\n')
mod('xlim.asm', 'l_NORM_V\tLD A,#AA', 'l_NORM_V\tLD A,#AE')
# the fight's object planes (port/obj.asm; its hooks told apart by their return addresses): l_HIX = the fighter A4P
# puts into DATR; GBU (a moving fighter, HERO) and PBU marked; PBU and l_HIX past the resident part, in the old
# fight stack's room (#8F3F..#8F7F: the stack is the layer's now)
mod('xlib.asm', '\tPUSH IX\n\tCALL l_GET_IX\n\tCALL l_HERLIV\n', '\tPUSH IX\n\tCALL l_GET_IX\n\tLD (l_HIX),IX\n\tCALL l_HERLIV\n')
mod('xlim.asm', 'l_CMR_\tLD BC,#203\n', 'l_CMR_\tLD BC,#203\n\tCALL LAY_FDC\n')
mod('xlim.asm', '\tLD (l_GB_AD+1),A\n\tLD HL,l_DATR+128\n', '\tLD (l_GB_AD+1),A\n\tEX DE,HL\n\tLD BC,#318\n\tCALL LAY_FDC\nl_PBUH\tEX DE,HL\n\tLD HL,l_DATR+128\n')
mod('xlim.asm', 'l_GBU\tPUSH HL\n', 'l_GBU\tLD BC,#318\n\tCALL LAY_FDC\nl_GBUH\tPUSH HL\n')
mod('xcom.asm', '\tCALL l_MU_ENT\n', '\n')   # no title (waiting for ENTER / a click): straight to the world map
# EGA: no blinking mark round the fighter in focus, no 3D cursor of the game (the layer's cursor shows its kind)
mod('xlim.asm', 'l_CURHER\t', 'l_CURHER\tLD A,(LAY_EGA)\n\tOR A\n\tRET NZ\n\t')
# EGA: the game's 3D cursor only as the floor of its cell (the top face's 8 lines of xMARKE's first picture drawn 23
# lines lower), never blinking - our mouse cursor shows the kind
mod('xlim.asm', '\tCALL l_CANF_V\n\tLD HL,(l_PPX)\n\tLD (l_TX),HL\n\tCALL l_GSP60\n', '\tCALL l_CANF_V\n\tLD HL,(l_PPX)\n\tLD (l_TX),HL\n\tLD A,(LAY_EGA)\n\tOR A\n\tJR NZ,l_PNT5\n\tCALL l_GSP60\n')
# (v57: the whole 3D cursor again - its pictures by kind, white in EGA: obj.asm ob_mkd)
mod('xlib.asm', 'l_ALLSPF\tLD A,(l_FLR)', 'l_ALLSPF\tLD BC,0\n\tCALL LAY_FDC\nl_ALLSH\tCALL l_ALLS0\n\tPUSH BC\n\tPUSH AF\n'
    '\tLD BC,0\n\tCALL LAY_FDC\nl_ALLSE\tPOP AF\n\tPOP BC\n\tRET\nl_ALLS0\tLD A,(l_FLR)')   # (and ends: xtil_i.asm as_end)   # (a whole redraw starts: obj.asm's ob_pass)   # PBU (the image under a moving fighter restored): marked
mod('xlim.asm', '\tLD DE,(l_P_AD)\n\tLD BC,#40FD\n', '\tLD DE,(l_P_AD)\n\tCALL LAY_FPAD\n\tLD BC,#40FD\n')
mod('xlib.asm', 'l_OUTDSC\tCALL l_MEM7\n', 'l_OUTDSC\tCALL l_MEM7\n\tJP LAY_OUTD\n')
import re
for lab in ('l_RRT', 'l_LRT', 'l_DRT', 'l_URT'):
    pp = os.path.join(D, 'xlib.asm'); t = open(pp, 'rb').read().decode('cp866')
    t, n = re.subn(r'^' + lab + r'\t', lab + '\tCALL LAY_FALL\n\t', t, count=1, flags=re.M); assert n == 1, lab
    open(pp, 'wb').write(t.encode('cp866'))
pp = os.path.join(D, 'xlic.asm'); t = open(pp, 'rb').read().decode('cp866')
t, n = re.subn(r'l_REMAP\t[^\n]*\n', 'l_REMAP\tCALL l_REMAP_\n\tJP LAY_MKALL\nl_REMAP_\n', t); assert n == 1
open(pp, 'wb').write(t.encode('cp866'))
# room in the resident part (it must end below #8F3F): the replaced routines' bodies out
pp = os.path.join(D, 'xlid.asm'); t = open(pp, 'rb').read().decode('cp866')
a = t.index('l_MOUSE\tJP LAY_MOUSE\n') + len('l_MOUSE\tJP LAY_MOUSE\n'); b = t.index('l_COORD\tDEFW')
t = t[:a] + '\n' + t[b:]; open(pp, 'wb').write(t.encode('cp866'))
pp = os.path.join(D, 'xlie.asm'); t = open(pp, 'rb').read().decode('cp866')
a = t.index('l_YES_NO\tJP LAY_YN\n') + len('l_YES_NO\tJP LAY_YN\n'); b = t.index('\tJR l_YES_NO\n', a) + len('\tJR l_YES_NO\n')
t = t[:a] + t[b:]; open(pp, 'wb').write(t.encode('cp866'))
# the fight's stack: the layer's free #3B80..#3CFF instead of #8F7E (just above the resident code: our hooks
# make the calls deeper, and the resident code grew)
mod('xlim.asm', '\tLD SP,#8F7E', '\tLD SP,#3D00')
# the music in the fights: interrupts on there (the layer's bat_on: its own interrupt handler, the DIs after E_I's and
# DELAY's HALT off); in the 3D fight the screen fills with SP: CLS / FRAME (every frame) with interrupts on - an
# interrupt's pushes land below SP, in what the fill writes next, or at its end below SHDSCR (#9000: xCONV, a scratch
# buffer) or in the top 2/3 the next CLS clears; FRAMIN (once, its last fill below kept lines) with interrupts off
mod('xlim.asm', '\tDI\n\tLD SP,#3D00', '\tEI\n\tLD SP,#3D00')
mod('xlie.asm', 'l_E_I\tm_push_S\n\tEI\n\tHALT\n\tDI\n', 'l_E_I\tm_push_S\n\tEI\n\tHALT\nl_EIDI\tDI\n')
mod('xcom.asm', 'l_DELAY\tEI\n\tHALT\n\tDI\n', 'l_DELAY\tEI\n\tHALT\nl_DLDI\tDI\n')
mod('xlesha.asm', 'l_FRAMIN\tLD (l_FR1CFG+1),SP', 'l_FRAMIN\tDI\n\tLD (l_FR1CFG+1),SP')
mod('xlesha.asm', 'l_FR1CFG\tLD SP,0\n', 'l_FR1CFG\tLD SP,0\n\tEI\n')
# the menu (the top left button): its music (the layer's MUS_TRK = 1; LAY_GEO at MLOOP sets 0 again)
mod('xlix.asm', '\tCP E\n\tLD A,D\n\tJR Z,l_US1\n', '\tCP E\n\tLD A,D\n\tJR l_US1\n')   # the encyclopedia's pictures: never loaded (UFO2.ENC has them in EGA; port/enc.asm)
mod('xlix.asm', 'l_XMENUS\t;', 'l_XMENUS\tLD A,1\n\tLD (#3DF4),A\n\t;')
# SELPM (the buy / sell / hire / fire / production windows' cancel, O.K., -, +; the callers loop on it, a step each
# answer): its own loop goes to SELPM0; - / + held on (no release seen by the layer's mouse: #3DEF, uimouse.asm) - one
# step, then nothing for ~a second (16 x E_I + SELPM0: ~3 frames each), then a step each answer (+ E_I: fast)
mod('xlix.asm', '\tJR NC,l_SELPM\n', '\tJR NC,l_SELPM0\n', 2)
mod('xlix.asm', 'l_COPY3\tLD BC,2048\n\tLD HL,l_DSCR+4096\n\tLD DE,l_SCR+4096\n\tLDIR\n\tRET\n', 'l_COPY3\tLD BC,2048\n\tLD HL,l_DSCR+4096\n\tLD DE,l_SCR+4096\n\tLDIR\n\tLD A,128\n\tLD BC,64*256+#FF\n\tJP LAY_MKLN\n')   # COPY3 (rows 16..23: the windows' sums, counts) marked - shown while - / + is held too
mod('xlix.asm', 'l_SELPM\tCALL l_MARK_', '''l_SELPM\tCALL l_SELPM0
	CP 2
	JR NC,l_PMR1
	LD HL,l_PM_A
	LD (HL),#FF
	OR A
	RET
l_PMR1\tLD HL,#3DEF
	LD C,(HL)
	LD (HL),0
	LD HL,l_PM_A
	CP (HL)
	LD (HL),A
	JR NZ,l_PMRN
	DEC C
	JR Z,l_PMRN
	LD HL,l_PM_T
	INC (HL)
	DEC (HL)
	JR Z,l_PMRR
	DEC (HL)
	CALL l_E_I
	JR l_SELPM
l_PMRN\tLD HL,l_PM_T
	LD (HL),16
	JR l_PMRS
l_PMRR\tPUSH AF
	CALL l_E_I
	POP AF
l_PMRS\tOR A
	RET
l_PM_A\tDEFB #FF
l_PM_T\tDEFB 0
l_SELPM0\tCALL l_MARK_''')
# the fight's map cursor "off" (BNEW: high byte 0) restores its 9 bytes into the ROM at #00xx..#07xx - here that
# is the layer's code (it hit int_h's own operand): skip while off
mod('xlim.asm', '\tLD HL,(l_BHL)\n\tLD DE,l_BIBU\n', '\tLD HL,(l_BHL)\n\tLD A,H\n\tOR A\n\tJR Z,l_BNEW\n\tLD DE,l_BIBU\n')
# the path search (CW254, "found"): POP x4 then LD (HL),250 - HL is the pushed AF (A = the wave step): on the ZX a
# write into the ROM; here the layer's code (the fight hung after a soldier was sent somewhere). Only into the RAM.
mod('xlim.asm', '\tPOP HL\n\tPOP HL\n\tLD (HL),250\n\tRET\n', '\tPOP HL\n\tPOP HL\n\tLD A,H\n\tAND #C0\n\tJR Z,$+4\n\tLD (HL),250\n\tLD A,255\n\tOR A\n\tRET\n')   # (A = 255, NZ, NC as before)
# the fight's square cursor (attribute #60 + a frame) over the panels: not in the EGA view (our arrow is there)
mod('xlim.asm', 'l_BO1\tCALL l_STS\n', 'l_BO1\tCALL l_STS\n\tLD A,(LAY_EGA)\n\tOR A\n\tJP NZ,l_PT128\n')
# the fight's RAM SAVE / LOAD: the progress through the layer (EGA: a bar under SAVE / LOAD; ZX: the game's own)
mod('xlin.asm', '\tCALL l_IND_LS\n', '\tCALL LAY_PROG\n', 2)
# HERROT (the turn to a target: S, the middle button, before a shot): the game turns by 45 degrees and draws the whole
# field each step (a full redraw each: 4 for a turn round). Here the steps (their looks, the floor) as the game does
# them, the field drawn once at the end
mod('xlin.asm', 'l_HERROT\tLD IX,(l_HER_AD)\t;поворот к цели\n\tCALL l_GET_XY\n\tCALL l_DIRF\n\tLD D,(IX+3)\n\tSUB D\n\tRET Z\n',
    'l_HERROT\tXOR A\t;поворот к цели (порт: поле рисуется один раз, в конце)\n\tLD (l_HRRN),A\nl_HRR0\tLD IX,(l_HER_AD)\n'
    '\tCALL l_GET_XY\n\tCALL l_DIRF\n\tLD D,(IX+3)\n\tSUB D\n\tJR Z,l_HRR2\n')
mod('xlin.asm', 'l_HRR1\tDEC A\n\tAND 7\n\tLD (IX+3),A\n\tLD A,(IX+5)\n\tOR A\n\tLD A,(l_FLR)\n\tPUSH AF\n\tCALL Z,l_LOOKS\n\tPOP AF\n'
    '\tCALL l_FLOOR\n\tCALL l_ALLSPF\n\tCALL l_OUTDSC\n\tJR l_HERROT\n',
    'l_HRR1\tDEC A\n\tAND 7\n\tLD (IX+3),A\n\tLD A,1\n\tLD (l_HRRN),A\n\tLD A,(IX+5)\n\tOR A\n\tLD A,(l_FLR)\n\tPUSH AF\n'
    '\tCALL Z,l_LOOKS\n\tPOP AF\n\tCALL l_FLOOR\n\tJR l_HRR0\n'
    'l_HRR2\tLD A,(l_HRRN)\n\tOR A\n\tRET Z\n\tCALL l_ALLSPF\n\tCALL l_OUTDSC\n\tXOR A\n\tRET\nl_HRRN\tDEFB 0\n')
# LOOKER (the look round on the spot: S, the middle button): the same - each 45-degree step drew the whole field
# (ALLSPF, OUTDSC); here the steps (time units, the looks, a new enemy seen: the stop) as the game does them, the
# field drawn once at the end (its own JP l_ALLSPF there)
mod('xlin.asm', '\tCALL l_FLOOR\n\tCALL l_LOOKS\n\tCALL l_ALLSPF\n\tCALL l_OUTDSC\n\tPOP AF\n\tCALL l_FLOOR\n\tLD A,(l_isNEW)\n',
    '\tCALL l_FLOOR\n\tCALL l_LOOKS\n\tPOP AF\n\tCALL l_FLOOR\n\tLD A,(l_isNEW)\n')
# a fight from the service panel (LOC GO): time units are not spent (DECPAR: A = 0, NC as with enough)
mod('xlim.asm', 'l_DECPAR\t', 'l_DECPAR\tLD A,(LAY_TUINF)\n\tOR A\n\tJR Z,1F\n\tXOR A\n\tRET\n1\t')
pp = os.path.join(D, 'xlim.asm'); t = open(pp, 'rb').read().decode('cp866')
a = t.index('l_PBU\t'); b = t.index('\tRET\n', a) + len('\tRET\n')
blk = t[a:b]; t = t[:a] + t[b:]; open(pp, 'wb').write(t.encode('cp866'))
pp = os.path.join(D, 'xmain.asm'); t = open(pp, 'rb').read().decode('cp866')
a = t.index('\tDS #8F3F-$,0'); a = t.index('\n', a) + 1
t = t[:a] + 'l_HIX\tDEFW 0\n' + blk + '\tDS #8F80-$,0\n' + t[a:]; open(pp, 'wb').write(t.encode('cp866'))
print('mods ok')
# module ends (physical addresses) for the packer
mod('xmain.asm', '\tINCLUDE "xlesha.asm"\n\tENT\n', '\tINCLUDE "xlesha.asm"\n\tENT\nMOD0_E\n')
mod('xmain.asm', '\tINCLUDE "xlix.asm"\n\tENT\n', '\tINCLUDE "xlix.asm"\n\tENT\nMOD1_E\n')
mod('xmain.asm', ';xlic\n;*L-\n\tENT\n', ';xlic\n;*L-\n\tENT\nMOD2_E\n')
mod('xmain.asm', ';xliF+xioD\n;*L-\n\tENT\n', ';xliF+xioD\n;*L-\n\tENT\nMOD3_E\n')
# the world map's marks: ours (port/ico.asm om_gat, om_plt - from the game's state), none on screen 7 (SHOWD, SHOWS,
# SHOWT: XOR sprites - their blinks were whole lines converted again and again)
for l_ in ('l_SHOWS', 'l_SHOWD', 'l_SHOWT'): mod('xlic.asm', l_ + '\t;', l_ + '\tRET\t;')
# the target's crosshair (PMAP: 8 XOR passes of its lines): only its place and the pass to the layer (port/ico.asm
# om_gat: B even - shown); ours draws it on the EGA map
cut('xlic.asm', 'l_Pmp\tPUSH BC', '\tCALL l_E_I\n\tCALL l_INT0\n\tPOP HL', 'l_Pmp\tPUSH BC\n\tPUSH HL\n\tLD (LAY_PMP),HL\n\tLD A,B\n\tLD (LAY_PMP+2),A\n')   # (no XOR lines on screen 7)
print('ends ok')
