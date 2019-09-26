module wrapper_gen  #(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 0,
	
	// Latency insenstive type ("non_li", "li_credit", "li_carloni" or "li_qsys")
	parameter WRAPPER_TYPE = "",

	// LI buffer address bits (depth = 2**FIFO_ADDR)
	parameter FIFO_ADDR = 0,

	// Number of words in fifo after which wrapper sends a stop singal
	parameter FIFO_ALMOST_FULL = 0, //Used for Carloni and  Qsys wrappers
	parameter FIFO_TYPE = "BRAM",

	// Number of pipline stages
	// Used to determine Qsys based system Ready Latency
	parameter N_STAGES = 5
)(
	input clock,
	input reset,

	/* Sender Signals */
	input signed 	[DATA_WIDTH-1:0]	i_data,
	input i_valid,
	output o_li_feedback,

	/* Receiver Signals */
	output signed 	[DATA_WIDTH-1:0]	o_data,
	output o_valid,
	input i_li_feedback
);

	if (WRAPPER_TYPE == "credit") begin 

		initial $display("Using Credit Wrapper");

		credit_wrapper #(
			.DATA_WIDTH(DATA_WIDTH),
			.FIFO_TYPE(FIFO_TYPE),
			.FIFO_ADDR(FIFO_ADDR)
		) credit_wrapper_inst (
			.clock(clock),
			.reset(reset),
			.i_data(i_data),
			.i_valid(i_valid),
			.o_increment_count(o_li_feedback),
			.o_data(o_data),
			.o_valid(o_valid),
			.i_increment_count(i_li_feedback)
		);

	end else if (WRAPPER_TYPE == "qsys") begin

		initial $display("Using Qsys Wrapper");

		localparam FIFO_NUM_WORDS = 2**FIFO_ADDR;
		localparam READY_LATENCY = FIFO_NUM_WORDS - (2 * N_STAGES);

		qsys_wrapper #(
			.DATA_WIDTH(DATA_WIDTH),
			.FIFO_TYPE(FIFO_TYPE),
			.FIFO_ADDR(FIFO_ADDR),
			.READY_LATENCY(READY_LATENCY)
		) qsys_wrapper_inst(
			.clock(clock),
			.reset(reset),
			.i_data(i_data),
			.i_valid(i_valid),
			.o_ready(o_li_feedback),
			.o_data(o_data),
			.o_valid(o_valid),
			.i_ready(i_li_feedback)
		);

	end else if (WRAPPER_TYPE == "carloni") begin

		initial $display("Using Carloni Wrapper");

		li_link #(.WIDTH(DATA_WIDTH)) input_link();
		assign input_link.data = i_data;
		assign input_link.valid = i_valid;
		assign o_li_feedback = input_link.stop;

		li_link #(.WIDTH(DATA_WIDTH)) output_link();
		assign o_data = output_link.data;
		assign o_valid = output_link.valid;
		assign output_link.stop = i_li_feedback;
		
		li_fir_wrapper_pipelined_gen #(
			.dw(DATA_WIDTH-1),
			.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
			.FIFO_ADDR(FIFO_ADDR),
			.FIFO_TYPE(FIFO_TYPE)
		) fir_inst (
			.clk(clock),
			.reset(reset),
			.i_li_link(input_link),
			.o_li_link(output_link)
		);

	end else if (WRAPPER_TYPE == "non-li") begin

		initial $display("Non-Li, no wrapper");

		fir#(
			.dw(DATA_WIDTH - 1)
		)fir_inst (
			.clk(clock),
			.clk_ena(1'b1),
			.reset(reset),
			.i_valid(i_data[0]),
			.i_in(i_data[DATA_WIDTH - 1:1]),
			.o_valid(o_data[0]),
			.o_out(o_data[DATA_WIDTH - 1:1])
		);

	end else begin
		//Shouldn't get here
		initial begin
			$error("Invalid FIFO type %s", WRAPPER_TYPE);
		end
	end

endmodule
