extends SceneTree
## Horneador de salas del acto 1, Forja de combate y ambiente (MV · v0.4). Fuente de verdad: `scripts/art/bg/` y
## `AmbientFrames`. Salida en assets/baked/rooms/, con su propio manifiesto.
##   godot --headless --path . -s res://tools/bake_rooms.gd                hornea todo
##   godot --headless --path . -s res://tools/bake_rooms.gd -- --check     sólo comprueba frescura
## Después: `godot --headless --path . --import` importa los PNG nuevos.
## Capas: sky (común), far_<tipo> y fore (comunes), mid_<tipo>_v<n>_c<banda> por variante. Cada variante tiene `<id>.txt`.

const Baker = preload("res://tools/bake_art.gd")
const DIR := BakedRooms.DIR
const MANIFEST := BakedRooms.MANIFEST
const SOURCES := ["res://scripts/art/bg/bg_act1.gd", "res://scripts/art/bg/bg_canvas.gd", "res://scripts/art/bg/bg_ramps.gd",
	"res://scripts/art/bg/bg_forge.gd", "res://scripts/art/bg/baked_rooms.gd", "res://scripts/ui/world/ambient/ambient_frames.gd",
	"res://scripts/art/rig/index_format.gd", "res://scripts/art/palette.gd", "res://tools/bake_rooms.gd"]
const ATLAS_WIDTH := 512
const FLAME_SIZES := [0.8, 0.9, 1.0, 1.1]
const CRUCIBLE_LEN := 66


func _initialize() -> void:
	await process_frame
	if OS.get_cmdline_user_args().has("--check"):
		var errs := freshness_errors()
		for e in errs:
			print("  ✗ ", e)
		print("bake_rooms --check: %s" % ("al día" if errs.is_empty() else "%d errores" % errs.size()))
		quit(0 if errs.is_empty() else 1)
		return
	var t0 := Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var files: Array[String] = []
	AmbientFrames.use_baked = false
	bake_rooms(files)
	bake_forge(files)
	bake_ambient(files)
	files.sort()
	var f := FileAccess.open(MANIFEST, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hash": source_hash(), "files": files}, "\t"))
	f.close()
	print("bake_rooms: %d archivos horneados, %.1f s" % [files.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	quit(0)


## Los archivos comunes se escriben una vez; si dos variantes los producen distintos, es un error de generación.
func bake_rooms(files: Array[String]) -> void:
	var shared := {}
	for kind: String in BakedRooms.VARIANT_FLOORS:
		var floors: Array = BakedRooms.VARIANT_FLOORS[kind]
		for v in floors.size():
			for band in 2:
				var r := BgAct1.build(kind, int(floors[v]), band, false)
				var id := BakedRooms.room_id(kind, v, band)
				var layers := {}
				for L: Dictionary in r["layers"]:
					var name: String = L["name"]
					var file := "mid_" + id
					if name == "sky" or name == "fore":
						file = name
					elif name == "far":
						file = "far_" + kind
					layers[name] = {"file": file, "margin": int(L["margin"]), "parallax": int(L["parallax"])}
					var data: PackedByteArray = (L["index"] as Image).get_data()
					if shared.has(file):
						if shared[file] != data:
							push_error("bake_rooms: la capa común %s difiere entre variantes" % file)
						continue
					shared[file] = data
					save_pair(file, L["index"], L["preview"], files)
				write_text(DIR + id + ".txt", var_to_str({"id": id, "floor": int(floors[v]), "anchors": r["anchors"], "layers": layers}), files)


func bake_forge(files: Array[String]) -> void:
	var forge := BgForge.build()
	var base: Dictionary = forge["base"]
	var entries: Array = [["base", 0, base, Vector2i.ZERO]]
	var frames: Dictionary = forge["frames"]
	for fname: String in frames:
		var offset := Vector2i.ZERO
		if fname.begins_with("mouth") or fname == "swallow" or fname.begins_with("flash"):
			offset = BgForge.MOUTH_RECT.position
		elif fname.begins_with("lick"):
			offset = BgForge.GAP_RECT.position
		var list: Array = frames[fname]
		for i in list.size():
			entries.append([fname, i, list[i], offset])
	var pack := pack_atlas(entries)
	save_pair("forge", pack["index"], pack["preview"], files)
	var offsets := {}
	for e: Array in entries:
		offsets[e[0]] = e[3]
	write_text(DIR + "forge.txt", var_to_str({"rects": pack["rects"], "offsets": offsets}), files)


func bake_ambient(files: Array[String]) -> void:
	AmbientFrames.clear_cache()
	var keys: Array = []
	for k in 8:
		for lean: int in [0, -1]:
			for size: float in FLAME_SIZES:
				AmbientFrames.flame(k, lean, size, true)
				keys.append(AmbientFrames.flame_key(k, lean, size, false))
			AmbientFrames.flame(k, lean, 1.0, true, true)
			keys.append(AmbientFrames.flame_key(k, lean, 1.0, true))
		for dens: int in [0, 1]:
			AmbientFrames.smoke(k, dens, true)
			keys.append(AmbientFrames.smoke_key(k, dens))
	for k in 16:
		for amp: int in [7, 11]:
			for glow: int in [0, 1]:
				AmbientFrames.crucible(k, CRUCIBLE_LEN, amp, glow, true)
				keys.append(AmbientFrames.crucible_key(k, CRUCIBLE_LEN, amp, glow))
	var entries: Array = []
	for key: String in keys:
		var idx: Image = AmbientFrames.index_image(key)
		entries.append([key, 0, {"index": idx, "preview": IndexFormat.preview(idx)}, Vector2i.ZERO])
	var pack := pack_atlas(entries)
	save_pair("ambient", pack["index"], pack["preview"], files)
	write_text(DIR + "ambient.txt", var_to_str({"rects": pack["rects"]}), files)
	AmbientFrames.clear_cache()


## Empaquetado por estantes. `entries`: [nombre, i, {index, preview}, desplazamiento].
func pack_atlas(entries: Array) -> Dictionary:
	var rects := {}
	var x := 0
	var y := 0
	var shelf := 0
	for e: Array in entries:
		var im: Image = e[2]["index"]
		if x + im.get_width() > ATLAS_WIDTH:
			x = 0
			y += shelf
			shelf = 0
		if not rects.has(e[0]):
			rects[e[0]] = []
		(rects[e[0]] as Array).append(Rect2i(x, y, im.get_width(), im.get_height()))
		x += im.get_width()
		shelf = maxi(shelf, im.get_height())
	var idx := Image.create(ATLAS_WIDTH, y + shelf, false, Image.FORMAT_RGBA8)
	var pre := Image.create(ATLAS_WIDTH, y + shelf, false, Image.FORMAT_RGBA8)
	idx.fill(Color(0, 0, 0, 0))
	pre.fill(Color(0, 0, 0, 0))
	var used := {}
	for e: Array in entries:
		var i: int = used.get(e[0], 0)
		used[e[0]] = i + 1
		var rc: Rect2i = rects[e[0]][i]
		var src: Image = e[2]["index"]
		idx.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), rc.position)
		var p: Image = e[2]["preview"]
		pre.blit_rect(p, Rect2i(Vector2i.ZERO, p.get_size()), rc.position)
	return {"index": idx, "preview": pre, "rects": rects}


func save_pair(file: String, idx: Image, pre: Image, files: Array[String]) -> void:
	for pair: Array in [["_idx.png", idx], ["_prev.png", pre]]:
		var path: String = DIR + file + String(pair[0])
		(pair[1] as Image).save_png(path)
		Baker.write_import(path)
		files.append(path)


func write_text(path: String, text: String, files: Array[String]) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	files.append(path)


static func source_hash() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for p: String in SOURCES:
		if FileAccess.file_exists(p):
			ctx.update(FileAccess.get_file_as_string(p).replace("\r\n", "\n").to_utf8_buffer())
		ctx.update(("|" + p + "\n").to_utf8_buffer())
	return ctx.finish().hex_encode()


## Prueba de frescura: las fuentes no han cambiado desde el horneado y están todos los archivos.
static func freshness_errors() -> Array[String]:
	var errs: Array[String] = []
	if not FileAccess.file_exists(MANIFEST):
		return ["falta %s: ejecuta tools/bake_rooms.gd" % MANIFEST]
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not (m is Dictionary):
		return ["manifiesto ilegible: %s" % MANIFEST]
	if String((m as Dictionary).get("hash", "")) != source_hash():
		errs.append("las fuentes cambiaron desde el último horneado: ejecuta tools/bake_rooms.gd")
	for f: Variant in (m as Dictionary).get("files", []):
		if not FileAccess.file_exists(String(f)):
			errs.append("falta %s" % f)
	return errs
