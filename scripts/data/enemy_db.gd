class_name EnemyDB
extends RefCounted
## Enemigos y encuentros. Movimientos:
##   ["atk", daño, veces] ["block", n] ["block_all", n] ["str", n] ["str_all", n] ["heal", n]
##   ["scorch_p", n] ["weak_p", n] ["vuln_p", n] ["add_card", id, n] ["heal_all", n]
##   ["steal", s]   roba Ascuas (s segundos de producción); si muere, las devuelve ×1.5
##   ["flee"]       si lleva botín, huye con él (sale del combate sin recompensa)
##   ["choke", n]   ahoga tu horno: −n Quemas el próximo turno
##   ["summon", id, n] invoca aliados · ["thorns", n] espinas · ["regen", n] regeneración
## Campos: on_death (ops al morir: ["dmg_p", n]), thorns y regen iniciales,
##   on_burn (ops cada vez que quemas), on_no_burn (ops al acabar tu turno si no has quemado).

## Afijos de ciclo: desde el ciclo II cada enemigo tiene 1 (élites y jefes 2 desde el ciclo III).
## Castigan o premian CÓMO quemas, no sólo si quemas.
const AFFIXES := {
	"fireproof": {"name": "Ignífugo", "desc": "Recibe la mitad de Quemadura; Detonar le hace la mitad."},
	"scavenger": {"name": "Carroñero", "desc": "Cada vez que quemas una carta, se cura un 3% de sus PV máximos."},
	"greedy": {"name": "Avaro", "desc": "Cada vez que quemas, roba 2 s de producción (devuelve ×1.5 al morir)."},
	"stifling": {"name": "Sofocante", "desc": "Al empezar el combate te ahoga: −1 Quema en tu primer turno."},
	"sticky": {"name": "Pegajoso", "desc": "Cada 2 turnos añade 1 Ceniza Húmeda a tu descarte."},
	"tempered": {"name": "Templado", "desc": "Empieza con Bloqueo igual al 15% de sus PV y 2 de Espinas."},
}

const ENEMIES := {
	# ---- Acto 1: Hollín -----------------------------------------------------
	"ash_slime": {"name": "Limo de Ceniza", "hp": [12, 16], "shape": "slime", "pattern": "random",
		"moves": [[["atk", 6, 1]], [["atk", 3, 1], ["weak_p", 1]], [["block", 5], ["str", 1]]]},
	"cinder_bat": {"name": "Murciélago Brasa", "hp": [8, 11], "shape": "bat", "pattern": "cycle",
		"moves": [[["atk", 3, 2]], [["atk", 4, 1], ["scorch_p", 2]]]},
	"soot_golem": {"name": "Gólem de Hollín", "hp": [28, 32], "shape": "golem", "pattern": "cycle",
		"moves": [[["block", 8], ["add_card", "soot", 2]], [["atk", 9, 1]], [["atk", 12, 1]]]},
	"ember_magpie": {"name": "Urraca Ígnea", "hp": [14, 17], "shape": "bird", "pattern": "cycle",
		"moves": [[["steal", 6]], [["atk", 5, 1], ["steal", 4]], [["flee"]]]},
	"candle_mite": {"name": "Ácaro de Vela", "hp": [6, 8], "shape": "mite", "pattern": "cycle",
		"on_death": [["dmg_p", 5]], "moves": [[["atk", 4, 1]], [["str", 2]]]},
	"flame_moth": {"name": "Polilla de Llama", "hp": [16, 20], "shape": "moth", "pattern": "cycle",
		"on_burn": [["str", 1]], "moves": [[["atk", 4, 2]], [["atk", 7, 1]], [["block", 6]]]},
	"hollow_knight": {"name": "Caballero Hueco", "hp": [44, 48], "shape": "knight", "pattern": "cycle", "elite": true,
		"moves": [[["str", 2], ["block", 10]], [["atk", 12, 1]], [["atk", 6, 2]]]},
	"smoke_witch": {"name": "Bruja de Humo", "hp": [38, 42], "shape": "wraith", "pattern": "cycle", "elite": true,
		"moves": [[["weak_p", 2], ["vuln_p", 2]], [["atk", 11, 1]], [["scorch_p", 5]], [["atk", 7, 1], ["add_card", "soot", 1]]]},
	"bellows_brute": {"name": "Bruto del Fuelle", "hp": [52, 56], "shape": "totem", "pattern": "cycle", "elite": true,
		"moves": [[["choke", 1], ["atk", 8, 1]], [["block", 12], ["str", 2]], [["atk", 15, 1]]]},
	"coalfather": {"name": "El Carbonero", "hp": [130, 130], "shape": "boss_king", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 7, 2]], [["add_card", "soot", 3], ["block", 15]], [["atk", 20, 1]], [["str", 3], ["heal", 10]]]},
	"great_bellows": {"name": "El Gran Fuelle", "hp": [120, 120], "shape": "boss_bellows", "pattern": "cycle", "boss": true,
		"moves": [[["summon", "candle_mite", 2]], [["choke", 1], ["atk", 10, 1]], [["atk", 5, 3]], [["block", 20], ["str", 2]]]},

	# ---- Acto 2: Escoria ----------------------------------------------------
	"slag_crawler": {"name": "Reptante de Escoria", "hp": [32, 36], "shape": "crawler", "pattern": "cycle",
		"moves": [[["atk", 10, 1]], [["block", 10], ["str", 2]], [["atk", 5, 2]]]},
	"molten_eye": {"name": "Ojo Fundido", "hp": [24, 28], "shape": "eye", "pattern": "cycle",
		"moves": [[["vuln_p", 2], ["atk", 6, 1]], [["atk", 14, 1]]]},
	"brimstone_imp": {"name": "Diablillo de Azufre", "hp": [20, 24], "shape": "imp", "pattern": "random",
		"moves": [[["atk", 5, 3]], [["scorch_p", 4]], [["atk", 8, 1], ["weak_p", 1]]]},
	"slag_serpent": {"name": "Sierpe de Escoria", "hp": [38, 42], "shape": "serpent", "pattern": "cycle", "thorns": 3,
		"moves": [[["atk", 9, 1]], [["thorns", 2], ["block", 8]], [["atk", 6, 2]]]},
	"ash_priest": {"name": "Sacerdote de Ceniza", "hp": [30, 34], "shape": "priest", "pattern": "cycle",
		"moves": [[["add_card", "wet_ash", 2], ["block_all", 8]], [["heal_all", 10]], [["atk", 12, 1]]]},
	"ash_glutton": {"name": "Devorador de Ceniza", "hp": [44, 48], "shape": "slime", "pattern": "cycle",
		"on_burn": [["heal", 5]], "moves": [[["atk", 11, 1]], [["add_card", "soot", 2], ["block", 8]], [["atk", 6, 2]]]},
	"rival_bellows": {"name": "Fuelle Rival", "hp": [110, 120], "shape": "totem", "pattern": "cycle", "elite": true,
		"on_no_burn": [["block", 12], ["str", 2]], "moves": [[["atk", 14, 1]], [["choke", 1], ["atk", 8, 2]], [["block", 15]]]},
	"slag_warden": {"name": "Guardián de Escoria", "hp": [95, 100], "shape": "golem", "pattern": "cycle", "elite": true,
		"moves": [[["block_all", 15], ["str_all", 2]], [["atk", 16, 1]], [["atk", 9, 2], ["vuln_p", 1]]]},
	"gilded_magpie": {"name": "Urraca Dorada", "hp": [70, 76], "shape": "bird", "pattern": "cycle", "elite": true,
		"moves": [[["steal", 15], ["block", 18]], [["atk", 8, 2], ["steal", 10]], [["flee"]]]},
	"slag_queen": {"name": "Reina Escoria", "hp": [280, 280], "shape": "boss_queen", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 10, 3]], [["scorch_p", 8], ["block", 25]], [["atk", 30, 1]], [["str_all", 3], ["add_card", "soot", 2]]]},
	"slag_hydra": {"name": "La Hidra de Escoria", "hp": [300, 300], "shape": "boss_hydra", "pattern": "cycle", "boss": true, "regen": 6,
		"moves": [[["atk", 7, 3]], [["thorns", 3], ["block", 20]], [["atk", 26, 1], ["add_card", "wet_ash", 1]], [["str", 3], ["regen", 3]]]},

	# ---- Acto 3: Ceniza Helada ----------------------------------------------
	"frost_wraith": {"name": "Espectro de Escarcha", "hp": [48, 54], "shape": "wraith", "pattern": "cycle",
		"moves": [[["atk", 12, 1], ["add_card", "frost", 1]], [["weak_p", 2], ["block", 12]], [["atk", 7, 2]]]},
	"rime_hound": {"name": "Sabueso de Escarcha", "hp": [40, 44], "shape": "hound", "pattern": "random",
		"moves": [[["atk", 6, 3]], [["atk", 15, 1]], [["str", 3]]]},
	"glacial_monk": {"name": "Monje Glacial", "hp": [60, 66], "shape": "knight", "pattern": "cycle",
		"moves": [[["block_all", 14]], [["atk", 18, 1]], [["heal", 15], ["vuln_p", 2]]]},
	"ice_moth": {"name": "Polilla de Hielo", "hp": [30, 34], "shape": "moth", "pattern": "cycle",
		"moves": [[["weak_p", 2], ["atk", 6, 1]], [["choke", 1], ["atk", 9, 1]], [["atk", 4, 3]]]},
	"frozen_titan": {"name": "Titán Congelado", "hp": [170, 180], "shape": "golem", "pattern": "cycle", "elite": true,
		"moves": [[["block", 30]], [["atk", 28, 1]], [["atk", 12, 2], ["add_card", "frost", 2]]]},
	"rime_knight": {"name": "Caballero de Escarcha", "hp": [150, 160], "shape": "knight", "pattern": "cycle", "elite": true, "thorns": 4,
		"moves": [[["block", 20], ["thorns", 2]], [["atk", 14, 2]], [["choke", 1], ["atk", 20, 1]]]},
	"cold_heart": {"name": "El Corazón Frío", "hp": [520, 520], "shape": "boss_heart", "pattern": "cycle", "boss": true,
		"moves": [[["atk", 14, 3]], [["add_card", "frost", 3], ["block", 40], ["str", 2]], [["atk", 45, 1]], [["weak_p", 3], ["vuln_p", 3], ["heal", 30]]]},
	"frost_king": {"name": "El Rey Escarcha", "hp": [480, 480], "shape": "boss_frost", "pattern": "cycle", "boss": true,
		"moves": [[["summon", "ice_moth", 1], ["block", 25]], [["choke", 2], ["atk", 18, 2]], [["add_card", "wet_ash", 2], ["atk", 30, 1]], [["str_all", 3], ["heal", 25]]]},
}

## Por acto: combates normales, élites, jefes (uno al azar).
const ACTS := [
	{"name": "Hollín", "normal": [["ash_slime", "ash_slime"], ["cinder_bat", "cinder_bat", "cinder_bat"], ["soot_golem"], ["ash_slime", "cinder_bat"],
			["soot_golem", "cinder_bat"], ["ember_magpie", "ash_slime"], ["candle_mite", "candle_mite", "candle_mite"], ["ember_magpie", "candle_mite"], ["flame_moth", "flame_moth"], ["flame_moth", "ash_slime"]],
		"easy": [["ash_slime"], ["cinder_bat", "cinder_bat"], ["ash_slime", "cinder_bat"], ["candle_mite", "candle_mite"], ["ember_magpie"]],
		"elite": [["hollow_knight"], ["smoke_witch"], ["bellows_brute"]], "boss": [["coalfather"], ["great_bellows"]]},
	{"name": "Escoria", "normal": [["slag_crawler", "brimstone_imp"], ["molten_eye", "molten_eye"], ["brimstone_imp", "brimstone_imp", "molten_eye"],
			["slag_crawler", "molten_eye"], ["slag_serpent", "brimstone_imp"], ["ash_priest", "slag_crawler"], ["ash_priest", "molten_eye", "brimstone_imp"], ["ash_glutton", "molten_eye"]],
		"easy": [["slag_crawler"], ["brimstone_imp", "molten_eye"], ["slag_serpent"]],
		"elite": [["slag_warden", "brimstone_imp"], ["smoke_witch", "molten_eye"], ["gilded_magpie", "ash_priest"], ["rival_bellows", "brimstone_imp"]], "boss": [["slag_queen"], ["slag_hydra"]]},
	{"name": "Ceniza Helada", "normal": [["frost_wraith", "rime_hound"], ["glacial_monk", "rime_hound"], ["rime_hound", "rime_hound", "frost_wraith"],
			["glacial_monk", "frost_wraith"], ["ice_moth", "ice_moth", "rime_hound"], ["ice_moth", "glacial_monk"]],
		"easy": [["frost_wraith"], ["rime_hound", "rime_hound"], ["ice_moth", "ice_moth"]],
		"elite": [["frozen_titan"], ["glacial_monk", "glacial_monk", "rime_hound"], ["rime_knight", "ice_moth"]], "boss": [["cold_heart"], ["frost_king"]]},
]


## Cada vuelta completa a la Torre (30 pisos) multiplica PV y daño. El salto debe superar la diferencia
## entre el acto 3 y el acto 1 (~×4) para que la dificultad nunca retroceda al empezar un ciclo.
const HP_PER_CYCLE := 4.0
const DMG_PER_CYCLE := 2.0


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
		"boss":
			var bosses: Array = act["boss"]
			return bosses[rng.randi_range(0, bosses.size() - 1)].duplicate()
		_:
			pool = act["easy"] if (floor_num - 1) % 10 < 2 else act["normal"]
	return pool[rng.randi_range(0, pool.size() - 1)].duplicate()


static func make(id: String, floor_num: int, rng: RandomNumberGenerator) -> Fighter:
	var d: Dictionary = ENEMIES[id]
	var f := Fighter.new()
	var c := cycle(floor_num)
	var in_act := float((floor_num - 1) % 10)
	var hp_mult := (1.0 + 0.08 * in_act) * pow(HP_PER_CYCLE, c)
	f.dmg_mult = (1.0 + 0.04 * in_act) * pow(DMG_PER_CYCLE, c)
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
	f.on_death = d.get("on_death", [])
	f.on_burn = d.get("on_burn", [])
	f.on_no_burn = d.get("on_no_burn", [])
	if c >= 1:
		var keys := AFFIXES.keys()
		var ar := RandomNumberGenerator.new()
		ar.seed = hash("%s#%d#%d" % [id, c, rng.randi()])
		var n := 2 if c >= 2 and (f.is_elite or f.is_boss) else 1
		for i in n:
			var k: String = keys[ar.randi_range(0, keys.size() - 1)]
			if not f.affixes.has(k):
				f.affixes.append(k)
		f.display_name = "%s %s" % [f.display_name, AFFIXES[f.affixes[0]]["name"]]
		if f.affixes.has("tempered"):
			f.block = int(f.max_hp * 0.15)
			f.add_status("thorns", 2)
	if d.has("thorns"):
		f.add_status("thorns", int(d["thorns"]))
	if d.has("regen"):
		f.add_status("regen", int(d["regen"]))
	return f
