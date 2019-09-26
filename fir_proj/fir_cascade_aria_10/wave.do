onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fir_cascade_tb/dut/reset
add wave -noupdate /fir_cascade_tb/dut/i_top_data_valid
add wave -noupdate /fir_cascade_tb/dut/i_top_data_data
add wave -noupdate /fir_cascade_tb/dut/i_top_valid
add wave -noupdate /fir_cascade_tb/dut/o_top_stop
add wave -noupdate /fir_cascade_tb/dut/o_top_data_data
add wave -noupdate /fir_cascade_tb/dut/o_top_data_valid
add wave -noupdate /fir_cascade_tb/dut/o_top_valid
add wave -noupdate /fir_cascade_tb/dut/i_top_stop
add wave -noupdate /fir_cascade_tb/inwave
add wave -noupdate /fir_cascade_tb/outwave
add wave -noupdate -divider {FIFO[0]}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/WIDTH}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/ADDR}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/FIFO_ALMOST_FULL}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/TYPE}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/clk}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/reset}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/i_data}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/o_data}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/i_enq}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/i_deq}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/o_almost_full}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/my_almost_full}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/myusedw}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/o_full}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_valid_i_in_link_buf/input_fifo/o_empty}
add wave -noupdate -divider {li_in[0]}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_li_link/WIDTH}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_li_link/stop}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_li_link/valid}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/i_li_link/data}
add wave -noupdate -divider {li_out[0]}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/o_li_link/WIDTH}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/o_li_link/stop}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/o_li_link/valid}
add wave -noupdate {/fir_cascade_tb/dut/FIRs[0]/LI_FIRs/FIRST_STAGE_VALID/fir_inst/o_li_link/data}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {18177 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 141
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
WaveRestoreZoom {2992 ps} {43546 ps}
