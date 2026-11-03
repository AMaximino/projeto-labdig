# Testbenches da FPGA

Os testbenches Verilog ficam separados do firmware ESP8266 e podem ser
simulados no ModelSim/QuestaSim. Os fontes RTL existentes continuam em
`circuito/` para manter os caminhos usados pelo projeto Quartus.

## ModelSim

Na raiz do repositorio:

```tcl
vsim -do fpga/testbench/run_all.do
```

O script compila os modulos RTL e executa tres testbenches independentes:

- `processador_acao_tb.v`: compra aceita e compra sem saldo suficiente.
- `telemetria_uart_tb.v`: framing serial, snapshot, sinal, sequencia e fila.
- `unidade_controle_moore_tb.v`: transicoes com nomes claros e saídas que
  mudam somente depois da transicao Moore.

O testbench original completo, `circuito_jogo_financeiro_tb1.v`, também está
nesta pasta. Para executá-lo interativamente:

```tcl
vlog -sv circuito/*.v fpga/testbench/circuito_jogo_financeiro_tb1.v
vsim work.circuito_jogo_financeiro_tb1
do sim/wave.do
run -all
```

Se o ModelSim for iniciado dentro da pasta `sim/`, use os caminhos relativos
`../circuito/*.v`, `../fpga/testbench/*.v` e `wave.do`.

## Icarus Verilog

Como alternativa para verificações rápidas no terminal:

```sh
iverilog -g2012 -s telemetria_uart_tb -o /tmp/aef_uart.vvp \
  circuito/telemetria_uart.v fpga/testbench/telemetria_uart_tb.v
vvp /tmp/aef_uart.vvp
```
