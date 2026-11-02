class_name BakedRooms
extends RefCounted
## Salas del acto 1 y Forja de combate horneadas (MV · v0.4). En juego nada se genera: todo sale de `assets/baked/rooms/`,
## escrito por `tools/bake_rooms.gd`. Variantes (docs/DECISIONES.md): 4 de sala normal y 2 de tiro, cada una para ciclo I
## y ciclo II+ (los ciclos posteriores usan II). Piso → variante por hash determinista.

const DIR := "res://assets/baked/rooms/"
const MANIFEST := DIR + "manifest.json"
## Piso representativo de cada variante: decide semilla, deterioro y atrezo al hornear.
const VARIANT_FLOORS := {"normal": [2, 4, 7, 9], "flue": [5, 10]}
const FLOORS_PER_CYCLE := 30


static func kind_for(is_elite: bool, is_boss: bool) -> String:
	return "flue" if is_elite or is_boss else "normal"


static func cycle_of_floor(floor_num: int) -> int:
	return maxi(0, (floor_num - 1) / FLOORS_PER_CYCLE)


static func cycle_band(cycle: int) -> int:
	return mini(maxi(cycle, 0), 1)


static func variant_for(kind: String, floor_num: int) -> int:
	var n: int = (VARIANT_FLOORS[kind] as Array).size()
	return mini(int(BgCanvas.hash3(floor_num, 211, 5 if kind == "flue" else 3) * n), n - 1)


static func room_id(kind: String, variant: int, band: int) -> String:
	return "%s_v%d_c%d" % [kind, variant, band]


## Sala lista para `Act1RoomView.build()`, o {} si no está horneada. Sin `cycle`, lo deduce del piso.
static func load_room(kind: String, floor_num: int, cycle: int = -1) -> Dictionary:
	if not VARIANT_FLOORS.has(kind):
		return {}
	var c := cycle if cycle >= 0 else cycle_of_floor(floor_num)
	var id := room_id(kind, variant_for(kind, floor_num), cycle_band(c))
	var meta := read_meta(DIR + id + ".txt")
	if meta.is_empty():
		return {}
	var layers: Array = []
	for name: String in ["sky", "far", "mid", "fore"]:
		var L: Dictionary = (meta["layers"] as Dictionary).get(name, {})
		var idx := load_texture(DIR + String(L.get("file", "")) + "_idx.png")
		var pre := load_texture(DIR + String(L.get("file", "")) + "_prev.png")
		if idx == null or pre == null:
			return {}
		layers.append({"name": name, "margin": int(L["margin"]), "parallax": int(L["parallax"]), "index_tex": idx, "preview_tex": pre})
	return {"kind": kind, "floor": floor_num, "cycle": c, "anchors": meta["anchors"], "layers": layers,
		"flicker": [], "crucible_patches": [], "baked": id}


## {"idx": Texture2D, "prev": Texture2D, "rects": {nombre: [Rect2i]}, "offsets": {nombre: Vector2i}} o {} si falta.
static func load_forge() -> Dictionary:
	var meta := read_meta(DIR + "forge.txt")
	var idx := load_texture(DIR + "forge_idx.png")
	var pre := load_texture(DIR + "forge_prev.png")
	if meta.is_empty() or idx == null or pre == null:
		return {}
	return {"idx": idx, "prev": pre, "rects": meta["rects"], "offsets": meta["offsets"]}


## Metadatos horneados: texto de `var_to_str` (conserva Vector2i y Rect2i).
static func read_meta(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var v: Variant = str_to_var(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}


## Textura del recurso importado o, recién horneado sin importar, leída del archivo.
static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t != null:
			return t
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			return ImageTexture.create_from_image(img)
	return null
