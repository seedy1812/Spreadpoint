
        seg     CODE_SEG

NUM_BOBS equ 20


outer_8 equ 18
outer_5 equ 14

inner_8 equ 14
inner_5 equ 10

// not signed
mul_hl_de:       ; (uint16)HL = (uint16)HL x (uint16)DE
    ld      c,e
    ; HxD xh*yh is not relevant for 16b result at all
    ld      e,l
    mul             ; LxD xl*yh
    ld      a,e     ; part of r:8:15
    ld      e,c
    ld      d,h
    mul             ; HxC xh*yl
    add     a,e     ; second part of r:8:15
    ld      e,c
    ld      d,l
    mul             ; LxC xl*yl (E = r:0:7)
    add     a,d     ; third/last part of r:8:15
    ; result in AE (16 lower bits), put it to HL
    ld      h,a
    ld      l,e
    ret             ; =4+4+8+4+4+4+8+4+4+4+8+4+4+4+10 = 78T



A_COL8 BALL_COL0,$00,$00,$00
A_COL8 BALL_COL1,$00,$60,$00
A_COL8 BALL_COL2,$22,$cc,$66
A_COL8 BALL_COL3,$00,$aa,$44

ball_sprite_image: incbin "ball.nxi"
 

ball_load_sprite:
    ld hl,ball_sprite_image
    ld bc, $303b

    xor a
    out (c),a ; start at pattern 0

    ld bc,$005b + (16*16/2)*256

    otir ;; send 256 bytes to port 0x5b

    ;; now to set the palette

    nextreg $43,%00100001

    nextreg $40,0           ; palette index

    nextreg $4b,0            ; sprites transpanecy index

    nextreg $41,BALL_COL0           ; 0 is transparent
    nextreg $41,BALL_COL1           ; 0 is transparent
    nextreg $41,BALL_COL2           ; 0 is transparent
    nextreg $41,BALL_COL3           ; 0 is transparent
    ret


draw_balls:
       ld bc, $303b

       xor a
       out (c),a ; start at pattern 0

       ld ix , posn
       ld b,NUM_BOBS
.loop:
       push bc
       ld d,(ix+0)          ;; de = x
       ld e,(ix+1)

       ld h,(ix+2)          ; hl = y
       ld l,(ix+3)

       ld c,$57
       out (c),e  ; x:lo
       out (c),l ; y: lo 

       ld a,1
       and d
       ; no rotation, v or H mirroring , plaette offset = 0
       out (c),a   ; bit 0 msb:x

       ld a,$80
       or %01000000 ;attrib 4 boing used
       out (c),a   ; visible+ sprite_vpattern - 

       ld a,1        ; msb y
       and h
       or $80        ;4 bit pattern
       out (c),a

       pop bc
       ld de,4
       add ix,de
       djnz .loop
       ret


calc_balls:
    border 1

    ld ix , posn
    ld a,0

    ld hl,(iteration5)
    add hl,outer_5
    ld (iteration5),hl
    ld (iteration5_current),hl

    ld hl,(iteration8)
    add hl,outer_8
    ld (iteration8),hl
    ld (iteration8_current),hl

    ld b,NUM_BOBS
.loop
    push bc
    ld hl ,(iteration5_current)
    call get_sin_hl_to_de

    ld hl,128-8
    call mul_hl_de

    ld l,h    
    ld a,h
    add a,a
    sbc a,a
    ld h,a

    add hl, 128+32-8

    ld (ix+0),h
    ld (ix+1),l

    ld hl,(iteration8_current)
    call get_sin_hl_to_de

    ld hl,50
    call mul_hl_de

    ld l,h    
    ld a,h
    add a,a
    sbc a,a
    ld h,a

    add hl, 50+32

    ld (ix+2),h
    ld (ix+3),l

    ld hl ,(iteration5_current)
    add hl,Inner_5
    ld (iteration5_current),hl

    ld hl ,(iteration8_current)
    add hl,Inner_8
    ld (iteration8_current),hl

    ld de,4
    add ix,de

    pop bc
    djnz .loop

    border 0

    ret



get_cos_hl_to_de
    add hl,512/4
get_sin_hl_to_de
    ld a,h
    and 1   ; sine table of 512 entries 0 -> 1ff
    ld h,a
    add hl,hl
    add hl,sine_table

    ld a,bank(sine_table)
    nextreg MMU_7,a

    ld e,(hl)
    inc hl
    ld d,(hl)
    ret

iteration5_current: dw 0
iteration8_current: dw 0
iteration5: dw 10
iteration8: dw 0

posn :  ds NUM_BOBS*2*2     ;; 16 bit * 20 bobs *2(x,y)

        seg SINE_SEG
sine_table:
        include "sine.s"
sine_table_end:
        seg CODE_SEG
