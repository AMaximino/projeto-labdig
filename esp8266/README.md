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

## Conectar ao site local pela rede

O fluxo e `FPGA → UART → ESP8266 → MQTT → backend → WebSocket → navegador`.
O site nao conecta diretamente a porta MQTT: ele recebe dados do backend.
As portas usadas neste projeto sao MQTT TCP **1883**, backend/WebSocket **3000**
e site **8000**.

### Iniciar o broker MQTT

Se estiver usando WSL/Ubuntu, instale o Mosquitto:

```sh
sudo apt update
sudo apt install -y mosquitto mosquitto-clients
sudo tee /etc/mosquitto/conf.d/aef.conf >/dev/null <<'EOF'
listener 1883 0.0.0.0
allow_anonymous true
EOF
sudo service mosquitto restart
```

Essa configuracao anonima serve apenas para desenvolvimento em uma rede
privada. Nao exponha a porta do broker a internet ou a redes compartilhadas.

Para o ESP8266 chegar ao broker no WSL atraves da rede Wi-Fi do computador,
obtenha o IP atual do WSL:

```sh
hostname -I
```

No PowerShell aberto **como administrador**, encaminhe a porta MQTT do Windows
ao WSL, substituindo `<IP_DO_WSL>` pelo primeiro endereco mostrado:

```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=1883 connectaddress=<IP_DO_WSL> connectport=1883
New-NetFirewallRule -DisplayName "AEF MQTT 1883" -Direction Inbound -Protocol TCP -LocalPort 1883 -Action Allow -RemoteAddress LocalSubnet
```

Se o encaminhamento ja existir, remova-o antes de cria-lo novamente:

```powershell
netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=1883
```

O IP do WSL pode mudar quando ele reiniciar; atualize `portproxy` se isso
acontecer. O ESP8266 e o computador precisam estar na mesma rede e a rede
precisa permitir comunicacao entre dispositivos. O valor atual de
`AEF_MQTT_HOST` deve ser o IPv4 do computador na rede Wi-Fi, nao `localhost`
nem o IP interno do WSL. Se o IP do computador mudar, atualize-o em
`aef_bridge/config.h`.

Teste o broker no WSL, em um terminal:

```sh
mosquitto_sub -h 127.0.0.1 -p 1883 -t aventura_financeira/telemetria -v
```

### Iniciar o backend e o painel

Em outro terminal WSL, na pasta do repositorio:

```sh
cd /mnt/c/Users/Sophia/Documents/projeto-labdig/backend
MQTT_URL=mqtt://127.0.0.1:1883 npm start
```

O log deve indicar conexao MQTT; confira o backend com:

```sh
curl http://localhost:3000/health
```

Em um terceiro terminal:

```sh
cd /mnt/c/Users/Sophia/Documents/projeto-labdig
python3 -m http.server 8000 --directory frontend
```

Abra `http://localhost:8000`. Na janela **Conexao de dados**, selecione
**Backend do jogo** e use `ws://localhost:3000/ws/telemetria`.

### Configurar e gravar o ESP8266

Copie `aef_bridge/config.example.h` para `aef_bridge/config.h`, mantendo o
SSID/senha Wi-Fi ja configurados e definindo `AEF_MQTT_HOST` para o IPv4 do
computador na Wi-Fi e `AEF_MQTT_PORT` para `1883`. Configure a IDE Arduino com
o pacote **ESP8266 by ESP8266 Community**, a biblioteca **PubSubClient** e a
placa/porta corretas; abra `aef_bridge/aef_bridge.ino` e grave o firmware.

Abra o Monitor Serial em **115200 baud** e confira as mensagens de conexao ao
Wi-Fi e ao broker. Com `mosquitto_sub` ainda aberto, inicie ou execute a FPGA:
devem aparecer mensagens no topico e o painel deve atualizar. A configuracao de
exemplo usa GPIO14 (D5 em NodeMCU/D1 mini) para RX; confira a pinagem da placa,
conecte o GND comum e confirme que o TX da FPGA nao excede 3,3 V.

O enderecamento IP pode mudar com o tempo: se o PC receber outro IP do Wi-Fi,
altere `AEF_MQTT_HOST` e atualize o encaminhamento do Windows se o IP do WSL
tambem tiver mudado. Reservar os IPs no roteador/hotspot evita esse ajuste.

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
