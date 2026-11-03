onerror {quit -code 1}

vlib work
vmap work work
vlog -sv circuito/*.v
vlog -sv fpga/testbench/processador_acao_tb.v
vlog -sv fpga/testbench/telemetria_uart_tb.v
vlog -sv fpga/testbench/unidade_controle_moore_tb.v

vsim work.processador_acao_tb
run -all
quit -sim

vsim work.telemetria_uart_tb
run -all
quit -sim

vsim work.unidade_controle_moore_tb
run -all
quit -sim

quit -f
