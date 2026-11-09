; mnu.asm - (0.61.0) the start menu (UFO2.MNU's code part: assembled for MNM_A, mnu0.asm st_mnu loads and runs it;
; it returns for the game). All its screens EGA (0.61.1; build/mkmnu.py): 0 - the title picture without "LOADING."
; (data/xtitle.png), 1 - the one with the choice (data/xmenu.png: XI1 recoloured), 2 - the author (data/xauthor.png:
; XI2), 3 - Copper Feet (data/xcopper.png: XI4, its rainbow drawn anew); the original's (DANGEROU.A80) XI3 - "НЛО-2"
; in yellow - left out, the title in its place. First the title till a key, then the menu in turn as in the original;
; the original's menu music (0.64.0: M_UFO from the crack's disk - build/data/mufo.bin). Keys: "2" / Enter - the game (the title and the loading as before); "3" - the instruction
; (UFO2.INS in UFO2DOC.COM - SEADOC; "4" - ABOUT.TXT in it, 0.65.0: the stub sb_* at SB_A runs it in place of UFO2.COM, its pictures - UFO2.INP - by
; the hook dh_* at DH_A; UFO2.COM loaded again after it, "UFO2 MENU": back here); Space - the next screen.
; A screen drawn with the palette black (no half-drawn screen seen).
; The pictures past the code's records: pages MNPG..MNPG+4 (80K; 0.65.1 - 5 pages, each screen from a 256 boundary) - each screen its length (2 bytes), then its 4
; parts RLE packed (port/title.asm t_part's format; page 1 +0, +#2000, page 5 +0, +#2000); mm_tab - where (mkmnu.py
; puts it in).
MNPG    equ 12
MUSM    equ 41                          ; (0.64.0) the menu's music (the original's: M_UFO - XMUSIC, 60000) at #EA00..
SB_A    equ #BF00                       ; (past UFO2.COM - init_end - and UFO2DOC's text / its saver's #A000..#A1FF)
DH_A    equ #BA00                       ; (past UFO2DOC's font - #B000..#B7FF - and this code's image: copied from it)
        DISP MNM_A
        db "MN", low MNM_N                    ; (mnu0.asm st_mnu: this build's)
        jp mnm_go
mm_tab  dw 0, 0, 0, 0                   ; (mkmnu.py: the screens' places from the pictures' start - code's offset 6)
mnm_go  call mm_hok                                             ; (the interrupts: W3 kept - mm_w3v)
        ld de,#4000 : ld b,44 : call mf_more                    ; the music: #EA00..#FFFF (build/data/mufo.bin)
        ld a,MUSM : call mm_w3 : ld hl,#4000 : ld de,#EA00 : ld bc,#1600 : ldir
        call #EA60 : ld a,3 : call mm_w3                        ; (its INIT)
        ld a,MNPG
1       push af : ld de,#4000 : ld b,128 : call mf_more : pop af : push af : call mm_put : pop af
        inc a : cp MNPG+5 : jr c,1B
        ld de,m_mode : ld c,9 : call BDOS                       ; (CP/M told: EGA)
        ld a,(smenu) : or a : jr nz,2F
        xor a : call mm_scr                                     ; the title first
        ld a,1 : ld (mm_on),a                                   ; (the music: past the disk's reading)
        call mm_key
        jr 3F
2       ld a,1 : ld (mm_on),a
3       ld a,0 : call kb_mode
        ld hl,mn_seq+2 : jr 2F                                  ; (the menu's screen first)
1       ld hl,mn_seq
2       ld a,(hl) : inc a : jr z,1B
        dec a : push hl : call mm_scr : pop hl : inc hl : ld c,(hl) : inc hl
3       ld b,25
4       call mm_fr
        ld a,#F7 : in a,(#FE) : bit 1,a : jr z,9F               ; "2": the game
        bit 2,a : jr z,8F                                       ; "3": the instruction
        bit 0,a : jr z,7F                                       ; "1": the intro
        bit 3,a : jr z,10F                                      ; "4": about the EGA version (ABOUT.TXT)
        ld a,#BF : in a,(#FE) : rra : jr nc,9F                  ; Enter
        ld a,#7F : in a,(#FE) : rra : jr nc,5F                  ; Space: the next screen
6       djnz 4B : dec c : jr nz,3B : jr 2B
5       call mm_fr : ld a,#7F : in a,(#FE) : rra : jr nc,5B : jr 2B     ; (till Space is up)
8       push hl : push bc : ld hl,sb_ins-SB_A+sb_img : ld e,4 : call mm_doc : pop bc : pop hl : jr 6B  ; (back: no UFO2DOC.COM / UFO2.INS)
10      push hl : push bc : ld hl,sb_abt-SB_A+sb_img : ld e,8 : call mm_doc : pop bc : pop hl : jr 6B  ; (ABOUT.TXT)
7       push hl : push bc : call mm_int : pop bc : pop hl : jr 6B
9       call mm_clr                                             ; black: the title picture next (t_show)
        call mm_unh
        di : ld a,3 : SHOWSCR : ld a,VM_EGA : call vmode : ei
        ld a,2 : jp kb_mode
mn_seq  db 0,15, 1,28, 0,20, 2,24, 0,16, 3,22, #FF     ; (the screen, its time: 25 frames each; DANGEROU.A80 LO1)
; HALT, then EGA mode again (CP/M's interrupt handler may put its own mode into #FD77 - 0.60.2)
mm_fr   halt : push bc : ld a,VM_EGA : call vmode : pop bc : ret
; a key (CP/M's keyboard) or a mouse button (till it is up)
mm_key  halt : ld bc,#FADF : in a,(c) : cpl : and 3 : jr nz,1F
        ld e,#FF : ld c,6 : call BDOS : or a : jr z,mm_key : ret
1       in a,(c) : cpl : and 3 : jr nz,1B : ret
;---- (0.64.0) the menu's music: its own IM2 vector (I = high mm_vec: in this code - CP/M's is in W3, page 3: not
; there with W3 another page) -> mm_ih: the player (page MUSM in W3), then CP/M's handler (W3 = page 3; its EI : RET
; back here), then W3 as it was (mm_w3v): the screens unpacked with the interrupts on - the music doesn't stop
mm_hok  ld a,(mm_hk) : or a : ret nz
        di
        IFDEF NEDOOS                                            ; (IM 1: the chain's vector - nedo.asm n_vec)
        ld hl,(n_vec) : ld (mm_cpm+1),hl : ld hl,mm_ih : ld (n_vec),hl
        ELSE
        ld hl,#0038 : ld a,(cpm_im1) : or a : jr nz,1F          ; (CP/M in IM 1: its #0038)
        ld a,(cpm_i) : ld h,a : ld l,#FF : ld a,(hl) : inc hl : ld h,(hl) : ld l,a
1       ld (mm_cpm+1),hl
        ld a,high mm_vec : ld i,a : im 2
        ENDIF
        ld a,1 : ld (mm_hk),a : ei : ret
mm_unh  ld a,(mm_hk) : or a : ret z
        di
        IFDEF NEDOOS
        ld hl,(mm_cpm+1) : ld (n_vec),hl
        ELSE
        ld a,(cpm_i) : ld i,a : ld a,(cpm_im1) : or a : jr z,1F
        im 1
        ENDIF
1       xor a : ld (mm_hk),a
        ld a,8                                                  ; (AY: volumes 0)
2       ld bc,#FFFD : out (c),a : ld b,#BF : ld e,a : xor a : out (c),a : ld a,e
        inc a : cp 11 : jr c,2B
        ei : ret
mm_ih   push af : push bc : push de : push hl : push ix : push iy : exx : push bc : push de : push hl : ex af,af' : push af
        ld a,(mm_on) : or a : jr z,1F
        ld bc,P_W3 : ld a,#7F-MUSM : out (c),a
        call #EA66                                              ; (its PLAY)
1       ld bc,P_W3 : ld a,#7F-3 : out (c),a
        pop af : ex af,af' : pop hl : pop de : pop bc : exx : pop iy : pop ix : pop hl : pop de : pop bc : pop af
        call mm_cpm
        di : push af : push bc : ld a,(mm_w3v) : ld bc,P_W3 : out (c),a : pop bc : pop af : ei : ret
mm_cpm  jp 0
        ds (#FF - ($ & #FF)) & #FF, 0
mm_vec  dw mm_ih                                                ; (at #xxFF: ATM's bus gives #FF)
mm_hk   db 0
mm_on   db 0                                                    ; 1: the music plays
mm_w3v  db #7F-3
; #4000.. (16K) -> page A
mm_put  call mm_w3 : ld hl,#4000 : ld de,#C000 : ld bc,#4000 : ldir : ld a,3 : jp mm_w3
; page A -> W3 (mm_w3v: the interrupt - mm_ih - puts it back; not hooked - CP/M in IM 1, the intro's loading: DI
; while W3 is not page 3, EI with page 3 again)
mm_w3   ld b,a : ld a,#7F : sub b : ld (mm_w3v),a
        ld b,a : ld a,(mm_hk) : or a : jr nz,1F
        di
1       ld a,b : ld bc,P_W3 : out (c),a
        cp #7F-3 : ret nz
        ld a,(mm_hk) : or a : ret nz
        ei : ret
; t_part with mm_w3v
mm_tp   push af : call mm_w3 : pop af : jp t_part
; screen A (0..3): the palette black, its parts unpacked, the palette back
mm_scr  ld (mm_cs),a : add a,a : ld l,a : ld h,0 : ld de,mm_tab : add hl,de : ld e,(hl) : inc hl : ld d,(hl)
        push de : halt : ld hl,mm_blk : call mm_pal : pop de
        call mm_get
        ld hl,#4002                                             ; (its length first)
        ld a,PS1 : ld de,#C000 : call mm_tp
        ld a,PS1 : ld de,#E000 : call mm_tp
        ld a,PS5 : ld de,#C000 : call mm_tp
        ld a,PS5 : ld de,#E000 : call mm_tp
        ld a,3 : call mm_w3
        halt : ld hl,mm_std
; the palette: HL = 16 values (ATM's: the bits inverted)
mm_pal  push bc : ld a,i : push af : di
        IFDEF NEDOOS
        PAL_HKS
        ENDIF
        ld bc,#BD77 : ld a,VM_EGA : out (c),a     ; (the interrupts as they were after)
        ld e,0
1       ld a,e : and 7 : bit 3,e : jr nz,2F
        out (#FE),a : jr 3F
2       out (#F6),a
3       ld a,(hl) : inc hl : out (#FF),a
        inc e : ld a,e : cp 16 : jr c,1B
        ld bc,#FD77 : ld a,VM_EGA : out (c),a : xor a : out (#FE),a
        pop af : pop bc : ret po
        ei : ret
mm_std  db #FF,#FE,#FD,#FC,#EF,#EE,#ED,#EC,#FF,#DE,#BD,#9C,#6F,#4E,#2D,#0C     ; (the port's 16: build/mkimg.py P)
mm_blk  ds 16, #FF
; DE = a screen's place in the pictures (in 256s from page MNPG's start; 0.65.1: 5 pages) -> #4000.. (28K: #4000..#AFFF)
mm_get  ld a,e : and 63 : or #C0 : ld h,a : ld l,0 : ld (mg_s),hl
        ld a,e : rlca : rlca : and 3 : ld b,a : ld a,d : add a,a : add a,a : or b : add a,MNPG : ld (mg_pg),a
        ld hl,#4000 : ld (mg_d),hl : ld hl,#7000 : ld (mg_n),hl
1       ld a,(mg_pg) : call mm_w3
        ld hl,(mg_s) : push hl
        xor a : sub l : ld c,a : ld a,0 : sbc a,h : ld b,a      ; BC: to the page's end
        ld hl,(mg_n) : or a : sbc hl,bc : jr nc,2F
        ld bc,(mg_n) : ld hl,0                                  ; (the last part)
2       ld (mg_n),hl
        pop hl : ld de,(mg_d) : ldir : ld (mg_d),de
        ld hl,#C000 : ld (mg_s),hl : ld hl,mg_pg : inc (hl)
        ld hl,(mg_n) : ld a,h : or l : jr nz,1B
        ld a,3 : jp mm_w3
mg_s    dw 0
mg_pg   db 0
mg_d    dw 0
mg_n    dw 0
; the screen black: pages 5 and 1, only the EGA screen's parts (+#0000, +#2000: 8000 bytes each - the rest is
; CP/M's)
mm_clr  ld a,PS5 : call 1F : ld a,PS1 : call 1F
        ld a,3 : jp mm_w3
1       call mm_w3 : ld hl,#FF3F : call 2F : ld hl,#DF3F
2       ld d,h : ld e,l : dec de : ld bc,8000-1 : ld (hl),0 : lddr : ret
; (0.63.0) "1": the intro (UFO2.INT, packed: its banks 0..4, 6, 7, 5) - mnu0.asm mi_run; then the screen again.
; (0.64.0) Bank 5 goes to page 5 last, past all the disk's reading, the interrupts off from then till CP/M's page 5
; is back: page 5 is CP/M's BIOS's RAM (0.63.0 reset the machine)
mm_int  ld a,#90 : ld (mz_b),a
        IFDEF NEDOOS                                            ; (NedoOS: the music off at once - not through
        call mm_unh                                             ;  the reading: the card's slower)
        ld hl,f_int : ld de,#4000 : ld b,128 : call mz_rd : jp nc,mm_hok
        ld a,b : or a : jp nz,mm_hok
        ELSE
        ld hl,f_int : ld de,#4000 : ld b,128 : call mz_rd : ret nc      ; (no UFO2.INT)
        ld a,b : or a : ret nz                                  ; (not all there)
        ENDIF
1       call mm_fr : ld a,#F7 : in a,(#FE) : rra : jr nc,1B     ; (till "1" is up)
        halt : ld hl,mm_blk : call mm_pal                       ; (black: page 5 - the screen's part - gets bank 5)
        ld a,INTB : call mm_put                                 ; bank 0
        ld a,PS5 : call mm_w3 : ld hl,#C000 : ld de,#4000 : ld bc,#4000 : ldir
        ld a,INT_SV : call mm_put                               ; (CP/M's page 5 kept)
        ld hl,mi_bk
2       ld a,(hl) : inc hl : push hl : push af
        ld de,#4000 : ld b,128 : call mz_more : ld a,b : or a : jr nz,7F
        pop af : cp 5 : jr z,3F
        add a,INTB : call mm_put : pop hl : jr 2B
7       pop af : pop hl : jr 9F                                 ; (not all there)
3       pop hl
        call mm_unh
        di
        ld a,PS5 : call mm_w3 : ld hl,#4000 : ld de,#C000 : ld bc,#4000 : ldir     ; bank 5 (the interrupts off)
        ld hl,mm_std : call mm_pal                              ; (its colours: the ZX ones; DI kept)
        call mi_run                                             ; (back: DI)
        ld hl,mm_blk : call mm_pal
        ld a,INT_SV : call mm_w3 : ld hl,#C000 : ld de,#4000 : ld bc,#4000 : ldir
        ld a,PS5 : call mm_w3 : ld hl,#4000 : ld de,#C000 : ld bc,#4000 : ldir     ; (CP/M's page 5 back)
        ld a,3 : call mm_w3
        ld a,VM_EGA : call vmode : ei
        call mm_hok
        ld a,(mm_cs) : jp mm_scr                                ; (the screen again)
9
        IFDEF NEDOOS
        call mm_hok
        ENDIF
        ld a,(mm_cs) : jp mm_scr
mi_bk   db 1, 2, 3, 4, 6, 7, 5
f_int   db "UFO2    INT"
mm_cs   db 1                                                    ; (the screen shown)
; "3" / "4" (0.65.0): HL = the text's name (UFO2.INS / ABOUT.TXT - in the stub's image), E = its key's bit (#F7FE):
; UFO2DOC.COM and it there (UFO2.DAT's drive) - the stub to SB_A, UFO2DOC runs in place of UFO2.COM
mm_doc  ld (mm_dn),hl : ld a,e : ld (mm_dk),a
        IFDEF NEDOOS                                            ; (the music off at once, as mm_int)
        call mm_unh
        call 1F : jp nc,mm_hok
        ld hl,sb_dc-SB_A+sb_img : call 1F : jp nc,mm_hok
        ELSE
        call 1F : ret nc
        ld hl,sb_dc-SB_A+sb_img : call 1F : ret nc
        ENDIF
2       call mm_fr : ld a,(mm_dk) : ld e,a : ld a,#F7 : in a,(#FE) : and e : jr z,2B   ; (till its key is up)
        call mm_clr
        call mm_unh
        IFDEF NEDOOS                                            ; (NedoOS: UFO2DOC.OVL in place of the code -
        ld b,50                                                 ;  nedo.asm n_doc; then the menu again)
3       halt : push bc : ld e,#FF : ld c,6 : call BDOS : pop bc : djnz 3B
        ld de,(mm_dn) : ld a,(mm_on) : ld hl,n_doc : call n_p3   ; (A: the music on - it plays meanwhile)
        ld a,VM_EGA : call vmode
        call mm_hok
        ld a,(mm_cs) : jp mm_scr
        ELSE
        di : ld a,3 : SHOWSCR : ld a,VM_TXT : call vmode : ei
        ld a,2 : call kb_mode
        ld b,50                                                 ; (CP/M's keyboard: what's there - away)
3       halt : push bc : ld e,#FF : ld c,6 : call BDOS : pop bc : djnz 3B
        ld hl,sb_img : ld de,SB_A : ld bc,SB_N : ldir
        ld a,(dfcb) : ld (sb_drv),a                            ; (in the copy)
        ld hl,(mm_dn) : ld de,SB_A-sb_img : add hl,de : ld de,sb_tn : ld bc,11 : ldir    ; (the text's name)
        jp SB_A
        ENDIF
1       ld de,ibuf : ld b,1 : jp mf_rd                          ; (is it there: NC - no)
mm_dn   dw 0
mm_dk   db 0
        ENT
; the stub (past UFO2.COM: its loading doesn't touch it): UFO2DOC.COM -> #0100, the hook (dh_*) to DH_A - it puts
; its changes into UFO2DOC (dh_set); UFO2DOC's way out (JP 0 / RST 0 - CP/M's warm boot) -> sb_ret: UFO2.COM again,
; "MENU" in its command line (0.61.1: not CP/M's (1) changed - UFO2DOC calls the BIOS by it)
sb_phys                                 ; (its place in the code's image: MNM_A + sb_phys - mnm_img when it runs)
sb_img  equ MNM_A + sb_phys - mnm_img
        DISP SB_A
        IFDEF NEDOOS
sb_ret  jp n_dret                                               ; (nedo.asm: UFO2DOC.OVL's way back)
        ELSE
        ld sp,SB_A+#FE
        ld hl,sb_dc : call sb_ld : jr c,sb_ret                  ; (no UFO2DOC.COM: back)
        ld hl,dh_img : ld de,DH_A : ld bc,DH_N : ldir           ; (from the menu's code: not touched yet)
        call dh_set
        jp #0100
sb_ret  ld sp,SB_A+#FE
        ld hl,sb_cn : call sb_ld : jp c,0                       ; (no UFO2.COM: CP/M)
        ld hl,sb_tl : ld de,#0080 : ld bc,6 : ldir
        jp #0100
; HL = the file's name: it -> #0100.. (CF: not there)
sb_ld   ld de,sb_fcb+1 : ld bc,11 : ldir
        ld hl,sb_fcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld a,(sb_drv) : ld (sb_fcb),a
        ld de,sb_fcb : ld c,15 : call BDOS : inc a : scf : ret z
        ld de,#0100
2       push de : ld c,26 : call BDOS
        ld de,sb_fcb : ld c,20 : call BDOS : pop de
        or a : ret nz                                           ; (the end: NC)
        ld hl,128 : add hl,de : ex de,hl : jr 2B
        ENDIF
sb_drv  db 0
sb_cn   db "UFO2    COM"
        IFDEF NEDOOS
sb_dc   db "UFO2DOC OVL"
        ELSE
sb_dc   db "UFO2DOC COM"
        ENDIF
sb_ins  db "UFO2    INS"
sb_abt  db "ABOUT   TXT"
sb_tn   ds 11                                                   ; (the text's: one of them)
sb_tl   db 5," MENU"
sb_fcb  ds 36
sb_end
        ENT
SB_N    equ sb_end-SB_A
        ASSERT SB_N <= #E0
; the hook in UFO2DOC (0.61.1; 0.64.0: in the text): its text's codes #0E..#12 (build/mkins.py: a line of its own, 9
; empty ones after it - the picture's 10 rows) - the pictures (UFO2.INP: XN5 - the instruction's title -, XN1..XN4;
; 256x80 - the original's 256x192 in 640x200's proportions -, 1 bit, 32 bytes a line, 20 records each) at the text's
; row now (#0A86: its y), in the middle (bytes 24..55), the ink - the original's paper colour; not 10 rows left on
; the page (#0FDD: its rows, 23 a page): its key first, the picture at the next page's top. UFO2DOC's main loop at
; #0FF3 (LD A,(HL) : CP #1A) calls dh_hk. Its screen: page 5 the points, page 1 the attributes (#7 - its text's;
; written with each letter), line y at #C000 + y*40, the odd bytes +#2000.
        IFDEF NEDOOS
; (NedoOS) the menu's music while UFO2DOC.OVL runs (nedo.asm n_doc: its n_vec; this at DM_A - its W2's page, free
; there): the player (page MUSM in W3) each interrupt, W3 back
DM_A    equ #AE00
dm_phys
dm_img  equ MNM_A + dm_phys - mnm_img
        DISP DM_A
dm_ih   push af : push bc : push de : push hl : push ix : push iy : exx : push bc : push de : push hl : ex af,af' : push af
        ld a,3 : in a,(#BE) : push af
        ld bc,P_W3 : ld a,#7F-MUSM : out (c),a
        call #EA66                                              ; (its PLAY)
        pop af : ld bc,P_W3 : out (c),a
        pop af : ex af,af' : pop hl : pop de : pop bc : exx : pop iy : pop ix : pop hl : pop de : pop bc : pop af
        ei : ret
dm_end
        ENT
DM_N    equ dm_end-DM_A
        ENDIF
dh_phys
dh_img  equ MNM_A + dh_phys - mnm_img
        DISP DH_A
dh_set  ld a,(sb_drv) : ld (#05EF),a : ld (#09FD),a : ld (dh_fcb),a     ; (the FCBs: the text's, the font's, ours)
        ld hl,#B000 : ld (#0107),hl                             ; (its font: #B000, not #8000 - the text, 35K from #1092)
        ld hl,sb_tn : ld de,#0FE0 : ld bc,11 : ldir             ; (its file: ABOUT.TXT -> UFO2.INS - or ABOUT.TXT)
        ld hl,sb_ret : ld (#09DA),hl                            ; (its ways out: JP 0 - no font -, the end / ESC:
        ld a,#C3 : ld (#106E),a : ld (#106F),hl                 ;  CALL #0491 "ESC M1 ESC Z1" : RST 0)
        ld a,#CD : ld (#0FF3),a : ld hl,dh_hk : ld (#0FF4),hl
        ret
dh_hk   ld a,(hl) : cp #0E : jr c,1F : cp #13 : jr nc,1F
        push hl : call dh_pic : pop hl : xor a                  ; (code 0: nothing printed)
1       cp #1A : ret
dh_pic  sub #0E : ld (dh_n),a
        ld a,(#0FDD) : cp 23-10+1 : call nc,#102C               ; (no room: the page's key; the screen cleared)
        ld a,(#0A86) : ld l,a : ld h,0 : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de    ; y * 5
        add hl,hl : add hl,hl : add hl,hl : ld de,#C000+12 : add hl,de : ld (dh_ad),hl : ld (dh_a0),hl  ; * 8
        ld hl,dh_fcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld de,dh_fcb : ld c,15 : call BDOS : inc a : ret z      ; (no UFO2.INP: no pictures)
        ld de,dh_buf : ld c,26 : call BDOS
        ld a,(dh_n) : ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld (dh_fcb+33),hl                                       ; (* 20)
        ld b,20
2       push bc
        ld de,dh_fcb : ld c,33 : call BDOS
        ld hl,(dh_fcb+33) : inc hl : ld (dh_fcb+33),hl
        di : ld bc,P_W3 : ld a,#7F-PS5 : out (c),a
        ld hl,dh_buf : ld b,4
3       push bc : ld de,(dh_ad) : ld b,16
4       ld a,(hl) : inc hl : ld (de),a                          ; (byte 24 + 2k: +0, 25 + 2k: +#2000)
        ld a,(hl) : inc hl : set 5,d : ld (de),a : res 5,d
        inc de : djnz 4B
        push hl : ld hl,(dh_ad) : ld de,40 : add hl,de : ld (dh_ad),hl : pop hl
        pop bc : djnz 3B
        ld bc,P_W3 : ld a,#7F-3 : out (c),a : ei
        pop bc : djnz 2B
        ld a,(dh_n) : ld e,a : ld d,0 : ld hl,dh_at : add hl,de : ld a,(hl)
; its part of the screen's attributes (page 1) = A
        di : push af : ld bc,P_W3 : ld a,#7F-PS1 : out (c),a : pop af
        ld hl,(dh_a0) : ld b,80
1       push bc : push hl : ld b,16
2       ld (hl),a : set 5,h : ld (hl),a : res 5,h : inc hl : djnz 2B
        pop hl : ld de,40 : add hl,de : pop bc : djnz 1B
        ld bc,P_W3 : ld a,#7F-3 : out (c),a : ei : ret
dh_at   db 4, 7, 5, 4, 5                ; (XN5, XN1..XN4: the original's papers - DATR_T - as the ink here)
dh_n    db 0
dh_ad   dw 0
dh_a0   dw 0
dh_fcb  db 0,"UFO2    INP" : ds 24
dh_buf  ds 128
dh_end
        ENT
DH_N    equ dh_end-DH_A
        ASSERT DH_A+DH_N <= SB_A
