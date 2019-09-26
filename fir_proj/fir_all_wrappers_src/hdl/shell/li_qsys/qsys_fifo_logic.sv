module qsys_fifo_logic #(
	// For input/output bits
	parameter DATA_WIDTH = 0
)(
	input clock,
	input reset,

	// FIFO contol signals
	input i_ready,
	input i_empty,
	output o_read_request,

	// FIFO output valid
	output o_valid
);

	// Output is always valid so long as FIFO is not empty
	assign o_valid = !i_empty;

	// Read when module is enabled
	assign o_read_request = i_ready;

endmodule