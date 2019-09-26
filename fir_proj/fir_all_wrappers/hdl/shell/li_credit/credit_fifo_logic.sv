module credit_fifo_logic #(
	parameter DATA_WIDTH = 16 // For input/output bits
)(
	input clock,
	input reset,

	// Interconnect Signals
	output o_increment_count,

	// FIFO contol signals
	input i_credit_ready,
	input i_empty,
	output o_read_request,

	// FIFO output valid
	output o_valid
);

	// Output is always valid so long as FIFO is not empty
	assign o_valid = !i_empty;

	// Read when module is enabled
	assign o_read_request = i_credit_ready;

	// Increment count when a valid read is processed
	assign o_increment_count = o_read_request && o_valid && !reset;

endmodule