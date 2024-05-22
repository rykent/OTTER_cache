module cache (
	input CLK,    // Clock
	input RST,
	input addr,
	input [31:0] data_in,
	output hit,
	output logic [31:0] data_out,
	output logic mem_valid
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

	assign tag = addr[31:6];
	assign index = addr[5:3];
	assign offset = addr[2:0];

	/*logic [26:0] tag_way1 [0:7];
	logic [26:0] tag_way2 [0:7];

	logic dirty_way1 [0:7];
	logic dirty_way2 [0:7];

	logic valid_way1 [0:7];
	logic valid_way2 [0:7];

	logic [255:0] cache_data_way1 [0:7];
	logic [255:0] cache_data_way2 [0:7];*/

	logic way1_hit, way2_hit;

	assign way1_hit = ((way1.tag == tag) & way1.valid[index]);
	assign way2_hit = ((way2.tag == tag) & way2.valid[index]);
	assign hit = (way1.hit | way2.hit);

	always_ff @(posedge CLK) begin : proc_
		if(RST) begin
			way1 <= 0;
			way2 <= 0;
			data <= 0;
		end
		else if (way1_hit & read) begin
			case (offset)
				0: data <= way1.data[31:0];
				1: data <= way1.data[63:32];
				2: data <= way1.data[95:64];
				3: data <= way1.data[127:96];
				4: data <= way1.data[159:128];
				5: data <= way1.data[191:160];
				6: data <= way1.data[223:192];
				7: data <= way1.data[255:224];
				default: data <= 32'hdeadbeef;
			endcase
		end
		else if (way2_hit & read) begin
			case (offset)
				0: data <= way2.data[31:0];
				1: data <= way2.data[63:32];
				2: data <= way2.data[95:64];
				3: data <= way2.data[127:96];
				4: data <= way2.data[159:128];
				5: data <= way2.data[191:160];
				6: data <= way2.data[223:192];
				7: data <= way2.data[255:224];
				default: data <= 32'hdeadbeef;
			endcase
		end
		else if (hit & write) begin
			
		end
	end

endmodule : cache