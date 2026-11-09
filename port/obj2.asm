; ---- obj.asm's second part (in UFO2.COM: zxl.asm img_out copies it past mk_sv; obj.asm itself - UFO2.DAT's MX block)
; (more of it: past mk_sv, not zeroed)
obj2_img
        DISP mk_sv+64
; (m_fmw) H = 0..45: H * 256 = 44 line + rest: line, rest
m_lt
.h = 0
        DUP 46
        db ((256*.h)/44) & 255, (256*.h)%44
.h = .h + 1
        EDUP
fm_lm   db 0,1,3,7,15,31,63,127,255
t352
.h = 0
        DUP 34
        dw 352*.h
.h = .h + 1
        EDUP
        ASSERT $ <= #10000
        ENT
obj2_img_end
