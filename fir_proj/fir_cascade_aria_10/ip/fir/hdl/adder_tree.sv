/*
 *  A 4 input adder tree (2 levels)
 *
 *  Inputs are not registered (should be fed by
 *  registered outputs of DSP blocks).
 *
 *  Output is registered.
 *  
 *  Each level is pipelined to improve frequency.
 * 
 */
module adder_tree
#(
	parameter WIDTH=17
)(
	input clk,
	input clk_ena,
	input reset,
	input signed [WIDTH-1:0] i_a,
	input signed [WIDTH-1:0] i_b,
	input signed [WIDTH-1:0] i_c,
	input signed [WIDTH-1:0] i_d,
	output signed [WIDTH-1:0] o_sum
);
	//Unregistered adder outputs
	wire signed [WIDTH-1:0] w_add1_sum;
	wire signed [WIDTH-1:0] w_add2_sum;
	wire signed [WIDTH-1:0] w_add3_sum;
	
	//Registered adder outputs
	reg signed [WIDTH-1:0] r_add1_sum; 
	reg signed [WIDTH-1:0] r_add2_sum;
	reg signed [WIDTH-1:0] r_add3_sum;
	
	//Level 1
	output_adder	output_adder_inst1 (
		.clock 	(clk),
		.clken	(clk_ena),
		.dataa 	(i_a),
		.datab 	(i_b),
		.result 	(w_add1_sum)
	);
	
	output_adder	output_adder_inst2 (
		.clock 	(clk),
		.clken	(clk_ena),
		.dataa 	(i_c),
		.datab 	(i_d),
		.result 	(w_add2_sum)
	);

	//Level 1 Output registers
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_add1_sum <= 0;
			r_add2_sum <= 0;
		end
		else begin
			if(clk_ena) begin
				r_add1_sum <= w_add1_sum;
				r_add2_sum <= w_add2_sum;		
			end else begin
				r_add1_sum <= r_add1_sum;
				r_add2_sum <= r_add2_sum;
			end
		end
	end
	
	//Level 2
	output_adder	output_adder_inst3 (
		.clock 	(clk),
		.clken	(clk_ena),
		.dataa 	(r_add1_sum),
		.datab 	(r_add2_sum),
		.result 	(w_add3_sum)
	);
	
	//Level 2 Output registers
	always@(posedge clk or posedge reset) begin
		if (reset)
			r_add3_sum <= 0;
		else
			if(clk_ena)
				r_add3_sum <= w_add3_sum;
			else
				r_add3_sum <= r_add3_sum;
	end
	
	//Final output
	assign o_sum = r_add3_sum;

endmodule
