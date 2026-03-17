vlib work
vmap work work
vlog *.v
vsim jogo_desafio_memoria_tb1

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/clock_in
add wave -noupdate -height 20 -radix decimal /jogo_desafio_memoria_tb1/caso
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/UC/estado
add wave -noupdate -divider Entradas
add wave -noupdate -color Magenta -height 20 /jogo_desafio_memoria_tb1/reset_in
add wave -noupdate -color Cyan -height 20 /jogo_desafio_memoria_tb1/jogar_in
add wave -noupdate -color Cyan -height 20 /jogo_desafio_memoria_tb1/configuracao_in
add wave -noupdate -color Yellow -height 20 /jogo_desafio_memoria_tb1/botoes_in
add wave -noupdate -divider Jogada
add wave -noupdate -color Yellow -height 20 /jogo_desafio_memoria_tb1/dut/FD/w_tem_jogada
add wave -noupdate -color Yellow -height 20 /jogo_desafio_memoria_tb1/dut/UC/jogada_pulso
add wave -noupdate -divider Depuração
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/db_igual_out
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/leds_rgb_out
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/configuracao_out
add wave -noupdate -divider Resultado
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/ganhou_out
add wave -noupdate -color Magenta -height 20 /jogo_desafio_memoria_tb1/perdeu_out
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/pronto_out
add wave -noupdate -color Magenta -height 20 /jogo_desafio_memoria_tb1/timeout_out
add wave -noupdate -divider {Fluxo Dados}
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/FD/contagem
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/FD/memoria
add wave -noupdate -color Yellow -height 20 /jogo_desafio_memoria_tb1/dut/FD/jogada
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/FD/rodada
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/UC/fim_rodada
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/UC/fim_jogo
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/UC/timeout1
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/UC/timeout2
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/FD/timerEspera/Q
add wave -noupdate -color White -height 20 /jogo_desafio_memoria_tb1/dut/FD/timerLED/Q
add wave -noupdate -divider {Unidade Controle}
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/rstED
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/we
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraCJ
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/contaCJ
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraR
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/registraR
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraM
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/registraM
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraT1
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/contaT1
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraT2
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/contaT2
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/zeraCR
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/contaCR
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/ligaLED
add wave -noupdate -height 20 /jogo_desafio_memoria_tb1/dut/FD/ledMem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 303
configure wave -valuecolwidth 82
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ns} {15002497 ns}

run -all