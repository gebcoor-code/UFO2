; ------------------------------------------------------------------ the title picture while loading (the start only)
; UFO2.IMG (build/mkimg.py): the EGA screen as it is in memory: page 1 +#0000, page 1 +#2000,
; page 5 +#0000, page 5 +#2000 (8000 bytes each: 200 lines of 40). Read into #4000.. (STAGE and on: free now; the
; file packed - mz.asm; 20K at most),
; then ESC M0 and the four parts into the pages (each RLE packed: build/mkimg.py). The progress: a white point every other pixel on line DOT_Y
; from DOT_X0 on ("LOADING." is in the picture). No UFO2.IMG: the text start as before ("Loading..." and dots).
DOT_X0  equ 53                          ; (odd: the right pixel of a pair; the picture's own point is at 51)
DOT_Y   equ 12
tshow   db 0                            ; 1: the picture shown
dotx    db DOT_X0
f_img   db "UFO2    IMG"
t_show  ld hl,(6) : ld de,#BE00 : or a : sbc hl,de : jr c,.txt          ; (BDOS below the buffer's end: no)
        ld a,#90 : ld (mz_b),a                                          ; (mz.asm: packed; its buffers #9000..#AFFF)
        ld hl,f_img : ld de,#4000 : ld b,160 : call mz_rd : jr nc,.txt
        ld a,b : or a : jr z,.txt : cp 160 : jr z,.txt                  ; (too long: no picture; empty)
        ld de,m_mode : ld c,9 : call BDOS       ; EGA 320x200, no cursor
        di
        ld hl,#4000
        ld a,1 : ld de,#C000 : call t_part
        ld a,1 : ld de,#E000 : call t_part
        ld a,5 : ld de,#C000 : call t_part
        ld a,5 : ld de,#E000 : call t_part
        WIN P_W3, 3
        ei
        ld a,1 : ld (tshow),a : ret
.txt    ld de,m_hello : ld c,9 : call BDOS : ld de,m_load : ld c,9 : jp BDOS
; A = page (W3), DE = where, HL = the packed part: 8000 bytes (c < #80: c+1 bytes; c >= #80: the next byte c-#7E times)
t_part  push hl : ld b,a : ld a,#7F : sub b : SCRV : ld bc,P_W3 : out (c),a : pop hl
        push de : ex (sp),hl : ld bc,8000 : add hl,bc : ex (sp),hl      ; (the end on the stack)
1       ld a,(hl) : inc hl : cp #80 : jr nc,2F
        ld c,a : ld b,0 : inc bc : ldir : jr 3F
2       sub #7E : ld b,a : ld a,(hl) : inc hl
4       ld (de),a : inc de : djnz 4B
3       ex (sp),hl : or a : sbc hl,de : add hl,de : ex (sp),hl : jr nz,1B
        pop de : ret
; "DEBUG" (any case: the CCP makes it upper) after spaces in the command line -> sdbg = 1; then "Xnn" (nn 00..11):
; LOC GO starts that location each time (xpg.asm dbg_loc: dbg_tb's order) - put into XPG's image (img_out: later)
a_dbg   ld hl,CMDL : ld b,(hl) : inc hl
1       ld a,b : or a : ret z
        ld a,(hl) : cp ' ' : jr nz,2F
        inc hl : dec b : jr 1B
2       ld a,(hl) : and #DF : cp 'M' : jr nz,7F                ; (0.61.0) "MENU": the instruction's way back
        ld a,1 : ld (smenu),a : ret
7       ld a,b : cp 5 : ret c
        ld c,b : ld de,s_dbg : ld b,5
3       ld a,(hl) : and #DF : ex de,hl : cp (hl) : ex de,hl : ret nz
        inc hl : inc de : djnz 3B
        ld a,1 : ld (sdbg),a
        ld a,c : sub 5 : ld b,a
5       ld a,b : or a : ret z
        ld a,(hl) : inc hl : dec b : cp ' ' : jr z,5B
        and #DF : cp 'X' : ret nz : ld a,b : or a : ret z
        ld a,(hl) : sub '0' : cp 10 : ret nc : ld c,a : dec b : jr z,6F               ; (one digit or two)
        inc hl : ld a,(hl) : sub '0' : cp 10 : jr nc,6F
        ld e,a : ld a,c : add a,a : add a,a : add a,c : add a,a : add a,e : ld c,a
6       ld a,c : cp 12 : ret nc
        ld (xpg_img + dbg_n - #C000),a : ld a,1 : ld (xpg_img + dbg_fx - #C000),a : ret
s_dbg   db "DEBUG"
; the next block of UFO2.DAT's stream -> STAGE.., DE = its end (build/mkdat.py, lpc.py's format):
; flag 0: 16K of zeros; 1: the 4 tail bytes, then tokens: #81..#BF n literals (as they are), #80 the end
; (the tail goes out), 0tttLLLo xx: a copy of LLL+3 from DE - (o:xx), then ttt literals, 11nnnnnn tttt:OOOO xx: a
; copy of n+4 from DE - (OOOO:xx), then tttt literals
lz_blk  call getb : ld de,STAGE : or a : jr nz,1F
        ld h,d : ld l,e : ld (hl),a : inc de : ld bc,#3FFF : ldir : ret              ; (DE = #8000)
1       ld hl,lz_t : ld b,4
2       call getb : ld (hl),a : inc hl : djnz 2B
.tok    call getb : cp #80 : jr c,.sh : cp #C0 : jr nc,.lg
        and #3F : jr z,.end
        ld c,a : call .lit : jr .tok
.sh     ld c,a : call getb : ld l,a : ld a,c : and 1 : ld h,a
        ld a,c : and #0E : rrca : add a,3 : ld b,a
        call .cpy : jr .tl
.lg     and #3F : add a,4 : ld b,a
        call getb : ld c,a : and 15 : ld h,a : call getb : ld l,a
        call .cpy
.tl     ld a,c : rrca : rrca : rrca : rrca : and 15 : jr z,.tok
        ld c,a : call .lit : jr .tok
; C literals: straight from ibuf (LDIR by the record's parts)
.lit    ld hl,(gp)
1       bit 7,l : call nz,gfill
        ld a,#80 : sub l : cp c : jr c,2F : ld a,c          ; A = min(left in ibuf, C)
2       ld b,a : ld a,c : sub b : ld c,a
        push bc : ld c,b : ld b,0 : ldir : pop bc
        ld a,c : or a : jr nz,1B
        ld (gp),hl : ret
.cpy    push bc : ld a,e : sub l : ld l,a : ld a,d : sbc a,h : ld h,a
        ld c,b : ld b,0 : ldir : pop bc : ret
.end    ld hl,lz_t : ld bc,4 : ldir : ret
lz_t    ds 4
; a progress point (the picture) or "." (the text)
dot     ld a,(tshow) : or a : jr nz,1F
        ld e,'.' : ld c,2 : jp BDOS
1       ld a,(dotx) : cp 159 : ret nc           ; (the left half of the line at most)
        ld c,a : add a,2 : ld (dotx),a
        srl c                                   ; the pair
        ld a,c : and 1 : ld b,1 : jr z,2F : ld b,5      ; pairs 0, 2 mod 4: page 1; 1, 3: page 5
2       ld a,c : and 2 : add a,a : add a,a : add a,a : add a,a : or #C0 : ld h,a   ; (#C000 / #E000)
        srl c : srl c : ld l,c                  ; + pair / 4
        ld de,DOT_Y*40 : add hl,de
        ld a,#7F : sub b : SCRV : ld bc,P_W3
        di : out (c),a
        ld a,(hl) : and #47 : or #B8 : ld (hl),a        ; the right pixel: colour 15
        ld a,#7F-3 : out (c),a : ei : ret
;
; loaded: the intro plays (CP/M's interrupt, LD_INT) till a key, a mouse button or its end (its loop point:
; the player's SETUP bit 7); "PRESS ANY KEY" over "LOADING." and its points (the text start: a line)
PAK_X   equ 6
PAK_Y   equ 4
t_wait
        IFDEF NEDOOS                            ; (NedoOS: the kernel keeps the keys pressed before - the menu's "2" -:
1       ld e,#FF : ld c,6 : call BDOS : or a : jr nz,1B ;  away first)
        ENDIF
        call mus_hok                            ; the intro starts now (not while loading)
        ld a,(tshow) : or a : jr nz,1F
        ld de,m_pak : ld c,9 : call BDOS : jr 3F
1       call t_pak
3       ld a,i : jp po,4F : halt                ; (CP/M's interrupts: the intro's ticks)
4       ld a,(pt3.SETUP) : rla : ret c          ; the intro's end
        ld bc,#FADF : in a,(c) : cpl : and 3 : jr nz,8F
        ld e,#FF : ld c,6 : call BDOS : or a : jr z,3B
        jr 9F
8       in a,(c) : cpl : and 3 : jr nz,8B       ; (till the button is up)
9       ld a,(mus_hk) : or a : ret z            ; the intro faded out (15 frames)
        ld a,i : ret po
5       halt : ld a,(m_ldf) : inc a : ld (m_ldf),a : cp 15 : jr c,5B
        ret
m_pak   db 13,10,"Press any key",13,10,"$"
; a key: the start goes on (the pages, the tiles' colours, the LUT - a few seconds): "Unpacking..." (the picture: over
; "PRESS ANY KEY", enc_u.asm's lt_unp (UPG) through W2; the text start: a line)
t_ldg   ld a,(tshow) : or a : jr nz,1F
        ld de,m_ldg : ld c,9 : jp BDOS
1       di
        ld a,1 : call t_pak.cl : ld a,5 : call t_pak.cl
        WIN P_W3, UPG
        ld a,PS1 : ld c,0 : call 2F
        ld a,PS5 : ld c,2 : call 2F
        WIN P_W3, 3
        ld a,2 : call map_w2 : ei : ret
2       call map_w2 : ld de,#8000 + (PAK_Y + 1) * 40 + 1 : jp lt_unp
t_pak   di
        ld a,1 : call .cl : ld a,5 : call .cl
        ld hl,pak_b : ld d,PAK_Y
1       ld e,PAK_X : ld c,13
2       ld a,(hl) : inc hl : ld b,8
3       rla : jr nc,4F
        push af : call t_px : pop af
4       inc e : djnz 3B
        dec c : jr nz,2B
        inc d : ld a,d : cp PAK_Y+8 : jr c,1B
        WIN P_W3, 3 : ei : ret
; lines 2..14, x 0..167 (bytes 0..20 of each part) black: page A's two parts
.cl     ld b,a : ld a,#7F : sub b : SCRV : ld bc,P_W3 : out (c),a
        ld hl,#C000+2*40 : call .c2
        ld hl,#E000+2*40
.c2     ld c,13
1       push hl : ld b,21
2       ld (hl),0 : inc hl : djnz 2B
        pop hl : ld de,40 : add hl,de : dec c : jr nz,1B : ret
; E = x (0..255), D = y: the pixel colour 15 (registers kept but A)
t_px    push bc : push de : push hl
        ld a,e : and 1 : ld (tp_r),a
        srl e                                   ; the pair
        ld a,e : and 1 : ld b,1 : jr z,1F : ld b,5      ; pairs 0, 2 mod 4: page 1; 1, 3: page 5
1       ld a,e : and 2 : rlca : rlca : rlca : rlca : or #C0 : ld h,a     ; (#C000 / #E000)
        srl e : srl e : ld l,e
        push hl : ld l,d : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        pop de : add hl,de                      ; + y * 40
        ld a,#7F : sub b : SCRV : ld bc,P_W3 : out (c),a
        ld a,(tp_r) : or a : ld a,(hl) : jr z,2F
        and #47 : or #B8 : jr 3F                ; the right pixel
2       and #B8 : or #47                        ; the left one
3       ld (hl),a
        pop hl : pop de : pop bc : ret
tp_r    db 0
pak_b   ; "PRESS ANY KEY" (SEA.FNT), 8 lines x 13 bytes
        db #FC, #FC, #FE, #78, #78, #00, #30, #C6, #CC, #00, #E6, #FE, #CC
        db #66, #66, #62, #CC, #CC, #00, #78, #E6, #CC, #00, #66, #62, #CC
        db #66, #66, #68, #E0, #E0, #00, #CC, #F6, #CC, #00, #6C, #68, #CC
        db #7C, #7C, #78, #78, #78, #00, #CC, #DE, #78, #00, #78, #78, #78
        db #60, #6C, #68, #1C, #1C, #00, #FC, #CE, #30, #00, #6C, #68, #30
        db #60, #66, #62, #CC, #CC, #00, #CC, #C6, #30, #00, #66, #62, #30
        db #F0, #E6, #FE, #78, #78, #00, #CC, #C6, #78, #00, #E6, #FE, #78
        db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00

; the saved CP/M pages 5, 1 (save_p15): the picture out of their screen part (the tails, the BIOS's RAM, kept)
t_clr   di
        ld a,PG_S5 : call 1F
        ld a,PG_S1 : call 1F
        ld a,2 : call map_w2 : ei : ret
1       call map_w2
        ld hl,#8000 : call 2F
        ld hl,#A000
2       ld d,h : ld e,l : inc de : ld bc,8000-1 : ld (hl),0 : ldir : ret
