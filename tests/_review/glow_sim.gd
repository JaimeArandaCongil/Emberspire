extends "res://tests/_review/econ_sources.gd"
## Prueba Resplandor: args: horas pct_por_carta tope burn_secs
var pct := 0.02
var cap := 2.0

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var g := get_node("/root/Game")
	g.set_script(load("res://tests/_review/glow_game.gd"))
	if a.size() >= 4:
		pct = float(a[1]); cap = float(a[2]); g.burn_secs = float(a[3])
	if a.size() >= 5:
		g.wave_scale = float(a[4])
	print("pct=%s cap=%s burn_secs=%s" % [pct, cap, g.burn_secs])
	super._ready()

func _ascend() -> int:
	var before := int(Game.stats.get("burns", 0))
	Game.glow = 0.0
	var r := super._ascend()
	var burned := int(Game.stats.get("burns", 0)) - before
	Game.glow = minf(cap, pct * burned)
	return r
