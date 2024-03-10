
   seg     TCB_1_SEG

tcb_logos:	incbin "logo_pagepdn.nxi"

    seg     CODE_SEG

tcb_log_pal: incbin "logo_pagepdn.nxp"

tcb_sine:   
            include "tcb_sine.s"
tcb_sine_end:


logo_ang_current:   dw 0
logo_ang_pos:       dw tcb_sine
logo_offset:        db 0
logo_frame:         db 0


LOGO_X:  equ        128

logo_sheet_xy:  db 0,0,64,20
                db 128,0,64,20

                db 0,40,64,20
                db 128,40,64,20

                db 0,80,64,20
                db 128,80,64,20

                db 0,120,64,20
                db 128,120,64,20

logo_update:
    ld hl,(logo_ang_pos)

    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld (logo_ang_current),de

    or a
    ld de,tcb_sine_end
    sbc hl,de
    add hl,de

    jr nz, .no_ang_wrap

    ld hl,tcb_sine
.no_ang_wrap:
    ld (logo_ang_pos),hl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld hl,(logo_ang_current)

    call get_sin_hl_to_de

    ld hl,25
    call mul_hl_de

    ld l,h    
    ld a,h
    add a,a
    sbc a,a
    ld h,a

    add hl,50

    ld a,l
    ld (logo_offset),a

;;;;;;;;;;;;;;;


    ld hl,(logo_ang_current)
    call get_cos_hl_to_de

    add de,256    ; now to 0 to 2

    ld hl,2         ; 0 to 4
    call mul_hl_de

    ld a, 4
    sub h
    cp 4
    jr nz,.valid
    dec a
.valid:
    ld (logo_frame),a

    nextreg 14,$ff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  my_break
    ld a,(logo_frame)

    ld ix ,logo_sheet_xy

    ld d,4
    ld e,a
    mul
    add ix,de

; set clipping around the logo

    ld b,(ix+2)               ; get half width
    ld a,LOGO_X
    sub b
    nextreg $18,a           ; set min clip x
    ld d, a
    add a,b
    add a,b                 ; add 2*half with
    dec a                   ; minus 1
    nextreg $18,a           ; set max clip x


    ld b,(ix+3)               ; get half height
    ld a,(logo_offset)      ; screen y
    sub b
    ld e,a
    nextreg $18,a           ; set min clip y
    add a,b
    add a,b                 ; add 2 *half height
    dec a                   ; minus 1
    nextreg $18,a           ; set max clip y

; de = min clip x,y

    ld a,(ix+0)           ; location on sprite sheet - clip min x
    sub  d
    nextreg $16,a

    ld a,(ix+1)           ; location on sprite sheet - clip min y
    sub e
    jr nc,.no_wrap      ; adjust as layer 2 if 0 to 191 not 0 to 255
    add a,192
.no_wrap:
    nextreg $17 ,a

    ret
 


logo_setup:
    nextreg $43,%00010001   ; set palette layer 2 pal 0

    nextreg $40,0           ; palette index
    ld hl,tcb_log_pal

    ld b,16
.lp:
    ld a,(hl)
    inc hl
    nextreg $41,a           ; 0 is transparent
    djnz    .lp

    ret




