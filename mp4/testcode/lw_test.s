ldst_mp2test.s:
.align 4
.section .text
.globl _start

    la x1, result               # X1 <= addr(result)
    lw x2, cooleceb             # X2 <= 0xc001eceb
    sh x2, 0(x1)                # result <= c001eceb
    lw x3, result               # X3 <= c001eceb

done:
    lw x7, good
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
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
