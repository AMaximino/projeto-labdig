# Aventura Financeira Evolution

Jogo de educação financeira com regras executadas na FPGA e painel de
telemetria. A compra RFID é uma simulação educativa: um cartão cadastrado
seleciona um item; não há cobrança ou processamento de pagamento.

## Pastas

- [`fpga/`](fpga/README.md): RTL, testbenches, projeto Quartus, simulação e
  pinagens da placa.
- [`esp/`](esp/README.md): firmware ESP32, leitor RFID RC522 e teste do parser.
- [`back/`](back/README.md): subscriber MQTT, API, histórico e WebSocket; também
  serve os arquivos do painel.
- [`front/`](front/README.md): interface web somente de leitura.

## Fluxo RFID e telemetria

```text
Cartão RFID → RC522 → ESP32 ── UART comando ──► FPGA (compra e saldo)
                                      FPGA ── UART telemetria ──► ESP32
FPGA → ESP32 → Wi-Fi/MQTT → back (HTTP + WebSocket) → front
```

Cada UID cadastrado no firmware corresponde a um item (1–10). O ESP32 envia
`RNN\n` uma vez ao aproximar um cartão; só aceita nova leitura depois de
confirmar que ele saiu do campo. A FPGA valida a compra com suas regras atuais,
atualiza o saldo e o inventário e transmite o evento `compra_aprovada` ou
`compra_recusada`. Só item repetido ou inválido é recusado. Uma compra maior que
o saldo é aprovada, deixa o saldo negativo e encerra o jogo por falência
(evento `falencia`). O painel não envia ações ao jogo.

## Início rápido

1. Inicie um broker MQTT acessível pelo computador e pela ESP32 (tópico
   `aventura_financeira/telemetria`).
2. Copie `esp/aef_bridge/config.example.h` para `esp/aef_bridge/config.h`,
   configure Wi-Fi/broker e cadastre os UIDs reais dos cartões.
3. Instale as bibliotecas Arduino `PubSubClient` e `MFRC522`, grave
   `esp/aef_bridge/aef_bridge.ino` e programe a FPGA pelo projeto
   `fpga/quartus/projeto_labdig.qpf`.
4. Inicie a aplicação a partir da raiz:

   ```sh
   npm --prefix back install
   MQTT_URL=mqtt://localhost:1883 npm --prefix back start
   ```

5. Abra `http://localhost:3000`. O backend serve o front e o navegador conecta
   automaticamente a `ws://<mesmo-host>:3000/ws/telemetria`. Para outro
   computador, abra `http://IP-DO-SERVIDOR:3000`.

Veja [o guia de ligação e inicialização](GUIA_IMPLEMENTACAO_FISICA_E_INTERFACE.md)
e os READMEs de cada pasta antes de conectar os fios.
