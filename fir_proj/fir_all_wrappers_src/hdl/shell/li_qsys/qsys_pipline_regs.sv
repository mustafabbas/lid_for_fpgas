module qsys_pipline_regs #(

	parameter DATA_WIDTH = 0,
	parameter N_STAGES = 0
	
)(

	/*Note no reset due to S10 inaccessibility, must flush the pipline and initialize registers*/

	input 									clock,
	
	//Pearl Signals
	input signed	[DATA_WIDTH-1:0]	i_data,
	output signed	[DATA_WIDTH-1:0]	o_data,
	
	//Control Signals
	input										i_valid,
	input										i_ready,
	output									o_valid,
	output									o_ready
);

//	initial begin
//		o_data = {(DATA_WIDTH){1'b0}};
//		o_valid = 0;
//		o_ready = 0;
//	end
	
	genvar i;
	generate
	
		//No registers just a passthrough
		if(N_STAGES == 0) begin: PASSTHROUGH
			assign o_data = i_data;
			assign o_valid = i_valid;
			assign o_ready = i_ready;
		end
		
		else begin
		
			//Generate the registers
			for(i=0; i < N_STAGES; i++) begin : PIPELINE_REGS
			
				//Interconnect Regs
				reg signed	[DATA_WIDTH-1:0]	r_data;
				reg									r_valid;
				reg									r_ready;
			
//				initial begin
//					r_data = {(DATA_WIDTH){1'b0}};
//					r_valid = 0;
//					r_ready = 0;
//				end

				if (i ==0) begin: ASSIGN_INPUTS
					always@(posedge clock) begin
						r_data <= i_data;
						r_valid <= i_valid;
						r_ready <= i_ready;
					end
				end else begin: WIRE_PIPELINE_REGS
					always@(posedge clock) begin
						r_data <= PIPELINE_REGS[i-1].r_data;
						r_valid <= PIPELINE_REGS[i-1].r_valid;
						r_ready <= PIPELINE_REGS[i-1].r_ready;
					end
				end

			end
			
			//Assign output
			assign o_data = PIPELINE_REGS[N_STAGES-1].r_data;
			assign o_valid = PIPELINE_REGS[N_STAGES-1].r_valid;
			assign o_ready = PIPELINE_REGS[N_STAGES-1].r_ready;
			
		end
	endgenerate

endmodule
