# Manual do jogador

## Livro de regras (livrinho, recomendado)

Livrinho de 8 páginas A5, no estilo de manual de jogo de tabuleiro.

- **Imprimir:** `livrinho_impressao.pdf`, que tem 2 folhas A4 já na ordem do
  livrinho. Imprima colorido, em escala 100% (sem "ajustar à página"), frente e
  verso **virando pela borda curta**. Dobre as duas folhas juntas ao meio, com a
  capa para fora, e grampeie na dobra.
- **Ler na tela:** `livrinho.pdf` (páginas na ordem normal).
- **Editar:** mude `livrinho.html` e rode
  `python3 manual-jogador/gerar_livrinho.py <caminho do chrome>`, que gera os
  dois PDFs. O número de páginas precisa ser múltiplo de 4.

## Folha de regras (versão antiga)

`manual-jogador.pdf`: 2 páginas A4 (frente e verso), gerado de `manual.html`.

Os textos seguem o feedback da especialista: frases curtas e literais, uma
ação por botão, cores iguais às capas dos botões e aos adesivos da tampa. Os
valores (saldo inicial, salário, preços e contas) são os de `front/app.js`;
se as regras da FPGA mudarem, atualize o manual também.
