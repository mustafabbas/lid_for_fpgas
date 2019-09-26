module pipeline_reg #(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 0

)(
	input clock,
	input reset,

	/* Sender Signals */
	input reg signed 	[DATA_WIDTH-1:0]	i_data,
	input reg i_valid,

	/* Receiver Signals */
	output reg signed 	[DATA_WIDTH-1:0]	o_data,
	output reg o_valid
);

	
	always@(posedge clock or posedge reset) begin
		if(reset) begin
			o_data <= {(DATA_WIDTH){1'b0}};
			o_valid <= 1'b0;
		end else begin
			o_data <= i_data;
			o_valid <= i_valid;
		end
	end

endmodule
