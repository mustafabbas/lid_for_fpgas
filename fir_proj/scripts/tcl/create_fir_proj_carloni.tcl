if {$argc < 2} {
    puts "usage quartus_sh -t <tcl_execuable> <project_dir/top_module_name> <top_module_name>"
    qexit -error
}

puts "project_new [lindex $argv 0] -overwrite"
set project [lindex $argv 0]
project_new $project -overwrite

# Assignments begin
set_global_assignment -name FAMILY "Arria 10"
set_global_assignment -name DEVICE 10AS066H1F34E1SG
set_global_assignment -name TOP_LEVEL_ENTITY fir_cascade
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 4
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (SystemVerilog)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "SYSTEMVERILOG HDL" -section_id eda_simulation
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE FASTEST
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name NUM_PARALLEL_PROCESSORS 1
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
set_global_assignment -name OPTIMIZE_TIMING "NORMAL COMPILATION"
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_instance_assignment -name VIRTUAL_PIN ON -to i_*
set_instance_assignment -name VIRTUAL_PIN ON -to o_*
set_instance_assignment -name VIRTUAL_PIN ON -to reset
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
set_global_assignment -name SEED 5
set_global_assignment -name SDC_FILE fir_cascade.sdc
set_global_assignment -name VERILOG_FILE ip/fir/hdl/input_adder/input_adder.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/output_adder/output_adder.v
set_global_assignment -name SYSTEMVERILOG_FILE ip/fir/hdl/adder_tree.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_free_word_count_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_almost_full_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_pipelined_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_opt.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_relay_stations.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_relay_station.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/scdpram_infer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_interface.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_input_buffer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/fir/hdl/fir.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/fir_cascade.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/pipeline_regs.sv
set_global_assignment -name VERILOG_FILE ip/fir/hdl/dsp_2mac_no_chainout.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/dsp_2mac_no_chainin.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/dsp2_mac.v
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF
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

