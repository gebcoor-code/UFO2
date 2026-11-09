; ---- the encyclopedia's pictures in colour: UPG's part (mk_atr -> ep_chk; the rest in XPG: enc.asm; ep_mb, ep_ch
; in shift2.asm - room); PUTATR's H, L, B, C: L = 0, B = 28, C = 21 the picture's last one. All registers kept.
ep_chk  push af : push bc : push de : push hl
        ld a,l : or a : jr nz,9F : ld a,b : cp 28 : jr nz,9F : ld a,c : cp 21 : jr nz,9F
        push ix : exx : push bc : push de : push hl : exx
        ld a,i : push af : di
        ld (ep_sp),sp : ld sp,#3F80                             ; (the game's stack: in W1 - remapped)
        ld hl,ep_prep : call far_x : or a : jr z,8F             ; (decoded into PLA, PLB; 0: not it / no UFO2.ENC)
        ld a,(bf) : call ep_mb : call ep_ch                     ; the cursors off (the conversion's step: on again)
        call swaprec : ld a,(bf) : xor 1 : call ep_mb : call ep_ch : call swaprec
        ld hl,ep_fin : call far_x                               ; both buffers, the shadow (the game's W1, W2 after)
8       ld sp,(ep_sp)
        pop af : jp po,1F : ei
1       exx : pop hl : pop de : pop bc : exx : pop ix
9       pop hl : pop de : pop bc : pop af : ret
ep_sp   dw 0
; the 3D fight's pace (zx_view: after each picture): at least 3, 3, 4 frames a picture (10 in 3: as a ZX at 1.5 x its
; clock, 5.25 MHz - the ATM's turbo was faster; a slower machine stays as it is)
x_pace  ld hl,xp_k : ld a,(hl) : inc a : cp 3 : jr c,1F : xor a
1       ld (hl),a : ld b,3 : or a : jr nz,2F : inc b
2       ld hl,xp_fr : ld a,i : jp po,4F                 ; (interrupts off: no waiting)
3       ld a,(ifr) : sub (hl) : cp b : jr nc,4F
        halt : jr 3B
4       ld a,(ifr) : ld (hl),a : ret
xp_k    db 0
xp_fr   db 0
; ---- a white text at DE (a page's part 0 / 1 line's byte: + #2000 the part 2 / 3), C = the glyphs' shift (0: pairs
; 4c, 4c + 2; 2: 4c + 1, 4c + 3): "Loading..." (a location: uipage.asm ld_beg, far_x) / "Unpacking..." (the start's
; rest: title.asm t_ldg, W3 = UPG, W2 the page) - UPG (was XPG's)
lt_load ld hl,ld_txt : jr ld_tx
lt_unp  ld hl,lu_txt
ld_tx
2       ld a,(hl) : or a : ret z
        inc hl : push hl : push de
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push de : ld de,ld_fnt - 8 : add hl,de : pop de
        ld b,8
3       push bc : ld a,(hl) : inc hl : ld b,c : inc b
31      dec b : jr z,32F : add a,a : jr 31B
32      push af : call 4F : ld (de),a : pop af
        add a,a : add a,a : add a,a : add a,a : call 4F : set 5,d : ld (de),a : res 5,d
        ex de,hl : ld bc,40 : add hl,bc : ex de,hl : pop bc : djnz 3B
        pop de : inc de : pop hl : jr 2B
; A's bits 7, 6 -> a pair's byte (white)
4       ld b,0 : rla : jr nc,41F : ld b,#47
41      rla : ld a,b : ret nc : or #B8 : ret
ld_txt  db 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 0
lu_txt  db 9, 6, 10, 3, 11, 12, 5, 6, 7, 8, 8, 8, 0
ld_fnt  db %01100000,%01100000,%01100000,%01100000,%01100000,%01100000,%01111110,0      ; L
        db 0,0,%00111100,%01100110,%01100110,%01100110,%00111100,0                      ; o
        db 0,0,%00111100,%00000110,%00111110,%01100110,%00111110,0                      ; a
        db %00000110,%00000110,%00111110,%01100110,%01100110,%01100110,%00111110,0      ; d
        db %00011000,0,%00111000,%00011000,%00011000,%00011000,%00111100,0              ; i
        db 0,0,%01111100,%01100110,%01100110,%01100110,%01100110,0                      ; n
        db 0,0,%00111110,%01100110,%01100110,%00111110,%00000110,%00111100              ; g
        db 0,0,0,0,0,%00011000,%00011000,0                                              ; .
        db %01100110,%01100110,%01100110,%01100110,%01100110,%01100110,%00111100,0      ; U
        db 0,0,%01111100,%01100110,%01100110,%01111100,%01100000,%01100000              ; p
        db 0,0,%00111100,%01100110,%01100000,%01100110,%00111100,0                      ; c
        db %01100000,%01100000,%01100110,%01101100,%01111000,%01101100,%01100110,0      ; k
