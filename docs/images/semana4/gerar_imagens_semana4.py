"""Gera as imagens da Semana 4 usadas no relatório.

Uso (a partir da raiz do repositório):
    python3 docs/images/semana4/gerar_imagens_semana4.py \
        --vcd semana4.vcd --transcript transcript_run.txt \
        --qarlog fpga/quartus/projeto_labdig_semana_4.qarlog \
        --map-summary <pasta restaurada>/quartus/output_files/circuito_jogo_financeiro.map.summary

- semana4.vcd: gerado por `vvp s4 +vcd` (circuito_caixa_semana4_tb)
- transcript_run.txt: saída de `vsim -c -do fpga/testbench/semana4/run_semana4.do`
- map.summary: Analysis & Synthesis do projeto restaurado a partir do .qar
"""
import argparse
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Polygon, Rectangle  # noqa: E402

AQUI = Path(__file__).resolve().parent

ESTADOS = {
    0b00000: "INICIO", 0b00001: "ESPERA_INICIO", 0b00010: "INICIALIZA",
    0b00011: "PREPARA", 0b00100: "ESPERA_ACAO", 0b00101: "REG_ACAO",
    0b00110: "PROC_ACAO", 0b00111: "VER_FALENCIA", 0b01000: "VER_JOGADA",
    0b01001: "VER_FIM_JOGO", 0b01010: "VER_FIM_RODADA", 0b01011: "AV_JOGADA",
    0b01100: "AV_RODADA", 0b01101: "APLICA_DESP", 0b01110: "VER_FAL_DESP",
    0b11010: "REG_DISPLAY", 0b11101: "FIM_JOGO", 0b11110: "FIM_FALENCIA",
}

# Cores no estilo da janela Wave do ModelSim
FUNDO = "#000000"
GRADE = "#1c1c1c"
VERDE = "#00e000"
AMARELO = "#ffff66"
CIANO = "#66ffff"
VERMELHO = "#ff4040"


# ---------------------------------------------------------------------------
# Leitura do VCD
# ---------------------------------------------------------------------------
def ler_vcd(caminho):
    ids, larg, ondas = {}, {}, {}
    t = 0
    with open(caminho) as f:
        for linha in f:
            linha = linha.strip()
            if linha.startswith("$var"):
                p = linha.split()
                ids.setdefault(p[3], []).append(p[4])
                larg[p[4]] = int(p[2])
                ondas[p[4]] = []
            elif linha.startswith("#"):
                t = int(linha[1:])
            elif linha.startswith("b"):
                v, k = linha[1:].split()
                for nome in ids.get(k, []):
                    ondas[nome].append((t, v))
            elif linha and linha[0] in "01xz" and len(linha) > 1:
                for nome in ids.get(linha[1:], []):
                    ondas[nome].append((t, linha[0]))
    return ondas, larg, t


def valor_int(v, largura, com_sinal=False):
    if any(c in "xz" for c in v):
        return None
    n = int(v, 2)
    if com_sinal and n >> (largura - 1):
        n -= 1 << largura
    return n


def valor_em(ondas, nome, t):
    ult = ondas[nome][0][1]
    for tt, v in ondas[nome]:
        if tt > t:
            break
        ult = v
    return ult


def inicio_caso(ondas, caso):
    for t, v in ondas["caso"]:
        if valor_int(v, 32) == caso:
            return t
    raise ValueError(caso)


# ---------------------------------------------------------------------------
# Desenho das formas de onda
# ---------------------------------------------------------------------------
def formatar(nome, v, largura, fmt):
    n = valor_int(v, largura, com_sinal=(fmt == "sdec"))
    if n is None:
        return "x"
    if fmt == "estado":
        return ESTADOS.get(n, format(n, "05b"))
    if fmt == "bin":
        return format(n, f"0{largura}b")
    if fmt == "hex":
        return format(n, "X")
    return str(n)


def desenhar(ondas, larg, sinais, t0, t1, titulo, arquivo, marcas=()):
    altura_linha = 0.42
    fig_h = 0.9 + altura_linha * len(sinais)
    fig = plt.figure(figsize=(13, fig_h), dpi=150, facecolor=FUNDO)
    ax_nome = fig.add_axes([0.0, 0.08, 0.17, 0.82], facecolor="#101010")
    ax = fig.add_axes([0.175, 0.08, 0.815, 0.82], facecolor=FUNDO)
    n = len(sinais)
    for a in (ax, ax_nome):
        a.set_ylim(n, 0)
        a.tick_params(colors="#c0c0c0", labelsize=7)
        for s in a.spines.values():
            s.set_color("#404040")
    ax_nome.set_xlim(0, 1)
    ax_nome.set_xticks([])
    ax_nome.set_yticks([])
    ax.set_xlim(t0, t1)
    ax.set_yticks([])

    escala, unidade = (1e9, "ms") if (t1 - t0) > 2e9 else (1e6, "µs")
    ticks = ax.get_xticks()
    ax.set_xticks(ticks)
    ax.set_xticklabels([f"{(x) / escala:.2f}" for x in ticks])
    ax.set_xlim(t0, t1)
    ax.set_xlabel(f"tempo ({unidade})", color="#c0c0c0", fontsize=8)
    for x in ticks:
        ax.axvline(x, color=GRADE, lw=0.6, zorder=0)
    largura_px = 13 * 0.815 * 150
    px = (t1 - t0) / largura_px

    for i, (nome, rotulo, fmt) in enumerate(sinais):
        y_lo, y_hi = i + 0.78, i + 0.22
        ax.axhline(i + 1, color=GRADE, lw=0.5)
        ax_nome.text(0.04, i + 0.5, rotulo, color="#e0e0e0", va="center",
                     fontsize=8, family="monospace")
        w = larg[nome]
        ev = ondas[nome]
        # trechos [ta, tb) com valor v dentro da janela
        trechos = []
        v_ini = valor_em(ondas, nome, t0)
        tc = t0
        for tt, v in ev:
            if tt <= t0:
                continue
            if tt >= t1:
                break
            trechos.append((tc, tt, v_ini))
            tc, v_ini = tt, v
        trechos.append((tc, t1, v_ini))
        if w == 1 and fmt != "bus":
            xs, ys = [], []
            for ta, tb, v in trechos:
                y = y_hi if v == "1" else y_lo if v == "0" else (y_lo + y_hi) / 2
                cor = VERDE if v in "01" else VERMELHO
                xs += [ta, tb]
                ys += [y, y]
            ax.plot(xs, ys, color=VERDE, lw=0.9, drawstyle="default")
        else:
            for ta, tb, v in trechos:
                d = min(3 * px, (tb - ta) / 2)
                ym = (y_lo + y_hi) / 2
                pts = [(ta, ym), (ta + d, y_hi), (tb - d, y_hi), (tb, ym),
                       (tb - d, y_lo), (ta + d, y_lo)]
                ax.add_patch(Polygon(pts, closed=True, fill=False,
                                     edgecolor=VERDE, lw=0.8))
                txt = formatar(nome, v, w, fmt)
                if (tb - ta) / px > 6.5 * len(txt) + 8:
                    ax.text((ta + tb) / 2, ym, txt, color=AMARELO, fontsize=6.5,
                            ha="center", va="center", family="monospace",
                            clip_on=True)
    for tm, texto in marcas:
        ax.axvline(tm, color=CIANO, lw=0.8, ls="--")
        ax.text(tm, -0.15, texto, color=CIANO, fontsize=7, ha="center",
                va="bottom", clip_on=False)
    fig.text(0.5, 0.985, titulo, color="white", ha="center", va="top", fontsize=10)
    fig.savefig(arquivo, facecolor=FUNDO)
    plt.close(fig)
    print("gerado", arquivo)


# ---------------------------------------------------------------------------
# Imagens de texto (transcript do ModelSim e relatório do .qar)
# ---------------------------------------------------------------------------
def imagem_texto(linhas, titulo, arquivo, destaques=(), largura=13):
    altura = 0.7 + 0.165 * len(linhas)
    fig = plt.figure(figsize=(largura, altura), dpi=150, facecolor="#f0f0f0")
    fig.text(0.01, 1 - 0.18 / altura, titulo, fontsize=10, weight="bold",
             va="top", color="#202020")
    ax = fig.add_axes([0.005, 0.01, 0.99, 1 - 0.42 / altura], facecolor="white")
    ax.set_xticks([]); ax.set_yticks([])
    for s in ax.spines.values():
        s.set_color("#909090")
    ax.set_xlim(0, 1); ax.set_ylim(len(linhas) + 0.5, -0.3)
    for i, l in enumerate(linhas):
        cor = "#202020"
        peso = "normal"
        for padrao, c in destaques:
            if re.search(padrao, l):
                cor, peso = c, "bold"
        ax.text(0.006, i + 0.5, l, fontsize=7.6, family="monospace", color=cor,
                va="center", weight=peso)
    fig.savefig(arquivo, facecolor="#f0f0f0")
    plt.close(fig)
    print("gerado", arquivo)


def transcript_regressao(caminho, arquivo):
    linhas = []
    for l in Path(caminho).read_text(errors="replace").splitlines():
        l = l.rstrip()
        if re.match(r"# vsim .*work\.", l) or "vsim -c" in l:
            linhas.append("")
            linhas.append(l)
        elif re.search(r"PASS|FALHOU|AVISO|antes da ultima|verificacoes|Compra sem saldo|"
                       r"UART framing|Moore outputs|Inicio da sim|Fim da sim|"
                       r"Semana 4 - interface|^# \*\* (Error|Fatal)", l):
            linhas.append(l)
        elif re.match(r"# \*\* Note: \$finish", l):
            linhas.append(l)
    while linhas and not linhas[0]:
        linhas.pop(0)
    imagem_texto(
        linhas,
        "ModelSim - Intel FPGA Edition 10.5b (18.1)  -  vsim -c -do fpga/testbench/semana4/run_semana4.do",
        arquivo,
        destaques=[(r"PASS|Compra sem saldo|UART framing|Moore outputs|Fim da sim", "#006400"),
                   (r"AVISO|antes da ultima", "#b05a00"),
                   (r"FALHOU|Error|Fatal", "#c00000"),
                   (r"^# vsim", "#00008b")],
    )


def imagem_qar(qarlog, summary, arquivo):
    linhas = []
    for l in Path(qarlog).read_text(errors="replace").splitlines():
        l = l.replace("C:/Users/Sophia/documents/projeto-labdig/", "")
        if l.strip():
            linhas.append(l.replace("\t", "    "))
    linhas.append("")
    linhas.append("--- projeto restaurado do .qar em pasta temporária e sintetizado (quartus_map) ---")
    for l in Path(summary).read_text(errors="replace").splitlines():
        if re.match(r"(Analysis|Quartus|Revision|Top-level|Family|Total registers|Total pins)", l):
            linhas.append(l)
    imagem_texto(
        linhas,
        "Quartus Prime 24.1std  -  quartus_sh --archive  (projeto_labdig_semana_4.qar)",
        arquivo,
        destaques=[(r"successfully|Successful", "#006400"),
                   (r"^Archive:|Total: ", "#00008b")],
    )


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vcd", required=True)
    ap.add_argument("--transcript", required=True)
    ap.add_argument("--qarlog", required=True)
    ap.add_argument("--map-summary", required=True)
    a = ap.parse_args()

    ondas, larg, t_fim = ler_vcd(a.vcd)
    S = lambda n, r, f="bin": (n, r, f)  # noqa: E731

    # Visão geral da simulação inteira
    desenhar(ondas, larg, [
        S("caso", "caso", "dec"),
        S("estado", "estado UC", "estado"),
        S("saldo", "saldo", "sdec"),
        S("indicador_itens", "LEDs itens", "bin"),
        S("rodada", "rodada", "dec"),
        S("jogada", "jogada", "dec"),
        S("ultima_rodada", "ULTIMA rodada"),
        S("perdeu", "LED FALIU"),
        S("terminou", "LED FIM JOGO"),
        S("uart_tx", "uart_tx"),
    ], 0, t_fim, "Cenário 10 - visão geral (casos 1 a 9)",
        AQUI / "sim-caixa-visao-geral.png")

    # Caso 2: seletor da posição 1 à 10
    t2, t3 = inicio_caso(ondas, 2), inicio_caso(ondas, 3)
    desenhar(ondas, larg, [
        S("seletor_item", "seletor_item", "bin"),
        S("clk_jogo", "clk_jogo"),
        S("estado", "estado UC", "estado"),
        S("tel_send", "tel_send"),
        S("tel_evento", "tel_evento", "dec"),
        S("tel_item", "tel_item", "dec"),
        S("saldo", "saldo", "sdec"),
    ], t2 - 20_000, t3, "Caso 2 - seletor girado da posição 1 à 10 (ativo em 0): evento 14 com o item",
        AQUI / "sim-caixa-seletor.png")

    # Caso 5: compra pelo cartão R08
    t5, t6 = inicio_caso(ondas, 5), inicio_caso(ondas, 6)
    desenhar(ondas, larg, [
        S("rfid_rx", "rfid_rx"),
        S("rfid_valid", "rfid_item_valid"),
        S("rfid_ack", "rfid_ack"),
        S("estado", "estado UC", "estado"),
        S("saldo", "saldo", "sdec"),
        S("indicador_itens", "LEDs itens", "bin"),
        S("tel_send", "tel_send"),
        S("tel_evento", "tel_evento", "dec"),
        S("tel_item", "tel_item", "dec"),
        S("uart_tx", "uart_tx"),
    ], t5 - 10_000, t6, "Caso 5 - cartão no item 8: ESP32 envia \"R08\\n\", compra aceita e LED 8 acende",
        AQUI / "sim-caixa-rfid.png")

    # Casos 7 e 8: item repetido e compra sem saldo
    t7, t9 = inicio_caso(ondas, 7), inicio_caso(ondas, 9)
    desenhar(ondas, larg, [
        S("caso", "caso", "dec"),
        S("rfid_rx", "rfid_rx"),
        S("seletor_item", "seletor_item", "bin"),
        S("comprar", "comprar"),
        S("estado", "estado UC", "estado"),
        S("saldo", "saldo", "sdec"),
        S("indicador_itens", "LEDs itens", "bin"),
        S("tel_evento", "tel_evento", "dec"),
        S("perdeu", "LED FALIU"),
    ], t7 - 10_000, t9, "Casos 7 e 8 - item repetido recusado (07) e compra sem saldo: saldo negativo e FALIU (13)",
        AQUI / "sim-caixa-falencia.png")

    # Caso 9: final da partida
    marcas = []
    ult = None
    for t, v in ondas["tel_evento"]:
        if valor_int(v, 8) == 12:
            ult = t
    if ult:
        marcas.append((ult, "evento 12"))
    t_ini = t_fim - 2_200_000_000 // 4  # últimas jogadas
    desenhar(ondas, larg, [
        S("trabalhar", "trabalhar"),
        S("estado", "estado UC", "estado"),
        S("rodada", "rodada", "dec"),
        S("jogada", "jogada", "dec"),
        S("ultima_rodada", "ULTIMA rodada"),
        S("ultima_jogada", "ULTIMA jogada"),
        S("terminou", "LED FIM JOGO"),
        S("tel_send", "tel_send"),
        S("tel_evento", "tel_evento", "dec"),
        S("saldo", "saldo", "sdec"),
    ], t_ini, t_fim, "Caso 9 - última rodada (rodada 14 = display 15): LEDs ÚLTIMA e FIM DO JOGO",
        AQUI / "sim-caixa-fim-jogo.png", marcas=marcas)

    transcript_regressao(a.transcript, AQUI / "sim-regressao-modelsim.png")
    imagem_qar(a.qarlog, a.map_summary, AQUI / "qar-semana4.png")


if __name__ == "__main__":
    main()
