# FPGA

- `rtl/`: projeto RTL e módulo `rfid_uart_rx.v`.
- `testbench/`: testbenches Verilog.
- `quartus/`: projeto e atribuições de pinos para Terasic DE0-CV
  (`5CEBA4F23C7`).
- `sim/`: arquivos de simulação ModelSim/QuestaSim.
- `configuracao/`: pinagens da placa (PDF/CSV com os botões do jogo) e
  configuração de forma de onda.
- `docs/`: estratégias de montagem e depuração da semana 3 e datasheet do
  MC74HC164.
- `archive/`: projetos ModelSim antigos e pacotes `.zip` de simulações
  anteriores, mantidos só como histórico.

## Entrada RFID

A FPGA mantém a autoridade do saldo e da compra. O ESP32 envia pela UART RX
`RNN\n`, em 115200 baud, 8-N-1, onde `NN` é o item de 01 a 10. O receptor
sincroniza o sinal, valida o quadro e mantém o item pendente até a FSM registrar
a ação. O item selecionado segue pelo mesmo `processador_acao.v` usado pelos
botões; a telemetria retorna como compra aprovada/recusada com snapshot
financeiro. A entrada só é habilitada na espera de ação do jogo.

O comando e a telemetria usam dois fios separados: `rfid_rx` recebe dados da
ESP32 e `uart_tx` envia telemetria à ESP32. O QSF principal atribui ambos
ao conector JP2/GPIO1 da DE0-CV: `rfid_rx` em GPIO_1_D22 (PIN_C15) e `uart_tx`
em GPIO_1_D20 (PIN_A14). Ambos usam o padrão de I/O 2.5 V (padrão do Cyclone V,
igual ao Pin Planner); não altere para 3.3-V LVTTL, pois o banco 7A conflita
com os demais pinos. Os demais
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

Os testes, diagramas e o roteiro físico da semana 3 ficam em
`fpga/testbench/semana3/` e `fpga/docs/ESTRATEGIA_MONTAGEM_SEMANA3.md`. Execute a
suíte isolada da semana com:

```tcl
vsim -do fpga/testbench/semana3/run_semana3.do
```
