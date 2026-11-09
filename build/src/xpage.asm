	;содержимое страниц
	;СТРАНИЦЫ: c #C000
	;0: #C000:
	;1: #C000:T(256<),TWCMPR(256),WORDS,MENUS,PEDIA,NAMES
	;2: *main*
	;3: #C000:xSprites,xSHIP,xUFO
	;4: #C000:xHERO(12k=8*16*96),#F000:xDIE(768),#F300:xBOOM(768),#F600
	;5: *main*
	;6: *swap*
	;7: #C000:SCR,#D800:ATR,#DB00:
	SLOT 3
	PAGE 4
	ORG #C000
l_xHERO
	INCBIN "data/xhero.dat"
l_xDIE	EQU l_xHERO+#3000
l_xBOOM	EQU l_xDIE+#300
l_xBUM	EQU l_xBOOM+#300
l_xBULL	EQU l_xBUM+#480
l_xSHIP
	INCBIN "data/xm0.lpc"
	DS #FFFE-$,0	; DEFR
	SLOT 3
	PAGE 3
	ORG #C000
l_xEARTH
	INCBIN "data/xsprites.dat"
l_xWEAPO	EQU l_xEARTH+2880
l_xBUTTO	EQU l_xEARTH+3840
l_xWBUTT	EQU l_xBUTTO+128
l_xBBUTT	EQU l_xWBUTT+96
l_xSIGN	EQU l_xEARTH+4192
l_xPARAM	EQU l_xEARTH+5056
l_xKEY	EQU l_xEARTH+5536
l_xPLUS	EQU l_xKEY+576
l_xLABEL	EQU l_xEARTH+6304
l_xMAP	EQU l_xEARTH+7136
l_xMARKE
	INCBIN "data/xmarker.dat"
l_xUFO
	INCBIN "data/xm1.lpc"
l_xL0
	INCBIN "data/xl0.lpc"
l_xL1
	INCBIN "data/xl1.lpc"
	SLOT 3
	PAGE 1
	ORG #C000
l_T
	INCBIN "data/x256.dat"
l_TWCMPR
	INCBIN "data/xcompres.dat"
l_WORDS
	INCBIN "data/xword.dat"
l_MENUS
	INCBIN "data/xmenu.dat"
l_PEDIA
	INCBIN "data/xfopedia.dat"
l_NAMES
	INCBIN "data/xname.dat"
	DS #FFFE-$,0	; DEFR
	SLOT 3
	PAGE 7
	ORG #C000

	INCBIN "data/xhist.scr"
	DS 1024,0
	DEFM " No room for STS 4.x!  Please reload..."

	SLOT 3
	PAGE 0
