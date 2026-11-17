"""Converte os ícones SVG da arte da tampa em PNG (arte/png/).

Os PNG já estão no repositório; rode este script só se mudar um SVG.
Usa o Chromium/Chrome em modo headless, porque o matplotlib não lê SVG.

    CHROME=/caminho/do/chrome modelagem/.venv/bin/python modelagem/arte/gerar_icones.py

Fontes dos ícones:
  - arte/svg/*.svg            ações, controles, cartão e seletor (desta pasta)
  - front/images/itens/*.svg  os 10 itens da loja (os mesmos do painel web)
"""

from __future__ import annotations

import glob
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ARTE = Path(__file__).resolve().parent
RAIZ = ARTE.parent.parent
SAIDA = ARTE / "png"
TAM = 400  # px; os ícones são impressos com ~20 mm, o que dá ~500 dpi


def achar_chrome() -> str:
    if os.environ.get("CHROME"):
        return os.environ["CHROME"]
    for nome in ("chromium", "chromium-browser", "google-chrome", "chrome"):
        if shutil.which(nome):
            return shutil.which(nome)
    candidatos = glob.glob(os.path.expanduser(
        "~/.cache/ms-playwright/chromium-*/chrome-linux/chrome"))
    if candidatos:
        return sorted(candidatos)[-1]
    raise SystemExit("Chrome/Chromium não encontrado. Defina CHROME=/caminho/do/chrome.")


def renderizar(chrome: str, svg: Path, png: Path) -> None:
    html = (f'<html><body style="margin:0;background:transparent">'
            f'<img src="{svg.as_uri()}" width="{TAM}" height="{TAM}"></body></html>')
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(html)
        pagina = f.name
    try:
        subprocess.run([chrome, "--headless=new", "--no-sandbox", "--disable-gpu",
                        "--hide-scrollbars", "--default-background-color=00000000",
                        f"--window-size={TAM},{TAM + 200}", f"--screenshot={png}",
                        Path(pagina).as_uri()],
                       check=True, capture_output=True, timeout=60)
    finally:
        os.unlink(pagina)
    # O modo headless desconta a barra da janela da altura; renderiza mais alto
    # e recorta o quadrado do ícone.
    from PIL import Image
    Image.open(png).crop((0, 0, TAM, TAM)).save(png)


def main() -> None:
    chrome = achar_chrome()
    SAIDA.mkdir(exist_ok=True)
    fontes = sorted((ARTE / "svg").glob("*.svg")) + sorted(
        (RAIZ / "front" / "images" / "itens").glob("item-*.svg"))
    for svg in fontes:
        renderizar(chrome, svg, SAIDA / (svg.stem + ".png"))
        print("ok", svg.stem)


if __name__ == "__main__":
    main()
