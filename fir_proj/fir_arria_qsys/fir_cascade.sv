module fir_cascade #(
	// For input/output bits
	parameter DATA_WIDTH = 17,

	// Number of FIR instances
	parameter N_FIRs = 1,

	// Number of pipeline stages
	parameter N_STAGES = 0,
	
	// For FIFO
	parameter FIFO_ADDR = 4,
	parameter FIFO_TYPE = "BRAM",
	parameter FIFO_NUM_WORDS = 2**FIFO_ADDR,
	parameter READY_LATENCY = FIFO_NUM_WORDS - (2 * N_STAGES),

	// For counter
	parameter N_CREDITS = 2**FIFO_ADDR
)(
	input clock,
	input reset,

	/* Signals to sender */
	input i_top_data_valid,
	input signed [(DATA_WIDTH-1) -1:0] i_top_data_data,

	input i_valid,
	output o_ready,

	/* Signals from receiver */
	output o_top_data_valid,
	output signed [(DATA_WIDTH-1) -1:0] o_top_data_data,

	output o_valid,
	input i_ready
);

// Debug begin
	initial begin
		$display("Ready latency = %d", READY_LATENCY);
		// Make sure system does not go into deadlock
		if (READY_LATENCY <= 0) begin
			$error("Ready latency = %d which is less than or equal to zero.", READY_LATENCY,
					"Number of Pipeline Stages cannot be greater than the Number of words the FIFO memory buffer.\n",
					"Check parameters N_Stages and FIFO_ADDR to resolve this issue.");
		end
	end
// Debug end

	genvar i;
	generate
		for (i = 0; i < N_FIRs; i++) begin : FIR

			// Pearl Signals
			wire signed [DATA_WIDTH-1:0] w_data;

			// Control Signals
			wire w_ready;
			wire w_valid;

			// Interconnect signals
			wire signed [DATA_WIDTH-1:0] w_pipelined_data;
			wire w_pipelined_valid;
			wire w_pipelined_ready;

			if(i == 0) begin: FIRST

				wire signed [DATA_WIDTH-1:0] i_top_data;
				assign i_top_data = {i_top_data_data, i_top_data_valid}; 

				qsys_wrapper #(
					.DATA_WIDTH(DATA_WIDTH),
					.FIFO_TYPE(FIFO_TYPE),
					.FIFO_ADDR(FIFO_ADDR),
					.READY_LATENCY(READY_LATENCY)
				) qsys_wrapper_inst(
					.clock(clock),
					.reset(reset),
					.i_valid(i_valid),
					.i_data(i_top_data),
					.o_ready(o_ready),
					.o_valid(w_valid),
					.o_data(w_data),
					.i_ready(w_ready)
				);

			end else begin: INTERMEDIATE_LAST

				qsys_pipline_regs #(
					.DATA_WIDTH(DATA_WIDTH),
					.N_STAGES(N_STAGES)
				) qsys_pipline_regs_inst(
					.clock(clock),
					.i_valid(FIR[i-1].w_valid),
					.i_data(FIR[i-1].w_data),
					.o_ready(FIR[i-1].w_ready),
					.o_valid(w_pipelined_valid),
					.o_data(w_pipelined_data),
					.i_ready(w_pipelined_ready)
				);

				qsys_wrapper #(
					.DATA_WIDTH(DATA_WIDTH),
					.FIFO_TYPE(FIFO_TYPE),
					.FIFO_ADDR(FIFO_ADDR),
					.READY_LATENCY(READY_LATENCY)
				) qsys_wrapper_inst(
					.clock(clock),
					.reset(reset),
					.i_valid(w_pipelined_valid),
					.i_data(w_pipelined_data),
					.o_ready(w_pipelined_ready),
					.o_valid(w_valid),
					.o_data(w_data),
					.i_ready(w_ready)
				);

			end

		end

		// Assign output
		assign o_top_data_data = FIR[N_FIRs-1].w_data[DATA_WIDTH-1:1];
		assign o_top_data_valid = FIR[N_FIRs-1].w_data[0];
		assign o_valid = FIR[N_FIRs-1].w_valid;
		assign FIR[N_FIRs-1].w_ready = i_ready;

	endgenerate

endmodule