extends RefCounted
## Ilustraciones del mazo inicial y del Grimorio Base (primera tanda, 12 cartas).
## Cada función devuelve una Image 68×46 en paleta. Gramática: FONDO + LUZ + SUJETO + FX + ENCUADRE (ver card_illus.gd).
## Composición: tabla de `docs/reviews/v04/cartas_ui/propuesta.md` §4.6.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const _Bg := preload("res://scripts/art/cards/illus/backdrops.gd")
const _Sj := preload("res://scripts/art/cards/illus/subjects.gd")
const W := 68
const H := 46

const IDS: Array[String] = ["strike", "defend", "kindling", "ember_slash", "heavy_hammer", "sparks", "cleave",
	"iron_wall", "quench", "bellows", "stoke", "coal"]


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


static func build(id: String) -> Image:
	match id:
		"strike": return strike()
		"defend": return defend()
		"kindling": return kindling()
		"ember_slash": return ember_slash()
		"heavy_hammer": return heavy_hammer()
		"sparks": return sparks()
		"cleave": return cleave()
		"iron_wall": return iron_wall()
		"quench": return quench()
		"bellows": return bellows()
		"stoke": return stoke()
		"coal": return coal()
	return null


# ---------------------------------------------------------------------------------------------------------------
# GOLPE · PC · la hoja de hierro entra en el hombro de un Gólem de Hollín. Luz: el chispazo del impacto.
static func strike() -> Image:
	var img := _Px.new_img()
	var hit := Vector2i(48, 8)
	_Bg.tower_wall(img, Vector2(hit), 46.0, 999.0, 0.1)
	_Bg.floor_slabs(img, 41, 46.0)
	_Px.blit(img, _Sj.golem_bust(), 45, 4)
	# Estela fina en media luna que acaba en la hoja.
	var pivot := Vector2(13.5, 41.5)
	var a_end := -PI * 0.25
	var a_start := -PI * 0.86
	var R := 52.0
	for y in H:
		for x in W:
			var v := Vector2(x + 0.5, y + 0.5) - pivot
			var r := v.length()
			var ang := atan2(v.y, v.x)
			if ang < a_start or ang > a_end:
				continue
			var p := (ang - a_start) / (a_end - a_start)
			var thick := 1.0 + p * p * 7.0
			if r > R - 2.0 or r < R - 2.0 - thick:
				continue
			var depth := (R - 2.0 - r) / thick
			if p < 0.35 and _Px.bayer(x, y) > p * 2.5:
				continue
			if depth > 0.7 and (x + y) % 2 == 0:
				continue
			img.set_pixel(x, y, P(&"ember_ui", 6) if depth < 0.4 else (P(&"linen", 5) if p > 0.6 else P(&"linen", 4)))
	_Px.blit(img, _Sj.sword45(W, H, Vector2i(14, 38), 34), 0, 0)
	for i in range(28, 32):
		_Px.put(img, 14 + i - 1, 38 - i, P(&"ember_ui", 6))
	_Sj.impact(img, hit, 5)
	for sp: Array in [[57, 3, 1, -1], [60, 9, 1, 0], [55, 15, 1, 1], [42, 4, -1, -1], [62, 4, 1, -1], [52, 17, 0, 1]]:
		_Px.put(img, sp[0], sp[1], P(&"fire", 6))
		_Px.put(img, int(sp[0]) - int(sp[2]), int(sp[1]) - int(sp[3]), P(&"fire", 4))
	for ch: Vector2i in [Vector2i(44, 14), Vector2i(41, 18), Vector2i(46, 21)]:
		_Px.put(img, ch.x, ch.y, P(&"rock_soot", 6))
		_Px.put(img, ch.x + 1, ch.y, _Px.ink())
	return img


# ---------------------------------------------------------------------------------------------------------------
# DEFENSA · PM · escudo de cometa que para una garra; el escudo refleja la Forja (cálida, izq.) y la Torre (fría, der.).
static func defend() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(-6, 24), 50.0, 34.0, 0.1, 7)
	_Bg.floor_slabs(img, 40, 20.0)
	# Escudo de cometa (heater): x 10..44, y 3..44.
	var cx := 27.0
	var sh := _Px.new_img()
	for y in range(3, 45):
		for x in range(6, 50):
			var t := float(y - 3) / 41.0
			var half := 16.0 if t < 0.45 else 16.0 * sqrt(maxf(0.0, 1.0 - pow((t - 0.45) / 0.55, 1.6)))
			var top_curve := 1.5 * pow(absf(x - cx) / 16.0, 2.0)
			if absf(x + 0.5 - cx) > half or y < 3 + top_curve:
				continue
			var nx := (x + 0.5 - cx) / maxf(1.0, half)
			var col: Color
			var rimd := half - absf(x + 0.5 - cx)
			if rimd < 2.0 or y < 5 + top_curve:
				# Canto de latón.
				col = P(&"brass", 5) if nx < -0.2 or y < 5 + top_curve else (P(&"brass", 3) if nx < 0.5 else P(&"brass", 2))
			elif nx < -0.35:
				col = _Px.ramp_pick(_Px.R(&"steel", 3, 6), 0.9 - (nx + 1.0) * 0.6 + (1.0 - t) * 0.1, x, y)
			else:
				col = _Px.ramp_pick(_Px.R(&"steel", 2, 6, true), 0.25 + (nx + 0.35) * 0.55 - t * 0.15, x, y)
			sh.set_pixel(x, y, col)
	# Nervio central y umbo.
	for y in range(6, 40):
		_Px.put(sh, int(cx), y, P(&"steel", 6, true) if y < 30 else P(&"steel", 5, true))
		_Px.put(sh, int(cx) + 1, y, P(&"steel", 2, true))
	_Px.disc(sh, cx + 0.5, 18.5, 4.0, P(&"brass", 3))
	_Px.disc(sh, cx - 0.5, 17.5, 2.5, P(&"brass", 4))
	_Px.put(sh, int(cx) - 1, 16, P(&"brass", 5))
	# Arañazos de la garra (claros) en la cara fría.
	for s: Array in [[35, 14, 43, 20], [34, 19, 42, 25], [35, 24, 42, 29]]:
		_Px.line(sh, s[0], s[1], s[2], s[3], P(&"steel", 6, true))
		_Px.line(sh, int(s[0]) + 1, int(s[1]) + 1, int(s[2]), int(s[3]), P(&"steel", 2, true))
	_Px.blit(img, _Px.outline(sh, _Px.ink()), 0, 0)
	# Garra entrando por arriba-derecha: antebrazo escamoso que se estrecha hasta la muñeca y tres uñas en gancho.
	var cl := _Px.new_img()
	var arm := _Px.R(&"rock_soot", 1, 6, true)
	var a0 := Vector2(70.0, -2.0)
	var a1 := Vector2(52.0, 15.0)
	for y in range(0, 26):
		for x in range(44, W):
			var ab := a1 - a0
			var t := clampf((Vector2(x + 0.5, y + 0.5) - a0).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var cxy := a0 + ab * t
			var d := Vector2(x + 0.5, y + 0.5).distance_to(cxy)
			var half := 7.0 - t * 3.0
			if d > half:
				continue
			var nrm := Vector2(-ab.y, ab.x).normalized()
			var side := (Vector2(x + 0.5, y + 0.5) - cxy).dot(nrm)
			var lit := 0.3 + (0.5 if side > half - 2.5 else 0.0) - (0.15 if side < -half + 2.0 else 0.0)
			if (int(x / 3) + int(y / 3)) % 2 == 0:
				lit += 0.08
			cl.set_pixel(x, y, _Px.ramp_pick(arm, lit, x, y, 0.2))
	for t2: Array in [[52, 10], [50, 14], [51, 18]]:
		var x0: int = t2[0]
		var y0: int = t2[1]
		var pts := [[0, 0], [-2, 0], [-4, 1], [-6, 2], [-7, 4], [-7, 5]]
		for i in pts.size():
			var pp: Array = pts[i]
			var px := x0 + int(pp[0])
			var py := y0 + int(pp[1])
			_Px.put(cl, px, py, P(&"ash", 9) if i < 3 else P(&"ash", 7))
			if i < 4:
				_Px.put(cl, px, py + 1, P(&"ash", 4))
	_Px.blit(img, _Px.outline(cl, _Px.ink()), 0, 0)
	for sp: Vector2i in [Vector2i(44, 15), Vector2i(43, 20), Vector2i(45, 24), Vector2i(41, 17), Vector2i(47, 11)]:
		_Px.put(img, sp.x, sp.y, P(&"fire", 7))
		_Px.put(img, sp.x - 1, sp.y + 1, P(&"fire", 5))
	return img


# ---------------------------------------------------------------------------------------------------------------
# LEÑA · PM bajo · un haz de leña atada junto al hogar; la punta más cercana al fuego empieza a prender.
static func kindling() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(80, 30), 70.0, 999.0, 0.06, 7)
	_Bg.floor_slabs(img, 36, 60.0)
	# Resplandor del hogar fuera de cuadro (derecha): veladura en el suelo y el muro.
	for y in H:
		for x in range(40, W):
			var d := Vector2(x - 72.0, (y - 38.0) * 1.4).length()
			if d < 22.0:
				_Px.veil(img, x, y, 1, 1.0 if d < 12.0 else 0.5)
	# Troncos: 3 abajo + 2 arriba, cortes a la derecha (dan al fuego).
	var logs := [[6, 30, 50, 7], [9, 23, 46, 7], [4, 37, 52, 7], [12, 16, 40, 7]]
	logs = [[4, 33, 50, 7], [8, 26, 47, 7], [14, 19, 40, 7]]
	var lay := _Px.new_img()
	for i in logs.size():
		var lg: Array = logs[i]
		var x0: int = lg[0]
		var y0: int = lg[1]
		var L: int = lg[2]
		var h: int = lg[3]
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + L):
				var ty := float(y - y0) / (h - 1)
				var bark := 0.55 - absf(ty - 0.3) * 0.7 + float(x - x0) / L * 0.25
				if (x * 3 + y * 7 + i * 5) % 11 == 0:
					bark -= 0.25
				if y == y0 + h - 1:
					bark = 0.05
				lay.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"wood", 2, 8), bark, x, y, 0.25))
		# Corte con anillos (elipse 5×7) a la derecha.
		var ex := x0 + L
		for y in range(y0, y0 + h):
			for x in range(ex - 2, ex + 3):
				var dx := (x - ex + 0.0) / 2.6
				var dy := (y - (y0 + h * 0.5 - 0.5)) / 3.5
				var rr := sqrt(dx * dx + dy * dy)
				if rr <= 1.0:
					var col := P(&"wood", 9)
					if rr < 0.35:
						col = P(&"wood", 7)
					elif rr < 0.7:
						col = P(&"wood", 10)
					if rr > 0.85:
						col = P(&"wood", 6)
					lay.set_pixel(x, y, col)
	# Atadura de cordel.
	for y in range(18, 41):
		for x in [26, 27]:
			if lay.get_pixel(x, y).a > 0.0:
				lay.set_pixel(x, y, P(&"burlap", 4) if (y + x) % 2 == 0 else P(&"burlap", 3))
	_Px.blit(img, _Px.outline(lay, _Px.ink()), 0, 0)
	# Lengua de fuego prendiendo en el corte del tronco de arriba y su humo.
	_Sj.flamelet(img, 56, 21, 7)
	_Sj.flamelet(img, 58, 22, 4)
	for y in range(4, 15):
		var sx := 57 + int(sin(y * 0.6) * 2.0)
		_Px.veil(img, sx, y, 2, 0.5)
		_Px.veil(img, sx + 1, y, 1, 0.5)
	_Bg.motes(img, Rect2i(46, 4, 18, 14), 5, 9)
	return img


# ---------------------------------------------------------------------------------------------------------------
# TAJO ÍGNEO · PC · la hoja al rojo barre la fragua y deja una media luna de fuego. Luz: la propia llama.
static func ember_slash() -> Image:
	var img := _Px.new_img()
	_Bg.forge_dark(img, Vector2(40, 30), 40.0)
	_Bg.pillar(img, 3, 6)
	_Bg.pillar(img, 61, 6)
	var fire := _Px.R(&"fire", 1, 7)
	var hilt := Vector2(21.5, 42.5)
	var RA := 36.0
	var RB := 32.5
	var off := Vector2(-1, 1).normalized() * 8.0
	for y in H:
		for x in W:
			var v := Vector2(x + 0.5, y + 0.5) - hilt
			var ang := atan2(v.y, v.x)
			if ang > -PI * 0.12:
				continue
			var lick := (_Px.vnoise(ang * 26.0, 0.0, 5) - 0.35) * 3.0
			var rA := v.length()
			if rA > RA + maxf(0.0, lick) or (v - off).length() < RB:
				continue
			var depth := RA - rA
			var front := clampf((ang + PI) / (PI * 0.75), 0.0, 1.0)
			var reach := 2.0 + front * 8.0
			if depth > reach and _Px.bayer(x, y) > 0.25:
				continue
			if front < 0.25 and _Px.bayer(x, y) > front * 4.0:
				continue
			var heat := clampf(1.0 - depth / reach, 0.0, 1.0) * (0.35 + front * 0.65) + 0.08
			if rA > RA:
				heat = 0.3 + front * 0.2
			img.set_pixel(x, y, _Px.ramp_pick(fire, heat, x, y, 0.3))
	_Px.blit(img, _Sj.sword45(W, H, Vector2i(int(hilt.x) + 1, int(hilt.y) - 1), 25, "hot"), 0, 0)
	for f: Array in [[14, 5], [22, 3], [50, 4]]:
		_Sj.flamelet(img, f[0], H - 1, f[1])
	_Bg.motes(img, Rect2i(8, 2, 52, 30), 14, 41)
	return img


# ---------------------------------------------------------------------------------------------------------------
# MARTILLAZO · PC · el martillo cae en vertical; el suelo se agrieta y salta la onda de choque (Vulnerable).
static func heavy_hammer() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(34, 36), 34.0, 999.0, 0.04, 7)
	_Bg.floor_slabs(img, 33, 34.0)
	var hit := Vector2i(34, 33)
	# Grietas radiales en el suelo.
	for cr: Array in [[-1, 0, 16], [1, 0, 18], [-1, 1, 9], [1, 1, 10], [0, 1, 8]]:
		var x := hit.x
		var y := hit.y + 1
		for k in int(cr[2]):
			x += int(cr[0]) if k % 2 == 0 or int(cr[1]) == 0 else 0
			y += int(cr[1]) if k % 3 == 0 else 0
			x += 1 if int(cr[0]) == 0 and k % 4 == 1 else 0
			_Px.put(img, x, y, _Px.ink())
			_Px.put(img, x, y - 1, P(&"stone", 7))
	# Onda de choque: dos arcos claros tramados a ras de suelo.
	for side: int in [-1, 1]:
		for i in 14:
			var ax := hit.x + side * (8 + i)
			var ay := hit.y - 1 - int(sqrt(maxf(0.0, 49.0 - pow(i - 7.0, 2.0))) * 0.6)
			if (i + side) % 3 != 0:
				_Px.put(img, ax, ay, P(&"ash", 9))
				_Px.put(img, ax, ay + 1, P(&"ash", 7))
	# Cascotes volando.
	for d: Array in [[20, 24], [17, 28], [50, 22], [54, 27], [44, 18], [26, 19]]:
		_Px.put(img, d[0], d[1], P(&"stone", 8))
		_Px.put(img, int(d[0]) + 1, d[1], P(&"stone", 4))
		_Px.put(img, d[0], int(d[1]) + 1, _Px.ink())
	# Mango en diagonal hacia arriba-derecha y cabeza de mazo apoyada de cara sobre el suelo.
	var hm := _Px.new_img()
	for i in 30:
		var x := 40 + i
		var y := 16 - int(i * 0.62)
		for d in 3:
			_Px.put(hm, x, y + d, P(&"wood", 8) if d == 0 else (P(&"wood", 6) if d == 1 else P(&"wood", 3)))
	var head := Rect2i(24, 12, 18, 21)
	for y in range(head.position.y, head.end.y):
		for x in range(head.position.x, head.end.x):
			var lx := x - head.position.x
			var ly := y - head.position.y
			if (lx < 1 or lx > head.size.x - 2) and (ly < 1 or ly > head.size.y - 2):
				continue
			var lit := 0.62 - float(lx) / head.size.x * 0.5
			if ly < 3:
				lit = 0.92 - float(lx) / head.size.x * 0.3
			if ly > head.size.y - 4:
				lit = 0.3
			if lx < 2:
				lit += 0.15
			if ly == 7:
				lit += 0.1
			elif ly == 8:
				lit -= 0.25
			hm.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"iron", 2, 9), lit, x, y, 0.2))
	_Px.hline(hm, head.position.x + 1, head.end.x - 2, head.end.y - 1, P(&"iron", 10))
	_Px.blit(img, _Px.outline(hm, _Px.ink()), 0, 0)
	for k in 3:
		var r := 14.0 + k * 3.0
		for i in 14:
			var a := -PI * 0.95 + i * 0.07
			var p := Vector2(33, 30) + Vector2(cos(a), sin(a)) * r
			if i % 4 != 3:
				_Px.put(img, int(p.x), int(p.y), P(&"ash", 8 - k))
	for side: int in [-1, 1]:
		for i in 9:
			var px := 33 + side * (12 + i)
			var py := 31 - int(sin(i * 0.4) * 3.0)
			_Px.put(img, px, py, P(&"ash", 7))
			_Px.put(img, px, py + 1, P(&"ash", 5))
			if i % 2 == 0:
				_Px.put(img, px, py - 1, P(&"ash", 8))
	# Fogonazo bajo la cara.
	_Px.hline(img, 20, 46, 33, P(&"fire", 7))
	_Px.hline(img, 24, 42, 34, P(&"fire", 5))
	return img


# ---------------------------------------------------------------------------------------------------------------
# LLUVIA DE CHISPAS · PG · tres criaturas pequeñas bajo una lluvia de chispas que cae en diagonal.
static func sparks() -> Image:
	var img := _Px.new_img()
	var room := _Px.R(&"stone", 1, 5, true)
	for y in H:
		for x in W:
			var l := 0.12 + (1.0 - y / 46.0) * 0.08 + (_Px.fbm(x / 9.0, y / 6.0, 3) - 0.5) * 0.12
			img.set_pixel(x, y, _Px.ramp_pick(room, l, x, y))
	_Bg.floor_slabs(img, 37, 34.0, true)
	# Charcos de luz donde caen las chispas.
	for c: Vector2 in [Vector2(14, 38), Vector2(34, 39), Vector2(54, 38)]:
		for y in range(35, H):
			for x in range(int(c.x) - 10, int(c.x) + 11):
				var d := Vector2((x - c.x) / 2.2, y - c.y).length()
				if d < 4.5:
					_Px.veil(img, x, y, 2 if d < 2.5 else 1, 1.0 if d < 2.5 else 0.5)
	var rim := P(&"fire", 5)
	_Px.blit(img, _Px.outline(_Sj.critter("slime", rim), _Px.ink()), 6, 30)
	_Px.blit(img, _Px.outline(_Sj.critter("mite", rim), _Px.ink()), 29, 26)
	_Px.blit(img, _Px.outline(_Sj.critter("bat", rim), _Px.ink()), 46, 16)
	# Chispas: cabeza blanca, estela hacia arriba-izquierda.
	var heads := [[12, 28], [20, 14], [27, 6], [35, 27], [40, 16], [48, 9], [57, 19], [62, 31], [16, 21], [31, 19], [53, 3], [8, 9], [44, 30], [24, 33]]
	for i in heads.size():
		var hx: int = heads[i][0]
		var hy: int = heads[i][1]
		var L := 3 + int(_Px.hash2(i, 2, 7) * 4.0)
		for k in L:
			var col := P(&"fire", 7) if k == 0 else (P(&"fire", 6) if k == 1 else (P(&"fire", 5) if k < 3 else P(&"fire", 3)))
			_Px.put(img, hx - k, hy - k * 2, col)
			if k == 0:
				_Px.put(img, hx + 1, hy, P(&"fire", 5))
	# Chispas que ya han tocado a las criaturas.
	_Sj.impact(img, Vector2i(11, 30), 3)
	_Sj.impact(img, Vector2i(56, 17), 3)
	return img


# ---------------------------------------------------------------------------------------------------------------
# BARRIDO · PC · un hacha barre en horizontal y corta a tres siluetas a la vez.
static func cleave() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(64, 14), 46.0, 999.0, 0.05, 7)
	_Bg.floor_slabs(img, 39, 60.0)
	# Tres enemigos (urraca, gólem chico, limo) a contraluz, con luz de borde fría de la Torre.
	var rim := P(&"rock_soot", 5, true)
	_Px.blit(img, _Px.outline(_Sj.critter("bird", rim), _Px.ink()), 5, 28)
	_Px.blit(img, _Px.outline(_Sj.critter("golem", rim), _Px.ink()), 24, 26)
	_Px.blit(img, _Px.outline(_Sj.critter("slime", rim), _Px.ink()), 38, 31)
	# Estela horizontal ancha (de izquierda a derecha), afilada en la cola.
	for y in range(14, 40):
		for x in W:
			var p := float(x) / W
			var cy := 31.0 - p * 7.0
			var half := 1.0 + p * p * 7.0
			var dy := absf(y - cy)
			if dy > half:
				continue
			if p < 0.3 and _Px.bayer(x, y) > p * 3.3:
				continue
			var t := dy / half
			var col := P(&"ember_ui", 6) if t < 0.35 else (P(&"linen", 5) if t < 0.7 else P(&"linen", 3))
			if t >= 0.7 and (x + y) % 2 == 0:
				continue
			img.set_pixel(x, y, col)
	# Cortes: destellos en cada silueta.
	for c: Vector2i in [Vector2i(11, 31), Vector2i(29, 29), Vector2i(45, 33)]:
		_Px.put(img, c.x, c.y - 3, P(&"fire", 7))
		_Px.put(img, c.x + 1, c.y - 4, P(&"fire", 5))
		_Px.put(img, c.x - 1, c.y + 3, P(&"fire", 5))
	# Hacha barbuda al final de la estela (cabeza de hierro, mango que sale por la izquierda... de la estela).
	var ax := _Px.new_img()
	var axe := [
		"......kkk...",
		"....kkHHhk..",
		"..kkHHhhhhk.",
		".kHHhhhhhhk.",
		"kHhhhhhhmmk.",
		"kHhhhhhmmmkk",
		"kHhhhhmmmmwk",
		"kHhhhhmmmmwk",
		"kHhhhhhmmmkk",
		".kHhhhhhmmk.",
		"..kkhhhhhmk.",
		"....kkhhmk..",
		"......kkk...",
	]
	var apal := {"k": _Px.ink(), "H": P(&"iron", 9), "h": P(&"iron", 6), "m": P(&"iron", 4), "w": P(&"wood", 7)}
	_Px.blit(ax, _Px.sprite(axe, apal), 55, 12)
	for x in range(44, 56):
		_Px.put(ax, x, 18 + (55 - x) / 4, P(&"wood", 8))
		_Px.put(ax, x, 19 + (55 - x) / 4, P(&"wood", 5))
	_Px.blit(img, _Px.outline(ax, _Px.ink()), 0, 0)
	return img


# ---------------------------------------------------------------------------------------------------------------
# MURO DE HIERRO · PM · chapas remachadas que encajan formando una muralla; la última cae en su sitio.
static func iron_wall() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(10, 0), 50.0, 30.0, 0.1, 7)
	var plates := _Px.new_img()
	var iron := _Px.R(&"iron", 3, 9)
	var rows := [[24, [0, 22, 44]], [35, [-11, 11, 33, 55]]]
	var specs: Array = []
	for r: Array in rows:
		for px0: int in r[1]:
			specs.append([px0, int(r[0]), 22, 11])
	# La chapa que cae: fila superior, centro, desplazada 6 px hacia arriba.
	specs.append([22, 7, 22, 11])
	specs.append([0, 13, 22, 11])
	specs.append([44, 13, 22, 11])
	for i in specs.size():
		var s: Array = specs[i]
		var x0: int = s[0]
		var y0: int = s[1]
		var w: int = s[2]
		var h: int = s[3]
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + w):
				if x < 0 or x >= W:
					continue
				var lx := x - x0
				var ly := y - y0
				var lit := 0.55 - float(ly) / h * 0.3 + (0.1 if i % 2 == 0 else 0.0)
				if ly == 0 or lx == 0:
					lit = 0.95
				elif ly == h - 1 or lx == w - 1:
					lit = 0.08
				elif ly == 1 or lx == 1:
					lit = 0.75
				plates.set_pixel(x, y, _Px.ramp_pick(iron, lit, x, y, 0.2))
		for rp: Vector2i in [Vector2i(x0 + 2, y0 + 2), Vector2i(x0 + w - 4, y0 + 2), Vector2i(x0 + 2, y0 + h - 4), Vector2i(x0 + w - 4, y0 + h - 4)]:
			_Px.put(plates, rp.x, rp.y, P(&"iron", 10))
			_Px.put(plates, rp.x + 1, rp.y + 1, P(&"iron", 2))
	_Px.blit(img, _Px.outline(plates, _Px.ink()), 0, 0)
	# Hueco en sombra bajo la chapa que cae y líneas de movimiento sobre ella.
	_Px.hline(img, 23, 42, 19, _Px.ink())
	for x: int in [25, 31, 37]:
		for y in range(1, 6):
			if y != 3:
				_Px.put(img, x, y, P(&"ash", 8))
	# Chispas en las juntas al encajar.
	for sp: Vector2i in [Vector2i(22, 18), Vector2i(44, 18), Vector2i(20, 15), Vector2i(46, 15)]:
		_Px.put(img, sp.x, sp.y, P(&"fire", 7))
		_Px.put(img, sp.x + signi(sp.x - 33), sp.y - 1, P(&"fire", 5))
	return img


# ---------------------------------------------------------------------------------------------------------------
# ENFRIAR · B · una hoja al rojo se hunde en el cubo de agua y estalla una nube de vapor.
static func quench() -> Image:
	var img := _Px.new_img()
	_Bg.forge_dark(img, Vector2(30, 30), 34.0, 8)
	_Bg.floor_slabs(img, 42, 30.0)
	# Cubo de duelas con aros de hierro: x 10..44, y 26..44.
	var bk := _Px.new_img()
	for y in range(26, 45):
		var inset := int((y - 26) * 0.15)
		for x in range(10 + inset, 45 - inset):
			var stave := (x - 10) / 5
			var lit := 0.6 - float(x - 10) / 34.0 * 0.5 + (0.08 if stave % 2 == 0 else 0.0)
			var col := _Px.ramp_pick(_Px.R(&"wood", 3, 8), lit, x, y, 0.2)
			if (x - 10) % 5 == 0:
				col = P(&"wood", 2)
			if y == 30 or y == 31 or y == 40 or y == 41:
				col = P(&"iron", 6) if y % 10 == 0 else P(&"iron", 3)
			bk.set_pixel(x, y, col)
	# Agua en la boca (elipse), ondas.
	for y in range(23, 29):
		for x in range(10, 45):
			var dx := (x + 0.5 - 27.5) / 17.5
			var dy := (y + 0.5 - 26.0) / 3.0
			if dx * dx + dy * dy <= 1.0:
				var col2 := P(&"wool_blue", 2)
				if dx * dx + dy * dy > 0.7:
					col2 = P(&"wood", 7) if dy < 0.0 else P(&"wood", 4)
				elif (x + int(dy * 4.0)) % 6 == 0:
					col2 = P(&"wool_blue", 4)
				bk.set_pixel(x, y, col2)
	_Px.blit(img, _Px.outline(bk, _Px.ink()), 0, 0)
	# Hoja al rojo de 3 px entrando en diagonal desde arriba-derecha; la parte sumergida ya se ha enfriado.
	var bl := _Px.new_img()
	for i in 24:
		var x := 30 + i
		var y := 28 - i
		var under := y >= 25
		var heat := clampi(5 - i / 6, 2, 5)
		_Px.put(bl, x - 1, y, P(&"steel", 4, true) if under else P(&"hot", heat))
		_Px.put(bl, x, y, P(&"steel", 3, true) if under else P(&"hot", maxi(2, heat - 1)))
		_Px.put(bl, x, y + 1, P(&"steel", 2, true) if under else P(&"hot", maxi(1, heat - 2)))
	for j in range(-3, 4):
		_Px.put(bl, 54 + j, 3 + j, P(&"gold", 4))
		_Px.put(bl, 55 + j, 3 + j, P(&"gold", 2))
	for i in range(1, 6):
		_Px.put(bl, 55 + i, 3 - i, P(&"leather", 4) if i % 2 == 0 else P(&"leather", 2))
		_Px.put(bl, 56 + i, 3 - i, P(&"leather", 3))
	_Px.blit(img, _Px.outline(bl, _Px.ink()), 0, 0)
	# Vapor: bocanadas redondas con luz desde arriba (3 tonos) y borde tramado; salen del punto de entrada.
	for pf: Array in [[10, 5, 6.0], [36, 5, 7.0], [21, 9, 9.0], [44, 14, 5.0], [31, 17, 7.5]]:
		var c := Vector2(pf[0], pf[1])
		var r: float = pf[2]
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				var v := Vector2(x + 0.5, y + 0.5) - c
				var d := v.length() / r
				if d > 1.0 or not _Px.inb(img, x, y):
					continue
				var lit := 0.6 - (v.y / r) * 0.45 - (v.x / r) * 0.12
				var col := P(&"linen", 5) if lit > 0.85 else (P(&"linen", 4) if lit > 0.5 else (P(&"linen", 3) if lit > 0.25 else P(&"linen", 2)))
				if d > 0.85 and (x + y) % 2 == 0:
					continue
				img.set_pixel(x, y, col)
	# Burbujas.
	for b: Vector2i in [Vector2i(30, 24), Vector2i(36, 25), Vector2i(26, 25)]:
		_Px.put(img, b.x, b.y, P(&"wool_blue", 5))
	return img


# ---------------------------------------------------------------------------------------------------------------
# FUELLE · B · un fuelle de cuero insufla aire y la llama del hogar se tumba y crece.
static func bellows() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(56, 30), 40.0, 999.0, 0.04, 7)
	_Bg.floor_slabs(img, 41, 54.0)
	# Hogar (derecha): base de piedra y llama grande que se tumba a la derecha.
	for y in range(36, 42):
		for x in range(40, 66):
			_Px.put(img, x, y, P(&"stone", 6) if y == 36 else (P(&"stone", 3) if (x + y) % 7 else _Px.ink()))
	for y in range(6, 36):
		for x in range(38, W):
			var t := float(36 - y) / 30.0
			var lean := t * t * 10.0
			var cx := 52.0 + lean
			var half := 11.0 * (1.0 - t) + 1.0 + sin(y * 0.7 + x * 0.2) * 1.2
			var dx := absf(x - cx)
			if dx > half:
				continue
			var heat := (1.0 - dx / half) * 0.8 + (1.0 - t) * 0.3
			img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"fire", 2, 7), heat, x, y, 0.3))
	# Fuelle: dos tablas de madera y el cuero plegado entre ellas; boquilla de latón hacia la derecha.
	var fb := _Px.new_img()
	for y in range(14, 34):
		for x in range(4, 30):
			var t := float(x - 4) / 26.0
			var half := 9.0 * (1.0 - t * 0.55)
			var cy := 24.0
			if absf(y - cy) > half:
				continue
			var top := y < cy - half + 3
			var bot := y > cy + half - 3
			var col: Color
			if top or bot:
				col = _Px.ramp_pick(_Px.R(&"wood", 3, 9), 0.85 - t * 0.4 if top else 0.3 - t * 0.2, x, y, 0.2)
			else:
				var pleat := (x - 4) % 4
				col = P(&"leather", 5) if pleat == 0 else (P(&"leather", 4) if pleat == 1 else (P(&"leather", 3) if pleat == 2 else P(&"leather", 2)))
			fb.set_pixel(x, y, col)
	for y in range(22, 27):
		for x in range(30, 38):
			fb.set_pixel(x, y, P(&"brass", 5) if y == 22 else (P(&"brass", 2) if y == 26 else P(&"brass", 4)))
	# Asas.
	for x in range(0, 6):
		_Px.put(fb, x, 13, P(&"wood", 6))
		_Px.put(fb, x, 35, P(&"wood", 4))
	_Px.blit(img, _Px.outline(fb, _Px.ink()), 0, 0)
	# Ráfaga: líneas de viento de la boquilla al fuego.
	for wl: Array in [[39, 21, 8], [40, 24, 11], [39, 27, 7]]:
		for k in int(wl[2]):
			if k % 4 != 3:
				_Px.put(img, int(wl[0]) + k, int(wl[1]) + int(sin(k * 0.6) * 1.0), P(&"linen", 5))
	_Bg.motes(img, Rect2i(50, 2, 18, 16), 7, 13)
	return img


# ---------------------------------------------------------------------------------------------------------------
# AVIVAR · PC · el atizador remueve las brasas del brasero y estalla una bocanada de chispas hacia arriba.
static func stoke() -> Image:
	var img := _Px.new_img()
	_Bg.forge_dark(img, Vector2(34, 36), 30.0, 44)
	# Brasero: cuenco de hierro en la parte baja.
	var bw := _Px.new_img()
	for y in range(30, 42):
		var half := 28.0 - (y - 30) * 1.2
		for x in range(int(34 - half), int(34 + half) + 1):
			var lit := 0.5 - float(x - 34) / half * 0.35 - (y - 30) * 0.03
			if y == 30:
				lit = 0.9
			bw.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"iron", 2, 8), lit, x, y, 0.2))
	for x in range(20, 50, 6):
		_Px.vline(bw, x, 42, 45, P(&"iron", 3))
	_Px.blit(img, _Px.outline(bw, _Px.ink()), 0, 0)
	# Montón de brasas sobre el cuenco.
	_Bg.ember_bed(img, Rect2i(8, 24, 52, 7), 0.75, 61, func(x: int, y: int) -> bool:
		return absf(x - 34.0) < 26.0 - (30 - y) * 2.6)
	# Atizador de hierro desde arriba-izquierda, con la punta hundida.
	var pk := _Px.new_img()
	for i in 30:
		var x := 6 + i
		var y := 2 + int(i * 0.8)
		_Px.put(pk, x, y, P(&"iron", 7))
		_Px.put(pk, x, y + 1, P(&"iron", 3))
		if i > 25:
			_Px.put(pk, x, y, P(&"hot", 4))
			_Px.put(pk, x, y + 1, P(&"hot", 3))
	for k in 5:
		_Px.put(pk, 4 + k % 2, 0 + k, P(&"iron", 6))
		_Px.put(pk, 3, k, P(&"iron", 3))
	_Px.blit(img, _Px.outline(pk, _Px.ink()), 0, 0)
	# Bocanada de chispas: abanico que sube desde la punta.
	var src := Vector2(37, 26)
	for i in 22:
		var a := -PI * 0.5 + (_Px.hash2(i, 1, 5) - 0.5) * 1.8
		var r := 6.0 + _Px.hash2(i, 2, 5) * 20.0
		var p := src + Vector2(cos(a), sin(a)) * r
		var col := P(&"fire", 7) if r < 12.0 else (P(&"fire", 6) if r < 18.0 else P(&"fire", 4))
		_Px.put(img, int(p.x), int(p.y), col)
		var tail := src + Vector2(cos(a), sin(a)) * (r - 2.0)
		_Px.put(img, int(tail.x), int(tail.y), P(&"fire", 4))
	# Llamarada central.
	_Sj.flamelet(img, 37, 27, 9)
	_Sj.flamelet(img, 32, 27, 5)
	_Sj.flamelet(img, 43, 28, 5)
	return img


# ---------------------------------------------------------------------------------------------------------------
# CARBÓN · B · hulla facetada sobre la rejilla, en la boca del horno. Luz: el lecho de abajo.
const COAL := [
	"...........kkkk...........",
	"........kkkHHHhk..........",
	".....kkkHHHHHhhhkk........",
	"...kkHHHHHHhhhhhhhkkk.....",
	"..kHHHHHhhhhhhhhhhmmmk....",
	".kHHHhhhhhhhhhhhhmmmmmkk..",
	".khhhhhhhhhhhhhhmmmmmmmmk.",
	"kGhhhhhhhhhhhmmmmmOmmmmddk",
	"kGGhhhhhhhhmmmmmmOmmmmdddk",
	"kGGGgmmmmmmmmmmmOmmmmddddk",
	"kGGgggmmmmmmOOOmmmmmddddk.",
	".kGgggggmmmmmmOmmmmddddk..",
	".kGggggggmmmmmmOmmmddddk..",
	"..kgggggggggmmmmOdddddk...",
	"..kgggOgggggggmmdddddk....",
	"...kgggOOggggggddddkk.....",
	"....kkgggOgggggddkk.......",
	"......kkkkkkkkkkk.........",
]


static func coal() -> Image:
	var img := _Px.new_img()
	var ac := Vector2(34.0, 44.0)
	var ri := 30.0
	_Bg.furnace_mouth(img, ac, ri, 37.0)
	var inside := func(x: int, y: int) -> bool:
		return Vector2((x + 0.5 - ac.x) / 1.15, y + 0.5 - ac.y).length() < ri
	_Bg.ember_bed(img, Rect2i(6, 39, 57, 7), 0.5, 77, inside)
	for x in range(6, 63):
		if not inside.call(x, 37):
			continue
		_Px.put(img, x, 37, P(&"iron", 7))
		_Px.put(img, x, 38, P(&"iron", 3))
		_Px.put(img, x, 39, _Px.ink())
	for x in range(9, 60, 5):
		for y in range(40, H):
			if inside.call(x, y):
				_Px.put(img, x, y, P(&"iron", 1))
	var cpal := {"k": _Px.ink(), "H": P(&"coal", 5), "h": P(&"coal", 4), "m": P(&"coal", 3), "d": P(&"coal", 2),
		"g": P(&"furnace_brick", 4), "G": P(&"furnace_brick", 6), "O": P(&"fire", 4)}
	var cimg := _Px.sprite(COAL, cpal)
	for y in cimg.get_height():
		for x in cimg.get_width():
			if cimg.get_pixel(x, y) == cpal["O"]:
				var nb := 0
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if _Px.get_c(cimg, x + d.x, y + d.y) == cpal["O"]:
						nb += 1
				if nb >= 2:
					cimg.set_pixel(x, y, P(&"fire", 6))
	cimg.set_pixel(11, 1, P(&"coal", 5, true))
	cimg.set_pixel(12, 1, P(&"coal", 4, true))
	cimg.set_pixel(5, 3, P(&"coal", 4, true))
	_Px.blit(img, cimg, 21, 20)
	# Humo violáceo por la clave del arco (veladura que aclara un paso).
	for y in range(5, 22):
		for x in range(22, 48):
			var sx := 34.0 + sin(y * 0.45) * 3.0
			var fall := 1.0 - absf(x - sx) / (5.0 + (22 - y) * 0.3)
			var a := _Px.fbm(x / 4.0, y / 3.0, 12) * fall * 1.6
			if a > 0.55:
				_Px.veil(img, x, y, 1, 1.0 if a > 0.8 else 0.5)
	_Bg.motes(img, Rect2i(16, 10, 36, 16), 9, 3)
	return img
