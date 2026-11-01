extends Node2D
## Fase 1 · MV — la sala viva EN EL MOTOR: Act1RoomView + ambiente + ArtParticles corriendo de verdad.
## Captura el viewport (1280×720 = 640×360 ×2) y guarda hoja de fotogramas + GIF animado.
## Uso: Godot --path . res://tests/_review_art/v04/mundo_vivo/fase1_live.tscn -- <normal|flue> [piso] [ciclo]

const OUT := "res://tests/_review_art/v04/mundo_vivo/out/fase1/"
const PER := "res://tests/_review_art/v04/personajes/out/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "parity":
		await _parity()
		get_tree().quit()
		return
	var kind := args[0] if args.size() > 0 else "normal"
	var fl := int(args[1]) if args.size() > 1 else 4
	var cyc := int(args[2]) if args.size() > 2 else 0
	var shader := args.size() > 3 and args[3] == "shader"
	var state := AmbientState.new()
	state.heat = 0.5
	state.production = 0.55
	var view := Act1RoomView.new()
	if shader:
		var wv := WorldView.new()
		var cl := CanvasLayer.new()
		add_child(cl)
		cl.add_child(wv)
		wv.world.add_child(view)
		view.build(BgAct1.build(kind, fl, cyc), state, wv.lights, wv.lit_material)
	else:
		var root := Node2D.new()
		root.scale = Vector2(2, 2)
		add_child(root)
		root.add_child(view)
		view.build(BgAct1.build(kind, fl, cyc), state)
	_actors(view.actors)
	# Precalienta el ambiente 3 s (partículas en régimen).
	for i in 180:
		view._process(1.0 / 60.0)
		view.particles_back.step(1.0 / 60.0)
		view.particles_front.step(1.0 / 60.0)
	var frames: Array = []
	for k in 24:
		if k == 10:
			state.pulse_burn(false)
			view.particles_front.burst(Vector2(60, 200), "spark", 24, Vector2.UP, 120.0)
			for c in view.crucibles:
				c.shake()
		await get_tree().create_timer(0.11).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(640, 360, Image.INTERPOLATE_NEAREST)
		frames.append(img)
	# Presupuesto: reposo (antes del pulso de quemar, fotograma 10) y evento (pulso) por separado.
	var rest := 0
	var rest_n := 0
	var rest_peak := 0
	var ev_peak := 0
	for i in range(1, frames.size()):
		var a: PackedByteArray = (frames[i] as Image).get_data()
		var b: PackedByteArray = (frames[i - 1] as Image).get_data()
		var n := 0
		for j in range(0, a.size(), 4):
			if a[j] != b[j] or a[j + 1] != b[j + 1] or a[j + 2] != b[j + 2]:
				n += 1
		if i < 10 or i > 20:
			rest += n
			rest_n += 1
			rest_peak = maxi(rest_peak, n)
		else:
			ev_peak = maxi(ev_peak, n)
	print("pixeles en movimiento: reposo media %d (%.1f pct) pico %d (%.1f pct) | evento quemar pico %d (%.1f pct)" % [rest / rest_n, 100.0 * rest / rest_n / 230400.0, rest_peak, 100.0 * rest_peak / 230400.0, ev_peak, 100.0 * ev_peak / 230400.0])
	var tag := "%s_p%d_c%d%s" % [kind, fl, cyc, "_shader" if shader else ""]
	(frames[0] as Image).save_png(OUT + "live_%s_f0.png" % tag)
	var big := (frames[11] as Image).duplicate() as Image
	big.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + "live_%s_quemar_x2.png" % tag)
	var sheet := Image.create(640 * 2 + 12, 360 * 4 + 20, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("101014"))
	for i in 8:
		sheet.blend_rect(frames[i * 3], Rect2i(0, 0, 640, 360), Vector2i(4 + (i % 2) * 644, 4 + (i / 2) * 364))
	sheet.save_png(OUT + "live_%s_hoja.png" % tag)
	_write_gif(ProjectSettings.globalize_path(OUT + "live_%s.gif" % tag), frames, 11)
	print("live %s ok" % tag)
	get_tree().quit()


## Paridad GPU: cada capa de índice por `palette_lit` con luz dinámica 0 debe dar EXACTAMENTE su vista previa.
func _parity() -> void:
	var wv := WorldView.new()
	var cl := CanvasLayer.new()
	add_child(cl)
	cl.add_child(wv)
	wv.lights.flicker_amp = 0.0
	wv.lights.heat = 0.5
	for kind: String in ["normal", "flue"]:
		var room := BgAct1.build(kind, 4, 1, false)
		for L: Dictionary in room["layers"]:
			var s := Sprite2D.new()
			s.centered = false
			s.position = Vector2(-int(L["margin"]), 0)
			s.texture = ImageTexture.create_from_image(L["index"])
			s.material = wv.lit_material
			var bg := ColorRect.new()
			bg.color = Color(1, 0, 1)
			bg.size = Vector2(640, 360)
			wv.world.add_child(bg)
			wv.world.add_child(s)
			for i in 4:
				await RenderingServer.frame_post_draw
			var got := wv.viewport.get_texture().get_image()
			got.convert(Image.FORMAT_RGBA8)
			var pre: Image = L["preview"]
			var m: int = L["margin"]
			var diff := 0
			var full := 0
			for y in 360:
				for x in 640:
					var e := pre.get_pixel(x + m, y)
					if e.a8 == 0:
						continue
					full += 1
					var c := got.get_pixel(x, y)
					if c.r8 != e.r8 or c.g8 != e.g8 or c.b8 != e.b8:
						diff += 1
			print("paridad %s/%s: %d distintos de %d" % [kind, L["name"], diff, full])
			bg.queue_free()
			s.queue_free()
			await RenderingServer.frame_post_draw


func _actors(parent: Node2D) -> void:
	var fg := Art.forge_sprite(0.75, 0).get_image()
	fg.resize(fg.get_width() * 2, fg.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var f := Sprite2D.new()
	f.centered = false
	f.texture = ImageTexture.create_from_image(fg)
	f.position = Vector2(-8, 264 - fg.get_height() + 2)
	parent.add_child(f)
	for pair: Array in [["fogonera_idle_x1.png", 114], ["golem_idle_x1.png", 410]]:
		var path: String = PER + String(pair[0])
		if not FileAccess.file_exists(path):
			continue
		var im := Image.load_from_file(ProjectSettings.globalize_path(path))
		var s := Sprite2D.new()
		s.centered = false
		s.texture = ImageTexture.create_from_image(im)
		s.position = Vector2(int(pair[1]), 264 - im.get_height() + 2)
		parent.add_child(s)


func _write_gif(path: String, frames: Array, delay_cs: int) -> void:
	var w: int = (frames[0] as Image).get_width()
	var h: int = (frames[0] as Image).get_height()
	var pal := {}
	var cols: Array = []
	var datas: Array = []
	for img: Image in frames:
		var data := PackedByteArray()
		data.resize(w * h)
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var key := (c.r8 << 16) | (c.g8 << 8) | c.b8
				if not pal.has(key):
					if cols.size() < 256:
						pal[key] = cols.size()
						cols.append(key)
					else:
						var best := 0
						var bd := 1 << 30
						for i in cols.size():
							var cc: int = cols[i]
							var d := absi(((cc >> 16) & 255) - c.r8) + absi(((cc >> 8) & 255) - c.g8) + absi((cc & 255) - c.b8)
							if d < bd:
								bd = d
								best = i
						pal[key] = best
				data[y * w + x] = pal[key]
		datas.append(data)
	var out := PackedByteArray()
	out.append_array("GIF89a".to_ascii_buffer())
	for v: int in [w, h]:
		out.append(v & 255)
		out.append(v >> 8)
	out.append_array(PackedByteArray([0xF7, 0, 0]))
	for i in 256:
		var c2: int = cols[i] if i < cols.size() else 0
		out.append_array(PackedByteArray([(c2 >> 16) & 255, (c2 >> 8) & 255, c2 & 255]))
	out.append_array(PackedByteArray([0x21, 0xFF, 0x0B]))
	out.append_array("NETSCAPE2.0".to_ascii_buffer())
	out.append_array(PackedByteArray([3, 1, 0, 0, 0]))
	for data: PackedByteArray in datas:
		out.append_array(PackedByteArray([0x21, 0xF9, 4, 0x04, delay_cs & 255, delay_cs >> 8, 0, 0, 0x2C, 0, 0, 0, 0, w & 255, w >> 8, h & 255, h >> 8, 0, 8]))
		var bits := PackedByteArray()
		var acc := 0
		var nb := 0
		var codes := PackedInt32Array([256])
		var run := 0
		for v2: int in data:
			codes.append(v2)
			run += 1
			if run >= 250:
				codes.append(256)
				run = 0
		codes.append(257)
		for c3: int in codes:
			acc |= c3 << nb
			nb += 9
			while nb >= 8:
				bits.append(acc & 255)
				acc >>= 8
				nb -= 8
		if nb > 0:
			bits.append(acc & 255)
		var p := 0
		while p < bits.size():
			var n := mini(255, bits.size() - p)
			out.append(n)
			out.append_array(bits.slice(p, p + n))
			p += n
		out.append(0)
	out.append(0x3B)
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_buffer(out)
	fh.close()
