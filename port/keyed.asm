; ------------------------------------------------------------------ UPG #EEB0 (past the screen-7 copies): a panel
; rectangle's line (pn_rc): HL = the picture (W1), DE = the buffer (W2), pn_n bytes, as pn_md says (keyed: the
; picture's colour 8 lets the buffer's pixel stay)
pn_cp   ld a,(pn_md) : or a : jp z,pn_ent
        cp 2 : jr z,2F
        push af : call kb : pop af : cp 1 : jp z,pn_ent     ; 1: the first keyed (pn_ent: n - 1 there)
        ld a,(pn_n) : cp 2 : ret c
        call pn_ent : jp kb                     ; 3: and the last (pn_ent: n - 2)
2       ld a,(pn_n) : ld (pn_k),a
3       call kb : ld a,(pn_k) : dec a : ld (pn_k),a : jr nz,3B
        ret

; OUTDSC's conversion (od_conv): sh_go = 1, but while scrolling (a shift pending at each OUTDSC) every other one is
; skipped: the game scrolls on, the next one moves the picture by both steps at once (half the moves and flips)
; v56: off (the user: steps of 16 points too jerky) - every step shown, sk_c = 1 keeps sk_pol quiet
sk_go   ld a,1 : ld (sk_c),a : ld (sh_go),a : ret
sk_c    db 1
; the back buffer's cursor off (ico.asm's overlays drawn into it then)
ep_hidb call swaprec : ld a,(bf) : xor 1 : call ep_mb : call ep_ch : jp swaprec
