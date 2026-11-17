onerror {quit -code 1}

# Simulações da semana 4 (cenários 8 e 10 do relatório).
# Executar a partir da raiz do repositório:
#   vsim -c -do fpga/testbench/semana4/run_semana4.do
# Para ver as formas de onda do cenário 10 no ModelSim:
#   vsim -do fpga/testbench/semana4/wave_semana4.do

vlib work
vmap work work
vlog -sv fpga/rtl/*.v
vlog -sv fpga/testbench/processador_acao_tb.v
vlog -sv fpga/testbench/rfid_uart_rx_tb.v
vlog -sv fpga/testbench/telemetria_uart_tb.v
vlog -sv fpga/testbench/unidade_controle_moore_tb.v
vlog -sv fpga/testbench/seletor_item_telemetria_tb.v
vlog -sv fpga/testbench/circuito_jogo_financeiro_tb1.v
vlog -sv fpga/testbench/semana3/unidade_controle_semana3_tb.v
vlog -sv fpga/testbench/semana3/rfid_uart_rx_semana3_tb.v
vlog -sv fpga/testbench/semana4/circuito_caixa_semana4_tb.v

# Cenário 8: regressão de todos os testbenches antes da montagem
vsim -onfinish stop work.processador_acao_tb
run -all
quit -sim

vsim -onfinish stop work.rfid_uart_rx_tb
run -all
quit -sim

vsim -onfinish stop work.rfid_uart_rx_semana3_tb
run -all
quit -sim

vsim -onfinish stop work.seletor_item_telemetria_tb
run -all
quit -sim

vsim -onfinish stop work.telemetria_uart_tb
run -all
quit -sim

vsim -onfinish stop work.unidade_controle_moore_tb
run -all
quit -sim

vsim -onfinish stop work.unidade_controle_semana3_tb
run -all
quit -sim

vsim -onfinish stop work.circuito_jogo_financeiro_tb1
run -all
quit -sim

# Cenário 10: interface física da caixa no topo do circuito
vsim -onfinish stop work.circuito_caixa_semana4_tb
run -all
quit -sim

quit -f
