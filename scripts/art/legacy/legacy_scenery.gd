extends "res://scripts/art/legacy/legacy_cards.gd"
## Arte LEGADO v0.3 (congelado) — Escenarios: fondo por acto 320×180, capa cercana, antorchas y suelo.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Escenarios ---------------------------------------------------------------

func torches(biome: int) -> Array[Vector2i]:
	match biome % 3:
		1:
			return [Vector2i(32, 72), Vector2i(88, 66), Vector2i(232, 66), Vector2i(288, 72)]
		2:
			return [Vector2i(22, 70), Vector2i(92, 66), Vector2i(228, 66), Vector2i(298, 70)]
	return TORCHES


## Fondo interior de la torre (320×180) para combate y menús: composición distinta por acto.
func background(biome: int, seed_value: int, cycle: int = 0) -> Texture2D:
	var key := "bg:%d:%d:%d" % [biome, seed_value, cycle]
	if _cache.has(key):
		return _cache[key]
	var pal := biome_colors(biome, cycle)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + biome
	var img := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	match biome % 3:
		0:
			_bg_brick(img, pal, rng)
		1:
			_bg_rock(img, pal, rng)
		2:
			_bg_ice(img, pal, rng)
	_bg_floor(img, pal, rng, biome % 3)
	for tp: Vector2i in torches(biome):
		_bg_torch(img, tp)
	_bg_vignette(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Capa cercana (primer plano) transparente: pilares y cadenas en silueta para el parallax.
func background_near(biome: int, seed_value: int, cycle: int = 0) -> Texture2D:
	var key := "bgn:%d:%d:%d" % [biome, seed_value, cycle]
	if _cache.has(key):
		return _cache[key]
	var pal := biome_colors(biome, cycle)
	var img := Image.create(336, 180, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color("0c0709")
	var rim: Color = (pal["wall"] as Color).lightened(0.12)
	# Pilares laterales (8 px de margen para el parallax).
	for px: int in [0, 326]:
		for y in 180:
			for x in range(px, px + 10):
				var c := dark
				if (px == 0 and x == px + 9) or (px != 0 and x == px):
					c = rim
				img.set_pixel(x, y, c)
	# Cadenas en primer plano.
	for cx: int in [20, 316]:
		var ln := 34 + (seed_value * 13 + cx) % 30
		for y in ln:
			var c2 := Color("2a2226") if y % 4 != 3 else dark
			img.set_pixel(cx, y, c2)
			if y % 4 == 1:
				img.set_pixel(cx - 1, y, dark)
				img.set_pixel(cx + 1, y, dark)
		img.set_pixel(cx, ln, Color("3a3034"))
	match biome % 3:
		1:
			# Estalactitas de escoria.
			for sx: int in [40, 70, 270, 300]:
				var l2 := 6 + (sx * 7 + seed_value) % 9
				for y in l2:
					var hw := int((l2 - y) / 4.0)
					for x in range(sx - hw, sx + hw + 1):
						img.set_pixel(x, y, dark if x != sx - hw else rim)
				img.set_pixel(sx, l2, pal["accent"])
		2:
			# Carámbanos.
			for sx2: int in [30, 46, 58, 278, 292, 306]:
				var l3 := 4 + (sx2 * 5 + seed_value) % 10
				for y in l3:
					var hw2 := int((l3 - y) / 5.0)
					for x in range(sx2 - hw2, sx2 + hw2 + 1):
						img.set_pixel(x, y, Color("d8ecf8") if x == sx2 - hw2 else Color("8ab4d0"))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


func _bg_brick(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	for by in range(0, FLOOR_Y, 8):
		var row := by / 8
		var off := 0 if row % 2 == 0 else 8
		for bx in range(-off, 320, 16):
			var tone := wall.lightened(rng.randf_range(-0.03, 0.05))
			if rng.randf() < 0.06:
				tone = wall.darkened(0.12)
			for y in range(by, mini(by + 8, FLOOR_Y)):
				for x in range(maxi(bx, 0), mini(bx + 16, 320)):
					var c := mortar if (y == by or x == bx) else tone
					if c != mortar and y == by + 1:
						c = c.lightened(0.05)
					elif c != mortar and y == by + 7:
						c = c.darkened(0.06)
					# Hollín: más oscuro arriba.
					c = c.darkened(0.30 * (1.0 - float(y) / FLOOR_Y))
					img.set_pixel(x, y, c)
	_bg_pilasters(img, pal, [100, 212])
	_bg_windows(img, pal, [52, 268], Color("1a0a10"), Color("5a2014"), false)
	# Gran arco central del horno-catedral.
	_bg_arch(img, pal, 160, 30, 26, Color("140a0c"), Color("6a2810"))
	_bg_banners(img, pal, [124, 196])
	_bg_chains(img, rng, [40, 150, 170, 280])


func _bg_rock(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	img.fill(mortar)
	var y := 0
	while y < FLOOR_Y:
		var bh := rng.randi_range(7, 12)
		var x := -rng.randi_range(0, 12)
		while x < 320:
			var bw := rng.randi_range(10, 26)
			var tone := wall.lightened(rng.randf_range(-0.04, 0.07))
			for yy in range(y + 1, mini(y + bh, FLOOR_Y)):
				for xx in range(maxi(x + 1, 0), mini(x + bw, 320)):
					var corner := (yy == y + 1 or yy == y + bh - 1) and (xx == x + 1 or xx == x + bw - 1)
					if corner:
						continue
					var c := tone
					if yy == y + 1:
						c = tone.lightened(0.06)
					elif yy == y + bh - 1:
						c = tone.darkened(0.08)
					c = c.darkened(0.25 * (1.0 - float(yy) / FLOOR_Y))
					img.set_pixel(xx, yy, c)
			x += bw
		y += bh
	_bg_pilasters(img, pal, [100, 212])
	# Goteos de escoria emisiva.
	var acc: Color = pal["accent"]
	for i in 7:
		var dx := rng.randi_range(12, 308)
		if absi(dx - 160) < 30:
			continue
		var ln := rng.randi_range(10, 46)
		for yy2 in ln:
			var c2 := acc.darkened(0.55 - 0.4 * float(yy2) / ln)
			img.set_pixel(dx, yy2, c2)
		img.set_pixel(dx, ln, acc)
		img.set_pixel(dx, ln + 1, acc.darkened(0.3))
	# Jaulas colgantes.
	for cx: int in [70, 250]:
		for yy3 in 26:
			img.set_pixel(cx, yy3, Color("3a3438") if yy3 % 3 else Color("1a1418"))
		for yy4 in range(26, 48):
			for xx2 in range(cx - 7, cx + 8):
				var bar := (xx2 - cx + 7) % 3 == 0 or yy4 == 26 or yy4 == 47
				if bar:
					img.set_pixel(xx2, yy4, Color("4a4448") if xx2 < cx else Color("2a2428"))
				elif yy4 > 40:
					img.set_pixel(xx2, yy4, img.get_pixel(xx2, yy4).lerp(acc, 0.12))
	_bg_arch(img, pal, 160, 34, 22, Color("0e0a12"), acc.darkened(0.5))
	_bg_banners(img, pal, [128, 192])


func _bg_ice(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	for by in range(0, FLOOR_Y, 12):
		var off := 0 if (by / 12) % 2 == 0 else 12
		for bx in range(-off, 320, 24):
			var tone := wall.lightened(rng.randf_range(-0.03, 0.06))
			for y in range(by, mini(by + 12, FLOOR_Y)):
				for x in range(maxi(bx, 0), mini(bx + 24, 320)):
					var c := mortar if (y == by or x == bx) else tone
					if c != mortar and y == by + 1:
						c = Color("b8d4e8") if _hash2(x, y, 7) < 0.35 else c.lightened(0.08)
					elif c != mortar and y == by + 11:
						c = c.darkened(0.06)
					c = c.darkened(0.22 * (1.0 - float(y) / FLOOR_Y))
					img.set_pixel(x, y, c)
	# Viga superior con carámbanos.
	for y in 6:
		for x in 320:
			img.set_pixel(x, y, Color("141c2a") if y < 5 else Color("3a5070"))
	for i in 40:
		var sx := rng.randi_range(0, 319)
		var l := rng.randi_range(2, 9)
		for y2 in l:
			if y2 < l - int(y2 / 3):
				img.set_pixel(sx, 6 + y2, Color("cfe6f6") if y2 < l - 1 else Color("8ab4d0"))
	_bg_pilasters(img, pal, [100, 212])
	_bg_windows(img, pal, [52, 268], Color("060a18"), Color("1e3456"), true)
	_bg_arch(img, pal, 160, 32, 24, Color("0a0e18"), Color("2a4a7a"))
	_bg_banners(img, pal, [124, 196])


func _bg_pilasters(img: Image, pal: Dictionary, xs: Array) -> void:
	var wall: Color = pal["wall"]
	for px: int in xs:
		for y in FLOOR_Y:
			for x in range(px, px + 8):
				var c := wall.lightened(0.10)
				if x == px or x == px + 7:
					c = pal["mortar"]
				elif x == px + 1:
					c = wall.lightened(0.18)
				elif x == px + 6:
					c = wall.darkened(0.05)
				if y < 6 or (y >= FLOOR_Y - 6):
					c = wall.lightened(0.14) if x > px and x < px + 7 else c
				c = c.darkened(0.2 * (1.0 - float(y) / FLOOR_Y))
				img.set_pixel(x, y, c)


## Ventanas arqueadas: cielo en bandas, parteluz, alféizar y (opcional) luna y nieve.
func _bg_windows(img: Image, pal: Dictionary, xs: Array, sky_top: Color, sky_bot: Color, cold: bool) -> void:
	for wx: int in xs:
		for y in range(24, 84):
			for x in range(wx - 12, wx + 13):
				var dx := x - wx
				var top := 36.0 - sqrt(maxf(0.0, 144.0 - dx * dx))
				if y < top:
					continue
				var edge := y < top + 1.0 or absi(dx) == 12
				var t := float(y - 24) / 60.0
				var band := int(t * 4.0)
				var c := sky_top.lerp(sky_bot, band / 3.0)
				if edge:
					c = pal["mortar"]
				elif dx == 0 or y == 56:
					c = Color("0a0608")
				img.set_pixel(x, y, c)
		if cold:
			# Luna y nieve.
			for dy in range(-3, 4):
				for dx2 in range(-3, 4):
					if dx2 * dx2 + dy * dy <= 9:
						img.set_pixel(wx - 6 + dx2, 38 + dy, Color("e8f0ff") if dx2 + dy < 1 else Color("b8c8e0"))
			for i in 8:
				img.set_pixel(wx - 10 + (i * 7) % 20, 44 + (i * 11) % 36, Color("d8e8f8"))
		else:
			for i in 5:
				img.set_pixel(wx - 9 + (i * 5) % 18, 40 + (i * 13) % 38, Color("ff8a3a"))
		for y in range(84, 88):
			for x in range(wx - 14, wx + 15):
				img.set_pixel(x, y, (pal["wall"] as Color).lightened(0.16 if y == 84 else 0.06))


## Arco profundo con dovelas y brillo en el fondo.
func _bg_arch(img: Image, pal: Dictionary, cx: int, top: int, half: int, inside: Color, glow: Color) -> void:
	var wall: Color = pal["wall"]
	for y in range(top, FLOOR_Y):
		for x in range(cx - half - 4, cx + half + 5):
			var dx := float(x - cx)
			var r_in := float(half)
			var r_out := float(half + 4)
			var ay := float(top + half + 4)
			var in_arch := false
			var on_ring := false
			if y < ay:
				var d := sqrt(dx * dx + (y - ay) * (y - ay))
				in_arch = d <= r_in
				on_ring = d > r_in and d <= r_out
			else:
				in_arch = absf(dx) <= r_in
				on_ring = absf(dx) > r_in and absf(dx) <= r_out
			if in_arch:
				var t := float(y - top) / float(FLOOR_Y - top)
				var c := inside
				if t > 0.8:
					c = inside.lerp(glow, 0.55)
				elif t > 0.6:
					c = inside.lerp(glow, 0.3)
				elif t > 0.4:
					c = inside.lerp(glow, 0.12)
				img.set_pixel(x, y, c)
			elif on_ring:
				var ang := atan2(float(y) - ay, dx)
				var joint := int(abs(ang) * 9.0) != int(abs(ang + 0.03) * 9.0) if y < ay else (y % 8 == 0)
				var c2 := wall.lightened(0.16 if dx < 0 else 0.06)
				if joint:
					c2 = pal["mortar"]
				img.set_pixel(x, y, c2)
	# Brasas en el fondo del arco.
	for i in 18:
		var ex := cx - half + 2 + (i * 7) % (half * 2 - 3)
		var ey := FLOOR_Y - 2 - (i * 5) % 7
		img.set_pixel(ex, ey, glow.lightened(0.4) if i % 3 == 0 else glow)


func _bg_banners(img: Image, pal: Dictionary, xs: Array) -> void:
	var banner: Color = pal["banner"]
	for bx: int in xs:
		for y in range(10, 58):
			for x in range(bx - 6, bx + 6):
				if y > 50 and absi(x - bx) < (y - 50):
					continue
				var c := banner
				if x == bx - 6 or x == bx + 5:
					c = banner.darkened(0.45)
				elif x == bx - 5:
					c = banner.lightened(0.15)
				elif x >= bx + 3:
					c = banner.darkened(0.15)
				img.set_pixel(x, y, c)
		for x in range(bx - 7, bx + 7):
			img.set_pixel(x, 9, Color("8a6a3a"))
			img.set_pixel(x, 8, Color("2a1e18"))
		var em := icon_image("flame")
		for y in 12:
			for x in 12:
				var p := em.get_pixel(x, y)
				if p.a > 0.0:
					img.set_pixel(bx - 6 + x, 24 + y, p.darkened(0.25))


func _bg_chains(img: Image, rng: RandomNumberGenerator, xs: Array) -> void:
	for cx: int in xs:
		var ln := rng.randi_range(10, 24)
		for y in ln:
			img.set_pixel(cx, y, Color("4a4448") if y % 3 != 2 else Color("221c20"))


## Soporte de antorcha + luz en anillos (sin tramado) sobre el muro.
func _bg_torch(img: Image, tp: Vector2i) -> void:
	for y in range(tp.y - 30, tp.y + 26):
		for x in range(tp.x - 30, tp.x + 31):
			if x < 0 or y < 0 or x >= 320 or y >= FLOOR_Y:
				continue
			var d := Vector2(x - tp.x, (y - tp.y + 4) * 1.15).length()
			var a := 0.0
			if d < 10:
				a = 0.16
			elif d < 18:
				a = 0.10
			elif d < 27:
				a = 0.05
			if a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color("ff9a4a"), a))
	for y in range(tp.y, tp.y + 10):
		img.set_pixel(tp.x, y, Color("4a3a30"))
		img.set_pixel(tp.x + 1, y, Color("2a1e18"))
	for x in range(tp.x - 2, tp.x + 4):
		img.set_pixel(x, tp.y, Color("6a5040"))
		img.set_pixel(x, tp.y + 1, Color("3a2a20"))


## Suelo en perspectiva (punto de fuga centrado; sin línea en el eje central).
func _bg_floor(img: Image, pal: Dictionary, rng: RandomNumberGenerator, act: int) -> void:
	var fl: Color = pal["floor"]
	var mortar: Color = pal["mortar"]
	var vy := float(FLOOR_Y - 22)
	var lights: Array = [52, 268] if act != 1 else [160]
	for y in range(FLOOR_Y, 180):
		var depth := (180.0 - vy) / (float(y) - vy)
		var row_f := depth * 1.6
		var next_f := (180.0 - vy) / (float(y + 1) - vy) * 1.6
		var hline := int(row_f) != int(next_f)
		for x in 320:
			var u := (x - 160.0) * depth / 2.0 + 12.0
			var col_i := int(floor(u / 24.0))
			var vline := fposmod(u, 24.0) < depth * 0.5
			var c := fl.lightened(0.04 if (col_i + int(row_f)) % 2 == 0 else 0.0)
			if y == FLOOR_Y:
				c = fl.lightened(0.22)
			elif y == FLOOR_Y + 1:
				c = mortar
			elif hline or vline:
				c = mortar
			# Charcos de luz (bandas, sin tramado).
			for lx: int in lights:
				var ddx := float(x - lx) / (26.0 + (y - FLOOR_Y) * 0.8)
				var ddy := float(y - FLOOR_Y - 18) / 16.0
				var lg := 1.0 - (ddx * ddx + ddy * ddy)
				if lg > 0.5:
					c = c.lerp(pal["glow"], 0.12)
				elif lg > 0.0:
					c = c.lerp(pal["glow"], 0.06)
			if act == 1 and _hash2(x, y, 3) < 0.004:
				c = pal["accent"]
			elif act == 2 and _hash2(x, y, 5) < 0.01:
				c = Color("d8ecf8")
			# Más oscuro cerca del borde inferior (allí va la mano).
			c = c.darkened(0.35 * clampf(float(y - 150) / 30.0, 0.0, 1.0))
			img.set_pixel(x, y, c)
	if act == 2:
		# Nieve acumulada al pie del muro.
		for x in 320:
			var hgt := int(2.0 + 2.0 * sin(x * 0.21) + 1.5 * sin(x * 0.07 + 1.0))
			for y in range(FLOOR_Y - hgt, FLOOR_Y + 1):
				img.set_pixel(x, y, Color("dce8f4") if y == FLOOR_Y - hgt else Color("a8c0d8"))


func _bg_vignette(img: Image) -> void:
	for y in 180:
		for x in 320:
			var dx := (float(x) - 160.0) / 160.0
			var dy := (float(y) - 99.0) / 99.0
			var v := (dx * dx + dy * dy) * 0.5
			var f := 1.0 - floorf(clampf(v, 0.0, 0.6) * 10.0) / 10.0 * 0.8
			var c := img.get_pixel(x, y) * f
			c.a = 1.0
			img.set_pixel(x, y, c)
