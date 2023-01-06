module cdb 
import rv32i_types::*;
(  input tomasula_types::cdb_data ctl [8],
                    input logic[7:0] enable,
                    input rst,
                    output tomasula_types::cdb_data out [8]
                    );

    cdb_latch latch0(
        .control(ctl[0]),
        .en(enable[0]),
        .rst(rst),
        .q(out[0])
    );

    cdb_latch latch1(
        .control(ctl[1]),
        .en(enable[1]),
        .rst(rst),
        .q(out[1])
    );

    cdb_latch latch2(
        .control(ctl[2]),
        .en(enable[2]),
        .rst(rst),
        .q(out[2])
    );

    cdb_latch latch3(
        .control(ctl[3]),
        .en(enable[3]),
        .rst(rst),
        .q(out[3])
    );

    cdb_latch latch4(
        .control(ctl[4]),
        .en(enable[4]),
        .rst(rst),
        .q(out[4])
    );

    cdb_latch latch5(
        .control(ctl[5]),
        .en(enable[5]),
        .rst(rst),
        .q(out[5])
    );

    cdb_latch latch6(
        .control(ctl[6]),
        .en(enable[6]),
        .rst(rst),
        .q(out[6])
    );

    cdb_latch latch7(
        .control(ctl[7]),
        .en(enable[7]),
        .rst(rst),
        .q(out[7])
    );


endmodule