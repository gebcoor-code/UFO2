l_MXDM	DEFM "////////////////////////"	;табл.альтернатив

l_ZT	DEFW l_Z0,l_Z1,l_Z2,l_Z3,l_Z4,l_Z5,l_Z6,l_Z7,l_Z8,l_Z9,l_ZA,l_ZB,l_ZC,l_ZD,l_ZE,l_ZT
l_MBU2	EQU #DB00	;(1024B-128)  ;
l_MBU	EQU #DE80	;(48B/128)   ;Pg7
l_ScrBU	EQU #DF00	;(1728B/1792)  ;
l_SwpMEM	EQU #E600	;(6656B)   ;
l_SwpADR	EQU #7580	;swap-адр

l_MBEG	DEFB 1	;у-1я стр. меню
l_MEND	DEFB 22	;у-последняя
l_MOLD	DEFB 255	;у-текущая предыдущая
l_MTMP	DEFB 255	;у-текущая
l_MPOS	DEFB 0	;пункт меню [0..MEND-MBEG]
l_MXSH	DEFB 1	;x-отступ
l_MLEN	DEFB 2	;ширина пункта меню
l_MC21	DEFB 1	;0-восстановить строки 21-23
l_TXM	DEFW 0	;текст меню
l_MCOLOR	DEFB 0	;цвет

	;команды: 0-набор WORDS, 1/2-высота 1/2, 3/4-центрир.фраза/слово(N),
	; 5-ВК/ПС, 6/7-нецентрир.фраза/слово(N),8/9/<?>-вывод byte,word,double,
	; <->/<.>/<,>-меню по усл."равно"/"неравно"/без условия
	; <:>-набор NAMES

l_MENU	PUSH IX
	CALL l_STD
	LD HL,l_MTXTM
	LD (l_MTXT+1),HL
	LD HL,l_MTX0M
	LD (l_MTX0+1),HL
	LD HL,#FFFF
	LD (l_MOLD),HL
	LD (l_MBEG),HL
	LD L,(IX)
	INC L
	INC IX
	LD H,(IX)
	LD (l_SX),HL
	INC IX
	LD A,(IX)
	LD (l_MLEN),A
	INC IX
	LD A,(l_C_ONOF)
	OR A
	LD A,#38
	JR NZ,l_Coff
	LD A,(IX)
	LD HL,l_DMCOL
	CALL l_BT
l_Coff	LD (l_MCOLOR),A
	XOR A
	LD (l_HIGH),A
	LD A,(l_SX)
	LD (l_MXSH),A

	m_M_S 1
	LD HL,l_MENUS
	LD A,(IX)
	INC IX
	OR A
	JR Z,l_JF
	LD B,A
l_JH	LD A,(HL)
	INC HL
	CP #7F
	JR NZ,l_JH
	DJNZ l_JH
l_JF	LD (l_TXM),HL
	CALL l_MTOP
	CALL l_MTXT
	LD HL,l_WORDS
	LD (l__words),HL
	XOR A
	LD (l_HIGH),A
	POP IX
	JR l_MBOT

l_BLNK	m_PUSH_S
	LD DE,(l_SX)
	LD A,(l_MXSH)
	LD E,A
	INC D
	LD (l_SX),DE
	DEC E
	LD BC,l_FONT
	LD L,104
	LD A,1
	CALL l_SYMBOL
	LD A,(l_MLEN)
	LD L,15
	CALL l_SYMBOL
	LD A,1
	LD L,111
	CALL l_SYMBOL
	CALL l_MPAI
	m_POP_S
	RET

l_MTOP	LD DE,(l_SX)
	DEC E
	LD BC,l_FONT
	LD A,1
	LD L,106
	CALL l_SYMBOL
	LD A,(l_MLEN)
	LD L,105
	CALL l_SYMBOL
	LD A,1
	LD L,107
	CALL l_SYMBOL
	JR l_MPAI

l_MBOT	LD DE,(l_SX)
	DEC E
	LD BC,l_FONT
	LD A,1
	LD L,108
	CALL l_SYMBOL
	LD A,(l_MLEN)
	LD L,110
	CALL l_SYMBOL
	LD A,1
	LD L,109
	CALL l_SYMBOL

l_MPAI	LD HL,(l_SX)
	DEC L
	LD BC,(l_MLEN-1)
	INC B
	INC B
	LD C,1
	LD A,(l_MCOLOR)
	JP l_ATRBAR

l_MTXTM	CALL l_BLNK
	LD HL,(l_TXM)
	LD A,(HL)
	OR #80
	INC A
	RET Z
	CALL l_BLNK
	LD HL,l_SY
	DEC (HL)
l_MTX0M	LD HL,(l_TXM)
	LD A,(HL)
	INC HL
	LD (l_TXM),HL
	LD HL,l_ZT
	CALL l_WT
	JP (HL)

l_MTX0	JP l_MTX0M
l_MTXT	JP l_MTXTM

l_Z0	LD HL,l_WORDS
l_Z0E	LD (l__words),HL
	JR l_MTX0
l_ZE	LD HL,l_NAMES
	JR l_Z0E
l_Z1	XOR A
	JR l_Z2_1
l_Z2	LD A,#1
l_Z2_1	LD (l_HIGH),A
	JR l_MTX0
l_Z5	LD A,(l_HIGH)
	OR A
	JR Z,l_MTXT
	LD HL,l_SY
	INC (HL)
	JR l_MTXT
l_Z6	LD HL,(l_TXM)
	CALL l_WORDHL
	LD HL,(l_TXT)
	LD (l_TXM),HL
	JP l_MTX0
l_Z7	LD A,(IX)
	INC IX
	CALL l_NWRD
	JP l_MTX0
l_Z8	LD L,(IX)
	LD H,(IX+1)
	INC IX
	INC IX
	CALL l_WBHL
	JP l_MTX0
l_Z9	LD L,(IX)
	LD H,(IX+1)
	INC IX
	INC IX
	CALL l_WW
	JP l_MTX0
l_ZA	LD L,(IX)
	INC IX
	LD H,(IX)
	INC IX
	CALL l_WD
	JP l_MTX0

l_Z3	LD HL,(l_TXM)
	LD (l_TXT),HL
	LD B,-1
l_Z33	LD A,(HL)
	INC HL
	INC B
	CP 128
	JR C,l_Z333
	INC B
l_Z333	CP 126
	JR NZ,l_Z33
	LD (l_TXM),HL
	LD A,(l_MLEN)
	SUB B
	SRL A
	LD DE,(l_SX)
	ADD A,E
	LD E,A
	LD (l_SX),DE
	CALL l_WORD
	JP l_Z5

l_Z46	LD E,B
	LD A,126
	LD B,A
l_Z46a	CPIR
	DEC E
	JR NZ,l_Z46a
	PUSH HL
	LD B,-1
l_Z47	LD A,(HL)
	INC HL
	INC B
	CP 128
	JR C,l_Z48
	INC B
l_Z48	CP 126
	JR NZ,l_Z47
	LD A,(l_MLEN)
	SUB B
	SRL A
	LD DE,(l_SX)
	ADD A,E
	LD E,A
	LD (l_SX),DE
	POP HL
	JP l_WORDHL

l_Z4	LD HL,(l__words)
	LD B,(IX)
	INC IX
	CALL l_Z46
	JP l_Z5

l_ZD	XOR A
	LD (l_HIGH),A
	LD L,(IX)
	INC IX
	LD H,(IX)
	INC IX
	LD B,(IX)
	INC IX
	LD DE,l_MXDM
	LD A,(l_SY)
	LD (l_MBEG),A
	LD C,0
l_Z_3	m_PUSH_S
	LD B,(HL)
	LD HL,(l__words)
	CALL l_Z46
	m_POP_S
	INC HL
	LD A,(l_SY)
	LD (l_MEND),A
	CALL l_BLNK
	LD A,C
	LD (DE),A
	INC C
	INC DE
	DJNZ l_Z_3
	JP l_MTXT

l_ZB	LD A,#20	;jr nz
	LD (l_Z_E),A
	JR l_Z11
l_ZC	LD A,#28	;jr z
	LD (l_Z_E),A
l_Z11	XOR A
	LD (l_HIGH),A
	LD DE,l_MXDM
	LD C,0
	LD A,(l_SY)
	LD (l_MBEG),A
	DEC A
	LD (l_MEND),A
	LD L,(IX)
	INC IX
	LD H,(IX)
	INC IX
	LD B,(IX)
	INC IX
	EXX
	LD B,(IX)
	INC IX
	LD L,(IX)
	INC IX
	LD H,(IX)
	INC IX
	EXX
l_Z_1	EXX
	LD A,(HL)
	INC HL
	CP B
	EXX
l_Z_E	JR NZ,l_Z_7
	m_PUSH_S
	LD B,(HL)
	LD HL,(l__words)
	CALL l_Z46
	m_POP_S
	LD A,(l_SY)
	LD (l_MEND),A
	CALL l_BLNK
	LD A,C
	LD (DE),A
	INC DE
l_Z_7	INC C
	INC HL
	DJNZ l_Z_1
	JP l_MTXT

	;------------------------
l_SWAP_X	LD A,(HL)	;Обмен по XOR
	XOR #C6
	EX AF,AF'
	LD A,(DE)
	XOR #C6
	EX AF,AF'
	LD (DE),A
	EX AF,AF'
	LD (HL),A
	INC HL
	INC DE
	DEC BC
	LD A,C
	OR B
	JR NZ,l_SWAP_X
	RET Z

l_DECM	LD IX,l_MONEY
l_DECR	EX DE,HL
	LD L,(IX)
	LD H,(IX+1)
	EXX
	LD L,(IX+2)
	LD H,(IX+3)
	EXX
	CALL l_SUBDW
	RET C
l_IM3	LD (IX),L
	LD (IX+1),H
	EXX
	LD (IX+2),L
	LD (IX+3),H
	EXX
	RET

l_INCM	LD IX,l_MONEY
l_INCR	EX DE,HL
	LD L,(IX)
	LD H,(IX+1)
	EXX
	LD L,(IX+2)
	LD H,(IX+3)
	EXX
	CALL l_ADDDW
	JR NC,l_IM3
	LD HL,#FFFE
	EXX
	LD HL,#0FFF	;до268млн
	EXX
	JR l_IM3

l_DD	RLCA
l_WA	RLCA
l_BA	ADD A,L
	LD L,A
	JR NC,l_BA_
	INC H
l_BA_	LD A,(HL)
	RET

l_INS	LD A,(IX)	;точка в боксе
	CP L
	RET NC
	LD A,L
	CP (IX+2)
	RET NC
	LD A,(IX+1)
	CP H
	RET NC
	LD A,H
	CP (IX+3)
	RET

l_NAL	CALL l_STD	;наличные
	LD HL,#1700
	LD (l_SX),HL
	XOR A
	LD (l_HIGH),A
	LD A,132
	CALL l_NWRDM
	LD HL,l_MONEY
	CALL l_WD
	JP l_WORD



l__words	DEFW l_WORDS	;/NAMES

l_NWRD	LD E,A
	INC E
	LD HL,(l__words)
	LD A,#7E
	LD B,A
l_NW0	CPIR
	DEC E
	JR NZ,l_NW0
	JP l_WORDHL

l_NWRDM	LD L,A
	m_M_S 1
	LD A,L
	CALL l_NWRD
	JP l_MEM7

l_BACK	LD HL,l_SCR
	LD DE,l_DSCR
	LD BC,6912
	JP LAY_MKSC

l_NOKEY	CALL l_CONTR	;ждать ненажатия
	AND %111111
	JR NZ,l_NOKEY
	LD A,14
	JP l_DELAY

l_TMOF	;ждать FIRE
	CALL l_NOKEY
l_TMOf	CALL l_CONTR
	AND %111111
	RET NZ
	JR l_TMOf
	;Цвета меню
l_DMCOL	DEFB #38,#30,#70,#4D,#69,000,000,#79,#39,#72
	DEFB #7A,#68,#38,#69,#71,#78,#6B,#7A,#72,#38
	DEFB #79,#38,#46,#68,#78,#78,#58,#30,#78,#78
	DEFB #43,#38,#38,#68,#79,#68,#38,#68,#68,#4D
	DEFB #79,#38,#46,#68,#47,#71,#56,#72,#30,#7A
	DEFB #39,#38,#69,#57,#60,#78,#7A,#38,#38,#71
	DEFB #60,#79,#30,#7A,#7A,#78,#78,#78,#7A,#57
	DEFB #7A,#7A,#38,#69,#71,#78,#7A,#79,#72,#79
	DEFB #71,#7A,#38,#38,#39,#78,#38,#38,#38,#38
	DEFB 000,000,000,#4F,#6A,#7A,#38,#38

	;============параметры ландшафта
l_L_LAND	DEFB 1	;ТИП ландшафта (0-7,8-КолонII,9-UбазаII,10-корабльII)
l_L_UFO	DEFB 6	;тип НЛО (0..8)
l_L_MOD	DEFB 1	;модификация ландш.
l_L_IPOS	DEFW 1	;поз.истр
l_B_RET	DEFB 1	;рез-т боя(0/1/2-гибель/эвак/победа)
	;===========пришельцы
l_A_RASA	DEFB 4	;раса(1..5)
l_A_NUM	DEFB 22	;макс число (4..22)
	;===============================

l_WEAPON	;парам оруж(TU,TUp,PREC,PRECp,HE,FR,Quantity,POWER)
	DEFB 25,50,60,90,32,0,25,0
	DEFB 45,90,50,110,90,0,6,1
	DEFB 90,90,120,120,210,0,5,2
	DEFB 55,75,70,120,0,120,6,0
	DEFB 40,75,60,90,60,0,16,1
	DEFB 30,30,100,100,80,0,0,0
	DEFB 25,25,100,100,150,0,0,0
	DEFB 45,80,50,100,105,0,15,3
	DEFB 40,60,75,110,75,0,25,2
	DEFB 50,70,80,115,130,0,14,3
	DEFB 45,45,100,100,120,0,0,2
	DEFB 40,40,100,100,0,80,0,0
	DEFB 40,60,70,105,0,0,7,0
	DEFB 45,45,100,100,0,0,0,0
	DEFB 24,24,100,100,0,0,0,0
	DEFB 0,0,0,0,60,0,0,2	;для взрыв.предм
	DEFB l_TIM_6,l_TIM_6,100,100,0,0,0,0	;для тентак
	;Цена выстрела
l_WP_PRC	DEFW 55,900,3500,2400,550,0,0,1100,700,950,0,300,0,0,0

l_ATRB2	INC H
	INC H
	JP l_ATRBAR

l_B_DRAW	DEFB 0	; 0 -из меню, 1 -из боя
l_SOLDAT	DEFB 0
l_SOLD_D	DEFW 0
l_Db	DEFB 1

l_HLINE	PUSH HL
	PUSH BC
	LD A,L
	SUB E
	INC A
	LD B,A
	CALL l_PCOORD
	LD A,E
	AND 7
	INC A
	LD C,1
l_HL1	RRC C
	DEC A
	JR NZ,l_HL1
l_HL2	OR C
	RRC C
	JR NC,l_HL3
	XOR (HL)
	LD (HL),A
	INC L
	XOR A
l_HL3	DJNZ l_HL2
	XOR (HL)
	LD (HL),A
	POP BC
	POP HL
	RET

l_DRAW_P	LD IX,(l_SOLD_D)
	;----рис.поле.параметров
	CALL l_OFFD
	CALL l_STD
	LD A,#13
	LD (l_Db),A
	LD (l_HIGH),A
	LD B,6
	LD HL,#40A
	PUSH IX
	m_CHN_S l_XOR_
l_DWP	PUSH BC
	PUSH HL
	LD (l_SX),HL
	LD A,(IX+3)
	CALL l_WB
	LD A,(l_Db)
	ADD A,16
	LD (l_Db),A
	LD D,A
	LD E,#70
	LD H,0
	LD L,(IX+3)
	INC L
	INC IX
	ADD HL,DE
	LD B,11
l_DR4	CALL l_HLINE
	INC H
	INC D
	DJNZ l_DR4
	POP HL
	INC H
	INC H
	POP BC
	DJNZ l_DWP
	POP IX
	m_M_S 3
	CALL l_STD
	m_ATR_S 0,#2018,#28	;всё
	LD BC,#1C04
	LD A,#30	;Ф.И.О.
	CALL l_ATRBAR
	m_ATR_S #400,#40C,#79	;оруж
	LD B,4
	LD DE,l_xWBUTT
l_P12	PUSH BC
	LD BC,#403
	CALL l_PUTSIM
	INC H
	INC H
	INC H
	POP BC
	DJNZ l_P12
	m_ATR_S #406,#30C,#72	;парам
	LD B,3
	LD DE,l_xPARAM
	CALL l_PUTSIM
	LD HL,#20E
	LD BC,#E02
	LD A,#38	;парам.линии
	CALL l_ATRB2
	LD A,#70
	CALL l_ATRB2
	LD A,#58
	CALL l_ATRB2
	LD A,#78
	CALL l_ATRB2
	LD A,#60
	CALL l_ATRB2
	LD A,#68
	CALL l_ATRB2
	LD B,4
	LD DE,l_xBUTTO
	LD HL,28
l_P14	PUSH BC
	LD BC,#404
	CALL l_PUTSIM
	LD A,4
	ADD A,H
	LD H,A
	POP BC
	DJNZ l_P14
	LD BC,#202
	LD HL,#FD1D
	LD DE,l_xLABEL
	CALL l_PBL
	LD DE,(4*32)+l_xLABEL
	CALL l_PBL
	LD DE,(24*32)+l_xLABEL
	CALL l_PBL
	LD DE,(3*32)+l_xLABEL
	CALL l_PBL
	LD E,(IX+1)
	LD L,(3*3)*8
	CALL l_MULB
	LD HL,l_xSIGN
	ADD HL,DE
	PUSH HL
	m_ATR_S #1100,#303,#70	;звание
	POP DE
	CALL l_PUTSIM
	LD E,(IX+2)
	LD L,(3*3)*8
	CALL l_MULB
	LD HL,(24*24)+l_xSIGN
	ADD HL,DE
	PUSH HL
	m_ATR_S #110F,#303,#78	;защита
	POP DE
	CALL l_PUTSIM
	LD B,4	;оружие
	PUSH IX
	LD A,(l_B_DRAW)
	OR A
	JR Z,l_DR50
	LD A,17-9	;(из боя)
	CALL l_HER_BA
	PUSH HL
	POP IX
l_DR50	LD HL,#2400
l_DR5	PUSH BC
	LD A,(IX+9)
	INC IX
	CP 255
	JR Z,l_DR6
	PUSH HL
	LD L,A
	LD E,(4*2)*8
	CALL l_MULB
	LD HL,l_xWEAPO
	ADD HL,DE
	EX DE,HL
	POP HL
	LD BC,#410
	CALL l_PUTSCR
l_DR6	LD A,H
	ADD A,24
	LD H,A
	POP BC
	DJNZ l_DR5
	POP IX
	LD A,2
	LD (l_HIGH),A
	LD A,(IX+1)
	LD HL,#1204
	LD (l_SX),HL
	ADD A,80
	CALL l_NWRDM
	LD A,#13
	LD (l_SX),A
	LD A,(IX+2)
	OR A
	JR Z,l_DW1
	ADD A,14
	JR l_DW2
l_DW1	LD A,160
l_DW2	CALL l_NWRDM
	LD HL,#101
	LD (l_SX),HL
	LD HL,l_NAMES
	LD (l__words),HL
	LD A,(IX)
	DEC A
	CALL l_NWRDM
	LD HL,l_WORDS
	LD (l__words),HL
	XOR A
	LD (l_HIGH),A
	m_WRD_S #1104,158
	m_WRD_S #1113,159
	JP l_MEM7

l_PBL	INC H
	INC H
	INC H
	INC H
	JP l_PUTSIM

l_SELM	LD HL,l_SELmr	;Выбор без выводa инф.
l_SELTX	LD (l_sx1+1),HL	;HL-Sub.ADR
	LD (l_sx2+1),HL
	CALL l_MEM7
	CALL l_INIMNU	;Выбор c выводом инф.
	CALL l_MENUC
l_SELTN	CALL l_MARK_
	JR C,l_SELTN
	LD A,(l_MPOS)
l_sx2	CALL 15635
l_selm_	CALL l_MARK
	PUSH AF
l_sx1	CALL 15635
	POP AF
	JR NC,l_selm_
	CP 254
	RET NC	;NC-отмена
	LD HL,l_MXDM
	CALL l_BA
	SCF
l_SELmr	RET

l_E_I	m_push_S
	EI
	HALT
l_EIDI	DI
	m_pop_S
	RET

l_YES_NO	JP LAY_YN

l_RESNUM	;выч числа иссл 
	LD HL,l_RS
	LD BC,#5000
l_RESU1	LD A,(HL)
	INC HL
	OR A
	JR NZ,l_RESU2
	INC C
l_RESU2	DJNZ l_RESU1
	LD A,C
	SUB #1F
	RET


	;===================================

l_VICTRY	;полная победа
	CALL l_LDASM3
	CALL l_POBEDA
	CALL l_LDASM2
	CALL l_NW_GE
	CALL l_OFFS
	CALL l_MLOOP

l_WAREND	DEFB 0	;не 0 - нет Пси-контр
l_BATRES	DEFB 2	;рез-т боя
l_BATTL_	CALL l_PREBAT	;один бой
	CALL l_LDASM3
	CALL l_L_Land
	CALL l_L_OFF
	CALL l_SWPBAT
	CALL l_PT128
	LD (l_BATRET+1),SP
	CALL l_COMBAT
l_BATRET	;A=0-гибель,1-эвак.,2-победа
	LD SP,#4022
	LD (l_BATRES),A
	PUSH AF
	CALL l_PICK
	CALL l_TO_INT
	CALL l_SWPBAT
	CALL l_LDASM1
	CALL l_LDASM2
	CALL LAY_GEO
	POP AF
	RET

l_L_ON	LD HL,#E000	;[]-откр поле
	LD BC,#2000
	LD A,(l_xHACK)
	CP #7F
	RET NZ
l_LQWE	RES 7,(HL)
	INC HL
	DEC BC
	LD A,C
	OR B
	JR NZ,l_LQWE
	RET

	;LODT DEFW LESHA,ASMBL1,ASMBL2
	;LODLEN DEFW #1500,#1500,#1800
	;LODLPc  PUSH AF
	; LD HL,LODLEN
	; CALL WT
	; POP AF
	; PUSH HL
	; LD HL,LODT ;без компр
	; CALL WT
	; XOR A
	; CALL MEM
	; POP BC
	; LDIR
	; RET

l_LODLPc	LD HL,#4000	;c компр
	CALL l_WT
	XOR A
	CALL l_MEM
	JP l_DELPC

l_BATREE	LD (l_WAREND),A
	JR l_BATRET

l_SWPBAT	CALL l_MEM7
	LD DE,l_SwpADR
	LD HL,l_SwpMEM
	LD BC,#1A00
	JP l_SWAP_X

l_LDASM1	LD DE,#AB00
	LD A,1
	JR l_lda
l_LDASM3	LD DE,l_SwpADR
	LD A,3
	JR l_lda
l_LDASM2	LD DE,l_SwpADR
	LD A,2
l_lda	CALL l_LODLPc
	JP l_MEM7

l_LODALX	LD DE,l_DSCR
	PUSH DE
	XOR A
	CALL l_LODLPc
	CALL l_PT128
	LD BC,#1500
	POP HL
	LD DE,#B000
	LDIR
	RET

l_B_LOOP	;вызов 1-3х этапов боя
	CALL l_CLEAR
	LD A,(l_T_TYPE)
	CP 7
	JR C,l_BP1
	LD A,5
	CALL l_BAT_A
	CP 2
	JP C,l_SMERT
	LD A,8
	CALL l_BAT_A
	CP 2
	JP C,l_SMERT
	LD A,7
	CALL l_BAT_A
	CP 2
	JP C,l_SMERT
	CALL l_VICTRY
l_BP1	CALL l_BAT_A
	JP Z,l_EVAC
	JP C,l_ALLDIE
	LD A,(l_RS+57)
	OR A
	JR NZ,l_BPOK	;не знаем о нижн этажах
	LD A,(l_T_TYPE)
	CP 1
	JR Z,l_BP21
	CP 5
	JR C,l_BPOK	;нет нижн эт
	ADD A,3
	JR l_BP2
l_BP21	LD A,10
l_BP2	CALL l_BAT_A
	JP Z,l_EVAC
	JP C,l_ALLDIE
l_BPOK	CALL l_BACK
	LD IX,l_MU95
	JP l_MNU

l_MU95	DEFW #404,#5F14
l_BAT_A	LD (l_L_LAND),A
	CALL l_BATTL_
	CP 1
	RET

l_BATTLE	;бой с нло
	CALL l_SEABAT

l_BATTL1	;битва
	DI
	CALL LAY_BAT
	CALL l_NOKEY
	LD A,R
	LD (l_RNB),A
	; JR RRJR ;==
	;  LD HL,256*5+13 ;GUN
	;  LD (AQNAVT+9),HL
	;  LD HL,256*11+12 ;GUN
	;  LD (AQNAVT+11),HL
	;  LD A,1
	;  LD (T_TYPE),A

l_RRJR	CALL l_B_LOOP
	CALL l_POSTBA
	CALL l_GOhome
	JP l_MLOOP
