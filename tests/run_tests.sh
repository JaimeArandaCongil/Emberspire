#!/usr/bin/env bash
# QA: ejecuta la suite headless y falla si hay errores de script o comprobaciones fallidas.
# Uso: GODOT=/ruta/a/godot ./tests/run_tests.sh
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
OUT=$("$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1)
CODE=$?
echo "$OUT" | grep -v "^\s*$"
if echo "$OUT" | grep -q "SCRIPT ERROR\|Parse Error"; then
	echo "QA: errores de script detectados"; exit 1
fi
exit $CODE
