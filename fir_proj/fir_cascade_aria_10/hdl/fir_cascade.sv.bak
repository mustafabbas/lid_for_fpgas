 (* multstyle = "dsp" *) module fir_cascade
#(
	/* Data Width */
	parameter dw = 16, //Data input/output bits

	parameter N_FIRs = 1, 			//Number of FIR instances
	parameter N_OUTPUT_REG=0,		//Number of extra registers stages to insert between FIRs in the NON-LI version
	parameter LI=0,					//Use the LI FIRs
	parameter LI_OPT=0,				//Use the optimized FIR implementaiton, which merges existing data and valid signals
	parameter LI_PIPELINE_WRAPPER=0, //Use the pipelined version of the LI wrapper (should have higher Fmax)
	parameter N_RELAY_STATIONS=0,	//Number of relay stations to insert between FIRs in the LI version
	parameter FIFO_ADDR=2			//LI buffer address bits (depth = 2**FIFO_ADDR)
)(
	input clk,
	input reset,
	
	input i_valid_valid,
	input i_valid_data,
	output i_valid_stop,
	
	input signed [dw-1:0] i_data_data,
	input i_data_valid,
	output i_data_stop,
	
	output o_valid_valid,
	output o_valid_data,
	input o_valid_stop,
	
	output signed [dw-1:0] o_data_data,
	output o_data_valid,
	input o_data_stop
	
);

	li_link #(.WIDTH(1)) i_valid_link();
	assign i_valid_link.valid = i_valid_valid;
	assign i_valid_link.data = i_valid_data;
	assign i_valid_stop = i_valid_link.stop;
	
	li_link #(.WIDTH(dw)) i_data_link();
	assign i_data_link.valid = i_data_valid;
	assign i_data_link.data = i_data_data;
	assign i_data_stop = i_data_link.stop;
	
	li_link #(.WIDTH(dw)) o_data_link();
	assign o_data_valid = o_data_link.valid;
	assign o_data_data = o_data_link.data;
	assign o_data_link.stop = o_data_stop;
	
	li_link #(.WIDTH(1)) o_valid_link();
	assign o_valid_valid = o_valid_link.valid;
	assign o_valid_data = o_valid_link.data;
	assign o_valid_link.stop = o_valid_stop;	
	
	genvar i, j;
	generate
		for (i = 0; i < N_FIRs; i++) begin : FIRs
			if(LI && LI_OPT && LI_PIPELINE_WRAPPER) begin : LI_FIRs
				initial $display ("LI OPT + Pipelined");
				li_link #(.WIDTH(dw+1)) fir_result_link();
				
				li_link #(.WIDTH(dw+1)) rs_result_link();
				
				if (i == 0) begin : FIRST_STAGE_VALID
					
					li_link #(.WIDTH(dw+1)) input_link();
					assign input_link.data[dw-1:0] = i_data_link.data;
					assign input_link.data[dw] = i_valid_link.data;
					assign input_link.valid = i_data_link.valid;
					assign i_data_link.stop = input_link.stop;
					
					li_fir_wrapper_pipelined_gen #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_i_in_link(input_link),
						.o_out_o_valid_link(fir_result_link)
						
					);
					
					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
		
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					li_fir_wrapper_pipelined_gen #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_i_in_link(FIRs[i-1].LI_FIRs.rs_result_link),
						.o_out_o_valid_link(fir_result_link)
					);

					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
					
				end
				
				if(i == N_FIRs - 1) begin
					assign o_data_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw-1:0];
					assign o_data_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
					assign FIRs[N_FIRs-1].LI_FIRs.rs_result_link.stop = o_data_link.stop & o_valid_link.stop;
					
					assign o_valid_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw];
					assign o_valid_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
				end
			end else if(LI && LI_OPT) begin : LI_FIRs
				initial $display ("LI OPT");
				li_link #(.WIDTH(dw+1)) fir_result_link();
				
				li_link #(.WIDTH(dw+1)) rs_result_link();
				
				if (i == 0) begin : FIRST_STAGE_VALID
					
					li_link #(.WIDTH(dw+1)) input_link();
					assign input_link.data[dw-1:0] = i_data_link.data;
					assign input_link.data[dw] = i_valid_link.data;
					assign input_link.valid = i_data_link.valid;
					assign i_data_link.stop = input_link.stop;
					
					li_fir_wrapper_opt #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_i_in_link(input_link),
						.o_out_o_valid_link(fir_result_link)
						
					);
					
					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
		
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					li_fir_wrapper_opt #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_i_in_link(FIRs[i-1].LI_FIRs.rs_result_link),
						.o_out_o_valid_link(fir_result_link)
					);

					li_relay_stations #(
						.WIDTH(dw+1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
					
				end
				
				if(i == N_FIRs - 1) begin
					assign o_data_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw-1:0];
					assign o_data_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
					assign FIRs[N_FIRs-1].LI_FIRs.rs_result_link.stop = o_data_link.stop & o_valid_link.stop;
					
					assign o_valid_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data[dw];
					assign o_valid_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
				end
			end else if(LI) begin : LI_FIRs
				initial $dispaly ("LI NO-OPT");
				li_link #(.WIDTH(dw)) fir_result_link();
				li_link #(.WIDTH(1))fir_result_valid_link();
				
				li_link #(.WIDTH(dw)) rs_result_link();
				li_link #(.WIDTH(1))rs_valid_link();
				
				if (i == 0) begin : FIRST_STAGE_VALID
					
					li_fir_wrapper #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_link(i_valid_link),
						.i_in_link(i_data_link),
						
						.o_valid_link(fir_result_valid_link),
						.o_out_link(fir_result_link)
						
					);

					li_relay_stations #(
						.WIDTH(1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_valid (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_valid_link),
						.out_link(rs_valid_link)
					);
					
					li_relay_stations #(
						.WIDTH(dw), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
		
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					li_fir_wrapper #(.dw(dw), .FIFO_ADDR(FIFO_ADDR)) fir_inst (
						.clk(clk),
						.reset(reset),
						
						.i_valid_link(FIRs[i-1].LI_FIRs.rs_valid_link),
						.i_in_link(FIRs[i-1].LI_FIRs.rs_result_link),
						
						.o_valid_link(fir_result_valid_link),
						.o_out_link(fir_result_link)
					);
					
					li_relay_stations #(
						.WIDTH(1), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_valid (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_valid_link),
						.out_link(rs_valid_link)
					);
					
					li_relay_stations #(
						.WIDTH(dw), 
						.N_RELAY_STATIONS(N_RELAY_STATIONS)
					) rs_result (
						.clk(clk),
						.reset(reset),
						.in_link(fir_result_link),
						.out_link(rs_result_link)
					);
					
				end
				
				if(i == N_FIRs - 1) begin
					assign o_data_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.data;
					assign o_data_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_result_link.valid;
					assign FIRs[N_FIRs-1].LI_FIRs.rs_result_link.stop = o_data_link.stop;
					
					assign o_valid_link.data = FIRs[N_FIRs-1].LI_FIRs.rs_valid_link.data;
					assign o_valid_link.valid = FIRs[N_FIRs-1].LI_FIRs.rs_valid_link.valid;
					assign FIRs[N_FIRs-1].LI_FIRs.rs_valid_link.stop = o_valid_link.stop;
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
						.clk(clk),
						.clk_ena(1'b1),
						.reset(reset),
						.i_valid(i_valid_link.data),
						.i_in(i_data_link.data),
						.o_valid(w_fir_result_valid),
						.o_out(w_fir_result)
					);
					
					pipeline_regs #(
						.WIDTH(dw),
						.N_STAGES(N_OUTPUT_REG)
					) pipeline_regs_inst (
						.clk(clk),
						.reset(reset),
						.i_valid(w_fir_result_valid),
						.i_data(w_fir_result),
						.o_valid(w_fir_result_valid_pipelined),
						.o_data(w_fir_result_pipelined)
					);
					
				end else begin : LATER_STAGE_VALID //Later stages (i > 0)
					initial $display("NON_LI FIR LATER #%d", i);
					fir#(.dw(dw)) fir_inst (
						.clk(clk),
						.clk_ena(1'b1),
						.reset(reset),
						.i_valid(FIRs[i-1].NON_LI.w_fir_result_valid_pipelined),
						.i_in(FIRs[i-1].NON_LI.w_fir_result_pipelined),
						.o_valid(w_fir_result_valid),
						.o_out(w_fir_result)
					);
					
					pipeline_regs #(
						.WIDTH(dw),
						.N_STAGES(N_OUTPUT_REG)
					) pipeline_regs_inst (
						.clk(clk),
						.reset(reset),
						.i_valid(w_fir_result_valid),
						.i_data(w_fir_result),
						.o_valid(w_fir_result_valid_pipelined),
						.o_data(w_fir_result_pipelined)
						
					);
					
				end
				
				if(i == N_FIRs - 1) begin
					assign o_data_link.data = FIRs[N_FIRs-1].NON_LI.w_fir_result_pipelined;
					assign o_data_link.valid = 1'b1;
					
					assign o_valid_link.data = FIRs[N_FIRs-1].NON_LI.w_fir_result_valid_pipelined;
					assign o_valid_link.valid = 1'b1;
					
					assign i_valid_link.stop =1'b0;
					assign i_data_link.stop =1'b0;
				end
			end


		end
		
	endgenerate
	

endmodule 

	
