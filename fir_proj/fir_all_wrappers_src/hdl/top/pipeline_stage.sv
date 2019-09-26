module pipeline_stage #(
	/* Data Width:
	 * Data input/output bits */
	parameter DATA_WIDTH = 0,

	// Latency insenstive type ("non_li", "li_credit", "li_carloni" or "li_qsys")
	parameter INTERCONNECT_TYPE = ""

)(
	input clock,
	input reset,

	/* Sender Signals */
	input signed 	[DATA_WIDTH-1:0]	i_data,
	input i_valid,
	output o_li_feedback,

	/* Receiver Signals */
	output signed 	[DATA_WIDTH-1:0]	o_data,
	output o_valid,
	input i_li_feedback
);

	if (INTERCONNECT_TYPE  == "credit") begin

		initial $display("Using Credit Regs");

		credit_interconnect_reg #(
			.DATA_WIDTH(DATA_WIDTH)
		) credit_interconnect_reg_inst(
			.clock(clock),
			.i_valid(i_valid),
			.i_data(i_data),
			.o_increment_count(o_li_feedback),
			.o_valid(o_valid),
			.o_data(o_data),
			.i_increment_count(i_li_feedback)
		);

	end else if (INTERCONNECT_TYPE == "qsys") begin

		initial $display("Using Qsys Regs");

		qsys_pipline_reg #(
			.DATA_WIDTH(DATA_WIDTH)
		) qsys_pipline_reg_inst(
			.clock(clock),
			.i_valid(i_valid),
			.i_data(i_data),
			.o_ready(o_li_feedback),
			.o_valid(o_valid),
			.o_data(o_data),
			.i_ready(i_li_feedback)
		);

	end else if (INTERCONNECT_TYPE == "carloni") begin

		initial $display("Using Carloni Relay Stations");

		li_link #(.WIDTH(DATA_WIDTH)) input_link();
		assign input_link.data = i_data;
		assign input_link.valid = i_valid;
		assign o_li_feedback = input_link.stop;

		li_link #(.WIDTH(DATA_WIDTH)) output_link();
		assign o_data = output_link.data;
		assign o_valid = output_link.valid;
		assign output_link.stop = i_li_feedback;

		li_relay_station #(
			.WIDTH(DATA_WIDTH)
		) li_relay_station_inst (
			.clk(clock),
			.reset(reset),
			.in_link(input_link),
			.out_link(output_link)
		);

	end else if (INTERCONNECT_TYPE == "non-li") begin

		initial $display("Using Non-Li Regs");

		pipeline_reg #(
			.DATA_WIDTH(DATA_WIDTH-1)
		) pipeline_reg_inst (
			.clock(clock),
			.reset(reset),
			.i_valid(i_data[0]),
			.i_data(i_data[DATA_WIDTH - 1:1]),
			.o_valid(o_data[0]),
			.o_data(o_data[DATA_WIDTH - 1:1])
		);

	end

endmodule
