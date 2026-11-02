#!/usr/bin/env bash
# QA silenciosa: imprime sólo resúmenes y fallos. Pensada para agentes (no llena el contexto con registros de Godot).
# Uso: tools/qa.sh [game|art|bake|all] [--only=id1,id2]   (por defecto: all)
# Variable GODOT para otra ruta del binario. Devuelve 0 sólo si todo pasa.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/Jaime/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
MODE="${1:-all}"; ONLY="${2:-}"; RC=0
filter() { grep -E "$1" | cut -c1-200 | sort -u | head -n "${2:-25}"; }
if [ "$MODE" = bake ]; then
	OUT=$("$GODOT" --headless --path . -s res://tools/bake_art.gd -- $ONLY 2>&1); C=$?
	echo "$OUT" | filter "ERROR|error|lint|horneado|hornead|al día" 25
	"$GODOT" --headless --path . --import >/dev/null 2>&1
	exit $C
fi
"$GODOT" --headless --path . --import >/dev/null 2>&1
if [ "$MODE" = game ] || [ "$MODE" = all ]; then
	OUT=$("$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1) || RC=1
	echo "$OUT" | filter "== QA|FALLO|SCRIPT ERROR|Parse Error"
	echo "$OUT" | grep -q "SCRIPT ERROR\|Parse Error" && RC=1
fi
if [ "$MODE" = art ] || [ "$MODE" = all ]; then
	OUT=$("$GODOT" --headless --path . res://tests/art/art_tests.tscn 2>&1) || RC=1
	echo "$OUT" | grep -E "== ARTE|✗|^ +·|SCRIPT ERROR|Parse Error" | cut -c1-200 | head -n 30
	echo "$OUT" | grep -q "✗\|SCRIPT ERROR\|Parse Error" && RC=1
fi
exit $RC
