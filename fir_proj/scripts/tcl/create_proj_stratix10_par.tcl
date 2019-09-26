if {$argc < 2} {
    puts "usage quartus_sh -t <tcl_execuable> <project_dir/top_module_name> <top_module_name>"
    qexit -error
}

puts "project_new [lindex $argv 0] -overwrite"
set project [lindex $argv 0]
project_new $project -overwrite

# Assignments begin
set_global_assignment -name FAMILY "Stratix 10"
set_global_assignment -name DEVICE 1SX165HU3F50E1VG
set_global_assignment -name TOP_LEVEL_ENTITY fir_cascade
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 17.1.0
set_global_assignment -name PROJECT_CREATION_TIME_DATE "16:29:35  NOVEMBER 28, 2017"
set_global_assignment -name LAST_QUARTUS_VERSION "17.1.0 Pro Edition"
set_instance_assignment -name VIRTUAL_PIN ON -to i_* -entity fir_cascade
set_instance_assignment -name VIRTUAL_PIN ON -to o_* -entity fir_cascade
set_instance_assignment -name VIRTUAL_PIN ON -to reset -entity fir_cascade
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE FASTEST
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (Verilog)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name NUM_PARALLEL_PROCESSORS 1
set_global_assignment -name OPTIMIZE_TIMING "NORMAL COMPILATION"
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF
set_global_assignment -name SDC_FILE fir_cascade.sdc

set_global_assignment -name SYSTEMVERILOG_FILE hdl/top/interconnect_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/top/pipeline_stage.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/non_li/pipeline_reg.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_interconnect_reg.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_pipline_reg.sv
set_global_assignment -name VERILOG_FILE hdl/pearl/stratix_10_dsp/dsp_2mac_no_chainout.v
set_global_assignment -name VERILOG_FILE hdl/pearl/stratix_10_dsp/dsp_2mac_no_chainin.v
set_global_assignment -name VERILOG_FILE hdl/pearl/stratix_10_dsp/dsp_2mac.v
set_global_assignment -name SYSTEMVERILOG_FILE hdl/top/fir_cascade.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/non_li/pipeline_regs.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_valid_logic.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_scdpram_infer.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_pipline_regs.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_fifo_logic.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_qsys/qsys_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_scdpram_infer.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_interconnect_regs.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_fifo_logic.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_credit/credit_counter.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_scdpram_infer.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_relay_stations.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_relay_station.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_interface.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_input_buffer.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_fir_wrapper_pipelined_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/shell/li_carloni/li_fifo.sv
set_global_assignment -name VERILOG_FILE hdl/pearl/output_adder.v
set_global_assignment -name VERILOG_FILE hdl/pearl/input_adder.v
set_global_assignment -name SYSTEMVERILOG_FILE hdl/pearl/fir.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/top/wrapper_gen.sv

set_instance_assignment -name PARTITION wrapper_gen -to FIRs[0].FIRST.wrapper_inst -entity fir_cascade
set_instance_assignment -name PARTITION_COLOUR 4292804519 -to FIRs[0].FIRST.wrapper_inst -entity fir_cascade
set_instance_assignment -name PARTITION wrapper_gen_1 -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst -entity fir_cascade
set_instance_assignment -name PARTITION_COLOUR 4294947544 -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst -entity fir_cascade
set_instance_assignment -name PLACE_REGION "X241 Y420 X274 Y432" -to FIRs[0].FIRST.wrapper_inst
set_instance_assignment -name RESERVE_PLACE_REGION OFF -to FIRs[0].FIRST.wrapper_inst
set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to FIRs[0].FIRST.wrapper_inst
set_instance_assignment -name REGION_NAME wrapper_gen -to FIRs[0].FIRST.wrapper_inst
set_instance_assignment -name PLACE_REGION "X4 Y1 X37 Y13" -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst
set_instance_assignment -name RESERVE_PLACE_REGION OFF -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst
set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst
set_instance_assignment -name REGION_NAME wrapper_gen_1 -to FIRs[1].INTERMEDIATE_LAST.wrapper_inst
# Assignments end

# Run Analysis and Synthesis
load_package flow
if {[catch {execute_module -tool map} result]} {
    puts "\nResult: $result\n"
    puts "ERROR: Analysis & Synthesis failed. See the report file.\n"
} else {
    puts "\nINFO: Analysis & Synthesis was successful.\n"
}

project_close

