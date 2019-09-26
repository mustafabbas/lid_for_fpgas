 (* multstyle = "dsp" *) module fir_cascade
#(
	/* Data Width:
	 * Data input/output bits */
	parameter dw = 16,

	// Number of FIR instances
	parameter N_FIRs = 2,

	// Use Latency insenstive Wrapper
	parameter LI=1,

	// Number of pipline stages
	// whether it be LI Relay Stations or NON-LI Regs.
	parameter N_STAGES = 0,

	// LI buffer address bits (depth = 2**FIFO_ADDR)
	parameter FIFO_ADDR=4,

	// Number of words in fifo after which wrapper sends a stop singal
	parameter FIFO_ALMOST_FULL = 4,
	parameter FIFO_TYPE = "fifo_almost_full_megafunction"
)(
	input clock,
	input reset,

	/* Sender Signals */
	input i_top_data_valid,
	input signed [dw-1:0] i_top_data_data,

	input i_top_valid,
	output o_top_stop,

	/* Receiver Signals */
	output o_top_data_valid,
	output signed [dw-1:0] o_top_data_data,

	output o_top_valid,
	input i_top_stop
);

localparam FIFO_NUM_WORDS	= 2**FIFO_ADDR;

// Debug begin
	initial begin
		if (FIFO_ALMOST_FULL > FIFO_NUM_WORDS) begin
			$display("FIFO_ALMOST_FULL = %d", FIFO_ALMOST_FULL);
			$display("FIFO_NUM_WORDS = %d", FIFO_NUM_WORDS);
			$error("FIFO_ALMOST_FULL value must be smaller than FIFO_NUM_WORDS");
		end
	end
// Debug end

	genvar i, j;
	generate
		for (i = 0; i < N_FIRs; i++) begin : FIRs
			if(LI) begin : LI_FIRs
				initial $display ("LI");
				li_link #(.WIDTH(dw+1)) fir_result_link();
				
				li_link #(.WIDTH(dw+1)) rs_result_link();
				
				if (i == 0) begin : FIRST_STAGE_VALID
					
					li_link #(.WIDTH(dw+1)) input_link();
					assign input_link.data[dw-1:0] = i_top_data_data;
					assign input_link.data[dw] = i_top_data_valid;
					assign input_link.valid = i_top_valid;
					assign o_top_stop = input_link.stop;
					
					li_fir_wrapper_pipelined_gen #(
						.dw(dw),
						.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
						.FIFO_ADDR(FIFO_ADDR),
						.FIFO_TYPE(FIFO_TYPE)
					) fir_inst (
						.clk(clock),
						.reset(reset),
						.i_li_link(input_link),
						.o_li_link(fir_result_link)
					);
					
					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_STAGES)
					) rs_result (
						.clk(clock),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
		
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					li_fir_wrapper_pipelined_gen #(
						.dw(dw),
						.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
						.FIFO_ADDR(FIFO_ADDR),
						.FIFO_TYPE(FIFO_TYPE)
					) fir_inst (
						.clk(clock),
						.reset(reset),
						.i_li_link(FIRs[i-1].LI_FIRs.rs_result_link),
						.o_li_link(fir_result_link)
					);

					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_STAGES)
					) rs_result (
						.clk(clock),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
					
				end
				
				if(i == N_FIRs - 1) begin
					assign o_top_data_data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw-1:0];
					assign o_top_data_valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw];
					assign FIRs[N_FIRs-1].LI_FIRs.rs_result_link.stop = i_top_stop;
					
					assign o_top_valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
				end
			end else begin : NON_LI
				initial $display ("NON-LI");
				wire w_fir_result_valid;
				wire [dw-1:0] w_fir_result;
				wire w_fir_result_valid_pipelined;
				wire [dw-1:0] w_fir_result_pipelined;				
				
				if (i == 0) begin : FIRST_STAGE_VALID
					initial $display("NON_LI FIR FIRST #%d", i);
					fir#(.dw(dw)) fir_inst (
						.clk(clock),
						.clk_ena(1'b1),
						.reset(reset),
						.i_valid(i_top_data_valid),
						.i_in(i_top_data_data),
						.o_valid(w_fir_result_valid),
						.o_out(w_fir_result)
					);
					
					pipeline_regs #(
						.WIDTH(dw),
						.N_STAGES(N_STAGES)
					) pipeline_regs_inst (
						.clk(clock),
						.reset(reset),
						.i_valid(w_fir_result_valid),
						.i_data(w_fir_result),
						.o_valid(w_fir_result_valid_pipelined),
						.o_data(w_fir_result_pipelined)
					);
					
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					initial $display("NON_LI FIR LATER #%d", i);
					fir#(.dw(dw)) fir_inst (
						.clk(clock),
						.clk_ena(1'b1),
						.reset(reset),
						.i_valid(FIRs[i-1].NON_LI.w_fir_result_valid_pipelined),
						.i_in(FIRs[i-1].NON_LI.w_fir_result_pipelined),
						.o_valid(w_fir_result_valid),
						.o_out(w_fir_result)
					);
					
					pipeline_regs #(
						.WIDTH(dw),
						.N_STAGES(N_STAGES)
					) pipeline_regs_inst (
						.clk(clock),
						.reset(reset),
						.i_valid(w_fir_result_valid),
						.i_data(w_fir_result),
						.o_valid(w_fir_result_valid_pipelined),
						.o_data(w_fir_result_pipelined)
						
					);
	
				end

				if(i == N_FIRs - 1) begin
					assign o_top_data_data = FIRs[N_FIRs-1].NON_LI.w_fir_result_pipelined;
					assign o_top_data_valid = FIRs[N_FIRs-1].NON_LI.w_fir_result_valid_pipelined;
					assign o_top_stop = 1'b0;
					assign o_top_valid = 1'b1;
				end
			end


		end
		
	endgenerate
	

endmodule 

	
