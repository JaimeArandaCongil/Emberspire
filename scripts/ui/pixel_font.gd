class_name PixelFont
extends RefCounted
## Fuente pixel 5×7 proporcional generada en runtime (sin binarios).
## Celda de glifo: 2 filas de acento + 7 de cuerpo + 2 de descendente; contorno `k` horneado.
## Uso: `PixelFont.font()`; el tamaño de fuente debe ser múltiplo de CELL_H (escalado entero).
## `PixelFont.px_size(scale)` devuelve el font_size para un factor de escala entero.

const CELL_H := 11          # alto lógico del glifo (acentos + cuerpo + descendente)
const ASCENT := 9           # filas por encima de la línea base
const LINE_H := 13          # alto de línea con contorno (11 + 2)

## Cuerpo del glifo: filas separadas por "|". Sin "^": la primera fila es la fila 2 (cuerpo).
## Con "^": la primera fila es la fila 0 (zona de acentos).
const GLYPHS := {
	"A": ".##.|#..#|#..#|####|#..#|#..#|#..#",
	"B": "###.|#..#|#..#|###.|#..#|#..#|###.",
	"C": ".##.|#..#|#...|#...|#...|#..#|.##.",
	"D": "###.|#..#|#..#|#..#|#..#|#..#|###.",
	"E": "####|#...|#...|###.|#...|#...|####",
	"F": "####|#...|#...|###.|#...|#...|#...",
	"G": ".##.|#..#|#...|#.##|#..#|#..#|.###",
	"H": "#..#|#..#|#..#|####|#..#|#..#|#..#",
	"I": "###|.#.|.#.|.#.|.#.|.#.|###",
	"J": "..##|...#|...#|...#|#..#|#..#|.##.",
	"K": "#..#|#..#|#.#.|##..|#.#.|#..#|#..#",
	"L": "#...|#...|#...|#...|#...|#...|####",
	"M": "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#",
	"N": "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
	"O": ".##.|#..#|#..#|#..#|#..#|#..#|.##.",
	"P": "###.|#..#|#..#|###.|#...|#...|#...",
	"Q": ".##.|#..#|#..#|#..#|#..#|#.#.|.#.#",
	"R": "###.|#..#|#..#|###.|#.#.|#..#|#..#",
	"S": ".###|#...|#...|.##.|...#|...#|###.",
	"T": "#####|..#..|..#..|..#..|..#..|..#..|..#..",
	"U": "#..#|#..#|#..#|#..#|#..#|#..#|.##.",
	"V": "#...#|#...#|#...#|.#.#.|.#.#.|..#..|..#..",
	"W": "#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#",
	"X": "#...#|.#.#.|.#.#.|..#..|.#.#.|.#.#.|#...#",
	"Y": "#...#|.#.#.|.#.#.|..#..|..#..|..#..|..#..",
	"Z": "####|...#|..#.|.#..|#...|#...|####",
	"a": "....|....|.##.|...#|.###|#..#|.###",
	"b": "#...|#...|###.|#..#|#..#|#..#|###.",
	"c": "...|...|.##|#..|#..|#..|.##",
	"d": "...#|...#|.###|#..#|#..#|#..#|.###",
	"e": "....|....|.##.|#..#|####|#...|.###",
	"f": ".##|#..|###|#..|#..|#..|#..",
	"g": "....|....|.###|#..#|#..#|.###|...#|###.",
	"h": "#...|#...|###.|#..#|#..#|#..#|#..#",
	"i": "#|.|#|#|#|#|#",
	"j": "..#|...|..#|..#|..#|..#|#.#|.#.",
	"k": "#...|#...|#..#|#.#.|##..|#.#.|#..#",
	"l": "#.|#.|#.|#.|#.|#.|.#",
	"m": ".....|.....|##.#.|#.#.#|#.#.#|#.#.#|#.#.#",
	"n": "....|....|###.|#..#|#..#|#..#|#..#",
	"o": "....|....|.##.|#..#|#..#|#..#|.##.",
	"p": "....|....|###.|#..#|#..#|###.|#...|#...",
	"q": "....|....|.###|#..#|#..#|.###|...#|...#",
	"r": "...|...|#.#|##.|#..|#..|#..",
	"s": "....|....|.###|#...|.##.|...#|###.",
	"t": ".#.|.#.|###|.#.|.#.|.#.|..#",
	"u": "....|....|#..#|#..#|#..#|#..#|.###",
	"v": "...|...|#.#|#.#|#.#|#.#|.#.",
	"w": ".....|.....|#...#|#...#|#.#.#|#.#.#|.#.#.",
	"x": "...|...|#.#|#.#|.#.|#.#|#.#",
	"y": "....|....|#..#|#..#|#..#|.###|...#|###.",
	"z": "....|....|####|..#.|.#..|#...|####",
	"0": ".##.|#..#|#.##|##.#|#..#|#..#|.##.",
	"1": ".#.|##.|.#.|.#.|.#.|.#.|###",
	"2": ".##.|#..#|...#|..#.|.#..|#...|####",
	"3": "###.|...#|...#|.##.|...#|...#|###.",
	"4": "#..#|#..#|#..#|####|...#|...#|...#",
	"5": "####|#...|###.|...#|...#|#..#|.##.",
	"6": ".##.|#...|#...|###.|#..#|#..#|.##.",
	"7": "####|...#|..#.|..#.|.#..|.#..|.#..",
	"8": ".##.|#..#|#..#|.##.|#..#|#..#|.##.",
	"9": ".##.|#..#|#..#|.###|...#|...#|.##.",
	".": ".|.|.|.|.|.|#",
	",": ".|.|.|.|.|.|#|#",
	":": ".|.|#|.|.|.|#",
	";": ".|.|#|.|.|.|#|#",
	"!": "#|#|#|#|#|.|#",
	"?": ".##.|#..#|...#|..#.|.#..|....|.#..",
	"¡": "#|.|#|#|#|#|#",
	"¿": "..#.|....|..#.|.#..|#...|#..#|.##.",
	"'": "#|#|.|.|.|.|.",
	"\"": "#.#|#.#|...|...|...|...|...",
	"(": ".#|#.|#.|#.|#.|#.|.#",
	")": "#.|.#|.#|.#|.#|.#|#.",
	"[": "##|#.|#.|#.|#.|#.|##",
	"]": "##|.#|.#|.#|.#|.#|##",
	"+": "...|...|.#.|###|.#.|...|...",
	"-": "...|...|...|###|...|...|...",
	"−": "...|...|...|###|...|...|...",
	"=": "...|...|###|...|###|...|...",
	"/": "..#|..#|.#.|.#.|.#.|#..|#..",
	"%": "##..#|##.#.|...#.|..#..|.#...|.#.##|#..##",
	"*": "...|#.#|.#.|#.#|...|...|...",
	"×": "...|...|#.#|.#.|#.#|...|...",
	"·": ".|.|.|#|.|.|.",
	"«": "....|....|.#.#|#.#.|.#.#|....|....",
	"»": "....|....|#.#.|.#.#|#.#.|....|....",
	"<": "...|..#|.#.|#..|.#.|..#|...",
	">": "...|#..|.#.|..#|.#.|#..|...",
	"#": ".#.#.|#####|.#.#.|.#.#.|#####|.#.#.|.....",
	"&": ".#..|#.#.|.#..|#.#.|#..#|#.#.|.#.#",
	"_": "...|...|...|...|...|...|...|###",
	"→": "....|....|..#.|####|..#.|....|....",
	"…": ".....|.....|.....|.....|.....|.....|#.#.#",
	"♪": ".###|.#.#|.#.#|.#..|##..|##..|....",
	"◆": ".....|..#..|.###.|#####|.###.|..#..|.....",
	"◇": ".....|..#..|.#.#.|#...#|.#.#.|..#..|.....",
	"★": "..#..|..#..|#####|.###.|.#.#.|#...#|.....",
	"✦": "..#..|..#..|.###.|#####|.###.|..#..|..#..",
}

## Acentos: base + patrón de 2 filas (se centra sobre el glifo).
const ACCENTS := {
	"á": ["a", "acute"], "é": ["e", "acute"], "í": ["ı", "acute"], "ó": ["o", "acute"], "ú": ["u", "acute"],
	"Á": ["A", "acute"], "É": ["E", "acute"], "Í": ["I", "acute"], "Ó": ["O", "acute"], "Ú": ["U", "acute"],
	"ñ": ["n", "tilde"], "Ñ": ["N", "tilde"], "ü": ["u", "diaer"], "Ü": ["U", "diaer"],
}
const ACCENT_ROWS := {"acute": ["..#", ".#."], "tilde": [".#.#", "#.#."], "diaer": ["#..#", "...."]}

static var _font: FontFile
static var _glyph_bits := {}     # char -> {w, rows: Array[String] (11 filas)}


## Mapa de bits de un carácter: 11 filas de ancho w ("#" encendido).
static func glyph(ch: String) -> Dictionary:
	if _glyph_bits.is_empty():
		_build_bits()
	if _glyph_bits.has(ch):
		return _glyph_bits[ch]
	var up := ch.to_upper()
	if _glyph_bits.has(up):
		return _glyph_bits[up]
	return _glyph_bits["?"]


static func _parse(src: String) -> Dictionary:
	var top := 2
	if src.begins_with("^"):
		top = 0
		src = src.substr(1)
	var parts := src.split("|")
	var w := 0
	for p in parts:
		w = maxi(w, p.length())
	var rows: Array[String] = []
	for i in CELL_H:
		rows.append(".".repeat(w))
	for i in parts.size():
		if top + i < CELL_H:
			rows[top + i] = parts[i].rpad(w, ".")
	return {"w": w, "rows": rows}


static func _build_bits() -> void:
	for ch: String in GLYPHS:
		_glyph_bits[ch] = _parse(GLYPHS[ch])
	# i sin punto para los acentos.
	_glyph_bits["ı"] = _parse(".|.|#|#|#|#|#")
	for ch: String in ACCENTS:
		var base: Dictionary = _glyph_bits[ACCENTS[ch][0]]
		var acc: Array = ACCENT_ROWS[ACCENTS[ch][1]]
		var w: int = maxi(int(base["w"]), String(acc[0]).length())
		var rows: Array[String] = []
		var lead := "." if int(base["w"]) == 1 else ""
		for r: String in base["rows"]:
			rows.append((lead + r).rpad(w, "."))
		var is_upper: bool = ch == ch.to_upper()
		var ay := 0 if is_upper else 2
		for i in 2:
			var a: String = acc[i]
			var ox := int((w - a.length()) / 2.0 + 0.5)
			var row := rows[ay + i]
			for x in a.length():
				if a[x] == "#" and ox + x < w:
					row = row.substr(0, ox + x) + "#" + row.substr(ox + x + 1)
			rows[ay + i] = row
		# Las mayúsculas acentuadas pierden la fila superior del cuerpo si choca con el acento.
		_glyph_bits[ch] = {"w": w, "rows": rows}


## Tamaño de fuente que produce escala entera `s`.
static func px_size(s: int) -> int:
	return LINE_H * maxi(1, s)


static func font() -> FontFile:
	if _font != null:
		return _font
	if _glyph_bits.is_empty():
		_build_bits()
	var chars: Array = _glyph_bits.keys()
	chars.erase("ı")
	# Atlas: cada glifo con 1 px de contorno alrededor.
	var total_w := 0
	for ch: String in chars:
		total_w += int(_glyph_bits[ch]["w"]) + 3
	var img := Image.create(total_w + 8, LINE_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var f := FontFile.new()
	f.fixed_size = LINE_H
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NONE
	var sz := Vector2i(LINE_H, 0)
	f.set_cache_ascent(0, LINE_H, ASCENT + 1)
	f.set_cache_descent(0, LINE_H, LINE_H - ASCENT - 1)
	var outline := Color("1a0f12")
	var x0 := 0
	for ch: String in chars:
		var g: Dictionary = _glyph_bits[ch]
		var w: int = g["w"]
		var rows: Array = g["rows"]
		var cw := w + 2
		# Contorno.
		for y in CELL_H:
			var row: String = rows[y]
			for x in w:
				if row[x] != "#":
					continue
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var px := x0 + 1 + x + dx
						var py := 1 + y + dy
						if img.get_pixel(px, py).a == 0.0:
							img.set_pixel(px, py, outline)
		for y in CELL_H:
			var row2: String = rows[y]
			for x in w:
				if row2[x] == "#":
					img.set_pixel(x0 + 1 + x, 1 + y, Color.WHITE)
		var gid := ch.unicode_at(0)
		f.set_glyph_advance(0, LINE_H, gid, Vector2(w + 1, 0))
		f.set_glyph_offset(0, sz, gid, Vector2(-1, -ASCENT - 2))
		f.set_glyph_size(0, sz, gid, Vector2(cw, LINE_H))
		f.set_glyph_uv_rect(0, sz, gid, Rect2(x0, 0, cw, LINE_H))
		f.set_glyph_texture_idx(0, sz, gid, 0)
		x0 += cw + 1
	# Espacio.
	f.set_glyph_advance(0, LINE_H, 32, Vector2(3, 0))
	f.set_glyph_advance(0, LINE_H, 160, Vector2(3, 0))
	f.set_texture_image(0, sz, 0, img)
	_font = f
	return f


## Ancho en píxeles lógicos (escala 1) de un texto de una línea.
static func text_width(text: String) -> int:
	var w := 0
	for i in text.length():
		var ch := text[i]
		if ch == " ":
			w += 3
		else:
			w += int(glyph(ch)["w"]) + 1
	return maxi(0, w - 1)


# =====================================================================================
# v0.4 · Pavesa (6×9, cuerpo de carta y tooltips a ×1) y Mini (3×5, etiquetas a ×2)
# =====================================================================================
## Pavesa deriva de Fragua (la fuente de arriba): duplica las filas 1 y 5 del cuerpo y la columna 1 de los glifos
## de ≥ 4 px de ancho. Celda: 2 filas de acento + 9 de cuerpo + 2 de descendente = 13; interlínea 14.
## Sin contorno: sobre pergamino es tinta; sobre fondo oscuro `UI.label()` añade sombra de 1 px.
## Mini: mayúsculas y cifras de 5 filas, minúsculas de x-altura 4, acento propio en la fila 0, descendente en la 6.

const P_CELL := 13
const P_ASCENT := 11
const P_LINE := 14
const M_CELL := 7
const M_ASCENT := 6
const M_LINE := 8

const MINI_GLYPHS := {
	"A": "1.#.|#.#|###|#.#|#.#", "B": "1##.|#.#|##.|#.#|##.", "C": "1.##|#..|#..|#..|.##", "D": "1##.|#.#|#.#|#.#|##.",
	"E": "1###|#..|##.|#..|###", "F": "1###|#..|##.|#..|#..", "G": "1.##|#..|#.#|#.#|.##", "H": "1#.#|#.#|###|#.#|#.#",
	"I": "1###|.#.|.#.|.#.|###", "J": "1..#|..#|..#|#.#|.#.", "K": "1#.#|#.#|##.|#.#|#.#", "L": "1#..|#..|#..|#..|###",
	"M": "1#...#|##.##|#.#.#|#...#|#...#", "N": "1#..#|##.#|#.##|#..#|#..#", "O": "1.#.|#.#|#.#|#.#|.#.",
	"P": "1##.|#.#|##.|#..|#..", "Q": "1.#.|#.#|#.#|###|.##", "R": "1##.|#.#|##.|#.#|#.#", "S": "1.##|#..|.#.|..#|##.",
	"T": "1###|.#.|.#.|.#.|.#.", "U": "1#.#|#.#|#.#|#.#|###", "V": "1#.#|#.#|#.#|.#.|.#.", "W": "1#...#|#...#|#.#.#|##.##|#...#",
	"X": "1#.#|#.#|.#.|#.#|#.#", "Y": "1#.#|#.#|.#.|.#.|.#.", "Z": "1###|..#|.#.|#..|###",
	"a": "2##.|..#|#.#|.##", "b": "1#..|##.|#.#|#.#|##.", "c": "2.##|#..|#..|.##", "d": "1..#|.##|#.#|#.#|.##",
	"e": "2.#.|#.#|##.|.##", "f": "1.##|#..|##.|#..|#..", "g": "2.##|#.#|.##|..#|##.", "h": "1#..|##.|#.#|#.#|#.#",
	"i": "1#|.|#|#|#", "j": "1.#|..|.#|.#|.#|#.", "k": "1#..|#.#|##.|##.|#.#", "l": "1#.|#.|#.|#.|.#",
	"m": "2##.#.|#.#.#|#.#.#|#.#.#", "n": "2##.|#.#|#.#|#.#", "o": "2.#.|#.#|#.#|.#.", "p": "2##.|#.#|#.#|##.|#..",
	"q": "2.##|#.#|#.#|.##|..#", "r": "2#.#|##.|#..|#..", "s": "2.##|##.|..#|##.", "t": "1.#.|###|.#.|.#.|.##",
	"u": "2#.#|#.#|#.#|.##", "v": "2#.#|#.#|#.#|.#.", "w": "2#...#|#.#.#|#.#.#|.#.#.", "x": "2#.#|.#.|.#.|#.#",
	"y": "2#.#|#.#|.##|..#|##.", "z": "2###|..#|.#.|###",
	"0": "1###|#.#|#.#|#.#|###", "1": "1.#.|##.|.#.|.#.|###", "2": "1##.|..#|.#.|#..|###", "3": "1##.|..#|.#.|..#|##.",
	"4": "1#.#|#.#|###|..#|..#", "5": "1###|#..|##.|..#|##.", "6": "1.##|#..|###|#.#|###", "7": "1###|..#|.#.|.#.|.#.",
	"8": "1###|#.#|###|#.#|###", "9": "1###|#.#|###|..#|##.",
	".": "5#", ",": "5#|#", ":": "2#|.|.|#", ";": "2#|.|.|#|#", "!": "1#|#|#|.|#", "?": "1##.|..#|.#.|...|.#.",
	"¡": "1#|.|#|#|#", "¿": "1.#.|...|.#.|#..|.##", "(": "1.#|#.|#.|#.|.#", ")": "1#.|.#|.#|.#|#.",
	"+": "2...|.#.|###|.#.", "-": "3###", "−": "3###", "×": "2...|#.#|.#.|#.#", "%": "1#.#|..#|.#.|#..|#.#",
	"/": "1..#|..#|.#.|#..|#..", "·": "3#", "=": "2...|###|...|###", "*": "1#.#|.#.|#.#", "<": "1..#|.#.|#..|.#.|..#",
	">": "1#..|.#.|..#|.#.|#..", "→": "2..#.|####|..#.", "«": "2.#.#|#.#.|.#.#", "»": "2#.#.|.#.#|#.#.",
	"◆": "1.#.|###|###|###|.#.", "◇": "1.#.|#.#|#.#|#.#|.#.", "★": "1.#.|###|.#.|#.#",
}
const MINI_ACCENTS := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ñ": "n", "ü": "u",
	"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ñ": "N"}

static var _pavesa: FontFile
static var _pavesa_bold: FontFile
static var _mini: FontFile
static var _p_bits := {}
static var _m_bits := {}


static func _pavesa_from(g: Dictionary) -> Dictionary:
	var w: int = g["w"]
	var out: Array[String] = []
	var rows: Array = g["rows"]
	for y in rows.size():
		var r: String = rows[y]
		if w >= 4:
			r = r.substr(0, 2) + r.substr(1, 1) + r.substr(2)
		out.append(r)
		if y == 3 or y == 7:
			out.append(r)
	return {"w": w + (1 if w >= 4 else 0), "rows": out}


## Mapa de bits Pavesa (13 filas).
static func pavesa_glyph(ch: String) -> Dictionary:
	if _p_bits.is_empty():
		if _glyph_bits.is_empty():
			_build_bits()
		for k: String in _glyph_bits:
			_p_bits[k] = _pavesa_from(_glyph_bits[k])
	if _p_bits.has(ch):
		return _p_bits[ch]
	if _p_bits.has(ch.to_upper()):
		return _p_bits[ch.to_upper()]
	return _p_bits["?"]


static func _mini_parse(src: String) -> Dictionary:
	var top := int(src.substr(0, 1))
	var parts := src.substr(1).split("|")
	var w := 0
	for p in parts:
		w = maxi(w, p.length())
	var rows: Array[String] = []
	for i in M_CELL:
		rows.append(".".repeat(w))
	for i in parts.size():
		if top + i < M_CELL:
			rows[top + i] = parts[i].rpad(w, ".")
	return {"w": w, "rows": rows}


## Mapa de bits Mini (7 filas).
static func mini_glyph(ch: String) -> Dictionary:
	if _m_bits.is_empty():
		for k: String in MINI_GLYPHS:
			_m_bits[k] = _mini_parse(MINI_GLYPHS[k])
		_m_bits["'"] = _mini_parse("1#|#")
		for k2: String in MINI_ACCENTS:
			var base: Dictionary = _m_bits[MINI_ACCENTS[k2]]
			var w: int = base["w"]
			var rows: Array[String] = []
			for r: String in base["rows"]:
				rows.append(r)
			var acc := ""
			if k2 == "ñ" or k2 == "Ñ":
				acc = "##."
			elif k2 == "ü":
				acc = "#.#"
			elif w == 1:
				acc = "#"
			else:
				acc = ".".repeat(w / 2) + "#"
			rows[0] = acc.rpad(w, ".").substr(0, w)
			_m_bits[k2] = {"w": w, "rows": rows}
	if _m_bits.has(ch):
		return _m_bits[ch]
	if _m_bits.has(ch.to_upper()):
		return _m_bits[ch.to_upper()]
	return _m_bits["?"]


## FontFile de mapa de bits sin contorno. `bold` engrosa 1 px a la derecha (doble trazo).
static func _bitmap_font(chars: Array, getter: Callable, cell: int, ascent: int, line: int, space: int, bold: bool) -> FontFile:
	var total := 8
	for ch: String in chars:
		total += int(getter.call(ch)["w"]) + 3
	var img := Image.create(total, cell, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var f := FontFile.new()
	f.fixed_size = line
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NONE
	var sz := Vector2i(line, 0)
	f.set_cache_ascent(0, line, ascent)
	f.set_cache_descent(0, line, line - ascent)
	var x0 := 0
	for ch: String in chars:
		var g: Dictionary = getter.call(ch)
		var w: int = g["w"]
		var rows: Array = g["rows"]
		var gw := w + (1 if bold else 0)
		for y in mini(cell, rows.size()):
			var r: String = rows[y]
			for x in w:
				if r[x] == "#":
					img.set_pixel(x0 + x, y, Color.WHITE)
					if bold:
						img.set_pixel(x0 + x + 1, y, Color.WHITE)
		var gid := ch.unicode_at(0)
		f.set_glyph_advance(0, line, gid, Vector2(gw + 1, 0))
		f.set_glyph_offset(0, sz, gid, Vector2(0, -ascent))
		f.set_glyph_size(0, sz, gid, Vector2(gw, cell))
		f.set_glyph_uv_rect(0, sz, gid, Rect2(x0, 0, gw, cell))
		f.set_glyph_texture_idx(0, sz, gid, 0)
		x0 += gw + 2
	for sp: int in [32, 160]:
		f.set_glyph_advance(0, line, sp, Vector2(space, 0))
	f.set_texture_image(0, sz, 0, img)
	return f


## Pavesa 6×9 (×1). Usar con `font_size = PixelFont.P_LINE`.
static func pavesa() -> FontFile:
	if _pavesa == null:
		pavesa_glyph("a")
		var chars: Array = _p_bits.keys()
		chars.erase("ı")
		_pavesa = _bitmap_font(chars, pavesa_glyph, P_CELL, P_ASCENT, P_LINE, 4, false)
	return _pavesa


## Pavesa negrita (doble trazo): cifras de las cartas.
static func pavesa_bold() -> FontFile:
	if _pavesa_bold == null:
		pavesa_glyph("a")
		var chars: Array = _p_bits.keys()
		chars.erase("ı")
		_pavesa_bold = _bitmap_font(chars, pavesa_glyph, P_CELL, P_ASCENT, P_LINE, 4, true)
	return _pavesa_bold


## Mini 3×5. Usar a ×2: `font_size = PixelFont.mini_size(2)`.
static func mini() -> FontFile:
	if _mini == null:
		mini_glyph("a")
		_mini = _bitmap_font(_m_bits.keys(), mini_glyph, M_CELL, M_ASCENT, M_LINE, 3, false)
	return _mini


static func mini_size(scale: int = 2) -> int:
	return M_LINE * maxi(1, scale)


static func pavesa_width(text: String, bold: bool = false) -> int:
	var w := 0
	for i in text.length():
		var ch := text[i]
		w += 4 if ch == " " else int(pavesa_glyph(ch)["w"]) + 1 + (1 if bold else 0)
	return maxi(0, w - 1)


static func mini_width(text: String) -> int:
	var w := 0
	for i in text.length():
		var ch := text[i]
		w += 3 if ch == " " else int(mini_glyph(ch)["w"]) + 1
	return maxi(0, w - 1)
