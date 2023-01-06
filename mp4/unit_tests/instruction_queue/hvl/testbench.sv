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

logic [31:0] pc_in;
always_comb begin : pc_mux
    if (itf.ld_br)
        pc_in = itf.cdb_out[itf.head_ptr].data[31:0];
    else 
        pc_in = pc + 4;
end

pc_register PC (
        .clk (itf.clk),
        .rst (~itf.reset_n),
        .load(ld_pc | itf.ld_br),
        .in(pc_in),
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
    .rob_full(itf.rob_full),
    .resbr_empty(itf.resbr_empty),
    .resbr_load(itf.resbr_load),
    .rob_load(itf.rob_load),
    .res1_load(itf.res1_load),
    .res2_load(itf.res2_load),
    .res3_load(itf.res3_load),
    .res4_load(itf.res4_load),
    .control_o(itf.control_o)
    // ,.iq_ir_itf(iq_ir_itf.IR_SIG)
    // .issue_q_full_n(itf.issue_q_full_n),
    // .ack_o(itf.ack_o)
);

always_comb begin : set_rob_valids
    for (int i = 0; i < 8; i++) begin
        itf.set_rob_valid[i] = 1'b0;
    end
    if (itf.res1_exec) begin
        itf.set_rob_valid[itf.res1_alu_out.tag] = 1'b1;
    end
    if (itf.res2_exec) begin
        itf.set_rob_valid[itf.res2_alu_out.tag] = 1'b1;
    end
    if (itf.res3_exec) begin
        itf.set_rob_valid[itf.res3_alu_out.tag] = 1'b1;
    end
    if (itf.res4_exec) begin
        itf.set_rob_valid[itf.res4_alu_out.tag] = 1'b1;
    end
end

rob rob (
     .*,
     .clk (itf.clk),
     .rst (~itf.reset_n),
     .rob_load (itf.rob_load),
     .instr_type (itf.control_o.op),
     .rd (itf.control_o.rd),
     .st_src (itf.control_o.src1_reg),
     .branch_mispredict (1'b0),
     .data_mem_resp (1'b0),
     .status_rob_valid (itf.status_rob_valid),
     .set_rob_valid (itf.set_rob_valid),
     .curr_ptr (itf.curr_ptr), 
     .head_ptr (itf.head_ptr), 
     .br_ptr (itf.br_ptr), 
     .rd_commit (itf.rd_commit),
     .st_src_commit (itf.st_src_commit),
     .regfile_load (itf.regfile_load),
     .rob_full (itf.rob_full),
     .ld_commit_sel (itf.ld_commit_sel),
     .ld_br (itf.ld_br),
     .data_read (itf.data_read),
     .data_write (itf.data_write)
 );

 /*rob
    //////////////////////////////////////////////////////
    // rob_tag | instr_type | rob_valid | rd | valid    //                                    //
    //                                                  //
    //                                                  //
    //                                                  //
    //////////////////////////////////////////////////////
 */


logic [31:0] regfile_in, ld_data;
assign ld_data = 32'h600d600d;
always_comb begin 
    if (itf.ld_commit_sel) 
        regfile_in = ld_data;
    else 
        regfile_in = itf.cdb_out[itf.head_ptr].data[31:0];
end

logic [31:0] data_mem_wdata;
regfile regfile (
    .*,
    .clk (itf.clk),
    .rst (~itf.reset_n),
    .load (itf.regfile_load),
    .allocate (itf.rob_load), // rob_load from instruction queue, more appropiate to call it allocate
    .reg_allocate (itf.control_o.rd), // gets register to allocate from control word of instruction queue
    .in (regfile_in),
    // from iq - sources to read
    .src_a (itf.control_o.src1_reg),
    .src_b (itf.control_o.src2_reg),
    // from iq - dest to write to
    .dest (itf.rd_commit), 
    .tag_in (itf.curr_ptr),
    .reg_a (itf.reg_src1_data),
    .reg_b (itf.reg_src2_data),
    .valid_a (itf.src1_valid),
    .valid_b (itf.src2_valid),
    .tag_a (itf.tag_a),
    .tag_b (itf.tag_b),
    .src_c (itf.st_src_commit),
    .data_out (data_mem_wdata)
);
tomasula_types::res_word res_word;
logic [31:0] src2_data;
logic src2_v;
assign src2_v = itf.src2_valid | itf.control_o.src2_valid;
assign src2_data = itf.control_o.src2_valid ? itf.control_o.src2_data : itf.reg_src2_data;

always_comb begin : assign_res_word
    res_word.op = itf.control_o.op;
    res_word.funct3 = itf.control_o.funct3;
    res_word.funct7 = itf.control_o.funct7;
    res_word.src1_tag = itf.tag_a;
    res_word.src1_data = itf.reg_src1_data;
    res_word.src1_valid = itf.src1_valid;
    res_word.src2_tag = itf.tag_b;
    res_word.src2_data = src2_data;
    res_word.src2_valid = src2_v;
    res_word.rd_tag = itf.curr_ptr;
    res_word.pc = itf.control_o.pc;
end

reservation_station res1(
    .clk (itf.clk),
    .rst(~itf.reset_n),
    .load_word(itf.res1_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .alu_data(itf.res1_alu_out),
    .start_exe(itf.res1_exec),
    .res_empty(itf.res1_empty),
    .res_in(res_word)
);

alu alu1(
    .alu_word(itf.res1_alu_out),
    .cdb_data(itf.alu1_calculation)
);

reservation_station res2(
    .clk (itf.clk),
    .rst(~itf.reset_n),
    .load_word(itf.res2_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .alu_data(itf.res2_alu_out),
    .start_exe(itf.res2_exec),
    .res_empty(itf.res2_empty),
    .res_in(res_word)
);

alu alu2(
    .alu_word(itf.res2_alu_out),
    .cdb_data(itf.alu2_calculation)
);

reservation_station res3(
    .clk (itf.clk),
    .rst(~itf.reset_n),
    .load_word(itf.res3_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .alu_data(itf.res3_alu_out),
    .start_exe(itf.res3_exec),
    .res_empty(itf.res3_empty),
    .res_in(res_word)
);

alu alu3(
    .alu_word(itf.res3_alu_out),
    .cdb_data(itf.alu3_calculation)
);

reservation_station res4(
    .clk (itf.clk),
    .rst(~itf.reset_n),
    .load_word(itf.res4_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .alu_data(itf.res4_alu_out),
    .start_exe(itf.res4_exec),
    .res_empty(itf.res4_empty),
    .res_in(res_word)
);

alu alu4(
    .alu_word(itf.res4_alu_out),
    .cdb_data(itf.alu4_calculation)
);

logic [7:0] cdb_enable;
always_comb begin : cdb_enable_logic
    // set default values to 0
    for (int i = 0; i < 8; i++) begin
        itf.cdb_in[i].data[31:0] = 32'h00000000;
    end
    itf.cdb_in[itf.res1_alu_out.tag].data[31:0] = itf.alu1_calculation.data[31:0];
    itf.cdb_in[itf.res2_alu_out.tag].data[31:0] = itf.alu2_calculation.data[31:0];
    itf.cdb_in[itf.res3_alu_out.tag].data[31:0] = itf.alu3_calculation.data[31:0];
    itf.cdb_in[itf.res4_alu_out.tag].data[31:0] = itf.alu4_calculation.data[31:0];
    
    cdb_enable[7:0] = 8'h00 | (itf.res1_exec << itf.res1_alu_out.tag) | (itf.res2_exec << itf.res2_alu_out.tag) | (itf.res3_exec << itf.res3_alu_out.tag) | (itf.res4_exec << itf.res4_alu_out.tag);
end

cdb cdb(
    .ctl(itf.cdb_in),
    .enable(cdb_enable),
    .rst(~itf.reset_n),
    .out(itf.cdb_out[0:7])
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
    // itf.res1_empty <= 1'b0;
    // itf.res2_empty <= 1'b0;
    // itf.res3_empty <= 1'b0;
    // itf.res4_empty <= 1'b0;
    // itf.regfile_tag1 <= 5'b00000;
    // itf.regfile_tag2 <= 5'b00000;
    //itf.rob_full <= 1'b0;

    /* regfile */
    // itf.reg_src1_data <= 32'h00000000;
    // itf.reg_src2_data <= 32'h00000000;

    /* rob signals */
    // itf.rd_rob_tag <= 5'b00000;

    // for (int i = 0; i < 8; ++i) begin
    //     itf.robs_calculated[i] <= 1'b0;
    // end

    /* cdb signals */
    // for (int i = 0; i < 8; ++i) begin
    //     // itf.cdb[i].tag <= 3'b000;
    //     itf.cdb[i].data <= 32'h00000000;
    // end

endtask

// task robs_calc (logic [7:0] valids);
//     itf.robs_calculated[0] <= valids[0];
//     itf.robs_calculated[1] <= valids[1];
//     itf.robs_calculated[2] <= valids[2];
//     itf.robs_calculated[3] <= valids[3];
//     itf.robs_calculated[4] <= valids[4];
//     itf.robs_calculated[5] <= valids[5];
//     itf.robs_calculated[6] <= valids[6];
//     itf.robs_calculated[7] <= valids[7];
// endtask

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

    // res_empty(1'b0, 1'b0, 1'b1, 1'b1);
    // robs_calc(8'b11111111);
    @(tb_clk);

    

    // rob_full(1'b1);
    // repeat (5) @(tb_clk);
    // rob_full(1'b0);
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
