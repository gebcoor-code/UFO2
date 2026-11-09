; ------------------------------------------------------------------ the coloured fighters / aliens (UFO2.SPR)
; Alone Coder's NedoOS UFO-2 pictures (XHERO): frame k = xHERO's k (16 x 24; 128..135 xDIE), 24 lines x 8 bytes, a byte
; two pixels (nibbles, high = left: a logical colour - xs_lm). Pages SPG (frames 0..71) and SPG2 (72..135), each with the
; same header at #4100 (W1 while used): xs_rec (the objects' places), the code, xs_tab / xs_om (xs_mkt).
; The hooks (obj.asm: A4P's DATR figure, GBU's moving one) note an object's frame and place (xs_rec, both pages);
; the conversion (tpg.asm ob_out -> ob_xc) puts the frame's pixels over the ones M says are the object's.
SPG     equ 26
SPG2    equ 27
XF      equ 136                         ; frames
XF1     equ 72                          ; in SPG
XFR     equ #4A00                       ; the frames
xs_tab  equ #4700                       ; (256) a nibble pair -> its EGA byte
xs_om   equ #4800                       ; (256) a nibble pair -> the EGA bits of its pixels (nibble 8: none)
xs_tf   equ #4900                       ; (256) as xs_tab, for the fighter in focus (brighter)
xs_rec  equ #4100                       ; (32 x 8) frame (#FF: none), top line (2), left pixel (2): the field's
XN      equ 32
; the records none (each fight's start, a battle loaded): W1 = SPG, SPG2 a moment 
        MACRO XS_CLR
        WIN P_W1, SPG : call xs_cl1
        WIN P_W1, SPG2 : call xs_cl1
        WIN P_W1, TLPG : call pl_new           ; (xtil.asm: the colour plane empty; W2 the game's bank 2 after)
        ENDM
ob_fd   equ #FF00                       ; (TPG: the old ob_m's room) the field byte converted (ob_g1)
xs_f    equ #FF02                       ; (TPG, not the page: XS_COL switches SPG -> SPG2 midway)
xs_r    equ #FF03
xs_p    equ #FF04
xs_q    equ #FF05
xs_sb   equ #FF06
xs_y    equ #FF07
xs_x    equ #FF08                       ; (2)
xs_li   equ #FF0A                       ; (2)
xs_rm   equ #FF0C                       ; M's pixels left
xs_th   equ #FF0D                       ; the object's table (high byte: xs_tab / xs_tf)

xspr_img
        DISP #4200
; ---- the hooks' (obj.asm xs_go: W1 = SPG, W3 = MPG; W1 left as it ends, xs_go puts the game's back)
; A4P's figure (ob_spr, after ob_hero): frame (alive: direction * 2 + race * 16; dead: 128 + race), top = the line +
; 4 - os_l0, left = its left column * 8
xs_hset ld a,(os_hx) : or a : ret z : dec a : cp XN : ret nc : ld (xs_ix),a
        ld hl,(G_HIX) : inc hl : inc hl : inc hl
        ld a,(os_lv) : or a : ld a,(hl) : inc hl : ld c,(hl) : jr z,1F
        add a,a : ld b,a : ld a,c : add a,a : add a,a : add a,a : add a,a : add a,b : jr 2F
1       ld a,c : add a,128
2       ld (xs_nf),a
        ld a,(os_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_l) : add a,4 : ld e,a : ld d,0 : add hl,de
        ld a,(os_l0) : ld e,a : rla : sbc a,a : ld d,a : or a : sbc hl,de : ld (xs_nt),hl
        ld a,(os_c) : ld l,a : ld a,(os_cm) : cp 2 : jr nz,3F : dec l
3       ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (xs_nl),hl
        ld a,(xs_ix) : ld hl,xs_mv : cp (hl) : jr nz,4F : ld (hl),#FF     ; (he stopped)
4       ld a,(xs_ix) : jr xs_wr
; GBU's (moving): frame = (his picture - xHERO) / 96, top = the line, left = the column * 8 + the shift
xs_gset ld a,(os_hx) : or a : ret z : dec a : cp XN : ret nc : ld (xs_ix),a
        ld l,(ix+6) : ld a,(ix+7) : sub high G_xHERO : ret c : ld h,a
        ld de,-96 : ld c,-1
1       inc c : add hl,de : jr c,1B
        ld a,c : cp XF : ret nc : ld (xs_nf),a
        ld a,(os_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_l) : ld e,a : ld d,0 : add hl,de : ld (xs_nt),hl
        ld a,(os_c) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_do) : ld e,a : ld d,0 : add hl,de : ld (xs_nl),hl
        ld a,(xs_ix) : ld (xs_mv),a
        jr xs_wr
; A = index: its record none (fg_cl1: his figure gone from its cell)
xs_off  cp XN : ret nc
        push hl : push de : push bc
        ld c,a : ld a,#FF : ld (xs_nf),a : ld a,c : call xs_wr
        pop bc : pop de : pop hl : ret
; A = index: xs_nf.. into its record here and in SPG2 (ends with W1 = SPG2); the row lists made again
xs_wr   add a,a : add a,a : add a,a : ld l,a : ld h,high xs_rec : push hl
        ld hl,xs_nf : ld a,(hl) : inc hl : ld c,(hl) : inc hl : ld b,(hl) : inc hl : ld e,(hl) : inc hl : ld d,(hl)
        pop hl : call 1F
        push bc : ld bc,P_W1 : push af : ld a,#7F-SPG2 : out (c),a : pop af : pop bc     ; (the same code there)
1       push hl : ld (hl),a : inc l : ld (hl),c : inc l : ld (hl),b : inc l : ld (hl),e : inc l : ld (hl),d : pop hl
        push af : ld a,#FF : ld (xs_cr),a : pop af : ret
xs_ix   db 0
xs_nf   db 0                                    ; frame, top (2), left (2): as xs_rec's
xs_nt   dw 0
xs_nl   dw 0
; the field scrolled (wideu.asm xs_scr): A = 0 a byte left, 1 right, 2 8 lines up, 3 down - the records the same
; (here and in SPG2: ends with W1 = SPG2)
xs_shf  ld c,a : call 1F
        push bc : ld bc,P_W1 : ld a,#7F-SPG2 : out (c),a : pop bc     ; (the same code there)
1       ld hl,xs_rec : ld b,XN
2       ld a,(hl) : cp XF : jr nc,5F
        push hl
        inc l : ld a,c : cp 2 : jr nc,3F : inc l : inc l                ; left (0, 1) or top (2, 3)
3       ld e,(hl) : inc l : ld d,(hl)
        push hl : ld hl,8 : bit 0,c : jr nz,4F : ld hl,-8
4       add hl,de : ex de,hl : pop hl
        ld (hl),d : dec l : ld (hl),e
        pop hl
5       ld a,l : add a,8 : ld l,a : djnz 2B
        ld a,#FF : ld (xs_cr),a : ret
; the field view's palette (wideu.asm xp_fight): xs_tab, xs_tf from xs_lm, xs_lf (the location's: wideu.asm lp_set -
; UFO2.TIL's, build/mktil.py: a slot the location took for a colour of its own / its paper's - the nearest of the
; others; 0.66.0)
xs_mkt  ld hl,xs_lm : ld (xs_mp),hl : ld hl,xs_tab : call 6F
        ; our fighters not in focus: blue (xs_lf; XS_COL) - the one in focus keeps the red (xs_tab), as the aliens
        ld hl,xs_lf : ld (xs_mp),hl : ld hl,xs_tf : call 6F
        ld hl,xs_om : ld c,0                    ; xs_om: a pair's pixels unless nibble 8
7       ld a,c : and #F0 : cp #80 : ld a,0 : jr z,71F : ld a,#47
71      ld b,a : ld a,c : and #0F : cp 8 : ld a,b : jr z,72F : or #B8
72      ld (hl),a : inc l : inc c : jr nz,7B
        ret
; HL = a table: pair C (nibbles) -> its EGA byte through the map (xs_mp)
6       ld c,0
4       ld a,c : rrca : rrca : rrca : rrca : call 5F : ld b,a  ; the left one: bits 0-2, 6
        and 7 : ld e,a : ld a,b : and 8 : rlca : rlca : rlca : or e : ld e,a
        ld a,c : call 5F : ld b,a                               ; the right one: bits 3-5, 7
        and 7 : rlca : rlca : rlca : or e : ld e,a : ld a,b : and 8 : rlca : rlca : rlca : rlca : or e
        ld (hl),a : inc l : inc c : jr nz,4B
        ret
5       and 15 : push hl : ld hl,(xs_mp) : add a,l : ld l,a : ld a,(hl) : pop hl : ret
xs_mp   dw 0
; logical colour -> slot (the location's: lp_set; here the fight's as before 0.66.0 - an old UFO2.TIL): black, white,
; olive (yellow), dark red (red), red (bright red), light grey (white), green (11), brown (8), -, grey-green (4),
; maroon (3), pink (5), blue-grey, teal (blue), orange (bright yellow), dark grey (white); then xs_lf - our fighters
; not in focus: dark red -> blue, red, pink -> bright blue, maroon -> black (the same dots). 32 bytes together (lp_set)
        ALIGN 16
xs_lm   db 0, 15, 6, 2, 10, 7, 11, 8, 0, 4, 3, 5, 1, 1, 14, 7
xs_lf   db 0, 15, 6, 1, 9, 7, 11, 8, 0, 4, 0, 9, 1, 1, 14, 7
        ASSERT high xs_lm == high (xs_lf+15) && xs_lf == xs_lm+16
; (XS_CLR: W1 = this page) xs_rec, xs_cr, xs_mv none
xs_cl1  ld hl,xs_rec : ld b,0
1       ld (hl),#FF : inc l : djnz 1B
        ld a,#FF : ld (xs_cr),a : ld (xs_mv),a : ret
xs_ok   db 0                                    ; UFO2.SPR read
xs_cr   db #FF                                  ; the row xs_cl is for (#FF: none; the hooks: xs_rec changed)
xs_mv   db #FF                                  ; the one moving (GBU), #FF: none
xspr_dend
        ENT
xspr_img_end
        ASSERT xspr_dend <= xs_tab
        ASSERT XFR + XF1 * 192 <= #8000 && (XFR & 255) == 0 && (XF1 * 192) % 128 == 0

; at the start (after mus_go: STAGE free): the header into SPG, SPG2; UFO2.SPR's frames (none: xs_ok 0, no colours)
xs_load di
        ld a,SPG : call 1F : ld a,SPG2 : call 1F
        ei
        ld a,#80 : ld (mz_b),a
        ld hl,f_spr : ld de,STAGE : ld b,XF1*192/128 : call mz_rd : ret nc     ; (mz.asm: packed)
        ld a,b : or a : ret nz                  ; (short)
        ld a,SPG : ld hl,STAGE : ld bc,XF1*192 : call 2F
        ld de,STAGE : ld b,(XF-XF1)*192/128 : call mz_more
        ld a,b : or a : ret nz
        ld a,SPG2 : ld hl,STAGE : ld bc,(XF-XF1)*192 : call 2F
        di
        ld a,SPG : call map_w2 : ld a,1 : ld (xs_ok-#4000+#8000),a
        ld a,SPG2 : call map_w2 : ld a,1 : ld (xs_ok-#4000+#8000),a
        ld a,2 : call map_w2 : ei : ret
2       di : push af : call map_w2 : pop af
        ld de,XFR-#4000+#8000 : call fcopy
        ld a,2 : call map_w2 : ei : ret
; the header: the table, no objects, the code
1       call map_w2
        ld hl,#8100 : ld b,0
4       ld (hl),#FF : inc l : djnz 4B           ; xs_rec: none
        ld hl,xspr_img : ld de,#8200 : ld bc,xspr_img_end-xspr_img : ldir
        ld a,2 : jp map_w2
f_spr   db "UFO2    SPR"
