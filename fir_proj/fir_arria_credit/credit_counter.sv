module credit_counter
#(
    parameter	N_CREDITS = 10
)
(
	input		clock,
	input		reset,

	// Pearl Fire logic
	output	o_ready,
	input		i_fifo_empty,

	// Control Signals
	input		i_increment_count,
	output	o_valid
);

// Fix this: credit count is not a signed number so this will never happen
//	//debug 
//	always @(posedge clock) begin
//		if(credit_count < 0) begin
//			$error("credit_count = %d", credit_count, "cannot be negtive");
//		end
//	end

	localparam COUNTER_WIDTH = $clog2(N_CREDITS) + 1;

	reg [COUNTER_WIDTH-1:0] r_credit_count;

	always @ (posedge clock) begin
		if(reset) begin
			r_credit_count <= N_CREDITS;
		end else begin

			if ((!i_fifo_empty) && (credit_count != 0)) begin
				r_credit_count = credit_count - 1;
			end 
			if (i_increment_count) begin
				r_credit_count = credit_count + 1;
			end

		end
	end

	reg r_ready;
	reg r_valid;

	always @ (posedge clock) begin
		if(reset) begin
			r_ready <= 1'b0;
			r_valid <= 1'b0;
		end else begin
			r_ready <= (r_credit_count != 0);
			r_valid <= (!i_fifo_empty) & (r_credit_count != 0);
		end
	end

	// assuming a ready_latency of 0
	assign o_ready = r_ready;
	assign o_valid = r_valid;

endmodule