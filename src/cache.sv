module cache (
	input CLK,    // Clock
	input RST,
	input [31:0] addr,
	input [1:0] mem_size,
	input mem_sign,
	input mem_write,
	input mem_read,
	input [31:0] data_in,
	input [255:0] cacheline_in,
	input update_lru,
	input update_tag,
	input update_cacheline,
	input set_dirty,
    input clear_dirty,
    input set_valid,
    input clear_valid,
    input addr_valid,
	output hit,
	output lru_dirty,
	output lru_valid,
	output [23:0] lru_tag,
	output logic [31:0] data_out,
	output logic [255:0] cacheline_out
);

	/*------------------------------------------------------------------------------
	-- CACHE ARRAYS
	------------------------------------------------------------------------------*/

	logic c_valid [0:7][0:1];
	logic c_dirty [0:7][0:1];
	logic [23:0] c_tag [0:7][0:1];
	logic [255:0] c_data [0:7][0:1];

	logic [23:0] i_tag;
	logic [2:0] index;
	logic [4:0] offset;

	logic lru [0:7];

	logic w1_hit, w2_hit;

	logic w1_write;
	logic w2_write;
	assign w1_write = w1_hit & mem_write & addr_valid;
	assign w2_write = w2_hit & mem_write & addr_valid;

	/*------------------------------------------------------------------------------
	--  Cache Logic
	------------------------------------------------------------------------------*/

	assign i_tag = addr[31:8];
	assign index = addr[7:5];
	assign offset = addr[4:0];

	assign lru_dirty = c_dirty[index][lru[index]];
	assign lru_valid = c_valid[index][lru[index]];
	assign lru_tag = c_tag[index][lru[index]];

	assign w1_hit = ((c_tag[index][0] == i_tag) & c_valid[index][0]);
	assign w2_hit = ((c_tag[index][1] == i_tag) & c_valid[index][1]);
	assign hit = (w1_hit | w2_hit);



	//Psuedo LRU
	always_ff @(posedge CLK) begin
		if(RST) begin
			lru[0] <= 0;
			lru[1] <= 0;
			lru[2] <= 0;
			lru[3] <= 0;
			lru[4] <= 0;
			lru[5] <= 0;
			lru[6] <= 0;
			lru[7] <= 0;
		end else if (update_lru) begin
			lru[index] <= w1_hit;
		end
	end

	//Valid Bit Array
	always_ff @(posedge CLK) begin
		if(RST) begin
			c_valid[0][0] <= 0;
			c_valid[1][0] <= 0;
			c_valid[2][0] <= 0;
			c_valid[3][0] <= 0;
			c_valid[4][0] <= 0;
			c_valid[5][0] <= 0;
			c_valid[6][0] <= 0;
			c_valid[7][0] <= 0;
			c_valid[0][1] <= 0;
			c_valid[1][1] <= 0;
			c_valid[2][1] <= 0;
			c_valid[3][1] <= 0;
			c_valid[4][1] <= 0;
			c_valid[5][1] <= 0;
			c_valid[6][1] <= 0;
			c_valid[7][1] <= 0;
		end else if (set_valid) begin
			c_valid[index][lru[index]] <= 1'b1;
		end
		else if (clear_valid) begin
			c_valid[index][lru[index]] <= 1'b0;
		end
	end

	//Dirty Bit Array
	always_ff @(posedge CLK) begin
		if(RST) begin
			//c_dirty <= 0;
		end else if (set_dirty) begin
			c_dirty[index][lru[index]] <= 1'b1;
		end
		else if (clear_dirty) begin
			c_dirty[index][lru[index]] <= 1'b0;
		end
	end

	//Tag Array
	always_ff @(posedge CLK) begin
		if(RST) begin
			//c_tag <= 0;
		end else if (update_tag) begin
			c_tag[index][lru[index]] <= i_tag;
		end
	end

	//Async Reeeads
	always_comb begin
		cacheline_out = c_data[index][lru[index]];
		if (w1_hit) begin 
			case ({mem_size, mem_sign})
				3'b000: data_out = $signed(c_data[index][0][offset*8 +: 8]);
				3'b001: data_out = $unsigned(c_data[index][0][offset*8 +: 8]);
				3'b010: data_out = $signed(c_data[index][0][offset*8 +: 16]);
				3'b011: data_out = $unsigned(c_data[index][0][offset*8 +: 16]);
				3'b100: data_out = $signed(c_data[index][0][offset*8 +: 32]);
				3'b101: data_out = $unsigned(c_data[index][0][offset*8 +: 32]);

				default: data_out = 32'hdeadbeef;
			endcase
		end
		else if (w2_hit) begin
			case ({mem_size, mem_sign})
				3'b000: data_out = $signed(c_data[index][1][offset*8 +: 8]);
				3'b001: data_out = $unsigned(c_data[index][1][offset*8 +: 8]);
				3'b010: data_out = $signed(c_data[index][1][offset*8 +: 16]);
				3'b011: data_out = $unsigned(c_data[index][1][offset*8 +: 16]);
				3'b100: data_out = $signed(c_data[index][1][offset*8 +: 32]);
				3'b101: data_out = $unsigned(c_data[index][1][offset*8 +: 32]);

				default: data_out = 32'hdeadbeef;
			endcase
		end
		else begin 
			data_out = 32'hdeadbeef;
		end
	end


	//Write logic
	always_ff @(posedge CLK) begin : proc_
		if(RST) begin
			//c_data <= 0;
		end
		else if (update_cacheline) begin
			c_data[index][lru[index]] <= cacheline_in;
		end
		else if (w1_write) begin
			case (mem_size)

				2'b00: c_data[index][0][offset*8 +: 8] <= data_in[7:0]; //Byte
				2'b01: c_data[index][0][offset*8 +: 16] <= data_in[15:0]; //Half
				2'b10: c_data[index][0][offset*8 +: 32] <= data_in; //Word


				default: c_data[index][0] <= 256'hdeadbeef;
			endcase
		end
		else if (w2_write) begin
			case (mem_size)
				
				2'b00: c_data[index][1][offset*8 +: 8] <= data_in[7:0]; //Byte
				2'b01: c_data[index][1][offset*8 +: 16] <= data_in[15:0]; //Half
				2'b10: c_data[index][1][offset*8 +: 32] <= data_in; //Word

				/*

				//Word 0 in block
				7'b0000000: c_data[index][1][7:0] <= data_in[7:0];
				7'b0000001: c_data[index][1][15:8] <= data_in[7:0];
				7'b0000010: c_data[index][1][23:16] <= data_in[7:0];
				7'b0000011: c_data[index][1][31:24] <= data_in[7:0];
				7'b0000100: c_data[index][1][15:0] <= data_in[15:0];
				7'b0000101: c_data[index][1][23:8] = data_in[15:0];
				7'b0000110: c_data[index][1][31:16] <= data_in[15:0];
				7'b0001000: c_data[index][1][31:0] <= data_in;

				//Word 1 in block
				7'b0010000: c_data[index][1][39:32] <= data_in[7:0];
				7'b0010001: c_data[index][1][47:40] <= data_in[7:0];
				7'b0010010: c_data[index][1][55:48] <= data_in[7:0];
				7'b0010011: c_data[index][1][63:56] <= data_in[7:0];
				7'b0010100: c_data[index][1][47:32] <= data_in[15:0];
				7'b0010101: c_data[index][1][55:40] = data_in[15:0];
				7'b0010110: c_data[index][1][63:48] <= data_in[15:0];
				7'b0011000: c_data[index][1][63:32] <= data_in;

				//Word 2 in block
				7'b0100000: c_data[index][1][71:64] <= data_in[7:0];
				7'b0100001: c_data[index][1][79:72] <= data_in[7:0];
				7'b0100010: c_data[index][1][87:80] <= data_in[7:0];
				7'b0100011: c_data[index][1][95:88] <= data_in[7:0];
				7'b0100100: c_data[index][1][79:64] <= data_in[15:0];
				7'b0100101: c_data[index][1][87:72] = data_in[15:0];
				7'b0100110: c_data[index][1][95:80] <= data_in[15:0];
				7'b0101000: c_data[index][1][95:64] <= data_in;

				//Word 3 in block
				7'b0110000: c_data[index][1][103:96] <= data_in[7:0];
				7'b0110001: c_data[index][1][111:104] <= data_in[7:0];
				7'b0110010: c_data[index][1][119:112] <= data_in[7:0];
				7'b0110011: c_data[index][1][127:120] <= data_in[7:0];
				7'b0110100: c_data[index][1][111:96] <= data_in[15:0];
				7'b0110101: c_data[index][1][119:104] = data_in[15:0];
				7'b0110110: c_data[index][1][127:112] <= data_in[15:0];
				7'b0111000: c_data[index][1][127:96] <= data_in;

				//Word 4 in block
				7'b1000000: c_data[index][1][135:128] <= data_in[7:0];
				7'b1000001: c_data[index][1][143:136] <= data_in[7:0];
				7'b1000010: c_data[index][1][151:144] <= data_in[7:0];
				7'b1000011: c_data[index][1][159:152] <= data_in[7:0];
				7'b1000100: c_data[index][1][143:128] <= data_in[15:0];
				7'b1000101: c_data[index][1][151:136] = data_in[15:0];
				7'b1000110: c_data[index][1][159:144] <= data_in[15:0];
				7'b1001000: c_data[index][1][159:128] <= data_in;

				//Word 5 in block
				7'b1010000: c_data[index][1][167:160] <= data_in[7:0];
				7'b1010001: c_data[index][1][175:168] <= data_in[7:0];
				7'b1010010: c_data[index][1][183:176] <= data_in[7:0];
				7'b1010011: c_data[index][1][191:184] <= data_in[7:0];
				7'b1010100: c_data[index][1][175:160] <= data_in[15:0];
				7'b1010101: c_data[index][1][183:168] = data_in[15:0];
				7'b1010110: c_data[index][1][191:176] <= data_in[15:0];
				7'b1011000: c_data[index][1][191:160] <= data_in;

				//Word 5 in block
				7'b1100000: c_data[index][1][199:192] <= data_in[7:0];
				7'b1100001: c_data[index][1][207:200] <= data_in[7:0];
				7'b1100010: c_data[index][1][215:208] <= data_in[7:0];
				7'b1100011: c_data[index][1][223:216] <= data_in[7:0];
				7'b1100100: c_data[index][1][207:192] <= data_in[15:0];
				7'b1100101: c_data[index][1][215:200] = data_in[15:0];
				7'b1100110: c_data[index][1][223:208] <= data_in[15:0];
				7'b1101000: c_data[index][1][223:192] <= data_in;

				//Word 5 in block
				7'b1110000: c_data[index][1][231:224] <= data_in[7:0];
				7'b1110001: c_data[index][1][239:232] <= data_in[7:0];
				7'b1110010: c_data[index][1][247:240] <= data_in[7:0];
				7'b1110011: c_data[index][1][255:248] <= data_in[7:0];
				7'b1110100: c_data[index][1][239:224] <= data_in[15:0];
				7'b1110101: c_data[index][1][247:232] = data_in[15:0];
				7'b1110110: c_data[index][1][255:240] <= data_in[15:0];
				7'b1111000: c_data[index][1][255:224] <= data_in; */

				default: c_data[index][0] <= 256'hdeadbeef;
			endcase
		end
	end

endmodule : cache