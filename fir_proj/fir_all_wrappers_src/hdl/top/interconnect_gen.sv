module interconnect_gen  #(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 0,

	// Latency insenstive type ("non_li", "credit", "carloni" or "qsys")
	parameter INTERCONNECT_TYPE = "",

	// Number of pipline stages
	// whether it be LI Relay Stations or regular Registers.
	parameter N_STAGES = 0
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

	genvar i;
	generate

		// No registers just a passthrough
		if(N_STAGES == 0) begin: PASSTHROUGH
			assign o_data = i_data;
			assign o_valid = i_valid;
			assign o_li_feedback = i_li_feedback;
		end

		else begin

			// Generate the pipeline
			for(i=0; i < N_STAGES; i++) begin : PIPELINE_STAGEs

				// Interconnect wires
				reg r_valid;
				reg r_li_feedback;
				reg [DATA_WIDTH-1:0] r_data;
			
				if (i == 0) begin: ASSIGN_INPUTS
					if (INTERCONNECT_TYPE == "carloni") begin
						pipeline_stage #(
							.DATA_WIDTH(DATA_WIDTH),
							.INTERCONNECT_TYPE(INTERCONNECT_TYPE)
						) pipeline_stage_inst (
							.clock(clock),
							.reset(reset),
							.i_data(i_data),
							.i_valid(i_valid),
							.o_li_feedback(o_li_feedback),
							.o_data(r_data),
							.o_valid(r_valid),
							.i_li_feedback(r_li_feedback)
						);
					end else begin
						pipeline_stage #(
							.DATA_WIDTH(DATA_WIDTH),
							.INTERCONNECT_TYPE(INTERCONNECT_TYPE)
						) pipeline_stage_inst (
							.clock(clock),
							.reset(reset),
							.i_data(i_data),
							.i_valid(i_valid),
							.o_li_feedback(r_li_feedback),
							.o_data(r_data),
							.o_valid(r_valid),
							.i_li_feedback(i_li_feedback)
						);
					end

				end else begin: WIRE_PIPELINE_STAGES

					pipeline_stage #(
						.DATA_WIDTH(DATA_WIDTH),
						.INTERCONNECT_TYPE(INTERCONNECT_TYPE)
					) pipeline_stage_inst (
						.clock(clock),
						.reset(reset),
						.i_data(PIPELINE_STAGEs[i-1].r_data),
						.i_valid(PIPELINE_STAGEs[i-1].r_valid),
						.o_li_feedback(r_li_feedback),
						.o_data(r_data),
						.o_valid(r_valid),
						.i_li_feedback(PIPELINE_STAGEs[i-1].r_li_feedback)
					);

				end

			end

			if (INTERCONNECT_TYPE == "carloni") begin
				// Assign output
				assign o_data = PIPELINE_STAGEs[N_STAGES-1].r_data;
				assign o_valid = PIPELINE_STAGEs[N_STAGES-1].r_valid;
				assign PIPELINE_STAGEs[N_STAGES-1].r_li_feedback = i_li_feedback;
			end else begin
				// Assign output
				assign o_data = PIPELINE_STAGEs[N_STAGES-1].r_data;
				assign o_valid = PIPELINE_STAGEs[N_STAGES-1].r_valid;
				assign o_li_feedback = PIPELINE_STAGEs[N_STAGES-1].r_li_feedback;
			end

		end
	endgenerate

//	genvar i;
//	generate
//
//		// No registers just a passthrough
//		if(N_STAGES == 0) begin: PASSTHROUGH
//			assign o_data = i_data;
//			assign o_valid = i_valid;
//			assign o_li_feedback = i_li_feedback;
//		end
//
//		else begin
//
//			// Generate the pipeline
//			for(i=0; i < N_STAGES; i++) begin : PIPELINE_STAGEs
//
//				// Interconnect wires
//				reg r_valid;
//				reg r_li_feedback;
//				reg [DATA_WIDTH-1:0] r_data;
//			
//				if (i == 0) begin: ASSIGN_INPUTS
//
//					pipeline_stage #(
//						.DATA_WIDTH(DATA_WIDTH),
//						.INTERCONNECT_TYPE(INTERCONNECT_TYPE)
//					) pipeline_stage_inst (
//						.clock(clock),
//						.reset(reset),
//						.i_data(i_data),
//						.i_valid(i_valid),
//						.o_li_feedback(r_li_feedback),
//						.o_data(r_data),
//						.o_valid(r_valid),
//						.i_li_feedback(i_li_feedback)
//					);
//
//				end else begin: WIRE_PIPELINE_STAGES
//
//					pipeline_stage #(
//						.DATA_WIDTH(DATA_WIDTH),
//						.INTERCONNECT_TYPE(INTERCONNECT_TYPE)
//					) pipeline_stage_inst (
//						.clock(clock),
//						.reset(reset),
//						.i_data(PIPELINE_STAGEs[i-1].r_data),
//						.i_valid(PIPELINE_STAGEs[i-1].r_valid),
//						.o_li_feedback(r_li_feedback),
//						.o_data(r_data),
//						.o_valid(r_valid),
//						.i_li_feedback(PIPELINE_STAGEs[i-1].r_li_feedback)
//					);
//
//				end
//
//			end
//
//			// Assign output
//			assign o_data = PIPELINE_STAGEs[N_STAGES-1].r_data;
//			assign o_valid = PIPELINE_STAGEs[N_STAGES-1].r_valid;
//			assign o_li_feedback = PIPELINE_STAGEs[N_STAGES-1].r_li_feedback;
//
//		end
//	endgenerate

endmodule
