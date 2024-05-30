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

    //Task to test a store/load pair with random data and random addr
    task test_pair_rand(input [1:0] size, input sign, output success);
        logic [31:0] test_data_i;
        logic [31:0] test_data_o; 
        logic [31:0] test_addr;

        case (size) 
            0: begin // Byte Test
                if (sign) test_data_i = $urandom_range(32'h0, 32'hFF);
                else test_data_i = $signed($urandom_range(-128, 127));
                test_addr = $urandom_range(32'h0, 32'hFFFF); // Get random address
            end
            1: begin // Half Test
                if (sign) test_data_i = $urandom_range(32'h0, 32'hFFFF);
                else test_data_i = $signed($urandom_range(-32768, 32767));
                test_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h1; // Get random Half aligned address
            end
            2: begin // Word Test
                test_data_i = $urandom();
                test_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h3; // Get random Word aligned address
            end
            default: begin
                test_data_i = 32'hdeadbeef;
                test_addr = 32'hdeadbeef;
            end
        endcase

        //$display(test_data_i);

        store(test_addr, test_data_i, size);
        @(posedge MEM_CLK);
        load(test_addr, sign, size, test_data_o);

        if (sign) success = (test_data_o == test_data_i) ? 1 : 0;
        else success = (test_data_o == $signed(test_data_i)) ? 1 : 0;
        @(posedge MEM_CLK);
    endtask : test_pair_rand

    // Task to test MEM Read misses
    task test_read_miss();
        logic [31:0] test_data_orig;
        logic [31:0] orig_addr;
        logic [31:0] test_data_out;

        test_data_orig = $urandom();
        orig_addr = $urandom_range(32'h0, 32'hFFFF) & ~32'h3;

        store()

    endtask : test_read_miss

    logic suc;

    initial begin
    	MEM_RST = 1;
    	#600
    	MEM_RST = 0;

        @(posedge MEM_CLK);

        //Test random Numbers Store/Load Pairs

        $display("TESTING WORDS");
        for (int i = 0; i < 100; i++) begin
            test_pair_rand(2, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING WORDS");
                $finish;
            end
        end

        $display("TESTING UNSIGNED HALFS");
        for (int i = 0; i < 100; i++) begin
            test_pair_rand(1, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING UNSIGNED HALFS");
                $finish;
            end
        end

        $display("TESTING SIGNED HALFS");
        for (int i = 0; i < 100; i++) begin
            test_pair_rand(1, 0, suc);
            if (~suc) begin
                $display("ERROR TESTING SIGNED HALFS");
                $finish;
            end
        end

        $display("TESTING UNSIGNED BYTES");
        for (int i = 0; i < 100; i++) begin
            test_pair_rand(0, 1, suc);
            if (~suc) begin
                $display("ERROR TESTING UNSIGNED BYTES");
                $finish;
            end
        end

        $display("TESTING SIGNED BYTES");
        for (int i = 0; i < 100; i++) begin
            test_pair_rand(0, 0, suc);
            if (~suc) begin
                $display("ERROR TESTING SIGNED BYTES");
                $finish;
            end
        end


        $display("ALL TESTS PASSED, WOOOOOOO!!!!");
            
    end

	OtterMemory DUT (.*);


endmodule : cache_tb