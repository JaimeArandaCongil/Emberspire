class_name RelicDB
extends RefCounted
## Reliquias: efectos pasivos de una run. Los ganchos se consultan en CombatEngine/RunState.

const RELICS := {
	"leather_bellows": {"name": "Fuelle de Cuero", "icon": "wind", "desc": "+1 Quema por turno."},
	"coal_heart": {"name": "Corazón de Carbón", "icon": "heart", "desc": "+12 PV máximos."},
	"ember_ring": {"name": "Anillo de Ascua", "icon": "orb", "desc": "Empiezas cada combate con 1 de Fuerza."},
	"pocket_brazier": {"name": "Brasero de Bolsillo", "icon": "flame", "desc": "Cura 6 PV al ganar un combate."},
	"eternal_candle": {"name": "Vela Eterna", "icon": "candle", "desc": "+1 Energía en el primer turno de cada combate."},
	"moneylender_lens": {"name": "Lupa del Cambista", "icon": "eye", "desc": "+30% Ascuas en esta ascensión."},
	"salamander_scale": {"name": "Escama de Salamandra", "icon": "lizard", "desc": "Los enemigos empiezan con 3 de Quemadura."},
	"ash_eye": {"name": "Ojo de Ceniza", "icon": "eye", "desc": "Roba 2 cartas extra en el primer turno."},
	"iron_lung": {"name": "Pulmón de Hierro", "icon": "shield", "desc": "Al quemar una carta, gana 3 de Bloqueo."},
	"slag_crown": {"name": "Corona de Escoria", "icon": "crown", "desc": "Las élites sueltan el doble de Ascuas."},
	"whetstone": {"name": "Piedra de Afilar", "icon": "sword", "desc": "Tus Ataques infligen +2 de daño."},
	"warm_stone": {"name": "Piedra Tibia", "icon": "coal", "desc": "Empiezas cada combate con 6 de Bloqueo."},
}


static func get_def(id: String) -> Dictionary:
	return RELICS.get(id, {"name": id, "icon": "orb", "desc": ""})


static func random_unowned(owned: Array, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	for id: String in RELICS:
		if not owned.has(id):
			pool.append(id)
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]
