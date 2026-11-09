; ------------------------------------------------------------------ UFO2.DAT in RAM
; Read once at the start (BDOS 20, while CP/M is surely fine); in the game D_READ / D_WRITE copy sectors from / to
; RAM pages without calling CP/M (BDOS during the game hung on the real machine: RD44).
; Kept: tracks 4, 5 (saved game, table) and 55..127 (data) = 75 tracks = 19 pages (4 tracks a page):
;   li = 0 (track 4), 1 (track 5), track - 53 (55..127);  page = dpages[li / 4], offset (li & 3) * #1000 + (sec - 1) * 256
; Pages 32..50 (1024K only).
; A saved game (D_WRITE, track 4) goes to RAM; on exit to CP/M it is written to UFO2.DAT (records 128..191).
NPG     equ 19
d_ram   db 0
mem1m   db 0                    ; 1: 1M of RAM
d_dirty db 0
cpm_i   db #F9                  ; CP/M's I at the start
cpm_im1 db 0                    ; 1: CP/M runs in IM 1 (im_det)
d_qt    db 0                    ; frames since the last write of a saved game (d_chk)
dpages  ds NPG

; A = track -> A = li; CY: not kept
d_li    cp 4 : jr z,1F
        cp 5 : jr z,2F
        cp 55 : ret c
        cp 128 : ccf : ret c
        sub 53 : ret
1       xor a : ret
2       ld a,1 : or a : ret

; A = page -> W2 (port value #7F - page)
map_w2  push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W2 : out (c),a : pop bc : ret

; one sector (d_de, d_hl, d_op) from / to RAM; game's windows, DI
ram_sec ld a,(d_de+1) : call d_li : jp c,.none
        ld c,a : srl a : srl a : ld e,a : ld d,0 : ld hl,dpages : add hl,de : ld a,(hl) : ld (rs_pg),a
        ld a,c : and 3 : rlca : rlca : rlca : rlca : ld b,a
        ld a,(d_de) : dec a : and 15 : or b : ld (rs_hi),a
        ld a,(d_hl+1) : and #C0 : cp #80 : jr z,.w1
        ld a,(rs_pg) : call map_w2
        ld a,(rs_hi) : or #80 : ld h,a : ld l,0
        call .copy
        WIN P_W2, PG_ZX+2
        ret
.w1     ld a,(rs_pg) : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a
        ld a,(rs_hi) : or #40 : ld h,a : ld l,0
        call .copy
        WIN P_W1, PG_ZX+5
        ret
.copy   ld de,(d_hl) : ld bc,256
        ld a,(d_op) : cp 33 : jr z,1F
        ex de,hl : ld a,(d_de+1) : cp 6 : jr nc,1F : ld a,1 : ld (d_dirty),a : xor a : ld (d_qt),a
1       ldir : ret
.none   ld a,(d_op) : cp 33 : ret nz
        ld hl,(d_hl) : ld d,h : ld e,l : inc de : ld (hl),0 : ld bc,255 : ldir : ret
rs_pg   db 0
rs_hi   db 0

; on exit (CP/M's windows, interrupts on): the saved game (tracks 4, 5 = page dpages[0], #0000..#1FFF) -> UFO2.DAT
