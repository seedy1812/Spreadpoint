    seg     CODE_SEG

SHIFT_BY_PIXEL equ 1            ; either scroll by letter or by pixel

dna_line: db 0                  ; y coloumn to draw down
dna_pixels_left: db 0           ; how many pixels left in letter
dna_scroll_pos: dw dna_font_ptr ; letter in scroller
dna_font_ptr: dw 0              ; current letter address
dna_y_offset: db 0
dna_rotate: db 0                ; offset to add to table to simulate rotate

zerobuffer: ds 64

letter_lookup:                  ; ascii to font table
        ds 32
        db  0, 1, 2, 0, 0, 0, 0, 3, 4, 5
        db  0, 0, 6, 7, 8, 0, 9,10,11,12
        db 13,14,15,16,17,18,19,20, 0, 0
        db  0,21, 0,22,23,24,25,26,27,28
        db 29,30,31,32,33,34,35,36,37,38
        db 39,40,41,42,43,44,45,46,47

dna_writes:
        dw dna_y_offset01,dna_y_offset02,dna_y_offset03,dna_y_offset04,dna_y_offset05,dna_y_offset06,dna_y_offset07,dna_y_offset08,dna_y_offset09,dna_y_offset10
        dw dna_y_offset11,dna_y_offset12,dna_y_offset13,dna_y_offset14,dna_y_offset15,dna_y_offset16,dna_y_offset17,dna_y_offset18,dna_y_offset19,dna_y_offset20
        dw dna_y_offset21,dna_y_offset22,dna_y_offset23,dna_y_offset24,dna_y_offset25,dna_y_offset26,dna_y_offset27,dna_y_offset28,dna_y_offset29,dna_y_offset30
        dw dna_y_offset31,dna_y_offset32,dna_y_offset33,dna_y_offset34,dna_y_offset35,dna_y_offset36,dna_y_offset37,dna_y_offset38,dna_y_offset39,dna_y_offset40
        dw dna_y_offset41,dna_y_offset42,dna_y_offset43,dna_y_offset44,dna_y_offset45,dna_y_offset46,dna_y_offset47,dna_y_offset48,dna_y_offset49,dna_y_offset50

dna_pos:    
        db  0,  6,  8, 10, 12, 13, 14, 16, 17, 18
        db 19, 20, 21, 22, 23, 24, 25, 25, 26, 27
        db 28, 29, 30, 31, 31, 32, 32, 33, 34, 35
        db 36, 37, 37, 38, 39, 40, 41, 42, 43, 44
        db 45, 46, 47, 49, 50, 51, 53, 55, 57, 63
dna_pos_end:


dma_palette:
        incbin "sa.nxp"        

dna_scroll_start:
        db "YO, SUCKERS!!!  THIS IS THE SPREADPOINT DEMO!   ALL CODING WAS DONE BY THE "
        db "CAREBEARS,  ALL GRAPHIXX WAS DESIGNED BY THE CAREBEARS AND THE MUZEXX WAS ALSO "
        db "'EINGEPLUPPED' BY THE CAREBEARS!  WE SAW THE ORIGINAL SPREADPOINT DEMO, BY "
        db "SPREADPOINT, ON THE NO-CREW-COPY-PARTY.  ON THE TRAIN HOME, WE DISCUSSED HOW TO "
        db "CONVERT IT TO THE ST.  WE DECIDED TO USE THIS DIGISHIT-ROUT, EVEN THOUGH IT TAKES "
        db "SOME PROCESSOR TIME. ON AN ST, DIGISOUND RESULTS IN LESS GRAPHICAL MOVEMENT, BUT "
        db "WE THINK THERE'S ENOUGH MOVEMENT ON THIS SCREEN, DON'T YOU? (DON'T ANSWER IF "
        db "YOU DON'T!) YOUR EYES ARE PROBABLY STARTING TO ACHE, SO LET'S WRAP. THE UNION "
        db "RULES.      ",0

dna_init:
    ld a, bank(tcb_logos)
    srl a
    ld (layer_2_front),a
    nextreg LAYER2_RAM_BANK,a


    ld a, bank(tcb_logos)
    add 12
    srl a
    ld (layer_2_back),a
    nextreg LAYER2_SHADOW_BANK,a

if 1
    Call Layer2cls
else
    ld a,%10000111
    ld bc, $123b   
	out (c), a
endif

    nextreg $43,%01010001   ; set paleet layer 2 pal 0

    nextreg $40,0           ; palette index
    ld hl,dma_palette

    ld b,16
.lp:
    ld a,(hl)
    inc hl
    nextreg $41,a           ; 0 is transparent
    djnz    .lp

    ret

Layer2cls:
    ld a,%10001111      ; first 16
    ld bc, $123b   
	out (c), a
    ld a,0
    call cls

    ret

cls:
    ld hl,0
    ld de,1
    ld bc,16*1024-1
    ld (hl),a
    ldir
    ret

dna_copper:
    ld ix,dna_writes        ; pointer to address to se the scrollery in coppet
    ld c,0                  ; y in the scroller 0 ->N
    ld a,(dna_rotate)       ; step round the scroller Y
    inc a
    and 63
    ld (dna_rotate),a
    ld iyl,a                ; store this here
    
    ld b, dna_pos_end - dna_pos ; for all the lines in the scroller
    ld de,dna_pos               ; these are the default Y values
.loop:
    ld a,(de)                   ; read the Y line to draw - default
    add a,iyl                   ; add on the rotation
    and 63                      ; only 64 lines in image  0->63 
    sub c                       ; find delta offset to shift Layer 2 by

    jr nc,.flip                 ; if negative we have to adjust as the values are 0 ->192 not 0->255
    sub 64
.flip:
    add 3                       ; shift scroller down screen to look like original

    ld l,(ix+0)                 ; read the copper address we will set the laer 2 dY
    ld h,(ix+1)

    ld (hl),a                   ; write it

    inc de                     ; point to the next line data
    inc ix
    inc ix
    inc c
    djnz .loop                 ; do all the lines
    ret


dna_test:
    ld a,(dna_pixels_left)
    or a
    jr nz,.same_letter
    ld a,32
    ld (dna_pixels_left),a

    ld hl, (dna_scroll_pos)
    inc hl
    ld a,(hl)
    or a
    jr nz,.not_end
    ld hl, dna_scroll_start
.not_end:
    ld (dna_scroll_pos),hl

    ld a,(hl)
    ld hl,letter_lookup
    add hl,a
    ld a,(hl)


if  1-SHIFT_BY_PIXEL
    push af
    ld a,(dna_y_offset)
    inc a
    and $1f
    ld (dna_y_offset),a
    pop af
endif



    ;; find out which 1 is the buffer
    push af
    and 7
    add a,a
    add a,a
    add a,$e0   ; should be be e0 e4 e8 ec f0 f4 f8 fc

    ld h,a
    ld l,0
    ld (dna_font_ptr),hl

    pop af


    ;; point to the memory bank - 8 letters per bank
    srl a
    srl a
    srl a
    add a,bank(dna_font)

    NextReg MMU_7,a


.same_letter:

;    ld d,0
    ld a,(dna_line)
    ld e,a

    ld d,0

    ld hl ,(dna_font_ptr)
    ld b,2
.loop:

    push bc
    push de
    push hl

    // needs spliiting into parts as can wrap the buffer

    // we clear the line out first - only 64*2 bytes

    // ->|..XXXXXXX......|<- if letter not at past bottom  then fill 1 span for letter

    // ->|XXXXX........XX|<- if letter goes past bottom by clearing bit 6 ( and 63) then it wraps


    // clear the vertical line
    ld b,64
    ld d,0
    ld hl, zerobuffer
.work_topa:
    LDWS
    djnz .work_topa

    pop hl
    pop de

    ld a,(dna_y_offset)

    ld b,25

    ld d,a

    push de
    push hl

.loop2
    LDWS
    res 6,d
    djnz .loop2

    pop hl
    add hl,32

    push af
    ld a,(dna_pixels_left)
    dec a
    ld (dna_pixels_left),a
    pop af


    pop de
    inc e
    pop bc

    djnz .loop

if  SHIFT_BY_PIXEL
    ld a,(dna_y_offset)
    inc a
    and $3f
    ld (dna_y_offset),a
endif

    ld (dna_font_ptr),hl

    ld a,e
    ld (dna_line),a

    ld ( dna_x_offset),a
    ret


        seg		DNA_FONT_SEG
dna_font: incbin "_sa.nxi"        


