# ESP8266 e leitor RFID RC522

O ESP8266 lê cartões no módulo MFRC522, traduz UID cadastrado em item, envia a
compra à FPGA e encaminha a telemetria aprovada/recusada ao broker MQTT.
Responsabilidade de saldo e regras permanece na FPGA.

## Ligações

Exemplo para NodeMCU ESP-12E ou Wemos D1 mini. Desligue as placas antes de
conectar. O módulo RC522 deve receber **3,3 V**, nunca 5 V.

| RC522 | ESP8266 | Função |
|---|---|---|
| SDA / SS | D2 (GPIO4) | Seleção SPI |
| SCK | D5 (GPIO14) | Clock SPI |
| MOSI | D7 (GPIO13) | Dados para o leitor |
| MISO | D6 (GPIO12) | Dados do leitor |
| RST | D1 (GPIO5) | Reset |
| 3.3V | 3V3 | Alimentação do RC522 |
| GND | GND | Terra comum |

| Sinal | Conexão |
|---|---|
| ESP8266 TX0 / GPIO1 | DE0-CV JP2, GPIO_1_D22 / PIN_C15 (`rfid_rx`) |
| DE0-CV JP2, GPIO_1_D20 / PIN_A14 (`uart_tx`) | ESP8266 RX0 / GPIO3 |
| GND DE0-CV | GND ESP8266 |

UART é 115200 baud, 8-N-1, níveis 3,3 V nos dois sentidos. Não ligue VCC entre
as placas. A porta UART0 também é usada pelo USB da ESP8266: remova os dois fios
UART durante gravação/monitor serial e reconecte depois. O firmware de jogo não
escreve logs nessa UART para não misturar texto aos quadros de telemetria e
comando.

## Preparar o firmware

Instale no Arduino IDE o pacote **ESP8266 by ESP8266 Community** e as
bibliotecas **PubSubClient** e **MFRC522**. Copie
`aef_bridge/config.example.h` para `aef_bridge/config.h` e configure SSID,
senha, IP/porta do broker e `AEF_DEVICE_ID`. `localhost` não funciona como host
MQTT para a ESP: use o IP do computador/servidor na rede.

Para ler o UID de cada cartão, grave primeiro
`tools/uid_reader/uid_reader.ino`, abra o Monitor Serial a 115200 baud e anote
o UID hexadecimal. Depois copie esse valor para `AEF_RFID_TAG_N_UID` no
`config.h` e o número de produto (1–10) para `AEF_RFID_TAG_N_ITEM`. Deixe vazios
os slots sem cartão. UIDs são identificadores de conveniência, não credenciais
seguras de pagamento.

Abra `aef_bridge/aef_bridge.ino`, escolha a placa e grave. Remova os fios UART
durante o upload se o conversor USB serial não conseguir acessar a placa.
Reconecte-os após o reinício. A ponte opera continuamente sem depender do
Monitor Serial.

## Compra de borda única

Ao ler um UID cadastrado, o firmware envia `RNN\n` uma vez. O RC522 é colocado
em espera e o firmware só libera nova leitura depois de observar ausência do
cartão por 300 ms. Assim, manter o cartão no leitor não repete a compra. UID não
cadastrado não envia comando. O receptor FPGA valida o quadro e mantém a compra
pendente até a FSM registrar a ação; o mesmo caminho de compra valida saldo,
inventário e telemetria.

O restante do quadro FPGA usa `AEF1` e retorna pelo TX0 da FPGA. O ESP8266
valida o protocolo, converte a unidade financeira RTL para centavos de BRL e
publica no tópico `aventura_financeira/telemetria`. O backend repassa os eventos
ao painel.

## Rede e painel

Inicie um broker MQTT acessível pela rede, configure seu IP em `config.h` e
inicie o servidor a partir da raiz:

```sh
npm --prefix back install
MQTT_URL=mqtt://localhost:1883 npm --prefix back start
```

Abra `http://localhost:3000` (ou `http://IP-DO-SERVIDOR:3000`). Essa mesma
origem serve o painel e seu WebSocket. Acompanhe `GET /health` e o estado da
conexão no painel.

## Parser local

Os testes do protocolo de telemetria ficam em `testbench/`. Execute na raiz:

```sh
sh esp/testbench/run_tests.sh
```
