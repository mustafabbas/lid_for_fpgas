// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  dsp_2mac_no_chainin  (
            ax,
            ay,
            bx,
            by,
            clk,
            aclr,
            ena,
            chainout,
            resulta);

            input [16:0] ax;
            input [15:0] ay;
            input [16:0] bx;
            input [15:0] by;
            input [2:0] clk;
            input  aclr;
            input [2:0] ena;
            output [63:0] chainout;
            output [43:0] resulta;

            wire [63:0] sub_wire0;
            wire [43:0] sub_wire1;
            wire [63:0] chainout = sub_wire0[63:0];    
            wire [43:0] resulta = sub_wire1[43:0];    

            fourteennm_mac        fourteennm_mac_component (
                                        .ax (ax),
                                        .ay (ay),
                                        .bx (bx),
                                        .by (by),
                                        .clk (clk),
                                        .clr ({1'b0,aclr}),
                                        .ena (ena),
                                        .chainout (sub_wire0),
                                        .resulta (sub_wire1));
            defparam

					fourteennm_mac_component.ax_clock="0",
					fourteennm_mac_component.ay_scan_in_clock="0",
					fourteennm_mac_component.az_clock="none",
					fourteennm_mac_component.output_clock="0",
					fourteennm_mac_component.bx_clock="0",
					fourteennm_mac_component.accumulate_clock="none",
					fourteennm_mac_component.accum_pipeline_clock="none",
					fourteennm_mac_component.bz_clock="none",
					fourteennm_mac_component.by_clock="0",
					fourteennm_mac_component.coef_sel_a_clock="none",
					fourteennm_mac_component.coef_sel_b_clock="none",
					fourteennm_mac_component.sub_clock="none",
					fourteennm_mac_component.negate_clock="none",
					fourteennm_mac_component.accum_2nd_pipeline_clock="none",
					fourteennm_mac_component.load_const_clock="none",
					fourteennm_mac_component.load_const_pipeline_clock="none",
					fourteennm_mac_component.load_const_2nd_pipeline_clock="none",
					fourteennm_mac_component.input_pipeline_clock="0",
					fourteennm_mac_component.second_pipeline_clock="0",
					fourteennm_mac_component.input_systolic_clock="none",
					fourteennm_mac_component.preadder_subtract_a = "false", 
					fourteennm_mac_component.preadder_subtract_b = "false", 
					fourteennm_mac_component.delay_scan_out_ay = "false", 
					fourteennm_mac_component.delay_scan_out_by = "false", 
					fourteennm_mac_component.ay_use_scan_in = "false", 
					fourteennm_mac_component.by_use_scan_in = "false", 
					fourteennm_mac_component.operand_source_may = "input", 
					fourteennm_mac_component.operand_source_mby = "input", 
					fourteennm_mac_component.operand_source_max = "input", 
					fourteennm_mac_component.operand_source_mbx = "input", 
					fourteennm_mac_component.signed_max = "true", 
					fourteennm_mac_component.signed_may = "true", 
					fourteennm_mac_component.signed_mbx = "true", 
					fourteennm_mac_component.signed_mby = "true", 
					fourteennm_mac_component.use_chainadder = "false", 
					fourteennm_mac_component.enable_double_accum = "false", 
					fourteennm_mac_component.operation_mode = "m18x18_sumof2", 
					fourteennm_mac_component.clear_type = "aclr",
					fourteennm_mac_component.ax_width = 17,
					fourteennm_mac_component.bx_width = 17,
					fourteennm_mac_component.ay_scan_in_width = 16,
					fourteennm_mac_component.by_width = 16,
					fourteennm_mac_component.result_a_width = 44,
					fourteennm_mac_component.load_const_value = 0,
					fourteennm_mac_component.coef_a_0 = 0,
					fourteennm_mac_component.coef_a_1 = 0,
					fourteennm_mac_component.coef_a_2 = 0,
					fourteennm_mac_component.coef_a_3 = 0,
					fourteennm_mac_component.coef_a_4 = 0,
					fourteennm_mac_component.coef_a_5 = 0,
					fourteennm_mac_component.coef_a_6 = 0,
					fourteennm_mac_component.coef_a_7 = 0,
					fourteennm_mac_component.coef_b_0 = 0,
					fourteennm_mac_component.coef_b_1 = 0,
					fourteennm_mac_component.coef_b_2 = 0,
					fourteennm_mac_component.coef_b_3 = 0,
					fourteennm_mac_component.coef_b_4 = 0,
					fourteennm_mac_component.coef_b_5 = 0,
					fourteennm_mac_component.coef_b_6 = 0,
					fourteennm_mac_component.coef_b_7 = 0;

endmodule

