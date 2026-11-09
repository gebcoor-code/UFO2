; UFO2.COM for NedoOS, stage N0: the frame of a NedoOS task (Evo BaseConf)
; - hides from NC (OS_HIDEFROMPARENT), takes the screen: EGA 320x200, its pages kept (+#80), a 16-colour palette
; - draws 16 bands on screen 0 and the same in the reverse order on screen 1
; - Space: the other screen (OS_SETSCREEN); any other key: back to NC (QUIT); the border: the start's steps
;   (1 blue: started, 2 red: the windows' ports are not Evo BaseConf's - a key: QUIT)
        device zxspectrum128
        include "../../port/nedo_h.inc"
        org #100
start   ld sp,#4000                             ; (the stack in our page 0: #3B00..#3FFF)
        ld hl,0 : NOS CMD_HIDEFROMPARENT
        ld e,#80 : NOS CMD_SETGFX               ; EGA, the screen's pages kept, the focus ours
        ld de,pal : NOS CMD_SETPAL
        ld e,1 : NOS CMD_SETBORDER
        NOS CMD_GETMEMPORTS                     ; BC = #4000's port, DE = #8000's, HL = #C000's
        ld a,b : cp high MP4000 : jr nz,bad
        ld a,d : cp high MP8000 : jr nz,bad
        ld a,h : cp high MPC000 : jr nz,bad
        ld a,(user_scr0_low) : NSETPG4
        ld a,(user_scr0_high) : NSETPG8
        xor a : call draw
        ld a,(user_scr1_low) : NSETPG4
        ld a,(user_scr1_high) : NSETPG8
        ld a,15 : call draw
        ld e,0 : NOS CMD_SETSCREEN
        ld e,0 : NOS CMD_SETBORDER
loop    NYIELD
        NGETKEY
        jr nz,loop                              ; (no focus)
        or a : jr z,loop
        cp key_redraw : jr z,loop
        cp ' ' : jr nz,quit
        ld a,(scr) : xor 1 : ld (scr),a
        ld e,a : NOS CMD_SETSCREEN
        jr loop
bad     ld e,2 : NOS CMD_SETBORDER
1       NYIELD
        NGETKEY
        jr nz,1B
        or a : jr z,1B
quit    ld hl,0 : NQUIT

; 16 bands of 12 lines, the last 8 lines colour 15; A = 0 (0 at the top) / 15 (reversed)
; EGA: line y at y*40 in #4000 (pixels 0, 1 of each 8: the low page) / #8000 (2, 3: the high page), +#2000: 4..7
draw    ld (dr_x),a
        ld hl,#4000 : ld de,#000C               ; D = band, E = its lines left
        ld b,200
1       push bc
        ld a,d
dr_x    equ $+1
        xor 0
        and 15 : call cbyte
        push hl : call fill40 : set 5,h : call fill40 : ld a,h : add a,#20 : ld h,a : ld a,c
        call fill40 : set 5,h : call fill40 : pop hl
        ld bc,40 : add hl,bc
        dec e : jr nz,2F
        ld e,12 : ld a,d : cp 15 : jr z,2F
        inc d
2       pop bc : djnz 1B
        ret
fill40  push hl : ld b,40
1       ld (hl),c : inc hl : djnz 1B
        pop hl : ret
; A = colour 0..15 -> C = the EGA byte of two such pixels (%HhLLL lll as the screen takes: bits 0-2, 6 the left
; pixel, 3-5, 7 the right one)
cbyte   ld b,a : and 7 : ld c,a : add a,a : add a,a : add a,a : or c : ld c,a
        bit 3,b : ret z
        ld a,c : or #C0 : ld c,a : ret

scr     db 0
; the palette: 16 x 2 bytes (Evo's low bits, ATM's %grbG11RB), inverted - NedoOS's standard one
pal     dw #FFFF,#FEFE,#FDFD,#FCFC,#EFEF,#EEEE,#EDED,#ECEC
        dw #FFFF,#DEDE,#BDBD,#9C9C,#6F6F,#4E4E,#2D2D,#0C0C
        savebin "ufo2n.com",#100,$-#100
