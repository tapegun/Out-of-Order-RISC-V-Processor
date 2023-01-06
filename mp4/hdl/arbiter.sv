module arbiter
import rv32i_types::*;
import adaptor_types::*;
(
    input clk,
    input rst,

    // instruction cache
    input addr_t instr_cache_address,
    output line_t instr_pmem_to_cache,
    input line_t instr_cache_to_pmem,
    input logic instr_cache_read,
    input logic instr_cache_write,
    output logic instr_cache_resp,

    // data cache
    input addr_t data_cache_address,
    output line_t data_pmem_to_cache,
    input line_t data_cache_to_pmem,
    input logic data_cache_read,
    input logic data_cache_write,
    output logic data_cache_resp,

    // pmem
    input line_t pmem_to_cache,
    output line_t cache_to_pmem,
    output addr_t cache_address,
    output logic cache_read,
    output logic cache_write,
    input logic cache_resp
);

/**************************** DECLARATIONS ***********************************/
/*
line_t cache_to_pmem;
line_t instr_pmem_to_cache, data_pmem_to_cache;
addr_t cache_address;
logic cache_read, cache_write;
logic instr_cache_resp, data_cache_resp;
*/

enum logic [2:0] {
    NONE,
    INSTR1,
    INSTR2,
    DATA1,
    DATA2
} state, next_state;

logic instr_req, data_req;
assign instr_req = instr_cache_read;
assign data_req = data_cache_read | data_cache_write;
/*****************************************************************************/

function void set_defaults();
    cache_to_pmem = '0;
    /*
    instr_pmem_to_cache = '0;
    data_pmem_to_cache = '0;
    */
    cache_address = 32'h00000000;
    cache_read = 1'b0;
    cache_write = 1'b0;
    instr_cache_resp = 1'b0;
    data_cache_resp = 1'b0;
endfunction

 
/*************************** STATE ASSIGNMENTS *******************************/
//FIXME: may have to hold the request information for a read in a buffer if
    //a simultaneous request occurs?
//FIXME: need to check if instr and data cache responses go high before
    //transitioning states
always_comb begin
    set_defaults();
    case (state)
    NONE: ;
    INSTR1: begin
        cache_to_pmem = instr_cache_to_pmem;
        cache_address = instr_cache_address;
        cache_read = instr_cache_read;
        cache_write = instr_cache_write;
        instr_pmem_to_cache = pmem_to_cache;
        instr_cache_resp = cache_resp;
        data_cache_resp = 1'b0;
    end
    DATA1: begin
        cache_to_pmem = data_cache_to_pmem;
        cache_address = data_cache_address;
        cache_read = data_cache_read;
        cache_write = data_cache_write;
        data_pmem_to_cache = pmem_to_cache;
        data_cache_resp = cache_resp;
        instr_cache_resp = 1'b0;
    end
    INSTR2, DATA2:;
    endcase
end
/*****************************************************************************/

/*************************** NEXT STATE LOGIC ********************************/
always_comb begin
    next_state = state;
    case (state)
    NONE: begin
        if (data_req) begin
            next_state = DATA1;
        end
        else begin
            if (instr_req) begin
                next_state = INSTR1;
            end
        end
    end
    INSTR1: begin
        if (cache_resp) begin
            next_state = INSTR2;
        end
    end
    INSTR2: begin
        if (data_req) begin
            next_state = DATA1;
        end
        else begin
            if (instr_req) begin
                next_state = INSTR1;
            end
            else begin
                next_state = NONE;
            end
        end
    end
    DATA1: begin
        if (cache_resp) begin
            next_state = DATA2;
        end
    end
    DATA2: begin
        if (data_req) begin
            next_state = DATA1;
        end
        else begin
            if (instr_req) begin
                next_state = INSTR1;
            end
            else begin
                next_state = NONE;
            end
        end
    end
    endcase
end
/*****************************************************************************/


/************************* Non-Blocking Assignments **************************/
always_ff @(posedge clk) begin
    if (rst) begin
        state <= NONE;
    end
    else begin
        state <= next_state;
    end
end

endmodule : arbiter

