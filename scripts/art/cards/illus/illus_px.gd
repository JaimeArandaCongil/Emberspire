class_name IllusPx
extends RefCounted
## Primitivas de pixel art para las ilustraciones de carta (68×46 nativos) y el marco.
## Reglas: todo color sale de `Palette` (rampas por material); el "suavizado" es una rampa con tramado Bayer
## SÓLO en la franja de transición entre bandas (`ramp_pick`); nada de alfa parcial ni mezclas fuera de paleta
## (para aclarar/oscurecer se sube o baja de PASO dentro de la rampa: `shift`).

const _Pal := preload("res://scripts/art/cards/card_pal.gd")
const W := 68
const H := 46
const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

static var _find_cache := {}


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


## Tramo de rampa [a..b] como Array (para ramp_pick).
static func R(mat: StringName, a: int, b: int, cold := false) -> Array:
	var out: Array = []
	for i in range(a, b + 1):
		out.append(Palette.color(mat, i, cold))
	return out


static func ink() -> Color:
	return Palette.UI[&"ink_deep"]


static func bayer(x: int, y: int) -> float:
	return (BAYER4[posmod(y, 4)][posmod(x, 4)] + 0.5) / 16.0


static func new_img(w: int = W, h: int = H) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func inb(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if inb(img, x, y) and c.a > 0.0:
		img.set_pixel(x, y, c)


static func get_c(img: Image, x: int, y: int) -> Color:
	return img.get_pixel(x, y) if inb(img, x, y) else Color(0, 0, 0, 0)


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


## Banda limpia + tramado Bayer sólo en el último `dz` de cada banda.
static func ramp_pick(ramp: Array, t: float, x: int, y: int, dz: float = 0.35) -> Color:
	t = clampf(t, 0.0, 0.9999)
	var f := t * (ramp.size() - 1)
	var i := int(f)
	var k := clampf((f - i - (1.0 - dz)) / dz, 0.0, 1.0)
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


static func sprite(rows: Array, pal: Dictionary) -> Image:
	return _Pal.sprite(rows, pal)


## Contorno exterior de 1 px (4-vecinos; `diag` también esquinas).
static func outline(src: Image, c: Color, diag: bool = false) -> Image:
	var out := src.duplicate() as Image
	for y in src.get_height():
		for x in src.get_width():
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


static func flipped(src: Image) -> Image:
	var s := src.duplicate() as Image
	s.flip_x()
	return s


static func scaled(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c


## Color desplazado `d` pasos dentro de su rampa de paleta (para luz, sombra y veladuras sin salir de paleta).
static func shifted(c: Color, d: int) -> Color:
	var k := Palette.key8(c)
	var f: Variant
	if _find_cache.has(k):
		f = _find_cache[k]
	else:
		f = Palette.find(c)
		_find_cache[k] = f
	if f == null:
		return c
	var a: Array = f
	return Palette.color(a[0], int(a[1]) + d, a[2])


static func shift(img: Image, x: int, y: int, d: int) -> void:
	if not inb(img, x, y):
		return
	var c := img.get_pixel(x, y)
	if c.a == 0.0:
		return
	img.set_pixel(x, y, shifted(c, d))


## Veladura tramada: desplaza pasos con cobertura 25/50/100 % (patrón Bayer), nunca alfa.
static func veil(img: Image, x: int, y: int, d: int, cover: float) -> void:
	if cover >= 1.0 or cover > bayer(x, y):
		shift(img, x, y, d)


## Copia de `img` recortada a una máscara Callable(x, y) -> bool.
static func masked(img: Image, f: Callable) -> Image:
	var out := img.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			if not f.call(x, y):
				out.set_pixel(x, y, Color(0, 0, 0, 0))
	return out


## Media luna (estela de golpe) entre dos círculos: dentro de A y fuera de B. `col_fn(depth 0..1, front 0..1)`.
static func crescent(img: Image, center: Vector2, ra: float, off: Vector2, rb: float, a0: float, a1: float, col_fn: Callable) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var v := Vector2(x + 0.5, y + 0.5) - center
			var ang := atan2(v.y, v.x)
			if ang < a0 or ang > a1:
				continue
			var r := v.length()
			if r > ra or (v - off).length() < rb:
				continue
			var front := (ang - a0) / (a1 - a0)
			var c: Color = col_fn.call(clampf((ra - r) / maxf(1.0, ra - rb + off.length()), 0.0, 1.0), front, x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
