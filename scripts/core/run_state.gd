class_name RunState
extends RefCounted
## Estado de una ascensión a la Torre.

const DOOR_INFO := {
	"combat": {"name": "Combate", "icon": "sword", "desc": "Enemigos comunes. Recompensa: carta y Ascuas."},
	"elite": {"name": "Élite", "icon": "skull", "desc": "Enemigo poderoso. Recompensa: reliquia."},
	"rest": {"name": "Hoguera", "icon": "bonfire", "desc": "Descansa, templa una carta o haz una ofrenda."},
	"shop": {"name": "Yunque Errante", "icon": "anvil", "desc": "Gasta Ascuas en cartas, reliquias y servicios."},
	"event": {"name": "Misterio", "icon": "eye", "desc": "Algo se mueve entre el humo..."},
	"treasure": {"name": "Tesoro", "icon": "chest", "desc": "Un cofre olvidado."},
	"boss": {"name": "JEFE", "icon": "crown", "desc": "El guardián del acto."},
}

var deck: Array[Card] = []
var relics: Array[String] = []
## Resonancias activas (ventajas de los generadores de la Forja).
var perks: Array[String] = []
## Pactos de Brasa activos en esta ascensión.
var pacts: Array[String] = []
var seen_events: Array[String] = []
var hp := 60
var max_hp := 60
var floor_num := 0
var max_energy := 3
var draw_per_turn := 5
var burns_per_turn := 1
var start_str := 0
var dmg_mult := 1.0
var ember_mult := 1.0
var embers_earned := 0.0
var kills := 0
var burned := 0
var mastery_ups := 0
## Brasas Vivas: pisos seguidos sin volver a la Forja y bote pendiente de cobrar.
var streak_floors := 0
var floors_climbed := 0
var pot := 0.0
var tutorial := false
var pending_drafts := 0
var pending_boss_relics := 0
## Puertas del piso: tipo + datos (encuentro y rasgo de los combates).
var door_meta: Array = []
## Modificadores del combate actual (rasgo de la puerta).
var combat_mods := {}
var phoenix_charges := 0
var pending_doors: Array[String] = []
## true mientras se está dentro de una sala (combate, tienda...). Al cargar se repite el piso.
var in_room := false
var rng := RandomNumberGenerator.new()


## Reliquia o Resonancia activa.
func has_relic(id: String) -> bool:
	return relics.has(id) or perks.has(id)


func has_pact(id: String) -> bool:
	return pacts.has(id)


func heat() -> int:
	var h := 0
	for id in pacts:
		h += int(ForgeDB.pact(id).get("heat", 0))
	return h


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
		"ember_coin":
			ember_mult *= 1.2
		"phoenix_ash":
			phoenix_charges += 1
		"ember_lantern":
			draw_per_turn += 1
		"cracked_core":
			max_energy += 1
		"leather_bellows":
			pass  # Se aplica en CombatEngine (Quemas por turno).
	if is_inside_codex_hook():
		Game.collect_relic(id)


## Las reliquias de ascensiones reales entran en el Reliquario (los tests usan runs sueltas).
func is_inside_codex_hook() -> bool:
	return Game.run == self


## +4% por piso de racha, tope +100%.
func streak_mult() -> float:
	return minf(1.0, 0.04 * streak_floors)


func heal(n: int) -> void:
	hp = mini(max_hp, hp + n)


func act_floor() -> int:
	return (floor_num - 1) % 10 + 1


const DOOR_TRAITS := {
	"rare": "Recompensa: carta rara garantizada",
	"burn": "+1 Quema cada turno de este combate",
	"embers": "+50% Ascuas en este combate",
	"upgrade": "La recompensa de carta viene mejorada",
	"none": "",
}


## Genera las puertas para el siguiente piso (y sus datos en door_meta).
func roll_doors(extra: int = 0) -> Array[String]:
	var next := floor_num + 1
	var in_act := (next - 1) % 10 + 1
	var out: Array[String] = []
	door_meta = []
	if in_act == 10:
		out = ["boss"]
	elif in_act == 9:
		out = ["rest", "shop"]
	elif next == 1:
		out = ["combat", "combat"]
	else:
		var weights := {"combat": 44, "elite": 0 if in_act < 4 else 13, "rest": 10 if in_act > 2 else 0,
			"shop": 10, "event": 16, "treasure": 4}
		var count := 3 + extra + (1 if has_relic("scorched_map") else 0)
		var guard := 0
		while out.size() < count and guard < 80:
			guard += 1
			var pick := _weighted(weights)
			# Nunca dos puertas iguales; los combates pueden repetirse una vez (con rasgo distinto).
			if out.has(pick) and (pick != "combat" or out.count("combat") >= 2):
				continue
			out.append(pick)
	var used_traits: Array[String] = []
	for kind in out:
		var meta := {}
		if kind in ["combat", "elite", "boss"]:
			meta["enemies"] = EnemyDB.pick_encounter(kind, next, rng)
			if kind == "combat":
				var traits := ["rare", "burn", "embers", "upgrade", "none", "none"]
				var t: String = traits[rng.randi_range(0, traits.size() - 1)]
				var tries := 0
				while used_traits.has(t) and tries < 10:
					t = traits[rng.randi_range(0, traits.size() - 1)]
					tries += 1
				used_traits.append(t)
				meta["trait"] = t
		door_meta.append(meta)
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


## Cartas para elegir tras un combate.
func roll_card_rewards(packs: Array, count: int = 3, elite: bool = false) -> Array[Card]:
	if has_relic("res_crucible1"):
		count += 1
	if has_relic("res_crucible1b"):
		count = 2
	if Game.constellations.has("c_seer"):
		count += 1
	var up_chance := 0.08 + floor_num * 0.006 + (0.15 if has_relic("res_crucible2") else 0.0)
	var out: Array[Card] = []
	var used: Array[String] = []
	for i in count:
		var roll := rng.randf()
		if i == 0 and has_relic("res_crucible1b"):
			roll = minf(roll, 0.32)
		if i == 0 and combat_mods.has("rare"):
			roll = 0.0
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
		out.append(Card.new(id, combat_mods.has("upgrade") or rng.randf() < up_chance))
	return out


# --- Guardado ---------------------------------------------------------------

func to_dict() -> Dictionary:
	var cards: Array = []
	for c in deck:
		cards.append([c.id, c.upgraded])
	return {"deck": cards, "relics": relics, "perks": perks, "pacts": pacts, "seen_events": seen_events,
		"hp": hp, "max_hp": max_hp, "floor": floor_num,
		"energy": max_energy, "draw": draw_per_turn, "burns": burns_per_turn, "str": start_str, "dmg_mult": dmg_mult,
		"ember_mult": ember_mult, "embers": embers_earned, "kills": kills, "burned": burned, "mastery_ups": mastery_ups, "streak": streak_floors, "climbed": floors_climbed, "pot": pot,
		"tutorial": tutorial, "drafts": pending_drafts, "boss_relics": pending_boss_relics, "door_meta": door_meta,
		"phoenix": phoenix_charges, "doors": pending_doors, "in_room": in_room, "seed": str(rng.seed), "state": str(rng.state)}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	for e in d.get("deck", []):
		if e is Array and e.size() == 2 and CardDB.CARDS.has(str(e[0])):
			r.deck.append(Card.new(str(e[0]), bool(e[1])))
	for id in d.get("relics", []):
		r.relics.append(str(id))
	for id in d.get("perks", []):
		r.perks.append(str(id))
	for id in d.get("pacts", []):
		r.pacts.append(str(id))
	for id in d.get("seen_events", []):
		r.seen_events.append(str(id))
	r.hp = int(d.get("hp", 60))
	r.max_hp = int(d.get("max_hp", 60))
	r.floor_num = int(d.get("floor", 0))
	r.max_energy = int(d.get("energy", 3))
	r.draw_per_turn = int(d.get("draw", 5))
	r.burns_per_turn = int(d.get("burns", 1))
	r.start_str = int(d.get("str", 0))
	r.dmg_mult = float(d.get("dmg_mult", 1.0))
	r.ember_mult = float(d.get("ember_mult", 1.0))
	r.embers_earned = float(d.get("embers", 0.0))
	r.kills = int(d.get("kills", 0))
	r.burned = int(d.get("burned", 0))
	r.mastery_ups = int(d.get("mastery_ups", 0))
	r.streak_floors = int(d.get("streak", 0))
	r.floors_climbed = int(d.get("climbed", 0))
	r.pot = float(d.get("pot", 0.0))
	r.tutorial = bool(d.get("tutorial", false))
	r.pending_drafts = int(d.get("drafts", 0))
	r.pending_boss_relics = int(d.get("boss_relics", 0))
	var dm: Variant = d.get("door_meta", [])
	if dm is Array:
		r.door_meta = dm
	var ph: Variant = d.get("phoenix", 0)
	r.phoenix_charges = (1 if ph else 0) if ph is bool else int(ph)
	for k in d.get("doors", []):
		r.pending_doors.append(str(k))
	r.rng.seed = str(d.get("seed", "0")).to_int()
	r.rng.state = str(d.get("state", "0")).to_int()
	# Si se cerró el juego dentro de una sala, se vuelve a elegir puerta en ese piso.
	if bool(d.get("in_room", false)):
		r.floor_num = maxi(0, r.floor_num - 1)
		r.pending_doors.clear()
		r.door_meta.clear()
	return r
