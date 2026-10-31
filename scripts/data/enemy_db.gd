class_name EnemyDB
extends RefCounted
## Enemigos y encuentros. Movimientos:
##   ["atk", daño, veces] ["block", n] ["block_all", n] ["str", n] ["str_all", n] ["heal", n]
##   ["scorch_p", n] ["weak_p", n] ["vuln_p", n] ["add_card", id, n]

const ENEMIES := {
	# ---- Acto 1: Hollín -----------------------------------------------------
	"ash_slime": {"name": "Limo de Ceniza", "hp": [12, 16], "shape": "slime", "pattern": "random",
		"moves": [[["atk", 6, 1]], [["atk", 3, 1], ["weak_p", 1]], [["block", 5], ["str", 1]]]},
	"cinder_bat": {"name": "Murciélago Brasa", "hp": [8, 11], "shape": "bat", "pattern": "cycle",
		"moves": [[["atk", 3, 2]], [["atk", 4, 1], ["scorch_p", 2]]]},
	"soot_golem": {"name": "Gólem de Hollín", "hp": [28, 32], "shape": "golem", "pattern": "cycle",
		"moves": [[["block", 8], ["add_card", "soot", 2]], [["atk", 9, 1]], [["atk", 12, 1]]]},
	"hollow_knight": {"name": "Caballero Hueco", "hp": [44, 48], "shape": "knight", "pattern": "cycle", "elite": true,
		"moves": [[["str", 2], ["block", 10]], [["atk", 12, 1]], [["atk", 6, 2]]]},
	"smoke_witch": {"name": "Bruja de Humo", "hp": [38, 42], "shape": "wraith", "pattern": "cycle", "elite": true,
		"moves": [[["weak_p", 2], ["vuln_p", 2]], [["atk", 11, 1]], [["scorch_p", 5]], [["atk", 7, 1], ["add_card", "soot", 1]]]},
	"coalfather": {"name": "El Carbonero", "hp": [130, 130], "shape": "boss_king", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 7, 2]], [["add_card", "soot", 3], ["block", 15]], [["atk", 20, 1]], [["str", 3], ["heal", 10]]]},

	# ---- Acto 2: Escoria ----------------------------------------------------
	"slag_crawler": {"name": "Reptante de Escoria", "hp": [32, 36], "shape": "crawler", "pattern": "cycle",
		"moves": [[["atk", 10, 1]], [["block", 10], ["str", 2]], [["atk", 5, 2]]]},
	"molten_eye": {"name": "Ojo Fundido", "hp": [24, 28], "shape": "eye", "pattern": "cycle",
		"moves": [[["vuln_p", 2], ["atk", 6, 1]], [["atk", 14, 1]]]},
	"brimstone_imp": {"name": "Diablillo de Azufre", "hp": [20, 24], "shape": "imp", "pattern": "random",
		"moves": [[["atk", 5, 3]], [["scorch_p", 4]], [["atk", 8, 1], ["weak_p", 1]]]},
	"slag_warden": {"name": "Guardián de Escoria", "hp": [95, 100], "shape": "golem", "pattern": "cycle", "elite": true,
		"moves": [[["block_all", 15], ["str_all", 2]], [["atk", 16, 1]], [["atk", 9, 2], ["vuln_p", 1]]]},
	"slag_queen": {"name": "Reina Escoria", "hp": [280, 280], "shape": "boss_queen", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 10, 3]], [["scorch_p", 8], ["block", 25]], [["atk", 30, 1]], [["str_all", 3], ["add_card", "soot", 2]]]},

	# ---- Acto 3: Ceniza Helada ----------------------------------------------
	"frost_wraith": {"name": "Espectro de Escarcha", "hp": [48, 54], "shape": "wraith", "pattern": "cycle",
		"moves": [[["atk", 12, 1], ["add_card", "frost", 1]], [["weak_p", 2], ["block", 12]], [["atk", 7, 2]]]},
	"rime_hound": {"name": "Sabueso de Escarcha", "hp": [40, 44], "shape": "hound", "pattern": "random",
		"moves": [[["atk", 6, 3]], [["atk", 15, 1]], [["str", 3]]]},
	"glacial_monk": {"name": "Monje Glacial", "hp": [60, 66], "shape": "knight", "pattern": "cycle",
		"moves": [[["block_all", 14]], [["atk", 18, 1]], [["heal", 15], ["vuln_p", 2]]]},
	"frozen_titan": {"name": "Titán Congelado", "hp": [170, 180], "shape": "golem", "pattern": "cycle", "elite": true,
		"moves": [[["block", 30]], [["atk", 28, 1]], [["atk", 12, 2], ["add_card", "frost", 2]]]},
	"cold_heart": {"name": "El Corazón Frío", "hp": [520, 520], "shape": "boss_heart", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 14, 3]], [["add_card", "frost", 3], ["block", 40], ["str", 2]], [["atk", 45, 1]], [["weak_p", 3], ["vuln_p", 3], ["heal", 30]]]},
}

## Por acto: combates normales, élites, jefe.
const ACTS := [
	{"name": "Hollín", "normal": [["ash_slime", "ash_slime"], ["cinder_bat", "cinder_bat", "cinder_bat"], ["soot_golem"], ["ash_slime", "cinder_bat"], ["soot_golem", "cinder_bat"]],
		"easy": [["ash_slime"], ["cinder_bat", "cinder_bat"], ["ash_slime", "cinder_bat"]],
		"elite": [["hollow_knight"], ["smoke_witch"]], "boss": ["coalfather"]},
	{"name": "Escoria", "normal": [["slag_crawler", "brimstone_imp"], ["molten_eye", "molten_eye"], ["brimstone_imp", "brimstone_imp", "molten_eye"], ["slag_crawler", "molten_eye"]],
		"easy": [["slag_crawler"], ["brimstone_imp", "molten_eye"]],
		"elite": [["slag_warden", "brimstone_imp"], ["smoke_witch", "molten_eye"]], "boss": ["slag_queen"]},
	{"name": "Ceniza Helada", "normal": [["frost_wraith", "rime_hound"], ["glacial_monk", "rime_hound"], ["rime_hound", "rime_hound", "frost_wraith"], ["glacial_monk", "frost_wraith"]],
		"easy": [["frost_wraith"], ["rime_hound", "rime_hound"]],
		"elite": [["frozen_titan"], ["glacial_monk", "glacial_monk", "rime_hound"]], "boss": ["cold_heart"]},
]


static func act_index(floor_num: int) -> int:
	return int((floor_num - 1) / 10) % ACTS.size()


static func cycle(floor_num: int) -> int:
	return int((floor_num - 1) / (10 * ACTS.size()))


static func act_name(floor_num: int) -> String:
	var c := cycle(floor_num)
	var n: String = ACTS[act_index(floor_num)]["name"]
	return n if c == 0 else "%s · Ciclo %s" % [n, _roman(c + 1)]


static func _roman(n: int) -> String:
	var vals := [10, 9, 5, 4, 1]
	var syms := ["X", "IX", "V", "IV", "I"]
	var out := ""
	for i in vals.size():
		while n >= vals[i]:
			out += syms[i]
			n -= vals[i]
	return out


static func pick_encounter(kind: String, floor_num: int, rng: RandomNumberGenerator) -> Array:
	var act: Dictionary = ACTS[act_index(floor_num)]
	var pool: Array
	match kind:
		"elite": pool = act["elite"]
		"boss": return act["boss"].duplicate()
		_:
			pool = act["easy"] if (floor_num - 1) % 10 < 2 else act["normal"]
	return pool[rng.randi_range(0, pool.size() - 1)].duplicate()


static func make(id: String, floor_num: int, rng: RandomNumberGenerator) -> Fighter:
	var d: Dictionary = ENEMIES[id]
	var f := Fighter.new()
	var c := cycle(floor_num)
	var in_act := float((floor_num - 1) % 10)
	var hp_mult := (1.0 + 0.06 * in_act) * pow(2.6, c)
	f.dmg_mult = (1.0 + 0.03 * in_act) * pow(1.7, c)
	f.def_id = id
	f.display_name = d["name"]
	var hr: Array = d["hp"]
	f.max_hp = int(round(rng.randi_range(hr[0], hr[1]) * hp_mult))
	f.hp = f.max_hp
	f.moves = d["moves"]
	f.pattern = d["pattern"]
	f.shape = d["shape"]
	f.is_boss = d.get("boss", false)
	f.is_elite = d.get("elite", false)
	f.biome = act_index(floor_num)
	f.sprite_seed = "%s#%d" % [id, c]
	return f
