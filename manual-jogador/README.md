# Manual do jogador

Folha de 2 páginas A4 (frente e verso) para imprimir e entregar aos jogadores.

- **Imprimir:** `manual-jogador.pdf`, em A4, frente e verso, colorido, escala 100%.
- **Editar:** mude `manual.html` e gere o PDF de novo no Chrome
  (Imprimir → Salvar como PDF, margens "Nenhuma", com "Gráficos de plano de
  fundo" ligado) ou pela linha de comando:

  ```sh
  chrome --headless --no-pdf-header-footer --print-to-pdf=manual-jogador.pdf manual.html
  ```

Os textos seguem o feedback da especialista: frases curtas e literais, uma
ação por botão, cores iguais às capas dos botões e aos adesivos da tampa. Os
valores (saldo inicial, salário, preços e contas) são os de `front/app.js`;
se as regras da FPGA mudarem, atualize o manual também.
