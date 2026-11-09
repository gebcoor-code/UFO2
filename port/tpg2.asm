; ------------------------------------------------------------------ TPG #EF40..#F1FF (the wide fight only: past the
; field's shadow, slot 12 unused then): the field row's conversion, faster (fc_t's job). Kept in OVPG (#A000), brought
; into TPG at each fight's start (t2_load). Lines' addresses stepped, only the marked groups, a group compared
; first (unrolled) and converted from its first different byte
tpg2_img
        DISP #EF40
fc_t2   push ix
        call fs_chk
        exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        ld a,(fs_all) : or a : jr z,01F                  ; (window 0: all rows forced)
        xor a : ld (fs_all),a : ld hl,fs_row : ld b,FDN
02      ld (hl),#FF : inc hl : djnz 02B
01      ld a,(cw_r) : ld hl,fs_row : add a,l : ld l,a : jr nc,0F : inc h
0       ld a,(hl) : ld (hl),0 : ld (fc_f),a
        ld a,(fw_a) : ld hl,fc_la : cp (hl) : jr z,1F
        ld (hl),a : ld a,#FF : ld (fc_f),a
1       call ob_row : ld a,(fw_a) : call tslot : ld (fc_th),a
        ; the marked groups' first bytes (#FF ends)
        ld a,(fw_g) : ld hl,f2_gl : ld c,0 : ld b,5
2       rrca : jr nc,3F : ld (hl),c : inc hl
3       ex af,af' : ld a,c : add a,8 : ld c,a : ex af,af' : djnz 2B
        ld (hl),#FF
        ; the first line: EGA (part 0, W1) 320 r + #4000, its shadow FSH + 320 r, the field BDSC + 2 + 44 (8 r + 32)
        ld a,(cw_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de            ; 320 r
        ld de,#4000 : add hl,de : ld (f2_e),hl
        ld de,FSH-#4000 : add hl,de : ld (f2_s),hl
        ld a,(cw_r) : add a,a : add a,a : add a,a : add a,32 : ld l,a : ld h,0
        add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : ld b,h : ld c,l : add hl,hl : add hl,hl : add hl,de : add hl,bc   ; 44
        ld de,BDSC+2 : add hl,de : ld (f2_f),hl
        xor a : ld (fc_cg),a : ld (fc_cl),a : inc a : ld (fc_lb),a
        ld a,(fw_l) : ld (bc_lm),a
        ld a,(cw_r) : add a,a : add a,a : add a,a : ld (f2_y),a
        ld b,8
4       push bc
        ld hl,bc_lm : rrc (hl) : jp nc,8F
        xor a : ld (fc_lc),a
        call f2_ln                              ; the panels' opaque columns on this line
        ld ix,f2_gl
f2_g5
5       ld a,(ix+0) : cp #FF : jp z,7F
        inc ix
        ; group at byte A: HL = its shadow, DE = its field bytes, DE' = EGA (B' its high byte, C' = H' = the tables)
        ld c,a : ld b,0
        ld hl,(f2_e) : add hl,bc : push hl
        ld hl,(f2_f) : add hl,bc : ex de,hl
        ld hl,(f2_s) : add hl,bc
        exx : pop de : ld a,(fc_th) : ld c,a : ld h,a : ld b,d : exx
        ld a,(ix-1) : rrca : rrca : rrca : call gbit : ld (f2_gb),a : ld hl,f2_tg : and (hl)
        ld hl,(f2_s) : add hl,bc : jr z,51F     ; (HL: the shadow again) no panel in this group
        ld a,(ix-1) : call f2_gm : or a : jr z,51F
        inc a : jp z,5B                         ; all under a panel: left (the shadow too; a hidden panel: forced)
        dec a : ld (f2_mr),a
        ld a,(fc_f) : or a : call nz,f2_inv
        ld a,(f2_gb) : ld hl,f2_ob : and (hl) : jp nz,ob_g1       ; (objects in it)
        ld hl,(f2_s) : add hl,bc : jp pc_1
51      ld a,(f2_gb) : ld hl,f2_ob : and (hl) : jp nz,ob_g0
        ld hl,(f2_s) : add hl,bc
        ld a,(fc_f) : or a : jp nz,f2_all
        ; compared first
        ld a,(de) : cp (hl) : jr nz,f2_d0 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d1 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d2 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d3 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d4 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d5 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d6 : inc de : inc l
        ld a,(de) : cp (hl) : jr nz,f2_d7
        jp 5B                                   ; (all the same)
f2_d0   xor a : jr f2_dc
f2_d1   ld a,1 : jr f2_dc
f2_d2   ld a,2 : jr f2_dc
f2_d3   ld a,3 : jr f2_dc
f2_d4   ld a,4 : jr f2_dc
f2_d5   ld a,5 : jr f2_dc
f2_d6   ld a,6 : jr f2_dc
f2_d7   ld a,7
f2_dc   ld c,a : exx : add a,e : ld e,a : exx  ; (a group never crosses 256 in EGA)
        ld a,8 : sub c : ld b,a                 ; B = the bytes left
        ld c,0
51      ld a,(de) : inc de : cp (hl) : jr z,52F
        ld (hl),a : ld c,b
        exx : ld l,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : dec h : ld a,d : xor #E0 : ld d,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : ld h,c : ld d,b
        inc e : exx
        inc l : djnz 51B
        jr 6F
52      exx : inc e : exx
        inc l : djnz 51B
        ld a,c : or a : jp z,5B
f2_g6
6       ; this group changed on this line
        ld a,(ix-1) : rrca : rrca : rrca : call gbit : ld hl,fc_cg : or (hl) : ld (hl),a
        ld a,1 : ld (fc_lc),a
        jp 5B
f2_all  ld b,8                                  ; (forced: all out)
55      ld a,(de) : inc de : ld (hl),a : inc l
        exx : ld l,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : dec h : ld a,d : xor #E0 : ld d,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : ld h,c : ld d,b : inc e
        exx : djnz 55B
        jr 6B
7       ld a,(fc_lc) : or a : jr z,8F
        ld a,(fc_lb) : ld hl,fc_cl : or (hl) : ld (hl),a
8       ld hl,fc_lb : rlc (hl) : ld hl,f2_y : inc (hl)
        ld hl,(f2_e) : ld de,40 : add hl,de : ld (f2_e),hl
        ld hl,(f2_s) : add hl,de : ld (f2_s),hl
        ld hl,(f2_f) : ld de,BW : add hl,de : ld (f2_f),hl
        ld hl,(budget) : ld de,5 : add hl,de : ld (budget),hl
        pop bc : dec b : jp nz,4B
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx
        pop ix
        ld a,(fc_cg) : ld e,a : ld a,(fc_cl) : ld d,a
        jp fc_sy
; a group partly under a panel (f2_mr: its bytes there, bit 0 first): those only into the shadow
pc_1    ld b,8 : ld c,0
pc_2    ld a,(f2_mr) : rrca : ld (f2_mr),a : jr c,pc_4
        ld a,(de) : inc de : cp (hl) : jr z,pc_3
        ld (hl),a : ld c,b
        exx : ld l,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : dec h : ld a,d : xor #E0 : ld d,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : ld h,c : ld d,b
        inc e : exx
        inc l : djnz pc_2 : jp 6B
pc_4    ld a,(de) : inc de : ld (hl),a
pc_3    exx : inc e : exx : inc l : djnz pc_2
        ld a,c : or a : jp z,5B : jp 6B
        display "tpg2 end ",$
        ASSERT $ <= BL_BUF
        ENT
tpg2_img_end
; (the rest: TPG #F320, past AB_BUF)
tpg3_img
        DISP #F320
; this line's columns under the opaque parts of the panels shown: [a1, b1) (the name or the bottom one), [a2, b2)
f2_ln   ld hl,0 : ld (f2_a1),hl : ld (f2_a2),hl : xor a : ld (f2_tg),a
        ld a,(f2_y) : cp 8 : jr nc,1F
        ld hl,30*256+10 : ld (f2_a1),hl : ld a,#0E : ld (f2_tg),a : jr 2F      ; (groups 1..3)
1       cp 160 : jr c,2F
        ld a,(pvw) : rrca : jr nc,2F : ld hl,32*256+8 : ld (f2_a1),hl : ld a,#0E : ld (f2_tg),a
2       ld a,(f2_y) : cp 18 : ret c : cp 181 : ret nc
        ld a,(pvw) : and 2 : ret z
        ld hl,40*256+37 : ld (f2_a2),hl : ld hl,f2_tg : set 4,(hl) : ret         ; (group 4)
f2_tg   db 0                                    ; the groups they touch
; A = a group's first byte -> A: its bytes in them (bit k: byte A + k)
f2_gm   push hl : push de : push bc : ld e,a : xor a : ld (f2_m),a
        ld hl,(f2_a1) : call 1F : ld hl,(f2_a2) : call 1F
        pop bc : pop de : pop hl : ld a,(f2_m) : ret
1       ld a,l : cp h : ret nc                  ; (none)
        ld a,e : add a,8 : cp h : jr c,2F : ld a,h
2       sub e : ret c : ret z : ld d,a          ; D = its end in the group
        ld a,l : sub e : jr nc,3F : xor a
3       cp d : ret nc
        ld c,a                                  ; C = its start
        ld a,8 : sub d : ld b,a : ld a,#FF : jr z,5F
4       srl a : djnz 4B
5       inc c : dec c : jr z,7F
        ld b,c : ld d,a : ld a,#FF
6       add a,a : djnz 6B
        and d
7       ld hl,f2_m : or (hl) : ld (hl),a : ret
f2_y    db 0
f2_m    db 0
f2_mr   db 0
f2_a1   dw 0
f2_a2   dw 0
; (tpg.asm's: here for room)
; forced: the group's shadow made different from the field
f2_inv  push hl : push de : ld b,8
1       ld a,(de) : cpl : ld (hl),a : inc de : inc l : djnz 1B
        pop de : pop hl : ret
; the object's frame over ob_o (xspr.asm: W1 = SPG a moment)
        display "tpg3 end ",$
        ASSERT $ <= #F400
        ENT
tpg3_img_end
