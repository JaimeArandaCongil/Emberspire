extends Node
## Fase 1 · MV — exportador de revisión: construye las salas del acto 1 (BgAct1) y compone las capas.
## Ejecutar con ventana: Godot --path . res://tests/_review_art/v04/mundo_vivo/fase1_export.tscn

const OUT := "res://tests/_review_art/v04/mundo_vivo/out/fase1/"
const PER := "res://tests/_review_art/v04/personajes/out/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var args := OS.get_cmdline_user_args()
	var only := args[0] if args.size() > 0 else ""
	var t0 := Time.get_ticks_msec()
	if only == "" or only == "normal":
		_room("normal", 4, 0)
	if only == "" or only == "flue":
		_room("flue", 10, 0)
	if only == "vars":
		_variants()
	if only == "strip":
		_strip()
	print("fase1_export: %d ms" % [Time.get_ticks_msec() - t0])
	get_tree().quit()


func compose(room: Dictionary, par: int = 0) -> Image:
	var img := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	img.fill(Color("0b0709"))
	for L: Dictionary in room["layers"]:
		var pre: Image = L["preview"]
		var m: int = L["margin"]
		var p: int = L["parallax"]
		img.blend_rect(pre, Rect2i(0, 0, pre.get_width(), pre.get_height()), Vector2i(-m + p * par, 0))
		if L["name"] == "mid":
			for fl: Dictionary in room["flicker"]:
				pass
	return img


func with_actors(img: Image, room: Dictionary) -> Image:
	var o := img.duplicate() as Image
	# Forja provisional (sprite v0.3 ×2) en su zona; la grande de DA/MV llega en la fase 2.
	var fg := Art.forge_sprite(0.75, 0).get_image()
	fg.convert(Image.FORMAT_RGBA8)
	fg.resize(fg.get_width() * 2, fg.get_height() * 2, Image.INTERPOLATE_NEAREST)
	o.blend_rect(fg, Rect2i(Vector2i.ZERO, fg.get_size()), Vector2i(-8, 264 - fg.get_height() + 2))
	for pair: Array in [["fogonera_idle_x1.png", 114], ["golem_idle_x1.png", 410]]:
		var path: String = PER + String(pair[0])
		if FileAccess.file_exists(path):
			var im := Image.load_from_file(ProjectSettings.globalize_path(path))
			im.convert(Image.FORMAT_RGBA8)
			o.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(int(pair[1]), 264 - im.get_height() + 2))
	# Zonas de interfaz atenuadas: HUD 0–15 y mano desde 296.
	for y in 360:
		if y >= 16 and y < 296:
			continue
		for x in 640:
			var c := o.get_pixel(x, y)
			o.set_pixel(x, y, Color(c.r * 0.45, c.g * 0.45, c.b * 0.45, 1.0))
	return o


func up(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c


func _room(kind: String, fl: int, cyc: int) -> void:
	var t0 := Time.get_ticks_msec()
	var room := BgAct1.build(kind, fl, cyc)
	print("%s piso %d: %d ms" % [kind, fl, Time.get_ticks_msec() - t0])
	var img := compose(room)
	up(img, 2).save_png(OUT + "a1_%s_x2.png" % kind)
	up(with_actors(img, room), 2).save_png(OUT + "a1_%s_contexto_x2.png" % kind)
	for L: Dictionary in room["layers"]:
		(L["index"] as Image).save_png(OUT + "a1_%s_%s_index.png" % [kind, L["name"]])


## Tira de los fotogramas reales de AmbientFrames (reposo, inclinada, humo), ×4 sobre muro oscuro.
func _strip() -> void:
	var out := Image.create(8 * 34 + 2, 104, false, Image.FORMAT_RGBA8)
	out.fill(Palette.color(&"brick", 2))
	for k in 8:
		var sm := AmbientFrames.smoke(k).get_image()
		var fl := AmbientFrames.flame(k, -1 if k >= 4 else 0).get_image()
		var bx := 2 + k * 34
		out.blend_rect(sm, Rect2i(Vector2i.ZERO, sm.get_size()), Vector2i(bx + 5, 8))
		out.blend_rect(fl, Rect2i(Vector2i.ZERO, fl.get_size()), Vector2i(bx, 60))
	up(out, 4).save_png(OUT + "anim_brasero_real_8f_x4.png")


func _variants() -> void:
	var imgs: Array = []
	for v: Array in [["normal", 1, 0], ["normal", 9, 0], ["normal", 4, 1], ["flue", 5, 0], ["flue", 10, 0], ["flue", 10, 2]]:
		imgs.append(compose(BgAct1.build(String(v[0]), int(v[1]), int(v[2]))))
	var out := Image.create(640 * 2 + 12, 360 * 3 + 16, false, Image.FORMAT_RGBA8)
	out.fill(Color("101014"))
	for i in imgs.size():
		var im: Image = imgs[i]
		out.blend_rect(im, Rect2i(0, 0, 640, 360), Vector2i(4 + (i % 2) * 644, 4 + (i / 2) * 364))
	out.save_png(OUT + "a1_variantes_x1.png")
