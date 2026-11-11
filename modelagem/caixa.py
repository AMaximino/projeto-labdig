"""Modelo paramétrico da caixa do jogo Aventura Financeira Evolution.

Gera, em modelagem/saida/:
  - gabarito_tampa.dxf       furos e marcações da tampa, escala 1:1 (AutoCAD/laser)
  - gabarito_tampa.pdf       o mesmo gabarito em folhas A4 para imprimir e colar
  - gabarito_traseira.dxf    rasgo de passagem dos cabos na parede traseira
  - gabarito_traseira.pdf
  - caixa.step / caixa.stl   modelo 3D montado (Fusion 360: File → Open)
  - caixa.glb                modelo 3D para o visualizador web (modelagem/visualizador/)
  - previa_tampa.png         prévia da tampa para conferência

Uso, na raiz do repositório:
    modelagem/.venv/bin/python modelagem/caixa.py

Sistema de coordenadas da tampa (vista de cima, jogador na frente):
  origem no canto frontal esquerdo, X para a direita (comprimento 415 mm),
  Y para o fundo (largura 315 mm). Todas as medidas em milímetros.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

import ezdxf
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.backends.backend_pdf import PdfPages  # noqa: E402
from matplotlib.patches import Circle, FancyBboxPatch, Rectangle  # noqa: E402

SAIDA = Path(__file__).resolve().parent / "saida"

# ---------------------------------------------------------------------------
# Parâmetros. [CONFIRMADO] veio do anúncio/usuário; [ASSUMIDO] precisa medir.
# ---------------------------------------------------------------------------

# Caixa MDF cru 41,5 × 31,5 × 20,5 cm [CONFIRMADO]
CAIXA_C = 415.0          # comprimento externo (X)
CAIXA_L = 315.0          # largura externa (Y)
CAIXA_A = 205.0          # altura externa total, com tampa fechada
MDF = 6.0                # espessura das paredes e da tampa [ASSUMIDO]
TAMPA_A = 50.0           # altura da tampa (aba lateral) [ASSUMIDO]

# Botão táctil 12×12 com capa [CONFIRMADO tipo; ASSUMIDO capa]
BOTAO_CORPO = 12.0       # corpo quadrado do botão
CAPA_DIAM = 12.0         # diâmetro (ou lado) da capa [ASSUMIDO]
FURO_BOTAO = 13.0        # furo na tampa: capa + 1 mm de folga
ALTURA_BOTAO_CAPA = 13.0 # da placa até o topo da capa [ASSUMIDO]
SOBRESSAI = 2.0          # quanto a capa sai acima da tampa

# RC522 [medidas típicas de 60 × 40 mm; conferir a placa recebida]
RC522_C, RC522_L = 60.0, 40.0
CARTAO_C, CARTAO_L = 85.6, 54.0   # cartão ISO/IEC 7810 ID-1

# Placas internas (não aparecem por fora)
FPGA_C, FPGA_L = 128.0, 99.0      # Terasic DE0-CV (conferir)
ESP_C, ESP_L = 55.0, 28.0         # ESP32 DevKit 30/38 pinos
ESPACADOR = 10.0                  # altura dos espaçadores das placas

# Rasgo para cabos (USB da FPGA, USB da ESP32, fonte) na parede traseira
RASGO_C, RASGO_A = 50.0, 25.0
RASGO_X = CAIXA_C / 2             # centro do rasgo, ao longo do comprimento
RASGO_Z = 15.0                    # distância do fundo até a borda inferior

MARGEM_MIN = 30.0                 # distância mínima dos furos à borda da tampa

# ---------------------------------------------------------------------------
# Layout da tampa
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Botao:
    nome: str
    x: float
    y: float


# Leitor RFID à esquerda; ações em grade 3 × 2 à direita, agrupadas por par
# (trabalhar/estudar, investir/resgatar, comprar/vender); iniciar e reset
# afastados no canto do fundo para não serem apertados sem querer.
RFID_X, RFID_Y = 115.0, 150.0

PASSO = 50.0
COL_X = (240.0, 240.0 + PASSO, 240.0 + 2 * PASSO)
LINHA_FUNDO, LINHA_FRENTE = 175.0, 115.0

BOTOES = [
    Botao("TRABALHAR", COL_X[0], LINHA_FUNDO),
    Botao("ESTUDAR", COL_X[0], LINHA_FRENTE),
    Botao("INVESTIR", COL_X[1], LINHA_FUNDO),
    Botao("RESGATAR", COL_X[1], LINHA_FRENTE),
    Botao("COMPRAR", COL_X[2], LINHA_FUNDO),
    Botao("VENDER", COL_X[2], LINHA_FRENTE),
    Botao("INICIAR", COL_X[1], 265.0),
    Botao("RESET", COL_X[2], 265.0),
]


def validar() -> None:
    r = FURO_BOTAO / 2
    for b in BOTOES:
        assert MARGEM_MIN <= b.x - r and b.x + r <= CAIXA_C - MARGEM_MIN, b
        assert MARGEM_MIN <= b.y - r and b.y + r <= CAIXA_L - MARGEM_MIN, b
    for i, a in enumerate(BOTOES):
        for b in BOTOES[i + 1:]:
            assert math.dist((a.x, a.y), (b.x, b.y)) >= 2 * FURO_BOTAO, (a, b)
    assert RFID_X - CARTAO_C / 2 >= MARGEM_MIN
    assert RFID_X + CARTAO_C / 2 + MARGEM_MIN <= min(b.x for b in BOTOES) - r
    assert ALTURA_BOTAO_CAPA - MDF - SOBRESSAI > 0, "capa não alcança a tampa"


def espacador_botoes() -> float:
    """Distância entre a face inferior da tampa e a placa dos botões."""
    return ALTURA_BOTAO_CAPA - MDF - SOBRESSAI


# ---------------------------------------------------------------------------
# DXF
# ---------------------------------------------------------------------------

CAMADAS = {
    "CORTE": 1,        # vermelho: furar/cortar
    "GRAVACAO": 5,     # azul: textos para gravar ou pintar (opcional)
    "REFERENCIA": 8,   # cinza: contorno, peças por baixo; não cortar
    "CENTRO": 3,       # verde: cruz de centro para a broca
}


def novo_dxf() -> tuple[ezdxf.document.Drawing, object]:
    doc = ezdxf.new("R2010", setup=True)
    doc.units = ezdxf.units.MM
    for nome, cor in CAMADAS.items():
        doc.layers.add(nome, color=cor)
    doc.layers.get("REFERENCIA").dxf.linetype = "DASHED"
    return doc, doc.modelspace()


def cruz(msp, x: float, y: float, t: float = 4.0) -> None:
    msp.add_line((x - t, y), (x + t, y), dxfattribs={"layer": "CENTRO"})
    msp.add_line((x, y - t), (x, y + t), dxfattribs={"layer": "CENTRO"})


def retangulo(msp, cx, cy, c, l, camada):
    pts = [(cx - c / 2, cy - l / 2), (cx + c / 2, cy - l / 2),
           (cx + c / 2, cy + l / 2), (cx - c / 2, cy + l / 2)]
    msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": camada})


def texto(msp, s, x, y, h=5.0, camada="GRAVACAO"):
    msp.add_text(s, height=h, dxfattribs={"layer": camada}).set_placement(
        (x, y), align=ezdxf.enums.TextEntityAlignment.MIDDLE_CENTER)


def dxf_tampa(caminho: Path) -> None:
    doc, msp = novo_dxf()
    msp.add_lwpolyline([(0, 0), (CAIXA_C, 0), (CAIXA_C, CAIXA_L), (0, CAIXA_L)],
                       close=True, dxfattribs={"layer": "REFERENCIA"})
    for b in BOTOES:
        msp.add_circle((b.x, b.y), FURO_BOTAO / 2, dxfattribs={"layer": "CORTE"})
        cruz(msp, b.x, b.y)
        texto(msp, b.nome, b.x, b.y - FURO_BOTAO / 2 - 7)
    retangulo(msp, RFID_X, RFID_Y, CARTAO_C, CARTAO_L, "GRAVACAO")
    retangulo(msp, RFID_X, RFID_Y, RC522_C, RC522_L, "REFERENCIA")
    cruz(msp, RFID_X, RFID_Y)
    texto(msp, "APROXIME O CARTAO", RFID_X, RFID_Y - CARTAO_L / 2 - 8)
    texto(msp, "FRENTE (jogador)", CAIXA_C / 2, 8, 4, "REFERENCIA")
    doc.saveas(caminho)


def dxf_traseira(caminho: Path) -> None:
    """Parede traseira vista de FORA; X da esquerda para a direita de quem
    olha a traseira (espelhado em relação à tampa), Z do fundo para cima."""
    doc, msp = novo_dxf()
    altura_corpo = CAIXA_A - TAMPA_A
    msp.add_lwpolyline([(0, 0), (CAIXA_C, 0), (CAIXA_C, altura_corpo),
                        (0, altura_corpo)], close=True,
                       dxfattribs={"layer": "REFERENCIA"})
    x = CAIXA_C - RASGO_X
    z = RASGO_Z + RASGO_A / 2
    r = 6.0
    msp.add_lwpolyline(_retangulo_arredondado(x, z, RASGO_C, RASGO_A, r),
                       close=True, dxfattribs={"layer": "CORTE"})
    cruz(msp, x, z)
    texto(msp, "CABOS (USB / fonte)", x, z + RASGO_A / 2 + 8)
    texto(msp, "FUNDO", CAIXA_C / 2, 6, 4, "REFERENCIA")
    doc.saveas(caminho)


def _retangulo_arredondado(cx, cy, c, l, r, n=8):
    pts = []
    cantos = [(cx + c / 2 - r, cy - l / 2 + r, -90), (cx + c / 2 - r, cy + l / 2 - r, 0),
              (cx - c / 2 + r, cy + l / 2 - r, 90), (cx - c / 2 + r, cy - l / 2 + r, 180)]
    for ox, oy, a0 in cantos:
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((ox + r * math.cos(a), oy + r * math.sin(a)))
    return pts


# ---------------------------------------------------------------------------
# PDF 1:1 em folhas A4 e prévia PNG
# ---------------------------------------------------------------------------


def desenhar_tampa(ax) -> None:
    ax.add_patch(Rectangle((0, 0), CAIXA_C, CAIXA_L, fill=False, ls="--", lw=0.6,
                           ec="0.5"))
    for b in BOTOES:
        ax.add_patch(Circle((b.x, b.y), FURO_BOTAO / 2, fill=False, ec="red", lw=0.8))
        _cruz_mpl(ax, b.x, b.y)
        ax.text(b.x, b.y - FURO_BOTAO / 2 - 6, b.nome, ha="center", va="center",
                fontsize=7, color="tab:blue")
    ax.add_patch(FancyBboxPatch((RFID_X - CARTAO_C / 2, RFID_Y - CARTAO_L / 2),
                                CARTAO_C, CARTAO_L, boxstyle="round,pad=0,rounding_size=3",
                                fill=False, ec="tab:blue", lw=0.8))
    ax.add_patch(Rectangle((RFID_X - RC522_C / 2, RFID_Y - RC522_L / 2), RC522_C,
                           RC522_L, fill=False, ls="--", ec="0.5", lw=0.6))
    _cruz_mpl(ax, RFID_X, RFID_Y)
    ax.text(RFID_X, RFID_Y - CARTAO_L / 2 - 7, "APROXIME O CARTÃO", ha="center",
            fontsize=7, color="tab:blue")
    ax.text(RFID_X, RFID_Y + RC522_L / 2 - 5, "RC522 por baixo", ha="center",
            fontsize=5, color="0.5")
    ax.text(CAIXA_C / 2, 8, "FRENTE (lado do jogador)", ha="center", fontsize=7,
            color="0.4")


def desenhar_traseira(ax) -> None:
    altura_corpo = CAIXA_A - TAMPA_A
    ax.add_patch(Rectangle((0, 0), CAIXA_C, altura_corpo, fill=False, ls="--",
                           lw=0.6, ec="0.5"))
    x, z = CAIXA_C - RASGO_X, RASGO_Z + RASGO_A / 2
    xs, ys = zip(*_retangulo_arredondado(x, z, RASGO_C, RASGO_A, 6.0))
    ax.fill(xs, ys, fill=False, ec="red", lw=0.8)
    _cruz_mpl(ax, x, z)
    ax.text(x, z + RASGO_A / 2 + 6, "CABOS (USB / fonte)", ha="center", fontsize=7,
            color="tab:blue")
    ax.text(CAIXA_C / 2, 5, "FUNDO — parede traseira vista de fora", ha="center",
            fontsize=7, color="0.4")


def _cruz_mpl(ax, x, y, t=4.0):
    ax.plot([x - t, x + t], [y, y], color="green", lw=0.5)
    ax.plot([x, x], [y - t, y + t], color="green", lw=0.5)


def pdf_a4_1para1(caminho: Path, largura: float, altura: float, desenhar,
                  titulo: str) -> int:
    """Divide o desenho em folhas A4 paisagem, escala 1:1, com sobreposição
    de 10 mm e régua de 100 mm em cada folha para conferir a impressão."""
    folha_w, folha_h, margem, sobrepos = 297.0, 210.0, 12.0, 10.0
    util_w, util_h = folha_w - 2 * margem, folha_h - 2 * margem - 10
    passo_x, passo_y = util_w - sobrepos, util_h - sobrepos
    nx = max(1, math.ceil((largura - sobrepos) / passo_x))
    ny = max(1, math.ceil((altura - sobrepos) / passo_y))
    with PdfPages(caminho) as pdf:
        for j in range(ny):
            for i in range(nx):
                fig = plt.figure(figsize=(folha_w / 25.4, folha_h / 25.4))
                ax = fig.add_axes([margem / folha_w, (margem + 10) / folha_h,
                                   util_w / folha_w, util_h / folha_h])
                x0, y0 = i * passo_x, j * passo_y
                ax.set_xlim(x0, x0 + util_w)
                ax.set_ylim(y0, y0 + util_h)
                ax.set_aspect("equal")
                ax.axis("off")
                desenhar(ax)
                ax.add_patch(Rectangle((x0, y0), util_w, util_h, fill=False,
                                       lw=0.3, ec="0.7"))
                fig.text(margem / folha_w, 4 / folha_h,
                         f"{titulo} — folha {j * nx + i + 1}/{nx * ny} "
                         f"(coluna {i + 1}, linha {j + 1}). Imprimir em TAMANHO "
                         "REAL (100%). Sobrepor 10 mm entre folhas.", fontsize=6)
                rx = 1 - (margem + 100) / folha_w
                fig.add_artist(Rectangle((rx, 9 / folha_h), 100 / folha_w,
                                         1.5 / folha_h, transform=fig.transFigure,
                                         color="black"))
                fig.text(rx, 11.5 / folha_h, "régua: deve medir 100 mm",
                         fontsize=6)
                pdf.savefig(fig)
                plt.close(fig)
    return nx * ny


def previa(caminho: Path) -> None:
    fig, ax = plt.subplots(figsize=(10, 10 * CAIXA_L / CAIXA_C))
    desenhar_tampa(ax)
    ax.set_xlim(-5, CAIXA_C + 5)
    ax.set_ylim(-5, CAIXA_L + 5)
    ax.set_aspect("equal")
    ax.set_title("Tampa vista de cima (mm)")
    ax.grid(True, lw=0.3, alpha=0.4)
    fig.savefig(caminho, dpi=150, bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# Modelo 3D
# ---------------------------------------------------------------------------


def modelo_3d():
    import cadquery as cq

    altura_corpo = CAIXA_A - TAMPA_A
    corpo = (cq.Workplane("XY").box(CAIXA_C, CAIXA_L, altura_corpo, centered=False)
             .faces(">Z").shell(-MDF))
    rasgo = (cq.Workplane("XY").box(RASGO_C, MDF * 3, RASGO_A)
             .translate((RASGO_X, CAIXA_L - MDF / 2, RASGO_Z + RASGO_A / 2)))
    corpo = corpo.cut(rasgo)

    tampa = (cq.Workplane("XY").box(CAIXA_C, CAIXA_L, TAMPA_A, centered=False)
             .faces("<Z").shell(-MDF).translate((0, 0, altura_corpo)))
    for b in BOTOES:
        furo = (cq.Workplane("XY", origin=(b.x, b.y, CAIXA_A - MDF * 2))
                .circle(FURO_BOTAO / 2).extrude(MDF * 3))
        tampa = tampa.cut(furo)

    face_inf_tampa = CAIXA_A - MDF
    placa_z = face_inf_tampa - espacador_botoes()
    corpo_alt = 3.5  # altura do corpo do botão táctil
    botoes = None
    for b in BOTOES:
        corpo_b = (cq.Workplane("XY", origin=(b.x, b.y, placa_z))
                   .rect(BOTAO_CORPO, BOTAO_CORPO).extrude(corpo_alt))
        capa = (cq.Workplane("XY", origin=(b.x, b.y, placa_z + corpo_alt))
                .circle(CAPA_DIAM / 2).extrude(ALTURA_BOTAO_CAPA - corpo_alt))
        peca = corpo_b.union(capa)
        botoes = peca if botoes is None else botoes.union(peca)

    rc522 = (cq.Workplane("XY", origin=(RFID_X, RFID_Y, face_inf_tampa - 4))
             .rect(RC522_C, RC522_L).extrude(1.6))
    fpga = (cq.Workplane("XY", origin=(CAIXA_C / 2 - 40, CAIXA_L - MDF - 20 - FPGA_L / 2,
                                       MDF + ESPACADOR))
            .rect(FPGA_C, FPGA_L).extrude(1.6))
    esp = (cq.Workplane("XY", origin=(CAIXA_C / 2 + 80, CAIXA_L - MDF - 20 - ESP_L / 2,
                                      MDF + ESPACADOR))
           .rect(ESP_C, ESP_L).extrude(1.6))

    montagem = (cq.Assembly(name="caixa_aef")
                .add(corpo, name="corpo", color=cq.Color(0.80, 0.65, 0.45))
                .add(tampa, name="tampa", color=cq.Color(0.85, 0.70, 0.50))
                .add(botoes, name="botoes", color=cq.Color(0.15, 0.15, 0.15))
                .add(rc522, name="rc522", color=cq.Color(0.10, 0.30, 0.80))
                .add(fpga, name="de0_cv", color=cq.Color(0.10, 0.45, 0.20))
                .add(esp, name="esp32", color=cq.Color(0.10, 0.10, 0.10)))
    return montagem


# ---------------------------------------------------------------------------


def main() -> None:
    validar()
    SAIDA.mkdir(exist_ok=True)
    dxf_tampa(SAIDA / "gabarito_tampa.dxf")
    dxf_traseira(SAIDA / "gabarito_traseira.dxf")
    n1 = pdf_a4_1para1(SAIDA / "gabarito_tampa.pdf", CAIXA_C, CAIXA_L,
                       desenhar_tampa, "Gabarito da TAMPA")
    n2 = pdf_a4_1para1(SAIDA / "gabarito_traseira.pdf", CAIXA_C, CAIXA_A - TAMPA_A,
                       desenhar_traseira, "Gabarito da TRASEIRA")
    previa(SAIDA / "previa_tampa.png")

    import cadquery as cq
    montagem = modelo_3d()
    montagem.export(str(SAIDA / "caixa.step"))
    cq.exporters.export(montagem.toCompound(), str(SAIDA / "caixa.stl"))
    montagem.export(str(SAIDA / "caixa.glb"))  # visualizador web (cores por peça)

    print(f"Espaçador da placa dos botões: {espacador_botoes():.1f} mm")
    print(f"PDF tampa: {n1} folhas A4; PDF traseira: {n2} folhas A4")
    print("Arquivos em", SAIDA)


if __name__ == "__main__":
    main()
