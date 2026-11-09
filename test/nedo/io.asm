        device zxspectrum128
        include "../../port/nedo_h.inc"
        org #100
        ld sp,#4000
        ld hl,0 : NOS CMD_HIDEFROMPARENT
        ld e,6 : NOS CMD_SETGFX
        ld e,7 : NOS CMD_CLS
        ld b,10
1       push bc
        ld bc,#FADF : in a,(c) : call phex
        ld bc,#FBDF : in a,(c) : call phex
        ld bc,#FFDF : in a,(c) : call phex
        ld bc,#001F : in a,(c) : call phex
        ld bc,#FEFE : in a,(c) : call phex
        ld bc,#7FFE : in a,(c) : call phex
        ld bc,#00FE : in a,(c) : call phex
        ld a,13 : NPRCHAR : ld a,10 : NPRCHAR
        ld b,10
2       push bc : NYIELD : pop bc : djnz 2B
        pop bc : djnz 1B
4       NYIELD : NGETKEY : jr nz,4B : or a : jr z,4B
        ld hl,0 : NQUIT
phex    push af : rrca : rrca : rrca : rrca : call 1F : pop af : call 1F : ld a,' ' : NPRCHAR : ret
1       and 15 : add a,'0' : cp '9'+1 : jr c,2F : add a,7
2       NPRCHAR : ret
        savebin "io.com",#100,$-#100
