extends RefCounted
## Kit de interfaz pixel v0.4: piezas 9-slice nativas (se dibujan a ×2) y su composición por TESELADO
## (nunca estirado: los bordes repiten su patrón, las esquinas quedan intactas).

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const K := Color("1a0f12")


static func c(h: String) -> Color:
	return Color(h)


## Compone una pieza 9-slice a (w, h) teselando bordes y centro.
static func nine(src: Image, m: int, w: int, h: int) -> Image:
	var sw := src.get_width()
	var sh := src.get_height()
	var out := PX.new_img(w, h)
	var cw := sw - 2 * m
	var chh := sh - 2 * m
	for y in h:
		for x in w:
			var sx: int
			var sy: int
			if x < m:
				sx = x
			elif x >= w - m:
				sx = sw - (w - x)
			else:
				sx = m + (x - m) % cw
			if y < m:
				sy = y
			elif y >= h - m:
				sy = sh - (h - y)
			else:
				sy = m + (y - m) % chh
			out.set_pixel(x, y, src.get_pixel(sx, sy))
	return out


## PIEDRA (paneles grandes: mapa, Antesala). 24×24, margen 8. Sillares biselados, centro oscuro liso.
static func stone() -> Image:
	var s := 24
	var img := PX.new_img(s, s)
	var st := [c("140c10"), c("221619"), c("352428"), c("4a3438"), c("6a4e4e"), c("8e7068")]
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var col: Color = st[1]
			if e == 0:
				col = K
			elif e < 7:
				# Sillares de 8×6 con bisel propio.
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
					col = st[3] if PX.hash2(x, y, 3) > 0.12 else st[2]
			elif e == 7:
				col = K
			else:
				col = st[1] if PX.hash2(x, y, 9) > 0.06 else st[0]
			img.set_pixel(x, y, col)
	return img


## HIERRO (barras de estado, botones grandes, tooltip). 16×16, margen 5. Chapa con remaches.
static func iron(base: Color = Color("3a3440")) -> Image:
	var s := 16
	var img := PX.new_img(s, s)
	for y in s:
		for x in s:
			var e := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var tl := (y == e and x < s - 1 - e) or (x == e and y < s - 1 - e)
			var col := base
			if e == 0:
				col = K
			elif e == 1:
				col = base.lightened(0.45) if tl else base.darkened(0.45)
			elif e == 2 or e == 3:
				col = base.lightened(0.12)
			elif e == 4:
				col = base.darkened(0.55) if tl else base.lightened(0.2)
			else:
				col = base.darkened(0.35)
			img.set_pixel(x, y, col)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(s - 4, 2), Vector2i(2, s - 4), Vector2i(s - 4, s - 4)]:
		img.set_pixel(p.x, p.y, base.lightened(0.7))
		img.set_pixel(p.x + 1, p.y, base.lightened(0.3))
		img.set_pixel(p.x, p.y + 1, base.lightened(0.3))
		img.set_pixel(p.x + 1, p.y + 1, base.darkened(0.6))
	return img


## PERGAMINO (texto largo: eventos, resumen, descripciones). 16×16, margen 5. Bordes tostados.
static func parchment() -> Image:
	var s := 16
	var img := PX.new_img(s, s)
	var pr := [c("5a3a22"), c("8a6440"), c("c8a47c"), c("e4c8a0"), c("f2e0be")]
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
			elif PX.hash2(x, y, 5) > 0.95:
				col = pr[2]
			img.set_pixel(x, y, col)
	return img


## BOTÓN de forja (20×14, margen 6). Estados: normal, hover (incandescente), pressed (hundido), disabled (frío).
static func button(state: String) -> Image:
	var w := 20
	var h := 14
	var img := PX.new_img(w, h)
	var face := c("6a2e1e")
	var hi := c("b05a32")
	var lo := c("3a160e")
	var rim := c("2a1410")
	match state:
		"hover":
			face = c("8e3a1e")
			hi = c("ffb43a")
			lo = c("5a1e10")
			rim = c("ff6a1a")
		"pressed":
			face = c("5a2416")
			hi = c("3a160e")
			lo = c("8e3a1e")
		"disabled":
			face = c("2e2a30")
			hi = c("4a4650")
			lo = c("1e1a20")
			rim = c("1a181e")
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
				col = lo.darkened(0.3)          # canto inferior (grosor del botón)
			elif e == 1:
				col = rim if state == "hover" else (hi if (y == 1 + off or x == 1) else lo)
			elif y == 2 + off:
				col = hi
			elif y >= h - 4 + off:
				col = lo
			img.set_pixel(x, y, col)
	if state == "hover":
		for x in range(3, w - 3, 2):
			img.set_pixel(x, 2, c("ffe08a"))
	return img


## PESTAÑA (16×12, margen 5): activa (unida al panel, cálida) / inactiva (hundida, fría).
static func tab(active: bool) -> Image:
	var w := 16
	var h := 12
	var img := PX.new_img(w, h)
	var face := c("4a2a22") if active else c("261a1e")
	for y in h:
		for x in w:
			if y == 0 and (x == 0 or x == w - 1):
				continue
			var col := face
			if x == 0 or x == w - 1 or y == 0:
				col = K
			elif y == 1:
				col = c("ffb43a") if active else c("3d2b2e")
			elif x == 1:
				col = face.lightened(0.2)
			elif x == w - 2:
				col = face.darkened(0.3)
			elif y == h - 1:
				col = face if active else K
			img.set_pixel(x, y, col)
	return img


## Barra (vida / bloqueo / calor). Marco de hierro + relleno con brillo superior y tramado en el corte.
static func bar(w: int, frac: float, fill: Array, frame: Color = Color("2a2430")) -> Image:
	var h := 7
	var img := PX.new_img(w, h)
	var cut := int(round((w - 4) * frac))
	for y in h:
		for x in w:
			if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
				continue
			var col := frame
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				col = K
			elif x == 1 or y == 1 or x == w - 2 or y == h - 2:
				col = frame.lightened(0.15) if y == 1 else frame
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
					col = c("140c10")
			img.set_pixel(x, y, col)
	return img


## Ascua (moneda del juego), 9×9: no es una moneda de oro, es una brasa facetada que late.
static func ember_icon() -> Image:
	return PX.sprite([
		"...kkk...",
		"..kyyok..",
		".kywyook.",
		"kywyyoork",
		"kyyyoorrk",
		"kyoooorRk",
		".korrrRk.",
		"..kRRRk..",
		"...kkk...",
	], {"k": K, "w": c("fff4c8"), "y": c("ffd36a"), "o": c("ff8a2a"), "r": c("d2381a"), "R": c("7a1a16")})


static func heart_icon() -> Image:
	return PX.sprite([
		".kk.kk.",
		"kwrkrrk",
		"krrrrRk",
		"krrrrRk",
		".krrRk.",
		"..kRk..",
		"...k...",
	], {"k": K, "w": c("ffc0a0"), "r": c("e0442a"), "R": c("8a1a16")})


static func shield_icon() -> Image:
	return PX.sprite([
		"kkkkkkk",
		"kwccccbk",
		"kcccccbk",
		"kcccccbk",
		".kccbbk.",
		"..kcbk..",
		"...kk...",
	], {"k": K, "w": c("e8f4ff"), "c": c("8ab4d0"), "b": c("4a6a8a")})
