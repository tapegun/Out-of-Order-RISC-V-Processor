module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2
logic rvfi_commit_buff;
logic [4:0] rvfi_rdaddr_buff;
logic [31:0] mem_wdata_buff;

always_ff @(posedge itf.clk) begin
    if (dut.ooo.rob.rvfi_commit | dut.ooo.itf.rob_ld_pc)
        rvfi_commit_buff <= 1'b1;
    else
        rvfi_commit_buff <= 1'b0;

    if (dut.ooo.rob.regfile_load)
        rvfi_rdaddr_buff[4:0] <= dut.ooo.regfile.dest[4:0];
    else
        rvfi_rdaddr_buff[4:0] <= rvfi_rdaddr_buff[4:0];

    if (dut.ooo.data_mem_resp)
        mem_wdata_buff <= dut.ooo.itf.regfile_data_out;

end

assign rvfi.commit = dut.ooo.itf.rob_ld_pc | dut.ooo.rob.rvfi_commit;
// assign rvfi.halt = 1'b0;
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO
always @(posedge itf.clk) begin
    if (itf.rst)
        rvfi.halt <= 1'b0;    

    else if (rvfi.commit & ((rvfi.pc_rdata == rvfi.pc_wdata)))
        rvfi.halt <= 1'b1;
end
assign rvfi.load_regfile = dut.ooo.rob.regfile_load;

//Instruction and trap:
assign rvfi.inst = dut.ooo.rob.curr_rvfi_word.inst;
assign rvfi.trap = 1'b0;




// registers and pc for architectural state tracking
assign rvfi.rd_wdata = rvfi.rd_addr ? dut.ooo.regfile.in : 0; // rd_wdata only valid when writing to a register that is not x0
assign rvfi.rs1_addr =  dut.ooo.rob.curr_rvfi_word.rs1_addr;

always_comb begin : set_rs2
    if (dut.ooo.rob.curr_rvfi_word.inst[6:0] == 7'b0100011) begin
        rvfi.rs2_addr = dut.ooo.rob.rd_arr[dut.ooo.rob._head_ptr];
        rvfi.rs2_rdata = mem_wdata_buff;
    end
    else if (dut.ooo.rob.curr_rvfi_word.imm) begin
        rvfi.rs2_addr = 5'b00000;
        rvfi.rs2_rdata = 32'h00000000;
    end
    else begin
        rvfi.rs2_addr = dut.ooo.rob.curr_rvfi_word.rs2_addr;
        rvfi.rs2_rdata = dut.ooo.cdb.out[dut.ooo.rob._head_ptr].rs2_data;
    end
end

assign rvfi.rs1_rdata = dut.ooo.cdb.out[dut.ooo.rob.curr_rvfi_word.rd_tag].rs1_data;
assign rvfi.rd_addr =  (dut.ooo.rob.curr_rvfi_word.inst[6:0] == 7'b0100011) ? 5'b00000 : dut.ooo.rob.curr_rvfi_word.rd_addr;
assign rvfi.pc_rdata = dut.ooo.rob.curr_rvfi_word.pc_rdata;

/* display correct pc for rvfi */
logic res_jalr_buff;
logic [31:0] jalr_pc_buff;

always_ff @(posedge itf.clk) begin
    if (itf.rst) begin
        res_jalr_buff <= 1'b0;
        jalr_pc_buff <= 32'h00000000;
    end
    else begin
        
        if (dut.ooo.itf.res1_jalr_executed) begin
            jalr_pc_buff <= dut.ooo.itf.alu1_calculation.data[31:0];
            res_jalr_buff <= 1'b1;
        end
        else if (dut.ooo.itf.res2_jalr_executed) begin
            jalr_pc_buff <= dut.ooo.itf.alu1_calculation.data[31:0];
            res_jalr_buff <= 1'b1;
        end
        else if (dut.ooo.itf.res3_jalr_executed) begin
            jalr_pc_buff <= dut.ooo.itf.alu1_calculation.data[31:0];
            res_jalr_buff <= 1'b1;
        end
        else if (dut.ooo.itf.res4_jalr_executed) begin
            jalr_pc_buff <= dut.ooo.itf.alu1_calculation.data[31:0];
            res_jalr_buff <= 1'b1;
        end
        else begin 
            res_jalr_buff <= 1'b0; // always reset buffers by default
            jalr_pc_buff <= 32'h00000000;
        end
    end
end

always_comb
begin : pc_next
    if (dut.ooo.itf.rob_ld_pc) // only happens for a branch mispredict
        rvfi.pc_wdata = dut.ooo.itf.cdb_out[dut.ooo.itf.br_ptr].data[31:0] ; // always works but fix later
    else
        rvfi.pc_wdata = dut.ooo.rob.curr_rvfi_word.pc_wdata;
end


/*
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
     // Remove after CP1
    // .instr_mem_resp(itf.inst_resp),
    // .instr_mem_rdata(itf.inst_rdata),
	// .data_mem_resp(itf.data_resp),
    // .data_mem_rdata(itf.data_rdata),
    // .instr_read(itf.inst_read),
	// .instr_mem_address(itf.inst_addr),
    // .data_read(itf.data_read),
    // .data_write(itf.data_write),
    // .data_mbe(itf.data_mbe),
    // .data_mem_address(itf.data_addr),
    // .data_mem_wdata(itf.data_wdata)

    // Connections after CP1
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
    
);
/***************************** End Instantiation *****************************/

endmodule
