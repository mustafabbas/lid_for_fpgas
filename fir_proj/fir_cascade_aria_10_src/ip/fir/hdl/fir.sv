(* multstyle = "dsp" *) module fir
#(
	/* Data Width */
	parameter dw = 16, //Data input/output bits

	/* Number of filter coefficients */
	parameter N = 51,
	parameter N_UNIQ = 26, // ciel(N/2) assuming symmetric filter coefficients
	
	/* DSP Info */
	parameter N_DSP2_INST = 13,	//Total number of dsp_2mac  ciel(N_UNIQ/2)
	
	/*Number of extra valid cycles needed to align output (i.e. computation pipeline depth + input/output registers)*/
	parameter N_EXTRA_VALID = 16
)(
	input clk,
	input reset,
	input clk_ena,
	input i_valid,
	input signed [dw-1:0] i_in,
	output o_valid,
	output signed [dw-1:0] o_out
);

//// Simple Module for testing
//	reg signed [dw-1:0] r_in;
//	reg r_valid;
//	
//	always @ (posedge clk) begin
//		if(reset) begin
//			r_in <= 0;
//			r_valid <= 0;
// 		end else if (clk_ena) begin
//			r_in <= i_in;
//			r_valid <= i_valid;
//		end else begin
//			r_in <= r_in;
//			r_valid <= r_valid;
//		end
//	end
//	
//	assign o_valid = r_valid;
//	assign o_out = r_in;

	/* Data Width dervied parameters */
	localparam dw_add_int = dw; //Internal adder precision bits
	localparam dw_mult_int = 2*dw; //Internal multiplier precision bits
	localparam scale_factor = dw_mult_int - dw - 1; //Multiplier normalization shift amount
	
	/* DSP output width */
	localparam DSP_RESULT_WIDTH = 44;
	localparam DSP_CHAIN_WIDTH = 64;
	
	/* Number of extra registers in INPUT_PIPELINE_REG to prevent contention for CHAIN_END's
	chain adders */
	localparam N_EXTRA_INPUT_REG = 0; 
	localparam N_INPUT_ADD_CYCLES = 1; //Number of cycles for input adders
	
	/* Max number of multipliers in one DSP unit*/
	localparam N_MULTIPLIERS_IN_DSP = 2;
	
	/* Debug */
	initial begin
		$display ("Data Width: %d", dw);
		$display ("Data Width Add Internal: %d", dw_add_int);
		$display ("Data Width Mult Internal: %d", dw_mult_int);
		$display ("Scale Factor: %d", scale_factor);
	end

	
	const shortint h [N_UNIQ] = '{
		16'd111,
		16'd0,
		-16'd122,
		-16'd247,
		-16'd368,
		-16'd475,
		-16'd559,
		-16'd613,
		-16'd630,
		-16'd602,
		-16'd526,
		-16'd399,
		-16'd223,
		16'd0,
		16'd265,
		16'd564,
		16'd888,
		16'd1226,
		16'd1565,
		16'd1893,
		16'd2196,
		16'd2464,
		16'd2684,
		16'd2848,
		16'd2950,
		16'd2984
	};


/*
	reg signed [15:0] h [N_UNIQ+1];
	initial begin
		h[0] = 16'd111;
		h[1] = 16'd0;
		h[2] = -16'd122;
		h[3] = -16'd247;
		h[4] = -16'd368;
		h[5] = -16'd475;
		h[6] = 16'd559;
		h[7] = -16'd613;
		h[8] = -16'd630;
		h[9] = -16'd602;
		h[10] = -16'd526;
		h[11] = -16'd399;
		h[12] = -16'd223;
		h[13] = 16'd0;
		h[14] = 16'd265;
		h[15] = 16'd564;
		h[16] = 16'd888;
		h[17] = 16'd1226;
		h[18] = 16'd1565;
		h[19] = 16'd1893;
		h[20] = 16'd2196;
		h[21] = 16'd2464;
		h[22] = 16'd2684;
		h[23] = 16'd2848;
		h[24] = 16'd2950;
		h[25] = 16'd2984;
		h[26] = 16'd2950;
	end
*/
	/* Debug */
	initial begin
		for (int i = 0; i < (N/2 + 1); i++) begin
			$display("h[%d]: %d", i, h[i]);
		end
	end
	
	/*******************************************************
	 * 
	 * Valid Delay Pipeline
	 *
	 *******************************************************/
	//Input valid signal is pipelined to become output valid signal
	genvar i;
	generate for (i = 0; i < N + N_EXTRA_VALID; i++) begin : VALID_PIPELINE_REG
		//Valid registers
		reg r_valid;
		
		if (i == 0) begin : FIRST_STAGE_VALID
			always@(posedge clk or posedge reset) begin
				if(reset)
					r_valid <= 0;
				else
					if(clk_ena)
						r_valid <= i_valid;
					else
						r_valid <= r_valid;
			end
		end
		else begin : LATER_STAGE_VALID //Later stages (i > 0)
			always@(posedge clk or posedge reset) begin
				if(reset)
					r_valid <= 0;
				else
					if(clk_ena)
						r_valid <= VALID_PIPELINE_REG[i-1].r_valid;
					else
						r_valid <= r_valid;
			end
		end
	end
	endgenerate
	
	
	/*******************************************************
	 * 
	 * Input Register Pipeline
	 *
	 *******************************************************/
	//Pipelined input values
	genvar k;
	generate for(k = 0; k < N + N_EXTRA_INPUT_REG; k++) begin : INPUT_PIPELINE_REG
	
		//Input value registers
		reg signed [dw-1:0] r_input;
		
		if (k == 0) begin : FIRST_STAGE_INPUT //First stage
			always@(posedge clk or posedge reset) begin
				if(reset)
					r_input <= 0;
				else
					if(clk_ena)
						r_input <= i_in;
					else
						r_input <= r_input;
			end
		end
		else begin : LATER_STAGE_INPUT // Later stages (i > 0)
			always@(posedge clk or posedge reset) begin
				if(reset)
					r_input <= 0;
				else begin
					if(clk_ena)
						r_input <= INPUT_PIPELINE_REG[k-1].r_input;
					else
						r_input <= r_input;
				end
			end
		end
	end
	endgenerate

	/*******************************************************
	 * 
	 * Computation Pipeline
	 *
	 *******************************************************/
	 
	//Pre-add inputs due to symmetric filter coefficients
	genvar j;
	generate
		for (j = 0; j < N_UNIQ; j++) begin : PRE_ADD_INST
		
			//Additional offset for last reg
			localparam last_offset = 1;
			
			//Pre-adder output wire
			wire signed [dw_add_int-1:0] w_sum;
			
			parameter n_additional_regs = j/2;
		
			if(j != N_UNIQ-1) begin
				input_adder	input_adder_inst(
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j+n_additional_regs].r_input),
					.datab 	(INPUT_PIPELINE_REG [(N-1) - j+n_additional_regs].r_input),
					.result 	(w_sum)
				);
			end
			
			else begin: LAST // last coefficent is not repeated so no adder
				assign w_sum = INPUT_PIPELINE_REG [j+n_additional_regs +last_offset].r_input;
			end
		end
	endgenerate
	
	// Generate N_DSP2_INST DSPs (2 multiply/acculmulate + chain in)
	genvar m;
	generate 
		for (m = 0; m < N_DSP2_INST; m++) begin : DSP_INST
			
			//Intermediate DSP chain-in/chain-out wire
			wire signed [DSP_CHAIN_WIDTH-1:0] w_out;
			
			if(m == 0) begin: FIRST_STAGE
				dsp_2mac_no_chainin dsp_2mac_inst(
					.clk        (clk),
					.ena        (clk_ena),
					.aclr       (reset),
//					.chainin    (),	// Un-connected
					.ax         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP		].w_sum),
					.ay         (h[m*N_MULTIPLIERS_IN_DSP		]),
					.bx         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP + 1	].w_sum),
					.by         (h[(m*N_MULTIPLIERS_IN_DSP )+ 1	]),
					.resulta    (),
					.chainout (w_out)
				);
			end
			else if (m != N_DSP2_INST-1) begin: CHAIN_START
				dsp_2mac dsp_2mac_inst(
					.clk        (clk),
					.ena        (clk_ena),
					.aclr       (reset),
					.chainin    (DSP_INST[m-1].w_out),	// Result from previous DSP
					.ax         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP		].w_sum),
					.ay         (h[m*N_MULTIPLIERS_IN_DSP		]),
					.bx         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP + 1	].w_sum),
					.by         (h[(m*N_MULTIPLIERS_IN_DSP )+ 1	]),
					.resulta    (),
					.chainout (w_out)
				);
			end
			else begin: LAST
				dsp_2mac_no_chainout dsp_2mac_no_chainout_inst(
					.clk        (clk),
					.ena        (clk_ena),
					.aclr       (reset),
					.chainin    (DSP_INST[m-1].w_out),	// Result from previous DSP
					.ax         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP		].w_sum),
					.ay         (h[m*N_MULTIPLIERS_IN_DSP		]),
					.bx         (PRE_ADD_INST[m*N_MULTIPLIERS_IN_DSP + 1	].w_sum),
					.by         (h[(m*N_MULTIPLIERS_IN_DSP )+ 1	]),
					.resulta    (w_out)
//					.chainout () // Un-connected
				);
			end
		end
	endgenerate
	

	/*******************************************************
	 * 
	 * Output Logic
	 *
	 *******************************************************/	
	//Actual outputs
	assign o_out =  DSP_INST[N_DSP2_INST-1].w_out >>> scale_factor;
	assign o_valid = VALID_PIPELINE_REG[N+N_EXTRA_VALID-1].r_valid;

endmodule 