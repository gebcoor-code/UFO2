; ------------------------------------------------------------------ window 0's overlay: code never run in a wide fight
; (the field buffer BDSC covers it then; saved at the start into page OVPG, back at bat_off)
pgcopy  call ay_off                             ; (a long DI: the music quiet, no note held)
        ld a,d : call map_w2
        ld a,e : ld b,a : ld a,#7F : sub b : ld bc,P_W3 : out (c),a
        ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir : ret
zx_on   ld (zv_sp),sp : ld sp,#3F80
        push af : push bc : push de : push hl : push ix
        ld a,i : push af : di
        ld de,256*15+PS5 : call pgcopy
        ld a,PS5 : ld (bpage+7),a
        jr zv_end
; ega_re: after a wide fight (bat_off) - bank 7 is at page 15 already: no copy, no ZX mode between
ega_re  ld a,#01 : jr 1F                        ; (LD BC,nn: the copy's CALL skipped)
ega_on  ld a,#CD
1       ld (er_c),a
        ld (zv_sp),sp : ld sp,#3F80
        push af : push bc : push de : push hl : push ix
        ld a,i : push af : di
        ld de,256*PS5+15
er_c    call pgcopy
        ; blank first: page 5 (shown in ZX mode): attributes 0 at once, then the rest; page 1; then EGA (black)
        ld a,PS5 : call map_w2
        ld hl,#9800 : ld de,#9801 : ld bc,#2FF : ld (hl),0 : ldir
        call clr16
        ld a,PS1 : call map_w2 : call clr16
        ld a,VM_EGA : call vmode
        IFDEF NEDOOS                            ; (the start's black palette - zxl.asm: the ZX screen's drafts not
        ld a,(pl_bk) : or a : call nz,pl_end    ;  seen till here - the standard one again)
        ENDIF
        ld a,15 : ld (bpage+7),a
        ld a,1 : ld (ega),a : ld (ui_red),a
        WIN P_W2, PG_ZX+2
        ld a,(cur) : call map_w3
        call scr_init
        call conv_all
        jr zv_ret
zv_end  xor a : ld (ega),a
        WIN P_W2, PG_ZX+2
        ld a,(cur) : call map_w3
        ld a,VM_ZX : call vmode
zv_ret  pop af : jp po,1F : ei
1       pop ix : pop hl : pop de : pop bc : pop af
        ld sp,(zv_sp)
        ret
zv_sp   dw 0
        IFDEF NEDOOS
; the palette black (EGA's mode kept); pl_bk: ega_on puts the standard one back
pl_bk   db 0
; (ega_on / ega_re) screen 1 cleared too (after a fight it may still be shown - its last picture; the shadow is all
; "changed": both are drawn anew), the standard palette
pl_end  ld a,15 : call map_w2                    ; (and the game's ZX screen - bank 7 - black: the conversion would
        ld hl,#8000 : ld de,#8001 : ld bc,#1AFF : ld (hl),0 : ldir      ;  show the fight's last one till the map)
        ld a,PS3 : call map_w2 : call clr16
        ld a,PS7 : call map_w2 : call clr16
        ld a,PS5 : call map_w2
        xor a : ld (pl_bk),a : ld a,VM_EGA : jp pal_std
pal_blk ld a,1 : ld (pl_bk),a
        ld bc,#BD77 : ld a,VM_EGA : out (c),a
        ld e,0
1       ld a,e : and 7 : bit 3,e : jr nz,2F
        out (#FE),a : jr 3F
2       out (#F6),a
3       ld a,#FF : out (#FF),a : inc e : bit 4,e : jr z,1B
        ld bc,#FD77 : ld a,VM_EGA : out (c),a : xor a : out (#FE),a : ret
        ENDIF
ega_off ld (zv_sp),sp : ld sp,#3F80
        push af : push bc : push de : push hl : push ix
        ld a,i : push af : di
        call ay_off
        ; blank (EGA pages 1, 5 = 0), ZX mode (black: attributes 0), then pixels, then attributes of bank 7
        ld a,PS5 : call map_w2 : call clr16
        ld a,PS1 : call map_w2 : call clr16
        ld a,VM_ZX : call vmode
        xor a : ld (bf),a : SHOWSCR                     ; (ZX mode shows page 5 then)
        ld a,15 : call map_w2
        ld a,PS5 : ld b,a : ld a,#7F : sub b : ld bc,P_W3 : out (c),a
        ld hl,#8000 : ld de,#C000 : ld bc,#1800 : ldir           ; pixels (not visible yet)
        ld hl,#9B00 : ld de,#DB00 : ld bc,#2500 : ldir           ; the rest of the bank
        ld hl,#9800 : ld de,#D800 : ld bc,#300 : ldir            ; attributes: the picture at once
        ld a,PS5 : ld (bpage+7),a
        jp zv_end
        IFNDEF NEDOOS                           ; (CP/M's only)
rest_pg
        ld a,PG_S3 : call map_w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir
        WIN P_W3, 7
        ld a,PG_S7 : call map_w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir
        WIN P_W3, 5
        ld a,PG_S5 : call map_w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir
        WIN P_W3, 1
        ld a,PG_S1 : call map_w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir
        WIN P_W3, 3
        ld a,2 : jp map_w2
        ENDIF
lay_zxm push af : call ay_off : xor a : ld (svc),a : ld (free),a : call kb_mode : ld a,(ega) : or a : call nz,ega_off : pop af : ret
; the AY quiet: its mixer all off, (0.67.9) the volumes 0 too - a note on the envelope (volume's bit 4) went on
; sounding with the mixer off (the encyclopedia's picture read: the music hung on); the music's next tick sets all again
ay_off  push hl : ld hl,#3F07                    ; (L = the register 7..10, H = its value: #3F, then 0; HL kept)
1       ld bc,#FFFD : out (c),l : ld b,#BF : out (c),h
        ld h,0 : inc l : ld a,l : cp 11 : jr c,1B
        pop hl
        ld a,15 : ld (FADE),a : ret             ; (after the pause: faded in)
zx_exit di
        call ay_off                             ; the music quiet first
        IFDEF NEDOOS                            ; back to NC: the saved game written first
        ld sp,#3FFE
        WIN P_W1, 4
        WIN P_W2, 2
        WIN P_W3, 3
        ei
        call d_flush
        jp n_quit
        ENDIF
        IFNDEF NEDOOS
        ld a,XPG : call map_w3p : ld hl,m_back : ld de,SHP : ld bc,m_back_n : ldir      ; (the line: XPG -> SHP)
        ld sp,#3FFE
        WIN P_W1, 4
        WIN P_W2, 2
        WIN P_W3, 3
        ld a,3 : ld bc,#7FFD : out (c),a        ; (CP/M's value: CE.COM)
        call rest_pg                            ; (CP/M's pages 3, 7, 5, 1 as they were)
        ld a,2 : call kb_mode                   ; keyboard controller: CP/M mode again
        call cpm_int
        ei
        call d_flush
        ld de,SHP : ld c,9 : call BDOS
        rst 0
        ENDIF
        ; (here, not with the start's messages: those are past SHP - the pixels' shadow overwrites them)
zx_view call conv_all
        ld hl,x_pace : call far_g               ; (the 3D fight's pace: ui6)
        jp G_PT128
zx_alexq
        ld a,XPG : call map_w3p : call x_m3d : ld a,(cur) : call map_w3   ; the 3D fight: interrupts on, its music
        ld a,(d3off) : or a : ret z
        pop hl : ld a,1 : scf : ret
lay_band
        ld (bd_y),a
        ld a,(ega) : or a : jr nz,.ega
.zx     push hl : push bc
        ld a,h : add a,#30 : ld d,a : ld e,l : ld bc,32 : ldir
        pop bc : pop hl
        call bd_next : djnz .zx
        ret
.ega    ld a,(bd_y) : ld de,(bd_c1) : cp e : ret z : cp d : ret z     ; compared lately (forgotten in int_h)
        ld d,e : ld e,a : ld (bd_c1),de         ; c2 = c1, c1 = A
        ld a,i : push af                        ; (interrupts as they are: int_f only ticks the music, W1's remap is
        ld (bd_sp),sp : ld sp,#3F70             ;  beyond it; W1 is the game's stack: remapped below)
        ld a,UPG : call map_w3p
        push bc : WIN P_W1, 15 : pop bc        ; W1 = screen 7 (bank 7)
        call bd_cmp
        WIN P_W1, PG_ZX+5
        ld a,(cur) : call map_w3
        ld sp,(bd_sp) : pop af : ret po : ei : ret
bd_next push af
        inc h : ld a,h : and 7 : jr nz,1F
        ld a,l : add a,32 : ld l,a : jr c,1F
        ld a,h : sub 8 : ld h,a
1       ld a,(bd_y) : inc a : ld (bd_y),a
        pop af : ret
dfcb    db 0,"UFO2    DAT" : ds 24
scr_init
        xor a : ld (bf),a : ld (fready),a : ld (bchg),a : ld (age),a
        SHOWSCR                                 ; A shown
        ld hl,bsync : ld b,4*SYN+48
3       ld (hl),a : inc hl : djnz 3B
        ld (brec),a                             ; (cs_on of the back buffer)
        ld a,1 : call map_buf : call clr4
        call scr_map : call clr4
        ld de,SHP : ld c,0                      ; c = r*8 + l (order of SHP)
1       ld a,c : rrca : rrca : rrca : and #1F : ld b,a  ; r
        and #18 : ld h,a : ld a,c : and 7 : or h : or #C0 : ld h,a
        ld a,b : and 7 : rrca : rrca : rrca : ld l,a    ; HL = ZX address of line (r, l)
        ld b,32
2       ld a,(hl) : cpl : ld (de),a : inc hl : inc de : djnz 2B
        inc c : ld a,c : cp 192 : jr c,1B
        ld hl,#D800 : ld de,SHA : ld bc,768 : ldir      ; attributes as they are (pixels already forced)
        call scr_unmap
        xor a : ld (crow),a : ld (cs_on),a : ret
clr4    ld hl,#4000 : call clr8k : ld hl,#6000 : call clr8k
        ld hl,#8000 : call clr8k : ld hl,#A000 : jr clr8k
clr16   ld hl,#8000 : ld de,#8001 : ld bc,#3FFF : ld (hl),0 : ldir : ret
clr8k   ld d,h : ld e,l : inc de : ld (hl),0 : ld bc,8000-1 : ldir : ret
c_cnt   ld c,0
        DUP 8
        ld a,(de) : cp (hl) : jr z,$+3 : inc c
        inc l : inc e
        EDUP
        ld a,l : sub 8 : ld l,a : ld a,e : sub 8 : ld e,a
        ld a,c : or a : ret
c_few   push hl : ld hl,(budget) : ld b,0 : add hl,bc : ld (budget),hl : pop hl
        DUP 8
        ld a,(de) : cp (hl) : call nz,conv_row.chg
        inc l : inc e
        EDUP
        ret
c_all   DUP 8
        ldi
        EDUP
        push hl : ld hl,(budget) : inc hl : inc hl : ld (budget),hl : pop hl
        ret
conv_row
        ld (cr),a
        ld hl,(budget) : inc hl : inc hl : ld (budget),hl
        ld a,(full) : ld (frc),a : xor a : ld (full),a
        ld a,(lmask) : inc a : jr nz,.pix      ; not whole: no attribute check
        ld a,(cr)
        ; attributes: a changed one invalidates the 8 shadow bytes of its cell
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl   ; r*32
        push hl : ld de,#D800 : add hl,de : ex de,hl : pop hl : ld bc,SHA : add hl,bc  ; DE = attrs, HL = shadow
        ld b,32 : ld c,0
1       ld a,(de) : cp (hl) : jr z,2F
        ld (hl),a
        push hl
        ld a,c : rrca : rrca : rrca : and 3 : call gbit
        ld hl,cmask : or (hl) : ld (hl),a
        ld hl,frc : or (hl) : ld (hl),a         ; the group: all its bytes out (no compare) in the pass below
        pop hl
2       inc hl : inc de : inc c : djnz 1B
        ; pixel lines: attributes of the row (32-aligned), source, shadow, destination of line 0
.pix    xor a : ld (rt_ok),a                   ; the column tables: when the first group-line needs them
        ld a,(lmask) : ld (lm),a
        ld a,(cr) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        push hl : ld bc,SHA : add hl,bc : ld (rt_src),hl : pop hl     ; (row_tabs: the row's attributes)
        ld bc,#D800 : add hl,bc : ld (arow),hl
        ld a,(cr) : and #18 : or #C0 : ld h,a : ld a,(cr) : and 7 : rrca : rrca : rrca : ld l,a : ld (src),hl
        ld a,(cr) : add a,high SHP : ld h,a : ld l,0 : ld (shd),hl
        ld a,(cr) : add a,a : add a,a : add a,a : add a,4
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld de,#4000 : add hl,de : ld (dst),hl                  ; W1 #4000 + y*40
        ld a,8 : ld (cl),a
        ld a,1 : ld (lbit),a
.ln     ld hl,lm : rrc (hl) : jp nc,.nxl
        ld hl,(budget) : inc hl : inc hl : ld (budget),hl
        ld hl,(src) : ld de,(shd)
        xor a : ld (fmask),a
        CGRP 1
        CGRP 2
        CGRP 4
        CGRP 8
        ld a,(fmask) : or a : jr z,.nxl
        ld hl,lgrp : or (hl) : ld (hl),a
        ld a,TPG : call map_w3p
        ld a,(rt_ok) : or a : jr nz,1F
        inc a : ld (rt_ok),a : call row_tabs
        ld hl,(budget) : ld de,8 : add hl,de : ld (budget),hl
1       call line_out : ld a,7 : call map_w3
        ; next line
.nxl    ld a,(lgrp) : or a : jr z,7F         ; changed: into bsync
        ld hl,bsync : ld a,(cr) : add a,l : ld l,a : jr nc,8F : inc h
8       ld a,(lgrp) : or (hl) : ld (hl),a
        ld de,SYN : add hl,de : ld a,(lbit) : or (hl) : ld (hl),a
        xor a : ld (lgrp),a : inc a : ld (bchg),a
7       ld hl,lbit : sla (hl)
        ld hl,src+1 : inc (hl)
        ld a,(shd) : add a,32 : ld (shd),a
        ld hl,(dst) : ld de,40 : add hl,de : ld (dst),hl
        ld hl,cl : dec (hl) : jp nz,.ln
        ret
; one byte (HL = source, DE = shadow): LUT of the pair and the attribute
.chg    ld a,(hl) : ld (de),a
        push hl : push de : push bc
        ld c,a                                  ; C = pixels
        ld a,l : and 31 : ld b,a                ; B = cx
        ld hl,(arow) : ld a,l : add a,b : ld l,a : ld e,(hl)    ; E = attribute
        ld hl,(dst) : ld a,l : add a,b : ld l,a : jr nc,1F : inc h
1       ld a,c : rlca : rlca : and 3 : add a,high LUT : ld d,a : ld a,(de) : ld (hl),a     ; pair 0: W1 +0
        set 5,h
        ld a,c : rrca : rrca : and 3 : add a,high LUT : ld d,a : ld a,(de) : ld (hl),a     ; pair 2: W1 +#2000
        ld a,h : xor #C0 : ld h,a
        ld a,c : and 3 : add a,high LUT : ld d,a : ld a,(de) : ld (hl),a                   ; pair 3: W2 +#2000
        res 5,h
        ld a,c : rrca : rrca : rrca : rrca : and 3 : add a,high LUT : ld d,a : ld a,(de) : ld (hl),a   ; pair 1
        pop bc : pop de : pop hl
        ret
sc_try  push af : ld a,UPG : call map_w3p : pop af : ld (sc_r),a : call sc_row1
        push af : call map_back : pop af : ret
od_line ld (od_y),a : call od_cpy
        ld a,(od_g) : ld c,a : ld a,(od_y) : ld b,1 : jp mk_ln
od_cpy  ld a,(od_y) : call scr_line : ex de,hl          ; DE = the screen line (column 0)
        ld a,(od_y) : sub 8 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld bc,#9401 : add hl,bc                 ; HL = DSCR for column 0 (screen column c = DSCR byte c + 1)
        ld a,(od_g) : ld (od_gm),a
        ld a,1 : ld bc,7 : call od_seg
        ld a,8 : ld bc,8 : call od_seg
        ld a,16 : ld bc,8 : call od_seg
        ld a,24 : ld bc,5
od_seg  push hl : push de : ld (od_t),a
        ld a,(od_gm) : rrca : ld (od_gm),a : jr nc,1F
        ld a,(od_t) : add a,l : ld l,a : ld a,(od_t) : add a,e : ld e,a
        ldir
1       pop de : pop hl : ret
od_gm   db 0
od_t    db 0
scr_line
        push af : and #C0 : rrca : rrca : rrca : ld h,a : pop af : push af : and 7 : or h : or #C0 : ld h,a
        pop af : and #38 : rlca : rlca : ld l,a : ret
od_chk  ld (od_y),a : call scr_line : push hl
        ld a,(od_y) : sub 8 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,#9402 : add hl,de
        pop de : inc de
        ld b,28
1       ld a,(de) : cp (hl) : jr nz,2F
        inc hl : inc de : djnz 1B
        ret
2       ld a,#0F : ld (od_g),a : ld a,(od_y) : jp od_line
tr_3d   ld hl,G_BATTLE : jr tr_go
tr_loc  di : ld a,(G_AQU) : or a : jr nz,1F          ; nobody aboard: 4 aquanauts with guns (no "all of them died")
        ld hl,crew_set : call far_x : ld a,7 : call map_w3
1       ld a,1 : ld (tuinf),a                   ; (time units not spent in this fight)
        ld a,(DBG) : or a : jr z,2F                             ; (debug: the locations in turn - xpg.asm dbg_loc)
        ld hl,dbg_loc : call far_x : ld a,7 : call map_w3
2
        ld hl,G_BATTL1
tr_go   di
        ld sp,#403E
        push hl
        ld a,(G_TTYPE) : cp 100 : jr c,1F
        xor a : ld (G_TTYPE),a                  ; no target: the UFO
1       ld a,(G_TUFO) : cp 3 : jr c,2F
        xor a : ld (G_TUFO),a                   ; UFO type 0..2
2       ld a,(G_TINTR) : cp 3 : jr c,3F
        xor a : ld (G_TINTR),a                  ; interceptor type 0..2
3       xor a : ld (svc),a : ld (free),a
        ld hl,96*256+128 : ld (G_COORD),hl : ld (lastx),hl  ; the game's cursor in the middle (at the right edge a fight scrolls)
        ld h,0 : ld (scx),hl : ld a,100 : ld (scy),a        ; and ours there
        call G_MEM7
        ei
        ret                                     ; BATTLE / BATTL1 switch to ZX screen mode themselves
zx_alex ld a,(d3off) : or a : jr z,1F
        ld a,1 : scf : ret                      ; "UFO damaged": landing question
1       ld hl,#C900 : jp #BCE9
; ui_mouse (not a wide fight), a saved game in RAM: half a second after the game's last write of it, to the disk
d_chk   ld a,(G_SEED) : ld hl,d_fr : cp (hl) : ret z : ld (hl),a     ; (once a frame)
        ld hl,d_qt : inc (hl) : ld a,(hl) : cp 25 : ret c
        ld (hl),0
; the saved game into UFO2.SAV now, the game running
d_save  ld a,(d_ok) : or a : jr nz,1F
        ld (d_dirty),a : ret
1       ld hl,d_flush
; HL = a routine calling BDOS, the game running. As CE.COM keeps CP/M: I #F9 IM 2, W3 = page 3 (#7C: BDOS), W2 =
; page 2, #7FFD = 3 (its BIOS pages through it); its BIOS's RAM: page 5's tails (#1F40.., #3F40..: past each 8000
; bytes of a picture - CP/M itself runs EGA there). So: DI; #7FFD = 3 (buffer A shown: our picture stays on screen,
; the BIOS keeps that, it was told EGA); CP/M's page 3 and the tails of 5, 1 swapped in; its I / IM, EI; the routine;
; DI; all back. W1 = the game's bank 5 all along.
d_cpm   ld (dv_hl),hl
        ld a,i : push af : di
        call ay_off                             ; (the music quiet while CP/M works: no note held)
        push bc : push de : push hl : push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        ld (dv_sp),sp
        IFDEF NEDOOS                            ; (n_bdos: in page 3 - W3; the screens stay as they are)
        WIN P_W3, 3
        ld sp,NB_DSTK                           ; (the kernel wants SP >= #3B00 at its calls: dk_stk is below)
        WIN P_W2, 2
        ld hl,(n_vec) : push hl : ld hl,n_iret : ld (n_vec),hl    ; (as CP/M's handler then: the game's - int_h, int_f -
        ei                                                          ;  put W3 back from W3V)
        ld hl,(dv_hl) : call 1F
        di
        pop hl : ld (n_vec),hl
        ld sp,(dv_sp)                           ; (before W3 changes: this stack is in page 3)
        ELSE
        ld sp,(dv_ns)                           ; (W0: #3D00..#3D3C past the fight's stack; in a fight: dk_stk)
        ld a,3 : ld bc,#7FFD : out (c),a
        call d_swap                             ; W3 = page 3, W2 = page 2 (as at the start)
        call cpm_int : ei                       ; its interrupts (the keyboard controller left in its ZX mode)
        ld hl,(dv_hl) : call 1F
        di
        ld a,#3E : ld i,a : im 2                ; ours again
        ld a,3 : ld bc,#7FFD : out (c),a        ; (the BIOS may have left its ROM2 map on)
        call d_swap
        ld a,(bf) : rlca : rlca : rlca : ld bc,#7FFD : out (c),a
        ENDIF
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,(cur) : call map_w3
        ld sp,(dv_sp)
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix : pop hl : pop de : pop bc
        pop af : ld i,a : ret po : ei : ret
1       jp (hl)
dv_hl   dw 0
dv_sp   dw 0
dv_ns   dw #3D3A
; the palette: 0..7 the ZX colours, 8..15 bright (as CP/M's ESC M0 had it): port #BD77 (PEN2 = 0: #FF is the
; palette), the entry by the border (#FE: 0..7, #F6: 8..15), the value inverted (D0 B, D1 R, D4 G; D5 b, D6 r, D7 g;
; D2, D3 = 1); then #FD77 again (#FF the disk port), the border black. A = the mode (#FD77's value) kept. DI.
pal_std ld (pl_m),a
        IFDEF NEDOOS
        ld hl,pl_tab : PAL_HKS : ld a,(pl_m)
        ENDIF
        ld bc,#BD77 : out (c),a
        ld hl,pl_tab : ld e,0
1       ld a,e : and 7 : bit 3,e : jr nz,2F
        out (#FE),a : jr 3F
2       out (#F6),a
3       ld a,(hl) : out (#FF),a : inc hl
        inc e : ld a,e : cp 16 : jr c,1B
        ld a,(pl_m) : ld bc,#FD77 : out (c),a
        xor a : out (#FE),a : ret
pl_m    db 0
pl_tab  db #FF,#FE,#FD,#FC,#EF,#EE,#ED,#EC      ; black, blue, red, magenta, green, cyan, yellow, white
        db #FF,#DE,#BD,#9C,#6F,#4E,#2D,#0C      ; bright
        IFNDEF NEDOOS                           ; (CP/M's only)
; CP/M's interrupts as at the start: its I, IM 1 or 2 (im_det)
cpm_int ld a,(cpm_i) : ld i,a : ld a,(cpm_im1) : or a : jr z,1F
        im 1 : ret
1       im 2 : ret
        ENDIF
d_fr    db 0
        IFNDEF NEDOOS                           ; (CP/M's only)
; pages 3, 7 <-> PG_S3, PG_S7; the tails of 5, 1 (#1F40.., #3F40.., 192 bytes each) <-> PG_S5, PG_S1's
; page 3 <-> PG_S3 whole; the tails of 5, 1 (#1F40.., #3F40.., 192 bytes each) <-> PG_S5, PG_S1's
; (W3, W2; leaves W3 = 3, W2 = page 2)
d_swap  WIN P_W3, 5
        ld a,PG_S5 : call map_w2 : call 1F
        WIN P_W3, 1
        ld a,PG_S1 : call map_w2 : call 1F
        WIN P_W3, 3
        ld a,PG_S3 : call map_w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : call 2F
        ld a,2 : jp map_w2
1       ld hl,#9F40 : ld de,#DF40 : ld bc,192 : call 2F
        ld hl,#BF40 : ld de,#FF40 : ld bc,192
2       ld a,(de) : ex af,af' : ld a,(hl) : ld (de),a : ex af,af' : ld (hl),a
        inc hl : inc de : dec bc : ld a,b : or c : jr nz,2B
        ret
        ENDIF
; UFO2.SAV (the game saved by "Запись на диск": 64 records; at the start, and from "Чтение с диска") -> dpages[0] #0000..#1FFF (tracks 4, 5); no file: as is
s_load  call sf_init : ld c,15 : call BDOS : inc a : ret z
        ld de,rbuf : ld c,26 : call BDOS
        ld hl,#8000 : ld b,64                   ; first into page PLA (the whole file or nothing; no fight now)
1       push bc : push hl
        ld de,sfcb : ld c,20 : call BDOS : or a : jr nz,2F
        pop de : push de
        di : ld a,PLA : call map_w2
        ld hl,rbuf : ld bc,128 : ldir
        ld a,2 : call map_w2 : ei
        pop hl : ld de,128 : add hl,de
        pop bc : djnz 1B
        ld hl,#8000 : ld b,64                   ; complete: -> dpages[0] (through rbuf)
3       push bc : push hl
        di : ld a,PLA : call map_w2
        ld de,rbuf : ld bc,128 : ldir
        ld a,(dpages) : call map_w2
        pop de : push de : ld hl,rbuf : ld bc,128 : ldir
        ld a,2 : call map_w2 : ei
        pop hl : ld de,128 : add hl,de
        pop bc : djnz 3B
        ret
2       pop hl : pop bc : ret
; "Чтение с диска" (the game reads track 4 from sector 1): UFO2.SAV from the disk first (not in a wide fight)
d_load  ld a,(bwide) : or a : ret nz
        ld a,(d_ok) : or a : ret z
        ld hl,s_load : jp d_cpm
; the saved game (tracks 4, 5: dpages[0] #0000..#1FFF, 64 records) -> UFO2.SAV (on UFO2.DAT's drive): deleted,
; made again, written in turn, closed (BDOS 19, 22, 21, 16)
d_flush ld a,(d_dirty) : or a : ret z
        ld a,(d_ok) : or a : ret z
        xor a : ld (d_dirty),a
        call sf_init : ld c,19 : call BDOS
        call sf_init : ld c,22 : call BDOS : inc a : ret z
        ld de,rbuf : ld c,26 : call BDOS
        ld hl,#8000 : ld b,64
1       push bc : push hl
        di : ld a,(dpages) : call map_w2
        ld de,rbuf : ld bc,128 : ldir
        ld a,2 : call map_w2 : ei
        ld de,sfcb : ld c,21 : call BDOS
        pop hl : ld de,128 : add hl,de
        pop bc : djnz 1B
        ld de,sfcb : ld c,16 : jp BDOS
; ---- the fight's state <-> UFO2.BTL (the fight's SAVE after the game's RAM save, its LOAD before the game's RAM
; load): the game's banks 2, 5 whole, 6's first half, 7's saved fight (#DB00.., what SAVE put there: the map, B_DAT,
; MAN). Called from XPG (x_dsk; in a wide fight it brought this overlay in over BDSC); back with W3 = XPG.
; A = 0 save, 1 load -> A = 1 done
dk_op   ld (dk_a),a : xor a : ld (dk_ok),a
        ld a,(d_ok) : or a : jr z,9F
        ld hl,(dv_ns) : push hl : ld hl,dk_stk : ld (dv_ns),hl
        ld hl,dk_run : call d_cpm
        pop hl : ld (dv_ns),hl
9       ld a,XPG : call map_w3p
        ld a,(dk_ok) : ret
dk_run  call bf_init : ld a,(dk_a) : or a : jr nz,dk_rd
        ld c,19 : call BDOS
        call bf_init : ld c,22 : call BDOS : inc a : ret z
        ld de,dkbuf : ld c,26 : call BDOS
        ld hl,G_BUILD : ld (dkbuf),hl : call bd_wr : jr nz,8F         ; (the first record: the build that wrote it)
        ld hl,dk_tab
1       call dk_ent : jr z,8F
2       di : ld hl,(dk_p) : ld a,(hl) : call map_w2
        ld hl,(dk_ad) : ld de,dkbuf : ld bc,128 : ldir : ld (dk_ad),hl
        ld a,2 : call map_w2 : ei
        call bd_wr : jr nz,8F                                           ; (the disk full: as far as it went)
        ld hl,dk_n : dec (hl) : jr nz,2B
        ld hl,(dk_p) : ld de,4 : add hl,de : jr 1B
8       ld c,16 : call bd_f
        ld a,(dk_p) : ld hl,dk_end : cp l : ret nz : ld a,1 : ld (dk_ok),a : ret
dk_rd   ld c,15 : call BDOS : inc a : ret z                            ; (no file: the RAM's)
        ld c,35 : call bd_f                                             ; the whole file or nothing
        ld a,(bfcb+35) : or a : ret nz
        ld hl,(bfcb+33) : ld de,DK_N : or a : sbc hl,de : ret nz         ; (another size: an old build's)
        ld de,dkbuf : ld c,26 : call BDOS
        call bd_rd : ret nz
        ld hl,(dkbuf) : ld de,G_BUILD : or a : sbc hl,de : ret nz       ; (another build's: its game code not ours)
        ld hl,dk_tab
1       call dk_ent : jr z,8F
2       call bd_rd : ret nz
        di : ld hl,(dk_p) : ld a,(hl) : call map_w2
        ld hl,dkbuf : ld de,(dk_ad) : ld bc,128 : ldir : ld (dk_ad),de
        ld a,2 : call map_w2 : ei
        ld hl,dk_n : dec (hl) : jr nz,2B
        ld hl,(dk_p) : ld de,4 : add hl,de : jr 1B
8       ld a,1 : ld (dk_ok),a : ret
; HL = dk_tab's entry -> dk_p, dk_n, dk_ad; Z: the end
dk_ent  ld (dk_p),hl : ld a,(hl) : inc a : ret z
        inc hl : ld e,(hl) : inc hl : ld d,(hl) : inc hl : ld a,(hl) : ld (dk_n),a : ld (dk_ad),de : ret
bd_rd   ld c,20 : jr 1F
bd_wr   ld c,21
1       call bd_f : or a : ret
bd_f    ld de,bfcb : jp BDOS
dk_tab  db PG_ZX+2 : dw #8000 : db 128
        db PG_ZX+5 : dw #8000 : db 128
        db PG_ZX+6 : dw #8000 : db 64
        db PG_ZX+7 : dw #9B00 : db 74          ; (#DB00..#FFFF)
dk_t7   db PG_ZX+7 : dw #9800 : db 6           ; screen 7's attributes (the field's colour)
dk_end  db #FF
DK_N    equ 1+128+128+64+74+6                   ; (the first record: G_BUILD - the build that wrote it)
dk_a    db 0
dk_ok   db 0
dk_n    db 0
dk_p    dw 0
dk_ad   dw 0
bf_init ld a,(dfcb) : ld (bfcb),a
        ld hl,bfcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld de,bfcb : ret
bfcb    db 0,"UFO2    BTL" : ds 24
dkbuf   ds 128
        ds 150                                  ; (d_cpm's stack in a fight)
dk_stk
; sfcb: the drive of UFO2.DAT, the rest zero; DE = sfcb
sf_init ld a,(dfcb) : ld (sfcb),a
        ld hl,sfcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld de,sfcb : ret
sfcb    db 0,"UFO2    SAV" : ds 24
lay_outd2
        ld a,(ega) : or a : jp z,G_OUTDSC+6     ; ZX screen mode: the game's own copy
        ld (infight),a
        ld a,(fall) : or a : jr nz,.alm
        ; the marked group-lines
        ld c,1                                  ; row
1       ld hl,fdrow : ld b,0 : add hl,bc : ld a,(hl) : or a : jr z,.nr
        ld (hl),0 : ld (od_g),a
        ld de,FDN : add hl,de : ld a,(hl) : ld (hl),0 : ld (od_l),a
        push bc
        ld a,c : add a,a : add a,a : add a,a : ld (od_y),a
        ld b,8
2       ld hl,od_l : rrc (hl) : jr nc,3F
        push bc : ld a,(od_y) : call od_line : pop bc
3       ld hl,od_y : inc (hl)
        djnz 2B
        pop bc
.nr     inc c : ld a,c : cp 17 : jr c,1B
        ; one more field line: compared
        ld a,(fscan) : add a,8 : and 127 : ld (fscan),a     ; (8 apart: all 128 in 16 passes)
        add a,8 : call od_chk
        jp od_end
.alm    xor a : ld (fall),a
        ld hl,fdrow : ld b,2*FDN
4       ld (hl),0 : inc hl : djnz 4B
.all    ld a,8                                  ; all the field (the game's own copy)
5       push af : ld (od_y),a : ld a,#0F : ld (od_g),a : call od_cpy : pop af
        inc a : cp 136 : jr c,5B
        ld a,8 : ld bc,128*256+#0F : call mk_ln
        jp od_end
sc_capw ld a,(fready) : or a : ret nz
        ld a,(bchg) : or a : ret nz             ; (changes not shown yet)
        ld a,(cap_r) : ld c,a : ld b,0
        ld hl,drow : add hl,bc : ld a,(hl) : or a : ret nz     ; (the row has marks)
        ld hl,psync : add hl,bc : ld a,(hl) : or a : ret nz    ; (the back = the shadow there)
        ld a,UPG : call map_w3p
        ld a,(cap_r) : or a : call z,sc_capsel
        ld a,(cap_r) : call sc_caprow
        ld hl,cap_r : inc (hl) : ld a,(hl) : cp 24 : ret c
        ld (hl),0 : xor a : ld (cap_pend),a : jp sc_capfin
