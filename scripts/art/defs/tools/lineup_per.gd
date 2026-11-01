extends SceneTree
## Reparto del acto 1 en una fila, a escala real entre sí: color arriba, silueta negra abajo (criterio de DA) y miniatura a 32 px.
## Godot --headless --path . -s res://scripts/art/defs/tools/lineup_per.gd  →  docs/reviews/v04/personajes/img/reparto_x3.png

const IDS := [["hero", "fogonera"], ["creatures", "soot_golem"], ["creatures", "ember_magpie"], ["creatures", "ash_slime"], ["creatures", "candle_mite"], ["creatures", "cinder_bat"]]


func _init() -> void:
	var frames: Array = []
	var total := 8
	var maxh := 0
	for e: Array in IDS:
		var def: RigDef = (load("res://scripts/art/defs/%s/%s.gd" % [e[0], e[1]]) as Script).call("build")
		var fr := RigRenderer.render(def, &"idle", 0, {})
		var im: Image = fr.preview
		var used := im.get_used_rect()
		var crop := im.get_region(used)
		frames.append(crop)
		total += crop.get_width() + 8
		maxh = maxi(maxh, crop.get_height())
	var H := maxh * 2 + 24
	var img := Image.create(total, H, false, Image.FORMAT_RGBA8)
	img.fill(Palette.color(&"stone", 3))
	var x := 8
	for f: Image in frames:
		var w := f.get_width()
		var h := f.get_height()
		img.blend_rect(f, Rect2i(0, 0, w, h), Vector2i(x, 8 + maxh - h))
		for yy in h:
			for xx in w:
				if f.get_pixel(xx, yy).a > 0.0:
					img.set_pixel(x + xx, 16 + 2 * maxh - h + yy, Palette.OUTLINE)
		x += w + 8
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png("res://docs/reviews/v04/personajes/img/reparto_x3.png")
	quit()
