interface li_link #(parameter WIDTH=16);
	logic stop;
	logic valid;
	logic [WIDTH-1:0] data;
	
	modport source (input stop, output valid, output data);
	modport sink (output stop, input valid, input data);
	
endinterface

