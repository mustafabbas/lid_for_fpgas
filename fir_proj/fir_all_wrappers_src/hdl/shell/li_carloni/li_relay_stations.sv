module li_relay_stations #(
	parameter WIDTH = 6,
	parameter N_RELAY_STATIONS = 1
) (
	input clk,
	input reset,
	
	li_link.sink in_link,
	li_link.source out_link
	
);
	//Generate relay stations
	genvar i;
	generate 
	
		if(N_RELAY_STATIONS == 0) begin
				assign out_link.data = in_link.data;
				assign out_link.valid = in_link.valid;
				assign in_link.stop = out_link.stop;
		end else begin
			for(i = 0; i < N_RELAY_STATIONS; i = i + 1) begin : RELAY_STATION	
				li_link #(.WIDTH(WIDTH)) inter_link();
				
				if (i == 0) begin : FIRST
					li_relay_station #(.WIDTH(WIDTH)) rs_inst (
						.clk(clk),
						.reset(reset),
						.in_link(in_link),
						.out_link(inter_link)
					);
				end else begin : INTERMEDIATE_LAST
					li_relay_station #(.WIDTH(WIDTH)) rs_inst (
						.clk(clk),
						.reset(reset),
						.in_link(RELAY_STATION[i-1].inter_link),
						.out_link(inter_link)
					);
				end
			end
			//Connect the final Relay Station to the out link
			assign out_link.data = RELAY_STATION[N_RELAY_STATIONS-1].inter_link.data;
			assign out_link.valid = RELAY_STATION[N_RELAY_STATIONS-1].inter_link.valid;
			assign RELAY_STATION[N_RELAY_STATIONS-1].inter_link.stop = out_link.stop;
		end
	endgenerate
	
endmodule
