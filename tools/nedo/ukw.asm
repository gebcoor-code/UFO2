; the task's low page as the NedoOS kernel (Evo) builds it: userkrnl.asm with its constants
        device zxspectrum128
memport4000=0x77f7
memport8000=0xb7f7
memportc000=0xf7f7
pagexor=0xff
pgkillable=pagexor-4
fd_system=0x57
        org 0
        include "userkrnl.asm"
        savebin "ulow.bin",0,#80
        display "init_resident=",init_resident
