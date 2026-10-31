class_name CardDB
extends RefCounted
## Tabla de cartas. Diseño edita aquí; la lógica vive en CombatEngine.
##
## Campos:
##   type: attack | skill | power | fuel | status
##   cost: -1 = X (gasta toda la energía)
##   target: true si requiere elegir enemigo
##   fx / up:            operaciones al jugar (base / mejorada)
##   burn / up_burn:     operaciones al quemar
##   pack: base | pyre | anvil | ash | solar | status
##   rarity: starter | common | uncommon | rare

const CARDS := {
	# --- Inicial -------------------------------------------------------------
	"strike": {"name": "Golpe", "type": "attack", "cost": 1, "target": true, "icon": "sword",
		"rarity": "starter", "pack": "base", "fx": [["dmg", 6]], "up": [["dmg", 9]]},
	"defend": {"name": "Defensa", "type": "skill", "cost": 1, "icon": "shield",
		"rarity": "starter", "pack": "base", "fx": [["block", 5]], "up": [["block", 8]]},
	"kindling": {"name": "Leña", "type": "fuel", "cost": 0, "icon": "log",
		"rarity": "starter", "pack": "base", "burn": [["energy", 1], ["draw", 1]], "up_burn": [["energy", 2], ["draw", 1]]},
	"ember_slash": {"name": "Tajo Ígneo", "type": "attack", "cost": 1, "target": true, "icon": "flame_sword",
		"rarity": "starter", "pack": "base", "fx": [["dmg", 6], ["scorch", 2]], "up": [["dmg", 8], ["scorch", 3]]},

	# --- Base ----------------------------------------------------------------
	"heavy_hammer": {"name": "Martillazo", "type": "attack", "cost": 2, "target": true, "icon": "hammer",
		"rarity": "common", "pack": "base", "fx": [["dmg", 14], ["vuln", 1]], "up": [["dmg", 18], ["vuln", 2]]},
	"sparks": {"name": "Lluvia de Chispas", "type": "attack", "cost": 1, "icon": "sparks",
		"rarity": "common", "pack": "base", "fx": [["dmg_rand", 3, 3]], "up": [["dmg_rand", 3, 4]]},
	"cleave": {"name": "Barrido", "type": "attack", "cost": 1, "icon": "sword",
		"rarity": "common", "pack": "base", "fx": [["dmg_all", 8]], "up": [["dmg_all", 11]]},
	"iron_wall": {"name": "Muro de Hierro", "type": "skill", "cost": 2, "icon": "shield",
		"rarity": "common", "pack": "base", "fx": [["block", 13]], "up": [["block", 17]]},
	"quench": {"name": "Enfriar", "type": "skill", "cost": 1, "icon": "drop",
		"rarity": "common", "pack": "base", "fx": [["block", 6], ["draw", 1]], "up": [["block", 8], ["draw", 2]]},
	"bellows": {"name": "Fuelle", "type": "skill", "cost": 0, "icon": "wind", "exhaust": true,
		"rarity": "common", "pack": "base", "fx": [["draw", 2]], "up": [["draw", 3]]},
	"stoke": {"name": "Avivar", "type": "skill", "cost": 0, "icon": "flame", "exhaust": true,
		"rarity": "uncommon", "pack": "base", "fx": [["energy", 1]], "up": [["energy", 1], ["draw", 1]],
		"burn": [["energy", 2]], "up_burn": [["energy", 2], ["draw", 1]]},
	"coal": {"name": "Carbón", "type": "fuel", "cost": 1, "icon": "coal",
		"rarity": "common", "pack": "base", "burn": [["ember_mult", 3], ["block", 4]], "up_burn": [["ember_mult", 4], ["block", 7]]},
	"smother": {"name": "Sofocar", "type": "skill", "cost": 1, "target": true, "icon": "smoke",
		"rarity": "common", "pack": "base", "fx": [["weak", 2], ["block", 4]], "up": [["weak", 3], ["block", 6]]},
	"forge_heart": {"name": "Corazón de Forja", "type": "power", "cost": 1, "icon": "heart_gear",
		"rarity": "uncommon", "pack": "base", "fx": [["power", "forge_block", 3]], "up": [["power", "forge_block", 5]]},
	"temper_steel": {"name": "Templar el Acero", "type": "power", "cost": 1, "icon": "anvil",
		"rarity": "uncommon", "pack": "base", "fx": [["str", 2]], "up": [["str", 3]]},
	"slag_shot": {"name": "Escupir Escoria", "type": "attack", "cost": 1, "target": true, "icon": "sparks",
		"rarity": "common", "pack": "base", "fx": [["dmg", 4], ["vuln", 2]], "up": [["dmg", 6], ["vuln", 3]]},
	"body_slam": {"name": "Embestida Blindada", "type": "attack", "cost": 1, "up_cost": 0, "target": true, "icon": "shield",
		"rarity": "uncommon", "pack": "base", "fx": [["block_dmg"]], "up": [["block_dmg"]]},
	"second_wind": {"name": "Segundo Aliento", "type": "skill", "cost": 1, "icon": "heart", "exhaust": true,
		"rarity": "uncommon", "pack": "base", "fx": [["heal", 5]], "up": [["heal", 8]]},

	# --- Grimorio de la Pira (quemar) ----------------------------------------
	"inner_fire": {"name": "Fuego Interior", "type": "power", "cost": 1, "icon": "flame",
		"rarity": "uncommon", "pack": "pyre", "fx": [["power", "inner_fire", 4]], "up": [["power", "inner_fire", 6]]},
	"ash_armor": {"name": "Armadura de Ceniza", "type": "power", "cost": 1, "icon": "shield",
		"rarity": "uncommon", "pack": "pyre", "fx": [["power", "ash_armor", 4]], "up": [["power", "ash_armor", 6]]},
	"gunpowder": {"name": "Pólvora", "type": "fuel", "cost": 1, "icon": "bomb",
		"rarity": "common", "pack": "pyre", "burn": [["dmg_all", 10]], "up_burn": [["dmg_all", 15]]},
	"pyre_dance": {"name": "Danza de la Pira", "type": "attack", "cost": 1, "target": true, "icon": "flame_sword",
		"rarity": "uncommon", "pack": "pyre", "fx": [["dmg_per_burned", 4, 4]], "up": [["dmg_per_burned", 6, 6]]},
	"open_flue": {"name": "Tiro Abierto", "type": "skill", "cost": 0, "icon": "wind", "exhaust": true,
		"rarity": "common", "pack": "pyre", "fx": [["burn_charge", 2], ["draw", 1]], "up": [["burn_charge", 2], ["draw", 2]]},
	"phoenix_feather": {"name": "Pluma de Fénix", "type": "fuel", "cost": 1, "icon": "feather",
		"rarity": "rare", "pack": "pyre", "burn": [["heal", 5], ["str", 1]], "up_burn": [["heal", 8], ["str", 2]]},
	"rake_coals": {"name": "Atizar", "type": "skill", "cost": 1, "icon": "flame",
		"rarity": "common", "pack": "pyre", "fx": [["draw", 3], ["burn_charge", 1]], "up": [["draw", 4], ["burn_charge", 1]]},

	# --- Grimorio del Yunque (fuerza y bloqueo) ------------------------------
	"anvil_stance": {"name": "Postura de Yunque", "type": "power", "cost": 2, "up_cost": 1, "icon": "anvil",
		"rarity": "rare", "pack": "anvil", "fx": [["power", "temper", 1]], "up": [["power", "temper", 1]]},
	"hammer_flurry": {"name": "Ráfaga de Martillo", "type": "attack", "cost": 1, "target": true, "icon": "hammer",
		"rarity": "common", "pack": "anvil", "fx": [["dmg_x", 4, 3]], "up": [["dmg_x", 5, 3]]},
	"double_shield": {"name": "Redoblar Escudo", "type": "skill", "cost": 1, "up_cost": 0, "icon": "shield",
		"rarity": "uncommon", "pack": "anvil", "fx": [["double_block"]], "up": [["double_block"]]},
	"counterweight": {"name": "Contrapeso", "type": "skill", "cost": 1, "icon": "anvil",
		"rarity": "common", "pack": "anvil", "fx": [["block", 7], ["str", 1]], "up": [["block", 10], ["str", 1]]},
	"molten_core": {"name": "Núcleo Fundido", "type": "attack", "cost": -1, "target": true, "icon": "orb",
		"rarity": "rare", "pack": "anvil", "fx": [["dmg_xcost", 9]], "up": [["dmg_xcost", 12]]},

	# --- Grimorio de la Ceniza (quemadura) -----------------------------------
	"salamander": {"name": "Salamandra", "type": "power", "cost": 1, "icon": "lizard",
		"rarity": "uncommon", "pack": "ash", "fx": [["power", "salamander", 1]], "up": [["power", "salamander", 2]]},
	"wildfire": {"name": "Incendio", "type": "attack", "cost": 1, "icon": "flame",
		"rarity": "common", "pack": "ash", "fx": [["scorch_all", 4]], "up": [["scorch_all", 6]]},
	"detonate": {"name": "Detonar", "type": "attack", "cost": 1, "target": true, "icon": "bomb",
		"rarity": "uncommon", "pack": "ash", "fx": [["detonate", 2]], "up": [["detonate", 3]]},
	"cinder_breath": {"name": "Aliento de Brasas", "type": "attack", "cost": 2, "icon": "smoke",
		"rarity": "common", "pack": "ash", "fx": [["dmg_all", 6], ["scorch_all", 3]], "up": [["dmg_all", 8], ["scorch_all", 4]]},
	"smoke_veil": {"name": "Velo de Humo", "type": "skill", "cost": 1, "icon": "smoke",
		"rarity": "common", "pack": "ash", "fx": [["block", 7], ["weak_all", 1]], "up": [["block", 10], ["weak_all", 2]]},

	# --- Grimorio Solar (raras) ----------------------------------------------
	"supernova": {"name": "Supernova", "type": "attack", "cost": 3, "icon": "sun", "exhaust": true,
		"rarity": "rare", "pack": "solar", "fx": [["dmg_all", 30]], "up": [["dmg_all", 42]]},
	"dwarf_star": {"name": "Estrella Enana", "type": "power", "cost": 3, "up_cost": 2, "icon": "sun",
		"rarity": "rare", "pack": "solar", "fx": [["power", "solar", 1]], "up": [["power", "solar", 1]]},
	"sunforge": {"name": "Forja Solar", "type": "skill", "cost": 1, "icon": "anvil",
		"rarity": "uncommon", "pack": "solar", "fx": [["block", 4], ["block_per_burned", 3]], "up": [["block", 6], ["block_per_burned", 4]]},
	"ember_rain": {"name": "Lluvia de Ascuas", "type": "fuel", "cost": 2, "icon": "sparks",
		"rarity": "rare", "pack": "solar", "burn": [["dmg_rand", 6, 4]], "up_burn": [["dmg_rand", 6, 6]]},

	# --- Estados (los añaden los enemigos) -----------------------------------
	"soot": {"name": "Hollín", "type": "status", "cost": 0, "icon": "smoke",
		"rarity": "status", "pack": "status", "burn": [["ember_mult", 1]]},
	"frost": {"name": "Escarcha", "type": "status", "cost": 1, "icon": "drop", "exhaust": true,
		"rarity": "status", "pack": "status", "fx": [], "playable_status": true},
}

const STARTER_DECK: Array[String] = [
	"strike", "strike", "strike", "strike", "ember_slash",
	"defend", "defend", "defend", "defend", "kindling",
]

const POWERS := {
	"forge_block": "Al inicio de tu turno, gana %d de Bloqueo.",
	"inner_fire": "Cuando quemes una carta, inflige %d de daño a TODOS.",
	"ash_armor": "Cuando quemes una carta, gana %d de Bloqueo.",
	"temper": "Al inicio de tu turno, gana %d de Fuerza.",
	"salamander": "Cuando apliques Quemadura, aplica %d más.",
	"solar": "Al inicio de tu turno, gana %d de Energía.",
}

const TYPE_NAMES := {"attack": "Ataque", "skill": "Habilidad", "power": "Poder", "fuel": "Combustible", "status": "Estado"}

const C_NUM := "#ffd36a"
const C_KEY := "#ff9a4a"


static func get_def(id: String) -> Dictionary:
	return CARDS.get(id, CARDS["strike"])


static func ids_in_packs(packs: Array, rarity := "") -> Array[String]:
	var out: Array[String] = []
	for id: String in CARDS:
		var d: Dictionary = CARDS[id]
		if d["rarity"] in ["starter", "status"]:
			continue
		if not packs.has(d["pack"]):
			continue
		if rarity != "" and d["rarity"] != rarity:
			continue
		out.append(id)
	return out


## Texto BBCode de una carta. `engine` (opcional) ajusta el daño mostrado con Fuerza/Débil.
static func describe(card: Card, engine: Object = null) -> String:
	var parts: PackedStringArray = []
	var d := card.def()
	if d["type"] == "fuel":
		parts.append("[color=%s]Combustible.[/color]" % C_KEY)
	elif d["type"] == "status" and not d.get("playable_status", false):
		parts.append("[color=%s]Injugable.[/color]" % C_KEY)
	for op: Array in card.effects():
		parts.append(_op_text(op, engine, false))
	var burn_ops := card.burn_effects()
	if not burn_ops.is_empty():
		var bt: PackedStringArray = []
		for op: Array in burn_ops:
			bt.append(_op_text(op, engine, true))
		parts.append("[color=%s]Al quemar:[/color] %s" % [C_KEY, " ".join(bt)])
	if d.get("exhaust", false):
		parts.append("[color=%s]Agotar.[/color]" % C_KEY)
	return "\n".join(parts)


static func _n(v: int) -> String:
	return "[color=%s]%d[/color]" % [C_NUM, v]


static func _dmg(base: int, engine: Object) -> String:
	if engine != null and engine.has_method("preview_damage"):
		var v: int = engine.preview_damage(base)
		if v > base:
			return "[color=#7dff7d]%d[/color]" % v
		if v < base:
			return "[color=#ff7d7d]%d[/color]" % v
	return _n(base)


static func _op_text(op: Array, engine: Object, _burn: bool) -> String:
	var k: String = op[0]
	match k:
		"dmg": return "Inflige %s de daño." % _dmg(op[1], engine)
		"dmg_x": return "Inflige %s de daño %s veces." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_all": return "Inflige %s de daño a TODOS." % _dmg(op[1], engine)
		"dmg_rand": return "Inflige %s de daño a un enemigo al azar %s veces." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_xcost": return "Inflige %s de daño X veces." % _dmg(op[1], engine)
		"dmg_per_burned": return "Inflige %s de daño, +%s por carta quemada este combate." % [_dmg(op[1], engine), _n(op[2])]
		"block": return "Gana %s de Bloqueo." % _n(op[1])
		"block_per_burned": return "Gana %s de Bloqueo por carta quemada." % _n(op[1])
		"double_block": return "Duplica tu Bloqueo."
		"block_dmg": return "Inflige daño igual a tu Bloqueo."
		"draw": return "Roba %s carta%s." % [_n(op[1]), "" if op[1] == 1 else "s"]
		"energy": return "Gana %s de Energía." % _n(op[1])
		"scorch": return "Aplica %s de Quemadura." % _n(op[1])
		"scorch_all": return "Aplica %s de Quemadura a TODOS." % _n(op[1])
		"vuln": return "Aplica %s de Vulnerable." % _n(op[1])
		"weak": return "Aplica %s de Débil." % _n(op[1])
		"weak_all": return "Aplica %s de Débil a TODOS." % _n(op[1])
		"str": return "Gana %s de Fuerza." % _n(op[1])
		"heal": return "Cura %s PV." % _n(op[1])
		"detonate": return "Inflige la Quemadura del objetivo ×%s como daño." % _n(op[1])
		"burn_charge": return "Gana %s Quema%s extra este turno." % [_n(op[1]), "" if op[1] == 1 else "s"]
		"ember_mult": return "Produce ×%s Ascuas." % _n(op[1])
		"power":
			var txt: String = POWERS.get(op[1], "%d")
			return txt.replace("%d", _n(op[2]))
	return ""
