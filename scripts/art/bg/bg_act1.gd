class_name BgAct1
extends RefCounted
## Acto 1 · HOLLÍN — «Las Salas de Fogones» a 640×360 nativos, por capas, en formato índice (BgCanvas).
## La Torre es el tiro de la Forja: cada piso es una galería alrededor del tiro central.
##   "normal": módulo de corredor de arcos (DA) fundido con el muro de taller (MV). El conducto de cobre es la
##             toma del fuelle y baja hasta la Forja grande (zona x 8–112, a la izquierda).
##   "flue":   galería con parapeto abierta al tiro (élite y jefe). El jefe sale del vacío.
## Disposición de combate (DEBATE.md): HUD 0–15 · banda de intención de jefe 22–44 · suelo y = 264 · cartas desde
## y = 296 · Forja x 8–112 · heroína x 128–196 · enemigos x 300–632.
## build() es determinista: misma (kind, floor, cycle) → mismos bytes.

const W := 640
const H := 360
const FY := 264
const M_SKY := 4
const M_FAR := 4
const M_FORE := 8

const BRICK := BgRamps.BRICK
const STONE := BgRamps.STONE
const IRON := BgRamps.IRON
const COPPER := BgRamps.COPPER
const WOOD := BgRamps.WOOD
const ASH := BgRamps.ASH
const SKY := BgRamps.SKY
const FIRE := BgRamps.FIRE
const CLOTH := BgRamps.CLOTH

## Radios de las 6 bandas de luz de un brasero de pared (art px).
const BRAZIER_R := [8.0, 16.0, 26.0, 40.0, 60.0, 88.0]

var kind := "normal"
var floor_num := 1
var cycle := 0
var room_seed := 0
var braziers: Array[Vector2i] = []
var anchors := {}
var lights: Array = []
var far_lights: Array = []


## `patches = false` omite los parches de parpadeo (sólo hacen falta sin shader).
static func build(p_kind: String, p_floor: int, p_cycle: int = 0, patches: bool = true) -> Dictionary:
	var b := BgAct1.new()
	return b._build(p_kind, p_floor, p_cycle, patches)


func h3(x: int, y: int, s: int) -> float:
	return BgCanvas.hash3(x, y, s + room_seed * 7919)


func _build(p_kind: String, p_floor: int, p_cycle: int, patches: bool = true) -> Dictionary:
	kind = p_kind
	floor_num = clampi(p_floor, 1, 9999)
	cycle = maxi(0, p_cycle)
	room_seed = floor_num * 31 + cycle * 1009 + (7 if kind == "flue" else 0)
	var local_floor := ((floor_num - 1) % 10) + 1
	if kind == "flue":
		braziers = [Vector2i(222, 150), Vector2i(618, 142)]
	else:
		braziers = [Vector2i(226, 156), Vector2i(520, 150)]
	anchors = {"braziers": braziers, "drips": [], "crucibles": [], "flue": Rect2i(), "window": Rect2i(),
		"grate": Vector2i(320, 276), "gauge": Vector2i(-1, -1), "forge_zone": Rect2i(8, 120, 104, 144)}
	lights = _static_lights()
	var mid := BgCanvas.new(W, H, 0)
	_build_mid(mid, local_floor)
	var far := BgCanvas.new(W + 2 * M_FAR, H, M_FAR)
	if kind == "flue":
		_build_shaft(far)
	else:
		_build_corridor(far)
	var sky := BgCanvas.new(W + 2 * M_SKY, H, M_SKY)
	_build_sky(sky)
	var fore := BgCanvas.new(W + 2 * M_FORE, H, M_FORE)
	_build_fore(fore)
	var out := {"kind": kind, "floor": floor_num, "cycle": cycle, "anchors": anchors, "lights": lights, "layers": []}
	var sb := sky.bake([])
	out["layers"].append({"name": "sky", "margin": M_SKY, "parallax": 1, "index": sb["index"], "preview": sb["preview"]})
	var fb := far.bake(far_lights)
	out["layers"].append({"name": "far", "margin": M_FAR, "parallax": 2, "index": fb["index"], "preview": fb["preview"]})
	var mb := mid.bake(lights)
	out["layers"].append({"name": "mid", "margin": 0, "parallax": 0, "index": mb["index"], "preview": mb["preview"]})
	var ob := fore.bake([])
	out["layers"].append({"name": "fore", "margin": M_FORE, "parallax": -4, "index": ob["index"], "preview": ob["preview"]})
	out["flicker"] = _flicker_patches(mid) if patches else []
	out["crucible_patches"] = _crucible_patches(mid) if patches else []
	return out


# --- luces estáticas (horneadas) ----------------------------------------------------------------

func _static_lights() -> Array:
	var L: Array = []
	for b: Vector2i in braziers:
		L.append(_brazier_light(b, 0))
		L.append({"t": "pt", "p": Vector2(b.x, FY + 6), "r": [20.0, 44.0, 72.0], "ys": 2.6, "y0": FY})
	# Rejilla del suelo: el calor de la Forja sube.
	L.append({"t": "pt", "p": Vector2(320, 278), "r": [16.0, 34.0, 60.0], "ys": 2.4, "y0": FY})
	if kind == "flue":
		# El tiro ilumina desde abajo el intradós, el parapeto y las mochetas.
		L.append({"t": "pt", "p": Vector2(440, 330), "r": [80.0, 116.0, 150.0], "ys": 1.0, "y1": FY - 1, "x0": 250, "x1": 630})
	else:
		# Luna por la ventana: alféizar y mancha en el suelo.
		L.append({"t": "pt", "p": Vector2(600, 176), "r": [14.0, 26.0], "ys": 2.2, "cold": true, "y0": 168, "y1": 182})
		L.append({"t": "skew", "cold": true, "ya": FY + 4, "yb": FY + 34, "xa0": 572.0, "xa1": 620.0, "xb0": 536.0, "xb1": 592.0})
		# La boca del corredor recibe algo de la luz del fondo.
		L.append({"t": "pt", "p": Vector2(320, 236), "r": [30.0, 52.0], "ys": 1.0, "y1": FY - 1, "x0": 270, "x1": 370})
	return L


func _brazier_light(b: Vector2i, flick: int) -> Dictionary:
	var rr: Array = []
	for i in BRAZIER_R.size():
		rr.append(float(BRAZIER_R[i]) + (0.0 if i == 0 else float(flick) * 3.0))
	return {"t": "pt", "p": Vector2(b.x, b.y - 12), "r": rr, "ys": 1.05, "y1": FY - 1}


# --- hollín ------------------------------------------------------------------------------------

func soot(x: int, y: int) -> int:
	var s := 0
	if y < 44:
		s = -2
	elif y < 70:
		s = -1
	for b: Vector2i in braziers:
		if y < b.y - 10 and y > 14:
			var up := b.y - 10 - y
			var wid := 4.0 + up / 9.0
			var dx := absf(x - b.x + (0.0 if up < 40 else 2.0))
			var rag := h3(x / 2, y / 5, 17) * 3.0
			if dx < wid * 0.45 + rag * 0.5:
				s = mini(s, -2)
			elif dx < wid + rag:
				s = mini(s, -1)
	return s


# --- capa media: muro + suelo -------------------------------------------------------------------

func _build_mid(c: BgCanvas, local_floor: int) -> void:
	var decay := 0.04 + local_floor * 0.006
	_build_veins()
	_bricks(c, decay)
	if kind == "flue":
		_beam(c, 0, 248, 18)
		_flue_arch(c)
		_pier(c, 248)
		_pier(c, 600)
		_parapet(c, 280, 600, local_floor)
		_plinth(c, 0, 248)
		_pipe_intake(c, 236)
		_gauge(c, 160, 69)
		_valve(c, 196, 60)
		_banner(c, 252, 42, 84, local_floor)
		anchors["flue"] = Rect2i(290, 40, 300, 168)
	else:
		_beam(c, 0, 248, 18)
		_beam(c, 392, 640, 18)
		_gothic_front(c)
		_pier(c, 248)
		_pier(c, 360)
		_plinth(c, 0, 248)
		_plinth(c, 392, 640)
		_pipe_intake(c, 236)
		_gauge(c, 160, 69)
		_valve(c, 200, 60)
		_window(c, 600, 64, 172)
		_banner(c, 252, 42, 84, local_floor)
		_banner(c, 364, 42, 84, local_floor + 3)
		_static_chain(c, 470, 18, 30)
		_static_chain(c, 636, 18, 22)
		anchors["crucibles"] = [{"pivot": Vector2i(444, 32), "len": 66}]
	# Atrezo de taller sobre la heroína (elegido por piso: herramientero o estante de crisoles).
	if h3(local_floor, 1, 5) < 0.6:
		_tool_rack(c, 130, 108)
	else:
		_crucible_shelf(c, 128, 116)
	for b: Vector2i in braziers:
		_brazier(c, b)
	_floor(c, local_floor)
	# Puntos de goteo de hollín bajo las vigas.
	var drips: Array = []
	for i in 4:
		var dx := 20 + int(h3(i, 9, 47) * 600.0)
		if kind == "flue" and dx > 240:
			dx = 20 + int(h3(i, 10, 47) * 220.0)
		if kind == "normal" and dx > 248 and dx < 392:
			dx += 150
		drips.append(Vector2i(dx, 34))
	anchors["drips"] = drips


func _bricks(c: BgCanvas, decay: float) -> void:
	for y in range(0, FY):
		var row := y / 7
		var ry := y % 7
		var off := (row % 2) * 8
		for x in W:
			var xx := x + off
			var ci := xx / 16
			var rx := xx % 16
			var s := soot(x, y)
			if ry == 0 or rx == 0:
				if _vein(x, y):
					c.put(x, y, FIRE, int(_veins[Vector2i(x, y)]))
				else:
					c.joint(x, y, BRICK, 1 + mini(0, s + 1))
				continue
			var hb := h3(ci, row, 11)
			var v := 2
			if hb < 0.14:
				v -= 1
			elif hb > 0.88:
				v += 1
			v += s
			if cycle > 0 and (_vein(x, y - 1) or _vein(x, y + 1) or _vein(x - 1, y) or _vein(x + 1, y)):
				v += 1
			var hc := h3(ci, row, 13)
			if hc < 0.22:
				var cx := 1 if hc < 0.11 else 15
				var cy := 1 if h3(ci, row, 14) < 0.5 else 6
				if absi(rx - cx) + absi(ry - cy) <= 1 + int(hc * 12.0) % 3:
					c.joint(x, y, BRICK, 1 + mini(0, s + 1))
					continue
			var anc := Vector2i(ci * 16 - off + 8, row * 7 + 3)
			if ry == 6:
				c.put(x, y, BRICK, v - 1, anc)
				continue
			if h3(x, y, 15) < 0.05:
				v -= 1
			var hk := h3(ci, row, 12)
			if hk < decay and rx == 4 + ry:
				v = 0
			# Pieza que falta (más cuanto más alto el piso del acto).
			if hk > 1.0 - decay * 0.5 and rx >= 6 and ry >= 2 and ry <= 5:
				c.joint(x, y, BRICK, 0)
				continue
			c.put(x, y, BRICK, v, anc, BgCanvas.F_BEVEL if (ry == 1 or rx == 1) and s >= -1 else 0)
	# Chorretones de hollín: el humo se condensa bajo las vigas y escurre.
	for i in 14:
		var dx := 6 + int(h3(i, 3, 47) * 628.0)
		var ln := 12 + int(h3(i, 4, 47) * 40.0)
		for y4 in range(34, 34 + ln):
			var wdt := 2 if y4 < 34 + ln * 2 / 3 else 1
			for xx2 in range(dx, dx + wdt):
				c.shift(xx2, y4, -1)


## Vetas de brasa del ciclo II+: grietas que CAMINAN por las juntas (tendel → llaga → tendel…) desde focos bajos,
## más calientes abajo. Se calculan una vez por sala (`_veins`: píxel → paso de fuego).
var _veins := {}


func _build_veins() -> void:
	_veins.clear()
	if cycle <= 0:
		return
	var foci: Array = [Vector2i(170, 241), Vector2i(470, 241), Vector2i(560, 150)]
	if cycle >= 2:
		foci.append_array([Vector2i(206, 199), Vector2i(420, 122)])
	for fi in foci.size():
		var o: Vector2i = foci[fi]
		var x := o.x
		var row := o.y / 7
		var rows := 7 + int(h3(fi, 1, 73) * 6.0) + cycle * 2
		for r in rows:
			var y := row * 7
			if y < 64:
				break
			# En reposo son rescoldos oscuros (el pulso de quemar los enciende); arriba se apagan.
			var heat := 2 if r < 2 else 1
			var dir := (-1 if h3(fi, 0, 74) < 0.5 else 1) * (-1 if h3(fi, r, 76) < 0.25 else 1)
			var run := 6 + int(pow(h3(fi, r, 75), 0.7) * 20.0)
			for i in run:
				# Tramos rotos: la veta se interrumpe (ceniza en la junta), más cuanto más sube.
				if h3(x + dir * i, y, 77) > 0.22 + float(r) / rows * 0.4:
					_veins[Vector2i(x + dir * i, y)] = heat
			x += dir * (run - 1)
			# Sube por la llaga más cercana de la hilada de arriba.
			var off := ((row - 1) % 2) * 8
			var lx := x - posmod(x + off, 16)
			if absi(lx + 16 - x) < absi(lx - x):
				lx += 16
			for i2 in range(min(x, lx), max(x, lx) + 1):
				if h3(i2, y, 78) > 0.3:
					_veins[Vector2i(i2, y)] = heat
			for yy in range(y - 6, y):
				if h3(lx, yy, 79) > 0.25:
					_veins[Vector2i(lx, yy)] = heat
			x = lx
			row -= 1


func _vein(x: int, y: int) -> bool:
	return _veins.has(Vector2i(x, y))


func _beam(c: BgCanvas, x0: int, x1: int, y0: int) -> void:
	for x in range(x0, x1):
		for y in range(y0, y0 + 16):
			var t := y - y0
			var v := 3
			if t == 0:
				v = 5
			elif t == 1:
				v = 4
			elif t >= 13:
				v = 1 if t == 15 else 2
			elif (x * 3 + y * 7) % 23 == 0 or h3(x / 9, y, 44) < 0.08:
				v = 2
			if posmod(x, 68) == 67:
				v = 1
			c.put(x, y, WOOD, v)
		var fx := posmod(x - 20, 52)
		if fx < 6:
			for y2 in range(y0, y0 + 14):
				c.put(x, y2, IRON, 4 if fx == 0 else (1 if fx == 5 else 2))
			if fx == 2 or fx == 3:
				for yr: int in [y0 + 4, y0 + 10]:
					c.put(x, yr, IRON, 7 if fx == 2 else 3)
		if h3(x, 1, 41) < 0.4:
			var ln := 1 + int(h3(x, 2, 41) * 5.0)
			for y3 in range(y0 + 16, y0 + 16 + ln):
				c.put(x, y3, ASH, 1 if y3 < y0 + 15 + ln else 2)
	for y in range(0, y0):
		for x in range(x0, x1):
			c.put(x, y, BRICK, 0)


func _pier(c: BgCanvas, x0: int) -> void:
	for y in range(28, FY):
		var course := (y - 28) / 20
		var ry := (y - 28) % 20
		var split := course % 2 == 1
		for x in range(x0, x0 + 32):
			var rx := x - x0
			if ry == 0 or (split and rx == 16):
				c.joint(x, y, STONE, 1)
				continue
			var v := 3
			if rx == 0 or rx == 31:
				v = 1
			elif rx <= 2:
				v = 4
			elif rx >= 27:
				v = 2
			if ry == 19:
				v -= 1
			elif ry == 1:
				v += 1
			if h3(course, rx / 6, 70) < 0.5 and posmod(rx + ry * 2, 7) == 0 and rx > 3 and rx < 27 and ry > 2 and ry < 18:
				v -= 1
			var bx := x0 + (8 if split and rx < 16 else (24 if split else 16))
			v += soot(x, y) / 2
			c.put(x, y, STONE, v, Vector2i(bx, 28 + course * 20 + 10), BgCanvas.F_BEVEL if ry == 1 and rx > 2 and rx < 27 else 0)
	var rows := [[6, 6], [5, 6], [4, 6], [3, 6], [6, 3], [5, 3], [3, 3], [2, 2], [1, 2], [1, 1], [0, 1]]
	for i in rows.size():
		var r: Array = rows[i]
		for x in range(x0 - int(r[1]), x0 + 32 + int(r[1])):
			var v2: int = int(r[0]) - (1 if i < 4 else 0)
			if x == x0 - int(r[1]):
				v2 += 1
			c.put(x, 28 + i, STONE, v2)
	var brows := [6, 5, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, 1]
	for i in brows.size():
		for x in range(x0 - 4, x0 + 36):
			var v3: int = brows[i]
			if x <= x0 - 3:
				v3 -= 1
			c.put(x, FY - 16 + i, STONE, v3)


## Arco apuntado de la boca del corredor (módulo normal). El interior queda vacío (lo llena la capa lejana).
func _gothic_front(c: BgCanvas) -> void:
	var spring := 150
	for y in range(40, FY):
		for x in range(268, 373):
			var st := _gothic_test(Vector2(x, y), 280.0, 360.0, float(spring), 0.0)
			if st == 0:
				c.erase(x, y)
			elif st == 1:
				# Dovelas: radiales respecto al centro del arco opuesto.
				var cc := Vector2(360.0, spring) if x < 320 else Vector2(280.0, spring)
				var a := atan2(spring - y, absf(x - cc.x))
				var si := int(a / 0.13)
				var fr := a / 0.13 - si
				if fr < 0.1 and y < spring:
					c.joint(x, y, STONE, 1)
					continue
				var d := Vector2(x - cc.x, y - spring).length()
				var v := 3 if d < 86.0 else 2
				if d < 82.0:
					v = 4
				var ac := (si + 0.5) * 0.13
				var anc := Vector2i(int(cc.x + signf(x - cc.x) * cos(ac) * 86.0), int(spring - sin(ac) * 86.0)) if y < spring else Vector2i(x, y)
				c.put(x, y, STONE, v + soot(x, y) / 2, anc, BgCanvas.F_BEVEL if d < 82.0 else 0)
	# Clave.
	for y in range(62, 84):
		for x in range(314, 327):
			if absi(x - 320) <= 6 - (y - 62) / 5 + 2:
				c.put(x, y, STONE, 4 if x < 320 else 3, Vector2i(320, 72), 0)
	for x in range(314, 327):
		c.joint(x, 62, STONE, 1)


## 0 = hueco, 1 = anillo de dovelas (12 px), 2 = fuera. Arco apuntado entre xl y xr con arranque en `spring`.
func _gothic_test(p: Vector2, xl: float, xr: float, spring: float, shrink: float) -> int:
	var span := xr - xl
	var ring := 12.0
	if p.y >= spring:
		if p.x > xl + shrink and p.x < xr - shrink:
			return 0
		if p.x > xl - ring and p.x < xr + ring:
			return 1 if p.y < FY - 16 else 2
		return 2
	var dl := Vector2(p.x - xr, p.y - spring).length()
	var dr := Vector2(p.x - xl, p.y - spring).length()
	var inside := dl < span - shrink and dr < span - shrink
	if inside:
		return 0
	var inside_ring := dl < span + ring and dr < span + ring
	return 1 if inside_ring and absf(p.x - (xl + xr) * 0.5) < span * 0.5 + ring else 2


## Gran arco escarzano al tiro (módulo de tiro).
func _flue_arch(c: BgCanvas) -> void:
	var cen := Vector2(440, 150)
	var rx := 160.0
	var ry := 112.0
	for y in range(20, FY):
		for x in range(262, 620):
			var e := Vector2((x - cen.x) / rx, (y - cen.y) / ry).length()
			if y >= cen.y:
				if x >= 280 and x < 600:
					c.erase(x, y)
				continue
			if e < 1.0:
				c.erase(x, y)
			elif e < 1.12:
				var a := atan2(cen.y - y, (x - cen.x) / rx * ry)
				var segs := 21
				var si := int(a / (PI / segs))
				var fr := a / (PI / segs) - si
				var key := si == segs / 2
				if (fr < 0.07 or fr > 0.97) and not key:
					c.joint(x, y, STONE, 1)
					continue
				var ac := (si + 0.5) * PI / segs
				var v := 3 if not key else 4
				if e > 1.1:
					v -= 2
				elif e < 1.02:
					v += 1
				if h3(si, int(e * 60.0), 72) < 0.12:
					v -= 1
				var anc := Vector2i(int(cen.x + cos(ac) * rx * 1.06), int(cen.y - sin(ac) * ry * 1.06))
				c.put(x, y, STONE, v + soot(x, y) / 2, anc, BgCanvas.F_BEVEL if e < 1.02 else 0)
	# Intradós (cara inferior del arco, iluminada desde el tiro).
	for y in range(40, 150):
		for x in range(280, 600):
			var e2 := Vector2((x - cen.x) / rx, (y - cen.y) / ry).length()
			if e2 >= 0.965 and e2 < 1.0 and y > 70:
				c.put(x, y, STONE, 2 if e2 < 0.985 else 1)
	for y in range(100, FY - 32):
		for i in 4:
			c.put(280 + i, y, STONE, [2, 2, 1, 0][i])
			c.put(599 - i, y, STONE, [2, 2, 1, 0][i])


func _parapet(c: BgCanvas, x0: int, x1: int, local_floor: int) -> void:
	var broken := local_floor >= 8
	for x in range(x0, x1):
		var gap := broken and x > 486 and x < 504
		for t in 5:
			c.put(x, FY - 32 + t, STONE, [6, 5, 4, 1, 0][t])
		for y in range(FY - 27, FY):
			var bi := (x - x0) / 28
			if posmod(x - x0, 28) == 0 or y == FY - 16:
				c.joint(x, y, STONE, 1)
			else:
				c.put(x, y, STONE, 3 if y < FY - 16 else 2, Vector2i(x0 + bi * 28 + 14, FY - 20))
		if gap:
			continue
		c.put(x, FY - 58, IRON, 4)
		c.put(x, FY - 57, IRON, 3)
		c.put(x, FY - 56, IRON, 1)
		c.put(x, FY - 42, IRON, 2)
		c.put(x, FY - 41, IRON, 1)
		var pp := posmod(x - x0 - 4, 14)
		if pp < 2:
			for y in range(FY - 55, FY - 32):
				c.put(x, y, IRON, (3 if pp == 0 else 1) if y < FY - 44 else (2 if pp == 0 else 0))
		elif pp == 7:
			for y in range(FY - 53, FY - 44):
				if y % 2 == 0:
					c.put(x, y, IRON, 1)
	if broken:
		# Barandilla doblada hacia el vacío.
		for i in 8:
			c.put(486 + i, FY - 58 + i / 2, IRON, 3)
			c.put(504 - i, FY - 58 + i / 3, IRON, 2)


func _plinth(c: BgCanvas, x0: int, x1: int) -> void:
	for x in range(x0, x1):
		for y in range(FY - 16, FY):
			var t := y - (FY - 16)
			var v := 2
			if t == 0:
				v = 5
			elif t == 1:
				v = 4
			elif t == 2:
				v = 3
			elif t >= 14:
				v = 1
			if posmod(x, 44) == 0 and t > 1:
				c.joint(x, y, STONE, 1)
				continue
			c.put(x, y, STONE, v, Vector2i(x / 44 * 44 + 22, FY - 8))
	var n := 3 + int(h3(x0, 2, 55) * 3.0)
	for i in n:
		var mx := x0 + 14 + int(h3(i, x0, 55) * float(x1 - x0 - 28))
		if mx < 116 and x0 == 0:
			mx = 116 + int(h3(i, 7, 55) * 100.0)
		var mw := 8 + int(h3(i, x0 + 1, 56) * 10.0)
		for dx in range(-mw, mw + 1):
			var hh := int((1.0 - pow(float(dx) / mw, 2.0)) * (3.0 + mw * 0.4))
			for dy in range(0, hh + 1):
				var v2 := 4 if dy == hh else (3 if dx < -mw / 3 else 2)
				if dy < hh and h3(mx + dx, dy, 57) < 0.1:
					v2 = 1
				c.put(mx + dx, FY - 1 - dy, ASH, v2 + 1)


## Toma del fuelle: viene del muro de la derecha y baja a la Forja grande (lado derecho de la zona 8–112).
func _pipe_intake(c: BgCanvas, x_end: int) -> void:
	var prof := [1, 3, 5, 8, 6, 5, 4, 3, 2, 1]
	var py := 64
	var vx := 100
	for x in range(vx, x_end):
		for i in 10:
			c.put(x, py + i, COPPER, prof[i])
		if h3(x / 3, 0, 81) < 0.45:
			c.put(x, py, ASH, 1)
			c.put(x, py + 1, COPPER, 2)
		if posmod(x, 22) == 11:
			for i2 in range(1, 9):
				c.put(x, py + i2, COPPER, maxi(1, int(prof[i2]) - 2))
		if posmod(x, 22) == 12:
			c.put(x, py + 3, COPPER, 9)
		c.put(x, py + 8, COPPER, 4 if posmod(x, 5) != 0 else 3)
	for y in range(py, 200):
		for i in 10:
			var v: int = prof[i]
			if y < py + 10:
				v = maxi(v, 3)
			c.put(vx + i, y, COPPER, v)
	for dy in 10:
		for dx in 10:
			if dx + dy >= 13:
				c.put(vx + dx, py + dy, COPPER, 1)
			elif dx + dy == 12:
				c.put(vx + dx, py + dy, COPPER, 3)
	for fx0: int in [150 - 6, x_end - 30]:
		for x in range(fx0, fx0 + 4):
			for y in range(py - 3, py + 13):
				c.put(x, y, IRON, 5 if x == fx0 else (4 if x == fx0 + 1 else (2 if x == fx0 + 2 else 1)))
		for yb: int in [py - 2, py + 11]:
			c.put(fx0 + 1, yb, IRON, 7)
			c.put(fx0 + 2, yb, IRON, 3)
	for fy0: int in [110, 160]:
		for y in range(fy0, fy0 + 4):
			for x in range(vx - 3, vx + 13):
				c.put(x, y, IRON, 5 if y == fy0 else (4 if y == fy0 + 1 else (2 if y == fy0 + 2 else 1)))
		for xb: int in [vx - 2, vx + 11]:
			c.put(xb, fy0 + 1, IRON, 7)
	for axx: int in [124, 214]:
		for y in range(py - 2, py + 14):
			c.shift(axx + 3, y + 2, -2)
			c.put(axx, y, IRON, 3)
			c.put(axx + 1, y, IRON, 2)
	# Boca de la toma: brida grande donde el conducto entra en el muro (el fuelle está detrás).
	for y in range(py - 6, py + 16):
		for x in range(x_end, x_end + 8):
			var v4 := 3
			if y == py - 6 or x == x_end:
				v4 = 5
			elif y == py + 15 or x == x_end + 7:
				v4 = 1
			c.put(x, y, IRON, v4)
	for p: Vector2i in [Vector2i(x_end + 2, py - 4), Vector2i(x_end + 5, py - 4), Vector2i(x_end + 2, py + 13), Vector2i(x_end + 5, py + 13)]:
		c.put(p.x, p.y, IRON, 7)


## Manómetro del fuelle: la esfera se hornea; la AGUJA la dibuja el ambiente según el calor.
func _gauge(c: BgCanvas, gx: int, py: int) -> void:
	var cy := py - 12
	for y in range(cy + 6, py):
		c.put(gx, y, IRON, 3)
		c.put(gx + 1, y, IRON, 1)
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var d := Vector2(dx, dy).length()
			if d > 8.4:
				continue
			if d > 6.5:
				c.put(gx + dx, cy + dy, COPPER, 7 if dx + dy < -3 else (4 if dx + dy < 4 else 2))
			else:
				c.put(gx + dx, cy + dy, ASH, 9 if dx + dy < 0 else 8)
	for a in 7:
		var ang := PI * 0.8 + a * PI * 1.4 / 6.0
		var tx := gx + int(roundf(cos(ang) * 5.0))
		var ty := cy + int(roundf(sin(ang) * 5.0))
		c.put(tx, ty, ASH, 3 if a < 5 else 0)
	c.put(gx + 4, cy - 3, FIRE, 3)
	c.put(gx + 5, cy - 2, FIRE, 3)
	c.put(gx, cy, IRON, 1)
	anchors["gauge"] = Vector2i(gx, cy)


func _valve(c: BgCanvas, vx: int, vy: int) -> void:
	for y in range(vy, vy + 5):
		c.put(vx, y, IRON, 2)
	var cy := vy - 4
	for a in 64:
		var ang := a * TAU / 64.0
		for rr: float in [7.5, 8.5]:
			var v := 5 if sin(ang) < -0.3 else (3 if cos(ang) < 0 else 2)
			if rr > 8.0:
				v -= 1
			c.put(vx + int(roundf(cos(ang) * rr)), cy + int(roundf(sin(ang) * rr * 0.9)), IRON, v)
	for d in range(-7, 8):
		c.put(vx + d, cy, IRON, 3)
		c.put(vx, cy + int(d * 0.9), IRON, 3)
	c.put(vx, cy, COPPER, 7)
	c.put(vx + 1, cy, COPPER, 4)


func _tool_rack(c: BgCanvas, x0: int, y0: int) -> void:
	for x in range(x0, x0 + 66):
		c.put(x, y0, WOOD, 6)
		c.put(x, y0 + 1, WOOD, 5 if h3(x / 5, 0, 3) < 0.7 else 4)
		c.put(x, y0 + 2, WOOD, 3)
		c.put(x, y0 + 3, WOOD, 1)
	for pg: int in [x0 + 2, x0 + 63]:
		for y in range(y0 - 2, y0 + 6):
			c.put(pg, y, IRON, 4 if y < y0 else 2)
	var t: Array = []
	var bx := x0 + 9
	for y in range(y0 + 4, y0 + 30):
		var sp := 0 if y < y0 + 18 else (y - y0 - 18) / 3
		t.append([bx - sp, y, IRON, 5])
		t.append([bx + 1 - sp, y, IRON, 3])
		t.append([bx + 3 + sp, y, IRON, 3])
		t.append([bx + 4 + sp, y, IRON, 1])
	t.append([bx + 1, y0 + 17, IRON, 7])
	t.append([bx + 2, y0 + 17, IRON, 4])
	var hx := x0 + 27
	for y in range(y0 + 4, y0 + 28):
		t.append([hx, y, WOOD, 6])
		t.append([hx + 1, y, WOOD, 4])
		t.append([hx + 2, y, WOOD, 2])
	for y in range(y0 + 26, y0 + 34):
		for x in range(hx - 6, hx + 9):
			var v := 4
			if y == y0 + 26:
				v = 6
			elif y == y0 + 33:
				v = 1
			elif x == hx - 6:
				v = 5
			elif x >= hx + 7:
				v = 2
			t.append([x, y, IRON, v])
	var lx := x0 + 44
	for y in range(y0 + 4, y0 + 24):
		t.append([lx, y, IRON, 4])
		t.append([lx + 1, y, IRON, 2])
	for i in 7:
		var hw := 7 - i / 2
		for x in range(lx + 1 - hw, lx + 2 + hw):
			var v2 := 2
			if i == 0:
				v2 = 5
			elif x <= lx + 1 - hw + 1:
				v2 = 4
			elif x >= lx + 1 + hw - 1:
				v2 = 1
			t.append([x, y0 + 24 + i, IRON, v2])
	for a in 20:
		var ang := PI * 0.15 + a * PI * 1.7 / 20.0 + PI * 0.5
		t.append([x0 + 58 + int(roundf(cos(ang) * 5.0)), y0 + 12 + int(roundf(sin(ang) * 6.0)), IRON, 4 if a < 10 else 2])
	for e: Array in t:
		c.shift(int(e[0]) - 2, int(e[1]) - 2, -2)
	for e: Array in t:
		c.put(int(e[0]), int(e[1]), int(e[2]), int(e[3]))


func _crucible_shelf(c: BgCanvas, x0: int, y0: int) -> void:
	for x in range(x0, x0 + 70):
		c.put(x, y0, WOOD, 6)
		c.put(x, y0 + 1, WOOD, 4)
		c.put(x, y0 + 2, WOOD, 3)
		c.put(x, y0 + 3, WOOD, 1)
		c.shift(x, y0 + 4, -2)
		c.shift(x, y0 + 5, -1)
	for bx: int in [x0 + 6, x0 + 62]:
		for i in 10:
			c.put(bx + (i / 3 if bx < x0 + 30 else -i / 3), y0 + 4 + i, IRON, 2)
	var sizes := [[x0 + 10, 7, 10], [x0 + 26, 5, 8], [x0 + 40, 8, 12], [x0 + 56, 4, 6]]
	for s: Array in sizes:
		var cx: int = s[0]
		var hw: int = s[1]
		var hh: int = s[2]
		for y in range(y0 - hh, y0):
			var tt := float(y0 - y) / hh
			var w := int(roundf(hw * (0.7 + 0.3 * tt)))
			for x in range(cx - w, cx + w + 1):
				var v := 3
				if x <= cx - w + 1:
					v = 5
				elif x >= cx + w - 1:
					v = 1
				if y == y0 - hh:
					v = 6
				c.put(x, y, ASH, v)
		c.put(cx - 1, y0 - hh, ASH, 1)
		c.put(cx, y0 - hh, ASH, 1)


func _brazier(c: BgCanvas, b: Vector2i) -> void:
	for y in range(b.y + 6, b.y + 28):
		for x in range(-5, 6):
			c.shift(b.x + x, y, -1)
	for y in range(b.y + 6, b.y + 26):
		c.fixed(b.x - 2, y, IRON, 3)
		c.fixed(b.x - 1, y, IRON, 2)
		c.fixed(b.x, y, IRON, 2)
		c.fixed(b.x + 1, y, IRON, 1)
	c.fixed(b.x - 1, b.y + 9, IRON, 6)
	c.fixed(b.x - 1, b.y + 22, IRON, 6)
	for i in 10:
		c.fixed(b.x - 6 + i, b.y + 18 - i, IRON, 2)
		c.fixed(b.x - 6 + i, b.y + 19 - i, IRON, 1)
	for p: Vector2i in [Vector2i(-7, 18), Vector2i(-8, 17), Vector2i(-8, 16), Vector2i(-7, 15), Vector2i(-6, 16)]:
		c.fixed(b.x + p.x, b.y + p.y, IRON, 2)
	var rows := [[11, 7], [11, 6], [10, 3], [9, 3], [8, 2], [7, 2], [5, 1], [3, 1]]
	for i in rows.size():
		var hw: int = rows[i][0]
		for x in range(-hw, hw + 1):
			var v: int = rows[i][1]
			if i >= 2:
				if x <= -hw + 1:
					v += 1
				elif x >= hw - 2:
					v -= 1
				if i == 2 and absi(x) < hw - 1:
					v = 1
			c.fixed(b.x + x, b.y - 2 + i, IRON, v)
	for x in range(-9, 10):
		for y in range(-4, -1):
			if y == -4 and absi(x) > 6:
				continue
			var lump := h3((x + 20) / 3, y, 61)
			var v2 := 3 if lump < 0.3 else (5 if lump > 0.8 else 4)
			if posmod(x, 3) == 0 and y == -2:
				v2 = 2
			c.put(b.x + x, b.y + y, FIRE, v2)


func _window(c: BgCanvas, wx: int, top: int, bottom: int) -> void:
	var half := 18
	var cy := top + half
	for y in range(top - 6, bottom):
		for x in range(wx - half - 8, wx + half + 9):
			var dx := float(x - wx)
			if y < cy:
				var d := Vector2(dx, y - cy).length()
				if d < half:
					c.erase(x, y)
				elif d < half + 7:
					var a := atan2(cy - y, dx)
					var si := int(a / (PI / 9.0))
					if a / (PI / 9.0) - si < 0.1:
						c.joint(x, y, STONE, 1)
						continue
					var ac := (si + 0.5) * PI / 9.0
					c.put(x, y, STONE, 3 if d < half + 2 else (2 if d < half + 5 else 1), Vector2i(int(wx + cos(ac) * (half + 3)), int(cy - sin(ac) * (half + 3))), BgCanvas.F_BEVEL if d < half + 1.5 else 0)
			else:
				var adx := absf(dx)
				if adx < half:
					c.erase(x, y)
				elif adx < half + 7:
					var course := (y - cy) / 12
					var deep := float(half + 7) if course % 2 == 0 else float(half + 5)
					if adx >= deep:
						continue
					if (y - cy) % 12 == 0:
						c.joint(x, y, STONE, 1)
						continue
					c.put(x, y, STONE, 3 if adx < half + 2 else 2, Vector2i(int(wx + signf(dx) * (half + 3)), cy + course * 12 + 6), BgCanvas.F_BEVEL if adx < half + 1 else 0)
	# Parteluz y travesaños; vidrieras emplomadas en rombo (sólo el plomo).
	for y in range(top + 2, bottom):
		c.put(wx, y, IRON, 1)
		c.put(wx + 1, y, IRON, 0)
	for yy: int in [cy + 22, cy + 58]:
		for x in range(wx - half, wx + half):
			c.put(x, yy, IRON, 1)
	for y in range(top, bottom):
		for x in range(wx - half + 1, wx + half):
			if x == wx or x == wx + 1:
				continue
			var inside := y >= cy or Vector2(x - wx, y - cy).length() < half - 1
			if inside and (posmod(x - wx + (y - top), 12) == 0 or posmod(x - wx - (y - top), 12) == 0):
				c.put(x, y, IRON, 0)
	for p: Vector2i in [Vector2i(-17, -2), Vector2i(-16, -2), Vector2i(-17, -3), Vector2i(16, -2), Vector2i(15, -2), Vector2i(-2, -40), Vector2i(3, -60)]:
		c.put(wx + p.x, bottom + p.y, SKY, 8)
	var sill := [5, 4, 2, 1, 0]
	for i in 5:
		for x in range(wx - half - 8, wx + half + 9):
			c.put(x, bottom + i, STONE, sill[i])
	for x in range(wx - half - 4, wx + half + 5):
		var hh := 1 + int(h3(x, 0, 61) * 2.2) - (1 if absi(x - wx) > half else 0)
		for y in range(bottom - hh, bottom):
			c.put(x, y, SKY, 9 if y == bottom - hh else 8)
	anchors["window"] = Rect2i(wx - half, top, half * 2, bottom - top)


## Estandarte tejido (paño + emblema martillo-llama bordado). Más deshilachado cuanto más alto el piso.
func _banner(c: BgCanvas, bx: int, top: int, ln: int, local_floor: int) -> void:
	var bw := 24
	for x in range(bx - 2, bx + bw + 2):
		c.put(x, top - 2, WOOD, 5)
		c.put(x, top - 1, WOOD, 2)
	c.put(bx - 3, top - 2, IRON, 5)
	c.put(bx + bw + 2, top - 2, IRON, 5)
	var tat := 2 + local_floor
	for x in range(bx, bx + bw):
		var rx := x - bx
		var cut := ln - int(absf(rx - bw * 0.5) * 0.8)
		cut -= int(h3(rx, local_floor, 91) * tat)
		for y in range(top, top + cut):
			var ry := y - top
			var v := 4
			if rx <= 1:
				v = 6
			elif rx >= bw - 3:
				v = 2
			elif posmod(rx, 6) == 3:
				v = 3
			if ry < 3:
				v -= 1
			# Hollín en el tercio superior.
			if ry < ln / 4:
				v -= 1
			c.put(x, y, CLOTH, v, Vector2i(bx + bw / 2, top + ry / 12 * 12 + 6))
	# Emblema bordado: martillo cruzado con llama (hilo de cobre).
	var ex := bx + bw / 2
	var ey := top + 34
	for i in range(-7, 8):
		c.put(ex + i / 2, ey + i, COPPER, 6)
	for x in range(ex - 6, ex + 1):
		for y in range(ey - 8, ey - 4):
			c.put(x, y, COPPER, 7 if y == ey - 8 else 5)
	var flame := [Vector2i(3, -9), Vector2i(2, -8), Vector2i(3, -8), Vector2i(4, -7), Vector2i(2, -7), Vector2i(3, -7), Vector2i(1, -6),
		Vector2i(2, -6), Vector2i(3, -6), Vector2i(4, -6), Vector2i(5, -5), Vector2i(1, -5), Vector2i(2, -5), Vector2i(3, -5), Vector2i(4, -5)]
	for p: Vector2i in flame:
		c.put(ex + p.x, ey + p.y + 2, COPPER, 9 if p.y < -7 else 8)
	for x in range(ex - 9, ex + 10):
		c.put(x, ey + 12, COPPER, 5)


func _static_chain(c: BgCanvas, cx: int, y0: int, ln: int) -> void:
	for y in range(y0 + 16, y0 + 16 + ln):
		var ph := (y - y0) % 10
		if ph < 7:
			if ph == 0 or ph == 6:
				c.put(cx, y, IRON, 2)
			else:
				c.put(cx - 1, y, IRON, 3)
				c.put(cx + 1, y, IRON, 1)
		else:
			c.put(cx, y, IRON, 2)


func _floor(c: BgCanvas, local_floor: int) -> void:
	var vy := float(FY - 48)
	for y in range(FY, H):
		var depth := (H - vy) / (float(y) - vy)
		var rowf := depth * 1.4
		var nxt := (H - vy) / (float(y + 1) - vy) * 1.4
		var prv := (H - vy) / (float(y - 1) - vy) * 1.4
		var hline := int(rowf) != int(nxt)
		var ri := int(rowf)
		for x in W:
			var u := (x - 320.0) * depth / 2.0 + 22.0
			var ci := int(floor(u / 44.0))
			var vline := fposmod(u, 44.0) < depth * 0.6
			var dc := (ri + 0.5) / 1.4
			var yc := int(vy + (H - vy) / dc)
			var xc := int(320.0 + ((ci + 0.5) * 44.0 - 22.0) * 2.0 / dc)
			if y == FY or y == FY + 1:
				c.put(x, y, STONE, 5 if y == FY else 4)
				continue
			if y == FY + 2 or y == FY + 3:
				c.joint(x, y, STONE, 1)
				continue
			if hline or vline:
				c.joint(x, y, STONE, 0 if y > 320 else 1)
				continue
			var v := 2 if h3(ci, ri, 21) < 0.6 else 1
			if int(prv) != ri:
				v += 1
			if y > 300:
				v -= 1
			if y > 330:
				v -= 1
			var blot := h3(x / 10, y / 4, 25) < 0.16
			if blot and h3(x, y, 23) < 0.12 and y < 320:
				c.put(x, y, ASH, 0)
				continue
			if h3(x, y, 24) < 0.0015 and absi(x - 320) < 160 and y < 296:
				c.put(x, y, FIRE, 3)
				continue
			c.put(x, y, STONE, v, Vector2i(xc, clampi(yc, FY, H - 1)))
	# Rejilla: el calor de la Forja sube por ella (el ambiente la aviva con la producción).
	for y in range(FY + 6, FY + 20):
		var hw := 18 + (y - FY - 6) * 2
		for x in range(320 - hw, 320 + hw + 1):
			var edge := absi(x - 320) >= hw - 1 or y <= FY + 7 or y >= FY + 18
			if edge:
				c.put(x, y, IRON, 4 if y == FY + 6 else (2 if y == FY + 7 else 1))
			elif posmod(x - 320, 5) < 2 or y == FY + 12 or y == FY + 13:
				c.put(x, y, IRON, 2 if posmod(x - 320, 5) == 0 else 1)
			else:
				var core := absi(x - 320) < hw / 2 and y > FY + 9 and y < FY + 16
				c.put(x, y, FIRE, 3 + (1 if core else 0) - (1 if absi(x - 320) > hw - 6 else 0))
	# Cascotes: el deterioro crece con el piso del acto.
	for i in local_floor:
		var rx := 130 + int(h3(i, 5, 99) * 480.0)
		if absi(rx - 320) < 50:
			continue
		var ry := FY + 6 + int(h3(i, 6, 99) * 18.0)
		for dx in 7:
			c.put(rx + dx, ry, BRICK, 6 if dx < 3 else 5)
			c.put(rx + dx, ry + 1, BRICK, 4)
			c.put(rx + dx, ry + 2, BRICK, 3)
		for dx2 in range(1, 7):
			c.put(rx + dx2 + 1, ry + 3, STONE, 0)


# --- capa lejana: corredor (normal) ---------------------------------------------------------------

func _build_corridor(c: BgCanvas) -> void:
	var V := Vector2(320, 214)
	var N := 6
	far_lights = [{"t": "pt", "p": Vector2(320, 232), "r": [10.0, 22.0, 38.0, 58.0, 84.0], "ys": 1.25}]
	for y in range(60, FY + 2):
		for x in range(272, 369):
			# Arco más profundo que contiene el punto.
			# Sólo dentro de la boca del arco frontal.
			if _gothic_test(Vector2(x, y), 280.0, 360.0, 150.0, 0.0) != 0:
				continue
			var kin := 0
			var ring := false
			for k in range(1, N + 1):
				var s := pow(0.74, k)
				var q := V + (Vector2(x, y) - V) / s
				var st := _gothic_test(q, 280.0, 360.0, 150.0, 0.0)
				if st == 0:
					kin = k
					ring = false
				elif st == 1 and kin == k - 1:
					ring = true
					kin = k
					break
				else:
					break
			var s2 := pow(0.74, kin)
			var floor_y := V.y + (FY - V.y) * s2
			if kin == N and not ring:
				_corridor_end(c, x, y)
				continue
			if ring:
				var v := 2 + kin / 2
				c.put(x, y, STONE, v, Vector2i(x / 3 * 3, y / 3 * 3))
				continue
			# Entre arcos: suelo con peldaños si está bajo la línea de suelo, bóveda/muros si no.
			var s_next := pow(0.74, kin + 1)
			var floor_next := V.y + (FY - V.y) * s_next
			if y >= floor_next:
				var steps := int((y - floor_next) / maxf(1.0, (floor_y - floor_next) / 3.0))
				var v2 := 1 + kin / 2
				var tread := posmod(int(y - floor_next), maxi(2, int((floor_y - floor_next) / 3.0))) == 0
				c.put(x, y, STONE, v2 + (1 if tread else 0), Vector2i(320, int(floor_next) + steps * 3))
			else:
				var bs := maxi(2, int(7.0 * s2))
				var bw := maxi(4, int(16.0 * s2))
				var row := int(y) / bs
				var off := (row % 2) * (bw / 2)
				var joint := int(y) % bs == 0 or posmod(x + off, bw) == 0
				var vv := kin / 3
				if joint:
					c.joint(x, y, BRICK, vv)
				else:
					c.put(x, y, BRICK, vv + 1, Vector2i(x, y))


## Fondo del corredor: escalera de caracol que sube, iluminada desde el tiro.
func _corridor_end(c: BgCanvas, x: int, y: int) -> void:
	var cx := 320
	var dx := x - cx
	if y > 226:
		var stp := (y - 226) / 3
		var lip := (y - 226) % 3 == 0
		c.put(x, y, STONE, 4 + (1 if lip else 0) - stp / 3, Vector2i(cx, 226 + stp * 3))
		return
	if absi(dx) < 5 and y > 204:
		c.put(x, y, FIRE, 4 if y > 214 else 3)
		return
	if absi(dx) < 6 and y > 202:
		c.put(x, y, STONE, 2)
		return
	c.put(x, y, BRICK, 1, Vector2i(x, y))


# --- capa lejana: el tiro (módulo de tiro) -----------------------------------------------------

func _build_shaft(c: BgCanvas) -> void:
	var R := 220.0
	var cx := 440.0
	far_lights = [{"t": "pt", "p": Vector2(440, 330), "r": [74.0, 108.0, 146.0, 196.0, 260.0], "ys": 1.2}]
	for y in range(0, FY + 4):
		for x in range(270, 612):
			var dx := clampf((x - cx) / R, -0.98, 0.98)
			var th := asin(dx)
			var row := y / 4
			var ry := y % 4
			var cc := th / (PI * 0.5) * 60.0 + 0.5 * (row % 2)
			var fr := fposmod(cc, 1.0)
			var mortar := ry == 0 or fr < 0.12 / maxf(0.4, cos(th))
			var v := 1
			if absf(dx) > 0.7:
				v -= 1
			var rib := false
			for rth: float in [-0.9, -0.3, 0.3, 0.9]:
				var rxx := cx + sin(rth) * R
				var rw := 7.0 * cos(rth) + 1.0
				if absf(x - rxx) < rw:
					rib = true
					# Nervio: canto izquierdo claro, cara media, sombra derecha (lee el cilindro).
					v = 2 if x < rxx - rw * 0.55 else (0 if x > rxx + rw * 0.45 else 1)
			if rib:
				if y % 16 == 0:
					c.joint(x, y, STONE, 0)
				else:
					c.put(x, y, STONE, v, Vector2i(x, y / 16 * 16 + 8))
				continue
			if mortar:
				c.joint(x, y, BRICK, v - 1)
			else:
				if h3(int(floorf(cc)), row, 33) < 0.15:
					v -= 1
				c.put(x, y, BRICK, v)
	# Ventanas de otras galerías (las encendidas son pisos donde el fuego ya llega).
	var wins := [Vector3i(318, 70, 1), Vector3i(352, 112, 0), Vector3i(512, 96, 1), Vector3i(300, 176, 0), Vector3i(334, 168, 1),
		Vector3i(470, 60, 0), Vector3i(560, 150, 1), Vector3i(410, 40, 1)]
	for wv: Vector3i in wins:
		for dy in range(-1, 8):
			for dx2 in range(0, 4):
				if dy == -1 and (dx2 == 0 or dx2 == 3):
					continue
				if wv.z == 1:
					c.put(wv.x + dx2, wv.y + dy, FIRE, 2 if dy < 1 else (3 if dx2 < 2 else 2))
				else:
					c.fixed(wv.x + dx2, wv.y + dy, BRICK, 0)
		for dx3 in range(-1, 5):
			c.put(wv.x + dx3, wv.y + 8, STONE, 3)
		if wv.z == 1:
			far_lights.append({"t": "pt", "p": Vector2(wv.x + 2, wv.y + 5), "r": [5.0, 10.0], "ys": 1.0})
	# Dos pasarelas cruzando el tiro.
	for py: int in [128, 54]:
		for x in range(270, 612):
			c.put(x, py - 12, IRON, 3)
			for y in range(py, py + 3):
				c.put(x, y, IRON, 3 if y == py else (2 if y == py + 1 else 1))
			c.put(x, py + 18, IRON, 1)
			c.put(x, py + 19, IRON, 0)
			for yy in range(py + 3, py + 18):
				var t := yy - py - 3
				if posmod(x + t, 24) == 0 or posmod(x - t, 24) == 0:
					c.put(x, yy, IRON, 1)
			if posmod(x, 24) == 0:
				for yy2 in range(py - 11, py):
					c.put(x, yy2, IRON, 1)
	# La gran cadena con el caldero de colada.
	var chx := 520
	for y in range(0, 176):
		var ph := y % 22
		if ph < 13:
			if ph < 2 or ph > 10:
				c.put(chx, y, IRON, 2)
				c.put(chx + 1, y, IRON, 1)
			else:
				c.put(chx - 2, y, IRON, 3)
				c.put(chx - 1, y, IRON, 2)
				c.put(chx + 2, y, IRON, 1)
				c.put(chx + 3, y, IRON, 0)
		else:
			c.put(chx, y, IRON, 3)
			c.put(chx + 1, y, IRON, 1)
	for i in 11:
		c.put(chx - i, 176 + i, IRON, 2)
		c.put(chx + 1 + i, 176 + i, IRON, 1)
	var prof := [14, 14, 14, 14, 14, 13, 13, 12, 12, 11, 10, 9, 8, 6, 4]
	for i in prof.size():
		var hw: int = prof[i]
		for dx5 in range(-hw, hw + 1):
			var v2 := 2
			if dx5 <= -hw + 2:
				v2 = 4
			elif dx5 >= hw - 2:
				v2 = 1
			if i <= 1:
				v2 = 5 if i == 0 else 3
			c.put(chx + dx5, 188 + i, COPPER, v2)
	for dx6 in range(-12, 13):
		c.put(chx + dx6, 189, FIRE, 4 if absi(dx6) < 8 else 3)


# --- exterior y primer plano ---------------------------------------------------------------------

func _build_sky(c: BgCanvas) -> void:
	for y in H:
		for x in range(-M_SKY, W + M_SKY):
			var v := 1 + mini(3, int(float(y) / 40.0))
			var dm := Vector2(x - 590, y - 92).length()
			if dm < 16.0:
				v += 1
			if dm < 24.0:
				v += 1
			if y < 120 and h3(x, y, 91) < 0.006:
				v = 7 if h3(x, y, 92) < 0.5 else 8
			c.put(x, y, SKY, v)
	for dy in range(-9, 10):
		for dx in range(-9, 10):
			if dx * dx + dy * dy <= 72 and (dx + 4) * (dx + 4) + (dy + 2) * (dy + 2) > 52:
				c.put(590 + dx, 92 + dy, SKY, 10 if dx < 1 else 9)
	for x in range(-M_SKY, W + M_SKY):
		var ridge := int(124.0 + 8.0 * sin(x * 0.025) + 5.0 * sin(x * 0.07 + 1.0) + 3.0 * sin(x * 0.16))
		for y in range(ridge, H):
			c.put(x, y, SKY, 3 if y > ridge else 6)
	var x0 := -M_SKY
	var n := 0
	while x0 < W + M_SKY:
		var bw := 12 + int(h3(n, 3, 7) * 14.0)
		var top := 138 + int(h3(n, 4, 7) * 14.0)
		var roof := 4 + int(h3(n, 5, 7) * 7.0)
		for x in range(x0, x0 + bw):
			var rx := mini(x - x0, x0 + bw - 1 - x)
			var ry := top - mini(roof, rx)
			for y in range(ry, H):
				var v := 1
				if y == ry:
					v = 8
				elif y == ry + 1 and rx < roof:
					v = 7
				c.put(x, y, SKY, v)
		if h3(n, 9, 7) < 0.45:
			var chx := x0 + 2 + int(h3(n, 10, 7) * (bw - 6))
			var cty := top - roof - 4
			for y in range(cty, top):
				for d in 3:
					c.put(chx + d, y, SKY, 1)
			for d2 in 3:
				c.put(chx + d2, cty, SKY, 8)
		if n % 5 == 3:
			for d3 in 2:
				c.put(x0 + bw / 2 + d3, top + 6, FIRE, 4 + d3)
				c.put(x0 + bw / 2 + d3, top + 7, FIRE, 3)
		x0 += bw
		n += 1


func _build_fore(c: BgCanvas) -> void:
	for i in range(0, 64):
		for t in 9:
			var y := 52 - i + t
			c.fixed(i - 8, y, WOOD, 1 if t > 0 and t < 8 else 0)
	for x in range(-8, 60):
		for y in range(0, 8):
			c.fixed(x, y, WOOD, 0)
	var pc := Vector2i(W - 22, 10)
	for dy in range(-12, 13):
		for dx in range(-12, 13):
			var d := dx * dx + dy * dy
			if d <= 144:
				c.fixed(pc.x + dx, pc.y + dy, IRON, (2 if dx + dy < -4 else 1) if d > 50 else 0)
	for y in range(10, 84):
		c.fixed(pc.x + 12, y, WOOD, 2 if y % 3 else 1)
		c.fixed(pc.x + 13, y, WOOD, 1)
		c.fixed(pc.x + 14, y, WOOD, 0)


# --- parpadeo y luz móvil: parches horneados (vista previa sin shader) -----------------------------

## Por brasero: 3 parches del muro (radio −1, 0, +1 paso de banda) para alternar sin shader.
func _flicker_patches(mid: BgCanvas) -> Array:
	var out: Array = []
	for bi in braziers.size():
		var b: Vector2i = braziers[bi]
		var rect := Rect2i(b.x - 92, b.y - 104, 184, 104 + 40).intersection(Rect2i(0, 0, W, FY))
		var frames: Array = []
		for f: int in [-1, 0, 1]:
			var L := lights.duplicate()
			L[bi * 2] = _brazier_light(b, f)
			var bk := mid.bake(L, rect)
			frames.append({"index": bk["index"], "preview": bk["preview"]})
		out.append({"rect": rect, "frames": frames})
	return out


## Luz del crisol que oscila: 16 parches (uno por posición del péndulo).
func _crucible_patches(mid: BgCanvas) -> Array:
	var out: Array = []
	for cr: Dictionary in anchors["crucibles"]:
		var piv: Vector2i = cr["pivot"]
		var ln: int = cr["len"]
		var rect := Rect2i(piv.x - 40, piv.y + ln - 24, 80, 64)
		var frames: Array = []
		for k in 16:
			var dx := int(roundf(7.0 * sin(TAU * k / 16.0)))
			var L := lights.duplicate()
			L.append({"t": "pt", "p": Vector2(piv.x + dx, piv.y + ln + 8), "r": [8.0, 16.0, 26.0], "ys": 1.0, "y1": FY - 1})
			var bk := mid.bake(L, rect)
			frames.append({"index": bk["index"], "preview": bk["preview"]})
		out.append({"rect": rect, "frames": frames})
	return out
