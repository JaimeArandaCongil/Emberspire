class_name IllusBg
extends RefCounted
## FONDOS reutilizables de la gramática de ilustración (68×46). Cada fondo acepta su LUZ como parámetro
## (posición, radio, cálida/fría), de modo que el mismo decorado cambia de humor según la carta.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const W := 68
const H := 46


## Muro de la Torre: ladrillo 11×5 con luz puntual `lp` de radio `lr`. `cold_x`: a partir de esa x la luz es la
## fría de la Torre (rampa fría); a la izquierda, la cálida de la Forja. `amb` = luz ambiente (0..1).
static func tower_wall(img: Image, lp: Vector2, lr: float, cold_x: float = 999.0, amb: float = 0.12, hi: int = 8) -> void:
	var warm := _Px.R(&"brick", 1, hi)
	var cold := _Px.R(&"brick", 1, hi, true)
	for y in img.get_height():
		for x in img.get_width():
			var row := y / 5
			var bx := x + (5 if row % 2 == 1 else 0)
			var mortar := y % 5 == 4 or bx % 11 == 10
			var l := clampf(1.0 - Vector2(x, y).distance_to(lp) / lr, 0.0, 1.0)
			l = l * 0.85 + amb + (_Px.hash2(bx / 11, row, 3) - 0.5) * 0.10
			if y % 5 == 0 and not mortar:
				l += 0.07
			if mortar:
				l -= 0.2
			var ramp: Array = cold if x > cold_x + (_Px.bayer(x, y) - 0.5) * 6.0 else warm
			img.set_pixel(x, y, _Px.ramp_pick(ramp, l, x, y))


## Losas de piedra desde `y0` hasta abajo, iluminadas hacia `lit_x`.
static func floor_slabs(img: Image, y0: int, lit_x: float, cold := false) -> void:
	var fl := _Px.R(&"stone", 1, 6, cold)
	for y in range(y0, img.get_height()):
		for x in img.get_width():
			var l := clampf(0.6 - (y - y0) * 0.06 - absf(x - lit_x) / 90.0, 0.0, 1.0)
			var col := _Px.ramp_pick(fl, l, x, y)
			if y == y0:
				col = fl[4] if absf(x - lit_x) < 22.0 else fl[3]
			elif y == y0 + 1:
				col = fl[1]
			elif (x + (y - y0) * 4) % 19 == 0:
				col = fl[0]
			img.set_pixel(x, y, col)


## Penumbra de fragua: ladrillo refractario en sombra con un foco de calor en `focus`.
static func forge_dark(img: Image, focus: Vector2, reach: float, seed: int = 21) -> void:
	var ramp := _Px.R(&"furnace_brick", 0, 5)
	for y in img.get_height():
		for x in img.get_width():
			var l := clampf(1.0 - Vector2((x - focus.x) / 1.5, y - focus.y).length() / reach, 0.0, 1.0)
			l = l * 0.85 + (_Px.fbm(x / 10.0, y / 7.0, seed) - 0.5) * 0.12
			img.set_pixel(x, y, _Px.ramp_pick(ramp, l, x, y))


## Pilar a contraluz (profundidad) de ancho `w` en x.
static func pillar(img: Image, x0: int, w: int) -> void:
	for y in img.get_height():
		for x in range(x0, x0 + w):
			var c := _Px.P(&"furnace_brick", 0)
			if x == x0 + w - 1 and x0 < W / 2:
				c = _Px.P(&"furnace_brick", 2)
			if x == x0 and x0 > W / 2:
				c = _Px.P(&"furnace_brick", 2)
			if y % 9 == 0:
				c = _Px.P(&"furnace_brick", 1)
			_Px.put(img, x, y, c)


## Boca de horno: arco de dovelas radiales alrededor de un interior al rojo. Devuelve el radio interior.
static func furnace_mouth(img: Image, ac: Vector2, ri: float, ro: float) -> void:
	var inner := _Px.R(&"furnace_brick", 1, 8)
	var brick := _Px.R(&"brick", 0, 8)
	for y in img.get_height():
		for x in img.get_width():
			var v := Vector2((x + 0.5 - ac.x) / 1.15, y + 0.5 - ac.y)
			var r := v.length()
			if r < ri:
				var l := clampf(1.0 - Vector2((x - ac.x) / 1.8, y - ac.y - 2).length() / (ri + 4.0), 0.0, 1.0)
				l += (_Px.fbm(x / 6.0, y / 4.0, 3) - 0.5) * 0.12
				img.set_pixel(x, y, _Px.ramp_pick(inner, l, x, y))
			elif r < ro:
				var ang := atan2(v.y, v.x)
				var seg := int(floor((ang + PI) / (PI / 11.0)))
				var mortar := fposmod((ang + PI) / (PI / 11.0), 1.0) < 0.09 or r > ro - 1.0
				var l2 := 0.85 - (r - ri) / (ro - ri) * 0.5 + (_Px.hash2(seg, 0, 8) - 0.5) * 0.15
				if r < ri + 1.0:
					l2 = 0.97
				if mortar:
					l2 = 0.06
				img.set_pixel(x, y, _Px.ramp_pick(brick, l2, x, y))
			else:
				var row := y / 4
				var bx := x + (4 if row % 2 == 1 else 0)
				var l3 := 0.2 + clampf(1.0 - (r - ro) / 12.0, 0.0, 1.0) * 0.2 + (_Px.hash2(bx / 9, row, 2) - 0.5) * 0.1
				if y % 4 == 3 or bx % 9 == 8:
					l3 = 0.02
				img.set_pixel(x, y, _Px.ramp_pick(brick, l3, x, y))


## Lecho de brasas (zona `rect`), con densidad de focos `hot` (0..1).
static func ember_bed(img: Image, r: Rect2i, hot: float, seed: int = 77, clip: Callable = Callable()) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if clip.is_valid() and not clip.call(x, y):
				continue
			var n := _Px.vnoise(x / 2.0, y / 1.5, seed) + (_Px.hash2(x, y, seed + 1) - 0.5) * 0.25 + (hot - 0.5) * 0.2
			var col := _Px.P(&"fire", 0)
			if n > 0.86:
				col = _Px.P(&"fire", 6)
			elif n > 0.74:
				col = _Px.P(&"fire", 5)
			elif n > 0.58:
				col = _Px.P(&"fire", 3)
			elif n > 0.4:
				col = _Px.P(&"fire", 1)
			img.set_pixel(x, y, col)


## Pavesas sueltas (n puntos) en la zona `r`.
static func motes(img: Image, r: Rect2i, n: int, seed: int, hi := true) -> void:
	for i in n:
		var x := r.position.x + int(_Px.hash2(i, 3, seed) * r.size.x)
		var y := r.position.y + int(_Px.hash2(i, 5, seed) * r.size.y)
		_Px.put(img, x, y, _Px.P(&"fire", 6 if (hi and i % 3 == 0) else 4))
