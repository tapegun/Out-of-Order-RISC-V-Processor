`ifndef rob_itf
`define rob_itf

interface rob_itf;
import rv32i_types::*;
bit clk, reset_n, rob_load, branch_mispredict, data_mem_resp, rob0_valid, rob1_valid, rob2_valid, rob3_valid, rob4_valid, rob5_valid, rob6_valid, rob7_valid, regfile_allocate, regfile_load, rob_full, ld_commit_sel, load_pc, data_read, data_write;
opt_t instr_type;
bit [4:0] rd, st_src, rd_inflight, st_commit;
bit [2:0] rob_tag;

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

endinterface : rob_itf

`endif
