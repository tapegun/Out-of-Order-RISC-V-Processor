jalr_test.s:
.align 4
.section .text
.globl _start

_start:
    addi x4, x0, 5
    call jump_one
    jr ra





.L1:
    ret
    .globl jump_one
    .hidden jump_one
    .type jump_one, @function
jump_one:
    addi x4, x4, 1
    addi x4, x4, 1
    addi x4, x4, 1
    addi x4, x4, 1
    addi x4, x4, 1
    ret