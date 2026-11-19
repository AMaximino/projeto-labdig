"""Gera o livrinho: livrinho.pdf (8 páginas A5, para ler) e
livrinho_impressao.pdf (2 folhas A4 deitadas, frente e verso, já na ordem de
dobrar e grampear). Rodar: python3 manual-jogador/gerar_livrinho.py"""
import subprocess, sys
from pathlib import Path
from pypdf import PdfReader, PdfWriter, PageObject, Transformation

AQUI = Path(__file__).resolve().parent
CHROME = sys.argv[1] if len(sys.argv) > 1 else "chrome"
leitura = AQUI / "livrinho.pdf"
subprocess.run([CHROME, "--headless", "--no-sandbox", "--disable-gpu", "--no-pdf-header-footer",
                f"--print-to-pdf={leitura}", (AQUI / "livrinho.html").as_uri()], check=True,
               stderr=subprocess.DEVNULL)

paginas = PdfReader(leitura).pages
n = len(paginas)
assert n % 4 == 0, f"o livrinho precisa ter páginas em múltiplo de 4 (tem {n})"
w, h = float(paginas[0].mediabox.width), float(paginas[0].mediabox.height)
# Ordem de imposição: em cada lado da folha, (esquerda, direita).
lados = []
for i in range(n // 4):
    lados.append((n - 2 * i, 1 + 2 * i))       # frente
    lados.append((2 + 2 * i, n - 1 - 2 * i))   # verso
saida = PdfWriter()
for esq, dir_ in lados:
    folha = PageObject.create_blank_page(width=2 * w, height=h)
    folha.merge_transformed_page(paginas[esq - 1], Transformation())
    folha.merge_transformed_page(paginas[dir_ - 1], Transformation().translate(w, 0))
    saida.add_page(folha)
saida.write(AQUI / "livrinho_impressao.pdf")
print(f"{n} páginas A5 -> {len(lados)} lados A4: {lados}")
