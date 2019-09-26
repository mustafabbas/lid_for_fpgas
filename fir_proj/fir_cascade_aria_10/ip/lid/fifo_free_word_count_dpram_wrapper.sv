module fifo_free_word_count_dpram_wrapper #(
	parameter WIDTH=8,
	parameter ADDR=1,
	parameter ALMOST_FULL_MIN_FREE_WORDS=2
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

//		if (2**ADDR <= ALMOST_FULL_MIN_FREE_WORDS) 
//			$error("ALMOST_FULL_MIN_FREE_WORDS must be < 2**ADDR (%d < %d) or else FIFO will always be full",ALMOST_FULL_MIN_FREE_WORDS, 2**ADDR );
	end
	
	generate
		if(ADDR > 0) begin : GEN
			//MSBs of wr_ptr/rd_ptr used to identify full/empty
			reg [ADDR:0] r_wr_ptr;
			reg [ADDR:0] r_wr_ptr_next;
			reg [ADDR:0] r_rd_ptr;
			reg [ADDR:0] r_rd_ptr_next;
			
			//Next (incremented) ptrs
			reg [ADDR:0] c_wr_ptr_next;
			reg [ADDR:0] c_wr_ptr_next_next;
			reg [ADDR:0] c_rd_ptr_next;
			reg [ADDR:0] c_rd_ptr_next_next;
			
			//The actual addresses used to drive the RAM
			wire [ADDR-1:0] w_wr_addr;
			wire [ADDR-1:0] w_rd_addr;
			
			//Almost full intermediate values
			wire [ADDR-1:0] addr_diff;
			reg [ADDR:0] c_free_words;
			
			//Assign rd/wr addr
			// For the rd_addr:
			//   1) If we are not recieving deq, we should just show the HEAD of the fifo -> r_rd_ptr
			//   2) If we ARE recieving deq, we should use the next addr to avoid stalling -> c_rd_ptr_next
			assign w_rd_addr = (deq == 1'b1) ? c_rd_ptr_next[ADDR-1:0] : r_rd_ptr[ADDR-1:0];
			assign w_wr_addr = r_wr_ptr[ADDR-1:0];
			
			//Inferred Single-Clock Simple Dual Port RAM primitive
			scdpram_infer #(.WIDTH(WIDTH), .ADDR(ADDR)) scdpram_inst (
//			scdpram_altsyncram #(.WIDTH(WIDTH), .ADDR(ADDR)) scdpram_inst (
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
					r_rd_ptr_next <= {(ADDR){1'b0}};
				end else begin
					r_wr_ptr <= r_wr_ptr;
					r_rd_ptr <= r_rd_ptr;
					r_rd_ptr_next <= r_rd_ptr_next;
					if(enq) begin
						r_wr_ptr <= c_wr_ptr_next;
						r_wr_ptr_next <= c_wr_ptr_next_next;
					end
					if(deq) begin
						r_rd_ptr <= c_rd_ptr_next;
						r_rd_ptr_next <= c_rd_ptr_next_next;
					end
				end
			end
			
			//Next rd/wr ptrs
			always@(*) begin
				c_rd_ptr_next <= r_rd_ptr + 1'b1;
				c_rd_ptr_next_next <= r_rd_ptr + 2'd2;
				c_wr_ptr_next <= r_wr_ptr + 1'b1;
				c_wr_ptr_next_next <= r_wr_ptr + 2'd2;
			end
			
			//Full Empty
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
			

			assign addr_diff = r_rd_ptr[ADDR-1:0] - r_wr_ptr[ADDR-1:0];

			always@(*) begin
				c_free_words <= 2**ADDR - addr_diff;
				if(full)
					c_free_words <= {(ADDR+1) {1'b0}};
			end
			
			assign almost_full = (c_free_words <= ALMOST_FULL_MIN_FREE_WORDS) ? 1 : 0;
		
		end
	endgenerate
		
endmodule
