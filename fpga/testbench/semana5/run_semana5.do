onerror {quit -code 1}

# Simulações da semana 5 (cenário 11 do relatório): regressão final com o RTL de
# 3 vidas, estudo sem custo e investimento de 10.000 por vez.
# Executar a partir da raiz do repositório:
#   vsim -c -do fpga/testbench/semana5/run_semana5.do
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

# Cenário 11: regressão final de todos os testbenches
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

# Cenário 11 (cont.): interface da caixa no topo, com 3 vidas no caso 8
vsim -onfinish stop work.circuito_caixa_semana4_tb
run -all
quit -sim

quit -f
