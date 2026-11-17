"""Gera as imagens 3D da caixa para o relatório (docs/images/caixa-3d-*.png).

Abre o visualizador web num Chrome/Chromium sem janela e salva capturas.
Rode depois de caixa.py, na raiz do repositório:

    modelagem/.venv/bin/python modelagem/capturar.py

Precisa de internet (o visualizador carrega o three.js do jsDelivr) e do
Chrome/Chromium (mesma busca de arte/gerar_icones.py; ou CHROME=/caminho).
"""

from __future__ import annotations

import functools
import http.server
import subprocess
import sys
import threading
from pathlib import Path

AQUI = Path(__file__).resolve().parent
DOCS = AQUI.parent / "docs" / "images"
sys.path.insert(0, str(AQUI / "arte"))
from gerar_icones import achar_chrome  # noqa: E402

CAPTURAS = {
    "caixa-3d-fechada.png": "vista=iso&painel=0",
    "caixa-3d-aberta.png": "vista=iso&painel=0&abrir=160",
    "caixa-3d-cima.png": "vista=cima&painel=0",
}


def main() -> None:
    chrome = achar_chrome()
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(AQUI))
    servidor = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    servidor.RequestHandlerClass.log_message = lambda *a: None
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    porta = servidor.server_address[1]
    DOCS.mkdir(parents=True, exist_ok=True)
    try:
        for arquivo, query in CAPTURAS.items():
            url = f"http://127.0.0.1:{porta}/visualizador/?{query}"
            subprocess.run([chrome, "--headless=new", "--no-sandbox", "--hide-scrollbars",
                            "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
                            "--window-size=1400,1000", "--virtual-time-budget=20000",
                            f"--screenshot={DOCS / arquivo}", url],
                           check=True, capture_output=True, timeout=180)
            print("salvo", DOCS / arquivo)
    finally:
        servidor.shutdown()


if __name__ == "__main__":
    main()
