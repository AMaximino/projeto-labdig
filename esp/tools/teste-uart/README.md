# Teste da telemetria UART

Este sketch recebe os dados de telemetria da FPGA no ESP8266 e os encaminha
sem alteracao para o Monitor Serial. Nao usa Wi-Fi nem MQTT.

## Como testar

1. Abra `teste-uart.ino` na Arduino IDE, selecione a placa ESP8266 e grave.
2. Ligue `uart_tx` da FPGA ao GPIO14 (D5 em NodeMCU/D1 mini) do ESP8266.
3. Ligue o GND da FPGA ao GND do ESP8266.
4. Abra o Monitor Serial em **115200 baud** e gere eventos na FPGA.

O sinal da FPGA deve ser compativel com 3,3 V; nao conecte sinais de 5 V
diretamente ao ESP8266. Para outra placa ou pino, altere `FPGA_RX_PIN` no
sketch.

## Formato recebido

O modulo de telemetria transmite uma linha CSV por evento, terminada por
`LF` (`\n`), no formato:

```text
AEF1,sequencia,event_code,item_id,saldo,salario,investimento,gastos_fixos,gastos_unicos,inventario,rodada,jogada,status
```

Sao 13 campos separados por virgula, sempre nesta ordem:

| # | Campo | Significado |
|---|---|---|
| 1 | `AEF1` | Identificador e versao do protocolo de telemetria. |
| 2 | `sequencia` | Numero sequencial do quadro, com seis digitos (`000001` a `999999`). Ajuda a identificar e ordenar eventos; volta a `000001` depois de `999999`. |
| 3 | `event_code` | Codigo decimal de dois digitos que identifica o evento. A tabela abaixo lista os codigos usados. |
| 4 | `item_id` | Item relacionado a acao: `00` quando nao ha item especifico; `01` a `10` para os itens do jogo. |
| 5 | `saldo` | Saldo atual do jogador, com sinal e sete caracteres, incluindo o sinal (por exemplo, `+0001126`). |
| 6 | `salario` | Salario atual, no mesmo formato dos demais valores financeiros. |
| 7 | `investimento` | Valor atualmente investido, no mesmo formato. |
| 8 | `gastos_fixos` | Total de gastos fixos, no mesmo formato. |
| 9 | `gastos_unicos` | Total de gastos unicos, no mesmo formato. |
| 10 | `inventario` | Mascara hexadecimal de quatro digitos. Os bits `0` a `9` representam os itens `1` a `10`; bit ligado significa que o jogador possui o item. |
| 11 | `rodada` | Contador de rodada enviado pela FPGA, como valor decimal de dois digitos. |
| 12 | `jogada` | Contador de jogada enviado pela FPGA, como valor decimal de dois digitos. |
| 13 | `status` | Resultado/qualificacao do evento: `0` informativo, `1` aceito ou aprovado, `2` recusado. |

Os valores financeiros sao inteiros internos da FPGA, com sinal. Cada unidade
corresponde a **R$ 100,00** (ou 10.000 centavos). Por exemplo, `+0001126`
representa `1126` unidades, ou **R$ 112.600,00**. O sinal faz parte do campo:
`-0000010` representa dez unidades negativas. `inventario` e hexadecimal:
por exemplo, `0080` significa que o bit 7 esta ligado, portanto o jogador tem
o item 8.

### Codigos de evento

| Codigo | Evento |
|---|---|
| `01` | Inicio da sessao |
| `02` | Trabalhar |
| `03` | Estudar |
| `04` | Investir |
| `05` | Resgatar investimento |
| `06` | Compra aprovada |
| `07` | Compra recusada |
| `08` | Venda aprovada |
| `09` | Venda recusada |
| `11` | Fim de rodada |
| `12` | Fim de jogo |
| `13` | Falencia |
| `14` | Posicao do seletor de item (`seletor_item`) |

Para os eventos `06` a `09`, `item_id` indica o item comprado ou vendido. No
evento `14`, `item_id` e a posicao atual do seletor de item (`01` a `10`), com
`status` `0`. A FPGA so envia o `14` quando o seletor fica ~80 ms parado numa
posicao valida diferente da ultima informada, e apenas com a FSM em
`ESPERA_ACAO`; depois de `iniciar`, a posicao e reenviada. Para os outros
eventos, `00` indica que nao ha um item associado. O codigo `10` nao
e usado atualmente.

### Exemplo decodificado

```text
AEF1,000164,02,00,+0001126,+0000144,+0000000,+0000040,+0000080,0080,08,01,1
```

- Quadro `000164`: evento **trabalhar** (`02`), sem item associado (`00`).
- Saldo `+0001126` = R$ 112.600,00; salario `+0000144` = R$ 14.400,00.
- Investimento `+0000000` = R$ 0,00; gastos fixos `+0000040` = R$ 4.000,00;
  gastos unicos `+0000080` = R$ 8.000,00.
- Mascara `0080`: item 8 no inventario; contadores transmitidos: rodada `08`,
  jogada `01`.
- Status `1`: acao aceita.

O sketch mostra a linha exatamente como recebida; nao interpreta nem converte
os campos.
