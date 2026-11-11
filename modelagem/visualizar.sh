#!/bin/sh
# Gera o modelo e abre o visualizador 3D em http://localhost:${PORTA:-8000}/visualizador/
# Uso (na raiz do repositório): sh modelagem/visualizar.sh
set -e
PORTA="${PORTA:-8000}"
DIR="$(cd "$(dirname "$0")" && pwd)"
PY="$DIR/.venv/bin/python"

if [ ! -x "$PY" ]; then
  echo "Criando ambiente Python em modelagem/.venv (só na primeira vez)..."
  python3 -m venv "$DIR/.venv"
  "$DIR/.venv/bin/pip" install -q -r "$DIR/requirements.txt"
fi

echo "Gerando modelo..."
"$PY" "$DIR/caixa.py" 2>/dev/null

# Libera a porta se algo ficou rodando nela (ex.: visualizador anterior)
PIDS="$(ss -ltnpH "sport = :$PORTA" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u)"
if [ -n "$PIDS" ]; then
  echo "Encerrando processos na porta $PORTA: $PIDS"
  kill $PIDS 2>/dev/null || true
  sleep 1
fi

echo
echo "Visualizador: http://localhost:$PORTA/visualizador/"
echo "Ctrl+C para parar."
cd "$DIR"
exec "$PY" -m http.server "$PORTA" --bind 0.0.0.0
