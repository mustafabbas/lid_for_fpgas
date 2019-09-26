module li_input_buffer #(
	parameter WIDTH = 6,
	parameter ADDR = 2
) (
	input clk,
	input reset,
	
	input i_bypass,
	
	input [WIDTH-1:0] i_data,
	output [WIDTH-1:0] o_data,
	
	input i_enq,
	input i_deq,
	
	output o_full,
	output o_almost_full,
	output o_empty
);

	wire [WIDTH-1:0] w_fifo_data_out;

	fifo #(.WIDTH(WIDTH), .ADDR(ADDR), .TYPE("fifo_almost_full_dpram_wrapper")) input_fifo (
		.clk(clk),
		.reset(reset),
		.i_data(i_data),
		.o_data(w_fifo_data_out),
		
		.i_enq(i_enq),
		.i_deq(i_deq),
		
		.o_full(o_full),
		.o_almost_full(o_almost_full),
		.o_empty(o_empty)
	);

	assign o_data = (i_bypass) ? i_data : w_fifo_data_out;
endmodule
