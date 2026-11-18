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
| **Dinheiro** 💰 | um 💰 por jogada de contas que o dinheiro paga (as contas saem a cada TRABALHAR ou ESTUDAR); os 💰 tremem quando não dá para pagar a próxima | TRABALHAR, RESGATAR, VENDER |
| **Estudo** 🧠 | um 🧠 por nível; nível = (salário − R$ 6,4 mil) ÷ R$ 4 mil, com o salário atual. Estudar não custa dinheiro: a jogada só paga o custo de vida | ESTUDAR |
| **Investimento** 🏦 | um 🏦 a cada R$ 1 mil guardado e quanto rende na próxima rodada | INVESTIR e o rendimento de 25% por rodada |
| **Rodada** (na faixa verde) | 15 blocos: a rodada atual (1 rodada = 1 ano; 1 jogada = 1 quadrimestre) | cada fim de rodada |

Na hora da jogada, a barra que mudou pisca e mostra quanto mudou ("+1 nível",
"+ R$ 6,4 mil"). O estado inicial enviado pelo backend ao conectar não anima.

A faixa verde mostra, da esquerda para a direita: o dinheiro, o **custo de vida
por jogada** (pago a cada TRABALHAR ou ESTUDAR), a rodada (1 rodada = 1 ano), a
jogada (1 jogada = 1 quadrimestre, 3 por rodada) e as vidas.

"O que você pode fazer agora?" avisa no topo que a lista **não tem botões**: o
jogador aperta o botão na caixa. As linhas não têm moldura de botão nem cursor
de clique. A lista mostra só as ações possíveis, com a cor da capa
do botão da caixa (TRABALHAR azul, ESTUDAR branco, INVESTIR preto, RESGATAR
vermelho, COMPRAR amarelo, VENDER verde). Uma ação que deixaria o dinheiro
negativo aparece em vermelho: "Se estudar agora, você PERDE".

**Pagamentos** lista o que sai a cada TRABALHAR ou ESTUDAR (é assim na FPGA:
`APLICA_DESPESA` depois de cada jogada): as contas básicas e a conta de cada
carro ou casa comprado.

## Últimas jogadas

A jogada mais nova fica em destaque (e pisca quando chega), e as 3 anteriores
descem para uma lista logo abaixo em vez de sumir. A FPGA manda vários eventos
seguidos (por exemplo, a compra e logo depois a vida perdida, ou a última jogada
e o fim da rodada), então o jogador consegue ler cada um.

## Vidas

O jogador tem **3 vidas** (❤️❤️❤️ na faixa verde, à direita da jogada). Quando
uma jogada deixa o saldo negativo e ainda há vida, a FPGA desfaz a jogada e
manda `vida_perdida` com as vidas que restam (campo `vidas`). O painel mostra um
aviso grande, que some sozinho em 8 s: "Você perdeu uma vida. Você gastou mais
dinheiro do que tinha. Por isso, você volta uma jogada." Os avisos de risco
dizem "Se comprar agora, você perde 1 vida" e, na última vida, "você PERDE o
jogo". Na 3ª falha, a FPGA manda `falencia` e aparece a tela de fim de jogo.
