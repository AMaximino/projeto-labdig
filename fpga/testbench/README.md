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

## Semana 3

Os testbenches específicos da semana 3 ficam em `fpga/testbench/semana3/` e
podem ser executados independentemente da suíte geral:

```tcl
vsim -do fpga/testbench/semana3/run_semana3.do
```

`rfid_uart_rx_semana3_tb.v` testa comandos válidos e inválidos, retenção do
comando até o acknowledge e bloqueio de sobrescrita. `unidade_controle_semana3_tb.v`
testa os caminhos principais de ação, avanço de jogada/rodada, falência, fim de
jogo e seleção de display. O script também roda `processador_acao_tb.v` (compra
sem saldo e item repetido) e `seletor_item_telemetria_tb.v` (evento 14 do
seletor), cobrindo os cenários 1 a 7 do relatório da semana. Para rodar em modo
texto, use `vsim -c -do ...`. Os mesmos arquivos estão empacotados em
`fpga/archive/simulacoes-semana3.zip`. Os diagramas de estado e a estratégia física estão,
respectivamente, em
[`DIAGRAMA_ESTADOS_SEMANA3.md`](semana3/DIAGRAMA_ESTADOS_SEMANA3.md) e
[`../docs/ESTRATEGIA_MONTAGEM_SEMANA3.md`](../docs/ESTRATEGIA_MONTAGEM_SEMANA3.md).
