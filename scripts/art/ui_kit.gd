class_name UIKit
extends RefCounted
## Kit de interfaz pixel v0.4: piezas 9-slice dibujadas por código a resolución nativa (rejilla ×2) y
## convertidas en `StyleBoxTexture` que TESELAN bordes y centro (AXIS_STRETCH_MODE_TILE): nunca se estira un píxel.
## Piezas: piedra (paneles grandes), hierro (HUD, tooltip, ranuras), pergamino (texto largo), botón ×4 estados,
## pestaña activa/inactiva, barra, y `plate(cara, canto)` para teñir paneles a medida (sustituye a StyleBoxFlat).
## Colores: SIEMPRE de la paleta maestra (`Palette`), por material y paso. Los colores que llegan de fuera
## (`plate(cara, canto)` desde `UI.box`) se ajustan a la paleta con `_Pal.snap`.

const _Pal := preload("res://scripts/art/cards/card_pal.gd")
const S := 2   # escala de la interfaz (rejilla de arte 640×360 → 1280×720)
static var K: Color = Palette.UI[&"k"]

static var _cache := {}


static func M(mat: StringName, step: int) -> Color:
	return Palette.color(mat, step)


# ------------------------------------------------------------------------------------------- utilidades

static func _img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _hash(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 1274126177) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10000) / 10000.0


## Textura ×S de una imagen nativa (cacheada por clave).
static func texture(key: String, img: Image) -> ImageTexture:
	var k := "tex:" + key
	if _cache.has(k):
		return _cache[k]
	var big := img.duplicate() as Image
	big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(big)
	_cache[k] = t
	return t


## StyleBoxTexture teselado. `m` = margen nativo de la pieza; `pad` = margen de contenido (px de pantalla).
static func stylebox(key: String, img: Image, m: int, pad: Vector4 = Vector4(10, 6, 10, 6), shadow: int = 0) -> StyleBoxTexture:
	var k := "sb:%s:%d:%s:%d" % [key, m, pad, shadow]
	if _cache.has(k):
		return _cache[k]
	var sb := StyleBoxTexture.new()
	sb.texture = texture(key, img)
	sb.texture_margin_left = m * S
	sb.texture_margin_top = m * S
	sb.texture_margin_right = (m + shadow) * S
	sb.texture_margin_bottom = (m + shadow) * S
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z + shadow * S
	sb.content_margin_bottom = pad.w + shadow * S
	sb.expand_margin_right = 0
	_cache[k] = sb
	return sb


## Sube o baja `d` pasos dentro de la rampa a la que pertenece el color (si no está en paleta, se ajusta antes).
static func _shift(col: Color, d: int) -> Color:
	var f: Variant = Palette.find(_Pal.snap(col))
	if f == null:
		return _Pal.snap(col)
	var a: Array = f
	return Color(Palette.color(a[0], int(a[1]) + d, a[2]), col.a)


# ------------------------------------------------------------------------------------------- piezas

## PIEDRA 24×24, margen 8: sillares biselados de la Torre; centro oscuro y liso (zona tranquila para texto).
static func stone() -> Image:
	if _cache.has("img:stone"):
		return _cache["img:stone"]
	var s := 24
	var img := _img(s, s)
	var st := [M(&"stone", 1), M(&"stone", 2), M(&"stone", 3), M(&"stone", 4), M(&"stone", 6)]
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var col: Color = st[1]
			if e == 0:
				col = K
			elif e < 7:
				var bx := x % 8
				var by := y % 6 if (x < 7 or x > 16) else (y + 3) % 6
				if y < 7 or y > 16:
					by = y % 6
					bx = (x + (4 if (y / 6) % 2 == 1 else 0)) % 8
				if bx == 0 or by == 0:
					col = st[0]
				elif bx == 1 or by == 1:
					col = st[4]
				elif bx == 7 or by == 5:
					col = st[2]
				else:
					col = st[3] if _hash(x, y, 3) > 0.12 else st[2]
			elif e == 7:
				col = K
			else:
				col = st[1]
			img.set_pixel(x, y, col)
	_cache["img:stone"] = img
	return img


## HIERRO 16×16, margen 5: chapa con doble bisel y remaches. `b` = paso base de la rampa `plate` (2–5).
static func iron(b: int = 4) -> Image:
	var key := "img:iron:%d" % b
	if _cache.has(key):
		return _cache[key]
	var s := 16
	var img := _img(s, s)
	var P := func(d: int) -> Color: return M(&"plate", clampi(b + d, 0, 6))
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var tl := (y == e and x < s - 1 - e) or (x == e and y < s - 1 - e)
			var col: Color = P.call(0)
			if e == 0:
				col = K
			elif e == 1:
				col = P.call(2) if tl else P.call(-2)
			elif e == 2 or e == 3:
				col = P.call(1)
			elif e == 4:
				col = P.call(-3) if tl else P.call(1)
			else:
				col = P.call(-1)
			img.set_pixel(x, y, col)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(s - 4, 2), Vector2i(2, s - 4), Vector2i(s - 4, s - 4)]:
		img.set_pixel(p.x, p.y, P.call(3))
		img.set_pixel(p.x + 1, p.y, P.call(2))
		img.set_pixel(p.x, p.y + 1, P.call(2))
		img.set_pixel(p.x + 1, p.y + 1, P.call(-3))
	_cache[key] = img
	return img


## PERGAMINO 16×16, margen 5: borde tostado y fibras.
static func parchment() -> Image:
	if _cache.has("img:parch"):
		return _cache["img:parch"]
	var s := 16
	var img := _img(s, s)
	var pr := [M(&"parchment", 1), M(&"parchment", 2), M(&"parchment", 3), M(&"parchment", 4)]
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var col: Color = pr[3]
			if e == 0:
				col = K
			elif e == 1:
				col = pr[0]
			elif e == 2:
				col = pr[1] if (x + y) % 2 == 0 else pr[2]
			elif e == 3:
				col = pr[2]
			img.set_pixel(x, y, col)
	_cache["img:parch"] = img
	return img


## BOTÓN de forja 20×14, margen 6. Estados: normal, hover (incandescente), pressed (hundido), disabled (frío).
static func button(state: String) -> Image:
	var key := "img:btn:" + state
	if _cache.has(key):
		return _cache[key]
	var w := 20
	var h := 14
	var img := _img(w, h)
	var fb := &"furnace_brick"
	var face := M(fb, 4)
	var hi := M(fb, 6)
	var lo := M(fb, 2)
	var rim := M(fb, 1)
	var lo2 := M(fb, 1)
	match state:
		"hover":
			face = M(fb, 5)
			hi = M(&"ember_ui", 4)
			lo = M(fb, 3)
			rim = M(&"ember_ui", 3)
			lo2 = M(fb, 2)
		"pressed":
			face = M(fb, 3)
			hi = M(fb, 2)
			lo = M(fb, 5)
		"disabled":
			face = M(&"plate", 3)
			hi = M(&"plate", 4)
			lo = M(&"plate", 2)
			rim = M(&"plate", 1)
			lo2 = M(&"plate", 1)
	var off := 1 if state == "pressed" else 0
	for y in h:
		for x in w:
			var e := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
				continue
			var col := face
			if e == 0:
				col = K
			elif y == h - 2 and state != "pressed":
				col = lo2
			elif e == 1:
				col = rim if state == "hover" else (hi if (y == 1 + off or x == 1) else lo)
			elif y == 2 + off:
				col = hi
			elif y >= h - 4 + off:
				col = lo
			img.set_pixel(x, y, col)
	if state == "hover":
		for x in range(3, w - 3, 2):
			img.set_pixel(x, 2, M(&"ember_ui", 5))
	_cache[key] = img
	return img


## PESTAÑA 16×12, margen 5: activa (se funde con el panel, cálida) / inactiva (hundida, fría).
static func tab(active: bool, hovered: bool = false) -> Image:
	var key := "img:tab:%s:%s" % [active, hovered]
	if _cache.has(key):
		return _cache[key]
	var w := 16
	var h := 12
	var img := _img(w, h)
	var face := M(&"brick", 5) if active else (M(&"plate", 3) if hovered else M(&"plate", 2))
	for y in h:
		for x in w:
			if y == 0 and (x == 0 or x == w - 1):
				continue
			var col := face
			if x == 0 or x == w - 1 or y == 0:
				col = K
			elif y == 1:
				col = M(&"ember_ui", 4) if active else (M(&"copper", 5) if hovered else M(&"plate", 4))
			elif x == 1:
				col = M(&"brick", 6) if active else M(&"plate", 4)
			elif x == w - 2:
				col = M(&"brick", 3) if active else M(&"plate", 1)
			elif y == h - 1:
				col = face if active else K
			img.set_pixel(x, y, col)
	_cache[key] = img
	return img


## PLACA teñida 12×12 (margen = grosor + 1): sustituye a los StyleBoxFlat de color a medida.
## `face` transparente → sólo marco (anillos de selección). `shadow` añade sombra pixel abajo-derecha.
static func plate(face: Color, rim: Color, thick: int = 2, shadow: int = 0) -> Image:
	face = _Pal.snap(face)
	rim = _Pal.snap(rim)
	var key := "img:plate:%s:%s:%d:%d" % [face.to_html(), rim.to_html(), thick, shadow]
	if _cache.has(key):
		return _cache[key]
	var s := 12
	var img := _img(s + shadow, s + shadow)
	if shadow > 0:
		for y in range(shadow, s + shadow):
			for x in range(shadow, s + shadow):
				img.set_pixel(x, y, Palette.OUTLINE)
	var outline := rim.a > 0.0 and thick > 0
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var tl := (y == e and x < s - 1 - e) or (x == e and y < s - 1 - e)
			var col := face
			if e == 0 and outline:
				col = K
			elif e >= 1 and e <= thick and rim.a > 0.0:
				col = _shift(rim, 1) if (e == 1 and tl) else (_shift(rim, -1) if e == 1 else rim)
				col.a = rim.a
			elif face.a > 0.0:
				if e == thick + 1 and tl:
					col = _shift(face, -1)
				elif e == thick + 1:
					col = _shift(face, 1)
			else:
				col = Color(0, 0, 0, 0)
			img.set_pixel(x, y, col)
	_cache[key] = img
	return img


## BARRA nativa (vida, bloqueo, calor, progreso): marco de hierro + relleno con luz arriba y sombra abajo.
static func bar(w: int, frac: float, fill: Array, frame: Color = Palette.color(&"plate", 3)) -> Image:
	var h := 7
	var img := _img(w, h)
	var cut := int(round((w - 4) * clampf(frac, 0.0, 1.0)))
	for y in h:
		for x in w:
			if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
				continue
			var col := frame
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				col = K
			elif x == 1 or y == 1 or x == w - 2 or y == h - 2:
				col = M(&"plate", 4) if y == 1 else frame
			else:
				var fx := x - 2
				if fx < cut:
					col = fill[1]
					if y == 2:
						col = fill[2]
					elif y == h - 3:
						col = fill[0]
					if fx == cut - 1 and y > 2:
						col = fill[2]
				else:
					col = M(&"plate", 1)
			img.set_pixel(x, y, col)
	return img


# ------------------------------------------------------------------------------------------- estilos listos

static func sb_stone() -> StyleBoxTexture:
	return stylebox("stone", stone(), 8, Vector4(18, 16, 18, 16))


static func sb_iron(b: int = 4, pad: Vector4 = Vector4(12, 8, 12, 8)) -> StyleBoxTexture:
	return stylebox("iron%d" % b, iron(b), 5, pad)


static func sb_parchment() -> StyleBoxTexture:
	return stylebox("parch", parchment(), 5, Vector4(14, 10, 14, 10))


static func sb_button(state: String) -> StyleBoxTexture:
	var pad := Vector4(12, 6, 12, 8) if state != "pressed" else Vector4(12, 8, 12, 6)
	return stylebox("btn" + state, button(state), 6, pad)


static func sb_tab(active: bool, hovered: bool = false) -> StyleBoxTexture:
	return stylebox("tab%s%s" % [active, hovered], tab(active, hovered), 5, Vector4(10, 4, 10, 4))


static func sb_plate(face: Color, rim: Color, thick: int = 2, shadow: int = 0, pad: Vector4 = Vector4(10, 6, 10, 6)) -> StyleBoxTexture:
	var key := "plate%s%s%d%d" % [face.to_html(), rim.to_html(), thick, shadow]
	return stylebox(key, plate(face, rim, thick, shadow), thick + 2, pad, shadow)


static func bar_texture(w: int, frac: float, fill: Array) -> ImageTexture:
	return ImageTexture.create_from_image(_scaled(bar(w, frac, fill)))


static func _scaled(img: Image) -> Image:
	var big := img.duplicate() as Image
	big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
	return big


# ------------------------------------------------------------------------------------------- iconos 9×9

static func ember_icon() -> Image:
	return _Pal.sprite([
		"...kkk...",
		"..kyyok..",
		".kywyook.",
		"kywyyoork",
		"kyyyoorrk",
		"kyoooorRk",
		".korrrRk.",
		"..kRRRk..",
		"...kkk...",
	], {"k": K, "w": M(&"ember_ui", 6), "y": M(&"ember_ui", 5), "o": M(&"ember_ui", 3), "r": M(&"ember_ui", 2), "R": M(&"ember_ui", 1)})
