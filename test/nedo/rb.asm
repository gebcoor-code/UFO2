        device zxspectrum128
        include "../../port/nedo_h.inc"
        org #100
        ld sp,#4000
        ld hl,0 : NOS CMD_HIDEFROMPARENT
        ld e,6 : NOS CMD_SETGFX
        ld e,7 : NOS CMD_CLS
        NOS CMD_GETMAINPAGES : push hl : push de
        pop hl : call phl : pop hl : call phl
        ld a,13 : NPRCHAR : ld a,10 : NPRCHAR
        ld a,(curpgc000) : ld (sv),a
        di
        ld bc,#F7F7 : ld a,#5A : out (c),a     ; W3 = #5A (no curpg: DI)
        ld b,#B7 : ld a,#61 : out (c),a        ; W2 = #61
        ld hl,buf : ld b,0 : ld c,#BE
1       in a,(c) : ld (hl),a : inc hl : inc b : ld a,b : cp 32 : jr nz,1B
        ld a,(sv) : ld bc,#F7F7 : out (c),a
        ld a,(curpg8000) : ld b,#B7 : out (c),a
        ei
        ld hl,buf : ld b,32
2       ld a,(hl) : push hl : push bc : call phex : pop bc : pop hl : inc hl : djnz 2B
4       NYIELD : NGETKEY : jr nz,4B : or a : jr z,4B
        ld hl,0 : NQUIT
phl     ld a,h : push hl : call phex : pop hl : ld a,l
phex    push af : rrca : rrca : rrca : rrca : call 1F : pop af : call 1F : ld a,' ' : NPRCHAR : ret
1       and 15 : add a,'0' : cp '9'+1 : jr c,2F : add a,7
2       NPRCHAR : ret
sv      db 0
buf     ds 32
        savebin "rb.com",#100,$-#100
