//Modified from the original (fpgacpu.ca/fpga/bram.html) by GateForge Consulting Ltd.

// Single Clock Dual Port RAM, (SCDPRAM)
// One write port and one read port, separately addressed, with common clock.

// Note: Add "no_rw_check" to RAMSTYLE inorder to specify that new data behaviour does not need to be infered

module scdpram_infer
#(
    parameter       WORD_WIDTH          = 16,
    parameter       ADDR_WIDTH          = 2,
    parameter       DEPTH               = 2**ADDR_WIDTH,
    parameter       RAMSTYLE            = "M20K", 	//M20K or MLAB
    parameter       READ_NEW_DATA       = 1			//behaviour of read durring writes to the same address
)
(
    input  wire                         clock,
    input  wire                         wren,
    input  wire     [ADDR_WIDTH-1:0]    write_addr,
    input  wire     [WORD_WIDTH-1:0]    write_data,
    input  wire                         rden,
    input  wire     [ADDR_WIDTH-1:0]    read_addr, 
    output reg      [WORD_WIDTH-1:0]    read_data
);

    initial begin
        read_data = 0;
    end

    (* ramstyle = RAMSTYLE *)
    reg [WORD_WIDTH-1:0] ram [DEPTH-1:0];

	genvar i;
	generate

//		//Initalize RAM
//		initial begin
//			for (i = 0; i < DEPTH; i++) begin
//				ram[i] = 0;
//			end
//		end

        // Returns OLD data
        if (READ_NEW_DATA == 0) begin
            always @(posedge clock) begin
                if(wren == 1) begin
                    ram[write_addr] <= write_data;
                end
                if(rden == 1) begin
                    read_data       <= ram[read_addr];
                end
            end
        end

        // Returns NEW data (non-blocking assignments)
        else begin
            always @(posedge clock) begin
                if(wren == 1) begin
                    ram[write_addr] = write_data;
                end
                if(rden == 1) begin
                    read_data  = ram[read_addr];
                end
            end
        end
    endgenerate

endmodule