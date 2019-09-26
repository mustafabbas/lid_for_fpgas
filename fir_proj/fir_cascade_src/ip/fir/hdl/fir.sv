(* multstyle = "dsp" *) module fir
#(
	/* Data Width */
	parameter dw = 16, //Data input/output bits

	/* Number of filter coefficients */
	parameter N = 51,
	parameter N_UNIQ = 26, // ciel(N/2) assuming symmetric filter coefficients
	
	/* DSP Info */
	parameter N_DSP_INST = 7,	//Total number of dsp_mac_4mult and dsp_mac_2mult instances
	parameter N_DSP2_INST = 1, //Number of dsp_mac_2mult instances
	
	/*Number of extra valid cycles needed to align output (i.e. computation pipeline depth + input/output registers)*/
	parameter N_EXTRA_VALID = 13
)(
	input clk,
	input reset,
	input clk_ena,
	input i_valid,
	input signed [dw-1:0] i_in,
	output o_valid,
	output signed [dw-1:0] o_out
);

	/* Data Width dervied parameters */
	localparam dw_add_int = dw; //Internal adder precision bits
	localparam dw_mult_int = 2*dw; //Internal multiplier precision bits
	localparam scale_factor = dw_mult_int - dw - 1; //Multiplier normalization shift amount
	
	/* DSP output width */
	localparam DSP_RESULT_WIDTH = 44;
	
	/* Number of extra registers in INPUT_PIPELINE_REG to prevent contention for CHAIN_END's
	chain adders */
	localparam N_EXTRA_INPUT_REG = (N_DSP_INST - N_DSP2_INST) / 2; //Should be 3
	localparam N_INPUT_ADD_CYCLES = 1; //Number of cycles for input adders
	
	/* Debug */
	initial begin
		$display ("Data Width: %d", dw);
		$display ("Data Width Add Internal: %d", dw_add_int);
		$display ("Data Width Mult Internal: %d", dw_mult_int);
		$display ("Scale Factor: %d", scale_factor);
	end

	
	const shortint h [N_UNIQ+1] = '{
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
		16'd2984,
		16'd2950	
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
	genvar j;
	generate for (j = 0; j < N_DSP_INST; j++) begin : DSP_INST
		localparam N_INPUTS_4MULT = 4;		
		
		//Offsets required to account for extra cycle delay caused
		// by DSP block chaining
		localparam head_offset_even = 0;
		localparam head_offset_odd = 1;
		localparam tail_offset_even = 0;
		localparam tail_offset_odd = 1;
		localparam last_offset = 2;
		
		//Intermediate wires
		wire signed [DSP_RESULT_WIDTH-1:0] w_result;
		wire signed [DSP_RESULT_WIDTH-1:0] w_norm_result_full_width;
		wire signed [dw_add_int-1:0] w_norm_result;
		wire signed [dw-1:0] w_shiftout;
		
		//Merge inputs due to symmetric filter coefficients
		wire signed [dw_add_int-1:0] w_inadder_out_0;
		wire signed [dw_add_int-1:0] w_inadder_out_1;
		wire signed [dw_add_int-1:0] w_inadder_out_2;
		wire signed [dw_add_int-1:0] w_inadder_out_3;
	
		if((j+1)*N_INPUTS_4MULT <= N_UNIQ) begin : INTERMEDIATE //All DSPs except for last
		
			if(j % 2 == 0) begin : CHAIN_START
				//Start of a DSP block chain pair
				
				//Input adders merging samples with common coefficients
				input_adder	input_adder_inst0 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+0+head_offset_even].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-1+tail_offset_even].r_input),
					.result 	(w_inadder_out_0)
				);
				input_adder	input_adder_inst1 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+1+head_offset_even].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-2+tail_offset_even].r_input),
					.result 	(w_inadder_out_1)
				);
				input_adder	input_adder_inst2 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+2+head_offset_even].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-3+tail_offset_even].r_input),
					.result 	(w_inadder_out_2)
				);
				input_adder	input_adder_inst3 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+3+head_offset_even].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-4+tail_offset_even].r_input),
					.result 	(w_inadder_out_3)
				);
				
				//Half of a Stratix IV DSP block
				dsp_4mult_add   dsp_4mult_add_inst (
					.clock0	(clk),
					.ena0		(clk_ena),
					.chainin (), //Un-connected
					.dataa_0 (w_inadder_out_0),
					.dataa_1 (w_inadder_out_1),
					.dataa_2 (w_inadder_out_2),
					.dataa_3 (w_inadder_out_3),
					.datab_0 (h[j*N_INPUTS_4MULT  ]),
					.datab_1 (h[j*N_INPUTS_4MULT+1]),
					.datab_2 (h[j*N_INPUTS_4MULT+2]),
					.datab_3 (h[j*N_INPUTS_4MULT+3]),
					.result 	(w_result)
				);
			end
			else begin : CHAIN_END
				//End of a DSP block chain pair
				
				input_adder	input_adder_inst0 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+0+head_offset_odd].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-1+tail_offset_odd].r_input),
					.result 	(w_inadder_out_0)
				);
				input_adder	input_adder_inst1 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+1+head_offset_odd].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-2+tail_offset_odd].r_input),
					.result 	(w_inadder_out_1)
				);
				input_adder	input_adder_inst2 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+2+head_offset_odd].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-3+tail_offset_odd].r_input),
					.result 	(w_inadder_out_2)
				);
				input_adder	input_adder_inst3 (
					.clock 	(clk),
					.clken	(clk_ena),
					.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+3+head_offset_odd].r_input),
					.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-4+tail_offset_odd].r_input),
					.result 	(w_inadder_out_3)
				);				
				
				dsp_4mult_add   dsp_4mult_add_inst (
					.clock0	(clk),
					.ena0		(clk_ena),
					.chainin (DSP_INST[j-1].w_result), //Chain from previous stage
					.dataa_0 (w_inadder_out_0),
					.dataa_1 (w_inadder_out_1),
					.dataa_2 (w_inadder_out_2),
					.dataa_3 (w_inadder_out_3),
					.datab_0 (h[j*N_INPUTS_4MULT  ]),
					.datab_1 (h[j*N_INPUTS_4MULT+1]),
					.datab_2 (h[j*N_INPUTS_4MULT+2]),
					.datab_3 (h[j*N_INPUTS_4MULT+3]),
					.result 	(w_result)
				);
			end
		end
		else begin : LAST
			input_adder	input_adder_inst0 (
				.clock 	(clk),
				.clken	(clk_ena),
				.dataa 	(INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+0+last_offset].r_input),
				.datab 	(INPUT_PIPELINE_REG[N-(j*N_INPUTS_4MULT)-1+last_offset].r_input),
				.result 	(w_inadder_out_0)
			);
			
			//Last coefficient is not repeated, so no adder
			assign w_inadder_out_1 = INPUT_PIPELINE_REG[j*N_INPUTS_4MULT+1+last_offset+N_INPUT_ADD_CYCLES].r_input; 
			
			dsp_2mult_add	dsp_2mult_add_inst (
				.clock0 	(clk),
				.ena0		(clk_ena),
				.dataa_0 (w_inadder_out_0),
				.dataa_1 (w_inadder_out_1),
				.datab_0 (h[N_UNIQ-2]),
				.datab_1 (h[N_UNIQ-1]),
				.result 	(w_result)
			);
		end
		
		assign w_norm_result_full_width = w_result >>> scale_factor; //Full width for chain
		assign w_norm_result = w_result >>> scale_factor; //Reduced width for output
	end
	endgenerate
	
	/*******************************************************
	 * 
	 * Output Adder Tree
	 *
	 *******************************************************/
	wire [dw_add_int-1:0] w_sum;
	
	//The last portion of the adder tree that doesn't fit in
	// DSP blocks
	adder_tree #(
		.WIDTH(dw_add_int)
		) adder_tree (
		.clk(clk),
		.clk_ena(clk_ena),
		.reset(reset),
		.i_a(DSP_INST[1].w_norm_result),
		.i_b(DSP_INST[3].w_norm_result),
		.i_c(DSP_INST[5].w_norm_result),
		.i_d(DSP_INST[6].w_norm_result),
		.o_sum(w_sum)
	);

	/*******************************************************
	 * 
	 * Output Logic
	 *
	 *******************************************************/	
	//Actual outputs
	assign o_out = w_sum;
	assign o_valid = VALID_PIPELINE_REG[N+N_EXTRA_VALID-1].r_valid;

endmodule 
