# Como jogar: subir o circuito completo

Passo a passo para colocar o jogo para funcionar: FPGA + ESP32 + RFID + painel
web. Os comandos `sh` rodam no terminal do **WSL (Ubuntu)**. Os comandos
`powershell` rodam no **PowerShell do Windows**.

```
Cartão ─► RC522 ─► ESP32 ──UART──► FPGA (jogo)
                     ▲                │
                     └──── telemetria ┘
ESP32 ──Wi-Fi──► Mosquitto (WSL, porta 1883) ──► backend (porta 3000) ──► painel no navegador
```

## Checklist rápido (uso diário)

Se tudo já foi configurado uma vez e a rede é a mesma:

1. Conecte o PC na rede **LAB_DIGITAL**.
2. Rode o **redirecionamento da porta 1883** (passo 3). O IP do WSL muda a
   cada reinício do PC.
3. No WSL: `npm --prefix back start` na raiz do projeto (passo 4).
4. Abra `http://localhost:3000`.
5. Ligue a FPGA com o `.sof` gravado e ligue a ESP32 no USB.
6. Aperte **iniciar** na placa e jogue.

---

## 1. Rede Wi-Fi

- Conecte o PC na rede **LAB_DIGITAL**. A ESP32 só funciona em **2,4 GHz**.
- Descubra o IP do PC na rede. No PowerShell:

  ```powershell
  ipconfig
  ```

  Procure o **Endereço IPv4** em "Adaptador de Rede sem Fio Wi-Fi". Em
  2026-11-11 ele era `192.168.17.221`.

## 2. Configurar e gravar a ESP32 (só quando mudar rede, IP ou cartões)

1. Abra `esp/aef_bridge/config.h`. Esse arquivo não vai para o Git, porque tem
   a senha da rede. Se ele não existir, copie de `config.example.h`. Confira:

   ```c
   #define AEF_WIFI_SSID "LAB_DIGITAL"
   #define AEF_WIFI_PASSWORD "..."          // senha da rede
   #define AEF_MQTT_HOST "192.168.17.221"   // IPv4 do PC (passo 1)
   #define AEF_MQTT_USERNAME ""
   #define AEF_MQTT_PASSWORD ""
   #define AEF_RFID_AUTO_ASSIGN 1           // 1 = cartão novo vira o próximo item
   ```

   Se o IP do PC mudou, atualize `AEF_MQTT_HOST` e grave de novo.

2. No **Arduino IDE**: abra `esp/aef_bridge/aef_bridge.ino`, escolha a placa
   **ESP32 Dev Module** e a porta COM da ESP (por exemplo `COM14`) e clique em
   **Upload**. As bibliotecas necessárias são **MFRC522** e **PubSubClient**.
3. Se o upload ficar parado em `Connecting...`, segure o botão **BOOT** da ESP32
   até começar a gravar.

## 3. Broker MQTT (Mosquitto no WSL)

O Mosquitto já está instalado no WSL e inicia sozinho, ouvindo em `0.0.0.0:1883`
sem senha (`/etc/mosquitto/conf.d/aef.conf`). Para conferir:

```sh
systemctl is-active mosquitto      # deve responder "active"
sudo systemctl start mosquitto     # só se não estiver ativo
```

### Redirecionar a porta 1883 do Windows para o WSL (a cada reinício do PC)

A ESP32 conecta no IP do Windows, mas o Mosquitto roda dentro do WSL, que tem
outro IP. O Windows precisa repassar a porta 1883.

1. No WSL, descubra o IP do WSL:

   ```sh
   ip -4 addr show eth0 | grep inet     # ex.: 172.25.124.12
   ```

2. No **PowerShell como administrador**, troque `IP_DO_WSL` pelo valor acima:

   ```powershell
   netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=1883
   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=1883 connectaddress=IP_DO_WSL connectport=1883
   ```

3. Só na primeira vez, libere a porta no firewall (também como administrador):

   ```powershell
   New-NetFirewallRule -DisplayName "MQTT AEF 1883" -Direction Inbound -Protocol TCP -LocalPort 1883 -Action Allow
   ```

Para conferir o redirecionamento: `netsh interface portproxy show all`.

## 4. Backend e painel

Na raiz do projeto, no WSL:

```sh
npm --prefix back install     # só na primeira vez
npm --prefix back start
```

Deixe esse terminal aberto. Ele deve mostrar:

```
Backend pronto em http://localhost:3000 e ws://localhost:3000/ws/telemetria.
MQTT conectado em mqtt://localhost:1883; assinando aventura_financeira/telemetria.
```

Abra **`http://localhost:3000`** no navegador do Windows. Para conferir o estado
do backend: `http://localhost:3000/health` deve mostrar `"mqtt_connected":true`.

## 5. FPGA

1. Ligue a DE0-CV e grave o `.sof` atual pelo **Quartus → Programmer**
   (USB-Blaster). O projeto fica em `fpga/quartus/`.
2. Confira os fios entre a FPGA e a ESP32:

   | ESP32 | FPGA (JP2) | Função |
   |---|---|---|
   | GPIO17 (TX2) | PIN_C15 (`rfid_rx`) | compra pelo cartão |
   | GPIO16 (RX2) | PIN_A14 (`uart_tx`) | telemetria |
   | GND | GND | referência comum (obrigatório) |

3. Os botões e chaves estão em `fpga/configuracao/pinagens/pinagem_com_nossos_botoes.csv`
   (iniciar `PIN_E14`, reset `PIN_B15`, trabalhar `PIN_K16`, estudar `PIN_G12`,
   investir `PIN_G15`, resgatar `PIN_F12`, comprar `PIN_E16`, vender `PIN_F15`).

## 6. Jogar

1. Ligue a ESP32 no USB. Ela conecta sozinha no Wi-Fi e no MQTT.
2. Aperte **iniciar** na FPGA. O painel recebe `inicio_sessao`.
3. Cada rodada tem **3 jogadas**. Trabalhar ou estudar consome uma jogada.
   Comprar, vender, investir e resgatar não consomem.
4. Para comprar com cartão: aproxime o cartão do leitor e depois retire. Cada
   aproximação vale uma compra só. Com `AEF_RFID_AUTO_ASSIGN 1`, cada cartão
   novo vira o próximo item livre (8, 7, 9, 10, 1, ...). Essa associação vale
   até a ESP reiniciar.
5. A compra é aceita **mesmo sem saldo suficiente**. Se o saldo ficar
   negativo, a FPGA declara `falencia` e o jogador perde. Uma compra só é
   recusada se o item já estiver no inventário.
6. Se o jogador falir (`falencia`) ou o jogo acabar (`fim_jogo`), a FPGA ignora
   as compras até apertar **iniciar** de novo.

## Ver o log da ESP32 (opcional)

Arduino IDE → **Monitor Serial** a **115200 baud**. Um boot normal:

```
[RFID] RC522 pronto (VersionReg=0x88)
[WiFi] conectado, IP 192.168.17.110
[MQTT] conectado a 192.168.17.221:1883 como aef-esp32-...
```

Uma compra:

```
[RFID] UID F382862A -> item 8
[RFID] comando enviado a FPGA: R08
[FPGA] seq=2 evento=compra_aprovada item=8
[MQTT] publicado em aventura_financeira/telemetria
```

Feche o Monitor Serial antes de gravar a ESP ou de usar outro programa na porta
COM.

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| `[WiFi]` não conecta | rede 2,4 GHz? SSID/senha no `config.h`? antena ligada? |
| `[MQTT] falha ... (estado -2)` | refazer o redirecionamento do passo 3 (o IP do WSL mudou); conferir `AEF_MQTT_HOST` = IPv4 atual do PC; firewall |
| Painel não atualiza, mas a ESP diz `publicado` | backend rodando? `/health` com `mqtt_connected:true`? recarregar a página |
| Cartão lido, mas não aparece `[FPGA]` | FPGA programada? jogo iniciado? fios GPIO17/GPIO16/GND |
| `RC522 nao respondeu` | fios do leitor e 3,3 V; teste com `esp/tools/rfid_test/` |
| Upload preso em `Connecting...` | segurar BOOT na ESP32 durante a gravação |
| Rede do laboratório bloqueia a ESP | usar o hotspot do celular (2,4 GHz) e atualizar SSID, senha e IP no `config.h` |
