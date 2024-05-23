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
    input RST,
    input mem_read,
    input mem_write,
    input hit,
    input lru_valid,
    input lru_dirty,
    input cl_busy,
    output update_lru,
    output update_tag,
    output mem_valid,
    output set_dirty,
    output clear_dirty,
    output set_valid,
    output clear_valid,
    output cl_read,
    output cl_write
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
        update_lru = 0;
        update_tag = 0;
        mem_valid = 0;
        set_dirty = 0;
        clear_dirty = 0;
        set_valid = 0;
        clear_valid = 0;
        cl_read = 0;
        cl_write = 0;
        case (ps)
            IDLE: begin
                //Wait for mem read or mem write (constantly reading the tag/index arrays checking for hits)
                if (read | write) begin
                    ns = HIT_CHECK;
                end
                else begin
                    ns = IDLE;
                end
            end
            HIT_CHECK: begin
                //Check if there was a hit on mem read or write
                if (hit & mem_read) begin
                    update_lru = 1'b1;
                    mem_valid = 1'b1;
                    ns = IDLE;
                end
                else if (hit & mem_write) begin
                    update_lru = 1'b1;
                    mem_valid = 1'b1;
                    set_dirty = 1'b1;
                    ns = IDLE;
                end
                else begin
                    ns = MISS;
                end
            end
            MISS: begin
                if (lru_valid & lru_dirty) begin
                    //If cache miss and data was valid and dirty writeback to memory
                    cl_write = 1'b1;
                    clear_valid = 1'b1;
                    clear_dirty = 1'b1;
                    ns = MEM_READ;
                end
                else if (~lru_valid | (lru_valid & ~lru_dirty)) begin
                    //No writeback neeeded start read into cache
                    cl_read = 1'b1;
                    ns = REFILL;
                end
                else begin
                    //Shouldn't get here
                    ns = IDLE;
                end
            end
            MEM_READ: begin
                if (cl_busy) begin
                    ns = MEM_READ;
                end
                else begin
                    cl_read = 1'b1;
                    ns = REFILL;
                end
            end
            REFILL: begin
                if (cl_busy) begin
                    ns = REFILL;
                end
                else begin
                    update_tag = 1'b1;
                    set_valid = 1'b1;
                    clear_dirty = 1'b1;
                    ns = HIT_CHECK;
                end
            end
            default: begin 
                ns = IDLE;
            end
        endcase
    end

endmodule
