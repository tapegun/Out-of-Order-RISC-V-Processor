module cdb_latch 
import rv32i_types::*;
(  input tomasula_types::cdb_data control,
                    input en,
                    input rst,
                    output tomasula_types::cdb_data q
                    );

tomasula_types::cdb_data _q;
assign q = _q;
always @ (en or rst or control.data) begin
    // always @ (en or rst) begin
    if(rst) begin
        _q.data <= 32'h00000000;
        _q.rs1_data <= 32'h00000000;
        _q.rs2_data <= 32'h00000000;
    end
    else begin
        if(en) begin
            _q.data <= control.data;
            _q.rs1_data <= control.rs1_data;
            _q.rs2_data <= control.rs2_data;
        end
    end
end

endmodule