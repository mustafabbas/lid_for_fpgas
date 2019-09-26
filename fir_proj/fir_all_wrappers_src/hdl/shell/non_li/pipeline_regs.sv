module pipeline_regs #(
	parameter WIDTH = 6,
	parameter N_STAGES = 1
) (
	input clk,
	input reset,

	input [WIDTH-1:0]i_data,
	input i_valid,
	output [WIDTH-1:0]o_data,
	output o_valid
);
	genvar i;
	generate
		if(N_STAGES == 0) begin
			assign o_data = i_data;
			assign o_valid = i_valid;
		end else begin	
			for(i=0; i < N_STAGES; i ++) begin : REGs
				reg [WIDTH-1:0] r_data;
				reg r_valid;
				
				if(i == 0) begin : FIRST
				
					always@(posedge clk or posedge reset) begin
						if(reset) begin
							r_data <= {(WIDTH){1'b0}};
							r_valid <= 1'b0;
						end else begin
							r_data <= i_data;
							r_valid <= i_valid;
						end
					end
					
				end else begin : INTERMEDIATE_LAST
				
					always@(posedge clk or posedge reset) begin
						if(reset) begin
							r_data <= {(WIDTH){1'b0}};
							r_valid <= 1'b0;
						end else begin
							r_data <= REGs[i-1].r_data;
							r_valid <= REGs[i-1].r_valid;
						end
					end	
		
				end
				
				//Assign output
				if(i == N_STAGES-1) begin
					assign o_data = REGs[i].r_data;
					assign o_valid = REGs[i].r_valid;
				end
				
			end
		end
	endgenerate


endmodule
