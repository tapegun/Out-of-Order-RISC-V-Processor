ldst_mp2test.s:
.align 4
.section .text
.globl _start

    lw x2, cooleceb # 60             # X1 <= 0x1111eceb
    lw x3, ecebeceb # 68
    lw x4, eceb # 70
    lw x5, answer # 78
    lw x6, answer_2 # 80
    lw x8, answer_3 # 88
    la x1, result
    sw x2, 0(x1)
    sw x3, 0(x1)
    sw x4, 0(x1)
    sw x5, 0(x1)
    sw x6, 0(x1)
    sw x8, 0(x1)

done:
    lw x7, good # 68
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt # 70  # from trying to execute the data below.
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
