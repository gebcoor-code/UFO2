; FLIP0.COM / FLIP1.COM: test of the 2nd EGA screen buffer (pages 3+7) under CP/M on ATM Turbo 2+.
; Screen A (pages 1+5) = blue/red stripes, screen B (pages 3+7) = green/yellow stripes; 12 flips via #7FFD bit 3
; (bit 4 = ROM2: 0 in FLIP0, 1 in FLIP1). Page 3 (CP/M itself) is saved to page 20 and restored; interrupts off.
        device zxspectrum128
        org #100
        jp start
m_hi    db "Flip test (#7FFD D4=", '0'+R2, "): 12 flips, then back to CP/M",13,10,"$"
m_mode  db 27,"M0",27,"Z0$"
m_back  db 27,"Z1",27,"M1",13,10,"Flip test done",13,10,"$"
start   ld de,m_hi : ld c,9 : call 5
        ld b,100
1       ei : halt : djnz 1B
        ld de,m_mode : ld c,9 : call 5
        di
        ld (oldsp),sp : ld sp,#3000
        ; page 3 -> page 20 (W3 shows page 3 now; page 20 into W2)
        ld a,20 : call w2 : ld hl,#C000 : ld de,#8000 : ld bc,#4000 : ldir
        ; screen A: pages 1, 5 ; screen B: pages 3, 7
        ld a,1 : call w2 : ld e,#11 : call fill      ; colour 1|2: blue / red
        ld a,5 : call w2 : ld e,#11 : call fill
        ld a,7 : call w2 : ld e,#26 : call fill      ; green / yellow
        ld hl,#C000 : ld de,#C001 : ld bc,#3FFF : ld (hl),#26 : ldir   ; page 3 via W3 (CP/M is gone now)
        ld b,12
2       push bc
        ld a,8+16*R2 : ld bc,#7FFD : out (c),a : call delay
        ld a,0+16*R2 : ld bc,#7FFD : out (c),a : call delay
        pop bc : djnz 2B
        ; page 3 back
        ld a,20 : call w2 : ld hl,#8000 : ld de,#C000 : ld bc,#4000 : ldir
        ld a,2 : call w2
        ld sp,(oldsp)
        ei
        ld de,m_back : ld c,9 : call 5
        rst 0
; A = page -> W2
w2      push bc : ld b,a : ld a,#7F : sub b : ld bc,#BFF7 : out (c),a : pop bc : ret
; fill W2 with E (bytes)
fill    ld hl,#8000 : ld (hl),e : ld de,#8001 : ld bc,#3FFF : ldir : ret
delay   ld de,#6000
1       ex (sp),hl : ex (sp),hl : ex (sp),hl : ex (sp),hl
        dec de : ld a,d : or e : jr nz,1B
        ret
oldsp   dw 0
end
        savebin OUTF,#100,end-#100
