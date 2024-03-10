	code_seg
   align 32

IM_2_Table:
        dw      linehandler     ; 0 - line interrupt
        dw      inthandler      ; 1 - uart0 rx
        dw      inthandler      ; 2 - uart1 rx
        dw      ctc0handler     ; 3 - ctc 0
        dw      inthandler      ; 4 - ctc 1
        dw      inthandler      ; 5 - ctc 2
        dw      inthandler      ; 6 - ctc 3
        dw      inthandler      ; 7 - ctc 4
        dw      inthandler      ; 8 - ctc 5
        dw      inthandler      ; 9 - ctc 6
        dw      inthandler      ; 10 - ctc 7
        dw      vbl             ; 11 - ula
        dw      inthandler      ; 12 - uart0 tx
        dw      inthandler      ; 13 - uart1 tx
        dw      inthandler      ; 14
        dw      inthandler      ; 15

init_vbl:
    di

    nextreg $22,%000
    nextreg $23,192

    ld a,IM_2_Table>>8
    ld i,a

    nextreg $c0, 1+(IM_2_Table & %11100000) ;low byte IRQ table  | base vector = 0xa0, im2 hardware mode
   	
	nextreg $c4,1				; ULA interrupt
	nextreg $c5,0               ; enable CTC channel 0 interrupts, disable CTC channel 1-7 interrupts
	nextreg $c6,0

    nextreg $cc,%10000001   ;  ula will inetrrupt dma
    nextreg $cd,1            ; ct 0 will interrupt dma

    im 2

vbl:
	di
	push hl
	push af

	border 6

	ld hl,irq_counter
	inc (hl)

	border 5

	pop af
	pop hl

    NextReg $c8,1
    ei
    reti

linehandler:
	my_break;
    NextReg $c8,2
    ei
    reti

ctc0handler:
	my_break;
    NextReg $c9,1
    ei
    reti

inthandler:
	my_break;
    ei
    reti


irq_counter: db 0
irq_last_count: db 0



wait_vbl:
	halt
	ld a,(irq_counter)
	ld (irq_last_count),a
	ld a,0
	ld (irq_counter),a
	ret


