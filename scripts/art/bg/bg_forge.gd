class_name BgForge
extends RefCounted
## Forja de combate en formato ÍNDICE (MV · v0.4). Horno de botella en x 8–112, con el conducto de cobre casado en
## x 100–109 (y = 200) y chimenea hasta el borde superior. Entre el tiro bajo y la campana hay una JUNTA DE TIRO abierta
## (y 78–118): ahí se ve arder el calor y ahí salta la columna al quemar. Sólo la usa `tools/bake_rooms.gd`;
## en juego se cargan los PNG horneados (`BakedRooms.load_forge`) y `CombatForge` los compone.
##   base                     todo lo inmóvil
##   mouth_<0|1|2>[6]         boca con llama según el calor (bajo, medio, alto), puerta bajada
##   swallow[2]               boca abierta aspirando: puerta subida, llama tragada hacia el fondo
##   flash[2], flash_card[1]  destello a blanco, con la silueta de la carta en el primero
##   lick_<0|1|2>[6]          lenguas en la junta de tiro
##   grate[3]                 rejilla encendida (Quema disponible). Apagada = la que hay en la base

const W := 120
const H := 272
const CX := 55
const MOUTH_RECT := Rect2i(33, 200, 45, 45)
const MOUTH_SPRING := 222
const MOUTH_HW := 22
const MOUTH_BOTTOM := 244
const GAP_RECT := Rect2i(40, 76, 31, 44)
const GAP_TOP := 78
const GAP_BOTTOM := 118
const GRATE_X := [16, 33, 50, 67, 84]
const GRATE_Y := 249
const GRATE_SIZE := Vector2i(13, 10)
const PIPE_X := 100
const PIPE_PROF := [1, 3, 5, 8, 6, 5, 4, 3, 2, 1]

const BRICK := BgRamps.FURNACE
const STONE := BgRamps.STONE
const IRON := BgRamps.IRON
const COPPER := BgRamps.COPPER
const FIRE := BgRamps.FIRE
const COAL := BgRamps.COAL
const WOOD_M := BgRamps.WOOD


static func _h(x: int, y: int, s: int) -> float:
	return BgCanvas.hash3(x, y, s + 4441)


## Mitad de anchura del cuerpo a la altura y.
static func _hw(y: int) -> int:
	var t := clampf((y - 128) / 116.0, 0.0, 1.0)
	return int(roundf(13.0 + 33.0 * pow(t, 0.6)))


static func in_arch(x: int, y: int) -> bool:
	if y > MOUTH_BOTTOM - 1:
		return false
	if y >= MOUTH_SPRING:
		return absi(x - CX) < MOUTH_HW
	return Vector2(x - CX, y - MOUTH_SPRING).length() < MOUTH_HW


static func build() -> Dictionary:
	var out := {"base": _bake_base(), "frames": {}, "rects": {}}
	var frames: Dictionary = out["frames"]
	for lvl in 3:
		var mouth: Array = []
		var lick: Array = []
		for k in 6:
			mouth.append(_mouth_frame(lvl, k))
			lick.append(_lick_frame(lvl, k))
		frames["mouth_%d" % lvl] = mouth
		frames["lick_%d" % lvl] = lick
	frames["swallow"] = [_swallow_frame(0), _swallow_frame(1)]
	frames["flash"] = [_flash_frame(false), _flash_frame(false)]
	frames["flash_card"] = [_flash_frame(true)]
	var gr: Array = []
	for k in 3:
		gr.append(_grate_frame(k))
	frames["grate"] = gr
	return out


# --- base --------------------------------------------------------------------------------------

static func _bake_base() -> Dictionary:
	var c := BgCanvas.new(W, H)
	_stack(c)
	_body(c)
	_mouth_frame_ring(c)
	_plinth(c)
	_bellows(c)
	# La boca ilumina el ladrillo cercano; el lomo y la chimenea quedan oscuros (el contraste lo da el fuego).
	var lights := [{"t": "pt", "p": Vector2(CX, 224), "r": [26.0, 36.0, 50.0, 70.0], "ys": 1.0, "y1": 245},
		{"t": "pt", "p": Vector2(CX, 118), "r": [12.0, 24.0], "ys": 1.4},
		# Misma luz horneada que la capa media (BgAct1._static_lights): el conducto y sus bridas casan en valor.
		{"t": "pt", "p": Vector2(60, 226), "r": [56.0, 84.0, 118.0, 158.0, 206.0], "ys": 1.0, "x0": 97, "y1": 209},
		{"t": "pt", "p": Vector2(60, 226), "r": [56.0, 84.0], "ys": 1.0, "x0": 97, "y0": 210}]
	return c.bake(lights)


static func _cyl_step(n: float) -> int:
	if n < -0.72:
		return 2
	if n < -0.25:
		return 3
	if n < 0.3:
		return 4
	if n < 0.72:
		return 2
	return 1


static func _stack(c: BgCanvas) -> void:
	# Chimenea alta, de planchas remachadas, hasta el borde superior.
	for y in range(0, 64):
		var hw := 11
		for x in range(CX - hw, CX + hw + 1):
			var n := float(x - CX) / hw
			var plate := y / 16
			var ry := y % 16
			var v := _cyl_step(n) + 1
			if y < 18:
				v -= 3
			elif y < 40:
				v -= 1
			if n > 0.72 and n < 0.95:
				v += 1
			if absi(x - CX) == hw:
				c.put(x, y, IRON, 0)
			elif ry == 0:
				c.joint(x, y, IRON, 1)
			else:
				if ry == 1:
					v += 1
				if ry == 3 and posmod(x - CX, 6) == 2:
					v += 2
				c.put(x, y, IRON, v, Vector2i(CX, plate * 16 + 8))
	# Abrazadera a la viga: la chimenea está anclada al edificio.
	for y in range(20, 26):
		for x in range(CX - 13, CX + 14):
			var t := y - 20
			c.put(x, y, IRON, [4, 3, 2, 2, 1, 0][t], Vector2i(CX, 23))
	# Campana: recoge el tiro en la junta.
	for y in range(64, GAP_TOP):
		var t := float(y - 64) / float(GAP_TOP - 64)
		var hw2 := int(roundf(lerpf(11.0, 18.0, t * t)))
		for x in range(CX - hw2, CX + hw2 + 1):
			var n2 := float(x - CX) / hw2
			var v2 := _cyl_step(n2) - 1
			if absi(x - CX) == hw2:
				v2 = 0
			elif y >= GAP_TOP - 2:
				v2 = 1 if y == GAP_TOP - 1 else 3
			c.put(x, y, IRON, v2, Vector2i(CX, 71))
	# Tirantes de la junta.
	for y in range(GAP_TOP, GAP_BOTTOM):
		for sx: int in [CX - 16, CX + 16]:
			c.put(sx, y, IRON, 3, Vector2i(sx, 98))
			c.put(sx + 1, y, IRON, 1, Vector2i(sx, 98))
	# Tiro bajo: cuello del horno con labio ensanchado.
	for y in range(GAP_BOTTOM, 130):
		var lip := y < GAP_BOTTOM + 4
		var hw3 := 16 if lip else 13
		for x in range(CX - hw3, CX + hw3 + 1):
			var n3 := float(x - CX) / hw3
			var v3 := _cyl_step(n3)
			if lip:
				v3 = [5, 4, 2, 1][y - GAP_BOTTOM] + (1 if n3 < -0.2 else 0)
			if absi(x - CX) == hw3:
				v3 = 0
			c.put(x, y, IRON, v3, Vector2i(CX, 124))


static func _body(c: BgCanvas) -> void:
	for y in range(128, MOUTH_BOTTOM + 1):
		var hw := _hw(y)
		for x in range(CX - hw, CX + hw + 1):
			var dx := x - CX
			var n := float(dx) / hw
			var sag := dx * dx / 170
			var cy := y - sag
			# Aros de hierro.
			var by := -1
			for y0: int in [146, 172]:
				if cy >= y0 and cy < y0 + 4:
					by = cy - y0
			if absi(dx) == hw:
				c.put(x, y, BRICK, 0)
				continue
			var col := asin(clampf(n, -1.0, 1.0)) * 30.0
			if by >= 0:
				var seg := int(floorf(col / 8.0))
				var iv: int = [5, 4, 2, 1][by] + (1 if n < -0.25 else 0) - (1 if n > 0.6 else 0)
				if by == 1 and posmod(int(col), 8) == 3:
					iv += 3
				c.put(x, y, IRON, iv, Vector2i(CX + int(sin((seg + 0.5) * 8.0 / 30.0) * hw), y - by + 2))
				continue
			var row := int(floorf(cy / 6.0))
			var ry := posmod(cy, 6)
			var uu := col + 3.5 * posmod(row, 2)
			var ci := int(floorf(uu / 7.0))
			var fr := uu / 7.0 - ci
			var cos_n := maxf(0.35, sqrt(maxf(0.0, 1.0 - n * n)))
			if ry == 0 or fr < 0.13 / cos_n:
				c.joint(x, y, BRICK, 1)
				continue
			var v := 3
			var an := absf(n)
			if an > 0.86:
				v -= 2
			elif an > 0.62:
				v -= 1
			if y < 150:
				v -= 1
			var hb := _h(ci, row, 1)
			if hb < 0.16:
				v -= 1
			elif hb > 0.86:
				v += 1
			if ry == 5:
				v -= 1
			var ax := (float(ci) + 0.5) * 7.0 - 3.5 * posmod(row, 2)
			var anc := Vector2i(clampi(CX + int(sin(ax / 30.0) * hw), 0, W - 1), mini(row * 6 + 3 + sag, H - 1))
			c.put(x, y, BRICK, v, anc, BgCanvas.F_BEVEL if ry == 1 else 0)


static func _mouth_frame_ring(c: BgCanvas) -> void:
	# Boca: jambas y dovelas de piedra alrededor de un fondo negro.
	var cen := Vector2(CX, MOUTH_SPRING)
	var RI := float(MOUTH_HW)
	var RO := RI + 6.0
	for y in range(MOUTH_SPRING - int(RO) - 1, MOUTH_BOTTOM):
		for x in range(CX - int(RO) - 1, CX + int(RO) + 2):
			if in_arch(x, y):
				c.put(x, y, BRICK, 0)
				continue
			var d := Vector2(x, y) - cen
			if y < MOUTH_SPRING:
				var r := d.length()
				if r >= RO:
					continue
				var a := atan2(-d.y, d.x)
				var si := int(a / (PI / 9.0))
				var fr := a / (PI / 9.0) - si
				if fr < 0.09:
					c.joint(x, y, STONE, 1)
					continue
				var key := si == 4
				var ac := (si + 0.5) * PI / 9.0
				var v := 3 if not key else 4
				if r >= RO - 1.0:
					v -= 1
				elif r < RI + 1.0:
					v = 1
				c.put(x, y, STONE, v, Vector2i(CX + int(cos(ac) * (RI + 3.0)), MOUTH_SPRING - int(sin(ac) * (RI + 3.0))))
			elif absi(x - CX) < int(RO):
				var course := (y - MOUTH_SPRING) / 8
				if (y - MOUTH_SPRING) % 8 == 0:
					c.joint(x, y, STONE, 1)
					continue
				var ax := absi(x - CX)
				var v2 := 3
				if ax < MOUTH_HW + 1:
					v2 = 1
				elif ax == int(RO) - 1:
					v2 = 1
				var side := 1 if x > CX else -1
				c.put(x, y, STONE, v2, Vector2i(CX + side * (MOUTH_HW + 3), MOUTH_SPRING + course * 8 + 4))


static func _plinth(c: BgCanvas) -> void:
	# Zócalo con las rejillas de Quemas.
	for y in range(MOUTH_BOTTOM, 268):
		var t := y - MOUTH_BOTTOM
		for x in range(8, 104):
			var v := 3
			if t == 0:
				v = 6
			elif t == 1:
				v = 5
			elif t == 2:
				v = 2
			elif y >= 266:
				v = 0
			elif y >= 264:
				v = 1
			if x == 8 and t > 0:
				v = 0
			var block := (x - 8) / 24
			if posmod(x - 8, 24) == 0 and t > 2 and y < 264:
				c.joint(x, y, STONE, 1)
				continue
			c.put(x, y, STONE, v, Vector2i(8 + block * 24 + 12, 255))
	for gx: int in GRATE_X:
		_grate_box(c, gx, GRATE_Y, -1, 0)


## Marco de hierro y barrotes; `fire_v` >= 0 llena el interior de fuego.
static func _grate_box(c: BgCanvas, gx: int, gy: int, fire_v: int, k: int) -> void:
	var w: int = GRATE_SIZE.x
	var hh: int = GRATE_SIZE.y
	var anc := Vector2i(gx + w / 2, gy + hh / 2)
	for y in hh:
		for x in w:
			var edge := x == 0 or y == 0 or x == w - 1 or y == hh - 1
			if edge:
				c.put(gx + x, gy + y, IRON, 5 if x == 0 or y == 0 else 1, anc)
			elif posmod(x, 3) == 0:
				c.put(gx + x, gy + y, IRON, 2, anc)
			elif fire_v >= 0:
				var low := y >= hh - 4
				var fv := fire_v + (1 if low else 0) + (1 if _h(x, y, k + 21) > 0.72 else 0) - (1 if y < 3 else 0)
				c.put(gx + x, gy + y, FIRE, clampi(fv, 1, 7))
			else:
				c.put(gx + x, gy + y, COAL, 1, anc)


static func _bellows(c: BgCanvas) -> void:
	# Caja de la tobera: recibe el conducto y lo mete en el horno.
	for y in range(210, 268):
		for x in range(97, 113):
			var plate := (y - 210) / 18
			var ry := (y - 210) % 18
			var v := 3
			if x == 97 or x == 112 or y >= 266:
				v = 0
			elif x == 98 or ry == 1:
				v = 5
			elif x >= 110 or ry == 17:
				v = 1
			if ry == 0:
				c.joint(x, y, IRON, 1)
				continue
			if ry == 3 and (x == 100 or x == 109):
				v = 7
			c.put(x, y, IRON, v, Vector2i(105, 210 + plate * 18 + 9))
	# Rendijas de aire de la plancha central y palanca del fuelle.
	for ry2 in 3:
		for x in range(101, 109):
			c.put(x, 233 + ry2 * 3, IRON, 0)
			c.put(x, 234 + ry2 * 3, IRON, 5, Vector2i(105, 237))
	for i in 12:
		c.put(110 + i / 6, 214 - i, WOOD_M, 5 if i % 4 else 3, Vector2i(111, 208))
		c.put(111 + i / 6, 214 - i, WOOD_M, 2, Vector2i(111, 208))
	# Tobera de cobre que entra en el cuerpo.
	for x in range(84, 98):
		for i in 8:
			var v2: int = [1, 3, 6, 8, 5, 4, 2, 1][i]
			if posmod(x - 84, 13) == 0:
				v2 = [5, 7, 6, 5, 4, 3, 2, 1][i]
			c.put(x, 222 + i, COPPER, v2, Vector2i(91, 226))
	# Conducto: mismo perfil que el de la capa media, para que case sin costura en x 100–109.
	for y in range(192, 212):
		for i in 10:
			c.put(PIPE_X + i, y, COPPER, PIPE_PROF[i], Vector2i(105, 200))
	for fy0: int in [192, 206]:
		for y in range(fy0, fy0 + 4):
			for x in range(PIPE_X - 3, PIPE_X + 13):
				c.put(x, y, IRON, 5 if y == fy0 else (4 if y == fy0 + 1 else (2 if y == fy0 + 2 else 1)), Vector2i(105, fy0 + 2))
		for xb: int in [PIPE_X - 2, PIPE_X + 11]:
			c.put(xb, fy0 + 1, IRON, 7, Vector2i(105, fy0 + 2))


# --- fotogramas -----------------------------------------------------------------------------------

static func _frame_canvas(r: Rect2i) -> BgCanvas:
	return BgCanvas.new(r.size.x, r.size.y)


static func _fire_step(hv: float) -> int:
	if hv > 0.72:
		return 7
	if hv > 0.56:
		return 6
	if hv > 0.42:
		return 5
	if hv > 0.28:
		return 4
	if hv > 0.15:
		return 3
	return 2


## Campo de llama: lenguas que nacen en `base_y` y suben hasta `height`. Devuelve > 0 dentro.
static func _tongues(xx: float, yy: float, base_y: float, height: float, n: int, spread: float, k: int, sd: int) -> float:
	var ph := float(k) / 6.0
	var f := 0.0
	for j in n:
		var p := fposmod(ph + float(j) / float(n) + _h(j, 0, sd) * 0.3, 1.0)
		var jx := (float(j) - (n - 1) * 0.5) * spread / maxf(1.0, n - 1.0) * 2.0
		var tall := height * (0.55 + 0.45 * _h(j, 1, sd)) * (0.7 + 0.3 * sin(p * TAU))
		var cx := jx + sin(p * TAU + j * 1.9) * 1.8
		var up := clampf((base_y - yy) / maxf(1.0, tall), -1.0, 1.0)
		var wid := (spread / maxf(1.0, n - 1.0) + 2.0) * (1.0 - up * up * 0.2) * (1.0 - maxf(up, 0.0))
		if wid <= 0.0:
			continue
		var bend := sin(up * 3.0 + p * TAU + j) * 1.6 * maxf(up, 0.0)
		var d := absf(xx - cx - bend) / wid
		if yy <= base_y and d < 1.0:
			f = maxf(f, (1.0 - d) * (1.0 - maxf(up, 0.0) * 0.8))
	return f


static func _mouth_frame(lvl: int, k: int) -> Dictionary:
	var r := MOUTH_RECT
	var c := _frame_canvas(r)
	var tall: float = [12.0, 24.0, 36.0][lvl]
	var count: int = [4, 5, 7][lvl]
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not in_arch(x, y):
				continue
			var lx := x - r.position.x
			var ly := y - r.position.y
			# Puerta bajada: una plancha de hierro con dientes en la parte alta.
			if y < 208 or (y == 208 and posmod(x, 5) != 0):
				var dv := 3 if y < 207 else 1
				if y == 201 or y == 204:
					dv = 2
				if x <= r.position.x + 3 or x >= r.end.x - 3:
					dv = 1
				c.put(lx, ly, IRON, dv, Vector2i(r.size.x / 2, 4))
				continue
			# Lecho de carbón.
			if y >= MOUTH_BOTTOM - 4:
				var lump := _h((x + k / 2) / 3, y, 3 + lvl)
				if lump > 0.82 - lvl * 0.14:
					c.put(lx, ly, FIRE, 5 + lvl / 2)
				elif lump > 0.45:
					c.put(lx, ly, COAL, 3, Vector2i(lx / 3 * 3, ly))
				else:
					c.put(lx, ly, COAL, 1, Vector2i(lx / 3 * 3, ly))
				continue
			var f := _tongues(float(x - CX), float(y), float(MOUTH_BOTTOM - 4), tall, count, 16.0, k, 30 + lvl)
			if f > 0.0:
				c.put(lx, ly, FIRE, clampi(_fire_step(f) - (1 if lvl == 0 else 0), 1, 7))
			else:
				_throat(c, x, y, lx, ly, MOUTH_BOTTOM - 12 - lvl * 7)
	return c.bake([])


## Fondo del hogar: hiladas de ladrillo a contraluz, encendidas sólo cerca del fuego.
static func _throat(c: BgCanvas, x: int, y: int, lx: int, ly: int, lit_from: int) -> void:
	var row := y / 5
	var joint := y % 5 == 0 or posmod(x + (row % 2) * 4, 8) == 0
	var v := 0
	if y >= lit_from:
		v = 1
	if not joint and y >= lit_from + 4:
		v = 2
	elif joint:
		v = maxi(0, v - 1)
	c.put(lx, ly, FIRE, v)


static func _swallow_frame(k: int) -> Dictionary:
	var r := MOUTH_RECT
	var c := _frame_canvas(r)
	var core := Vector2(CX, 232)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not in_arch(x, y):
				continue
			var lx := x - r.position.x
			var ly := y - r.position.y
			# Puerta subida: sólo asoman sus dientes.
			if y < 202:
				c.put(lx, ly, IRON, 1, Vector2i(r.size.x / 2, 1))
				continue
			var d := Vector2(x, y) - core
			var e := Vector2(d.x / (9.0 - k), d.y / (7.0 - k)).length()
			if e < 0.55:
				c.put(lx, ly, FIRE, 7)
			elif e < 1.0:
				c.put(lx, ly, FIRE, 5)
			else:
				# Regueros de llama tragados hacia el centro: desiguales, más largos cuanto más traga.
				var a := atan2(d.y, d.x)
				var spoke_i := posmod(int(floorf(a / TAU * 22.0)), 22)
				var reach := 7.0 + _h(spoke_i, k, 71) * (9.0 + k * 7.0)
				var fade := d.length()
				if _h(spoke_i, 3, 72) < 0.55 and fade < reach:
					c.put(lx, ly, FIRE, 4 if fade < reach * 0.5 else (3 if fade < reach * 0.8 else 2))
				else:
					_throat(c, x, y, lx, ly, MOUTH_BOTTOM + 1)
	return c.bake([])


static func _flash_frame(with_card: bool) -> Dictionary:
	var r := MOUTH_RECT
	var c := _frame_canvas(r)
	var card := Rect2i(CX - 8, 214, 16, 22)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not in_arch(x, y):
				continue
			var lx := x - r.position.x
			var ly := y - r.position.y
			var edge := not in_arch(x - 2, y) or not in_arch(x + 2, y) or not in_arch(x, y - 2)
			var v := 6 if edge else 7
			if with_card and card.has_point(Vector2i(x, y)):
				var border := x == card.position.x or x == card.end.x - 1 or y == card.position.y or y == card.end.y - 1
				v = 5 if border else 7
			c.put(lx, ly, FIRE, v)
	return c.bake([])


static func _lick_frame(lvl: int, k: int) -> Dictionary:
	var r := GAP_RECT
	var c := _frame_canvas(r)
	var tall: float = [8.0, 18.0, 30.0][lvl]
	var count: int = [2, 3, 4][lvl]
	for y in range(r.position.y, GAP_BOTTOM):
		for x in range(r.position.x, r.end.x):
			var f := _tongues(float(x - CX), float(y), float(GAP_BOTTOM + 1), tall, count, 7.0 + lvl, k, 60 + lvl)
			if f > 0.0:
				c.put(x - r.position.x, y - r.position.y, FIRE, clampi(_fire_step(f * 0.85), 1, 6))
	return c.bake([])


static func _grate_frame(k: int) -> Dictionary:
	var c := BgCanvas.new(GRATE_SIZE.x, GRATE_SIZE.y)
	_grate_box(c, 0, 0, 4, k)
	return c.bake([])
