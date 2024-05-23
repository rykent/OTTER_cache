`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cow Poly
// Engineer: Danny Gutierrez
// 
// Create Date: 04/07/2024 12:27:49 AM
// Design Name: 
// Module Name: CacheController
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      This module is the cache controller.
//      It is responsible for controlling the memory system.
//
// Instantiated by:
//      CacheController myCacheController (
//          .CLK        ()
//      );
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CacheController(
    input CLK,
    input RST
    );

    typedef enum {IDLE, HIT_CHECK, MISS, MEM_READ, REFILL} state;

    state ps,ns;

    always_ff @(posedge CLK) begin : proc_
        if(RST) begin
            ps <= IDLE;
        end else begin
            ps <= ns;
        end
    end

    always_comb begin
        case (ps)

        endcase
    end

endmodule
