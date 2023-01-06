ldst_mp2test.s:
.align 4
.section .text
.globl _start

    lw x2, cooleceb # 60            
    lw x3, ecebeceb # 68    
    lw x6, four        
    ; lw x4, target # 70             

# test 1 branch padded with loads everywhere -- not taken      
    lw x4, one # 70      
    beq x2, x3, load_not_taken
    lw x4, two #   
    sw x4, 0(store_slot)    # store slot should have 2
    ld x5, store_slot    # x5 should have 2

# test 2 branch padded with loads everywhere -- taken      
    lw x4, one # 70      
    beq x2, x2, load_taken_1
    lw x4, four 
    beq x0, x0, halt    
load_taken_1:
    lw x4, three # 78  
    sw x4, 0(store_slot)    # store slot should have 3 and no 2 before this
    ld x5, store_slot    # x5 should have 3

# test 3 
    beq x0, x0 load_taken_2
    sw x6, store_slot
    
load_taken_2:
    ld store_slot # if this is 3 good job, if its 4 that means we stored the above line by accident



load_not_taken:
    lw x4, four # 78  // 
    beq x0, x0, halt

done:
    lw x7, good # 68
    addi x8, x7, 2
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
one:            .word 0x00000001
two:            .word 0x00000002
three:          .word 0x00000003
four:           .word 0x00000004
store_slot:     .word 0x00000000


