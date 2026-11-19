# Cenário em loop

Cenário animado para ficar numa tela ao lado do jogo durante a Feira:
uma cidadezinha em tons pastel com moedas, notas, livros, peças de montar,
videogame e computador subindo devagar, um cofrinho recebendo moedas, uma
árvore de moedas crescendo e carros passando. No topo, frases curtas trocam a
cada 6 s: "Trabalhe e ganhe dinheiro", "Estude e aprenda mais", "Guarde e veja
crescer" e "Vamos jogar?".

Pensado para conforto sensorial: cores suaves, movimentos lentos e nada que
pisque. O ciclo inteiro dura 24 s e emenda sem corte.

## Como abrir

- **No navegador (localhost):** com o backend rodando (`npm --prefix back start`),
  abra **http://localhost:3000/cenario/** e aperte **F11** para tela cheia. A
  animação roda direto no navegador, em qualquer resolução.
- **Como vídeo:** `front/cenario/cenario_loop.mp4` (1920 × 1080, 30 fps, 24 s).
  Abra num player com repetição ligada. Também fica em
  http://localhost:3000/cenario/cenario_loop.mp4.

## Arquivos

| Arquivo | O que é |
|---|---|
| `front/cenario/index.html` | o cenário (SVG + CSS, sem scripts) |
| `front/cenario/cenario_loop.mp4` | o vídeo em loop gerado a partir da página |
| `cenario/gerar_video.py` | gera o vídeo: captura os 720 quadros no instante exato e monta o MP4 |

Para gerar o vídeo de novo depois de mudar a página:

```sh
pip install playwright && python3 -m playwright install chromium
python3 cenario/gerar_video.py            # ou --previa para só 6 quadros de amostra
```

Todas as animações têm período que divide 24 s; ao acrescentar uma, mantenha
isso para o loop continuar emendando.
