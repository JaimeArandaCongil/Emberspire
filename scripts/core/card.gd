class_name Card
extends RefCounted
## Instancia de carta dentro de un mazo. La definición vive en CardDB.
## La Maestría (Game.mastery) escala sus números: las cartas que quemas recuerdan el fuego.

static var _next_uid := 1

var id: String
var upgraded: bool
## Mejora temporal (sólo este combate): Reforjar, Aleación, Tenazas...
var temp_up := false
var uid: int


func _init(p_id: String = "strike", p_upgraded: bool = false) -> void:
	id = p_id
	upgraded = p_upgraded
	uid = _next_uid
	_next_uid += 1


func def() -> Dictionary:
	return CardDB.get_def(id)


func is_up() -> bool:
	return upgraded or temp_up


func title() -> String:
	return def()["name"] + ("+" if is_up() else "")


func type() -> String:
	return def()["type"]


func rarity() -> String:
	return def()["rarity"]


func mastery() -> int:
	return Game.mastery_level(id)


func cost() -> int:
	var d := def()
	if is_up() and d.has("up_cost"):
		return d["up_cost"]
	return d["cost"]


func is_x_cost() -> bool:
	return cost() < 0


func needs_target() -> bool:
	return def().get("target", false)


func is_playable() -> bool:
	var d := def()
	if d["type"] == "fuel":
		return false
	if d["type"] == "status":
		return d.get("playable_status", false)
	return true


func is_burnable() -> bool:
	return not def().get("unburnable", false)


func exhausts() -> bool:
	return def().get("exhaust", false)


func has_kw(key: String) -> bool:
	return def().get(key, false)


## Rama de Temple activa ("" si no hay). Con la Constelación Doble Temple y Maestría 5, ambas.
func has_temple(branch: String) -> bool:
	var t: String = Game.temples.get(id, "")
	if t == branch:
		return true
	return t != "" and Game.constellations.has("c_twin") and mastery() >= Game.MASTERY_MAX and CardDB.temple_branches(id).has(branch)


func effects() -> Array:
	var d := def()
	var ops: Array = d["up"] if is_up() and d.has("up") else d.get("fx", [])
	return CardDB.scale_ops(ops, mastery() + (2 if has_temple("edge") else 0))


func burn_effects() -> Array:
	var d := def()
	var ops: Array = d["up_burn"] if is_up() and d.has("up_burn") else d.get("burn", [])
	var out := CardDB.scale_ops(ops, mastery())
	if has_temple("ember"):
		out = out + CardDB.temple_ember_ops(id)
	if has_temple("forge"):
		out = out + [["burn_charge", 1]]
	return out


## Coste de la quema en caliente: -1 si no se puede (Combustible, Estado, coste 0).
func hot_cost(energy: int) -> int:
	if not is_playable() or type() == "status":
		return -1
	if is_x_cost():
		return maxi(1, energy)
	return cost() if cost() > 0 else -1


func can_upgrade() -> bool:
	var d := def()
	return not upgraded and (d.has("up") or d.has("up_burn") or d.has("up_cost"))


func duplicate_card() -> Card:
	return Card.new(id, upgraded)
