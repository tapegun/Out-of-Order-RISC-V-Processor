#  mp4-cp2.s version 1.3
.align 4
.section .text
.globl _start
_start:

#   Your pipeline should be able to do hazard detection and forwarding.
#   Note that you should not stall or forward for dependencies on register x0 or when an
#   instruction does not use one of the source registers (such as rs2 for immediate instructions).

# Mispredict taken branch flushing tests
taken_branches:
    beq x0, x0, forward_br # 60
    lw x7, BAD # 64

backward_br:
    beq x0, x0, not_taken_branches # 6c NOTE THHAT LOADS TAKE UP 2 PC's (one for auipc, one for the actual load)
    beq x0, x0, oof # 70                    # Also, test back-to-back branches

forward_br:
    beq x0, x0, backward_br # 74
    lw x7, BAD # 78

# Mispredict not-taken branch flushing tests
not_taken_branches:
    add x1, x0, 1 # 80                      # Also, test branching on forwarded value :) 
    beq x0, x1, oof # 84                    # Don't take 

    beq x0, x0, backward_br_nt # 88         # Take 


forwarding_tests:
    # Forwarding x0 test
    add x3, x3, 1 # 8c
    add x0, x1, 0 # 90
    add x2, x0, 0 # 94

    beq x2, x3, oof # 98

    # Forwarding sr2 imm test
    add x2, x1, 0   # 9c
    add x3, x1, 2   # a0                  # 2 immediate makes sr2 bits point to x2
    add x4, x0, 3   # a4

    bne x3, x4, oof # a8                   # Also, test branching on 2 forwarded values :)

    # MEM -> EX forwarding with stall
    lw x1, NOPE
    lw x1, A
    add x5, x1, x0                     # Necessary forwarding stall

    bne x5, x1, oof

    # WB -> MEM forwarding test
    add x3, x1, 1 # 2
    la x8, TEST
    sw  x3, 0(x8)
    lw  x4, TEST

    bne x4, x3, oof


    # Half word forwarding test
    lh  x2, FULL
    add x3, x0, -1

    bne x3, x2, oof

    # Cache miss control test
    add x4, x0, 3
    lw  x2, B                          # Cache miss
    add x3, x2, 1                      # Try to forward from cache miss load

    bne x4, x3, oof

    # Forwarding contention test
    add x2, x0, 1
    add x2, x0, 2
    add x3, x2, 1

    beq x3, x2, oof

    lw x7, GOOD

halt:
    beq x0, x0, halt
    lw x7, BAD

oof:
    lw x7, BAD
    lw x2, PAY_RESPECTS
    beq x0, x0, halt

backward_br_nt:
    beq x0, x1, oof                    # Don't take

    beq x0, x0, forwarding_tests       # Take



.section .rodata
.balign 256
DataSeg:
    nop
    nop
    nop
    nop
    nop
    nop
BAD:            .word 0x00BADBAD
PAY_RESPECTS:   .word 0xFFFFFFFF
# cache line boundary - this cache line should never be loaded

A:      .word 0x00000001
GOOD:   .word 0x600D600D
NOPE:   .word 0x00BADBAD
TEST:   .word 0x00000000
FULL:   .word 0xFFFFFFFF
        nop
        nop
        nop
# cache line boundary

B:      .word 0x00000002
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

C:      .word 0x00000003
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

D:      .word 0x00000004
        nop
        nop
        nop
        nop
        nop
        nop
        nop
