module mp4
import rv32i_types::*;
import adaptor_types::*;
(
    input clk,
    input rst,
	
	//Remove after CP1
    // input 					instr_mem_resp,
    // input rv32i_word 	instr_mem_rdata,
	// input 					data_mem_resp,
    // input rv32i_word 	data_mem_rdata, 
    // output logic 			instr_read,
	// output rv32i_word 	instr_mem_address,
    // output logic 			data_read,
    // output logic 			data_write,
    // output logic [3:0] 	data_mbe,
    // output rv32i_word 	data_mem_address,
    // output rv32i_word 	data_mem_wdata

	//Connections after CP1
    input pmem_resp,
    input [63:0] pmem_rdata,

	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic instr_mem_resp, data_mem_resp;
logic instr_read, instr_write, data_read, data_write; 
rv32i_word instr_mem_rdata, data_mem_rdata, data_mem_wdata;
logic [3:0] data_mbe;

rv32i_word instr_mem_address, data_mem_address;
rv32i_word instr_cache_address, data_cache_address;
line_t instr_pmem_to_cache, instr_cache_to_pmem, data_pmem_to_cache, data_cache_to_pmem;
logic instr_cache_read, instr_cache_write, data_cache_read, data_cache_write;
logic instr_cache_resp, data_cache_resp;

line_t pmem_to_cache, cache_to_pmem;
rv32i_word cache_address;
logic cache_read, cache_write;
logic cache_resp;

ooo ooo(.*);

cache i_cache(
    .clk(clk),

    .mem_address(instr_mem_address),
    .mem_rdata_cpu(instr_mem_rdata),
    .mem_wdata_cpu(),
    .mem_read(instr_read),
    .mem_write(1'b0),
    .mem_byte_enable_cpu(),
    .mem_resp(instr_mem_resp),

    .pmem_address(instr_cache_address),
    .pmem_rdata(instr_pmem_to_cache),
    .pmem_wdata(),
    .pmem_read(instr_cache_read),
    .pmem_write(),
    .pmem_resp(instr_cache_resp)
);


cache d_cache(
    .clk(clk),

    .mem_address(data_mem_address),
    .mem_rdata_cpu(data_mem_rdata),
    .mem_wdata_cpu(data_mem_wdata),
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_byte_enable_cpu(data_mbe),
    .mem_resp(data_mem_resp),

    .pmem_address(data_cache_address),
    .pmem_rdata(data_pmem_to_cache),
    .pmem_wdata(data_cache_to_pmem),
    .pmem_read(data_cache_read),
    .pmem_write(data_cache_write),
    .pmem_resp(data_cache_resp)
);


arbiter arbiter (
    .clk(clk),
    .rst(rst),

    .instr_cache_address(instr_cache_address),
    .instr_pmem_to_cache(instr_pmem_to_cache),
    .instr_cache_to_pmem(instr_cache_to_pmem),
    .instr_cache_read(instr_cache_read),
    .instr_cache_write(instr_cache_write),
    .instr_cache_resp(instr_cache_resp),
    
    .data_cache_address(data_cache_address),
    .data_pmem_to_cache(data_pmem_to_cache),
    .data_cache_to_pmem(data_cache_to_pmem),
    .data_cache_read(data_cache_read),
    .data_cache_write(data_cache_write),
    .data_cache_resp(data_cache_resp),

    .pmem_to_cache(pmem_to_cache),
    .cache_to_pmem(cache_to_pmem),
    .cache_address(cache_address),
    .cache_read(cache_read),
    .cache_write(cache_write),
    .cache_resp(cache_resp)
);

cacheline_adaptor cacheline_adaptor 
(
    .clk(clk),
    .reset_n(~rst),

    .line_i(cache_to_pmem),
    .line_o(pmem_to_cache),
    .address_i(cache_address),
    .read_i(cache_read),
    .write_i(cache_write),
    .resp_o(cache_resp),

    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);


endmodule : mp4

