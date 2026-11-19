"""Gera front/cenario/cenario_loop.mp4 (1920×1080, 30 fps, 24 s que emendam sem corte) a partir de front/cenario/index.html.

Cada quadro é capturado com o relógio das animações parado no instante exato
(Web Animations API), então o vídeo fica liso e o último quadro emenda no primeiro.

Uso:  python3 cenario/gerar_video.py [--chrome CAMINHO] [--ffmpeg CAMINHO] [--previa]
Precisa do Playwright (pip install playwright) e de um Chromium.
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
PAGINA = AQUI.parent / "front" / "cenario" / "index.html"
SAIDA = AQUI.parent / "front" / "cenario" / "cenario_loop.mp4"
LOOP_S, FPS, W, H = 24, 30, 1920, 1080

ap = argparse.ArgumentParser()
ap.add_argument("--chrome", default=None)
ap.add_argument("--ffmpeg", default=shutil.which("ffmpeg") or "ffmpeg")
ap.add_argument("--previa", action="store_true", help="só 6 quadros de amostra, sem vídeo")
args = ap.parse_args()

from playwright.sync_api import sync_playwright  # noqa: E402

PARA_EM = """(t) => {
  for (const a of document.getAnimations()) { a.pause(); a.currentTime = t; }
}"""

with tempfile.TemporaryDirectory() as tmp, sync_playwright() as p:
    nav = p.chromium.launch(args=["--no-sandbox"], executable_path=args.chrome) if args.chrome else p.chromium.launch()
    pagina = nav.new_page(viewport={"width": W, "height": H})
    pagina.goto(PAGINA.as_uri())
    pagina.evaluate("document.fonts.ready")
    pagina.wait_for_timeout(500)
    # quadro de aquecimento, descartado: garante que tudo já foi desenhado
    pagina.evaluate(PARA_EM, 0)
    pagina.screenshot(path=str(Path(tmp) / "aquecimento.png"))
    pagina.wait_for_timeout(300)
    total = LOOP_S * FPS
    quadros = [0, total // 6, total // 3, total // 2, 2 * total // 3, 5 * total // 6] if args.previa else range(total)
    for i in quadros:
        pagina.evaluate(PARA_EM, i * 1000 / FPS)
        destino = (AQUI / f"previa_{i:04d}.png") if args.previa else Path(tmp) / f"q{i:04d}.png"
        pagina.screenshot(path=str(destino))
        if not args.previa and i % 120 == 0:
            print(f"quadro {i}/{total}", flush=True)
    # confere a emenda: o instante 24 s tem que ser igual ao 0 s
    if not args.previa:
        pagina.evaluate(PARA_EM, LOOP_S * 1000)
        pagina.screenshot(path=str(Path(tmp) / "emenda.png"))
    nav.close()

    if args.previa:
        sys.exit(0)

    from PIL import Image, ImageChops
    dif = ImageChops.difference(Image.open(Path(tmp) / "q0000.png").convert("RGB"),
                                Image.open(Path(tmp) / "emenda.png").convert("RGB")).getbbox()
    print("emenda do loop:", "perfeita" if dif is None else f"diferença em {dif}")

    saida = SAIDA
    subprocess.run([args.ffmpeg, "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(Path(tmp) / "q%04d.png"),
                    "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
                    "-movflags", "+faststart", str(saida)], check=True)
    print("salvo", saida)
