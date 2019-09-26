 (* multstyle = "dsp" *) module fir_cascade
#(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 17,

	// Number of FIR instances
	parameter N_FIRs = 2,
	
	// Latency insenstive type ("non_li", "credit", "carloni" or "qsys")
	parameter WRAPPER_TYPE = "credit",

	// Number of pipline stages
	// whether it be LI Relay Stations or regular Registers.
	parameter N_STAGES = 60,

	// LI buffer address bits (depth = 2**FIFO_ADDR)
	parameter FIFO_ADDR = 7,

	// Number of words in fifo after which wrapper sends a stop singal
	parameter FIFO_ALMOST_FULL = 4, //Used for Carloni and  Qsys wrappers
	parameter FIFO_TYPE = "BRAM"

)(
	input clock,
	input reset,

	/* Sender Signals */
	input i_top_data_valid,
	input signed [(DATA_WIDTH - 1) - 1:0] i_top_data_data,

	input i_top_valid,
	output o_top_li_feedback,

	/* Receiver Signals */
	output o_top_data_valid,
	output signed [(DATA_WIDTH - 1) - 1:0] o_top_data_data,

	output o_top_valid,
	input i_top_li_feedback
);

	genvar i, j;
	generate
		for (i = 0; i < N_FIRs; i++) begin : FIRs
		
			// Pearl Signals
			wire signed [DATA_WIDTH-1:0] w_data;

			// Control Signals
			wire w_valid;
			wire w_li_feedback;

			// Interconnect signals
			wire signed [DATA_WIDTH-1:0] w_pipelined_data;
			wire w_pipelined_valid;
			wire w_pipelined_li_feedback;
		
			if(i == 0) begin: FIRST

				wire signed [DATA_WIDTH-1:0] i_top_data;
				
				if (WRAPPER_TYPE == "carloni") begin
					assign i_top_data = {i_top_data_valid, i_top_data_data}; 	
				end else begin
					assign i_top_data = {i_top_data_data, i_top_data_valid}; 
				end
				wrapper_gen  #(
					.DATA_WIDTH(DATA_WIDTH),
					.WRAPPER_TYPE(WRAPPER_TYPE),
					.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
					.FIFO_ADDR(FIFO_ADDR),
					.FIFO_TYPE(FIFO_TYPE),
					.N_STAGES(N_STAGES)
				) wrapper_inst (
					.clock(clock),
					.reset(reset),
					.i_data(i_top_data),
					.i_valid(i_top_valid),
					.o_li_feedback(o_top_li_feedback),
					.o_data(w_data),
					.o_valid(w_valid),
					.i_li_feedback(w_li_feedback)
				);

			end else begin: INTERMEDIATE_LAST

				interconnect_gen #(
					.INTERCONNECT_TYPE(WRAPPER_TYPE),
					.DATA_WIDTH(DATA_WIDTH),
					.N_STAGES(N_STAGES)
				) interconnect_gen_inst (
					.clock(clock),
					.reset(reset),
					.i_data(FIRs[i-1].w_data),
					.i_valid(FIRs[i-1].w_valid),
					.o_li_feedback(FIRs[i-1].w_li_feedback),
					.o_data(w_pipelined_data),
					.o_valid(w_pipelined_valid),
					.i_li_feedback(w_pipelined_li_feedback)
				);

				wrapper_gen  #(
					.DATA_WIDTH(DATA_WIDTH),
					.WRAPPER_TYPE(WRAPPER_TYPE),
					.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
					.FIFO_ADDR(FIFO_ADDR),
					.FIFO_TYPE(FIFO_TYPE),
					.N_STAGES(N_STAGES)
				) wrapper_inst (
					.clock(clock),
					.reset(reset),
					.i_data(w_pipelined_data),
					.i_valid(w_pipelined_valid),
					.o_li_feedback(w_pipelined_li_feedback),
					.o_data(w_data),
					.o_valid(w_valid),
					.i_li_feedback(w_li_feedback)
				);

			end

		end

		// Assign output
		if (WRAPPER_TYPE == "carloni") begin
			assign o_top_data_data = FIRs[N_FIRs-1].w_data[DATA_WIDTH-1:0];
			assign o_top_data_valid = FIRs[N_FIRs-1].w_data[DATA_WIDTH-1];	
		end else begin
			assign o_top_data_data = FIRs[N_FIRs-1].w_data[DATA_WIDTH-1:1];
			assign o_top_data_valid = FIRs[N_FIRs-1].w_data[0];
		end
		assign o_top_valid = FIRs[N_FIRs-1].w_valid;
		assign FIRs[N_FIRs-1].w_li_feedback = i_top_li_feedback;

	endgenerate

endmodule
