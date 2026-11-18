# Feedback da especialista sobre o jogo

Conversa gravada (cerca de 4 min 25 s) em que uma especialista avalia o jogo e
dá orientações para o público dele. Arquivo original:
`Escola Politécnica Universidade de São Paulo 13.m4a.mp4` (fora do
repositório). A transcrição abaixo foi feita automaticamente em 2026-11-18
com o faster-whisper (modelo `small`, português) e **tem erros de
reconhecimento**: "Lógia" é quase certamente "Loja", e alguns trechos ficaram
confusos (por exemplo, "3 minutos ele tá impediado").

## Resumo

**Avaliação:** "O projeto é ótimo, o jogo tá bom, as fontes estão aprovadas,
a paleta de cor tá incrível." Ela pediu para lembrar dos pontos abaixo na
defesa.

**Princípios para o público do jogo**

- **Ser literal:** as conexões precisam ser diretas; aprendizado nas
  entrelinhas não funciona.
- **Hierarquia:** o que deve ter destaque vai em primeiro plano.
- **Recompensa imediata:** mostrar o efeito na hora (barras como "vida" e
  "inteligência"); não pode ser "estudei e tô perdendo dinheiro" sem retorno
  visível.
- **Só o que interessa ao jogador:** esconder o que é de controle e tirar o
  que parece clicável sem ser ("tudo que der vontade de clicar, eu vou querer
  clicar").
- **Quanto mais simples, melhor.**

**Sugestões**

1. Menos texto nos itens: só o nome ("livro", "lego") ou "Compre este carro".
2. Separar "Loja" (o que se compra) de "Pagamentos" (o que se tem que pagar).
3. Aluguel com texto direto: "Pagar aluguel" ou "Morar de aluguel", para
   ligar com "aqui eu compro a casa".
4. Conta de luz de forma literal; foi comentada uma luzinha que acende e apaga.
5. Mostrar "O que você pode fazer agora?" (ela achou melhor que "o que o seu
   dinheiro compra").

## O que mudamos por causa do feedback

| Feedback | O que foi feito | Onde |
|---|---|---|
| Só o que interessa; nada que pareça clicável sem ser | Modo jogador sem menus, abas, conexão nem botões; o resto foi para o modo professor (`?professor` ou Ctrl+Alt+P) | `front/` (commit `3c02774`) |
| Hierarquia | Dinheiro em primeiro plano e bem grande; depois ações possíveis, progresso, loja e última jogada | `front/` |
| Menos texto, ser literal | Textos curtos ("Você trabalhou", "+ R$ 6,4 mil", "Se comprar, você PERDE"); nomes curtos dos itens; um valor só, sem "valor exato" | `front/` |
| Recompensa imediata (barras) | Barras Dinheiro, Estudo, Investimento e Rodada, com o nome do botão que as faz subir; a barra pisca e mostra "+1 nível", "+ R$ 200" na hora | `front/` (commit `3affaa3`) |
| "O que você pode fazer agora?" | Lista só as ações possíveis, com a cor da capa de cada botão; ações que levam à falência em vermelho | `front/` (commit `3affaa3`) |
| Separar Loja e Pagamentos | Seletor virou "Loja"; bloco Pagamentos com contas básicas, conta de cada carro ou casa e o total por rodada | `front/` (commit `3affaa3`) |
| Aluguel e conta de luz | **Pendente:** decidir se só renomeia a despesa fixa ou se muda a regra na FPGA (comprar casa zera o aluguel; LED da conta de luz na caixa) | — |

## Transcrição

```text
[00:00] Pode gravar, então lembra sempre de ser literal, sistema de recompensa, ter na tela só aquilo que de fato interessa o jogador
[00:10] Então segredar o que for de controle
[00:12] Exatamente, e lembrar que tudo que der vontade de clicar, eu vou querer clicar, então você tem que deixar...
[00:18] Tem que tirar as coisas não clicáveis na tela
[00:20] Isso, e deixa nítido o que é para a visualização
[00:24] Lembra que toda a conexão...
[00:26] Aí!
[00:27] Boa!
[00:28] Lembra que toda a conexão, ela vai ser direta
[00:32] Então mesmo que você queira colocar um aprendizado intrínseco, não vai sortir efeito efetivo porque eles são literais
[00:42] E hierárquicos, ou seja, conforme você quiser dar destaque para uma coisa, você precisa colocar aquilo em primeiro plano
[00:52] Isso é imediato
[00:53] Isso é imediato
[00:54] Você vê alguma coisa na hora
[00:56] Então colocar barra de vida, colocar barra de inteligência
[00:59] Você tem que recompensar na hora, não é tipo assim, putz, estudei e tô perdendo dinheiro
[01:05] Não, eu tô com o que eu te juro, 3 minutos ele tá impediado
[01:09] Tem que ser o tempo todo ali dando uns...
[01:11] Eu não tá com isso de ganhar dinheiro em curto
[01:13] Entendeu?
[01:14] É tipo, e então assim, lembra disso que eu tô falando que vai ser muito importante para vocês na hora da defesa
[01:20] O projeto é ótimo, o jogo tá bom, as fontes estão aprovadas
[01:23] A paleta de cor tá incrível
[01:25] Não sei, eu tipo, nenhuma dúvida quanto a isso
[01:28] Só sempre lembra disso que eu falei agora
[01:31] Quanto mais simples, mais vantagens vocês vão ter
[01:34] Tá bom
[01:35] E aí os itens que a gente vai mudar, o que você sugere que a gente coloca em lugar?
[01:39] Item, um pouco menos de texto
[01:41] Então é tipo, compre este carro
[01:44] Bem básico assim, tipo, compre de algo de tabuleiro
[01:48] Ou se não você escreve aqui em cima
[01:50] Venda
[01:52] Lógia
[01:54] Lógia é bem objetivo
[01:56] Lógia
[01:57] E aí você coloca só o nome do item
[01:59] Tipo assim, é livro, lego, dananã, sabe?
[02:04] Tipo, objetividade
[02:06] Corta texto
[02:07] E aquela coisa do aluguel, então a gente vai ter isso daí
[02:10] Pode colocar, mas coloca bem assim
[02:12] Pagar aluguel, ou morar de aluguel
[02:15] Que aí a pessoa vai conectar
[02:17] Tipo assim, aqui eu vou morar de aluguel
[02:19] Aqui eu vou comprar essa casa
[02:21] Porque o meu dinheiro dá pra morar de aluguel
[02:23] Tipo, sempre ardem direta
[02:25] E tipo, pagar luz e tal, não precisa, sabe?
[02:28] Tipo, tá muita, tá muita, hein?
[02:30] Pagar, conta de luz, pode te colocar
[02:32] É tipo, eu que tava pensando nesse pagar conta de luz
[02:35] A gente pode botar uma luzinha, aquele tipo, ligue e afaga
[02:38] Você pode fazer uma coisa literal
[02:40] Lógia até separar entre
[02:43] É, compras, pagamentos
[02:46] Entendeu? Tipo
[02:48] Aqui, que tá na loja, é tudo pra comprar
[02:51] Isso aqui é o que eu tenho que pagar
[02:53] Entendeu?
[02:54] Outra coisa que eu tava pensando em fazer
[02:56] Era aqui do lado, estender mais essa barra
[02:58] E colocar aqui, assim, jogadas que podem ser feitas
[03:02] Alguma coisa ver sentido
[03:04] Tipo, indicando o que ele pode fazer depois
[03:06] Que ele já fez essa jogada, sabe?
[03:08] Agora você pode comprar investido, sei o quê?
[03:12] Eu não sei se tipo, sozinho ele vai tipo
[03:15] Ah, eu vou pensar, entendeu?
[03:17] Eu acho que talvez a gente tem que colocar uma coisa mais
[03:19] Você pode colocar, você pode colocar até assim
[03:21] O que você pode fazer agora?
[03:23] Ah, perfeito, perfeito
[03:24] Ou que o seu dinheiro compra
[03:26] Mas o que você pode fazer agora é melhor
[03:28] Porque é tipo, fica nessa linha que eu tô falando
[03:31] Eu acho inclusive que as coisas acontecem por algum motivo
[03:34] Tipo, tem um motivo, tá necessário
[03:36] Tem mesmo?
[03:37] Agora, então acho que vai ajudar bastante vocês
[03:39] Até fiquei tentada ali, a falar pros professores
[03:42] Mas tem negócio da ética, que eu ia falar
[03:44] Puts, eu não posso levar eles lá no ônibus
[03:47] Porque, tipo, ia ser muito legal levar os jogos lá
[03:50] Pra eles tentarem e vocês verem na prática, sabe?
[03:54] Mas enfim, deixei umas dicas aqui pra você
[03:57] Obrigada
[03:58] Lembra de observar o que eu tava te falando
[04:02] Que é a cabeça
[04:04] Como é o objetivo?
[04:06] Tipo, o nome do jogo?
[04:08] Jogar
[04:10] Essa pessoa que tem 30 anos
[04:12] A cabeça dela é de novo
[04:14] Aqueles outros dois que eu te mostrei
[04:16] Que é o jogo do Cowboy
[04:18] Eles tem 15
[04:20] Tá?
[04:22] Vai lá
```
