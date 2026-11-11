# Guia de montagem e execução

## Hardware RFID

Este mapeamento considera a Terasic DE0-CV selecionada no QSF e uma ESP32
(módulo ESP32-WROOM-32U, placa ESP32 Dev Module). O RC522 usa o SPI padrão
(VSPI) e recebe 3,3 V. Detalhes e links de pinout em [`esp/README.md`](../esp/README.md).

| RC522 | ESP32 |
|---|---|
| SDA/SS | GPIO5 |
| SCK | GPIO18 |
| MOSI | GPIO23 |
| MISO | GPIO19 |
| RST | GPIO22 |
| 3.3V / GND | 3V3 / GND |

> O pino **SDA** do RC522 é o *chip select* (SS/NSS) do SPI, não o SDA de I2C.
> Por isso ele vai no **GPIO5 (VSPI_CS)**, e não no GPIO21 (SDA da ESP32).
> O GPIO22 aparece no pinout como VSPI_WP/SCL, mas aqui é usado como GPIO comum
> para o RST, já que o projeto não usa I2C.

| UART | DE0-CV JP2 |
|---|---|
| ESP32 TX2/GPIO17 → FPGA RX | `rfid_rx`, GPIO_1_D22, PIN_C15 |
| FPGA TX → ESP32 RX2/GPIO16 | `uart_tx`, GPIO_1_D20, PIN_A14 |
| GND | GND |

Os dois sinais UART usam 115200 baud, 8-N-1 e níveis de 3,3 V. As atribuições
estão no `fpga/quartus/circuito_jogo_financeiro.qsf`. A placa DE0-CV tem GPIO
de 3,3 V; confirme o nome do conector e a revisão no [manual do fabricante
Terasic](https://www.terasic.com.tw/cgi-bin/page/archive.pl?CategoryNo=13&Language=English&No=921&PartNo=4).
Não conecte fios com as placas ligadas, não una os pinos VCC e não alimente o
RC522 ou a ESP32 pelos pinos com 5 V. Ligue apenas GND comum e os sinais indicados.

A ESP32 usa a UART2 (GPIO16/17) só para a FPGA, e a UART0 (USB) fica para
gravação e logs. Os fios da FPGA podem ficar ligados durante a gravação, e o
Monitor Serial mostra os eventos (RFID, quadros, Wi-Fi, MQTT) sem interferir nos
quadros de jogo.

## Cadastrar cartões

1. Instale **esp32 by Espressif Systems**, `MFRC522` e `PubSubClient` no Arduino IDE.
2. Grave `esp/tools/uid_reader/uid_reader.ino` (placa **ESP32 Dev Module**).
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

Inicie um broker MQTT acessível pela ESP32 e pelo computador. Em `config.h`,
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
- Sem comando da compra: confira UID cadastrado e GPIO17→`rfid_rx`.
- Compra sem evento: confira `uart_tx`→GPIO16, baud 115200 e GND comum.
- Resposta incorreta: confira UID→item e o saldo/inventário no jogo; a FPGA
  mantém as regras de aprovação.

O teste isolado do parser da telemetria está em `esp/testbench/`; as instruções
do Quartus e ModelSim ficam em `fpga/README.md`.
