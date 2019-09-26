module fir_cascade #(
	// For input/output bits
	parameter DATA_WIDTH = 17,

	// Number of FIR instances
	parameter N_FIRs = 1,

	// For FIFO
	parameter FIFO_ADDR = 4,
	parameter FIFO_TYPE = "BRAM",

	// For counter
	parameter N_CREDITS = 2**FIFO_ADDR,	

	// Number of pipeline stages
	parameter N_STAGES = 0
)(
	input clock,
	input reset,

	/* Signals to sender */
	input i_top_data_valid,
	input signed [(DATA_WIDTH-1) -1:0] i_top_data_data,

	input i_valid,
	output o_increment_count,

	/* Signals from receiver */
	output o_top_data_valid,
	output signed [(DATA_WIDTH-1) -1:0] o_top_data_data,

	input i_increment_count,
	output o_valid
);

	genvar i;
	generate
		for (i = 0; i < N_FIRs; i++) begin : FIR

			// Pearl Signals
			wire signed [DATA_WIDTH-1:0] w_data;

			// Control Signals
			wire w_increment_count;
			wire w_valid;

			// Interconnect signals
			wire signed [DATA_WIDTH-1:0] w_pipelined_data;
			wire w_pipelined_valid;
			wire w_pipelined_increment_count;

			if(i == 0) begin: FIRST

				wire signed [DATA_WIDTH-1:0] i_top_data;
				assign i_top_data = {i_top_data_data, i_top_data_valid}; 

				credit_wrapper #(
					.DATA_WIDTH(DATA_WIDTH),
					.FIFO_TYPE(FIFO_TYPE),
					.FIFO_ADDR(FIFO_ADDR),
					.N_CREDITS(N_CREDITS)
				) credit_wrapper_inst(
					.clock(clock),
					.reset(reset),
					.i_valid(i_valid),
					.i_data(i_top_data),
					.o_increment_count(o_increment_count),
					.o_valid(w_valid),
					.o_data(w_data),
					.i_increment_count(w_increment_count)
				);

			end else begin: INTERMEDIATE_LAST

				credit_interconnect_regs #(
					.DATA_WIDTH(DATA_WIDTH),
					.N_STAGES(N_STAGES)
				) credit_interconnect_regs_inst(
					.clock(clock),
					.i_valid(FIR[i-1].w_valid),
					.i_data(FIR[i-1].w_data),
					.o_increment_count(FIR[i-1].w_increment_count),
					.o_valid(w_pipelined_valid),
					.o_data(w_pipelined_data),
					.i_increment_count(w_pipelined_increment_count)
				);

				credit_wrapper #(
					.DATA_WIDTH(DATA_WIDTH),
					.FIFO_TYPE(FIFO_TYPE),
					.FIFO_ADDR(FIFO_ADDR),
					.N_CREDITS(N_CREDITS)
				) credit_wrapper_inst(
					.clock(clock),
					.reset(reset),
					.i_valid(w_pipelined_valid),
					.i_data(w_pipelined_data),
					.o_increment_count(w_pipelined_increment_count),
					.o_valid(w_valid),
					.o_data(w_data),
					.i_increment_count(w_increment_count)
				);

			end

		end

		// Assign output
		assign o_top_data_data = FIR[N_FIRs-1].w_data[DATA_WIDTH-1:1];
		assign o_top_data_valid = FIR[N_FIRs-1].w_data[0];
		assign o_valid = FIR[N_FIRs-1].w_valid;
		assign FIR[N_FIRs-1].w_increment_count= i_increment_count;

	endgenerate

endmodule