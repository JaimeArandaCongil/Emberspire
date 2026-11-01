class_name Fighter
extends RefCounted
## Participante de combate (jugador o enemigo). Sólo estado; las reglas están en CombatEngine.

var display_name := ""
var def_id := ""
var is_player := false
var hp := 1
var max_hp := 1
var block := 0
var statuses := {}   # str, vuln, weak, scorch, thorns, regen, choke
var powers := {}     # sólo jugador
# Enemigo
var moves: Array = []
var pattern := "cycle"
var move_idx := 0
var last_move := -1
var intent: Dictionary = {}
var dmg_mult := 1.0
var shape := "slime"
var sprite_seed := ""
var biome := 0
var is_boss := false
var is_elite := false
var on_death: Array = []
## Ascuas robadas (Urracas): se devuelven dobles al matarla.
var stolen := 0.0


func alive() -> bool:
	return hp > 0


func st(id: String) -> int:
	return statuses.get(id, 0)


func add_status(id: String, n: int) -> void:
	var v := st(id) + n
	if v <= 0:
		statuses.erase(id)
	else:
		statuses[id] = v


func pw(id: String) -> int:
	return powers.get(id, 0)
