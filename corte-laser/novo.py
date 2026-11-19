"""Corte "novo": só os furos concêntricos ao furo redondo (seletor) da tampa.

- TAMPA (415 × 315 mm): furo Ø 25 mm, concêntrico ao seletor Ø 20 mm
  (centro no meio da tampa, a 145 mm da frente).
- FUNDO (400 × 300 mm), caixa de cabeça para baixo: furo Ø 24 mm, alinhado
  com o mesmo eixo. A tampa (415 × 315) é 7,5 mm maior que o fundo
  (400 × 300) de cada lado, então o centro fica a 145 − 7,5 = 137,5 mm da
  frente do fundo e no meio do comprimento. Como o furo está no meio, virar a
  caixa de cabeça para baixo não muda a posição.

Mesmas cores e coordenadas de gerar.py (vermelho = cortar; azul = borda da
peça, não cortar). Rodar:  python3 corte-laser/novo.py
Gera:  novo_tampa.svg, novo_fundo.svg e conferencia_novo_tampa.png / conferencia_novo_fundo.png
"""
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))
import gerar as g  # noqa: E402

TAMPA_FURO_D = 25.0
FUNDO_FURO_D = 24.0

# Centro do seletor, medido da frente da tampa: borda a 135 mm + raio 10 mm.
CENTRO_DA_FRENTE_TAMPA = g.SELETOR_DA_FRENTE + g.SELETOR_D / 2          # 145 mm
SOBRA = (g.TAMPA_L - g.FUNDO_L) / 2                                      # 7,5 mm
CENTRO_DA_FRENTE_FUNDO = CENTRO_DA_FRENTE_TAMPA - SOBRA                  # 137,5 mm


def pecas():
    tampa = g.Peca("novo_tampa", "TAMPA 415 × 315 mm: furo Ø 25 mm concêntrico ao seletor",
                   g.TAMPA_C, g.TAMPA_L,
                   [g.Circ("furo_25", g.TAMPA_C / 2, g.TAMPA_L - CENTRO_DA_FRENTE_TAMPA, TAMPA_FURO_D)])
    fundo = g.Peca("novo_fundo", "FUNDO 400 × 300 mm (de cabeça para baixo): furo Ø 24 mm alinhado ao seletor",
                   g.FUNDO_C, g.FUNDO_L,
                   [g.Circ("furo_24", g.FUNDO_C / 2, g.FUNDO_L - CENTRO_DA_FRENTE_FUNDO, FUNDO_FURO_D)])
    return tampa, fundo


def conferencia(p, arquivo, referencia_d=None):
    """Desenho cotado, no mesmo estilo de gerar.py (4 px por mm)."""
    from PIL import Image, ImageDraw, ImageFont

    esc, m = 4.0, 210
    W, H = int(p.c * esc + 2 * m), int(p.l * esc + 2 * m + 60)
    im = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
        fb = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
    except OSError:
        f = fb = ImageFont.load_default()
    P = lambda x, y: (m + x * esc, m + 60 + y * esc)
    cinza, texto = (120, 120, 120), (60, 60, 60)
    cm = lambda v: f"{v / 10:g} cm".replace(".", ",")

    d.text((m, 30), p.titulo, font=fb, fill="black")
    d.rectangle([P(0, 0), P(p.c, p.l)], outline=(0, 0, 255), width=3)
    d.text(P(p.c / 2 - 18, p.l + 4), "FRENTE", font=f, fill=(0, 0, 255))
    d.text(P(p.c / 2 - 12, -8), "TRÁS", font=f, fill=(0, 0, 255))
    d.line([P(p.c / 2, 0), P(p.c / 2, p.l)], fill=(215, 215, 215), width=1)
    d.text(P(p.c / 2 + 3, 4), "centro", font=f, fill=(160, 160, 160))

    fu = p.furos[0]
    r = fu.d / 2
    if referencia_d:  # seletor atual, tracejado, para mostrar que é concêntrico
        rr = referencia_d / 2
        for k in range(0, 360, 20):
            d.arc([P(fu.cx - rr, fu.cy - rr), P(fu.cx + rr, fu.cy + rr)], k, k + 10, fill=(150, 150, 150), width=2)
    d.ellipse([P(fu.cx - r, fu.cy - r), P(fu.cx + r, fu.cy + r)], outline=(220, 0, 0), width=3)
    d.line([P(fu.cx - 4, fu.cy), P(fu.cx + 4, fu.cy)], fill=(220, 0, 0), width=2)
    d.line([P(fu.cx, fu.cy - 4), P(fu.cx, fu.cy + 4)], fill=(220, 0, 0), width=2)
    rotulo = f"Ø {cm(fu.d)}" + (f"  (seletor atual Ø {cm(referencia_d)} tracejado)" if referencia_d else "")
    d.text(P(fu.cx + r + 4, fu.cy - r - 8), rotulo, font=f, fill=texto)

    # centro até a frente (vertical) e até a esquerda (horizontal)
    x = fu.cx + 35
    d.line([P(x, fu.cy), P(x, p.l)], fill=cinza, width=2)
    for yy in (fu.cy, p.l):
        d.line([P(x - 2, yy), P(x + 2, yy)], fill=cinza, width=2)
    d.line([P(fu.cx, fu.cy), P(x, fu.cy)], fill=(200, 200, 200), width=1)
    d.text((P(x, (fu.cy + p.l) / 2)[0] + 8, P(x, (fu.cy + p.l) / 2)[1] - 11),
           f"{cm(p.l - fu.cy)} da frente até o centro", font=f, fill=texto)
    y = fu.cy + 45
    d.line([P(0, y), P(fu.cx, y)], fill=cinza, width=2)
    for xx in (0, fu.cx):
        d.line([P(xx, y - 2), P(xx, y + 2)], fill=cinza, width=2)
    d.line([P(fu.cx, fu.cy), P(fu.cx, y)], fill=(200, 200, 200), width=1)
    d.text((P(fu.cx / 2, y)[0] - 150, P(fu.cx / 2, y)[1] - 30),
           f"{cm(fu.cx)} da esquerda até o centro", font=f, fill=texto)

    # medidas gerais
    d.line([P(0, -18), P(p.c, -18)], fill=(0, 0, 255), width=2)
    d.text((P(p.c / 2, -18)[0] + 60, P(p.c / 2, -18)[1] - 30), cm(p.c), font=f, fill=(0, 0, 255))
    d.line([P(-18, 0), P(-18, p.l)], fill=(0, 0, 255), width=2)
    d.text((P(-18, p.l / 2)[0] - 105, P(-18, p.l / 2)[1] - 11), cm(p.l), font=f, fill=(0, 0, 255))
    d.text((m, H - 50), "vermelho = cortar · azul = borda da peça (referência, não cortar) · medidas até o CENTRO do furo",
           font=f, fill=(80, 80, 80))
    im.save(arquivo)


def main():
    for p in pecas():
        g.conferir(p)
        (AQUI / f"{p.nome}.svg").write_text(g.svg(p, contorno_corta=False), encoding="utf-8")
        conferencia(p, AQUI / f"conferencia_{p.nome}.png",
                    referencia_d=g.SELETOR_D if p.nome == "novo_tampa" else None)
        f = p.furos[0]
        print(f"{p.nome}.svg: Ø {f.d:g} mm, centro a {f.cx:g} mm da esquerda e {p.l - f.cy:g} mm da frente")


if __name__ == "__main__":
    main()
