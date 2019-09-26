if {$argc < 2} {
    puts "usage quartus_sh -t <tcl_execuable> <project_dir/top_module_name> <top_module_name>"
    qexit -error
}

puts "project_new [lindex $argv 0] -overwrite"
set project [lindex $argv 0]
project_new $project -overwrite

# Assignments begin
set_global_assignment -name FAMILY "Stratix IV"
set_global_assignment -name DEVICE EP4SGX230DF29C2X
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 12.0
set_global_assignment -name PROJECT_CREATION_TIME_DATE "13:55:25  MAY 24, 2013"
set_global_assignment -name LAST_QUARTUS_VERSION "17.0.0 Standard Edition"
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (SystemVerilog)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "SYSTEMVERILOG HDL" -section_id eda_simulation
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_global_assignment -name NUM_PARALLEL_PROCESSORS 1
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "2.5 V"
set_global_assignment -name EDA_TEST_BENCH_ENABLE_STATUS TEST_BENCH_MODE -section_id eda_simulation
set_global_assignment -name EDA_NATIVELINK_SIMULATION_TEST_BENCH fir_cascade_tb -section_id eda_simulation
set_global_assignment -name EDA_TEST_BENCH_NAME fir_cascade_tb -section_id eda_simulation
set_global_assignment -name EDA_DESIGN_INSTANCE_NAME NA -section_id fir_cascade_tb
set_global_assignment -name EDA_TEST_BENCH_MODULE_NAME fir_cascade_tb -section_id fir_cascade_tb
set_global_assignment -name EDA_NATIVELINK_SIMULATION_SETUP_SCRIPT sim.do -section_id eda_simulation
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name SYNTH_GATED_CLOCK_CONVERSION ON
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING OFF
set_global_assignment -name SEED 3
set_global_assignment -name OPTIMIZE_TIMING "NORMAL COMPILATION"
set_global_assignment -name INI_VARS "qatm_force_vqm=on;vqmo_gen_sivgx_vqm=on"
set_global_assignment -name EDA_TEST_BENCH_FILE fir_cascade_tb.sv -section_id fir_cascade_tb
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_free_word_count_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_almost_full_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_pipelined_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper_opt.sv
set_global_assignment -name SDC_FILE fir_cascade.sdc
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_relay_stations.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_relay_station.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/scdpram_infer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/fifo_dpram_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_fir_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_interface.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/lid/li_input_buffer.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/fir_cascade_tb.sv
set_global_assignment -name VERILOG_FILE ip/fir/hdl/dsp_4mult_add/dsp_4mult_add.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/dsp_2mult_add/dsp_2mult_add.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/output_adder/output_adder.v
set_global_assignment -name VERILOG_FILE ip/fir/hdl/input_adder/input_adder.v
set_global_assignment -name SYSTEMVERILOG_FILE ip/fir/hdl/adder_tree.sv
set_global_assignment -name SYSTEMVERILOG_FILE ip/fir/hdl/fir.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/fir_cascade.sv
set_global_assignment -name SYSTEMVERILOG_FILE hdl/pipeline_regs.sv
set_instance_assignment -name VIRTUAL_PIN ON -to i_*
set_instance_assignment -name VIRTUAL_PIN ON -to o_*
set_instance_assignment -name VIRTUAL_PIN ON -to reset
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
# Assignments end

load_package flow
if {[catch {execute_flow -compile} result]} {
    puts "\nResult: $result\n"
    puts "ERROR: Compilation failed. See report files.\n"
} else {
    puts "\nINFO: Compilation was successful.\n"
}

project_close	

