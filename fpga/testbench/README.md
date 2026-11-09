# Testbenches FPGA

Os testbenches ficam separados do RTL em `fpga/testbench/`. Com ModelSim ou
QuestaSim, a partir da raiz do repositório:

```tcl
vsim -do fpga/testbench/run_all.do
```

O script executa os testes de compra, framing de telemetria, comando RFID e FSM
de Moore. `rfid_uart_rx_tb.v` verifica `R07`/`R10`, mantém o comando pendente e
confirma que o acknowledge o consome uma vez. O testbench completo da partida é
`circuito_jogo_financeiro_tb1.v`. Os fontes de síntese ficam em `fpga/rtl/` e o
projeto Quartus em `fpga/quartus/`.
