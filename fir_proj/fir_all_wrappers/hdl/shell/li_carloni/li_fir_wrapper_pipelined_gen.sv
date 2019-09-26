module li_fir_wrapper_pipelined_gen #(
	parameter N = 51,
	parameter dw = 16,
	parameter N_UNIQ = 26,
	parameter N_DSP_INST = 7,
	parameter N_DSP2_INST = 1,
	parameter FIFO_ADDR = 2,
	parameter FIFO_ALMOST_FULL = 0,
	parameter FIFO_TYPE = "fifo_almost_full_megafunction"
) (
	input  clk,
	input  reset,

	li_link.sink   i_li_link,
	li_link.source o_li_link
);
	/*
	 * Delcarations
	 */
	wire [(dw+1)-1:0] w_fifo_data;
	wire w_enq;
	wire w_deq;
	wire w_i_valid_i_in_link_buf_full;
	wire w_almost_full;
	wire w_fire;
	wire w_fifo_empty;
	reg r_fire;
	
	/*
	 * Bypassable input queue(s)
	 */
	li_input_buffer #(
		.WIDTH(dw+1),
		.ADDR(FIFO_ADDR),
		.FIFO_ALMOST_FULL(FIFO_ALMOST_FULL),
		.FIFO_TYPE(FIFO_TYPE)
	) i_valid_i_in_link_buf (
		.clk           (clk),
		.reset         (reset),
		.i_data        (i_li_link.data),
		.o_data        (w_fifo_data),
		.i_enq         (w_enq),
		.i_deq         (w_deq),
		.o_full        (w_i_valid_i_in_link_buf_full),
		.o_almost_full (w_almost_full),
		.o_empty       (w_fifo_empty)
	);

	
	/*
	 * The pearl
	 */
	fir #(
		.N (N),
		.dw (dw),
		.N_UNIQ (N_UNIQ)
	) pearl (
		.clk (clk),
		.reset (reset),
		.clk_ena (r_fire),
		.i_in (w_fifo_data[dw-1:0]),
		.i_valid (w_fifo_data[dw]),
		.o_out (o_li_link.data[dw-1:0]),
		.o_valid (o_li_link.data[dw])
	);

	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_fire <= 1'b0;
		end else begin
			r_fire <= w_fire;
		end
	end
	
	//Output Valid
	assign o_li_link.valid = r_fire;
	
	//Fire condition
	assign w_fire = !w_fifo_empty && !o_li_link.stop;

	//Enq
	assign w_enq = i_li_link.valid;
	
	//Deq
	assign w_deq = !w_fifo_empty && !o_li_link.stop;
	
	//Stop upstream
	assign i_li_link.stop = w_almost_full;
	
endmodule
