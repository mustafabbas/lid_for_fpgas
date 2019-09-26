onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/o_golden_out
add wave -noupdate /testbench/clock
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/i_top_data_valid
add wave -noupdate /testbench/i_top_data_data
add wave -noupdate /testbench/i_valid
add wave -noupdate /testbench/o_increment_count
add wave -noupdate /testbench/o_top_data_valid
add wave -noupdate /testbench/o_top_data_data
add wave -noupdate /testbench/o_valid
add wave -noupdate /testbench/dut/o_increment_count
add wave -noupdate -divider credit1
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/credit_counter_inst/o_ready}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/credit_counter_inst/i_fifo_empty}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/credit_counter_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/credit_counter_inst/o_valid}
add wave -noupdate -radix unsigned {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/credit_counter_inst/credit_count}
add wave -noupdate -divider fifo_logic1
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_logic_inst/o_increment_count}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_logic_inst/i_credit_ready}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate -divider fifo1
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_inst/genblk1/fifo_inst/full}
add wave -noupdate -divider fir1
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fir_inst/o_valid}
add wave -noupdate -radix decimal {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fir_inst/o_out}
add wave -noupdate -divider interconnect
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/credit_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -radix decimal {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_data}
add wave -noupdate -radix decimal {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_increment_count}
add wave -noupdate -divider fifo_logic2
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_increment_count}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_credit_ready}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -divider fifo2
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/genblk1/fifo_inst/full}
add wave -noupdate -divider fir2
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_out}
add wave -noupdate -divider counter2
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/o_ready}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_fifo_empty}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/o_valid}
add wave -noupdate -radix unsigned {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/credit_count}
add wave -noupdate -divider interconnect2
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_increment_count}
add wave -noupdate -divider fifo_logic3
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_increment_count}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_credit_ready}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -divider fifo3
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/genblk1/fifo_inst/full}
add wave -noupdate -divider fir3
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_out}
add wave -noupdate -divider credit3
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/o_ready}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_fifo_empty}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/o_valid}
add wave -noupdate -radix unsigned {/testbench/dut/FIR[2]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/credit_count}
add wave -noupdate -divider interconnect4
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_interconnect_regs_inst/o_increment_count}
add wave -noupdate -divider fifo_logic4
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_data}
add wave -noupdate -radix binary {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate -divider fifo4
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_increment_count}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_credit_ready}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -divider fir4
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/fir_inst/o_out}
add wave -noupdate -divider credit4
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_fifo_empty}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/i_increment_count}
add wave -noupdate {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/o_valid}
add wave -noupdate -radix unsigned {/testbench/dut/FIR[3]/INTERMEDIATE_LAST/credit_wrapper_inst/credit_counter_inst/credit_count}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {972938 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 184
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {794460 ps} {1041317 ps}
