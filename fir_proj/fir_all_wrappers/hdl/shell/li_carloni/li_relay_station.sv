 module li_relay_station #(
	parameter WIDTH = 6
) (
	input clk,
	input reset,
	
	li_link.sink in_link,
	li_link.source out_link
);

	//FSM parameters & states
	localparam 	C_STATE_BITS = 2;
	localparam	[C_STATE_BITS-1:0]	S_PROCESS   = 2'b00,
												S_WRITE_AUX = 2'b01,
												S_READ_AUX  = 2'b10,
												S_STALL     = 2'b11;

	reg [C_STATE_BITS-1:0] r_curr_state;
	reg [C_STATE_BITS-1:0] c_next_state;

	//FSM outputs
	reg c_write_main;
	reg c_write_aux;
	reg c_mux_sel_aux;
	reg c_mux_sel_main;
	reg c_stop_upstream;

	//Registers
	reg [WIDTH-1:0] r_data_main;
	reg r_valid_main;
	reg [WIDTH-1:0] r_data_aux;
	reg r_valid_aux;

	//Mux outputs
	reg [WIDTH-1:0] c_data_mux;
	reg c_valid_mux;
	reg c_valid_main_mux;

	//Aux register bank
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_data_aux <= {(WIDTH){1'b0}};
			r_valid_aux <= 1'b0;
		end else begin
			if(c_write_aux) begin
				r_data_aux <= in_link.data;
				r_valid_aux <= in_link.valid;
			end else begin
				r_data_aux <= r_data_aux;
				r_valid_aux <= r_valid_aux;
			end
		end
	end

	//Main register bank
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_data_main  <= {(WIDTH){1'b0}};
			r_valid_main <= 1'b0;
		end else begin
			if(c_write_main) begin
				r_data_main  <= c_data_mux;
				r_valid_main <= c_valid_mux;
			end else begin
				r_data_main  <= r_data_main;
				r_valid_main <= r_valid_main;
			end
		end
	end

	//Data mux
	always@(*) begin
		if(c_mux_sel_aux == 0) begin
			c_data_mux <= in_link.data;
			c_valid_mux <= in_link.valid;
		end else begin
			c_data_mux <= r_data_aux;
			c_valid_mux <= r_valid_aux;
		end
	end

	//Valid Main mux
	always@(*) begin
		if(c_mux_sel_main == 0) begin
			c_valid_main_mux <= r_valid_main;
		end else begin
			c_valid_main_mux <= 1'b0;
		end
	end

	assign out_link.data  = r_data_main;
	assign out_link.valid = c_valid_main_mux;
	assign in_link.stop = c_stop_upstream;

	/*
	 * Control FSM
	 */

	//FSM output logic
	always@(*) begin
		// NOTE: Combined MEALY and MOORE FSM
		// c_stop_upstream is a MOORE output, so there is not combinational path through the FSM for it
		// All other FSM outputs drive internal module structures that control the main output FFs
		case(r_curr_state)
			S_PROCESS: begin
				// Never stall the upstream if processing
				c_stop_upstream <= 0;

				// Control Logic is the same regardless of input stop bit
				c_mux_sel_aux  <= 0;
				c_mux_sel_main <= 0;
				c_write_main   <= 1;
				c_write_aux    <= 0;

				if (~out_link.stop) begin
					c_next_state <= S_PROCESS;
				end else begin
					c_next_state <= S_WRITE_AUX;
				end
			end
			S_WRITE_AUX: begin
				// Always stall upstream since we are going into a stall and can't accept any
				// new packets
				c_stop_upstream <= 1;

				if(out_link.stop) begin
					c_mux_sel_aux  <= 0;
					c_mux_sel_main <= 1;    // Invalidate output
					c_write_main   <= 0;		// Store current value in main register
					c_write_aux    <= 1;    // Store next value in aux register

					c_next_state   <= S_STALL;
				end else begin
					// Keep the same control logic as Process and return to Process
					// state immediately after
					c_mux_sel_aux  <= 0;
					c_mux_sel_main <= 0;
					c_write_main   <= 1;
					c_write_aux    <= 0;

					c_next_state <= S_PROCESS;
				end
			end
			S_READ_AUX: begin
				// Returning back from stall so no need to stall upstream
				c_stop_upstream <= 0;

				// Control Logic
				c_mux_sel_aux  <= 1;    // Read from aux
				c_mux_sel_main <= 0;    // Validate output (Read valid from Main reg. bank)
				c_write_main   <= 1;
				c_write_aux    <= 0;

				if(out_link.stop) begin
					c_next_state <= S_WRITE_AUX;
				end else begin
					c_next_state <= S_PROCESS;
				end
			end
			S_STALL: begin
				// Always stall upstream since we are stalled and can't accept any
				// new packets
				c_stop_upstream <= 1;

				// Contol Logic
				c_mux_sel_aux  <= 0;
				c_mux_sel_main <= 1;    // Invalidate Output
				c_write_main   <= 0;    // Disable Main reg.
				c_write_aux    <= 0;    // Disable Aux reg.

				if(out_link.stop) begin
					c_next_state <= S_STALL;
				end else begin
					c_next_state <= S_READ_AUX;
				end
			end
			default: begin
				//Should never get here, included to avoid latch inference
				c_stop_upstream <= 0;

				// Same control logic as process state
				c_mux_sel_aux  <= 0;
				c_mux_sel_main <= 0;
				c_write_main   <= 1;
				c_write_aux    <= 0;

				c_next_state <= S_PROCESS;
			end
		endcase
	end

	//FSM state update
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_curr_state <= S_PROCESS;
		end else begin
			r_curr_state <= c_next_state;
		end
	end

//
//	//FSM parameters & states
//	localparam 	C_STATE_BITS = 2;
//	localparam	[C_STATE_BITS-1:0]	S_PROCESS   = 2'b00,
//												S_WRITE_AUX = 2'b01,
//												S_READ_AUX  = 2'b10,
//												S_STALL     = 2'b11;
//
//	reg [C_STATE_BITS-1:0] r_curr_state;
//	reg [C_STATE_BITS-1:0] c_next_state;
//
//	//FSM outputs
//	reg c_write_main;
//	reg c_write_aux;
//	reg c_mux_sel_aux;
//	reg c_mux_sel_main;
//	reg c_stop_upstream;
//
//	//Registers
//	reg [WIDTH-1:0] r_data_main;
//	reg r_valid_main;
//	reg [WIDTH-1:0] r_data_aux;
//	reg r_valid_aux;
//
//	//Mux outputs
//	reg [WIDTH-1:0] c_data_mux;
//	reg c_valid_mux;
//	reg c_valid_main_mux;
//
//	//Aux register bank
//	initial begin
//		r_data_aux = {(WIDTH){1'b0}};
//		r_valid_aux = 1'b0;
//	end
//	always@(posedge clk) begin
//		if(c_write_aux) begin
//			r_data_aux <= in_link.data;
//			r_valid_aux <= in_link.valid;
//		end else begin
//			r_data_aux <= r_data_aux;
//			r_valid_aux <= r_valid_aux;
//		end
//	end
//
//	//Main register bank
//	initial begin
//		r_data_main  = {(WIDTH){1'b0}};
//		r_valid_main = 1'b0;
//	end
//	always@(posedge clk) begin
//		if(c_write_main) begin
//			r_data_main  <= c_data_mux;
//			r_valid_main <= c_valid_mux;
//		end else begin
//			r_data_main  <= r_data_main;
//			r_valid_main <= r_valid_main;
//		end
//	end
//
//	//Data mux
//	always@(*) begin
//		if(c_mux_sel_aux == 0) begin
//			c_data_mux <= in_link.data;
//			c_valid_mux <= in_link.valid;
//		end else begin
//			c_data_mux <= r_data_aux;
//			c_valid_mux <= r_valid_aux;
//		end
//	end
//
//	//Valid Main mux
//	always@(*) begin
//		if(c_mux_sel_main == 0) begin
//			c_valid_main_mux <= r_valid_main;
//		end else begin
//			c_valid_main_mux <= 1'b0;
//		end
//	end
//
//	assign out_link.data  = r_data_main;
//	assign out_link.valid = c_valid_main_mux;
//	assign in_link.stop = c_stop_upstream;
//
//	/*
//	 * Control FSM
//	 */
//
//	//FSM output logic
//	always@(*) begin
//		// NOTE: Combined MEALY and MOORE FSM
//		// c_stop_upstream is a MOORE output, so there is not combinational path through the FSM for it
//		// All other FSM outputs drive internal module structures that control the main output FFs
//		case(r_curr_state)
//			S_PROCESS: begin
//				// Never stall the upstream if processing
//				c_stop_upstream <= 0;
//
//				// Control Logic is the same regardless of input stop bit
//				c_mux_sel_aux  <= 0;
//				c_mux_sel_main <= 0;
//				c_write_main   <= 1;
//				c_write_aux    <= 0;
//
//				if (~out_link.stop) begin
//					c_next_state <= S_PROCESS;
//				end else begin
//					c_next_state <= S_WRITE_AUX;
//				end
//			end
//			S_WRITE_AUX: begin
//				// Always stall upstream since we are going into a stall and can't accept any
//				// new packets
//				c_stop_upstream <= 1;
//
//				if(out_link.stop) begin
//					c_mux_sel_aux  <= 0;
//					c_mux_sel_main <= 1;    // Invalidate output
//					c_write_main   <= 0;		// Store current value in main register
//					c_write_aux    <= 1;    // Store next value in aux register
//
//					c_next_state   <= S_STALL;
//				end else begin
//					// Keep the same control logic as Process and return to Process
//					// state immediately after
//					c_mux_sel_aux  <= 0;
//					c_mux_sel_main <= 0;
//					c_write_main   <= 1;
//					c_write_aux    <= 0;
//
//					c_next_state <= S_PROCESS;
//				end
//			end
//			S_READ_AUX: begin
//				// Returning back from stall so no need to stall upstream
//				c_stop_upstream <= 0;
//
//				// Control Logic
//				c_mux_sel_aux  <= 1;    // Read from aux
//				c_mux_sel_main <= 0;    // Validate output (Read valid from Main reg. bank)
//				c_write_main   <= 1;
//				c_write_aux    <= 0;
//
//				if(out_link.stop) begin
//					c_next_state <= S_WRITE_AUX;
//				end else begin
//					c_next_state <= S_PROCESS;
//				end
//			end
//			S_STALL: begin
//				// Always stall upstream since we are stalled and can't accept any
//				// new packets
//				c_stop_upstream <= 1;
//
//				// Contol Logic
//				c_mux_sel_aux  <= 0;
//				c_mux_sel_main <= 1;    // Invalidate Output
//				c_write_main   <= 0;    // Disable Main reg.
//				c_write_aux    <= 0;    // Disable Aux reg.
//
//				if(out_link.stop) begin
//					c_next_state <= S_STALL;
//				end else begin
//					c_next_state <= S_READ_AUX;
//				end
//			end
//			default: begin
//				//Should never get here, included to avoid latch inference
//				c_stop_upstream <= 0;
//
//				// Same control logic as process state
//				c_mux_sel_aux  <= 0;
//				c_mux_sel_main <= 0;
//				c_write_main   <= 1;
//				c_write_aux    <= 0;
//
//				c_next_state <= S_PROCESS;
//			end
//		endcase
//	end
//
//	//FSM state update
//	initial begin
//		r_curr_state = S_PROCESS;
//	end
//	always@(posedge clk) begin
//		r_curr_state <= c_next_state;
//	end

endmodule
