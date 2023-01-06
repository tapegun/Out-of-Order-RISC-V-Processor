`define BAD_MUX_SEL $display("Illegal mux select")

module cmp
import rv32i_types::*;
(
    //compare
    input [2:0] funct3_in,
    input rv32i_word first,
    input rv32i_word second,
    output tomasula_types::cdb_data result
);

/* translate slt and sltu operations to branches with an extended output */
logic [2:0] br_op;
always_comb begin : br_op_set
    br_op = branch_funct3_t'(3'b100);
    if (arith_funct3_t'(funct3_in) == slt)
        br_op = branch_funct3_t'(3'b100);
    else if (arith_funct3_t'(funct3_in) == sltu)
        br_op = branch_funct3_t'(3'b110);
end

always_comb begin
    unique case (branch_funct3_t'(br_op))
        rv32i_types::bltu: result.data = {{31{1'b0}}, (first < second)};
        rv32i_types::blt: result.data = {{31{1'b0}}, ($signed(first) < $signed(second))};
        default: `BAD_MUX_SEL;
    endcase
end

endmodule
