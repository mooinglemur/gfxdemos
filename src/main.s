.import affinetable

.segment "LOADADDR"
    .word $0801
.segment "BASICSTUB"
    .word start-2
    .byte $00,$00,$9e
    .byte "2061"
    .byte $00,$00,$00
.segment "STARTUP"
start:
    jmp main
.segment "BSS"

xscale:
    .res 1
addrm_off:
    .res 1
addrl_off:
    .res 1
ysub:
    .res 2
iterations:
    .res 1
angle:
    .res 1
row:
    .res 1

.segment "ZEROPAGE"
tmp0:
    .res 1
tmp1:
    .res 1
ptr1:
    .res 2
ptr2:
    .res 2
front:
    .res 1
pixels:
    .res 1
back:
    .res 1
quadrant:
    .res 1


.segment "CODE"

.include "x16.inc"

main:
    ; load sprite into VRAM (4k)
    lda #12
    ldx #<clowncar
    ldy #>clowncar
    jsr X16::Kernal::SETNAM

    lda #1
    ldx #8
    ldy #2
    jsr X16::Kernal::SETLFS

    ldx #0
    ldy #0
    lda #2 ; VRAM load, bank 0
    jsr X16::Kernal::LOAD


    ; load palette into VRAM (512b)
    lda #16
    ldx #<clowncar
    ldy #>clowncar
    jsr X16::Kernal::SETNAM

    lda #1
    ldx #8
    ldy #2
    jsr X16::Kernal::SETLFS

    ldx #<Vera::VRAM_palette
    ldy #>Vera::VRAM_palette
    lda #3 ; VRAM load, bank 1
    jsr X16::Kernal::LOAD


    ; enable sprite layer and disable tile layers
    stz Vera::Reg::Ctrl
    lda #$41
    sta Vera::Reg::DCVideo


    ; enable sprite 0 at $1000
    stz Vera::Reg::Ctrl
    lda #<Vera::VRAM_sprattr
    sta Vera::Reg::AddrL
    lda #>Vera::VRAM_sprattr
    sta Vera::Reg::AddrM
    lda #^Vera::VRAM_sprattr
    ora #$10 ; auto increment = 1
    sta Vera::Reg::AddrH

    lda #($1000 >> 5)
    sta Vera::Reg::Data0
    lda #(($1000 >> 13) | $80)
    sta Vera::Reg::Data0
    lda #<(160-32)
    sta Vera::Reg::Data0
    lda #>(160-32)
    sta Vera::Reg::Data0
    lda #<(120-32)
    sta Vera::Reg::Data0
    lda #>(120-32)
    sta Vera::Reg::Data0
    lda #$0C
    sta Vera::Reg::Data0
    lda #$F0
    sta Vera::Reg::Data0

    ; set scale to 320x240
    lda #64
    sta Vera::Reg::DCHScale
    sta Vera::Reg::DCVScale

    lda #4
    sta iterations
    stz xscale

loop:
    stz ysub
    stz ysub+1
    inc xscale
    
    lda xscale
    lsr
    lsr
    lsr
    eor #$1F
    sta addrl_off

    lda xscale
    lsr
    lsr
    lsr
    lsr
    lsr
    eor #$7
    clc
    adc #$10 ; for sprite pos #1
    sta addrm_off

    lda xscale
    asl
    asl
    asl
    eor #$C0
    and #$C0
    clc
    adc addrl_off
    sta addrl_off
    lda addrm_off
    adc #0
    sta addrm_off


    stz Vera::Reg::Ctrl
    VERA_SET_ADDR 0, 1
    inc Vera::Reg::Ctrl
    VERA_SET_ADDR $1000, 0

    lda #%00000101 ; Affine mode, leave addrsel 1
    sta Vera::Reg::Ctrl

    lda xscale
    sta $9F29
    lda #$24
    sta $9F2A
    stz $9F2B
    stz $9F2C

    ldx #0
spriteloop1:
    lda xscale

    clc
    adc ysub
    sta ysub
    lda ysub+1
    adc #0
    sta ysub+1
    
    stz tmp0
    lsr
    ror tmp0
    lsr
    ror tmp0
    clc
    adc addrm_off
    sta tmp1

    lda addrl_off
    clc
    adc tmp0
    sta Vera::Reg::AddrL   

    lda tmp1
    adc #0
    sta Vera::Reg::AddrM

    ; reset subpixel pos
    lda #%00000101 ; Affine mode, leave addrsel 1
    sta Vera::Reg::Ctrl

.repeat 64
    lda Vera::Reg::Data0
    sta Vera::Reg::Data1
.endrepeat

    inx
    cpx #64
    bcs :+
    jmp spriteloop1
:
    lda xscale
    bne :+
    dec iterations
    beq donescale
:
    jmp loop
donescale:
    ; let's try some rotations
    stz angle 
    lda #2
    sta iterations

angleloop:
    lda angle
    asl
    asl
    tay
    lda affinetable, y
    sta ptr1
    lda affinetable+1, y
    sta ptr1+1
    lda affinetable+2, y
    sta ptr2
    lda affinetable+3, y
    sta ptr2+1
    
    ; set addr_h and pixel increments
    lda angle
    rol
    rol
    rol
    and #3
    sta quadrant
    tay ; quadrant

    stz Vera::Reg::Ctrl
    ; set addr0 ptr to $1000
    lda #$10
    sta Vera::Reg::AddrM
    stz Vera::Reg::AddrL

    inc Vera::Reg::Ctrl
    lda incyt,y
    sta Vera::Reg::AddrH

    ; set X/Y subpixel step
    lda #%00000100 ; Affine mode
    sta Vera::Reg::Ctrl
    ; reset addr0 inc
    lda #%00010000
    sta Vera::Reg::AddrH

    bit angle
    bvs swap

    lda (ptr1)
    sta Vera::Reg::DCHSubIncL
    ldy #1
    lda (ptr1),y
    ldx quadrant
    ora incxt,x
    sta Vera::Reg::DCHSubIncH
    iny
    lda (ptr1),y
    sta Vera::Reg::DCVSubIncL
    iny
    lda (ptr1),y
    sta Vera::Reg::DCVSubIncH
    jmp endangle
swap:
    lda (ptr1)
    sta Vera::Reg::DCVSubIncL
    ldy #1
    lda (ptr1),y
    sta Vera::Reg::DCVSubIncH
    iny
    lda (ptr1),y
    sta Vera::Reg::DCHSubIncL
    iny
    lda (ptr1),y
    ldx quadrant
    ora incxt,x
    sta Vera::Reg::DCHSubIncH

endangle:
    stz row

rowloop:

    lda row
    asl
    asl
    tay

    lda #%00000101 ; affine, addrsel 1
    sta Vera::Reg::Ctrl

    ldx quadrant
    lda incyt,x
    sta Vera::Reg::AddrH
    
    lda quadrant
    beq q0
    dex
    beq q1
    dex
    beq q2
q3:
    lda (ptr2),y
    sta front ; zeroed bytes to skip

    iny
    lda (ptr2),y
    eor #$3f

    stz tmp0
    lsr
    ror tmp0
    lsr
    ror tmp0
    sta tmp1

    iny
    lda (ptr2),y

    ora tmp0
    sta tmp0

    iny
    lda (ptr2),y
    sta back ; zero bytes to write out at the end
    bra qend
q2:
    lda angle

    lda (ptr2),y
    sta front ; zeroed bytes to skip

    iny
    lda (ptr2),y
    eor #$3f

    asl
    asl
    sta tmp0

    iny
    lda (ptr2),y
    eor #$3f

    lsr
    ror tmp0
    lsr
    ror tmp0
    sta tmp1

    iny
    lda (ptr2),y
    sta back ; zero bytes to write out at the end
    bra qend
q1:
    lda (ptr2),y
    sta front ; zeroed bytes to skip

    iny
    lda (ptr2),y

    stz tmp0
    lsr
    ror tmp0
    lsr
    ror tmp0
    sta tmp1

    iny
    lda (ptr2),y
    eor #$3f

    ora tmp0
    sta tmp0

    iny
    lda (ptr2),y
    sta back ; zero bytes to write out at the end
    bra qend
q0:
    lda (ptr2),y
    sta front ; zeroed bytes to skip

    iny
    lda (ptr2),y

    asl
    asl
    sta tmp0

    iny
    lda (ptr2),y

    lsr
    ror tmp0
    lsr
    ror tmp0
    sta tmp1

    iny
    lda (ptr2),y
    sta back ; zero bytes to write out at the end

qend:
    lda tmp0
    sta Vera::Reg::AddrL
    lda tmp1
    sta Vera::Reg::AddrM    

    lda #64
    sec
    sbc front
    sbc back
    sta pixels

    ldx front
    beq prepixelloop
frontloop:
    stz Vera::Reg::Data0
    dex
    bne frontloop

prepixelloop:
    ldx pixels
    beq prebackloop
pixelloop:
    lda Vera::Reg::Data1
    sta Vera::Reg::Data0
    dex
    bne pixelloop

prebackloop:
    ldx back
    beq endrow
backloop:
    stz Vera::Reg::Data0
    dex
    bne backloop

endrow:
    inc row
    lda row
    cmp #64
    beq :+
    jmp rowloop
:

    inc angle
    bne :+
    dec iterations
:

    lda iterations
    bmi :+
    wai
:
    jmp angleloop

    rts

clowncar:
    .byte "CLOWNCAR.BIN.PAL"
incxt:
    .byte %00100000,%10100000,%10100000,%00100000
incyt:
    .byte %01110000,%01110000,%01111000,%01111000

bresenham:
