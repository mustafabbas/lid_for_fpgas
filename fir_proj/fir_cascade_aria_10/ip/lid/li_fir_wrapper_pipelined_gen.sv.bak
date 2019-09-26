/*
 * Latency Insensitive Wrapper generated on Mon Jul 22 12:00:44 2013 for kmurray
 *
 * Command Line:
 *   ../wrapper_script/li_wrap.pl -v ip/fir/hdl/fir.sv -o li_fir_wrapper_pipelined_gen.sv -m i_valid,i_in;o_out,o_valid -p 2
 *
 */

module li_fir_wrapper_pipelined_gen #(
	parameter N = 51,
	parameter dw = 16,
	parameter N_UNIQ = 26,
	parameter N_DSP_INST = 7,
	parameter N_EXTRA_VALID = 13,
	parameter N_DSP2_INST = 1,
	parameter FIFO_ADDR = 2
) (
	input  clk,
	input  reset,

	li_link.sink   i_valid_i_in_link,
	li_link.source o_out_o_valid_link
);
	/*
	 * Delcarations
	 */
	//i_valid_i_in_link_buf delcarations
	wire w_i_valid_i_in_link_buf_bypass;
	wire [(dw+1)-1:0] w_i_valid_i_in_link_buf_data;
	reg [(dw+1)-1:0] r_i_valid_i_in_link_buf_data;
	reg c_i_valid_i_in_link_buf_enq;
	wire w_i_valid_i_in_link_buf_deq;
	wire w_i_valid_i_in_link_buf_full;
	wire w_i_valid_i_in_link_buf_almost_full;
	wire w_i_valid_i_in_link_buf_empty;
	
	//Control Logic delcarations
	reg r_o_out_o_valid_link_stop;
	wire w_inputs_valid;
	wire w_outputs_ok;
	wire w_fire;
	reg r_fire;
	reg r_o_out_o_valid_link_done;
	reg r_o_out_o_valid_link_done_delay1;
	
	/*
	 * Bypassable input queue(s)
	 */
	li_input_buffer #(
		.WIDTH(dw+1),
		.ADDR(FIFO_ADDR)
	) i_valid_i_in_link_buf (
		.clk           (clk),
		.reset         (reset),
		.i_bypass      (w_i_valid_i_in_link_buf_bypass),
		.i_data        (i_valid_i_in_link.data),
		.o_data        (w_i_valid_i_in_link_buf_data),
		.i_enq         (c_i_valid_i_in_link_buf_enq),
		.i_deq         (w_i_valid_i_in_link_buf_deq),
		.o_full        (w_i_valid_i_in_link_buf_full),
		.o_almost_full (w_i_valid_i_in_link_buf_almost_full),
		.o_empty       (w_i_valid_i_in_link_buf_empty)
	);
	
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_i_valid_i_in_link_buf_data <= {(dw+1) {1'b0}};
		end else begin
			r_i_valid_i_in_link_buf_data <= w_i_valid_i_in_link_buf_data;
		end
	end
	
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
		.clk (clk),
		.reset (reset),
		.clk_ena (r_fire),
		.i_in (r_i_valid_i_in_link_buf_data[dw-1:0]),
		.i_valid (r_i_valid_i_in_link_buf_data[dw]),
		.o_out (o_out_o_valid_link.data[dw-1:0]),
		.o_valid (o_out_o_valid_link.data[dw])
	);
	
	//Output Channle Stop Register(s)
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_o_out_o_valid_link_stop <= 1'b0;
		end else begin
			r_o_out_o_valid_link_stop <= o_out_o_valid_link.stop;
		end
	end
	
	//Fire condition
	assign w_inputs_valid = ((i_valid_i_in_link.valid || !w_i_valid_i_in_link_buf_empty));
	assign w_outputs_ok = !((r_o_out_o_valid_link_stop));
	assign w_fire = w_inputs_valid && w_outputs_ok;
	
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_fire <= 1'b1;
		end else begin
			r_fire <= w_fire;
		end
	end
	
	//Output(s) valid
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_o_out_o_valid_link_done <= 1'b1;
			r_o_out_o_valid_link_done_delay1 <= 1'b0;
		end else begin
			if(!r_o_out_o_valid_link_stop) begin
				r_o_out_o_valid_link_done <= w_fire;
			end else begin
				r_o_out_o_valid_link_done <= 1'b0;
			end
			//Pipeline for one cycle to match datapath
			r_o_out_o_valid_link_done_delay1 <= r_o_out_o_valid_link_done;
		end
	end
	assign o_out_o_valid_link.valid = r_o_out_o_valid_link_done_delay1;
	
	//Enq
	always@(*) begin
		casex({i_valid_i_in_link.valid, w_i_valid_i_in_link_buf_almost_full, w_i_valid_i_in_link_buf_full, w_fire, w_i_valid_i_in_link_buf_empty})
			5'b1000x: begin
				//Valid && not almost full && not full && not fire
				c_i_valid_i_in_link_buf_enq <= 1'b1;
			end
			5'b100x0: begin
				//Valid && not almost full && not full && not empty
				c_i_valid_i_in_link_buf_enq <= 1'b1;
			end
			5'b110xx: begin
				//Valid && almost full && not full
				c_i_valid_i_in_link_buf_enq <= 1'b1;
			end
			default: begin
				c_i_valid_i_in_link_buf_enq <= 1'b0;
			end
		endcase
	end
	
	//Deq
	assign w_i_valid_i_in_link_buf_deq = !w_i_valid_i_in_link_buf_empty && w_fire;
	
	//Stop upstream
	assign i_valid_i_in_link.stop = w_i_valid_i_in_link_buf_almost_full;
	
	//FIFO bypass
	assign w_i_valid_i_in_link_buf_bypass = w_i_valid_i_in_link_buf_empty;
	
endmodule

