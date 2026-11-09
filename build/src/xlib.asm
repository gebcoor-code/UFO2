	;**** HЛО-2. Дьяволы бездны ****
	;8F80-xCONV(128)
	;9000-теневой экран(6k)
	;A800-теневые атрибуты(768)  (128-буф1)
	;AB00-MAN+ALIEN(1024)
	;AF80-vSIZE(128)
	;AF00-xATR(128)
	;B000-истребитель(2k) (0,1,2-15)
	;B800-НЛО(6k) (16-63)
	;D000-ландшафт(4k) (64-95)
	;E000-1й этаж(4k)
	;F000-2й этаж(4k)

	;CПРАЙТЫ: 0-fill 2й этаж;1-fill 1й этаж
	;2-15-истребитель(2-vSIZE<4)
	;96-127-стоит герой(0-31)

l_SCR	EQU #C000
l_ATR	EQU #D800
l_DSCR	EQU #9000
l_BDSC	EQU #0F40
l_BW	EQU 44
l_BCELL	EQU 21
l_BROWS	EQU 29
l_VISH	EQU 200
l_FROWS	EQU 25
l_PROW	EQU 26
l_DATR	EQU #A800
l_MAN	EQU #AB00
l_ALIEN	EQU l_MAN+320
l_TMP	EQU l_DSCR
l_xATR	EQU #AF00
l_vSIZE	EQU #AF80
l_xCONV	EQU #8F80

	;****************************************** работа с 3D спрайтами

l_SH	DEFB 0	; Shift 0/8
l_TX	DEFB 0
l_TY	DEFB 1
l_TTX	DEFB #CD
l_TTY	DEFB 0
l_NSH	DEFW 0
l_UDHL	DEFW 6
l_XMAX	DEFB 63	;макс.коорд
l_YMAX	DEFB 63
	;*L+
l_B_DAT	;-----данные боя-------------
l_OLDFLR	DEFB 0
l_X0	DEFB 63
l_Y0	DEFB 63
l_RNB	DEFB 5
l_RNA	DEFW 1970
l_NX_RNB	DEFB 0
l_NX_RNA	DEFW 505
l_FIRTYP	DEFB 0	;тип Стрельбы (1-прицельная)
l_HER_N	DEFB 0	;NO. текущ героя
l_HER_AD	DEFW 0	;адр. его данных
l_G_TIME	DEFB 0	;время использ текущ оружия
l_G_TYPE	DEFB #FF	;текущ оружие
l_SETLEN	EQU 38
l_SET_N	DEFB 0	;к-во записей
l_SETDIM	DS 5*l_SETLEN,#FF	;двери/гранаты (X,Y,Flr,Tmp,Door)/(x,y,Flr,0,0)
l_B_LEN	EQU $-l_B_DAT	;--------------

l_HER_BA	LD HL,(l_HER_AD)	;взять поле А
	JP l_BA

l_RRT	CALL LAY_FALL
	LD DE,l_BDSC+(32*l_BW)	;скролл вправо
	LD HL,l_BDSC+(32*l_BW)+1
	LD BC,(l_VISH*l_BW)-1
	LDIR
	LD A,(l_SH)
	XOR 8
	LD (l_SH),A
	JR NZ,l_RR8
	LD HL,l_X0
	INC (HL)
	INC HL
	DEC (HL)
l_RR8	LD A,(l_FLR)
	OR A
	JR NZ,l_RLN
	INC A
	CALL l_FLOOR
	CALL l_RLN
	XOR A
	CALL l_FLOOR
l_RLN	LD DE,(l_X0)
	LD A,l_BCELL-1
	ADD A,E
	LD E,A
	LD A,1-l_BCELL
	ADD A,D
	LD D,A
	LD A,(l_SH)
	OR A
	JR Z,l_RL0
	LD HL,l_BDSC+(2*l_BCELL)-1+(4*l_BW)
	JR l_LL1
l_RL0	DEC E
	LD HL,l_BDSC+(2*l_BCELL)-1
	JR l_LL1

l_LRT	CALL LAY_FALL
	LD DE,l_BDSC+((32+l_VISH)*l_BW)-1	;Скролл влево
	LD HL,l_BDSC+((32+l_VISH)*l_BW)-2
	LD BC,(l_VISH*l_BW)-1
	LDDR
	LD A,(l_SH)
	XOR 8
	LD (l_SH),A
	JR Z,l_LR8
	LD HL,l_X0
	DEC (HL)
	INC HL
	INC (HL)
l_LR8	LD A,(l_FLR)
	OR A
	JR NZ,l_LLN
	INC A
	CALL l_FLOOR
	CALL l_LLN
	XOR A
	CALL l_FLOOR
l_LLN	LD A,(l_SH)
	LD DE,(l_X0)
	OR A
	JR NZ,l_LL0
	LD HL,l_BDSC+(4*l_BW)+2
	JR l_LL1
l_LL0	LD HL,l_BDSC+2
	DEC D
l_LL1	LD (l_TX),DE
	LD B,l_BROWS
l_LL2	CALL l_ASP
	JR Z,l_LL_2
	CALL l_LSP
l_LL_2	LD DE,4*l_BW
	ADD HL,DE
	LD A,(l_TY)
	INC A
	LD (l_TY),A
	CALL l_ASP
	JR Z,l_LL_3
	CALL l_RSP
l_LL_3	LD DE,4*l_BW
	ADD HL,DE
	LD A,(l_TX)
	INC A
	LD (l_TX),A
	DJNZ l_LL2
	RET

l_DRT	CALL LAY_FALL
	LD DE,l_BDSC+(32*l_BW)	;скролл вниз
	LD HL,l_BDSC+(40*l_BW)
	LD BC,(l_VISH-8)*l_BW
	LDIR
	LD HL,l_X0
	INC (HL)
	INC HL
	INC (HL)
	LD A,(l_FLR)
	OR A
	JR NZ,l_DLN
	INC A
	CALL l_FLOOR
	CALL l_DLN
	XOR A
	CALL l_FLOOR
l_DLN	LD HL,l_X0
	LD A,15+((l_VISH-128)/8)
	ADD A,(HL)
	LD (l_TTX),A
	INC HL
	LD A,15+((l_VISH-128)/8)
	ADD A,(HL)
	LD (l_TTY),A
	LD HL,l_BDSC+((24+l_VISH)*l_BW)+1
	JR l_UL_

l_URT	CALL LAY_FALL
	LD DE,l_BDSC+((32+l_VISH)*l_BW)-1	;скролл вверх
	LD HL,l_BDSC+((24+l_VISH)*l_BW)-1
	LD BC,(l_VISH-8)*l_BW
	LDDR
	LD HL,l_X0
	DEC (HL)
	INC HL
	DEC (HL)
	LD A,(l_FLR)
	OR A
	JR NZ,l_ULN
	INC A
	CALL l_FLOOR
	CALL l_ULN
	XOR A
	CALL l_FLOOR
l_ULN	LD HL,(l_X0)
	LD (l_TTX),HL
	LD HL,l_BDSC+(32*l_BW)+1
l_UL_	LD A,(l_SH)
	OR A
	JR NZ,l_UL10
	INC HL
l_UL10	LD (l_UDHL),HL
	LD HL,96
	LD (l_NSH),HL
	LD C,4
l_UL0	LD HL,(l_UDHL)
	LD DE,(l_TTX)
	LD (l_TX),DE
	CALL l_UDL2
	LD HL,(l_UDHL)
	DEC HL
	LD DE,(l_TTX)
	INC D
	LD (l_TX),DE
	CALL l_UDL
	LD HL,(l_NSH)
	LD DE,32
	OR A
	SBC HL,DE
	LD (l_NSH),HL
	LD HL,(l_TTX)
	INC H
	INC L
	LD (l_TTX),HL
	DEC C
	JR NZ,l_UL0
	LD HL,-16
	LD (l_NSH),HL
	LD HL,(l_UDHL)
	LD DE,4*l_BW
	ADD HL,DE
	LD DE,(l_TTX)
	LD (l_TX),DE
	CALL l_UDL2
	RET

l_UDL	LD B,l_BCELL
l_UD0	CALL l_ASP
	JR Z,l_U_D0
	CALL l_NSP
l_U_D0	LD DE,(l_TX)
	DEC D
	INC E
	LD (l_TX),DE
	INC HL
	INC HL
	DJNZ l_UD0
	RET

l_UDL2	LD B,l_BCELL
l_UD2	CALL l_ASP
	JR Z,l_U_D2
	CALL l_NSP2
l_U_D2	LD DE,(l_TX)
	DEC D
	INC E
	LD (l_TX),DE
	INC HL
	INC HL
	DJNZ l_UD2
	RET

l_PSP	;задать N спр
	EX AF,AF'
	CALL l_GSP
	CP 2
	RET C
	EXX
	EX AF,AF'
	LD (HL),A
	EXX
	RET

l_ATSP	;получить атрибуты из xATR
	CALL l_GSP
	AND #7F
l_ATSP_	EXX
	LD E,A
	LD D,l_xATR/256
	LD A,(DE)
	EXX
	RET

l_ATSPM	;взять атрибуты с учётом героев
	CALL l_GSP
	AND #7F
	CP #60
	JR C,l_ATSP_
	SUB #60
	EXX
	RLCA
	RLCA
	RLCA
	LD D,0
	SLA A
	RL D
	SLA A
	RL D
	ADD A,7
	LD E,A
	LD A,D
	ADD A,l_MAN/256
	LD D,A
	LD A,(DE)
	AND #7F
	JR l_ATSP_+1

l_GS_4x4	LD A,63
	CP H
	DEFB #38,#14	;JR C,G00
	CP L
	DEFB #38,#11	;JR C,G00
	LD A,L
	RLCA
	RLCA
	SRL H
	RRA
	SRL H
	RRA
	LD L,A

l_GS_8x2	LD A,31
	CP H
	DEFB #38,#14	;JR C,G00
	LD A,127
	CP L
	DEFB #38,#0F	;JR C,G00
	RLC L
	SRL H
	RR L
	NOP
	NOP

l_SET4x4	LD HL,#3F3F	;уст.поле 64х64
	LD DE,l_GS_4x4
	JR l_SETxxx
l_SET8x2	LD HL,#1F7F	;уст.поле 128х32
	LD DE,l_GS_8x2
l_SETxxx	LD (l_XMAX),HL
	EX DE,HL
	LD DE,l_GSPdim
	LD BC,18
	LDIR
	RET

l_GSP	EXX	;получить N спр
	LD HL,(l_TX)
l_GSPdim	LD A,63
	CP H
	JR C,l_G00
	CP L
	JR C,l_G00
	LD A,L
	RLCA
	RLCA
	SRL H
	RRA
	SRL H
	RRA
	LD L,A
l_GS1	LD A,#F0	;map #F000/#E000
	OR H
	LD H,A
	LD A,(HL)
	EXX
	RET
l_G00	LD A,1	;Вне поля
	EXX
	RET

	;AinvX- #AA(XOR D)-норм.,#0(NOP)-только маска
	;возвр: Z-0й спрайт DE-адр А-номер
l_ASP	CALL l_GSP
	LD D,A
	RLCA
	LD A,(l_Ainv1)
	JR C,l_A2P
	OR A
	JR NZ,l_A22P
	LD A,#AE
	JR l_A21P
l_A2P	OR A
	JR Z,l_A22P
	XOR A
l_A21P	LD (l_Ainv1),A
	LD (l_Ainv2),A
	LD (l_Ainv3),A
	LD (l_Ainv4),A
l_A22P	LD A,D
l_A22P_	LD E,0
	AND #7F
	PUSH AF
	CP #60
	JR NC,l_A4P
	SRL A
	RR E
	ADD A,#B0	;sprites
	LD D,A
	POP AF
	RET
l_A4P	POP AF
	SUB #60
	m_PUSH_S
	PUSH IX
	CALL l_GET_IX
	LD (l_HIX),IX
	CALL l_HERLIV
	JR NZ,l_A7PLIV
	LD A,(IX+4)
	CALL l_M96
	LD DE,l_xDIE
	JR l_A6P
l_A7PLIV	LD A,(IX+6)	;visi
	OR A	;
	LD A,(IX+7)	;
	JR Z,l_A9P	;
	POP IX
	m_POP_S
	JR l_A22P_
l_A9P	CALL l_NORM_V
	LD A,(IX+3)
	CALL l_M96
	ADD HL,HL
	LD A,(IX+4)
	RLCA
	LD D,A
	RLCA
	ADD A,D
	ADD A,H
	LD H,A
	LD DE,l_xHERO
l_A6P	ADD HL,DE
	PUSH HL
	LD A,(IX+7)
	AND #7F
	LD L,0
	SRL A
	RR L
	ADD A,#B0
	LD H,A
	LD DE,l_DATR
	LD BC,128
	LDIR
	POP HL
	LD DE,l_DATR+16
	m_M_S 4
	LD B,48
l_A5P	LD A,(DE)
	OR (HL)
	LD (DE),A
	INC DE
	LD A,(DE)
	CPL
	OR (HL)
	CPL
	INC HL
	OR (HL)
	LD (DE),A
	INC DE
	INC HL
	DJNZ l_A5P
	CALL l_PT128
	POP IX
	m_POP_S
	LD DE,l_DATR
	LD A,#60
	OR A
	RET	;NZ

l_M96	LD L,A
	RLCA
	ADD A,L	;x3
	RLCA	;x6
	RLCA	;x12
	LD L,A
	LD H,0
	ADD HL,HL	;x24
	ADD HL,HL	;x48
	ADD HL,HL	;x96
	RET

l_MSizeP	m_push_S
	CALL l_ASP
	JR Z,l_MSiRET
	PUSH HL
	LD B,l_vSIZE/256
	OR #80	;(vSIZE mod 256)
	LD C,A
	LD A,(BC)
	LD H,0
	ADD A,A
	ADD A,A
	ADD A,A
	LD L,A
	RRCA
	ADD A,E
	LD E,A
	PUSH DE
	LD D,H
	LD E,L
	ADD HL,HL
	ADD HL,HL
	ADD HL,DE
	SRL D
	RR E
	ADD HL,DE
	POP DE
	LD A,(BC)
	POP BC
	ADD HL,BC
	CPL
	ADD A,33
	LD B,A
	JP l_MS2

l_BSP	m_push_S
	JP l_MS2

l_NSP	m_push_S
	LD BC,(l_NSH)
	EX DE,HL
	ADD HL,BC
	EX DE,HL
	LD B,8
	JP l_MS2

l_NSP2	m_push_S
	EX DE,HL
	LD BC,(l_NSH)
	ADD HL,BC
	LD BC,16
	ADD HL,BC
	EX DE,HL
	LD B,4
	LD A,(l_NSH)
	CP 96
	JR Z,l_MS2
	CP -16
	JR Z,l_MS2
	LD B,8
	JP l_MS2

l_MSP	m_push_S
	LD B,32
l_MS2	CALL LAY_FD2
	EX DE,HL
l_MS20	LD A,(DE)
	OR (HL)
	INC HL
l_Ainv1	XOR (HL)
	INC HL
	LD (DE),A
	INC DE
	LD A,(DE)
	OR (HL)
	INC HL
l_Ainv2	XOR (HL)
	INC HL
	LD (DE),A
	LD A,E
	ADD A,l_BW-1
	LD E,A
	JR NC,$+3
	INC D
	DJNZ l_MS20
	EX DE,HL
l_MSiRET	m_pop_S
	RET

l_LSP	m_push_S
	LD B,32
l_LS2	CALL LAY_FD1
	EX DE,HL
l_LS20	LD A,(DE)
	OR (HL)
	INC HL
l_Ainv3	XOR (HL)
	INC HL
	LD (DE),A
	INC HL
	INC HL
	LD A,E
	ADD A,l_BW
	LD E,A
	JR NC,$+3
	INC D
	DJNZ l_LS20
	EX DE,HL
	m_pop_S
	RET

l_RSP	m_push_S
	LD B,32
l_RS2	CALL LAY_FD1
	EX DE,HL
l_RS20	INC HL
	INC HL
	LD A,(DE)
	OR (HL)
	INC HL
l_Ainv4	XOR (HL)
	INC HL
	LD (DE),A
	LD A,E
	ADD A,l_BW
	LD E,A
	JR NC,$+3
	INC D
	DJNZ l_RS20
	EX DE,HL
	m_pop_S
	RET

l_RSPB	m_push_S
	JR l_RS2

l_LSPB	m_push_S
	JR l_LS2

l_ALLSPF	LD BC,0
	CALL LAY_FDC
l_ALLSH	CALL l_ALLS0
	PUSH BC
	PUSH AF
	LD BC,0
	CALL LAY_FDC
l_ALLSE	POP AF
	POP BC
	RET
l_ALLS0	LD A,(l_FLR)	;вывод обоих этажей
	OR A
	JR NZ,l_ALLSP
	INC A
	CALL l_FLOOR
	CALL l_ALLSP
	XOR A
	CALL l_FLOOR
l_ALLSP	LD HL,l_BDSC+(4*l_BW)+2
	LD A,(l_SH)
	OR A
	JR Z,l_AP1
	DEC HL
l_AP1	LD DE,(l_X0)
	LD (l_TX),DE
	LD C,l_BROWS
l_AP2	LD B,l_BCELL
	PUSH DE
l_AP3	CALL l_MSizeP
	LD DE,(l_TX)
	INC E
	DEC D
	LD (l_TX),DE
	INC HL
	INC HL
	DJNZ l_AP3
	LD DE,(4*l_BW)-(2*l_BCELL)-1
	ADD HL,DE
	POP DE
	INC D
	LD (l_TX),DE
	PUSH DE
	LD B,l_BCELL
l_AP4	CALL l_MSizeP
	LD DE,(l_TX)
	INC E
	DEC D
	LD (l_TX),DE
	INC HL
	INC HL
	DJNZ l_AP4
	LD DE,(4*l_BW)-(2*l_BCELL)+1
	ADD HL,DE
	POP DE
	INC E
	LD (l_TX),DE
	DEC C
	JR NZ,l_AP2
	RET

l_DSC3	LD B,8
	PUSH DE
l_DS3	PUSH DE
	PUSH BC
	INC DE
	LDI
	LDI
	LDI
	LDI	;4
	LDI
	LDI
	LDI
	LDI	;8
	LDI
	LDI
	LDI
	LDI	;12
	LDI
	LDI
	LDI
	LDI	;16
	LDI
	LDI
	LDI
	LDI	;20
	LDI
	LDI
	LDI
	LDI	;24
	LDI
	LDI
	LDI
	LDI	;28
	LD DE,4
	ADD HL,DE
	POP BC
	POP DE
	INC D
	DJNZ l_DS3
	POP DE
	LD A,32
	ADD A,E
	LD E,A
	DEC C
	JR NZ,l_DSC3
	RET

l_OUTDSC	CALL l_MEM7
	JP LAY_OUTD
	LD DE,l_SCR+32
	LD HL,(l_DSCR+1024)+2
	LD C,7
	CALL l_DSC3
	LD DE,l_SCR+2048
	LD C,8
	CALL l_DSC3
	LD DE,l_SCR+4096
	LD C,1
	CALL l_DSC3
	JP l_PT128

l_FLR	EQU l_G00+1	;этаж 1-1й 0-2й
l_FLOOR	OR A	;сменить этаж на А(0-2Й;1-1Й)
	LD A,(l_FLR)
	JR NZ,l_FLO2
	OR A
	RET Z
	XOR A	;2й
	LD (l_FLR),A
	PUSH BC
	LD C,3
	LD A,#E0
l_FLO_	LD (l_GS1+1),A
	LD A,(l_X0)
	ADD A,C
	LD (l_X0),A
	LD A,(l_Y0)
	ADD A,C
	LD (l_Y0),A
	POP BC
	RET
l_FLO2	OR A
	RET NZ
	INC A
	LD (l_FLR),A
	PUSH BC
	LD C,-3
	LD A,#F0
	JR l_FLO_

l_LCOUNT	LD DE,l_vSIZE	;подсчёт высоты
	LD HL,#B000
	LD B,96
l_LCX	PUSH BC
	PUSH HL
	LD BC,#1F00
l_LCX0	LD A,(HL)
	OR A
	JR NZ,l_LCX2
	INC HL
	INC HL
	LD A,(HL)
	OR A
	JR NZ,l_LCX2
	INC HL
	INC HL
	INC C
	DJNZ l_LCX0
l_LCX2	LD A,C
	LD (DE),A
	INC DE
	POP HL
	LD BC,128
	ADD HL,BC
	POP BC
	DJNZ l_LCX
	XOR A
	LD (DE),A
	RET

