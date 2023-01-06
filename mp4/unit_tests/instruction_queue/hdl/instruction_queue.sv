`ifndef iq
`define iq
module iq
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    // input tomasula_types::ctl_word control_i,
    input logic res1_empty,
    input logic res2_empty,
    input logic res3_empty,
    input logic res4_empty,
    input logic resbr_empty,
    input logic rob_full,
    // input logic enqueue,

    // output logic [4:0] regfile_tag1, // register one index in regfile
    // output logic [4:0] regfile_tag2, // register two index in regfile
    output logic rob_load,
    output logic res1_load,
    output logic res2_load,
    output logic res3_load,
    output logic res4_load,
    output logic resbr_load,
    output tomasula_types::ctl_word control_o,
    // output logic issue_q_full_n,
    // output logic ack_o,

    IQ_2_IR.IQ_SIG iq_ir_itf
);

/* NOTE:
don't send rob_load/allocate to register file for a branch
*/

logic [3:0] res_snoop;
logic control_o_valid, dequeue, enqueue;
tomasula_types::ctl_word control_o_buf;
assign res_snoop = {res4_empty, res3_empty, res2_empty, res1_empty};

logic ready_o;
assign ready_o = iq_ir_itf.issue_q_full_n;
// assign control_o = control_o_buf;

always_comb begin : control_o_logic
    if (control_o_valid)
        control_o = control_o_buf;
    else begin
        control_o.op = tomasula_types::BRANCH;
        control_o.src1_reg = 5'b00000;
        control_o.src1_valid = 1'b0;
        control_o.src2_reg = 5'b00000;
        control_o.src2_valid = 1'b0;
        control_o.src2_data = 32'h00000000;
        control_o.funct3 = 3'b000;
        control_o.funct7 = 1'b0;
        control_o.rd = 5'b00000;
        control_o.pc = 32'h00000000;
    end
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

always_comb begin : enqueue_logic 

    iq_ir_itf.ack_o = 1'b0; // by default
    enqueue = 1'b0;

    if (iq_ir_itf.ld_iq) begin
        if (ready_o) begin
            enqueue = 1'b1;
            iq_ir_itf.ack_o = 1'b1;
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

    // if the fifo is holding a valid entry
    if (control_o_valid) begin 
        // if the rob has space
        if (~rob_full) begin
            // branch goes to branching unit
            if (control_o_buf.op == tomasula_types::BRANCH) begin
                if (resbr_empty) begin
                    dequeue = 1'b1;
                end
            end
            else begin
                if (res1_empty | res2_empty | res3_empty | res4_empty) begin
                    // dequeue the instruction
                    dequeue = 1'b1;
               
                    // send read signals to the regfile
                    // regfile_tag1 = control_o_buf.src1_reg;
                    // regfile_tag2 = control_o_buf.src2_reg;

                    // assign the output to the output of the queue
                    // control_o = control_o_buf;

                    // find out which reservation station to route to
                    if (res_snoop[0])
                        res1_load = 1'b1;
                    else if (res_snoop[1])
                        res2_load = 1'b1;
                    else if (res_snoop[2])
                        res3_load = 1'b1;
                    else if (res_snoop[3])
                        res4_load = 1'b1;
                end
            end
        end
    end
    // rob logic is the same as dequeue, reuse here instead of rechecking
    rob_load = dequeue;
end


endmodule : iq

`endif
