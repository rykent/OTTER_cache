`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cow Poly
// Engineer: Danny Gutierrez
// 
// Create Date: 04/05/2024 11:14:42 PM
// Design Name: 
// Module Name: SinglePortDelayMemory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//        This module is the main memory module.
//        It is single ported and has a delay of DELAY_CYCLES.
//        It has a burst length of BURST_LEN. For each cycle in the burst, MEMVALID is asserted. Each cycle in the burst, the memory is read or written to.
//        The memory is initialized with the contents of otter_memory.mem
//        The memory is 64KB in size. 2^16 x 32 bits
//        Can only read or write to one port at a time.
//        !!! This module writes to memory on the falling edge of the clock !!!
//
// Instantiated by:
//      SinglePortMemory #(
//          .DELAY_CYCLES   (10),
//          .BURST_LEN      (4)
//      ) mySinglePortMemory (
//          .CLK            (),
//          .RE             (),
//          .WE             (),
//          .DATA_IN        (),
//          .ADDR           (),
//          .DATA_OUT       (),
//          .MEMVALID       ()
//      );
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SinglePortDelayMemory #(
    parameter DELAY_CYCLES = 10,
    parameter BURST_LEN = 4
    ) (
    input CLK,
    input RE,
    input WE,
    input [31:0] DATA_IN,
    input [31:0] ADDR,
    output logic MEM_VALID,
    output logic [31:0] DATA_OUT
    );
    
    logic [31:0] memory [0:16383];
    initial begin
        $readmemh("otter_memory.mem", memory, 0, 16383);
    end

    initial begin
        forever begin
            MEM_VALID = 0;
            @(posedge CLK iff RE | WE);
            for (int i = 0; i < DELAY_CYCLES; i++) begin
                @(posedge CLK);
            end
            for (int i = 0; i < BURST_LEN; i++) begin
                if (RE ^ WE)
                    MEM_VALID = 1;
                else
                    MEM_VALID = 0;
                @(posedge CLK);
            end
        end
    end

    always_comb begin 
        DATA_OUT = MEM_VALID ? memory[ADDR] : 32'hdeadbeef;
    end

    always_ff @(negedge CLK) begin
        if (WE && MEM_VALID) begin
            memory[ADDR] <= DATA_IN;
        end
    end
 
endmodule