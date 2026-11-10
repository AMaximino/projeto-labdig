onerror {quit -code 1}

vlib work
vmap work work
vlog -sv fpga/rtl/rfid_uart_rx.v
vlog -sv fpga/rtl/unidade_controle.v
vlog -sv fpga/testbench/semana3/rfid_uart_rx_semana3_tb.v
vlog -sv fpga/testbench/semana3/unidade_controle_semana3_tb.v

vsim work.rfid_uart_rx_semana3_tb
run -all
quit -sim

vsim work.unidade_controle_semana3_tb
run -all
quit -sim

quit -f
