    seg     CODE_SEG

PAL_INDEX            equ $40
PAL_VALUE_8BIT       equ $41
TILE_X_LO            equ $30
TILE_X_HI            equ $2f
TILE_Y               equ $31

LAYER2_HSCROLL       equ $16
LAYER2_VSCROLL       equ $17

LAYER2_CLIP_WINDOW   equ $18

    
TCB_PAL0      equ $d4
TCB_PAL1      equ $d0
TCB_PAL2      equ $d0
TCB_PAL3      equ $c8
TCB_PAL4      equ $c4
TCB_PAL5      equ $c0
TCB_PAL6      equ $a0
TCB_PAL7      equ $81
TCB_PAL8      equ $81
TCB_PAL9      equ $62
TCB_PALA      equ $44
TCB_PALB      equ $22
TCB_PALC      equ $03

video_setup:

       nextreg $43,%01100000   ; select tilemap 1st palette
       nextreg $40,1           ; palette index
       nextreg $4c,$0           ; 0 is transparent

       nextreg $68,%00000000   ;ula disable
       nextreg $6b,%10100011    ; Tilemap Control 512 tiles + above ula
       nextreg $6c,%00000010
       nextreg $6f,HI(TILE_GRAPHICS) ; tile pattern @ $4000
       nextreg $6e,HI(TILE_MAP) ; tilemap @ $7600

      nextreg $1c,%00001000 ; Clip Window control : reset tilemap index

       nextreg $1b,0+16; Clip Window Tilemap : x1 /2     
       nextreg $1b,159-16              ; x2 /2
       nextreg $1b,(32)                          ; y1
       nextreg $1b,(192+64-32-1)               ; y2

       nextreg TILE_X_HI,0           ; Tilemap Offset X MSB ; windows x = 0
       nextreg TILE_X_LO,0           ; Tilemap Offset X LSB

       nextreg TILE_Y,0           ; Tilemap Offset Y ;windows y = 0

       nextreg $15,%00000111 ; no low rez , LSU , no sprites , no over border

       ret


 ReadNextReg:
       push bc
       ld bc,$243b
       out (c),a
       inc b
       in a,(c)
       pop bc
       ret


;; Detect current video mode:
;; 0, 1, 2, 3 = HDMI, ZX48, ZX128, Pentagon (all 50Hz), add +4 for 60Hz modes
;; (Pentagon 60Hz is not a valid mode => value 7 shouldn't be returned in A)
DetectMode:
       ld      a,$05 ; PERIPHERAL_1_NR_05
       call    ReadNextReg
       and     $04             ; bit 2 = 50Hz/60Hz configuration
       ld      b,a             ; remember the 50/60 as +0/+4 value in B
       ; read HDMI vs VGA info
       ld      a,$11 ; VIDEO_TIMING_NR_11
       call    ReadNextReg
       inc     a               ; HDMI is value %111 in bits 2-0 -> zero it
       and     $07
       jr      z,.hdmiDetected
       ; if VGA mode, read particular zx48/zx128/pentagon setting
       ld      a,$03
       call    ReadNextReg
       ; a = bits 6-4: %00x zx48, %01x zx128, %100 pentagon
       swapnib
       rra
       inc     a
       and     $03             ; A = 1/2/3 for zx48/zx128/pentagon
.hdmiDetected:
       add     a,b             ; add 50/60Hz value to final result
       ret

VideoScanLines: ; 1st copper ,2nd irq
       dw 312-32                           ; hdmi_50
       dw 312-32                           ; zx48_50
       dw 311-32                           ; zx128_50
       dw 320-32                           ; pentagon_50

       dw 262-32                           ; hdmi_60
       dw 262-32                            ; zx48_60
       dw 261-32                            ; zx128_60
       dw 262-32                            ; pentagon_60

GetMaxScanline:
       call DetectMode:
       ld hl, VideoScanLines
       add a,a
       add hl,a
       ret

StartCopper:
       call scroller
       
       border 0

       call update

       border 6

	ld      hl,copper_new_start
	ld      bc,copper_new_end-copper_new_start
 

do_copper:
	nextreg $61,0   ; LSB = 0
	nextreg $62,0   ;// copper stop | MSBs = 00

@lp1:	ld	a,(hl)  ;// write the bytes of the copper
	nextreg $60,a
	inc	hl
	
       ld	a,(hl)  ;// write the bytes of the copper
	nextreg $60,a
	inc	hl
	
       ld	a,(hl)  ;// write the bytes of the copper
	nextreg $60,a
	inc	hl
	
       ld	a,(hl)  ;// write the bytes of the copper
	nextreg $60,a
	inc	hl

       // not wrried if over by 2 bytes , less loops
       add    bc,-4
	ld	a,b
	or	a
	jp	p,@lp1		

       border 7

	nextreg $62,%01000000 ;// copper start | MSBs = 00

	ret
 

  
		// copper WAIT  VPOS,HPOS
COPPER_WAIT	macro
		db	HI($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
		db	LO($8000+(\0&$1ff)+(( ((\1/8) >>3) &$3f)<<9))
		endm
		// copper MOVE reg,val
COPPER_MOVE		macro
		db	HI($0000+((\0&$ff)<<8)+(\1&$ff))
		db	LO($0000+((\0&$ff)<<8)+(\1&$ff))
		endm
COPPER_NOP	macro
		db	0,0
		endm

COPPER_HALT     macro
                db 255,255
                endm

COPPER_SET_PAL_INDEX macro
                     COPPER_MOVE(PAL_INDEX,\0)
                     endm

COPPER_SET_COLOR     macro
                     COPPER_MOVE(PAL_VALUE_8BIT,\0)
                     endm


MAP_DX equ $30
 ; hori scroll LSB   - will be 0 to 7
MAP_DY equ $31   
; vert scroll LSB   - will be mutiple of 8 - so each scan line starts - only 0->8 scanlines 
COL1  equ $56

OFF_Y equ -32

PART2 equ -96

PAL_LAYER2  macro
             COPPER_MOVE($43,%10010001)
              endm

PAL_LAYER2_PAL2  macro
             COPPER_MOVE($43,%01010101)
              endm


PAL_LAYER3  macro
             COPPER_MOVE($43,%10110001)
              endm

PAL_LAYER3_2  macro
             COPPER_MOVE($43,%10110101)
              endm



DNA_FADE_PAL_X equ 256
; pass Y

COPPER_BLOCK_NOW macro              
              PAL_LAYER2_PAL2
              COPPER_SET_PAL_INDEX(1)
              COPPER_SET_COLOR(%11100000)
              COPPER_SET_COLOR(%00011100)
              COPPER_SET_COLOR(%00000011)
              COPPER_SET_PAL_INDEX(1)
              PAL_LAYER3_2
              endm

COPPER_BLOCK macro              
              COPPER_WAIT(\0,DNA_FADE_PAL_X)
              COPPER_BLOCK_NOW
              endm

copper_new_start:

COPPER_WAIT(0,1) 

layer_2_front equ *+1
COPPER_MOVE(LAYER2_RAM_BANK,0);

_DX_0:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+0) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL0)
COPPER_MOVE(67,%00000001)


_MAGIC
PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL0)
PAL_LAYER3


COPPER_WAIT(6,0) 
_DX_1:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*1) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL1)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL1)
PAL_LAYER3

COPPER_WAIT(12,0) 
_DX_2:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL2)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL2)
PAL_LAYER3

COPPER_WAIT(18,0) 
_DX_3:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*3) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL3)
PAL_LAYER3

COPPER_WAIT(24,0) 
_DX_4:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*4) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)

COPPER_WAIT(30,0) 
_DX_5:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*5) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL4)
PAL_LAYER3

COPPER_WAIT(36,0) 
_DX_6:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*6) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL5)
PAL_LAYER3

COPPER_WAIT(42,0) 
_DX_7:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*7) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL6)
PAL_LAYER3

COPPER_WAIT(48,0) 
_DX_8:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*8) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL8)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL7)
PAL_LAYER3

COPPER_WAIT(54,0) 
_DX_7a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*0)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL8)
PAL_LAYER3

COPPER_WAIT(60,0) 
_DX_6a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*1)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PAL9)
PAL_LAYER3

COPPER_WAIT(66,0) 
_DX_5a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*2)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PALA)
PAL_LAYER3


COPPER_WAIT(72,0) 
_DX_4a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*3)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PALB)
PAL_LAYER3

COPPER_WAIT(78,0) 
_DX_3a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*4)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

PAL_LAYER2
COPPER_MOVE(PAL_VALUE_8BIT,TCB_PALC)
PAL_LAYER3

COPPER_WAIT(84,0) 
_DX_2a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*5)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL2)

COPPER_WAIT(90,0) 
_DX_1a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*6)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL1)

COPPER_WAIT(96,0) 
_DX_0a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*7)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL0)

COPPER_WAIT(96+6,0) 
_DX_1b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*1+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL1)

COPPER_WAIT(96+12,0) 
_DX_2b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*2+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL2)

COPPER_WAIT(96+18,0) 
_DX_3b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*3+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

COPPER_WAIT(96+24,0) 
_DX_4b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*4+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)

;; test code for the dna scroller
;; test code for the dna scroller
;; test code for the dna scroller
DNA_PAL_0:
COPPER_BLOCK_NOW(124)


COPPER_WAIT(125,0)
COPPER_MOVE( LAYER2_CLIP_WINDOW,0)
COPPER_MOVE( LAYER2_CLIP_WINDOW,255)
COPPER_MOVE( LAYER2_CLIP_WINDOW,0)
COPPER_MOVE( LAYER2_CLIP_WINDOW,128+50-4)
COPPER_MOVE(PAL_VALUE_8BIT,255)
dna_x_offset: equ *+1
COPPER_MOVE( LAYER2_HSCROLL,0)  
dna_y_offset01: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)
COPPER_MOVE(67,%10110101)

layer_2_back equ *+1
COPPER_MOVE(LAYER2_RAM_BANK,0);

COPPER_WAIT(96+30,0) 
_DX_5b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*5+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)
dna_y_offset02: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+30+1,0) 
dna_y_offset03: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)


COPPER_WAIT(96+30+2,0) 
dna_y_offset04: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+30+3,0) 
dna_y_offset05: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

DNA_PAL_1:
COPPER_BLOCK_NOW(129)


COPPER_WAIT(96+30+4,0) 
dna_y_offset06: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+30+5,0) 
dna_y_offset07: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+36,0) 
_DX_6b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*6)+PART2 ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)
dna_y_offset08: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+36+1,0) 
dna_y_offset09: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,64)

COPPER_WAIT(96+36+2,0) 
dna_y_offset10: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+36+3,0) 
dna_y_offset11: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+36+4,0) 
dna_y_offset12: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_2:
COPPER_BLOCK_NOW(134)

COPPER_WAIT(96+36+5,0) 
dna_y_offset13: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+42,0) 
_DX_7b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*7+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)
dna_y_offset14: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+42+1,0) 
dna_y_offset15: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_3:
COPPER_BLOCK_NOW(139)

COPPER_WAIT(96+42+2,0) 
dna_y_offset16: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+42+3,0) 
dna_y_offset17: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+42+4,0) 
dna_y_offset18: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+42+5,0) 
dna_y_offset19: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)


COPPER_WAIT(96+48,0) 
_DX_8b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*8+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL8)
dna_y_offset20: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_4:
COPPER_BLOCK_NOW(144)

COPPER_WAIT(96+48+1,0) 
dna_y_offset21: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+48+2,0) 
dna_y_offset22: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_5:
COPPER_BLOCK_NOW(146)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


COPPER_WAIT(96+51,0) 
dna_y_offset23: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+52,0) 
dna_y_offset24: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+53,0) 
dna_y_offset25: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)


COPPER_WAIT(96+54,0) 
_DX_7c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*0)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)
dna_y_offset26: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+55,0) 
dna_y_offset27: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+56,0) 
dna_y_offset28: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)


DNA_PAL_6:
COPPER_BLOCK_NOW(152)

COPPER_WAIT(96+57,0) 
dna_y_offset29: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+58,0) 
dna_y_offset30: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_7:
COPPER_BLOCK_NOW(154)


COPPER_WAIT(96+59,0) 
dna_y_offset31: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+60,0) 
_DX_6c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*1)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)
dna_y_offset32: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+61,0) 
dna_y_offset33: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+62,0) 
dna_y_offset34: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+63,0) 
dna_y_offset35: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)


DNA_PAL_8:
COPPER_BLOCK_NOW(159)


COPPER_WAIT(96+64,0) 
dna_y_offset36: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+65,0) 
dna_y_offset37: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+66,0) 
_DX_5c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*2))+PART2 ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)
dna_y_offset38: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+67,0) 
dna_y_offset39: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+68,0) 
dna_y_offset40: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_9:
COPPER_BLOCK_NOW(164)

COPPER_WAIT(96+69,0) 
dna_y_offset41: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+70,0) 
dna_y_offset42: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+71,0) 
dna_y_offset43: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)


COPPER_WAIT(96+72,0) 
_DX_4c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*3)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)
dna_y_offset44: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+73,0) 
dna_y_offset45: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

DNA_PAL_10:
COPPER_BLOCK_NOW(169)

COPPER_WAIT(96+74,0) 
dna_y_offset46: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+75,0) 
dna_y_offset47: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+76,0) 
dna_y_offset48: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+77,0) 
dna_y_offset49: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+78,0) 
_DX_3c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*4)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)
dna_y_offset50: equ *+1
COPPER_MOVE( LAYER2_VSCROLL,60)

COPPER_WAIT(96+84,0) 
_DX_2c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*5)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL2)

COPPER_WAIT(96+90,0) 
_DX_1c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*6)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL1)

COPPER_WAIT(96+96,0) 
_DX_0c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*7)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL0)
COPPER_MOVE(67,%10110001)

COPPER_MOVE( LAYER2_VSCROLL,0)

COPPER_HALT
COPPER_HALT

copper_new_end:



update:

ld de,offset+1

ld a,(de)
and 7
inc de
inc de
ld(_DX_0+1),a
ld(_DX_0a+1),a
ld(_DX_0c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_1+1),a
ld(_DX_1a+1),a
ld(_DX_1b+1),a
ld(_DX_1c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_2+1),a
ld(_DX_2a+1),a
ld(_DX_2b+1),a
ld(_DX_2c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_3+1),a
ld(_DX_3a+1),a
ld(_DX_3b+1),a
ld(_DX_3c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_4+1),a
ld(_DX_4a+1),a
ld(_DX_4b+1),a
ld(_DX_4c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_5+1),a
ld(_DX_5a+1),a
ld(_DX_5b+1),a
ld(_DX_5c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_6+1),a
ld(_DX_6a+1),a
ld(_DX_6b+1),a
ld(_DX_6c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_7+1),a
ld(_DX_7a+1),a
ld(_DX_7b+1),a
ld(_DX_7c+1),a

ld a,(de)
and 7
inc de
inc de
ld(_DX_8+1),a
ld(_DX_8b+1),a

ret


scroller:
       // ad the speed to each offset (offset:pixel))
       ld de,speed
       ld ix,offset
       ld b, 9
.loop:
       ld a,(de)
       ld h,(ix+0)   ;// current offset
       ld l,(ix+1)
       add hl,a
       ld (ix+0),h   ;// current offset
       ld (ix+1),l
       add hl,-(TheText_end-TheText_start)*8
       ld a,h
       or a
       jp m,.no_wrap
       ld a,7
       and (ix+1)
       ld (ix+0),0   ;// current offset
       ld (ix+1),l
.no_wrap:
       inc ix
       inc ix
       inc de
       djnz .loop

       // now we need to copy the 40 bytes to each line

	ld de,TILE_MAP
       ld b,9
       ld ix,offset
.loop2:
       push bc

       push de

       ld d,(ix+0)
       ld e,(ix+1)

       ld b,3
       bsrl de,b

       ld h,d        ; hl char in 
       ld l,e

       pop de
       add hl,TheText_start

       border 1

       ld bc,40
       ldir

       inc ix
       inc ix

       pop bc
       djnz .loop2

       border 0
       
       ret

speed db 9,8,7,6,5,4,3,2,1
offset ds 18*2

TheTiles_start:
       incbin "d1.nxi"
TheTiles_end:

TheText_start:
              db "YO, SUCKERS!!!  THIS IS THE SPREADPOINT DEMO!   ALL CODING WAS DONE BY THE "
              db "CAREBEARS,  ALL GRAPHIXX WAS DESIGNED BY THE CAREBEARS AND THE MUZEXX WAS ALSO "
              db "'EINGEPLUPPED' BY THE CAREBEARS!  WE SAW THE ORIGINAL SPREADPOINT DEMO, BY "
              db "SPREADPOINT, ON THE NO-CREW-COPY-PARTY.  ON THE TRAIN HOME, WE DISCUSSED HOW TO "
              db "CONVERT IT TO THE ST.  WE DECIDED TO USE THIS DIGISHIT-ROUT, EVEN THOUGH IT TAKES "
              db "SOME PROCESSOR TIME. ON AN ST, DIGISOUND RESULTS IN LESS GRAPHICAL MOVEMENT, BUT "
              db "WE THINK THERE'S ENOUGH MOVEMENT ON THIS SCREEN, DON'T YOU? (DON'T ANSWER IF "
              db "YOU DON'T!) YOUR EYES ARE PROBABLY STARTING TO ACHE, SO LET'S WRAP. THE UNION "
              db "RULES.      "
TheText_end:
       ds     40
 

; \0 = var name
; \1 = R
; \2 = G
; \3 = B
;       \0 equ (\1&%11100000)+((\2>>6)&%11)+((\1>>3)&%11100)
A_COL8	macro
       \0 equ (\1&%11100000)+((\3>>6)&%11)+((\2>>3)&%11100)
	endm

A_COL8 _COL0,238,238,238
A_COL8 _COL1,238,238,204
A_COL8 _COL2,238,204,170
A_COL8 _COL3,238,170,136
A_COL8 _COL4,204,136,102
A_COL8 _COL5,170,102,68
A_COL8 _COL6,136,68,34
A_COL8 _COL7,102,34,0
A_COL8 _COL8,68,0,0

