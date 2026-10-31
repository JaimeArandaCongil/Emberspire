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
	{"id": "greed", "name": "Codicia", "icon": "coin", "base": 80.0, "growth": 1.9, "max": 25, "desc": "+25% Ascuas obtenidas en la Torre."},
	{"id": "flue", "name": "Tiro de Chimenea", "icon": "wind", "base": 600.0, "growth": 12.0, "max": 3, "desc": "+1 Quema por turno."},
	{"id": "temper", "name": "Templado", "icon": "anvil", "base": 400.0, "growth": 2.6, "max": 10, "desc": "Mejora 1 carta más del mazo inicial."},
	{"id": "hearth", "name": "Brasero Cálido", "icon": "flame", "base": 300.0, "growth": 3.0, "max": 4, "desc": "Las Hogueras curan +10% más."},
	{"id": "arm", "name": "Brazo Forjado", "icon": "sword", "base": 15000.0, "growth": 9.0, "max": 3, "desc": "+1 Fuerza al empezar cada combate."},
	{"id": "heirloom", "name": "Herencia", "icon": "crown", "base": 8000.0, "growth": 20.0, "max": 2, "desc": "Empiezas la ascensión con 1 reliquia aleatoria."},
	{"id": "hands", "name": "Manos Hábiles", "icon": "card", "base": 40000.0, "growth": 30.0, "max": 2, "desc": "+1 carta robada por turno."},
	{"id": "edge", "name": "Filo Eterno", "icon": "flame_sword", "base": 3000.0, "growth": 1.7, "max": 999, "desc": "×1.04 daño de tus cartas (acumulativo). Sin límite."},
	{"id": "skin", "name": "Piel Forjada", "icon": "shield", "base": 3000.0, "growth": 1.7, "max": 999, "desc": "×1.04 PV máximos (acumulativo). Sin límite."},
	{"id": "core", "name": "Núcleo Ígneo", "icon": "orb", "base": 600000.0, "growth": 50.0, "max": 2, "desc": "+1 Energía por turno."},
]

const GRIMOIRES: Array[Dictionary] = [
	{"id": "pyre", "name": "Grimorio de la Pira", "cost": 500.0, "desc": "Cartas que premian quemar."},
	{"id": "anvil", "name": "Grimorio del Yunque", "cost": 4000.0, "desc": "Fuerza, golpes múltiples y bloqueo."},
	{"id": "ash", "name": "Grimorio de la Ceniza", "cost": 25000.0, "desc": "Quemadura en área y detonaciones."},
	{"id": "solar", "name": "Grimorio Solar", "cost": 300000.0, "desc": "Cartas raras de poder estelar."},
]

const TALENTS: Array[Dictionary] = [
	{"id": "memory", "name": "Memoria del Fuego", "cost": 1, "desc": "Tras Renacer empiezas con 10 Chispas y 1.000 Ascuas."},
	{"id": "eternal", "name": "Llama Eterna", "cost": 2, "desc": "Producción offline hasta 24 h (antes 8 h)."},
	{"id": "star_map", "name": "Mapa Estelar", "cost": 2, "desc": "Una puerta extra en cada piso."},
	{"id": "autoforge", "name": "Autoforja", "cost": 3, "desc": "Compra automáticamente el generador más barato."},
	{"id": "phoenix", "name": "Fénix", "cost": 5, "desc": "Una vez por ascensión, al morir revives con 50% PV."},
	{"id": "stellar_greed", "name": "Codicia Estelar", "cost": 8, "desc": "Renacer otorga +50% Polvo Estelar."},
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
