module alu
import rv32i_types::*;
(
    // input tomasula_types::op_t op,
    // input tomasula_types::alu_word::src1_data src1_data,
    // input tomasula_types::alu_word::src2_data src2_data,
    // input tomasula_types::alu_word::funct3 funct3,
    // input tomasula_types::alu_word::funct7 funct7,
    // input tomasula_types::alu_word::load load,
    // input tomasula_types::alu_word::tag tag,
    input tomasula_types::alu_word alu_word,
//    output tomasula_types::cdb_data::data data,
//    output tomasula_types::cdb_data::tag tag_out,
//    output tomasula_types::cdb_data::request req
    output tomasula_types::cdb_data cdb_data
);

logic [31:0] a, b;
rv32i_types::alu_ops aluop;

always_comb begin : OPERATION
    a = alu_word.src1_data;
    b = alu_word.src2_data;

    // alu_op = alu_add;
    if(alu_word.op == tomasula_types::ARITH) begin
        if (alu_word.funct3 == rv32i_types::sr) begin 
                if (alu_word.funct7 != 1'b1)
                    aluop = rv32i_types::alu_srl;
                else
                    aluop = rv32i_types::alu_sra;
            end
            else if (alu_word.funct3 == rv32i_types::add) begin
                if (alu_word.funct7 != 1'b1)
                    aluop = rv32i_types::alu_add;
                else
                    aluop = rv32i_types::alu_sub;
            end
            else
                aluop = rv32i_types::alu_ops'(alu_word.funct3);
    end
    else begin
        aluop = rv32i_types::alu_add;
    end
    
end

always_comb begin : EXECUTION
    unique case (aluop)
        alu_add:  cdb_data.data = a + b;
        alu_sll:  cdb_data.data = a << b[4:0];
        alu_sra:  cdb_data.data = $signed(a) >>> b[4:0];
        alu_sub:  cdb_data.data = a - b;
        alu_xor:  cdb_data.data = a ^ b;
        alu_srl:  cdb_data.data = a >> b[4:0];
        alu_or:   cdb_data.data = a | b;
        alu_and:  cdb_data.data = a & b;
    endcase
    // cdb_data.req = alu_word.load;
    // cdb_data.tag = alu_word.tag;


end

endmodule : alu
