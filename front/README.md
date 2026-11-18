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
