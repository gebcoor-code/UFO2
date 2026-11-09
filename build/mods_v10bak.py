# Changes of the converted UFO-2 sources for the ATM CP/M build (applied to src/*.asm after conv.py).
# The CP/M layer (UFO2.COM) has a vector table at #0103: DREAD, DWRITE, MOUSE, YN, ALEXQ, VIEW.
import sys, os, re
D = sys.argv[1] if len(sys.argv) > 1 else 'src'
def mod(fn, old, new, count=1):
    p = os.path.join(D, fn); s = open(p, 'rb').read().decode('cp866')
    n = s.count(old)
    if n != count: raise SystemExit('%s: %r found %d times (want %d)' % (fn, old[:60], n, count))
    s = s.replace(old, new); open(p, 'wb').write(s.encode('cp866'))

VEC = '''LAY_DREAD	EQU #0103
LAY_DWRITE	EQU #0106
LAY_MOUSE	EQU #0109
LAY_YN	EQU #010C
LAY_ALEXQ	EQU #010F
LAY_VIEW	EQU #0112
'''
mod('xcom.asm', '\tINCLUDE "xpage.asm"', VEC + '\tINCLUDE "xpage.asm"')

# disk: the release's (cracked) logic on TR-DOS sectors of 256 bytes; the layer reads them from UFO2.DAT in RAM
mod('xiod.asm', 'l_READ1\tCALL l_D_READ\n', 'l_READ1\tJP l_D_READ\n\tCALL l_D_READ\n')
mod('xiod.asm', 'l_TR000\tCALL l_TR0\n', 'l_TR000\tRET\n\tCALL l_TR0\n')
mod('xiod.asm', 'l_D_WRIT\tDI\n', 'l_D_WRIT\tJP LAY_DWRITE\n\tDI\n')
mod('xiod.asm', 'l_D_READ\tDI\t;E-sec,D-trk,B-sec.num,HL-mem.adr\n', 'l_D_READ\tJP LAY_DREAD\t;E-sec 1..16, D-trk (TR-DOS), B-secs, HL\n\tDI\n')
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
mod('xcom.asm', '\tLD A,(l_KEYJOY)\n\tOR A\n\tJR Z,l_CO1\n', '\tLD A,(l_KEYJOY)\n\tOR A\n\tJR l_CO1\n')
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
print('mods ok')
# module ends (physical addresses) for the packer
mod('xmain.asm', '\tINCLUDE "xlesha.asm"\n\tENT\n', '\tINCLUDE "xlesha.asm"\n\tENT\nMOD0_E\n')
mod('xmain.asm', '\tINCLUDE "xlix.asm"\n\tENT\n', '\tINCLUDE "xlix.asm"\n\tENT\nMOD1_E\n')
mod('xmain.asm', ';xlic\n;*L-\n\tENT\n', ';xlic\n;*L-\n\tENT\nMOD2_E\n')
mod('xmain.asm', ';xliF+xioD\n;*L-\n\tENT\n', ';xliF+xioD\n;*L-\n\tENT\nMOD3_E\n')
print('ends ok')
