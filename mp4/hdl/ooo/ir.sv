
module ir
import rv32i_types::*;
(
    input clk,
    input rst,
    input instr_mem_resp,
    // input iq_resp,
    input [31:0] in,
    // input [31:0] pc,
    input logic br_pr_take,
    input executed_jalr_one,
    input executed_jalr_two,
    input executed_jalr_three,
    input executed_jalr_four,
    input logic [31:0] jalr_pc_one,
    input logic [31:0] jalr_pc_two,
    input logic [31:0] jalr_pc_three,
    input logic [31:0] jalr_pc_four,
    input flush_ip,

    input iq_ack,

    input logic ld_br_pc,
    input logic [31:0] br_pc,

    output rv32i_word instr_mem_address, // ir will have to communicate with pc to get this, or maybe pc just wires directly to icache
    output logic instr_read,
    // output logic ld_pc,
    output logic [31:0] pc_calc,
    output logic [31:0] curr_instr,

    IQ_2_IR.IR_SIG iq_ir_itf
);

logic [31:0] data; // holds current instruction from cache
logic [31:0] br_pc_buffer; // holds the pc to request from branch mispredict
logic [31:0] jalr_pc_buffer; // holds the pc to request from jalr instruction
logic [31:0] pc; // internal pc counter
logic [31:0] prev_pc; // previous pc state to hold for instructions that need to stall such as JALR
logic [31:0] instr_pc; // pc to store alongside an instruction/rvfi_word
logic [31:0] predicted_br_pc_buffer; // buffer to hold what the predicted branch to take is in the case that branch instruction is stalled due to iq being full
logic [31:0] predicted_br_pc;
logic [31:0] prev_mem_address; // used to hold mem address for previous requests in stalling states
logic ld_pc; // signal to update pc

logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] i_imm, s_imm, b_imm, j_imm, u_imm;
logic [4:0] rs1, rs2, rd;
rv32i_opcode opcode;

assign curr_instr = data;

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]}; // 32
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];

/* this is an rvfi word that will get passed so that the rvfi can properly debug */
rv32i_types::rvfi_word rvfi;

assign iq_ir_itf.rvfi = rvfi;

always_comb
begin : generate_rvfi_word
    rvfi.inst = data;
    rvfi.rd_addr = rd;
    rvfi.pc_rdata = pc;
    
end

enum int unsigned {
    RESET = 0,
    FETCH = 1,
    CREATE = 2,
    STALL = 3,
    STALL_JALR = 4,
    STALL_JALR_TWO = 5,
    STALL_FLUSH = 6,
    STALL_FLUSH_TWO = 7
} state, next_state;

always_comb
begin : immediate_op_logic
    if (state == STALL) begin
        instr_pc = prev_pc;
        predicted_br_pc = predicted_br_pc_buffer;
    end
    else begin
        instr_pc = pc;
        predicted_br_pc = pc + b_imm;
    end

    iq_ir_itf.control_word.opcode = tomasula_types::s_op_invalid; 
    iq_ir_itf.control_word.src1_reg = rs1;
    iq_ir_itf.control_word.src1_valid = 1'b0;
    iq_ir_itf.control_word.src2_reg = rs2; // should be rs2 if no immediate is used, otherwise 0
    iq_ir_itf.control_word.pc = instr_pc + 4;
    iq_ir_itf.control_word.og_pc = pc;
    iq_ir_itf.control_word.src2_valid = 1'b0;
    iq_ir_itf.control_word.src2_data = 32'h00000000;
    iq_ir_itf.control_word.funct3 = funct3;
    iq_ir_itf.control_word.funct7 = data[30];
    iq_ir_itf.control_word.rd = rd;
    iq_ir_itf.control_word.og_instr = data;

    /* rvfi signals to be set */
    rvfi.rs1_addr = rs1;
    rvfi.rs2_addr = rs2;
    rvfi.pc_wdata = iq_ir_itf.control_word.pc;
    rvfi.imm = iq_ir_itf.control_word.src2_valid;
    case (opcode) 
        /* going to experiment with op_lui,op_auipc, and op_jal by storing their data in rs2_data rather than pc */
        /* for instructions doing arithmetic, set funct3 to 000 for addition */
        op_lui: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_imm;
            iq_ir_itf.control_word.src1_reg = 5'b00000;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_data = u_imm;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.funct3 = 3'b000;
            iq_ir_itf.control_word.funct7 = 1'b0;

            rvfi.rs1_addr = 5'b00000;
            rvfi.rs2_addr = 5'b00000;
            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_auipc: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_imm;
            iq_ir_itf.control_word.src1_reg = 5'b00000;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_data = instr_pc + u_imm;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.funct3 = 3'b000;
            iq_ir_itf.control_word.funct7 = 1'b0;

            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_jal: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_jal;
            iq_ir_itf.control_word.src1_reg = 5'b00000;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_data = instr_pc + 4;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            rvfi.pc_wdata = pc_calc;
            iq_ir_itf.control_word.funct3 = 3'b000;

            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_jalr: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_jalr;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_data = i_imm;
            iq_ir_itf.control_word.pc = instr_pc + 4; 
            iq_ir_itf.control_word.funct3 = 3'b000;
            iq_ir_itf.control_word.funct7 = 1'b0;

            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_br: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_br;
            // if predicted to not be taken, save target address for taking
            // the branch
            if (~br_pr_take) begin
                iq_ir_itf.control_word.pc = predicted_br_pc;
                // 0 0 0 PREDICTION 0
                iq_ir_itf.control_word.rd = 5'b00000; 
                rvfi.pc_wdata = instr_pc + 4;
            end 
            else begin
                iq_ir_itf.control_word.pc = instr_pc + 4;
                iq_ir_itf.control_word.rd = 5'b00010;
                rvfi.pc_wdata = predicted_br_pc;
            end
            rvfi.imm = 1'b0;
        end
        op_load: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_load;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_data = i_imm;

            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_store: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_store;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_data = s_imm;

            rvfi.imm = 1'b0;
        end
        op_imm: begin
            /* remember to pay attention to funct7 */
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_imm;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_data = i_imm;
            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
        op_reg: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_reg;
        end
        op_csr: begin
            iq_ir_itf.control_word.opcode = tomasula_types::s_op_csr;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_data = i_imm;

            rvfi.imm = iq_ir_itf.control_word.src2_valid;
        end
    endcase
    
end

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
        state <= RESET;
        br_pc_buffer <= 32'h00000000;
        jalr_pc_buffer <= 32'h00000000;
        predicted_br_pc_buffer <= 32'h00000000;
        pc <= 32'h00000060;
        prev_pc <= 32'h00000000;
    end

    else begin
        if (ld_br_pc)
            br_pc_buffer <= br_pc;

        if (executed_jalr_one)
            jalr_pc_buffer <= jalr_pc_one;
        if (executed_jalr_two)
            jalr_pc_buffer <= jalr_pc_two;
        if (executed_jalr_three)
            jalr_pc_buffer <= jalr_pc_three;
        if (executed_jalr_four)
            jalr_pc_buffer <= jalr_pc_four;
        
        if (ld_pc) begin
            pc <= pc_calc;
            prev_pc <= pc;
        end

        if (instr_read)
            prev_mem_address <= instr_mem_address;

        /* states in which new data is fetched */
        if (state == FETCH | state == STALL_FLUSH_TWO | state == STALL_JALR_TWO) begin
            data <= in;
            state <=next_state;
        end

        if ((state == CREATE) & (opcode == op_br))
            predicted_br_pc_buffer <= pc + b_imm;

        state <= next_state;
    end
end

function void set_defaults();
    instr_read = 1'b0;
    ld_pc = 1'b0;
    iq_ir_itf.ld_iq = 1'b0;
    pc_calc = pc + 4;
    instr_mem_address = pc;
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
            if (~flush_ip) begin
                // address calculation 
                if(opcode == op_jal) begin
                    pc_calc = pc + j_imm;
                end
                if(opcode == op_br) begin
                    if (br_pr_take)
                        pc_calc = pc + b_imm;
                    else
                        pc_calc = pc + 4;
                end
                /*
                intuitively, we only we wouldn't care about the next instruction if the opcode is jalr but we can safely
                assume with the jalr_stall state that even though pc gets loaded with pc + 4, we will never fetch this address from i-cache,
                we will only fetch the calculated address from jalr since jalr will load pc with its calculated address eventually in order to
                leave the jalr_stall state
                */
                ld_pc = 1'b1; 
                iq_ir_itf.ld_iq = 1'b1;
            end
        end
        STALL: begin
            iq_ir_itf.ld_iq = 1'b1;
        end
        STALL_JALR: begin
            // do nothing
        end
        STALL_JALR_TWO: begin
            instr_read = 1'b1;
            instr_mem_address = jalr_pc_buffer;
            pc_calc = jalr_pc_buffer;
            ld_pc = 1'b1;
        end
        STALL_FLUSH: begin
            instr_read = 1'b1;
            instr_mem_address = prev_mem_address;
        end
        STALL_FLUSH_TWO: begin
            instr_read = 1'b1;
            instr_mem_address = br_pc_buffer; // request the branch pc address from memory instead of current pc
            pc_calc = br_pc_buffer; // current pc is now branch pc; gets incrememnted by 4 once transitioned to CREATE state
            ld_pc = 1'b1;
        end
    endcase
end

always_comb
begin : next_state_logic
    next_state = state;
    case(state)
        RESET: next_state = FETCH;
        FETCH: begin
            if (flush_ip) begin
                next_state = STALL_FLUSH;
            end
            else if (instr_mem_resp)
                next_state = CREATE;
        end
        CREATE: begin
            if (flush_ip) begin
                next_state = STALL_FLUSH_TWO;
            end
            else if (iq_ack) begin
                if(opcode == op_jalr) 
                    next_state = STALL_JALR;
                else
                    next_state = FETCH;
            end
            else
                next_state = STALL;
        end
        STALL: begin
            if (flush_ip)
                next_state = STALL_FLUSH_TWO;
            else if (iq_ack) begin
                if(opcode == op_jalr) 
                    next_state = STALL_JALR;
                else
                    next_state = FETCH;
            end
        end
        /* instruction register must stall because it can't speculate the instruction to be taken from JALR */
        STALL_JALR: begin
            if (flush_ip)
                next_state = STALL_FLUSH;
            else if (executed_jalr_one | executed_jalr_two | executed_jalr_three | executed_jalr_four) begin
                next_state = STALL_JALR_TWO;
            end
        end
        /* instruction register has now resolved JALR instruction, now to request its address and continue */
        STALL_JALR_TWO: begin
            if (flush_ip)
                next_state = STALL_FLUSH;
            else if (instr_mem_resp)
                next_state = CREATE;
        end
        /* must wait for instr_read to be resolved before requesting branch instruction */
        STALL_FLUSH: begin
            if (instr_mem_resp)
                next_state = STALL_FLUSH_TWO;
        end
        STALL_FLUSH_TWO: begin
            if (~flush_ip & instr_mem_resp)
                next_state = CREATE; // could have made a better design choice to work around CREATE state instead
        end
    endcase
end

endmodule : ir
