; ------------------------------------------------------------------ the wide battlefield: page UPG part (see wide.asm)
; a location fight starts (DI): the wide field in window 0 from now on
bat_on  ld hl,int_f : ld (#3D3E),hl : ld a,5 : ld (MUS_TRK),a   ; the fight's music (once the field is shown): COMBAT turns interrupts on
        xor a : ld (G_EIDI),a : ld (G_DLDI),a   ; (E_I's and DELAY's DI after their HALT: off)
        ld a,1 : ld (bwide),a : ld (bst),a : ld (infight),a : ld (fs_new),a : ld (fs_all),a
        ld a,(ega) : or a : ld a,31 : jr z,0F : ld a,41
0       ld (rxe),a                              ; the right scroll edge (BX): EGA 41, ZX screen 31
        ld a,(G_COLOR) : ld (FW_C),a
        WIN P_W2, MPG : xor a : ld (lp_ok-#4000),a : WIN P_W2, PG_ZX+2      ; (the location's palette: textr.asm lp_set)
        ld a,FSLOT : ld (nslot),a
        call t2_ld                              ; (fc_t2 into TPG)
        ld hl,#5F00 : ld de,SBU : call sbu_cp   ; the geoscape's bottom display kept (sbu_cp)
        xor a : ld (cap_pend),a : ld (fast),a : ld (fall),a : ld (ui_red),a
        ld hl,sc_rowf : ld b,24
1       ld (hl),a : inc hl : djnz 1B
        ld hl,fdrow : ld b,2*FDN
2       ld (hl),a : inc hl : djnz 2B
        ld hl,fe_row : ld b,2*FDN
3       ld (hl),a : inc hl : djnz 3B
        call sy_b                               ; (state B's copy grid)
        xor a : ld hl,BDSC : ld de,BDSC+1 : ld bc,BLINES*BW-1 : ld (hl),a : ldir
        ld hl,dbg_bat : call far_x              ; (debug LOC GO: the next location - xpg.asm; into BDSC's tail)
        ld a,(ega) : or a : ret z
        jp ld_beg                               ; black, "Loading..."; all of screen 7 marked (state B) - ui6

; after the fight (the game's windows, DI): LUT, the shadow (all "changed"), the attribute shadow back
bat_off_u
        call mus_fo
        ld a,i : push af : di
        WIN P_W1, OVPG                         ; window 0's overlay back (BDSC covered it)
        ld hl,#4000 : ld de,ovl_start : ld bc,ovl_end-ovl_start : ldir
        WIN P_W1, PG_ZX+5
        call sy_b
        xor a : ld (bwide),a : ld (bst),a : ld (LD_ON),a : ld (BPOP),a : inc a : ld (ui_red),a   ; (LD_ON: a location left while loading; BPOP: a popup's - textc.asm txf skipped columns 0, 29..31)
        ld a,(xp_p) : ld hl,bo_rmp : call far_m               ; (the buffers' field into the standard palette's colours: textr.asm)
        call xp_std
        IFDEF NEDOOS                            ; (the palette black till the EGA view - ovl.asm ega_re puts the
        call pal_blk                            ;  standard one back: the fight's screen in the standard colours - its
        ENDIF                                   ;  ZX underlay - not seen meanwhile; the overlay is back here)
        ld a,NSLOT : ld (nslot),a
        call mk_lut
        ld hl,bo_shd : call far_m               ; the shadow (mx.asm)
        ld hl,SBU : ld de,#5F00 : call sbu_cp   ; the geoscape's bottom display back
        pop af : ret po : ei : ret

; The geoscape keeps its bottom display (the money, 24 x 9 characters) in bank 7 at #DF00 (ScrBU, LODMON puts
; it back after a fight) - but the fight's RAM SAVE (C_SAVE) copies MAN to #DC00..#DFFF and bank 6 to #E000..: the
; display came back as garbage (the game's own bug). A copy in MUSPB (#F000, past its modules) over the fight.
SBU     equ #B000                       ; (W2: MUSPB's #F000)
sbu_cp  push af : ld a,i : push af : di
        WIN P_W1, 15 : WIN P_W2, MUSPB
        ld bc,24*9*8 : ldir
        WIN P_W1, PG_ZX+5 : WIN P_W2, PG_ZX+2
        pop af : jp po,1F : ei
1       pop af : ret

; (shift2.asm ov_fl3: ico.asm ov_fl wants the back's cursor off) off, the overlays, on again - the flip would show
; the back buffer without it (the cursor's bottom blinking over the world map's lines)
ov_flb  call ep_hidb : ld hl,ov_fl : call far_x
        call swaprec : ld a,(bf) : xor 1 : call ep_mb : call 1F : jp swaprec
1       ld a,(cs_on) : or a : ret nz                                    ; (as ui.asm cur_show - W3 stays UPG)
        ld a,(ct_y) : inc a : ret z
        ld hl,(ct_x) : ld (cs_x),hl : ld a,(ct_y) : ld (cs_y),a
        ld a,1 : ld (cs_md),a : ld a,(cs_mode) : inc a : ld (cs_on),a
        jp cs_iof
; the LUT (window 0): mx.asm mk_lmx
mk_lut  ld hl,mk_lmx : jp far_m

; OUTDSC in the fight (bank 7 in W3; here screen 7 at W1): the changed part of the field into screen 7
; (columns 1..28 = field bytes 2..29: the game's menus take their background from there; the ZX screen mode
; shows it) and for the EGA conversion (fe_row); state B -> A
; a location loading for ~30 s (1536 cursor steps): the game shows something and waits (the demo's end at a colony
; before period 2...) - LD_ON 0, all of screen 7 to be converted: Z
; SCROLL done (zxl.asm lay_scre): text.asm tx_scr
scr_u   push af : push bc : push de
        ld hl,tx_scr : call far_x
        ld hl,tw_beg : call far_m               ; (mx.asm: the console's line - before the rows are converted)
        xor a : ld (s_hold),a
        pop de : pop bc : pop af : ret
; SCROLL's step (B = 0): rows 15..23 held; else (B = 1, its end) the console still typing: NZ (mx.asm tw_q)
scl_u   ld a,b : or a : jr nz,1F
        ld a,9 : ld (s_hold),a : ret
1       ld hl,tw_q : jp far_m
ld_tmo  ld hl,(ld_t) : inc hl : ld (ld_t),hl : ld a,h : cp 6 : jr nc,1F : or 1 : ret
1       xor a : ld (LD_ON),a : push bc : ld b,24 : ld c,#0F : call mk_rows : pop bc : xor a : ret
ld_t    dw 0
; outd_u: state B -> A (the popups gone: the text map's field rows too - their characters are not there any more)
ld_end  xor a : ld (bst),a : ld (LD_ON),a : ld (BPOP),a : ld a,(FW_C) : ld (BC_CMP),a
        ld hl,tx_fcl : jp far_x
outd_u  ld a,1 : ld (infight),a
        call fw_set : nop : nop : nop           ; the field's attribute (screen 7's cell could be the cursor's) - ui6
        WIN P_W1, 15
        ld a,(ega) : or a : jp z,.all           ; ZX screen mode: all of it (no marks there)
        ld a,(fall) : or a : jr z,1F
        xor a : ld (fall),a
        call fd_all
1       ld a,(bst) : or a : jr z,2F
        ld a,(BPOP) : or a : jr z,0F
        ld hl,wn_end : call far_m : call ld_end : call sy_ap : jr 2F     ; a popup's end: only its rows again
0       call ld_end : nop                       ; state B -> A: everything again (the field, the panels); LD_ON 0
        call xp_fight
        inc a : ld (fs_all),a : ld (pn_full),a
        ld hl,drow : ld b,48                    ; (state B's marks: all of it is drawn now)
7       ld (hl),0 : inc hl : djnz 7B
        call sy_a
        call fd_all
2       ld c,0                                  ; field rows 0..24
3       ld hl,fdrow : ld b,0 : add hl,bc : ld a,(hl) : or a : jr z,4F
        ld (hl),0 : ld de,fe_row-fdrow : add hl,de : or (hl) : ld (hl),a
        ld de,fdlin-fe_row : add hl,de : ld a,(hl) : ld (hl),0 : ld (ou_l),a
        ld de,fe_lin-fdlin : add hl,de : or (hl) : ld (hl),a
        ; (screen 7's field: only when the game saves the screen - text.asm ou_fl at its BACK)
4       inc c : ld a,c : cp FDN : jr c,3B
        WIN P_W1, PG_ZX+5
        ret
.all    ld hl,ou_all : call far_m                            ; (mx.asm)
        WIN P_W1, PG_ZX+5
        ret
ou_l    db 0
; all the field's rows marked (fdrow)
fd_all  ld hl,fd_mx : jp far_m                                ; (mx.asm)
; (uipage.asm ov_fl6: each conversion step's end - interrupts) the fight's quick keys latched (x_hot: a press while
; the game is busy - no poll - not lost)
hk_lat  ld hl,hk_mx : call far_m : jp ov_fl3                 ; (mx.asm)
; the copy grid: state A (the field's rows: y 8 r, 25 of them) / B (screen 7's: y 4 + 8 r, 24); nothing pending
sy_a    ld hl,sy_amx : jr 1F                                    ; (mx.asm: the grid, the pending scroll, bsync)
sy_ap   ld hl,sy_apx : jr 1F                                    ; (a popup's end, start: the pending copies kept)
sy_bp   ld hl,sy_bpx : jr 1F
sy_b    ld hl,sy_bmx
1       call far_m : ld hl,0 : ld (off0),hl : ld (off1),hl : ld (cur_off),hl : ret


; ---- the wide fight (no shadow): screen 7's parts outside the field compared with their copy (here), a part per
; interrupt; what differs is marked (the game also draws there without its hooks: attribute bars...).
; Parts 0..7: rows 0, 17..23 (8 lines x 32 + 32 attributes); 8..23: rows 1..16, columns 29..31 (8 x 3 + 3)
ps_n    db 0
PS_ROWS equ #E400                       ; (UPG) the copies: 8 x 288
PS_COLS equ PS_ROWS+8*288               ; 16 x 27
ps_tab  db 0,17,18,19,20,21,22,23
pscan_u ld a,(BPOP) : or a : ret nz                     ; (a popup: state A's panels stay)
        WIN P_W1, 15                           ; screen 7 at W1
        ld a,(ps_n) : inc a : cp 24 : jr c,1F : xor a
1       ld (ps_n),a : cp 8 : jr nc,.col
        ; a whole row
        ld e,a : ld d,0 : ld hl,ps_tab : add hl,de : ld c,(hl)          ; C = row
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,hl : add hl,de
        add hl,hl : add hl,hl : ld de,PS_ROWS : add hl,de : ex de,hl    ; DE = its copy (n * 288)
        call ps_l0 : ld b,8
2       push bc : push hl : ld b,32 : call ps_cmp : pop hl : pop bc : inc h : djnz 2B
        call ps_at : ld b,32 : call ps_cmp
        ld a,(ps_d) : or a : jr z,.r
        ld a,(ps_q) : or a : jr nz,.r
        ld a,c : ld b,1 : ld c,#0F : call mk_rows
        jr .r
.col    sub 8 : ld l,a : ld h,0 : ld d,h : ld e,l : add hl,hl : add hl,de : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,hl : add hl,de    ; n * 27
        ld de,PS_COLS : add hl,de : ex de,hl
        ld a,(ps_n) : sub 7 : ld c,a                    ; row 1..16
        call ps_l0 : ld a,l : add a,29 : ld l,a : ld b,8
3       push bc : push hl : ld b,3 : call ps_cmp : pop hl : pop bc : inc h : djnz 3B
        call ps_at : ld a,l : add a,29 : ld l,a : ld b,3 : call ps_cmp
        ld a,(ps_d) : or a : jr z,.r
        ld a,(ps_q) : or a : jr nz,.r
        ld a,c : ld b,1 : ld c,#08 : call mk_rows
.r      WIN P_W1, PG_ZX+5
        ret
ps_d    db 0
ps_q    db 0                            ; 1: the copies only (ps_sync)
; all of the copies as screen 7 is now, nothing marked (state B -> A: the whole panel is drawn anyway)
ps_sync ld a,1 : ld (ps_q),a : ld b,24
1       push bc : call pscan_u : pop bc : djnz 1B
        xor a : ld (ps_q),a : ret
        ASSERT $ < PS_ROWS
; C = row -> HL = its line 0 at W1 (ps_d = 0)
ps_l0   xor a : ld (ps_d),a
        ld a,c : and #18 : or #40 : ld h,a : ld a,c : and 7 : rrca : rrca : rrca : ld l,a : ret
; C = row -> HL = its attributes at W1
ps_at   ld a,c : rrca : rrca : rrca : ld l,a : and 3 : or #58 : ld h,a : ld a,l : and #E0 : ld l,a : ret
; B bytes HL (screen 7) against DE (the copy): differences copied, ps_d = 1 (DE moves on)
ps_cmp  ld a,(de) : cp (hl) : jr z,1F
        ld a,(hl) : ld (de),a : ld a,1 : ld (ps_d),a
1       inc hl : inc de : djnz ps_cmp
        ret

; the fight's RAM SAVE / LOAD progress (lay_prog, the game's windows): the bar into the shown buffer; at the end
; its line given back to the conversion (marked: the fight converts without a shadow)
lay_prog_u
        push bc : push de
        ld a,b : ld (pg_b),a
        ld c,14 : ld a,d : cp #57 : jr z,1F : ld c,11
1       ld a,c : ld (pg_v),a
        ld a,(bwide) : or a : jp z,5F : ld a,(bst) : or a : jp nz,5F
        ; state A: right of our cursor (64 x 4; left of it at the right edge), both buffers; at the end the field
        ; and the panels there again
        ld a,(pg_b) : cp 32 : jr nz,2F
        ld hl,(scx) : ld de,10 : add hl,de : ld de,320-66 : or a : sbc hl,de : add hl,de : jr c,1F
        ld hl,(scx) : ld de,-68 : add hl,de : jr c,1F : ld hl,0
1       srl h : rr l : ld a,l : ld (pg_e0),a
        ld a,(scy) : add a,3 : cp 196 : jr c,11F : ld a,195
11      ld (pg_y),a
2       xor a : call pn_map : call pg_draw : ld a,1 : call pn_map : call pg_draw
        ld a,(pg_b) : dec a : jr nz,7F
        ld a,(pg_e0) : ld e,a : ld c,0 : ld b,32 : push bc : push de : xor a : call pn_map : pop de : pop bc
        push bc : push de : call pg_run : ld a,1 : call pn_map : pop de : pop bc : call pg_run
        ld a,(pg_e0) : ld e,a : ld a,(pg_y) : ld hl,pl_now : call far_x                         ; (the field's rows there again: xpg.asm)
        call pn_show                                            ; (the panels there again)
        jr 7F
5       ld a,12 : ld (pg_e0),a : ld a,190 : ld (pg_y),a
        ld a,(bf) : call pn_map : call pg_draw
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,(pg_b) : dec a : jr nz,4F
        ld a,186 : ld bc,4*256+3 : call mk_ln
4       pop de : pop bc : ret
7       WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        pop de : pop bc : ret

sh_all  ld a,1 : ld (fs_all),a : ld hl,fe_row : ld b,FDN
2       ld (hl),#1F : push hl : ld de,FDN : add hl,de : ld (hl),#FF : pop hl : inc hl : djnz 2B
        ret

; HL = an offset -> sp_dx (bytes), sp_dy (rows): HL = 320 sp_dy + sp_dx; CY: too far (all out instead)
sh_dec  ld c,0
1       bit 7,h : jr nz,3F
        ld de,161 : or a : sbc hl,de : add hl,de : jr c,5F
        ld de,-320 : add hl,de : inc c : jr 1B
3       ld de,160 : add hl,de : bit 7,h : jr nz,4F
        or a : sbc hl,de : jr 5F
4       ld de,160 : add hl,de : dec c : jr 1B
5       ld a,l : ld (sp_dx),a : ld a,c : ld (sp_dy),a
        ld a,l : add a,39 : cp 79 : ccf : ret c         ; |dx| >= 40
        ld a,c : add a,24 : cp 49 : ccf : ret
; the fight's SAVE / LOAD with the disk (lay_dsk; A = 0 / 1)
u_dsk   ld hl,x_dsk : jp far_x
; (shift2.asm sh_pan) the shadow moved by sh_off - not with the colour plane (BDSC not drawn, not converted)
sh_fsh  ld hl,(sh_off) : ld a,h : or l : ret z
        ld a,(PL_USE) : or a : ret nz
        ld (sh_o),hl
        WIN P_W1, TPG
        ld hl,FSH-#8000 : jp sh_rg
; the field scrolled (sh_fall: IX = its sh_tab entry, (ix+4) 0 left, 1 right, 2 up, 3 down): the coloured frames'
; records with it (xspr.asm xs_shf; the game's windows: W1 = bank 5)
xs_scr  ld a,(PL_USE) : or a : jr z,1F         ; the colour plane: the game's own move of BDSC skipped (its LD DE,
        ld hl,14 : add hl,sp : ld a,(hl) : add a,11 : ld (hl),a : jr nc,1F : inc hl : inc (hl)   ; HL, BC, LDIR /
1       ld a,(ix+4) : push af                   ; LDDR: 11 bytes; the game's return: lay_fall's SP + 4 = ours + 14)
        WIN P_W1, SPG
        pop af : push af : call xs_shf
        WIN P_W1, TLPG
        pop af : call pl_shf                    ; (xtil.asm: the colour plane)
        WIN P_W1, PG_ZX+5
        ret
; ---- the field view (state A) with the location's palette (0.66.0: lp_set's - by default the NedoOS colours in slots
; 8, 11, 4, 3, 5: brown, green, grey-green, maroon, pink; the field's paper slot its ZX colour); xs_tab for it. W1 =
; screen 7 after.
xp_fight
        ld hl,ptab : ld (ptab_p),hl             ; (debug LOC GO's patch table done: xpg.asm dbg_loc)
        ld a,(ega) : or a : ret z
        ld a,15 : ld hl,lp_set : call far_m     ; (the location's palette, unless the first sprite did it: textr.asm)
        ld a,(FW_C) : rrca : rrca : rrca : and 7 : ld (xp_p),a
        ld c,a : ld b,1 : cp 5 : jr nz,1F : inc b       ; (B 2: the paper cyan - its slot kept)
1       call xp_go
        WIN P_W1, SPG : ld a,(xp_p) : call xs_mkt
        WIN P_W1, SPG2 : ld a,(xp_p) : call xs_mkt
        WIN P_W1, 15
        ret
; the standard palette back (the fight's end)
xp_std  ld a,(ega) : or a : ret z
        ld a,#FF : ld (xp_p),a : ld c,a : ld b,0
; B = 0: the standard palette, 1 / 2: the location's (C = its paper's slot: kept) - the palette, the game's colours
; on screen 7 through the slots the field left (textc.asm xp_rmp); the screen cache gone
xp_go   ld hl,sc_val : xor a : ld (hl),a : inc hl : ld (hl),a : inc hl : ld (hl),a
        ld hl,tx_rm : jp far_x
xp_p    db #FF
; the fight's music faded out before the work after it (the music silent anyway: as is). Interrupts on 10 frames
; (int_f: only the music; the game's code is in our call), then as they were.
mus_fo  ld a,(MUS_TRK) : cp 4 : ret nc
        ld hl,(#3D3E) : ld de,int_f : or a : sbc hl,de : ret nz                 ; (int_f: the fights')
        ld a,4 : ld (MUS_TRK),a
        ld a,i : push af : ei
        ld b,10
1       halt : djnz 1B
        pop af : ret pe : di : ret
; the coloured location: fc_t2's row through the plane (xpg.asm pl_post), then the panels
pl_pst  push af : ld hl,pl_post : call far_x : pop af : jp pn_ovl
