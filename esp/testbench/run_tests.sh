#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUTPUT="${TMPDIR:-/tmp}/aef-esp8266-protocol-test"

g++ -std=c++11 -Wall -Wextra -Werror \
  "$SCRIPT_DIR/telemetry_protocol_test.cpp" \
  -o "$OUTPUT"
"$OUTPUT"
rm -f "$OUTPUT"
