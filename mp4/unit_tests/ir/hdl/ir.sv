
module ir
import rv32i_types::*;
(
    input clk,
    input rst,
    input instr_mem_resp,
    input iq_resp,
    input [31:0] in,
    input [31:0] pc,

    output rv32i_word instr_mem_address, // ir will have to communicate with pc to get this, or maybe pc just wires directly to icache
    output instr_read,
    output tomasulo_types::ctl_word control_word,
    output ld_pc,
    output ld_iq
);

logic [31:0] data; // holds current instruction from cache
logic [31:0] curr_pc; // holds current pc to add to control word

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]};
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];

assign control_word.src1_reg = rs1;
assign control_word.src2_reg = rs2;
assign control_word.src1_valid = 1'b0;
assign control_word.funct3 = funct3;
assign control_word.funct7 = funct7[30];
assign control_word.rd = rd;
assign control_word.pc = curr_pc;

assign instr_mem_address = curr_pc;

enum int unsigned {
    RESET = 0,
    FETCH = 1,
    CREATE = 2,
    STALL = 3
} state, next_state;

always_comb
begin : immediate_logic
    control_word.src2_data = 32'h0000;
    control_word.src2_valid = 1'b0;
    case (opcode)
        op_lui, op_auipc: begin 
            control_word.src2_data = u_imm;
            control_word.src2_valid = 1'b1;
        end
        op_jal: begin
            control_word.src2_data = j_imm;
            control_word.src2_valid = 1'b1;
        end
        op_br: begin
            control_word.src2_data = b_imm;
            control_word.src2_valid = 1'b1;
        end
        op_store: begin
            control_word.src2_data = s_imm;
            control_word.src2_valid = 1'b1;
        end
        op_jalr, op_load, op_imm, op_csr: begin
            control_word.src2_data = i_imm;
            control_word.src2_valid = 1'b1;
        end
    endcase
end

//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
        curr_pc <= '0;
        state <= RESET;
    end
    else if (next_state == FETCH)
    begin
        data <= in;
        curr_pc <= pc;
        state <= next_state;
    end
    // else if (next_state == CREATE)
    // else if (next_state == STALL)
    else
        state <= next_state;

end

function void set_defaults();
    instr_read = 1'b0;
    ld_pc = 1'b0;
    ld_iq = 1'b0;
endfunction

always_comb
begin : state_actions
    set_defaults();

    case (state)
        RESET: ;
        FETCH: begin
            instr_read = 1'b1;
        end
        CREATE: begin
            ld_pc = 1'b1; 
            ld_iq = 1'b1;
        end
        STALL: begin
            ld_iq = 1'b1;
        end
    endcase
end

always_comb
begin : next_state_logic
    next_state = state;
    case(state)
        RESET: next_state = FETCH;
        FETCH: begin
            if (instr_mem_resp)
                next_state = CREATE;
        end
        CREATE: begin
            if (iq_resp)
                next_state = FETCH;
            else
                next_state = STALL;
        end
        STALL: begin
            if (iq_resp)
                next_state = FETCH;
        end
    endcase
end

endmodule : ir
