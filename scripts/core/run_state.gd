class_name RunState
extends RefCounted
## Estado de una ascensión a la Torre.

const DOOR_INFO := {
	"combat": {"name": "Combate", "icon": "sword", "desc": "Enemigos comunes. Recompensa: carta y Ascuas."},
	"elite": {"name": "Élite", "icon": "skull", "desc": "Enemigo poderoso. Recompensa: reliquia."},
	"rest": {"name": "Hoguera", "icon": "flame", "desc": "Descansa o templa una carta."},
	"shop": {"name": "Yunque Errante", "icon": "anvil", "desc": "Gasta Ascuas en cartas y servicios."},
	"event": {"name": "Misterio", "icon": "eye", "desc": "Algo se mueve entre el humo..."},
	"treasure": {"name": "Tesoro", "icon": "chest", "desc": "Un cofre olvidado."},
	"boss": {"name": "JEFE", "icon": "crown", "desc": "El guardián del acto."},
}

var deck: Array[Card] = []
var relics: Array[String] = []
var hp := 60
var max_hp := 60
var floor_num := 0
var max_energy := 3
var draw_per_turn := 5
var burns_per_turn := 1
var start_str := 0
var ember_mult := 1.0
var embers_earned := 0.0
var kills := 0
var burned := 0
var phoenix_available := false
var rng := RandomNumberGenerator.new()


func has_relic(id: String) -> bool:
	return relics.has(id)


func add_relic(id: String) -> void:
	if id == "" or relics.has(id):
		return
	relics.append(id)
	match id:
		"coal_heart":
			max_hp += 12
			hp += 12
		"moneylender_lens":
			ember_mult *= 1.3


func heal(n: int) -> void:
	hp = mini(max_hp, hp + n)


func act_floor() -> int:
	return (floor_num - 1) % 10 + 1


## Genera las puertas para el siguiente piso.
func roll_doors(extra: int = 0) -> Array[String]:
	var next := floor_num + 1
	var in_act := (next - 1) % 10 + 1
	if in_act == 10:
		return ["boss"]
	if in_act == 9:
		return ["rest", "shop"]
	if next == 1:
		return ["combat", "combat"]
	var weights := {"combat": 46, "elite": 0 if in_act < 4 else 13, "rest": 10 if in_act > 2 else 0,
		"shop": 10, "event": 13, "treasure": 6}
	var count := 3 + extra
	var out: Array[String] = []
	var guard := 0
	while out.size() < count and guard < 50:
		guard += 1
		var pick := _weighted(weights)
		# Evita repetir tipos no combativos en el mismo piso.
		if pick != "combat" and out.has(pick):
			continue
		out.append(pick)
	return out


func _weighted(weights: Dictionary) -> String:
	var total := 0
	for k: String in weights:
		total += int(weights[k])
	var r := rng.randi_range(1, total)
	for k: String in weights:
		r -= int(weights[k])
		if r <= 0:
			return k
	return "combat"


## Tres cartas para elegir tras un combate.
func roll_card_rewards(packs: Array, count: int = 3, elite: bool = false) -> Array[Card]:
	var out: Array[Card] = []
	var used: Array[String] = []
	for i in count:
		var roll := rng.randf()
		var rarity := "common"
		if roll < (0.12 if elite else 0.05):
			rarity = "rare"
		elif roll < (0.45 if elite else 0.33):
			rarity = "uncommon"
		var pool := CardDB.ids_in_packs(packs, rarity)
		if pool.is_empty():
			pool = CardDB.ids_in_packs(packs)
		var id: String = pool[rng.randi_range(0, pool.size() - 1)]
		var tries := 0
		while used.has(id) and tries < 10:
			id = pool[rng.randi_range(0, pool.size() - 1)]
			tries += 1
		used.append(id)
		out.append(Card.new(id, rng.randf() < 0.08 + floor_num * 0.006))
	return out
