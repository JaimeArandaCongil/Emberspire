extends "res://scripts/art/legacy/legacy_scenery.gd"
## Arte LEGADO v0.3 (congelado) — Forja (pantalla principal y combate) y hoguera.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Forja ----------------------------------------------------------------------

## Forja de la pantalla principal (64×56, ×4). `heat` 0..1 aviva la boca; `frame` 0..3 anima las brasas.
func forge_sprite(heat: float, frame: int = 0) -> Texture2D:
	var lvl := clampi(int(heat * 4.0), 0, 4)
	var key := "forge:%d:%d" % [lvl, frame % 4]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_draw_forge(64, 56, lvl, frame % 4, true))
	return _cache[key]


## Horno de combate (36×34, ×4).
func furnace_small(heat: float, frame: int = 0) -> Texture2D:
	var lvl := clampi(int(heat * 4.0), 0, 4)
	var key := "furn:%d:%d" % [lvl, frame % 4]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_draw_forge(36, 34, lvl, frame % 4, false))
	return _cache[key]


func _draw_forge(W: int, H: int, lvl: int, frame: int, full: bool) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k: Color = PAL["k"]
	var brick := Color("6a3a30")
	var brick2 := Color("7e4636")
	var mortar := Color("2a1418")
	var hot: Array[Color] = [Color("5a1a0c"), Color("8a2a10"), Color("c24a1a"), Color("ff6a1a"), Color("ffb43a"), Color("ffe08a"), Color("fff4c8")]
	var plinth_y := H - 6 if full else H - 4
	var cx := 28.0 if full else 18.0
	var rx := 24.0 if full else 16.0
	var ry := 34.0 if full else 22.0
	var base_y := float(plinth_y)
	var mouth_hw := 10.0 if full else 7.0
	var mouth_cy := base_y - (10.0 if full else 7.0)
	# Chimenea.
	var chx := int(cx) + (6 if full else 4)
	var chw := 8 if full else 6
	for y in range(0, int(base_y - ry) + 6):
		for x in range(chx, chx + chw):
			var c := brick if (y / 3 + (x - chx) / 4) % 2 == 0 else brick2
			if x == chx or x == chx + chw - 1:
				c = k
			elif y % 3 == 0:
				c = mortar
			if y == 3 or y == 4:
				c = PAL["m"] if y == 3 else PAL["d"]
				if x == chx or x == chx + chw - 1:
					c = k
			if y == 0:
				c = k
			img.set_pixel(x, y, c)
	# Cúpula de ladrillo radial.
	for y in range(int(base_y - ry) - 1, int(base_y)):
		for x in W:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base_y) / ry
			var r := sqrt(dx * dx + dy * dy)
			if r > 1.0:
				continue
			var ring := int((1.0 - r) * ry / 4.0)
			var ang := atan2(dy, dx)
			var arc := ang * r * rx / 6.0 + ring * 0.5
			var ring_edge := int((1.0 - r) * ry / 4.0) != int((1.0 - (r + 1.0 / ry)) * ry / 4.0)
			var brick_edge := int(floor(arc)) != int(floor(arc + 0.17))
			var c := brick if (ring + int(floor(arc))) % 2 == 0 else brick2
			if ring_edge or brick_edge:
				c = mortar
			if r > 1.0 - 1.2 / ry or r > 1.0 - 1.2 / rx and absf(dx) > 0.9:
				c = k
			elif dx < -0.25 and dy < -0.35:
				c = c.lightened(0.12)
			elif dx > 0.45:
				c = c.darkened(0.22)
			# Resplandor de la boca sobre el ladrillo.
			var md := Vector2(x - cx, (y - mouth_cy) * 1.2).length()
			if md < mouth_hw + 5 and c != k and c != mortar:
				c = c.lerp(hot[3], 0.08 + 0.04 * lvl)
			img.set_pixel(x, y, c)
	# Boca: arco con dovelas e interior encendido.
	for y in range(int(mouth_cy - mouth_hw) - 2, int(base_y)):
		for x in range(int(cx - mouth_hw) - 3, int(cx + mouth_hw) + 3):
			var dx2 := x + 0.5 - cx
			var dy2 := y + 0.5 - mouth_cy
			var dist := sqrt(dx2 * dx2 + dy2 * dy2) if dy2 < 0.0 else absf(dx2)
			if dist <= mouth_hw:
				# Interior.
				var depth := (y - (mouth_cy - mouth_hw)) / (base_y - (mouth_cy - mouth_hw))
				var hi := clampi(int(depth * 3.0) + lvl - 1, 0, 6)
				if absf(dx2) > mouth_hw - 2.0:
					hi = maxi(0, hi - 2)
				var c2: Color = hot[hi]
				img.set_pixel(x, y, c2)
			elif dist <= mouth_hw + 2.0:
				var ang2 := atan2(dy2, dx2)
				var joint := int(floor(ang2 * 4.0)) != int(floor((ang2 + 0.08) * 4.0)) if dy2 < 0.0 else (y % 4 == 0)
				var c3 := Color("8a7a70") if dx2 < 0 else Color("6a5a58")
				if joint:
					c3 = mortar
				if dist > mouth_hw + 1.4:
					c3 = k
				img.set_pixel(x, y, c3)
	# Brasas animadas y llamas proporcionales al calor.
	var coal_y := int(base_y) - 3
	for x in range(int(cx - mouth_hw) + 1, int(cx + mouth_hw)):
		for y in range(coal_y, int(base_y)):
			var n := _hash2(x, y, frame * 31 + 7)
			var c4: Color = Color("2a1410")
			if n > 0.72:
				c4 = hot[mini(6, 3 + lvl / 2)]
			elif n > 0.45:
				c4 = hot[2 + mini(lvl, 2)]
			elif n > 0.25:
				c4 = Color("4a2418")
			img.set_pixel(x, y, c4)
		# Lenguas de fuego.
		var fh := int((1.0 + lvl) * (0.4 + 0.6 * _hash2(x, frame, 11)) * (mouth_hw / 8.0))
		for i in fh:
			var yy := coal_y - 1 - i
			if yy < mouth_cy - mouth_hw + 1:
				break
			var t := float(i) / maxf(1.0, fh)
			img.set_pixel(x, yy, hot[clampi(6 - int(t * 4.0) - (2 if lvl < 2 else 0), 2, 6)])
	# Parrilla.
	for x in range(int(cx - mouth_hw), int(cx + mouth_hw) + 1):
		img.set_pixel(x, int(base_y) - 1, k if x % 3 != 0 else Color("4a4048"))
	# Base de piedra.
	for y in range(plinth_y, H):
		for x in range(1, W - 1):
			var c5 := Color("4a4048") if ((x / 6) + (y - plinth_y) / 3) % 2 == 0 else Color("564c54")
			if y == plinth_y:
				c5 = Color("7a7078")
			elif y == H - 1 or x == 1 or x == W - 2:
				c5 = k
			elif (x % 6 == 0) and y > plinth_y:
				c5 = Color("2a2228")
			img.set_pixel(x, y, c5)
	if full:
		# Yunque junto a la forja.
		var ax := 50
		var ay := plinth_y - 9
		var anvil := ["kkkkkkkkkkkk", "kMMMMMMMMMmk", ".kmmmmmmmmk.", "..kkkmmmkk..", "....kmmk....",
			"....kmmk....", "...kmmmmk...", "..kmmmmmmk..", "..kkkkkkkk.."]
		for y in anvil.size():
			var row: String = anvil[y]
			for x in row.length():
				var ch := row[x]
				if ch != "." and ax + x < W:
					img.set_pixel(ax + x - 1, ay + y, PAL[ch])
	return img


## Hoguera grande (32×24, ×4) con 4 fotogramas de llama.
func bonfire(frame: int = 0) -> Texture2D:
	var key := "bonfire:%d" % (frame % 4)
	if _cache.has(key):
		return _cache[key]
	var W := 32
	var H := 24
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k: Color = PAL["k"]
	var ramp: Array[Color] = [PAL["R"], PAL["r"], PAL["o"], PAL["y"], PAL["w"], PAL["Y"]]
	# Llama.
	for x in range(6, 26):
		var cxd := absf(x - 15.5) / 10.0
		var hgt := (1.0 - cxd * cxd) * 17.0 * (0.75 + 0.25 * _hash2(x, frame, 3))
		hgt += 3.0 * sin(x * 0.9 + frame * 1.7)
		var top := int(19 - hgt)
		for y in range(maxi(0, top), 19):
			var t := float(y - top) / maxf(1.0, 19 - top)
			var core := 1.0 - cxd
			var idx := clampi(int(t * 3.0 + core * 2.5), 0, 5)
			img.set_pixel(x, y, ramp[idx])
	# Chispas.
	for i in 4:
		var sx := 8 + int(_hash2(i, frame, 9) * 16)
		var sy := int(_hash2(i, frame, 5) * 6)
		img.set_pixel(sx, sy, PAL["y"] if i % 2 == 0 else PAL["o"])
	# Troncos cruzados.
	var logs := [[4, 19, 27, 16], [5, 16, 27, 20]]
	for lg: Array in logs:
		for s in 24:
			var t2 := s / 23.0
			var lx := int(lerpf(lg[0], lg[2], t2))
			var ly := int(lerpf(lg[1], lg[3], t2))
			for dy in range(-1, 2):
				var c := PAL["n"] if dy < 1 else PAL["h"]
				if dy == -1:
					c = PAL["n"].lightened(0.1)
				img.set_pixel(lx, ly + dy, c)
	# Piedras alrededor.
	for i in 7:
		var px := 2 + i * 4
		for y in range(20, 24):
			for x in range(px, px + 4):
				var c2 := Color("6a6068") if y == 20 else Color("4a4048")
				if x == px or y == 23:
					c2 = k
				img.set_pixel(x, y, c2)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
