module testbench(
    tb_itf itf
    );
import rv32i_types::*;

IQ_2_IR iq_ir_itf();

logic ld_pc;
logic [31:0] pc;

ir ir (
    .*,
    .clk(itf.clk),
    .rst(~itf.reset_n),
    .instr_mem_resp(itf.instr_mem_resp),
    .in(itf.in),
    .pc(pc),
    .instr_mem_address(itf.instr_mem_address),
    .instr_read(itf.instr_read),
    .ld_pc(ld_pc)
    // ,.iq_ir_itf(iq_ir_itf.IQ_SIG)
);

pc_register PC (
        .clk (itf.clk),
        .rst (~itf.reset_n),
        .load(ld_pc),
        .in(pc + 4),
        .out(pc)
    );

iq iq (
    .*,
    .clk (itf.clk),
    .rst (~itf.reset_n),
    // .control_i (itf.control_i),
    .res1_empty(itf.res1_empty),
    .res2_empty(itf.res2_empty),
    .res3_empty(itf.res3_empty),
    .res4_empty(itf.res4_empty),
    .resldst_empty(itf.resldst_empty),
    .rob_full(itf.rob_full),
    .ldst_q_full(itf.ldst_q_full),
    // .enqueue(itf.enqueue),
    .regfile_tag1(itf.regfile_tag1),
    .regfile_tag2(itf.regfile_tag2),
    .rob_load(itf.rob_load),
    .res1_load(itf.res1_load),
    .res2_load(itf.res2_load),
    .res3_load(itf.res3_load),
    .res4_load(itf.res4_load),
    .resldst_load(itf.resldst_load),
    .control_o(itf.control_o)
    // ,.iq_ir_itf(iq_ir_itf.IR_SIG)
    // .issue_q_full_n(itf.issue_q_full_n),
    // .ack_o(itf.ack_o)
);

rob rob (
    .*,
    .clk (itf.clk),
    .rst (~itf.reset_n),
    .rob_load (itf.rob_load),
    .instr_type (itf.instr_type),
    .rd (itf.rd),
    .st_src (itf.sr_src),
    .branch_mispredict (itf.branch_mispredict),
    .data_mem_resp (itf.data_mem_resp),
    .rob0_valid (itf.rob0_valid),
    .rob1_valid (itf.rob1_valid),
    .rob2_valid (itf.rob2_valid),
    .rob3_valid (itf.rob3_valid),
    .rob4_valid (itf.rob4_valid),
    .rob5_valid (itf.rob5_valid),
    .rob6_valid (itf.rob6_valid),
    .rob7_valid (itf.rob7_valid),
    .rob_tag (itf.rob_tag), 
    .rd_inflight (itf.rd_inflight),
    .st_commit (itf.st_commit),
    .regfile_allocate (itf.regfile_allocate),
    .regfile_load (itf.regfile_load),
    .rob_full (itf.rob_full),
    .ld_commit_sel (itf.ld_commit_sel),
    .load_pc (itf.load_pc),
    .data_read (itf.data_read),
    .data_write (itf.data_write),
);
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, testbench, "+all");
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask
task set_init();
    itf.reset_n <= 1'b0;
    /* set up instruction cache to instruction register communication */
    itf.instr_mem_resp <= 1'b0;
    itf.in <= 32'h00000000;

    /* set up iq signals */
    itf.res1_empty <= 1'b0;
    itf.res2_empty <= 1'b0;
    itf.res3_empty <= 1'b0;
    itf.res4_empty <= 1'b0;
    itf.resldst_empty <= 1'b0;
    //itf.rob_full <= 1'b0;
    itf.ldst_q_full <= 1'b0;

endtask

task set_instr(logic [31:0] instr);
    /* here's a list of some instructions to load */
    /*
        32'h000170b3; and x1, x2, x0
        32'h0001f133; and x2, x3, x0
        32'h000271b3; and x3, x4, x0
        32'h00b08093; addi x1, x1, 11
        32'h00c10113; addi x2, x2, 12
        32'h00d18193; addi x3, x3, 13
    */
    itf.in <= instr;
    itf.instr_mem_resp <= 1'b1;
    @(tb_clk);
    itf.instr_mem_resp <= 1'b0;
    @(tb_clk);
endtask

task res_empty(bit res1_empty, bit res2_empty, bit res3_empty, bit res4_empty);
    itf.res1_empty <= res1_empty;
    itf.res2_empty <= res2_empty;
    itf.res3_empty <= res3_empty;
    itf.res4_empty <= res4_empty;
endtask

//task rob_full(bit rob_full);
//    itf.rob_full <= rob_full;
//endtask

// task set_init();
//     itf.reset_n <= 1'b0;
//     /* set up control word for res station */
//     itf.control_i.op <= tomasula_types::ARITH;
//     itf.control_i.src1_reg <= 8'h1;
//     itf.control_i.src1_valid <= 1'b0;
//     itf.control_i.src2_reg <= 8'h2;
//     itf.control_i.src2_valid <= 1'b0;
//     itf.control_i.funct3 <= 3'b000;
//     itf.control_i.funct7 <= 1'b0;
//     itf.control_i.rd <= 8'h3;
//     itf.control_i.imm <= 32'h0000;

//     /* set up cdb */
//     itf.cdb.tag = 3'b000;
//     itf.cdb.data = 3'b000;

//     /* set up other inputs */
//     itf.load_word <= 1'b0;
//     itf.rob_tag1 <= 3'b000;
//     itf.rob_tag2 <= 3'b000;
//     itf.rob_v1 <= 1'b0;
//     itf.rob_v2 <= 1'b0;
//     itf.alu_free <= 1'b0;
//     itf.src1 <= 32'h0000;
//     itf.src2 <= 32'h0000;

// endtask

// task load_res();
//     itf.load_word <= 1'b1;
//     @(tb_clk);
//     itf.load_word <= 1'b0;
//     @(tb_clk);
// endtask

// task set_cdb (input logic [2:0] tag, input logic [31:0] data);
//     itf.cdb.tag <= tag;
//     itf.cdb.data <= data;
// endtask

// task set_src_data (input logic [31:0] data1, input logic [31:0] data2);
//     itf.src1 <= data1;
//     itf.src2 <= data2;
// endtask

// task set_robs (input bit v1, input logic [2:0] rob_id_1, input bit v2, input logic [2:0] rob_id_2);
//     itf.rob_v1 <= v1;
//     itf.rob_tag1 <= rob_id_1;
//     itf.rob_v2 <= v2;
//     itf.rob_tag2 <= rob_id_2;
// endtask

// task set_alu (input bit set);
//     itf.alu_free <= set;
// endtask


initial begin
    $display("starting instruction queue test");

    set_init();
    reset();

    set_instr(32'h000170b3);
    set_instr(32'h0001f133);
    set_instr(32'h000271b3);
    set_instr(32'h00b08093);
    set_instr(32'h00c10113);
    set_instr(32'h00d18193);

    res_empty(1'b0, 1'b0, 1'b1, 1'b1);
    @(tb_clk);

    rob_full(1'b1);
    repeat (5) @(tb_clk);
    rob_full(1'b0);
    @(tb_clk);

    // set_src_data(5, 3);
    // set_robs (1'b1, 3'b001, 0, 3'b000);
    // @(tb_clk);

    // load_res();

    // repeat (10) @(tb_clk);
    // set_cdb (3'b001, 32'h0002);
    // repeat (2) @(tb_clk);
    // set_alu(1'b1);
    // @(tb_clk);



    itf.finish();

end

endmodule : testbench
