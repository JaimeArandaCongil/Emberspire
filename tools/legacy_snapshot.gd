extends SceneTree
## Huella del arte legado (v0.3): hash de CADA imagen que puede devolver la fachada `Art` para un barrido
## exhaustivo de entradas. Sirve para demostrar que el troceo de art.gd y los cambios de la fachada no alteran
## ni un píxel del arte legado mientras siga en uso.
##
## Uso (headless):
##   godot --headless --path . -s res://tools/legacy_snapshot.gd -- --out=user://legacy.json
##   godot --headless --path . -s res://tools/legacy_snapshot.gd -- --compare=res://tests/art/legacy_hashes.json
## Salida: código 0 si coincide (o si sólo escribe), 1 si hay diferencias.

const DEFAULT_REF := "res://tests/art/legacy_hashes.json"


func _initialize() -> void:
	await process_frame
	var out_path := ""
	var cmp_path := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--compare="):
			cmp_path = a.substr(10)
	var art: Node = root.get_node_or_null("Art")
	if art == null:
		push_error("legacy_snapshot: falta el autoload Art")
		quit(2)
		return
	var hashes := collect(art)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(hashes, "\t", true))
		f.close()
		print("legacy_snapshot: %d imágenes → %s" % [hashes.size(), out_path])
	var code := 0
	if cmp_path != "":
		var diff := compare(hashes, cmp_path)
		for d: String in diff.slice(0, 40):
			print("  ≠ ", d)
		print("legacy_snapshot: %d imágenes, %d diferencias" % [hashes.size(), diff.size()])
		code = 0 if diff.is_empty() else 1
	quit(code)


static func compare(hashes: Dictionary, ref_path: String) -> Array[String]:
	var out: Array[String] = []
	var txt := FileAccess.get_file_as_string(ref_path)
	var ref = JSON.parse_string(txt)
	if not (ref is Dictionary):
		out.append("no se pudo leer " + ref_path)
		return out
	for k: String in ref.keys():
		if not hashes.has(k):
			out.append(k + " (falta)")
		elif hashes[k] != ref[k]:
			out.append(k)
	for k: String in hashes.keys():
		if not ref.has(k):
			out.append(k + " (nuevo)")
	return out


static func _h(img: Image) -> String:
	if img == null:
		return "null"
	var c := img.duplicate() as Image
	if c.get_format() != Image.FORMAT_RGBA8:
		c.convert(Image.FORMAT_RGBA8)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(("%dx%d:" % [c.get_width(), c.get_height()]).to_utf8_buffer())
	ctx.update(c.get_data())
	return ctx.finish().hex_encode()


static func _t(tex: Texture2D) -> String:
	return "null" if tex == null else _h(tex.get_image())


## Barrido exhaustivo de la API pública de imágenes de `Art`.
static func collect(art: Node) -> Dictionary:
	var h := {}
	var icon_ids: Array = art.SPRITES.keys() + art.VARIANTS.keys()
	icon_ids.sort()
	for id: String in icon_ids:
		h["icon:" + id] = _t(art.icon(id))
		h["icon_big:" + id] = _t(art.icon_big(id))
	h["icon:__unknown__"] = _t(art.icon("__no_existe__"))
	h["player"] = _t(art.player())
	h["player_arm"] = _t(art.player_arm())
	var poses: Array = art.POSES.keys() + ["idle_b"]
	for p: String in poses:
		h["player_pose:" + p] = _t(art.player_pose(p))
	var shapes: Array = art.SHAPES.keys() + art.BASES.keys()
	for b: String in art.BASES.keys():
		if not b.begins_with("boss_"):
			shapes.append(b + "@2")
	shapes.sort()
	for sh: String in shapes:
		for biome in 3:
			for cyc in 2:
				var k := "%s:%d:%d" % [sh, biome, cyc]
				h["monster:" + k] = _t(art.monster(sh, "snap", biome, cyc))
				h["monster_glow:" + k] = _t(art.monster_glow(sh, "snap", biome, cyc))
				for pose: String in ["base", "crouch", "stretch"]:
					h["monster_pose:%s:%s" % [k, pose]] = _t(art.monster_pose(sh, "snap", biome, cyc, pose))
					h["monster_pose_glow:%s:%s" % [k, pose]] = _t(art.monster_pose_glow(sh, "snap", biome, cyc, pose))
		h["monster_lift:" + sh] = str(art.monster_lift(sh))
	for biome in 6:
		for cyc in 3:
			h["biome_colors:%d:%d" % [biome, cyc]] = str(art.biome_colors(biome, cyc))
		h["torches:%d" % biome] = str(art.torches(biome))
	for type: String in art.TYPE_ART.keys():
		for rar: String in art.RARITY_GEM.keys():
			for up in [false, true]:
				for m in [0, 1, 3, 5]:
					h["card_frame:%s:%s:%s:%d" % [type, rar, up, m]] = _t(art.card_frame(type, rar, up, m))
	var cards: Dictionary = load("res://scripts/data/card_db.gd").CARDS
	var ids: Array = cards.keys()
	ids.sort()
	for id: String in ids:
		var d: Dictionary = cards[id]
		h["card_art:" + id] = _t(art.card_art(id, d.get("type", "attack"), d.get("icon", "unknown")))
	for a in [false, true]:
		for u in [false, true]:
			h["cost_orb:%s:%s" % [a, u]] = _t(art.cost_orb(a, u))
	h["card_back"] = _t(art.card_back())
	h["card_back_small"] = _t(art.card_back_small())
	for biome in 3:
		for sd in [1, 4, 7, 30]:
			for cyc in 2:
				h["background:%d:%d:%d" % [biome, sd, cyc]] = _t(art.background(biome, sd, cyc))
				h["background_near:%d:%d:%d" % [biome, sd, cyc]] = _t(art.background_near(biome, sd, cyc))
	for heat in [0.0, 0.3, 0.6, 1.0]:
		for fr in 4:
			h["forge_sprite:%s:%d" % [heat, fr]] = _t(art.forge_sprite(heat, fr))
			h["furnace_small:%s:%d" % [heat, fr]] = _t(art.furnace_small(heat, fr))
	for fr in 4:
		h["bonfire:%d" % fr] = _t(art.bonfire(fr))
	for ev: String in art.EVENT_SCENES.keys():
		h["event_art:" + ev] = _t(art.event_art(ev))
	h["event_art:__none__"] = _t(art.event_art("__no_existe__"))
	for kind: String in art.DOOR_COLORS.keys():
		for biome in 3:
			h["door_art:%s:%d" % [kind, biome]] = _t(art.door_art(kind, biome))
	h["logo"] = _t(art.logo())
	return h
