# ESP32 — ponte RFID ⇄ FPGA ⇄ backend

Firmware para **ESP32-WROOM-32U** que faz três coisas ao mesmo tempo:

1. **Lê cartões RFID** no módulo **RC522** (via SPI).
2. **Conversa com a FPGA** (DE0-CV) por **UART**: envia a compra (`RNN\n`) e
   recebe os quadros de telemetria `AEF1`.
3. **Publica a telemetria no backend** via Wi-Fi/MQTT, no tópico
   `aventura_financeira/telemetria`.

Saldo, inventário e regras do jogo continuam sendo responsabilidade da FPGA. A
ESP32 apenas traduz UID → item, transporta mensagens e converte valores.

```
Cartão ─► RC522 ──SPI──► ESP32 ──UART2 TX (GPIO17)──► FPGA rfid_rx   (comando RNN)
                         ESP32 ◄─UART2 RX (GPIO16)─── FPGA uart_tx   (telemetria AEF1)
                         ESP32 ──Wi-Fi/MQTT──► broker ──► back ──WebSocket──► front
                         ESP32 ──USB (UART0)──► computador (gravação + logs)
```

## Conteúdo da pasta

| Caminho | O que é |
|---|---|
| `aef_bridge/aef_bridge.ino` | Firmware principal da ponte (RFID + UART + MQTT) |
| `aef_bridge/config.example.h` | Modelo de configuração (Wi-Fi, broker, UIDs, pinos) |
| `aef_bridge/telemetry_protocol.h` | Parser do quadro `AEF1` e geração do JSON |
| `tools/uid_reader/uid_reader.ino` | Ferramenta para descobrir o UID de cada cartão |
| `tools/rfid_test/` | Teste rápido do RC522 com janela guiada no Windows |
| `testbench/` | Teste do parser no PC, sem hardware |
| `esp32_wifi/` | Teste simples de conexão Wi-Fi na ESP32 |

## O que mudou em relação à versão ESP8266

| Item | ESP8266 (antes) | ESP32 (agora) |
|---|---|---|
| UART com a FPGA | UART0 (a mesma do USB) | **UART2 dedicada** (GPIO16/17) |
| Fios da FPGA na gravação | Precisavam ser removidos | **Podem ficar ligados** |
| Logs no Monitor Serial | Desligados (misturariam com a FPGA) | **Ligados** (`AEF_DEBUG 1`) |
| SPI do RC522 | D5/D6/D7/D2 + RST D1 | VSPI GPIO18/19/23/5 + RST GPIO22 |
| Identificador do chip | `ESP.getChipId()` | Últimos 3 bytes do MAC (`ESP.getEfuseMac()`) |
| Pacote Arduino | ESP8266 Community | **esp32 by Espressif Systems** |

O protocolo (`RNN\n`, `AEF1`, JSON publicado) **não mudou**. FPGA, backend e
front continuam iguais.

## A ESP32 tem SPI para o RC522?

Sim. O ESP32 tem quatro controladores SPI. Dois deles (SPI0/SPI1) já são usados
pela flash interna do módulo. Os outros dois ficam livres para uso: **HSPI** e
**VSPI**. No Arduino, `SPI` usa o **VSPI** por padrão, nos pinos abaixo. Este
firmware usa esse barramento.

Como o ESP32 tem matriz de GPIO, o SPI pode ir para outros pinos. Os pinos
padrão do VSPI usam o IO MUX direto, que é o caminho mais simples e confiável.

### Onde ver o pinout da sua placa

O **ESP32-WROOM-32U** é o *módulo*: a plaquinha metálica com conector de antena
U.FL. Ele fica soldado numa *placa de desenvolvimento*, normalmente uma
**ESP32-DevKitC** ou uma placa compatível de 30/38 pinos. Os nomes impressos na
placa (`D18`, `IO18`, `G18`, `GPIO18`) indicam o **número do GPIO**. Os pinos
deste README usam esse número, não a posição física.

- **Pinout da placa DevKitC (Espressif)**, com o diagrama de pinos (a DevKitC V4
  aceita o WROOM-32U):
  <https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32/esp32-devkitc/user_guide.html>
- **Datasheet do módulo ESP32-WROOM-32D / 32U**, seção *Pin Definitions*:
  <https://www.espressif.com/sites/default/files/documentation/esp32-wroom-32d_esp32-wroom-32u_datasheet_en.pdf>
- **Datasheet do chip ESP32**, tabela *IO MUX* com os pinos de VSPI/HSPI:
  <https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf>
- **Pinos padrão no Arduino-ESP32** (`SS=5, MOSI=23, MISO=19, SCK=18`), no
  arquivo `variants/esp32/pins_arduino.h` do pacote instalado.

> Se a sua placa não for uma DevKitC, procure o diagrama pelo nome do fabricante
> ou do modelo, por exemplo *"ESP32 DevKit V1 30 pin pinout"*. Os números de GPIO
> são os mesmos em qualquer placa com WROOM-32U.

> **Antena:** o sufixo **U** significa que o módulo **não tem antena na
> placa**. Conecte uma antena 2,4 GHz no conector U.FL/IPEX. Sem ela, o Wi-Fi
> fica muito fraco ou nem conecta.

## Ligações

Desligue tudo antes de mexer nos fios. **O RC522 é alimentado com 3,3 V, nunca
com 5 V.** Não ligue o VCC/3V3 de uma placa no da outra. Ligue **somente o GND**
em comum.

### RC522 → ESP32 (SPI / VSPI)

| RC522 | ESP32 | Função |
|---|---|---|
| SDA (SS) | **GPIO5** | Chip select |
| SCK | **GPIO18** | Clock SPI |
| MOSI | **GPIO23** | ESP32 → leitor |
| MISO | **GPIO19** | Leitor → ESP32 |
| RST | **GPIO22** | Reset do leitor |
| IRQ | — | Não usado |
| 3.3V | **3V3** | Alimentação |
| GND | **GND** | Terra |

> O pino **SDA** do RC522 é o *chip select* (SS/NSS) do SPI, não o SDA de I2C.
> Por isso ele vai no **GPIO5 (VSPI_CS)**, e não no GPIO21 (SDA da ESP32).
> O GPIO22 aparece no pinout como VSPI_WP/SCL, mas aqui é usado como GPIO comum
> para o RST, já que o projeto não usa I2C.

### ESP32 ⇄ FPGA DE0-CV (UART2)

| De | Para | Sinal |
|---|---|---|
| ESP32 **GPIO17** (TX2) | DE0-CV JP2 GPIO_1_D22 / PIN_C15 | `rfid_rx`: comando `RNN\n` |
| DE0-CV JP2 GPIO_1_D20 / PIN_A14 | ESP32 **GPIO16** (RX2) | `uart_tx`: telemetria `AEF1` |
| GND ESP32 | GND DE0-CV | Referência comum (obrigatória) |

A UART usa **115200 baud, 8-N-1** e níveis de **3,3 V** dos dois lados. A
DE0-CV e a ESP32 operam em 3,3 V, então não há conversor de nível. Os pinos da
FPGA **não mudaram**.

### Pinos que devem ficar livres

- **GPIO1/GPIO3 (TX0/RX0):** são do USB. Ficam livres para gravação e logs.
- **GPIO6–GPIO11:** ligados à flash interna. Não use.
- **GPIO0, GPIO2, GPIO12, GPIO15:** pinos de *strapping*. Evite ligar coisas que
  forcem nível no boot. O GPIO5 também é strapping, mas pode ser usado como SS
  do RC522, porque o leitor não força esse pino.
- **GPIO34–39:** só aceitam entrada.

Para mudar algum pino, descomente a linha `AEF_PIN_*` correspondente em
`config.h`.

## Preparar o ambiente (Arduino IDE)

1. **Placas:** em *Boards Manager*, instale **esp32 by Espressif Systems**
   (testado com 3.3.12). Selecione a placa **ESP32 Dev Module**.
2. **Bibliotecas:** em *Library Manager*, instale **MFRC522** (GithubCommunity,
   testado com 1.4.12) e **PubSubClient** (Nick O'Leary).
3. **Porta:** a placa aparece como *Silicon Labs CP210x* ou *CH340/CH9102*.
   Escolha essa COM. Se nenhuma porta aparecer, instale o driver do conversor
   USB da sua placa.

> Se o upload travar em `Connecting...`, segure o botão **BOOT** até começar a
> gravação.

## Passo 0 (opcional): teste rápido do leitor com janela

1. Grave `tools/rfid_test/rfid_test.ino` e feche o Monitor Serial do Arduino IDE.
2. No PowerShell do Windows, rode:

   ```powershell
   powershell -ExecutionPolicy Bypass -File esp\tools\rfid_test\rfid_test_gui.ps1 -Port COM14
   ```

3. A janela verifica se o RC522 responde pelo SPI e depois pede: **aproxime o
   cartão**, **retire**, **aproxime de novo**. No fim mostra *RFID FUNCIONANDO*
   e o UID do cartão. Se algo falhar, ela indica o passo e o que conferir.

## Passo 1: descobrir o UID dos cartões

1. Grave `tools/uid_reader/uid_reader.ino`.
2. Abra o Monitor Serial a **115200 baud**.
3. Na primeira linha deve aparecer `RC522 pronto (VersionReg=0x92)` (ou `0x91`,
   `0x88` em clones). Se aparecer `RC522 nao respondeu (VersionReg=0x00)` ou
   `0xFF`, confira os fios SPI, o 3V3 e o GND.
4. Aproxime cada cartão e anote o UID hexadecimal impresso, por exemplo
   `A1B2C3D4`.

UIDs servem para identificar cartões por conveniência. Não são credenciais
seguras de pagamento.

## Passo 2: configurar e gravar a ponte

1. Copie `aef_bridge/config.example.h` para `aef_bridge/config.h`. Esse arquivo
   está no `.gitignore` e não vai para o Git.
2. Preencha:
   - `AEF_WIFI_SSID` e `AEF_WIFI_PASSWORD`. Use rede **2,4 GHz**: a ESP32 não
     conecta em 5 GHz.
   - `AEF_MQTT_HOST`: o **IP do computador** com o broker, na mesma rede. Não
     use `localhost`, que apontaria para a própria ESP32.
   - `AEF_DEVICE_ID`: identificador da bancada.
   - `AEF_RFID_TAG_N_UID` com o UID do cartão e `AEF_RFID_TAG_N_ITEM` com o
     produto (1–10). Deixe vazios os slots sem cartão.
3. Abra `aef_bridge/aef_bridge.ino`, selecione **ESP32 Dev Module** e grave.
   Os fios da FPGA podem ficar ligados.

### O que aparece no Monitor Serial (115200)

```
[AEF] ponte ESP32 iniciando
[AEF] FPGA UART2: RX=GPIO16 TX=GPIO17 115200 baud
[RFID] RC522 pronto (VersionReg=0x92)
[WiFi] conectando em "MinhaRede"...
[WiFi] conectado, IP 192.168.1.42
[MQTT] conectado a 192.168.1.100:1883 como aef-esp32-a1b2c3-0
[RFID] UID A1B2C3D4 -> item 3
[RFID] comando enviado a FPGA: R03
[FPGA] seq=000012 evento=compra_aprovada item=3
[MQTT] publicado em aventura_financeira/telemetria
[RFID] cartao removido, leitor liberado
```

Esses logs vão **só pelo USB**. A FPGA nunca recebe esse texto. Para silenciar,
use `#define AEF_DEBUG 0` em `config.h`.

## Como a ponte funciona

### Compra por borda única (RFID → FPGA)

Ao ler um UID cadastrado, o firmware envia `RNN\n` **uma única vez** pela UART2
(`R03\n` = item 3). Depois disso, o leitor fica travado nesse cartão. Ele só é
liberado depois de **300 ms sem detectar o cartão**. Assim, manter o cartão no
leitor não repete a compra. UID não cadastrado não envia nada, só gera log.

Na FPGA, o receptor valida o quadro e mantém a compra pendente até a FSM
registrar a ação. Saldo e inventário são verificados lá.

### Telemetria (FPGA → backend)

A FPGA envia linhas `AEF1,...` (13 campos separados por vírgula, terminadas em
`\n`) pela UART2. A ESP32:

1. Valida o quadro. Linhas inválidas ou longas demais são descartadas e geram
   log.
2. Converte a unidade financeira da RTL para centavos de BRL e calcula o delta
   de saldo.
3. Gera um `session_id` novo no evento `inicio_sessao`.
4. Coloca o JSON numa fila de até 4 mensagens e publica no MQTT quando há
   conexão.

O horário (`timestamp`) vem de NTP. Enquanto não sincroniza, vai como `null`.

### Reconexão automática

Se cair, o Wi-Fi é tentado de novo a cada 10 s e o MQTT a cada 5 s. A leitura de
RFID e a UART continuam funcionando sem rede, mas as mensagens que não couberem
na fila são descartadas.

## Rede e painel

Inicie um broker MQTT acessível pela rede (por exemplo, Mosquitto com
`listener 1883 0.0.0.0`). Depois, na raiz do repositório:

```sh
npm --prefix back install
MQTT_URL=mqtt://localhost:1883 npm --prefix back start
```

Abra `http://localhost:3000` (ou `http://IP-DO-SERVIDOR:3000`). Essa origem
serve o painel e o WebSocket. Para acompanhar, use `GET /health` e o indicador
de conexão do painel.

## Testes

Teste do parser no PC, sem hardware:

```sh
sh esp/testbench/run_tests.sh
```

Compilação por linha de comando (opcional):

```sh
arduino-cli compile -b esp32:esp32:esp32 esp/aef_bridge
arduino-cli compile -b esp32:esp32:esp32 esp/tools/uid_reader
```

## Problemas comuns

| Sintoma | O que verificar |
|---|---|
| `RC522 nao respondeu (0x00/0xFF)` | Fios SCK/MISO/MOSI/SS trocados, RC522 sem 3V3, GND solto |
| Cartão lido, mas `nao cadastrado` | UID em `config.h` diferente do impresso (sem espaços, hexadecimal) |
| `R0N` enviado, mas a FPGA não reage | GPIO17 → PIN_C15, GND comum, FPGA programada com o `.sof` atual |
| FPGA envia, mas não aparece `[FPGA]` | PIN_A14 → GPIO16, baud 115200 |
| `[FPGA] quadro invalido` | Formato `AEF1` diferente do esperado (ver `telemetry_protocol.h`) |
| Wi-Fi não conecta | Antena U.FL ligada? Rede é 2,4 GHz? SSID/senha corretos? |
| `[MQTT] falha ... (estado -2)` | IP do broker, firewall do Windows na porta 1883, broker ouvindo em `0.0.0.0` |
| Upload preso em `Connecting...` | Segurar o botão BOOT durante o início da gravação |
