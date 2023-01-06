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

    lhu x8, eceb            # X8 <= 0x0000eceb
    la x10, result          # X10 <= result_addr
    sh x8, 0(x10)           # result_addr = xxxx_eceb
    sh x8, 2(x10)           # result_addr = eceb_eceb
    lw x9, result           # check for correctness
    lw x11, ecebeceb
    bne x11, x9, deadend     

    lw x2, answer_3         # X2 <= 0xc001bead
    la x1, target           # X1 <= target_addr
    sw x2, 0(x1)            # target_addr = 0xc001bead
    lw x3, target           # check for correctness
    bne x2, x3, deadend     # 
   
    la x20, cooleceb
    lbu x4, 2(x20)
    lbu x2, 0(x20)
    lb x5, 3(x20)
    lb x3, 1(x20)

    la x1, target
    sh x2, 0(x1)
    sb x3, 1(x1)
    sb x5, 3(x1)
    sb x4, 2(x1)
     
    lw x10, cooleceb
    lw x6, target
    bne x10, x6, deadend

    lw x14, idk
    lw x15, 0(x14)

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
