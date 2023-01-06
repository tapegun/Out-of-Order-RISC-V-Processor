
module regfile
(
    input clk,
    input rst,
    input load,
    input allocate,
    input logic [4:0] reg_allocate,
    input logic [31:0] in, // data to place into dest register
    input logic [4:0] src_a, src_b, dest, // src registers to read and dest register to change
    input logic [2:0] tag_in, // rob tag that will right into dest register next
    output logic [31:0] reg_a, reg_b,
    output logic valid_a, valid_b,
    output logic [2:0] tag_a, tag_b, //tag_dest,

    // signals for memory interaction
    
    input logic [4:0]src_c,
    output logic [31:0] data_out
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
            valid[i] = 1'b1;
        end
    end
    //FIXME: must support simultaneous load and allocate
    // allocate: read in from control_o (instruction queue)
    // load: read in from cdb, get register from rob.
    else begin
        if (load && dest)
        begin
            data[dest] <= in;
            valid[dest] <= 1'b1;
        end

        if(allocate && reg_allocate)
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

    if((dest == src_a) && load ) begin
        reg_a = in;
        reg_b = src_b ? data[src_b] : 0;
        valid_a = 1'b1;
        valid_b = valid[src_b];
    end

    else if((dest == src_b) && load) begin
        reg_a = src_a ? data[src_a] : 0;
        reg_b = in;
        valid_a = valid [src_a];
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
