class_name IllusSubj
extends RefCounted
## SUJETOS reutilizables (armas, criaturas, objetos). Se combinan con otra pose, luz y efecto para que ninguna
## carta repita composición (regla C5). Todas devuelven Image con contorno propio o dibujan en `img`.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


## Espada a 45° (empuñadura abajo-izquierda): `base` = unión hoja-guarda, `L` = largo de la hoja.
## `metal`: "steel" (plata fría) | "hot" (al rojo). Devuelve capa con contorno.
static func sword45(w: int, h: int, base: Vector2i, L: int, metal: String = "steel") -> Image:
	var sw := _Px.new_img(w, h)
	var edge: Color = P(&"steel", 6, true)
	var mid: Color = P(&"steel", 5, true)
	var sh: Color = P(&"steel", 4, true)
	var back: Color = P(&"steel", 3, true)
	if metal == "hot":
		edge = P(&"fire", 7)
		mid = P(&"fire", 6)
		sh = P(&"fire", 4)
		back = P(&"fire", 3)
	for i in L:
		var px := base.x + i
		var py := base.y - i
		_Px.put(sw, px, py, mid)
		if i < L - 1:
			_Px.put(sw, px - 1, py, edge)
			_Px.put(sw, px, py + 1, sh)
		if i < L - 3 and i > 2:
			_Px.put(sw, px + 1, py + 1, back)
	# Guarda perpendicular de latón, puño de cuero, pomo.
	for j in range(-4, 5):
		var gx := base.x - 1 + j
		var gy := base.y + 1 + j
		_Px.put(sw, gx, gy, P(&"gold", 5) if absi(j) == 4 else P(&"gold", 4))
		_Px.put(sw, gx + 1, gy, P(&"gold", 2))
	for i in range(1, 6):
		var hx := base.x - 1 - i
		var hy := base.y + 2 + i
		_Px.put(sw, hx, hy, P(&"leather", 5) if i % 2 == 0 else P(&"leather", 3))
		_Px.put(sw, hx + 1, hy, P(&"leather", 4) if i % 2 == 0 else P(&"leather", 2))
	_Px.put(sw, base.x - 8, base.y + 9, P(&"gold", 5))
	_Px.put(sw, base.x - 7, base.y + 9, P(&"gold", 4))
	_Px.put(sw, base.x - 8, base.y + 10, P(&"gold", 3))
	_Px.put(sw, base.x - 7, base.y + 10, P(&"gold", 2))
	return _Px.outline(sw, _Px.ink() if metal != "hot" else P(&"furnace_brick", 1))


## Busto de gólem de hollín (mira a la izquierda), 30×44, luz desde arriba-izquierda (`lit_tl`) o desde la izquierda.
static func golem_bust() -> Image:
	var gw := 30
	var gh := 44
	var occ := func(x: int, y: int) -> int:
		var hx := (x - 8.5) / 6.5
		var hy := (y - 6.5) / 6.0
		if absf(hx) < 1.0 and absf(hy) < 1.0 and absf(hx) + absf(hy) < 1.6:
			return 1
		var ax := (x - 5.0) / 6.0
		var ay := (y - 24.0) / 10.0
		if ax * ax + ay * ay <= 1.0:
			return 3
		var sx := (x - 19.0) / 12.0
		var sy := (y - 17.0) / 10.0
		if sx * sx + sy * sy <= 1.0 or (x >= 8 and x <= 29 and y >= 17):
			return 2
		return 0
	var img := _Px.new_img(gw, gh)
	var stone := _Px.R(&"rock_soot", 1, 7)
	for y in gh:
		for x in gw:
			var part: int = occ.call(x, y)
			if part == 0:
				continue
			var lit := 0.32
			if int(occ.call(x - 1, y - 1)) != part:
				lit = 0.95
			elif int(occ.call(x - 2, y - 2)) != part:
				lit = 0.7
			elif int(occ.call(x + 2, y + 1)) != part:
				lit = 0.1
			lit -= (y / float(gh)) * 0.2
			var by := (y + (3 if (x / 7) % 2 == 0 else 0)) % 8
			if part != 1 and (by == 0 or x % 7 == 0) and lit < 0.9:
				lit -= 0.18
			if part == 3:
				lit += 0.08
			img.set_pixel(x, y, _Px.ramp_pick(stone, lit, x, y, 0.2))
	for e: Vector2i in [Vector2i(4, 6), Vector2i(8, 6)]:
		img.set_pixel(e.x, e.y, P(&"fire", 7))
		img.set_pixel(e.x + 1, e.y, P(&"fire", 6))
		img.set_pixel(e.x, e.y + 1, P(&"fire", 4))
	for x in range(4, 11):
		img.set_pixel(x, 10, P(&"fire", 4) if x % 2 == 0 else P(&"fire", 2))
	for crack: Array in [[[16, 12], [18, 15], [17, 18], [20, 22]], [[24, 20], [23, 25], [25, 29], [24, 33]], [[13, 30], [15, 34], [14, 38]], [[4, 20], [6, 24], [5, 28]]]:
		for i in crack.size() - 1:
			var p0: Array = crack[i]
			var p1: Array = crack[i + 1]
			_Px.line(img, p0[0], p0[1], p1[0], p1[1], P(&"fire", 4))
		var m: Array = crack[1]
		img.set_pixel(m[0], m[1], P(&"fire", 6))
	return _Px.outline(img, _Px.ink())


## Criaturas pequeñas en silueta con luz de borde (para ilustraciones con varios enemigos).
static func critter(kind: String, rim: Color) -> Image:
	var rows: Array
	match kind:
		"slime":
			rows = ["....kkkkkk....", "..kkbbbbbbkk..", ".kbbbbbbbbbbk.", "kbbebbbbbbebbk", "kbbbbbbbbbbbbk",
				"kbbbbkkkkbbbbk", "kbbbbbbbbbbbbk", ".kkkkkkkkkkkk."]
		"bat":
			rows = ["k...............k", "kk.....k.k.....kk", "kbk....kkk....kbk", "kbbk..kbbbk..kbbk",
				"kbbbkkbebebkkbbbk", ".kbbbbbbbbbbbbbk.", "..kbbk.kbk.kbbk..", "...kk...k...kk..."]
		"mite":
			rows = ["....o....", "...oyo...", "...oyo...", "....k....", "..kkkkk..", ".kbbbbbk.", ".kbebebk.",
				".kbbbbbk.", ".kbbbbbk.", "kkbbbbbkk", "k.kbbbk.k", "..k...k.."]
		"bird":
			rows = [".....kkk.....", "....kbbbk....", "...kbbebkoo..", "...kbbbbko...", "..kbbbbbk....",
				".kbbbbbbbk...", "kbbbbbbbbbk..", "kbbbbbbbbbbk.", ".kbbbbbbbbbbk", "..kkbbbbbkkkk", "....k..k....."]
		"golem":
			rows = ["...kkkkk...", "..kbbbbbk..", "..kbebebk..", "..kbbbbbk..", "kkkkbbbkkkk", "kbbbbbbbbbk",
				"kbbbbobbbbk", "kbbbbbbbbbk", "kbkbbbbbkbk", "kbkbbbbbkbk", "kk.kbbbk.kk", "...kk.kk...", "...kk.kk..."]
		_:
			rows = ["kkk", "kbk", "kkk"]
	var pal := {"k": _Px.ink(), "b": P(&"rock_soot", 2), "e": P(&"fire", 6), "o": P(&"fire", 5), "y": P(&"fire", 7)}
	var img := _Px.sprite(rows, pal)
	# Luz de borde superior.
	var out := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y) == pal["b"]:
				if _Px.get_c(img, x, y - 1) == pal["k"]:
					out.set_pixel(x, y, rim)
				elif _Px.get_c(img, x, y - 2) == pal["k"] and (x + y) % 2 == 0:
					out.set_pixel(x, y, P(&"rock_soot", 4))
	return out


## Estallido de impacto: estrella de 8 rayos con rampa de fuego.
static func impact(img: Image, c: Vector2i, size: int = 5) -> void:
	var rays := [[0, -1, size], [0, 1, size - 1], [-1, 0, size], [1, 0, size + 1], [1, -1, size - 2], [-1, 1, size - 2], [1, 1, size - 2], [-1, -1, size - 2]]
	for s: Array in rays:
		for k in int(s[2]):
			var col := P(&"fire", 7) if k < 2 else (P(&"fire", 6) if k < 4 else P(&"fire", 4))
			_Px.put(img, c.x + int(s[0]) * k, c.y + int(s[1]) * k, col)


## Llamita de `h` px de alto con la base en (x, y).
static func flamelet(img: Image, x: int, y: int, h: int) -> void:
	for k in h:
		var w := maxi(0, (h - k) / 2)
		for dx in range(-w, w + 1):
			var t := float(k) / h
			_Px.put(img, x + dx, y - k, P(&"fire", clampi(int(7.0 - t * 4.0 - absi(dx) * 1.5), 1, 7)))
