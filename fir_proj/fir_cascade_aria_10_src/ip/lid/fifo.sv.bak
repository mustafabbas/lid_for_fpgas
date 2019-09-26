module fifo #(
	parameter WIDTH = 16,
	parameter ADDR = 1,
	parameter TYPE = "fifo_dpram_wrapper"
) (
	input clk,
	input reset,
	
	input [WIDTH-1:0] i_data,
	output [WIDTH-1:0] o_data,
	
	input i_enq,
	input i_deq,
	
	output o_almost_full,
	output o_full,
	output o_empty
);

	generate
		if(TYPE == "scfifo") begin
			//Altera's single clock fifo megafunction
			scfifo fifo_inst (
				.aclr				(reset),
				.almost_empty	(),
				.almost_full	(),
				.clock			(clk),
				.data				(i_data),
				.empty			(o_empty),
				.full				(o_full),
				.q					(o_data),
				.rdreq			(i_deq),
				.sclr				(),
				.usedw			(),
				.wrreq			(i_enq)
			);
			defparam
				fifo_inst.lpm_width = WIDTH,
				fifo_inst.lpm_widthu = ADDR,
				fifo_inst.lpm_numwords = 2**ADDR,
				fifo_inst.lpm_showahead = "ON";
			
		end else if (TYPE == "fifo_dpram_wrapper") begin
			fifo_dpram_wrapper #(
				.WIDTH(WIDTH),
				.ADDR(ADDR)
			) fifo_inst (
				.clk	(clk),
				.reset(reset),
				.din	(i_data),
				.enq	(i_enq),
				.deq	(i_deq),
				.dout	(o_data),
				.empty(o_empty),
				.full	(o_full)
			);
			assign o_almost_full = 1'b0;
		end else if (TYPE == "fifo_almost_full_dpram_wrapper") begin
			initial $display("almsot full fifo");
			fifo_almost_full_dpram_wrapper #(
				.WIDTH(WIDTH),
				.ADDR(ADDR)
			) fifo_inst (
				.clk	(clk),
				.reset(reset),
				.din	(i_data),
				.enq	(i_enq),
				.deq	(i_deq),
				.dout	(o_data),
				.empty(o_empty),
				.almost_full(o_almost_full),
				.full	(o_full)
			);
		end else if (TYPE == "fifo_free_word_count_dpram_wrapper") begin
			initial $display("wc fifo");
			fifo_free_word_count_dpram_wrapper #(
				.WIDTH(WIDTH),
				.ADDR(ADDR)
			) fifo_inst (
				.clk	(clk),
				.reset(reset),
				.din	(i_data),
				.enq	(i_enq),
				.deq	(i_deq),
				.dout	(o_data),
				.empty(o_empty),
				.almost_full(o_almost_full),
				.full	(o_full)
			);
		end else begin
			//Shouldn't get here
			initial begin
				$error("Invalid FIFO type %s", TYPE);
			end
		end	
	endgenerate
	
	
	
endmodule
	