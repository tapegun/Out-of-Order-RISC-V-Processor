module lsq
import rv32i_types::*;
(
    input clk,
    input rst, 
    input load,
    input flush_ip,
    input tomasula_types::res_word res_in,
    input tomasula_types::cdb_data cdb[8],
    input logic rob_invalidated_n [8],
    output logic finished_entry,
    output tomasula_types::alu_word finished_entry_data,
    input logic [7:0] robs_calculated,
    input logic [2:0] rob_head_ptr,
    output logic full,
    output logic [4:0] wdata_reg,

    // signals between memory
    input data_mem_resp,
    output logic data_read,
    output logic data_write,
    output rv32i_word data_mem_address,
    output logic [2:0] load_type,
    output logic [3:0] data_mbe
);
// NOTE: for now this lsq will only handle loads, but should incorporate stores soon

/* 
** reasonably entries should be half the size of rob since loads are broken 
** into auipc and load, thus only at most 4 auipc's can be in rob 
*/
logic [1:0] head_ptr, curr_ptr;
logic addr_rdy [4];
logic entries_allocated [4];
logic invalidated [4]; // entries that got invalidated from a flush
logic [1:0] memaddr_offset;
tomasula_types::res_word entries [4];
assign memaddr_offset = data_mem_address[1:0];

enum int unsigned {
    RESET = 0,
    ACTIVE = 1,
    FLUSH = 2
} lsq_state, lsq_next_state;

always_comb begin : assign_alu_output
    finished_entry_data.opcode = entries[head_ptr].opcode;
    finished_entry_data.funct3 = entries[head_ptr].funct3;
    finished_entry_data.funct7 = entries[head_ptr].funct7;
    finished_entry_data.src1_data = entries[head_ptr].src1_data;
    finished_entry_data.src2_data = entries[head_ptr].src2_data;
    finished_entry_data.pc = entries[head_ptr].pc;
    finished_entry_data.tag = entries[head_ptr].rd_tag;
    load_type = entries[head_ptr].funct3;
end

always_comb begin : store_mask
    case(store_funct3_t'(entries[head_ptr].funct3)) 
        sw: data_mbe = 4'b1111;
        sh: data_mbe = 4'b0011 << memaddr_offset;
        sb: data_mbe = 4'b0001 << memaddr_offset;
        default: data_mbe = 4'b0000;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 4; i++) begin : initialize_arrays
            addr_rdy[i] <= 1'b0;
            invalidated[i] <= 1'b0;
            entries[i].opcode <= tomasula_types::s_op_invalid;
            entries[i].funct3 <= 3'b000;
            entries[i].funct7 <= 1'b0;
            entries[i].src1_tag <= 3'b000;
            entries[i].src1_data <= 32'h00000000;
            entries[i].src1_valid <= 1'b0;
            entries[i].src2_tag <= 3'b000;
            entries[i].src2_data <= 32'h00000000;
            entries[i].src2_valid <= 1'b0;
            entries[i].src2_reg <= 5'b00000;
            entries[i].rd_tag <= 3'b000;
            entries[i].pc <= 32'h00000000;
            entries_allocated[i] <= 1'b0;
        end
        head_ptr <= 2'b00;
        curr_ptr <= 2'b00;
        lsq_state <= RESET;
    end
    else begin
        if (lsq_state == RESET) begin
            for (int i = 0; i < 4; i++) begin : initialize_arrays
            addr_rdy[i] <= 1'b0;
            invalidated[i] <= 1'b0;
            entries[i].opcode <= tomasula_types::s_op_invalid;
            entries[i].funct3 <= 3'b000;
            entries[i].funct7 <= 1'b0;
            entries[i].src1_tag <= 3'b000;
            entries[i].src1_data <= 32'h0000;
            entries[i].src1_valid <= 1'b0;
            entries[i].src2_tag <= 3'b000;
            entries[i].src2_data <= 32'h0000;
            entries[i].src2_valid <= 1'b0;
            entries[i].src2_reg <= 5'b00000;
            entries[i].rd_tag <= 3'b000;
            entries[i].pc <= 32'h00000000;
            entries_allocated[i] <= 1'b0;
            end
            head_ptr <= 2'b00;
            curr_ptr <= 2'b00;
        end
        // update curr_ptr when allocating a new entries
        if (load & (lsq_state == ACTIVE)) begin
            // entries[curr_ptr].op <= res_in.op;
            entries[curr_ptr].opcode <= res_in.opcode;
            entries[curr_ptr].funct3 <= res_in.funct3;
            entries[curr_ptr].funct7 <= res_in.funct7;
            entries[curr_ptr].src1_tag <= res_in.src1_tag;
            entries[curr_ptr].src1_data <= res_in.src1_data;
            addr_rdy[curr_ptr] <= res_in.src1_valid;
            entries[curr_ptr].src1_valid <= res_in.src1_valid;
            entries[curr_ptr].src2_tag <= res_in.src2_tag;
            entries[curr_ptr].src2_data <= res_in.src2_data;
            entries[curr_ptr].src2_valid <= res_in.src2_valid;
            entries[curr_ptr].src2_reg <= res_in.src2_reg;
            entries[curr_ptr].rd_tag <= res_in.rd_tag;
            entries[curr_ptr].pc <= res_in.pc;
            // entries[curr_ptr] <= res_in;
            curr_ptr <= curr_ptr + 1;
            entries_allocated[curr_ptr] <= 1'b1;
        end
        // update head ptr when entries in queue has finished using memory
        // reads even if invalidated should wait for mem response; stores should move on
        if ((data_mem_resp | entries[head_ptr].opcode != tomasula_types::s_op_load & invalidated[head_ptr]) & (lsq_state == ACTIVE)) begin
            invalidated[head_ptr] <= 1'b0; // can reset invalidate signal if it was set high if head pointer moves on
            head_ptr <= head_ptr + 1;
            entries_allocated[head_ptr] <= 1'b0;
            addr_rdy[head_ptr] <= 1'b0;
            entries[head_ptr].src1_valid <= 1'b0;
        end

        for (int i = 0; i < 4; i++) begin
            if (flush_ip & ~rob_invalidated_n[entries[i].rd_tag]) begin // need to deal with loading flushes if flush in progress, else update entries
                invalidated[i] <= 1'b1;
            end
            if (~addr_rdy[i] & robs_calculated[entries[i].src1_tag] & entries_allocated[i]) begin
                entries[i].src1_data <= cdb[entries[i].src1_tag].data;
                addr_rdy[i] <= 1'b1;
                entries[i].src1_valid <= 1'b1;
            end 
        end

        lsq_state <= lsq_next_state;
    end
end

function void set_defaults();
    full = 1'b0;
    finished_entry = 1'b0;
    data_mem_address = 32'h00000000;
    wdata_reg = 5'b00000;
    data_read = 1'b0;
    data_write = 1'b0;
endfunction

always_comb begin : actions
    set_defaults();

    case (lsq_state)
        RESET: begin
            full = 1'b1;
        end
        ACTIVE: begin
            /* finished getting the data for the current entries */
            if (data_mem_resp & ~flush_ip & ~invalidated[head_ptr]) begin
                finished_entry = 1'b1;
            end
            /* address ready for head of queue, request data from memory */
            if (addr_rdy[head_ptr] & (rob_head_ptr == entries[head_ptr].rd_tag)) begin
                if (entries[head_ptr].opcode == tomasula_types::s_op_load) begin
                    data_read = 1'b1;
                end
                /* should not send write signal at all if entry is invalidated */
                else if (~invalidated[head_ptr]) begin
                    data_write = 1'b1;
                    wdata_reg = entries[head_ptr].src2_reg;
                end
                data_mem_address = entries[head_ptr].src1_data + entries[head_ptr].src2_data;
            end

            if (entries_allocated[0] & entries_allocated[1] & entries_allocated[2] & entries_allocated[3])
                full = 1'b1;

            
        end
        FLUSH: begin
            full = 1'b1;
        end
    endcase
end

always_comb begin : next_state_logic
    lsq_next_state = lsq_state;
    
    case (lsq_state)
        RESET: begin
            if (~rst)
                lsq_next_state = ACTIVE;
        end
        ACTIVE: begin
            if (flush_ip & ~data_mem_resp)
                lsq_next_state = FLUSH;
        end
        FLUSH: begin
            if (data_mem_resp)
                lsq_next_state = ACTIVE;
        end
    endcase
end

endmodule