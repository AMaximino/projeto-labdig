# Roteiro do pitch: Aventura Financeira Evolution

Versão de 2026-11-19. Cópia do documento editável:
https://claude.ai/artifact/WosBgjtTfkFPguB94SCvAV

## Visão geral

Pitch de cerca de 7 minutos, falado pelos três, com a caixa ligada na mesa e o painel no projetor. A ideia central: dinheiro é abstrato, e para muitas pessoas autistas o abstrato é justamente a barreira; o Aventura Financeira transforma cada decisão em algo físico, literal e com resposta na hora.

| Bloco | Quem fala | Tempo |
| --- | --- | --- |
| Abertura | Sophia | 0:45 |
| O problema | Sophia | 1:00 |
| A solução | Gabriel | 1:00 |
| Por que funciona para autistas | Sophia | 1:30 |
| Demonstração ao vivo | Luís | 1:45 |
| Modo professor | Gabriel | 0:45 |
| Fechamento | Luís | 0:30 |

A divisão de falas é uma sugestão; troquem os nomes como fizer sentido para vocês. O texto não é para decorar palavra por palavra: falem com as próprias palavras, mantendo as ideias e a ordem.

## Abertura (Sophia, 0:45)

*Sophia começa com a caixa ao lado, ainda sem apontar para ela.*

> Oi, gente. Antes de começar, deixa eu fazer uma pergunta pra vocês: o que é investir?
>
> Parece fácil, né? Mas tenta explicar sem nenhuma metáfora. Sem “plantar uma sementinha”, sem “fazer o dinheiro trabalhar pra você”. Complica, né?
>
> Agora pensa numa pessoa que entende tudo ao pé da letra. Pra ela, “fazer o dinheiro trabalhar” não faz o menor sentido, porque dinheiro não trabalha. E é bem assim que muita pessoa autista recebe educação financeira hoje: cheia de entrelinha.
>
> Bom, eu sou a Sophia, esse é o Gabriel, esse é o Luís, e a gente vai mostrar pra vocês o Aventura Financeira Evolution.

*Dica:* depois da pergunta, façam uma pausa de dois segundos. Deixem a banca pensar antes de continuar.

## O problema (Sophia, 1:00)

> Cuidar do próprio dinheiro é uma das coisas mais difíceis da vida adulta pra muita pessoa autista. E não é por falta de capacidade, tá? É porque o jeito que a gente ensina dinheiro não foi pensado pra elas.
>
> Pensa no app do seu banco. É informação pra todo lado, botão que você nem sabe pra que serve, propaganda no meio… E o pior: você gasta hoje e só vai sentir no fim do mês. Pra quem precisa ver causa e efeito bem claros, isso não ensina nada. Só dá ansiedade.
>
> E tem mais: errar com dinheiro de verdade sai caro. Ninguém deveria aprender a se organizar errando com o próprio salário.
>
> Aí a gente se perguntou: e se desse pra aprender dinheiro de um jeito literal, previsível, e onde errar não tem problema?

*Atenção:* se quiserem citar um dado (por exemplo, sobre emprego ou independência financeira de adultos autistas), usem só um número com fonte que vocês consigam mostrar se a banca perguntar. Sem fonte, deixem a frase como está.

## A solução (Gabriel, 1:00)

*Gabriel pega a caixa e mostra os botões, o seletor e o leitor de cartão.*

> Então, essa aqui é a nossa caixa. É um jogo de educação financeira que você joga com as mãos mesmo. Nada de tela cheia de opção.
>
> Cada botão faz uma coisa só, e o nome dele já diz o quê: trabalhar, estudar, investir, comprar e vender. Cada rodada tem três jogadas. Trabalhou, ganhou dinheiro. Estudou, gasta um pouco agora, mas o salário sobe depois. Investiu, o dinheiro fica guardado rendendo.
>
> Quer comprar alguma coisa? Gira esse seletor até o item, sei lá, um livro, um carro, e encosta o cartão aqui. É o mesmo gesto de pagar no mercado, só que sem dinheiro de verdade.
>
> E aqui dentro quem manda nas regras é uma FPGA, que é um circuito digital que a gente mesmo projetou. Ela manda tudo pra esse painel aqui, que mostra na hora o que aconteceu com o dinheiro.

*Dica:* aqui não entrem em detalhe técnico. Se a banca quiser saber de FPGA, ESP32 e MQTT, isso vai para as perguntas.

## Por que funciona para autistas (Sophia, 1:30)

> Uma coisa que a gente fez questão: não quis ficar chutando o que funciona. A gente levou o jogo pra uma especialista que trabalha com esse público, ela jogou, criticou, e saiu de lá com quatro regras. A gente refez o jogo inteiro em cima delas.
>
> **A primeira é ser literal.** Ela falou uma frase que ficou na nossa cabeça: “toda conexão vai ser direta”. Então o painel fala “Você trabalhou, mais 6,4 mil”. Item é só o nome: livro, lego, carro. E a gente separou a Loja, que é o que você escolhe comprar, dos Pagamentos, que é o que você tem que pagar.
>
> **A segunda é recompensa na hora.** Não dá pro jogador pensar “poxa, estudei e só perdi dinheiro”. Então, estudou, a barrinha de estudo sobe na hora e pisca: mais um nível. Você vê o resultado no mesmo segundo.
>
> **A terceira é só mostrar o que interessa.** Ela disse: “tudo que der vontade de clicar, eu vou querer clicar”. Faz sentido, né? Então a gente tirou da tela do jogador tudo que é menu, aba, botão. O que é de controle foi pro modo professor.
>
> **E a quarta é hierarquia.** O mais importante, que é o dinheiro, fica bem grande, lá em cima. Logo embaixo vem “O que você pode fazer agora?”, com a cor de cada botão. E o que te levaria à falência aparece em vermelho.
>
> E tem uma parte que eu acho a mais legal de todas: aqui errar não tem problema. O jogador tem três vidas. Se ele faz uma jogada que deixa o saldo negativo, o jogo desfaz, tira uma vida e explica o que aconteceu. Ninguém leva susto.

*Dica:* essa é a parte que mais diferencia o projeto. Falem devagar e, em cada regra, apontem para a parte da tela correspondente.

Mais duas características que podem ser citadas se sobrar tempo, ou guardadas para as perguntas:

- **Previsibilidade:** o modo “Como jogar” mostra o jogo passo a passo antes da primeira partida, para o jogador saber o que vai acontecer.
- **O físico ajuda:** botões com cor, seletor que gira e cartão que encosta dão uma ação concreta para cada decisão abstrata.

## Demonstração ao vivo (Luís, 1:45)

Luís joga e narra; Gabriel cuida do projetor. Cada ação é dita antes de ser feita, para a banca olhar a tela no momento certo.

1. **Identificação:** “Primeiro o jogador diz quem está jogando. Vou colocar o nome de um professor.” Digite o nome de um professor da banca. Isso costuma arrancar um sorriso.
2. **Iniciar:** aperte iniciar. “O jogo começa com o dinheiro aqui em cima, bem grande.”
3. **Trabalhar:** “Vou trabalhar.” Aperte. “Olha: ‘Você trabalhou’, e o dinheiro subiu na hora.”
4. **Estudar:** “Agora vou estudar. Custa dinheiro, mas olha a barra de estudo subindo. No próximo trabalho, o salário é maior.”
5. **Comprar com o cartão:** gire o seletor até um item. “O painel mostra o que está selecionado e o preço.” Encoste o cartão. “Comprei.”
6. **Errar de propósito:** compre algo caro demais. “E se eu gastar mais do que tenho? O jogo não me pune de surpresa: desfaz a jogada, tira uma vida e explica.” Mostre o aviso e feche.
7. **Fechar a demo:** “Tudo isso em poucos segundos, sem nenhuma palavra que precise ser interpretada.”

**Plano B:** se o Wi-Fi ou a placa falharem, abram o modo “Como jogar” no painel, que roda sem a caixa, ou passem o trecho do vídeo de demonstração. Deixem os dois abertos em abas antes de começar.

- [ ] Testar a caixa, o Wi-Fi e o painel 30 minutos antes
- [ ] Deixar o modo “Como jogar” e o vídeo abertos em abas
- [ ] Ensaiar a compra que dá saldo negativo, para saber qual item usar

## Modo professor (Gabriel, 0:45)

*Gabriel abre o modo professor (Ctrl+Alt+P) na aba “Análise do aluno”.*

> Agora, o jogo não é só pra quem tá jogando. Lembra que a gente tirou um monte de coisa da tela do aluno? Veio tudo pra cá, pro modo do professor. Ou do terapeuta, ou da família.
>
> Aqui eu escolho o aluno e vejo como ele foi evoluindo partida a partida: com quanto dinheiro terminou, quantas vidas perdeu, quanto ele trabalhou, estudou ou investiu. E o painel já te dá umas observações prontas, tipo “Não investiu: o dinheiro guardado não rendeu nada”, ou quais jogadas deixaram o saldo negativo.
>
> Ou seja, quem acompanha o aluno não precisa ficar adivinhando onde ele tem dificuldade. Tá tudo aqui, e dá pra sentar e conversar com ele sobre isso.

## Fechamento (Luís, 0:30)

> Então, resumindo: dinheiro é uma coisa abstrata, e o Aventura Financeira deixa ele concreto. Cada decisão é um botão, você vê o resultado na hora, e errar faz parte.
>
> A gente pensou tudo isso pra pessoas autistas, mas acabou percebendo uma coisa no caminho: quando o jogo fica claro o bastante pra elas, ele fica melhor pra todo mundo.
>
> Daqui pra frente, a gente quer testar com jogadores autistas, junto com a especialista, e deixar a conta de luz e o aluguel ainda mais literais, do jeito que ela sugeriu. É isso, gente, obrigado! A caixa tá aqui, quem quiser jogar pode vir.

*Dica:* terminem oferecendo a caixa. Professor que joga lembra do projeto.

## Perguntas prováveis da banca

| Pergunta | Resposta curta |
| --- | --- |
| Vocês testaram com pessoas autistas? | Ainda não com jogadores, por questão ética. A especialista avaliou o jogo e cada mudança que ela pediu está documentada. O teste com jogadores, com acompanhamento dela, é o próximo passo. |
| Por que uma caixa física e não um app? | O gesto concreto (apertar, girar, encostar o cartão) liga cada decisão a uma ação. E a tela do jogador fica limpa, sem nada que pareça clicável. |
| Para qual idade é? | Para jovens e adultos. A especialista lembrou que a idade de uma pessoa não diz o jeito que ela aprende, por isso o jogo não é infantilizado. |
| Por que a FPGA, se um microcontrolador faria isso? | As regras do jogo são uma máquina de estados em hardware, que é o objetivo da disciplina. A ESP32 só faz a ponte do RFID e do Wi-Fi. |
| O cartão RFID cobra alguma coisa? | Não. É uma simulação: o cartão só confirma a compra do item que está no seletor. |
| E se o jogador ficar frustrado ao errar? | Errar não encerra o jogo: são três vidas, e cada erro desfaz a jogada e explica o motivo. |
| Como o professor usa os dados? | No modo professor, por aluno: evolução entre partidas, distribuição das decisões e observações automáticas, como “não estudou” ou “não investiu”. |

*Dica:* se não souberem uma resposta, digam “boa pergunta, a gente não testou isso ainda”. A banca valoriza honestidade mais do que improviso.
