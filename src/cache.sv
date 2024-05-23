module cache (
	input CLK,    // Clock
	input RST,
	input addr,
	input [31:0] data_in,
	input [255:0] cacheline_in,
	input update_lru,
	input update_tag,
	input set_dirty,
    input clear_dirty,
    input set_valid,
    input clear_valid,
	output hit,
	output lru_dirty,
	output lru_valid,
	output logic [31:0] data_out,
	output logic [255:0] cacheline_out
);

	/*------------------------------------------------------------------------------
	-- CACHE ARRAYS
	------------------------------------------------------------------------------*/

	logic c_valid [0:7][0:1];
	logic c_dirty [0:7][0:1];
	logic [25:0] c_tag [0:7][0:1];
	logic [255:0] c_data [0:7][0:1];

	logic [25:0] i_tag;
	logic [2:0] index;
	logic [2:0] offset;

	logic lru [0:7];

	logic w1_hit, w2_hit;

	/*------------------------------------------------------------------------------
	--  Cache Logic
	------------------------------------------------------------------------------*/

	assign tag = addr[31:6];
	assign index = addr[5:3];
	assign offset = addr[2:0];

	assign lru_dirty = c_dirty[index][lru[index]];
	assign lru_valid = c_valid[index][lru[index]];

	assign hit = (w1_hit | w2_hit);

	//Hit logic
	always_ff @(posedge CLK) begin
		if(RST) begin
			w1_hit <= 0;
			w2_hit <= 0;
		end else begin
			w1_hit <= ((c_tag[index][0] == tag) & c_valid[index][0]);
			w2_hit <= ((c_tag[index][1] == tag) & c_valid[index][1]);
		end
	end

	//Psuedo LRU
	always_ff @(posedge CLK) begin
		if(RST) begin
			lru <= 0;
		end else if (update_lru) begin
			lru[index] <= w2_hit;
		end
	end

	//Valid Bit Array
	always_ff @(posedge CLK) begin
		if(RST) begin
			c_valid <= 0;
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
			c_dirty <= 0;
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
			c_tag <= 0;
		end else if (update_tag) begin
			c_tag[index][lru[index]] <= tag;
		end
	end

	//Async Reeeads
	always_comb begin
		if (w1_hit) begin 
			cacheline_out = c_data[index][0];
			case (offset)
				0: data = c_data[index][0][31:0];
				1: data = c_data[index][0][63:32];
				2: data = c_data[index][0][95:64];
				3: data = c_data[index][0][127:96];
				4: data = c_data[index][0][159:128];
				5: data = c_data[index][0][191:160];
				6: data = c_data[index][0][223:192];
				7: data = c_data[index][0][255:224];
				default: data = 32'hdeadbeef;
			endcase
		end
		else if (way2_hit) begin
			cacheline_out = c_data[index][1];
			case (offset)
				0: data = c_data[index][1][31:0];
				1: data = c_data[index][1][63:32];
				2: data = c_data[index][1][95:64];
				3: data = c_data[index][1][127:96];
				4: data = c_data[index][1][159:128];
				5: data = c_data[index][1][191:160];
				6: data = c_data[index][1][223:192];
				7: data = c_data[index][1][255:224];
				default: data = 32'hdeadbeef;
			endcase
		end
		else begin 
			cacheline_out = 256'hdeadbeef;
			data = 32'hdeadbeef;
		end
	end


	//Write logic
	always_ff @(posedge CLK) begin : proc_
		if(RST) begin
			way1 <= 0;
			way2 <= 0;
		end

		/*
		else if (way1_hit & write) begin
			w1_dirty[index] <= 1'b1;
			case (offset)
				0: w1_data[index][31:0] <= data_in;
				1: w1_data[index][63:32] <= data_in;
				2: w1_data[index][95:64] <= data_in;
				3: w1_data[index][127:96] <= data_in;
				4: w1_data[index][159:128] <= data_in;
				5: w1_data[index][191:160] <= data_in;
				6: w1_data[index][223:192] <= data_in;
				7: w1_data[index][255:224] <= data_in;
				default: data <= 32'hdeadbeef;
			endcase
		end
		else if (way2_hit & write) begin
			w2_dirty[index] <= 1'b1;
			case (offset)
				0: w2_data[index][31:0] <= data_in;
				1: w2_data[index][63:32] <= data_in;
				2: w2_data[index][95:64] <= data_in;
				3: w2_data[index][127:96] <= data_in;
				4: w2_data[index][159:128] <= data_in;
				5: w2_data[index][191:160] <= data_in;
				6: w2_data[index][223:192] <= data_in;
				7: w2_data[index][255:224] <= data_in;
				default: w2_data <= 256'hdeadbeef;
			endcase
		end*/
	end

endmodule : cache