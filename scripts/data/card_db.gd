class_name CardDB
extends RefCounted
## Tabla de cartas. Diseño edita aquí; la lógica vive en CombatEngine.
##
## Campos:
##   short: nombre corto de presentación, sólo para el título de la carta cuando el completo no cabe ni en Mini ×2
##          (DECISIONES «Títulos de carta», F2-ILUS4). El nombre completo (`name`) sigue en datos, tooltips, tienda y compendio.
##   type: attack | skill | power | fuel | status
##   cost: -1 = X (gasta toda la energía)
##   target: true si requiere elegir enemigo
##   fx / up:            operaciones al jugar (base / mejorada)
##   burn / up_burn:     operaciones al quemar
##   pack: base | pyre | anvil | ash | solar | forge | crucible | status | token
##   rarity: starter | common | uncommon | rare | status | token
##   Palabras clave: exhaust (Agotar), retain (Brasa: se queda en la mano), innate (Innata: empieza en la mano),
##                   ethereal (Etérea: se agota si sigue en la mano al acabar el turno), unburnable (no se puede quemar)

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
	"cleave": {"name": "Barrido", "type": "attack", "cost": 1, "icon": "axe",
		"rarity": "common", "pack": "base", "fx": [["dmg_all", 8]], "up": [["dmg_all", 11]]},
	"iron_wall": {"name": "Muro de Hierro", "type": "skill", "cost": 2, "icon": "wall",
		"rarity": "common", "pack": "base", "fx": [["block", 16]], "up": [["block", 21]]},
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
	"temper_steel": {"name": "Templar el Acero", "short": "Templar Acero", "type": "power", "cost": 1, "icon": "anvil",
		"rarity": "uncommon", "pack": "base", "fx": [["str", 2]], "up": [["str", 3]]},
	"slag_shot": {"name": "Escupir Escoria", "type": "attack", "cost": 1, "target": true, "icon": "slag",
		"rarity": "common", "pack": "base", "fx": [["dmg", 4], ["vuln", 2]], "up": [["dmg", 6], ["vuln", 3]]},
	"body_slam": {"name": "Embestida Blindada", "short": "Embestida", "type": "attack", "cost": 1, "up_cost": 0, "target": true, "icon": "shield_bash",
		"rarity": "uncommon", "pack": "base", "fx": [["block_dmg"]], "up": [["block_dmg"]]},
	"second_wind": {"name": "Segundo Aliento", "type": "skill", "cost": 1, "icon": "heart", "exhaust": true,
		"rarity": "uncommon", "pack": "base", "fx": [["heal", 5]], "up": [["heal", 8]]},
	"twin_strike": {"name": "Doble Tajo", "type": "attack", "cost": 1, "target": true, "icon": "twin_swords",
		"rarity": "common", "pack": "base", "fx": [["dmg_x", 5, 2]], "up": [["dmg_x", 7, 2]]},
	"shield_bash": {"name": "Golpe de Escudo", "type": "attack", "cost": 1, "target": true, "icon": "shield_bash",
		"rarity": "common", "pack": "base", "fx": [["dmg", 5], ["block", 5]], "up": [["dmg", 7], ["block", 7]]},
	"ember_guard": {"name": "Guardia de Ascuas", "short": "Guardia Ígnea", "type": "skill", "cost": 1, "icon": "shield",
		"rarity": "common", "pack": "base", "fx": [["block", 8]], "up": [["block", 11]],
		"burn": [["block", 8]], "up_burn": [["block", 11]]},
	"fan_flames": {"name": "Abanicar", "type": "skill", "cost": 1, "icon": "fan",
		"rarity": "common", "pack": "base", "fx": [["burn_charge", 1], ["block", 6]], "up": [["burn_charge", 1], ["block", 9]]},
	"spitfire": {"name": "Escupefuego", "type": "attack", "cost": 0, "target": true, "icon": "flame",
		"rarity": "common", "pack": "base", "fx": [["dmg", 4]], "up": [["dmg", 6]],
		"burn": [["dmg_all", 4]], "up_burn": [["dmg_all", 6]]},
	"searing_blow": {"name": "Golpe Abrasador", "type": "attack", "cost": 2, "target": true, "icon": "hammer",
		"rarity": "uncommon", "pack": "base", "fx": [["dmg", 12], ["scorch", 4]], "up": [["dmg", 16], ["scorch", 6]]},
	"brace": {"name": "Apuntalar", "type": "skill", "cost": 1, "icon": "wall",
		"rarity": "uncommon", "pack": "base", "fx": [["block", 6], ["energy_next", 1]], "up": [["block", 9], ["energy_next", 1]]},
	"fire_wall": {"name": "Muro de Fuego", "type": "skill", "cost": 2, "icon": "fire_wall",
		"rarity": "uncommon", "pack": "base", "fx": [["block", 12], ["scorch_all", 2]], "up": [["block", 15], ["scorch_all", 3]]},
	"smelt": {"name": "Fundir", "type": "skill", "cost": 1, "icon": "crucible",
		"rarity": "uncommon", "pack": "base", "fx": [["free_hot", 1], ["draw", 1]], "up": [["free_hot", 1], ["draw", 2]]},
	"rally": {"name": "Cántico de Forja", "type": "power", "cost": 1, "icon": "bell",
		"rarity": "uncommon", "pack": "base", "fx": [["power", "rhythm", 2]], "up": [["power", "rhythm", 3]]},
	"fireborn": {"name": "Hija del Fuego", "type": "power", "cost": 2, "up_cost": 1, "icon": "phoenix",
		"rarity": "rare", "pack": "base", "fx": [["power", "flame_brand", 1]], "up": [["power", "flame_brand", 1]]},
	"anvil_drop": {"name": "Caída del Yunque", "type": "attack", "cost": 2, "target": true, "icon": "anvil",
		"rarity": "uncommon", "pack": "base", "fx": [["dmg", 20]], "up": [["dmg", 27]]},

	# --- Grimorio de la Pira (quemar) ----------------------------------------
	"inner_fire": {"name": "Fuego Interior", "type": "power", "cost": 1, "icon": "flame",
		"rarity": "uncommon", "pack": "pyre", "fx": [["power", "inner_fire", 4]], "up": [["power", "inner_fire", 6]]},
	"ash_armor": {"name": "Armadura de Ceniza", "short": "Cota de Ceniza", "type": "power", "cost": 1, "icon": "armor",
		"rarity": "uncommon", "pack": "pyre", "fx": [["power", "ash_armor", 4]], "up": [["power", "ash_armor", 6]]},
	"gunpowder": {"name": "Pólvora", "type": "fuel", "cost": 1, "icon": "bomb",
		"rarity": "common", "pack": "pyre", "burn": [["dmg_all", 10]], "up_burn": [["dmg_all", 15]]},
	"pyre_dance": {"name": "Danza de la Pira", "type": "attack", "cost": 1, "target": true, "icon": "flame_sword",
		"rarity": "uncommon", "pack": "pyre", "fx": [["dmg_per_burned", 4, 4]], "up": [["dmg_per_burned", 6, 6]]},
	"open_flue": {"name": "Tiro Abierto", "type": "skill", "cost": 0, "icon": "wind", "exhaust": true,
		"rarity": "common", "pack": "pyre", "fx": [["burn_charge", 2], ["draw", 1]], "up": [["burn_charge", 2], ["draw", 2]]},
	"phoenix_feather": {"name": "Pluma de Fénix", "type": "fuel", "cost": 1, "icon": "feather",
		"rarity": "rare", "pack": "pyre", "burn": [["heal", 5], ["str", 1]], "up_burn": [["heal", 8], ["str", 2]]},
	"rake_coals": {"name": "Atizar", "type": "skill", "cost": 0, "icon": "poker",
		"rarity": "common", "pack": "pyre", "fx": [["draw", 3], ["burn_charge", 1]], "up": [["draw", 4], ["burn_charge", 1]]},
	"kiln": {"name": "Horno de Tiro", "type": "power", "cost": 1, "up_cost": 0, "icon": "furnace",
		"rarity": "uncommon", "pack": "pyre", "fx": [["burn_charge", 1], ["power", "kiln", 1]], "up": [["burn_charge", 1], ["power", "kiln", 1]]},
	"bonfire": {"name": "Hoguera Viva", "type": "fuel", "cost": 1, "icon": "bonfire",
		"rarity": "common", "pack": "pyre", "burn": [["block", 8], ["dmg_all", 4]], "up_burn": [["block", 12], ["dmg_all", 6]]},
	"phoenix_paper": {"name": "Fénix de Papel", "type": "skill", "cost": 1, "icon": "phoenix", "exhaust": true,
		"rarity": "uncommon", "pack": "pyre", "fx": [["recall", 1]], "up": [["recall", 2]]},
	"pyroclasm": {"name": "Piroclasto", "type": "attack", "cost": 2, "icon": "volcano",
		"rarity": "rare", "pack": "pyre", "fx": [["dmg_all_per_burned", 6, 3]], "up": [["dmg_all_per_burned", 8, 4]]},
	"stoke_rage": {"name": "Atizar la Furia", "type": "skill", "cost": 0, "icon": "blood_flame",
		"rarity": "common", "pack": "pyre", "fx": [["lose_hp", 3], ["burn_charge", 2]], "up": [["lose_hp", 2], ["burn_charge", 2], ["draw", 1]]},
	"ash_feast": {"name": "Banquete de Ceniza", "short": "Festín de Hollín", "type": "skill", "cost": 1, "icon": "goblet", "exhaust": true,
		"rarity": "rare", "pack": "pyre", "fx": [["heal_per_burned", 2]], "up": [["heal_per_burned", 3]]},
	"forge_lung": {"name": "Pulmón de Forja", "type": "power", "cost": 2, "up_cost": 1, "icon": "lung",
		"rarity": "rare", "pack": "pyre", "fx": [["power", "bellows_pw", 1]], "up": [["power", "bellows_pw", 1]]},
	"tinder_box": {"name": "Caja de Yesca", "type": "skill", "cost": 1, "icon": "box",
		"rarity": "common", "pack": "pyre", "fx": [["add_hand", "spark_card", 2]], "up": [["add_hand", "spark_card", 3]]},
	"cinder_storm": {"name": "Tormenta de Cisco", "short": "Racha de Cisco", "type": "fuel", "cost": 2, "icon": "sparks",
		"rarity": "uncommon", "pack": "pyre", "burn": [["dmg_rand", 5, 3], ["scorch_all", 2]], "up_burn": [["dmg_rand", 5, 4], ["scorch_all", 3]]},

	# --- Grimorio del Yunque (fuerza y bloqueo) ------------------------------
	"anvil_stance": {"name": "Postura de Yunque", "short": "Pose de Yunque", "type": "power", "cost": 2, "up_cost": 1, "icon": "anvil",
		"rarity": "rare", "pack": "anvil", "fx": [["power", "temper", 1]], "up": [["power", "temper", 1]]},
	"hammer_flurry": {"name": "Ráfaga de Martillo", "short": "Martilleo", "type": "attack", "cost": 1, "target": true, "icon": "hammer",
		"rarity": "common", "pack": "anvil", "fx": [["dmg_x", 4, 3]], "up": [["dmg_x", 5, 4]]},
	"double_shield": {"name": "Redoblar Escudo", "type": "skill", "cost": 1, "up_cost": 0, "icon": "twin_shields",
		"rarity": "uncommon", "pack": "anvil", "fx": [["double_block"]], "up": [["double_block"]]},
	"counterweight": {"name": "Contrapeso", "type": "skill", "cost": 1, "icon": "weight",
		"rarity": "common", "pack": "anvil", "fx": [["block", 7], ["str", 1]], "up": [["block", 10], ["str", 1]]},
	"molten_core": {"name": "Núcleo Fundido", "type": "attack", "cost": -1, "target": true, "icon": "orb",
		"rarity": "rare", "pack": "anvil", "fx": [["dmg_xcost", 9]], "up": [["dmg_xcost", 12]]},
	"heavy_blade": {"name": "Mandoble", "type": "attack", "cost": 2, "target": true, "icon": "greatsword",
		"rarity": "uncommon", "pack": "anvil", "fx": [["dmg_strmult", 14, 3]], "up": [["dmg_strmult", 18, 5]]},
	"iron_skin": {"name": "Piel de Hierro", "type": "power", "cost": 1, "icon": "armor",
		"rarity": "uncommon", "pack": "anvil", "fx": [["power", "slag_skin", 4]], "up": [["power", "slag_skin", 6]]},
	"spiked_shield": {"name": "Escudo de Púas", "type": "power", "cost": 1, "icon": "spikes",
		"rarity": "uncommon", "pack": "anvil", "fx": [["power", "thorns", 3]], "up": [["power", "thorns", 5]]},
	"parry": {"name": "Desviar", "type": "skill", "cost": 1, "target": true, "icon": "parry",
		"rarity": "common", "pack": "anvil", "fx": [["block", 5], ["vuln", 1]], "up": [["block", 8], ["vuln", 2]]},
	"sledge": {"name": "Mazazo", "type": "attack", "cost": 3, "target": true, "icon": "sledge",
		"rarity": "uncommon", "pack": "anvil", "fx": [["dmg", 24], ["weak", 2]], "up": [["dmg", 32], ["weak", 3]]},
	"unbreakable": {"name": "Inquebrantable", "type": "skill", "cost": 2, "icon": "fortress", "exhaust": true,
		"rarity": "rare", "pack": "anvil", "fx": [["block", 30]], "up": [["block", 40]]},
	"anvil_ward": {"name": "Guarda del Yunque", "short": "Yunque Guardián", "type": "skill", "cost": 1, "icon": "shield", "retain": true,
		"rarity": "common", "pack": "anvil", "fx": [["block", 9]], "up": [["block", 13]]},

	# --- Grimorio de la Ceniza (quemadura) -----------------------------------
	"salamander": {"name": "Salamandra", "type": "power", "cost": 1, "icon": "lizard",
		"rarity": "uncommon", "pack": "ash", "fx": [["power", "salamander", 1]], "up": [["power", "salamander", 2]]},
	"wildfire": {"name": "Incendio", "type": "attack", "cost": 1, "icon": "fire_wall",
		"rarity": "common", "pack": "ash", "fx": [["scorch_all", 3]], "up": [["scorch_all", 5]]},
	"detonate": {"name": "Detonar", "type": "attack", "cost": 1, "target": true, "icon": "bomb",
		"rarity": "uncommon", "pack": "ash", "fx": [["scorch", 3], ["detonate", 2]], "up": [["scorch", 4], ["detonate", 3]]},
	"cinder_breath": {"name": "Aliento de Brasas", "short": "Vaho de Brasas", "type": "attack", "cost": 2, "icon": "breath",
		"rarity": "common", "pack": "ash", "fx": [["dmg_all", 6], ["scorch_all", 3]], "up": [["dmg_all", 8], ["scorch_all", 4]]},
	"smoke_veil": {"name": "Velo de Humo", "type": "skill", "cost": 1, "icon": "smoke",
		"rarity": "common", "pack": "ash", "fx": [["block", 7], ["weak_all", 1]], "up": [["block", 10], ["weak_all", 2]]},
	"kindle_brand": {"name": "Marca Ígnea", "type": "attack", "cost": 1, "target": true, "icon": "brand",
		"rarity": "common", "pack": "ash", "fx": [["dmg", 5], ["scorch", 3]], "up": [["dmg", 7], ["scorch", 4]]},
	"conflagration": {"name": "Conflagración", "type": "skill", "cost": 1, "up_cost": 0, "target": true, "icon": "volcano",
		"rarity": "uncommon", "pack": "ash", "fx": [["scorch_double"]], "up": [["scorch_double"]]},
	"smoldering": {"name": "Rescoldo", "type": "power", "cost": 1, "icon": "coal",
		"rarity": "uncommon", "pack": "ash", "fx": [["power", "smolder", 1]], "up": [["power", "smolder", 2]]},
	"ashen_shroud": {"name": "Mortaja de Ceniza", "short": "Velo de Ceniza", "type": "skill", "cost": 1, "icon": "cloak",
		"rarity": "common", "pack": "ash", "fx": [["block_scorch", 3]], "up": [["block_scorch", 7]]},
	"firestorm": {"name": "Tormenta de Fuego", "short": "Tormenta Ígnea", "type": "attack", "cost": 3, "icon": "volcano",
		"rarity": "rare", "pack": "ash", "fx": [["dmg_all", 8], ["scorch_all", 8]], "up": [["dmg_all", 10], ["scorch_all", 10]]},
	"flashpoint": {"name": "Punto de Ignición", "short": "Ignición", "type": "attack", "cost": 0, "target": true, "icon": "brand", "exhaust": true,
		"rarity": "common", "pack": "ash", "fx": [["detonate", 1]], "up": [["detonate", 2]]},

	# --- Grimorio Solar (raras) ----------------------------------------------
	"supernova": {"name": "Supernova", "type": "attack", "cost": 3, "icon": "sun", "exhaust": true,
		"rarity": "rare", "pack": "solar", "fx": [["dmg_all", 30]], "up": [["dmg_all", 42]]},
	"dwarf_star": {"name": "Estrella Enana", "type": "power", "cost": 3, "up_cost": 2, "icon": "sun",
		"rarity": "rare", "pack": "solar", "fx": [["power", "solar", 1]], "up": [["power", "solar", 1]]},
	"sunforge": {"name": "Forja Solar", "type": "skill", "cost": 1, "icon": "anvil",
		"rarity": "uncommon", "pack": "solar", "fx": [["block", 4], ["block_per_burned", 3]], "up": [["block", 6], ["block_per_burned", 4]]},
	"ember_rain": {"name": "Lluvia de Ascuas", "type": "fuel", "cost": 2, "icon": "sparks",
		"rarity": "rare", "pack": "solar", "burn": [["dmg_rand", 6, 4]], "up_burn": [["dmg_rand", 6, 6]]},
	"corona": {"name": "Corona Solar", "type": "power", "cost": 2, "icon": "corona",
		"rarity": "rare", "pack": "solar", "fx": [["power", "corona", 3]], "up": [["power", "corona", 5]]},
	"star_seed": {"name": "Semilla Estelar", "type": "skill", "cost": 1, "icon": "star", "exhaust": true,
		"rarity": "uncommon", "pack": "solar", "fx": [["energy", 2], ["draw", 1]], "up": [["energy", 2], ["draw", 2]]},
	"eclipse": {"name": "Eclipse", "type": "skill", "cost": 2, "up_cost": 1, "icon": "moon", "exhaust": true,
		"rarity": "rare", "pack": "solar", "fx": [["weak_all", 3], ["vuln_all", 3]], "up": [["weak_all", 3], ["vuln_all", 3]]},
	"solar_flare": {"name": "Fulgor", "type": "attack", "cost": 1, "icon": "corona",
		"rarity": "uncommon", "pack": "solar", "fx": [["dmg_all", 7], ["draw", 1]], "up": [["dmg_all", 10], ["draw", 1]]},

	# --- Grimorio de la Forja (crecen con tu progreso incremental) -----------
	"brazier_flame": {"name": "Llama de Brasero", "short": "Brasero", "type": "attack", "cost": 1, "target": true, "icon": "brazier",
		"rarity": "common", "pack": "forge", "fx": [["dmg_braziers", 4, 5]], "up": [["dmg_braziers", 6, 4]]},
	"gen_wall": {"name": "Muralla de Engranajes", "short": "Muro Dentado", "type": "skill", "cost": 1, "icon": "gear",
		"rarity": "common", "pack": "forge", "fx": [["block_gens", 4, 50]], "up": [["block_gens", 6, 40]]},
	"stardust_strike": {"name": "Golpe Estelar", "type": "attack", "cost": 1, "target": true, "icon": "star_sword",
		"rarity": "uncommon", "pack": "forge", "fx": [["dmg_dust", 4, 2]], "up": [["dmg_dust", 6, 3]]},
	"dividend": {"name": "Dividendo Ígneo", "type": "skill", "cost": 1, "icon": "coin", "exhaust": true,
		"rarity": "uncommon", "pack": "forge", "fx": [["embers_secs", 30], ["draw", 1]], "up": [["embers_secs", 45], ["draw", 2]]},
	"legacy": {"name": "Legado", "type": "power", "cost": 1, "icon": "book",
		"rarity": "rare", "pack": "forge", "fx": [["str_mastery", 8, 4]], "up": [["str_mastery", 6, 6]]},
	"ember_cannon": {"name": "Cañón de Ascuas", "type": "attack", "cost": 2, "target": true, "icon": "cannon",
		"rarity": "rare", "pack": "forge", "fx": [["dmg_prod", 10, 5]], "up": [["dmg_prod", 14, 7]]},
	"hearth_song": {"name": "Canción del Hogar", "short": "Canto del Hogar", "type": "skill", "cost": 1, "icon": "bell", "exhaust": true,
		"rarity": "uncommon", "pack": "forge", "fx": [["heal_braziers", 3, 8]], "up": [["heal_braziers", 5, 6]]},
	"relic_echo": {"name": "Eco del Reliquario", "short": "Eco de Reliquia", "type": "skill", "cost": 1, "icon": "chest",
		"rarity": "uncommon", "pack": "forge", "fx": [["block_codex", 4, 4]], "up": [["block_codex", 7, 4]]},

	# --- Grimorio del Crisol (alquimia) --------------------------------------
	"transmute": {"name": "Transmutar", "type": "skill", "cost": 1, "up_cost": 0, "icon": "flask", "exhaust": true,
		"rarity": "uncommon", "pack": "crucible", "fx": [["transmute", 1]], "up": [["transmute", 1]]},
	"quicksilver": {"name": "Azogue", "type": "skill", "cost": 0, "icon": "drop", "ethereal": true,
		"rarity": "common", "pack": "crucible", "fx": [["draw", 2]], "up": [["draw", 3]]},
	"alloy": {"name": "Aleación", "type": "skill", "cost": 1, "icon": "ingot",
		"rarity": "common", "pack": "crucible", "fx": [["block", 5], ["upgrade_rand", 1]], "up": [["block", 8], ["upgrade_rand", 2]]},
	"philosopher": {"name": "Piedra Filosofal", "type": "power", "cost": 2, "up_cost": 1, "icon": "gem",
		"rarity": "rare", "pack": "crucible", "fx": [["power", "philo", 1]], "up": [["power", "philo", 1]]},
	"retort": {"name": "Alambique", "type": "attack", "cost": 1, "target": true, "icon": "flask",
		"rarity": "common", "pack": "crucible", "fx": [["dmg_hand", 2]], "up": [["dmg_hand", 3]]},
	"fuel_search": {"name": "Buscar Combustible", "short": "Acopio de Leña", "type": "skill", "cost": 1, "up_cost": 0, "icon": "poker",
		"rarity": "common", "pack": "crucible", "fx": [["draw_type", "fuel", 2], ["burn_charge", 1]], "up": [["draw_type", "fuel", 2], ["burn_charge", 1]]},
	"golden_flux": {"name": "Flujo Áureo", "type": "fuel", "cost": 0, "icon": "ingot",
		"rarity": "uncommon", "pack": "crucible", "burn": [["ember_mult", 5], ["draw", 1]], "up_burn": [["ember_mult", 7], ["draw", 1]]},
	"elixir": {"name": "Elixir Ígneo", "type": "skill", "cost": 1, "icon": "potion", "exhaust": true,
		"rarity": "rare", "pack": "crucible", "fx": [["heal", 8], ["str", 2]], "up": [["heal", 12], ["str", 3]]},
	"reforge": {"name": "Reforjar", "type": "skill", "cost": 1, "up_cost": 0, "icon": "anvil", "exhaust": true,
		"rarity": "uncommon", "pack": "crucible", "fx": [["upgrade_hand"]], "up": [["upgrade_hand"]]},

	# --- Fichas (generadas en combate) ---------------------------------------
	"spark_card": {"name": "Chispa Volátil", "type": "fuel", "cost": 0, "icon": "sparks", "ethereal": true,
		"rarity": "token", "pack": "token", "burn": [["dmg_rand", 4, 1], ["draw", 1]], "up_burn": [["dmg_rand", 6, 1], ["draw", 1]]},

	# --- Estados (los añaden los enemigos) -----------------------------------
	"soot": {"name": "Hollín", "type": "status", "cost": 0, "icon": "smoke",
		"rarity": "status", "pack": "status", "burn": [["ember_mult", 1]]},
	"frost": {"name": "Escarcha", "type": "status", "cost": 1, "icon": "snowflake", "exhaust": true, "ethereal": true,
		"rarity": "status", "pack": "status", "fx": [], "playable_status": true},
	"sodden_ash": {"name": "Ceniza Empapada", "type": "status", "cost": 0, "icon": "wet_ash", "unburnable": true,
		"rarity": "status", "pack": "status"},
	"wet_ash": {"name": "Ceniza Húmeda", "type": "status", "cost": 0, "icon": "wet_ash", "ethereal": true, "unburnable": true,
		"rarity": "status", "pack": "status"},
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
	"rhythm": "Cuando juegues un Ataque, gana %d de Bloqueo.",
	"flame_brand": "Tus Ataques aplican %d de Quemadura.",
	"kiln": "Cuando quemes una carta, roba %d.",
	"bellows_pw": "Al inicio de tu turno, gana %d Quema extra.",
	"slag_skin": "Al final de tu turno, gana %d de Bloqueo.",
	"thorns": "Cuando un enemigo te ataque, recibe %d de daño.",
	"smolder": "Al inicio de tu turno, aplica %d de Quemadura a TODOS.",
	"corona": "Al inicio de tu turno, inflige %d de daño a TODOS.",
	"philo": "Al inicio de tu turno, mejora %d carta al azar de tu mano.",
}

const POWER_ICONS := {
	"forge_block": "heart_gear", "inner_fire": "flame", "ash_armor": "armor", "temper": "anvil", "salamander": "lizard",
	"solar": "sun", "rhythm": "bell", "flame_brand": "phoenix", "kiln": "furnace", "bellows_pw": "lung",
	"slag_skin": "armor", "thorns": "spikes", "smolder": "coal", "corona": "corona", "philo": "gem",
}

const TYPE_NAMES := {"attack": "Ataque", "skill": "Habilidad", "power": "Poder", "fuel": "Combustible", "status": "Estado"}
const RARITY_NAMES := {"starter": "Inicial", "common": "Común", "uncommon": "Poco común", "rare": "Rara", "status": "Estado", "token": "Ficha"}
const PACK_NAMES := {"base": "Base", "pyre": "Pira", "anvil": "Yunque", "ash": "Ceniza", "solar": "Solar",
	"forge": "Forja", "crucible": "Crisol", "status": "Estado", "token": "Ficha"}

## Índices numéricos que escalan con la Maestría (y se muestran resaltados).
const SCALABLE := {"dmg": [1], "dmg_x": [1], "dmg_all": [1], "dmg_rand": [1], "dmg_xcost": [1], "dmg_per_burned": [1],
	"dmg_all_per_burned": [1], "block": [1], "block_per_burned": [1], "scorch": [1], "scorch_all": [1], "heal": [1],
	"dmg_braziers": [1], "block_gens": [1], "dmg_dust": [1], "dmg_prod": [1], "block_codex": [1], "dmg_strmult": [1],
	"block_scorch": [1], "heal_braziers": [1], "dmg_hand": [1], "embers_secs": [1]}

const C_NUM := "#ffd36a"
const C_KEY := "#ff9a4a"
const C_MASTER := "#ffb0ff"


static func get_def(id: String) -> Dictionary:
	return CARDS.get(id, CARDS["strike"])


static func ids_in_packs(packs: Array, rarity := "") -> Array[String]:
	var out: Array[String] = []
	for id: String in CARDS:
		var d: Dictionary = CARDS[id]
		if d["rarity"] in ["starter", "status", "token"]:
			continue
		if not packs.has(d["pack"]):
			continue
		if rarity != "" and d["rarity"] != rarity:
			continue
		out.append(id)
	return out


## Cartas coleccionables (las que pueden aparecer en el Códice).
static func collectible_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in CARDS:
		if not (CARDS[id]["rarity"] in ["status", "token"]):
			out.append(id)
	return out


## Aplica la Maestría a una lista de operaciones: +10% por nivel a los valores escalables (redondeo).
static func scale_ops(ops: Array, level: int) -> Array:
	if level <= 0:
		return ops
	var out: Array = []
	for op: Array in ops:
		var idx: Array = SCALABLE.get(op[0], [])
		if idx.is_empty():
			out.append(op)
			continue
		var n := op.duplicate()
		for i: int in idx:
			var v := int(n[i])
			n[i] = v + int(round(v * 0.1 * level))
		out.append(n)
	return out


## Valor base de operaciones que leen la Forja (Braseros, generadores, Polvo, producción, Reliquario).
static func dyn_value(op: Array) -> int:
	match op[0]:
		"dmg_braziers": return int(op[1]) + int(Game.max_floor / maxi(1, int(op[2])))
		"heal_braziers": return int(op[1]) + int(Game.max_floor / maxi(1, int(op[2])))
		"block_gens": return int(op[1]) + int(Game.total_generators() / maxi(1, int(op[2])))
		"dmg_dust": return int(op[1]) + int(float(op[2]) * log(1.0 + Game.stardust_total) / log(2.0))
		"dmg_prod": return int(op[1]) + int(op[2]) * int(floor(log(maxf(Game.production(), 1.0)) / log(10.0)))
		"block_codex": return int(op[1]) + int(Game.relic_codex.size() / maxi(1, int(op[2])))
	return 0


static func str_mastery_value(op: Array) -> int:
	return mini(int(op[2]), int(Game.mastered_count(1) / maxi(1, int(op[1]))))


## Texto BBCode de una carta. `engine` (opcional) ajusta el daño mostrado con Fuerza/Débil.
static func describe(card: Card, engine: Object = null) -> String:
	var parts: PackedStringArray = []
	var d := card.def()
	var kw: PackedStringArray = []
	if d.get("innate", false):
		kw.append("Innata")
	if d.get("retain", false):
		kw.append("Brasa")
	if d.get("ethereal", false):
		kw.append("Etérea")
	if not kw.is_empty():
		parts.append("[color=%s]%s.[/color]" % [C_KEY, ". ".join(kw)])
	if d["type"] == "fuel":
		parts.append("[color=%s]Combustible.[/color]" % C_KEY)
	elif d["type"] == "status" and not d.get("playable_status", false):
		parts.append("[color=%s]Injugable.[/color]" % C_KEY)
	if d.get("unburnable", false):
		parts.append("[color=#8ab4d0]No se puede quemar.[/color]")
	for op: Array in card.effects():
		parts.append(_op_text(op, engine))
	var burn_ops := card.burn_effects()
	if not burn_ops.is_empty():
		var bt: PackedStringArray = []
		for op: Array in burn_ops:
			var t := _op_text(op, engine)
			if t != "":
				bt.append(t)
		if not bt.is_empty():
			parts.append("[color=%s]Al quemar:[/color] %s" % [C_KEY, " ".join(bt)])
	if d.get("exhaust", false) and not d.get("ethereal", false):
		parts.append("[color=%s]Agotar.[/color]" % C_KEY)
	return "\n".join(parts)


## Rama Brasa del Temple: lo que la carta añade al quemarse (40% de su número principal, mín. 3).
static func temple_ember_ops(card_id: String) -> Array:
	var d := get_def(card_id)
	var main := 0
	for op: Array in d.get("fx", []):
		if SCALABLE.has(op[0]):
			main = int(op[1])
			break
	var x := maxi(3, int(round(main * 0.4)))
	match d["type"]:
		"attack":
			return [["dmg_rand_hot", x]] if main > 0 else [["draw", 1]]
		"skill":
			return [["block", x]] if main > 0 else [["draw", 1]]
		"power":
			return [["energy_once", 1]]
	return []


const TEMPLE_NAMES := {"edge": "Filo", "ember": "Brasa", "forge": "Fragua", "rekindle": "Rescoldo"}


static func temple_desc(card_id: String, branch: String) -> String:
	match branch:
		"edge": return "Filo: +20% a sus números al jugarla."
		"ember":
			var parts: PackedStringArray = []
			for op: Array in temple_ember_ops(card_id):
				parts.append(_op_text(op, null))
			return "Brasa: al quemarla, además: %s" % " ".join(parts)
		"forge": return "Fragua: al quemarla, gana 1 Quema extra."
		"rekindle": return "Rescoldo: al quemarla vuelve a tu descarte en vez de exiliarse."
	return ""


static func temple_branches(card_id: String) -> Array[String]:
	if get_def(card_id)["type"] == "fuel":
		return ["forge", "rekindle"]
	return ["edge", "ember"]


## Texto plano (para tooltips y listas).
static func describe_plain(card: Card) -> String:
	var rx := RegEx.new()
	rx.compile("\\[[^\\]]*\\]")
	return rx.sub(describe(card), "", true)


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


static func _op_text(op: Array, engine: Object) -> String:
	var k: String = op[0]
	match k:
		"dmg": return "Inflige %s de daño." % _dmg(op[1], engine)
		"dmg_x": return "Inflige %s de daño %s veces." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_all": return "Inflige %s de daño a TODOS." % _dmg(op[1], engine)
		"dmg_rand": return "%s de daño a un enemigo al azar%s." % [_dmg(op[1], engine), "" if op[2] == 1 else " %s veces" % _n(op[2])]
		"dmg_xcost": return "Inflige %s de daño X veces." % _dmg(op[1], engine)
		"dmg_per_burned": return "Inflige %s de daño, +%s por Calor." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_all_per_burned": return "Inflige %s de daño a TODOS, +%s por Calor." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_strmult": return "Inflige %s de daño. La Fuerza cuenta ×%s." % [_dmg(op[1], engine), _n(op[2])]
		"dmg_hand": return "Inflige %s de daño por carta en tu mano." % _n(op[1])
		"dmg_braziers": return "Inflige %s de daño (+1 por cada %d Braseros)." % [_dmg(dyn_value(op), engine), op[2]]
		"dmg_dust": return "Inflige %s de daño (crece con tu Polvo Estelar)." % _dmg(dyn_value(op), engine)
		"dmg_prod": return "Inflige %s de daño (+%d por cada cifra de tu producción)." % [_dmg(dyn_value(op), engine), op[2]]
		"block": return "Gana %s de Bloqueo." % _n(op[1])
		"block_per_burned": return "Gana %s de Bloqueo por Calor." % _n(op[1])
		"block_scorch": return "Gana %s de Bloqueo + la Quemadura total de los enemigos." % _n(op[1])
		"block_gens": return "Gana %s de Bloqueo (+1 por cada %d generadores)." % [_n(dyn_value(op)), op[2]]
		"block_codex": return "Gana %s de Bloqueo (+1 por cada %d reliquias del Reliquario)." % [_n(dyn_value(op)), op[2]]
		"heal_braziers": return "Cura %s PV (+1 por cada %d Braseros)." % [_n(dyn_value(op)), op[2]]
		"double_block": return "Duplica tu Bloqueo."
		"block_dmg": return "Inflige daño igual a tu Bloqueo."
		"draw": return "Roba %s carta%s." % [_n(op[1]), "" if op[1] == 1 else "s"]
		"draw_type": return "Roba %s carta%s %s de tu mazo." % [_n(op[2]), "" if op[2] == 1 else "s", "Combustible" if op[1] == "fuel" else TYPE_NAMES.get(op[1], "")]
		"energy": return "Gana %s de Energía." % _n(op[1])
		"energy_next": return "El próximo turno, gana %s de Energía." % _n(op[1])
		"scorch": return "Aplica %s de Quemadura." % _n(op[1])
		"scorch_all": return "Aplica %s de Quemadura a TODOS." % _n(op[1])
		"scorch_double": return "Duplica la Quemadura del objetivo."
		"vuln": return "Aplica %s de Vulnerable." % _n(op[1])
		"vuln_all": return "Aplica %s de Vulnerable a TODOS." % _n(op[1])
		"weak": return "Aplica %s de Débil." % _n(op[1])
		"weak_all": return "Aplica %s de Débil a TODOS." % _n(op[1])
		"str": return "Gana %s de Fuerza." % _n(op[1])
		"str_mastery": return "Gana 1 de Fuerza por cada %d cartas con Maestría, máx. %d (%s)." % [op[1], op[2], _n(str_mastery_value(op))]
		"heal": return "Cura %s PV." % _n(op[1])
		"heal_per_burned": return "Cura %s PV por Calor." % _n(op[1])
		"lose_hp": return "Pierdes %s PV." % _n(op[1])
		"detonate": return "Inflige la Quemadura del objetivo ×%s como daño." % _n(op[1])
		"burn_charge": return "Gana %s Quema%s extra." % [_n(op[1]), "" if op[1] == 1 else "s"]
		"free_burn": return "Quema %s carta al azar de tu mano sin gastar Quemas." % _n(op[1])
		"free_hot": return "Tu próxima quema en caliente este turno no cuesta Energía."
		"dmg_rand_hot": return "Inflige %s de daño a un enemigo al azar." % _dmg(op[1], engine)
		"energy_once": return "Gana %s de Energía (1 vez por turno)." % _n(op[1])
		"recall": return "Devuelve a tu mano %s carta%s quemada%s este combate." % [_n(op[1]), "" if op[1] == 1 else "s", "" if op[1] == 1 else "s"]
		"add_hand": return "Añade %s %s a tu mano." % [_n(op[2]), get_def(op[1])["name"]]
		"upgrade_rand": return "Mejora %s carta%s al azar de tu mano (este combate)." % [_n(op[1]), "" if op[1] == 1 else "s"]
		"upgrade_hand": return "Mejora todas las cartas de tu mano (este combate)."
		"transmute": return "Transforma %s carta al azar de tu mano en una carta aleatoria mejorada." % _n(op[1])
		"embers_secs": return "Produce Ascuas: %s s de producción de la Forja." % _n(op[1])
		"ember_mult": return "Produce ×%s Ascuas." % _n(op[1])
		"power":
			var txt: String = POWERS.get(op[1], "%d")
			return txt.replace("%d", _n(op[2]))
	return ""
