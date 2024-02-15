
MY_BREAK	macro
        db $dd,01
		endm

	DMA_PORT    equ $6b ;//: zxnDMA

	TILE_GRAPHICS       equ $6000
	TILE_MAP            equ $5000

	DIGIT_0		equ 100

	OPT Z80
	OPT ZXNEXTREG    

    seg     CODE_SEG, 4:$0000,$8000
    seg     STNICC_SEG, $30:$0000,$0000 
    

    seg     CODE_SEG

	include "irq.s"

	org $8200                    ; Start of application
StackEnd:
	ds	128
StackStart:
	ds  2

start:
;; set the stack pointer
	ld sp , StackStart

; first page to load stuff
	ld a,(mem_init_page)

; load top layer map
	ld (load_page),a


	call video_setup

	call init_vbl


	ld de,TILE_GRAPHICS
	ld hl,TheTiles_start+4				// skip top line
	ld bc,TheTiles_end - TheTiles_start
	ldir

	ld hl,TheText_start
	ld bc,TheText_end - TheText_start + 40  ; first tile is 32 so sub that
.loop:
	ld a,(hl)
	sub $20
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,.loop

	ld hl,TheText_start
	ld bc,40
	ld de,TheText_end
	ldir

	nextreg 7,%11 ;/ 14mhz

	nextreg $43,%00110001	;; palette auto update layer 3 palette 1  | enable EnahncedULA

	nextreg $40,$00			;; palette index 0
	nextreg $41,$ff			;; black
	nextreg $41,$ff			;; black

	nextreg $43,%10110001	;; palette NON auto update layer 3 palette 1  | enable EnahncedULA

	nextreg $40,$01			;; palette index 1 - index for scroll teext palette entry

	nextreg $6b, %10100001
	nextreg $6c, %00000000

frame_loop:
	call wait_vbl
	call StartCopper
	ld a, 0
	out ($fe),a
	jp frame_loop


    
mem_init_page:  db 16


include "loading.s"
include "video.s"


 	savenex "player.nex",start

