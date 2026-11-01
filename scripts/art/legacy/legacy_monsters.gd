extends "res://scripts/art/legacy/legacy_hero.gd"
## Arte LEGADO v0.3 (congelado) — Monstruos: sombreado por campo de distancia, variación por semilla, poses y capa emisiva.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Monstruos --------------------------------------------------------------

func biome_colors(biome: int, cycle: int = 0) -> Dictionary:
	var b: Dictionary = BIOMES[biome % BIOMES.size()]
	if cycle == 0:
		return b
	var out := {}
	for k: String in b:
		var c: Color = b[k]
		out[k] = Color.from_hsv(fposmod(c.h + 0.29 * cycle, 1.0), minf(1.0, c.s + 0.1), c.v)
	return out


func monster_lift(shape: String) -> int:
	var base := shape.get_slice("@", 0)
	return int(SHAPE_LIFT.get(base, 0)) * (2 if shape.ends_with("@2") else 1)


## Monstruo: base dibujada a mano (o máscara simétrica) + sombreado + variación por semilla.
func monster(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	return monster_pose(shape, seed_key, biome, cycle, "base")


## Capa emisiva del monstruo (ojos, grietas, acentos) para el brillo pulsante aditivo.
func monster_glow(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	return monster_pose_glow(shape, seed_key, biome, cycle, "base")


## Variante de pose generada sin escalar: "base", "crouch" (−1 fila) o "stretch" (+1 fila).
func monster_pose(shape: String, seed_key: String, biome: int, cycle: int, pose: String) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key + ":base"):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache.get(key + ":" + pose, _cache[key + ":base"])


func monster_pose_glow(shape: String, seed_key: String, biome: int, cycle: int, pose: String) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key + ":base"):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache.get(key + ":" + pose + ":glow", _cache[key + ":base:glow"])


## EPX sobre la rejilla de caracteres: los jefes se dibujan a media resolución y se amplían ×2 ANTES
## de sombrear, de modo que el sombreado, el contorno y las grietas se calculan a resolución final.
static func grid_scale2x(grid: Array) -> Array:
	var h := grid.size()
	var w := String(grid[0]).length()
	var out: Array = []
	for y in h:
		var r0 := ""
		var r1 := ""
		for x in w:
			var p: String = grid[y][x]
			var a: String = grid[y - 1][x] if y > 0 else p
			var b: String = grid[y][x + 1] if x < w - 1 else p
			var c: String = grid[y][x - 1] if x > 0 else p
			var d: String = grid[y + 1][x] if y < h - 1 else p
			var e0 := p
			var e1 := p
			var e2 := p
			var e3 := p
			if c != b and a != d:
				if a == c:
					e0 = a
				if a == b:
					e1 = b
				if d == c:
					e2 = c
				if d == b:
					e3 = b
			r0 += e0 + e1
			r1 += e2 + e3
		out.append(r0)
		out.append(r1)
	return out


## `shape@2` = versión de élite: la misma base ampliada ×2 con EPX antes de sombrear.
func _monster_grid(shape: String, rng: RandomNumberGenerator) -> Array:
	if shape.ends_with("@2"):
		return grid_scale2x(_monster_grid(shape.get_slice("@", 0), rng))
	var grid: Array = []
	if BASES.has(shape) and shape.begins_with("boss_"):
		var src: Array = []
		for r: String in BASES[shape]:
			src.append(r)
		for g: String in grid_scale2x(src):
			var line := ""
			for ch in g:
				match ch:
					"o": ch = "X" if rng.randf() < 0.55 else "."
					"?": ch = "a" if rng.randf() < 0.6 else "X"
				line += ch
			grid.append(line)
		return grid
	if BASES.has(shape):
		var rows: Array = BASES[shape]
		var w := 0
		for r: String in rows:
			w = maxi(w, r.length())
		for r: String in rows:
			var line := ""
			for x in w:
				var ch := r[x] if x < r.length() else "."
				match ch:
					"o": ch = "X" if rng.randf() < 0.55 else "."
					"?": ch = "a" if rng.randf() < 0.6 else "X"
				line += ch
			grid.append(line)
		return grid
	var half: Array = SHAPES.get(shape, SHAPES["slime"])
	var hw := 0
	for r: String in half:
		hw = maxi(hw, r.length())
	for r: String in half:
		var left := ""
		for x in hw:
			var ch := r[x] if x < r.length() else "."
			match ch:
				"o": ch = "X" if rng.randf() < 0.55 else "."
				"?": ch = "a" if rng.randf() < 0.5 else "X"
				"w": ch = "W"
				"d": ch = "3"
			left += ch
		grid.append(left + left.reverse())
	# Las criaturas frontales pequeñas se amplían ×2 (EPX) para leerse a escala de juego.
	if shape in ["mite", "bat", "moth"]:
		grid = grid_scale2x(grid)
	return grid


func _build_monster(shape: String, seed_key: String, biome: int, cycle: int, key: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key + ":" + shape)
	var grid := _monster_grid(shape, rng)
	var h := grid.size()
	var w := String(grid[0]).length()
	var big := h >= 36
	var solid := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h:
			return false
		var c: String = grid[y][x]
		return c != "." and c != "k"
	# Campo de distancia al borde/contornos internos.
	var dist: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		for x in w:
			row[x] = 99 if solid.call(x, y) else 0
		dist.append(row)
	for _pass in 5:
		for y in h:
			for x in w:
				if int(dist[y][x]) == 0:
					continue
				var m := 99
				for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + dd.x
					var ny := y + dd.y
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						m = 0
					else:
						m = mini(m, int(dist[ny][nx]))
				dist[y][x] = mini(int(dist[y][x]), m + 1)
	var pal := biome_colors(biome, cycle)
	var jit_h := rng.randf_range(-0.02, 0.02)
	var jit_v := rng.randf_range(-0.03, 0.03)
	var ramp: Array[Color] = []
	for k: String in ["deep", "dark", "mid", "light", "hi"]:
		var c0: Color = pal[k]
		ramp.append(Color.from_hsv(fposmod(c0.h + jit_h, 1.0), c0.s, clampf(c0.v + jit_v, 0.0, 1.0)))
	var accent: Color = pal["accent"]
	var eye_col: Color = pal["eye"]
	var fire := Color("ff8a3a")
	var crack_rate := rng.randf_range(0.15, 0.6)
	var crack_seed := rng.randi()
	var outline: Color = PAL["k"]
	# 1 px de margen alrededor + 1 fila libre arriba para "stretch".
	var W := w + 2
	var H := h + 3
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var glow := Image.create(W, H, false, Image.FORMAT_RGBA8)
	glow.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var ch: String = grid[y][x]
			if ch == ".":
				continue
			var col: Color
			var emissive := false
			var up_e: bool = not solid.call(x, y - 1)
			var dn_e: bool = not solid.call(x, y + 1)
			var lf_e: bool = not solid.call(x - 1, y)
			var rt_e: bool = not solid.call(x + 1, y)
			match ch:
				"k":
					col = outline
				"E":
					col = eye_col
					var ue: bool = y > 0 and grid[y - 1][x] == "E"
					var le: bool = x > 0 and grid[y][x - 1] == "E"
					if not ue and not le:
						col = Color("fffbe8")
					emissive = true
				"W":
					col = PAL["W"] if not dn_e else Color("c8b498")
				"m":
					col = ramp[0].darkened(0.45)
				"M":
					col = PAL["M"]
				"N":
					col = PAL["m"]
				"H":
					col = PAL["n"]
				"h":
					col = PAL["h"]
				"a":
					col = accent.lightened(0.3) if up_e else accent
					emissive = true
				"1":
					col = ramp[4] if up_e else ramp[3]
				"2":
					col = ramp[2]
				"4":
					col = ramp[0]
				"3":
					col = ramp[1]
					# Grietas: algunas filas de pliegue brillan según la semilla.
					var n := fposmod(sin(float(x * 12.9898 + y * 78.233 + crack_seed % 997)) * 43758.5453, 1.0)
					if n < crack_rate and not dn_e:
						col = accent if biome != 2 else ramp[4]
						emissive = true
				_:
					var d := float(mini(int(dist[y][x]), 4))
					var lit := 0.30 + 0.10 * d - 0.22 * float(y) / h
					if up_e:
						lit += 0.30
					if lf_e:
						lit += 0.10
					if dn_e:
						lit -= 0.28
					if rt_e:
						lit -= 0.12
					var f := clampf(lit, 0.0, 0.999) * 5.0
					var i0 := int(f)
					var frac := f - i0
					if big and biome % 3 != 2 and frac > 0.55 and dither(x, y, 0.5):
						i0 += 1
					col = ramp[clampi(i0, 0, 4)]
			# Luz de fuego desde la izquierda (el horno y la heroína están ahí).
			if lf_e and ch in ["X", "1", "2", "3"] and not emissive:
				col = col.lerp(fire, 0.32)
			img.set_pixel(x + 1, y + 2, col)
			if emissive:
				glow.set_pixel(x + 1, y + 2, col.lightened(0.2))
	# Halo de 1 px alrededor de los ojos en la capa emisiva.
	var halo := glow.duplicate() as Image
	for y in H:
		for x in W:
			if glow.get_pixel(x, y).a > 0.0:
				continue
			for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + dd.x
				var ny := y + dd.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H:
					var gp := glow.get_pixel(nx, ny)
					if gp.a > 0.0 and gp.v > 0.85:
						halo.set_pixel(x, y, Color(gp.r, gp.g, gp.b, 0.35))
						break
	# Contorno exterior de 1 px.
	var out_img := img.duplicate() as Image
	for y in H:
		for x in W:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + dd.x
				var ny := y + dd.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H and img.get_pixel(nx, ny).a > 0.0:
					out_img.set_pixel(x, y, outline)
					break
	var mid_row := 2 + int(h * 0.55)
	_cache[key + ":base"] = ImageTexture.create_from_image(out_img)
	_cache[key + ":base:glow"] = ImageTexture.create_from_image(halo)
	_cache[key + ":crouch"] = ImageTexture.create_from_image(crouch_image(out_img, mid_row))
	_cache[key + ":crouch:glow"] = ImageTexture.create_from_image(crouch_image(halo, mid_row))
	_cache[key + ":stretch"] = ImageTexture.create_from_image(stretch_image(out_img, mid_row))
	_cache[key + ":stretch:glow"] = ImageTexture.create_from_image(stretch_image(halo, mid_row))
