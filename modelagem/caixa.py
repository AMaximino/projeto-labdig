"""Modelo paramétrico da caixa do jogo Aventura Financeira Evolution.

A caixa é toda de MDF cortado a laser, com encaixes de dedo (finger joints):
um corpo aberto em cima (fundo + 4 paredes) e uma tampa que encaixa por fora
(topo + 4 abas). Na tampa ficam só os controles do jogador; tudo o que o
painel web já mostra (rodada, jogada, saldo, itens, fim de jogo) não tem
display nem LED na caixa.

Gera, em modelagem/saida/:
  laser/chapa_N.dxf / .svg   arquivos de corte, um por chapa (AutoCAD, LightBurn,
                             RDWorks, Inkscape). CORTE = vermelho, GRAVACAO = azul
  laser/todas_as_chapas.dxf  todas as chapas lado a lado, só para conferir
  laser/mapa_chapas.png      mapa com o nome de cada peça
  laser/pecas.csv            lista das peças de MDF e em qual chapa está cada uma
  arte_adesivos.pdf          adesivos coloridos em tamanho real (papel couchê)
  previa_colorida.png        como a tampa fica pronta (vista de cima)
  previa_tampa.png           desenho técnico da tampa: furos e contornos gravados
  lista_componentes.csv      cada componente: posição, furo, cor, sinal e pino
  caixa.step / caixa.stl     modelo 3D montado (Fusion 360: File → Open)
  caixa.glb, textura_*.png,  modelo com cores e arte para o visualizador web
  visualizador.json

Uso, na raiz do repositório:
    modelagem/.venv/bin/python modelagem/caixa.py

Coordenadas da tampa (vista de cima, jogador na frente): origem no canto
frontal esquerdo, X para a direita (415 mm), Y para o fundo (315 mm), em mm.
"""

from __future__ import annotations

import csv
import json
import math
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

import ezdxf
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.backends.backend_pdf import PdfPages  # noqa: E402
from matplotlib.font_manager import FontProperties  # noqa: E402
from matplotlib.patches import Circle, FancyBboxPatch, PathPatch, Polygon, Rectangle  # noqa: E402
from matplotlib.textpath import TextPath  # noqa: E402
from matplotlib.transforms import Affine2D  # noqa: E402

AQUI = Path(__file__).resolve().parent
SAIDA = AQUI / "saida"
LASER = SAIDA / "laser"
ICONES = AQUI / "arte" / "png"
LOGO_ARQ = AQUI.parent / "front" / "images" / "logo.jpe"

# ---------------------------------------------------------------------------
# Parâmetros. [ASSUMIDO] precisa ser conferido antes de cortar.
# ---------------------------------------------------------------------------

# Medidas externas com a tampa fechada
CAIXA_C = 415.0          # comprimento (X)
CAIXA_L = 315.0          # largura (Y)
CAIXA_A = 205.0          # altura total
TAMPA_A = 40.0           # altura da tampa (topo + aba)

MDF = 3.0                # espessura da chapa [ASSUMIDO: medir com paquímetro]
KERF = 0.15              # largura do corte do laser [ASSUMIDO: cortar a peça de teste]
FOLGA_TAMPA = 0.5        # folga de cada lado entre a aba da tampa e o corpo
DEDO = 18.0              # largura aproximada de cada dedo do encaixe

# Área útil da cortadora / tamanho da chapa [ASSUMIDO: perguntar no laboratório]
CHAPA_C, CHAPA_L = 600.0, 400.0
MARGEM_CHAPA = 5.0       # distância das peças à borda da chapa
ESPACO_PECAS = 4.0       # distância entre peças

# Corpo: fica dentro da aba da tampa
CORPO_C = CAIXA_C - 2 * (MDF + FOLGA_TAMPA)
CORPO_L = CAIXA_L - 2 * (MDF + FOLGA_TAMPA)
CORPO_A = CAIXA_A - MDF                    # a tampa apoia no topo das paredes
CORPO_X0 = CORPO_Y0 = MDF + FOLGA_TAMPA    # posição do corpo sob a tampa

# Botão táctil 12×12 com capa
BOTAO_CORPO = 12.0
CAPA_DIAM = 12.0         # [ASSUMIDO: medir a capa do kit]
FURO_BOTAO = 13.0        # capa + 1 mm de folga
ALTURA_BOTAO_CAPA = 13.0 # da placa até o topo da capa [ASSUMIDO]
SOBRESSAI = 2.0          # quanto a capa sai acima da tampa

# Chave rotativa de 10+ posições (seletor de item)
FURO_SELETOR = 10.0      # bucha de 3/8" (9,5 mm) + folga [ASSUMIDO: medir a rosca]
KNOB_DIAM, KNOB_A = 24.0, 14.0

# RC522 e cartão
RC522_C, RC522_L = 60.0, 40.0
CARTAO_C, CARTAO_L = 85.6, 54.0   # cartão ISO/IEC 7810 ID-1

# Placas internas
FPGA_C, FPGA_L = 128.0, 99.0      # Terasic DE0-CV (conferir)
ESP_C, ESP_L = 55.0, 28.0         # ESP32 DevKit
ESPACADOR = 10.0                  # espaçadores da FPGA no fundo

# Rasgo para os cabos USB na parede traseira (coordenadas da parede)
RASGO_C, RASGO_A, RASGO_R = 50.0, 25.0, 6.0
RASGO_X = CORPO_C / 2
RASGO_Z = 20.0                    # do chão até a borda de baixo do rasgo

# Adesivo do logotipo na frente do corpo
LOGO_FRENTE = 130.0               # lado do adesivo quadrado
LOGO_Z = 15.0                     # do chão até a base do adesivo

MARGEM_MIN = 30.0                 # distância mínima dos furos à borda da tampa
FOLGA_FUROS = 4.0                 # madeira mínima entre dois furos

# ---------------------------------------------------------------------------
# Paleta (tons pastel nas áreas grandes; verdes e dourado do painel web)
# ---------------------------------------------------------------------------

COR = {
    "madeira": "#E3C9A0",
    "madeira_escura": "#D2B385",
    "aba": "#CFE7D9",            # aba da tampa pintada de verde-menta
    "tinta": "#24343A",
    "verde_painel": "#2E7161",
    "verde_escuro": "#1D4E43",
    "dourado": "#BC8A33",
}

# Cores das capas: as mesmas da pinagem da Semana 3
CAPA = {
    "azul": "#2F6DB5", "branco": "#F4F4F0", "preto": "#2A2A2A",
    "vermelho": "#C9433A", "amarelo": "#F1C232", "verde": "#3E9A52",
}


@dataclass(frozen=True)
class Zona:
    """Adesivo de papel couchê colado sobre a tampa."""
    chave: str
    titulo: str
    x0: float
    y0: float
    c: float
    l: float
    fundo: str
    borda: str

    @property
    def cx(self) -> float:
        return self.x0 + self.c / 2

    @property
    def cy(self) -> float:
        return self.y0 + self.l / 2


ZONAS = {z.chave: z for z in [
    Zona("seletor", "Escolha o item", 22, 22, 150, 146, "#ECE5F6", "#6F5AA8"),
    Zona("cartao", "Pague com o cartão", 182, 22, 110, 146, "#F3EEFA", "#6F5AA8"),
    Zona("partida", "Partida", 302, 22, 91, 146, "#F7EFDF", "#B08A4A"),
    Zona("logo", "Logotipo", 22, 180.5, 110, 110, "#FFFFFF", COR["verde_painel"]),
    Zona("acao_1", "Trabalho e estudo", 147, 178, 78, 115, "#DCEAF7", "#4F86C0"),
    Zona("acao_2", "Investimentos", 231, 178, 78, 115, "#DCF0E2", "#3F9258"),
    Zona("acao_3", "Compras", 315, 178, 78, 115, "#FCE3D3", "#C7684F"),
]}


# ---------------------------------------------------------------------------
# Componentes da tampa
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Botao:
    nome: str
    x: float
    y: float
    capa: str
    icone: str
    sinal: str
    pino: str
    conector: str
    zona: str


@dataclass(frozen=True)
class Item:
    numero: int
    nome: str
    icone: str


ITENS = [
    Item(1, "CARRO COMPACTO", "item-01"), Item(2, "CARRO FAMILIAR", "item-02"),
    Item(3, "CARRO PREMIUM", "item-03"), Item(4, "CASA PEQUENA", "item-04"),
    Item(5, "CASA CONFORTÁVEL", "item-05"), Item(6, "CASA DOS SONHOS", "item-06"),
    Item(7, "COMPUTADOR", "item-07"), Item(8, "JOGOS", "item-08"),
    Item(9, "LIVROS", "item-09"), Item(10, "LEGO", "item-10"),
]

# Pinos da DE0-CV (fpga/quartus/circuito_jogo_financeiro.qsf). O item k usa o
# bit k-1 de seletor_item.
PINO_SELETOR = ["PIN_J13", "PIN_H14", "PIN_H10", "PIN_J19", "PIN_H18",
                "PIN_G18", "PIN_C13", "PIN_A13", "PIN_H15", "PIN_H16"]
GPIO_SELETOR = [f"GPIO_1_D{18 - 2 * i}" for i in range(10)]

# --- Seletor com as ilustrações dos itens ----------------------------------
SELETOR_X, SELETOR_Y = 97.0, 95.0
SELETOR_PASSO = 30.0               # graus entre posições (chave 1P12T)
SELETOR_RAIO_NUM = 28.0            # círculo dos números
SELETOR_RAIO_ICONE = 47.0          # círculo das ilustrações
ICONE_ITEM = 15.0

# --- Cartão ------------------------------------------------------------------
RFID_X, RFID_Y = 237.0, 92.0
ESP_X, ESP_Y = 237.0, 150.0        # ESP32 sob a tampa, ao lado do RC522

# --- Ações: 3 zonas, 2 botões lado a lado em cada uma ------------------------
ACAO_Y = 228.0
ACAO_DX = 19.0
PARTIDA_X, PARTIDA_ICONE_X = 359.5, 325.5
INICIAR_Y, RESET_Y = 120.0, 60.0


def _acao_x(zona: str, lado: int) -> float:
    return ZONAS[zona].cx + lado * ACAO_DX


BOTOES = [
    Botao("TRABALHAR", _acao_x("acao_1", -1), ACAO_Y, "azul", "trabalhar", "trabalhar",
          "PIN_K16", "GPIO_1_D35", "acao_1"),
    Botao("ESTUDAR", _acao_x("acao_1", 1), ACAO_Y, "branco", "estudar", "estudar",
          "PIN_G12", "GPIO_1_D33", "acao_1"),
    Botao("INVESTIR", _acao_x("acao_2", -1), ACAO_Y, "preto", "investir", "investir",
          "PIN_G15", "GPIO_1_D31", "acao_2"),
    Botao("RESGATAR", _acao_x("acao_2", 1), ACAO_Y, "vermelho", "resgatar", "resgatar",
          "PIN_F12", "GPIO_1_D29", "acao_2"),
    Botao("COMPRAR", _acao_x("acao_3", -1), ACAO_Y, "verde", "comprar", "comprar",
          "PIN_E16", "GPIO_1_D25", "acao_3"),
    Botao("VENDER", _acao_x("acao_3", 1), ACAO_Y, "amarelo", "vender", "vender",
          "PIN_F15", "GPIO_1_D27", "acao_3"),
    Botao("INICIAR", PARTIDA_X, INICIAR_Y, "verde", "iniciar", "iniciar",
          "PIN_E14", "GPIO_1_D23", "partida"),
    Botao("RESET", PARTIDA_X, RESET_Y, "vermelho", "reset", "reset",
          "PIN_B15", "GPIO_1_D21", "partida"),
]

# O que saiu da caixa porque o painel web já mostra (os sinais continuam na
# FPGA; só não são ligados a nada).
FORA_DA_CAIXA = [
    ("10 LEDs 'meus itens'", "indicador_itens[9:0]", "inventário no painel web"),
    ("display RODADA", "display_rodadas", "rodada no painel web"),
    ("display JOGADA", "display_jogadas", "jogada no painel web"),
    ("LEDs ÚLTIMA RODADA/JOGADA", "ultima_rodada, ultima_jogada", "rodada/jogada no painel"),
    ("LEDs FIM DO JOGO / FALIU", "terminou, perdeu", "tela de fim de jogo no painel"),
    ("6 botões de consulta", "config_display[5:0]", "saldo, salário, investido, "
     "rendimento e gastos no painel"),
]


# ---------------------------------------------------------------------------
# Geometria 2D: furos, contornos com dedos e compensação do kerf
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Recorte:
    """Furo cortado numa peça: círculo (d) ou retângulo arredondado (c × l, r)."""
    nome: str
    x: float
    y: float
    d: float = 0.0
    c: float = 0.0
    l: float = 0.0
    r: float = 0.0
    zona: str = ""

    @property
    def redondo(self) -> bool:
        return self.d > 0

    def caixa(self) -> tuple[float, float, float, float]:
        if self.redondo:
            r = self.d / 2
            return self.x - r, self.y - r, self.x + r, self.y + r
        return (self.x - self.c / 2, self.y - self.l / 2,
                self.x + self.c / 2, self.y + self.l / 2)

    def pontos(self, kerf: float = 0.0) -> list[tuple[float, float]]:
        k = kerf / 2
        return _retangulo_arredondado(self.x, self.y, self.c - 2 * k, self.l - 2 * k,
                                      max(self.r - k, 0.05))

    def girado(self, l_peca: float) -> "Recorte":
        """Mesmo furo depois de girar a peça 90° (ver Peca.girar)."""
        return Recorte(self.nome, l_peca - self.y, self.x, self.d, self.l, self.c, self.r,
                       self.zona)


def _retangulo_arredondado(cx, cy, c, l, r, n=8):
    """Pontos no sentido anti-horário."""
    pts = []
    cantos = [(cx + c / 2 - r, cy - l / 2 + r, -90), (cx + c / 2 - r, cy + l / 2 - r, 0),
              (cx - c / 2 + r, cy + l / 2 - r, 90), (cx - c / 2 + r, cy - l / 2 + r, 180)]
    for ox, oy, a0 in cantos:
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((ox + r * math.cos(a), oy + r * math.sin(a)))
    return pts


def _n_dedos(comprimento: float) -> int:
    """Número ímpar de segmentos: o padrão fica simétrico nas duas pontas."""
    n = int(comprimento // DEDO)
    if n % 2 == 0:
        n -= 1
    return max(n, 3)


def _segmentos(comprimento: float, tipo: str):
    """Segmentos (início, fim, saliente) de uma borda.

    A: dedos nos segmentos ímpares (pontas recuadas)
    B: dedos nos segmentos pares (pontas salientes), complemento de A
    L: borda lisa, sem encaixe
    """
    if tipo == "L":
        return [(0.0, comprimento, True)]
    n = _n_dedos(comprimento)
    w = comprimento / n
    return [(i * w, (i + 1) * w, (i % 2 == 1) if tipo == "A" else (i % 2 == 0))
            for i in range(n)]


def _ponta_saliente(tipo: str) -> bool:
    return tipo in ("B", "L")


def _limpar(pts):
    """Remove pontos repetidos e colineares (o offset precisa disso)."""
    unicos = []
    for p in pts:
        if not unicos or math.dist(unicos[-1], p) > 1e-7:
            unicos.append(p)
    while len(unicos) > 1 and math.dist(unicos[0], unicos[-1]) < 1e-7:
        unicos.pop()
    pts = unicos
    mudou = True
    while mudou and len(pts) > 3:
        mudou = False
        n = len(pts)
        for i in range(n):   # remove um ponto colinear por vez
            a, b, c = pts[i - 1], pts[i], pts[(i + 1) % n]
            cruz = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
            if abs(cruz) < 1e-7:
                pts = pts[:i] + pts[i + 1:]
                mudou = True
                break
    return pts


def contorno_dedos(c: float, l: float, bordas: tuple[str, str, str, str]):
    """Contorno de uma peça c × l com encaixes. `bordas` = (baixo, direita,
    cima, esquerda). Cada borda tem uma faixa de largura MDF onde os dedos
    alternam; o canto MDF × MDF só pertence à peça se as duas bordas que se
    encontram nele têm a ponta saliente. Pontos no sentido anti-horário."""
    cantos = [(0.0, 0.0), (c, 0.0), (c, l), (0.0, l)]
    direcoes = [(1, 0), (0, 1), (-1, 0), (0, -1)]
    normais = [(0, 1), (-1, 0), (0, -1), (1, 0)]   # para dentro da peça
    comprimentos = [c, l, c, l]
    pts = []
    for i in range(4):
        tipo, anterior = bordas[i], bordas[i - 1]
        p, d, n, n_ant = cantos[i], direcoes[i], normais[i], normais[i - 1]
        if _ponta_saliente(anterior) and _ponta_saliente(tipo):
            pts.append(p)
        else:
            pts.append((p[0] + MDF * (n_ant[0] + n[0]), p[1] + MDF * (n_ant[1] + n[1])))
        comp = comprimentos[i]
        for s0, s1, saliente in _segmentos(comp, tipo):
            a, b = max(s0, MDF), min(s1, comp - MDF)
            if b <= a:
                continue
            prof = 0.0 if saliente else MDF
            for s in (a, b):
                pts.append((p[0] + d[0] * s + n[0] * prof, p[1] + d[1] * s + n[1] * prof))
    return _limpar(pts)


def _offset_ortogonal(pts, dist: float):
    """Desloca para fora um polígono só com lados horizontais/verticais
    (anti-horário). Usado para compensar o kerf: a peça sai do tamanho certo."""
    saida = []
    n = len(pts)
    for i in range(n):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
        normais = []
        for a, b in ((p0, p1), (p1, p2)):
            dx, dy = b[0] - a[0], b[1] - a[1]
            comp = math.hypot(dx, dy)
            normais.append((dy / comp, -dx / comp))
        saida.append((p1[0] + dist * (normais[0][0] + normais[1][0]),
                      p1[1] + dist * (normais[0][1] + normais[1][1])))
    return saida


@dataclass
class Peca:
    """Peça de MDF cortada a laser."""
    nome: str
    descricao: str
    c: float
    l: float
    bordas: tuple[str, str, str, str]
    grupo: str                       # corpo, tampa ou teste
    plano: str = "xy"                # orientação no modelo 3D
    destino: tuple[float, float, float] = (0.0, 0.0, 0.0)
    recortes: list[Recorte] = field(default_factory=list)
    gravacoes: list[list[tuple[float, float]]] = field(default_factory=list)

    def contorno(self, kerf: float = 0.0):
        pts = contorno_dedos(self.c, self.l, self.bordas)
        return _offset_ortogonal(pts, kerf / 2) if kerf else pts


def _contorno_gravado(z: Zona) -> list[tuple[float, float]]:
    """Linha gravada 1 mm fora do adesivo: guia para colar no lugar certo."""
    return _retangulo_arredondado(z.cx, z.cy, z.c + 2, z.l + 2, 6.0)


@lru_cache(maxsize=None)
def _furos_tampa() -> tuple[Recorte, ...]:
    lista = [Recorte(b.nome, b.x, b.y, d=FURO_BOTAO, zona=b.zona) for b in BOTOES]
    lista.append(Recorte("SELETOR", SELETOR_X, SELETOR_Y, d=FURO_SELETOR, zona="seletor"))
    return tuple(lista)


def furos() -> list[Recorte]:
    return list(_furos_tampa())


def _furo(nome: str) -> Recorte:
    return next(f for f in _furos_tampa() if f.nome == nome)


def pecas() -> list[Peca]:
    """As 10 peças da caixa e 2 peças de teste do encaixe.

    Corpo: fundo com bordas A; paredes com borda de baixo B; nas quinas
    verticais a frente/trás usa B e as laterais A. A tampa é a mesma
    estrutura de cabeça para baixo: topo A, abas com a borda do topo B.
    """
    frente_logo = _retangulo_arredondado(CORPO_C / 2, LOGO_Z + LOGO_FRENTE / 2,
                                         LOGO_FRENTE + 2, LOGO_FRENTE + 2, 7.0)
    rasgo = Recorte("RASGO CABOS", RASGO_X, RASGO_Z + RASGO_A / 2, c=RASGO_C, l=RASGO_A,
                    r=RASGO_R)
    zt = CAIXA_A - TAMPA_A
    lista = [
        Peca("tampa_topo", "Tampa: topo (furos dos botões e do seletor)", CAIXA_C, CAIXA_L,
             ("A", "A", "A", "A"), "tampa", "xy", (0, 0, CAIXA_A - MDF),
             recortes=furos(), gravacoes=[_contorno_gravado(z) for z in ZONAS.values()]),
        Peca("tampa_aba_frente", "Tampa: aba da frente", CAIXA_C, TAMPA_A,
             ("B", "B", "L", "B"), "tampa", "xz_baixo", (0, 0, zt)),
        Peca("tampa_aba_tras", "Tampa: aba de trás", CAIXA_C, TAMPA_A,
             ("B", "B", "L", "B"), "tampa", "xz_baixo", (0, CAIXA_L - MDF, zt)),
        Peca("tampa_aba_esq", "Tampa: aba esquerda", CAIXA_L, TAMPA_A,
             ("B", "A", "L", "A"), "tampa", "yz_baixo", (0, 0, zt)),
        Peca("tampa_aba_dir", "Tampa: aba direita", CAIXA_L, TAMPA_A,
             ("B", "A", "L", "A"), "tampa", "yz_baixo", (CAIXA_C - MDF, 0, zt)),
        Peca("corpo_fundo", "Corpo: fundo", CORPO_C, CORPO_L, ("A", "A", "A", "A"),
             "corpo", "xy", (CORPO_X0, CORPO_Y0, 0)),
        Peca("corpo_frente", "Corpo: frente (contorno do logotipo gravado)", CORPO_C,
             CORPO_A, ("B", "B", "L", "B"), "corpo", "xz", (CORPO_X0, CORPO_Y0, 0),
             gravacoes=[frente_logo]),
        Peca("corpo_tras", "Corpo: traseira (rasgo dos cabos)", CORPO_C, CORPO_A,
             ("B", "B", "L", "B"), "corpo", "xz", (CORPO_X0, CORPO_Y0 + CORPO_L - MDF, 0),
             recortes=[rasgo]),
        Peca("corpo_lat_esq", "Corpo: lateral esquerda", CORPO_L, CORPO_A,
             ("B", "A", "L", "A"), "corpo", "yz", (CORPO_X0, CORPO_Y0, 0)),
        Peca("corpo_lat_dir", "Corpo: lateral direita", CORPO_L, CORPO_A,
             ("B", "A", "L", "A"), "corpo", "yz", (CORPO_X0 + CORPO_C - MDF, CORPO_Y0, 0)),
        # Peças de teste: cortar primeiro e conferir encaixe e furos
        Peca("teste_a", "Teste: encaixe macho + furos do botão e do seletor", 60, 40,
             ("L", "L", "B", "L"), "teste",
             recortes=[Recorte("teste botão", 17, 18, d=FURO_BOTAO),
                       Recorte("teste seletor", 43, 18, d=FURO_SELETOR)]),
        Peca("teste_b", "Teste: encaixe fêmea", 60, 30, ("A", "L", "L", "L"), "teste"),
    ]
    return lista


def angulo_seletor(pos: int) -> float:
    """Ângulo (graus, anti-horário a partir de +X) da posição 1..10. A posição
    1 fica embaixo à esquerda e as demais seguem no sentido horário."""
    return 225.0 - SELETOR_PASSO * (pos - 1)


def _pos_icone(pos: int) -> tuple[float, float]:
    a = math.radians(angulo_seletor(pos))
    return (SELETOR_X + SELETOR_RAIO_ICONE * math.cos(a),
            SELETOR_Y + SELETOR_RAIO_ICONE * math.sin(a))


def espacador_botoes() -> float:
    """Distância entre a face de baixo da tampa e a placa dos botões."""
    return ALTURA_BOTAO_CAPA - MDF - SOBRESSAI


# ---------------------------------------------------------------------------
# Validação
# ---------------------------------------------------------------------------


def _distancia(a: Recorte, b: Recorte) -> float:
    return math.dist((a.x, a.y), (b.x, b.y)) - (a.d + b.d) / 2


def validar() -> None:
    lista = furos()
    for f in lista:
        x0, y0, x1, y1 = f.caixa()
        assert MARGEM_MIN <= x0 and x1 <= CAIXA_C - MARGEM_MIN, f"margem X: {f.nome}"
        assert MARGEM_MIN <= y0 and y1 <= CAIXA_L - MARGEM_MIN, f"margem Y: {f.nome}"
        z = ZONAS[f.zona]
        assert z.x0 + 2 <= x0 and x1 <= z.x0 + z.c - 2, f"fora do adesivo: {f.nome}"
        assert z.y0 + 2 <= y0 and y1 <= z.y0 + z.l - 2, f"fora do adesivo: {f.nome}"
    for i, a in enumerate(lista):
        for b in lista[i + 1:]:
            assert _distancia(a, b) >= FOLGA_FUROS, f"furos próximos: {a.nome} / {b.nome}"
    for i, a in enumerate(BOTOES):
        for b in BOTOES[i + 1:]:
            assert math.dist((a.x, a.y), (b.x, b.y)) >= 2 * FURO_BOTAO, (a.nome, b.nome)
    zs = list(ZONAS.values())
    for i, a in enumerate(zs):
        # o adesivo não pode cobrir a faixa dos encaixes na borda da tampa
        assert MDF + 5 <= a.x0 and a.x0 + a.c <= CAIXA_C - MDF - 5, f"borda: {a.chave}"
        assert MDF + 5 <= a.y0 and a.y0 + a.l <= CAIXA_L - MDF - 5, f"borda: {a.chave}"
        for b in zs[i + 1:]:
            sobrepoe = (a.x0 - 3 < b.x0 + b.c and b.x0 - 3 < a.x0 + a.c and
                        a.y0 - 3 < b.y0 + b.l and b.y0 - 3 < a.y0 + a.l)
            assert not sobrepoe, f"adesivos encostados: {a.chave} / {b.chave}"
    sel = ZONAS["seletor"]
    for pos in range(1, 11):
        x, y = _pos_icone(pos)
        r = ICONE_ITEM / 2 + 1.5
        assert sel.x0 + 2 <= x - r and x + r <= sel.x0 + sel.c - 2, f"ícone {pos} (X)"
        assert sel.y0 + 2 <= y - r and y + r <= sel.y0 + sel.l - 14, f"ícone {pos} (Y)"
    car = ZONAS["cartao"]
    assert car.x0 + 3 <= RFID_X - CARTAO_C / 2 and RFID_X + CARTAO_C / 2 <= car.x0 + car.c - 3
    # Metal do seletor e da ESP32 longe da antena do RC522 (≥ 20 mm)
    assert RFID_X - RC522_C / 2 - (SELETOR_X + 14) >= 20
    assert ESP_Y - ESP_L / 2 - (RFID_Y + RC522_L / 2) >= 20
    assert espacador_botoes() > 0, "capa não alcança a tampa"
    # Rasgo longe dos encaixes da parede traseira
    assert RASGO_Z >= MDF + 5 and RASGO_Z + RASGO_A <= CORPO_A - TAMPA_A - 5
    # Logotipo da frente fica abaixo da aba da tampa
    assert LOGO_Z >= MDF + 5 and LOGO_Z + LOGO_FRENTE <= CORPO_A - (TAMPA_A - MDF) - 5
    for p in pecas():
        for rec in p.recortes:
            x0, y0, x1, y1 = rec.caixa()
            assert MDF + 3 <= x0 and x1 <= p.c - MDF - 3, f"furo na borda: {p.nome}"
            assert MDF + 3 <= y0 and y1 <= p.l - MDF - 3, f"furo na borda: {p.nome}"


# ---------------------------------------------------------------------------
# Distribuição das peças nas chapas (guilhotina, com rotação de 90°)
# ---------------------------------------------------------------------------


@dataclass
class Colocada:
    peca: Peca
    girada: bool
    x: float
    y: float

    def _transformar(self, pts):
        """Coordenadas da peça → coordenadas da chapa."""
        if self.girada:
            pts = [(self.peca.l - v, u) for u, v in pts]
        return [(self.x + u, self.y + v) for u, v in pts]

    def contorno(self, kerf=KERF):
        return self._transformar(self.peca.contorno(kerf))

    def recortes(self):
        lista = self.peca.recortes
        if self.girada:
            lista = [r.girado(self.peca.l) for r in lista]
        return [Recorte(r.nome, self.x + r.x, self.y + r.y, r.d, r.c, r.l, r.r) for r in lista]

    def gravacoes(self):
        return [self._transformar(g) for g in self.peca.gravacoes]

    @property
    def tamanho(self) -> tuple[float, float]:
        return (self.peca.l, self.peca.c) if self.girada else (self.peca.c, self.peca.l)


def distribuir(lista: list[Peca]) -> list[list[Colocada]]:
    folga = ESPACO_PECAS + KERF
    util_c = CHAPA_C - 2 * MARGEM_CHAPA + ESPACO_PECAS
    util_l = CHAPA_L - 2 * MARGEM_CHAPA + ESPACO_PECAS
    chapas: list[dict] = []

    def tentar(chapa, p) -> bool:
        melhor = None
        for i, (fx, fy, fw, fh) in enumerate(chapa["livres"]):
            for girada in (False, True):
                w = (p.l if girada else p.c) + folga
                h = (p.c if girada else p.l) + folga
                if w <= fw + 1e-6 and h <= fh + 1e-6:
                    sobra = fw * fh - w * h
                    if melhor is None or sobra < melhor[0]:
                        melhor = (sobra, i, girada, w, h)
        if melhor is None:
            return False
        _, i, girada, w, h = melhor
        fx, fy, fw, fh = chapa["livres"].pop(i)
        if fw - w < fh - h:
            novos = [(fx + w, fy, fw - w, h), (fx, fy + h, fw, fh - h)]
        else:
            novos = [(fx + w, fy, fw - w, fh), (fx, fy + h, w, fh - h)]
        chapa["livres"] += [r for r in novos if r[2] > 1 and r[3] > 1]
        chapa["itens"].append(Colocada(p, girada, fx + KERF / 2, fy + KERF / 2))
        return True

    for p in sorted(lista, key=lambda p: (max(p.c, p.l), p.c * p.l), reverse=True):
        if not any(tentar(ch, p) for ch in chapas):
            chapa = {"livres": [(MARGEM_CHAPA, MARGEM_CHAPA, util_c, util_l)], "itens": []}
            chapas.append(chapa)
            if not tentar(chapa, p):
                raise SystemExit(f"A peça {p.nome} ({p.c:g} × {p.l:g} mm) não cabe na chapa "
                                 f"{CHAPA_C:g} × {CHAPA_L:g} mm. Ajuste CHAPA_C/CHAPA_L.")
    return [ch["itens"] for ch in chapas]


# ---------------------------------------------------------------------------
# Arquivos de corte: DXF (AutoCAD/LightBurn) e SVG (Inkscape/LightBurn)
# ---------------------------------------------------------------------------

CAMADAS = {"CORTE": 1, "GRAVACAO": 5, "REFERENCIA": 8}   # vermelho, azul, cinza


def novo_dxf():
    doc = ezdxf.new("R2010", setup=True)
    doc.units = ezdxf.units.MM
    for nome, cor in CAMADAS.items():
        doc.layers.add(nome, color=cor)
    return doc, doc.modelspace()


def _dxf_itens(msp, itens: list[Colocada], dx=0.0, dy=0.0) -> None:
    """Ordem pensada para o laser: gravações, depois furos, depois contornos
    (as peças só se soltam da chapa no fim)."""
    mover = lambda pts: [(x + dx, y + dy) for x, y in pts]  # noqa: E731
    for it in itens:
        for g in it.gravacoes():
            msp.add_lwpolyline(mover(g), close=True, dxfattribs={"layer": "GRAVACAO"})
    for it in itens:
        for r in it.recortes():
            if r.redondo:
                msp.add_circle((r.x + dx, r.y + dy), r.d / 2 - KERF / 2,
                               dxfattribs={"layer": "CORTE"})
            else:
                msp.add_lwpolyline(mover(r.pontos(KERF)), close=True,
                                   dxfattribs={"layer": "CORTE"})
    for it in itens:
        msp.add_lwpolyline(mover(it.contorno()), close=True, dxfattribs={"layer": "CORTE"})


def dxf_chapa(caminho: Path, itens: list[Colocada]) -> None:
    doc, msp = novo_dxf()
    _dxf_itens(msp, itens)
    doc.saveas(caminho)


def dxf_todas(caminho: Path, chapas: list[list[Colocada]]) -> None:
    """Todas as chapas lado a lado, com o limite da chapa e o nome de cada
    peça na camada REFERENCIA (só para conferir; não mandar para o laser)."""
    doc, msp = novo_dxf()
    for n, itens in enumerate(chapas):
        dx = n * (CHAPA_C + 40)
        msp.add_lwpolyline([(dx, 0), (dx + CHAPA_C, 0), (dx + CHAPA_C, CHAPA_L),
                            (dx, CHAPA_L)], close=True, dxfattribs={"layer": "REFERENCIA"})
        msp.add_text(f"CHAPA {n + 1}", height=12, dxfattribs={"layer": "REFERENCIA"}) \
            .set_placement((dx, CHAPA_L + 8))
        _dxf_itens(msp, itens, dx, 0)
        for it in itens:
            w, h = it.tamanho
            msp.add_text(it.peca.nome, height=6, dxfattribs={"layer": "REFERENCIA"}) \
                .set_placement((dx + it.x + w / 2, it.y + h / 2),
                               align=ezdxf.enums.TextEntityAlignment.MIDDLE_CENTER)
    doc.saveas(caminho)


def svg_chapa(caminho: Path, itens: list[Colocada]) -> None:
    """SVG em milímetros (1 unidade = 1 mm), traço fino: vermelho corta,
    azul grava."""
    def caminho_svg(pts):
        s = " ".join(f"{x:.3f},{CHAPA_L - y:.3f}" for x, y in pts)
        return f"M {s} Z"

    linhas = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{CHAPA_C:g}mm" '
        f'height="{CHAPA_L:g}mm" viewBox="0 0 {CHAPA_C:g} {CHAPA_L:g}">',
        '<g id="GRAVACAO" fill="none" stroke="#0000FF" stroke-width="0.1">',
    ]
    for it in itens:
        for g in it.gravacoes():
            linhas.append(f'<path d="{caminho_svg(g)}"/>')
    linhas += ['</g>', '<g id="CORTE" fill="none" stroke="#FF0000" stroke-width="0.1">']
    for it in itens:
        for r in it.recortes():
            if r.redondo:
                linhas.append(f'<circle cx="{r.x:.3f}" cy="{CHAPA_L - r.y:.3f}" '
                              f'r="{r.d / 2 - KERF / 2:.3f}"/>')
            else:
                linhas.append(f'<path d="{caminho_svg(r.pontos(KERF))}"/>')
    for it in itens:
        linhas.append(f'<path d="{caminho_svg(it.contorno())}"/>')
    linhas += ['</g>', '</svg>']
    caminho.write_text("\n".join(linhas), encoding="utf-8")


def mapa_chapas(caminho: Path, chapas: list[list[Colocada]]) -> None:
    n = len(chapas)
    colunas = min(n, 3)
    linhas_fig = math.ceil(n / colunas)
    fig, eixos = plt.subplots(linhas_fig, colunas,
                              figsize=(6.2 * colunas, 6.2 * linhas_fig * CHAPA_L / CHAPA_C + 0.6),
                              squeeze=False)
    for k, ax in enumerate(eixos.flat):
        ax.set_axis_off()
        if k >= n:
            continue
        ax.add_patch(Rectangle((0, 0), CHAPA_C, CHAPA_L, fc="#F3E6CF", ec="0.4", lw=0.8))
        for it in chapas[k]:
            ax.add_patch(Polygon(it.contorno(), closed=True, fc="#E3C9A0", ec="#D0021B",
                                 lw=0.5))
            for r in it.recortes():
                if r.redondo:
                    ax.add_patch(Circle((r.x, r.y), r.d / 2, fc="#F3E6CF", ec="#D0021B",
                                        lw=0.5))
                else:
                    ax.add_patch(Polygon(r.pontos(), closed=True, fc="#F3E6CF",
                                         ec="#D0021B", lw=0.5))
            for g in it.gravacoes():
                ax.add_patch(Polygon(g, closed=True, fill=False, ec="#1F4FD8", lw=0.4))
            w, h = it.tamanho
            ax.text(it.x + w / 2, it.y + h / 2, it.peca.nome.replace("_", " "),
                    ha="center", va="center", fontsize=7 if min(w, h) > 45 else 5.5,
                    rotation=90 if h > w * 2 else 0, color="#222", weight="bold")
        ax.set_xlim(-5, CHAPA_C + 5)
        ax.set_ylim(-5, CHAPA_L + 5)
        ax.set_aspect("equal")
        ax.set_title(f"Chapa {k + 1}  ({CHAPA_C:g} × {CHAPA_L:g} mm)", fontsize=10)
    fig.suptitle(f"MDF {MDF:g} mm — vermelho: cortar · azul: gravar (linha fraca) · "
                 f"kerf compensado: {KERF:g} mm", fontsize=11)
    fig.tight_layout()
    fig.savefig(caminho, dpi=140)
    plt.close(fig)


def lista_pecas(caminho: Path, chapas: list[list[Colocada]]) -> None:
    with open(caminho, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["peca", "descricao", "comprimento_mm", "largura_mm", "espessura_mm",
                    "chapa", "girada_90"])
        for n, itens in enumerate(chapas, start=1):
            for it in itens:
                p = it.peca
                w.writerow([p.nome, p.descricao, f"{p.c:g}", f"{p.l:g}", f"{MDF:g}", n,
                            "sim" if it.girada else "não"])


# ---------------------------------------------------------------------------
# Desenho em milímetros (matplotlib): o mesmo código serve para o PDF 1:1 e
# para as prévias.
# ---------------------------------------------------------------------------

FONTE = FontProperties(family="DejaVu Sans", weight="bold")
FONTE_NORMAL = FontProperties(family="DejaVu Sans")


def texto_mm(ax, s, x, y, h, cor=None, ha="center", fonte=FONTE, z=6, rot=0.0):
    """Escreve `s` com altura de corpo `h` mm, centrado verticalmente em y."""
    tp = TextPath((0, 0), s, size=h, prop=fonte)
    ext = tp.get_extents()
    dx = {"center": -(ext.x0 + ext.x1) / 2, "left": -ext.x0, "right": -ext.x1}[ha]
    t = Affine2D().translate(dx, -0.36 * h).rotate_deg(rot).translate(x, y)
    ax.add_patch(PathPatch(t.transform_path(tp), fc=cor or COR["tinta"], ec="none",
                           lw=0, zorder=z))


@lru_cache(maxsize=None)
def _imagem(nome: str):
    caminho = ICONES / f"{nome}.png"
    if not caminho.exists():
        return None
    return plt.imread(caminho)


@lru_cache(maxsize=None)
def _logo():
    """Logotipo do jogo (front/images/logo.jpe) recortado no quadrado útil."""
    from PIL import Image
    if not LOGO_ARQ.exists():
        return None
    img = Image.open(LOGO_ARQ).convert("RGB")
    a = np.asarray(img)
    ys, xs = np.nonzero((a < 235).any(axis=2))
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    lado = max(x1 - x0, y1 - y0) + 24
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    caixa = (cx - lado // 2, cy - lado // 2, cx + lado // 2, cy + lado // 2)
    fundo = Image.new("RGB", (lado, lado), "white")
    fundo.paste(img.crop(caixa), (0, 0))
    return np.asarray(fundo)


def icone(ax, nome, x, y, tam, z=4):
    img = _imagem(nome)
    if img is None:   # sem PNG: círculo neutro, para o script nunca falhar
        ax.add_patch(Circle((x, y), tam / 2, fc="#ffffff", ec="#999999", lw=0.3, zorder=z))
        return
    ax.imshow(img, extent=(x - tam / 2, x + tam / 2, y - tam / 2, y + tam / 2),
              zorder=z, interpolation="antialiased")


def caixa_arredondada(ax, x0, y0, c, l, r, fc, ec="none", lw=0.0, z=2, ls="-"):
    ax.add_patch(FancyBboxPatch((x0, y0), c, l, boxstyle=f"round,pad=0,rounding_size={r}",
                                fc=fc, ec=ec, lw=lw, ls=ls, zorder=z))


def pilula(ax, s, x, y, h, fundo, cor, z=5):
    """Etiqueta arredondada com texto."""
    largura = TextPath((0, 0), s, size=h, prop=FONTE).get_extents().width + 2.4 * h
    caixa_arredondada(ax, x - largura / 2, y - 0.95 * h, largura, 1.9 * h, 0.95 * h,
                      fundo, z=z)
    texto_mm(ax, s, x, y, h, cor, z=z + 1)


def _marca_furo(ax, f: Recorte, cor, z=7):
    """No adesivo: contorno fino do furo, para recortar o papel."""
    ax.add_patch(Circle((f.x, f.y), f.d / 2, fc="#ffffff", ec=cor, lw=0.35, zorder=z))
    t = min(2.0, f.d / 3)
    ax.plot([f.x - t, f.x + t], [f.y, f.y], color=cor, lw=0.25, zorder=z + 1)
    ax.plot([f.x, f.x], [f.y - t, f.y + t], color=cor, lw=0.25, zorder=z + 1)


def _passo(ax, n, s, x, y, h, cor_fundo, cor_texto):
    """Título com número do passo num círculo: (1) ESCOLHA O ITEM."""
    largura = TextPath((0, 0), s, size=h, prop=FONTE).get_extents().width
    x_num = x - largura / 2 - 1.3 * h
    ax.add_patch(Circle((x_num, y), 0.95 * h, fc=cor_fundo, ec="none", zorder=5))
    texto_mm(ax, str(n), x_num, y, h * 0.95, "#ffffff", z=6)
    texto_mm(ax, s, x + 0.6 * h, y, h, cor_texto)


# --- conteúdo de cada adesivo ------------------------------------------------


def arte_seletor(ax, z: Zona) -> None:
    roxo, roxo_esc = z.borda, "#4B3D7A"
    _passo(ax, 1, "ESCOLHA O ITEM", z.cx, z.y0 + z.l - 9, 4.6, roxo, roxo_esc)
    anel = KNOB_DIAM / 2 + 3.5
    ax.add_patch(Circle((SELETOR_X, SELETOR_Y), anel, fc="#F8F5FD", ec=roxo, lw=0.6,
                        zorder=3))
    for pos in range(1, 11):
        a = math.radians(angulo_seletor(pos))
        cos, sen = math.cos(a), math.sin(a)
        ax.plot([SELETOR_X + anel * cos, SELETOR_X + (SELETOR_RAIO_NUM - 4.4) * cos],
                [SELETOR_Y + anel * sen, SELETOR_Y + (SELETOR_RAIO_NUM - 4.4) * sen],
                color=roxo, lw=0.8, zorder=3, solid_capstyle="round")
        xi, yi = SELETOR_X + SELETOR_RAIO_NUM * cos, SELETOR_Y + SELETOR_RAIO_NUM * sen
        ax.add_patch(Circle((xi, yi), 4.2, fc=roxo, ec="none", zorder=4))
        texto_mm(ax, str(pos), xi, yi, 4.0 if pos < 10 else 3.3, "#ffffff", z=5)
        xc, yc = _pos_icone(pos)
        ax.add_patch(Circle((xc, yc), ICONE_ITEM / 2 + 1.3, fc="#ffffff", ec=roxo, lw=0.4,
                            zorder=3))
        icone(ax, ITENS[pos - 1].icone, xc, yc, ICONE_ITEM)
    pilula(ax, "GIRE ATÉ O NÚMERO DO ITEM", SELETOR_X, z.y0 + 10, 2.8, roxo, "#ffffff")
    _marca_furo(ax, _furo("SELETOR"), roxo)


def arte_cartao(ax, z: Zona) -> None:
    roxo, roxo_esc = z.borda, "#4B3D7A"
    _passo(ax, 2, "PAGUE COM O CARTÃO", z.cx, z.y0 + z.l - 9, 4.0, roxo, roxo_esc)
    caixa_arredondada(ax, RFID_X - CARTAO_C / 2, RFID_Y - CARTAO_L / 2, CARTAO_C, CARTAO_L,
                      4, "#FFFFFF", roxo, 0.9, z=3, ls=(0, (4, 2)))
    icone(ax, "cartao", RFID_X, RFID_Y + 6, 30)
    texto_mm(ax, "APROXIME AQUI", RFID_X, RFID_Y - 17, 3.4, roxo_esc)
    texto_mm(ax, "CADA APROXIMAÇÃO", z.cx, z.y0 + 20, 2.9, roxo_esc)
    texto_mm(ax, "= 1 COMPRA DO ITEM ESCOLHIDO", z.cx, z.y0 + 13, 2.5, roxo_esc,
             fonte=FONTE_NORMAL)


def arte_acao(ax, z: Zona) -> None:
    escuro = {"acao_1": "#2D4F75", "acao_2": "#24573A", "acao_3": "#7A3826"}[z.chave]
    texto_mm(ax, z.titulo.upper(), z.cx, z.y0 + z.l - 8, 3.2, escuro)
    for b in [b for b in BOTOES if b.zona == z.chave]:
        ax.add_patch(Circle((b.x, b.y + 25), 10.5, fc="#ffffff", alpha=0.7, ec="none",
                            zorder=3))
        icone(ax, b.icone, b.x, b.y + 25, 17)
        texto_mm(ax, b.nome, b.x, b.y - 12.5, 2.9, escuro)
        _marca_furo(ax, _furo(b.nome), z.borda)
    tag = "USA 1 JOGADA" if z.chave == "acao_1" else "NÃO USA JOGADA"
    pilula(ax, tag, z.cx, z.y0 + 8, 2.4, z.borda, "#ffffff")


def arte_partida(ax, z: Zona) -> None:
    escuro = "#6B4F1D"
    texto_mm(ax, "PARTIDA", z.cx, z.y0 + z.l - 9, 4.0, escuro)
    for b in [b for b in BOTOES if b.zona == "partida"]:
        icone(ax, b.icone, PARTIDA_ICONE_X, b.y, 17)
        texto_mm(ax, b.nome, b.x, b.y - 12.5, 3.2, escuro)
        _marca_furo(ax, _furo(b.nome), z.borda)
    texto_mm(ax, "NOVA PARTIDA", z.cx, INICIAR_Y + 17, 2.4, escuro, fonte=FONTE_NORMAL)
    texto_mm(ax, "VOLTA AO INÍCIO", z.cx, RESET_Y + 17, 2.4, escuro, fonte=FONTE_NORMAL)


def arte_logo(ax, x0, y0, lado, borda=COR["verde_painel"]) -> None:
    caixa_arredondada(ax, x0, y0, lado, lado, 6, "#FFFFFF", borda, 0.8, z=2)
    img = _logo()
    m = 3.0
    if img is None:
        texto_mm(ax, "AVENTURA FINANCEIRA", x0 + lado / 2, y0 + lado / 2, lado / 14,
                 COR["verde_escuro"])
        return
    ax.imshow(img, extent=(x0 + m, x0 + lado - m, y0 + m, y0 + lado - m), zorder=3,
              interpolation="antialiased")


ARTE = {"seletor": arte_seletor, "cartao": arte_cartao, "partida": arte_partida,
        "acao_1": arte_acao, "acao_2": arte_acao, "acao_3": arte_acao}


def desenhar_adesivo(ax, z: Zona) -> None:
    if z.chave == "logo":
        arte_logo(ax, z.x0, z.y0, z.c, z.borda)
        return
    caixa_arredondada(ax, z.x0, z.y0, z.c, z.l, 5, z.fundo, z.borda, 0.8, z=2)
    ARTE[z.chave](ax, z)


# ---------------------------------------------------------------------------
# Prévias, texturas do visualizador e PDF dos adesivos
# ---------------------------------------------------------------------------


def _fundo_madeira(ax, recorte=None) -> None:
    """MDF cru. `recorte`: polígono que limita a madeira (contorno da peça)."""
    base = Polygon(recorte, closed=True) if recorte is not None else \
        Rectangle((0, 0), CAIXA_C, CAIXA_L)
    base.set(fc=COR["madeira"], ec="none", zorder=0)
    ax.add_patch(base)
    rng = np.random.default_rng(7)   # veios suaves, sempre iguais
    for _ in range(70):
        y = rng.uniform(0, CAIXA_L)
        xs = np.linspace(0, CAIXA_C, 60)
        ys = y + 1.2 * np.sin(xs / rng.uniform(25, 70) + rng.uniform(0, 6))
        (linha,) = ax.plot(xs, ys, color=COR["madeira_escura"], lw=rng.uniform(0.15, 0.5),
                           alpha=rng.uniform(0.15, 0.4), zorder=1)
        linha.set_clip_path(base)


def _desenhar_componentes(ax) -> None:
    """Capas dos botões e botão do seletor como vão aparecer prontos."""
    for b in BOTOES:
        ax.add_patch(Circle((b.x, b.y), FURO_BOTAO / 2, fc="#3A3A3A", zorder=8))
        ax.add_patch(Circle((b.x, b.y), CAPA_DIAM / 2, fc=CAPA[b.capa], ec="#00000055",
                            lw=0.4, zorder=9))
        ax.add_patch(Circle((b.x - 1.6, b.y + 1.6), CAPA_DIAM / 5, fc="#ffffff",
                            alpha=0.35, ec="none", zorder=10))
    ax.add_patch(Circle((SELETOR_X + 0.8, SELETOR_Y - 0.8), KNOB_DIAM / 2, fc="#00000030",
                        ec="none", zorder=8))
    ax.add_patch(Circle((SELETOR_X, SELETOR_Y), KNOB_DIAM / 2, fc="#5E4B96", ec="#3E3170",
                        lw=0.6, zorder=9))
    ax.add_patch(Circle((SELETOR_X, SELETOR_Y), KNOB_DIAM / 2 - 3, fc="#735FB0", ec="none",
                        zorder=9))
    a = math.radians(angulo_seletor(7))   # exemplo: seletor no item 7
    ax.plot([SELETOR_X + 2 * math.cos(a), SELETOR_X + (KNOB_DIAM / 2 - 1.5) * math.cos(a)],
            [SELETOR_Y + 2 * math.sin(a), SELETOR_Y + (KNOB_DIAM / 2 - 1.5) * math.sin(a)],
            color="#ffffff", lw=2.2, solid_capstyle="round", zorder=10)


def _eixos_mm(largura, altura, dpi):
    fig = plt.figure(figsize=(largura / 25.4, altura / 25.4), dpi=dpi)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_axis_off()
    return fig, ax


def _topo() -> Peca:
    return next(p for p in pecas() if p.nome == "tampa_topo")


def previa_colorida(caminho: Path) -> None:
    m = 12.0
    fig, ax = _eixos_mm(CAIXA_C + 2 * m, CAIXA_L + 2 * m, 220)
    ax.add_patch(Rectangle((-m, -m), CAIXA_C + 2 * m, CAIXA_L + 2 * m, fc="#F4F1EC",
                           zorder=-2))
    # As pontas das abas aparecem entre os dedos do topo
    ax.add_patch(Rectangle((0, 0), CAIXA_C, CAIXA_L, fc=COR["aba"], ec="#9CC4AE", lw=0.6,
                           zorder=-1))
    _fundo_madeira(ax, _topo().contorno())
    for z in ZONAS.values():
        desenhar_adesivo(ax, z)
    _desenhar_componentes(ax)
    texto_mm(ax, "FRENTE (lado do jogador)", CAIXA_C / 2, -7.0, 4.0, "#7A7A7A",
             fonte=FONTE_NORMAL)
    ax.set_xlim(-m, CAIXA_C + m)
    ax.set_ylim(-m, CAIXA_L + m)
    fig.savefig(caminho, dpi=220)
    plt.close(fig)


def textura_tampa(caminho: Path, px_mm: float = 4.0) -> None:
    """Arte da tampa para o visualizador 3D: madeira + adesivos, transparente
    nos furos e entre os dedos do encaixe."""
    from PIL import Image, ImageDraw

    fig, ax = _eixos_mm(CAIXA_C, CAIXA_L, 25.4 * px_mm)
    _fundo_madeira(ax)
    for z in ZONAS.values():
        desenhar_adesivo(ax, z)
    ax.set_xlim(0, CAIXA_C)
    ax.set_ylim(0, CAIXA_L)
    fig.savefig(caminho, dpi=25.4 * px_mm)
    plt.close(fig)
    img = Image.open(caminho).convert("RGBA")
    w, h = img.size
    px = lambda x, y: (x / CAIXA_C * w, (1 - y / CAIXA_L) * h)  # noqa: E731
    mascara = Image.new("L", img.size, 0)
    desenho = ImageDraw.Draw(mascara)
    desenho.polygon([px(x, y) for x, y in _topo().contorno()], fill=255)
    for f in furos():
        x0, y0, x1, y1 = f.caixa()
        desenho.ellipse([*px(x0, y1), *px(x1, y0)], fill=0)
    img.putalpha(mascara)
    img.save(caminho, optimize=True)


def textura_frente(caminho: Path, px_mm: float = 4.0) -> None:
    fig, ax = _eixos_mm(LOGO_FRENTE, LOGO_FRENTE, 25.4 * px_mm)
    arte_logo(ax, 0, 0, LOGO_FRENTE)
    ax.set_xlim(0, LOGO_FRENTE)
    ax.set_ylim(0, LOGO_FRENTE)
    fig.savefig(caminho, dpi=25.4 * px_mm, transparent=True)
    plt.close(fig)


def previa_tampa(caminho: Path) -> None:
    """Desenho técnico do topo da tampa: contorno com dedos, furos e as linhas
    gravadas onde vão os adesivos."""
    topo = _topo()
    fig, ax = plt.subplots(figsize=(10, 10 * CAIXA_L / CAIXA_C))
    ax.add_patch(Polygon(topo.contorno(), closed=True, fill=False, ec="red", lw=0.8))
    for g, z in zip(topo.gravacoes, ZONAS.values()):
        ax.add_patch(Polygon(g, closed=True, fill=False, ec="tab:blue", lw=0.6,
                             ls=(0, (3, 2))))
        ax.text(z.x0 + 2, z.y0 + z.l - 2, z.titulo, ha="left", va="top", fontsize=6,
                color="tab:blue")
    for f in topo.recortes:
        ax.add_patch(Circle((f.x, f.y), f.d / 2, fill=False, ec="red", lw=0.8))
        ax.plot([f.x - 3, f.x + 3], [f.y, f.y], color="green", lw=0.4)
        ax.plot([f.x, f.x], [f.y - 3, f.y + 3], color="green", lw=0.4)
        ax.text(f.x, f.y - f.d / 2 - 3.5, f"{f.nome} Ø{f.d:g}\n({f.x:g}; {f.y:g})",
                ha="center", va="top", fontsize=4.6, color="0.2")
    ax.add_patch(Rectangle((RFID_X - RC522_C / 2, RFID_Y - RC522_L / 2), RC522_C, RC522_L,
                           fill=False, ls="--", ec="0.5", lw=0.6))
    ax.text(RFID_X, RFID_Y, "RC522 por baixo\n(sem furo)", ha="center", va="center",
            fontsize=6, color="0.4")
    ax.text(CAIXA_C / 2, -8, "FRENTE (lado do jogador)", ha="center", fontsize=8, color="0.4")
    ax.set_xlim(-12, CAIXA_C + 12)
    ax.set_ylim(-14, CAIXA_L + 8)
    ax.set_aspect("equal")
    ax.set_title(f"Topo da tampa (mm): vermelho = corte, azul = gravação. "
                 f"Origem no canto frontal esquerdo. MDF {MDF:g} mm.", fontsize=9)
    ax.grid(True, lw=0.3, alpha=0.4)
    fig.savefig(caminho, dpi=170, bbox_inches="tight")
    plt.close(fig)


def _rodape_a4(fig, folha_w, folha_h, margem, texto_rodape):
    fig.text(margem / folha_w, 4 / folha_h, texto_rodape, fontsize=6)
    rx = 1 - (margem + 100) / folha_w
    fig.add_artist(Rectangle((rx, 9 / folha_h), 100 / folha_w, 1.5 / folha_h,
                             transform=fig.transFigure, color="black"))
    fig.text(rx, 11.5 / folha_h, "régua: deve medir 100 mm", fontsize=6)


# Organização dos adesivos nas folhas A4: (orientação, [(chave, x, y) na folha])
FOLHAS_ADESIVOS = [
    ("paisagem", [("seletor", 12, 34), ("cartao", 174, 34)]),
    ("paisagem", [("partida", 12, 34), ("acao_1", 115, 34), ("acao_2", 205, 34)]),
    ("retrato", [("logo_frente", 40, 152), ("acao_3", 10, 25), ("logo", 94, 25)]),
]


def _dimensoes_adesivo(chave: str) -> tuple[float, float, float, float]:
    if chave == "logo_frente":
        return LOGO_FRENTE, LOGO_FRENTE, 0.0, 0.0
    z = ZONAS[chave]
    return z.c, z.l, z.x0, z.y0


def validar_folhas() -> None:
    usados = set()
    for orient, itens in FOLHAS_ADESIVOS:
        fw, fh = (210.0, 297.0) if orient == "retrato" else (297.0, 210.0)
        caixas = []
        for chave, px, py in itens:
            c, l, _, _ = _dimensoes_adesivo(chave)
            assert px - 2 >= 6 and px + c + 2 <= fw - 4, f"adesivo fora da folha: {chave}"
            assert py - 2 >= 16 and py + l + 8 <= fh, f"adesivo fora da folha: {chave}"
            caixas.append((px - 2, py - 2, px + c + 2, py + l + 8))
            usados.add(chave)
        for i, a in enumerate(caixas):
            for b in caixas[i + 1:]:
                assert not (a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]), \
                    f"adesivos sobrepostos na folha {orient}"
    assert usados == set(ZONAS) | {"logo_frente"}, "falta adesivo nas folhas"


def pdf_adesivos(caminho: Path) -> int:
    """Adesivos coloridos em tamanho real, com linha de corte (cinza) e o
    contorno dos furos para recortar o papel depois de colado."""
    with PdfPages(caminho) as pdf:
        for n, (orient, itens) in enumerate(FOLHAS_ADESIVOS, start=1):
            fw, fh = (210.0, 297.0) if orient == "retrato" else (297.0, 210.0)
            fig = plt.figure(figsize=(fw / 25.4, fh / 25.4))
            for chave, px, py in itens:
                c, l, x0, y0 = _dimensoes_adesivo(chave)
                if chave == "logo_frente":
                    nome = "LOGO DA FRENTE — dentro do contorno gravado na frente do corpo"
                else:
                    nome = f"{ZONAS[chave].titulo.upper()} — tampa, x={x0:g} y={y0:g} mm"
                b = 2.0
                ax = fig.add_axes([(px - b) / fw, (py - b) / fh, (c + 2 * b) / fw,
                                   (l + 2 * b) / fh])
                ax.set_axis_off()
                if chave == "logo_frente":
                    arte_logo(ax, 0, 0, LOGO_FRENTE)
                else:
                    desenhar_adesivo(ax, ZONAS[chave])
                ax.add_patch(Rectangle((x0, y0), c, l, fill=False, ec="#9A9A9A", lw=0.3,
                                       ls=(0, (2, 2)), zorder=20))
                ax.set_xlim(x0 - b, x0 + c + b)
                ax.set_ylim(y0 - b, y0 + l + b)
                fig.text(px / fw, (py + l + 2.5) / fh, nome, fontsize=4.6 if c < 100 else 5.5,
                         color="0.35", va="bottom")
            _rodape_a4(fig, fw, fh, 12.0,
                       f"Adesivos da caixa — folha {n}/{len(FOLHAS_ADESIVOS)}. Imprimir em "
                       "TAMANHO REAL (100%) em couchê fosco. Cortar na linha tracejada.")
            pdf.savefig(fig)
            plt.close(fig)
    return len(FOLHAS_ADESIVOS)


def lista_componentes(caminho: Path) -> None:
    with open(caminho, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["componente", "tipo", "zona", "x_mm", "y_mm", "furo", "cor",
                    "sinal", "pino_fpga", "conector"])
        for b in BOTOES:
            w.writerow([b.nome, "botão 12x12 + capa", ZONAS[b.zona].titulo, b.x, b.y,
                        f"Ø{FURO_BOTAO:g}", f"capa {b.capa}", b.sinal, b.pino, b.conector])
        for i in range(10):
            w.writerow([f"SELETOR posição {i + 1} ({ITENS[i].nome.lower()})",
                        "chave rotativa 1 polo x 10+ posições", ZONAS["seletor"].titulo,
                        SELETOR_X, SELETOR_Y, f"Ø{FURO_SELETOR:g}", "botão lilás",
                        f"seletor_item[{i}] (ativo em 0)", PINO_SELETOR[i], GPIO_SELETOR[i]])
        w.writerow(["RC522", "leitor RFID (sem furo, colado por baixo)",
                    ZONAS["cartao"].titulo, RFID_X, RFID_Y, "—", "—",
                    "SPI na ESP32 (GPIO 5/18/19/22/23)", "—", "ESP32"])
        w.writerow(["ESP32", "ponte RFID/telemetria (sob a tampa)", ZONAS["cartao"].titulo,
                    ESP_X, ESP_Y, "—", "—", "GPIO17→rfid_rx, uart_tx→GPIO16, GND",
                    "PIN_C15 / PIN_A14", "GPIO_1_D22 / GPIO_1_D20"])
        for nome, sinal, motivo in FORA_DA_CAIXA:
            w.writerow([nome, "NÃO VAI NA CAIXA", "—", "—", "—", "—", "—", sinal,
                        "não ligar", f"o painel web já mostra ({motivo})"])


def config_visualizador(caminho: Path) -> None:
    """Onde o visualizador web cola as texturas (mm, coordenadas do CAD)."""
    dados = {
        "caixa": [CAIXA_C, CAIXA_L, CAIXA_A],
        "artes": [
            {"arquivo": "textura_tampa.png", "pai": "tampa", "c": CAIXA_C, "l": CAIXA_L,
             "pos": [CAIXA_C / 2, CAIXA_L / 2, CAIXA_A + 0.05], "plano": "xy"},
            {"arquivo": "textura_frente.png", "pai": "corpo", "c": LOGO_FRENTE,
             "l": LOGO_FRENTE, "pos": [CORPO_X0 + CORPO_C / 2, CORPO_Y0 - 0.45,
                                       LOGO_Z + LOGO_FRENTE / 2], "plano": "xz"},
        ],
    }
    caminho.write_text(json.dumps(dados, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# Modelo 3D: cada peça é o mesmo contorno do arquivo de corte, extrudado
# ---------------------------------------------------------------------------


def _cq_cor(hexa: str):
    import cadquery as cq
    r, g, b = matplotlib.colors.to_rgb(hexa)
    return cq.Color(r, g, b)


def _uniao(lista):
    total = None
    for p in lista:
        total = p if total is None else total.union(p)
    return total


def solido_peca(p: Peca):
    """Peça extrudada e colocada no lugar dela na caixa montada."""
    import cadquery as cq
    wp = cq.Workplane("XY").polyline(p.contorno()).close().extrude(MDF)
    for r in p.recortes:
        base = cq.Workplane("XY", origin=(0, 0, -1))
        ferramenta = (base.center(r.x, r.y).circle(r.d / 2) if r.redondo
                      else base.polyline(r.pontos()).close()).extrude(MDF + 2)
        wp = wp.cut(ferramenta)
    # (u, v, espessura) → mundo
    if p.plano in ("xz", "yz"):
        wp = wp.rotate((0, 0, 0), (1, 0, 0), 90)       # (u, -t, v)
    elif p.plano in ("xz_baixo", "yz_baixo"):
        wp = wp.rotate((0, 0, 0), (1, 0, 0), -90)      # (u, t, -v)
    if p.plano.startswith("yz"):
        wp = wp.rotate((0, 0, 0), (0, 0, 1), 90)       # (∓t, u, ±v)
    bb = wp.val().BoundingBox()
    esperado = {"xy": (p.c, p.l, MDF), "xz": (p.c, MDF, p.l), "xz_baixo": (p.c, MDF, p.l),
                "yz": (MDF, p.c, p.l), "yz_baixo": (MDF, p.c, p.l)}[p.plano]
    assert all(abs(a - b) < 0.01 for a, b in zip((bb.xlen, bb.ylen, bb.zlen), esperado)), \
        f"orientação errada: {p.nome}"
    x, y, z = p.destino
    return wp.translate((x - bb.xmin, y - bb.ymin, z - bb.zmin))


def validar_3d(solidos: dict) -> None:
    """Nenhuma peça de MDF pode ocupar o mesmo espaço que outra."""
    nomes = list(solidos)
    for i, a in enumerate(nomes):
        for b in nomes[i + 1:]:
            vol = solidos[a].val().intersect(solidos[b].val()).Volume()
            assert vol < 1e-3, f"peças se sobrepõem: {a} / {b} ({vol:.2f} mm³)"


def modelo_3d():
    import cadquery as cq

    face_inf = CAIXA_A - MDF
    topo_tampa = CAIXA_A
    paineis = {p.nome: (p, solido_peca(p)) for p in pecas() if p.grupo != "teste"}
    validar_3d({k: s for k, (_, s) in paineis.items()})

    corpo = cq.Assembly(name="corpo")
    aba = cq.Assembly(name="tampa_aba")
    for nome, (p, s) in paineis.items():
        if p.grupo == "corpo":
            corpo.add(s, name=nome, color=_cq_cor(COR["madeira_escura"]))
        elif nome != "tampa_topo":
            aba.add(s, name=nome, color=_cq_cor(COR["aba"]))

    logo = (cq.Workplane("XZ", origin=(CORPO_X0 + CORPO_C / 2, CORPO_Y0,
                                       LOGO_Z + LOGO_FRENTE / 2))
            .rect(LOGO_FRENTE, LOGO_FRENTE).extrude(0.4))   # XZ extruda para -Y
    fpga = (cq.Workplane("XY", origin=(CORPO_X0 + CORPO_C / 2,
                                       CORPO_Y0 + CORPO_L - MDF - 20 - FPGA_L / 2,
                                       MDF + ESPACADOR))
            .rect(FPGA_C, FPGA_L).extrude(1.6))

    adesivos = cq.Assembly(name="adesivos")
    for z in ZONAS.values():
        placa = (cq.Workplane("XY", origin=(z.cx, z.cy, topo_tampa))
                 .rect(z.c, z.l).extrude(0.4).edges("|Z").fillet(4.5))
        for f in furos():
            if f.zona == z.chave:
                placa = placa.cut(cq.Workplane("XY", origin=(f.x, f.y, topo_tampa - 1))
                                  .circle(f.d / 2).extrude(2.4))
        adesivos.add(placa, name=f"adesivo_{z.chave}", color=_cq_cor(z.fundo))

    placa_z = face_inf - espacador_botoes()
    corpo_alt = 3.5
    botoes = cq.Assembly(name="botoes")
    for b in BOTOES:
        corpo_b = (cq.Workplane("XY", origin=(b.x, b.y, placa_z))
                   .rect(BOTAO_CORPO, BOTAO_CORPO).extrude(corpo_alt))
        capa = (cq.Workplane("XY", origin=(b.x, b.y, placa_z + corpo_alt))
                .circle(CAPA_DIAM / 2).extrude(ALTURA_BOTAO_CAPA - corpo_alt)
                .faces(">Z").edges().fillet(1.2))
        botoes.add(corpo_b, name=f"corpo_{b.nome.lower()}", color=_cq_cor("#1E1E1E"))
        botoes.add(capa, name=f"capa_{b.nome.lower()}", color=_cq_cor(CAPA[b.capa]))

    seletor = cq.Assembly(name="seletor")
    corpo_s = (cq.Workplane("XY", origin=(SELETOR_X, SELETOR_Y, face_inf - 22))
               .circle(14).extrude(22))
    eixo = (cq.Workplane("XY", origin=(SELETOR_X, SELETOR_Y, face_inf))
            .circle(3).extrude(MDF + 4))
    knob = (cq.Workplane("XY", origin=(SELETOR_X, SELETOR_Y, topo_tampa + 0.5))
            .circle(KNOB_DIAM / 2).extrude(KNOB_A).faces(">Z").edges().fillet(2.0))
    ang = angulo_seletor(1)
    a = math.radians(ang)
    sx, sy = SELETOR_X + 6 * math.cos(a), SELETOR_Y + 6 * math.sin(a)
    seta = (cq.Workplane("XY", origin=(sx, sy, topo_tampa + 0.5 + KNOB_A))
            .rect(9, 2.4).extrude(0.6)
            .rotate((sx, sy, 0), (sx, sy, 1), ang))
    seletor.add(corpo_s, name="seletor_corpo", color=_cq_cor("#9A9A9A"))
    seletor.add(eixo, name="seletor_eixo", color=_cq_cor("#C0C0C0"))
    seletor.add(knob, name="seletor_botao", color=_cq_cor("#5E4B96"))
    seletor.add(seta, name="seletor_seta", color=_cq_cor("#FFFFFF"))

    rc522 = (cq.Workplane("XY", origin=(RFID_X, RFID_Y, face_inf - 2.6))
             .rect(RC522_C, RC522_L).extrude(1.6))
    esp = (cq.Workplane("XY", origin=(ESP_X, ESP_Y, face_inf - 12))
           .rect(ESP_C, ESP_L).extrude(1.6))

    placas = cq.Assembly(name="placas_tampa")
    xs = [b.x for b in BOTOES if b.zona.startswith("acao")]
    placa_acoes = (cq.Workplane("XY", origin=((min(xs) + max(xs)) / 2, ACAO_Y, placa_z - 1.6))
                   .rect(max(xs) - min(xs) + 24, 24).extrude(1.6))
    placa_partida = (cq.Workplane("XY", origin=(PARTIDA_X, (INICIAR_Y + RESET_Y) / 2,
                                                placa_z - 1.6))
                     .rect(24, INICIAR_Y - RESET_Y + 24).extrude(1.6))
    placas.add(placa_acoes, name="placa_acoes", color=_cq_cor("#B88A4A"))
    placas.add(placa_partida, name="placa_partida", color=_cq_cor("#B88A4A"))

    tampa = (cq.Assembly(name="tampa")
             .add(paineis["tampa_topo"][1], name="tampa_topo", color=_cq_cor(COR["madeira"]))
             .add(aba)
             .add(adesivos)
             .add(botoes)
             .add(seletor)
             .add(rc522, name="rc522", color=_cq_cor("#1A4DB3"))
             .add(esp, name="esp32", color=_cq_cor("#151515"))
             .add(placas))

    return (cq.Assembly(name="caixa_aef")
            .add(corpo)
            .add(logo, name="logo_frente", color=_cq_cor("#FFFFFF"))
            .add(fpga, name="de0_cv", color=_cq_cor("#1A6B33"))
            .add(tampa))


# ---------------------------------------------------------------------------


def main() -> None:
    validar()
    validar_folhas()
    SAIDA.mkdir(exist_ok=True)
    LASER.mkdir(exist_ok=True)
    for antigo in LASER.glob("chapa_*.*"):
        antigo.unlink()

    chapas = distribuir(pecas())
    for n, itens in enumerate(chapas, start=1):
        dxf_chapa(LASER / f"chapa_{n}.dxf", itens)
        svg_chapa(LASER / f"chapa_{n}.svg", itens)
    dxf_todas(LASER / "todas_as_chapas.dxf", chapas)
    mapa_chapas(LASER / "mapa_chapas.png", chapas)
    lista_pecas(LASER / "pecas.csv", chapas)

    n_ades = pdf_adesivos(SAIDA / "arte_adesivos.pdf")
    previa_tampa(SAIDA / "previa_tampa.png")
    previa_colorida(SAIDA / "previa_colorida.png")
    textura_tampa(SAIDA / "textura_tampa.png")
    textura_frente(SAIDA / "textura_frente.png")
    config_visualizador(SAIDA / "visualizador.json")
    lista_componentes(SAIDA / "lista_componentes.csv")

    import cadquery as cq
    montagem = modelo_3d()
    montagem.export(str(SAIDA / "caixa.step"))
    cq.exporters.export(montagem.toCompound(), str(SAIDA / "caixa.stl"))
    montagem.export(str(SAIDA / "caixa.glb"))

    print(f"MDF {MDF:g} mm, kerf {KERF:g} mm. Corpo {CORPO_C:g} × {CORPO_L:g} × {CORPO_A:g} mm; "
          f"tampa {CAIXA_C:g} × {CAIXA_L:g} × {TAMPA_A:g} mm")
    print(f"Laser: {len(chapas)} chapas de {CHAPA_C:g} × {CHAPA_L:g} mm "
          f"({sum(len(c) for c in chapas)} peças, incluindo 2 de teste)")
    print(f"Furos na tampa: {len(BOTOES)} botões Ø{FURO_BOTAO:g}, 1 seletor Ø{FURO_SELETOR:g}")
    print(f"Espaçador da placa dos botões: {espacador_botoes():.1f} mm")
    print(f"Adesivos: {n_ades} folhas A4")
    print("Arquivos em", SAIDA)


if __name__ == "__main__":
    main()
