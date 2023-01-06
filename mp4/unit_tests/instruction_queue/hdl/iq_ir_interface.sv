`ifndef iq_ir_interface
`define iq_ir_interface

interface IQ_2_IR;

import rv32i_types::*;
/* signal declarations */
// Signals from the instruction register to the instruction queue
tomasula_types::ctl_word control_word;
logic ld_iq;

// Signals from the instruction queue to the instruction register
logic issue_q_full_n, ack_o;

/* Modport Declarations */
modport IR_SIG(
    input issue_q_full_n,
    input ack_o,
    output control_word,
    output ld_iq
);

modport IQ_SIG(
    output issue_q_full_n,
    output ack_o,
    input control_word,
    input ld_iq
);

endinterface : IQ_2_IR
`endif