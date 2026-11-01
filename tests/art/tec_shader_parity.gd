extends Node
## Paridad GPU/CPU del formato de índice (TEC · v0.4). NECESITA VENTANA (renderer real, no headless):
##   godot --path . res://tests/art/tec_shader_parity.tscn
## 1. Con luz dinámica 0, palette_lit dibuja EXACTAMENTE la vista previa `_prev.png`, también con el sprite volteado (scale.x = -1).
## 2. Con una luz encendida, todo color sigue en la paleta y los píxeles de una misma pieza se mueven a la vez.
## Código de salida: 0 bien · 1 diferencias.


func _ready() -> void:
	var wv := WorldView.new()
	add_child(wv)
	wv.lights.flicker_amp = 0.0
	wv.viewport.transparent_bg = true
	var idx: Texture2D = SpriteBank.frames(&"golem_example", &"idle")[0]
	var prev: Image = SpriteBank.atlas_image(&"golem_example", false).get_region(Rect2i(0, 0, 96, 96))
	var s := Sprite2D.new()
	s.centered = false
	s.position = Vector2(100, 100)
	s.texture = idx
	s.material = wv.lit_material
	wv.world.add_child(s)
	var bad := 0
	await _frames()
	var d1 := _diff(_grab(wv), prev)
	print("sin luz: %d píxeles distintos de la vista previa" % d1)
	bad += d1
	s.position = Vector2(196, 100)   # el volteo es un scale(-1): el rectángulo sigue en x 100..196
	s.scale = Vector2(-1, 1)
	await _frames()
	var pf := prev.duplicate() as Image
	pf.flip_x()
	var d2 := _diff(_grab(wv), pf)
	print("volteado: %d píxeles distintos" % d2)
	bad += d2
	s.scale = Vector2.ONE
	s.position = Vector2(100, 100)
	wv.lights.add_light(Vector2(148, 148), 120.0, 3.0)
	await _frames()
	var lit := _grab(wv)
	var off := 0
	var changed := 0
	for y in 96:
		for x in 96:
			var c := lit.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			if not Palette.is_palette_color(c):
				off += 1
			if c != prev.get_pixel(x, y):
				changed += 1
	print("con luz: %d píxeles cambian, %d fuera de paleta" % [changed, off])
	if changed == 0 or off > 0:
		bad += 1
	print("tec_shader_parity: %s (%s)" % ["OK" if bad == 0 else "FALLO", RenderingServer.get_video_adapter_name()])
	get_tree().quit(0 if bad == 0 else 1)


func _frames() -> void:
	for i in 3:
		await RenderingServer.frame_post_draw


func _grab(wv: WorldView) -> Image:
	var img := wv.viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img.get_region(Rect2i(100, 100, 96, 96))


func _diff(a: Image, b: Image) -> int:
	var n := 0
	for y in 96:
		for x in 96:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if (ca.a > 0.0) != (cb.a > 0.0) or (cb.a > 0.0 and ca != cb):
				n += 1
	return n
