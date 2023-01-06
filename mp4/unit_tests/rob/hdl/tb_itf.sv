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
logic res1_empty, res2_empty, res3_empty, res4_empty, resldst_empty, rob_full, ldst_q_full, rob_load, res1_load, res2_load, res3_load, res4_load, resldst_load;
logic [4:0] regfile_tag1, regfile_tag2;
tomasula_types::ctl_word control_o;

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