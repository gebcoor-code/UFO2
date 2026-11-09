; ------------------------------------------------------------------ the wide battlefield (location fights)
; The game (build/wide.py) draws its field into window 0, #1C00..#39FF: 40 bytes a line, 192 lines, the visible
; part = lines 32..159, bytes 2..37 (288 x 128: as the game's 28 of its 30 drawn bytes, the 19 cells' 38). Outside the fights that is our shadow (SHP), LUT and attribute
; shadow: they are rebuilt after the fight (bat_off). In the fight the conversion uses no shadow (always "all out").
; EGA, state A (the field view): the field at x 0..287, y 12..139 (converted from the wide buffer, fe_row marks);
; screen 7's rows 0 and 17..23 (columns 0..28) as usual, columns 29..31 of every row at x 296..319;
; state B (after a whole screen-7 picture: menus, "?", the start): screen 7 as on the geoscape, x 256..319 black.
; The next OUTDSC goes back to state A.
BDSC    equ #0F40                       ; (the fight) 264 lines x 44 = 11616 bytes: up to the game's stack (#3CA0)
BW      equ 44
BLINES  equ 264
BL_BUF  equ #F200               ; (TPG: past the field's shadow) the row's lines from screen 7 (8 x 32), state B
AB_BUF  equ #F300               ; (TPG) the row's attributes (32)
pn_full db 0                    ; 1: state A's whole panel to draw (the next conversion)
bwide   db 0                    ; 1: the wide field is in window 0
bst     db 0                    ; 0: state A (the field view), 1: state B (a screen-7 picture)
pvw     db 3                    ; the panels shown (for fc_t2): bit 0 the bottom one, bit 1 the side one
fe_row  ds FDN                  ; field rows 0..24: groups of 8 EGA bytes to convert
fe_lin  ds FDN                  ; (must follow fe_row) their lines
fs_row  ds FDN                  ; #FF: the row all out next time (fc_t; fs_all sets all; the panels hidden: pn_force)
cw_r    db 0
fs_new  db 0                    ; 1: TPG's slots 8..12 still to be freed (the field's shadow there)
fs_all  db 0                    ; 1: the field's shadow invalid (all out)
fw_g    db 0
fw_l    db 0
fw_a    db 0
; XYHL: E = half-row, D = column -> HL = E*4*44 + D (BC, DE kept)
lay_xyhl
        push bc : push de
        ld l,e : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld b,h : ld c,l      ; 16 E
        add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de : add hl,bc            ; 176 E
        pop de
        ld c,d : ld b,0 : add hl,bc
        pop bc : ret
; BATTL1 (DI): the EGA view as LAY_GEO does it, then the wide field
lay_bat push af : push bc : push de : push hl
        xor a : ld (s_hold),a : call kb_mode
        ld a,(ega) : or a : call z,ega_on
        ld hl,bat_on : call far_g
        pop hl : pop de : pop bc : pop af : ret
; the game's windows: HL = code in UPG (W3 back to the game's bank after it)
far_g   push af : ld a,UPG : call map_w3p : pop af
        call 1F
        push af : ld a,(cur) : call map_w3 : pop af : ret
1       jp (hl)
; OUTDSC in the fight (bank 7 in W3)
lay_outw
        ld a,MPG : call map_w3p : call ob_pend          ; (the objects' changes: real ones marked)
        ld hl,outd_u : call far_g
        ld a,(ega) : or a : jp z,G_PT128
        jp od_end
; row A of the conversion (W3 = bank 7, the back buffer mapped): screen 7's part (cmask, lmask), then the field's
conv_rw ld (cw_r),a
        ld a,(bst) : or a : jr nz,.b
        ; state A: field row cw_r (0..24): what is pending there copied first, converted, the panels over it
        ld a,(cw_r) : cp FDN : ret nc
        call sync_row
        ld a,(cw_r) : ld hl,fe_row : add a,l : ld l,a : jr nc,6F : inc h
6       ld a,(hl) : or a : ret z
        ld (fw_g),a : ld (hl),0 : ld de,FDN : add hl,de : ld a,(hl) : ld (fw_l),a : ld (hl),0
        ld a,(FW_C) : and #3F : ld (fw_a),a                ; the field's attribute (the game's COLOR: outd_u)
        ld a,TPG : call map_w3p : call fc_t0
        ld de,(fc_cg)                           ; (E, D: its changed groups, lines - the colour plane's pl_post)
        ld a,(cw_r) : ld hl,pl_pst : jp far_ui  ; (then the panels: pn_ovl; W3 = bank 7 after it)
        ; state B: screen 7's row (cmask, lmask) -> TPG's buffers (W1 = TPG meanwhile), then bc_t
.b      ld a,(cmask) : or a : jr z,8F
        WIN P_W1, TPG
        ld a,(cw_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,#D800 : add hl,de : ld de,AB_BUF-#8000 : ld bc,32 : ldir                ; its attributes
        ld a,(cw_r) : and #18 : or #C0 : ld h,a : ld a,(cw_r) : and 7 : rrca : rrca : rrca : ld l,a
        ld de,BL_BUF-#8000 : ld a,(lmask) : ld c,a : ld b,8
2       rrc c : jr nc,3F
        push bc : push hl : ld bc,32 : ldir : pop hl : pop bc : jr 4F           ; a marked line
3       ld a,e : add a,32 : ld e,a
4       inc h : djnz 2B
        ld a,(bf) : or a : ld a,#7F-PS3 : jr z,7F : ld a,#7F-PS1
7       ld bc,P_W1 : out (c),a                 ; W1: the back buffer again
        ld a,TPG : call map_w3p : call bc_t                    ; (its pending copy there: tpg.asm bc_cv)
8       ld a,(cw_r) : call sync_row                             ; (else - LD_ON, a popup's other rows - here)
        ld a,7 : jp map_w3
; the conversion step's end: the panel's marked elements (into both buffers: our cursor off in both first)
pn_fl   ld hl,ov_fl6 : call far_ui : ret z          ; (state A: what the game's state changed -> the panels' picture)
        call scr_map : call cur_hide : call bcur_hide
        ld hl,pn2_show : jp far_ui
; LAY_NAME (PANELM, NAMPRE): A = the name's word just printed into DSCR
lay_name
        ld hl,pn2_name : jp far_g
lay_namp
        ld hl,G_MAN+8 : ld b,10
1       push bc : push hl : ld a,(hl) : or a : ld de,-8 : add hl,de : call nz,G_PNAM   ; (ADD HL keeps Z)
        pop hl : ld de,32 : add hl,de : pop bc : djnz 1B
        ret
; the fight's SAVE / LOAD with the disk (A = 0 / 1; UPG's u_dsk -> XPG's x_dsk)
lay_dsk ld hl,u_dsk : jp far_g
; after the fight (LAY_GEO, the game's windows): the shadow, LUT, attribute shadow back
bat_off push hl : ld hl,bat_off_u : call far_g
        call ega_re : pop hl : ret               ; (bwide: 0 by bat_off_u; the EGA view again at once - no ZX mode between)
