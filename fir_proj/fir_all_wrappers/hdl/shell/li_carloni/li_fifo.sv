module carloni_fifo #(
	parameter WIDTH = 16,
	parameter ADDR = 1,
	parameter FIFO_ALMOST_FULL = 0,
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

	localparam FIFO_NUM_WORDS	= 2**ADDR;

// Debug begin
	initial begin
		if (FIFO_ALMOST_FULL > FIFO_NUM_WORDS) begin
			$display("FIFO_ALMOST_FULL = %d", FIFO_ALMOST_FULL);
			$display("FIFO_NUM_WORDS = %d", FIFO_NUM_WORDS);
			$error("FIFO_ALMOST_FULL value must be smaller than FIFO_NUM_WORDS");
		end
	end
// Debug end

	generate
		if (TYPE == "BRAM") begin
			initial $display("almost full megafunction fifo");
			scfifo fifo_inst (
				.aclr				(reset),
				.almost_empty	(),
				.almost_full	(o_almost_full),
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
				fifo_inst.lpm_width                = WIDTH,
				fifo_inst.lpm_widthu               = ADDR,
				fifo_inst.lpm_numwords             = 2**ADDR,
				fifo_inst.lpm_showahead            = "OFF",
				fifo_inst.lpm_type                 =  "scfifo",
				fifo_inst.enable_ecc               = "FALSE",       //Error Checking
				fifo_inst.use_eab                  = "ON",          //USE RAM BLOCKS
				fifo_inst.ram_block_type           = "M20K",
				fifo_inst.almost_full_value        =  FIFO_ALMOST_FULL - 1,
				fifo_inst.add_ram_output_register  = "ON";
		end else begin
			//Shouldn't get here
			initial begin
				$error("Invalid FIFO type %s", TYPE);
			end
		end	
	endgenerate
	
	
	
endmodule
	