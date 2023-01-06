module top;
import rv32i_types::*;

// instruction_queue_itf itf();
tb_itf itf();

testbench tb(.*);

endmodule : top;
