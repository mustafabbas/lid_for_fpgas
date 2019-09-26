module credit_fifo #(
	parameter DATA_WIDTH	= 16,
	parameter FIFO_ADDR	= 2,
	parameter FIFO_TYPE	= "BRAM",
	parameter RAMSTYLE	= "M20K" 	//M20K or MLAB
) (
	input clock,
	input reset,

	// Data signals
	input signed [DATA_WIDTH-1:0] i_data,
	output signed [DATA_WIDTH-1:0] o_data,

	// Control Signals
	input i_enq,
	input i_deq,

	// Feedback Signals
	output o_empty
);

    (* ramstyle = RAMSTYLE *)

	generate
		if(FIFO_TYPE == "BRAM") begin
			// Altera's single clock fifo megafunction
			scfifo  fifo_inst (
				.clock (clock),
				.data (i_data),
				.rdreq (i_deq),
				.wrreq (i_enq),
				.q (o_data),
				.aclr (reset),
				.almost_empty (),
				.almost_full (),
				.eccstatus (),
				.empty (o_empty),
				.full (),			// Not used, counter kepts track at the sender side
				.sclr (),
				.usedw ());
			defparam
				fifo_inst.lpm_width  = DATA_WIDTH,
				fifo_inst.lpm_widthu  = FIFO_ADDR,
				fifo_inst.lpm_numwords  = 2**FIFO_ADDR,
				fifo_inst.lpm_showahead  = "OFF",
				fifo_inst.lpm_type  = "scfifo",
				//fifo_inst.overflow_checking  = "OFF",
				//fifo_inst.underflow_checking  = "OFF",
				fifo_inst.enable_ecc  = "FALSE",				//Error Checking
				fifo_inst.use_eab  = "ON",						//USE RAM BLOCKS
				fifo_inst.ram_block_type = "M20K",
				fifo_inst.add_ram_output_register  = "ON";

		end else if (FIFO_TYPE == "MLAB") begin
			// Altera's single clock fifo megafunction
			scfifo  fifo_inst (
				.clock (clock),
				.data (i_data),
				.rdreq (i_deq),
				.wrreq (i_enq),
				.q (o_data),
				.aclr (reset),
				.almost_empty (),
				.almost_full (),
				.eccstatus (),
				.empty (),
				.full (),
				.sclr (),
				.usedw ());
			defparam
				fifo_inst.lpm_width  = DATA_WIDTH,
				fifo_inst.lpm_widthu  = FIFO_ADDR,
				fifo_inst.lpm_numwords  = 2**FIFO_ADDR,
				fifo_inst.lpm_showahead  = "ON",
				fifo_inst.lpm_type  = "scfifo",
				fifo_inst.overflow_checking  = "OFF",
				fifo_inst.underflow_checking  = "OFF",
				fifo_inst.enable_ecc  = "FALSE",				//Error Checking
				fifo_inst.use_eab  = "ON",						//USE RAM BLOCKS
				fifo_inst.ram_block_type = "MLAB",
				fifo_inst.add_ram_output_register  = "ON";

		end else begin
			//Shouldn't get here
			initial begin
				$error("Invalid FIFO type %s", FIFO_TYPE);
			end
		end	
	endgenerate

endmodule
	