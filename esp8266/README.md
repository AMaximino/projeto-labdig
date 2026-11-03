# Firmware ESP8266

Ponte unidirecional de telemetria: UART da FPGA para MQTT. O firmware nao
decide jogadas nem envia comandos para a FPGA.

## Preparacao

1. Use uma placa ESP8266 (por exemplo, NodeMCU ou D1 mini).
2. Na Arduino IDE, instale o pacote de placas **ESP8266 by ESP8266 Community**
   e a biblioteca **PubSubClient**.
3. Copie `aef_bridge/config.example.h` para `aef_bridge/config.h` e configure
   Wi-Fi, broker MQTT, credenciais e `AEF_FPGA_RX_PIN`. O arquivo `config.h` e
   local e nao deve ser versionado.
4. Abra `aef_bridge/aef_bridge.ino`, selecione a placa ESP8266 e grave.
5. O broker deve aceitar publicacao QoS 0 no topico
   `aventura_financeira/telemetria`.

O firmware usa `SoftwareSerial` com buffer RX de 256 bytes para a entrada da
FPGA e deixa a serial USB (`Serial`) disponivel para mensagens de diagnostico.
O pino de exemplo e GPIO14 (D5 em NodeMCU/D1 mini); confirme o mapeamento da
sua placa e configure esse GPIO como entrada UART.

## Ligacao UART

| FPGA | ESP8266 |
|---|---|
| `uart_tx` (saida) | GPIO `AEF_FPGA_RX_PIN` (entrada UART por software) |
| GND | GND |

UART 115200, 8-N-1. O firmware configura buffer UART de recepcao de 256 bytes.
Como a ESP8266 recebe por UART de software, valide a recepcao no modelo exato
da placa durante uso simultaneo de Wi-Fi. Se ocorrer perda de bytes, use o RX
UART0 de hardware (GPIO3/RX) e desative a serial USB de diagnostico, ou reduza
a taxa UART de ambos os lados de forma coordenada.

A tensao efetiva do pino FPGA depende do banco e do padrao IO escolhido. A
entrada ESP8266 exige sinal compativel com 3,3 V; confirme no manual da placa e
use conversao de nivel se necessario. Nao ligue sinais de 5 V nem escolha um
pino FPGA ja atribuido a display, botoes ou outro circuito. O pino FPGA para
`uart_tx` ainda precisa ser confirmado e atribuido no QSF.

O ESP8266 valida cada linha UART antes de gerar JSON. Cada unidade RTL equivale
a R$ 100,00, portanto `centavos = valor_RTL * 10000`. A fila local guarda ate
quatro mensagens durante quedas curtas de Wi-Fi/MQTT. PubSubClient publica QoS
0; o backend deduplica por dispositivo, sessao e sequencia.

Se o relogio NTP ainda nao estiver sincronizado, o payload envia
`"timestamp": null`; o backend usa o instante UTC de recebimento e preserva
esse fato em `device_timestamp`.

## Testes do ESP8266

Os testes do parser e da conversao de escala estao separados dos testbenches
FPGA em `esp8266/testbench/`. Na raiz do repositorio:

```sh
sh esp8266/testbench/run_tests.sh
```

Esse teste compila o mesmo `telemetry_protocol.h` incluído pelo firmware com
um compilador C++ local; nao precisa de placa, Wi-Fi ou broker.
