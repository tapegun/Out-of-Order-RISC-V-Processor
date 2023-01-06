
module ooo
import rv32i_types::*;
(
    input clk,
    input rst,
	
    input 					instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 					data_mem_resp,
    input rv32i_word 	data_mem_rdata, 
    output logic 			instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 			data_read,
    output logic 			data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata
);

/***************************************** Listing all signals *****************************************/
/* interface between instruction queue and instruction register */
IQ_2_IR iq_ir_itf();

/* harness containing all module signals */
debug_itf itf();

/***************************************** Modules ***************************************************/

logic [31:0] regfile_mem_in;

`define write_to_cdb(RES_STATION_EXEC, ALU_OUT, DATA_SEL, ALU_DATA) \
    if (``RES_STATION_EXEC) begin \
            itf.cdb_in[``ALU_OUT.tag].data[31:0] = ``DATA_SEL? ``ALU_OUT.pc : ``ALU_DATA; \
            itf.cdb_in[``ALU_OUT.tag].rs1_data[31:0] = ``ALU_OUT.src1_data[31:0]; \
            itf.cdb_in[``ALU_OUT.tag].rs2_data[31:0] = ``ALU_OUT.src2_data[31:0]; \
        end

logic [1:0] memaddr_offset; 

always_comb begin : data_mem_req

    data_mem_address = itf.lsq_data_mem_address & {{30{1'b1}}, 2'b00};
    memaddr_offset = itf.lsq_data_mem_address[1:0];
    
    case(load_funct3_t'(itf.lsq_load_type))
        lw: regfile_mem_in = data_mem_rdata; 
        lh: regfile_mem_in = {{16{data_mem_rdata[16 * ((memaddr_offset/2)+1) - 1]}}, data_mem_rdata[8 * memaddr_offset+:16]};
        lhu: regfile_mem_in = {{16{1'b0}}, data_mem_rdata[8 * memaddr_offset+:16]}; 
        lb: regfile_mem_in = {{24{data_mem_rdata[(8 * (memaddr_offset+1)) - 1]}}, data_mem_rdata[8 * memaddr_offset+:8]}; 
        lbu: regfile_mem_in = {{24{1'b0}}, data_mem_rdata[8 * memaddr_offset+:8]}; 
        default: regfile_mem_in = data_mem_rdata; 
    endcase 

end

always_comb begin : jalr_pc_wdata 
    itf.jalr_pc = 32'h00000000;
    itf.jalr_tag = 5'b00000;
    itf.jalr_executed = itf.res1_jalr_executed | itf.res2_jalr_executed | itf.res3_jalr_executed | itf.res4_jalr_executed;
    if (itf.res1_jalr_executed) begin
        itf.jalr_pc = itf.alu1_calculation.data[31:0];
        itf.jalr_tag = itf.res1_jalr_tag;
    end
    if (itf.res2_jalr_executed) begin
        itf.jalr_pc = itf.alu2_calculation.data[31:0];
        itf.jalr_tag = itf.res2_jalr_tag;
    end
    if (itf.res3_jalr_executed) begin
        itf.jalr_pc = itf.alu3_calculation.data[31:0];
        itf.jalr_tag = itf.res3_jalr_tag;
    end
    if (itf.res4_jalr_executed) begin
        itf.jalr_pc = itf.alu4_calculation.data[31:0];
        itf.jalr_tag = itf.res4_jalr_tag;
    end
end

ir ir (
    .*,
    .clk(clk),
    .rst(rst),
    .instr_mem_resp(instr_mem_resp),
    .in(instr_mem_rdata),
    .executed_jalr_one(itf.res1_jalr_executed),
    .executed_jalr_two(itf.res2_jalr_executed),
    .executed_jalr_three(itf.res3_jalr_executed),
    .executed_jalr_four(itf.res4_jalr_executed),
    .jalr_pc_one(itf.alu1_calculation.data[31:0]),
    .jalr_pc_two(itf.alu2_calculation.data[31:0]),
    .jalr_pc_three(itf.alu3_calculation.data[31:0]),
    .jalr_pc_four(itf.alu4_calculation.data[31:0]),
    .br_pr_take (1'b0),
    .flush_ip(itf.flush_in_prog),
    .instr_mem_address(instr_mem_address),
    .instr_read(instr_read),
    .pc_calc(itf.pc_calc),
    .iq_ack(itf.iq_ir_ack),
    .curr_instr(itf.ir_instr),
    .ld_br_pc(itf.rob_ld_pc),
    .br_pc(itf.cdb_out[itf.br_ptr].data[31:0])
);

iq iq (
    .*,
    .clk (clk),
    .rst (rst | itf.flush_in_prog),
    .flush_ip(itf.flush_in_prog),
    .res1_empty(itf.res1_empty),
    .res2_empty(itf.res2_empty),
    .res3_empty(itf.res3_empty),
    .res4_empty(itf.res4_empty),
    .lsq_empty(~itf.lsq_full),
    .rob_full(itf.rob_full),
    .resbr_empty(itf.resbr_empty),
    .resbr_load(itf.resbr_load),
    .rob_load(itf.rob_load),
    .regfile_allocate(itf.regfile_allocate),
    .res1_load(itf.res1_load),
    .res2_load(itf.res2_load),
    .res3_load(itf.res3_load),
    .res4_load(itf.res4_load),
    .lsq_load(itf.lsq_load),
    .control_o(itf.control_o),
    .ack_o(itf.iq_ir_ack),
    .original_instr(itf.original_instr),
    .instr_pc(itf.original_instr_pc),
    .instr_next_pc(itf.original_instr_next_pc),
    .rvfi_wrd(itf.rvfi_wrd)
);

rob rob (
     .*,
     .clk (clk),
     .rst (rst),
     .rob_load (itf.rob_load),
    .instr_type(itf.control_o.opcode),
     .rd (itf.control_o.rd),
     .st_src (itf.control_o.src2_reg),
     .data_mem_resp (data_mem_resp),
     .status_rob_valid (itf.status_rob_valid),
     .set_rob_valid (itf.set_rob_valid),
     .set_reg_valid(itf.set_reg_valid),
     .reg_valid(itf.reg_valid),
     .invalidated_n(itf.rob_invalidated_entries),
     .br_entry(itf.resbr_alu_out.tag),
     .br_taken(itf.taken),
     .update_br(itf.resbr_update_br),
     .curr_ptr (itf.curr_ptr), 
     .head_ptr (itf.head_ptr), 
     .rd_updated(itf.rd_updated),
     .br_ptr (itf.br_ptr), 
     .br_flush_ptr(itf.br_flush_ptr),
     .flush_in_prog(itf.flush_in_prog),
     .reallocate_reg_tag(itf.rob_reallocate_reg_tags),
     .rd_commit (itf.rd_commit),
     .regfile_load (itf.regfile_load),
     .rob_full (itf.rob_full),
     .ld_commit_sel (itf.ld_commit_sel),
     .ld_pc (itf.rob_ld_pc),
     .new_instr(itf.original_instr),
     .new_pc(itf.original_instr_pc),
     .new_next_pc(itf.original_instr_next_pc),
     .rvfi_wrd(itf.rvfi_wrd),
     .jalr_executed(itf.jalr_executed),
     .jalr_tag(itf.jalr_tag),
     .jalr_pc(itf.jalr_pc)
 );


logic [31:0] regfile_in, ld_data;
assign ld_data = 32'h600d600d;
always_comb begin 
    if (itf.ld_commit_sel) 
        regfile_in = regfile_mem_in;
    else 
        regfile_in = itf.cdb_out[itf.head_ptr].data[31:0];
end

regfile regfile (
    .*,
    .clk (clk),
    .rst (rst),
    .load (itf.regfile_load),
    .commit_tag(itf.head_ptr),
    .allocate (itf.rob_reallocate_reg_tags | itf.regfile_allocate), // rob_load from instruction queue, more appropiate to call it allocate
    .reg_allocate (itf.rob_reallocate_reg_tags ? itf.br_flush_ptr : itf.control_o.rd), // gets register to allocate from control word of instruction queue
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
    .set_reg_valid(itf.set_reg_valid),
    .reg_valid(itf.reg_valid),
    .flush_ip(itf.flush_in_prog),
    .src_c (itf.st_src_commit),
    .data_out (itf.regfile_data_out)
);

assign data_mem_wdata = itf.regfile_data_out << (memaddr_offset * 8);

tomasula_types::res_word res_word;
logic [31:0] src2_data;
logic src2_v;

assign src2_v = itf.src2_valid | itf.control_o.src2_valid;
assign src2_data = itf.control_o.src2_valid ? itf.control_o.src2_data : itf.reg_src2_data;

always_comb begin : assign_res_word
    res_word.opcode = itf.control_o.opcode;
    res_word.funct3 = itf.control_o.funct3;
    res_word.funct7 = itf.control_o.funct7;
    res_word.src1_tag = itf.tag_a;
    res_word.src1_data = itf.reg_src1_data;
    res_word.src1_valid = itf.src1_valid;
    res_word.src2_tag = itf.tag_b;
    res_word.src2_data = src2_data;
    res_word.src2_valid = src2_v;
    res_word.src2_reg = itf.control_o.src2_reg;
    res_word.rd_tag = itf.curr_ptr;
    res_word.pc = itf.control_o.pc;
end

lsq lsq(
    .clk(clk),
    .rst(rst | itf.flush_in_prog),
    .load(itf.lsq_load),
    .flush_ip(itf.flush_in_prog),
    .res_in(res_word),
    .cdb(itf.cdb_out),
    .rob_invalidated_n(itf.rob_invalidated_entries),
    .finished_entry(itf.finished_lsq_entry),
    .finished_entry_data(itf.finished_lsq_entry_data),
    .robs_calculated(itf.status_rob_valid),
    .rob_head_ptr(itf.head_ptr),
    .full(itf.lsq_full),
    .wdata_reg(itf.st_src_commit),
    .data_mem_resp(data_mem_resp),
    .data_read(data_read),
    .data_write(data_write),
    .data_mem_address(itf.lsq_data_mem_address),
    .data_mbe(data_mbe),
    .load_type(itf.lsq_load_type)
);

reservation_station res1(
    .clk (clk),
    .rst(rst),
    .load_word(itf.res1_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .invalidated_rob_entries_n(itf.rob_invalidated_entries),
    .alu_data(itf.res1_alu_out),
    .start_exe(itf.res1_exec),
    .jalr_executed(itf.res1_jalr_executed),
    .jalr_tag(itf.res1_jalr_tag),
    .ld_pc_to_cdb(itf.res1_pc_to_cdb),
    .update_br(itf.res1_update_br),
    .res_empty(itf.res1_empty),
    .res_in(res_word)
);

alu alu1(
    .alu_word(itf.res1_alu_out),
    .cdb_data(itf.alu1_calculation)
);

reservation_station res2(
    .clk (clk),
    .rst(rst),
    .load_word(itf.res2_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .invalidated_rob_entries_n(itf.rob_invalidated_entries),
    .alu_data(itf.res2_alu_out),
    .start_exe(itf.res2_exec),
    .jalr_executed(itf.res2_jalr_executed),
    .jalr_tag(itf.res2_jalr_tag),
    .ld_pc_to_cdb(itf.res2_pc_to_cdb),
    .update_br(itf.res2_update_br),
    .res_empty(itf.res2_empty),
    .res_in(res_word)
);

alu alu2(
    .alu_word(itf.res2_alu_out),
    .cdb_data(itf.alu2_calculation)
);

reservation_station res3(
    .clk (clk),
    .rst(rst),
    .load_word(itf.res3_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .invalidated_rob_entries_n(itf.rob_invalidated_entries),
    .alu_data(itf.res3_alu_out),
    .start_exe(itf.res3_exec),
    .jalr_executed(itf.res3_jalr_executed),
    .jalr_tag(itf.res3_jalr_tag),
    .ld_pc_to_cdb(itf.res3_pc_to_cdb),
    .update_br(itf.res3_update_br),
    .res_empty(itf.res3_empty),
    .res_in(res_word)
);

cmp cmp3(
    .funct3_in(itf.res3_alu_out.funct3),
    .first(itf.res3_alu_out.src1_data),
    .second(itf.res3_alu_out.src2_data),
    .result(itf.alu3_calculation)
);

reservation_station res4(
    .clk (clk),
    .rst(rst),
    .load_word(itf.res4_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .invalidated_rob_entries_n(itf.rob_invalidated_entries),
    .alu_data(itf.res4_alu_out),
    .start_exe(itf.res4_exec),
    .jalr_executed(itf.res4_jalr_executed),
    .jalr_tag(itf.res4_jalr_tag),
    .ld_pc_to_cdb(itf.res4_pc_to_cdb),
    .update_br(itf.res4_update_br),
    .res_empty(itf.res4_empty),
    .res_in(res_word)
);

cmp cmp4(
    .funct3_in(itf.res4_alu_out.funct3),
    .first(itf.res4_alu_out.src1_data),
    .second(itf.res4_alu_out.src2_data),
    .result(itf.alu4_calculation)
);

reservation_station res_br(      // for branches
    .clk (clk),
    .rst(rst),
    .load_word(itf.resbr_load),
    .cdb(itf.cdb_out),
    .robs_calculated(itf.status_rob_valid),
    .invalidated_rob_entries_n(itf.rob_invalidated_entries),
    .alu_data(itf.resbr_alu_out),
    .start_exe(itf.resbr_exec),
    .jalr_executed(itf.resbr_jalr_executed),
    .jalr_tag(),
    .ld_pc_to_cdb(itf.resbr_pc_to_cdb),
    .update_br(itf.resbr_update_br),
    .res_empty(itf.resbr_empty),
    .res_in(res_word)
);

branch_alu CMP(
    .op(branch_funct3_t'(itf.resbr_alu_out.funct3)), // typecast func3 to rv32i type to suppress warning
    .first(itf.resbr_alu_out.src1_data),
    .second(itf.resbr_alu_out.src2_data),
    .answer(itf.taken)
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
    if (itf.resbr_exec) begin
        itf.set_rob_valid[itf.resbr_alu_out.tag] = 1'b1;
    end
    if (itf.finished_lsq_entry) begin
        itf.set_rob_valid[itf.finished_lsq_entry_data.tag] = 1'b1;
    end
end

logic [7:0] cdb_enable;
logic false;
always_comb begin : cdb_enable_logic
    // set default values to 0
    for (int i = 0; i < 8; i++) begin
        itf.cdb_in[i].data[31:0] = 32'h00000000;
    end
    false = 1'b0;
    /* load cdb with alu outputs or pc in jal/jalr special cases */
    `write_to_cdb(itf.res1_exec, itf.res1_alu_out, itf.res1_pc_to_cdb, itf.alu1_calculation.data[31:0]);
    `write_to_cdb(itf.res2_exec, itf.res2_alu_out, itf.res2_pc_to_cdb, itf.alu2_calculation.data[31:0]);
    `write_to_cdb(itf.res3_exec, itf.res3_alu_out, itf.res3_pc_to_cdb, itf.alu3_calculation.data[31:0]);
    `write_to_cdb(itf.res4_exec, itf.res4_alu_out, itf.res4_pc_to_cdb, itf.alu4_calculation.data[31:0]);

    // Data propogation for branch computation. All 1's if taken otherwise 0
    `write_to_cdb(itf.resbr_exec, itf.resbr_alu_out, itf.resbr_update_br, 32'h00000000);

    // data loaded from memory to cdb through lsq; store 0's in cdb for a store
    `write_to_cdb(itf.finished_lsq_entry, itf.finished_lsq_entry_data, false, regfile_mem_in);
    
    cdb_enable[7:0] = 8'h00 | (itf.res1_exec << itf.res1_alu_out.tag) | (itf.res2_exec << itf.res2_alu_out.tag) | (itf.res3_exec << itf.res3_alu_out.tag) | (itf.res4_exec << itf.res4_alu_out.tag) | (itf.resbr_exec << itf.resbr_alu_out.tag) | (itf.finished_lsq_entry << itf.finished_lsq_entry_data.tag);
end

cdb cdb(
    .clk(clk),
    .ctl(itf.cdb_in),
    .enable(cdb_enable),
    .rst(rst),
    .out(itf.cdb_out[0:7])
); 




endmodule : ooo
