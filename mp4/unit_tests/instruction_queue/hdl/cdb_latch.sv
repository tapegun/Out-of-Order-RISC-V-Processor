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
    if(rst) 
        _q.data <= 32'h00000000;
    else begin
        if(en)
            _q.data <= control.data;
    end
end

endmodule