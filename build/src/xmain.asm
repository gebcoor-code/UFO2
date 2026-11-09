	;**** HЛО-2. Дьяволы бездны ****
;*M-
;*D-
	DEFB 0
l_SYSINI	DEFB 28	;systxt 28
l_MONINI	DEFB 1	;1/0 в ScrBU нет/есть текст
l_xHACK	DEFB #7	;F;если 7f, то видимое поле []
	INCLUDE "xlid.asm"
	INCLUDE "xgamedat.asm"
l_FONT
	INCBIN "data/xfont.dat"
l_CRC3	DEFB 11
;*L+
l_TAB100	DS 98,0	; DEFR
	DEFB #15,#88	;таблица плохих секторов
;*L-
	INCLUDE "xlib.asm"
l_CRC2	DEFW 0	;[] -crc2
l_xHAC2	DEFB #D5	;D6;если D6, то нет боя []
	INCLUDE "xlie.asm"
	;--------swap-область
	;*L+
	INCLUDE "xlin.asm"
	INCLUDE "xlim.asm"
	INCLUDE "xlik.asm"
;*L+
;*D-
	DS #8F3F-$,0	; DEFR
l_HIX	DEFW 0
l_PBU	LD DE,(l_GB_AD)	;восст
	LD A,D
	OR A
	RET Z
	XOR A
	LD (l_GB_AD+1),A
	EX DE,HL
	LD BC,#318
	CALL LAY_FDC
l_PBUH	EX DE,HL
	LD HL,l_DATR+128
	LD A,24
l_PBU1	LDI
	LDI
	LDI
	EX DE,HL
	LD BC,l_BW-3
	ADD HL,BC
	EX DE,HL
	DEC A
	JR NZ,l_PBU1
	RET
l_CSAVd	CALL l_C_SAVE
	XOR A
	JP LAY_DSK
l_CLODd	LD A,1
	CALL LAY_DSK
	JP l_C_LOAD
	DS #8F80-$,0
	DEFM " Область для размещения стека "
	DS #9000-$,#CC
;*L-
	INCLUDE "xli1.asm"
	ORG $
l_LESHA	DISP #B000
	INCLUDE "xlesha.asm"
	ENT
MOD0_E

	SLOT 3
	PAGE 0
	ORG #C000
l_ASMBL1	DISP #AB00
	INCLUDE "xlix.asm"
	ENT
MOD1_E
	ORG $
l_ASMBL2	DISP l_SwpADR
	INCLUDE "xlic.asm"
;*L+
	DEFB $/256,$ mod 256	;xlic
;*L-
	ENT
MOD2_E
	ORG $
l_ASMBL3	DISP l_SwpADR
	INCLUDE "xlif.asm"
	INCLUDE "xiod.asm"
;*L+
	DEFB $/256,$ mod 256	;xliF+xioD
;*L-
	ENT
MOD3_E

