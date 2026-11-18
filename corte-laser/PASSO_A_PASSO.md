# Passo a passo: cortar a tampa e o fundo na Epilog Fusion Pro 48

Guia para levar ao laboratório. Os arquivos e as medidas estão no
[README](README.md). Se o laboratório tiver um técnico responsável pela laser,
mostre este passo a passo a ele antes de começar: os nomes dos menus podem
mudar um pouco conforme a versão do software da Epilog.

## 1. Antes de ir ao laboratório

- [ ] Conferir as prévias `conferencia_tampa.png` e `conferencia_fundo.png`
      (e `sobreposicao_tampa.png`, sobre o seu desenho).
- [ ] Copiar para um pendrive (ou para a nuvem): `tampa.pdf`, `fundo.pdf`,
      `teste.pdf`. Os `.svg` e `.dxf` são uma reserva, caso o computador da
      laser use outro programa.
- [ ] Separar um **retalho de MDF de 5 mm** de uns 10 × 6 cm para a peça de
      teste. Pode ser de outra chapa, desde que tenha a mesma espessura.
- [ ] Levar a **caixa com a tampa** e um botão com capa e o seletor, para
      testar o encaixe.
- [ ] Levar régua ou trena e fita crepe.
- [ ] Agendar o horário da laser e perguntar ao laboratório se há uma **tabela
      de configuração para MDF** (velocidade, potência e frequência) da máquina
      deles.

## 2. No computador da laser: abrir o arquivo

1. Abra o `teste.pdf` no programa de desenho do computador (Illustrator,
   CorelDRAW ou Inkscape).
2. Confira o tamanho: a página tem que ter **75 × 40 mm**. Se abrir em outra
   escala, não continue: a escala tem que ser **100%**.
3. Linhas vermelhas são para cortar. No teste, tudo é vermelho.
4. Mande imprimir (**Arquivo → Imprimir**) escolhendo a impressora
   **Epilog Engraver**. Abre o **Epilog Dashboard**, a tela de configuração da
   laser.

Para a tampa e o fundo, faça o mesmo com `tampa.pdf` (415 × 315 mm) e
`fundo.pdf` (400 × 300 mm). Nesses dois arquivos, a **borda da peça é azul** e
**não pode ser cortada** (veja o passo 3).

## 3. No Epilog Dashboard: configurar

1. **Tipo de trabalho:** *Vector* (corte por linha). Não há gravação.
2. **Separar por cor** (*Split by Color*):
   - **vermelho**: ligado, processo *Vector* (corte);
   - **azul**: **desligado**. Se não der para desligar, volte ao programa de
     desenho, apague a borda azul (camada `referencia_nao_cortar`) e mande
     imprimir de novo.
3. **Configuração do vermelho**, para MDF de 5 mm:
   - use a configuração de MDF da tabela do laboratório; se não houver, a de
     MDF de 1/4" (6 mm) da Epilog;
   - potência alta (por volta de 100%), frequência baixa (10–20%) e a
     velocidade da tabela;
   - ar assistido (*Air Assist*) **ligado**, para não pegar fogo e queimar menos.
4. **Foco:** use o foco automático na superfície que vai ser cortada. No fundo,
   a superfície fica a 20,5 cm da mesa (veja o passo 5).
5. **Posição:** o trabalho começa no **canto de cima à esquerda** da mesa
   (origem). Se a máquina tiver câmera, dá para ver a peça na tela e conferir
   se os furos caem no lugar.
6. Envie o trabalho para a máquina.

## 4. Na máquina: peça de teste

1. Ligue a **exaustão** e o **ar assistido**.
2. Coloque o retalho de MDF no **canto de cima à esquerda** da mesa, encostado
   nas réguas.
3. Faça o foco.
4. Na tela da máquina, escolha o trabalho `teste` e aperte **Go**.
5. **Fique olhando o corte o tempo todo.** MDF pode pegar fogo. Se aparecer
   chama que não apaga sozinha, pause a máquina e chame o técnico.
6. Espere a exaustão tirar a fumaça antes de abrir a tampa da máquina.
7. Confira:
   - os pedaços de dentro **caíram sozinhos**? Se ficaram presos, o corte não
     atravessou: diminua a velocidade ou faça **uma segunda passada** e teste
     de novo;
   - o **botão** entra no furo quadrado de 1,5 cm e o **seletor** no redondo
     de 2 cm?
   - a borda ficou muito queimada? Aumente um pouco a velocidade ou confira o
     ar assistido.

Só passe para a tampa quando o teste sair bom. Anote a configuração que
funcionou.

## 5. Cortar a tampa

1. Abra `tampa.pdf` e configure como no passo 3, com o **azul desligado** e a
   configuração que funcionou no teste.
2. Coloque a tampa na mesa com a **face de cima para cima** e a **frente da
   caixa virada para você** (para a frente da máquina).
3. Encoste o **canto de trás à esquerda** da tampa no **canto de origem** da
   mesa (cima à esquerda). Se precisar, prenda com fita crepe.
4. Se a tampa tiver aba (borda que desce), abaixe a mesa até a tampa caber e
   foque **na face de cima**.
5. Confira a posição antes de cortar: use a câmera ou o ponteiro vermelho da
   máquina para ver se o canto do desenho bate com o canto da tampa.
6. Aperte **Go** e acompanhe o corte.
7. Confira os furos com a régua: botões a 4 cm da frente, seletor 8 cm acima
   dos botões, RFID a 4 cm da esquerda e a 15 cm da frente, botões da direita
   a 4 cm da direita e a 12 cm da frente.

## 6. Cortar o fundo (caixa de cabeça para baixo)

1. Abra `fundo.pdf` e configure como antes (azul desligado).
2. **Abaixe bem a mesa:** a caixa tem 20,5 cm de altura. Confira com o técnico
   se a máquina tem altura para isso.
3. Coloque a caixa **de cabeça para baixo**, com a **frente virada para você**
   e o **canto de trás à esquerda** do fundo no canto de origem da mesa.
4. Foque **na superfície do fundo**, ou seja, no topo da caixa virada.
5. Confira a posição com a câmera ou o ponteiro vermelho.
6. Aperte **Go** e acompanhe o corte.
7. Confira: a abertura de 8 × 6 cm deve estar centralizada, a 3 cm da frente.

## 7. Depois do corte

- Espere a exaustão terminar e só então abra a máquina.
- Tire os pedaços que caíram dentro da caixa e da mesa.
- Lixe de leve as bordas dos furos, se ficaram ásperas, e limpe a fuligem com
  um pano seco.
- Teste o encaixe dos botões, do seletor e do leitor RFID.

## Se algo der errado

| Problema | O que fazer |
|---|---|
| O desenho saiu de tamanho errado | A escala não estava em 100%. Abra o PDF de novo e confira o tamanho da página antes de imprimir. |
| A laser cortou a borda azul | O azul não foi desligado no Dashboard. Apague a borda azul no programa de desenho antes de imprimir. |
| O corte não atravessou | Não mexa na peça. Mande o mesmo trabalho de novo (segunda passada), sem tirar a peça do lugar. |
| Os furos saíram tortos ou fora do lugar | A peça não estava encostada no canto de origem ou estava torta. Use a câmera ou o ponteiro antes de cortar. |
| Uma medida precisa mudar | Mude o valor no topo de `gerar.py` e rode `python3 corte-laser/gerar.py` para gerar os arquivos de novo. |
