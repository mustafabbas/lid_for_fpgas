vlib work
vlog -novopt *.sv *.v
vsim work.testbench -L altera_mf_ver -L twentynm_ver -L lpm_ver
do wave.do
run -a
