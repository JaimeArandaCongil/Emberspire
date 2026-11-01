extends "res://scripts/art/legacy/legacy_forge.gd"
## Arte LEGADO v0.3 (congelado) — Viñetas de evento, puertas del mapa y logotipo.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Viñetas de evento y puertas ----------------------------------------------

const EVENT_SCENES := {
	"altar": ["candle", Color("3a1a2a"), Color("ff8a3a")], "smith": ["anvil", Color("2a1a14"), Color("ff6a1a")],
	"well": ["drop", Color("101a2a"), Color("8ab4d0")], "mirror": ["moon", Color("1a1a2e"), Color("d0d4ff")],
	"merchant": ["chest", Color("2a1e10"), Color("ffcc40")], "forge_spirit": ["furnace", Color("1e1418"), Color("ff7a2a")],
	"gambler": ["gem", Color("201030"), Color("d0a8ff")], "hollow_shrine": ["skull", Color("14141a"), Color("9a5ad0")],
	"frozen_traveller": ["snowflake", Color("0e1a2a"), Color("8ab4d0")], "library": ["book", Color("1e1410"), Color("ffb43a")],
	"anvil_trial": ["hammer", Color("1a1414"), Color("ff6a1a")], "wind_bellows": ["wind", Color("141a22"), Color("c8e0f0")],
	"star_fall": ["star", Color("0e0e24"), Color("ffe08a")], "coal_mine": ["coal", Color("140c0a"), Color("ff6a1a")],
	"tinkerer": ["gear", Color("16161a"), Color("d0d4d8")], "burning_bridge": ["fire_wall", Color("1e0c0a"), Color("ff6a1a")],
}


## Viñeta de evento 96×48 (mostrar a ×4 → 384×192 o ×2): fondo en bandas, cono de luz, pedestal,
## protagonista a 24×24 (EPX) y velas laterales.
func event_art(id: String) -> Texture2D:
	var key := "ev:" + id
	if _cache.has(key):
		return _cache[key]
	var sc: Array = EVENT_SCENES.get(id, ["unknown", Color("1a1418"), Color("ffb43a")])
	var W := 96
	var H := 48
	var bg: Color = sc[1]
	var light: Color = sc[2]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var t := float(y) / H
			var c := bg.darkened(0.3).lerp(bg.lightened(0.08), floorf(t * 4.0) / 4.0)
			if y >= 36:
				c = bg.lightened(0.1) if (y == 36) else bg.darkened(0.1 + 0.04 * ((x / 8 + y / 3) % 2))
			# Cono de luz desde arriba.
			var half := 8.0 + y * 0.45
			if absf(x - 47.5) < half and y < 40:
				c = c.lerp(light, 0.10 if absf(x - 47.5) < half * 0.6 else 0.05)
			img.set_pixel(x, y, c)
	# Pedestal.
	for y in range(30, 38):
		for x in range(34, 62):
			var c2 := Color("5a5058") if y == 30 else Color("3a3238")
			if x == 34 or x == 61 or y == 37:
				c2 = PAL["k"]
			img.set_pixel(x, y, c2)
	# Protagonista.
	var ic := scale2x(icon_image(sc[0]))
	for y in 24:
		for x in 24:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0:
				img.set_pixel(36 + x + 1, 6 + y + 1, bg.darkened(0.6))
	img.blend_rect(ic, Rect2i(0, 0, 24, 24), Vector2i(36, 6))
	# Velas laterales.
	for vx: int in [16, 78]:
		for y in range(28, 36):
			img.set_pixel(vx, y, PAL["W"])
			img.set_pixel(vx + 1, y, Color("c8b498"))
		img.set_pixel(vx, 27, PAL["k"])
		img.set_pixel(vx, 25, PAL["y"])
		img.set_pixel(vx, 26, PAL["o"])
		img.set_pixel(vx + 1, 26, PAL["o"].darkened(0.3))
		for dy in range(-4, 3):
			for dx in range(-4, 5):
				if dx * dx + dy * dy < 14 and img.get_pixel(vx + dx, 26 + dy) != PAL["W"]:
					img.set_pixel(vx + dx, 26 + dy, img.get_pixel(vx + dx, 26 + dy).lerp(Color("ff9a4a"), 0.12))
	# Marco.
	for x in W:
		img.set_pixel(x, 0, PAL["k"])
		img.set_pixel(x, H - 1, PAL["k"])
	for y in H:
		img.set_pixel(0, y, PAL["k"])
		img.set_pixel(W - 1, y, PAL["k"])
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


const DOOR_COLORS := {"combat": Color("c2321e"), "elite": Color("b02a5a"), "rest": Color("ff8a2a"),
	"shop": Color("ffb43a"), "event": Color("9a5ad0"), "treasure": Color("ffd040"), "boss": Color("ff3a1a")}


## Puerta 28×36 (mostrar a ×4 → 112×144): arco de dovelas, interior oscuro, resplandor del destino e icono.
func door_art(kind: String, biome: int = 0) -> Texture2D:
	var key := "door:%s:%d" % [kind, biome]
	if _cache.has(key):
		return _cache[key]
	var W := 28
	var H := 36
	var pal := biome_colors(biome)
	var col: Color = DOOR_COLORS.get(kind, Color("ffb43a"))
	var stone: Color = (pal["wall"] as Color).lightened(0.22)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := 13.5
	var ay := 13.0
	for y in H:
		for x in W:
			var dx := x - cx
			var d := sqrt(dx * dx + (y - ay) * (y - ay)) if y < ay else absf(dx)
			if d <= 9.5:
				var t := float(y) / H
				var c := Color("0c0709").lerp(col.darkened(0.55), clampf((t - 0.45) * 1.6, 0.0, 1.0))
				if t > 0.82:
					c = col.darkened(0.25)
				img.set_pixel(x, y, c)
			elif d <= 13.5:
				var ang := atan2(float(y) - ay, dx)
				var joint := int(floor(ang * 3.0)) != int(floor((ang + 0.12) * 3.0)) if y < ay else (y % 6 == 0)
				var c2 := stone.lightened(0.1) if dx < 0 else stone.darkened(0.1)
				if joint:
					c2 = pal["mortar"]
				if d > 12.6 or d < 10.3:
					c2 = PAL["k"]
				img.set_pixel(x, y, c2)
	# Clave del arco.
	for y in range(0, 4):
		for x in range(12, 16):
			img.set_pixel(x, y, PAL["k"] if (y == 0 or x == 12 or x == 15) else col)
	# Escalón.
	for x in range(1, W - 1):
		img.set_pixel(x, H - 2, stone)
		img.set_pixel(x, H - 1, PAL["k"])
	var ic := icon_image(DOOR_ICONS.get(kind, "unknown"))
	img.blend_rect(ic, Rect2i(0, 0, 12, 12), Vector2i(8, 10))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


const DOOR_ICONS := {"combat": "sword", "elite": "skull", "rest": "bonfire", "shop": "anvil", "event": "eye",
	"treasure": "chest", "boss": "crown"}


## Logotipo EMBERSPIRE (≈100×18) a partir de la fuente pixel engordada ×2 con rampa de fuego.
func logo() -> Texture2D:
	if _cache.has("logo"):
		return _cache["logo"]
	var text := "EMBERSPIRE"
	var cells: Array = []
	var total := 0
	for i in text.length():
		var g := PixelFont.glyph(text[i])
		cells.append(g)
		total += int(g["w"]) * 2 + 2
	var W := total + 4
	var H := 7 * 2 + 6
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ramp: Array[Color] = [PAL["Y"], PAL["w"], PAL["y"], PAL["y"], PAL["o"], PAL["o"], PAL["r"]]
	var x0 := 2
	var on := {}
	for g: Dictionary in cells:
		var rows: Array = g["rows"]
		for gy in 7:
			var row: String = rows[gy + 2]
			for gx in int(g["w"]):
				if row[gx] == "#":
					for sy in 2:
						for sx in 2:
							on[Vector2i(x0 + gx * 2 + sx, 2 + gy * 2 + sy)] = gy
		x0 += int(g["w"]) * 2 + 2
	# Sombra y contorno.
	for p: Vector2i in on:
		for d: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]:
			var q := p + d
			if not on.has(q) and q.x < W and q.y < H:
				img.set_pixel(q.x, q.y, PAL["R"])
	for p: Vector2i in on:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var q2 := p + Vector2i(dx, dy)
				if not on.has(q2) and q2.x >= 0 and q2.y >= 0 and q2.x < W and q2.y < H:
					img.set_pixel(q2.x, q2.y, PAL["k"])
	for p: Vector2i in on:
		var gy2: int = on[p]
		var c: Color = ramp[gy2]
		if not on.has(p + Vector2i(0, -1)):
			c = c.lightened(0.25)
		img.set_pixel(p.x, p.y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache["logo"] = tex
	return tex
