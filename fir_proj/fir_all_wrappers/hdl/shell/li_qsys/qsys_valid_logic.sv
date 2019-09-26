module valid_logic (

	input clock,
	input reset,

	// Backpressure ready signal comming from downstream
	input i_ready,

	// FIFO valid signal
	input		i_valid,

	// Wrapper output valid
	output	o_valid
);

	assign o_valid = i_ready && i_valid;

endmodule