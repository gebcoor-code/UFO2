        device zxspectrum128
        include "../../port/nedo_h.inc"
        org #100
        ld sp,#4000
        ld hl,0 : NOS CMD_HIDEFROMPARENT
        ld e,6 : NOS CMD_SETGFX
        ld e,7 : NOS CMD_CLS
        NOS CMD_GETMAINPAGES : push hl : push de
        pop hl : call phl : pop hl : call phl
        ld a,(user_scr0_low) : call phex : ld a,(user_scr0_high) : call phex
        ld a,(user_scr1_low) : call phex : ld a,(user_scr1_high) : call phex
        ld a,13 : NPRCHAR : ld a,10 : NPRCHAR
        ld hl,buf
1       push hl : NOS CMD_NEWPAGE : pop hl
        or a : jr nz,2F
        ld (hl),e : inc hl : jr 1B
2       ld (end),hl
        ld hl,buf
3       ld de,(end) : or a : sbc hl,de : add hl,de : jr z,4F
        ld a,(hl) : push hl : call phex : pop hl : inc hl : jr 3B
4       NYIELD : NGETKEY : jr nz,4B : or a : jr z,4B
        ld hl,0 : NQUIT
phl     ld a,h : push hl : call phex : pop hl : ld a,l
phex    push af : rrca : rrca : rrca : rrca : call 1F : pop af : call 1F : ld a,' ' : NPRCHAR : ret
1       and 15 : add a,'0' : cp '9'+1 : jr c,2F : add a,7
2       NPRCHAR : ret
end     dw 0
buf
        savebin "probe.com",#100,$-#100
