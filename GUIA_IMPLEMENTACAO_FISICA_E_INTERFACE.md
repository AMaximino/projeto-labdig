# Guia de montagem e execução

## Hardware RFID

Este mapeamento considera a Terasic DE0-CV selecionada no QSF e uma ESP8266
NodeMCU/D1 mini. O RC522 usa SPI e recebe 3,3 V.

| RC522 | ESP8266 |
|---|---|
| SDA/SS | D2/GPIO4 |
| SCK | D5/GPIO14 |
| MOSI | D7/GPIO13 |
| MISO | D6/GPIO12 |
| RST | D1/GPIO5 |
| 3.3V / GND | 3V3 / GND |

| UART | DE0-CV JP2 |
|---|---|
| ESP TX0/GPIO1 → FPGA RX | `rfid_rx`, GPIO_1_D22, PIN_C15 |
| FPGA TX → ESP RX0/GPIO3 | `uart_tx`, GPIO_1_D20, PIN_A14 |
| GND | GND |

Os dois sinais UART usam 115200 baud, 8-N-1 e níveis de 3,3 V. As atribuições
estão no `fpga/quartus/circuito_jogo_financeiro.qsf`. A placa DE0-CV tem GPIO
de 3,3 V; confirme o nome do conector e a revisão no [manual do fabricante
Terasic](https://www.terasic.com.tw/cgi-bin/page/archive.pl?CategoryNo=13&Language=English&No=921&PartNo=4).
Não conecte fios com as placas ligadas, não una os pinos VCC e não alimente o
RC522 ou ESP8266 com 5 V. Ligue apenas GND comum e os sinais indicados.

A UART0 da ESP8266 é compartilhada com USB. Durante a gravação e leitura do UID,
retire os fios TX0/RX0 da FPGA. Recoloque após a gravação. O firmware integrado
não envia logs pela UART para preservar os quadros binários/textuais de jogo.

## Cadastrar cartões

1. Instale ESP8266 Community, `MFRC522` e `PubSubClient` no Arduino IDE.
2. Grave `esp/tools/uid_reader/uid_reader.ino` com os fios UART desligados.
3. Abra o Monitor Serial em 115200, aproxime cada cartão e copie o UID
   hexadecimal mostrado.
4. Copie `esp/aef_bridge/config.example.h` para `config.h`, preencha Wi-Fi e
   broker e coloque cada UID em `AEF_RFID_TAG_N_UID`, associando o produto
   `1`–`10` em `AEF_RFID_TAG_N_ITEM`. UID vazio desabilita o slot.
5. Grave `esp/aef_bridge/aef_bridge.ino`; reconecte os fios UART depois do
   reinício.

O firmware envia uma compra ao detectar um UID cadastrado e só permite nova
leitura depois de o cartão sair do campo por 300 ms. A FPGA valida saldo,
duplicidade e inventário; aproximar um cartão não garante aprovação.

## Rede e interface

Inicie um broker MQTT acessível pela ESP8266 e pelo computador. Em `config.h`,
use o IP do servidor MQTT na rede, não `localhost`. Na raiz do projeto, inicie o
backend:

```sh
npm --prefix back install
MQTT_URL=mqtt://localhost:1883 npm --prefix back start
```

Abra `http://localhost:3000` no computador do servidor ou
`http://IP-DO-SERVIDOR:3000` em outro computador da mesma rede. Libere a porta
3000 no firewall local. O backend serve front e WebSocket no mesmo host; o
navegador conecta ao `/ws/telemetria` e tenta novamente após quedas.

Confirme `http://IP-DO-SERVIDOR:3000/health` e verifique
`"mqtt_connected":true`. Faça uma compra RFID: a interface deve receber
`compra_aprovada` ou `compra_recusada`, com o snapshot atualizado.

## Diagnóstico por etapa

- Sem atividade no painel: confira o host/porta 3000, o WebSocket e o log do
  backend.
- Backend com MQTT desconectado: valide broker, endereço, porta, Wi-Fi e
  tópico `aventura_financeira/telemetria`.
- Sem comando da compra: confira UID cadastrado e TX0→`rfid_rx`.
- Compra sem evento: confira RX FPGA→RX0, baud 115200 e GND comum.
- Resposta incorreta: confira UID→item e o saldo/inventário no jogo; a FPGA
  mantém as regras de aprovação.

O teste isolado do parser da telemetria está em `esp/testbench/`; as instruções
do Quartus e ModelSim ficam em `fpga/README.md`.
