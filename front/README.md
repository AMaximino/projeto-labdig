# Painel web

Interface de acompanhamento, sem controles que enviem ações ao jogo. O backend
serve esta pasta em `http://<host>:3000`, fornece o WebSocket
`/ws/telemetria` e mantém o histórico de eventos.

Ao abrir, o painel conecta ao mesmo host na porta 3000. O front entende tanto
eventos diretos quanto envelopes WebSocket `snapshot`/`event`, e tenta
reconectar com espera progressiva quando a rede interrompe a conexão. Assim, o
IP do servidor não precisa ser configurado em cada computador. A janela precisa
ter ao menos 1100 px de largura.

Para iniciar, siga [`../back/README.md`](../back/README.md). O endpoint pode ser
alterado temporariamente no menu **Conexão de dados**. Mensagens financeiras
seguem o contrato canônico em centavos BRL.

O leitor RFID só gera eventos através da FPGA; o painel não recebe UID de
cartões e não inicia compras.

## Modo jogador e modo professor

O painel abre no **modo jogador**: uma tela só, sem menus nem botões, com o
que interessa a quem joga, nesta ordem: o dinheiro (bem grande), a rodada e a
jogada, o seletor de item, a última jogada e os itens que o jogador já tem. Os
textos são curtos e literais ("Você trabalhou", "+ R$ 6,4 mil", "Se comprar,
você PERDE"). Isso segue o feedback da especialista: mostrar só o que
interessa, não ter nada que pareça clicável sem ser, e cortar texto.

O **modo professor** mostra também as abas (Estatísticas, Calculadora), o
histórico, a loja detalhada, a conexão com o backend, a troca de jogador e a
exportação da sessão. Para abrir:

- `http://localhost:3000/?professor`; ou
- **Ctrl+Alt+P** na tela do jogo (aperte de novo para voltar ao modo jogador).

## Barras de progresso e "O que você pode fazer agora?"

Cada barra mostra algo que muda o jogo de verdade (regras da FPGA em
`fpga/rtl/processador_acao.v`) e tem o nome do botão que a faz subir. Dinheiro,
Estudo e Investimento são barras de 10 ícones, como os corações do Minecraft:
cada ícone colorido é um nível atingido e os demais ficam escuros.

| Barra | O que mostra | Sobe com |
|---|---|---|
| **Dinheiro** 💰 | um 💰 por rodada de contas que o dinheiro paga; os 💰 tremem quando não dá para pagar a próxima | TRABALHAR, RESGATAR, VENDER |
| **Estudo** 🧠 | um 🧠 por nível; nível = (salário − R$ 6,4 mil) ÷ R$ 4 mil, com o salário atual | ESTUDAR |
| **Investimento** 🏦 | um 🏦 a cada R$ 1 mil guardado e quanto rende na próxima rodada | INVESTIR e o rendimento de 25% por rodada |
| **Jornada** (na faixa verde) | 15 blocos: a rodada atual | cada fim de rodada |

Na hora da jogada, a barra que mudou pisca e mostra quanto mudou ("+1 nível",
"+ R$ 6,4 mil"). O estado inicial enviado pelo backend ao conectar não anima.

"O que você pode fazer agora?" lista só as ações possíveis, com a cor da capa
do botão da caixa (TRABALHAR azul, ESTUDAR branco, INVESTIR preto, RESGATAR
vermelho, COMPRAR amarelo, VENDER verde). Uma ação que deixaria o dinheiro
negativo aparece em vermelho: "Se estudar agora, você PERDE".

**Pagamentos** lista o que sai no fim de cada rodada: as contas básicas e a
conta de cada carro ou casa comprado.
