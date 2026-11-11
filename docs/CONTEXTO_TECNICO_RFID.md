# Contrato técnico RFID e telemetria

## Autoridade e fluxo

```text
RC522 → ESP32 ── comando UART → FPGA (compra/saldo/inventário)
FPGA ── snapshot UART → ESP32 → MQTT → back → WebSocket → front
```

A compra é uma simulação educativa, sem autorização ou cobrança financeira. O
UID é mantido localmente no ESP32 e nunca é publicado no MQTT. UID não é um
segredo criptográfico: não usar esta solução como pagamento real.

- `fpga/rtl/`: regras do jogo, parser UART de comando e telemetria.
- `esp/aef_bridge/`: leitura RC522, mapa UID→item, MQTT e parser `AEF1`.
- `back/src/`: validação, deduplicação, diário JSONL, HTTP e WebSocket.
- `front/`: painel somente de leitura.

## Comando UART ESP32 → FPGA

- Formato: `RNN\n`, ASCII, 115200 baud, 8-N-1.
- `NN`: item decimal `01`–`10`; exemplos `R01\n`, `R10\n`.
- ESP32 TX2/GPIO17 liga a DE0-CV `rfid_rx` em GPIO_1_D22/PIN_C15.
- O receptor FPGA sincroniza o sinal ao clock de 50 MHz, valida caracteres e
  mantém `item_valid` até a FSM registrar a compra.
- O estado da FSM habilita a ação somente em espera de jogada; um cartão
  aproximado antes do início fica pendente até o jogo aceitar ações.
- RC522 mantém o cartão em latch; só rearma após ausência por 300 ms. Cartão
  não cadastrado não gera comando.

## Telemetria FPGA → ESP32

Continua o framing ASCII `AEF1` já descrito pelo firmware: snapshots em linhas
terminadas por LF, 115200 baud, 8-N-1, sequência, evento, item, valores
financeiros com sinal, máscara de inventário, rodada, jogada e status. Os eventos
de compra são `06` aprovada e `07` recusada. A compra só é recusada quando o
item é inválido ou já está no inventário. Se o saldo não for suficiente, a compra
**é aprovada** e o saldo fica negativo. Na sequência, a FSM detecta a falência
(`saldo[20]`) e a FPGA envia o evento `13` (`falencia`) logo após o `06`. Campos monetários no JSON MQTT são
centavos de BRL; cada unidade financeira RTL equivale a R$ 100, portanto
`valor_centavos = valor_RTL × 10.000`.

O firmware só transmite ao FPGA os cartões RFID. A compra retorna pelo fluxo
normal da RTL: `processador_acao.v` valida saldo e duplicidade do item,
atualiza os registradores e a telemetria informa o resultado. A rede nunca
aciona regras diretamente.

## MQTT e navegador

- Tópico: `aventura_financeira/telemetria`.
- ESP32 publica snapshots JSON com `schema_version: 1`.
- Backend valida dispositivo, sessão, sequência, escala, status e campos antes
  de persistir e transmitir.
- WebSocket: `/ws/telemetria`; envelopes de servidor têm `type: "snapshot" | 
  "event"` e `data` com o evento canônico.
- O backend serve o front no mesmo host/porta 3000. O browser calcula a URL WS
  do host atual, desempacota snapshot/event e reconecta após falhas.

## Pinos DE0-CV

O QSF seleciona dispositivo `5CEBA4F23C7` e agora atribui os dois fios ao JP2:

| Sinal RTL | Nome no conector | Pino FPGA | Direção |
|---|---|---|---|
| `uart_tx` | GPIO_1_D20 | PIN_A14 | FPGA TX → ESP32 RX2/GPIO16 |
| `rfid_rx` | GPIO_1_D22 | PIN_C15 | ESP32 TX2/GPIO17 → FPGA RX |

Ambos usam o padrão de I/O 2.5 V no QSF (`uart_tx` explícito, `rfid_rx` pelo
padrão do Cyclone V), igual ao Pin Planner; não altere para 3.3-V LVTTL, pois
o banco 7A conflita com os demais pinos. Confirme a revisão da placa e consulte o manual
DE0-CV ao localizar JP2; o nome GPIO da coluna do conector é a referência do
QSF. Compartilhe GND. Não conecte VCC entre as placas nem aplique 5 V aos GPIOs.

## Referências

- [Guia de ligação e execução](GUIA_IMPLEMENTACAO_FISICA_E_INTERFACE.md)
- [Como jogar (passo a passo)](COMO_JOGAR.md)
- [Firmware e pinagem ESP](../esp/README.md)
- [RTL e Quartus](../fpga/README.md)
- [Backend](../back/README.md)
- [Painel](../front/README.md)
