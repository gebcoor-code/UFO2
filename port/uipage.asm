; the panel's code: page UPG at #C000 (W3), called through far_ui (W1, W2 = a screen buffer; W0 = the layer)
ui_img
        DISP #C000
; colour c -> byte with both pixels c
enc     push bc : ld b,a : and 7 : ld c,a : rlca : rlca : rlca : or c : ld c,a
        ld a,b : and 8 : jr z,1F : ld a,#C0
1       or c : pop bc : ret
; the panel's buttons and the music icon: in MPG's MX (uidraw.asm)
ui_draw0
        ld hl,ui_draw0_x : jp far_m
; DE = text (0 = none), C = box colour: the status box
; ---- the fight's RAM SAVE / LOAD bar (pg_b = 32..1, pg_v = colour): EGA lines 190..193, pairs pg_e0.. +31
pg_e0   db 12
pg_draw ld a,(pg_b) : cp 32 : jr nz,1F
        ld a,1 : call enc : ld c,a : ld a,(pg_e0) : ld e,a : ld b,32 : call pg_run        ; the frame of the bar
1       ld a,(pg_e0) : ld e,a : ld a,(pg_b) : neg : add a,32 : add a,e : ld e,a : ld a,(pg_v) : call enc : ld c,a : ld b,1
; pairs E .. E+B-1 of EGA lines pg_y.. +3 = byte C
pg_run  ld a,(pg_y) : ld d,a : add a,4 : ld (.e+1),a
1       ld a,d : call yoff
        push bc : push de
2       ld a,e : call paddr : ld (hl),c : inc e : djnz 2B
        pop de : pop bc
        inc d : ld a,d
.e      cp 194 : jr c,1B
        ret
pg_y    db 190                                  ; (not before pg_run: pg_draw falls into it)
; ---- the cursor's place and kind (cur_tgt, the game's windows): the wide fight: where the mouse is; over the field
; (state A, not on a panel) the game's 3D cursor's kind, its hot spot
cur_tgt_u
        xor a : ld (cs_mode),a
        ld a,(bwide) : or a : jr z,0F
        ld hl,(scx) : ld a,(scy) : ld c,a
        call ld_chk : nop : jr nz,8F                    ; (a location loading: none - ui6)
        ld a,(pn_ovr) : or a : jr nz,8F
        ld a,(cs_fld) : or a : jr nz,9F                ; (v58: over the field none of ours - the game's 3D cursor)
        ld a,#FF : ld (ct_y),a : ret
9       push hl : ld hl,(G_PIMG) : ld de,-G_xMARKE : add hl,de : add hl,hl : ld a,h : and 3 : ld b,a
        ld a,(G_FLR) : or a : jr nz,1F : set 2,b
1       set 3,b : ld a,b : ld (cs_mode),a
        and 3 : add a,a : ld e,a : ld d,0 : ld hl,cs_hot : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : pop hl
        ld a,d : or a : jp m,21F                ; (a negative hot spot: the shape right / below the point)
        ld a,c : sub d : jr nc,2F : xor a : jr 2F
21      ld a,c : sub d
2       ld c,a : ld a,e : rla : sbc a,a : ld d,a : jr nz,22F
        or a : sbc hl,de : jr nc,3F : ld hl,0 : jr 3F
22      or a : sbc hl,de
3       ld a,(cs_mode) : bit 2,a : jr z,8F
31      res 0,l                                 ; ("2" / the sword: at an even x, all of it in the 5 pairs)
8       ld (ct_x),hl : ld a,c : ld (ct_y),a : ret
0       ld a,(cs_hid) : or a : jr z,01F
        ld a,#FF : ld (ct_y),a : ret
01      ld a,(G_COORD+1) : add a,4 : ld (ct_y),a
        ld a,(free) : or a : jr z,1F
        ld hl,(scx) : ld a,(scy) : ld (ct_y),a : jr 2F
1       ld a,(G_COORD) : ld l,a : ld h,0
        ld a,(infight) : or a : jr z,2F         ; the fight: over its field the game shows its own cursor
        ld a,l : sub 8 : cp 224 : jr nc,2F
        ld a,(G_COORD+1) : sub 8 : cp 128 : jr nc,2F
        ld a,#FF : ld (ct_y),a                  ; (none)
2       ld (ct_x),hl : ret
; ---- the cursor (W1, W2 = a buffer): cursor.asm cs_iox (MPG's MX)
cs_iof  ld hl,cs_iox : jp far_m
cs_fld  db 0                                    ; 1: our cross / sword / lift arrows over the field again

        include "sc.asm"
; ---- MRK1's band compare (from lay_band: W1 = screen 7, own stack): B lines from HL (DSCR); first the text map of
; its rows (textr.asm bd_tx: screen 7's CM_S, TA_S from the band's pixels - what the game put into the band, e.g. a
; price, is the text layer's then; before the compare: its marks' conversion finds the map ready)
bd_cmp  push hl : push bc : ld hl,bd_tx : call far_m : WIN P_W1, 15 : pop bc : pop hl
.lp     push bc : push hl
        ld a,h : sub #50 : ld d,a : ld e,l      ; (screen 7 at W1: DSCR + #3000 - #8000)
        xor a : ld (bd_m),a : ld b,1            ; B = the group's bit
.g      ld c,0
        DUP 8
        ld a,(de) : cp (hl) : jr z,$+5 : ld a,(hl) : ld (de),a : inc c
        inc l : inc e
        EDUP
        ld a,c : or a : jr z,.ng
        ld a,(bd_m) : or b : ld (bd_m),a
.ng     sla b : bit 4,b : jr z,.g
        ld a,(bd_m) : or a : jr z,.nm
        ld c,a : ld a,(bd_y) : ld b,1 : call mk_ln
.nm     pop hl : pop bc
        call bd_next
        dec b : jp nz,.lp
        ret
; ---- the interrupt (game's windows, from ui_int): a wanted start, if the game waits in its HALT with the geoscape module present
ui_int_u
        ld hl,tw_tick : call far_m              ; (mx.asm: the console's next character)
        ld a,(pend) : or a : ret z
        ld hl,pend_t : dec (hl) : jr nz,1F
        xor a : ld (pend),a : inc a : ld (ui_red),a : ret     ; too late: forget it
1       ld hl,(i_sp) : ld e,(hl) : inc hl : ld d,(hl)          ; DE = return address
        ld hl,G_EI : ex de,hl : or a : sbc hl,de : ret c   ; return address - E_I: 0..7 = in the HALT routine
        ld a,h : or a : ret nz : ld a,l : cp 8 : ret nc
        call is_geo : ret nz
        ld a,(cs_hid) : or a : jr nz,2F         ; our cursor off first (the next HALTs' conversions: cur_tgt_u),
        inc a : ld (cs_hid),a : ld a,5 : ld (pend_w),a : ret   ; then the start (its pause without it)
2       ld a,(pend_w) : or a : jr z,4F : dec a : ld (pend_w),a : ret
4       ld a,(pend) : ld de,tr_3d : cp 1 : jr z,3F : ld de,tr_loc
3       ld hl,(i_sp) : ld (hl),e : inc hl : ld (hl),d
        xor a : ld (pend),a : inc a : ld (ui_red),a : ret
cs_hid  db 0                                    ; 1: our cursor off on the geoscape till the mouse moves
pend_w  db 0
is_geo  push hl : push de : push bc
        ld hl,xl_pat : ld de,G_GEO1 : ld b,5
1       ld a,(de) : cp (hl) : jr nz,2F
        inc hl : inc de : djnz 1B
        ld hl,xg_pat : ld de,#7580 : ld b,6     ; and the start of XLIC (a shorter module may leave #88E4 as it was)
3       ld a,(de) : cp (hl) : jr nz,2F
        inc hl : inc de : djnz 3B
2       pop bc : pop de : pop hl : ret
        include "uimouse.asm"
        include "wideu.asm"
        include "panel.asm"
        include "mku.asm"
        include "enc_u.asm"
        display "upg end ",$
        ASSERT $ <= PS_ROWS
        ENT
ui_img_end
ui2_img
        DISP #FAE0
        include "shift.asm"
        display "ui2 end ",$
        ASSERT $ <= #FFFF && $ >= #FAE0  ; (free past it)
        ENT
ui2_img_end
ui3_img
        DISP #F570
        include "shift2.asm"
        display "ui3 end ",$
        ASSERT $ <= #FAE0
        ENT
ui3_img_end
ui4_img
        DISP #EEB0
        include "keyed.asm"
        display "ui4 end ",$
        ASSERT $ <= PN_ROW
        ENT
ui4_img_end
ui5_img
        DISP pn2_s+PN2_NS                       ; (between the panel's states: ico.asm's mark hooks)
; PUTSIM / PUTSCR done (mku.asm's dispatch): the items' / signs' pictures noted (ico.asm), then marked as before
ov_sim3 push hl : ld hl,ov_sim : call far_x : pop hl : jp mk_sim
ov_psc3 push hl : ld hl,ov_psc : call far_x : pop hl : jp mk_psc
        display "ui5 end ",$
        ASSERT $ <= pn2_p
        ENT
ui5_img_end
ui6_img
        DISP #F280                              ; (UPG: PN_BLK's tail - its blocks 640 bytes at most)
; a location starts loading (bat_on, EGA): both buffers black, "Loading..." in white in the middle; LD_ON until
; outd_u's state A (ld_end): no conversion (tpg.asm bc_t), no overlays, no cursor (ld_chk)
ld_beg  ld a,i : push af : di
        ld a,1 : ld (LD_ON),a : ld hl,0 : ld (ld_t),hl
        xor a : ld (cs_on),a : ld (brec),a      ; (the cursors' records dropped: their bytes are black now)
        ld (lb_sp),sp : ld sp,#3FB0             ; (own stack - conv_all's: the game's may be in W1; DI)
        ld hl,(#3D3E) : push hl : ld hl,int_f : ld (#3D3E),hl : ei         ; (meanwhile the music: int_f - W3 only)
        ld hl,ld_pgs : ld b,4
0       push bc : ld a,(hl) : inc hl : ld c,(hl) : inc hl : push hl : call 1F : pop hl : pop bc : djnz 0B
        di : pop hl : ld (#3D3E),hl
        WIN P_W1, PG_ZX+5
        ld sp,(lb_sp)
        pop af : jp po,9F : ei
9       xor a : ld b,24 : ld c,#0F : jp mk_rows ; all of screen 7 (state B)
ld_pgs  db #7F-PS1,0, #7F-PS3,0, #7F-PS5,2, #7F-PS7,2   ; (the buffers' pages: pairs 4c, 4c + 2 / 4c + 1, 4c + 3)
; A = W1's port value, C = the glyphs' shift: the page black, the text on it (enc_u.asm lt_load)
1       push bc : ld bc,P_W1 : out (c),a
        ld hl,#4000 : ld de,#4001 : ld bc,#3FFF : ld (hl),0 : ldir
        pop bc : ld de,#4000 + 96 * 40 + 15 : jp lt_load
lb_sp   dw 0
; cur_tgt_u: A = bst, NZ: state B; a location loading: no cursor at all (the caller's ret skipped)
ld_chk  ld a,(LD_ON) : or a : jr z,1F
        call ld_tmo : jr z,1F                           ; (too long: the game's screen shown - wideu.asm)
        pop af : ld a,#FF : ld (ct_y),a : ret
1       ld a,(bst) : or a : ret
; outd_u: FW_C = the game's COLOR; BC_CMP too, unless the fighter's screen set it to #FF (till state A: ld_end)
fw_set  ld a,(BC_CMP) : inc a : ld a,(G_COLOR) : ld (FW_C),a : ret z : ld (BC_CMP),a : ret
;
; pn_fl: the front's cursor on (cur_show's work, W3 kept) before the overlays' work - the world map's lines can take
; frames (the step began with it off when the mouse moved: cur_move)
ov_fl6  ld a,(cs_on) : or a : jr nz,2F
        ld a,(ct_y) : inc a : jr z,2F
        ld a,(bf) : or a : ld a,#7F-PS1 : ld e,#7F-PS5 : jr z,1F : ld a,#7F-PS3 : ld e,#7F-PS7
1       ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a
        ld hl,(ct_x) : ld (cs_x),hl : ld a,(ct_y) : ld (cs_y),a
        ld a,1 : ld (cs_md),a : ld a,(cs_mode) : inc a : ld (cs_on),a
        call cs_iof
2       jp hk_lat
;
; conv_all's end (zxl.asm): the overlays, the text (the Y/N questions' windows - the wide fight's, the geoscape's: the
; game waits in YES_NO, ui.asm yn_w); not the 3D view's (the geoscape's overlays would come over it)
ov_fl3w ld hl,#7FFF : ld (bmax),hl                ; (ico.asm ov_fl: as conv_all's end - all rows done)
        ld a,(bwide) : or a : jp nz,ov_fl3
        ld a,(MUS_TRK) : cp 3 : ret z : jp ov_fl3
;
; SCOORD's vector (#0128; D, E = row, column; HL = the cell; BC kept): screen 7 - its marks; screen 7 and the
; DSCR: the text map (text.asm tx_rec). DE = #9000: the game's BACK (HL = SCR, BC = 6912: the LDIR is ours - screen 7
; is W3's page (cur) - then the text map screen 7 -> DSCR)
mk_sc   push af
        ld a,d : cp #90 : jr nz,1F : ld a,e : or l : jr z,3F         ; (BACK: DE = #9000, HL = #C000)
1       ld a,h : cp #C0 : jr c,2F : cp #D8 : jr nc,2F
        push bc
        ld a,l : and #18 : rrca : rrca : rrca : call gbit : ld c,a
        ld a,l : rlca : rlca : rlca : and 7 : ld b,a : ld a,h : and #18 : or b
        ld b,1 : call mk_rows
        pop bc
2       push hl : ld hl,tx_rec : call far_t : pop hl
        jr c,5F
        pop af : ret
5       pop af : jp mk_ln                               ; (PUTDAT: A = 0, B = 32, C = 8)
3       ld hl,tx_bk : call far_x
        ld hl,#DB00 : ld de,#AB00 : ld bc,0             ; (as the LDIR leaves them)
        pop af : ret
; the whole-screen vector (#011F): COPY / COPYAT (after their LDIR from the DSCR: HL = #A800 / #AB00, DE = #D800 /
; #DB00) - the text map DSCR -> screen 7 too; then mk_all
mk_cy   push af : push hl
        ld a,l : or e : jr nz,9F
        ld a,h : cp #A8 : jr z,1F : cp #AB : jr nz,9F
1       ld a,d : cp #D8 : jr z,2F : cp #DB : jr nz,9F
2       xor a : ld hl,tx_cmx : call far_x
9       pop hl : pop af : jp mk_all
        display "ui6 end ",$
        ASSERT $ <= PN_CMB
        ENT
ui6_img_end
xpg_img
        DISP #C000
        include "xpg.asm"
        display "xpg end ",$
        ENT
xpg_img_end
        DISP #FC00
        include "ommap.asm"
        ENT
xpg3_end
