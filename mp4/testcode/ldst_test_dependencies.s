ldst_mp2test.s:
.align 4
.section .text
.globl _start

    lw x2, cooleceb # 60             # X1 <= 0x1111eceb
    addi x4, x0, 20
    addi x5, x0, 4
    add x6, x4, x5

    addi x6, x6, -10

    addi x3, x2, 1 # 68

done:
    lw x7, good # 6c
    addi x8, x7, 2 # 74
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt # 78  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.
deadend:
    lw x10, bad       
deadloop:
    beq x10, x10, deadloop

.section .rodata

bad:            .word 0xdeadbeef # addr 0?
good:           .word 0x600d600d # 4
result:         .word 0x00000000
eceb:           .word 0x0000eceb
ecebeceb:       .word 0xecebeceb
cooleceb:       .word 0xc001eceb
answer:         .word 0x78563412
answer_2:       .word 0x600deceb
answer_3:       .word 0xc001bead
answer_4:       .word 0x0000eceb
answer_5:       .word 0x00be00ad
target:         .word 0x00000000
target_2:       .word 0x00000008
idk:            .word 0x00022000
