
module regfile
(
    input clk,
    input rst,
    input load, // update data in destination register
    input allocate, // input signal to allocate a new tag to be assigned to a register while also declaring the register's data as not valid (not up to date)
    input logic [4:0] reg_allocate, // the register to update with a new tag and set valid to 0
    input logic [2:0] commit_tag, // potentially make the register valid if the committed tag matches the current tag
    input logic [2:0] tag_in, // rob tag that will right into dest register next

    input logic [31:0] in, // data to place into dest register
    input logic [4:0] src_a, src_b, dest, // src registers to read and dest register to change
    output logic [31:0] reg_a, reg_b, // data from src a and b registers 

    output logic valid_a, valid_b, // if data on registers is most up to date or if they are in the cdb
    output logic [2:0] tag_a, tag_b, // where the data for the source registers exist in the cdb if not valid

    /* signal to set registers back to valid after a flush */
    input logic set_reg_valid [8],
    input logic [4:0] reg_valid [8],
    input logic flush_ip,
    
    input logic [4:0]src_c, // data to be read for a store
    output logic [31:0] data_out // data from src c
);

logic [31:0] data [32];
logic [2:0] tag [32];
logic valid [32];       // 0 means waiting for ROB to fill it up, 1 means its rdy

always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
            tag[i] <= '0;
            valid[i] <= 1'b1;
        end
    end
    //FIXME: must support simultaneous load and allocate
    // allocate: read in from control_o (instruction queue)
    // load: read in from cdb, get register from rob.
    else begin
        if (load && dest)
        begin
            data[dest] <= in;
            /* only set to valid if the commit tag matches, otherwise the register is waiting on more rob entries to update it */
            if (commit_tag == tag[dest])
                valid[dest] <= 1'b1;
        end

        /* if a flush is in progress, registers need to know that their values are once again valid */
        if (flush_ip) begin
            for (int i = 0; i < 8; i=i+1) begin
                if (set_reg_valid[i])
                    valid[int'(reg_valid[i])] <= 1'b1;
            end
        end
        /* updating tag that register will be updated by, ignore incoming tag from register load */
        else if(allocate && reg_allocate)
        begin
            valid[reg_allocate] <= 1'b0;
            tag[reg_allocate] <= tag_in;
        end 

        
    end

end

always_comb
begin
    // default values
    valid_a = 1'b0;
    valid_b = 1'b0;
    if ((dest == src_a) && (src_a == src_b) && (src_a != 5'b00000) && load) begin
        reg_a = in;
        reg_b = in;
        if (tag[src_a] == commit_tag) begin
            valid_a = 1'b1;
            valid_b = 1'b1;
        end
    end
    else if((dest == src_a) && (src_a != 5'b00000) && load ) begin
        reg_a = in;
        reg_b = src_b ? data[src_b] : 0;
        if (tag[src_a] == commit_tag)
            valid_a = 1'b1;
        valid_b = valid[src_b];
    end

    else if((dest == src_b) && (src_b != 5'b00000) && load) begin
        reg_a = src_a ? data[src_a] : 0;
        reg_b = in;
        valid_a = valid [src_a];
        if (tag[src_b] == commit_tag)
            valid_b = 1'b1;
    end
    
    else  begin
        reg_a = src_a ? data[src_a] : 0;
        reg_b = src_b ? data[src_b] : 0;
        valid_a = valid [src_a];
        valid_b = valid [src_b];
    end

    tag_a = tag[src_a];
    tag_b = tag[src_b];
    
    data_out = data[src_c];
    
end

endmodule : regfile
