# projeto-labdig
Respositório do projeto de desenvolvimento de um circuito digital para auxiliar a educação financeira de crianças e adolescentes, em especial daquelas no espectro autista. O projeto consiste em um jogo de tabuleiro digital interativo que simula situações da vida real.

## Telemetria FPGA, ESP8266 e painel

A FPGA continua executando as regras do jogo. A saida UART envia snapshots para
o firmware ESP8266, que publica eventos MQTT; o backend valida e encaminha os
dados por WebSocket ao front-end.

- RTL UART e captura de eventos: `circuito/telemetria_uart.v` e
  `circuito/circuito_jogo_financeiro.v` (saida nova `uart_tx`).
- A FSM em `circuito/unidade_controle.v` continua sendo Moore, com estados
  separados e nomes que descrevem cada etapa do jogo.
- Testbenches Verilog para ModelSim ficam em
  [`fpga/testbench/README.md`](fpga/testbench/README.md); o teste de protocolo
  do firmware fica separado em [`esp8266/testbench/`](esp8266/testbench/).
- Os modulos FPGA continuam em `circuito/` para manter o projeto Quartus; a
  pasta `fpga/testbench/` guarda somente os testbenches FPGA e a pasta
  `esp8266/` guarda somente firmware e testes ESP8266.
- Firmware ESP8266 e ligacao UART: [`esp8266/README.md`](esp8266/README.md).
- Backend MQTT/WebSocket: [`backend/README.md`](backend/README.md).
- Contrato de dados e escala monetaria:
  [`CONTEXTO_TECNICO_AEF_FPGA_ESP32_FRONTEND.md`](CONTEXTO_TECNICO_AEF_FPGA_ESP32_FRONTEND.md).
- Painel e conexao WebSocket: [`frontend/README.md`](frontend/README.md).

**Hardware:** o `uart_tx` ainda nao esta associado a um pino no QSF. Confirme
um pino de expansao livre e o nivel eletrico antes de ligar a entrada RX da
ESP8266. A serial usa 115200 baud, 8-N-1; a entrada ESP8266 exige sinal compativel
com 3,3 V e pode exigir conversao de nivel.
