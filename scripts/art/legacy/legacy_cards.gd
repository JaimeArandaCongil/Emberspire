extends "res://scripts/art/legacy/legacy_monsters.gd"
## Arte LEGADO v0.3 (congelado) — Cartas: marco 75×105, ilustración 60×30, orbe de coste y dorsos.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Cartas -----------------------------------------------------------------

const TYPE_ART := {
	"attack": [Color("2a0c0c"), Color("6a1c14"), Color("c2401c"), Color("ffb060")],
	"skill": [Color("0c1428"), Color("1a3256"), Color("2e5a8a"), Color("a8d8ff")],
	"power": [Color("1e0e2e"), Color("4a2458"), Color("8a5a1a"), Color("ffd870")],
	"fuel": [Color("140a08"), Color("3a1c10"), Color("6a3418"), Color("ff8a2a")],
	"status": [Color("101014"), Color("26262e"), Color("3a3a44"), Color("9aa0b0")],
}
const RARITY_GEM := {"starter": Color("8a6a5a"), "common": Color("b0a8a0"), "uncommon": Color("5aa8ff"),
	"rare": Color("ffcc40"), "status": Color("6a6a74"), "token": Color("ff8a4a")}
const PARCHMENT := {"attack": Color("ead2b0"), "skill": Color("dcd6c4"), "power": Color("ecd8a8"),
	"fuel": Color("e4c8a0"), "status": Color("bab4ac")}
## Ventana de la ilustración dentro del marco (px del marco 75×105).
const ART_RECT := Rect2i(7, 16, 60, 30)


## ¿El píxel (lx, ly) de la ventana 60×30 pertenece a la forma de la ventana según el tipo?
static func window_mask(type: String, lx: int, ly: int) -> bool:
	match type:
		"attack":
			# Hoja: esquinas superiores achaflanadas y punta inferior.
			if lx + ly < 7 or (59 - lx) + ly < 7:
				return false
			var cx := absf(lx - 29.5)
			return ly < 26 or cx < 30.0 - (ly - 26) * 4.0
		"power":
			var dx := (lx - 29.5) / 30.0
			var dy := (ly - 14.5) / 15.2
			return dx * dx + dy * dy <= 1.0
		"fuel":
			if ly >= 11:
				return true
			var ax := (lx - 29.5) / 30.0
			var ay := (ly - 11.0) / 11.5
			return ax * ax + ay * ay <= 1.0
		"skill":
			return not ((lx < 2 or lx > 57) and (ly < 2 or ly > 27))
	return true


## Marco de carta 75×105 (se muestra ×2 → 150×210). Forma de ventana por tipo, cuerpo de pergamino.
func card_frame(type: String, rarity: String, upgraded: bool, mastery: int) -> Texture2D:
	var key := "cf:%s:%s:%s:%d" % [type, rarity, upgraded, mastery]
	if _cache.has(key):
		return _cache[key]
	var W := 75
	var H := 105
	var tc: Color = UI.TYPE_COLORS.get(type, Color("5a4040"))
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline: Color = PAL["k"]
	var band := tc
	if upgraded:
		band = tc.lerp(Color("ffcc50"), 0.45)
	var band_hi := band.lightened(0.35)
	var band_lo := band.darkened(0.4)
	var paper := Color("2a1c20").lerp(tc, 0.14)
	for y in H:
		for x in W:
			var c := paper
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			if edge == 0:
				c = outline
			elif edge <= 3:
				var tl := x <= 3 or y <= 3
				var br := x >= W - 4 or y >= H - 4
				c = band
				if edge == 1:
					c = band_hi if tl and not br else band_lo
				elif edge == 3:
					c = band_lo.darkened(0.2)
			img.set_pixel(x, y, c)
	# Banda del nombre.
	for y in range(4, 14):
		for x in range(4, W - 4):
			var c2 := band_lo.darkened(0.3)
			if y == 4:
				c2 = band.darkened(0.05)
			elif y == 13:
				c2 = outline
			img.set_pixel(x, y, c2)
	# Ventana con forma: marco de 1 px de banda + contorno.
	var ar := ART_RECT
	for y in range(ar.position.y - 2, ar.end.y + 2):
		for x in range(ar.position.x - 2, ar.end.x + 2):
			var lx := x - ar.position.x
			var ly := y - ar.position.y
			var inside := lx >= 0 and ly >= 0 and lx < ar.size.x and ly < ar.size.y and window_mask(type, lx, ly)
			if inside:
				img.set_pixel(x, y, outline)
				continue
			# Distancia a la ventana (1 → contorno, 2 → borde de banda).
			var near1 := false
			var near2 := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var qx := lx + dx
					var qy := ly + dy
					if qx >= 0 and qy >= 0 and qx < ar.size.x and qy < ar.size.y and window_mask(type, qx, qy):
						if absi(dx) <= 1 and absi(dy) <= 1:
							near1 = true
						else:
							near2 = true
			if near1:
				img.set_pixel(x, y, outline)
			elif near2:
				img.set_pixel(x, y, band if (y < ar.position.y + 4 or x < ar.position.x + 4) else band_lo)
	# Detalles por tipo.
	match type:
		"power":
			for i in 12:
				var a := TAU * i / 12.0
				for rr in range(2):
					var px := int(37 + cos(a) * (33 + rr))
					var py := int(31 + sin(a) * (17 + rr))
					if px > 4 and px < W - 5 and py > 14 and py < 48 and img.get_pixel(px, py) == paper:
						img.set_pixel(px, py, band.darkened(0.2))
		"skill":
			for p: Vector2i in [Vector2i(5, 16), Vector2i(68, 16), Vector2i(5, 45), Vector2i(68, 45)]:
				img.set_pixel(p.x, p.y, band_hi)
				img.set_pixel(p.x, p.y + 1, band_lo)
		"attack":
			for p: Vector2i in [Vector2i(5, 15), Vector2i(68, 15)]:
				for i in 3:
					img.set_pixel(p.x, p.y + i, band_hi if i == 0 else band)
	# Cinta del tipo.
	for y in range(48, 54):
		for x in range(16, W - 16):
			var c3 := band_lo
			if y == 48:
				c3 = band
			elif y == 53:
				c3 = outline
			if x == 16 or x == W - 17:
				c3 = outline
			img.set_pixel(x, y, c3)
	# Pergamino del texto.
	var parch: Color = PARCHMENT.get(type, Color("e0d0b0"))
	if upgraded:
		parch = parch.lerp(Color("fff0c0"), 0.25)
	for y in range(55, 99):
		for x in range(6, W - 6):
			var c4 := parch
			var e2 := mini(mini(x - 6, W - 7 - x), mini(y - 55, 98 - y))
			if e2 == 0:
				c4 = outline
			elif e2 == 1:
				c4 = parch.darkened(0.18)
			elif y == 56 + 1:
				c4 = parch.darkened(0.08)
			elif (x * 7 + y * 13) % 23 == 0:
				c4 = parch.darkened(0.05)
			img.set_pixel(x, y, c4)
	# Gema de rareza (rombo 5×5 en el borde inferior).
	var gem: Color = RARITY_GEM.get(rarity, Color("b0a8a0"))
	var gx := W / 2
	var gy := H - 4
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var md := absi(dx) + absi(dy)
			if md <= 3:
				var gc := outline
				if md <= 2:
					gc = gem.lightened(0.45) if (dx < 0 and dy < 0) else (gem.darkened(0.3) if dx + dy > 0 else gem)
				img.set_pixel(gx + dx, gy + dy, gc)
	# Maestría: ascuas a la izquierda de la gema.
	for i in mastery:
		var mx := 8 + i * 5
		var my := H - 5
		var mc := Color("ff8ad8") if mastery >= Game.MASTERY_MAX else Color("ffb43a")
		img.set_pixel(mx + 1, my - 1, mc.lightened(0.4))
		img.set_pixel(mx, my, mc)
		img.set_pixel(mx + 1, my, mc.lightened(0.2))
		img.set_pixel(mx + 2, my, mc)
		img.set_pixel(mx + 1, my + 1, mc.darkened(0.3))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Ilustración 60×30 (se muestra ×2 → 120×60, misma rejilla que el marco). Fondo por tipo en
## bandas, efecto por tipo e icono 24×24 suavizado con EPX. Fuera de la forma de ventana es transparente.
func card_art(card_id: String, type: String, icon_id: String) -> Texture2D:
	var key := "ca:" + card_id + ":" + type
	if _cache.has(key):
		return _cache[key]
	var W := 60
	var H := 30
	var cols: Array = TYPE_ART.get(type, TYPE_ART["status"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(card_id)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cx := W * 0.5 + rng.randf_range(-4.0, 4.0)
	var cy := H * 0.5
	for y in H:
		for x in W:
			var t := 1.0 - float(y) / H
			# Bandas verticales con una fila tramada entre bandas.
			var f := t * 2.999
			var i0 := int(f)
			if f - i0 > 0.82 and dither(x, y, 0.5):
				i0 += 1
			var base: Color = cols[clampi(i0, 0, 2)]
			# Halo central en anillos.
			var dx := (x - cx) / 22.0
			var dy := (y - cy) / 11.0
			var g := 1.0 - sqrt(dx * dx + dy * dy)
			if g > 0.55:
				base = base.lerp(cols[3], 0.30)
			elif g > 0.3:
				base = base.lerp(cols[3], 0.16)
			elif g > 0.1:
				base = base.lerp(cols[3], 0.07)
			img.set_pixel(x, y, base)
	match type:
		"attack":
			for i in 2:
				var sy := rng.randi_range(6, H - 8)
				for x in range(rng.randi_range(0, 10), rng.randi_range(36, W)):
					var yy := sy + int(x * 0.35) - 8
					if yy >= 0 and yy < H:
						img.set_pixel(x, yy, (cols[3] as Color).darkened(0.1))
						if yy + 1 < H:
							img.set_pixel(x, yy + 1, (cols[2] as Color).lightened(0.1))
		"power":
			for i in 10:
				var a := TAU * i / 10.0 + rng.randf() * 0.2
				for r in range(9, 34):
					var px := int(cx + cos(a) * r)
					var py := int(cy + sin(a) * r * 0.5)
					if px >= 0 and py >= 0 and px < W and py < H and r % 3 != 0:
						img.set_pixel(px, py, (cols[3] as Color).darkened(0.35))
		"skill":
			for r in [12, 16]:
				for i in 64:
					var a2 := TAU * i / 64.0
					var px2 := int(cx + cos(a2) * r)
					var py2 := int(cy + sin(a2) * r * 0.5)
					if px2 >= 0 and py2 >= 0 and px2 < W and py2 < H and i % 2 == 0:
						img.set_pixel(px2, py2, (cols[2] as Color).lightened(0.25))
		"fuel":
			# Lecho de brasas: guijarros de 2×1 con ruido estable por carta.
			var cs := rng.randi() % 1000
			for x in W:
				for y in range(H - 4, H):
					var n := _hash2(x / 2, y, cs)
					var c: Color = Color("2a140c")
					if n > 0.8:
						c = Color("ffb43a") if y < H - 2 else Color("ff8a2a")
					elif n > 0.55:
						c = Color("c2401c")
					elif n > 0.3:
						c = Color("5a2414")
					img.set_pixel(x, y, c)
		"status":
			for i in 3:
				var sy2 := rng.randi_range(4, H - 6)
				for x in W:
					var yy2 := sy2 + int(sin(x * 0.3 + i) * 1.5)
					if yy2 >= 0 and yy2 < H and x % 3 != 0:
						img.set_pixel(x, yy2, (cols[2] as Color).lightened(0.1))
	# Motas en la paleta del tipo.
	for i in 8:
		var px3 := rng.randi_range(1, W - 2)
		var py3 := rng.randi_range(1, H - 8)
		img.set_pixel(px3, py3, cols[3] if i % 2 == 0 else (cols[3] as Color).lightened(0.3))
	# Icono 24×24 con sombra arrojada.
	var ic := scale2x(icon_image(icon_id))
	var ox := int(W / 2.0 - 12)
	var oy := 3
	var shadow: Color = (cols[0] as Color).darkened(0.5)
	for y in 24:
		for x in 24:
			if ic.get_pixel(x, y).a > 0.0 and x + ox + 2 < W and y + oy + 2 < H:
				img.set_pixel(x + ox + 2, y + oy + 2, shadow)
	for y in 24:
		for x in 24:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0 and y + oy < H:
				img.set_pixel(x + ox, y + oy, p)
	# Rejilla de horno delante de las brasas.
	if type == "fuel":
		for x in range(3, W, 8):
			for y in range(H - 4, H):
				img.set_pixel(x, y, PAL["k"])
		for x in W:
			img.set_pixel(x, H - 5, Color("4a4048") if x % 8 != 3 else PAL["k"])
	# Máscara de la forma de ventana.
	for y in H:
		for x in W:
			if not window_mask(type, x, y):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Orbe de coste 16×16 (×2).
func cost_orb(affordable: bool, upgraded: bool) -> Texture2D:
	var key := "orb:%s:%s" % [affordable, upgraded]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Color("c24a1a") if affordable else Color("4a3a3a")
	if upgraded and affordable:
		base = Color("d07a1a")
	for y in 16:
		for x in 16:
			var dx := x - 7.5
			var dy := y - 7.5
			var r := sqrt(dx * dx + dy * dy)
			if r > 7.6:
				continue
			var c := base
			if r > 6.6:
				c = PAL["k"]
			else:
				var lit := (-dx - dy) / 10.0 + 0.3
				if lit > 0.55:
					c = base.lightened(0.45)
				elif lit > 0.15:
					c = base.lightened(0.15)
				elif lit < -0.45:
					c = base.darkened(0.35)
			img.set_pixel(x, y, c)
	img.set_pixel(5, 4, Color("fff4c8"))
	img.set_pixel(4, 5, Color("fff4c8"))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Dorso de carta 75×105 (×2), para la animación de robo.
func card_back() -> Texture2D:
	if _cache.has("cb"):
		return _cache["cb"]
	var W := 75
	var H := 105
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			var c := Color("3a1a18")
			if edge == 0:
				c = PAL["k"]
			elif edge <= 3:
				c = Color("8a4a2a") if edge == 1 else Color("5a2a1a")
			else:
				var dx := absf(x - W * 0.5)
				var dy := absf(y - H * 0.5)
				if int(dx + dy) % 12 == 0:
					c = Color("5a2418")
				elif dx + dy < 26:
					c = Color("4a2018")
			img.set_pixel(x, y, c)
	var ic := scale2x(icon_image("flame"))
	img.blend_rect(ic, Rect2i(0, 0, 24, 24), Vector2i(26, 40))
	var t := ImageTexture.create_from_image(img)
	_cache["cb"] = t
	return t


## Dorso pequeño 15×21 (×2 → 30×42) para pilas y cartas fantasma (sin escalados fraccionarios).
func card_back_small() -> Texture2D:
	if _cache.has("cbs"):
		return _cache["cbs"]
	var W := 15
	var H := 21
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			var c := Color("3a1a18")
			if edge == 0:
				c = PAL["k"]
			elif edge == 1:
				c = Color("8a4a2a") if (x <= 1 or y <= 1) else Color("5a2a1a")
			img.set_pixel(x, y, c)
	for p: Vector2i in [Vector2i(7, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(6, 9), Vector2i(7, 9),
			Vector2i(8, 9), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10),
			Vector2i(5, 11), Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11), Vector2i(6, 12),
			Vector2i(7, 12), Vector2i(8, 12)]:
		img.set_pixel(p.x, p.y, PAL["o"] if p.y < 10 else (PAL["y"] if p.x == 7 else PAL["r"]))
	var t := ImageTexture.create_from_image(img)
	_cache["cbs"] = t
	return t
