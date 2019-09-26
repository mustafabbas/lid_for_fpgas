module qsys_wrapper #(
	// For input/output bits
	parameter DATA_WIDTH	= 0,
	
	// For FIFO
	parameter	FIFO_ADDR	= 0,
	parameter	FIFO_TYPE	= "",
	parameter	READY_LATENCY = 0

)(
	input clock,
	input reset,

	// Upstream Signals
	input [DATA_WIDTH-1:0]	i_data,
	input i_valid,
	output o_ready,

	// Downstream Signals
	output [DATA_WIDTH-1:0]	o_data,
	output o_valid,
	input i_ready
);

	//Receiver side singals
	wire signed [DATA_WIDTH-1:0] w_FIFO_data;
	wire w_receiver_ready;
	wire w_FIFO_empty; 
	wire w_FIFO_valid;

	//Sender side signals
	wire w_pearl_enable;
	wire w_ready;

	/*
	 * FIFO + Control Logic
	 */
	fifo #(
		.DATA_WIDTH(DATA_WIDTH),
		.FIFO_ADDR(FIFO_ADDR),
		.FIFO_TYPE(FIFO_TYPE),
		.READY_LATENCY(READY_LATENCY)
	) fifo_inst (
		.clock(clock),
		.reset(reset),
		.i_data(i_data),
		.o_data(w_FIFO_data),
		.i_enq(i_valid),
		.i_deq(w_receiver_ready),
		.o_almost_full(w_ready),
		.o_empty(w_FIFO_empty)
	);

	fifo_logic #(
		.DATA_WIDTH(DATA_WIDTH)
	) fifo_logic_inst (
		.clock(clock),
		.reset(reset),
		.i_ready(i_ready),
		.i_empty(w_FIFO_empty),
		.o_read_request(w_receiver_ready),
		.o_valid(w_FIFO_valid)
	);

	/*
	 * The Pearl
	 */
	fir #(
		.dw(DATA_WIDTH-1)
	) fir_inst (
		.clk(clock),
		.reset(reset),
		.clk_ena(w_pearl_enable),
		.i_valid(w_FIFO_data[0]),
		.i_in(w_FIFO_data[DATA_WIDTH-1:1]),
		.o_valid(o_data[0]),
		.o_out(o_data[DATA_WIDTH-1:1])
	);

	/*
	 * Valid
	 */
	 valid_logic
	 valid_logic_inst (
			.clock(clock),
			.reset(reset),
			.i_ready(i_ready),
			.i_valid(w_FIFO_valid),
			.o_valid(o_valid)
	 );
	 
	 assign w_pearl_enable = o_valid;
	 assign o_ready = !w_ready;
	
endmodule