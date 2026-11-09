	;Начальные установки и защита
l_DELRET	LD HL,l_START1
	LD DE,l_START1+1
	LD (HL),H
	LD BC,(l_START2-l_START1)-2
	LDIR
	RET
l_START1
	LD HL,l_start
	LD (l_JP_ST+1),HL
	;------------защита проц боя
	;4 - пров свопперов
	LD DE,l_LQWE-l_MAN
	LD BC,((l_B_LOOP-l_LQWE)*256)+8
	LD IX,l_MAN
	ADD IX,DE
l_prt4_	LD A,(IX+2)
	OR A
	JR Z,l_prt44_
	ADD A,C
	LD C,A
l_prt44_	INC IX
	DJNZ l_prt4_
	LD (l_CRC4),A
	;
	CALL l_SWPBAT
	CALL l_LDASM1
	CALL l_LDASM2
	;------------защита проц меню/карты
	;2
	m_M_S 0
	LD HL,l_SCR
	PUSH HL
	LD BC,#2000
	ADD HL,BC
	POP DE
l_prt1	LD A,(DE)
	CP (HL)
	JR Z,l_prt1_
	DEC C
	ADD A,B
	ADD A,(HL)
	LD B,A
l_prt1_	INC HL
	INC DE
	LD A,H
	OR L
	JR NZ,l_prt1
	LD (l_CRC2),BC
	;3
	LD HL,#FF02
	LD (l_TX),HL
	XOR A
	CALL l_MEM
	XOR A
	LD C,A
	ADD A,#3D
	LD B,A
l_prt3_	LD DE,l_TY
	LD A,(DE)
	EXX
	LD HL,l_TX
	SUB (HL)
	LD (HL),A
	EXX
	LDD
	JP PE,l_prt3_
	LD A,(l_TX)
	LD (l_CRC3),A
	;
	CALL l_MEM7
	JP l_DELRET
l_START2	LD A,R
	JR l_STRT2
	DEFM "*** Hello, my dear! You find hidden entry in my subject! ***"
	DEFM " (812)1433303 *** UFO-2 by Vyacheslav Mednonogov (c)1996 ***"
l_STRT2	LD (l_RNB),A
	LD (l_NX_RNB),A
	;------------созд игр данных
	m_M_S 3
	LD HL,l_DATA
	LD DE,l_NEWDAT
	LD B,6
l_JJ0	PUSH BC
	PUSH HL
l_JJ1	CALL l_RND
	CP 192
	JR NC,l_JJ1
	INC A
	LD (l_N_AQU),A
	CALL l_RND
	LD (l_RNBgen),A
	CALL l_RND
	LD (l_RNAgen+1),A
	AND #F
	INC A
	LD (l_TARoff),A
	LD BC,480
	LDIR
	POP HL
	POP BC
	DJNZ l_JJ0
	JP l_MEM7
