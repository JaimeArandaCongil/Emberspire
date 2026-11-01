#!/bin/bash
# Uso: bash tests/_review_art/v04/cartas_ui/run.sh [script.gd]
cd /c/Users/Jaime/Desktop/Claude/emberspire
S=${1:-gen.gd}
L="C:/Users/Jaime/AppData/Local/Temp/claude/C--Users-Jaime-Desktop-Claude/7edeef0b-ef30-4d30-a0e0-2a28a44096a1/scratchpad/g.log"
G="/c/Users/Jaime/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 120 "$G" --headless --path . --script res://tests/_review_art/v04/cartas_ui/$S > "$L" 2>&1
echo EXIT $?
grep -E "ERROR|SCRIPT|ok|at: " "$L" | grep -v "BUG\|leaked\|PagedAlloc\|string_name\|paged_alloc\|thread.cpp\|~PagedAllocator\|unref" | head -20
git checkout project.godot 2>/dev/null
