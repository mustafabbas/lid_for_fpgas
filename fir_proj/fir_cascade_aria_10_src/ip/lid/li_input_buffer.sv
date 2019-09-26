module li_input_buffer #(
	parameter WIDTH = 6,
	parameter ADDR = 2,
	parameter STOP_LATENCY = 0,
	parameter FIFO_TYPE = "fifo_almost_full_megafunction"
) (
	input clk,
	input reset,
	
	//input i_bypass,
	
	input [WIDTH-1:0] i_data,
	output [WIDTH-1:0] o_data,
	
	input i_enq,
	input i_deq,
	
	output o_full,
	output o_almost_full,
	output o_empty
);

	//wire [WIDTH-1:0] w_fifo_data_out;

	fifo #(
		.WIDTH(WIDTH),
		.ADDR(ADDR),
		.STOP_LATENCY(STOP_LATENCY),
		.TYPE(FIFO_TYPE)
	) input_fifo (
		.clk(clk),
		.reset(reset),
		.i_data(i_data),
		.o_data(o_data), // w_fifo_data_out for bypass
		
		.i_enq(i_enq),
		.i_deq(i_deq),
		
		.o_full(o_full),
		.o_almost_full(o_almost_full),
		.o_empty(o_empty)
	);

	//assign o_data = (i_bypass) ? i_data : w_fifo_data_out;
endmodule
