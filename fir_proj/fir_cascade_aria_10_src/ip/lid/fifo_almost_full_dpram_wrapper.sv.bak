module fifo_almost_full_dpram_wrapper #(
	parameter WIDTH=16,
	parameter ADDR=2,
	parameter ALMOST_FULL_MIN_FREE_WORDS=2, //almost_full turns on when there are this many or fewer words free
	parameter GENERALIZED_FULL_EMPTY=0,
	parameter GENERALIZED_ALMOST_FULL=0
)(
	input clk,
	input reset,
	input [WIDTH-1:0] din,
	input enq,
	input deq,
	output [WIDTH-1:0] dout,
	output reg empty,
	output reg full,
	output reg almost_full
);

	initial begin
		$display("FIFO WIDTH: %d FIFO ADDR %d", WIDTH, ADDR);
		
		if (2**ADDR <= ALMOST_FULL_MIN_FREE_WORDS)
			$warning("2**ADDR <= ALMOST_FULL_MIN_FREE_WORDS, FIFO will always be almost full");
	end
	
	generate
		if(ADDR >= 0) begin : GEN
			//MSBs of wr_ptr/rd_ptr used to identify full/empty
			reg [ADDR:0] r_wr_ptr;
			reg [ADDR:0] r_rd_ptr;
			
			//Next (incremented) ptrs
			reg [ADDR:0] c_wr_ptr_next;
			reg [ADDR:0] c_rd_ptr_next;
			
			//The actual addresses used to drive the RAM
			wire [ADDR-1:0] w_wr_addr;
			wire [ADDR-1:0] w_rd_addr;
			
			//Assign rd/wr addr
			// For the rd_addr:
			//   1) If we are not recieving deq, we should just show the HEAD of the fifo -> r_rd_ptr
			//   2) If we ARE recieving deq, we should use the next addr to avoid stalling -> c_rd_ptr_next
			assign w_rd_addr = (deq == 1'b1) ? c_rd_ptr_next[ADDR-1:0] : r_rd_ptr[ADDR-1:0];
			assign w_wr_addr = r_wr_ptr[ADDR-1:0];
			
			//Inferred Single-Clock Simple Dual Port RAM primitive
			scdpram_infer #(.WIDTH(WIDTH), .ADDR(ADDR)) scdpram_inst (
				.clk			(clk),
				.i_rd_addr	(GEN.w_rd_addr),
				.i_wr_addr	(GEN.w_wr_addr),
				.i_data		(din),
				.i_wr_ena	(enq),
				.o_data		(dout)
			);

			//RD/WR ptr reg update
			always@(posedge clk or posedge reset) begin
				if(reset) begin
					r_wr_ptr <= {(ADDR){1'b0}};
					r_rd_ptr <= {(ADDR){1'b0}};
				end else begin
					r_wr_ptr <= r_wr_ptr;
					r_rd_ptr <= r_rd_ptr;
					if(enq) begin
						r_wr_ptr <= c_wr_ptr_next;
					end
					if(deq) begin
						r_rd_ptr <= c_rd_ptr_next;
					end
				end
			end
			
			//Next rd/wr ptrs
			always@(*) begin
				c_rd_ptr_next <= r_rd_ptr + 1'b1;
				c_wr_ptr_next <= r_wr_ptr + 1'b1;
			end
			
			//Full Empty
//			always@(*) begin
//				empty <= 1'b0;
//				full <= 1'b0;
//				if(r_wr_ptr[ADDR-1:0] == r_rd_ptr[ADDR-1:0]) begin
//					if(r_wr_ptr[ADDR] == r_rd_ptr[ADDR]) begin
//						empty <= 1'b1;
//					end else begin
//						full <= 1'b1;
//					end
//				end
//			end
			
			if(GENERALIZED_FULL_EMPTY) begin
				wire [ADDR-1:0] addr_diff;
				assign addr_diff = r_wr_ptr[ADDR-1:0] - r_rd_ptr[ADDR-1:0];

				reg [ADDR:0] c_free_words;

				always@(*) begin
					c_free_words <= 2**ADDR - addr_diff;
					if((addr_diff == {(ADDR) {1'b0}}) && (r_wr_ptr[ADDR] != r_rd_ptr[ADDR])) begin
						c_free_words <= {(ADDR+1) {1'b0}};
					end
				end				
				
				assign empty = (c_free_words == 2**ADDR);
				assign almost_full = (c_free_words <= ALMOST_FULL_MIN_FREE_WORDS);
				assign full = (c_free_words == 0);
			
			end else begin
			
				always@(*) begin
					empty <= 1'b0;
					full <= 1'b0;
					if(r_wr_ptr[ADDR-1:0] == r_rd_ptr[ADDR-1:0]) begin
						if(r_wr_ptr[ADDR] == r_rd_ptr[ADDR]) begin
							empty <= 1'b1;
						end else begin
							full <= 1'b1;
						end
					end
				end
				
				if(GENERALIZED_ALMOST_FULL) begin
					wire [ADDR-1:0] addr_diff;
					assign addr_diff = r_wr_ptr[ADDR-1:0] - r_rd_ptr[ADDR-1:0];
					
					reg [ADDR:0] c_free_words;
					always@(*) begin
						c_free_words <= 2**ADDR - addr_diff;
						if(full) begin
							c_free_words <= {(ADDR+1) {1'b0}};
						end
					end
					assign almost_full = (c_free_words <= ALMOST_FULL_MIN_FREE_WORDS);
					
				end else begin
					if(ALMOST_FULL_MIN_FREE_WORDS == 0) begin
						assign almost_full = full;
					end else if(ALMOST_FULL_MIN_FREE_WORDS == 1) begin
						// Signal amost full when only one unused word remains
						reg [ADDR:0] r_wr_ptr_next;
						
						always@(posedge clk or posedge reset) begin
							if(reset) begin
								r_wr_ptr_next <= 2'd1;//{(ADDR+1) {1'b0}};
							end else begin
								r_wr_ptr_next <= r_wr_ptr_next;
								if(enq) begin
									r_wr_ptr_next <= r_wr_ptr + 2'd2;
								end
							end
								
						end
						
						always@(*) begin
							almost_full <= 1'b0;
							if((r_wr_ptr_next[ADDR] != r_rd_ptr[ADDR]) && (r_wr_ptr_next[ADDR-1:0] == r_rd_ptr[ADDR-1:0])) begin
								almost_full <= 1'b1;
							end
							if(full)
								almost_full <= 1'b1;
						end
						
					end else if (ALMOST_FULL_MIN_FREE_WORDS == 2) begin
						reg [ADDR:0] r_wr_ptr_next;
						reg [ADDR:0] r_wr_ptr_next_next;
						
						always@(posedge clk or posedge reset) begin
							if(reset) begin
								r_wr_ptr_next <= 2'd1;
								r_wr_ptr_next_next <= 2'd2;
							end else begin
								r_wr_ptr_next <= r_wr_ptr_next;
								r_wr_ptr_next_next <= r_wr_ptr_next_next;
								if(enq) begin
									r_wr_ptr_next <= r_wr_ptr + 2'd2;
									r_wr_ptr_next_next <= r_wr_ptr + 2'd3;
								end
							end
								
						end
						
						// Signal amost full when only one unused word remains
						always@(*) begin
							almost_full <= 1'b0;
							if((r_wr_ptr_next[ADDR] != r_rd_ptr[ADDR]) && (r_wr_ptr_next[ADDR-1:0] == r_rd_ptr[ADDR-1:0])) begin
								almost_full <= 1'b1;
							end
							if((r_wr_ptr_next_next[ADDR] != r_rd_ptr[ADDR]) && (r_wr_ptr_next_next[ADDR-1:0] == r_rd_ptr[ADDR-1:0])) begin
								almost_full <= 1'b1;
							end
							if(full)
								almost_full <= 1'b1;
						end					
					end else begin
						initial $error("Invalid ALMOST_FULL_MIN_FREE_WORDS %d, with GENERALIZED_ALMOST_FULL set to 0", ALMOST_FULL_MIN_FREE_WORDS);
					end
				end
			end
			
		end else begin
			initial
				$error("Invalid ADDR: %d", ADDR);
		end
		
	endgenerate
		
endmodule
