class_name HudArt
extends RefCounted
## Arte del HUD de combate v0.4: iconos 9×9 (intención, estados), dorsos pequeños y crisol de energía.
## Todo a mano (ASCII) o por rampas de `Palette`; se muestra a ×2. Cada intención y estado se distingue por FORMA
## además de por color (miniatura en grises, daltonismo).

const K := &"k"
const S := 2

static var _tex := {}


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


static func tex(key: String, img: Image) -> ImageTexture:
	if _tex.has(key):
		return _tex[key]
	var big := img.duplicate() as Image
	big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(big)
	_tex[key] = t
	return t


static func _sprite(rows: Array, pal: Dictionary) -> Image:
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if pal.has(row[x]):
				img.set_pixel(x, y, pal[row[x]])
	return img


# ------------------------------------------------------------------------------------------- iconos

const SWORD := ["......kkk", ".....kwmk", "....kwmk.", ".k.kwmk..", "kgkwmk...", ".kgmk....", "..kgk....", ".kbkgk...", "kbk.k...."]
const SHIELD := ["kkkkkkkkk", "kwccccbbk", "kwccccbbk", "kcccccbbk", "kcccccbbk", ".kcccbbk.", ".kcccbbk.", "..kcbbk..", "...kkk..."]
const SHIELD_SWORD := ["kkkkkkkkk", "kwccwcbbk", "kwccwcbbk", "kcgggggbk", "kcccwcbbk", ".kccwbbk.", ".kccwbbk.", "..kcwbk..", "...kkk..."]
const UP := ["....k....", "...kyk...", "..kyyyk..", ".kyyyyyk.", "kkkyyykkk", "..kyyyk..", "..kyyyk..", "..koook..", "..kkkkk.."]
const DOWN := ["..kkkkk..", "..koook..", "..kyyyk..", "..kyyyk..", "kkkyyykkk", ".kyyyyyk.", "..kyyyk..", "...kyk...", "....k...."]
const SKULL := [".kkkkkkk.", "kwwwwwwwk", "kwkkwkkwk", "kwkkwkkwk", "kwwwkwwwk", ".kwwwwwk.", "..kwkwk..", "..kwkwk..", "...kkk..."]
const COIN := ["...kkk...", "..kyyok..", ".kywyook.", "kywyyoork", "kyyyoorrk", "kyoooorRk", ".korrrRk.", "..kRRRk..", "...kkk..."]
const EYE := ["..kkkkk..", ".kwwwwwk.", "kwwkkkwwk", "kwkyykkwk", "kwkyykkwk", "kwwkkkwwk", ".kwwwwwk.", "..kkkkk..", "........."]
## Fuerza: martillo alzado. Débil: hoja partida. Vulnerable: escudo rajado. Quemadura: llama. Espinas: abrojo.
## Regeneración: cruz. Asfixia: bocanada de humo.
const HAMMER := ["kkkkkkk..", "kwmmmbk..", "kwmmmbkk.", "kkkkkkrrk", "....kkrrk", "...krrkk.", "..krrk...", ".krrk....", ".kkk....."]
const BROKEN := ["......kkk", ".....kwmk", "....kwmk.", "....kkk..", "..k......", ".kmk.....", "kgmk.....", ".kgk.....", "..k......"]
const CRACKED := ["kkkkkkkkk", "kwccroobk", "kwcrcobbk", "kcccrcbbk", "kccrccbbk", ".kcrcbbk.", ".kccrbbk.", "..kcrbk..", "...kkk..."]
const FLAME := ["....k....", "...kyk...", "..kyok.k.", "..koyokyk", ".kooyyook", "kooywyook", "kroywyork", ".krooork.", "..kkkkk.."]
const THORNS := ["....k....", ".k.kwk.k.", "kwkkmkkwk", ".kmmmmmk.", "kkmmbmmkk", ".kmmmmmk.", "kwkkmkkwk", ".k.kbk.k.", "....k...."]
const CROSS := ["...kkk...", "...kwk...", "...kgk...", "kkkkgkkkk", "kwgggggbk", "kkkkgkkkk", "...kgk...", "...kbk...", "...kkk..."]
const SMOKE := ["..kkkk...", ".kwwmmk..", "kwwmkkmk.", "kwmk.kmk.", "kwmkkmmkk", ".kmmmmwwk", "..kkmmwmk", "...kkmmk.", ".....kk.."]

const INTENTS := ["attack", "attack_heavy", "attack_debuff", "attack_defend", "defend", "buff", "debuff", "steal", "summon", "unknown"]
const STATUSES := ["str", "weak", "vuln", "scorch", "thorns", "regen", "choke"]


static func _pal_steel() -> Dictionary:
	return {"k": Palette.OUTLINE, "w": P(&"steel", 6, true), "m": P(&"steel", 5, true), "g": P(&"gold", 4), "b": P(&"leather", 4)}


## Escudo en el color del bloqueo (`frost_glow`, como su contorno en StatusFX): el acero claro se perdía sobre el muro.
static func _pal_shield() -> Dictionary:
	return {"k": Palette.OUTLINE, "w": P(&"frost_glow", 5), "c": P(&"frost_glow", 3), "b": P(&"frost_glow", 2), "g": P(&"gold", 4)}


static func _pal_fire() -> Dictionary:
	return {"k": Palette.OUTLINE, "y": P(&"ember_ui", 5), "w": P(&"ember_ui", 6), "o": P(&"ember_ui", 3), "r": P(&"ember_ui", 2), "R": P(&"ember_ui", 1)}


## Icono de intención 9×9 (nativo). `kind`: ver INTENTS.
static func intent_image(kind: String) -> Image:
	match kind:
		"attack":
			return _sprite(SWORD, _pal_steel())
		"attack_heavy":
			return _sprite(SWORD, {"k": Palette.OUTLINE, "w": P(&"fire", 7), "m": P(&"fire", 4), "g": P(&"fire", 3), "b": P(&"fire", 2)})
		"attack_debuff":
			return _sprite(SWORD, {"k": Palette.OUTLINE, "w": P(&"magic", 4), "m": P(&"magic", 3), "g": P(&"gold", 4), "b": P(&"leather", 4)})
		"attack_defend":
			return _sprite(SHIELD_SWORD, _pal_shield())
		"defend":
			return _sprite(SHIELD, _pal_shield())
		"buff":
			return _sprite(UP, {"k": Palette.OUTLINE, "y": P(&"gold", 5), "o": P(&"gold", 3)})
		"debuff":
			return _sprite(DOWN, {"k": Palette.OUTLINE, "y": P(&"magic", 4), "o": P(&"magic", 2)})
		"steal":
			return _sprite(COIN, _pal_fire())
		"summon":
			return _sprite(SKULL, {"k": Palette.OUTLINE, "w": P(&"linen", 5)})
	return _sprite(EYE, {"k": Palette.OUTLINE, "w": P(&"linen", 4), "y": P(&"magic", 4)})


## Icono de estado 9×9 (nativo). `id`: ver STATUSES.
static func status_image(id: String) -> Image:
	match id:
		"str":
			return _sprite(HAMMER, {"k": Palette.OUTLINE, "w": P(&"steel", 6, true), "m": P(&"steel", 4, true), "b": P(&"steel", 2, true), "r": P(&"blood", 3)})
		"weak":
			return _sprite(BROKEN, {"k": Palette.OUTLINE, "w": P(&"ash", 8), "m": P(&"ash", 5), "g": P(&"ash", 3)})
		"vuln":
			return _sprite(CRACKED, {"k": Palette.OUTLINE, "w": P(&"steel", 5, true), "c": P(&"steel", 4, true), "b": P(&"steel", 2, true), "r": P(&"magic", 4), "o": P(&"magic", 3)})
		"scorch":
			return _sprite(FLAME, _pal_fire())
		"thorns":
			return _sprite(THORNS, {"k": Palette.OUTLINE, "w": P(&"linen", 5), "m": P(&"wood", 6), "b": P(&"wood", 3)})
		"regen":
			return _sprite(CROSS, {"k": Palette.OUTLINE, "w": P(&"heal", 4), "g": P(&"heal", 3), "b": P(&"heal", 2)})
		"choke":
			return _sprite(SMOKE, {"k": Palette.OUTLINE, "w": P(&"ash", 7, true), "m": P(&"ash", 4, true)})
	return _sprite(EYE, {"k": Palette.OUTLINE, "w": P(&"linen", 4), "y": P(&"magic", 4)})


## Placa de intención: `w` × 13 px nativos más una punta de 2 hacia el dueño. Contorno, canto claro arriba y cara oscura.
static func intent_plate(w: int) -> ImageTexture:
	var key := "intplate:%d" % w
	if _tex.has(key):
		return _tex[key]
	var body_h := 13
	var img := Image.create(w, body_h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in body_h:
		for x in w:
			var corner := (x == 0 or x == w - 1) and (y == 0 or y == body_h - 1)
			if corner:
				continue
			var edge := x == 0 or x == w - 1 or y == 0 or y == body_h - 1
			img.set_pixel(x, y, Palette.OUTLINE if edge else (P(&"plate", 5) if y == 1 else P(&"plate", 2)))
	var cx := w / 2
	for x in range(cx - 1, cx + 2):
		img.set_pixel(x, body_h, Palette.OUTLINE)
	img.set_pixel(cx, body_h, P(&"plate", 2))
	img.set_pixel(cx, body_h + 1, Palette.OUTLINE)
	return tex(key, img)


static func intent_texture(kind: String) -> ImageTexture:
	return tex("int:" + kind, intent_image(kind))


static func status_texture(id: String) -> ImageTexture:
	return tex("st:" + id, status_image(id))


## Icono v0.3 (12×12) ajustado a la paleta, para Poderes hasta que tengan el suyo. Textura ×2 (24 px).
static func legacy_icon(id: String) -> ImageTexture:
	var key := "leg:" + id
	if _tex.has(key):
		return _tex[key]
	var img := (Art.icon_image(id) as Image).duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a > 0.0:
				img.set_pixel(x, y, CardPal.snap(Color(p, 1.0)))
	return tex(key, img)


# ------------------------------------------------------------------------------------------- pilas

## Dorso pequeño 15×21 con hasta 3 cartas apiladas (4 px más). `kind`: draw | discard | exhaust. `n`: cartas (0 = hueco).
static func pile_image(kind: String, n: int) -> Image:
	var layers := clampi(n, 0, 3)
	var w := 15 + 2
	var h := 21 + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if layers == 0:
		# Hueco: marco punteado.
		for y in range(2, h):
			for x in range(0, 15):
				var e := mini(mini(x, 14 - x), mini(y - 2, h - 1 - y))
				if e == 0 and (x + y) % 2 == 0:
					img.set_pixel(x, y, P(&"plate", 4))
		return img
	var mat: StringName = &"frame_attack"
	var glyph: Color = P(&"ember_ui", 4)
	match kind:
		"discard":
			mat = &"frame_status"
			glyph = P(&"ash", 8)
		"exhaust":
			mat = &"frame_fuel"
			glyph = P(&"ember_ui", 3)
	for i in range(layers - 1, -1, -1):
		var ox := 2 - i if layers == 3 else (1 - i if layers == 2 else 0)
		ox = i
		var oy := 2 - i
		for y in 21:
			for x in 15:
				var e2 := mini(mini(x, 14 - x), mini(y, 20 - y))
				var col: Color = P(mat, 2)
				if e2 == 0:
					col = Palette.OUTLINE
				elif e2 == 1:
					col = P(mat, 5) if (x == 1 or y == 1) else P(mat, 3)
				elif (x + y) % 4 == 0:
					col = P(mat, 3)
				img.set_pixel(x + ox, y + oy, col)
	# Llama en el dorso de la carta de arriba (con ceniza si está exiliada).
	var oy2 := 2
	for p: Vector2i in [Vector2i(7, 6), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8),
			Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10),
			Vector2i(8, 10), Vector2i(9, 10), Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11)]:
		img.set_pixel(p.x, p.y + oy2, glyph if p.y < 9 else (P(&"ember_ui", 5) if p.x == 7 and kind != "discard" else glyph))
	return img


# ------------------------------------------------------------------------------------------- crisol

const CRUCIBLE_W := 46
const CRUCIBLE_H := 44
const CRUCIBLE_FRAMES := 4


## Crisol de hierro con metal fundido (DA): el nivel es la energía. `level` 0..8; `frame` 0..3 (oleaje y burbujas).
static func crucible_image(level: int, frame: int) -> Image:
	var img := Image.create(CRUCIBLE_W, CRUCIBLE_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(22.5, 20.5)
	var ro := 18.0
	var ri := 13.0
	# Patas y anillo de apoyo.
	for leg: Array in [[8, 34, 5, 43], [37, 34, 40, 43], [22, 37, 22, 43]]:
		_line(img, leg[0], leg[1], leg[2], leg[3], P(&"iron", 3))
		_line(img, int(leg[0]) + 1, leg[1], int(leg[2]) + 1, leg[3], P(&"iron", 5))
	# Asas laterales.
	for s: int in [-1, 1]:
		for k in 4:
			var hx := int(c.x + s * (ro + k * 0.5))
			img.set_pixel(hx, int(c.y) - 6 + k, Palette.OUTLINE)
			img.set_pixel(hx, int(c.y) + 3 - k, Palette.OUTLINE)
		img.set_pixel(int(c.x + s * (ro + 2)), int(c.y) - 2, P(&"iron", 6))
		img.set_pixel(int(c.x + s * (ro + 2)), int(c.y) - 1, P(&"iron", 5))
	var surf := int(round(c.y + ri - 1.0 - (ri * 2.0 - 2.0) * level / 8.0))
	var iron := [P(&"iron", 2), P(&"iron", 3), P(&"iron", 4), P(&"iron", 5), P(&"iron", 6), P(&"iron", 7), P(&"iron", 8)]
	for y in CRUCIBLE_H:
		for x in CRUCIBLE_W:
			var v := Vector2(x + 0.5, y + 0.5) - c
			var d := v.length()
			if d > ro + 1.0:
				continue
			var col: Color
			if d > ro:
				col = Palette.OUTLINE
			elif d > ri + 1.0:
				# Pared de hierro: luz arriba-izquierda, rebote caliente abajo si hay metal.
				var lit := 0.5 + (-v.x - v.y * 1.3) / (ro * 2.6)
				if d > ro - 1.0:
					lit += 0.12
				var idx := clampi(int(lit * 6.99), 0, 6)
				if (x + y) % 2 == 0 and fmod(lit * 6.99, 1.0) > 0.7:
					idx = mini(idx + 1, 6)
				col = iron[idx]
			elif d > ri:
				col = Palette.OUTLINE
			else:
				var wave := int(round(sin(x * 0.7 + frame * PI * 0.5) * 0.7))
				if level > 0 and y >= surf + wave:
					var depth := y - (surf + wave)
					var k := 7 if depth == 0 else (6 if depth <= 1 else (5 if depth <= 3 else (4 if depth <= 7 else 3)))
					if depth > 7 and depth % 2 == 1 and (x + y + frame) % 4 == 0:
						k = 2
					col = P(&"fire", k)
				else:
					col = P(&"iron", 1) if y < c.y else P(&"iron", 2)
					# Reflejo del metal en la pared interior, sobre la superficie.
					if level > 0 and y >= surf - 2 and d > ri - 2.0:
						col = P(&"fire", 2)
			img.set_pixel(x, y, col)
	# Burbujas que suben (posición por fotograma).
	if level > 1:
		for b: Vector2i in [Vector2i(16, 2), Vector2i(27, 0), Vector2i(21, 3)]:
			var bx := b.x
			var by: int = int(c.y + ri - 3.0) - ((frame * 3 + b.y * 3) % 12)
			if by > surf + 1 and Vector2(bx + 0.5, by + 0.5).distance_to(c) < ri - 1.0:
				img.set_pixel(bx, by, P(&"fire", 7))
	# Brillo especular del borde.
	img.set_pixel(11, 8, P(&"iron", 10))
	img.set_pixel(12, 7, P(&"iron", 10))
	img.set_pixel(13, 6, P(&"iron", 9))
	return img


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		var t := float(i) / maxi(1, n)
		var x := int(round(lerpf(x0, x1, t)))
		var y := int(round(lerpf(y0, y1, t)))
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, col)
