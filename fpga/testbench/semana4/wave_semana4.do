# Formas de onda do cenário 10 (interface física da caixa).
# Executar a partir da raiz do repositório:
#   vsim -do fpga/testbench/semana4/wave_semana4.do

vlib work
vmap work work
vlog -sv fpga/rtl/*.v
vlog -sv fpga/testbench/semana4/circuito_caixa_semana4_tb.v
vsim -onfinish stop work.circuito_caixa_semana4_tb

set TB /circuito_caixa_semana4_tb
add wave -divider "Caso de teste"
add wave -radix unsigned $TB/caso
add wave -divider "Tampa: botoes (ativos em 0)"
add wave $TB/reset $TB/iniciar $TB/trabalhar $TB/estudar
add wave $TB/investir $TB/resgatar $TB/comprar $TB/vender
add wave -radix binary $TB/seletor_item
add wave -radix binary $TB/config_display
add wave -divider "ESP32 <-> FPGA"
add wave $TB/rfid_rx $TB/rfid_valid $TB/rfid_ack $TB/uart_tx
add wave -divider "Jogo"
add wave $TB/clk_jogo
add wave -radix binary $TB/estado
add wave -radix decimal $TB/saldo $TB/salario $TB/investido
add wave -radix hex $TB/dinheiro
add wave -radix unsigned $TB/rodada $TB/jogada
add wave $TB/tel_send
add wave -radix unsigned $TB/tel_evento $TB/tel_item
add wave -divider "Tampa: LEDs"
add wave -radix binary $TB/indicador_itens
add wave $TB/ultima_rodada $TB/ultima_jogada $TB/terminou $TB/perdeu

run -all
wave zoom full
