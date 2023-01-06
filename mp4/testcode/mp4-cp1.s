#  mp4-cp1.s version 4.0
.align 4
.section .text
.globl _start
_start:
pcrel_NEGTWO: auipc x10, %pcrel_hi(NEGTWO) # 60
pcrel_TWO: auipc x11, %pcrel_hi(TWO) # 64
pcrel_ONE: auipc x12, %pcrel_hi(ONE) # 68
    nop # 6c
    nop # 74 
    nop # 78
    nop # 7c
    nop # 80
    nop # 84
    nop # 88
    lw x1, %pcrel_lo(pcrel_NEGTWO)(x10) # 8c
    lw x2, %pcrel_lo(pcrel_TWO)(x11) # 90
    lw x4, %pcrel_lo(pcrel_ONE)(x12) # 94
    nop # 98
    nop # 9c
    nop # 9c
    nop # a0
    nop # a4
    nop # a8
    nop # ac
    beq x0, x0, LD_ST_TEST # b0
    nop
    nop
    nop
    nop
    nop
    nop
    nop # 28th

.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
BYTES:  .word 0x04030201
HALF:   .word 0x0020FFFF

.section .text
.align 4
LD_ST_TEST:
pcrel_BYTES: auipc x1, %pcrel_hi(BYTES)
pcrel_HALF: auipc x2, %pcrel_hi(HALF)
    nop
    nop
    nop
    nop
    nop
    nop
    addi x1, x1, %pcrel_lo(pcrel_BYTES)
    addi x2, x2, %pcrel_lo(pcrel_HALF)
    nop
    nop
    nop
    nop
    nop
    nop
    lb x3, 0(x1) # 45th
    lb x4, 2(x1)
    lb x5, 3(x1)
    lh x6, 0(x2)
    lh x7, 2(x2)
    nop
    nop
    nop
    nop
    nop
    nop
    add x8, x3, x4
    bgt x6, x0, BADBAD
    nop
    nop
    nop
    nop
    nop
    nop
    bne x5, x8, BADBAD
    nop
    nop
    nop
    nop
    nop # 69th


LOOP:
pcrel_TEMP1_1: auipc x13, %pcrel_hi(TEMP1)
pcrel_TEMP1_2: auipc x14, %pcrel_hi(TEMP1)
    add x3, x1, x2 # X3 <= X1 + X2
    and x5, x1, x4 # X5 <= X1 & X4
    not x6, x1     # X6 <= ~X1
    nop # 75
    nop
    nop
    addi x9, x13, %pcrel_lo(pcrel_TEMP1_1) # X9 <= address of TEMP1 # 78th
    nop
    nop
    nop
    nop
    nop
    nop
    sw x6, 0(x9)   # TEMP1 <= x6
    lw x7, %pcrel_lo(pcrel_TEMP1_2)(x14) # X7    <= TEMP1
    add x1, x1, x4 # X1    <= X1 + X4
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    blt x0, x1, DONEa
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    beq x0, x0, LOOP
    nop
    nop
    nop
    nop
    nop
    nop
    nop
BADBAD:
pcrel_BADD: auipc x15, %pcrel_hi(BADD)
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    lw x1, %pcrel_lo(pcrel_BADD)(x15)
HALT:
    beq x0, x0, HALT
    nop
    nop
    nop
    nop
    nop
    nop
    nop

DONEa:
pcrel_GOOD: auipc x16, %pcrel_hi(GOOD)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    # adding code
    # addi x23, x16, %pcrel_lo(pcrel_GOOD) # X9 <= address of TEMP1 # 78th
    # and x1, x0, x0
    # addi x1, x1, 4
    # sw x1, 0(x23)
    # done adding code
    lw x1, %pcrel_lo(pcrel_GOOD)(x16)
DONEb:
    beq x0, x0, DONEb
    nop
    nop
    nop
    nop
    nop
    nop
    nop
