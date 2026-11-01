extends RefCounted
## Primitivas de pixel art por código (prueba de concepto v0.4 · cartas e interfaz).
## Todo opera sobre Image RGBA8 en píxeles nativos. Nada de antialiasing: el "suavizado" se hace con
## rampas de color elegidas a mano y tramado ordenado (Bayer 4×4) sólo en las transiciones.

const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


static func bayer(x: int, y: int) -> float:
	return (BAYER4[posmod(y, 4)][posmod(x, 4)] + 0.5) / 16.0


static func new_img(w: int, h: int, fill: Color = Color(0, 0, 0, 0)) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	return img


static func inb(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if inb(img, x, y) and c.a > 0.0:
		img.set_pixel(x, y, c)


static func get_c(img: Image, x: int, y: int) -> Color:
	if inb(img, x, y):
		return img.get_pixel(x, y)
	return Color(0, 0, 0, 0)


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			put(img, xx, yy, c)


static func hline(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		put(img, x, y, c)


static func vline(img: Image, x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		put(img, x, y, c)


static func line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		put(img, x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


static func disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
		for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				put(img, x, y, c)


## Rampa con tramado sólo en el último `dz` de cada banda (bandas limpias, transición tramada).
static func ramp_pick(ramp: Array, t: float, x: int, y: int, dz: float = 0.35) -> Color:
	t = clampf(t, 0.0, 0.9999)
	var f := t * (ramp.size() - 1)
	var i := int(f)
	var fr := f - i
	var k := clampf((fr - (1.0 - dz)) / dz, 0.0, 1.0)
	if k > bayer(x, y) and i + 1 < ramp.size():
		i += 1
	return ramp[i]


static func hash2(x: int, y: int, s: int = 0) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177
	h = h & 0x7fffffff
	return float(h % 10000) / 10000.0


static func vnoise(x: float, y: float, s: int = 0) -> float:
	var ix := int(floor(x))
	var iy := int(floor(y))
	var fx := x - ix
	var fy := y - iy
	var a := hash2(ix, iy, s)
	var b := hash2(ix + 1, iy, s)
	var c := hash2(ix, iy + 1, s)
	var d := hash2(ix + 1, iy + 1, s)
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy)


static func fbm(x: float, y: float, s: int = 0) -> float:
	return vnoise(x, y, s) * 0.6 + vnoise(x * 2.0, y * 2.0, s + 7) * 0.3 + vnoise(x * 4.0, y * 4.0, s + 13) * 0.1


## Sprite ASCII → Image. `pal`: carácter → Color. '.' y ' ' transparentes.
static func sprite(rows: Array, pal: Dictionary) -> Image:
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img := new_img(w, rows.size())
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return img


## Contorno exterior de 1 px (4-vecinos; `diag` añade esquinas) sobre una capa transparente.
static func outline(src: Image, c: Color, diag: bool = false) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := src.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			var hit := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if get_c(src, x + d.x, y + d.y).a > 0.0:
					hit = true
			if diag and not hit:
				for d2: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
					if get_c(src, x + d2.x, y + d2.y).a > 0.0:
						hit = true
			if hit:
				out.set_pixel(x, y, c)
	return out


static func blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


static func blit_flip(dst: Image, src: Image, x: int, y: int) -> void:
	var s := src.duplicate() as Image
	s.flip_x()
	blit(dst, s, x, y)


## Recorta `img` a una máscara (Callable(x, y) -> bool).
static func mask(img: Image, f: Callable) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if not f.call(x, y):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


static func scaled(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c


## Mezcla `c` sobre el píxel con opacidad `a` cuantizada a 0/25/50/75/100 % mediante trama (sin alfa real).
static func tint(img: Image, x: int, y: int, c: Color, a: float) -> void:
	if not inb(img, x, y):
		return
	var q := snappedf(clampf(a, 0.0, 1.0), 0.25)
	if q <= 0.0:
		return
	var base := img.get_pixel(x, y)
	if base.a == 0.0:
		return
	img.set_pixel(x, y, base.lerp(Color(c, 1.0), q))


## Texto con la fuente pixel del juego (PixelFont 5×7) a escala 1 en píxeles del lienzo.
## `tall` = variante "Pavesa" 6×9 para el cuerpo de las cartas a ×1 de pantalla: duplica las filas 2 y 6
## del cuerpo y la columna 1 (glifos de ≥4 de ancho). Mismo ADN que la fuente de títulos, más legible.
static var _tall_cache := {}


static func glyph(ch: String, tall: bool) -> Dictionary:
	var g: Dictionary = PixelFont.glyph(ch)
	if not tall:
		return g
	if _tall_cache.has(ch):
		return _tall_cache[ch]
	var w: int = g["w"]
	var rows: Array = g["rows"]
	var out: Array = []
	for y in rows.size():
		var r: String = rows[y]
		if w >= 4:
			r = r.substr(0, 2) + r.substr(1, 1) + r.substr(2)
		out.append(r)
		if y == 3 or y == 7:
			out.append(r)
	var res := {"w": w + (1 if w >= 4 else 0), "rows": out}
	_tall_cache[ch] = res
	return res


static func text_w(t: String, tall: bool = false) -> int:
	var w := 0
	for i in t.length():
		var ch := t[i]
		if ch == " ":
			w += 4 if tall else 3
		else:
			w += int(glyph(ch, tall)["w"]) + 1
	return maxi(0, w - 1)


static func text(img: Image, x: int, y: int, t: String, c: Color, shadow: Color = Color(0, 0, 0, 0), outline_c: Color = Color(0, 0, 0, 0), tall: bool = false) -> void:
	var cx := x
	for i in t.length():
		var ch := t[i]
		if ch == " ":
			cx += 4 if tall else 3
			continue
		var g: Dictionary = glyph(ch, tall)
		var gw: int = g["w"]
		var rows: Array = g["rows"]
		if outline_c.a > 0.0:
			for yy in rows.size():
				var r0: String = rows[yy]
				for xx in gw:
					if r0[xx] == "#":
						for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
							put(img, cx + xx + d.x, y + yy + d.y, outline_c)
		if shadow.a > 0.0:
			for yy in rows.size():
				var r1: String = rows[yy]
				for xx in gw:
					if r1[xx] == "#":
						put(img, cx + xx + 1, y + yy + 1, shadow)
		for yy in rows.size():
			var r2: String = rows[yy]
			for xx in gw:
				if r2[xx] == "#":
					put(img, cx + xx, y + yy, c)
		cx += gw + 1
