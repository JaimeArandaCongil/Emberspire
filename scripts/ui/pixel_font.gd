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
		for r: String in base["rows"]:
			rows.append(r.rpad(w, "."))
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
