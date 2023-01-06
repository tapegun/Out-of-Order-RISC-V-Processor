riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style

     and x1, x2, x0 # 60
     and x2, x3, x0 # 64
     and x3, x4, x0 # 68
     addi x2, x2, 1 # 6c

    beq x1, x2, branch_label # 70

    addi x5, x3, 3 # 74
    addi x3, x3, 4 # 78
    addi x3, x3, 5 # 7c
    addi x3, x3, 5 # 80
    addi x3, x3, 5 # 84
    addi x3, x3, 5 # 88
    
    auipc x7, 0 # 8c # test of auipc and jalr to go to halt # jal x1, halt # 8c
    jalr x1, x7, 16 # 90 next instruction goes to in x1, use address in x7 and offset that goes to halt

branch_label:
    addi x3, x3, 7 # 90
    addi x3, x3, 7 # 94

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt # jal:98 jalr: 9c # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
