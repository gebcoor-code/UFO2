; ---- screen 7's change marks the game reports (vectors #011C..#0131 through mkv: W3 = UPG meanwhile)
mkv_u   push hl : push af : ld a,(mkv_r)
        cp #1F : ld hl,mk_hl : jr z,1F
        cp #22 : ld hl,mk_cy : jr z,1F
        cp #25 : ld hl,mk_atr : jr z,1F
        cp #2B : ld hl,mk_scs : jr z,1F
        cp #2E : ld hl,ov_sim3 : jr z,1F
        cp #31 : ld hl,mk_spr : jr z,1F
        ld hl,ov_psc3
1       ld (mkv_j+1),hl : pop af : pop hl
mkv_j   jp 0
mk_hl   call cm_hl : push af
        ld a,h : cp #C0 : jr c,9F
        cp #D8 : jr nc,1F
        push bc
        ld a,l : and #18 : rrca : rrca : rrca : call gbit : ld c,a : add a,a : or c : and #0F : ld c,a
        ld a,l : rlca : rlca : rlca : and 7 : ld b,a : ld a,h : and #18 : or b
        ld b,3 : call mk_rows
        pop bc
9       pop af : ret
1       cp #DB : jr nc,9B
        push bc
        ld a,l : and #18 : rrca : rrca : rrca : call gbit : ld c,a
        ld a,l : rlca : rlca : rlca : and 7 : ld b,a : ld a,h : and 3 : rlca : rlca : rlca : or b
        ld b,1 : call mk_rows
        pop bc : pop af : ret
; (mk_sc: uipage.asm's ui6 - the text layer's recorder: xpg.asm text.asm tx_rec) on its own stack (MS_S): the game's
; may be only ~30 bytes above its table at #4000 (LODLPc's modules: bank 5) - with an interrupt our chain went into it
; (the next location's modules unpacked from nowhere: a reset). Its top 6 bytes copied (tx_rec reads the game's two
; words past mkv's return), mk_sc's return -> ms_ep (back to the game's stack)
MS_S    equ #3F60
mk_scs  push af
        ld (ms_hl),hl : ld (ms_de),de : ld (ms_bc),bc
        ld hl,2 : add hl,sp : ld (ms_sp),hl
        ld de,MS_S-6 : ld bc,6 : ldir
        pop af
        ld sp,MS_S-6
        ld hl,ms_ep : ld (MS_S-6),hl
        ld hl,(ms_hl) : ld de,(ms_de) : ld bc,(ms_bc)
        jp mk_sc
ms_ep   ld (ms_hl),hl : ld hl,(ms_sp) : ld sp,hl : ld hl,(ms_hl) : ret
ms_hl   dw 0
ms_de   dw 0
ms_bc   dw 0
ms_sp   dw 0
mk_atr  push af
        ld a,(G_SELAT1+1) : cp #D8 : jr nz,9F
        pop af : push af : call 1F              ; (marked first: ep_chk takes the picture's marks back)
        call ep_chk                             ; (the encyclopedia's picture: its colours - enc.asm)
        pop af : ret
1       push af : jr mk_rb
mk_sim  call cm_sim : push af
        ld a,(G_SCOSCR+1) : cp #C0 : jr nz,9F
mk_rb   push bc : push de
        ld a,c : or a : jr z,8F
        ld d,h : ld a,h : add a,c : dec a : ld e,a
        call cols : call mk_box
8       pop de : pop bc
9       pop af : ret
mk_spr  push af
        ld a,(G_BCOSCR+1) : cp #C0 : jr nz,9B
        push hl : push bc
        ld a,l : rrca : rrca : rrca : and #1F : ld l,a : inc b      ; shifted: one byte more
        jr 1F
mk_psc  call cm_psc : push af
        ld a,(G_BCOSCR+1) : cp #C0 : jr nz,9B
        push hl : push bc
1       push de
        ld a,c : or a : jr z,2F
        ld a,h : rrca : rrca : rrca : and #1F : ld d,a
        ld a,h : add a,c : jr c,3F : dec a : cp 192 : jr c,4F
3       ld a,191
4       rrca : rrca : rrca : and #1F : ld e,a
        call cols : call mk_box
2       pop de : pop bc : pop hl : pop af : ret
cols    push bc
        ld a,l : cp 32 : jr nc,1F
        ld a,b : or a : jr z,1F
        ld a,l : add a,b : dec a : jr c,2F : cp 32 : jr c,3F
2       ld a,31
3       ld c,a : ld a,l : call gmask
        pop bc : ret
1       xor a : pop bc : ret
mk_box  or a : ret z
        push bc : ld c,a
        ld a,e : sub d : jr c,1F
        inc a : ld b,a : ld a,d : call mk_rows
1       pop bc : ret
gmask   push bc
        rrca : rrca : rrca : and 3 : ld b,a     ; first group
        ld a,c : rrca : rrca : rrca : and 3 : ld c,a
        ld a,b : call gbit : push af : ld a,c : inc a : call gbit : dec a : ld c,a   ; (2 << last) - 1
        pop af : dec a : cpl : and c            ; bits first .. last
        pop bc : ret
; the text map's cells a picture / a pixel covered (mx.asm cm_sim, cm_psc, cm_hl: MPG; HL passed in IX)
cm_sim  push ix : push hl : pop ix : ld hl,cm_simx : jr 1F
cm_psc  push ix : push hl : pop ix : ld hl,cm_pscx : jr 1F
cm_hl   push af : ld a,(infight) : or a : jr z,2F : pop af : ret         ; (not in the fights: PCOORD there is the field's)
2       pop af : push ix : push hl : pop ix : ld hl,cm_hlx
1       call far_m : push ix : pop hl : pop ix : ret
