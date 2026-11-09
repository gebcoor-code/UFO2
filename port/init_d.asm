; ---- UFO2.DAT's drive (A:..D:) - at the start, before the LUT is made (so past init_mv_end: in the LUT's place)
d_try   db 0,2,1,3,4,#FF
d_cur   db 0
d_open
        IFDEF NEDOOS                            ; (the current directory: NC's - the game's folder)
        xor a : ld (dfcb),a
        ld hl,dfcb+12 : ld b,24
5       ld (hl),0 : inc hl : djnz 5B
        ld de,dfcb : ld c,15 : call BDOS
        inc a : ret z                           ; (CY = 0)
        ld a,1 : ld (d_ok),a : scf : ret
        ENDIF
        ld c,25 : call BDOS : ld (d_cur),a
        ld hl,(1) : ld de,24 : add hl,de : ld (.sel+1),hl : ld (.sl2+1),hl
        ld hl,d_try
1       ld a,(hl) : cp #FF : ret z                      ; (CY = 0)
        inc hl : push hl
        ld (dfcb),a : or a : jr z,3F
        dec a : ld c,a : ld a,(d_cur) : cp c : jr z,2F   ; the current one: tried already
        ld e,0
.sel    call 0
        push hl
        ld a,(d_cur) : ld c,a : ld e,1
.sl2    call 0                                          ; CP/M's drive selected again
        pop hl
        ld a,h : or l : jr z,2F
3       ld hl,dfcb+12 : ld b,24
4       ld (hl),0 : inc hl : djnz 4B
        ld de,dfcb : ld c,15 : call BDOS
        inc a : jr z,2F
        pop hl : ld a,1 : ld (d_ok),a : scf : ret
2       pop hl : jr 1B
