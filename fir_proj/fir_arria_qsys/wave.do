onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/dut/clock
add wave -noupdate /testbench/dut/reset
add wave -noupdate /testbench/dut/i_top_data_valid
add wave -noupdate /testbench/dut/i_top_data_data
add wave -noupdate /testbench/dut/i_valid
add wave -noupdate /testbench/dut/o_ready
add wave -noupdate /testbench/dut/o_top_data_valid
add wave -noupdate /testbench/dut/o_top_data_data
add wave -noupdate /testbench/dut/o_valid
add wave -noupdate /testbench/dut/i_ready
add wave -noupdate -divider {FIFO 0}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/o_almost_full}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/my_almost_full}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/genblk1/fifo_inst/almost_full_value}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/genblk1/fifo_inst/full}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_inst/genblk1/fifo_inst/usedw}
add wave -noupdate -divider {Valid 0}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/valid_logic_inst/i_ready}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/valid_logic_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/valid_logic_inst/o_valid}
add wave -noupdate -divider {FIFO logic 0}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_logic_inst/i_ready}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -divider {FIR 0}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fir_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[0]/FIRST/qsys_wrapper_inst/fir_inst/o_out}
add wave -noupdate -divider {FIFO 1}
add wave -noupdate -radix decimal {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/i_data}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/o_data}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/i_enq}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/i_deq}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/o_empty}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/o_almost_full}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/my_almost_full}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/genblk1/fifo_inst/full}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_inst/genblk1/fifo_inst/usedw}
add wave -noupdate -divider {Valid 1}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/valid_logic_inst/i_ready}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/valid_logic_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/valid_logic_inst/o_valid}
add wave -noupdate -divider {FIFO logic 1}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_logic_inst/i_ready}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_logic_inst/i_empty}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_logic_inst/o_read_request}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fifo_logic_inst/o_valid}
add wave -noupdate -divider {fir 1}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fir_inst/clk_ena}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fir_inst/i_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fir_inst/i_in}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fir_inst/o_valid}
add wave -noupdate {/testbench/dut/FIR[1]/INTERMEDIATE_LAST/qsys_wrapper_inst/fir_inst/o_out}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
WaveRestoreZoom {0 ps} {439361 ps}
