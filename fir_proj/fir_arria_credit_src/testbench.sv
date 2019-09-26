`timescale 1ps/1ps

module testbench();
localparam SIM_LEN = 200;
localparam RAND_INPUT = 0;
localparam POWER_EST = 0; //Toggle correctness test and power test
localparam DATA_WIDTH = 16;
localparam FIFO_ADDR = 4;
localparam N_CREDITS = 2**FIFO_ADDR;

logic signed [15:0] o_golden_out;   // Golden output you are trying to match.

/*
 * Module Signals
 */
logic clock;
logic reset;

//Signals to sender
logic i_top_data_valid;
logic signed [DATA_WIDTH-1:0] i_top_data_data;

logic i_valid;
logic o_increment_count;

//Signals from receiver
logic o_top_data_valid;
logic signed [DATA_WIDTH-1:0] o_top_data_data;

logic o_valid;
logic i_increment_count;

fir_cascade dut ( .* );

initial clock = '1;
//always #1960 clock = ~clock;  // 510.2 MHz clock
//always #2500 clock = ~clock; //400 MHz clock
always #5000 clock = ~clock; //200 MHz clock
//always #10000 clock = ~clock; //100 MHz clock

logic signed [DATA_WIDTH-1:0] inwave[SIM_LEN-1:0];
logic signed [15:0] outwave[SIM_LEN-1:0];

// Producer
initial begin
	integer f;
	integer num_credits = N_CREDITS -1;

	if(RAND_INPUT) begin
		 //Random input vector for power estimation
		 for (int i = 0; i < SIM_LEN; i++) begin
				inwave[i] = $urandom_range(20000,0);
		 end

	end else begin
		// Create known good input: a delta function, then a step function
		for (int i = 0; i < SIM_LEN; i++) begin
			if (i == 60 || i >= 120) 
				inwave[i] = 16'd20000;
			else
				inwave[i] = 16'd0;
//// simple test case: uncomment bellow
//			inwave[i] = i;
//			outwave[i] = i;
		end

	end

//// simple test case: comment out file loading
	// Load known good output
	f = $fopen("outdata4.txt", "r");
	for (int i = 0; i < SIM_LEN; i++) begin
		integer d;
		d = $fscanf(f, "%d", outwave[i]);
	end
	$fclose(f);

	i_top_data_valid = 1'b0;
	i_top_data_data = 16'd0;
	i_valid = 1'b0;

	//Infinite storage: Always ready to receive data
	i_increment_count = 1'b1;

	reset = 1'b1;
	@(negedge clock);
	reset = 1'b0;

	for (int i = 0; i < SIM_LEN; i++) begin
		@(negedge clock);
		num_credits = num_credits + o_increment_count;
		if(num_credits == 0) begin
			i--;
			i_top_data_valid = 1'b0;
			i_valid = 1'b0;
		end else begin
			i_top_data_data = inwave[i];
			i_top_data_valid = 1'b1;
			i_valid = 1'b1;
			num_credits = num_credits - 1;
		end
	end

	@(negedge clock);
	i_top_data_valid = 1'b0;
	i_valid = 1'b1;

end

// Consumer
initial begin
	static real rms = 0.0;

	o_golden_out = 16'b0;
	for (int i = 0; i < SIM_LEN; i++) begin
		real v1;
		real v2;
		real diff;

		// Wait for a valid output
		@(posedge clock);
		while (!o_top_data_valid || !o_valid) begin
			@(posedge clock);
		end

		//@(negedge clock);  // Give time for o_out to be updated.
		v1 = real'(o_top_data_data);
		o_golden_out = outwave[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);

		rms += diff*diff;
		$display("diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
	end

	rms /= SIM_LEN;
	rms = rms ** (0.5);

	$display("RMS Error: %f", rms);
	if (rms > 0) begin
		$display("Average RMS Error is above 0 units (on a scale to 32,000) - something is probably wrong");
	end
	else begin
		$display("Error is within  units (on a scale to 32,000) - great success!!");
	end

	$stop(0);
end

endmodule