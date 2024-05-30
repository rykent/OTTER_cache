`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cow Poly
// Engineer: 
// 
// Create Date: 04/07/2024 12:18:27 AM
// Design Name: 
// Module Name: OtterMemory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//     This module is the memory wrapper.
//     It is responsible for interfacing between the memory and the OTTER.
// 
// Instantiated by:
//      OtterMemory myOtterMemory (
//          .MEM_CLK        (),
//          .MEM_RST        (),
//          .MEM_RDEN1      (),
//          .MEM_RDEN2      (),
//          .MEM_WE2        (),
//          .MEM_ADDR1      (),
//          .MEM_ADDR2      (),
//          .MEM_DIN2       (),
//          .MEM_SIZE       (),
//          .MEM_SIGN       (),
//          .IO_IN          (),
//          .IO_WR          (),
//          .MEM_DOUT1      (),
//          .MEM_DOUT2      (),
//          .MEM_VALID1     (),
//          .MEM_VALID2     ()
//      );
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   IO taken from 233 memory module. Thanks to the creators of that module.
//   This module IO should not be changed.
//   This memory system should be able to work with the multi-cycle and pipeline OTTER. Change your controllers accordingly.
//   Have fun with this lab :)
//
//////////////////////////////////////////////////////////////////////////////////


module OtterMemory (
    input MEM_CLK, 
    input MEM_RST,
    input MEM_RDEN1,                // read enable Instruction
    input MEM_RDEN2,                // read enable data
    input MEM_WE2,                  // write enable.
    input [13:0] MEM_ADDR1,         // Instruction Memory word Addr (Connect to PC[15:2])
    input [31:0] MEM_ADDR2,         // Data Memory Addr
    input [31:0] MEM_DIN2,          // Data to save
    input [1:0] MEM_SIZE,           // 0-Byte, 1-Half, 2-Word
    input MEM_SIGN,                 // 1-unsigned 0-signed
    input [31:0] IO_IN,             // Data from IO     
    output logic IO_WR,             // IO 1-write 0-read
    output logic [31:0] MEM_DOUT1,  // Instruction
    output logic [31:0] MEM_DOUT2,  // Data
    output logic MEM_VALID1,
    output logic MEM_VALID2,
    output ERR
    );
    
    /* ADD YOUR DESIGN HERE */

    logic d_lru_dirty, d_set_dirty, d_set_valid, d_update_tag, d_clear_valid, d_update_cacheline, d_hit, d_lru_valid, d_update_lru, d_clear_dirty, d_cl_busy, d_cl_write, d_cl_read, d_mem_RE, d_mem_WE;

    logic [255:0] d_cacheline_in, d_cacheline_out;

    logic [31:0] d_mem_to_cache_data, d_cache_to_mem_data, d_mem_addr;

    logic [31:0] dcacheReadSized, memAddr2Buffer, ioBuffer;

    logic addrValid;

    logic alignment_error;
    assign ERR = alignment_error;

    // Alignment check logic
    always_comb begin
        alignment_error = 0;
        if ((MEM_SIZE == 2'b01 && MEM_ADDR2[0] != 0) || // Half-word not aligned
            (MEM_SIZE == 2'b10 && MEM_ADDR2[1:0] != 2'b00)) begin // Word not aligned
            alignment_error = 1;
        end
    end

    // L1 or L1s

    CacheLineAdapter D_clAdapter (
        .CLK      (MEM_CLK),
        .RST      (MEM_RST),
        .cl_busy  (d_cl_busy),
        .cl_write (d_cl_write),
        .cl_read  (d_cl_read),
        .addr     (MEM_ADDR2),
        .m_data_o (d_mem_to_cache_data),
        .c_data_i (d_cacheline_out),
        .m_o_valid(d_mem_to_cache_valid),
        .m_data_i (d_cache_to_mem_data),
        .m_waddr  (d_mem_addr),
        .mem_we   (d_mem_WE),
        .mem_re   (d_mem_RE),
        .c_data_o (d_cacheline_in)
    );

    // Your choice of dual port or single port main memory

    SinglePortDelayMemory #(
        .DELAY_CYCLES   (10),
        .BURST_LEN      (4)
      ) mySinglePortMemory (
        .CLK            (MEM_CLK),
        .RE             (d_mem_RE),
        .WE             (d_mem_WE),
        .DATA_IN        (d_cache_to_mem_data),
        .ADDR           (d_mem_addr),
        .DATA_OUT       (d_mem_to_cache_data),
        .MEM_VALID       (d_mem_to_cache_valid)
    );

    // Cache Controller

    CacheController D_cacheController (
        .CLK        (MEM_CLK),
        .RST             (MEM_RST),
        .mem_read        (MEM_RDEN2),
        .mem_write       (MEM_WE2),
        .hit             (d_hit),
        .lru_valid       (d_lru_valid),
        .lru_dirty       (d_lru_dirty),
        .cl_busy         (d_cl_busy),
        .update_lru      (d_update_lru),
        .update_tag      (d_update_tag),
        .update_cacheline(d_update_cacheline),
        .mem_valid       (MEM_VALID2),
        .set_dirty       (d_set_dirty),
        .clear_dirty     (d_clear_dirty),
        .set_valid       (d_set_valid),
        .clear_valid     (d_clear_valid),
        .cl_read         (d_cl_read),
        .cl_write        (d_cl_write),
        .addr_valid     (addrValid)
    );

    // Cache Data

    cache D_cache (
        .CLK             (MEM_CLK),
        .RST             (MEM_RST),
        .mem_read        (MEM_RDEN2),
        .mem_size        (MEM_SIZE),
        .mem_sign        (MEM_SIGN),
        .lru_dirty       (d_lru_dirty),
        .set_dirty       (d_set_dirty),
        .set_valid       (d_set_valid),
        .update_tag      (d_update_tag),
        .clear_valid     (d_clear_valid),
        .update_cacheline(d_update_cacheline),
        .hit             (d_hit),
        .lru_valid       (d_lru_valid),
        .mem_write       (MEM_WE2),
        .update_lru      (d_update_lru),
        .clear_dirty     (d_clear_dirty),
        .addr            (MEM_ADDR2),
        .data_in         (MEM_DIN2),
        .cacheline_in    (d_cacheline_in),
        .data_out        (dcacheReadSized),
        .cacheline_out   (d_cacheline_out),
        .addr_valid     (addrValid)
    );


    // buffer the IO input for reading
    always_ff @(posedge MEM_CLK) begin
      if(MEM_RDEN2)
        ioBuffer <= IO_IN;
        memAddr2Buffer <= MEM_ADDR2;
    end
 
    // Memory Mapped IO
    always_comb begin
      if(memAddr2Buffer >= 32'h00010000) begin  // external address range
        IO_WR = MEM_WE2;                 // IO Write
        MEM_DOUT2 = ioBuffer;            // IO read from buffer
        addrValid = 0;                 // address beyond memory range
      end
      else begin
        IO_WR = 0;                  // not MMIO
        MEM_DOUT2 = dcacheReadSized;   // output sized and sign extended data
        addrValid = ~alignment_error;      // address in valid memory range
      end
    end


endmodule
