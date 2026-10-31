class_name Card
extends RefCounted
## Instancia de carta dentro de un mazo. La definición vive en CardDB.

static var _next_uid := 1

var id: String
var upgraded: bool
var uid: int


func _init(p_id: String = "strike", p_upgraded: bool = false) -> void:
	id = p_id
	upgraded = p_upgraded
	uid = _next_uid
	_next_uid += 1


func def() -> Dictionary:
	return CardDB.get_def(id)


func title() -> String:
	return def()["name"] + ("+" if upgraded else "")


func type() -> String:
	return def()["type"]


func cost() -> int:
	var d := def()
	if upgraded and d.has("up_cost"):
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


func exhausts() -> bool:
	return def().get("exhaust", false)


func effects() -> Array:
	var d := def()
	if upgraded and d.has("up"):
		return d["up"]
	return d.get("fx", [])


func burn_effects() -> Array:
	var d := def()
	if upgraded and d.has("up_burn"):
		return d["up_burn"]
	return d.get("burn", [])


func can_upgrade() -> bool:
	var d := def()
	return not upgraded and (d.has("up") or d.has("up_burn") or d.has("up_cost"))


func duplicate_card() -> Card:
	return Card.new(id, upgraded)
