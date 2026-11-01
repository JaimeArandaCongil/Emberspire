extends Node

func render(rows: Array, biome: int) -> Image:
	var pal: Dictionary = Art.BIOMES[biome]
	var map := {"1": pal["light"], "2": pal["mid"], "3": pal["dark"], "4": (pal["dark"] as Color).darkened(0.35),
		"a": pal["accent"], "E": pal["eye"], "k": Art.PAL["k"]}
	var w := String(rows[0]).length()
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		for x in w:
			var ch: String = rows[y][x]
			if map.has(ch):
				img.set_pixel(x, y, map[ch])
	return img

func _ready() -> void:
	var src := FileAccess.get_file_as_string("res://tests/_review_art/monsters_src.txt").split("\n")
	var blocks := {}
	var cur := ""
	for l: String in src:
		l = l.strip_edges()
		if l.begins_with("#"):
			cur = l.substr(1); blocks[cur] = []
		elif l != "":
			blocks[cur].append(l)
	var out := Image.create(1200, 3 * 210, false, Image.FORMAT_RGBA8)
	for b in 3:
		out.fill_rect(Rect2i(0, b * 210, 1200, 210), Art.BIOMES[b]["wall"])
		var x := 10
		for k: String in blocks:
			var rows: Array = blocks[k]
			var w := 0
			for r: String in rows: w = maxi(w, r.length())
			var padded: Array = []
			for r: String in rows: padded.append(r.rpad(w, "."))
			var im := render(padded, b)
			im.resize(im.get_width() * 8, im.get_height() * 8, Image.INTERPOLATE_NEAREST)
			out.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(x, b * 210 + 205 - im.get_height()))
			x += im.get_width() + 30
	out.save_png(ProjectSettings.globalize_path("res://tests/_review_art/out/proposal_monsters.png"))
	print("MON OK")
	get_tree().quit()
