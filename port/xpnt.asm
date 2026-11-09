; ---- the hooks' part (TLPG at XPA): not in UFO2.COM - UFO2.DAT's last block (ufo2p.bin, after obj.asm and MX:
; ram_init.asm mx_load puts it into TLPG)
xpnt_img
        DISP XPA
; (PL_SPR: W3 = MPG; BC, DE kept) HL = the draw's frame word: L = frame (#FF: none), H = its table (W2's: xs_tab / xs_tf)
pf_get  ld hl,#FFFF
        ld a,(os_hx) : or a : ret z : cp XN+1 : ret nc
        push de : push bc
        ld e,(ix+6) : ld d,(ix+7) : ld hl,-G_DATR : add hl,de : jr nc,9F
        ld a,h : or a : jr nz,9F : ld a,l : cp 128 : jr nc,9F
        ld hl,(G_HIX) : inc hl : inc hl : inc hl
        ld a,(os_lv) : or a : ld a,(hl) : inc hl : ld c,(hl) : jr z,1F
        add a,a : ld b,a : ld a,c : add a,a : add a,a : add a,a : add a,a : add a,b : jr 2F     ; alive: direction * 2 + race * 16
1       ld a,c : add a,128                                                                      ; dead: 128 + race
2       cp XF : jr nc,9F : ld l,a
        call pf_tab : ld h,a
        push hl : call ob_fs : pop hl : jr 8F                   ; (his rows converted again: obj.asm)
9       ld hl,#FFFF
8       pop bc : pop de : ret
; os_hx -> A = his table (as XS_COL: the one in focus red, our others blue, the aliens as drawn)
pf_tab  ld a,(os_hx) : ld b,a : ld a,(ob_cur) : cp b : ld a,high xs_tab+#40 : ret z
        ld a,b : cp 11 : ld a,high xs_tf+#40 : ret c : ld a,high xs_tab+#40 : ret
; a ZX picture (mp_src: 4 bytes a line - mask, ink of the left column, of the right one; in mp_pg's page at W2) on the
; plane's lines pq_y.. (pp_n, pp_r0 its first line), its columns mp_cm (bit 0 the left, 1 the right) from pp_p0's pair,
; shifted by mp_s pairs: (screen OR mask) XOR ink, the ZX bit black - mask and ink white, the mask alone black
mp_put  call pp_clip : ret z
        ld a,12 : ld (pp_np),a : call pp_pair : ret z
        ld a,(pp_r0) : add a,a : add a,a : ld e,a : ld d,0 : ld hl,(mp_src) : add hl,de : ld (mp_src),hl
        ld a,(pp_n) : ld b,a
1       push bc
        ld a,(mp_pg) : ld bc,P_W2 : out (c),a
        ld hl,(mp_src) : ld e,(hl) : inc hl : ld d,(hl) : inc hl : ld c,(hl) : inc hl : ld b,(hl) : inc hl : ld (mp_src),hl
        ld a,(mp_cm) : rrca : jr c,2F : ld e,0
2       rrca : jr c,3F : ld c,0
3       ld a,d : and e : ld d,a                                 ; white: the mask's pixels XORed (ZX: paper)
        ld a,b : and c : ld b,a
        ld hl,0 : ld a,(mp_s) : or a : jr z,5F
4       srl e : rr c : rr l : srl e : rr c : rr l
        srl d : rr b : rr h : srl d : rr b : rr h
        dec a : jr nz,4B
5       ld a,e : ld (mp_m),a : ld a,c : ld (mp_m+1),a : ld a,l : ld (mp_m+2),a
        ld a,d : ld (mp_m+3),a : ld a,b : ld (mp_m+4),a : ld a,h : ld (mp_m+5),a
        ld de,pp_lb : ld hl,mp_m : ld b,3
6       push bc : ld c,(hl) : inc hl : push hl : inc hl : inc hl : ld b,(hl)  ; C = the mask, B = white
        ld a,4
7       push af
        xor a : rl b : rla : rl b : rla : call 8F : ld (de),a : inc de
        xor a : rl c : rla : rl c : rla : call 9F : ld (de),a : inc de
        pop af : dec a : jr nz,7B
        pop hl : pop bc : djnz 6B
        ld bc,P_W2 : ld a,#7F-PLA : out (c),a
        call pp_ln
        ld hl,(pq_o) : ld de,40 : add hl,de : ld (pq_o),hl
        pop bc : dec b : jp nz,1B
        ret
9       or a : ret z : cp 2 : ld a,#B8 : ret c : ld a,#47 : ret z : ld a,#FF : ret
8       or a : ret z : cp 2 : ld a,(mp_xr) : ret c : ld a,(mp_xl) : ret z : push hl : ld hl,mp_xr : or (hl) : pop hl : ret

; ---- after a hook (obj.asm ob_ent; W1 = TLPG, W3 = MPG; IX: ob_ent's)
ob_post ld a,(pl_use) : or a : ret z
        ld a,(ob_cur) : ld hl,fc_cur : cp (hl) : call nz,fc_go  ; (the one in focus changed: his colours, the last one's)
        ld l,(ix+12) : ld h,(ix+13)
        ld de,lfd2_r : or a : sbc hl,de : jr z,.spr
        ld de,lfd1_r-lfd2_r : or a : sbc hl,de : jr z,.spr
        ld de,lfpd_r-lfd1_r : or a : sbc hl,de : jr z,.off
        ld de,lfdc_r-lfpd_r : or a : sbc hl,de : ret nz
        ld l,(ix+16) : ld h,(ix+17)
        ld de,G_GBUH : or a : sbc hl,de : ld a,0 : jr z,.go
        ld de,G_PBUH-G_GBUH : or a : sbc hl,de : ld a,1 : jr z,.go
        ld de,G_ALLSH-G_PBUH : or a : sbc hl,de : ld a,4 : jr z,.go
        ld de,G_ALLSE-G_ALLSH : or a : sbc hl,de : ret nz : ld a,5 : jr .go
.off    ld a,3 : jr .go
.spr    ld l,(ix+6) : ld h,(ix+7) : ld de,-G_xMARKE : add hl,de : ret nc   ; the 3D cursor's picture (its first line)
        ld a,h : cp 2 : ret nc : ld a,l : and 127 : ret nz
        ld a,2
.go     ld (po_k),a
        ld (PL_SP),sp : ld sp,PL_SP : call 0F : jp pl_ret
0       ld a,(po_k) : or a : jp z,gb_put : dec a : jp z,pb_put : dec a : jp z,cs_put : dec a : jp z,cx_off
        dec a : jp z,as_beg : jp as_end
; ---- the fighter in focus changed (ob_cur): the last one's pixels of his frame red -> blue, the new one's blue -> red
; (where the plane has his frame's colour: not where something in front covers him)
fc_go   push ix : ld (PL_SP),sp : ld sp,PL_SP : call fc_chk : ld sp,(PL_SP) : pop ix : ret
fc_chk  call as_brk
        ld a,(ob_cur) : ld hl,fc_cur : ld b,(hl) : ld (hl),a : push af
        ld a,b : ld bc,(high xs_tf+#40)*256+high xs_tab+#40 : call fc_one
        pop af : ld bc,(high xs_tab+#40)*256+high xs_tf+#40
; A = index + 1 (a fighter of ours; none: 0), C = his table now, B = the new one
fc_one  or a : ret z : cp 11 : ret nc : dec a
        ld (fc_to),bc
        add a,a : add a,a : add a,a : ld l,a : ld h,high xs_rec+#40     ; his record (SPG's, W2)
        ld bc,P_W2 : ld a,#7F-SPG : out (c),a
        ld a,(hl) : cp XF : jp nc,9F : ld (pl_pf),a
        inc l : ld e,(hl) : inc l : ld d,(hl) : inc l
        push hl : ld hl,-32 : add hl,de : ld (pq_y),hl : pop hl
        ld e,(hl) : inc l : ld d,(hl) : ld hl,-16 : add hl,de : sra h : rr l : ld (pp_p0),hl
        xor a : ld (pp_r0),a : ld a,24 : ld (pp_n),a
        ; his rows' groups converted again (W3 = MPG: obj.asm ob_frc)
        ld hl,(pp_p0) : sra h : rr l : sra h : rr l : ld a,l : add a,2 : ld (ob4),a : add a,2 : ld (ob4+1),a
        ld hl,(pq_y) : ld de,32 : add hl,de : push hl : call rk_8 : ld (ob4+2),a
        pop hl : ld de,23 : add hl,de : call rk_8 : ld (ob4+3),a
        ld hl,ob4 : call ob_f4 : call fb_ob4
        call pp_clip : jp z,9F
        ld a,8 : ld (pp_np),a : call pp_pair : jp z,9F
        ld hl,(pp_lbj) : ld de,-pp_lb : add hl,de : srl h : rr l : ld de,fc_ob : add hl,de : ld (fc_obj),hl
        ld a,(pl_pf) : ld c,SPG : cp XF1 : jr c,1F : sub XF1 : ld c,SPG2
1       ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld d,h : ld e,l : add hl,hl : add hl,de
        ld de,XFR+#4000 : add hl,de : ld (pp_src),hl
        ld a,#7F : sub c : ld (pp_pg),a
        ld a,(W3V) : ld (gb_w3),a : ld bc,P_W3 : ld a,#7F-PLB : ld (W3V),a : out (c),a
        ld a,(pp_n) : ld b,a
2       push bc
        ld a,(pp_n) : sub b : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld de,(pp_src) : add hl,de
        ld a,(pp_pg) : ld bc,P_W2 : out (c),a
        ld de,fc_ob : ld (fc_p),de : ld de,pp_lb : ld b,8
3       ld a,(hl) : inc hl : push hl
        ld l,a : ld h,high xs_om+#40 : ld c,(hl)
        ld a,(fc_tn) : ld h,a : ld a,(hl) : ld (de),a : inc de : ld a,c : ld (de),a : inc de
        ld a,(fc_to) : ld h,a : ld a,(hl) : ld hl,(fc_p) : ld (hl),a : inc hl : ld (fc_p),hl
        pop hl : djnz 3B
        ld bc,P_W2 : ld a,#7F-PLA : out (c),a
        call fq_ln
        ld hl,(pq_o) : ld de,40 : add hl,de : ld (pq_o),hl
        pop bc : djnz 2B
        jp gb_unm
9       ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a : ret
; (as pp_ln) the line's pairs, only the pixels with his old colour (fc_ob's)
fq_ln   ld hl,(pq_o) : ld de,(pp_a) : add hl,de
        ld de,(pp_lbj) : ld ix,(fc_obj) : ld a,(pp_c) : ld b,a : ld a,(pp_ph) : ld c,a
1       inc de : ld a,(de) : dec de : or a : jr z,2F
        push bc : ld b,a
        ld a,(hl) : xor (ix+0) : ld c,a
        and #47 : jr z,11F : ld a,b : and #B8 : ld b,a          ; (the left pixel another colour: not his)
11      ld a,c : and #B8 : jr z,12F : ld a,b : and #47 : ld b,a
12      ld a,(de) : ld c,a : ld a,(hl) : xor c : and b : xor (hl) : ld (hl),a : pop bc
2       inc de : inc de : inc ix
        ld a,c : inc c : or a : jr z,30F : dec a : jr z,31F : dec a : jr z,32F
        res 6,h : res 5,h : inc hl : ld c,0 : jr 4F
30      set 6,h : jr 4F
31      res 6,h : set 5,h : jr 4F
32      set 6,h
4       djnz 1B
        ret
fc_cur  db 0
fc_to   db 0                                    ; his table now, the new one
fc_tn   db 0
fc_obj  dw 0
fc_p    dw 0
fc_ob   ds 8
; (cs_put) the 3D cursor's picture (cu_x its byte - its right half's for RS2 -, cu_y its first line) within the place
; kept (sv_x, sv_x + 1; sv_y + 0..32)? CY: not - not drawn (the game's other pictures of xMARKE - an edge's mark - at
; places P_AD does not tell: POFF would leave them)
cs_in   ld a,(cu_x) : sub 2 : ld hl,sv_x : sub (hl) : cp 2 : ccf : ret c
        ld a,(sv_y) : ld l,a : ld a,(cu_y) : sub l : cp 33 : ccf : ret
; (W1 = TLPG: xpnt's)
; the field scrolled (sh_fall -> xs_scr): A = 0 a byte left, 1 right, 2 8 lines up, 3 down - the plane the same
; (W2: PLA then PLB, then the game's bank 2)
pl_shf  ld (pl_dir),a : xor a : ld (as_ok),a                ; (as_*: the old list's places moved)
        ld a,(pl_use) : or a : ret z
        call pl_rel                                             ; (the draws' list too: sq_cut)
        ld a,i : push af : ei                   ; (frames of work: the music's ticks go on - int_f touches only W3)
        ld a,#7F-PLA : call 1F
        ld a,#7F-PLB : call 1F
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        pop af : ret pe : di : ret
1       ld bc,P_W2 : out (c),a
        ld hl,#8000 : call 2F : ld hl,#A000
2       ld a,(pl_dir) : or a : jr z,.lt : dec a : jr z,.rt : dec a : jr z,.up
        push hl                                                 ; down 8 lines: 199..8 <- 191..0, 0..7 none
        ld de,199*40+39 : add hl,de : ld d,h : ld e,l : ld bc,-320 : add hl,bc : ld bc,192*40 : call pl_bd
        pop hl : jr .clr
.up     push hl                                                 ; up 8 lines: 0..191 <- 8..199, 192..199 none
        ld d,h : ld e,l : ld bc,320 : add hl,bc : ld bc,192*40 : call pl_bi
        pop hl : ld de,192*40 : add hl,de
.clr    ld (hl),0 : ld d,h : ld e,l : inc de : ld bc,319 : ldir : ret
.lt     push hl : ld d,h : ld e,l : inc hl : ld bc,8000 : call pl_bi    ; all a byte down (line L's 39 <- L + 1's 0:
        pop hl : ld de,39 : add hl,de : ld de,40 : jr 5F                 ; past the part's 8000 its tail's byte - then
.rt     push hl : ld de,7999 : add hl,de : ld d,h : ld e,l : dec hl : ld bc,8000 : call pl_bd   ; 39 none), up
        pop hl : ld de,40                                               ; (0 <- the line before's 39: 0 none)
5       ld b,200 : xor a
6       ld (hl),a : add hl,de : djnz 6B
        ret
; BC (a multiple of 32) bytes HL -> DE, up / down (LDI / LDD 32 at a time)
pl_bi
        DUP 32
        ldi
        EDUP
        jp pe,pl_bi
        ret
pl_bd
        DUP 32
        ldd
        EDUP
        jp pe,pl_bd
        ret
; each fight's start (XS_CLR's; tl_exp after it): the plane empty (black), in use if UFO2.TIL was read
pl_new  call sq_inv : xor a : ld (as_ok),a
        ld a,(pl_ok) : ld (pl_use),a : ld (PL_USE),a : ld (pl_exp),a : or a : ret z
        ld a,i : push af : ld de,pl_clr : call cs_ed                           ; (the music meanwhile: int_f - W3 only)
        pop af : jp po,3F : ei
3       ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a : ret
pl_clr  ld a,#7F-PLA : ld e,0 : call 1F
        ld a,#7F-PLB : ld e,0
1       ld bc,P_W2 : out (c),a
        ld hl,#8000 : ld (hl),e : ld de,#8001 : ld bc,#3FFF : ldir : ret
; (pl_mk: past tl_nm - below)
; ---- a scroll coming (pl_shf; W1 = TLPG): the 3D cursor's place and the moving one's back first - the plane
; moves, their kept places would not (the game's POFF / PBU after it: nothing)
pl_rel  ld (PL_SP),sp : ld sp,PL_SP : ld a,(W3V) : push af
        ld bc,P_W3 : ld a,#7F-MPG : ld (W3V),a : out (c),a     ; (the list's page: the callers' W3 may be another)
        call cx_off
        ld a,(gb_v) : or a : call nz,pb_rs
        call sq_cut
        pop af : ld (W3V),a : ld bc,P_W3 : out (c),a : jp pl_ret
; ---- POFF: the 3D cursor's place back
cx_off  ld a,(cs_v) : or a : ret z
        xor a : ld (cs_v),a : call cs_box
        call gb_map : ld a,1 : call cs_sr : jp gb_unm
; the 3D cursor's place (P_AD: 64 lines x 2 bytes) -> sv_*, ob4; CY: none
cs_box  ld bc,P_W2 : ld a,#7F-(PG_ZX+5) : out (c),a : ld hl,(G_PAD+#4000)     ; (bank 5's, W2 a moment)
        ld a,#7F-(PG_ZX+2) : out (c),a
        call ob_lc : ret c
        push bc : ld (ob4+2),a : add a,a : add a,a : add a,a : add a,b : ld l,a : ld h,0 : ld de,-32 : add hl,de
        ld (sv_y),hl : ld de,32+63 : add hl,de : call rk_8 : ld (ob4+3),a
        pop bc : ld a,c : ld (ob4),a : inc a : ld (ob4+1),a : sub 3 : ld (sv_x),a
        ld a,2 : ld (sv_w),a : ld a,64 : ld (sv_l),a : xor a : ld (sv_md),a
        call op_chk : or a : ret
cs_sr   ld (sv_d),a : jp sv_go
; ---- a 3D cursor's picture (MS2 / LS2 / RS2 of xMARKE's): the place kept first (the first one since POFF), the picture
cs_put  ld a,(cs_v) : or a : jr nz,1F
        ld bc,P_W2 : ld a,#7F-(PG_ZX+5) : out (c),a : ld a,(G_PVIS+#4000)      ; (the game's PVIS: 0 - not PNTR's
        ld b,H_W2 : ld e,a : ld a,#7F-(PG_ZX+2) : out (c),a : ld a,e : or a : ret z   ; picture - the walk's marks: no place
        call rp_go                                              ; (xrep.asm: a figure's place changed - again; before
        call cs_box : ret c                                     ; the place's test: a cursor at the field's edge too)
        ld a,1 : ld (cs_v),a
        call gb_map : xor a : call cs_sr : call gb_unm
1       ld l,(ix+4) : ld h,(ix+5) : call ob_lc : ret c
        ld e,a : ld a,c : ld (cu_x),a
        ld a,e : add a,a : add a,a : add a,a : add a,b : ld l,a : ld h,0 : ld de,-32 : add hl,de : ld (cu_y),hl
        call cs_in : ret c
        ld l,(ix+12) : ld h,(ix+13) : ld de,lfd2_r : or a : sbc hl,de : ld a,3 : jr z,2F         ; MS2: both
        ld l,(ix+16) : ld h,(ix+17) : ld de,G_LS2+3 : or a : sbc hl,de : ld a,1 : jr z,2F        ; LS2: the left
        ld hl,cu_x : dec (hl) : ld a,2                                                          ; RS2: the right (its
2       ld (mp_cm),a : xor a : ld (mp_s),a                                                      ; place the right's)
        ld a,(cur) : call bk_pg : ld b,a : ld a,#7F : sub b : ld (mp_pg),a
        ld l,(ix+6) : ld a,(ix+7) : sub #40 : ld h,a : ld (mp_src),hl
        ld a,(cu_x) : ld (ob4),a : inc a : ld (ob4+1),a
        ld hl,(cu_y) : ld de,32 : add hl,de : push hl : call rk_8 : ld (ob4+2),a
        pop hl : ld a,(ix+9) : ld e,a : ld d,0 : add hl,de : dec hl : call rk_8 : ld (ob4+3),a
        call op_chk                                             ; (pl_do's variables used there)
        ld hl,(cu_y) : ld (pq_y),hl : ld a,(ix+9) : ld (pp_n),a : xor a : ld (pp_r0),a
        ld a,(cu_x) : sub 2 : call pp_x4
        call gb_map : call mp_put : jp gb_unm

; ---- GBU (after ob_gbu): the place under him kept, his frame (a fighter's: os_hx his) or the ZX picture over it
gb_put  ld hl,(ob_sv) : ld a,h : or l : ret z                   ; (ob_gbu: none)
        ld (gb_ad),hl
        ld a,(os_c) : ld (ob4),a : add a,2 : ld (ob4+1),a : sub 4 : ld (sv_x),a
        ld a,(os_r) : ld (ob4+2),a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_l) : add a,l : ld l,a : add a,23 : rra : rra : rra : and #1F : ld (ob4+3),a
        ld de,-32 : add hl,de : ld (sv_y),hl
        ld hl,ob4 : ld de,gb_rk : ld bc,4 : ldir
        ld hl,(sv_y) : ld (gb_y),hl : ld a,(sv_x) : ld (gb_x),a
        ld a,(os_do) : rrca : ld (mp_s),a
        ; who: as ob_gbu (a MAN entry, his picture xHERO's, coloured: os_hx his) - MPG's still in W3
        ld a,#FF : ld (gb_pf),a
        ld l,(ix+0) : ld h,(ix+1) : ld de,-G_MAN : add hl,de : jr nc,3F
        ld a,h : cp 4 : jr nc,3F
        add hl,hl : add hl,hl : add hl,hl : ld a,(os_hx) : dec a : cp h : jr nz,3F
        ld l,(ix+6) : ld a,(ix+7) : sub high G_xHERO : jr c,3F : ld h,a
        ld de,-96 : ld c,-1
1       inc c : add hl,de : jr c,1B
        ld a,c : cp XF : jr nc,3F : ld (gb_pf),a
        call pf_tab : ld (gb_pt),a
3       ld a,(ix+7) : cp #C0 : ld a,PG_ZX+2 : jr c,4F           ; (the ZX picture: bank 2's at W2, or W3's bank)
        ld a,(cur) : call bk_pg
4       ld b,a : ld a,#7F : sub b : ld (mp_pg),a
        ld l,(ix+6) : ld a,(ix+7) : cp #C0 : jr c,5F : sub #40
5       ld h,a : ld (mp_src),hl
        call op_chk                                             ; (pl_do's variables used there)
        ld a,24 : ld (pp_n),a : xor a : ld (pp_r0),a : ld (sv_md),a : ld (sv_d),a
        ld a,3 : ld (sv_w),a : ld (mp_cm),a : ld a,24 : ld (sv_l),a : inc a : ld (sv_md),a
        call gb_map : call sv_go : ld a,1 : ld (gb_v),a
        ld hl,(gb_y) : ld (pq_y),hl : ld a,(gb_x) : call pp_x4
        ld a,24 : ld (pp_n),a : xor a : ld (pp_r0),a
        ld a,(ix+7) : cp #80 : jp c,gb_unm                      ; (not a picture of bank 2 or W3's)
        ld a,(gb_pf) : cp XF : jr nc,6F : ld (pl_pf),a
        ld a,(gb_pt) : ld (pl_pt),a : xor a : ld (pl_md),a : ld a,#FF : ld (pp_pm),a
        ld hl,(pp_p0) : ld a,(mp_s) : ld e,a : ld d,0 : add hl,de : ld (pp_p0),hl   ; (shifted as the ZX one: DSP)
        call pp_put : jp gb_unm
6       ld a,(ix+7) : ld bc,#B046 : cp high G_BULL : jr z,63F   ; BULL (the shot's / grenade's picture): yellow
        ld bc,#B847 : cp #F3 : jr c,63F                         ; (xHERO, xDIE: white) xBOOM, xBUM (bank 4): by
        cp #FA : jr c,61F : ld bc,#B046 : jr nz,63F             ; their time - white, yellow, red, dark red; xBULL
        bit 7,(ix+6) : jr nz,63F                                ; (#FA80..): yellow
61      sub #F3 : cp 3 : jr c,62F : sub 3
62      add a,a : add a,low mp_ct : ld l,a : ld a,high mp_ct : adc a,0 : ld h,a : ld c,(hl) : inc hl : ld b,(hl)
63      ld (mp_xl),bc : call mp_put : ld hl,#B847 : ld (mp_xl),hl : jr gb_unm
; ---- PBU (after ob_pbu): his place back (the one GBU kept: the same field address)
pb_put  ld a,(gb_v) : or a : ret z
        call ob_h4 : ld de,(gb_ad) : or a : sbc hl,de : ret nz
pb_rs   xor a : ld (gb_v),a
        ld hl,gb_rk : ld de,ob4 : ld bc,4 : ldir
        call op_chk
        ld hl,(gb_y) : ld (sv_y),hl : ld a,(gb_x) : ld (sv_x),a
        ld a,3 : ld (sv_w),a : ld a,24 : ld (sv_l),a : ld a,1 : ld (sv_md),a : ld (sv_d),a
        call gb_map : call sv_go
gb_unm  ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        ld b,H_W3 : ld a,(gb_w3) : ld (W3V),a : out (c),a : ret
gb_map  ld a,(W3V) : ld (gb_w3),a
        ld bc,P_W3 : ld a,#7F-PLB : ld (W3V),a : out (c),a
        ld b,H_W2 : ld a,#7F-PLA : out (c),a : ret
; a place (sv_x.. sv_w bytes, sv_y.. sv_l lines; the plane's, signed) kept (sv_d 0) / back (1): sv_md 0 - in the
; parts' tails (#1F40 + line * sv_w + byte), 1 - gb_buf (4 bytes each)
sv_go   ld c,0 : ld hl,0 : ld (sv_i),hl
1       ld hl,(sv_y) : ld a,c : add a,l : ld l,a : ld a,h : adc a,0 : ld h,a
        or a : jr nz,5F : ld a,l : cp 200 : jr nc,5F
        push bc
        ld e,l : ld d,0 : ld h,d : add hl,hl : add hl,hl : add hl,de : add hl,hl : add hl,hl : add hl,hl : set 7,h
        ld a,(sv_w) : ld b,a : ld a,(sv_x)
2       push af : push bc : push hl
        cp 40 : jr nc,3F
        add a,l : ld l,a : jr nc,21F : inc h
21      call sv_4
3       pop hl : pop bc : pop af
        push hl : ld hl,(sv_i) : inc hl : ld (sv_i),hl : pop hl
        inc a : djnz 2B
        pop bc : jr 6F
5       ld hl,(sv_i) : ld a,(sv_w) : ld e,a : ld d,0 : add hl,de : ld (sv_i),hl   ; (a line off the plane: skipped)
6       inc c : ld a,(sv_l) : cp c : jr nz,1B
        ret
sv_4    ld de,(sv_i) : ld a,(sv_md) : or a : jr nz,5F
        ld a,e : add a,#40 : ld e,a : ld d,#9F                  ; the tails: parts 0, 2, 1, 3 at #9F, #BF, #DF, #FF
        ld a,(sv_d) : or a : jr z,1F : ex de,hl
1       ld a,(hl) : ld (de),a : set 5,h : set 5,d
        ld a,(hl) : ld (de),a : set 6,h : set 6,d
        ld a,(hl) : ld (de),a : res 5,h : res 5,d
        ld a,(hl) : ld (de),a : ret
5       ex de,hl : add hl,hl : add hl,hl : ld bc,gb_buf : add hl,bc : ex de,hl
        ld a,(sv_d) : or a : jr nz,6F
        ld a,(hl) : ld (de),a : inc de : set 5,h : ld a,(hl) : ld (de),a : inc de : set 6,h
        ld a,(hl) : ld (de),a : inc de : res 5,h : ld a,(hl) : ld (de),a : ret
6       ld a,(de) : ld (hl),a : inc de : set 5,h : ld a,(de) : ld (hl),a : inc de : set 6,h
        ld a,(de) : ld (hl),a : inc de : res 5,h : ld a,(de) : ld (hl),a : ret
; a moving thing's place (ob4: bytes, rows) touched now: the skipped draws under it drawn first (they were before
; it); noted in hb_c
op_chk  call as_brk : call fb_ob4                      ; (as_*: a whole redraw's list drawn first; its cells)
        ld hl,ob4 : call ob_f4                                 ; (its rows' groups converted again: its frame's
        ld a,(iv_c) : ld hl,sq_iv : cp (hl) : call nz,sq_end   ; (an interval's first)
        ld a,(sq_m) : or a : jr z,5F
        ld a,(sq_i) : or a : jr z,5F : ld b,a
        ld hl,SQ_B
1       push bc : push hl : call rk_get : ld de,ob4 : call bx_hit : pop hl : pop bc : jr c,2F
        ld de,SQE : add hl,de : djnz 1B : jr 5F
2       ld a,(sq_i) : ld b,a : call sq_rp : xor a : ld (sq_m),a
5       ld hl,ob4 : ld de,hb_c
; DE = a place, HL = another: DE both (bytes c0, c1, rows r0, r1)
bx_add  ld b,2
1       ld a,(de) : cp (hl) : jr c,2F : ld a,(hl) : ld (de),a
2       inc hl : inc de
        ld a,(de) : cp (hl) : jr nc,3F : ld a,(hl) : ld (de),a
3       inc hl : inc de : djnz 1B : ret
; HL = a draw's words (pl_do's: md, x, y (2), columns, lines, ...) -> rk: its field bytes, rows
rk_get  inc hl : ld a,(hl) : inc hl : add a,2 : ld (rk),a : ld (rk+1),a
        ld e,(hl) : inc hl : ld d,(hl) : inc hl
        ld a,(hl) : inc hl : cp 3 : jr nz,1F : ld a,(rk) : inc a : ld (rk+1),a
1       ld b,(hl)
        ex de,hl : ld de,32 : add hl,de
        push hl : call rk_8 : ld (rk+2),a : pop hl
        ld a,b : or a : jr z,3F : dec a
3       ld e,a : ld d,0 : add hl,de : call rk_8 : ld (rk+3),a : ret
; HL = a field line (signed) -> A = its row (0..255)
rk_8    bit 7,h : jr z,1F : xor a : ret
1       srl h : rr l : srl h : rr l : srl h : rr l : ld a,h : or a : ld a,l : ret z : ld a,#FF : ret
; DE = a place: CY if rk's meets it
bx_hit  ex de,hl
        ld a,(rk+1) : cp (hl) : jr c,0F
        inc hl : ld a,(rk) : ld b,a : ld a,(hl) : cp b : jr c,0F
        inc hl : ld a,(rk+3) : cp (hl) : jr c,0F
        inc hl : ld a,(rk+2) : ld b,a : ld a,(hl) : cp b : jr c,0F
        scf : ret
0       or a : ret
; (pl_sq: a draw as the last time's) HL = its words: CY if a moving thing touched its place since
hb_key  call rk_get
        ld de,hb_p : call bx_hit : ret c
        ld de,hb_c : jr bx_hit
; (sq_end) an interval ended: its places the last one's
hb_roll ld hl,hb_c : ld de,hb_p : ld bc,4 : ldir
        ld hl,hb_c : jr 1F
; (sq_inv: a scroll, a fight's start) none; the places kept none too
hb_clr  xor a : ld (gb_v),a : ld (cs_v),a
        ld hl,hb_p : call 1F : ld hl,hb_c
1       ld (hl),#FF : inc hl : ld (hl),0 : inc hl : ld (hl),#FF : inc hl : ld (hl),0 : ret
; ---- a whole redraw (ALLSPF: obj.asm ob_post - its start, its end; W1 = TLPG, W3 = MPG). The game draws all of its
; field again, mostly the same tiles at the same places in the same order as the last time (a turn: the fighter's
; place changed). Its draws are not drawn as they come: kept in a list (page ASPG, W2 a moment), each compared with
; the last whole redraw's (the old list: one taken, or one a few on - those skipped not there now); one not there
; then (or one of the old not there now) makes its cells (a byte x 8 lines) dirty, as do the cells anything else drew
; into since (fb_*: FB_C). At the end the new list's draws are drawn into the dirty cells only (clipped to them, in
; their order): the other cells have that picture already - the same draws over a picture they made give it again.
; Something else drawing meanwhile (a moving one, the 3D cursor, the colours of the one in focus: as_brk), too many
; differences: all of the list drawn at once, the rest of the redraw as it comes (as_on 2: the list still made). The
; field moved, another floor (ob_fk), no old list: the same from the start.
        ASSERT FB_C+1000 <= #FCA0
as_w2   ld bc,P_W2 : ld a,#7F-ASPG : out (c),a : ret
as_w2x  ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a : ret
; ALLSPF's start: the skipped repeats drawn first (pl_sq: nothing repeats past it), the list from now on
as_beg  ld a,(pl_use) : or a : ret z
        ld a,(sq_m) : or a : jr z,1F
        ld a,(sq_i) : or a : jr z,1F : ld b,a : call sq_rp
1       xor a : ld (sq_m),a : ld (sq_pn),a : dec a : ld (sq_i),a
        ld hl,AS_L : ld (as_np),hl : ld hl,0 : ld (as_mm),hl : ld (as_rs),hl
        ld a,(as_ok) : or a : jr z,3F
        ld hl,ob_fk : ld de,as_k : ld b,4
2       ld a,(de) : cp (hl) : jr nz,3F : inc hl : inc de : djnz 2B
        ld a,1 : ld (as_on),a : ret
3       ld hl,#C000 : ld (as_ob),hl                     ; (the old one not there / no good: all drawn, the list made)
        call as_fb0
        ld a,1 : ld (as_rp),a : inc a : ld (as_on),a : ret
as_fb0  ld hl,FB_C : ld de,FB_C+1 : ld bc,999 : ld (hl),0 : ldir : ret
; (as_on 2) the draw into the list, drawn now (NZ); no room: no list
as_rec  ld bc,P_W2 : ld a,#7F-ASPG : out (c),a                   ; (as_w2)
        ld hl,(as_np) : ld a,h : cp high (#C000-AS_E) : jr nc,1F
        ld hl,2 : add hl,sp : ld de,(as_np)
        DUP AS_E
        ldi
        EDUP
        ld (as_np),de
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a : or 1 : ret      ; (as_w2x)
1       call as_w2x : xor a : ld (as_on),a : ld (as_ok),a : ld (as_rp),a : or 1 : ret
; (as_on 1 -> 2) the list so far drawn whole, the old one dropped, from now on drawn as they come
as_sw   call as_w2 : call as_fl : call as_w2x : call as_dra
        ld hl,#C000 : ld (as_ob),hl
        call as_db0 : call as_fb0
        ld a,1 : ld (as_rp),a : inc a : ld (as_on),a : ret
; (pl_sq, jumped to: the draw's words past our return) into the list; Z: not drawn now
as_add  ld a,(as_on) : cp 2 : jr z,as_rec
as_a1   ld hl,(as_ob) : ld a,h : cp high #C000 : jr nc,0F
        call as_w2                                      ; the old one's next the same (mostly): taken
        ld hl,2 : add hl,sp : ex de,hl : ld hl,(as_ob)  ; (DE: the stack's - no low byte's wrap there)
        DUP AS_E-1
        ld a,(de) : cp (hl) : jr nz,0F : inc e : inc hl
        EDUP
        ld a,(de) : cp (hl) : jr nz,0F : inc hl
        ld (as_ob),hl : ld a,(as_rs+1) : or a : jr nz,01F       ; (taken: into the new one later - as_fl)
        ld bc,-AS_E : add hl,bc : ld (as_rs),hl
01      call as_w2x : xor a : ret                       ; (the gap between the lists as it was)
0       ld hl,2 : add hl,sp : ld de,as_e : ld bc,AS_E : ldir
        call as_w2 : call as_fl
        ld hl,(as_ob) : ld b,AS_W
2       ld a,h : cp high #C000 : jr nc,.ins             ; (the old list's end)
        push bc : push hl : call as_eq : pop hl : pop bc : jr z,.fnd
        ld de,AS_E : add hl,de : djnz 2B
.ins    ld hl,as_e : call as_dm : call as_mi : jr .put   ; (new here: its cells dirty)
.fnd    ld (as_t),hl
3       ld hl,(as_ob) : ld de,(as_t) : or a : sbc hl,de : jr z,4F
        ld hl,(as_ob) : call as_dm : call as_mi         ; (the old ones before it: gone - their cells dirty)
        ld hl,(as_ob) : ld de,AS_E : add hl,de : ld (as_ob),hl : jr 3B
4       ld hl,(as_t) : ld de,AS_E : add hl,de : ld (as_ob),hl
.put    ld hl,(as_mm) : ld de,-AS_MX : add hl,de : jr nc,.put2
        call as_w2x : call as_sw : jp as_rec            ; (too many differences: all drawn)
.put2   ld hl,(as_np) : ld de,AS_E : add hl,de : ex de,hl : ld hl,(as_ob) : or a : sbc hl,de : jr nc,5F
        call as_orm                                     ; (no room: the old one's rest gone)
        ld hl,(as_np) : ld de,AS_E+1 : add hl,de : ld a,h : cp high #C000 : jr c,5F
        call as_w2x : call as_bk : or 1 : ret           ; (too many: drawn as they come - this one too)
5       ld de,(as_np) : ld hl,as_e : ld bc,AS_E : ldir : ld (as_np),de
        call as_w2x : xor a : ret
as_mi   ld hl,(as_mm) : inc hl : ld (as_mm),hl : ret
; HL = an entry: Z - as as_e
as_eq   ld de,as_e : ld b,AS_E
1       ld a,(de) : cp (hl) : ret nz : inc hl : inc de : djnz 1B : ret
; the old list's rest: gone (W2 = ASPG)
as_orm  ld hl,(as_ob) : ld a,h : cp high #C000 : ret nc
        call as_dm : ld hl,(as_ob) : ld de,AS_E : add hl,de : ld (as_ob),hl : jr as_orm
; HL = an entry -> its lines on the plane as_y0.. as_y1 - 1, as_r0 the first's row; Z: none (as pl_do: l0 < 32,
; lines within the tile's 32)
as_yr   inc hl : inc hl : ld e,(hl) : inc hl : ld d,(hl) : inc hl : inc hl : ld b,(hl) : inc hl : ld c,(hl)
        ld a,32 : sub c : jr c,9F : jr z,9F : cp b : jr nc,1F : ld b,a
1       ld a,b : or a : jr z,9F
        bit 7,d : jr z,2F
        ld a,d : inc a : jr nz,9F : ld a,e : add a,b : jr nc,9F : jr z,9F : ld d,a : ld e,0 : jr 3F
2       ld a,d : or a : jr nz,9F : ld a,e : cp 200 : jr nc,9F
        add a,b : jr c,21F : cp 200 : jr c,22F
21      ld a,200
22      ld d,a
3       ld a,e : ld (as_y0),a : rrca : rrca : rrca : and #1F : ld (as_r0),a : ld a,d : ld (as_y1),a : or 1 : ret
9       xor a : ret
; HL = an entry: its cells dirty
as_dm   push hl : call as_yr : pop hl : ret z
        inc hl : ld b,(hl) : inc hl : inc hl : inc hl : ld c,(hl)               ; B = x, C = columns
        ld a,c : rrca : jr nc,1F : ld a,b : push bc : call as_mk : pop bc
1       ld a,c : and 2 : ret z : ld a,c : cp 3 : ld a,b : jr nz,as_mk : inc a
; A = a column: its cells as_r0.. dirty
as_mk   call as_cl : ret nc
1       ld (hl),1 : add hl,de : djnz 1B : ret
; A = a column -> HL = its cell in row as_r0 (DB_C), DE = 40, B = the rows to as_y1; NC: off the plane
as_cl   cp 40 : ret nc
        ld e,a : ld a,(as_y0) : and #F8 : ld l,a : ld h,0 : ld c,l : ld b,h : add hl,hl : add hl,hl : add hl,bc
        ld d,0 : add hl,de : ld de,DB_C : add hl,de
        ld a,(as_y1) : dec a : rrca : rrca : rrca : and #1F : ld b,a : ld a,(as_r0) : neg : add a,b : inc a : ld b,a
        ld de,40 : scf : ret
; A = a column -> A = its dirty rows' bits (bit k: row as_r0 + k)
as_cm   call as_cl : ld a,0 : ret nc
        ld c,1
1       ld a,(hl) : or a : jr z,2F : ld a,(as_m) : or c : ld (as_m),a
2       sla c : add hl,de : djnz 1B
        ld a,(as_m) : ret
; ALLSPF's end: the old list's rest gone, the other draws' cells dirty, the new list drawn into the dirty cells,
; it is the old one now
as_end  ld a,(as_on) : or a : ret z
        ld b,a : xor a : ld (as_on),a : ld (as_kp),a : ld a,b : cp 2 : ld (as_ck),a : jp z,3F  ; (drawn as it came: the list kept)
        call as_w2
        ld hl,(as_rs) : ld de,(as_os) : or a : sbc hl,de : jr nz,05F         ; all of the old one taken, nothing else:
        ld a,(as_ob+1) : cp high #C000 : jr c,05F                           ; it stays where it is (the new one)
        ld hl,(as_np) : ld de,AS_L : or a : sbc hl,de : jr nz,05F
        ld hl,(as_os) : ld (as_ls),hl : ld hl,#C000 : ld (as_le),hl : ld a,1 : ld (as_kp),a : jr 06F
05      call as_fl : call as_orm
        ld hl,AS_L : ld (as_ls),hl : ld hl,(as_np) : ld (as_le),hl
06
        ld hl,#00FF : ld (as_bc),hl : ld (as_br),hl     ; (the dirty cells' box: none)
        ld hl,FB_C : ld de,DB_C : ld c,0
11      ld b,0
1       ld a,(de) : or (hl) : ld (de),a : ld (hl),0 : call nz,as_bx : inc hl : inc de
        inc b : ld a,b : cp 40 : jr c,1B
        inc c : ld a,c : cp 25 : jr c,11B
        ld a,(as_br) : inc a : jp z,3F                ; (none dirty: nothing to draw)
        ld a,1 : ld (as_rp),a
        ld hl,(as_ls)
        ld a,(as_br) : add a,a : add a,a : add a,a : ld (as_yl),a           ; (the box's lines: as_yl.. as_yh - 1)
        ld a,(as_br+1) : inc a : add a,a : add a,a : add a,a : ld (as_yh),a
        call as_w2
2       ld de,(as_le) : or a : sbc hl,de : add hl,de : jr nc,3F
        ; past the box (its columns, lines - the tile's own clipping not yet): not drawn
        push hl : inc hl : ld a,(hl) : inc a : jp m,21F : ld de,as_bc : ex de,hl : cp (hl) : ex de,hl : jr c,29F
21      dec a : jp m,22F : ld de,as_bc+1 : ex de,hl : cp (hl) : ex de,hl : jr z,22F : jr nc,29F
22      inc hl : ld e,(hl) : inc hl : ld d,(hl) : inc hl : inc hl : ld c,(hl)            ; DE = y, C = lines
        bit 7,d : jr nz,23F : ld a,d : or a : jr nz,29F : ld a,(as_yh) : dec a : cp e : jr c,29F
23      ld a,(as_yl) : ld l,a : ld h,0 : ex de,hl : ld b,0 : add hl,bc : or a : sbc hl,de : jr z,29F : jp m,29F
        pop hl : push hl : ld de,as_e : ld bc,AS_E : ldir : call as_rpe : call as_w2
29      pop hl : ld de,AS_E : add hl,de : jr 2B
3
        IF ASCHK                                        ; (a test: the whole list drawn again changes nothing)
        ld a,(as_ck) : cp 2 : jr z,39F
chk_a   nop
        call as_dra
chk_b   nop
39
        ENDIF
        xor a : ld (as_rp),a
        ld hl,ob_fk : ld de,as_k : ld bc,4 : ldir
        call as_w2
        ld a,(as_kp) : or a : ld hl,(as_os) : jr nz,4F                     ; (kept where it was)
        ld hl,(as_np) : ld de,AS_L : or a : sbc hl,de : ld b,h : ld c,l : ld hl,#C000 : jr z,4F
        ld hl,(as_np) : dec hl : ld de,#BFFF : lddr : ex de,hl : inc hl
4       ld (as_ob),hl : ld (as_os),hl : ld a,1 : ld (as_ok),a : call rp_sd           ; (its figures: xrep.asm)
        call as_w2x
as_db0  ld hl,DB_C : ld de,DB_C+1 : ld bc,999 : ld (hl),0 : ldir : ret
; (the merge) B = a column, C = a row dirty: the box
as_bx   push hl : ld hl,as_bc : ld a,b : cp (hl) : jr nc,1F : ld (hl),a
1       inc hl : cp (hl) : jr c,2F : ld (hl),a
2       inc hl : ld a,c : cp (hl) : jr nc,3F : ld (hl),a
3       inc hl : cp (hl) : jr c,4F : ld (hl),a
4       pop hl : ret
; as_e drawn into its dirty cells (clipped to their runs; both columns the same: as one)
as_rpe  ld hl,as_e : call as_yr : ret z
        ld a,(as_y1) : dec a : rrca : rrca : rrca : and #1F : ld hl,as_br : cp (hl) : ret c        ; (its rows, columns
        inc hl : ld a,(as_r0) : cp (hl) : jr z,0F : ret nc                                        ; past the box: none)
0       ld a,(as_e+1) : inc a : bit 7,a : jr nz,01F : ld hl,as_bc : cp (hl) : ret c                ; (x + 1 < c0)
01      dec a : bit 7,a : jr nz,02F : inc hl : cp (hl) : jr z,02F : ret nc                          ; (x > c1)
02
        ld a,(as_e+4) : cp 3 : jr nz,1F
        ld a,(as_e+1) : xor a : ld (as_m),a : ld a,(as_e+1) : call as_cm : push af
        xor a : ld (as_m),a : ld a,(as_e+1) : inc a : call as_cm : ld c,a : pop af
        cp c : jr nz,2F
        ld b,a : ld a,(as_e+1) : ld c,3 : jr as_em      ; (the same rows: both at once)
2       push bc : ld b,a : ld a,(as_e+1) : ld c,1 : call as_em
        pop bc : ld b,c : ld a,(as_e+1) : inc a : ld c,2 : jr as_em
1       xor a : ld (as_m),a : ld a,(as_e+1) : call as_cm : ld b,a : ld a,(as_e+4) : ld c,a : ld a,(as_e+1)
; A = x, C = columns, B = the rows' bits: each run drawn
as_em   ld (em_x),a : ld a,c : ld (em_c),a : ld c,0
1       ld a,b : or a : ret z
        srl b : jr c,2F : inc c : jr 1B
2       ld a,c : ld (em_s),a : inc c
3       srl b : jr nc,4F : inc c : jr 3B
4       push bc : call as_run : pop bc : inc c : jr 1B
; rows as_r0 + em_s .. as_r0 + C - 1 of as_e drawn (its lines there)
as_run  ld a,(as_r0) : add a,c : add a,a : add a,a : add a,a : ld b,a
        ld a,(as_y1) : cp b : jr c,1F : ld a,b
1       ld (em_e),a
        ld a,(em_s) : ld b,a : ld a,(as_r0) : add a,b : add a,a : add a,a : add a,a : ld b,a
        ld a,(as_y0) : cp b : jr nc,2F : ld a,b
2       ld e,a : ld (as_w+2),a : xor a : ld (as_w+3),a
        ld a,(em_e) : sub e : ret z : ret c : ld (as_w+5),a
        ld a,(as_e+2) : ld b,a : ld a,e : sub b : ld b,a : ld a,(as_e+6) : add a,b : ld (as_w+6),a
        ld a,(as_e) : ld (as_w),a : ld a,(em_x) : ld (as_w+1),a : ld a,(em_c) : ld (as_w+4),a
        ld a,(as_e+7) : ld (as_w+7),a : ld hl,(as_e+8) : ld (as_w+8),hl
        ld hl,as_w : jp as_dr
; something else draws into the plane (op_chk, fc_chk): a redraw going on - its list drawn now (all of it), the rest
; as it comes; the next one draws all
as_brk  ld a,(as_on) : dec a : ret nz : jp as_sw
; (too many draws) the list drawn whole, none kept
as_bk   xor a : ld (as_on),a : ld (as_ok),a
        call as_dra : xor a : ld (as_rp),a : jp as_db0
; the list so far drawn whole (as_rp 1 after)
as_dra  ld a,1 : ld (as_rp),a
        ld hl,AS_L
1       ld de,(as_np) : or a : sbc hl,de : add hl,de : jr nc,2F
        push hl : call as_w2 : ld de,as_w : ld bc,AS_E : ldir : ld hl,as_w : call as_dr : pop hl
        ld de,AS_E : add hl,de : jr 1B
2       jp as_w2x
; (pl_mk) a draw done otherwise: E its first line, D the end, mk_x its byte - its cells (and the next byte's) in FB_C
fb_mk   push de : push hl
        ld a,e : ld (as_y0),a : rrca : rrca : rrca : and #1F : ld (as_r0),a : ld a,d : ld (as_y1),a
        ld a,(mk_x) : push af : call as_mk2 : pop af : inc a : call as_mk2
        pop hl : pop de : ret
as_mk2  call as_cl : ret nc : push de : ld de,FB_C-DB_C : add hl,de : pop de
1       ld (hl),1 : add hl,de : djnz 1B : ret
; (op_chk, fc_chk) ob4: bytes c0, c1 (the field's), rows r0, r1 (lines + 32) - its cells in FB_C
fb_ob4  ld a,(ob4+3) : sub 4 : ret c : cp 25 : jr c,1F : ld a,24
1       ld (as_m),a : inc a : add a,a : add a,a : add a,a : ld (as_y1),a
        ld a,(ob4+2) : sub 4 : jr nc,2F : xor a
2       ld hl,as_m : cp (hl) : jr z,21F : ret nc
21      ld (as_r0),a : add a,a : add a,a : add a,a : ld (as_y0),a
        ld a,(ob4) : sub 2 : jr nc,3F : xor a
3       ld c,a
4       ld a,(ob4+1) : sub 2 : ret c : cp c : ret c
        ld a,c : push bc : call as_mk2 : pop bc : inc c : ld a,c : cp 40 : jr c,4B : ret
as_on   db 0                                    ; 1: the draws into the list (a whole redraw), 2: drawn too
as_rp   db 0                                    ; 1: the list drawn (not marked in FB_C)
as_ok   db 0                                    ; the old list valid
as_ob   dw #C000                                ; the old list's first entry left
as_np   dw AS_L                                 ; the new list's next
as_rs   dw 0                                    ; the old one's entries taken from here (to as_ob; 0: none) - as_fl
as_os   dw #C000                                ; the old one's start
as_ls   dw AS_L                                 ; (as_end) the new one: as_ls .. as_le
as_le   dw AS_L
as_kp   db 0                                    ; (as_end) 1: the old one taken whole - kept in place
as_t    dw 0
as_ck   db 0
as_mm   dw 0                                    ; (as_on 1) the differences so far
as_k    ds 4                                    ; ob_fk at the last whole redraw's end
as_yl   db 0
as_yh   db 0
as_bc   db #FF, 0                               ; the dirty cells' box: columns c0, c1, rows r0, r1 (c0 #FF: none)
as_br   db #FF, 0
as_y0   db 0
as_y1   db 0
as_r0   db 0
as_m    db 0
em_x    db 0
em_c    db 0
em_s    db 0
em_e    db 0
as_e    ds AS_E
as_w    ds AS_E
mp_src  dw 0
mp_pg   db 0
mp_s    db 0
mp_cm   db 0
mp_m    ds 6
sv_x    db 0
sv_y    dw 0
sv_w    db 0
sv_l    db 0
sv_d    db 0
sv_md   db 0
sv_i    dw 0
cu_x    db 0
cu_y    dw 0
cs_v    db 0                                    ; the 3D cursor's place kept (POFF: back)
gb_v    db 0                                    ; GBU's place kept (PBU: back)
gb_ad   dw 0                                    ; its field address
gb_x    db 0                                    ; its first byte (the plane's, signed)
gb_y    dw 0                                    ; its first line (the plane's, signed)
gb_pf   db 0                                    ; his frame (#FF: none), table
; (0.66.9; xtil_i.asm pl_sqd: the draw's words past our return) a ship's tile (XM0's 3..15: in its cell instead of the
; floor) on the 1st floor (the game's FLR: obj.asm pf_fl) - the location's floor (enl.asm te_flr: pf_flo) drawn under it
; first: its lines 16..31 there, as a draw of its own (pl_sq, pl_do - the repeats, the lists have it too). On the 2nd
; floor nothing under it (the 1st's seen through - the wings in the air). Before: the floor in its EGA tile itself
pl_fl   ld a,(pf_fl) : dec a : ret nz
        ld a,(pf_flo) : cp 96 : ret nc
        ld hl,9 : add hl,sp : ld a,(hl) : cp 3 : ret c : cp 16 : ret nc
        ld hl,pl_w1t : push hl                                  ; (pl_do's end there: W1 = TLPG again)
        ld hl,-SQE : add hl,sp : ld sp,hl : ex de,hl
        ld hl,SQE+4 : add hl,sp : ld bc,SQE : ldir              ; its words copied
        ld hl,7 : add hl,sp : ld a,(pf_flo) : ld (hl),a         ; the floor's code
        dec hl : ld a,(hl) : cp 16 : jr nc,1F                   ; from line 16
        ld c,a : ld a,16 : sub c : ld c,a : ld (hl),16
        dec hl : ld a,(hl) : sub c : jr c,9F : jr z,9F : ld (hl),a
        ld hl,2 : add hl,sp : ld a,(hl) : add a,c : ld (hl),a : inc hl : ld a,(hl) : adc a,0 : ld (hl),a
1       ld hl,8 : add hl,sp : ld (hl),#FF : inc hl : ld (hl),#FF        ; (no figure)
        call pl_sq : jp nz,pl_do
9       ld hl,SQE : add hl,sp : ld sp,hl : ret
gb_pt   db 0
gb_w3   db 0
gb_rk   ds 4                                    ; its place (bytes, rows)
ob4     ds 4
rk      ds 4
hb_p    db #FF, 0, #FF, 0
hb_c    db #FF, 0, #FF, 0
sq_lst  ds SQN*SQE                               ; (the draws' list: pl_sq)
xpnt_end
gb_buf  equ xpnt_end                            ; (TLPG's only: 3 x 24 x 4)
        ENT
xpnt_img_end
; ---- the hooks' second part: TLPG's #4700 (tl_nm's second half - not used), with the first (mx_load: xp_load)
xpn2_img
        DISP tl_nm+256
; ---- (pl_do, W1 = TLPG; its words on the stack past our return) the draw's place marked for the output (field.asm
; fdrow, fdlin: the plane's rows' groups - its columns and one each side, for the frame - and lines; the plane is all
; of the field's picture: the game's own marks are not needed - obj.asm m_fmw)
pl_mk   ld hl,3 : add hl,sp : ld a,(hl) : ld (mk_x),a          ; the plane byte (signed)
        inc hl : ld e,(hl) : inc hl : ld d,(hl) : inc hl : inc hl : ld b,(hl)   ; DE = the first line (signed), B = lines
        bit 7,d : jr z,1F
        ld a,d : inc a : ret nz : ld a,e : add a,b : ret nc : ret z : ld b,a : ld e,0 : jr 2F    ; (above: its rest)
1       ld a,d : or a : ret nz : ld a,e : cp 200 : ret nc
2       ld a,e : add a,b : jr c,3F : cp 200 : jr c,4F
3       ld a,200
4       ld d,a                                                  ; E = the first line, D = the end
        ld a,(as_rp) : or a : call z,fb_mk                      ; (not the list's: its cells in FB_C)
        ld a,(mk_x) : inc a : cp 42 : ret nc                    ; (x - 1 .. x + 1 within 0..39)
        add a,low t_gm : ld l,a : ld h,high t_gm : ld c,(hl)    ; C = the groups
        ; rows E / 8 .. (D - 1) / 8: their groups C, lines (the first's from E on, the last's to D, all between)
        ld a,e : cp d : ret nc
        ld a,d : dec a : ld b,a : and 7 : add a,low mk_hi : ld l,a : ld h,high mk_hi : ld a,(hl) : ld (mk_e),a
        ld a,e : and 7 : add a,low mk_lo : ld l,a : ld a,(hl) : ld (mk_f),a
        ld a,b : rrca : rrca : rrca : and #1F : ld b,a                          ; B = the last row
        ld a,e : rrca : rrca : rrca : and #1F : ld e,a : ld a,b : sub e : ld b,a        ; B = rows - 1
        ld a,e : add a,low fdrow : ld l,a : ld h,high fdrow                     ; (fdrow, fdlin: one 256)
        ld a,c : or (hl) : ld (hl),a
        ld a,b : or a : ld a,(mk_e) : jr nz,8F
        ld e,a : ld a,(mk_f) : and e : jr 9F                                    ; (one row)
8       ld a,l : add a,FDN : ld l,a : ld a,(mk_f) : or (hl) : ld (hl),a : ld a,l : sub FDN-1 : ld l,a
        dec b : jr z,82F
81      ld a,c : or (hl) : ld (hl),a : ld a,l : add a,FDN : ld l,a : ld (hl),#FF : sub FDN-1 : ld l,a : djnz 81B
82      ld a,c : or (hl) : ld (hl),a : ld a,(mk_e)
9       ld e,a : ld a,l : add a,FDN : ld l,a : ld a,e : or (hl) : ld (hl),a : ret
        ASSERT high fdrow == high (fdlin+FDN-1) && fdlin == fdrow+FDN
        ALIGN 32
mk_lo   db #FF, #FE, #FC, #F8, #F0, #E0, #C0, #80
mk_hi   db #01, #03, #07, #0F, #1F, #3F, #7F, #FF
mk_x    db 0
mk_e    db 0
mk_f    db 0
xpn2_end
        ENT
xpn2_img_end
        ASSERT xpn2_end <= TLR
        display "xpn2 end ",xpn2_end
