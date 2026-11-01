extends Node

func _ready() -> void:
	Game.autosave_enabled = false
	var r := RunState.new()
	r.rng.seed = 42
	var n := 0
	var all_combat := 0
	var dup_combat := 0
	var treasure := 0
	var elite := 0
	var types := {}
	for i in 20000:
		r.floor_num = i % 30
		var d := r.roll_doors()
		if d.size() < 3:
			continue
		n += 1
		var cc := d.count("combat")
		if cc == d.size():
			all_combat += 1
		if cc >= 2:
			dup_combat += 1
		if d.has("treasure"):
			treasure += 1
		if d.has("elite"):
			elite += 1
	print("pisos con 3 puertas: %d · todas combate %.1f%% · ≥2 combates (opciones repetidas) %.1f%% · con Tesoro %.1f%% · con Élite %.1f%%" % [n, 100.0 * all_combat / n, 100.0 * dup_combat / n, 100.0 * treasure / n, 100.0 * elite / n])
	get_tree().quit()
