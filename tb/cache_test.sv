`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cow Poly
// Engineer: Ryken Thompson
// 
// Create Date: 05/28/2024 09:24:42 AM
// Design Name: 
// Module Name: cache_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module cache_tb ();

	logic MEM_CLK = 0; 
    logic MEM_RST;
    logic MEM_RDEN1;                // read enable Instruction
    logic MEM_RDEN2;                // read enable data
    logic MEM_WE2;                  // write enable.
    logic [13:0] MEM_ADDR1;         // Instruction Memory word Addr (Connect to PC[15:2])
    logic [31:0] MEM_ADDR2;         // Data Memory Addr
    logic [31:0] MEM_DIN2;          // Data to save
    logic [1:0] MEM_SIZE;           // 0-Byte, 1-Half, 2-Word
    logic MEM_SIGN;                 // 1-unsigned 0-signed
    logic [31:0] IO_IN;             // Data from IO     
    logic IO_WR;             // IO 1-write 0-read
    logic [31:0] MEM_DOUT1;  // Instruction
    logic [31:0] MEM_DOUT2;  // Data
    logic MEM_VALID1;
    logic MEM_VALID2;
    logic ERR;

    initial forever  #5  MEM_CLK =  !MEM_CLK; 

    //Task to emulate store instructions
    task store(input logic [31:0] addr, input logic [31:0] data, input logic [1:0] size);
    	MEM_ADDR2 = addr;
        MEM_WE2 = 1;
        MEM_DIN2 = data;
        MEM_SIZE = size;
        //Stall while waiting for cache
        while (~MEM_VALID2 & ~ERR) begin
            @(posedge MEM_CLK);
        end
        MEM_WE2 = 0;
    endtask : store


    //Task to emulate load instructions
    task load(input logic [31:0] addr, input logic sign, input logic [1:0] size, output logic [31:0] data);
        MEM_ADDR2 = addr;
        MEM_RDEN2 = 1;
        MEM_SIZE = size;
        MEM_SIGN = sign;
        //Stall while waiting for cache
        while (~MEM_VALID2 & ~ERR) begin
            @(posedge MEM_CLK);
        end
        MEM_RDEN2 = 0;
        data = MEM_DOUT2;
    endtask : load


    task test_pair_rand(input [1:0] size, input sign, output success);
        logic [31:0] test_data_i;
        logic [31:0] test_data_o; 
        logic [31:0] test_addr;

        case (size) 
            0: begin // Byte Test
                test_data_i = $urandom_range(32'h0, 32'hFF);
                test_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h3; // Get random address
            end
            1: begin // Half Test
                test_data_i = $urandom_range(32'h0, 32'hFFFF);
                test_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h1; // Get random Half aligned address
            end
            2: begin // Word Test
                test_data_i = $urandom_range(32'h0, 32'hFFFFFFFF);
                test_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h3; // Get random Word aligned address
            end
            default: begin
                test_data_i = 32'hdeadbeef;
                test_addr = 32'hdeadbeef;
            end
        endcase

        $display(test_data_i);

        store(test_addr, test_data_i, size);
        @(posedge MEM_CLK);
        load(test_addr, sign, size, test_data_o);

        if (sign) success = (test_data_o == test_data_i) ? 1 : 0;
        else success = (test_data_o == $signed(test_data_i)) ? 1 : 0;
    endtask : test_pair_rand

    logic suc;

    initial begin
    	MEM_RST = 1;
    	#600
    	MEM_RST = 0;

        @(posedge MEM_CLK);


        for (int i = 0; i < 10; i++) begin
            test_pair_rand(2, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING WORDS");
                $finish;
            end
        end

        for (int i = 0; i < 10; i++) begin
            test_pair_rand(1, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING UNSIGNED HALFS");
                $finish;
            end
        end

        for (int i = 0; i < 10; i++) begin
            test_pair_rand(0, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING UNSIGNED BYTES");
                $finish;
            end
        end

        $display("ALL TESTS PASSED, WOOOOOOO!!!!");
         
    end

	OtterMemory DUT (.*);


endmodule : cache_tb