# ESP8266: da FPGA ao painel web

Este guia começa do zero. A ESP8266 não executa regras do jogo e não controla
os displays: ela recebe pela UART os eventos/snapshots gerados pela FPGA,
publica-os por MQTT e o painel existente os mostra pela conexão com o backend:

```text
FPGA (regras e estado) → UART → ESP8266 → Wi-Fi/MQTT → backend → WebSocket → painel
```

O painel é somente leitura. Os botões físicos continuam controlando a partida.
O navegador não se conecta à porta MQTT TCP 1883; recebe os eventos do backend
em `ws://...:3000/ws/telemetria`.

## Antes de começar

- Placa ESP8266 NodeMCU ou Wemos D1 mini e cabo USB de dados.
- Computador e ESP8266 na mesma rede Wi-Fi (redes de convidados podem bloquear
  comunicação entre dispositivos).
- FPGA programada com a telemetria UART deste projeto.
- Arduino IDE, acesso para configurar rede/firewall e Node.js 20+.
- Um broker MQTT local; este guia usa Mosquitto no Ubuntu/WSL.

**A ligação física FPGA→ESP ainda depende de escolher um pino de expansão livre
para `uart_tx` e atribuí-lo no QSF.** O repositório não documenta esse pino.
Não conecte um pino por tentativa: confirme conector e atribuição QSF. A entrada
da ESP8266 aceita no máximo 3,3 V; use conversor de nível se necessário.

## 1. Prepare o Arduino IDE

1. Instale o Arduino IDE no computador.
2. Em **Arquivo → Preferências**, adicione às URLs de placas:
   `https://arduino.esp8266.com/stable/package_esp8266com_index.json`
3. Em **Ferramentas → Placa → Gerenciador de Placas**, procure `esp8266` e
   instale **esp8266 by ESP8266 Community**.
4. Em **Sketch → Incluir Biblioteca → Gerenciar Bibliotecas**, procure
   `PubSubClient` e instale a biblioteca de Nick O'Leary.
5. Conecte a placa com USB. Escolha **NodeMCU 1.0 (ESP-12E Module)** ou
   **LOLIN(WEMOS) D1 R2 & mini**, conforme o modelo. Em **Ferramentas → Porta**,
   selecione a porta COM/tty que apareceu. Se não aparecer, verifique cabo de
   dados e instale o driver USB-serial da placa.

## 2. Inicie o broker MQTT (Ubuntu/WSL)

No terminal Ubuntu/WSL:

```sh
sudo apt update
sudo apt install -y mosquitto mosquitto-clients
sudo tee /etc/mosquitto/conf.d/aef.conf >/dev/null <<'EOF'
listener 1883 0.0.0.0
allow_anonymous true
EOF
sudo service mosquitto restart
```

É uma configuração sem senha apenas para desenvolvimento em rede privada; não
exponha a porta 1883 à internet. Teste e deixe este terminal aberto:

```sh
mosquitto_sub -h 127.0.0.1 -p 1883 -t aventura_financeira/telemetria -v
```

No WSL2, encaminhe a porta do Windows para o IP interno do WSL. Descubra-o no
Ubuntu/WSL com:

```sh
hostname -I
```

Abra PowerShell **como administrador** e troque `<IP_DO_WSL>` pelo endereço
mostrado:

```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=1883 connectaddress=<IP_DO_WSL> connectport=1883
New-NetFirewallRule -DisplayName "AEF MQTT 1883" -Direction Inbound -Protocol TCP -LocalPort 1883 -Action Allow -RemoteAddress LocalSubnet
```

Se o WSL reiniciar e mudar de IP, remova e recrie o encaminhamento:

```powershell
netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=1883
```

No PowerShell, execute `ipconfig` e anote o IPv4 do adaptador Wi-Fi do
computador (por exemplo, `192.168.1.25`). **Esse IPv4 do Wi-Fi é o host MQTT
da ESP.** O IP interno do WSL é somente o destino do encaminhamento. Não use
`localhost` na ESP.

## 3. Configure a ESP8266

Na pasta `esp8266/aef_bridge/`, copie `config.example.h` para `config.h` e edite:

- `AEF_WIFI_SSID` e `AEF_WIFI_PASSWORD`: nome e senha do Wi-Fi.
- `AEF_MQTT_HOST`: IPv4 do computador na rede Wi-Fi, anotado acima.
- `AEF_MQTT_PORT`: mantenha `1883`.
- `AEF_MQTT_USERNAME` e `AEF_MQTT_PASSWORD`: vazios para o broker de exemplo;
  preencha se seu broker exigir autenticação.
- `AEF_DEVICE_ID`: identificador único sem espaços.
- `AEF_FPGA_RX_PIN`: mantenha `14` para GPIO14/D5 no exemplo.

`config.h` é ignorado pelo Git porque contém credenciais. Não o compartilhe.

## 4. Compile e grave

1. No Arduino IDE, abra `esp8266/aef_bridge/aef_bridge.ino`.
2. Confira modelo da placa e porta USB em **Ferramentas**.
3. Clique em **Verificar** (✓). Corrija erros de biblioteca/placa antes de
   prosseguir.
4. Clique em **Carregar** (→) e aguarde a conclusão.
5. Abra **Ferramentas → Monitor Serial**, configure **115200 baud** e reinicie
   a placa. O firmware deve indicar início da ponte e conexão ao broker.

Se não conectar, confira primeiro SSID/senha, IP MQTT, porta 1883, serviço
Mosquitto, encaminhamento WSL e firewall.

O firmware lê linhas `AEF1` pela UART a 115200 baud, 8-N-1, valida os campos,
converte cada unidade financeira RTL para 10.000 centavos e publica JSON QoS 0
no tópico `aventura_financeira/telemetria`. Uma fila RAM guarda até quatro
eventos durante quedas breves sem bloquear a FPGA. Ao receber início de partida,
gera um identificador de sessão. Se NTP ainda não sincronizou, envia
`timestamp: null`; o backend registra o horário de chegada.

O exemplo recebe por `SoftwareSerial` no GPIO14 (normalmente D5 em NodeMCU/D1
mini) e deixa USB/Serial livre para diagnóstico. A 115200 baud pode haver perda
de bytes conforme a placa e atividade Wi-Fi; valide na placa real. RX0 de
hardware é GPIO3/RX e compartilha a serial USB, exigindo outra estratégia para
diagnóstico.

## 5. Inicie backend e painel

Com o broker ativo, em outro terminal Ubuntu/WSL, a partir da raiz do projeto:

```sh
cd backend
npm install
MQTT_URL=mqtt://127.0.0.1:1883 npm start
```

Confira o backend:

```sh
curl http://localhost:3000/health
```

Em outro terminal, na raiz do projeto:

```sh
python3 -m http.server 8000 --directory frontend
```

Abra `http://localhost:8000`, clique **Conexão de dados**, selecione **Backend
do jogo (recomendado)** e use `ws://localhost:3000/ws/telemetria`. Salve/conecte.
Não use o modo MQTT direto para a porta 1883: MQTT TCP não é WebSocket.

## 6. Conecte FPGA e confira a telemetria

Antes de ligar fios, confirme qual pino livre da placa FPGA foi atribuído a
`uart_tx` no QSF e que sua tensão é compatível com 3,3 V. Com as placas
desligadas, ligue:

| FPGA | ESP8266 | Nota |
|---|---|---|
| `uart_tx` | GPIO14/D5 | TX da FPGA → RX da ESP |
| GND | GND | Terra comum obrigatório |

Não aplique 5 V ao RX. Alimente cada placa segundo seu manual; não use o pino
3,3 V da ESP para alimentar a FPGA. Programe a FPGA, ligue os sistemas e inicie
uma partida pelos controles físicos.

Confira o fluxo em três lugares: (1) Monitor Serial mostra eventos recebidos;
(2) `mosquitto_sub` mostra JSON no tópico; (3) painel atualiza rodada, jogada,
saldo, inventário e histórico. Se faltar uma etapa, use esta localização:

- Sem evento no Serial: reveja atribuição QSF, TX→RX, GND, velocidade e nível
  lógico.
- Evento no Serial, sem JSON no subscriber: reveja Wi-Fi e conexão MQTT.
- JSON no broker, painel parado: reveja log/health do backend e URL WebSocket.

## Protocolo e responsabilidades

- FPGA mantém regras, saldo, inventário, botões e displays; ESP apenas traduz.
- UART: framing ASCII `AEF1`, terminado em LF, 115200 baud, 8-N-1.
- MQTT: JSON UTF-8 em `aventura_financeira/telemetria`.
- Backend: WebSocket `/ws/telemetria`, porta 3000.
- Site: HTTP porta 8000, modo de conexão **Backend do jogo**.
- Escala: `150` unidades RTL = `1.500.000` centavos = R$ 15.000,00.

O pino FPGA `uart_tx` ainda precisa ser escolhido e documentado no QSF da placa
utilizada. Consulte o [contrato técnico](../CONTEXTO_TECNICO_AEF_FPGA_ESP32_FRONTEND.md),
o [guia do backend](../backend/README.md) e o [guia do painel](../frontend/README.md).

## Teste local do parser

Sem placa ou broker, execute na raiz do repositório:

```sh
sh esp8266/testbench/run_tests.sh
```
