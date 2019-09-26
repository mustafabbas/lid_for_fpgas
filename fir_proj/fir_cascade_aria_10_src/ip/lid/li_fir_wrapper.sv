module li_fir_wrapper #(
	parameter N = 51,
	parameter dw = 16,
	parameter N_UNIQ = 26,
	parameter N_DSP_INST = 7,
	parameter N_EXTRA_VALID = 13,
	parameter N_DSP2_INST = 1,
	parameter FIFO_ADDR = 1
) (
	input  clk,
	input  reset,

	li_link.source o_valid_link,
	li_link.sink   i_valid_link,
	li_link.source o_out_link,
	li_link.sink   i_in_link
);
	/*
	 * Delcarations
	 */
	//i_valid_link_buf delcarations
	wire w_i_valid_link_buf_bypass;
	wire w_i_valid_link_buf_data;
	wire w_i_valid_link_buf_enq;
	wire w_i_valid_link_buf_deq;
	wire w_i_valid_link_buf_full;
	wire w_i_valid_link_buf_empty;
	
	//i_in_link_buf delcarations
	wire w_i_in_link_buf_bypass;
	wire [dw-1:0] w_i_in_link_buf_data;
	wire w_i_in_link_buf_enq;
	wire w_i_in_link_buf_deq;
	wire w_i_in_link_buf_full;
	wire w_i_in_link_buf_empty;
	
	//Control Logic delcarations
	wire w_inputs_valid;
	wire w_outputs_ok;
	wire w_fire;
	wire w_gclk;
	reg r_o_valid_link_done;
	reg r_o_out_link_done;
	
	/*
	 * Bypassable input queue(s)
	 */
	li_input_buffer #(
		.WIDTH(1),
		.ADDR(FIFO_ADDR)
	) i_valid_link_buf (
		.clk        (clk),
		.reset      (reset),
		.i_bypass   (w_i_valid_link_buf_bypass),
		.i_data     (i_valid_link.data),
		.o_data     (w_i_valid_link_buf_data),
		.i_enq      (w_i_valid_link_buf_enq),
		.i_deq      (w_i_valid_link_buf_deq),
		.o_full     (w_i_valid_link_buf_full),
		.o_empty    (w_i_valid_link_buf_empty)
	);
	
	li_input_buffer #(
		.WIDTH(dw),
		.ADDR(FIFO_ADDR)
	) i_in_link_buf (
		.clk        (clk),
		.reset      (reset),
		.i_bypass   (w_i_in_link_buf_bypass),
		.i_data     (i_in_link.data),
		.o_data     (w_i_in_link_buf_data),
		.i_enq      (w_i_in_link_buf_enq),
		.i_deq      (w_i_in_link_buf_deq),
		.o_full     (w_i_in_link_buf_full),
		.o_empty    (w_i_in_link_buf_empty)
	);
	
	/*
	 * The pearl
	 */
	fir #(
		.N (N),
		.dw (dw),
		.N_UNIQ (N_UNIQ),
		.N_DSP_INST (N_DSP_INST),
		.N_EXTRA_VALID (N_EXTRA_VALID),
		.N_DSP2_INST (N_DSP2_INST)
	) pearl (
		.clk (w_gclk),
		.clk_ena(1'b1),
		.reset (reset),
		.o_valid (o_valid_link.data),
		.i_valid (w_i_valid_link_buf_data),
		.o_out (o_out_link.data),
		.i_in (w_i_in_link_buf_data)
	);
	
	//Fire condition
	assign w_inputs_valid = ((i_valid_link.valid || !w_i_valid_link_buf_empty) && (i_in_link.valid || !w_i_in_link_buf_empty));
	assign w_outputs_ok = !((o_valid_link.stop && o_valid_link.valid) || (o_out_link.stop && o_out_link.valid));
	assign w_fire = w_inputs_valid & w_outputs_ok;
	assign w_gclk = w_fire & clk;
	
	//Output(s) valid
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_o_valid_link_done <= 1'b1;
		end else begin
			if(o_valid_link.stop && r_o_valid_link_done)
				r_o_valid_link_done <= 1'b1;
			else
				r_o_valid_link_done <= w_fire;
		end
	end
	assign o_valid_link.valid = r_o_valid_link_done;
	
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_o_out_link_done <= 1'b1;
		end else begin
			if(o_out_link.stop && r_o_out_link_done)
				r_o_out_link_done <= 1'b1;
			else
				r_o_out_link_done <= w_fire;
		end
	end
	assign o_out_link.valid = r_o_out_link_done;
	
	//Enq
	assign w_i_valid_link_buf_enq = i_valid_link.valid && (!w_fire || !w_i_valid_link_buf_empty) && !w_i_valid_link_buf_full;
	assign w_i_in_link_buf_enq = i_in_link.valid && (!w_fire || !w_i_in_link_buf_empty) && !w_i_in_link_buf_full;
	
	//Deq
	assign w_i_valid_link_buf_deq = !w_i_valid_link_buf_empty && w_fire;
	assign w_i_in_link_buf_deq = !w_i_in_link_buf_empty && w_fire;
	
	//Stop upstream
	assign i_valid_link.stop = w_i_valid_link_buf_full;
	assign i_in_link.stop = w_i_in_link_buf_full;
	
	//FIFO bypass
	assign w_i_valid_link_buf_bypass = w_i_valid_link_buf_empty;
	assign w_i_in_link_buf_bypass = w_i_in_link_buf_empty;
	
endmodule

