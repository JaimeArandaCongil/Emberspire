extends RefCounted
## Ilustraciones de las 4 cartas que eran «icono sobre degradado» (C10, F2-ILUS): composición propia por carta.
## Cada función devuelve una Image 68×46 en paleta. Gramática: FONDO + LUZ + SUJETO + FX + ENCUADRE (card_illus.gd).
## Combinaciones (fondo · encuadre · sujeto · posición), ninguna repetida en el registro:
## - inner_fire: muro de la Torre cálido · capilla · mano abierta con una llama · centro, de abajo arriba.
## - brazier_flame: muro mitad cálido/mitad frío + losas · filo · tres braseros en fuga que lanzan un latigazo · diagonal
##   abajo-izq. → arriba-der. (murciélago alcanzado).
## - shield_bash: penumbra de fragua + losas · filo · rodela de perfil empujada por el brazo · izquierda, golpeando un
##   limo a la derecha.
## - ember_guard: muro frío de la Torre · escudo · cúpula de ascuas sobre un montón de brasas · izquierda-centro, dardos
##   de hollín rompiéndose desde arriba-derecha.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const _Bg := preload("res://scripts/art/cards/illus/backdrops.gd")
const _Sj := preload("res://scripts/art/cards/illus/subjects.gd")
const W := 68
const H := 46

const IDS: Array[String] = ["inner_fire", "brazier_flame", "shield_bash", "ember_guard"]


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


static func build(id: String) -> Image:
	match id:
		"inner_fire": return inner_fire()
		"brazier_flame": return brazier_flame()
		"shield_bash": return shield_bash()
		"ember_guard": return ember_guard()
	return null


## Llama en lágrima con la base en (bx, by), alto `h`, medio ancho `hw`; `lean` desplaza la punta en x.
static func _flame(img: Image, bx: float, by: float, h: float, hw: float, lean: float, seed: int) -> void:
	for y in range(int(by - h) - 2, int(by) + 2):
		for x in range(int(bx - hw) - 3, int(bx + hw + absf(lean)) + 3):
			var t := clampf((by - (y + 0.5)) / h, 0.0, 1.0)
			if y + 0.5 > by + 1.0:
				continue
			var cx := bx + lean * t * t
			var half := hw * sqrt(maxf(0.0, 1.0 - pow(t, 1.6))) * (1.0 - t * 0.35)
			half += (_Px.fbm(x / 3.0, y / 2.0 - t * 2.0, seed) - 0.5) * 2.6 * t
			var d := absf(x + 0.5 - cx)
			if d > half:
				continue
			var core := 1.0 - d / maxf(0.6, half)
			var heat := core * 0.75 + (1.0 - t) * 0.45
			var step := 2
			if heat > 1.0:
				step = 7
			elif heat > 0.85:
				step = 6
			elif heat > 0.66:
				step = 5
			elif heat > 0.45:
				step = 4
			elif heat > 0.28:
				step = 3
			_Px.put(img, x, y, P(&"fire", step))


# ---------------------------------------------------------------------------------------------------------------
# FUEGO INTERIOR · PM · una mano abierta, palma arriba, sostiene una llama que nace de ella; los dedos la enjaulan.
# Luz: la propia llama (cantos de los dedos que la miran al rojo, antebrazo en sombra). Fondo: muro de la Torre que sólo la
# llama ilumina.
static func inner_fire() -> Image:
	var img := _Px.new_img()
	var fc := Vector2(34, 20)
	_Bg.tower_wall(img, fc, 30.0, 999.0, 0.02, 7)
	# Halo de calor tramado en el muro (sube un paso alrededor de la llama).
	for y in H:
		for x in W:
			var d := Vector2((x - fc.x) / 1.2, y - fc.y).length()
			if d < 13.0:
				_Px.veil(img, x, y, 1, 1.0 - d / 13.0 + 0.2)
	# La llama nace de la palma; la mano se dibuja delante (los dedos la enjaulan y se recortan contra ella).
	_flame(img, 34.0, 31.0, 30.0, 9.0, 1.5, 41)
	_flame(img, 27.0, 30.0, 12.0, 3.0, -3.0, 43)
	_flame(img, 41.0, 30.0, 13.0, 3.0, 3.0, 47)
	# Mano abierta, palma arriba, que sube desde abajo: piezas como cápsulas [a, b, radio, parte].
	var caps := [
		[Vector2(35.0, 39.0), Vector2(37.0, 52.0), 5.0, 2],     # muñeca y antebrazo (manga desde y 42)
		[Vector2(28.0, 36.0), Vector2(22.0, 31.0), 1.9, 1],     # pulgar
		[Vector2(29.0, 33.0), Vector2(26.5, 26.5), 1.6, 1],     # índice
		[Vector2(32.5, 32.0), Vector2(32.0, 25.0), 1.6, 1],     # corazón
		[Vector2(36.5, 32.5), Vector2(38.5, 25.5), 1.6, 1],     # anular
		[Vector2(39.5, 34.0), Vector2(43.0, 28.5), 1.4, 1],     # meñique
	]
	var occ := func(x: int, y: int) -> int:
		var p := Vector2(x + 0.5, y + 0.5)
		var e := pow((p.x - 34.0) / 7.5, 2.0) + pow((p.y - 36.0) / 4.2, 2.0)
		if e <= 1.0:
			return 1
		for c: Array in caps:
			var a0: Vector2 = c[0]
			var ab: Vector2 = (c[1] as Vector2) - a0
			var t := clampf((p - a0).dot(ab) / ab.length_squared(), 0.0, 1.0)
			if p.distance_to(a0 + ab * t) <= float(c[2]):
				return int(c[3]) if (int(c[3]) != 2 or p.y < 42.0) else 3
		return 0
	var flame_c := Vector2(34.0, 22.0)
	var hand := _Px.new_img()
	for y in range(14, H):
		for x in range(14, 54):
			var part: int = occ.call(x, y)
			if part == 0:
				continue
			var p2 := Vector2(x + 0.5, y + 0.5)
			var dir := (flame_c - p2).normalized()
			var lit := 0.42 - clampf((p2.distance_to(flame_c) - 8.0) / 40.0, 0.0, 0.3)
			if int(occ.call(int(floor(p2.x + dir.x * 1.5)), int(floor(p2.y + dir.y * 1.5)))) == 0:
				lit = 0.97
			elif int(occ.call(int(floor(p2.x + dir.x * 3.0)), int(floor(p2.y + dir.y * 3.0)))) == 0:
				lit = 0.72
			var ramp: Array = _Px.R(&"cloth", 1, 6) if part == 3 else _Px.R(&"skin", 1, 6)
			if part == 3 and y == 42:
				lit = 0.1
			hand.set_pixel(x, y, _Px.ramp_pick(ramp, lit, x, y, 0.25))
	_Px.blit(img, _Px.outline(hand, _Px.ink()), 0, 0)
	# Lengüetas secundarias y pavesas que suben.
	for m: Vector2i in [Vector2i(26, 9), Vector2i(44, 6), Vector2i(40, 14), Vector2i(23, 16), Vector2i(31, 2), Vector2i(47, 12)]:
		_Px.put(img, m.x, m.y, P(&"fire", 6))
		_Px.put(img, m.x, m.y + 1, P(&"fire", 3))
	return img


# ---------------------------------------------------------------------------------------------------------------
# LLAMA DE BRASERO · PC · tres braseros en fuga a lo largo del muro; sus llamas se tuercen y se trenzan en un
# latigazo que alcanza a un murciélago de ceniza arriba a la derecha. Luz: los braseros (cálida, izq.) contra la
# fría de la Torre (der.).
static func brazier_flame() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(14, 30), 34.0, 40.0, 0.08, 7)
	_Bg.floor_slabs(img, 37, 14.0)
	var hit := Vector2(55.0, 11.0)
	# Braseros: [centro x, y del borde, medio ancho, alto de patas].
	var braz := [[11.0, 33.0, 8.0, 9.0], [27.0, 31.0, 5.0, 6.0], [38.0, 30.0, 3.0, 4.0]]
	var flames := _Px.new_img()
	for i in range(braz.size() - 1, -1, -1):
		var b: Array = braz[i]
		var bx: float = b[0]
		var by: float = b[1]
		var hw: float = b[2]
		var lh: float = b[3]
		var br := _Px.new_img()
		# Patas en trípode.
		for lx: float in [-hw * 0.7, 0.0, hw * 0.7]:
			var x0 := int(bx + lx * 0.6)
			var x1 := int(bx + lx * 1.15)
			_Px.line(br, x0, int(by) + 2, x1, int(by + lh), P(&"iron", 2))
		# Cuenco de hierro: trapecio con canto alto iluminado por las brasas.
		var bh := maxi(2, int(hw * 0.55))
		for y in range(int(by), int(by) + bh + 1):
			var t := float(y - int(by)) / maxf(1.0, bh)
			var half := hw * (1.0 - t * 0.45)
			for x in range(int(bx - half), int(bx + half) + 1):
				var lit := 0.55 - t * 0.4 - (x - bx) / (hw * 4.0)
				var col := _Px.ramp_pick(_Px.R(&"iron", 2, 6), lit, x, y, 0.2)
				if y == int(by):
					col = P(&"iron", 6)
				_Px.put(br, x, y, col)
		_Px.blit(img, _Px.outline(br, _Px.ink()), 0, 0)
		# Brasas en la boca.
		for x in range(int(bx - hw) + 1, int(bx + hw)):
			_Px.put(img, x, int(by) - 1, P(&"fire", 5 if (x + i) % 3 == 0 else 3))
		# Llama propia, inclinada hacia el blanco.
		_flame(img, bx, by - 1.0, 6.0 + hw * 1.3, hw * 0.55, hw * 0.9, 50 + i)
		# Corriente hacia el blanco (curva cuadrática que se adelgaza).
		var p0 := Vector2(bx + hw * 0.4, by - 4.0 - hw)
		var p1 := Vector2(bx + 8.0, p0.y - 14.0 + i * 4.0)
		var n := 90
		for k in n:
			var t2 := float(k) / (n - 1)
			var q := p0.lerp(p1, t2).lerp(p1.lerp(hit, t2), t2)
			var th := lerpf(hw * 0.35, 1.2, t2) + t2 * 1.2
			for dy in range(-int(th), int(th) + 1):
				var heat := 1.0 - absf(dy) / (th + 0.5)
				var step := 3 if heat < 0.35 else (5 if heat < 0.75 else 6)
				if t2 > 0.7 and heat > 0.5:
					step = 7
				var px := int(q.x)
				var py := int(q.y) + dy
				if _Px.get_c(flames, px, py).a == 0.0 or step > int(Palette.find(_Px.get_c(flames, px, py))[1]):
					_Px.put(flames, px, py, P(&"fire", step))
	_Px.blit(img, flames, 0, 0)
	# Murciélago alcanzado, con luz de borde del fuego.
	var bat := _Sj.critter("bat", P(&"fire", 5))
	_Px.blit(img, bat, int(hit.x) - 4, int(hit.y) - 6)
	_Sj.impact(img, Vector2i(hit), 4)
	for sp: Vector2i in [Vector2i(63, 4), Vector2i(61, 18), Vector2i(49, 3), Vector2i(65, 12)]:
		_Px.put(img, sp.x, sp.y, P(&"fire", 6))
	return img


# ---------------------------------------------------------------------------------------------------------------
# GOLPE DE ESCUDO · PM · el brazo empuja una rodela de canto contra un limo de ceniza, que se aplasta. Luz: el
# chispazo del choque (derecha) y la fragua al fondo (izquierda, rasante).
static func shield_bash() -> Image:
	var img := _Px.new_img()
	_Bg.forge_dark(img, Vector2(44, 22), 34.0, 23)
	_Bg.floor_slabs(img, 38, 46.0)
	var hit := Vector2i(44, 19)
	# Limo de ceniza aplastado contra el escudo (derecha).
	var sl := _Px.new_img()
	var sc := Vector2(53.0, 29.0)
	for y in range(12, 40):
		for x in range(38, W):
			var dx := (x + 0.5 - sc.x)
			var dy := (y + 0.5 - sc.y)
			# Aplastado por la izquierda: más ancho abajo, hundido donde entra el escudo.
			var rx := 13.0 + dy * 0.2
			var ry := 9.0
			if dx < 0.0:
				rx -= maxf(0.0, 5.0 - absf(dy + 6.0) * 0.6)
			var e := (dx / rx) * (dx / rx) + (dy / ry) * (dy / ry)
			if e > 1.0 or y > 38:
				continue
			var lit := 0.42 - dy / ry * 0.3 - dx / rx * 0.15
			if dx < -rx * 0.5:
				lit += 0.3   # el chispazo le da en la cara
			var col := _Px.ramp_pick(_Px.R(&"ash", 1, 6), lit, x, y, 0.25)
			# Brillo húmedo: reflejos del fuego en la cúpula del limo (lo distingue de una roca).
			var gl := Vector2((dx + 3.0) / 3.2, (dy + 5.5) / 1.4).length()
			if gl < 1.0:
				col = P(&"fire", 5) if gl < 0.5 else P(&"ash", 7)
			if Vector2((dx - 6.0) / 1.6, (dy + 4.0) / 1.0).length() < 1.0:
				col = P(&"ash", 7)
			sl.set_pixel(x, y, col)
	# Charco a sus pies.
	for x in range(40, W):
		var w := 1.0 - absf(x - 54.0) / 15.0
		if w > 0.0:
			_Px.put(sl, x, 38, P(&"ash", 3))
			if w > 0.4:
				_Px.put(sl, x, 39, P(&"ash", 2))
	# Ojos aplastados y gotas que salen despedidas.
	for e2: Vector2i in [Vector2i(49, 26), Vector2i(55, 26)]:
		_Px.rect(sl, e2.x, e2.y - 1, 2, 3, _Px.ink())
		_Px.put(sl, e2.x, e2.y - 1, P(&"fire", 6))
	_Px.hline(sl, 50, 55, 31, _Px.ink())
	_Px.put(sl, 51, 30, _Px.ink())
	_Px.put(sl, 54, 30, _Px.ink())
	_Px.blit(img, _Px.outline(sl, _Px.ink()), 0, 0)
	for g: Vector2i in [Vector2i(58, 14), Vector2i(63, 18), Vector2i(53, 13)]:
		_Px.rect(img, g.x, g.y, 2, 2, P(&"ash", 5))
		_Px.put(img, g.x + 1, g.y + 1, P(&"ash", 3))
		_Px.put(img, g.x - 1, g.y + 2, P(&"ash", 3))
	# Estela de movimiento detrás del escudo (líneas horizontales tramadas).
	for row: Array in [[14, 3, 26], [19, 0, 24], [25, 2, 25], [31, 6, 27]]:
		var yy: int = row[0]
		for x in range(int(row[1]), int(row[2])):
			var f := float(x - int(row[1])) / (int(row[2]) - int(row[1]))
			if f < 0.5 and _Px.bayer(x, yy) > f * 2.0:
				continue
			_Px.put(img, x, yy, P(&"linen", 4) if f > 0.6 else P(&"linen", 3))
	# Brazo (manga y guante) desde la izquierda hasta el asa de la rodela.
	var arm := _Px.new_img()
	var a0 := Vector2(-4.0, 34.0)
	var a1 := Vector2(26.0, 24.0)
	var ab := a1 - a0
	for y in range(14, H):
		for x in range(0, 34):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := clampf((p - a0).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var c := a0 + ab * t
			var half := 4.5 - t * 1.0
			if p.distance_to(c) > half:
				continue
			var s := (p - c).dot(Vector2(-ab.y, ab.x).normalized()) / half
			var lit := 0.3 - s * 0.35 + t * 0.15
			var ramp: Array = _Px.R(&"leather", 1, 6) if t > 0.7 else _Px.R(&"cloth", 1, 6)
			arm.set_pixel(x, y, _Px.ramp_pick(ramp, lit, x, y, 0.25))
	_Px.blit(img, _Px.outline(arm, _Px.ink()), 0, 0)
	# Rodela de perfil (elipse estrecha): canto de latón, cara de hierro, umbo; brillo del choque a la derecha.
	var sh := _Px.new_img()
	var shc := Vector2(34.5, 22.5)
	for y in range(4, 42):
		for x in range(24, 46):
			var v := Vector2((x + 0.5 - shc.x) / 7.0, (y + 0.5 - shc.y) / 17.0)
			var r := v.length()
			if r > 1.0:
				continue
			var col: Color
			if r > 0.8:
				col = P(&"brass", 6) if v.x > 0.2 else (P(&"brass", 4) if v.y < 0.0 else P(&"brass", 2))
			else:
				var lit := 0.45 + v.x * 0.5 - v.y * 0.15
				col = _Px.ramp_pick(_Px.R(&"steel", 2, 6, true), lit, x, y, 0.3)
			sh.set_pixel(x, y, col)
	# Grueso del escudo (borde trasero a la izquierda).
	for y in range(6, 40):
		var v2 := (y + 0.5 - shc.y) / 17.0
		var hx := 7.0 * sqrt(maxf(0.0, 1.0 - v2 * v2))
		_Px.put(sh, int(shc.x - hx) - 1, y, P(&"brass", 1))
	_Px.disc(sh, 36.5, 22.5, 3.0, P(&"brass", 3))
	_Px.disc(sh, 37.0, 21.5, 1.6, P(&"brass", 5))
	_Px.put(sh, 37, 21, P(&"brass", 6))
	for rv: Vector2i in [Vector2i(35, 9), Vector2i(36, 35), Vector2i(31, 22), Vector2i(39, 15), Vector2i(39, 30)]:
		_Px.put(sh, rv.x, rv.y, P(&"brass", 5))
	_Px.blit(img, _Px.outline(sh, _Px.ink()), 0, 0)
	# Chispazo del choque.
	_Sj.impact(img, hit, 6)
	for sp: Array in [[49, 12, 1, -1], [50, 26, 1, 1], [45, 9, 0, -1], [52, 18, 1, 0]]:
		_Px.put(img, sp[0], sp[1], P(&"fire", 6))
		_Px.put(img, int(sp[0]) - int(sp[2]), int(sp[1]) - int(sp[3]), P(&"fire", 4))
	return img


# ---------------------------------------------------------------------------------------------------------------
# GUARDIA DE ASCUAS · PM · un montón de brasas levanta una cúpula de ascuas; los dardos de hollín de un murciélago
# se rompen contra ella. Luz: las brasas (cálida, dentro de la cúpula) contra la noche fría de la Torre.
static func ember_guard() -> Image:
	var img := _Px.new_img()
	_Bg.tower_wall(img, Vector2(24, 36), 26.0, -999.0, 0.06, 6)
	_Bg.floor_slabs(img, 38, 24.0, true)
	var dc := Vector2(24.0, 39.0)
	var rx := 21.0
	var ry := 28.0
	# Interior de la cúpula: el muro se calienta (veladura cálida tramada que sube pasos).
	for y in range(0, 39):
		for x in W:
			var e := Vector2((x + 0.5 - dc.x) / rx, (y + 0.5 - dc.y) / ry).length()
			if e < 0.92:
				_Px.veil(img, x, y, 1, 1.0 - e * 0.9)
	# Montón de brasas en el centro.
	_Bg.ember_bed(img, Rect2i(13, 33, 23, 7), 0.75, 91, func(x: int, y: int) -> bool:
		return Vector2((x + 0.5 - 24.0) / 11.5, (y + 0.5 - 40.0) / 7.0).length() < 1.0)
	_Sj.flamelet(img, 21, 34, 6)
	_Sj.flamelet(img, 27, 35, 5)
	# Cúpula: anillo de ascuas en guiones tangentes, más denso y caliente en el frente (derecha, donde golpean).
	for i in 260:
		var a := PI + PI * float(i) / 259.0
		var jit := (_Px.hash2(i, 1, 5) - 0.5) * 2.4
		var px := dc.x + cos(a) * (rx + jit)
		var py := dc.y + sin(a) * (ry + jit * 1.2)
		if _Px.hash2(i, 2, 5) > 0.55 + float(i) / 259.0 * 0.3:
			continue
		var hot := 0.35 + float(i) / 259.0 * 0.5 + _Px.hash2(i, 3, 5) * 0.2
		var step := 3 if hot < 0.55 else (5 if hot < 0.8 else 6)
		_Px.put(img, int(px), int(py), P(&"fire", step))
		var tx := int(px - sin(a) * 1.5)
		var ty := int(py + cos(a) * 1.5)
		_Px.put(img, tx, ty, P(&"fire", maxi(2, step - 2)))
	# Arco interior tenue (segunda capa de la cúpula).
	for i2 in 120:
		var a2 := PI * 1.08 + PI * 0.84 * float(i2) / 119.0
		if i2 % 3 != 0:
			continue
		_Px.put(img, int(dc.x + cos(a2) * (rx - 4.0)), int(dc.y + sin(a2) * (ry - 5.0)), P(&"fire", 2))
	# Murciélago de hollín arriba a la derecha y sus dardos, rotos contra la cúpula.
	var bat := _Sj.critter("bat", P(&"rock_soot", 5, true))
	_Px.blit(img, bat, 49, 3)
	var hits: Array[Vector2i] = []
	for d: Array in [[50, 12, 40.0, 18.0], [56, 13, 43.0, 28.0], [60, 10, 37.0, 13.0]]:
		var s := Vector2(float(d[0]), float(d[1]))
		var e2 := Vector2(float(d[2]), float(d[3]))
		var dir := (e2 - s).normalized()
		var L := int(s.distance_to(e2))
		for k in range(maxi(0, L - 9), L):
			var q := s + dir * k
			var q2 := q + Vector2(-dir.y, dir.x)
			_Px.put(img, int(q.x), int(q.y), P(&"soot", 4, true))
			if k < L - 3:
				_Px.put(img, int(q2.x), int(q2.y), P(&"soot", 2, true))
		hits.append(Vector2i(e2))
	for hp: Vector2i in hits:
		_Px.put(img, hp.x, hp.y, P(&"fire", 7))
		for dd: Vector2i in [Vector2i(1, -1), Vector2i(2, 0), Vector2i(1, 1), Vector2i(-1, -1)]:
			_Px.put(img, hp.x + dd.x, hp.y + dd.y, P(&"fire", 5))
		_Px.put(img, hp.x + 3, hp.y - 2, P(&"fire", 4))
	return img
