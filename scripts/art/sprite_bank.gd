class_name SpriteBank
extends RefCounted
## Banco de sprites horneados (TEC · v0.4). Sirve los atlas de `assets/baked/` (tools/bake_art.gd) y, si una pieza
## aún no está horneada, cae al arte legado v0.3 de la fachada `Art`. Así el juego arranca y se juega siempre.
##
##   SpriteBank.has(&"soot_golem")                       ¿hay hoja horneada?
##   SpriteBank.frames(&"soot_golem", &"idle")           Array[Texture2D] de ÍNDICE (para palette_lit)
##   SpriteBank.frames(&"soot_golem", &"idle", false)    … de VISTA PREVIA en color (sin shader)
##   SpriteBank.sprite_frames(&"soot_golem")             SpriteFrames con todas las animaciones (índice) y sus ms
##   SpriteBank.socket(&"soot_golem", &"attack", 3, &"hit")   Vector2i en el lienzo del sprite
##   SpriteBank.monster_texture(shape, seed, biome, cycle, pose, use_index)   horneado o legado (respaldo)

const ROOT := "res://assets/baked/"
const GROUPS := ["creatures", "hero", "bosses", "props", "examples"]

static var _meta := {}        # id → Dictionary (o {} si no existe)
static var _tex := {}         # ruta → Texture2D
static var _frames := {}      # clave → Array[Texture2D]


static func _find_meta(id: StringName) -> Dictionary:
	if _meta.has(id):
		return _meta[id]
	var found := {}
	for g: String in GROUPS:
		var p := ROOT + g + "/" + String(id) + ".json"
		if FileAccess.file_exists(p):
			var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
			if m is Dictionary:
				found = m
				found["_dir"] = ROOT + g + "/"
			break
	_meta[id] = found
	return found


static func has(id: StringName) -> bool:
	return not _find_meta(id).is_empty()


static func meta(id: StringName) -> Dictionary:
	return _find_meta(id)


static func has_anim(id: StringName, anim: StringName) -> bool:
	var m := _find_meta(id)
	return not m.is_empty() and (m["anims"] as Dictionary).has(String(anim))


## Textura de un atlas. Usa el recurso importado si existe (exportación) y si no lee el PNG (desarrollo, pruebas).
static func _atlas(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null and FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			img.convert(Image.FORMAT_RGBA8)
			t = ImageTexture.create_from_image(img)
	_tex[path] = t
	return t


## Imagen del atlas (CPU) para pruebas y herramientas.
static func atlas_image(id: StringName, use_index := true, variant: StringName = &"") -> Image:
	var m := _find_meta(id)
	if m.is_empty():
		return null
	return load_image(_path(m, use_index, variant))


## Imagen RGBA8 de un PNG horneado: por el recurso importado si existe; si no, leyendo el archivo (recién horneado).
static func load_image(path: String) -> Image:
	var img: Image = null
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t != null:
			img = t.get_image()
	if img == null and FileAccess.file_exists(path):
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	return img


static func _path(m: Dictionary, use_index: bool, variant: StringName) -> String:
	var suffix := "" if variant == &"" or variant == &"base" else "@" + String(variant)
	return String(m["_dir"]) + String(m["id"]) + suffix + ("_idx.png" if use_index else "_prev.png")


## Fotogramas de una animación como AtlasTexture (sin copias de memoria).
static func frames(id: StringName, anim: StringName, use_index := true, variant: StringName = &"") -> Array[Texture2D]:
	var key := "%s|%s|%s|%s" % [id, anim, use_index, variant]
	if _frames.has(key):
		return _frames[key]
	var out: Array[Texture2D] = []
	var m := _find_meta(id)
	if m.is_empty() or not (m["anims"] as Dictionary).has(String(anim)):
		return out
	var atlas := _atlas(_path(m, use_index, variant))
	if atlas == null:
		return out
	var a: Dictionary = m["anims"][String(anim)]
	var w: int = m["size"][0]
	var h: int = m["size"][1]
	for f in int(a["frames"]):
		var at := AtlasTexture.new()
		at.atlas = atlas
		at.region = Rect2(f * w, int(a["row"]) * h, w, h)
		at.filter_clip = true
		out.append(at)
	_frames[key] = out
	return out


## Jefes multiparte: metadatos de cada parte {id, offset, phase, size, origin, anims, variants}.
static func parts(id: StringName) -> Array:
	var m := _find_meta(id)
	return m.get("parts", []) if not m.is_empty() else []


## Fotogramas de una parte de jefe (cada parte tiene su atlas, su desfase y sus variantes de fase).
static func part_frames(id: StringName, part_id: StringName, anim: StringName, use_index := true, variant: StringName = &"") -> Array[Texture2D]:
	var key := "part|%s|%s|%s|%s|%s" % [id, part_id, anim, use_index, variant]
	if _frames.has(key):
		return _frames[key]
	var out: Array[Texture2D] = []
	var m := _find_meta(id)
	for p: Dictionary in parts(id):
		if String(p["id"]) != String(part_id) or not (p["anims"] as Dictionary).has(String(anim)):
			continue
		var suffix := "" if variant == &"" or variant == &"base" else "@" + String(variant)
		var atlas := _atlas(String(m["_dir"]) + String(id) + "." + String(part_id) + suffix + ("_idx.png" if use_index else "_prev.png"))
		if atlas == null:
			break
		var a: Dictionary = p["anims"][String(anim)]
		var w: int = p["size"][0]
		var h: int = p["size"][1]
		for f in int(a["frames"]):
			var at := AtlasTexture.new()
			at.atlas = atlas
			at.region = Rect2(f * w, int(a["row"]) * h, w, h)
			at.filter_clip = true
			out.append(at)
		break
	_frames[key] = out
	return out


static func frame_ms(id: StringName, anim: StringName) -> Array:
	var m := _find_meta(id)
	if m.is_empty() or not (m["anims"] as Dictionary).has(String(anim)):
		return []
	return m["anims"][String(anim)]["ms"]


## SpriteFrames listo para AnimatedSprite2D (velocidad 1000 → la duración de cada fotograma va en ms/1000 s).
static func sprite_frames(id: StringName, use_index := true, variant: StringName = &"") -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	var m := _find_meta(id)
	if m.is_empty():
		return sf
	for an: String in (m["anims"] as Dictionary).keys():
		var a: Dictionary = m["anims"][an]
		sf.add_animation(an)
		sf.set_animation_loop(an, bool(a["loop"]))
		sf.set_animation_speed(an, 1000.0)
		var fr := frames(id, StringName(an), use_index, variant)
		var ms: Array = a["ms"]
		for i in fr.size():
			sf.add_frame(an, fr[i], float(ms[i]))
	return sf


static func socket(id: StringName, anim: StringName, frame: int, name: StringName) -> Variant:
	var m := _find_meta(id)
	if m.is_empty() or not (m["anims"] as Dictionary).has(String(anim)):
		return null
	var sk: Array = m["anims"][String(anim)]["sockets"]
	if frame < 0 or frame >= sk.size() or not (sk[frame] as Dictionary).has(String(name)):
		return null
	var v: Array = sk[frame][String(name)]
	return Vector2i(int(v[0]), int(v[1]))


## Respaldo para monstruos: fotograma horneado si existe la hoja de `shape`; si no, el arte legado v0.3.
## `pose` legado: base | crouch | stretch → anim horneada idle(0) | attack(0) | attack(último).
static func monster_texture(shape: String, seed_key: String, biome: int, cycle: int, pose: String, use_index := false) -> Texture2D:
	var id := StringName(shape.get_slice("@", 0))
	if has(id):
		var anim := &"idle"
		var f := 0
		if pose == "crouch" and has_anim(id, &"attack"):
			anim = &"attack"
		elif pose == "stretch" and has_anim(id, &"attack"):
			anim = &"attack"
			f = frames(id, anim, use_index).size() - 1
		var fr := frames(id, anim, use_index)
		if f < fr.size():
			return fr[f]
	var art: Node = Engine.get_main_loop().root.get_node_or_null("Art") if Engine.get_main_loop() is SceneTree else null
	if art == null:
		return null
	return art.monster_pose(shape, seed_key, biome, cycle, pose)


## Vacía las cachés (tras volver a hornear en caliente desde una herramienta).
static func clear() -> void:
	_meta.clear()
	_tex.clear()
	_frames.clear()
