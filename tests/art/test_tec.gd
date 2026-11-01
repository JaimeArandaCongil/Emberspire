extends RefCounted
## Pruebas del artista técnico (TEC · v0.4). `run() -> Array` devuelve los fallos.
##  1. Fachada: el arte legado v0.3 es idéntico píxel a píxel a la huella (tests/art/legacy_hashes.json).
##  2. Frescura: todas las hojas horneadas están al día con sus fuentes (assets/baked/manifest.json).
##  3. Determinismo e imagen dorada (PER-7): renderizar dos veces da los mismos bytes, y coincide con el atlas versionado.
##  4. Reglas como errores de horneado: RigLint detecta cada condición de PER y de DA en definiciones defectuosas.
##  5. Formato de índice: empaquetado ida y vuelta; las hojas horneadas son válidas y su vista previa coincide.
##  6. Shader y globales: cada `global uniform` de palette_lit está declarado en project.godot.
##  7. WorldView: conversión mundo ↔ interfaz exacta; LightRig: pasos en el punto.
##  8. Siluetas distintas entre criaturas horneadas (PER-12).
##  9. Jefe multiparte con desfase y fase 2 (PER-10); primitivas box/poly/slab con bisel (PER-6).

const Snapshot = preload("res://tools/legacy_snapshot.gd")
const Baker = preload("res://tools/bake_art.gd")
const Example = preload("res://scripts/art/rig/examples/golem_example.gd")


func run() -> Array:
	var f: Array = []
	f.append_array(check_legacy())
	f.append_array(check_freshness())
	f.append_array(check_determinism())
	f.append_array(check_lint())
	f.append_array(check_index_format())
	f.append_array(check_shader_globals())
	f.append_array(check_world_view())
	f.append_array(check_silhouettes())
	f.append_array(check_multipart())
	return f


# 1 ---------------------------------------------------------------------------------------------
func check_legacy() -> Array:
	var art: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Art")
	if art == null:
		return ["[TEC fachada] falta el autoload Art"]
	var diff := Snapshot.compare(Snapshot.collect(art), "res://tests/art/legacy_hashes.json")
	var out: Array = []
	for d in diff.slice(0, 10):
		out.append("[TEC fachada] el arte legado cambió: " + d)
	if diff.size() > 10:
		out.append("[TEC fachada] … %d diferencias en total" % diff.size())
	return out


# 2 ---------------------------------------------------------------------------------------------
func check_freshness() -> Array:
	var out: Array = []
	for e in Baker.freshness_errors():
		out.append("[TEC frescura] " + e)
	return out


# 3 ---------------------------------------------------------------------------------------------
func check_determinism() -> Array:
	var out: Array = []
	var d1: RigDef = Example.build()
	var d2: RigDef = Example.build()
	for an: StringName in [&"idle", &"attack"]:
		for fr in [0, 2, 3]:
			var a := RigRenderer.render(d1, an, fr, {})
			var b := RigRenderer.render(d2, an, fr, {})
			if a.index.get_data() != b.index.get_data():
				out.append("[TEC PER-7] %s:%d no es determinista" % [an, fr])
	# imagen dorada: el atlas versionado es exactamente lo que produce el motor hoy
	var sheet := Baker.bake_sheet(Example.build(), {}, {})
	var gold := SpriteBank.atlas_image(&"golem_example")
	if gold == null:
		out.append("[TEC PER-7] falta el atlas dorado de golem_example (hornear con tools/bake_art.gd)")
	elif (sheet["index"] as Image).get_data() != gold.get_data():
		out.append("[TEC PER-7] el atlas de golem_example no coincide con el render actual (¿motor cambiado sin rehornear?)")
	return out


# 4 ---------------------------------------------------------------------------------------------
func _base() -> RigBuilder:
	var b := RigBuilder.new(&"lint_case", Vector2i(48, 48), Vector2i(24, 30))
	b.material(&"skin", &"skin")
	b.bone(&"root", &"", Vector2.ZERO)
	b.ell(&"body", &"root", &"skin", Vector3.ZERO, Vector3(6, 8, 5))
	b.anim(&"idle", 2, 150, {0: {}, 1: {&"root": 0.05}})
	return b


func _expect(name: String, b: RigBuilder, needle: String) -> Array:
	var errs := RigLint.check(b.def)
	for e in errs:
		if needle in e:
			return []
	return ["[TEC lint] %s: no detectó '%s' (errores: %s)" % [name, needle, errs]]


func check_lint() -> Array:
	var out: Array = []
	var ok := _base()
	if not RigLint.check(ok.def).is_empty():
		out.append("[TEC lint] una definición correcta da errores: %s" % RigLint.check(ok.def))
	var ex := RigLint.check(Example.build())
	if not ex.is_empty():
		out.append("[TEC lint] el ejemplo de referencia no pasa: %s" % ex)
	var b1 := _base()
	b1.material(&"bad", &"magenta_hsv")
	out.append_array(_expect("PER-1", b1, "PER-1"))
	var b2 := _base()
	b2.ell(&"head", &"root", &"skin", Vector3(0, -10, 0), Vector3(4, 4, 4), {"tags": [&"face"]})
	out.append_array(_expect("PER-2", b2, "PER-2"))
	var b3 := _base()
	b3.ell(&"blob", &"root", &"skin", Vector3.ZERO, Vector3(12, 12, 10))
	out.append_array(_expect("PER-3", b3, "PER-3"))
	var b4 := _base()
	b4.patch(&"idle", 0, &"root", Vector2.ZERO, ["kkkkkkkkkkkkkkkk"], {"k": [&"skin", "LINE"]})
	out.append_array(_expect("PER-6", b4, "PER-6"))
	var b5 := _base()
	b5.material(&"stone", &"stone", {"facet": {"cell_area": 40.0}})
	out.append_array(_expect("DA facetas", b5, "sólo en carbón"))
	var b6 := _base()
	b6.material(&"coal", &"coal", {"facet": {"cell_area": 10.0}})
	out.append_array(_expect("DA celda", b6, "< 24"))
	var b7 := _base()
	b7.material(&"x", &"skin", {"planes": 5})
	out.append_array(_expect("DA planos", b7, "planos"))
	var b8 := RigBuilder.new(&"tiny", Vector2i(24, 20), Vector2i(12, 14))
	b8.material(&"skin", &"skin")
	b8.bone(&"root", &"", Vector2.ZERO)
	b8.ell(&"body", &"root", &"skin", Vector3.ZERO, Vector3(4, 4, 4))
	out.append_array(_expect("modo pequeño", b8, "modo pequeño"))
	var b9 := _base()
	b9.anim(&"bad", 2, 100, {0: {&"no_such_bone": 0.3}})
	out.append_array(_expect("hueso inexistente", b9, "no es un hueso"))
	# el modo pequeño correcto pasa y se renderiza con los pasos forzados de la losa
	var sm := RigBuilder.new(&"tiny_ok", Vector2i(24, 20), Vector2i(12, 14))
	sm.def.small = true
	sm.material(&"skin", &"skin")
	sm.bone(&"root", &"", Vector2.ZERO)
	sm.slab(&"body", &"root", ["..aa..", ".abba.", "abbbba", ".abba."], Vector2(-3, -2), {"a": [&"skin", 2], "b": [&"skin", 4]})
	if not RigLint.check(sm.def).is_empty():
		out.append("[TEC lint] modo pequeño correcto da errores: %s" % RigLint.check(sm.def))
	else:
		var fr := RigRenderer.render_pose(sm.def, {})
		var c := fr.index.get_pixel(12, 13)   # una 'b' de la losa
		if IndexFormat.is_empty(c) or IndexFormat.step_of(c) != 4:
			out.append("[TEC modo pequeño] la losa no conserva su paso forzado (%s)" % c)
	return out


# 5 ---------------------------------------------------------------------------------------------
func check_index_format() -> Array:
	var out: Array = []
	var c := IndexFormat.pack(Palette.index(&"brick"), 7, IndexFormat.F_COLD | IndexFormat.F_JOINT, Vector2i(-5, 12))
	if IndexFormat.material_of(c) != Palette.index(&"brick") or IndexFormat.step_of(c) != 7 \
			or IndexFormat.flags_of(c) != (IndexFormat.F_COLD | IndexFormat.F_JOINT) or IndexFormat.anchor_delta(c) != Vector2i(-5, 12):
		out.append("[TEC índice] empaquetado ida y vuelta incorrecto")
	if IndexFormat.is_empty(IndexFormat.pack(0, 0, 0, Vector2i(0, -127))):
		out.append("[TEC índice] un píxel lleno con ancla −127 se lee como vacío")
	var m := Baker.load_manifest()
	for id: String in (m["entries"] as Dictionary).keys():
		for path: String in m["entries"][id].get("files", []):
			if not path.ends_with("_idx.png"):
				continue
			var img := SpriteBank.load_image(path)
			if img == null:
				out.append("[TEC índice] no se puede leer %s" % path)
				continue
			for e in IndexFormat.validate(img).slice(0, 3):
				out.append("[TEC índice] %s: %s" % [path, e])
			var pv := SpriteBank.load_image(path.replace("_idx.png", "_prev.png"))
			if pv != null:
				if IndexFormat.preview(img).get_data() != pv.get_data():
					out.append("[TEC índice] %s: la vista previa no es la del índice" % path)
	return out


# 6 ---------------------------------------------------------------------------------------------
func check_shader_globals() -> Array:
	var out: Array = []
	var src := FileAccess.get_file_as_string("res://shaders/palette_lit.gdshader")
	if src.is_empty():
		return ["[TEC shader] falta shaders/palette_lit.gdshader"]
	var re := RegEx.create_from_string("global uniform \\w+ (\\w+)")
	for mt in re.search_all(src):
		var n := mt.get_string(1)
		if not ProjectSettings.has_setting("shader_globals/" + n):
			out.append("[TEC shader] el global '%s' no está declarado en project.godot [shader_globals]" % n)
	var lut := Palette.build_lut_image()
	if lut.get_width() != Palette.LUT_W or lut.get_height() != Palette.count() * 2:
		out.append("[TEC shader] LUT de %dx%d" % [lut.get_width(), lut.get_height()])
	return out


# 7 ---------------------------------------------------------------------------------------------
func check_world_view() -> Array:
	var out: Array = []
	var wv := WorldView.new()
	wv.position = Vector2(0, 0)
	for p: Vector2 in [Vector2(0, 0), Vector2(466, 140), Vector2(639, 359)]:
		var ui := wv.world_to_ui(p)
		if ui != p * 2.0:
			out.append("[TEC WorldView] mundo→UI %s = %s (se esperaba %s)" % [p, ui, p * 2.0])
		if wv.ui_to_world(ui + Vector2(1, 1)) != p:
			out.append("[TEC WorldView] UI→mundo no deshace la conversión en %s" % p)
	if wv.viewport.size != WorldView.WORLD_SIZE:
		out.append("[TEC WorldView] SubViewport de %s" % wv.viewport.size)
	wv.free()
	var lr := LightRig.new()
	lr.heat = 1.0
	if lr.steps_at(lr.forge_pos) <= 0.0:
		out.append("[TEC LightRig] calor máximo no ilumina la Forja")
	lr.heat = 0.5
	if absf(lr.steps_at(lr.forge_pos)) > 0.001:
		out.append("[TEC LightRig] el calor nominal debería ser 0 pasos dinámicos (la luz nominal va horneada)")
	lr.free()
	# SpriteBank: hoja horneada si existe; si no, respaldo al arte legado (el juego siempre arranca)
	if not SpriteBank.has(&"golem_example") or SpriteBank.frames(&"golem_example", &"idle").size() != 8:
		out.append("[TEC SpriteBank] no sirve la hoja horneada de golem_example")
	var art: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Art")
	if art != null:
		var legacy: Texture2D = art.monster_pose("slime", "sb", 0, 0, "base")
		if SpriteBank.has(&"slime"):
			pass
		elif SpriteBank.monster_texture("slime", "sb", 0, 0, "base") != legacy:
			out.append("[TEC SpriteBank] sin hoja horneada no cae al arte legado")
	return out


# 8 ---------------------------------------------------------------------------------------------
func check_silhouettes() -> Array:
	var out: Array = []
	var m := Baker.load_manifest()
	var masks := {}
	for id: String in (m["entries"] as Dictionary).keys():
		var g: String = m["entries"][id].get("group", "")
		if g != "creatures" and g != "bosses":
			continue
		var fr := SpriteBank.frames(StringName(id), &"idle", false)
		if fr.is_empty():
			continue
		var img := (fr[0] as AtlasTexture).atlas.get_image().get_region(Rect2i((fr[0] as AtlasTexture).region))
		masks[id] = img
	var ids := masks.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var v := silhouette_iou(masks[ids[i]], masks[ids[j]])
			if v > 0.85:
				out.append("[TEC siluetas] %s y %s comparten silueta (IoU %.2f > 0,85)" % [ids[i], ids[j], v])
	# la propia medida: idéntica = 1, disjunta = 0
	var p := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	var q := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	p.fill_rect(Rect2i(0, 0, 2, 4), Color.WHITE)
	q.fill_rect(Rect2i(2, 0, 2, 4), Color.WHITE)
	if silhouette_iou(p, p) != 1.0 or silhouette_iou(p, q) != 0.0:
		out.append("[TEC siluetas] la medida IoU es incorrecta")
	return out


static func silhouette_iou(a: Image, b: Image) -> float:
	var inter := 0
	var uni := 0
	for y in mini(a.get_height(), b.get_height()):
		for x in mini(a.get_width(), b.get_width()):
			var pa := a.get_pixel(x, y).a > 0.0
			var pb := b.get_pixel(x, y).a > 0.0
			inter += int(pa and pb)
			uni += int(pa or pb)
	return 0.0 if uni == 0 else float(inter) / uni


# 9 ---------------------------------------------------------------------------------------------
## Jefe multiparte (PER-10) y primitivas box/poly/slab con bisel (PER-6): la hoja existe y cada parte se ve.
func check_multipart() -> Array:
	var out: Array = []
	var ps := SpriteBank.parts(&"boss_example")
	if ps.size() != 2:
		return ["[TEC multiparte] boss_example debería tener 2 partes (tiene %d)" % ps.size()]
	for p: Dictionary in ps:
		if SpriteBank.part_frames(&"boss_example", StringName(p["id"]), &"idle").is_empty():
			out.append("[TEC multiparte] sin fotogramas de %s" % p["id"])
	if int(ps[1]["phase"]) != 3:
		out.append("[TEC multiparte] se perdió el desfase de la parte")
	var base := SpriteBank.part_frames(&"boss_example", &"boss_door", &"idle", false)
	var ph2 := SpriteBank.part_frames(&"boss_example", &"boss_door", &"idle", false, &"phase2")
	if base.is_empty() or ph2.is_empty():
		out.append("[TEC multiparte] falta la variante de fase 2")
	elif (base[0] as AtlasTexture).atlas.get_image().get_data() == (ph2[0] as AtlasTexture).atlas.get_image().get_data():
		out.append("[TEC multiparte] la fase 2 no cambia la imagen")
	# cada primitiva biselada pinta y da más de un tono (el bisel existe)
	var door: RigDef = (load("res://scripts/art/rig/examples/boss_example.gd") as GDScript).call("door")
	for pc: StringName in [&"frame_box", &"plate_poly", &"rune_slab"]:
		var one := RigRenderer.render_pose(_only(door, pc), {}, {&"door_shut": true})
		var tones := {}
		for y in one.index.get_height():
			for x in one.index.get_width():
				var c := one.index.get_pixel(x, y)
				if not IndexFormat.is_empty(c) and IndexFormat.material_of(c) != 0:
					tones[IndexFormat.step_of(c)] = true
		if tones.size() < 2:
			out.append("[TEC primitivas] %s sale plana (%d tonos)" % [pc, tones.size()])
	return out


func _only(d: RigDef, id: StringName) -> RigDef:
	var c := RigDef.new()
	c.id = d.id
	c.size = d.size
	c.origin = d.origin
	c.bones = d.bones
	c.materials = d.materials
	for pc in d.pieces:
		if pc.id == id:
			c.pieces.append(pc)
	return c
