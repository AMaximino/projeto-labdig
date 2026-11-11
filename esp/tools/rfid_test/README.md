# Teste do leitor RFID (RC522 + ESP32)

Teste rápido para confirmar que o módulo **RC522** está ligado corretamente na
**ESP32** e lê cartões. O teste pede para **aproximar o cartão**, **retirar** e
**aproximar de novo**, e no fim mostra o UID lido.

São dois arquivos:

| Arquivo | Onde roda | Função |
|---|---|---|
| `rfid_test.ino` | ESP32 | Lê o RC522 e avisa pela Serial USB quando um cartão chega ou sai |
| `rfid_test_gui.ps1` | Windows (PowerShell) | Janela que guia o teste passo a passo e mostra o resultado |

O sketch também pode ser usado sozinho, só com o Monitor Serial (veja
[Teste sem a janela](#teste-sem-a-janela)).

## Ligação

Mesma pinagem do firmware principal (`aef_bridge`). **Alimente o RC522 com
3,3 V, nunca 5 V.**

| RC522 | ESP32 |
|---|---|
| SDA (SS) | GPIO5 |
| SCK | GPIO18 |
| MOSI | GPIO23 |
| MISO | GPIO19 |
| RST | GPIO22 |
| 3.3V | 3V3 |
| GND | GND |
| IRQ | não ligar |

## Como rodar

1. No Arduino IDE, com a placa **ESP32 Dev Module** e a biblioteca **MFRC522**
   instaladas, grave `rfid_test.ino`.
2. **Feche o Monitor Serial** do Arduino IDE (a porta COM só pode ser aberta por
   um programa de cada vez).
3. No PowerShell, na raiz do repositório:

   ```powershell
   powershell -ExecutionPolicy Bypass -File esp\tools\rfid_test\rfid_test_gui.ps1 -Port COM14
   ```

   Troque `COM14` pela porta da sua ESP32. Sem `-Port`, o script usa a última
   porta COM encontrada.

4. Siga as instruções da janela.

## Etapas do teste

```
CONECTAR ──► APROXIME O CARTAO ──► AGORA RETIRE ──► APROXIME DE NOVO ──► RFID FUNCIONANDO
   │               │                    │                  │
   └───────────────┴──── tempo esgotado ou erro ───────────┴──► FALHOU (mostra o que conferir)
```

| # | Etapa | Cor da janela | O que fazer | Tempo limite |
|---|---|---|---|---|
| 1 | RC522 responde pelo SPI | cinza | nada, é automático | 6 s |
| 2 | Cartão detectado | azul — *APROXIME O CARTAO* | encostar o cartão no centro do leitor (até ~3 cm) | 20 s |
| 3 | Retirada detectada | laranja — *AGORA RETIRE* | afastar o cartão do leitor | 20 s |
| 4 | Segunda leitura | azul — *APROXIME DE NOVO* | aproximar o **mesmo** cartão | 20 s |

No final:

- **Verde — RFID FUNCIONANDO:** as duas leituras deram o mesmo UID. Anote o UID
  mostrado para usar no `config.h`.
- **Laranja — LEU OUTRO CARTAO:** a segunda leitura foi de um cartão diferente.
  O leitor funciona; repita com o mesmo cartão para comparar.
- **Vermelho:** alguma etapa falhou (veja a tabela abaixo).

O botão **Repetir teste** recomeça do passo 1 sem precisar fechar a janela.

## Problemas comuns

| Mensagem na janela | Causa provável | O que conferir |
|---|---|---|
| ESP32 NAO RESPONDE | sketch errado gravado ou porta errada | gravar `rfid_test.ino` de novo; conferir a COM |
| Nao foi possivel abrir COMx | porta em uso | fechar o Monitor Serial do Arduino IDE |
| RC522 NAO RESPONDE (`0x00` ou `0xFF`) | SPI ou alimentação | fios SDA/SCK/MOSI/MISO/RST, 3V3 e GND |
| NENHUM CARTAO LIDO | cartão longe ou incompatível | aproximar mais; usar cartão 13,56 MHz (MIFARE) |
| CARTAO NAO FOI RETIRADO | cartão ficou no campo | afastar bem o cartão e repetir |
| SEGUNDA LEITURA FALHOU | leitura instável | mau contato nos jumpers ou distância |
| CONEXAO PERDIDA | cabo USB desconectado | reconectar e abrir a janela de novo |

## Protocolo Serial do `rfid_test.ino`

Serial USB a **115200 baud**, uma mensagem por linha:

| Mensagem | Significado |
|---|---|
| `READY <versao>` | RC522 respondeu (ex.: `READY 0x92`; `0x91` e `0x88` também são válidos) |
| `ERROR <versao>` | RC522 não respondeu (`0x00` ou `0xFF`): problema de fios ou alimentação |
| `CARD <UID>` | cartão detectado; UID em hexadecimal, sem espaços (ex.: `CARD A1B2C3D4`) |
| `REMOVED` | o cartão saiu do campo e ficou fora por pelo menos 300 ms |

Comando aceito: enviar `V` faz a ESP32 reenviar `READY`/`ERROR`. A janela usa
isso no início de cada teste.

### Como a detecção funciona

- O leitor é consultado a cada **100 ms**.
- Quando um cartão é lido, o sketch envia `CARD` **uma única vez** e passa a
  apenas verificar se o cartão continua presente (com `PICC_WakeupA`). Assim,
  deixar o cartão parado em cima do leitor não gera leituras repetidas.
- Se o cartão não responder por **300 ms** seguidos, o sketch envia `REMOVED` e
  volta a esperar um novo cartão. Esse intervalo evita falsos `REMOVED` quando
  o cartão oscila na borda do campo.

## Teste sem a janela

Também dá para testar só com o Monitor Serial do Arduino IDE (115200 baud,
final de linha qualquer):

1. Ao abrir, deve aparecer `READY 0x92` (ou parecido). Se não aparecer, envie
   `V`.
2. Aproxime o cartão: aparece `CARD <UID>`.
3. Retire o cartão: aparece `REMOVED`.
4. Aproxime de novo: aparece `CARD <UID>` com o mesmo UID.
