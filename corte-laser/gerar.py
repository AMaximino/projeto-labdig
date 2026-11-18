"""Arquivos de corte a laser (Epilog Fusion Pro 48) da tampa e do fundo da caixa.

A caixa de MDF já vem pronta (41,5 × 31,5 × 20,5 cm, MDF de 5 mm). A laser só
abre os furos:

- TAMPA (415 × 315 mm): 6 botões de ação, seletor, 2 botões da direita e a
  abertura do RFID;
- FUNDO (400 × 300 mm), com a caixa de cabeça para baixo: 1 abertura de 80 × 60 mm.

Medidas confirmadas a partir do desenho caixa-labdig.pdf. Todas as distâncias
vão da borda da peça até a BORDA do furo, menos o passo dos botões (25 mm),
que é entre centros. Cada peça é medida a partir das próprias bordas.

Coordenadas: mm, origem no canto de TRÁS à esquerda da peça (canto de cima à
esquerda da mesa da laser), X para a direita, Y para a frente. A frente da peça
fica na parte de baixo do arquivo, como no desenho.

Cores (mapeamento de cores do driver da Epilog):
- vermelho RGB(255,0,0), linha fina: CORTAR (vetor);
- azul RGB(0,0,255): contorno da peça, só referência, NÃO cortar
  (desligue essa cor no Color Mapping ou apague a camada antes de enviar).

Rodar:  python3 corte-laser/gerar.py
Gera:   tampa.svg/.pdf/.dxf, fundo.svg/.pdf/.dxf, teste.svg/.pdf/.dxf e
        conferencia_tampa.png / conferencia_fundo.png (desenho cotado).
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

AQUI = Path(__file__).resolve().parent

# ---------------------------------------------------------------- medidas (mm)
MDF = 5.0  # espessura (para a configuração de corte; não muda a geometria)

TAMPA_C, TAMPA_L = 415.0, 315.0  # comprimento (esq.→dir.) × largura (trás→frente)
FUNDO_C, FUNDO_L = 400.0, 300.0

# 6 botões de ação: quadrados de 15 mm, passo de 25 mm entre centros,
# fileira centralizada, borda de baixo a 40 mm da frente.
BOTAO = 15.0
BOTAO_PASSO = 25.0
BOTOES_N = 6
BOTOES_DA_FRENTE = 40.0

# Seletor: furo redondo Ø 20 mm, centralizado, borda de baixo 80 mm acima da
# borda de cima dos botões de ação.
SELETOR_D = 20.0
SELETOR_ACIMA_BOTOES = 80.0
SELETOR_DA_FRENTE = BOTOES_DA_FRENTE + BOTAO + SELETOR_ACIMA_BOTOES  # 135 mm

# 2 botões da direita: quadrados de 15 mm, lado direito a 40 mm da borda
# direita; o de baixo com a borda de baixo a 120 mm da frente; o de cima 25 mm
# acima (entre centros).
DIR_DA_DIREITA = 40.0
DIR_BAIXO_DA_FRENTE = 120.0
DIR_PASSO = 25.0

# Abertura do RFID: 40 × 20 mm, lado esquerdo a 40 mm da borda esquerda,
# borda de baixo a 150 mm da frente.
RFID_C, RFID_L = 40.0, 20.0
RFID_DA_ESQUERDA = 40.0
RFID_DA_FRENTE = 150.0

# Fundo: abertura de 80 × 60 mm, centralizada, borda a 30 mm da frente.
FUNDO_FURO_C, FUNDO_FURO_L = 80.0, 60.0
FUNDO_FURO_DA_FRENTE = 30.0

MADEIRA_MIN = 8.0  # madeira mínima entre furos e até a borda (conferência)

# Linha de corte: "hairline" da Epilog (0,001 pol = 0,0254 mm).
LINHA_MM = 0.0254
VERMELHO = (255, 0, 0)
AZUL = (0, 0, 255)


# ---------------------------------------------------------------- geometria
@dataclass
class Ret:
    nome: str
    x: float  # canto de trás à esquerda
    y: float
    c: float  # largura em X
    l: float  # altura em Y

    @property
    def caixa(self):
        return self.x, self.y, self.x + self.c, self.y + self.l


@dataclass
class Circ:
    nome: str
    cx: float
    cy: float
    d: float

    @property
    def caixa(self):
        r = self.d / 2
        return self.cx - r, self.cy - r, self.cx + r, self.cy + r


@dataclass
class Peca:
    nome: str
    titulo: str
    c: float
    l: float
    furos: list


def da_frente(l_peca: float, distancia: float, altura: float) -> float:
    """Y da borda de trás de um furo cuja borda da frente fica a `distancia` da frente."""
    return l_peca - distancia - altura


def tampa() -> Peca:
    furos = []
    meio = TAMPA_C / 2
    y = da_frente(TAMPA_L, BOTOES_DA_FRENTE, BOTAO)
    for k in range(BOTOES_N):
        cx = meio + (k - (BOTOES_N - 1) / 2) * BOTAO_PASSO
        furos.append(Ret(f"botão {k + 1}", cx - BOTAO / 2, y, BOTAO, BOTAO))
    r = SELETOR_D / 2
    furos.append(Circ("seletor", meio, TAMPA_L - SELETOR_DA_FRENTE - r, SELETOR_D))
    x = TAMPA_C - DIR_DA_DIREITA - BOTAO
    y_baixo = da_frente(TAMPA_L, DIR_BAIXO_DA_FRENTE, BOTAO)
    furos.append(Ret("direita de baixo", x, y_baixo, BOTAO, BOTAO))
    furos.append(Ret("direita de cima", x, y_baixo - DIR_PASSO, BOTAO, BOTAO))
    furos.append(Ret("RFID", RFID_DA_ESQUERDA, da_frente(TAMPA_L, RFID_DA_FRENTE, RFID_L), RFID_C, RFID_L))
    return Peca("tampa", "TAMPA 415 × 315 mm (vista de cima, frente embaixo)", TAMPA_C, TAMPA_L, furos)


def fundo() -> Peca:
    furo = Ret("abertura", (FUNDO_C - FUNDO_FURO_C) / 2,
               da_frente(FUNDO_L, FUNDO_FURO_DA_FRENTE, FUNDO_FURO_L), FUNDO_FURO_C, FUNDO_FURO_L)
    return Peca("fundo", "FUNDO 400 × 300 mm (caixa de cabeça para baixo, frente embaixo)", FUNDO_C, FUNDO_L, [furo])


def teste() -> Peca:
    """Peça de teste: confere potência/velocidade e o encaixe do botão e do seletor."""
    return Peca("teste", "TESTE 75 × 40 mm", 75.0, 40.0, [
        Ret("botão", 12.0, 12.5, BOTAO, BOTAO),
        Circ("seletor", 52.0, 20.0, SELETOR_D),
    ])


def conferir(p: Peca) -> None:
    caixas = [(f.nome, f.caixa) for f in p.furos]
    for nome, (x0, y0, x1, y1) in caixas:
        assert x0 >= MADEIRA_MIN and y0 >= MADEIRA_MIN and x1 <= p.c - MADEIRA_MIN and y1 <= p.l - MADEIRA_MIN, \
            f"{p.nome}: {nome} perto demais da borda"
    for i, (n1, a) in enumerate(caixas):
        for n2, b in caixas[i + 1:]:
            folga = max(b[0] - a[2], a[0] - b[2], b[1] - a[3], a[1] - b[3])
            assert folga >= MADEIRA_MIN or p.nome == "teste", f"{p.nome}: {n1} e {n2} com {folga:.1f} mm de madeira"


# ---------------------------------------------------------------- SVG
def svg(p: Peca, contorno_corta: bool) -> str:
    hexa = lambda c: "#%02x%02x%02x" % c
    cor_contorno = VERMELHO if contorno_corta else AZUL
    partes = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{p.c}mm" height="{p.l}mm" viewBox="0 0 {p.c} {p.l}">',
        f'<title>{p.titulo}</title>',
        f'<g id="referencia_nao_cortar" fill="none" stroke="{hexa(cor_contorno)}" stroke-width="{LINHA_MM}">'
        f'<rect x="0" y="0" width="{p.c}" height="{p.l}"/></g>',
        f'<g id="corte" fill="none" stroke="{hexa(VERMELHO)}" stroke-width="{LINHA_MM}">',
    ]
    for f in p.furos:
        if isinstance(f, Ret):
            partes.append(f'<rect id="{f.nome.replace(" ", "_")}" x="{f.x:.3f}" y="{f.y:.3f}" width="{f.c:.3f}" height="{f.l:.3f}"/>')
        else:
            partes.append(f'<circle id="{f.nome}" cx="{f.cx:.3f}" cy="{f.cy:.3f}" r="{f.d / 2:.3f}"/>')
    partes += ["</g>", "</svg>", ""]
    return "\n".join(partes)


# ---------------------------------------------------------------- PDF (vetorial, 1:1)
def pdf(p: Peca, contorno_corta: bool) -> bytes:
    pt = 72 / 25.4
    W, H = p.c * pt, p.l * pt
    X = lambda x: x * pt
    Y = lambda y: H - y * pt  # PDF tem origem embaixo
    k = 0.5523
    ops = [f"{LINHA_MM * pt:.4f} w", "0 J 0 j"]

    def cor(c):
        ops.append("%.3f %.3f %.3f RG" % tuple(v / 255 for v in c))

    def ret(x, y, c, l):
        ops.append(f"{X(x):.3f} {Y(y + l):.3f} {c * pt:.3f} {l * pt:.3f} re S")

    def circ(cx, cy, r):
        a, b, R, K = X(cx), Y(cy), r * pt, r * pt * k
        ops.append(f"{a + R:.3f} {b:.3f} m "
                   f"{a + R:.3f} {b + K:.3f} {a + K:.3f} {b + R:.3f} {a:.3f} {b + R:.3f} c "
                   f"{a - K:.3f} {b + R:.3f} {a - R:.3f} {b + K:.3f} {a - R:.3f} {b:.3f} c "
                   f"{a - R:.3f} {b - K:.3f} {a - K:.3f} {b - R:.3f} {a:.3f} {b - R:.3f} c "
                   f"{a + K:.3f} {b - R:.3f} {a + R:.3f} {b - K:.3f} {a + R:.3f} {b:.3f} c h S")

    cor(VERMELHO if contorno_corta else AZUL)
    ret(0, 0, p.c, p.l)
    cor(VERMELHO)
    for f in p.furos:
        if isinstance(f, Ret):
            ret(f.x, f.y, f.c, f.l)
        else:
            circ(f.cx, f.cy, f.d / 2)
    conteudo = "\n".join(ops).encode()
    objs = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {W:.3f} {H:.3f}] /Contents 4 0 R /Resources << >> >>".encode(),
        b"<< /Length %d >>\nstream\n" % len(conteudo) + conteudo + b"\nendstream",
        f"<< /Title ({p.nome}) /Creator (corte-laser/gerar.py) >>".encode(),
    ]
    saida = bytearray(b"%PDF-1.4\n")
    posicoes = []
    for i, o in enumerate(objs, start=1):
        posicoes.append(len(saida))
        saida += b"%d 0 obj\n" % i + o + b"\nendobj\n"
    xref = len(saida)
    saida += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objs) + 1)
    for pos in posicoes:
        saida += b"%010d 00000 n \n" % pos
    saida += b"trailer\n<< /Size %d /Root 1 0 R /Info 5 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objs) + 1, xref)
    return bytes(saida)


# ---------------------------------------------------------------- DXF (R12, mm)
def dxf(p: Peca, contorno_corta: bool) -> str:
    # Y do DXF cresce para cima: espelha para a frente ficar embaixo.
    linhas = ["0", "SECTION", "2", "HEADER", "9", "$INSUNITS", "70", "4", "9", "$MEASUREMENT", "70", "1",
              "0", "ENDSEC", "0", "SECTION", "2", "TABLES", "0", "TABLE", "2", "LAYER", "70", "2",
              "0", "LAYER", "2", "CORTE", "70", "0", "62", "1", "6", "CONTINUOUS",
              "0", "LAYER", "2", "REFERENCIA_NAO_CORTAR", "70", "0", "62", "5", "6", "CONTINUOUS",
              "0", "ENDTAB", "0", "ENDSEC", "0", "SECTION", "2", "ENTITIES"]

    def ret(x, y, c, l, camada):
        pts = [(x, y), (x + c, y), (x + c, y + l), (x, y + l)]
        linhas.extend(["0", "POLYLINE", "8", camada, "66", "1", "70", "1"])
        for px, py in pts:
            linhas.extend(["0", "VERTEX", "8", camada, "10", f"{px:.4f}", "20", f"{p.l - py:.4f}", "30", "0"])
        linhas.extend(["0", "SEQEND", "8", camada])

    ret(0, 0, p.c, p.l, "CORTE" if contorno_corta else "REFERENCIA_NAO_CORTAR")
    for f in p.furos:
        if isinstance(f, Ret):
            ret(f.x, f.y, f.c, f.l, "CORTE")
        else:
            linhas.extend(["0", "CIRCLE", "8", "CORTE", "10", f"{f.cx:.4f}", "20", f"{p.l - f.cy:.4f}", "30", "0",
                           "40", f"{f.d / 2:.4f}"])
    linhas.extend(["0", "ENDSEC", "0", "EOF"])
    return "\n".join(linhas) + "\n"


# ---------------------------------------------------------------- desenho cotado
def conferencia(p: Peca, arquivo: Path) -> None:
    from PIL import Image, ImageDraw, ImageFont

    esc = 4.0  # px por mm
    m = 210
    W, H = int(p.c * esc + 2 * m), int(p.l * esc + 2 * m + 60)
    im = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
        fb = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
    except OSError:
        f = fb = ImageFont.load_default()
    P = lambda x, y: (m + x * esc, m + 60 + y * esc)
    d.text((m, 30), p.titulo, font=fb, fill="black")
    d.rectangle([P(0, 0), P(p.c, p.l)], outline=(0, 0, 255), width=3)
    d.text(P(p.c / 2 - 18, p.l + 4), "FRENTE", font=f, fill=(0, 0, 255))
    d.text(P(p.c / 2 - 12, -8), "TRÁS", font=f, fill=(0, 0, 255))
    cota = (120, 120, 120)

    def cota_v(x, y0, y1, texto, y_texto=None):
        d.line([P(x, y0), P(x, y1)], fill=cota, width=2)
        for yy in (y0, y1):
            d.line([P(x - 2, yy), P(x + 2, yy)], fill=cota, width=2)
        yt = (y0 + y1) / 2 if y_texto is None else y_texto
        d.text((P(x, yt)[0] + 8, P(x, yt)[1] - 11), texto, font=f, fill=(60, 60, 60))

    def cota_h(y, x0, x1, texto):
        d.line([P(x0, y), P(x1, y)], fill=cota, width=2)
        for xx in (x0, x1):
            d.line([P(xx, y - 2), P(xx, y + 2)], fill=cota, width=2)
        d.text((P((x0 + x1) / 2, y)[0] - 30, P((x0 + x1) / 2, y)[1] - 30), texto, font=f, fill=(60, 60, 60))

    for fu in p.furos:
        x0, y0, x1, y1 = fu.caixa
        if isinstance(fu, Ret):
            d.rectangle([P(x0, y0), P(x1, y1)], outline=(220, 0, 0), width=3)
        else:
            d.ellipse([P(x0, y0), P(x1, y1)], outline=(220, 0, 0), width=3)
    cm = lambda v: f"{v / 10:g} cm".replace(".", ",")
    if p.nome == "tampa":
        b1, b6 = p.furos[0], p.furos[5]
        cota_v(b1.x - 8, b1.y + b1.l, p.l, cm(BOTOES_DA_FRENTE))
        cota_h(b1.y - 6, b1.x + b1.c / 2, b1.x + b1.c / 2 + BOTAO_PASSO, cm(BOTAO_PASSO))
        cota_h(b6.y + b6.l + 12, b6.x, b6.x + b6.c, cm(BOTAO))
        s = p.furos[6]
        # passa no vão entre o 3º e o 4º botão
        cota_v(s.cx, s.cy + s.d / 2, b1.y, cm(SELETOR_ACIMA_BOTOES) + " acima dos botões")
        d.text(P(s.cx + 14, s.cy - 18), f"Ø {cm(SELETOR_D)}", font=f, fill=(60, 60, 60))
        db, dc = p.furos[7], p.furos[8]
        cota_v(db.x - 8, db.y + db.l, p.l, cm(DIR_BAIXO_DA_FRENTE))
        cota_h(dc.y - 8, db.x + db.c, p.c, cm(DIR_DA_DIREITA))
        cota_v(db.x + db.c + 6, dc.y + dc.l / 2, db.y + db.l / 2, cm(DIR_PASSO))
        r = p.furos[9]
        cota_h(r.y - 8, 0, r.x, cm(RFID_DA_ESQUERDA))
        cota_v(r.x + r.c + 8, r.y + r.l, p.l, cm(RFID_DA_FRENTE))
        d.text(P(r.x, r.y - 30), f"RFID {cm(RFID_C)} × {cm(RFID_L)}", font=f, fill=(60, 60, 60))
        d.line([P(p.c / 2, 0), P(p.c / 2, p.l)], fill=(215, 215, 215), width=1)
        d.text(P(p.c / 2 + 3, 4), "centro", font=f, fill=(160, 160, 160))
        d.text(P(db.x - 2, db.y + db.l + 3), "1,5 × 1,5 cm", font=f, fill=(60, 60, 60))
    elif p.nome == "fundo":
        a = p.furos[0]
        cota_v(a.x - 10, a.y + a.l, p.l, cm(FUNDO_FURO_DA_FRENTE))
        cota_h(a.y - 10, a.x, a.x + a.c, cm(FUNDO_FURO_C))
        cota_v(a.x + a.c + 10, a.y, a.y + a.l, cm(FUNDO_FURO_L))
        d.line([P(p.c / 2, 0), P(p.c / 2, p.l)], fill=(200, 200, 200), width=1)
        d.text(P(p.c / 2 + 3, 4), "centro", font=f, fill=(160, 160, 160))
    # medidas gerais da peça
    d.line([P(0, -18), P(p.c, -18)], fill=(0, 0, 255), width=2)
    d.text((P(p.c / 2, -18)[0] + 60, P(p.c / 2, -18)[1] - 30), cm(p.c), font=f, fill=(0, 0, 255))
    d.line([P(-18, 0), P(-18, p.l)], fill=(0, 0, 255), width=2)
    d.text((P(-18, p.l / 2)[0] - 105, P(-18, p.l / 2)[1] - 11), cm(p.l), font=f, fill=(0, 0, 255))
    d.text((m, H - 50), "vermelho = cortar · azul = borda da peça (referência, não cortar) · medidas até a borda do furo",
           font=f, fill=(80, 80, 80))
    im.save(arquivo)


def main() -> None:
    for p, contorno_corta in [(tampa(), False), (fundo(), False), (teste(), True)]:
        conferir(p)
        (AQUI / f"{p.nome}.svg").write_text(svg(p, contorno_corta), encoding="utf-8")
        (AQUI / f"{p.nome}.pdf").write_bytes(pdf(p, contorno_corta))
        (AQUI / f"{p.nome}.dxf").write_text(dxf(p, contorno_corta), encoding="ascii")
        if p.nome != "teste":
            conferencia(p, AQUI / f"conferencia_{p.nome}.png")
        print(f"{p.nome}: {len(p.furos)} furos")
        for f in p.furos:
            x0, y0, x1, y1 = f.caixa
            print(f"  {f.nome:18s} esq {x0:6.1f}  dir {p.c - x1:6.1f}  trás {y0:6.1f}  frente {p.l - y1:6.1f} mm")


if __name__ == "__main__":
    main()
