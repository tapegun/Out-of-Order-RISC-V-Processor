module reservation_station
import rv32i_types::*;
(
    input clk, 
    input rst, 
    input load_word,
    input tomasula_types::ctl_word control_word,
    input [31:0] src1,
    input [31:0] src2,
    input tomasula_types::cdb_data cdb,
    input [2:0] rob_tag1,
    input [2:0] rob_tag2, 
    input rob_v1,
    input rob_v2,
    input alu_free,
    output tomasula_types::alu_word alu_data,
    output logic start_exe,
    output logic res_empty
);

tomasula_types::res_word res_word;

enum int unsigned {
    EMPTY = 0,
    LOAD  = 1,
    PEEK  = 2,
    STALL = 3,
    EXEC  = 4
} state, next_state;

always_comb
begin : assign_alu_data
    alu_data.op = res_word.op;
    alu_data.funct3 = res_word.funct3;
    alu_data.funct7 = res_word.funct7;
    alu_data.src1_data = res_word.src1_data;
    alu_data.src2_data = res_word.src2_data;
    alu_data.imm = res_word.imm;
    alu_data.tag = res_word.rd_tag;
end


always_ff @(posedge clk)
begin
    if (rst)
    begin
        res_word.op <= tomasula_types::BRANCH;
        res_word.funct3 <= 3'b000;
        res_word.funct7 <= 1'b0;
        res_word.src1_tag <= 3'b000;
        res_word.src1_data <= 32'h0000;
        res_word.src1_valid <= 1'b0;
        res_word.src2_tag <= 3'b000;
        res_word.src2_data <= 32'h0000;
        res_word.src2_valid <= 1'b0;
        res_word.rd_tag <= 3'b000;
        res_word.imm <= 32'h0000;

        state <= EMPTY;
    end
    // now cover EMPTY cases
    else if (next_state == EMPTY)
    begin
        res_word.op <= control_word.op;
        res_word.funct3 <= control_word.funct3;
        res_word.funct7 <= control_word.funct7;
        res_word.src1_tag <= control_word.src1_reg;
        res_word.src1_data <= 32'h0000;
        res_word.src1_valid <= 1'b0;
        res_word.src2_tag <= control_word.src2_reg;
        res_word.src2_data <= 32'h0000;
        res_word.src2_valid <= 1'b0;
        res_word.rd_tag <= control_word.rd;
        res_word.imm <= control_word.imm;

        state <= next_state;
    end
    // LOAD cases
    else if (next_state == LOAD)
    begin
        res_word.src1_data <= src1;
        res_word.src1_valid <= ~rob_v1;
        res_word.src1_tag <= rob_tag1;
        res_word.src2_data <= src2;
        res_word.src2_valid <= ~rob_v2;
        res_word.src2_tag <= rob_tag2;
        state <= next_state;
    end
    // PEEK cases
    else if (next_state == PEEK)
    begin
    if (cdb.tag == res_word.src1_tag & ~res_word.src1_valid)
    begin
        res_word.src1_data <= cdb.data;
        res_word.src1_valid <= 1'b1;
    end
    if (cdb.tag == res_word.src2_tag & ~res_word.src2_valid)
    begin
        res_word.src2_data <= cdb.data;
        res_word.src2_valid <= 1'b1;
    end
    state <= next_state;
    end
    // STALL cases -- do nothing
    // EXEC cases -- do nothing
    // else if (state == EXEC)
    // begin
    // end
    else
    begin
        state <= next_state;
    end
end

function void set_defaults();
    res_empty = 1'b0;
    start_exe = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();

    /* Actions for each state */
    case(state)
        EMPTY: begin
            res_empty = 1'b1;
        end
        LOAD, PEEK: ; // do nothing
        EXEC: begin
            start_exe = 1'b1;
        end
    endcase
end

always_comb
begin : next_state_logic
    next_state = state;
    case (state)
        EMPTY: begin
            if (load_word)
                next_state = LOAD;
            else
                next_state = EMPTY;
        end
        LOAD, PEEK: begin
            /* if the source register data is ready and the alu unit is ready, start execution on next clk cycle */
            if (res_word.src1_valid & res_word.src2_valid & alu_free) 
                next_state = EXEC;
            else if (res_word.src1_valid & res_word.src2_valid)
                next_state = STALL;
            else
                next_state = PEEK;
        end
        STALL: begin
            if (alu_free)
                next_state = EXEC;
            else
                next_state = STALL;
        end
        EXEC: next_state = EMPTY;
    endcase
end

endmodule : reservation_station