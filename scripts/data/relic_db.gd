class_name RelicDB
extends RefCounted
## Reliquias (efectos pasivos de una ascensión) y Resonancias (ventajas que dan los generadores de la Forja).
## Ambas comparten ganchos: CombatEngine y RunState preguntan `run.has_relic(id)`, que mira las dos listas.
## rarity: common | uncommon | rare | boss

const RELICS := {
	"leather_bellows": {"name": "Fuelle de Cuero", "icon": "wind", "rarity": "uncommon", "desc": "+1 Quema por turno."},
	"coal_heart": {"name": "Corazón de Carbón", "icon": "heart", "rarity": "common", "desc": "+12 PV máximos."},
	"ember_ring": {"name": "Anillo de Ascua", "icon": "ring", "rarity": "common", "desc": "Empiezas cada combate con 1 de Fuerza."},
	"pocket_brazier": {"name": "Brasero de Bolsillo", "icon": "brazier", "rarity": "common", "desc": "Cura 6 PV al ganar un combate."},
	"eternal_candle": {"name": "Vela Eterna", "icon": "candle", "rarity": "common", "desc": "+1 Energía en el primer turno de cada combate."},
	"moneylender_lens": {"name": "Lupa del Cambista", "icon": "lens", "rarity": "uncommon", "desc": "+30% Ascuas en esta ascensión."},
	"salamander_scale": {"name": "Escama de Salamandra", "icon": "lizard", "rarity": "uncommon", "desc": "Los enemigos empiezan con 3 de Quemadura."},
	"ash_eye": {"name": "Ojo de Ceniza", "icon": "eye", "rarity": "common", "desc": "Roba 2 cartas extra en el primer turno."},
	"iron_lung": {"name": "Pulmón de Hierro", "icon": "lung", "rarity": "uncommon", "desc": "Al quemar una carta, gana 3 de Bloqueo."},
	"slag_crown": {"name": "Corona de Escoria", "icon": "crown", "rarity": "uncommon", "desc": "Las élites sueltan el doble de Ascuas."},
	"whetstone": {"name": "Piedra de Afilar", "icon": "whetstone", "rarity": "common", "desc": "Tus Ataques infligen +2 de daño."},
	"warm_stone": {"name": "Piedra Tibia", "icon": "coal", "rarity": "common", "desc": "Empiezas cada combate con 6 de Bloqueo."},
	"bone_tinder": {"name": "Yesca de Hueso", "icon": "bone", "rarity": "common", "desc": "Al empezar cada combate, añade 1 Chispa Volátil a tu mano."},
	"cinder_heart": {"name": "Corazón de Cisco", "icon": "heart_gear", "rarity": "uncommon", "desc": "Cada 3 cartas quemadas en un combate, gana 1 de Energía."},
	"tongs": {"name": "Tenazas de Forja", "icon": "tongs", "rarity": "common", "desc": "En el primer turno, mejora 1 carta al azar de tu mano (este combate)."},
	"charred_tome": {"name": "Tomo Chamuscado", "icon": "book", "rarity": "uncommon", "desc": "La primera carta que quemes cada turno roba 1 carta."},
	"molten_shield": {"name": "Escudo Fundido", "icon": "shield", "rarity": "common", "desc": "Si terminas el turno sin Bloqueo, gana 5 de Bloqueo."},
	"thorn_ring": {"name": "Anillo de Espinas", "icon": "spikes", "rarity": "common", "desc": "Cuando un enemigo te ataque, recibe 3 de daño."},
	"blood_coal": {"name": "Carbón Sangriento", "icon": "blood_flame", "rarity": "uncommon", "desc": "Al inicio de tu turno, si tienes la mitad de PV o menos, gana 1 de Energía."},
	"pyre_mask": {"name": "Máscara de la Pira", "icon": "mask", "rarity": "common", "desc": "Los enemigos empiezan cada combate con 1 de Vulnerable."},
	"frost_pendant": {"name": "Colgante Helado", "icon": "snowflake", "rarity": "common", "desc": "Los enemigos empiezan cada combate con 1 de Débil."},
	"kiln_key": {"name": "Llave del Horno", "icon": "key", "rarity": "boss", "desc": "Las Quemas que no uses se guardan para el turno siguiente (máx. 3)."},
	"gold_bellows": {"name": "Fuelle Dorado", "icon": "fan", "rarity": "rare", "desc": "Quemar cartas produce +50% Ascuas."},
	"ledger": {"name": "Libro de Cuentas", "icon": "scroll", "rarity": "uncommon", "desc": "Al ganar un combate, recibes 10 s más de producción."},
	"phoenix_ash": {"name": "Ceniza de Fénix", "icon": "phoenix", "rarity": "boss", "desc": "Una vez más: al morir, revives con 50% PV (se suma al talento Fénix)."},
	"war_drum": {"name": "Tambor de Guerra", "icon": "drum", "rarity": "uncommon", "desc": "Cada 4 Ataques jugados en un combate, gana 1 de Fuerza."},
	"ember_lantern": {"name": "Farol de Ascuas", "icon": "lantern", "rarity": "boss", "desc": "Robas 1 carta extra cada turno."},
	"anvil_charm": {"name": "Amuleto de Yunque", "icon": "anvil", "rarity": "common", "desc": "Cada vez que juegues un Poder, gana 6 de Bloqueo."},
	"scorched_map": {"name": "Mapa Chamuscado", "icon": "map", "rarity": "uncommon", "desc": "Una puerta extra en cada piso."},
	"merchant_seal": {"name": "Sello del Mercader", "icon": "coin", "rarity": "uncommon", "desc": "Los precios del Yunque Errante bajan un 30%."},
	"healing_salve": {"name": "Bálsamo de Brea", "icon": "potion", "rarity": "common", "desc": "Las Hogueras curan 10 PV adicionales."},
	"slag_hammer": {"name": "Martillo de Escoria", "icon": "hammer", "rarity": "rare", "desc": "El primer Ataque de cada combate inflige el doble de daño."},
	"volcanic_glass": {"name": "Vidrio Volcánico", "icon": "gem", "rarity": "rare", "desc": "Al matar a un enemigo, gana 1 de Energía."},
	"cracked_core": {"name": "Núcleo Agrietado", "icon": "orb", "rarity": "boss", "desc": "+1 Energía por turno. Cada combate empieza con 3 Ceniza Empapada en tu mazo (no se queman ni se agotan)."},
	"smiths_journal": {"name": "Diario de la Herrera", "icon": "book", "rarity": "boss", "desc": "Las cartas que quemas ganan el doble de Maestría."},
	"stardust_vial": {"name": "Vial de Polvo Estelar", "icon": "vial", "rarity": "rare", "desc": "Al derrotar a un jefe, obtienes 1 Polvo Estelar."},
	"brazier_shard": {"name": "Esquirla de Brasero", "icon": "brazier", "rarity": "rare", "desc": "Tus Ataques infligen +1 de daño por cada 20 Braseros."},
	"iron_kettle": {"name": "Caldera de Hierro", "icon": "kettle", "rarity": "common", "desc": "Empiezas cada combate con Bloqueo igual al 10% de tus PV máximos."},
	"soot_jar": {"name": "Tarro de Hollín", "icon": "jar", "rarity": "uncommon", "desc": "Quemar cartas de Estado no gasta Quemas."},
	"ember_coin": {"name": "Moneda de Ascua", "icon": "coin", "rarity": "common", "desc": "+20% Ascuas en esta ascensión."},
}

## Resonancias: cada generador al llegar a 10 / 50 / 100 unidades concede una ventaja de combate.
const RESONANCE_TIERS: Array[int] = [10, 50, 100]
const PERKS := {
	"res_spark1": {"gen": "spark", "tier": 0, "name": "Chisporroteo", "icon": "sparks", "desc": "La primera carta que quemes en cada combate roba 1 carta."},
	"res_spark2": {"gen": "spark", "tier": 1, "name": "Chispa Temprana", "icon": "sparks", "desc": "+1 Quema en el primer turno de cada combate."},
	"res_spark3": {"gen": "spark", "tier": 2, "name": "Metralla", "icon": "sparks", "desc": "Al quemar un Combustible, inflige 4 de daño a un enemigo al azar."},
	"res_bellows1": {"gen": "bellows", "tier": 0, "name": "Corriente", "icon": "wind", "desc": "Empiezas cada combate con 5 de Bloqueo."},
	"res_bellows2": {"gen": "bellows", "tier": 1, "name": "Aire Fresco", "icon": "wind", "desc": "Roba 1 carta extra en el primer turno."},
	"res_bellows3": {"gen": "bellows", "tier": 2, "name": "Vendaval", "icon": "wind", "desc": "Al inicio de cada turno, gana 2 de Bloqueo."},
	"res_furnace1": {"gen": "furnace", "tier": 0, "name": "Ladrillo Cálido", "icon": "furnace", "desc": "+8 PV máximos."},
	"res_furnace2": {"gen": "furnace", "tier": 1, "name": "Brasa Curativa", "icon": "furnace", "desc": "Cura 4 PV al ganar un combate."},
	"res_furnace3": {"gen": "furnace", "tier": 2, "name": "Horno Interior", "icon": "furnace", "desc": "Empiezas cada combate con 1 de Fuerza."},
	"res_crucible1": {"gen": "crucible", "tier": 0, "name": "Mezcla", "icon": "crucible", "desc": "Las recompensas de carta ofrecen 4 opciones."},
	"res_crucible2": {"gen": "crucible", "tier": 1, "name": "Aleación Fina", "icon": "crucible", "desc": "+15% de probabilidad de que las recompensas vengan mejoradas."},
	"res_crucible3": {"gen": "crucible", "tier": 2, "name": "Piedra Filosofal", "icon": "crucible", "desc": "Empiezas cada ascensión con 1 carta rara aleatoria."},
	"res_blast1": {"gen": "blast", "tier": 0, "name": "Filo Caliente", "icon": "blast", "desc": "Tus Ataques infligen +1 de daño."},
	"res_blast2": {"gen": "blast", "tier": 1, "name": "Escoria Ardiente", "icon": "blast", "desc": "Al quemar una carta, aplica 2 de Quemadura a TODOS."},
	"res_blast3": {"gen": "blast", "tier": 2, "name": "Acero al Rojo", "icon": "blast", "desc": "Tus Ataques infligen +2 de daño adicional."},
	"res_sun1": {"gen": "dwarf_sun", "tier": 0, "name": "Amanecer", "icon": "sun", "desc": "+1 Energía en el primer turno de cada combate."},
	"res_sun2": {"gen": "dwarf_sun", "tier": 1, "name": "Fotosfera", "icon": "sun", "desc": "Cada 3 cartas quemadas en un combate, gana 1 de Energía."},
	"res_sun3": {"gen": "dwarf_sun", "tier": 2, "name": "Cénit", "icon": "sun", "desc": "+1 Quema por turno."},
	"res_heart1": {"gen": "heart_world", "tier": 0, "name": "Latido", "icon": "heart_gear", "desc": "Empiezas cada combate con 2 de Fuerza."},
	"res_heart2": {"gen": "heart_world", "tier": 1, "name": "Pulso del Mundo", "icon": "heart_gear", "desc": "+1 Energía por turno."},
	"res_heart3": {"gen": "heart_world", "tier": 2, "name": "Eje del Mundo", "icon": "heart_gear", "desc": "Al empezar cada combate, los enemigos pierden un 10% de sus PV."},
	# --- Variante B de cada umbral (se elige en la Antesala) ---
	"res_spark1b": {"gen": "spark", "tier": 0, "alt": true, "name": "Yesca", "icon": "sparks", "desc": "Al empezar cada combate, añade 1 Chispa Volátil a tu mano."},
	"res_spark2b": {"gen": "spark", "tier": 1, "alt": true, "name": "Brasa Guardada", "icon": "sparks", "desc": "1 Quema sin usar pasa al turno siguiente."},
	"res_spark3b": {"gen": "spark", "tier": 2, "alt": true, "name": "Ignición", "icon": "sparks", "desc": "Al quemar un Ataque, inflige 6 de daño al enemigo con menos PV."},
	"res_bellows1b": {"gen": "bellows", "tier": 0, "alt": true, "name": "Ráfaga", "icon": "wind", "desc": "En el primer turno robas 1 carta menos y ganas 1 de Energía."},
	"res_bellows2b": {"gen": "bellows", "tier": 1, "alt": true, "name": "Sotavento", "icon": "wind", "desc": "Al acabar el turno, gana 4 de Bloqueo por cada Energía sin gastar."},
	"res_bellows3b": {"gen": "bellows", "tier": 2, "alt": true, "name": "Huracán", "icon": "wind", "desc": "Cada vez que barajas tu mazo, gana 1 de Energía."},
	"res_furnace1b": {"gen": "furnace", "tier": 0, "alt": true, "name": "Piel Curtida", "icon": "furnace", "desc": "Al derrotar a una élite, +4 PV máximos (esta ascensión)."},
	"res_furnace2b": {"gen": "furnace", "tier": 1, "alt": true, "name": "Sangre de Hierro", "icon": "furnace", "desc": "Si ganas un combate con la mitad de PV o menos, cura 10."},
	"res_furnace3b": {"gen": "furnace", "tier": 2, "alt": true, "name": "Corazón de Brasa", "icon": "furnace", "desc": "La primera vez en cada combate que bajas de la mitad de PV, gana 2 de Fuerza."},
	"res_crucible1b": {"gen": "crucible", "tier": 0, "alt": true, "name": "Tamiz", "icon": "crucible", "desc": "Las recompensas ofrecen sólo 2 cartas, pero una es al menos poco común."},
	"res_crucible2b": {"gen": "crucible", "tier": 1, "alt": true, "name": "Purga", "icon": "crucible", "desc": "Tras vencer a una élite, puedes eliminar 1 carta de tu mazo."},
	"res_crucible3b": {"gen": "crucible", "tier": 2, "alt": true, "name": "Transmutación", "icon": "crucible", "desc": "Al empezar la ascensión, 3 Golpes/Defensas se transforman en cartas de tus Grimorios."},
	"res_blast1b": {"gen": "blast", "tier": 0, "alt": true, "name": "Escoria Afilada", "icon": "blast", "desc": "Tus Ataques de coste 2 o más infligen +3 de daño."},
	"res_blast2b": {"gen": "blast", "tier": 1, "alt": true, "name": "Martinete", "icon": "blast", "desc": "Tus Ataques de varios golpes infligen +1 por golpe."},
	"res_blast3b": {"gen": "blast", "tier": 2, "alt": true, "name": "Primer Martillo", "icon": "blast", "desc": "El primer Ataque de cada turno inflige ×1.5 de daño."},
	"res_sun1b": {"gen": "dwarf_sun", "tier": 0, "alt": true, "name": "Amanecer Tardío", "icon": "sun", "desc": "+2 de Energía en el segundo turno de cada combate."},
	"res_sun2b": {"gen": "dwarf_sun", "tier": 1, "alt": true, "name": "Mancha Solar", "icon": "sun", "desc": "La primera vez que juegas un Poder cada turno, gana 1 de Energía."},
	"res_sun3b": {"gen": "dwarf_sun", "tier": 2, "alt": true, "name": "Corona Estable", "icon": "sun", "desc": "Robas 1 carta más cada turno."},
	"res_heart1b": {"gen": "heart_world", "tier": 0, "alt": true, "name": "Pulso", "icon": "heart_gear", "desc": "Al empezar cada turno par, gana 1 de Fuerza."},
	"res_heart2b": {"gen": "heart_world", "tier": 1, "alt": true, "name": "Latido Ígneo", "icon": "heart_gear", "desc": "La primera quema en caliente de cada turno no cuesta Energía."},
	"res_heart3b": {"gen": "heart_world", "tier": 2, "alt": true, "name": "Eje Invertido", "icon": "heart_gear", "desc": "Al matar a un enemigo, los demás pierden un 10% de sus PV máximos."},
}


static func get_def(id: String) -> Dictionary:
	if PERKS.has(id):
		return PERKS[id]
	return RELICS.get(id, {"name": id, "icon": "orb", "desc": "", "rarity": "common"})


static func is_perk(id: String) -> bool:
	return PERKS.has(id)


## Resonancia de un generador y umbral. variant "a" (la original) o "b" (la alternativa).
static func perk_for(gen_id: String, tier: int, variant: String = "a") -> String:
	for id: String in PERKS:
		var d: Dictionary = PERKS[id]
		if d["gen"] == gen_id and int(d["tier"]) == tier and d.get("alt", false) == (variant == "b"):
			return id
	return ""


static func random_unowned(owned: Array, rng: RandomNumberGenerator, rarity := "") -> String:
	var pool: Array = []
	for id: String in RELICS:
		if owned.has(id):
			continue
		var r: String = RELICS[id]["rarity"]
		if rarity == "" and r == "boss":
			continue
		if rarity != "" and r != rarity:
			continue
		pool.append(id)
	if pool.is_empty():
		if rarity != "":
			return random_unowned(owned, rng)
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]


## Varias reliquias distintas para elegir (jefes: 3 de jefe).
static func choices(owned: Array, rng: RandomNumberGenerator, count: int, rarity := "") -> Array[String]:
	var out: Array[String] = []
	var taken := owned.duplicate()
	for i in count:
		var id := random_unowned(taken, rng, rarity)
		if id == "":
			break
		out.append(id)
		taken.append(id)
	return out
