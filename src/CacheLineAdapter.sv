`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cow Poly
// Engineer: Danny Gutierrez
// 
// Create Date: 04/07/2024 12:16:02 AM
// Design Name: 
// Module Name: CacheLineAdapter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:
//         This module is responsible for interfacing between the cache and the memory. The middle man if you will.
//         It will be responsible for reading and writing to the memory
//         It will also be responsible for reading and writing to the cache
//         It will be responsible for the cache line size
// 
// Instantiated by:
//      CacheLineAdapter myCacheLineAdapter (
//          .CLK        ()
//      );
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CacheLineAdapter (
    input CLK,
    input RST,
    input [31:0] addr,
    input [23:0] lru_tag,
    input [255:0] c_data_i,
    input [31:0] m_data_o,
    input cl_read,
    input cl_write,
    input m_o_valid,
    output logic [31:0] m_data_i,
    output logic [31:0] m_waddr,
    output logic mem_we,
    output logic mem_re,
    output [255:0] c_data_o,
    output logic cl_busy
    );

    logic [255:0] data_fifo;

    logic [2:0] count;
    
    logic fifo_we, fifo_re, fifo_s;

    assign m_data_i = data_fifo[255:224];
    assign c_data_o = data_fifo;

    always_ff @(posedge CLK) begin : MADDR_
        if(RST) begin
            m_waddr <= 0;
        end else if (cl_write) m_waddr <= {lru_tag, addr[7:5], 5'b11111};
        else if (cl_read) m_waddr <= {addr[31:5], 5'b11111};
        else if (m_o_valid) m_waddr <= {m_waddr[31:5], (count << 2)};
    end

    //Counter to verify all word have been read or written to memory
    always_ff @(posedge CLK) begin : COUNTER_
        if(RST) begin
            count <= 0;
        end else if (cl_read | cl_write) begin
            count <= 7;
        end
        else if (m_o_valid & count != 0) begin
            count <= count - 1;
        end
    end

    //CL Adapter State Machine
    enum {IDLE, READ, WRITE} ps, ns;

    always_ff @(posedge CLK) begin : STATE_
        if(RST) begin
            ps <= IDLE;
        end else begin
            ps <= ns;
        end
    end

    always_comb begin
        mem_we = 0;
        mem_re = 0;
        fifo_we = 0;
        fifo_re = 0;
        fifo_s = 0;
        cl_busy = 0;
        case (ps)
            IDLE: begin
                if (cl_read) ns = READ;
                else if (cl_write) begin
                    fifo_s = 1'b1;
                    ns = WRITE;
                end
                else ns = IDLE;
            end
            READ: begin
                cl_busy = 1'b1;
                mem_re = 1'b1;
                fifo_we = m_o_valid;
                if (count > 0) ns = READ;
                else ns = IDLE;
            end
            WRITE: begin
                cl_busy = 1'b1;
                mem_we = 1'b1;
                fifo_re = m_o_valid;
                if (count > 0) ns = WRITE;
                else ns = IDLE;
            end

        endcase
    end


    //FIFO for incoming/outgoing data
    always_ff @(posedge CLK) begin : data_fifo_
        if(RST) begin
            data_fifo <= 0;
        end else if (fifo_s) begin
            data_fifo <= c_data_i;
        end else if (fifo_we) begin
            data_fifo <= {data_fifo[223:0], m_data_o};
        end else if (fifo_re) begin
            data_fifo <= {data_fifo[223:0], 32'b0};
        end
    end
    
endmodule
