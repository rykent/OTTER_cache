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

    typedef enum {IDLE, WR, RE, LRU_DIRTY, MEM_READ, CACHE_EDIT} state;

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
            //Wait for cache reads or writes
            IDLE: begin
                if (mem_read) ns = RE;
                else if (mem_write) ns = WR;
                else ns = IDLE;
            end
            WR: begin
                //Cache Hit go back to IDLE
                if (hit & (~mem_write | ~mem_read)) begin
                    mem_resp = 1'b1;
                    ns = IDLE;
                end
                else if (hit & mem_write) begin
                    mem_resp = 1'b1;
                    ns = WR;
                end
                else if (hit & mem_read) begin
                    mem_resp = 1'b1;
                    ns = RE;
                end
                else if (lru_dirty) begin
                    mem_resp = 1'b0;
                    ns = LRU_DIRTY;
                end
                else begin
                    mem_resp = 1'b0;
                    ns = MEM_READ;
                end
            end
            RE: begin
                
            end
        endcase
    end

endmodule
