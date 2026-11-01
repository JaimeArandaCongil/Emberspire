extends Control
## Demostración de WorldView + palette_lit + LightRig + SpriteBank (TEC · v0.4).
## Ejecutar con ventana:  godot --path . res://tests/art/tec_world_demo.tscn
## Capturas y salida:     godot --path . res://tests/art/tec_world_demo.tscn -- --shots   → tests/art/out/world_demo_*.png
## Ratón: mueve una luz fría. Clic: onda de quemar carta. Teclas 1/2/3: calor de la Forja bajo/medio/alto; H: PV bajos.

const OUT := "res://tests/art/out/"
const FLOOR_Y := 264
const SLOTS := [350, 460, 572]

var wv: WorldView
var cursor_light := -1
var intent_labels: Array[Label] = []
var golems: Array[AnimatedSprite2D] = []


func _ready() -> void:
	wv = WorldView.new()
	add_child(wv)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = ImageTexture.create_from_image(build_room())
	bg.material = wv.lit_material
	wv.world.add_child(bg)
	var meta := SpriteBank.meta(&"golem_example")
	for i in SLOTS.size():
		var g := wv.make_baked_sprite(&"golem_example", &"idle", &"chained" if i == 1 else &"")
		var sz: Array = meta.get("size", [96, 96])
		g.position = Vector2(SLOTS[i] - int(sz[0]) / 2, FLOOR_Y - 88)
		g.frame = i * 3
		wv.world.add_child(g)
		golems.append(g)
		var lb := Label.new()
		lb.text = "⚔ 12"
		lb.add_theme_color_override("font_color", Color("ffb43a"))
		add_child(lb)
		intent_labels.append(lb)
	cursor_light = wv.lights.add_light(Vector2(500, 120), 110.0, 2.0, true)
	wv.lights.add_light(Vector2(604, 150), 90.0, 1.0)
	if "--shots" in OS.get_cmdline_user_args():
		_shots.call_deferred()


func _process(_delta: float) -> void:
	for i in golems.size():
		var g := golems[i]
		var s: Variant = SpriteBank.socket(&"golem_example", &"idle", g.frame, &"intent")
		var p: Vector2 = g.position + (Vector2(s) if s != null else Vector2(48, 0))
		intent_labels[i].position = wv.world_to_ui(p) - Vector2(16, 24)


func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		wv.lights.move_light(cursor_light, wv.ui_to_world((ev as InputEventMouseMotion).position))
	elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
		wv.lights.burn()
	elif ev is InputEventKey and (ev as InputEventKey).pressed:
		match (ev as InputEventKey).keycode:
			KEY_1: wv.lights.heat = 0.1
			KEY_2: wv.lights.heat = 0.5
			KEY_3: wv.lights.heat = 1.0
			KEY_H: wv.lights.low_hp = 0.0 if wv.lights.low_hp > 0.0 else 0.9


## Sala de prueba en formato ÍNDICE: muro de ladrillo con ancla por ladrillo, suelo de losas y boca de Forja emisiva.
## (Los fondos de verdad son de MV, scripts/art/bg/; esto sólo ejercita el formato y el shader.)
static func build_room() -> Image:
	var W := 640
	var H := 360
	var img := IndexFormat.blank(W, H)
	var brick := Palette.index(&"brick")
	var stone := Palette.index(&"stone")
	var fire := Palette.index(&"fire")
	var forge := Vector2(60, 226)
	for y in H:
		for x in W:
			var m := brick
			var s := 0
			var f := 0
			var anc := Vector2i(x, y)
			if y >= FLOOR_Y:
				var ty := (y - FLOOR_Y) / 12
				var off := ty * 13
				var tx := (x + off) / 32
				var edge := (y - FLOOR_Y) % 12 == 0 or (x + off) % 32 == 0
				m = stone
				s = 1 if edge else 3 + int(_h(tx, ty + 99) * 2.0)
				f = IndexFormat.F_JOINT if edge else 0
				anc = Vector2i(tx * 32 - off + 16, FLOOR_Y + ty * 12 + 6)
			else:
				var by := y / 8
				var sh := 8 if by % 2 == 1 else 0
				var bx := (x + sh) / 16
				var lx := (x + sh) % 16
				var ly := y % 8
				anc = Vector2i(bx * 16 - sh + 8, by * 8 + 4)
				if lx == 0 or ly == 0:
					s = 1
					f = IndexFormat.F_JOINT
				else:
					s = 2 + int(_h(bx, by) * 2.0)
					if ly == 1:
						s += 1
						f = IndexFormat.F_BEVEL
			if s > 0:
				# luz nominal de la Forja horneada por PIEZA (en el ancla)
				var lit := 4.0 * maxf(0.0, 1.0 - Vector2(anc).distance_to(forge) / 420.0)
				s = clampi(s + int(round(lit)), 1, Palette.steps(Palette.material_at(m)) - 1)
			var d := Vector2(x, y).distance_to(forge)
			if y < FLOOR_Y and d < 34.0:
				m = fire
				s = clampi(7 - int(d / 5.0), 1, 7)
				f = IndexFormat.F_EMISSIVE
				anc = Vector2i(forge)
			elif y < FLOOR_Y and d < 37.0:
				m = 0
				s = 0
				f = 0
			img.set_pixel(x, y, IndexFormat.pack(m, s, f, anc - Vector2i(x, y)))
	return img


static func _h(x: int, y: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	wv.lights.flicker_amp = 0.0
	var states := [
		["a_base", 0.5, 0.0, -1.0, Vector2(500, 120)],
		["b_forja_alta", 1.0, 0.0, -1.0, Vector2(500, 120)],
		["c_forja_baja_pv_bajos", 0.1, 0.9, -1.0, Vector2(500, 120)],
		["d_quemar_t015", 0.6, 0.0, 0.15, Vector2(500, 120)],
		["e_quemar_t035", 0.6, 0.0, 0.35, Vector2(500, 120)],
		["f_luz_fria_sobre_golem", 0.5, 0.0, -1.0, Vector2(470, 200)],
	]
	for st: Array in states:
		wv.lights.heat = st[1]
		wv.lights.low_hp = st[2]
		wv.lights.move_light(cursor_light, st[4])
		if st[3] >= 0.0:
			wv.lights.burn()
			wv.lights._burn_t = st[3]
		for g in golems:
			g.pause()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if st[3] >= 0.0:
			wv.lights._burn_t = st[3]
			wv.lights._push()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT + "world_demo_%s.png" % st[0])
	# coste: 300 fotogramas sin vsync
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for g in golems:
		g.play(&"idle")
	RenderingServer.viewport_set_measure_render_time(wv.viewport.get_viewport_rid(), true)
	var gpu := 0.0
	var t0 := Time.get_ticks_usec()
	for k in 300:
		if k % 60 == 0:
			wv.lights.burn()
		await RenderingServer.frame_post_draw
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(wv.viewport.get_viewport_rid())
	print("tec_world_demo: %.3f ms/fotograma · GPU mundo %.3f ms · %s" % [(Time.get_ticks_usec() - t0) / 300000.0, gpu / 300.0,
		ProjectSettings.get_setting("rendering/renderer/rendering_method")])
	get_tree().quit()
