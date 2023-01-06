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
    // input set_rob0_valid,
    // input set_rob1_valid,
    // input set_rob2_valid,
    // input set_rob3_valid,
    // input set_rob4_valid,
    // input set_rob5_valid,
    // input set_rob6_valid,
    // input set_rob7_valid,
    
    input logic set_rob_valid[8],
    output logic status_rob_valid[8],

    // output status_rob0_valid,
    // output status_rob1_valid,
    // output status_rob2_valid,
    // output status_rob3_valid,
    // output status_rob4_valid,
    // output status_rob5_valid,
    // output status_rob6_valid,
    // output status_rob7_valid,

    // to regfile
    output [2:0] rob_tag,
    output [4:0] rd_inflight,
    output [4:0] st_commit,
    output regfile_allocate,
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
logic 
logic [4:0] rd_arr [8];
logic [4:0] st_arr [8];
logic valid_arr [8];

logic [2:0] rob_tag;
logic [4:0] rd_inflight, st_commit;
logic flush_ip;
logic ld_br;
logic data_read, data_write;
logic regfile_allocate, regfile_load;
logic rob_full

logic [2:0] curr_ptr;
logic [2:0] head_ptr;
logic [2:0] br_ptr;

assign rob_full = (head_ptr + 7) % 8 == curr_ptr;

always_comb begin : assign_rob_valids
    for (int i = 0; i < 8; i++) begin
        status_rob_valid[i] = valid_arr[i];
    end
end

always_ff @(posedge clk) begin
    load_pc <= 1'b0;
    ld_commit_sel <= 1'b0;
    regfile_allocate <= 1'b0;

    if (rst) begin
        for (int i=0; i<8; i++) begin
            instr_arr[i] <= '0;
            rd_arr[i] <= '0;
            st_arr[i] <= '0;
            valid_arr[i] <= 0;
        end
        curr_ptr <= 3'b000;
        head_ptr <= 3'b000;
        br_ptr <= 3'b000;
        flush_ip <= 1'b0;
    end

    else begin 
        // initialize valids
        for (int i = 0; i < 8; i++) begin
            valid_arr[i] <= set_rob_valid[i];
        end
        
        if (rob_load) begin
           // allocate ROB entry 
           instr_arr[curr_ptr] <= instr_type; 
           rd_arr[curr_ptr] <= rd; 
           // do not allocate regfile entry for st
           if (instr_type == tomasula_types::ST) begin 
               rd_arr[curr_ptr] <= st_src;
           end
           else if (instr_type != tomasula_types::BRANCH) begin
               // output to regfile
               rd_inflight <= rd;
               rob_tag <= curr_ptr;
               regfile_allocate <= 1'b1;
           end
           // increment curr_ptr
           curr_ptr <= (curr_ptr + 1) % 8;
        end

        // if the head of the rob has been computed
        if (valid_arr[head_ptr]) begin
            if(instr_arr[head_ptr] == tomasula_types::BRANCH) begin
               load_pc <= 1'b1; 
            end
            else if (instr_arr[head_ptr] == tomasula_types::LD) begin
                data_read <= 1'b1;
                rob_tag <= head_ptr;
                // address comes from cdb, determined by rob_tag
                // make sure instruction is not committed until data returned
                // from d-cache...
                if (data_mem_resp) begin
                    data_read <= 1'b0;
                    valid_arr[head_ptr] <= 1'b0;
                    // use d-cache data
                    ld_commit_sel <= 1'b1;
                    regfile_load <= 1'b1;
                    rd_inflight <= rd_array[head_ptr];
                    // update head
                    head_ptr <= (head_ptr + 1) % 8;
                end
            end
            else if (instr_arr[head_ptr] == tomasula_types::ST) begin
                data_write <= 1'b1;
                // for st address
                rob_tag <= head_ptr;
                // send regfile the register file to read from
                st_commit <= dr_arr[head_ptr];
                // once store has been processed
                if (data_mem_resp) begin
                    data_write <= 1'b0;
                    valid_arr[head_ptr] <= 1'b0;
                    head_ptr <= (head_ptr + 1) % 8;
                end
            end
            // for all other instructions
            else begin
                regfile_load <= 1'b1;
                valid_arr[head_ptr] <= 1'b0;

                // increment head_ptr
                rd_inflight <= rd_array[head_ptr];
                rob_tag <= head_ptr;
                head_ptr <= (head_ptr + 1) % 8;
            end
        end
        // branch mispredict handling
        if (branch_mispredict) begin
            flush_ip <= 1'b1;
            br_ptr <= head_ptr;
        end 
        // FIXME: does this if get processed on the same cycle flush_ip is set?
        if (flush_ip) begin
            if (instr_type[br_ptr] == tomasula_types::BRANCH) begin
                // if we reached the branch, set the valid bit. 
                // will be committed on the next cycle
                // FIXME: im dont think the valid bit needs to be set here,
                // since at this point there was a branch already calculated
                // which has the valid bit set already
                valid_arr[br_ptr] = 1'b1;
                // flush all instructions after the branch
                for (int i = br_ptr + 1; i <= (head_ptr + 7) % 8; i++) begin
                    valid_arr[i] <= 1'b0;
                end
                // update current pointer
                curr_ptr = br_ptr;
                // flush now finished processing
                flush_ip <= 1'b0;
            end
            // if we haven't reached the branch yet
            else begin
                regfile_allocate <= 1'b1;
                rd_inflight <= rd_arr[br_ptr];
                rob_tag <= br_ptr;
                br_ptr <= (br_ptr + 1) % 8;
            end
        end
    end
end

endmodule : rob
