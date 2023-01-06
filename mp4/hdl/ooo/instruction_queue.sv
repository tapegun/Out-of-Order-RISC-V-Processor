`ifndef iq
`define iq
module iq
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic flush_ip,

    input logic res1_empty,
    input logic res2_empty,
    input logic res3_empty,
    input logic res4_empty,
    input logic resbr_empty,
    input logic lsq_empty,
    input logic rob_full,

    output logic rob_load,
    output logic regfile_allocate,
    output logic res1_load,
    output logic res2_load,
    output logic res3_load,
    output logic res4_load,
    output logic resbr_load,
    output logic lsq_load,
    output tomasula_types::ctl_word control_o,

    /* outputs to ROB for rvfi monitor */
    output logic [31:0] original_instr,
    output logic [31:0] instr_pc,
    output logic [31:0] instr_next_pc,

    output rv32i_types::rvfi_word rvfi_wrd,

    output logic ack_o,

    IQ_2_IR.IQ_SIG iq_ir_itf
);


logic [3:0] res_snoop;
logic control_o_valid, dequeue, enqueue;
tomasula_types::ctl_word control_o_buf;
assign res_snoop = {res4_empty, res3_empty, res2_empty, res1_empty};

logic ready_o;
assign ready_o = iq_ir_itf.issue_q_full_n & ~rst; // if fifo is ready and instruction queue is not getting reset/flushed

always_comb begin : control_o_logic
    if (control_o_valid)
        control_o = control_o_buf;
    else begin
        control_o.opcode = tomasula_types::s_op_invalid;
        control_o.src1_reg = 5'b00000;
        control_o.src1_valid = 1'b0;
        control_o.src2_reg = 5'b00000;
        control_o.src2_valid = 1'b0;
        control_o.src2_data = 32'h00000000;
        control_o.funct3 = 3'b000;
        control_o.funct7 = 1'b0;
        control_o.pc = 32'h00000000;
        control_o.og_pc = 32'h00000000;
        control_o.og_instr = 32'h00000000;
    end

    /* assign outputs to ROB for rvfi monitor */
    original_instr = control_o.og_instr;
    instr_pc = control_o.og_pc;
    instr_next_pc = control_o.pc;
end


    
fifo_synch_1r1w #(.DTYPE(tomasula_types::ctl_word)) instruction_queue
(
    .clk_i(clk),
    .reset_n_i(~rst),
    .data_i(iq_ir_itf.control_word),
    .valid_i(enqueue),
    .ready_o(iq_ir_itf.issue_q_full_n),
    .valid_o(control_o_valid),
    .data_o(control_o_buf),
    .yumi_i(dequeue)
);

fifo_synch_1r1w #(.DTYPE(rv32i_types::rvfi_word)) rvfi_queue (
    .clk_i(clk),
    .reset_n_i(~rst),
    .data_i(iq_ir_itf.rvfi),
    .valid_i(enqueue),
    .ready_o(),
    .valid_o(),
    .data_o(rvfi_wrd),
    .yumi_i(dequeue)
);

always_comb begin : enqueue_logic 

    ack_o = 1'b0; // by default
    enqueue = 1'b0;

    if (iq_ir_itf.ld_iq) begin
        if (ready_o) begin
            enqueue = 1'b1;
            ack_o = 1'b1;
        end
    end

end

always_comb begin : dequeue_logic
    // default values 
    res1_load = 1'b0;
    res2_load = 1'b0;
    res3_load = 1'b0;
    res4_load = 1'b0;
    dequeue = 1'b0;
    resbr_load = 1'b0;
    lsq_load = 1'b0;
    regfile_allocate = 1'b0;

    // if the fifo is holding a valid entry
    if (control_o_valid & ~flush_ip) begin 
        // if the rob has space and instruction queue has is not empty
        if (~rob_full) begin
            // branch goes to branching unit
            if (control_o_buf.opcode == tomasula_types::s_op_br) begin
                if (resbr_empty) begin
                    dequeue = 1'b1;
                    resbr_load = 1'b1;
                end
            end
            // the instruction is a load/store
            else if (control_o_buf.opcode == tomasula_types::s_op_load | control_o_buf.opcode == tomasula_types::s_op_store) begin
                if (lsq_empty) begin
                    if (control_o_buf.opcode == tomasula_types::s_op_load)
                        regfile_allocate = 1'b1;
                    dequeue = 1'b1;
                    lsq_load = 1'b1;
                end
            end
            else if (((control_o_buf.opcode == tomasula_types::s_op_imm) | (control_o_buf.opcode == tomasula_types::s_op_reg)) & ((arith_funct3_t'(control_o_buf.funct3) == slt) | (arith_funct3_t'(control_o_buf.funct3) == sltu))) begin
                if (res3_empty | res4_empty) begin
                    // dequeue the instruction
                    dequeue = 1'b1;
                    // allocate destination tag in the register file
                    regfile_allocate = 1'b1;

                    // find out which reservation station to route to
                    if (res_snoop[2])
                        res3_load = 1'b1;
                    else if (res_snoop[3])
                        res4_load = 1'b1;
                end
            end
            else begin
                if (res1_empty | res2_empty) begin
                    // dequeue the instruction
                    dequeue = 1'b1;

                    // allocate to register file
                    regfile_allocate = 1'b1;

                    // find out which reservation station to route to
                    if (res_snoop[0])
                        res1_load = 1'b1;
                    else if (res_snoop[1])
                        res2_load = 1'b1;
                end
            end
        end
    end
    // rob logic is the same as dequeue, reuse here instead of rechecking
    rob_load = dequeue;
end


endmodule : iq

`endif
