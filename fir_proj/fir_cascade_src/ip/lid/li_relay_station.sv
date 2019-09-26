 module li_relay_station #(
	parameter WIDTH = 6
) (
	input clk,
	input reset,
	
	li_link.sink in_link,
	li_link.source out_link
);

	//FSM parameters & states
	localparam 	C_STATE_BITS = 1;
	localparam	[C_STATE_BITS-1:0]	S_PROCESS = 0,
												S_STALL = 1;
	
	reg [C_STATE_BITS-1:0] r_curr_state;
	reg [C_STATE_BITS-1:0] c_next_state;
	
	//FSM outputs
	reg c_write_main;
	reg c_write_aux;
	reg c_mux_sel;
	reg c_stop_upstream;
	
	//Registers
	reg [WIDTH-1:0] r_data_main;
	reg [WIDTH-1:0] r_data_aux;
	reg r_valid;
	
	//Mux outputs
	reg [WIDTH-1:0] c_data_mux;
	reg c_valid_mux;
	

	//Aux register bank
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_data_aux <= {(WIDTH){1'b0}};
		end else begin
			if(c_write_aux) begin
				r_data_aux <= in_link.data;
			end else begin
				r_data_aux <= r_data_aux;
			end
		end
	end
	
	//Data mux
	always@(*) begin
		if(c_mux_sel == 0) begin
			c_data_mux <= in_link.data;
		end else begin
			c_data_mux <= r_data_aux;
		end
	end
	
	//Valid mux
	always@(*) begin
		if(c_mux_sel == 0) begin
			c_valid_mux <= in_link.valid;
		end else begin
			c_valid_mux <= 1;
		end
	end
	
	//Main register bank
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_data_main <= {(WIDTH){1'b0}};
			r_valid <= 0;
		end else begin
			if(c_write_main) begin
				r_data_main <= c_data_mux;
				r_valid<= c_valid_mux;
			end else begin
				r_data_main <= r_data_main;
				r_valid <= r_valid;
			end
		end
	end
	
	assign out_link.data  = r_data_main;
	assign out_link.valid = r_valid;
	assign in_link.stop = c_stop_upstream;
	
	/*
	 * Control FSM
	 */
	 
	//FSM output logic
	always@(*) begin
		//NOTE: 	combined MEALY and MOORE FSM
		// c_stop_upstream is a MOORE output, so there is not combinational path through the FSM for it
		// All other FSM outputs drive internal module structures that control the main output FFs
		case(r_curr_state)
			S_PROCESS: begin
				//Never stall the upstream if processing
				c_stop_upstream <= 0;

				if (~out_link.stop | (in_link.valid & ~out_link.valid)) begin
					//Accept new packets if either condition is true:
					//    a) Down stream has room (!Stop)
					//    b) Downstream has NO room, but current output is invalid, 
					//       and input is valid, i.e. overwrite the current invalid packet [optimization]
					c_mux_sel <= 0;
					c_write_main <= 1;
					c_write_aux <= 0;
				end else if(out_link.stop & ~in_link.valid) begin
					//Drop void packets if stalled [optimization]
					c_mux_sel <= 0;
					c_write_main <= 0;
					c_write_aux <= 0;
				end else if (out_link.stop & in_link.valid & out_link.valid) begin
					//Transition to Stall
					//  Write the incoming packet to the AUX register
					c_mux_sel <= 0;
					c_write_main <= 0;
					c_write_aux <= 1;
				end else begin
					//Should never get here, included to avoid latch inference
					c_mux_sel <= 0;
					c_write_main <= 0;
					c_write_aux <= 0;
				end
			end
			S_STALL: begin
				//Always stall upstream since we are stalled and can't accept any
				// new packets
				c_stop_upstream <= 1;
				
				if(out_link.stop) begin
					//Stalled don't do anything
					c_mux_sel <= 0;
					c_write_main <= 0;
					c_write_aux <= 0;
				end else begin
					//Transitioning out of stall,
					// Feed AUX into MAIN reg
					c_mux_sel <= 1;
					c_write_main <= 1;
					c_write_aux <= 0;				
				end
			end
			default: begin
				c_mux_sel <= 0;
				c_write_main <= 1;
				c_write_aux <= 0;
			end
		endcase
	end
	
	
	//FSM next state logic
	always@(*) begin
		case(r_curr_state)
			S_PROCESS: begin
				if (~out_link.stop | (in_link.valid & ~out_link.valid)) begin
					//Down stream can accept the packet or [Optimization] we can
					// overwrite the current invalid packet
					c_next_state <= S_PROCESS;
				end else if(out_link.stop & ~in_link.valid) begin
					//[Optimization] We can drop void packets if the downstream module requests a stop
					c_next_state <= S_PROCESS;
				end else if (out_link.stop & in_link.valid & out_link.valid) begin
					//Transition to stall
					c_next_state <= S_STALL;
				end else begin
					//Should never get here, included to avoid latch inference
					c_next_state <= S_PROCESS;
				end
			end
			S_STALL: begin
				if(out_link.stop) begin
					//Still stalled
					c_next_state <= S_STALL;
				end else begin
					//Transition out of stall
					c_next_state <= S_PROCESS;
				end
			end
			default: begin
				c_next_state <= S_PROCESS;
			end
		endcase
	end
												
	//FSM state update
	always@(posedge clk or posedge reset) begin
		if(reset)
			r_curr_state <= S_PROCESS;
		else
			r_curr_state <= c_next_state;
	end
	
endmodule
