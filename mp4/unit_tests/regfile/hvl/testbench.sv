module testbench(reservation_station_itf itf);
import rv32i_types::*;

reservation_station res (
    .clk (itf.clk),
    .rst (~itf.reset_n),
    .load_word (itf.load_word),
    .control_word (itf.control_word),
    .src1 (itf.src1),
    .src2 (itf.src2),
    .cdb (itf.cdb),
    .rob_tag1 (itf.rob_tag1),
    .rob_tag2 (itf.rob_tag2),
    .rob_v1 (itf.rob_v1),
    .rob_v2 (itf.rob_v2),
    .alu_free (itf.alu_free),
    .alu_data (itf.alu_data),
    .start_exe (itf.start_exe),
    .res_empty (itf.res_empty)
);

default clocking tb_clk @(posedge itf.clk); endclocking

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
    /* set up control word for res station */
    itf.control_word.op <= tomasula_types::ARITH;
    itf.control_word.src1_reg <= 8'h1;
    itf.control_word.src1_valid <= 1'b0;
    itf.control_word.src2_reg <= 8'h2;
    itf.control_word.src2_valid <= 1'b0;
    itf.control_word.funct3 <= 3'b000;
    itf.control_word.funct7 <= 1'b0;
    itf.control_word.rd <= 8'h3;
    itf.control_word.imm <= 32'h0000;

    /* set up cdb */
    itf.cdb.tag = 3'b000;
    itf.cdb.data = 3'b000;

    /* set up other inputs */
    itf.load_word <= 1'b0;
    itf.rob_tag1 <= 3'b000;
    itf.rob_tag2 <= 3'b000;
    itf.rob_v1 <= 1'b0;
    itf.rob_v2 <= 1'b0;
    itf.alu_free <= 1'b0;
    itf.src1 <= 32'h0000;
    itf.src2 <= 32'h0000;

endtask

task load_res();
    itf.load_word <= 1'b1;
    @(tb_clk);
endtask

task unload_res();
    itf.load_word <= 1'b0;
    @(tb_clk);
endtask

task set_cdb (input logic [2:0] tag, input logic [31:0] data);
    itf.cdb.tag <= tag;
    itf.cdb.data <= data;
endtask

task set_src_data (input logic [31:0] data1, input logic [31:0] data2);
    itf.src1 <= data1;
    itf.src2 <= data2;
endtask

task set_robs (input bit v1, input logic [2:0] rob_id_1, input bit v2, input logic [2:0] rob_id_2);
    itf.rob_v1 <= v1;
    itf.rob_tag1 <= rob_id_1;
    itf.rob_v2 <= v2;
    itf.rob_tag2 <= rob_id_2;
endtask

task set_alu (input bit set);
    itf.alu_free <= set;
endtask


initial begin
    $display("starting reservation station test");

    set_init();
    reset();

    set_src_data(5, 3);
    set_robs (1'b1, 3'b001, 0, 3'b000);
    @(tb_clk);

    load_res();
    unload_res();

    repeat (10) @(tb_clk);
    set_cdb (3'b001, 32'h0002);
    repeat (2) @(tb_clk);
    set_alu(1'b1);
    repeat (2) @(tb_clk);
    // set_alu(1'b0);
    set_src_data(7, 9);
    set_robs (1'b0, 3'b010, 1'b0, 3'b101);
    load_res();
    set_robs (1'b0, 3'b000, 1'b0, 3'b000);
    unload_res();



    itf.finish();

end

endmodule : testbench