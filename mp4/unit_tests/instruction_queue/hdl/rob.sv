module rob
import rv32i_types::*;
(
    input clk, 
    input rst, 
    // from iq
    input rob_load,
    // from iq
    input tomasula_types::op_t instr_type,
    input [4:0] rd,
    input [4:0] st_src,

    // when high, need to flush rob
    input branch_mispredict,

    // from d-cache
    input data_mem_resp,

    // determines if rob entry has been computed
    // from reservation station
    input logic set_rob_valid[8],
    output logic [7:0] status_rob_valid,

    // to regfile
    output [2:0] curr_ptr,
    output [2:0] head_ptr,
    output [2:0] br_ptr,
    output [4:0] rd_commit,
    output [4:0] st_src_commit,
    output regfile_load,
    output rob_full,

    // signal to select between using data from cdb or d-cache
    output ld_commit_sel,

    // determined by branch output
    output ld_br,

    // to d-cache
    output data_read,
    output data_write
);

tomasula_types::op_t instr_arr [8];
logic [4:0] rd_arr [8];
logic valid_arr [8];

logic [4:0] _rd_commit, _st_src_commit;
logic flush_ip;
logic _ld_commit_sel;
logic _ld_br;
logic _data_read, _data_write;
logic _regfile_load;
logic _rob_full;

logic [2:0] _curr_ptr, _head_ptr, br_ptr;

// assign rd_commit = _rd_commit;
assign rd_commit = rd_arr[_head_ptr];
assign st_src_commit = _st_src_commit;
assign ld_commit_sel = _ld_commit_sel;
assign ld_br = _ld_br;
assign data_read = _data_read;
assign data_write = _data_write;
assign regfile_load = _regfile_load;
assign rob_full = _rob_full;
assign curr_ptr = _curr_ptr;
assign head_ptr = _head_ptr;

assign _rob_full = _head_ptr + 3'h7 == _curr_ptr;

assign status_rob_valid[0] = valid_arr[0];
assign status_rob_valid[1] = valid_arr[1];
assign status_rob_valid[2] = valid_arr[2];
assign status_rob_valid[3] = valid_arr[3];
assign status_rob_valid[4] = valid_arr[4];
assign status_rob_valid[5] = valid_arr[5];
assign status_rob_valid[6] = valid_arr[6];
assign status_rob_valid[7] = valid_arr[7];

always_ff @(posedge clk) begin
    _ld_br <= 1'b0;
    _ld_commit_sel <= 1'b0;
    _regfile_load <= 1'b0;

    if (rst) begin
        for (int i=0; i<8; i++) begin
            instr_arr[i] <= tomasula_types::op_t'(0);
            rd_arr[i] <= '0;
            valid_arr[i] <= '0;
        end
        _curr_ptr <= 3'b000;
        _head_ptr <= 3'b000;
        br_ptr <= 3'b000;
        flush_ip <= 1'b0;
    end

    else begin 
        for (int i = 0; i < 8; i++) begin
            if (set_rob_valid[i]) begin
                valid_arr[i] <= 1'b1;
            end
        end
        if (rob_load) begin
           // allocate ROB entry 
           instr_arr[_curr_ptr] <= instr_type; 
           rd_arr[_curr_ptr] <= rd; 
           // do not allocate regfile entry for st
           if (instr_type == tomasula_types::ST) begin 
               rd_arr[_curr_ptr] <= st_src;
           end
           else if (instr_type != tomasula_types::BRANCH) begin
               // output to regfile
            //    _rd_commit <= rd;
           end
           // increment _curr_ptr
           //TODO: beware! overflow may cause errors
           _curr_ptr <= _curr_ptr + 1'b1;
        end

        // if the head of the rob has been computed
        if (valid_arr[_head_ptr]) begin
            if(instr_arr[_head_ptr] == tomasula_types::BRANCH) begin
               _ld_br <= 1'b1; 
            end
            else if (instr_arr[_head_ptr] == tomasula_types::LD) begin
                _data_read <= 1'b1;
                // make sure instruction is not committed until data returned
                // from d-cache...
                if (data_mem_resp) begin
                    _data_read <= 1'b0;
                    valid_arr[_head_ptr] <= 1'b0;
                    // use d-cache data
                    _ld_commit_sel <= 1'b1;
                    _regfile_load <= 1'b1;
                    // _rd_commit <= rd_arr[_head_ptr];
                    // update head
                    _head_ptr <= _head_ptr + 1'b1;
                end
            end
            else if (instr_arr[_head_ptr] == tomasula_types::ST) begin
                _data_write <= 1'b1;
                // for st address
                // send regfile the register file to read from
                _st_src_commit <= rd_arr[_head_ptr];
                // once store has been processed
                if (data_mem_resp) begin
                    _data_write <= 1'b0;
                    valid_arr[_head_ptr] <= 1'b0;
                    _head_ptr <= _head_ptr + 1'b1;
                end
            end
            // for all other instructions
            else begin
                _regfile_load <= 1'b1;
                valid_arr[_head_ptr] <= 1'b0;

                // increment _head_ptr
                // _rd_commit <= rd_arr[_head_ptr];
                _head_ptr <= _head_ptr + 1'b1;
            end
        end
        // branch mispredict handling
        if (branch_mispredict) begin
            flush_ip <= 1'b1;
            br_ptr <= _head_ptr;
        end 
        // FIXME: does this if get processed on the same cycle flush_ip is set?
        if (flush_ip) begin
            if (instr_arr[br_ptr] == tomasula_types::BRANCH) begin
                // if we reached the branch, set the valid bit. 
                // will be committed on the next cycle
                // FIXME: im dont think the valid bit needs to be set here,
                // since at this point there was a branch already calculated
                // which has the valid bit set already
                valid_arr[br_ptr] = 1'b1;
                // flush all instructions after the branch
                for (int i = br_ptr + 1; i <= (_head_ptr + 7) % 8; i++) begin
                    valid_arr[i] <= 1'b0;
                end
                // update current pointer
                _curr_ptr = br_ptr;
                // flush now finished processing
                flush_ip <= 1'b0;
            end
            // if we haven't reached the branch yet
            else begin
                // _rd_commit <= rd_arr[br_ptr];
                br_ptr <= br_ptr + 1'b1;
            end
        end
    end
end

endmodule : rob
