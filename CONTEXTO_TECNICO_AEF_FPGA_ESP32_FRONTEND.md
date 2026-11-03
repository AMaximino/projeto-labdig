# Aventura Financeira Evolution — contexto para FPGA, ESP8266 e interface

Este documento é um handoff técnico para desenvolver a telemetria do jogo sem
substituir nem deslocar as regras que já são executadas na FPGA. FPGA, ESP8266,
backend e front-end devem ser implementáveis separadamente, mas precisam
compartilhar o contrato de dados descrito aqui.

## 1. Objetivo e limites

- A FPGA continua sendo a autoridade da partida: lê os botões físicos, aplica
  as regras, atualiza saldo, inventário, rodada e jogada, e decide se uma ação
  foi aceita ou recusada.
- A ESP8266 atua como ponte de comunicação. Ela recebe telemetria da FPGA por
  UART, converte-a para JSON e publica no MQTT. Não decide compras nem recalcula
  o estado do jogo.
- O backend recebe os eventos publicados no broker, valida e registra a sessão
  e os encaminha ao front-end em tempo real por WebSocket (ou SSE).
- O front-end é somente leitura em relação à partida. Não publica ações, não
  altera o estado da FPGA e não substitui os botões físicos.
- A calculadora do front-end é uma ferramenta independente para estimativas.
  Seus resultados nunca são enviados ao jogo.

Fluxo recomendado:

```text
Botões/sensores físicos
          │
          ▼
FPGA (regras e estado autoritativos)
          │ UART TX — 115200, 8-N-1
          ▼
ESP8266 (ponte UART → JSON)
          │ Wi-Fi / MQTT publish
          ▼
Broker MQTT ──► Backend (subscriber, validação, histórico)
                         │ WebSocket /telemetria
                         ▼
                    Front-end web
```

O projeto atual já possui uma conexão MQTT sobre WebSocket diretamente no
navegador. Ela serve como caminho de demonstração/compatibilidade, mas não é um
backend de aplicação. Para a arquitetura acima, a implementação futura deve
adicionar um modo WebSocket do backend e deixar a FPGA/ESP8266 independentes do
protocolo interno do navegador.

## 2. Contexto do jogo existente

Os arquivos Verilog atuais são a referência para preservar a lógica:

- `circuito/circuito_jogo_financeiro.v`: módulo de topo; recebe `iniciar`,
  ações, seletor de item e configuração de display; aciona displays e expõe
  `indicador_itens`, `ultima_jogada`, `ultima_rodada`, `terminou` e `perdeu`.
- `circuito/fluxo_dados.v`: registra o saldo, salário, investimento, despesas e
  máscara de itens; liga o processador de ações/eventos; controla contadores.
- `circuito/unidade_controle.v`: máquina de Moore com estados separados e
  nomes explícitos para iniciar, esperar, registrar, processar, verificar e
  encerrar. As saídas dependem somente do estado atual; preservar esse padrão
  ao alterar a sequência do jogo. Não juntar estados de registro, processamento
  e verificação só para reduzir a quantidade: a sequência explícita facilita
  simulação e diagnóstico.
- `circuito/processador_acao.v`: ações e catálogo de preços/despesas.
- `circuito/processador_evento.v`: aplica rendimento e despesas no fluxo de
  eventos/rodadas.
- `circuito/inicializador.v`: valores iniciais.
- `frontend/docs/AEX5_T6BA6_Spec.pdf`: especifica FPGA → UART → ESP8266 → MQTT,
  dashboard, registro da sessão e clareza/acessibilidade para pessoas com TEA.
- `frontend/docs/Semana1_T6BA6_Relato.pdf`: relata a arquitetura e o fluxo de
  dados/FSM da implementação.

### Regras e valores observados no código

- Saldo inicial: `150` unidades internas = R$ 15.000,00.
- Salário inicial: `64` unidades internas = R$ 6.400,00.
- Despesas fixas iniciais: `40` unidades internas = R$ 4.000,00.
- Estudar: custo `120` unidades = R$ 12.000,00; aumenta o salário em `40`
  unidades = R$ 4.000,00.
- Investir/resgatar: até `10` unidades = R$ 1.000,00 por ação.
- O rendimento é calculado como `valorInvestido >> 2` ao iniciar nova rodada
  (25% do valor investido na escala inteira da RTL).
- A máscara de inventário tem 10 bits. bit 0 é item 1; bit 9 é item 10.
- Há três jogadas por rodada e até quinze rodadas pretendidas. Os contadores
  internos são base zero; a interface deve mostrar rodada 1–15 e jogada 1–3.
- Ações codificadas em `processador_acao.v`: vender `000001`, comprar
  `000010`, resgatar `000100`, investir `001000`, trabalhar `010000`, estudar
  `100000`.

### Escala monetária — ponto importante

Os valores de dinheiro da RTL não são reais nem centavos: o comentário do
`inicializador.v` associa `150` a R$ 15.000, `64` a R$ 6.400 e `40` a R$ 4.000.
Portanto, **1 unidade interna RTL equivale a R$ 100,00**. Para transportar
dinheiro como centavos no JSON, a ESP8266 deve converter:

```text
valor_centavos = valor_unidades_rtl × 10.000
```

Exemplo: saldo RTL `150` → `1.500.000` centavos → R$ 15.000,00. Não enviar `150`
como se fossem R$ 150,00, centavos ou reais. Se a implementação alterar a escala
da RTL, documentar a nova escala e atualizar o conversor e os testes juntos.

## 3. Contrato FPGA-UART-ESP8266 implementado

### Requisitos já presentes na especificação

- UART transmissora na FPGA, 115200 bps, 8 bits, sem paridade, 1 stop bit
  (8-N-1).
- A FPGA informa pelo menos código do evento, item e saldo resultante.
- A ESP8266 interpreta a UART, formata JSON e publica no tópico
  `aventura_financeira/telemetria`.
- Compra recusada deve ser comunicada; não acionar o atuador quando o saldo
  for insuficiente.

### Enquadramento UART

O PDF não fixa framing nem códigos de evento. A implementação usa uma linha
ASCII por evento, terminada por `\n`, separada por vírgulas, sem JSON na FPGA.
Todos os campos numéricos têm largura fixa:

```text
AEF1,000001,06,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,00,00,1\n
```

- `AEF1`: identificador/versão do framing; `seq`: sequência decimal de 6
  dígitos, de 1 a 999999 (reinicia com reset da FPGA).
- `event`: código decimal de 2 dígitos; `item_id`: índice decimal de 2 dígitos,
  00 quando não aplicável e 01–10 conforme catálogo.
- Os cinco campos financeiros são complemento de dois convertido para decimal
  com sinal explícito e sete dígitos (`+0000150`, `-0000120`), na escala RTL.
- `inventory_mask`: quatro dígitos hexadecimais maiúsculos, com zeros à
  esquerda; bit 0 representa o item 1.
- `round0` e `move0`: contadores base zero, dois dígitos; o JSON soma 1.
- `status`: `0` normal/fim, `1` ação aceita, `2` ação recusada.
- A linha tem 76 bytes contando o `\n`. Não há checksum; o firmware rejeita
  linhas incompletas, compridas, com campos fora do formato ou códigos
  desconhecidos, mas não consegue detectar toda corrupção que ainda forme
  caracteres válidos.

Tabela compartilhada de `event`:

| Código | Nome JSON | Significado |
|---|---|---|
| 01 | `inicio_sessao` | Estado inicial registrado |
| 02 | `trabalhar` | Trabalho aceito |
| 03 | `estudar` | Estudo aceito |
| 04 | `investir` | Investimento aceito |
| 05 | `resgatar` | Resgate aceito |
| 06 / 07 | `compra_aprovada` / `compra_recusada` | Compra aceita / recusada |
| 08 / 09 | `venda_aprovada` / `venda_recusada` | Venda aceita / recusada |
| 10 | reservado | `fim_jogada` não é emitido nesta versão |
| 11 | `fim_rodada` | Rendimento e contador de rodada atualizados |
| 12 | `fim_jogo` | Fim normal |
| 13 | `falencia` | Saldo negativo |

A linha completa precisa ser transmitida somente após a FPGA registrar os novos
valores do evento; não amostrar barramentos combinacionais durante a transição
da FSM. A RTL registra evento/status e a UART transmite pelo clock de 50 MHz,
sem alterar os botões ou displays. `uart_tx` é uma saída de topo nova e ainda
precisa de uma atribuição QSF para um pino de expansão livre confirmado na
placa. O nível elétrico depende do banco/padrão IO; confirmar compatibilidade
com 3,3 V e usar conversão de nível se necessário.

O firmware ESP8266 usa `SoftwareSerial` RX configurável e buffer de recepção
de 256 bytes. Ele valida a linha, converte cada unidade RTL para 10.000
centavos, cria `session_id` ao receber `inicio_sessao` e publica JSON em QoS 0.
Uma fila RAM comporta quatro mensagens; se excedida, o firmware registra
descarte no Serial, mas não bloqueia a partida. Testar a recepção a 115200 baud
com Wi-Fi ativo na placa escolhida; em caso de perda, usar o RX UART0 de
hardware e desligar o diagnóstico USB. O backend é idempotente para mensagens
repetidas.

## 4. Contrato recomendado MQTT → backend → front-end

### MQTT

- Tópico de telemetria: `aventura_financeira/telemetria`.
- Direção ESP8266 → broker; o front-end/backend não enviam comandos ao tópico.
- O firmware atual usa MQTT QoS 0. O backend torna o processamento idempotente
  por `device_id + session_id
  + seq`.
- Publicar JSON UTF-8. O broker deve ser configurado para acesso somente de
  publicação para a ESP8266 e somente de leitura para o backend.

Exemplo de estado após uma compra aprovada (valores monetários sempre em
**centavos de BRL**, não em unidade interna Verilog):

```json
{
  "schema_version": 1,
  "device_id": "aef-fpga-01",
  "session_id": "id-gerado-no-inicio-da-partida",
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

Convenções:

- `rodada` e `jogada` no JSON são 1-based, no mesmo formato mostrado no front.
- `item_id` é o índice 1–10; `inventario_mask` usa bit 0 para item 1.
- `delta_saldo_centavos` é o delta efetivo assinado (positivo quando o saldo
  aumenta). Recusa tem delta zero, estado inalterado e `status: "recusada"`.
- `event` permitido: `inicio_sessao`, `trabalhar`, `estudar`, `investir`,
  `resgatar`, `compra_aprovada`, `compra_recusada`, `venda_aprovada`,
  `venda_recusada`, `fim_rodada`, `fim_jogo` ou `falencia`. O código 10 está
  reservado no framing e não é publicado pela FPGA atual.
- Cada evento deve carregar um snapshot completo dos campos financeiros e do
  inventário. Assim o backend/front não precisam inferir o saldo ou reconstruir
  a máscara a partir de eventos perdidos.
- `timestamp` é UTC ISO-8601. O backend também deve registrar o horário de
  recebimento.
- `schema_version` permite mudar o contrato sem quebrar o front antigo.

### Backend e transporte para o navegador

O backend implementado em `backend/`:

1. Assina o tópico MQTT, valida versão, tipos, limites, campos obrigatórios e
   sequência por dispositivo/sessão; mensagens duplicadas ou antigas são
   ignoradas e lacunas são registradas sem inventar eventos.
2. Registra erros de JSON/schema no log; valores inválidos não atualizam estado.
3. Persiste eventos em `backend/data/events.jsonl` e expõe `GET /health`,
   `GET /api/sessions`, `GET /api/sessions/<device_id>%3A<session_id>/snapshot`
   e `GET /api/sessions/<device_id>%3A<session_id>/events?limit=100`.
4. Distribui mensagens em `ws://localhost:3000/ws/telemetria`. Ao conectar,
   envia `{"type":"snapshot","data":...}` se houver estado e, depois, envelopes
   `{"type":"event","data":...}`. Configure TLS/autenticação em um proxy antes
   de disponibilizar fora da rede local.
5. Se o ESP8266 ainda não sincronizou o relógio, aceita `timestamp: null`, grava
   o instante de recebimento em `timestamp` e mantém `device_timestamp: null`.

O backend encaminha o JSON canônico (ou um envelope equivalente com
`type: "snapshot" | "event"` e `data`) sem mudar unidades. O navegador pode
manter o modo MQTT direto para compatibilidade, mas o modo recomendado é
WebSocket do backend. Ambos os modos são somente de leitura.

## 5. Pontos de verificação na RTL antes de transmitir

Preservar a estrutura original e incluir telemetria nos pontos de registro já
existentes; manter a máquina de Moore e não transferir regras para a ESP8266. A revisão
dos arquivos atuais encontrou questões que os implementadores devem verificar
antes de chamar o dado de telemetria de "aprovado":

- `processador_acao.v` agora exige saldo suficiente para compra e informa
  aprovação/recusa; em recusa, saldo, inventário e despesas permanecem iguais.
- `fluxo_dados.v` captura eventos e snapshot após registro; a UART fica em
  `circuito/telemetria_uart.v`. A saída de topo `uart_tx` não tem pino físico
  escolhido, pois o mapeamento FPGA→ESP8266 não consta nos arquivos de pinagem.
- `fluxo_dados.v` tem comparadores de contagem internos e sinais `fim_rodada`,
  `ultima_rodada`; confirmar a sequência exata de três jogadas/quinze rodadas
  em simulação. O framing deve converter contadores zero-based em 1-based sem
  alterar os contadores originais.
- Compra, venda, falência, fim de rodada e nova sessão têm eventos distintos.
  Não inferir evento apenas comparando saldo: duas ações diferentes podem
  produzir o mesmo saldo.
- Na venda, manter a regra já codificada de retirar o item e atualizar os
  valores correspondentes; não corrigir outras regras sem decidir com a equipe.
- Verificar sinal/sinalização de valores: registradores de dinheiro são
  `signed [20:0]`, enquanto alguns fios intermediários são declarados sem
  sinal. Tratar corretamente saldo negativo/falência e evitar publicar um
  inteiro grande sem sinal.

## 6. Diretrizes da interface

- Interface exclusiva para computador, em português, com a logo e cores do jogo.
  Não criar nem manter layout para celular/tablet: abaixo de 1100 px de largura,
  esconder a aplicação e mostrar apenas um aviso de que é necessário um
  computador. Não inserir fotos do tabuleiro ou protótipos físicos na tela.
- Linguagem concreta e direta, poucas transições e sem animação intensa,
  conforme requisitos de conforto sensorial e literalidade da especificação.
- A primeira tela destaca rodada e jogada; mantém inventário, catálogo visual,
  saldo e último evento em leitura passiva.
- Dar prioridade visual às ilustrações dos itens do catálogo, usando valores
  monetários resumidos (por exemplo, “R$ 15 mil”) e mantendo o valor exato
  disponível como informação secundária.
- Aba **Calculadora**: simulação educativa local; deixa explícito que não altera
  a partida nem envia dados para a FPGA.
- Aba **Estatísticas**: resumo da sessão e evolução do saldo/histórico, baseado
  nos eventos recebidos. Indicar quando os dados estão em modo de demonstração
  ou quando ainda não há eventos.
- Não apresentar botões de comprar, vender, estudar ou trabalhar como controles
  do jogo. As decisões reais são feitas nos botões físicos.

## 7. Critérios de aceite para a próxima implementação

### FPGA

- Build e simulação preservam inicialização, botões, displays, itens, ordem de
  jogadas/rodadas e encerramento.
- A FSM de jogo continua Moore; estados mantêm nomes claros e etapas separadas.
  `fpga/testbench/unidade_controle_moore_tb.v` verifica que entradas não mudam as saídas
  antes da transição de estado.
- Executar `vsim -do fpga/testbench/run_all.do` na raiz para os testbenches
  focados e manter `fpga/testbench/circuito_jogo_financeiro_tb1.v` para a
  simulação completa do jogo.
- Cada decisão física gera no máximo um evento UART com sequência crescente e
  snapshot pós-decisão.
- Compra insuficiente gera evento recusado, sem alteração de saldo/inventário
  nem acionamento do motor.
- UART 115200 8-N-1 é observável e a perda de rede da ESP8266 não bloqueia o jogo.

### ESP8266/backend

- Teste com linhas UART válidas, incompletas, corrompidas e desconhecidas; erro
  não deve publicar payload de sucesso.
- Executar `sh esp8266/testbench/run_tests.sh`; o teste de parser usa o mesmo
  header incluído pelo firmware e não depende de conexão à placa.
- Conversão de escala validada: `150` → `1500000` centavos (R$ 15.000,00).
- MQTT publica no tópico combinado; reconexão Wi-Fi/MQTT não duplica o mesmo
  `seq` na sessão.
- Backend valida, persiste e distribui snapshots/eventos na ordem; cliente novo
  recebe snapshot antes dos próximos eventos.

### Front-end

- Recebe atualização de backend em tempo real e reflete rodada, jogada, saldo,
  inventário, último evento, estatísticas e histórico.
- Saldo recebido em centavos é convertido para BRL exatamente uma vez.
- Evento de compra recusada não altera o estado exibido como se houvesse compra.
- Calculadora não publica mensagens e não altera o snapshot da partida.

## 8. Referências do repositório

- Especificação: `frontend/docs/AEX5_T6BA6_Spec.pdf`
- Relato técnico: `frontend/docs/Semana1_T6BA6_Relato.pdf`
- Lógica do jogo: `circuito/`
- Interface e compatibilidade MQTT atual: `frontend/README.md`,
  `frontend/index.html`, `frontend/app.js` e `frontend/styles.css`
- Pinagem atualmente registrada: `configuracoes_e_pinagens/` e PDFs na raiz.
  Confirmar a pinagem elétrica da UART antes de conectar FPGA e ESP8266.

## 9. Instrução resumida para a IA implementadora

> Leia este handoff e os módulos Verilog/documentos citados antes de editar.
> Desenvolva a telemetria sem trocar a FSM nem mover a lógica do jogo para a
> ESP8266 ou para o navegador. Entregue separadamente: (1) alterações HDL e
> testbench para registrar evento/snapshot e transmitir UART 115200 8-N-1;
> (2) firmware ESP8266 que enquadra/valida UART, converte a escala monetária e
> publica JSON versão 1 em `aventura_financeira/telemetria`; (3) testes de cada
> lado e instruções de ligação/execução. Use a proposta de framing e o schema
> deste documento, ou explique e atualize antes qualquer incompatibilidade.
> Preserve os botões e displays atuais. Não acione o motor nem altere saldo ou
> inventário em compra recusada. Teste desconexão, mensagem incompleta,
> conversão `150` → `1500000` centavos e eventos aceitos/recusados. Declare
> claramente qualquer pinagem ou premissa que não esteja documentada; não
> invente conexões físicas.
