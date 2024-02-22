// not signed
mul_hl_de:       ; (uint16)HL = (uint16)HL x (uint16)DE

    bit 7,d
    jr .do_mul
    
    xor a
    sub e
    ld e,a
    sbc a,a
    sub d
    ld d,a

    call .do_mul

    xor a
    sub e
    ld e,a
    sbc a,a
    sub d
    ld d,a

    ret
.do_mul


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
       ld b,20
.loop:
       push bc
       ld d,(ix+0)          ;; de = x
       ld e,(ix+1)

       ld h,(ix+2)          ; hl = y
       ld l,(ix+3)

       ld a,b
       add de, 128+32
       add hl, 100

       add hl,a
       add de,a


       ld b,a
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
    ld ix , posn
    ld a,0

    ld hl,(iteration5)
    add hl,5*2
    ld (iteration5),hl

    ld hl,(iteration8)
    add hl,8*2
    ld (iteration8),hl
    
   push af
    ld hl ,(iteration5)
    add  hl,a
    call get_sin_hl_to_de

    ld a,d
    or a
    jp p,.pos
.pos:
   pop af

.loop
    push af
    ld hl ,(iteration5)
    add  hl,a
    call get_sin_hl_to_de

  
    ld hl,128
    call mul_hl_de

    ld l,h    
    ld a,h
    add a,a
    sbc a,a
    ld h,a


 ;   add    hl,128
    ld (ix+0),h
    ld (ix+1),l
    pop af

    push af

    ld a,7
    out ($fe),a

    ld hl,(iteration8)
    add  hl,a
    call get_sin_hl_to_de
    ld hl,50
    call mul_hl_de

    ld l,h    
    ld a,h
    add a,a
    sbc a,a
    ld h,a


;    add    hl,50
    ld (ix+2),h
    ld (ix+3),l

    ld a,3
    out ($fe),a

    pop af

    ld de,4
    add ix,de


    add 10
;    inc a
    cp 20*10
    jr nz,.loop
    ret


get_sin_hl_to_de
    ld a,h
    and 3   ; sine table of 512 entries 0 -> 1ff
    ld h,a
    add hl,hl
    add hl,sine_table
    ld e,(hl)
    inc hl
    ld d,(hl)

;    ld de,-32000
    ret



iteration5:: dw 0
iteration8: dw 0
posn :  ds 20*2*2     ;; 16 bit * 20 bobs *2(x,y)

sine_table:
            dw $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
            dw $10,$01,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
            dw $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
            dw $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
            dw $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
            dw $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f
            dw $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
            dw $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f
            dw $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
            dw $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
            dw $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
            dw $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
            dw $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
            dw $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df
            dw $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
			dw $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff

			dw $ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8,$f7,$f6,$f5,$f4,$f3,$f2,$f1,$f0
            dw $ef,$ee,$ed,$ec,$eb,$ea,$e9,$e8,$e7,$e6,$e5,$e4,$e3,$e2,$e1,$e0
            dw $df,$de,$dd,$dc,$db,$da,$d9,$d8,$d7,$d6,$d5,$d4,$d3,$d2,$d1,$d0
            dw $cf,$ce,$cd,$cc,$cb,$ca,$c9,$c8,$c7,$c6,$c5,$c4,$c3,$c2,$c1,$c0
            dw $bf,$be,$bd,$bc,$bb,$ba,$b9,$b8,$b7,$b6,$b5,$b4,$b3,$b2,$b1,$b0
            dw $af,$ae,$ad,$ac,$ab,$aa,$a9,$a8,$a7,$a6,$a5,$a4,$a3,$a2,$a1,$a0
            dw $9f,$9e,$9d,$9c,$9b,$9a,$99,$98,$97,$96,$95,$94,$93,$92,$91,$90
            dw $8f,$8e,$8d,$8c,$8b,$8a,$89,$88,$87,$86,$85,$84,$83,$82,$81,$80
            dw $7f,$7e,$7d,$7c,$7b,$7a,$79,$78,$77,$76,$75,$74,$73,$72,$71,$70
            dw $6f,$6e,$6d,$6c,$6b,$6a,$69,$68,$67,$66,$65,$64,$63,$62,$61,$60
            dw $5f,$5e,$5d,$5c,$5b,$5a,$59,$58,$57,$56,$55,$54,$53,$52,$51,$50
            dw $4f,$4e,$4d,$4c,$4b,$4a,$49,$48,$47,$46,$45,$44,$43,$42,$41,$40
            dw $3f,$3e,$3d,$3c,$3b,$3a,$39,$38,$37,$36,$35,$34,$33,$32,$31,$30
            dw $2f,$2e,$2d,$2c,$2b,$2a,$29,$28,$27,$26,$25,$24,$23,$22,$21,$20
            dw $1f,$0e,$1d,$1c,$1b,$1a,$19,$18,$17,$16,$15,$14,$13,$12,$11,$10
            dw $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00

            dw -$00,-$01,-$02,-$03,-$04,-$05,-$06,-$07,-$08,-$09,-$0a,-$0b,-$0c,-$0d,-$0e,-$0f
            dw -$10,-$01,-$12,-$13,-$14,-$15,-$16,-$17,-$18,-$19,-$1a,-$1b,-$1c,-$1d,-$1e,-$1f
            dw -$20,-$21,-$22,-$23,-$24,-$25,-$26,-$27,-$28,-$29,-$2a,-$2b,-$2c,-$2d,-$2e,-$2f
            dw -$30,-$31,-$32,-$33,-$34,-$35,-$36,-$37,-$38,-$39,-$3a,-$3b,-$3c,-$3d,-$3e,-$3f
            dw -$40,-$41,-$42,-$43,-$44,-$45,-$46,-$47,-$48,-$49,-$4a,-$4b,-$4c,-$4d,-$4e,-$4f
            dw -$50,-$51,-$52,-$53,-$54,-$55,-$56,-$57,-$58,-$59,-$5a,-$5b,-$5c,-$5d,-$5e,-$5f
            dw -$60,-$61,-$62,-$63,-$64,-$65,-$66,-$67,-$68,-$69,-$6a,-$6b,-$6c,-$6d,-$6e,-$6f
            dw -$70,-$71,-$72,-$73,-$74,-$75,-$76,-$77,-$78,-$79,-$7a,-$7b,-$7c,-$7d,-$7e,-$7f
            dw -$80,-$81,-$82,-$83,-$84,-$85,-$86,-$87,-$88,-$89,-$8a,-$8b,-$8c,-$8d,-$8e,-$8f
            dw -$90,-$91,-$92,-$93,-$94,-$95,-$96,-$97,-$98,-$99,-$9a,-$9b,-$9c,-$9d,-$9e,-$9f
            dw -$a0,-$a1,-$a2,-$a3,-$a4,-$a5,-$a6,-$a7,-$a8,-$a9,-$aa,-$ab,-$ac,-$ad,-$ae,-$af
            dw -$b0,-$b1,-$b2,-$b3,-$b4,-$b5,-$b6,-$b7,-$b8,-$b9,-$ba,-$bb,-$bc,-$bd,-$be,-$bf
            dw -$c0,-$c1,-$c2,-$c3,-$c4,-$c5,-$c6,-$c7,-$c8,-$c9,-$ca,-$cb,-$cc,-$cd,-$ce,-$cf
            dw -$d0,-$d1,-$d2,-$d3,-$d4,-$d5,-$d6,-$d7,-$d8,-$d9,-$da,-$db,-$dc,-$dd,-$de,-$df
            dw -$e0,-$e1,-$e2,-$e3,-$e4,-$e5,-$e6,-$e7,-$e8,-$e9,-$ea,-$eb,-$ec,-$ed,-$ee,-$ef
			dw -$f0,-$f1,-$f2,-$f3,-$f4,-$f5,-$f6,-$f7,-$f8,-$f9,-$fa,-$fb,-$fc,-$fd,-$fe,-$ff

			dw -$ff,-$fe,-$fd,-$fc,-$fb,-$fa,-$f9,-$f8,-$f7,-$f6,-$f5,-$f4,-$f3,-$f2,-$f1,-$f0
            dw -$ef,-$ee,-$ed,-$ec,-$eb,-$ea,-$e9,-$e8,-$e7,-$e6,-$e5,-$e4,-$e3,-$e2,-$e1,-$e0
            dw -$df,-$de,-$dd,-$dc,-$db,-$da,-$d9,-$d8,-$d7,-$d6,-$d5,-$d4,-$d3,-$d2,-$d1,-$d0
            dw -$cf,-$ce,-$cd,-$cc,-$cb,-$ca,-$c9,-$c8,-$c7,-$c6,-$c5,-$c4,-$c3,-$c2,-$c1,-$c0
            dw -$bf,-$be,-$bd,-$bc,-$bb,-$ba,-$b9,-$b8,-$b7,-$b6,-$b5,-$b4,-$b3,-$b2,-$b1,-$b0
            dw -$af,-$ae,-$ad,-$ac,-$ab,-$aa,-$a9,-$a8,-$a7,-$a6,-$a5,-$a4,-$a3,-$a2,-$a1,-$a0
            dw -$9f,-$9e,-$9d,-$9c,-$9b,-$9a,-$99,-$98,-$97,-$96,-$95,-$94,-$93,-$92,-$91,-$90
            dw -$8f,-$8e,-$8d,-$8c,-$8b,-$8a,-$89,-$88,-$87,-$86,-$85,-$84,-$83,-$82,-$81,-$80
            dw -$7f,-$7e,-$7d,-$7c,-$7b,-$7a,-$79,-$78,-$77,-$76,-$75,-$74,-$73,-$72,-$71,-$70
            dw -$6f,-$6e,-$6d,-$6c,-$6b,-$6a,-$69,-$68,-$67,-$66,-$65,-$64,-$63,-$62,-$61,-$60
            dw -$5f,-$5e,-$5d,-$5c,-$5b,-$5a,-$59,-$58,-$57,-$56,-$55,-$54,-$53,-$52,-$51,-$50
            dw -$4f,-$4e,-$4d,-$4c,-$4b,-$4a,-$49,-$48,-$47,-$46,-$45,-$44,-$43,-$42,-$41,-$40
            dw -$3f,-$3e,-$3d,-$3c,-$3b,-$3a,-$39,-$38,-$37,-$36,-$35,-$34,-$33,-$32,-$31,-$30
            dw -$2f,-$2e,-$2d,-$2c,-$2b,-$2a,-$29,-$28,-$27,-$26,-$25,-$24,-$23,-$22,-$21,-$20
            dw -$1f,-$0e,-$1d,-$1c,-$1b,-$1a,-$19,-$18,-$17,-$16,-$15,-$14,-$13,-$12,-$11,-$10
            dw -$0f,-$0e,-$0d,-$0c,-$0b,-$0a,-$09,-$08,-$07,-$06,-$05,-$04,-$03,-$02,-$01,-$00

;            if (iteration >= 804) draw_balls(804);
;
;
;       function draw_balls(offset_iteration) {
;            var x, y, a = 5, b = 8, ite = iteration - offset_iteration;
;            for (var j = 0 ; j < 20 ; j++) {
;                x = 151 + Math.round(151 * Math.sin(a * (ite / 71 + j / 47))),
;                y =  50 + Math.round( 50 * Math.sin(b * (ite / 71 + j / 47)));
;                ball.draw(main_canvas, x + 52, y + 29);
;            }
;        }
;