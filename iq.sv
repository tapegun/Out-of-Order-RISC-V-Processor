module iq
(
    input logic clk,
    input logic rst,
    input ctl_word control_i,
    input logic res1_valid,
    input logic res2_valid,
    input logic res3_valid,
    input logic res4_valid,
    input logic resldst_valid,
    input logic rob_full,
    input logic ldst_q_full,

    output logic rob_load,
    output logic res1_load,
    output logic res2_load,
    output logic res3_load,
    output logic res4_load,
    output logic resldst_load,
    output ctl_word control_o
);

logic [3:0] res_snoop;
assign res_snoop = {res4_valid, res3_valid, res2_valid, res1_valid};

    
fifo instruction_queue 
(
    .clk_i(clk),
    .reset_n_i(~rst),
    .data_i(control_i),
    .valid_i(enqueue),
    .ready_o(issue_q_full_n),
    .valid_o(control_o_valid),
    .data_o(control_o),
    .yumi_i(dequeue)
);

always_comb begin 
    // if the issue queue isn't full, add the instruction
    enqueue = issue_q_full_n ? 1'b1: 1'b0;
    // if the fifo is holding a valid entry
    if (control_o_valid) begin 
        // for load store instructions
        if (control_o.op == STORE || control_o.op == LOAD) begin
            resldst_load = (resldst_valid && ~rob_full && ~ldst_q_full)? 1'b1 : 1'b0;
            dequeue = (resldst_valid && ~rob_full && ~ldst_q_full)? 1'b1 : 1'b0;
        end
        else begin
            res1_load = 1'b0;
            res2_load = 1'b0;
            res3_load = 1'b0;
            res4_load = 1'b0;

            dequeue = ((|res_snoop) && ~rob_full)? 1'b1 : 1'b0;

            unique case(res_snoop)
                4'b0001: begin
                    res1_load = (~rob_full)? 1'b1 : 1'b0;
                end
                4'b0010: begin
                    res2_load = (~rob_full)? 1'b1 : 1'b0;
                end
                4'b0100: begin
                    res3_load = (~rob_full)? 1'b1 : 1'b0;
                end
                4'b1000: begin
                    res4_load = (~rob_full)? 1'b1 : 1'b0;
                end
            endcase
        end

        // rob logic is the same as dequeue, reuse here instead of rechecking
        rob_load = dequeue? 1'b1 : 1'b0;
    end
end


endmodule : iq
