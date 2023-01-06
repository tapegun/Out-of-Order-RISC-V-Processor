`ifndef tb_itf
`define tb_itf

interface tb_itf;
import rv32i_types::*;
bit clk, reset_n;

/* ir signals */
logic instr_mem_resp, instr_read;
logic [31:0] in;
rv32i_word instr_mem_address;

/* iq signals */
logic res1_empty, res2_empty, res3_empty, res4_empty, rob_load, res1_load, res2_load, res3_load, res4_load, resbr_empty, resbr_load;
tomasula_types::ctl_word control_o;

/* res1 signals */
logic res1_exec;
tomasula_types::alu_word res1_alu_out;

/* res2 signals */
logic res2_exec;
tomasula_types::alu_word res2_alu_out;


/* res3 signals */
logic res3_exec;
tomasula_types::alu_word res3_alu_out;

/* res4 signals */
logic res4_exec;
tomasula_types::alu_word res4_alu_out;

/* regfile signals */
logic [31:0] reg_src1_data, reg_src2_data;
logic src1_valid, src2_valid;
logic [2:0] tag_a, tag_b;
// logic [31:0] reg_a, reg_b;
// logic valid_a, valid_b;

/* rob signals */
// logic robs_calculated[8];
logic ld_br, regfile_load, rob_full, ld_commit_sel, data_read, data_write;
logic [7:0] status_rob_valid;
logic set_rob_valid[8];
logic [2:0] curr_ptr, head_ptr, br_ptr;
logic [4:0] rd_commit, st_src_commit;

/* cdb signals */
tomasula_types::cdb_data cdb_in[8];
tomasula_types::cdb_data cdb_out[8];

/* alu outputs */
tomasula_types::cdb_data alu1_calculation;
tomasula_types::cdb_data alu2_calculation;
tomasula_types::cdb_data alu3_calculation;
tomasula_types::cdb_data alu4_calculation;

time timestamp;

task finish();
    repeat (100) @(posedge clk);
    $finish;
endtask : finish

// Generate clk signal
always #5 clk = (clk === 1'b0);

initial timestamp = '0;
always @(posedge clk) timestamp = timestamp + time'(1);

struct {
    logic read_error [time];
} stu_errors;

function automatic void tb_report_dut_error(error_e err);
    $display("%0t: TB: Reporting %s at %0t", $time, err.name, timestamp);
    case (err)
        READ_ERROR: stu_errors.read_error[timestamp] = 1'b1;
        default: $fatal("TB reporting Unknown error");
    endcase
endfunction

endinterface : tb_itf

`endif
