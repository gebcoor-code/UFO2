; ------------------------------------------------------------------ the battlefield in the EGA view
; The fight draws its field into DSCR (bank 2, #9000: linear, 32 bytes a line; the visible part = lines 32..159,
; bytes 2..29) and copies it to screen 7 (OUTDSC: lines 8..135, columns 1..28) in every pass of its loop.
; Here the drawing routines mark what they change (field lines x groups of 8 screen columns, fdrow / fdlin),
; and OUTDSC copies only that (and marks it for the conversion); one more line in 16 is compared anyway.
FDN     equ 25                      ; field rows (state A: 0..24, y 8 r; the ZX screen mode: rows 1..16)
fdrow   equ #3DB8                   ; (FDN) groups
fdlin   equ fdrow+FDN               ; (FDN, must follow fdrow) lines
fall    db 0                    ; 1: all the field changed (scroll, clear)
fscan   db 0                    ; the next field line of the slow check
fm_l    db 0
fm_n    db 0
fm_g    db 0
; HL = DSCR address, B = lines, C = bytes: marked (all registers kept)
lay_fd2 push bc : ld c,2 : call fmark
lfd2_r  pop bc : ret
lay_fd1 push bc : ld c,1 : call fmark
lfd1_r  pop bc : ret
lay_fdc push bc : ld a,b : ld b,c : ld c,a : call fmark     ; (CURHER, GBU, PBU: B = bytes, C = lines)
lfdc_r  pop bc : ret                    ; (obj.asm tells its callers apart by these returns)
lay_fpad
        push hl : push bc : ex de,hl : ld bc,#4002 : call fmark
lfpd_r  ex de,hl : pop bc : pop hl : ret
; the game's scrolls (RRT / LRT / DRT / URT, before its own LDIR): state A (EGA) the shift is noted (sh_fall), done
; once before the next conversion (sh_do: the back buffer and the shadow moved, not converted again)
lay_fall
        push af : ld a,(ega) : or a : jr z,1F : ld a,(bst) : or a : jr nz,1F
        push hl : ld hl,4 : add hl,sp : ld a,(hl) : inc hl : ld h,(hl) : ld l,a   ; HL = the game's routine + 3
        push bc : push de : ld a,i : push af : di
        ld a,MPG : call map_w3p : call ob_sh : ld a,UPG : call map_w3p : call sh_fall : ld a,(cur) : call map_w3
        pop af : jp po,2F : ei
2       pop de : pop bc : pop hl : pop af : ret
1       ld a,1 : ld (fall),a : pop af : ret
sh_off  dw 0                    ; the pending shift: new(p) = old(p - sh_off) (flat, 40 a line)
sh_pend db 0                    ; 1: one is pending (no conversion before it is done)
sh_go   db 0                    ; 1: OUTDSC's conversion (the picture complete): do it
; the pending shift: the back buffer and the shadow moved, what the front has more copied, the panels (sh_pan)
sh_do   ld hl,sh_pan : call far_ui
        jp map_back
fmark   push af : ld a,(ega) : or a : jr z,9F   ; (the work: ob_ent in MPG; the fight's DI)
        push bc : push de : push hl
        ld a,(W3V) : ld (fm_w3),a                               ; (ob_ent puts it back: obj.asm ob_ex)
        ld a,MPG : call map_w3p : call ob_ent                   ; (the marks, the object planes)
        pop hl : pop de : pop bc
9       pop af : ret

; OUTDSC (bank 7 in W3); ends as the game's: PT128
lay_outd
        ld a,(bwide) : or a : jp nz,lay_outw
        jp lay_outd2                            ; (overlay: not in a wide fight)
; the fight runs with interrupts off (only its DELAY waits in a HALT): a step of the conversion after each picture
od_end  call od_conv : jp G_PT128
; (also from the game's input polling, when OUTDSC has not come for a while: its own waiting loops, "?" etc.)
od_conv xor a : ld (od_cnt),a
        ld a,i : push af : di                   ; P/V = IFF2
        ld hl,od_h+1 : push hl                  ; "returns after a HALT": conv_step's big budget
        ld (i_sp),sp : ld sp,#3FC0 : push ix    ; (int_h's own: no interrupt in here)
        ld hl,sk_go2 : call far_g               ; (sh_go: a scroll going on - every other step shown)
        call cs_ei                               ; (a flip if one was ready)
1       ld a,(bchg) : or a : jr z,2F            ; the picture changed: convert all of it now, then flip
        ld a,(fready) : or a : jr nz,3F
        xor a : ld (age),a                      ; (complete: no flip by age here)
        call cs_ei : jr 1B
3       xor a : ld (sh_go),a                    ; (the flip: the other buffer moved at the next OUTDSC, with its scroll)
        call cs_ei
2       xor a : ld (sh_go),a
        pop ix : ld sp,(i_sp) : pop af : pop af
        ret po : ei : ret
od_cnt  db 0
od_h    halt
od_g    db 0
od_l    db 0
od_y    db 0
; screen line A: the groups (od_g) copied from DSCR and marked
; copy screen line (od_y), groups (od_g), columns 1..28, from DSCR
; A = first column, BC = bytes, if the next group's bit (od_gm, bit 0 first) is set (HL, DE kept)
; A = screen line -> HL = its address in screen 7 (column 0)
; screen line A: compared with DSCR; if different, copied and marked

; ---- the fight's RAM SAVE / LOAD (instead of IND_LS): D = its attribute (#57 save, #4D load), B = 32..1;
; EGA: a bar under SAVE / LOAD drawn into the shown buffer (EGA lines 190..193, x 24..87), then given back to the
; conversion (shadow of row 23 lines 2..5 made "different", marked)
lay_prog
        ld a,(ega) : or a : jp z,G_INDLS
        push hl : ld hl,lay_prog_u : call far_g : pop hl : ret
pg_b    db 0
pg_v    db 0
