`ifndef reservation_station_itf
`define reservation_station_itf

interface reservation_station_itf;
import rv32i_types::*;
bit clk, reset_n, load_word, rob_v1, rob_v2, alu_free, start_exe, res_empty;
tomasula_types::ctl_word control_word;
logic [31:0] src1, src2;
tomasula_types::cdb_data cdb;
logic [2:0] rob_tag1, rob_tag2;
tomasula_types::alu_word alu_data;

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

endinterface : reservation_station_itf

`endif