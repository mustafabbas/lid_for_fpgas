vlib work

vlog -novopt ../hdl/top/*.sv
vlog -novopt ../hdl/pearl/*.sv
vlog -novopt ../hdl/pearl/*.v
vlog -novopt ../hdl/pearl/stratix_10_dsp/*.v
vlog -novopt ../hdl/shell/li_carloni/*.sv
vlog -novopt ../hdl/shell/li_credit/*.sv
vlog -novopt ../hdl/shell/li_qsys/*.sv
vlog -novopt ../hdl/shell/non_li/*.sv
vlog -novopt testbench.sv

vsim work.testbench -L altera_mf_ver -L fourteennm_ver -L lpm_ver

do wave.do

run -a
