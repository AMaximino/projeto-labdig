vlib work
vmap work work

vlog ../circuito/*.v
vlog ../tb/*.v

vsim circuito_jogo_financeiro_tb1


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/clock_in
add wave -noupdate -height 22 -radix decimal /circuito_jogo_financeiro_tb1/caso
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/Eatual
add wave -noupdate -divider Entradas
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/reset_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/iniciar_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/trabalhar_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/estudar_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/investir_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/resgatar_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/comprar_in
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/vender_in
add wave -noupdate -divider Saidas
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/ultima_jogada_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/ultima_rodada_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/terminou_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/perdeu_out
add wave -noupdate -divider valoresFinanceiros
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/saldo
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/salario
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/valorInvestido
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/rendimento
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/gastosFixos
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/gastosUnicos
add wave -noupdate -divider FD
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/iniciar
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/acoes
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/acoes_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/tem_acao
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/acao_pulso
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/eh_jogada
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/fim_jogo
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/fim_perdeu
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/uc/fim_rodada
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/contagem
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/rodada
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/saldo_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/salario_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/valor_investido_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/rendimento_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/gastos_fixos_out
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/p/gastos_unicos_out
add wave -noupdate -divider UC
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/rstED
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/init
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/we
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/zeraCJ
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/contaCJ
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/zeraCR
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/contaCR
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/zeraD
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/registraD
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/zeraA
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/registraA
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/zeraR
add wave -noupdate -height 22 /circuito_jogo_financeiro_tb1/dut/fd/registraR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 133
configure wave -valuecolwidth 40
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {29864 ns}


run -all