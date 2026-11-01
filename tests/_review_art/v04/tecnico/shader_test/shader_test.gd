extends Node
## Prueba C2 (ronda 1): shader de paleta en gl_compatibility, en ventana.
## SubViewport 640×360 mostrado a ×2. Muro + Forja + 3 gólems (índices horneados por el rig de la PoC),
## máscara de luz 80×45 animada en CPU (parpadeo de la Forja, antorcha, pulso de quemar carta).
## Guarda capturas en shader_test/out/ y mide coste (CPU de la máscara, GPU del SubViewport, FPS con/sin shader).

const OUT := "res://tests/_review_art/v04/tecnico/shader_test/out/"
const RIG := preload("res://tests/_review_art/v04/tecnico/rig_poc.gd")
const VW := 640
const VH := 360
const MW := 80
const MH := 45
const FORGE := Vector2(56, 262)
const TORCH := Vector2(604, 176)
const FLOOR_Y := 300

const BRICK := ["0b080e", "140e16", "1e141e", "2b1a26", "3b222c", "522c30", "6e3a32", "965034", "c26e3c"]

var rows: Array = []          # filas de la LUT (Array de Color)
var lookup := {}              # html → Vector2i(fila, paso)
var lut_tex: ImageTexture
var mask_img: Image
var mask_tex: ImageTexture
var mat: ShaderMaterial
var vp: SubViewport
var golem_frames: Array = []  # ImageTexture de índice
var golem_color: Array = []   # ImageTexture de color (comparación sin shader)
var sprites: Array = []
var wall_idx: ImageTexture
var wall_sprite: Sprite2D
var wall_anchor: ImageTexture
var mat_wall: ShaderMaterial
var forge_gain := 1.0
var torch_gain := 1.0
var burn_t := -1.0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	print("renderer: ", ProjectSettings.get_setting("rendering/renderer/rendering_method"), " · ", RenderingServer.get_video_adapter_name(), " · ", RenderingServer.get_video_adapter_api_version())
	_build_lut()
	_bake_golem()
	_build_wall()
	_build_scene()
	mask_img = Image.create(MW, MH, false, Image.FORMAT_R8)
	mask_tex = ImageTexture.create_from_image(mask_img)
	mat.set_shader_parameter("light_mask", mask_tex)
	mat_wall.set_shader_parameter("light_mask", mask_tex)
	await _captures()
	await _perf()
	print("shader_test: OK")
	get_tree().quit()


# ---------------------------------------------------------------- LUT y horneado de índices
func _row(cols: Array) -> int:
	var r: Array = []
	for c in cols:
		r.append(c if c is Color else Color(c))
	rows.append(r)
	var ri := rows.size() - 1
	for s in r.size():
		var key: String = (r[s] as Color).to_html(false)
		if not lookup.has(key):
			lookup[key] = Vector2i(ri, s)
	return ri


func _build_lut() -> void:
	_row([RIG.K])            # 0 contorno
	_row(RIG.ROCK)           # 1
	_row(RIG.HORN)           # 2
	_row(RIG.IRON)           # 3
	_row(RIG.ROCK_WARM)      # 4
	_row(RIG.MAGMA)          # 5 emisivo
	_row(["ff8a3a", "ffb43a", "ffe08a"])   # 6 luz de borde
	_row(BRICK)              # 7 ladrillo
	var img := Image.create(16, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var r: Array = rows[y]
		for x in 16:
			img.set_pixel(x, y, r[mini(x, r.size() - 1)])
	lut_tex = ImageTexture.create_from_image(img)


func _bake_golem() -> void:
	var rig: Node = RIG.new()
	rig._make_seeds()
	var key := {"kind": "dir", "dir": Vector3(-0.70, -0.50, 0.50).normalized(), "rim": Color("ff8a3a"), "warm": true}
	var fdir := Vector3(-0.85, -0.2, 0.5).normalized()
	var miss := 0
	for f in 8:
		var pose: Dictionary = rig._pose_idle(f)
		var col: Image = rig.render(pose, key, f, false)
		var gb: Dictionary = rig.raster(pose)
		var piece: PackedInt32Array = gb["piece"]
		var idx := Image.create(col.get_width(), col.get_height(), false, Image.FORMAT_RGBA8)
		idx.fill(Color(0, 0, 0, 0))
		for y in col.get_height():
			for x in col.get_width():
				var c := col.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var k: String = c.to_html(false)
				var rs: Vector2i = lookup.get(k, Vector2i(-1, -1))
				if rs.x < 0:
					miss += 1
					rs = Vector2i(1, 3)
				var i := y * col.get_width() + x
				var facing := 0.0
				var fixed := rs.x == 0 or rs.x == 5 or rs.x == 6
				if piece[i] >= 0:
					var n: Vector3 = gb["n"][i]
					facing = clampf(n.dot(fdir), 0.0, 1.0)
				else:
					fixed = true   # contorno exterior / estelas
				idx.set_pixel(x, y, Color8(rs.x * 16 + rs.y, int(facing * 255), 255 if fixed else 0, 255))
		golem_frames.append(ImageTexture.create_from_image(idx))
		golem_color.append(ImageTexture.create_from_image(col))
		if f == 0:
			idx.save_png(OUT + "golem_index_f0.png")
	rig.free()
	print("colores fuera de LUT: ", miss)


func _forge_light(p: Vector2, gain: float) -> float:
	return gain * 3.6 * maxf(0.0, 1.0 - p.distance_to(FORGE) / 420.0)


func _h(x: int, y: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)


func _build_wall() -> void:
	var img := Image.create(VW, VH, false, Image.FORMAT_RGBA8)
	var anc := Image.create(VW, VH, false, Image.FORMAT_RGBA8)
	for y in VH:
		for x in VW:
			var row := 7
			var s := 0
			var facing := 0.7
			var fixed := false
			var ap := Vector2(x, y)
			if y >= FLOOR_Y:
				# suelo en losas 32×12 con fuga
				var ty := (y - FLOOR_Y) / 12
				var tx := (x + ty * 13) / 32
				var edge := (y - FLOOR_Y) % 12 == 0 or (x + ty * 13) % 32 == 0
				s = 1 if edge else 2 + int(_h(tx, ty + 99) * 1.6)
				ap = Vector2(tx * 32 - ty * 13 + 16, FLOOR_Y + ty * 12 + 6)
				facing = 1.0
			else:
				var by := y / 8
				var bx := (x + (8 if by % 2 == 1 else 0)) / 16
				var lx := (x + (8 if by % 2 == 1 else 0)) % 16
				var ly := y % 8
				if lx == 0 or ly == 0:
					s = 1
				else:
					s = 2 + int(_h(bx, by) * 1.8)
					if ly == 1:
						s += 1
					elif ly == 7:
						s -= 1
				ap = Vector2(bx * 16 - (8 if by % 2 == 1 else 0) + 8, by * 8 + 4)
			# luz nominal de la Forja HORNEADA (base); la máscara sólo añade la diferencia en tiempo real
			if s > 0:
				s = clampi(s + int(floor(_forge_light(ap, 1.0) * (0.35 + 0.65 * facing) + 0.5)), 1, 8)
			# boca de la Forja (emisiva)
			var d := Vector2(x, y).distance_to(FORGE + Vector2(0, 14))
			if y < FLOOR_Y and d < 30.0:
				row = 5
				s = clampi(5 - int(d / 6.0), 1, 5)
				fixed = true
			elif y < FLOOR_Y and d < 33.0:
				row = 0
				s = 0
				fixed = true
			img.set_pixel(x, y, Color8(row * 16 + s, int(facing * 255), 255 if fixed else 0, 255))
			anc.set_pixel(x, y, Color(clampf(ap.x / VW, 0, 1), clampf(ap.y / VH, 0, 1), 0))
	wall_idx = ImageTexture.create_from_image(img)
	wall_anchor = ImageTexture.create_from_image(anc)


func _build_scene() -> void:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.stretch_shrink = 2
	cont.size = Vector2(1280, 720)
	cont.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(cont)
	vp = SubViewport.new()
	vp.size = Vector2i(VW, VH)
	vp.snap_2d_transforms_to_pixel = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	cont.add_child(vp)
	mat = ShaderMaterial.new()
	mat.shader = load("res://tests/_review_art/v04/tecnico/shader_test/palette_lit.gdshader")
	mat.set_shader_parameter("lut", lut_tex)
	wall_sprite = Sprite2D.new()
	wall_sprite.centered = false
	wall_sprite.texture = wall_idx
	mat_wall = mat.duplicate()
	mat_wall.set_shader_parameter("use_anchor", true)
	mat_wall.set_shader_parameter("anchor_tex", wall_anchor)
	wall_sprite.material = mat_wall
	vp.add_child(wall_sprite)
	for i in 3:
		_add_golem(Vector2(300 + i * 110, FLOOR_Y + 6 - 84), i * 3)


func _add_golem(pos: Vector2, phase: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.position = pos
	s.texture = golem_frames[phase % 8]
	s.material = mat
	s.set_meta("phase", phase)
	vp.add_child(s)
	sprites.append(s)
	return s


# ---------------------------------------------------------------- máscara de luz (CPU)
func _update_mask() -> void:
	var r := 0.0
	var fade := 0.0
	if burn_t >= 0.0:
		r = burn_t * 1100.0
		fade = clampf(1.0 - burn_t / 0.6, 0.0, 1.0)
	for my in MH:
		for mx in MW:
			var p := Vector2((mx + 0.5) * 8.0, (my + 0.5) * 8.0)
			var L := _forge_light(p, forge_gain) - _forge_light(p, 1.0)
			L += torch_gain * 2.2 * maxf(0.0, 1.0 - p.distance_to(TORCH) / 150.0) - 0.9 * maxf(0.0, 1.0 - p.distance_to(TORCH) / 150.0)
			if fade > 0.0:
				var dd := (p.distance_to(FORGE) - r) / 40.0
				L += 2.6 * fade * exp(-dd * dd)
			mask_img.set_pixel(mx, my, Color(clampf((L + 2.0) / 6.0, 0.0, 1.0), 0, 0))
	mask_tex.update(mask_img)


func _set_frame(f: int) -> void:
	for s: Sprite2D in sprites:
		s.texture = golem_frames[(f + int(s.get_meta("phase"))) % 8]


# ---------------------------------------------------------------- capturas
func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")


func _captures() -> void:
	var states := [
		["s0_base", 1.0, 1.0, -1.0, 0, true, 0],
		["s1_forja_baja", 0.72, 0.8, -1.0, 0, true, 1],
		["s2_forja_alta", 1.3, 1.25, -1.0, 0, true, 2],
		["s3_quemar_t010", 1.15, 1.0, 0.10, 2, true, 3],
		["s4_quemar_t025", 1.15, 1.0, 0.25, 2, true, 4],
		["s5_quemar_t040", 1.1, 1.0, 0.40, 1, true, 5],
		["s6_quemar_t055", 1.05, 1.0, 0.55, 1, true, 6],
		["s7_sin_mascara", 1.0, 1.0, -1.0, 0, false, 7],
	]
	for st: Array in states:
		forge_gain = st[1]
		torch_gain = st[2]
		burn_t = st[3]
		for m: ShaderMaterial in [mat, mat_wall]:
			m.set_shader_parameter("emit_boost", st[4])
			m.set_shader_parameter("use_mask", st[5])
		_set_frame(st[6])
		_update_mask()
		await _grab(st[0])
	mat.set_shader_parameter("emit_boost", 0)
	mat.set_shader_parameter("use_mask", true)


# ---------------------------------------------------------------- coste
func _perf() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	# 60 gólems más (63 + muro) para estresar
	for i in 60:
		_add_golem(Vector2((i * 37) % 560, 120 + (i * 53) % 160), i)
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	var res := {}
	for mode in ["sin_shader", "shader"]:
		for s: Sprite2D in sprites:
			s.material = mat if mode == "shader" else null
		wall_sprite.material = mat_wall if mode == "shader" else null
		var mask_us := 0
		var gpu := 0.0
		var cpu := 0.0
		var n := 0
		for k in 30:
			await RenderingServer.frame_post_draw
		var t0 := Time.get_ticks_usec()
		for k in 400:
			forge_gain = 0.8 + 0.4 * _h(k, 1)
			burn_t = fposmod(k / 60.0, 1.2) if k % 120 < 60 else -1.0
			var m0 := Time.get_ticks_usec()
			_update_mask()
			mask_us += Time.get_ticks_usec() - m0
			if mode == "sin_shader":
				for s: Sprite2D in sprites:
					s.texture = golem_color[(k / 9 + int(s.get_meta("phase"))) % 8]
			else:
				_set_frame(k / 9)
			await RenderingServer.frame_post_draw
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid())
			n += 1
		var dt := (Time.get_ticks_usec() - t0) / 1000.0 / n
		res[mode] = [dt, gpu / n, cpu / n, mask_us / 1000.0 / n]
		print("%s: %.3f ms/fotograma total · GPU SubViewport %.3f ms · CPU render %.3f ms · máscara CPU %.3f ms (64 sprites)" % [mode, dt, gpu / n, cpu / n, mask_us / 1000.0 / n])
	await _grab("s8_estres_64_sprites")
