class_name ForgeDB
extends RefCounted
## Economía incremental: generadores, Arsenal, Grimorios y Talentos.

const COST_GROWTH := 1.15
const MILESTONES: Array[int] = [25, 50, 100, 200]

const GENERATORS: Array[Dictionary] = [
	{"id": "spark", "name": "Chispa", "icon": "sparks", "base_cost": 10.0, "rate": 0.5, "flavor": "Una brizna obstinada."},
	{"id": "bellows", "name": "Fuelle", "icon": "wind", "base_cost": 120.0, "rate": 4.0, "flavor": "Aire para el hambre del fuego."},
	{"id": "furnace", "name": "Horno", "icon": "furnace", "base_cost": 1400.0, "rate": 25.0, "flavor": "Ladrillo, barro y paciencia."},
	{"id": "crucible", "name": "Crisol", "icon": "orb", "base_cost": 18000.0, "rate": 150.0, "flavor": "Funde lo que la torre olvida."},
	{"id": "blast", "name": "Alto Horno", "icon": "anvil", "base_cost": 250000.0, "rate": 1000.0, "flavor": "Ruge como un dragón dormido."},
	{"id": "dwarf_sun", "name": "Sol Enano", "icon": "sun", "base_cost": 4.0e6, "rate": 8000.0, "flavor": "Una estrella en cautiverio."},
	{"id": "heart_world", "name": "Corazón del Mundo", "icon": "heart_gear", "base_cost": 9.0e7, "rate": 70000.0, "flavor": "El último latido, ahora tuyo."},
]

## Arsenal: mejoras permanentes de combate. cost = base * growth^nivel
const ARSENAL: Array[Dictionary] = [
	{"id": "vitality", "name": "Corazón de Hierro", "icon": "heart", "base": 50.0, "growth": 1.55, "max": 30, "desc": "+6 PV máximos."},
	{"id": "greed", "name": "Codicia", "icon": "coin", "base": 80.0, "growth": 1.9, "max": 20, "desc": "+10% Ascuas obtenidas en la Torre."},
	{"id": "flue", "name": "Tiro de Chimenea", "icon": "wind", "base": 600.0, "growth": 12.0, "max": 3, "desc": "+1 Quema por turno."},
	{"id": "temper", "name": "Templado", "icon": "anvil", "base": 400.0, "growth": 2.6, "max": 10, "desc": "Mejora 1 carta más del mazo inicial."},
	{"id": "hearth", "name": "Brasero Cálido", "icon": "flame", "base": 300.0, "growth": 3.0, "max": 4, "desc": "Las Hogueras curan +10% más."},
	{"id": "arm", "name": "Brazo Forjado", "icon": "sword", "base": 15000.0, "growth": 9.0, "max": 3, "desc": "+1 Fuerza al empezar cada combate."},
	{"id": "heirloom", "name": "Herencia", "icon": "crown", "base": 8000.0, "growth": 20.0, "max": 2, "desc": "Empiezas con 1 reliquia de tu Reliquario (eliges en la Antesala)."},
	{"id": "hands", "name": "Manos Hábiles", "icon": "card", "base": 40000.0, "growth": 30.0, "max": 2, "desc": "+1 carta robada por turno."},
	{"id": "edge", "name": "Filo Eterno", "icon": "flame_sword", "base": 3000.0, "growth": 1.7, "max": 999, "desc": "×1.04 daño de tus cartas (acumulativo). Sin límite."},
	{"id": "skin", "name": "Piel Forjada", "icon": "shield", "base": 3000.0, "growth": 1.7, "max": 999, "desc": "×1.04 PV máximos (acumulativo). Sin límite."},
	{"id": "core", "name": "Núcleo Ígneo", "icon": "orb", "base": 600000.0, "growth": 50.0, "max": 2, "desc": "+1 Energía por turno."},
]

const GRIMOIRES: Array[Dictionary] = [
	{"id": "pyre", "name": "Grimorio de la Pira", "cost": 500.0, "desc": "Cartas que premian quemar: recuperar quemadas, Quemas extra, Calor."},
	{"id": "anvil", "name": "Grimorio del Yunque", "cost": 4000.0, "desc": "Fuerza, golpes múltiples, espinas y bloqueo."},
	{"id": "forge", "name": "Grimorio de la Forja", "cost": 12000.0, "desc": "Cartas que crecen con tu Forja: Braseros, generadores, Polvo y producción."},
	{"id": "ash", "name": "Grimorio de la Ceniza", "cost": 25000.0, "desc": "Quemadura en área, duplicarla y detonarla."},
	{"id": "crucible", "name": "Grimorio del Crisol", "cost": 80000.0, "desc": "Alquimia: mejoras temporales, transmutación y búsqueda de Combustible."},
	{"id": "solar", "name": "Grimorio Solar", "cost": 300000.0, "desc": "Cartas raras de poder estelar."},
]

const TALENTS: Array[Dictionary] = [
	{"id": "memory", "name": "Memoria del Fuego", "cost": 1, "desc": "Tras Renacer empiezas con 10 Chispas y 1.000 Ascuas."},
	{"id": "eternal", "name": "Llama Eterna", "cost": 2, "desc": "Producción offline hasta 24 h (antes 8 h)."},
	{"id": "star_map", "name": "Mapa Estelar", "cost": 2, "desc": "Una puerta extra en cada piso."},
	{"id": "autoforge", "name": "Autoforja", "cost": 3, "desc": "Compra automáticamente el generador más barato."},
	{"id": "phoenix", "name": "Fénix", "cost": 5, "desc": "Una vez por ascensión, al morir revives con 50% PV."},
	{"id": "stellar_greed", "name": "Codicia Estelar", "cost": 8, "desc": "Renacer otorga +50% Polvo Estelar."},
	{"id": "ember_memory", "name": "Memoria Ígnea", "cost": 2, "desc": "Cada carta quemada gana +1 de Maestría extra."},
	{"id": "twin_embers", "name": "Brasas Gemelas", "cost": 2, "desc": "+1 Quema en el primer turno de cada combate."},
	{"id": "echoes", "name": "Ecos", "cost": 3, "desc": "Las Resonancias necesitan la mitad de generadores (5 / 25 / 50)."},
	{"id": "deep_codex", "name": "Códice Profundo", "cost": 3, "desc": "Cada reliquia del Reliquario da +4% de producción (antes +2%)."},
	{"id": "heat_lover", "name": "Amante del Calor", "cost": 4, "desc": "Cada punto de Calor de Pacto da +30% Ascuas en la Torre (antes +20%)."},
	{"id": "star_forge", "name": "Forja Estelar", "cost": 6, "desc": "Los generadores cuestan un 15% menos."},
]

## Pactos de Brasa: dificultad opcional a cambio de Calor (más Ascuas en la Torre). Se desbloquean en el piso 10.
const PACTS: Array[Dictionary] = [
	{"id": "pact_hp", "name": "Carne de Piedra", "heat": 1, "icon": "golem", "desc": "Los enemigos tienen +25% PV."},
	{"id": "pact_dmg", "name": "Colmillos", "heat": 1, "icon": "fang", "desc": "Los enemigos infligen +20% de daño."},
	{"id": "pact_elite", "name": "Élites Coronadas", "heat": 1, "icon": "crown", "desc": "Élites y jefes empiezan con 3 de Fuerza."},
	{"id": "pact_rest", "name": "Hogueras Mortecinas", "heat": 1, "icon": "bonfire", "desc": "Las Hogueras curan la mitad."},
	{"id": "pact_frost", "name": "Mazo Escarchado", "heat": 1, "icon": "snowflake", "desc": "Empiezas la ascensión con 2 Escarchas en el mazo."},
	{"id": "pact_burn", "name": "Horno Avaro", "heat": 2, "icon": "furnace", "desc": "−1 Quema en el primer turno de cada combate."},
	{"id": "pact_boss", "name": "Guardianes Antiguos", "heat": 2, "icon": "skull", "desc": "Los jefes tienen +50% PV."},
	{"id": "pact_hunger", "name": "Hambre", "heat": 2, "icon": "goblet", "desc": "Derrotar a un jefe no te cura."},
]

## Crónica: hitos con recompensa única. stat: ver Game.stat_value().
const HITOS: Array[Dictionary] = [
	{"id": "floor5", "name": "Primeros Pasos", "stat": "max_floor", "goal": 5, "secs": 60, "desc": "Alcanza el piso 5."},
	{"id": "floor10", "name": "Matacarboneros", "stat": "max_floor", "goal": 10, "dust": 1, "desc": "Alcanza el piso 10."},
	{"id": "floor20", "name": "Reina Depuesta", "stat": "max_floor", "goal": 20, "dust": 2, "desc": "Alcanza el piso 20."},
	{"id": "floor30", "name": "Cumbre Helada", "stat": "max_floor", "goal": 30, "dust": 3, "desc": "Alcanza el piso 30."},
	{"id": "floor40", "name": "Más Allá del Ciclo", "stat": "max_floor", "goal": 40, "dust": 4, "desc": "Alcanza el piso 40."},
	{"id": "floor60", "name": "Torre sin Fin", "stat": "max_floor", "goal": 60, "dust": 6, "desc": "Alcanza el piso 60."},
	{"id": "burns50", "name": "Pirómana", "stat": "burns", "goal": 50, "secs": 120, "desc": "Quema 50 cartas."},
	{"id": "burns300", "name": "Hija de la Hoguera", "stat": "burns", "goal": 300, "dust": 1, "desc": "Quema 300 cartas."},
	{"id": "burns1500", "name": "Incendiaria", "stat": "burns", "goal": 1500, "dust": 3, "desc": "Quema 1.500 cartas."},
	{"id": "kills100", "name": "Cazadora", "stat": "kills", "goal": 100, "secs": 120, "desc": "Derrota a 100 enemigos."},
	{"id": "kills1000", "name": "Azote de la Torre", "stat": "kills", "goal": 1000, "dust": 2, "desc": "Derrota a 1.000 enemigos."},
	{"id": "elites10", "name": "Cazacoronas", "stat": "elites", "goal": 10, "dust": 1, "desc": "Derrota a 10 élites."},
	{"id": "bosses3", "name": "Regicida", "stat": "bosses", "goal": 3, "dust": 2, "desc": "Derrota a 3 jefes."},
	{"id": "relics10", "name": "Coleccionista", "stat": "relics", "goal": 10, "dust": 1, "desc": "Reúne 10 reliquias en el Reliquario."},
	{"id": "relics25", "name": "Conservadora", "stat": "relics", "goal": 25, "dust": 3, "desc": "Reúne 25 reliquias en el Reliquario."},
	{"id": "mastery10", "name": "Aprendiz", "stat": "mastered", "goal": 10, "secs": 120, "desc": "Consigue Maestría en 10 cartas distintas."},
	{"id": "mastery_max1", "name": "Maestra del Fuego", "stat": "mastered_max", "goal": 1, "dust": 1, "desc": "Lleva una carta a Maestría 5."},
	{"id": "mastery_max8", "name": "Gran Maestra", "stat": "mastered_max", "goal": 8, "dust": 3, "desc": "Lleva 8 cartas a Maestría 5."},
	{"id": "gens100", "name": "Taller", "stat": "gens", "goal": 100, "secs": 300, "desc": "Ten 100 generadores a la vez."},
	{"id": "gens500", "name": "Fundición", "stat": "gens", "goal": 500, "dust": 2, "desc": "Ten 500 generadores a la vez."},
	{"id": "prod1m", "name": "Industria", "stat": "prod", "goal": 1000000, "dust": 2, "desc": "Produce 1M Ascuas por segundo."},
	{"id": "prod1b", "name": "Revolución", "stat": "prod", "goal": 1000000000, "dust": 4, "desc": "Produce 1B Ascuas por segundo."},
	{"id": "rebirth1", "name": "Ave Fénix", "stat": "rebirths", "goal": 1, "dust": 1, "desc": "Renace en Ceniza por primera vez."},
	{"id": "heat3", "name": "Jugar con Fuego", "stat": "heat_boss", "goal": 3, "dust": 2, "desc": "Derrota a un jefe con 3 o más de Calor de Pacto."},
	{"id": "heat8", "name": "Infierno", "stat": "heat_boss", "goal": 8, "dust": 5, "desc": "Derrota a un jefe con 8 o más de Calor de Pacto."},
	{"id": "grim_all", "name": "Biblioteca Completa", "stat": "grimoires", "goal": 6, "dust": 2, "desc": "Aprende los 6 Grimorios."},
]



static func generator(id: String) -> Dictionary:
	for g in GENERATORS:
		if g["id"] == id:
			return g
	return {}


static func arsenal(id: String) -> Dictionary:
	for a in ARSENAL:
		if a["id"] == id:
			return a
	return {}


static func talent(id: String) -> Dictionary:
	for t in TALENTS:
		if t["id"] == id:
			return t
	return {}


static func pact(id: String) -> Dictionary:
	for p in PACTS:
		if p["id"] == id:
			return p
	return {}


static func grimoire(id: String) -> Dictionary:
	for g in GRIMOIRES:
		if g["id"] == id:
			return g
	return {}


static func generator_cost(g: Dictionary, owned: int, amount: int = 1) -> float:
	# Suma geométrica: base * r^n * (r^k - 1) / (r - 1)
	var r := COST_GROWTH
	return float(g["base_cost"]) * pow(r, owned) * (pow(r, amount) - 1.0) / (r - 1.0)


static func max_affordable(g: Dictionary, owned: int, money: float) -> int:
	var r := COST_GROWTH
	var base := float(g["base_cost"]) * pow(r, owned)
	if money < base:
		return 0
	return int(floor(log(money * (r - 1.0) / base + 1.0) / log(r)))


static func milestone_mult(owned: int) -> float:
	var m := 1.0
	for t in MILESTONES:
		if owned >= t:
			m *= 2.0
	return m


static func arsenal_cost(a: Dictionary, level: int) -> float:
	return float(a["base"]) * pow(float(a["growth"]), level)
