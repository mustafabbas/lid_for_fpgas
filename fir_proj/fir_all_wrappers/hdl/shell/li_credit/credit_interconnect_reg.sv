module credit_interconnect_reg #(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 0

)(
/* Note no reset due to S10 inaccessibility,
   must flush the pipline and initialize registers */
	input clock,

	// Pearl Signals
	input	reg [DATA_WIDTH-1:0] i_data,
	output reg [DATA_WIDTH-1:0] o_data,

	// Control Signals
	input	reg i_valid,
	input	reg i_increment_count,
	output reg o_valid,
	output reg o_increment_count
);

	initial begin
		o_data = {(DATA_WIDTH){1'b0}};
		o_valid = 0;
		o_increment_count = 0;
	end

	always@(posedge clock) begin
		o_data <= i_data;
		o_valid <= i_valid;
		o_increment_count <= i_increment_count;
	end

endmodule
