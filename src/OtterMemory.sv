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
    output logic MEM_VALID2
    );
    
    /* ADD YOUR DESIGN HERE */

    // L1 or L1s

    CacheLineAdapter myCacheLineAdapter (
        .CLK        ()
    );

    // Your choice of dual port or single port main memory

    SinglePortMemory #(
        .DELAY_CYCLES   (10),
        .BURST_LEN      (4)
      ) mySinglePortMemory (
        .CLK            (),
        .RE             (),
        .WE             (),
        .DATA_IN        (),
        .ADDR           (),
        .DATA_OUT       (),
        .MEMVALID       ()
    );

    // Cache Controller

    CacheController myCacheController (
        .CLK        ()
    );

endmodule
