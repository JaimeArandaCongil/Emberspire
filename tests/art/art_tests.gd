extends Node
## Escena de pruebas de ARTE v0.4 (TEC). Ejecuta `run() -> Array` (fallos) de cada `tests/art/test_*.gd`.
## Uso:  godot --headless --path . res://tests/art/art_tests.tscn            (todas)
##       godot --headless --path . res://tests/art/art_tests.tscn -- --only=tec,da
## Código de salida: 0 si no hay fallos; 1 si los hay. Convención (DA): cada prueba es un RefCounted con `run() -> Array`
## que devuelve cadenas de fallo; vacío = todo pasa. Cada rol amplía SU archivo (test_da, test_tec, test_ui, test_mv, test_per).

const DIR := "res://tests/art/"


func _ready() -> void:
	var only: Array[String] = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for s in a.substr(7).split(",", false):
				only.append(s.strip_edges())
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	var total := 0
	var suites := 0
	for f: String in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		var tag := f.get_basename().substr(5)
		if not only.is_empty() and not only.has(tag):
			continue
		var t0 := Time.get_ticks_msec()
		var scr: Variant = load(DIR + f)
		if not (scr is GDScript) or not (scr as GDScript).can_instantiate():
			print("✗ %s: no compila" % f)
			total += 1
			continue
		var inst: Object = (scr as GDScript).new()
		if not inst.has_method("run"):
			print("✗ %s: falta run() -> Array" % f)
			total += 1
			continue
		var fails: Array = inst.call("run")
		suites += 1
		total += fails.size()
		print("%s %s: %d fallos (%.1f s)" % ["✓" if fails.is_empty() else "✗", f, fails.size(), (Time.get_ticks_msec() - t0) / 1000.0])
		for e in fails.slice(0, 60):
			print("    · ", e)
		if fails.size() > 60:
			print("    … y %d más" % (fails.size() - 60))
	print("== ARTE: %d suites, %d fallos ==" % [suites, total])
	get_tree().quit(0 if total == 0 else 1)
