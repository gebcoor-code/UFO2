; ---- the supervisor's screen in EGA (xlin.asm GUN14: a map 27 x 23 of the location around the fighter into DSCR -
; xMAP's 12 characters, attributes #58 around / #69, the fighter's cell #6A at row 11, column 15 - S_COPY to screen 7,
; then it waits for a key; MX - MPG: far_m): from ico.asm ov_fl's end (the back buffer complete, state B) - each cell found among
; xMAP's pictures (sp_tb: its bytes 1, 3) drawn again in its type's paper / ink (sp_tb) - the cells of the groups
; the step converted (bsync: the slow scan converts again what differs). -> A = 1: the back buffer's cursor off first
; (ov_flb, then again)
SP_HI   equ 14                                  ; (the fighter's cell: its ink)
sp_fl   ld d,0
        WIN P_W1, PG_ZX+7
        ld a,(#5800+29) : cp #58 : jr nz,8F
        ld a,(#5802) : cp #69 : jr nz,8F
        ld a,(#5800+367) : cp #6A : jr nz,8F
        ld hl,bsync : ld b,24 : xor a
0       or (hl) : inc l : djnz 0B
        and #0F : jr z,9F                                           ; (no group of its rows converted again)
        inc d : ld a,(brec) : or a : jr nz,9F : dec d
        ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,1F : ld a,#7F-PS1 : ld e,#7F-PS5
1       push af : ld a,e : ld bc,P_W2 : out (c),a
        ld a,1 : call sp_ps                                         ; pairs 1, 3 (W2: their page)
        pop af : ld bc,P_W2 : out (c),a
        xor a : call sp_ps                                          ; pairs 0, 2
        ld d,0 : jr 9F
8
9       ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,91F : ld a,#7F-PS1 : ld e,#7F-PS5
91      ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a     ; (W1, W2: the back buffer)
        ld a,d : ret
; A = 1: pairs 1, 3 of each cell (its bits 5, 4 / 1, 0), 0: pairs 0, 2 (7, 6 / 3, 2); W2: their page (its parts 2, 3 /
; 0, 1: +0, +#2000 - as mkico.py's ega()), W1: screen 7
sp_ps   ld (sp_sh),a : ld hl,#8000 + 4 * 40 : ld (sp_dr),hl : ld c,0
1       ld a,c : add a,low bsync : ld l,a : ld h,high bsync : ld a,(hl) : ld (sp_g),a    ; (the row's groups converted)
        ld b,2
2       push bc
        ld a,b : rrca : rrca : rrca : and 3 : ld e,a : ld a,(sp_g) : inc e
21      dec e : jr z,22F : rrca : jr 21B
22      rrca : jp nc,8F                                             ; (its group: as it is)
        ld a,c : and #18 : or #40 : ld h,a : ld a,c : rrca : rrca : rrca : and #E0 : or b : ld l,a  ; (its line 0)
        push hl
        inc h : ld e,(hl) : inc h : inc h : ld d,(hl)
        ld hl,sp_tb : ld b,SP_N
3       ld a,(hl) : inc hl : cp e : jr nz,4F : ld a,(hl) : cp d : jr z,5F
4       inc hl : inc hl : inc hl : djnz 3B
        pop hl : jp 8F                                              ; (none of them: as converted)
5       inc hl : ld e,(hl) : inc hl : ld d,(hl)                     ; E = paper, D = ink
        pop hl : push hl : ld a,h : rrca : rrca : rrca : and 3 : or #58 : ld h,a
        ld a,(hl) : cp #6A : jr nz,6F : ld d,SP_HI                  ; (the fighter's cell)
6       ld a,e : call sp_l : ld b,a : ld a,d : call sp_l : ld c,a   ; B, C: the left pixel's bits - paper, ink
        ld a,e : add a,16 : call sp_l : push af : ld a,d : add a,16 : call sp_l      ; (the right one's)
        ld hl,sp_cb+3 : ld e,a : or c : ld (hl),a : dec l : pop af : ld d,a : or c : ld (hl),a : dec l
        ld a,e : or b : ld (hl),a : dec l : ld a,d : or b : ld (hl),a
        pop hl : pop bc : push bc
        push hl : ld hl,(sp_dr) : ld a,b : add a,l : ld l,a : jr nc,$+3 : inc h : ex de,hl : pop hl
        ld b,8
7       ld a,(sp_sh) : or a : ld a,(hl) : jr z,71F : rlca : rlca
71      ld c,a : push hl
        rlca : rlca : and 3 : or low sp_cb : ld l,a : ld h,high sp_cb : ld a,(hl) : ld (de),a     ; (pair 0 / 1: part 0 / 2)
        ld a,c : rrca : rrca : and 3 : or low sp_cb : ld l,a : ld a,(hl)                         ; (pair 2 / 3: part 1 / 3)
        set 5,d : ld (de),a : res 5,d
        pop hl : inc h
        ld a,e : add a,40 : ld e,a : jr nc,72F : inc d
72      djnz 7B
8       pop bc : inc b : ld a,b : cp 30 : jp c,2B
        ld hl,(sp_dr) : ld de,320 : add hl,de : ld (sp_dr),hl
        inc c : ld a,c : cp 24 : jp c,1B
        ret
sp_l    push hl : ld hl,sp_el : add a,l : ld l,a : jr nc,$+3 : inc h : ld a,(hl) : pop hl : ret
; per xMAP's character: its bytes 1, 3; paper, ink (columns 2..29, rows 0..23: the map and its frame)
sp_tb   db #18,#46, 1,12        ; ours
        db #18,#7E, 1,7         ; ours dead
        db #FF,#FF, 0,0         ; rock
        db #81,#BD, 0,7         ; a wall
        db #81,#81, 1,9         ; floor
        db #00,#00, 1,1         ; open
        db #95,#95, 1,14        ; a ladder
        db #81,#FF, 1,14        ; a ladder
        db #81,#A1, 1,15        ; a lift
        db #81,#A5, 1,6         ; a door
        db #99,#46, 1,10        ; an alien
        db #DB,#7E, 1,2         ; an alien dead
        db #BF,#BF, 7,0         ; (the frame's lines - XOR on the #58 around: right, bottom)
        db #FF,#BF, 7,0
        db #00,#FF, 7,0
        db #C0,#FF, 7,0
        db #3F,#FF, 7,0
SP_N    equ ($-sp_tb)/4
sp_el   db #00,#01,#02,#03,#04,#05,#06,#07,#40,#41,#42,#43,#44,#45,#46,#47     ; (as enc.asm ep_el, ep_er: a slot's
        db #00,#08,#10,#18,#20,#28,#30,#38,#80,#88,#90,#98,#A0,#A8,#B0,#B8     ;  EGA bits, left pixel / right one)
        ALIGN 4
sp_cb   ds 4                                    ; a cell's 4 bytes of a pair: paper / ink left, right
        ASSERT high sp_cb == high (sp_cb+3)
sp_g    db 0
sp_sh   db 0
sp_dr   dw 0
