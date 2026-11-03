# Aventura Financeira Evolution — Front-end

Painel web para computador para acompanhar a partida, o inventário e os dados
financeiros enviados pelo jogo. A tela destaca a rodada e a jogada, usa imagens
dos itens e apresenta valores em formato simplificado, com o valor exato
disponível como detalhe. O layout é exclusivo para computador e requer uma
janela com pelo menos 1100 pixels de largura; telas menores recebem um aviso,
sem uma interface móvel ou para tablet.

O front-end é somente leitura em relação ao jogo: as ações são feitas nos
controles físicos ligados à FPGA. A **Calculadora** é uma ferramenta local de
estimativa e não altera nem envia dados para a partida. A aba **Estatísticas**
apresenta os eventos recebidos e a evolução da sessão.

## Executar

Sirva esta pasta com qualquer servidor HTTP e abra `index.html`. Por exemplo,
na raiz do repositório:

```sh
python3 -m http.server 8000 --directory frontend
```

Depois, acesse `http://localhost:8000`. Sem conexão, o painel exibe os valores
iniciais da demonstração.

## Fluxo de integração

O fluxo recomendado é:

```text
FPGA → UART → ESP32 → MQTT → backend → WebSocket → front-end
```

A FPGA mantém as regras e o estado oficiais do jogo. A ESP32 transforma os
eventos da UART em JSON e publica no tópico `aventura_financeira/telemetria`.
O backend assina esse tópico, valida e registra os dados e os encaminha ao
navegador. O front-end não envia comandos de volta.

No botão **Conexão de dados**, o modo recomendado é **Backend do jogo**. Informe
o WebSocket do backend; o endereço sugerido para desenvolvimento é
`ws://localhost:3000/ws/telemetria`. O servidor deverá encaminhar snapshots e
eventos JSON em texto. O front também mantém a opção **Broker MQTT direto** para
testes/compatibilidade, que exige MQTT sobre WebSocket (`ws://` ou `wss://`).
Uma porta MQTT TCP comum não pode ser usada diretamente no navegador.

O endereço, o tópico e o modo de conexão são guardados no armazenamento local.
Credenciais MQTT são usadas apenas na conexão e não são persistidas.

## Contrato de telemetria recomendado

Use JSON UTF-8 no MQTT e mantenha os valores monetários em centavos de BRL:

```json
{
  "schema_version": 1,
  "device_id": "aef-fpga-01",
  "session_id": "id-da-partida",
  "seq": 18,
  "timestamp": "2026-11-02T23:46:00.000Z",
  "event": "compra_aprovada",
  "item_id": 7,
  "status": "ok",
  "rodada": 2,
  "jogada": 1,
  "saldo_centavos": 300000,
  "salario_centavos": 640000,
  "valor_investido_centavos": 0,
  "rendimento_centavos": 0,
  "gastos_fixos_centavos": 400000,
  "gastos_unicos_centavos": 1200000,
  "inventario_mask": 64,
  "delta_saldo_centavos": -1200000
}
```

O parser do front-end aceita os campos canônicos em centavos (`*_centavos`) e
converte para reais uma única vez. Também mantém aliases legados como `saldo`,
`salario`, `gastos_fixos`, `item` e `itens`; valores numéricos desses aliases
antigos são interpretados como reais.

**Atenção à escala atual da FPGA:** `circuito/inicializador.v` define o saldo
como `150` e comenta que isso representa R$ 15.000,00. A unidade RTL, portanto,
representa R$ 100,00; para converter um valor RTL em centavos, multiplique por
10.000. Exemplo: `150` → `1.500.000` centavos. Não publique o valor RTL como
reais sem conversão.

O inventário é uma máscara de 10 bits: bit 0 representa o item 1 e bit 9 o item
10. A rodada e jogada no JSON são 1-based para coincidir com o que aparece na
tela. Recomenda-se que cada evento contenha um snapshot financeiro completo,
além do identificador de sequência para detectar duplicatas/lacunas.

O documento de integração para as implementações de FPGA, ESP32 e backend fica
em [`../CONTEXTO_TECNICO_AEF_FPGA_ESP32_FRONTEND.md`](../CONTEXTO_TECNICO_AEF_FPGA_ESP32_FRONTEND.md).

## Arquivos e dados

- `index.html`, `styles.css`, `app.js`: interface e atualização em tempo real.
- `images/logo.jpe`: logo fornecida para o jogo.
- As fotos do tabuleiro e dos protótipos físicos não são mostradas na interface.
- Catálogo, preços e despesas recorrentes: `circuito/processador_acao.v`.
- Regras de rodada e contadores: `circuito/fluxo_dados.v`.

O histórico fica salvo neste navegador e pode ser exportado em CSV. Não são
publicadas mensagens de jogo pela interface.
