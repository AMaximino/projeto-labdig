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
