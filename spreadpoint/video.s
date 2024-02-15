PAL_INDEX            equ $40
PAL_VALUE_8BIT       equ $41
TILE_X_LO            equ $30
TILE_X_HI            equ $2f
TILE_Y               equ $31

video_setup:

       nextreg $43,%01100000   ; select tilemap 1st palette
       nextreg $40,1           ; palette index
       nextreg $4c,0           ; 0 is transparent

       nextreg $68,%00000000   ;ula disable
       nextreg $6b,%10100011    ; Tilemap Control 512 tiles + above ula
       nextreg $6c,%00000010
       nextreg $6f,HI(TILE_GRAPHICS) ; tile pattern @ $4000
       nextreg $6e,HI(TILE_MAP) ; tilemap @ $7600

      nextreg $1c,%00001000 ; Clip Window control : reset tilemap index

       nextreg $1b,+((0+8)/2) ; Clip Window Tilemap : x1 /2     
       nextreg $1b,+((320-8)/2-1)              ; x2 /2
       nextreg $1b,(32)                          ; y1
       nextreg $1b,(192+32+32-32-1)               ; y2

       nextreg TILE_X_HI,0           ; Tilemap Offset X MSB ; windows x = 0
       nextreg TILE_X_LO,0           ; Tilemap Offset X LSB

       nextreg TILE_Y,0           ; Tilemap Offset Y ;windows y = 0

       nextreg $15,%00000001 ; no low rez , LSU , no sprites , no over border

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
       call testme
       
       ld a,0
       out($fe),a

       call update

       ld a,6
       out($fe),a

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

	ld a,7
	out ($fe),a

	nextreg $62,%01000000 ;// copper start | MSBs = 00

	ld a,0
	out ($fe),a

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

MAP_DX equ $30
 ; hori scroll LSB   - will be 0 to 7
MAP_DY equ $31   
; vert scroll LSB   - will be mutiple of 8 - so each scan line starts - only 0->8 scanlines 
COL1  equ $56

OFF_Y equ -32

PART2 equ -96

copper_new_start:

COPPER_WAIT(0,1) 

_DX_0:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+0) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL0)

COPPER_WAIT(6,0) 
_DX_1:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*1) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL1)

COPPER_WAIT(12,0) 
_DX_2:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL2)

COPPER_WAIT(18,0) 
_DX_3:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*3) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

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

COPPER_WAIT(36,0) 
_DX_6:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*6) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

COPPER_WAIT(42,0) 
_DX_7:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*7) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

COPPER_WAIT(48,0) 
_DX_8:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*8) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL8)

COPPER_WAIT(54,0) 
_DX_7a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*0)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

COPPER_WAIT(60,0) 
_DX_6a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*1)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

COPPER_WAIT(66,0) 
_DX_5a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*2)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)

COPPER_WAIT(72,0) 
_DX_4a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*3)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)

COPPER_WAIT(78,0) 
_DX_3a:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*4)) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

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

COPPER_WAIT(96+30,0) 
_DX_5b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*5+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)

COPPER_WAIT(96+36,0) 
_DX_6b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*6)+PART2 ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

COPPER_WAIT(96+42,0) 
_DX_7b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*7+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

COPPER_WAIT(96+48,0) 
_DX_8b:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+(8-6)*8+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL8)

COPPER_WAIT(96+54,0) 
_DX_7c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*0)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL7)

COPPER_WAIT(96+60,0) 
_DX_6c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*1)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL6)

COPPER_WAIT(96+66,0) 
_DX_5c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*2))+PART2 ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL5)

COPPER_WAIT(96+72,0) 
_DX_4c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*3)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL4)

COPPER_WAIT(96+78,0) 
_DX_3c:
COPPER_MOVE(MAP_DX,0) 
COPPER_MOVE(MAP_DY,OFF_Y+2-(14*4)+PART2) ;  8*col-6*i   
COPPER_MOVE(PAL_VALUE_8BIT,_COL3)

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


testme:
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

       ld a,l
       out ($fe),a

       ld bc,40
       ldir

       inc ix
       inc ix

       pop bc
       djnz .loop2

       ld a,0
       out ($fe),a
       
       ret







speed db 9,8,7,6,5,4,3,2,1
       db "ANDREW SEED"
offset ds 18*2

TheTiles_start:
       incbin "d1.nxi"
TheTiles_end:

TheText_start:
       db     " HELLO AND WELCOME TO THE SWEDISH NEW YEAR DEMO, RELEASED THE 01-01-1989 (A.C.)    PRESS F1-SYNC";
       db     "  F2-THE CAREBEARS (VERY VERY GOOD DEMO) (GUESS WHO WROTE THAT)  F3-OMEGA  F4-F10 DON'T WORK    ";
       db     "  THE CREDITS:  OMEGA FOR GRAPHIXX, THE CAREBEARS FOR RECODING (WITHOUT ANY BUGS) AND PUTTING ";
       db     "EVERYTHING TOGETHER (AND JAS FOR CHOOSING THE PALETTE FOR THE SCROLLTEXT) AND MAD MAX FOR THE MUZAK. ";
       db     "IF YOU READ THIS TEN TIMES WE WILL TELL YOU HOW TO REMOVE ALL OF THE BORDERS.    ";
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

A_COL8 _COL0,220,221,220
A_COL8 _COL1,226,230,196
A_COL8 _COL2,244,198,150
A_COL8 _COL3,235,172,143
A_COL8 _COL4,196,144,100
A_COL8 _COL5,181,111,86
A_COL8 _COL6,155,80,54
A_COL8 _COL7,122,36,0
A_COL8 _COL8,72,5,3
    



;COPPER_WAIT 0,6*32



;endif
