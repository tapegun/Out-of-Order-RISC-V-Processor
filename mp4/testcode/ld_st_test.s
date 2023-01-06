riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.

    
TEMP1:  .word 0x00000001

_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style

    and x1, x2, x0 # 60
    and x2, x3, x0 # 64
    and x3, x4, x0 # 68
    addi x2, x2, 1 # 6c
    not x2, x2      # 70
    addi x3, x3, 1 # 74

    
    pcrel_TEMP1_1: auipc x13, %pcrel_hi(TEMP1)
    pcrel_TEMP1_2: auipc x14, %pcrel_hi(TEMP1)
    ; and x9, x9, x0
    addi x9, x13, %pcrel_lo(pcrel_TEMP1_1) # X9 <= address of TEMP1
    sw x3, 0(x9)   # TEMP1 <= x6

    # sw x6, 0(x2)   # TEMP1 <= x6 78

    # beq x1, x2, branch_label # 70

    # jal x1, halt # 8c

    
    and x1, x2, x0 # 60
    and x2, x3, x0 # 64
    and x3, x4, x0 # 68


branch_label:
    addi x3, x3, 7 # 90
    addi x3, x3, 7 # 94

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt # 98  # from trying to execute the data below.
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
