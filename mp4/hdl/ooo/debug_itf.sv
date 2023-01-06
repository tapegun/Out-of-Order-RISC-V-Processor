`ifndef debug_itf
`define debug_itf

interface debug_itf;
import rv32i_types::*;

/* ir signals */
logic [31:0] pc_calc;
logic ir_ld_pc;
logic [31:0] ir_instr;

/* iq signals */
logic res1_empty, res2_empty, res3_empty, res4_empty, rob_load, res1_load, res2_load, res3_load, res4_load, resbr_empty, resbr_load, lsq_load;
logic regfile_allocate;
tomasula_types::ctl_word control_o;
logic iq_ir_ack;
logic [31:0] original_instr;
logic [31:0] original_instr_pc;
logic [31:0] original_instr_next_pc;



/* res1 signals */
logic res1_exec;
tomasula_types::alu_word res1_alu_out;
logic res1_jalr_executed;
logic [4:0] res1_jalr_tag;
logic res1_pc_to_cdb;
logic res1_update_br;

/* res2 signals */
logic res2_exec;
tomasula_types::alu_word res2_alu_out;
logic res2_jalr_executed;
logic [4:0] res2_jalr_tag;
logic res2_pc_to_cdb;
logic res2_update_br;

/* res3 signals */
logic res3_exec;
tomasula_types::alu_word res3_alu_out;
logic res3_jalr_executed;
logic [4:0] res3_jalr_tag;
logic res3_pc_to_cdb;
logic res3_update_br;

/* res4 signals */
logic res4_exec;
tomasula_types::alu_word res4_alu_out;
logic res4_jalr_executed;
logic [4:0] res4_jalr_tag;
logic res4_pc_to_cdb;
logic res4_update_br;


/* resbr signals */
logic resbr_exec;
tomasula_types::alu_word resbr_alu_out;
logic resbr_jalr_executed;
logic resbr_pc_to_cdb;
logic resbr_update_br;

/* comparator logic */
logic taken;

/* regfile signals */
logic [31:0] reg_src1_data, reg_src2_data, regfile_data_out;
logic src1_valid, src2_valid;
logic [2:0] tag_a, tag_b;
logic [4:0] rd_updated;

/* rob signals */
logic rob_ld_pc, regfile_load, rob_full, ld_commit_sel, data_read, data_write, flush_in_prog;
logic [7:0] status_rob_valid, allocated_rob_entries;
logic set_rob_valid[8];
logic rob_invalidated_entries[8];
logic [2:0] curr_ptr, head_ptr, br_ptr, br_flush_ptr;
logic [4:0] rd_commit, st_src_commit;
logic rob_reallocate_reg_tags;
logic set_reg_valid [8];
logic [4:0] reg_valid [8];

/* cdb signals */
tomasula_types::cdb_data cdb_in[8];
tomasula_types::cdb_data cdb_out[8];

/* alu outputs */
tomasula_types::cdb_data alu1_calculation;
tomasula_types::cdb_data alu2_calculation;
tomasula_types::cdb_data alu3_calculation;
tomasula_types::cdb_data alu4_calculation;

/* lsq signals */
logic finished_lsq_entry, lsq_full;
logic [31:0] lsq_data_mem_address;
tomasula_types::alu_word finished_lsq_entry_data; 
logic [2:0] lsq_load_type;

/* mux logic */
logic [31:0] pc_in;

/* rvfi signals */
rv32i_types::rvfi_word rvfi_wrd;
logic jalr_executed;
logic [31:0] jalr_pc;
logic [2:0] jalr_tag;

endinterface : debug_itf

`endif
