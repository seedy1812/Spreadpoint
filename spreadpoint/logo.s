
   seg     TCB_1_SEG

tcb_logos:	incbin "logo_pagepdn.nxi"

    seg     CODE_SEG

tcb_log_pal: incbin "logo_pagepdn.nxp"

logo_x1 db 0
logo_y1 db 0

logo_x: db 0
logo_y: db 0


offsets: db $64,$3c,$14,$ac


dy: db $82

logo_dir: db 1
logo_offset: db 16
logo_frame: db 6

logo_update:
    ld a,(logo_frame)
    inc a
    ld (logo_frame),a



    ld a,(logo_dir)
    or a
    ld a,(logo_offset)
    jr z,.down
.up:
    dec a
    ld (logo_offset),a
    jr nz,.done
    jr .flip
.down:
    inc a
    ld (logo_offset),a
    cp 32
    jr nz,.done
.flip:  
    ld a,(logo_dir)
    xor 1
    ld  (logo_dir),a
.done:

    ld a,(logo_frame)
    swapnib
    and 7

    ld d,a
    ld e,0
    sra d
    ccf
    rr e
    ld a,(logo_x1)
    add a,e
    nextreg $16,a

  ; ld a,0
  ;  ld (logo_offset),a

    ld a,(logo_offset)
    ld e,a

    ld hl,offsets
    ld a,d
    add hl,a
    ld a,(hl)
    neg
    sub e


    nextreg $17,a

    ld a,(logo_x1)
    nextreg $18,a
    add 128-1
    nextreg $18,a

    ld a,(logo_y1)
    ld b,a
    ld a,(logo_offset)
    add a,b
   nextreg $18,a
    add 40-1
   nextreg $18,a

    ret
 


logo_setup:
    ld a, 64
    ld (logo_x1),a

    ld a,$24

    ld (logo_y1),a

    ld a,0
    ld (logo_dir),a
    ld (logo_offset),a
    
    call logo_update

;    nextreg $14,$ff  ;  wrong

    nextreg $43,%00010001   ; set paleet layer 2 pal 0

    nextreg $40,0           ; palette index
    ld hl,tcb_log_pal

    ld b,16
.lp:
    ld a,(hl)
    inc hl
    nextreg $41,a           ; 0 is transparent
    djnz    .lp

    ld a,0

    or %0011      ; shadow layer2 , is visible and layer 2 write paging

    ld bc, $123b   
	out (c), a

    ret



