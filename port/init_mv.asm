; ------------------------------------------------------------------ moved here: run only at the start
hook_delpc
        ld hl,DELPC : ld de,dl_pat : ld b,14
1       ld a,(de) : cp (hl) : ret nz
        inc hl : inc de : djnz 1B
        ld a,#C3 : ld (DELPC),a : ld hl,zx_delpc : ld (DELPC+1),hl
        ld a,1 : ld (dl_ok),a : ret
dl_pat  db #D5,#11 : dw DLPCB : db #01,#04,#00,#ED,#B0,#D1,#7E,#CB,#7F,#20
find_h  ld a,(gi) : ld h,a : ld l,#FF
        ld a,(gbank) : ld (cur),a
        ld a,h : cp #C0 : jr nc,1F              ; the table is in #4000..#BFFF (banks 5 / 2): mapped now
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a : ld (gh),hl : ret
1       ld hl,#4040 : ld (gh),hl : ret          ; (not expected)
