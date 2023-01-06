module cdb 
import rv32i_types::*;
(  
    input clk,
    input tomasula_types::cdb_data ctl [8],
                    input logic[7:0] enable,
                    input rst,
                    output tomasula_types::cdb_data out [8]
                    );

    tomasula_types::cdb_data data [8];
    assign out = data;
    always_ff @(posedge clk) begin
        if (rst)
        begin
            for (int i = 0; i < 8; i++) begin
                data[i].data <= 32'h00000000;
                data[i].rs1_data <= 32'h00000000;
                data[i].rs2_data <= 32'h00000000;
            end
        end
        else begin
            for (int i = 0; i < 8; i++) begin
                if (enable[i]) begin
                    data[i] <= ctl[i];
                end
            end
        end

    end

endmodule