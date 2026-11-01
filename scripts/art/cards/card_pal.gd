class_name CardPal
extends RefCounted
## Color de cartas e interfaz sobre la paleta maestra de DA (`Palette`).
## - `m(material, paso)`: color de una rampa (forma preferida).
## - `c("hex")`: atajo para colores escritos a mano; se AJUSTA al color de paleta más cercano (distancia perceptual
##   ponderada), de modo que todo lo que dibujan cartas e interfaz cumple la prueba de paleta cerrada.
## - `snap(color)`: lo mismo para colores calculados (lighten/darken/lerp).

static var _snap_cache := {}
static var _list: Array[Color] = []


static func m(material: StringName, step: int) -> Color:
	return Palette.color(material, step)


static func c(h: String) -> Color:
	return snap(Color(h))


static func snap(col: Color) -> Color:
	if col.a == 0.0:
		return col
	var k := Palette.key8(col)
	if _snap_cache.has(k):
		var r: Color = _snap_cache[k]
		return Color(r, col.a)
	if _list.is_empty():
		for key: int in Palette.all_colors():
			_list.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255))
	var best := _list[0]
	var bd := INF
	for p: Color in _list:
		var dr := (col.r - p.r) * 0.30
		var dg := (col.g - p.g) * 0.59
		var db := (col.b - p.b) * 0.11
		var d := dr * dr + dg * dg + db * db + 0.08 * pow(col.get_luminance() - p.get_luminance(), 2.0)
		if d < bd:
			bd = d
			best = p
	_snap_cache[k] = best
	return Color(best, col.a)


## Sprite ASCII → Image (paleta de caracteres; '.' y ' ' transparentes).
static func sprite(rows: Array, pal: Dictionary) -> Image:
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return img
