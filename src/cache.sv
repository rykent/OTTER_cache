module cache (
	input CLK,    // Clock
	input RST,
	input addr,
	input [31:0] data_in,
	input [255:0] cacheline_in,
	output hit,
	output logic [31:0] data_out,
	output logic [255:0] cacheline_out
);

	typedef struct packed {
		logic valid [0:7];
		logic dirty [0:7];
		logic [25:0] tag [0:7];
		logic [255:0] data [0:7];
	} way_t;

	way_t way1;
	way_t way2;

	logic [25:0] tag;
	logic [2:0] index;
	logic [2:0] offset;

	logic lru;
	logic lru_dirty;
	logic lru_valid;

	assign tag = addr[31:6];
	assign index = addr[5:3];
	assign offset = addr[2:0];

	logic way1_hit, way2_hit;

	assign hit = (way1.hit | way2.hit);

	//Hit logic
	always_ff @(posedge CLK) begin
		if(RST) begin
			way1_hit <= 0;
			way2_hit <= 0;
		end else begin
			way1_hit <= ((way1.tag[index] == tag) & way1.valid[index]);
			way2_hit <= ((way2.tag[index] == tag) & way2.valid[index]);
		end
	end

	//Psuedo LRU
	always_ff @(posedge CLK) begin
		if(RST) begin
			lru <= 1'b0;

		end
		else if (read | write) begin
			if (way1_hit) begin
				lru <= 1'b0;
				lru_valid <= way1.valid[index];
				lru_dirty <= way1.dirty[index];
			end
			else if (way2_hit) begin
				lru <= 1'b1;
				lru_valid <= way2.valid[index];
				lru_dirty <= way2.dirty[index];
			end
		end
	end


	//Async Reeeads
	always_comb begin
		if (way1_hit) begin 
			cacheline_out = way1.data[index];
			case (offset)
				0: data = way1.data[index][31:0];
				1: data = way1.data[index][63:32];
				2: data = way1.data[index][95:64];
				3: data = way1.data[index][127:96];
				4: data = way1.data[index][159:128];
				5: data = way1.data[index][191:160];
				6: data = way1.data[index][223:192];
				7: data = way1.data[index][255:224];
				default: data = 32'hdeadbeef;
			endcase
		end
		else if (way2_hit) begin
			cacheline_out = way2.data[index];
			case (offset)
				0: data = way2.data[index][31:0];
				1: data = way2.data[index][63:32];
				2: data = way2.data[index][95:64];
				3: data = way2.data[index][127:96];
				4: data = way2.data[index][159:128];
				5: data = way2.data[index][191:160];
				6: data = way2.data[index][223:192];
				7: data = way2.data[index][255:224];
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
		else if (cacheline_write) begin
			
		end
		else if (way1_hit & write) begin
			way1.dirty[index] <= 1'b1;
			case (offset)
				0: way1.data[index][31:0] <= data_in;
				1: way1.data[index][63:32] <= data_in;
				2: way1.data[index][95:64] <= data_in;
				3: way1.data[index][127:96] <= data_in;
				4: way1.data[index][159:128] <= data_in;
				5: way1.data[index][191:160] <= data_in;
				6: way1.data[index][223:192] <= data_in;
				7: way1.data[index][255:224] <= data_in;
				default: data <= 32'hdeadbeef;
			endcase
		end
		else if (way2_hit & write) begin
			way2.dirty[index] <= 1'b1;
			case (offset)
				0: way2.data[index][31:0] <= data_in;
				1: way2.data[index][63:32] <= data_in;
				2: way2.data[index][95:64] <= data_in;
				3: way2.data[index][127:96] <= data_in;
				4: way2.data[index][159:128] <= data_in;
				5: way2.data[index][191:160] <= data_in;
				6: way2.data[index][223:192] <= data_in;
				7: way2.data[index][255:224] <= data_in;
				default: way2.data <= 256'hdeadbeef;
			endcase
		end
	end

endmodule : cache