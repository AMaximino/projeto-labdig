onerror {quit -code 1}

# Simulações da semana 3 (cenários 1 a 7 do relatório).
# Executar a partir da raiz do repositório:
#   vsim -c -do fpga/testbench/semana3/run_semana3.do

vlib work
vmap work work
vlog -sv fpga/rtl/*.v
vlog -sv fpga/testbench/semana3/unidade_controle_semana3_tb.v
vlog -sv fpga/testbench/semana3/rfid_uart_rx_semana3_tb.v
vlog -sv fpga/testbench/processador_acao_tb.v
vlog -sv fpga/testbench/seletor_item_telemetria_tb.v

# Cenários 1 a 4: unidade de controle
vsim -onfinish stop work.unidade_controle_semana3_tb
run -all
quit -sim

# Cenário 5: recepção do comando RFID
vsim -onfinish stop work.rfid_uart_rx_semana3_tb
run -all
quit -sim

# Cenário 6: compra sem saldo e item repetido
vsim -onfinish stop work.processador_acao_tb
run -all
quit -sim

# Cenário 7: evento do seletor de item
vsim -onfinish stop work.seletor_item_telemetria_tb
run -all
quit -sim

quit -f
