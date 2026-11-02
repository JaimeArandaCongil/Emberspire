extends RefCounted
## Ilustraciones del Grimorio de la Pira, prueba de nivel B (3 cartas: ataque, habilidad, poder).
## Cada función devuelve una Image 68×46 en paleta. Composición: `propuesta.md` §4.6.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const _Bg := preload("res://scripts/art/cards/illus/backdrops.gd")
const W := 68
const H := 46

const IDS: Array[String] = ["pyre_dance", "open_flue", "kiln"]


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


static func build(id: String) -> Image:
	match id:
		"pyre_dance": return pyre_dance()
		"open_flue": return open_flue()
		"kiln": return kiln()
	return null


static func _in_poly(poly: Array, x: float, y: float) -> bool:
	var inside := false
	var j := poly.size() - 1
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[j]
		if (a.y > y) != (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x:
			inside = not inside
		j = i
	return inside


# ---------------------------------------------------------------------------------------------------------------
# DANZA DE LA PIRA · PM · la Fogonera gira sobre el altar con la espada; a su alrededor sube una espiral de fuego con
# cartas ardiendo. Luz: la propia espiral (cálida, desde atrás y los lados).
static func pyre_dance() -> Image:
	var img := _Px.new_img()
	var bgr := _Px.R(&"furnace_brick", 0, 5)
	for y in H:
		for x in W:
			var l := clampf(1.0 - Vector2((x - 34.0) / 1.3, y - 24.0).length() / 36.0, 0.0, 1.0)
			l = l * 0.8 + (_Px.fbm(x / 9.0, y / 6.0, 31) - 0.5) * 0.1
			img.set_pixel(x, y, _Px.ramp_pick(bgr, l, x, y))
	_Bg.pillar(img, 0, 6)
	_Bg.pillar(img, 62, 6)
	# Dais circular de piedra con su canto iluminado.
	for y in range(35, H):
		for x in W:
			var e := pow((x - 34.0) / 33.0, 2.0) + pow((y - 35.0) / 11.0, 2.0)
			if e > 1.0:
				continue
			var l2 := clampf(0.7 - (y - 35) * 0.045 - absf(x - 34.0) / 70.0, 0.0, 1.0)
			var col := _Px.ramp_pick(_Px.R(&"stone", 1, 6), l2, x, y)
			if e > 0.78:
				col = P(&"stone", 5) if y < 40 else P(&"stone", 2)
			img.set_pixel(x, y, col)
	# Espiral de fuego: hélice elíptica que sube.
	var spiral := _Px.new_img()
	var N := 520
	for i in N:
		var t := float(i) / N
		var a := t * TAU * 2.6 + 0.6
		var r := 11.0 + 17.0 * (1.0 - t) * (1.0 - t) + 4.0 * t
		var px := 34.0 + cos(a) * r * 1.7
		var py := 40.0 - t * 38.0 + sin(a) * r * 0.28
		var heat := 7 - int(t * 4.0) - (1 if sin(a) < 0.0 else 0)
		var thick := 2 if t < 0.7 else 1
		for k in thick:
			_Px.put(spiral, int(px), int(py) + k, P(&"fire", clampi(heat - k, 2, 7)))
	# Cartas ardiendo.
	var cards := [[11, 30], [53, 24], [14, 14], [55, 8], [29, 3]]
	for cd: Array in cards:
		var cx: int = cd[0]
		var cy: int = cd[1]
		for y in range(cy, cy + 7):
			for x in range(cx, cx + 5):
				var edge := x == cx or x == cx + 4 or y == cy or y == cy + 6
				var col := P(&"parch_attack", 3)
				if edge:
					col = P(&"fire", 5)
				elif y == cy + 3 and x > cx + 1 and x < cx + 4:
					col = P(&"fire", 3)
				_Px.put(spiral, x, y, col)
		_Px.put(spiral, cx + 1, cy - 1, P(&"fire", 6))
		_Px.put(spiral, cx + 3, cy - 2, P(&"fire", 7))
	_Px.blit(img, _Px.outline(spiral, P(&"furnace_brick", 1)), 0, 0)
	# Fogonera.
	var fg := _Px.new_img()
	for y in range(32, 41):
		for x in range(30, 39):
			if x == 34 or (y > 38 and (x < 31 or x > 37)):
				continue
			_Px.put(fg, x, y, _Px.ramp_pick(_Px.R(&"boot", 1, 5), 0.5 - (y - 32) * 0.03 + (0.15 if x < 34 else 0.0), x, y))
	for y in range(27, 37):
		var half := 5.0 + (y - 27) * 1.0
		for x in range(int(34 - half), int(34 + half) + 1):
			var nx := (x - 34.0) / half
			var l3 := 0.5 + nx * 0.25 - (y - 27) * 0.03
			if y > 33 and (x + y) % 3 == 0:
				l3 -= 0.1
			_Px.put(fg, x, y, _Px.ramp_pick(_Px.R(&"cloth", 2, 9), l3, x, y, 0.25))
	for y in range(19, 28):
		for x in range(30, 38):
			var l4 := 0.45 + (x - 34.0) * 0.07
			_Px.put(fg, x, y, _Px.ramp_pick(_Px.R(&"cloth", 3, 8), l4, x, y, 0.25))
	_Px.hline(fg, 30, 37, 26, P(&"leather", 4))
	_Px.put(fg, 34, 26, P(&"gold", 4))
	_Px.disc(fg, 34.0, 15.5, 3.6, P(&"skin", 4))
	_Px.put(fg, 35, 15, P(&"skin", 5))
	_Px.put(fg, 36, 15, _Px.ink())
	for y in range(11, 16):
		for x in range(30, 38):
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(34.0, 15.5)) < 4.2 and y < 14 + (1 if x < 33 else 0):
				_Px.put(fg, x, y, P(&"hair", 4 + (x + y) % 2))
	for k in 10:
		var hx := 30 - k
		var hy := 13 + int(sin(k * 0.8) * 1.5) + k / 3
		_Px.put(fg, hx, hy, P(&"hair", clampi(6 - k / 2, 3, 6)))
		_Px.put(fg, hx, hy + 1, P(&"hair", clampi(5 - k / 2, 2, 5)))
	_Px.line(fg, 36, 22, 41, 20, P(&"cloth", 6))
	_Px.line(fg, 36, 23, 41, 21, P(&"cloth", 4))
	_Px.put(fg, 42, 20, P(&"skin", 4))
	_Px.blit(img, _Px.outline(fg, _Px.ink()), 0, 0)
	var blade := _Px.new_img()
	_Px.line(blade, 42, 20, 62, 15, P(&"steel", 6, true))
	_Px.line(blade, 42, 21, 62, 16, P(&"steel", 4, true))
	_Px.line(blade, 43, 22, 60, 17, P(&"steel", 3, true))
	_Px.line(blade, 41, 17, 41, 23, P(&"gold", 5))
	_Px.blit(img, _Px.outline(blade, _Px.ink()), 0, 0)
	_Px.line(img, 63, 15, 66, 22, P(&"fire", 7))
	_Px.line(img, 62, 17, 64, 24, P(&"fire", 5))
	_Px.line(img, 64, 14, 65, 11, P(&"fire", 4))
	_Bg.motes(img, Rect2i(8, 2, 52, 30), 12, 41)
	return img


# ---------------------------------------------------------------------------------------------------------------
# TIRO ABIERTO · B · mirando hacia arriba por el hueco de la chimenea: la trampilla se abre y la corriente de aire arrastra
# brasas hacia un cielo nocturno. Luz: la luna por la boca (fría) y el calor del fondo (cálido).
static func open_flue() -> Image:
	var img := _Px.new_img()
	var vp := Vector2(34.0, 9.0)
	var warm := _Px.R(&"furnace_brick", 0, 7)
	var cold := _Px.R(&"brick", 1, 8, true)
	for y in H:
		for x in W:
			var dx := (x + 0.5 - vp.x) / 11.0
			var dy := (y + 0.5 - vp.y) / 6.5
			var s := maxf(absf(dx), absf(dy))
			if s < 1.0:
				var t := clampf(float(y) / 14.0, 0.0, 1.0)
				img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"sky", 3, 8), 0.25 + t * 0.65, x, y))
				continue
			var ang := atan2(dy, dx)
			var ring := log(s) / log(1.45)
			var rid := int(floor(ring))
			var spoke := (ang + PI) / (PI / 12.0) + (0.5 if rid % 2 == 1 else 0.0)
			var mortar := fposmod(ring, 1.0) < 0.14 or fposmod(spoke, 1.0) < 0.1 * (1.0 + ring * 0.25)
			var l := 1.12 - ring * 0.2 + (_Px.hash2(int(floor(spoke)), rid, 6) - 0.5) * 0.16
			if mortar:
				l -= 0.22
			if ring < 1.0:
				img.set_pixel(x, y, _Px.ramp_pick(cold, l, x, y))
			else:
				var wl := l * 0.9 + clampf((y - 22.0) / 30.0, 0.0, 0.45) * (1.0 - absf(x - 34.0) / 40.0)
				img.set_pixel(x, y, _Px.ramp_pick(warm, wl, x, y))
	_Px.disc(img, 40.0, 5.0, 2.6, P(&"moon", 5))
	_Px.put(img, 39, 4, P(&"moon", 4))
	_Px.put(img, 41, 6, P(&"moon", 3))
	for st: Vector2i in [Vector2i(27, 3), Vector2i(31, 8), Vector2i(45, 9), Vector2i(35, 2)]:
		_Px.put(img, st.x, st.y, P(&"moon", 4))
	# Trampilla abierta, abatida sobre el borde izquierdo.
	var hatch := [Vector2(21, 15), Vector2(10, 8), Vector2(11, 1), Vector2(23, 6)]
	var hl := _Px.new_img()
	for y in range(0, 17):
		for x in range(8, 26):
			if not _in_poly(hatch, x + 0.5, y + 0.5):
				continue
			var plank := int(x + y * 0.4) % 4
			var l2 := 0.6 + (0.1 if plank == 0 else 0.0) - (y / 40.0)
			if plank == 3:
				l2 -= 0.25
			hl.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"wood", 2, 8), l2, x, y, 0.25))
	_Px.line(hl, 12, 4, 22, 9, P(&"iron", 6))
	_Px.line(hl, 12, 5, 22, 10, P(&"iron", 3))
	_Px.put(hl, 11, 4, P(&"gold", 5))
	_Px.blit(img, _Px.outline(hl, _Px.ink()), 0, 0)
	# Corriente ascendente y brasas arrastradas.
	for k in 7:
		var x0 := 34.0 + (k - 3) * 3.2
		for y in range(44, 12, -1):
			var f := float(44 - y) / 32.0
			var px := lerpf(x0, 34.0 + (k - 3) * 1.2, f) + sin(y * 0.35 + k) * (1.0 + f * 1.4)
			if (y + k * 3) % 5 < 3 and f > 0.1:
				_Px.veil(img, int(px), y, 3, 0.5 if f < 0.8 else 1.0)
	for i in 16:
		var f2 := _Px.hash2(i, 2, 11)
		var y2 := int(44.0 - f2 * 38.0)
		var x2 := 34.0 + (_Px.hash2(i, 4, 11) - 0.5) * lerpf(26.0, 8.0, f2) + sin(y2 * 0.4) * 1.5
		_Px.put(img, int(x2), y2, P(&"fire", 6 if i % 3 == 0 else 5))
		_Px.put(img, int(x2), y2 + 1, P(&"fire", 3))
	return img


# ---------------------------------------------------------------------------------------------------------------
# HORNO DE TIRO · E · horno de botella de ladrillo con la boca de leña encendida y el tiro abierto, humo en columna.
# Luz: la boca de leña (cálida, abajo) y un resto de cielo azul tras el horno.
static func kiln() -> Image:
	var img := _Px.new_img()
	for y in H:
		for x in W:
			var t := 1.0 - float(y) / 40.0
			img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"sky", 1, 6), 0.1 + (1.0 - t) * 0.55 + (_Px.fbm(x / 8.0, y / 4.0, 4) - 0.5) * 0.1, x, y))
	for st: Vector2i in [Vector2i(6, 4), Vector2i(14, 9), Vector2i(58, 5), Vector2i(62, 14), Vector2i(48, 3), Vector2i(20, 2), Vector2i(8, 17)]:
		_Px.put(img, st.x, st.y, P(&"sky", 9))
	_Bg.floor_slabs(img, 41, 34.0)
	var cx := 34.0
	var kl := _Px.new_img()
	var brick := _Px.R(&"brick", 1, 8)
	for y in range(7, 42):
		var half: float
		if y < 13:
			half = 3.5
		elif y < 19:
			half = 3.5 + (y - 13) * 0.9
		else:
			half = 8.9 + pow(float(y - 19) / 22.0, 1.15) * 12.6
		for x in range(int(cx - half), int(cx + half) + 1):
			var nx := (x + 0.5 - cx) / half
			var row := y / 3
			var bx := x + (3 if row % 2 == 1 else 0)
			var mortar := y % 3 == 2 or bx % 6 == 5
			var glow := clampf(1.0 - Vector2((x - cx) * 0.8, y - 41.0).length() / 26.0, 0.0, 1.0)
			var l := 0.28 - nx * 0.12 + glow * 0.6 + (_Px.hash2(bx / 6, row, 5) - 0.5) * 0.14
			if absf(nx) > 0.85:
				l -= 0.15
			if mortar:
				l -= 0.2
			kl.set_pixel(x, y, _Px.ramp_pick(brick, l, x, y))
	for hy: int in [25, 32]:
		for x in range(0, W):
			if kl.get_pixel(x, hy).a > 0.0:
				kl.set_pixel(x, hy, P(&"iron", 6) if x < 34 else P(&"iron", 4))
				if kl.get_pixel(x, hy + 1).a > 0.0:
					kl.set_pixel(x, hy + 1, P(&"iron", 2))
	for x in range(29, 40):
		kl.set_pixel(x, 7, P(&"iron", 6) if x < 36 else P(&"iron", 4))
		kl.set_pixel(x, 8, P(&"iron", 2))
	_Px.blit(img, _Px.outline(kl, _Px.ink()), 0, 0)
	# Boca de leña.
	for y in range(34, 41):
		for x in range(27, 42):
			var ax := (x + 0.5 - 34.0) / 7.0
			var ay := (y + 0.5 - 41.0) / 8.0
			if ax * ax + ay * ay > 1.0:
				continue
			var d := Vector2(ax, ay * 0.8).length()
			img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"fire", 2, 7), 1.0 - d * 0.9, x, y))
	# Resplandor y humo del tiro.
	_Px.hline(img, 31, 37, 6, P(&"fire", 5))
	_Px.hline(img, 32, 36, 5, P(&"fire", 7))
	for y in range(0, 5):
		var sx := 34.0 + sin(y * 0.8) * 1.5 + (4 - y) * 0.5
		var half2 := 2.0 + (4 - y) * 0.7
		for x in range(int(sx - half2), int(sx + half2) + 1):
			var n := _Px.fbm(x / 3.0, y / 2.0, 8)
			if n > 0.4:
				_Px.put(img, x, y, P(&"smoke", 4 if n > 0.55 else 3))
	_Bg.motes(img, Rect2i(28, 0, 14, 8), 4, 17)
	return img
