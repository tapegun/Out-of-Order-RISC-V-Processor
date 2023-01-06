ldst_mp2test.s:
.align 4
.section .text
.globl _start

    lh x8, eceb             # X8 <= 0xffffeceb
    la x10, result          # X10 <= result_addr
    sh x8, 0(x10)           # result_addr = xxxx_eceb
    sh x8, 2(x10)           # result_addr = eceb_eceb
    lw x9, result           # check for correctness
    lw x11, ecebeceb
    bne x11, x9, deadend     

    bne x11, x9, deadend     

    beq x10, x9, deadend     

    beq x8, x9, deadend     

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
