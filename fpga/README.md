# FPGA

- `rtl/`: projeto RTL e módulo `rfid_uart_rx.v`.
- `testbench/`: testbenches Verilog.
- `quartus/`: projeto e atribuições de pinos para Terasic DE0-CV
  (`5CEBA4F23C7`).
- `sim/`: arquivos de simulação ModelSim/QuestaSim.
- `configuracao/pinagens/`: pinagens e diagramas de montagem.

## Entrada RFID

A FPGA mantém a autoridade do saldo e da compra. O ESP8266 envia pela UART RX
`RNN\n`, em 115200 baud, 8-N-1, onde `NN` é o item de 01 a 10. O receptor
sincroniza o sinal, valida o quadro e mantém o item pendente até a FSM registrar
a ação. O item selecionado segue pelo mesmo `processador_acao.v` usado pelos
botões; a telemetria retorna como compra aprovada/recusada com snapshot
financeiro. A entrada só é habilitada na espera de ação do jogo.

O comando e a telemetria usam dois fios separados: `rfid_rx` recebe dados da
ESP8266 e `uart_tx` envia telemetria à ESP8266. O QSF principal atribui ambos
ao conector JP2/GPIO1 da DE0-CV: `rfid_rx` em GPIO_1_D22 (PIN_C15) e `uart_tx`
em GPIO_1_D20 (PIN_A14). Ambos estão configurados como 3,3 V LVTTL. Os demais
pinos do jogo permanecem nas atribuições existentes.

## Compilar e simular

Abra `quartus/projeto_labdig.qpf` no Quartus Prime. Para executar os testbenches
com ModelSim/QuestaSim a partir da raiz do repositório:

```tcl
vsim -do fpga/testbench/run_all.do
```

O teste completo da partida fica em
`fpga/testbench/circuito_jogo_financeiro_tb1.v`. As atribuições físicas devem
ser mantidas em sincronia com a revisão da placa usada na bancada.
