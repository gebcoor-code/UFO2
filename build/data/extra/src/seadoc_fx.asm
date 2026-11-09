; UFO2DOC / SEADOC: the screen saver - points flying in all directions, bouncing off the edges (as in MERFI.COM),
; instead of the falling snow. Replaces #0C55..#0D7A (the encrypted part: re-encrypted by mkdoc.py).
        DEVICE NOSLOT64K
YTAB    equ #0141               ; the viewer's: 200 line addresses (#C000 + y*40)
MTAB    equ #0139               ; #80, #40 .. #01
PTS     equ #A000               ; N x (x lo, x hi, y, flags: bit 0 x back, bit 1 y back)
SAV     equ #A100               ; saved screen bytes: (byte, lo, hi) per point
N       equ 64
EXIT    equ #0E0E               ; the viewer's: page 3, EI, POP AF, JP #048E

        org #0C55
fx      di
        ld ix,PTS : ld b,N                      ; random places and directions
1       call rnd : ld l,a : call rnd : and 1 : ld h,a   ; x 0..511 + ..
        call rnd : and 127 : ld e,a : ld d,0 : add hl,de   ; .. 0..638
        ld (ix+0),l : ld (ix+1),h
2       call rnd : cp 200 : jr nc,2B : ld (ix+2),a
        call rnd : and 3 : ld (ix+3),a
        ld de,4 : add ix,de : djnz 1B
.frame  ld bc,#FFF7 : ld a,#7A : out (c),a      ; pixels (page 5)
        exx : ld de,SAV : exx
        ld ix,PTS : ld b,N
3       push bc : call plot : pop bc
        ld de,4 : add ix,de : djnz 3B
        ld bc,#FFF7 : ld a,#7C : out (c),a
        ei : halt
        push bc
        call #F812 : or a                       ; a key: away (the snow did so)
        di
        ld bc,#FFF7 : ld a,#7A : out (c),a
        push af : call unplot : pop af
        jp nz,EXIT
        pop bc
        ; move: x by 0..7, y by 0..3 a frame, back at the edges
        ld ix,PTS : ld b,N
4       ld l,(ix+0) : ld h,(ix+1)
        call rnd : and 7 : ld e,a : ld d,0
        bit 0,(ix+3) : jr nz,5F
        add hl,de : push hl : ld de,-640 : add hl,de : pop hl : jr nc,6F
        jr 7F
5       or a : sbc hl,de : jr nc,6F
7       ld a,(ix+3) : xor 1 : ld (ix+3),a : jr 8F      ; (an edge: the other way, from the next frame)
6       ld (ix+0),l : ld (ix+1),h
8       call rnd : and 3 : ld c,a : ld a,(ix+2)
        bit 1,(ix+3) : jr nz,9F
        add a,c : cp 200 : jr c,10F
        jr 11F
9       sub c : jr nc,10F
11      ld a,(ix+3) : xor 2 : ld (ix+3),a : jr 12F
10      ld (ix+2),a
12      ld de,4 : add ix,de : djnz 4B
        jp .frame
; the saved bytes back (the last first)
unplot  exx
1       ld hl,SAV : or a : sbc hl,de : jr nc,2F
        dec de : ld a,(de) : ld h,a : dec de : ld a,(de) : ld l,a : dec de
        ld a,(de) : ld (hl),a : jr 1B
2       exx : ret
rnd     push hl
        ld a,r : ld h,a
        ld a,(rs1) : rrca : rrca : rrca : ld (rs1),a : adc a,h : ld h,a
        ld a,(rs2) : rlca : xor h : ld (rs2),a
        pop hl : ret
rs1     db #9B
rs2     db #72
fx_end
        ASSERT fx_end <= #0D7B
        display "fx end ", fx_end

        org #0DAB                       ; (plain part: the old dead copy of the effect)
fx2
; the point IX: its byte saved (SAV.. by DE'), its pixel set
plot    ld l,(ix+2) : ld h,0 : add hl,hl : ld de,YTAB : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ld e,(ix+0) : ld d,(ix+1)
        ld a,e : and 7 : push hl : ld hl,MTAB : add a,l : ld l,a : ld c,(hl) : pop hl
        srl d : rr e : srl d : rr e : srl e : srl e     ; E = x / 16, CY = column odd
        ld d,#20 : jr c,1F : ld d,0
1       add hl,de
        ld a,(hl) : exx : ld (de),a : inc de : exx
        or c : ld (hl),a
        ld a,l : exx : ld (de),a : inc de : exx
        ld a,h : exx : ld (de),a : inc de : exx
        ret
fx2_end
        ASSERT fx2_end <= EXIT
        display "fx2 end ", fx2_end
        savebin "fx.bin",#0C55,fx_end-#0C55
        savebin "fx2.bin",fx2,fx2_end-fx2
