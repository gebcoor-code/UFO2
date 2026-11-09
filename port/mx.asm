; ---- MPG's MX (W3 = MPG, #CE00 .. OB_Z0): code loaded from UFO2.DAT (zxl.asm mx_img; ram_init.asm mx_load).
; Called from UPG: ld hl,routine : call far_m (ui.asm; A, flags back as the routine leaves them).
mx_id   db "MX"

; ---- (panel.asm pn_bclr: mk_all in the wide fight, screen 7 all new - COPY) a popup over state A? The game's window
; (MENU: S_COPY, BYE) over the field: in state A still (sy_off 0), at least WN_MIN of screen 7's field cells (rows
; 1..16, columns 1..28) still of the field's attribute (FW_C) (all: no window rows - WN_R0 #FF): NZ, BPOP = 1, WN_R0..WN_R1 its rows (state B
; then converts only those, tpg.asm bc_t1; pscan_u off). Else Z, BPOP = 0 (a whole picture: state B as ever).
WN_MIN  equ 112
WN_MC   equ 4                           ; a window's row: at least 4 cells not of the field's attribute
WN_MAXR equ 12                          ; a popup: at most 12 rows (WN_R1 - WN_R0 < 12; the Y/N question: 8)
wn_det  xor a : ld (BPOP),a
        ld a,(sy_off) : or a : jp nz,9F : ld (wn_n),a : ld (wn_n+1),a
        ld a,#FF : ld (WN_R0),a : xor a : ld (WN_R1),a
        ld a,i : push af                                        ; (interrupts as they are: the music's ticks - int_f
        ld (wn_sp),sp : ld sp,#3F60                             ;  touches W3 only; the game's stack may be in W1)
        WIN P_W1, 15
        ld hl,#5821 : ld c,1                                    ; row 1, column 1
1       ld b,28 : push hl : ld e,0
2       ld a,(FW_C) : cp (hl) : jr z,3F
        inc e : jr 4F
3       push hl : ld hl,(wn_n) : inc hl : ld (wn_n),hl : pop hl
4       inc hl : djnz 2B
        pop hl : ld a,e : cp WN_MC : jr c,5F                    ; (fewer: not the window's - the 3D cursor's cells)
        ld a,(WN_R0) : cp c : jr c,51F : ld a,c : ld (WN_R0),a
51      ld a,c : ld (WN_R1),a
5       ld de,32 : add hl,de : inc c : ld a,c : cp 17 : jr c,1B
        WIN P_W1, PG_ZX+5
        ld sp,(wn_sp)
        pop af : jp po,6F : ei
6       ld hl,(wn_n) : ld de,-WN_MIN : add hl,de : jp nc,9F
        ld a,(WN_R1) : or a : jr z,7F
        ld hl,WN_R0 : sub (hl) : cp WN_MAXR : jr nc,9F          ; (taller: a whole screen drawn in parts - the soldier's)
        ld a,1 : ld (BPOP),a : or a : ret                       ; NZ, P: a popup (state B its way)
7       ld (bst),a : dec a : ret                                ; NZ, M: no window rows (row 0, the panel's rows only -
                                                                ; the aliens' turn's line: the name bar shows it): state A
9       ld a,24 : ld (s_hold),a                                 ; Z (a whole picture: not converted till the game
        ld a,(POLLN) : ld (hl_p),a : ld a,(ifr) : ld (hl_t),a   ;  polls - it may copy it again, the soldier's
        xor a : ret                                             ;  screen: hk_mx)
wn_n    dw 0
hl_p    db 0
hl_t    db 0
wn_sp   dw 0
; ---- (wideu.asm outd_u) a popup's end (state B -> A): state B's marks gone, the field rows under it (y 4 + 8 r:
; state A's rows WN_R0 .. WN_R1 + 1) out again from the colour plane (the panels' columns stay - pl_post)
wn_end  ld hl,drow : ld b,48
1       ld (hl),0 : inc hl : djnz 1B
        ld a,(WN_R0) : inc a : ret z : dec a : ld e,a : ld d,0 : ld hl,fdrow : add hl,de
        ld a,(WN_R1) : sub e : add a,2 : ld b,a
2       ld (hl),#1F : ld de,FDN : add hl,de : ld (hl),#FF : ld de,-FDN : add hl,de : inc hl : djnz 2B
        ret
; ---- (wideu.asm bat_off_u, DI) the shadow of screen 7 (SHP: all "changed" - inverted; SHA)
bo_shd WIN P_W1, 15                           ; screen 7 at W1
        ld de,SHP : ld c,0                      ; c = r*8 + l (order of SHP)
1       ld a,c : rrca : rrca : rrca : and #1F : ld b,a  ; r
        and #18 : ld h,a : ld a,c : and 7 : or h : or #40 : ld h,a
        ld a,b : and 7 : rrca : rrca : rrca : ld l,a    ; HL = screen 7 line (r, l)
        ld b,32
2       ld a,(hl) : cpl : ld (de),a : inc hl : inc de : djnz 2B
        inc c : ld a,c : cp 192 : jr c,1B
        ld hl,#5800 : ld de,SHA : ld bc,768 : ldir
        WIN P_W1, PG_ZX+5
        ret

; ---- (wideu.asm hk_lat: each conversion step's end - interrupts) the fight's quick keys latched (xpg.asm x_hot: a
; press while the game is busy - no poll - not lost)
; (zxl.asm mk_off: OFFS / OFFD, the EGA view, not a fight) the rows looked for in the screen cache, the capture
mo_mx   push hl : ld hl,sc_rowf : ld b,24
3       ld (hl),1 : inc hl : djnz 3B
        ld a,CAPQ : ld (cap_pend),a : xor a : ld (cap_r),a
        pop hl
; (mo_mx: OFFS / OFFD - DE: the cleared screen's start - 1) its text map emptied: CM_S, TA_S, the rows' flags
; (D = #BF: screen 7) or CM_D, TA_D (#8F: the DSCR) - nothing there is text now (TXPG at W2 a moment)
tx_clr  push hl : push de
        ld a,d : cp #BF : ld hl,#A000 : jr z,1F : cp #8F : jr nz,9F : ld hl,#A400
1       ld bc,P_W2 : ld a,#7F-TXPG : out (c),a
        push hl : ld c,#10 : call 2F : ld bc,32 : ld a,0 : call 4F : pop hl     ; CM: all a blank (#10: the space - as
        ld a,h : sub #10 : ld h,a : ld bc,768 : xor a : call 4F                 ;  epg.asm tx_cv's), the rows' flags, TA: 0
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
9       pop de : pop hl : ret
2       ld a,c : ld bc,768
4       ld (hl),a : ld d,h : ld e,l : inc de : dec bc : ldir : inc hl : ret     ; (HL past it)
; (mk_sim: PUTSIM done - rows H.., columns L.., B x C cells of screen 7 or the DSCR) a picture there: those cells'
; text map emptied (CM_S / CM_D, TA; TXPG at W2 a moment) - the text layer leaves them to the conversion
cm_simx push af : push bc : push de : push hl : push ix : pop hl
        ld a,(G_SCOSCR+1)
cm_box  cp #C0 : ld d,#A0 : jr z,1F : cp #90 : jr nz,9F : ld d,#A4
1       ld a,b : or a : jr z,9F : ld a,c : or a : jr z,9F
        ld a,l : cp 32 : jr nc,9F
        ld a,32 : sub l : cp b : jr c,11F : ld a,b
11      ld e,a                                          ; E: the columns (not past 31)
        push bc : ld bc,P_W2 : ld a,#7F-TXPG : out (c),a : pop bc
2       ld a,h : cp 24 : jr nc,8F
        push hl
        ld a,h : rrca : rrca : rrca : ld h,a : and #E0 : or l : ld l,a : ld a,h : and 3 : add a,d : ld h,a   ; (row * 32 + column)
        ld b,e
3       ld (hl),0 : ld a,h : sub #10 : ld h,a : ld (hl),0 : add a,#10 : ld h,a : inc l : djnz 3B     ; (CM, TA)
        pop hl : inc h : dec c : jr nz,2B
8       ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
9       pop hl : pop de : pop bc : pop af : ret
; (mk_psc: PUTSCR done - line H, column L, B bytes x C lines) the same for the cells it touched
cm_pscx push af : push bc : push de : push hl : push ix : pop hl
        ld a,c : or a : jr z,9B
        ld a,h : add a,c : jr nc,1F : ld a,0 : dec a                ; (the last line + 1, at most 255)
1       dec a : rrca : rrca : rrca : and 31 : ld c,a
        ld a,h : rrca : rrca : rrca : and 31 : ld h,a
        ld a,c : sub h : inc a : ld c,a                                ; C: rows from row H
        ld a,(G_BCOSCR+1) : jp cm_box
; (mk_hl: PCOORD - HL a pixel's address in screen 7 / the DSCR) its cell is not text now: out of the text map
cm_hlx  push af : push hl : push bc : push ix : pop hl
        ld a,h : cp #D8 : jr nc,9F : cp #C0 : ld c,#A0 : jr nc,1F : cp #A8 : jr nc,9F : cp #90 : jr c,9F : ld c,#A4
1       and #18 : rrca : rrca : rrca : add a,c : ld h,a                  ; (row * 32 + column: its third * 256 + L)
        push bc : ld bc,P_W2 : ld a,#7F-TXPG : out (c),a : pop bc
        ld (hl),0 : ld a,h : sub #10 : ld h,a : ld (hl),0
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
9       pop bc : pop hl : pop af : ret
hk_mx   ld a,(MUS_TRK) : cp 5 : jr nz,4F                        ; (a fight's music waiting for the field: with the
        ld a,(LD_ON) : or a : jr nz,4F : ld a,(PL_USE) : or a : jr z,4F  ;  colour plane fs_all stays - fc_t2 not used; the
        ld a,2 : ld (MUS_TRK),a                                 ;  location loaded: the field is on the screen)
4       ld a,(s_hold) : cp 24 : jr nz,3F                        ; (held: out at the game's poll, 40 frames at most)
        ld a,(POLLN) : ld hl,hl_p : cp (hl) : jr nz,2F
        ld a,(ifr) : ld hl,hl_t : sub (hl) : cp 40 : jr c,3F
2       xor a : ld (s_hold),a : inc a : ld (fast),a                     ; (now all of it: fast - a flip meanwhile cleared it)
3       ld a,(infight) : or a : ld a,20 : jr z,1F : ld a,25
1       ld (agef),a
        ld a,(bwide) : or a : jr nz,0F                      ; (not the wide fight, nothing changed since the flip:
        ld a,(infight) : or a : ret nz
        ld a,(bchg) : or a : ret nz                             ;  the age counts from now - scr.asm agef: from the
        ld a,(ifr) : ld (age),a : ret                           ;  first change on)
0
        ld bc,#F7FE : in a,(c) : cpl : and #0F : ld hl,HK_L1 : or (hl) : ld (hl),a
        ld b,#FB : in a,(c) : cpl : and #1F : ld hl,HK_L2 : or (hl) : ld (hl),a : ret
; ---- (wideu.asm sy_a / sy_b) the copy grid: state A (the field's rows: y 8 r, 25) / B (screen 7's: y 4 + 8 r, 24);
; nothing pending (a pending scroll: all out anyway; UPG's offsets: sy_a's own). sy_ap / sy_bp (a popup's end / start:
; only its rows converted - the rest of the other buffer must still get its pending copies): those moved into the
; new grid instead (sy_ba / sy_ab)
sy_apx  call sy_ba : xor a : ld b,FDN : jr 3F
sy_bpx  call sy_ab : ld a,4 : ld b,24 : jr 3F
sy_amx  xor a : ld b,FDN : jr 1F
sy_bmx  ld a,4 : ld b,24
1       ld hl,bsync : ld c,4*SYN
2       ld (hl),0 : inc hl : dec c : jr nz,2B
3       ld (sy_off),a : ld a,b : ld (sy_n),a
        xor a : ld (sh_pend),a : ld h,a : ld l,a : ld (sh_off),hl
        ret
; bsync, psync (groups; their lines at + SYN) A -> B: B's row r (y 4 + 8 r) = A's rows r, r + 1 (y 8 r), all lines
sy_ab   ld hl,bsync : call 1F : ld hl,psync
1       ld b,SYN-1
2       ld a,(hl) : inc hl : or (hl) : dec hl : ld (hl),a : call sy_lin : inc hl : djnz 2B
        xor a : ld (hl),a : jr sy_lin                          ; (row 24: none in B)
; B -> A: A's row k = B's rows k - 1, k
sy_ba   ld hl,bsync+SYN-1 : call 1F : ld hl,psync+SYN-1
1       ld b,SYN-1
2       ld a,(hl) : dec hl : or (hl) : inc hl : ld (hl),a : call sy_lin : dec hl : djnz 2B
        ld a,(hl)
; HL = a row's groups (A = them): its lines all (none: none)
sy_lin  push hl : ld de,SYN : add hl,de : or a : jr z,1F : ld a,#FF
1       ld (hl),a : pop hl : ret
; ---- (wideu.asm mk_lut; zxl.asm at the start) the LUT (window 0): 4 tables (pixel pairs 00 01 10 11) x 256 attributes
mk_lmx  ld c,0
1       ld l,c : ld h,high LUT
        ld a,c : and 7 : bit 6,c : jr z,2F : or 8
2       ld (ink),a
        ld a,c : rrca : rrca : rrca : and 7 : bit 6,c : jr z,3F : or 8
3       ld (pap),a
        ld a,(pap) : call pl : ld b,a : ld a,(pap) : call pr : or b : ld (hl),a : inc h    ; 00
        ld a,(pap) : call pl : ld b,a : ld a,(ink) : call pr : or b : ld (hl),a : inc h    ; 01: right ink
        ld a,(ink) : call pl : ld b,a : ld a,(pap) : call pr : or b : ld (hl),a : inc h    ; 10: left ink
        ld a,(ink) : call pl : ld b,a : ld a,(ink) : call pr : or b : ld (hl),a            ; 11
        inc c : jr nz,1B
        ret
pl      ld d,a : and 7 : ret z : bit 3,d : ret z : or #40 : ret          ; (bright black: black - slot 8 is the
pr      ld d,a : and 7 : ret z : rlca : rlca : rlca : bit 3,d : ret z : or #80 : ret    ; fight's brown, xp_fight)
ink     db 0
pap     db 0
; ---- (wideu.asm fd_all) all the field's rows marked (fdrow)
fd_mx   ld hl,fdrow : ld b,FDN
1       ld (hl),#1F : push hl : ld de,FDN : add hl,de : ld (hl),#FF : pop hl : inc hl : djnz 1B
        ret
; ---- (wideu.asm outd_u, the ZX screen mode: screen 7 at W1) all of the field into screen 7
ou_all  ld a,8
9       push af : call ou_line : pop af : inc a : cp 136 : jr c,9B
        ret
; screen line A (8..135): field line A + 24, bytes 2..29 -> screen 7 (at W1) columns 1..28
ou_line push af
        and #C0 : rrca : rrca : rrca : ld d,a : pop af : push af : and 7 : or d : or #40 : ld d,a
        pop af : push af : and #38 : rlca : rlca : inc a : ld e,a       ; DE = screen line, column 1
        pop af : add a,24 : ld l,a : ld h,0
        add hl,hl : add hl,hl : ld b,h : ld c,l : add hl,hl : push hl : add hl,hl : add hl,hl : add hl,bc : pop bc : add hl,bc   ; * 44
        ld bc,BDSC+2 : add hl,bc
        DUP 28
        ldi
        EDUP
        ret
; ---- the geoscape's message window (rows 15..23, columns 0..23) as a console: SCROLL's new line (screen 7's row 23)
; typed - a character a frame (zxl.asm ifr: each frame's) from its first non-blank column to its last, a block cursor before it (the paper:
; #00 or #FF - whichever the line has more of; the cursor - its complement). The game waits at SCROLL's end till it is
; typed (build/mods.py: LAY_SCRL with B = 1 - wideu.asm scl_u -> tw_q), the frames' ticks: uipage.asm ui_int_u
; -> tw_tick (int_h - the game's HALT, before the conversion). Screen 7 at W2 meanwhile (DI; no calls there)
TW_S    equ #90E0                       ; screen 7's row 23 at W2 (line l: + l * 256)
TW_MAX  equ 60                          ; frames the game waits at most
; (wideu.asm scr_u: SCROLL done, rows 15..23 still held) the new line kept, its columns from the first non-blank one
; blank, the cursor there
tw_beg  xor a : ld (tw_on),a : inc a : ld (fast),a         ; (the scrolled window converted in one step, shown
        ld a,(ega) : or a : ret z                               ;  whole - also with a blank new line)
        ld a,i : push af : di
        call tw_w2
        ld hl,TW_S : ld de,tw_buf : ld b,8
1       push bc : push hl : ld bc,24 : ldir : pop hl : inc h : pop bc : djnz 1B
        ld hl,tw_buf : ld bc,192*256 : xor a                    ; the paper: #00 or #FF, whichever is more of the bytes
5       cp (hl) : jr z,51F : inc c
51      inc hl : djnz 5B
        ld a,c : cp 97 : sbc a,a : cpl : ld (tw_bg),a           ; (C: the bytes not 0 - fewer than 97: 0)
        ld c,0 : ld de,#00FF                                    ; E: the first non-blank column (#FF none), D: the last
2       call tw_cb : jr z,3F
        ld a,e : inc a : jr nz,21F : ld e,c
21      ld d,c
3       inc c : ld a,c : cp 24 : jr c,2B
        ld a,e : inc a : jr z,8F                                ; (all blank)
        ld a,e : ld (tw_t),a : ld a,d : ld (tw_e),a
        ld c,e
4       ld a,(tw_bg) : call tw_cs : inc c : ld a,c : cp 24 : jr c,4B
        ld c,e : ld a,(tw_bg) : cpl : call tw_cs
        ld a,(ifr) : ld (tw_f),a
        ld a,TW_MAX : ld (tw_n),a : ld a,1 : ld (tw_on),a
8       call tw_w2b
        pop af : ret po : ei : ret
; (a frame, int_h: DI) the cursor's column gets its character back, the cursor on to the next one (past the last:
; done). The cursor's column not the cursor, the next one not blank: the game drew there - stop
tw_tick ld a,(tw_on) : or a : ret z
        ld a,(infight) : ld hl,bwide : or (hl) : jr nz,0F        ; (a fight started meanwhile - LOC GO: stop)
        ld a,(ifr) : ld hl,tw_f : ld b,(hl) : ld (hl),a : sub b : jr nz,1F : inc a     ; (a character a frame: the
1       cp 8 : jr c,2F : ld a,8                                 ;  frames since the last tick, 8 at most)
2       ld (tw_k),a
        call tw_w2
        ld a,(tw_t) : ld (tw_p),a
3       ld a,(tw_t) : ld c,a
        call tw_cz : jr nz,7F
        call tw_rs
        call tw_cb : call nz,tw_clk                             ; (a letter, not a blank: the beeper clicks)
        inc c : ld a,(tw_e) : cp c : jr c,7F                    ; (the last one typed)
        ld a,c : ld (tw_t),a
        call tw_cf : jr nz,7F
        ld a,(tw_bg) : cpl : call tw_cs
        ld hl,tw_k : dec (hl) : jr nz,3B
        jr 8F
7       xor a : ld (tw_on),a
8       call tw_w2b
        ld a,1 : ld (fast),a                                    ; (all that is marked converted in the next step,
                                                                ;  shown after it: the game waits anyway)
        ld a,(tw_p) : call tw_g : ld c,a : ld a,(tw_t) : inc a : call tw_g : or c : ld c,a
        ld a,184 : ld b,8 : jp mk_ln                            ; (row 23's lines, those columns' groups)
0       xor a : ld (tw_on),a : ret
; (wideu.asm scl_u: SCROLL's end, the game waits) NZ: still typing; too long - all of it at once, Z
tw_q    ld a,(tw_on) : or a : ret z
        ld a,(btn_l) : or a : jr nz,3F                          ; (a click / a key meanwhile: the rest at once - the
        xor a : in a,(#FE) : cpl : and #1F : jr nz,3F           ;  menus not kept waiting by the typing)
        ld hl,tw_n : dec (hl) : ret nz
3
        ld a,i : push af : di
        call tw_w2
        ld a,(tw_t) : ld c,a
1       call tw_rs : inc c : ld a,c : cp 24 : jr c,1B
        xor a : ld (tw_on),a
        call tw_w2b
        pop af : jp po,2F : ei
2       ld a,184 : ld bc,8*256+7 : call mk_ln : xor a : ret
; a light click of the beeper (#FE bit 4; the border black)
tw_clk  ld a,#10 : out (#FE),a : ld b,24
1       djnz 1B
        xor a : out (#FE),a : ret
; screen 7 at W2 / W2 back
tw_w2   ld a,7 : call bk_pg : xor #7F : ld bc,P_W2 : out (c),a : ret
tw_w2b  ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a : ret
; column C: Z - tw_buf's all blank (tw_cb), the screen's all blank (tw_cf) / all the cursor (tw_cz); A -> the screen's (tw_cs);
; tw_buf's -> the screen (tw_rs)
tw_cb   ld h,high tw_buf : ld l,c : ld b,8
1       ld a,(tw_bg) : cp (hl) : ret nz : ld a,l : add a,24 : ld l,a : djnz 1B
        xor a : ret
tw_cf   ld a,(tw_bg) : jr 2F
tw_cz   ld a,(tw_bg) : cpl
2       ld e,a : call tw_sa
1       ld a,(hl) : cp e : ret nz : inc h : djnz 1B
        xor a : ret
tw_cs   push af : call tw_sa : pop af
1       ld (hl),a : inc h : djnz 1B
        ret
tw_rs   call tw_sa : ex de,hl : ld h,high tw_buf : ld l,c
1       ld a,(hl) : ld (de),a : inc d : ld a,l : add a,24 : ld l,a : djnz 1B
        ret
tw_sa   ld a,low TW_S : add a,c : ld l,a : ld h,high TW_S : ld b,8 : ret
; column A (0..24) -> its group's bit (columns 8 g .. 8 g + 7)
tw_g    rrca : rrca : rrca : and 3 : ld b,a : inc b : xor a : scf
1       rla : djnz 1B
        ret
tw_on   db 0                                    ; 1: typing
tw_bg   db 0                                    ; the paper's byte (the cursor: its complement)
tw_t    db 0                                    ; the cursor's column
tw_e    db 0                                    ; the last one to type
tw_p    db 0                                    ; the first column typed this tick
tw_f    db 0                                    ; the frame (ifr) of the last tick
tw_k    db 0                                    ; the characters still to type this tick
tw_n    db 0                                    ; the frames the game may still wait
        ALIGN 256
tw_buf  ds 192                                  ; the line (8 lines x 24)
; ---- (xtil.asm tx_init, the start: MPG at W3, TXPG at W2: GF #A800, OF #B000 - ico_load's, after it at #B800 the drawn ones' bits - build/mkico.py) OF's
; characters not drawn in FONT.png from GF (0s - the letter): the letter's classes - the upper half of its rows the
; light (all 8 rows: none), the rest the letter; the shadow - a cell pixel with the letter left or up-left of it
og_gen  xor a : ld (og_k),a
1       ld a,(og_k) : ld c,a : rrca : rrca : rrca : and 15 : ld l,a : ld h,#B8
        ld a,c : and 7 : ld b,a : inc b : ld a,(hl)
2       rrca : djnz 2B
        jr c,9F                                                 ; (drawn)
        ld l,c : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push hl : add hl,hl : ld de,#B000 : add hl,de
        push hl : pop ix : pop hl : ld de,#A800 : add hl,de     ; IX: OF, HL: GF
        push hl : ld bc,#0800
3       ld a,(hl) : inc a : jr z,31F : inc c
31      inc hl : djnz 3B
        ld a,c : and 7 : srl a : ld (og_lt),a : xor a : ld (og_pv),a
        pop hl : ld b,8
4       push bc : push hl
        ld a,(hl) : cpl : ld c,a                                ; C: the letter
        ld a,(og_pv) : or c : srl a : ld b,a : ld a,c : cpl : and b : ld b,a    ; B: the shadow
        ld a,c : ld (og_pv),a
        or a : jr z,41F : ld a,(og_lt) : or a : jr z,41F : dec a : ld (og_lt),a
        ld a,c : or b : ld c,b : ld b,a : jr 42F                ; (light: high bits L | S, low S)
41      ld a,c : or b : ld c,a                                  ; (the letter: high S, low L | S)
42      ld h,8
5       sla b : rl e : rl d : sla c : rl e : rl d : dec h : jr nz,5B
        ld (ix+0),d : ld (ix+1),e : inc ix : inc ix
        pop hl : inc hl : pop bc : djnz 4B
9       ld hl,og_k : inc (hl) : bit 7,(hl) : jp z,1B
        ret
og_k    equ STAGE+8192                                  ; (W1: STAGE's - its first 1024 bytes tx_init's)
og_lt   equ og_k+1
og_pv   equ og_k+2
