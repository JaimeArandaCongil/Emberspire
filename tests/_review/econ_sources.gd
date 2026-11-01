extends "res://tests/progression_sim.gd"
## Revisión: desglose de Ascuas por fuente durante la simulación de progresión.

var by_src := {}
var by_src_window := {}
var window_marks := [30.0, 60.0, 120.0, 240.0, 480.0]
var _next_w := 0


func _ready() -> void:
	Game.embers_gained.connect(_on_gain)
	super._ready()
	print("\n== Ascuas por fuente (8 h) ==")
	var total := 0.0
	for k in by_src:
		total += by_src[k]
	var keys := by_src.keys()
	keys.sort_custom(func(a, b): return by_src[a] > by_src[b])
	for k in keys:
		print("  %-10s %12s  %5.1f%%" % [k, Num.fmt(by_src[k]), 100.0 * by_src[k] / total])


func _on_gain(amount: float, source: String) -> void:
	by_src[source] = by_src.get(source, 0.0) + amount
	var tm := t / 60.0
	while _next_w < window_marks.size() and tm >= window_marks[_next_w]:
		var tot := 0.0
		for k in by_src:
			tot += by_src[k]
		var s := "  t=%3d min:" % int(window_marks[_next_w])
		for k in ["idle", "click", "burn", "kill", "wave", "event", "treasure", "hito", "refund"]:
			s += " %s %.1f%%" % [k, 100.0 * by_src.get(k, 0.0) / maxf(tot, 1.0)]
		print(s)
		_next_w += 1
