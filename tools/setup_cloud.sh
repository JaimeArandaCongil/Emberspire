#!/usr/bin/env bash
# Entorno en la nube (Linux): instala Godot 4.7.2 en /opt/godot si falta. Idempotente.
# Capturas con ventana: xvfb-run -a -s "-screen 0 1280x720x24" /opt/godot/Godot_v4.7.2-stable_linux.x86_64 --path . res://tests/smoke.tscn
set -eu
BIN=/opt/godot/Godot_v4.7.2-stable_linux.x86_64
[ -x "$BIN" ] && { "$BIN" --version; exit 0; }
mkdir -p /opt/godot && cd /opt/godot
curl -sSL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -oq g.zip && rm g.zip
"$BIN" --version
