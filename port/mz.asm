; ---- packed files (UFO2.SPR, .ICO, .TIL, .IMG - build/mkico.py pk(): "PK", then per 4096 bytes of the file as it was
; its length - bit 15: stored as is - and its LZ (enc.asm ep_lz's format); 0: the end). mz_rd / mz_more as mf_rd /
; mf_more (HL = the name; DE, B records of the file as it was -> CY, B: the records not there): a segment read into
; (mz_b) * 256 and unpacked past it (+ #1000) - page 2 in W2 (the COM's images' place: img_out copied them out)
mz_rd   push de : push bc
        ld de,ibuf : ld b,1 : call mf_rd : jp nc,9F
        ld hl,(ibuf) : ld de,"KP" : or a : sbc hl,de : jp nz,9F       ; (not packed - an older file: none)
        ld hl,ibuf+2 : ld (mz_p),hl : ld a,126 : ld (mz_n),a
        ld hl,0 : ld (mz_l),hl
        pop bc : pop de
mz_more ld (mz_o),de : ld l,0 : ld h,b : srl h : rr l : ld (mz_w),hl  ; (B * 128 bytes)
1       ld hl,(mz_w) : ld a,h : or l : jr z,8F
        ld hl,(mz_l) : ld a,h : or l : jr nz,2F
        ld a,(mz_w+1) : cp #10 : jr c,11F                               ; (a whole segment wanted: straight into place)
        ld hl,(mz_o) : call mz_seg : jr c,7F
        ld hl,(mz_o) : ld bc,(mz_l) : add hl,bc : ld (mz_o),hl
        ld hl,(mz_w) : or a : sbc hl,bc : ld (mz_w),hl : ld hl,0 : ld (mz_l),hl : jr 1B
11      ld a,(mz_b) : add a,#10 : ld h,a : ld l,0 : call mz_seg : jr c,7F
2       ld hl,(mz_l) : ld bc,(mz_w) : or a : sbc hl,bc : jr nc,3F      ; BC = min (left in the segment, wanted)
        add hl,bc : ld b,h : ld c,l
3       ld hl,(mz_l) : or a : sbc hl,bc : ld (mz_l),hl
        ld hl,(mz_w) : or a : sbc hl,bc : ld (mz_w),hl
        ld hl,(mz_q) : ld de,(mz_o) : ldir : ld (mz_q),hl : ld (mz_o),de
        jr 1B
7       ld hl,(mz_w) : ld bc,127 : add hl,bc : add hl,hl : ld b,h : scf : ret   ; (the end: B = the records not there)
8       ld b,0 : scf : ret
9       pop bc : pop de : or a : ret
; the next segment -> HL (mz_q), its length (mz_l); CY: none (the end)
mz_seg  ld (mz_q),hl : ld hl,mz_t : ld bc,2 : call mz_rb : ret c
        ld bc,(mz_t) : ld a,b : or c : scf : ret z
        ld hl,(mz_q)
        bit 7,b : jr z,1F
        res 7,b : ld (mz_l),bc : jr mz_rb                               ; (stored as is)
1       ld a,(mz_b) : ld h,a : ld l,0 : call mz_rb : ret c
        ld a,(mz_b) : ld h,a : ld l,0 : ld de,(mz_q) : call mz_lz
        ld hl,(mz_q) : ex de,hl : or a : sbc hl,de : ld (mz_l),hl : or a : ret
; BC bytes of the file -> HL; CY: the file's end
mz_rb   ld (mz_d),hl : ld (mz_c),bc
1       ld bc,(mz_c) : ld a,b : or c : ret z
        ld a,(mz_n) : or a : jr nz,2F
        ld a,b : or a : jr nz,4F : ld a,c : cp 128 : jr c,5F             ; (a whole record wanted: straight into place)
4       ld de,(mz_d) : ld c,26 : call BDOS : ld de,mfcb : ld c,20 : call BDOS
        or a : scf : ret nz
        ld hl,(mz_d) : ld bc,128 : add hl,bc : ld (mz_d),hl
        ld hl,(mz_c) : or a : sbc hl,bc : ld (mz_c),hl : jr 1B
5        ld de,ibuf : ld c,26 : call BDOS : ld de,mfcb : ld c,20 : call BDOS
        or a : scf : ret nz
        ld hl,ibuf : ld (mz_p),hl : ld a,128 : ld (mz_n),a : ld bc,(mz_c)
2       ld e,a : ld d,0 : ld a,b : or a : jr nz,3F : ld a,c : cp e : jr nc,3F : ld e,c     ; DE = min (BC, mz_n)
3       ld a,(mz_n) : sub e : ld (mz_n),a
        ld hl,(mz_c) : or a : sbc hl,de : ld (mz_c),hl
        ld b,d : ld c,e : ld hl,(mz_p) : ld de,(mz_d) : ldir : ld (mz_p),hl : ld (mz_d),de
        jp 1B
; LZ: HL -> DE (enc.asm ep_lz's format; the bit buffer in A - a marker bit past the bits left - as ZX0's decoders)
MZBIT   MACRO
        add a,a : jr nz,$+5 : ld a,(hl) : inc hl : rla
        ENDM
mz_lz   ld a,#80 : ld bc,1 : ld (mz_of),bc
1       MZBIT : jr c,3F                                                 ; (after a match / at the start: 0 literals)
        call 7F : ldir
        MZBIT : jr c,3F                                                 ; (after literals: 0 the last offset)
        call 7F : inc bc : jr 4F
3       call 7F : inc b : dec b : ret nz                                ; (256: the end)
        dec c : ld b,c : ld c,(hl) : inc hl : inc bc : ld (mz_of),bc
        call 7F : inc bc
4       push hl : ld h,d : ld l,e : push bc : ld bc,(mz_of) : or a : sbc hl,bc : pop bc : ldir : pop hl
        jr 1B
7       ld bc,1                                                         ; (a number: 1, then per "0, bit" a bit more)
71      MZBIT : ret c
        MZBIT : rl c : rl b : jr 71B
mz_b    db #80
mz_of   dw 0
mz_n    db 0
mz_p    dw 0
mz_l    dw 0
mz_q    dw 0
mz_w    dw 0
mz_o    dw 0
mz_c    dw 0
mz_d    dw 0
mz_t    dw 0
