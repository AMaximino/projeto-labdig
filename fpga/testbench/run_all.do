onerror {quit -code 1}

vlib work
vmap work work
vlog -sv fpga/rtl/*.v
vlog -sv fpga/testbench/processador_acao_tb.v
vlog -sv fpga/testbench/telemetria_uart_tb.v
vlog -sv fpga/testbench/rfid_uart_rx_tb.v
vlog -sv fpga/testbench/unidade_controle_moore_tb.v
vlog -sv fpga/testbench/seletor_item_telemetria_tb.v

vsim work.processador_acao_tb
run -all
quit -sim

vsim work.telemetria_uart_tb
run -all
quit -sim

vsim work.rfid_uart_rx_tb
run -all
quit -sim

vsim work.unidade_controle_moore_tb
run -all
quit -sim

vsim work.seletor_item_telemetria_tb
run -all
quit -sim

quit -f
