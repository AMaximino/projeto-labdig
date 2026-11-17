"""Diagrama de ligações da caixa (docs/images/ligacoes-caixa.png).

    modelagem/.venv/bin/python docs/images/ligacoes-caixa.py
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyBboxPatch  # noqa: E402

SAIDA = Path(__file__).resolve().parent / "ligacoes-caixa.png"

fig, ax = plt.subplots(figsize=(16, 9.2), dpi=150)
ax.set_xlim(0, 160)
ax.set_ylim(-1.5, 92)
ax.axis("off")


def box(x, y, w, h, title, lines, fc, ec, tsize=10.5):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=1.6",
                                fc=fc, ec=ec, lw=1.4))
    ax.text(x + w / 2, y + h - 2.2, title, ha="center", va="center", fontsize=tsize,
            weight="bold", color="#24343A")
    for i, linha in enumerate(lines):
        ax.text(x + 1.6, y + h - 5.6 - i * 2.7, linha, ha="left", va="center",
                fontsize=8.2, color="#33454c")


def fio(x1, y1, x2, y2, txt, cor, xm, dy=0.6, lw=1.8, tx=None):
    ax.plot([x1, xm, xm, x2], [y1, y1, y2, y2], color=cor, lw=lw, solid_capstyle="round")
    ax.text(tx if tx is not None else x1 + 0.6, y1 + dy, txt, ha="left", va="bottom",
            fontsize=7.4, color=cor, weight="bold")


ax.add_patch(FancyBboxPatch((1, 3), 62, 84, boxstyle="round,pad=0,rounding_size=2",
                            fc="#FBF7EF", ec="#C8B48F", lw=1, ls=(0, (4, 3))))
ax.text(32, 84.6, "TAMPA (MDF 3 mm, tudo preso por baixo)", ha="center", fontsize=11,
        weight="bold", color="#8A6D3B")
box(4, 66, 42, 14, "Ações — 6 botões", ["trabalhar, estudar, investir,",
                                         "resgatar, comprar, vender",
                                         "(mesma ligação da Semana 3)"], "#DCEAF7", "#4F86C0")
box(4, 51, 42, 12, "Partida — 2 botões", ["iniciar (capa verde)", "reset (capa vermelha)"],
    "#F7EFDF", "#B08A4A")
box(4, 35, 42, 13, "Seletor rotativo 10 posições", ["posição k → seletor_item[k-1]",
                                                     "comum → GND (ativo em 0)",
                                                     "ilustração de cada item no adesivo"],
    "#ECE5F6", "#6F5AA8")
box(4, 8, 24, 14, "RC522", ["SDA→GPIO5  SCK→18", "MOSI→23 MISO→19", "RST→22  3,3V/GND"],
    "#D6E2F7", "#1A4DB3", 10)
box(33, 8, 27, 14, "ESP32 (sob a tampa)", ["GPIO17 (TX2) → rfid_rx", "GPIO16 (RX2) ← uart_tx",
                                            "alimentação: USB 5 V"], "#E3E3E3", "#151515", 10)
ax.plot([28, 33], [15, 15], color="#1A4DB3", lw=2.2)
ax.text(30.5, 15.9, "SPI", ha="center", fontsize=7.6, color="#1A4DB3", weight="bold")

box(80, 34, 34, 34, "FPGA DE0-CV", ["(fundo da caixa, espaçadores 10 mm)", "",
                                     "JP2 = GPIO_1", "  botões, seletor,", "  UART com a ESP32", "",
                                     "VCC3P3 do conector → 3,3 V", "dos botões e do seletor"],
    "#DDEFE2", "#1A6B33", 12)
ax.text(79, 50, "JP2", ha="right", fontsize=9, weight="bold", color="#1A6B33")
fio(46, 73, 80, 52, "GPIO_1 D25…D35 (6)", "#4F86C0", 68)
fio(46, 57, 80, 49, "GPIO_1 D23, D21", "#B08A4A", 72)
fio(46, 41.5, 80, 46, "GPIO_1 D0…D18 (pares)", "#6F5AA8", 66)
fio(60, 18, 80, 40, "UART: GPIO_1 D22 / D20", "#151515", 76, tx=60.6, dy=0.5)
ax.plot([60, 78.5, 78.5, 80], [11, 11, 36, 36], color="#222", lw=2.4, ls=(0, (1, 1.5)))
ax.text(60.6, 11.6, "GND comum", fontsize=7.4, weight="bold", color="#222")

box(80, 4.5, 34, 25, "Não vai na caixa", ["o painel web já mostra:", "rodada e jogada,",
                                         "saldo, salário, investido,",
                                         "itens comprados, fim do jogo", "",
                                         "LEDs, displays e botões de consulta",
                                         "saíram (sinais ficam sem ligação)"],
    "#F4F4F4", "#9A9A9A", 10.5)
box(124, 56, 33, 24, "Computador da bancada", ["USB-Blaster → programa a FPGA",
                                                "Mosquitto (MQTT) + backend",
                                                "painel web em http://…:3000", "",
                                                "Wi-Fi 2,4 GHz ← ESP32"], "#F2F2F2", "#777777",
    10.5)
box(124, 26, 33, 24, "Alimentação e referência", ["DE0-CV: fonte/USB própria",
                                                   "ESP32: USB 5 V (rasgo traseiro)",
                                                   "RC522: 3,3 V da ESP32",
                                                   "GND comum FPGA ↔ ESP32",
                                                   "NÃO unir os VCC das placas"], "#FCE3D3",
    "#C7684F", 10.5)
fio(114, 62, 124, 66, "USB (JTAG)", "#777777", 119, dy=-2.4, tx=114.4)
ax.plot([46.5, 46.5, 120, 120, 124], [8, 3.6, 3.6, 72, 72], color="#777777", lw=1.4,
        ls=(0, (4, 3)))
ax.text(121, 20, "Wi-Fi / MQTT (telemetria)", fontsize=7.4, color="#777777", weight="bold",
        ha="left", rotation=90)
ax.text(80, 0.3, "Feixe tampa → corpo: jumpers de 40–50 cm em espiral, para tirar a tampa "
        "sem puxar fios. Placas desligadas ao conectar.", fontsize=8.5, ha="center",
        color="#444")
fig.savefig(SAIDA, dpi=150, bbox_inches="tight", facecolor="white")
