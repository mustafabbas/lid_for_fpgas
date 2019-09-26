`timescale 1ps/1ps

module fir_cascade_tb();
localparam SIM_LEN = 200;
localparam RAND_INPUT = 0;
localparam MAKE_GOLDEN = 0;
localparam POWER_EST = 0; //Toggle correctness test and power test
localparam N_RELAY_STATIONS = 0;
localparam ROUND_TRIP_LATENCY = (2* N_RELAY_STATIONS);

//logic signed [15:0] i_in;
//logic signed [15:0] o_out;
//logic i_valid;
//logic o_valid;
logic signed [15:0] o_golden_out;   // Golden output you are trying to match.
logic clock;
logic reset;

logic i_top_valid;

logic signed [15:0] i_top_data_data;
logic i_top_data_valid;
logic o_top_stop;

logic o_top_valid;

logic signed[15:0] o_top_data_data;
logic o_top_data_valid;
logic i_top_stop;


fir_cascade dut ( .* );


initial clk = '1;
//always #1960 clk = ~clk;  // 510.2 MHz clock
//always #2500 clk = ~clk; //400 MHz clock
always #5000 clk = ~clk; //200 MHz clock
//always #10000 clk = ~clk; //100 MHz clock

logic signed [15:0] inwave[SIM_LEN-1:0];
logic signed [15:0] outwave[SIM_LEN-1:0];


// Producer
initial begin
	integer f;
	integer k;
	integer j;

	if(RAND_INPUT) begin
		 //Random input vector for power estimation
		 for (int i = 0; i < SIM_LEN; i++) begin
					inwave[i] = $urandom_range(20000,0);
		 end

	end else begin
		// Create known good input: a delta function, then a step function
		for (int i = 0; i < SIM_LEN; i++) begin
//			if (i == 60 || i >= 120) 
//				inwave[i] = 16'd20000;
//			else
//				inwave[i] = 16'd0;
// simple test case: uncomment bellow
			inwave[i] = i;
			outwave[i] = i;
		end

	end

//// simple test case: comment out file loading
//	// Load known good output
//	f = $fopen("outdata2.txt", "r");
//	for (int i = 0; i < SIM_LEN; i++) begin
//		integer d;
//		d = $fscanf(f, "%d", outwave[i]);
//	end
//	$fclose(f);

	i_top_valid = 1'b0;
	i_top_data_data = 'd0;
	i_top_data_valid = 1'b0;
	i_top_stop = 1'b0;
	
	reset = 1'b1;
	@(negedge clk);
	reset = 1'b0;	
	
	k = 0;
	j = 0;
	for (int i = 0; i < SIM_LEN; i++) begin
		@(negedge clk);

		//Stall
		if ($urandom_range(1,0)) begin//k > 10 && k < 20) begin
			i_top_stop = 1'b1;
		end else begin
			i_top_stop = 1'b0;
		end
		k++;

		if(o_top_stop) begin
			if(j == ROUND_TRIP_LATENCY) begin
				i--;
				i_top_valid = 1'b0;
			end else begin
				j++;
				if($urandom_range(1,0)) begin
					i_top_data_data = 0;
					i_top_data_valid = 1'b1;
					i_top_valid = 1'b0;
					i--;
				end else begin
					i_top_data_data = inwave[i];
					i_top_data_valid = 1'b1;
					i_top_valid = 1'b1;
				end
			end
		end else begin
			if(j > 0) begin
				j--;
			end
			if($urandom_range(1,0)) begin
				i_top_data_data = 0;
				i_top_data_valid = 1'b1;
				i_top_valid = 1'b0;
				i--;
			end else begin
				i_top_data_data = inwave[i];
				i_top_data_valid = 1'b1;
				i_top_valid = 1'b1;
			end
		end
	end
	
	@(negedge clk);
	i_top_valid = 1'b1; // remain valid to gather results that have big latencies
	i_top_data_valid = 1'b0;
	i_top_stop = 1'b0;
	
end

// Consumer
initial begin
	static real rms = 0.0;
	integer f;
	
	if (MAKE_GOLDEN) begin
		f = $fopen("outdata.txt", "w");
	end
	
	o_golden_out = 16'b0;
	for (int i = 0; i < SIM_LEN; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!o_top_valid || !o_top_data_valid) begin
			@(posedge clk);
			//$display("diff %f %f %d", o_top_data_valid, o_top_valid, o_top_data_data);
		end
		//$display("diff %f %f %d", o_top_data_valid, o_top_valid, o_top_data_data);
		
		if (MAKE_GOLDEN) begin
			$fdisplay(f, "%d", o_top_data_data);
		end
		
		//@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_top_data_data);
		o_golden_out = outwave[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		$display("diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
	end
	
	if (MAKE_GOLDEN) begin
		$fclose(f);
		$stop(0);
	end
	
	rms /= SIM_LEN;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 0) begin
		$display("Average RMS Error is above 0 units (on a scale to 32,000) - something is probably wrong");
	end
	else begin
		$display("Error is within 0 units (on a scale to 32,000) - great success!!");
	end
	
	$stop(0);
end

endmodule
