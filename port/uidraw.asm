; ---- the panel's service buttons and the music's icon (MPG's MX; from UPG's ui_draw0 through far_m; the screen buffer in W1, W2)
; colour c -> byte with both pixels c
x_enc   push bc : ld b,a : and 7 : ld c,a : rlca : rlca : rlca : or c : ld c,a
        ld a,b : and 8 : jr z,1F : ld a,#C0
1       or c : pop bc : ret
px      db 0
py      db 0
; plot panel pixel (px 0..63 = x 256 + px, py) colour A
plot    push bc : push de : push hl
        ld c,a : ld a,(py) : call yoff
        ld a,(px) : srl a : push af : add a,128 : call paddr : pop af
        ld a,#47 : jr nc,1F : ld a,#B8
1       ld b,a : ld a,c : call x_enc : and b : ld e,a : ld a,b : cpl : and (hl) : or e : ld (hl),a
        pop hl : pop de : pop bc : ret
; box x 258..317 (pairs 129..158), y = A .. A+height-1, colour C
box     push af : ld a,c : call x_enc : ld (bx_v),a : pop af
        ld b,BT_H
bx_h    equ $-1                                 ; height (patched for the status box)
1       push bc : push af
        call yoff
        ld ix,bxt : ld b,4
2       push bc
        ld hl,(y_off) : ld e,(ix+1) : ld d,0 : add hl,de : ld a,(ix+0) : add a,h : ld h,a
        ld b,(ix+2) : ld a,(bx_v)
3       ld (hl),a : inc hl : djnz 3B
        inc ix : inc ix : inc ix
        pop bc : djnz 2B
        pop af : inc a : pop bc : djnz 1B
        ret
bxt     db #40,34,5, #80,34,5, #60,33,5, #A0,33,5      ; part: high byte, first byte, bytes (x 268..307)
bx_v    db 0
; text HL (0-terminated) at (D = x in the panel, E = y), colour C
text    ld a,(hl) : or a : ret z
        push hl : push de
        call glyph
        pop de : pop hl
        inc hl : ld a,d : add a,6 : ld d,a : jr text
glyph   ; A = char
        ld hl,font : ld b,a
1       ld a,(hl) : or a : ret z
        cp b : jr z,2F
        ld a,l : add a,8 : ld l,a : jr nc,1B : inc h : jr 1B
2       inc hl : ld b,7
3       push bc
        ld a,(hl) : inc hl : push hl
        ld l,a : ld a,e : ld (py),a : ld a,d : ld (px),a
        ld b,5
        sla l : sla l : sla l           ; row bits 4..0 -> 7..3
5
        bit 7,l : jr z,6F
        ld a,c : call plot
6       sla l
        ld a,(px) : inc a : ld (px),a
        djnz 5B
        pop hl : inc e : pop bc : djnz 3B
        ret
; text HL centred in the box x BT_X..+39 at y = E, colour 15
ctext   push hl : ld b,0
1       ld a,(hl) : or a : jr z,2F : inc hl : inc b : jr 1B
2       pop hl
        ld a,b : add a,a : ld c,a : add a,a : add a,c   ; 6n
        ld c,a : ld a,41 : sub c : srl a : add a,BT_X-256 : ld d,a
        ld c,15 : jp text
; button A (0..3), colour C, label HL
button  push hl : ld b,a : ld a,BT_Y0 : inc b
1       dec b : jr z,2F : add a,BT_STEP : jr 1B
2       push af : call box : pop af
        inc a : ld e,a : pop hl
        jp ctext

; 5x7 glyphs: char, 7 rows (bits 4..0)
font    db '3', #0E,#11,#01,#06,#01,#11,#0E
        db 'D', #1E,#11,#11,#11,#11,#11,#1E
        db 'G', #0E,#11,#10,#17,#11,#11,#0F
        db 'O', #0E,#11,#11,#11,#11,#11,#0E
        db 'L', #10,#10,#10,#10,#10,#10,#1F
        db 'C', #0E,#11,#10,#10,#10,#11,#0E
        db 'N', #11,#19,#15,#13,#11,#11,#11
        db 'F', #1F,#10,#10,#1E,#10,#10,#10
        db ' ', 0,0,0,0,0,0,0
        db '0', #0E,#11,#13,#15,#19,#11,#0E
        db '1', #04,#0C,#04,#04,#04,#04,#0E
        db '2', #0E,#11,#01,#02,#04,#08,#1F
        db '4', #02,#06,#0A,#12,#1F,#02,#02
        db '5', #1F,#10,#1E,#01,#01,#11,#0E
        db '6', #06,#08,#10,#1E,#11,#11,#0E
        db '7', #1F,#01,#02,#04,#08,#08,#08
        db '?', #0E,#11,#01,#02,#04,#00,#04
        db '8', #0E,#11,#11,#0E,#11,#11,#0E
        db '9', #0E,#11,#11,#0F,#01,#02,#0C
        db 'A', #0E,#11,#11,#1F,#11,#11,#11
        db 'B', #1E,#11,#11,#1E,#11,#11,#1E
        db 'E', #1F,#10,#10,#1E,#10,#10,#1F
        db 'R', #1E,#11,#11,#1E,#14,#12,#11
        db 'W', #11,#11,#11,#15,#15,#15,#0A
        db 'T', #1F,#04,#04,#04,#04,#04,#04
        db 'S', #0F,#10,#10,#0E,#01,#01,#1E
        db 'P', #1E,#11,#11,#1E,#10,#10,#10
        db 'Z', #1F,#01,#02,#04,#08,#10,#1F
        db 'Y', #11,#11,#0A,#04,#04,#04,#04
        db 1, #02,#06,#1E,#1E,#1E,#06,#02       ; the music icon: a speaker,
        db 2, #02,#09,#05,#15,#05,#09,#02       ; its sound,
        db 3, #00,#11,#0A,#04,#0A,#11,#00       ; off
        db 0

; ---- the panel into the mapped buffer (no cursor there)
ui_draw0_x
        call mus_icon
        ld a,(DBG) : or a : ret z               ; (no service buttons but "UFO2 DEBUG")
        ld a,(pend) : cp 1 : ld c,1 : jr nz,1F : ld c,6
1       ld a,0 : ld hl,s_3dgo : call button
        ld a,(pend) : cp 2 : ld c,1 : jr nz,2F : ld c,6
2       ld a,1 : ld hl,s_locgo : call button
        ld a,(d3off) : or a : ld c,4 : ld hl,s_3don : jr z,3F : ld c,2 : ld hl,s_3doff
3       ld a,2 : call button
        ld a,(LZ_ON) : or a : ld c,1 : jr z,4F : ld c,4
4       ld a,3 : ld hl,s_lazy : jp button

; the music's icon at the top right (x 306..316, y 1..7): on / off (MUS_OFF, W0); a click there toggles it
mus_icon
        ld e,0
1       ld d,50
2       ld a,d : ld (px),a : ld a,e : ld (py),a : xor a : call plot
        inc d : ld a,d : cp 62 : jr c,2B
        inc e : ld a,e : cp 9 : jr c,1B
        ld a,(MUS_OFF) : or a : jr nz,3F
        ld a,1 : ld de,50*256+1 : ld c,15 : call glyph
        ld a,2 : ld de,56*256+1 : ld c,12 : jp glyph
3       ld a,1 : ld de,50*256+1 : ld c,7 : call glyph
        ld a,3 : ld de,56*256+1 : ld c,10 : jp glyph
; the service buttons' labels (uipage.asm ui_draw0)
s_3dgo  db "3D GO",0
s_locgo db "LOC GO",0
s_3don  db "3D ON",0
s_3doff db "3D OFF",0
s_lazy  db "LAZY",0
