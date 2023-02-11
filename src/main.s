.import affinetable_l, affinetable_h

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


.segment "ZEROPAGE"
ptr1:
    .res 2
angle:
    .res 1
iteration:
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

    lda #%00000111 ; dcsel 3, addrsel 1
    sta Vera::Reg::Ctrl

    lda #%00000100 ; repeat mode
    sta Vera::Reg::DCSubAccH

    lda #%10100111 ; 64x64 bitmap mode for affine helper
    sta Vera::Reg::L0Config
    stz Vera::Reg::L0MapBase ; source texture address of 0x00000

    lda Vera::Reg::AddrH

    lda #4
    sta iteration
    stz angle
angleloop:
    ; ptr1 points to small table per angle
    ldy angle
    lda affinetable_l,y
    sta ptr1
    lda affinetable_h,y
    sta ptr1+1

    stz Vera::Reg::Ctrl ; addrsel 0
    ; position data0
    stz Vera::Reg::AddrL
    lda #$10
    sta Vera::Reg::AddrM
    lda #$36 ; with blit bits
    sta Vera::Reg::AddrH 

    lda #%00000101 ; dcsel 2, addrsel 1
    sta Vera::Reg::Ctrl

    ; table contains
    ; base address of start pixel (2), addr1 dec bit, affine inc row (2), affine inc col (2)
    ldy #0
    lda (ptr1),y
    sta Vera::Reg::AddrL

    iny
    lda (ptr1),y
    sta Vera::Reg::AddrM

    iny
    lda Vera::Reg::AddrH
    and #%00000111
    ora (ptr1),y
    ora #$70
    sta Vera::Reg::AddrH

    iny
    lda (ptr1),y
    sta Vera::Reg::DCHSubIncL

    iny
    lda (ptr1),y
    sta Vera::Reg::DCHSubIncH

    iny
    lda (ptr1),y
    sta Vera::Reg::DCVSubIncL

    iny
    lda (ptr1),y
    sta Vera::Reg::DCVSubIncH

    ldx #64
rowloop:
    lda Vera::Reg::DCVSubIncH
    ora #$E0 ; reset sub px, and trigger next row
    sta Vera::Reg::DCVSubIncH

.repeat 16
    lda Vera::Reg::Data1
    lda Vera::Reg::Data1
    lda Vera::Reg::Data1
    lda Vera::Reg::Data1
    stz Vera::Reg::Data0
.endrepeat

    dex
    beq :+
    jmp rowloop
:

    lda iteration
    beq :+
    wai
:
    inc angle
    lda angle
    bne :+
    lda iteration
    beq :+
    dec iteration
:

    jmp angleloop


    rts

clowncar:
    .byte "CLOWNCAR.BIN.PAL"

