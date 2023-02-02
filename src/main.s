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
tmp0:
    .res 1
tmp1:
    .res 1
ysub:
    .res 2

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
    stz $9F2A
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
    stz Vera::Reg::Ctrl
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
    jmp loop


    rts

clowncar:
    .byte "CLOWNCAR.BIN.PAL"


bresenham:
