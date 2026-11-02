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

## Rejilla del suelo (C19): fuera de las placas de PV (enemigos x ≥ 311, heroína x ≤ 201). El calor de la Forja sube por ella.
const GRATE_X := 256
## Escena de los enemigos (C19): desde aquí el muro y el suelo bajan de valor y de contraste de juntas.
const STAGE_X := 300
## Zócalo en sombra tras los enemigos: los ladrillos por debajo de esta fila (y) bajan 1 paso.
const DADO_Y := 218
const PIER_SHADE_Y := 240
## Paño tras los enemigos donde las juntas van al paso de la pieza (F2-SALA2, C19): x STAGE_X..CALM_X1, y CALM_Y0..CALM_Y1.
## Acaba sobre las cabezas (y 167): más abajo, subir las juntas aclara el fondo de las criaturas oscuras y les resta contraste.
const CALM_X1 := 604
const CALM_Y0 := 60
const CALM_Y1 := 167
## Crisol colgante de la sala normal (antes en x 444, en mitad del muro tras los enemigos).
const CRUCIBLE_X := 552
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
		braziers = [Vector2i(222, 150), Vector2i(625, 136)]
	else:
		braziers = [Vector2i(226, 156), Vector2i(520, 150)]
	anchors = {"braziers": braziers, "drips": [], "crucibles": [], "flue": Rect2i(), "window": Rect2i(),
		"grate": Vector2i(GRATE_X, 276), "gauge": Vector2i(-1, -1), "forge_zone": Rect2i(8, 120, 104, 144),
		# Adónde suben las brasas de los muertos: el vacío del tiro o el fondo del corredor.
		"ember_sink": Vector2i(440, 44) if kind == "flue" else Vector2i(320, 214),
		# Recorrido del calor al quemar: de la Forja a la toma del fuelle, brida a brida.
		"pipe": [Vector2i(105, 200), Vector2i(105, 68), Vector2i(236, 68)],
		"flanges": [Rect2i(97, 160, 16, 4), Rect2i(97, 110, 16, 4), Rect2i(144, 61, 4, 16), Rect2i(206, 61, 4, 16), Rect2i(236, 58, 8, 22)]}
	lights = _static_lights()
	var mid := BgCanvas.new(W, H, 0)
	_build_mid(mid, local_floor)
	# Lo lejano y el primer plano no dependen del piso: se comparten entre variantes al hornear.
	room_seed = 7 if kind == "flue" else 0
	var far := BgCanvas.new(W + 2 * M_FAR, H, M_FAR)
	if kind == "flue":
		_build_shaft(far)
	else:
		_build_corridor(far)
	room_seed = 0
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
		# Tras los enemigos el canto del suelo no recoge el charco del brasero: es el borde sobre el que se leen los pies.
		var pool: Array = [20.0, 44.0, 72.0] if b.x < STAGE_X else [16.0, 32.0, 52.0]
		L.append({"t": "pt", "p": Vector2(b.x, FY + 6), "r": pool, "ys": 2.6, "y0": FY + (2 if b.x >= STAGE_X else 0)})
	# La Forja grande: su luz nominal (calor 0,5) va horneada; LightRig sólo suma la diferencia con el calor actual.
	L.append({"t": "pt", "p": Vector2(60, 226), "r": [56.0, 84.0, 118.0, 158.0, 206.0], "ys": 1.0, "y1": FY - 1})
	L.append({"t": "pt", "p": Vector2(60, FY + 4), "r": [56.0, 100.0, 150.0, 210.0], "ys": 2.8, "y0": FY})
	# Rejilla del suelo: el calor de la Forja sube.
	L.append({"t": "pt", "p": Vector2(GRATE_X, 278), "r": [16.0, 34.0, 60.0], "ys": 2.4, "y0": FY})
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
		# Crisol colgante junto al brasero (F2-SALA2, C19): su luz (+2 pasos, r 34) ya no pinta un foco en mitad del muro
		# tras los enemigos; cuelga en el rincón caliente, entre el humo del brasero y la ventana.
		anchors["crucibles"] = [{"pivot": Vector2i(CRUCIBLE_X, 32), "len": 66}]
	# Atrezo de taller sobre la heroína (elegido por piso: herramientero o estante de crisoles).
	if not local_floor in [4, 9, 10]:
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
	_pick_ashlars()
	for y in range(0, FY):
		var row := y / 7
		var ry := y % 7
		var off := (row % 2) * 8
		for x in W:
			var xx := x + off
			var ci := xx / 16
			var rx := xx % 16
			var s := soot(x, y)
			if _vein(x, y):
				c.put(x, y, FIRE, int(_veins[Vector2i(x, y)]))
				continue
			if _ashlar(c, x, y, s):
				continue
			var anc := Vector2i(ci * 16 - off + 8, row * 7 + 3)
			var stage := _in_stage(anc, row)
			var dado := stage and row * 7 >= DADO_Y
			var hb := h3(ci, row, 11)
			var dv := 0
			if hb < 0.14:
				dv -= 1
			elif hb > 0.88:
				dv += 1
			# Grupos de ladrillo de otra hornada (C19): paños de ~3×3 piezas un paso más viejos o más nuevos.
			var hg := h3((xx + int(h3(row / 3, 0, 103) * 32.0)) / 48, row / 3, 104)
			if hg < 0.12:
				dv -= 1
			elif hg > 0.92 and not stage:
				dv += 1
			var jb := 2 + s - (1 if dado else 0)
			if ry == 0 or rx == 0:
				# En el paño tras los enemigos la junta va al paso de la pieza: si la pieza es más oscura, la junta la sigue.
				c.joint(x, y, BRICK, _joint_v(x, y, anc, jb + (mini(0, dv) if _in_calm(x, y) else 0), s, stage))
				continue
			var v := 2 + dv + s
			if dado:
				v -= 1
			if cycle > 0 and (_vein(x, y - 1) or _vein(x, y + 1) or _vein(x - 1, y) or _vein(x + 1, y)):
				v += 1
			var hc := h3(ci, row, 13)
			if hc < 0.22:
				var cx := 1 if hc < 0.11 else 15
				var cy := 1 if h3(ci, row, 14) < 0.5 else 6
				if absi(rx - cx) + absi(ry - cy) <= 1 + int(hc * 12.0) % 3:
					c.joint(x, y, BRICK, _joint_v(x, y, anc, jb + (mini(0, dv) if _in_calm(x, y) else 0), s, stage))
					continue
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


## La pieza (por su ancla) cae en la escena de los enemigos: x ≥ STAGE_X con el borde dentado por hiladas.
func _in_stage(anc: Vector2i, row: int) -> bool:
	return anc.x >= STAGE_X + int(h3(row, 0, 93) * 3.0) * 16


func _in_calm(x: int, y: int) -> bool:
	return x < CALM_X1 and y >= CALM_Y0 and y <= CALM_Y1


## Junta. Fuera de la escena, −1/−2 pasos según la luz (como siempre). En la escena (C19), a −1 del ladrillo: se compensa
## el paso de luz que la junta pierde al hornear, para que el muro tras los enemigos no se lea como una rejilla.
func _joint_v(x: int, y: int, anc: Vector2i, brick_v: int, s: int, stage: bool) -> int:
	var j := 1 + mini(0, s + 1)
	if not stage:
		return j
	var la := BgCanvas.steps_at(Vector2(anc), lights, false)
	var lp := BgCanvas.steps_at(Vector2(x, y), lights, false)
	# F2-SALA2 (C19): en el paño tras los enemigos (x < CALM_X1, y CALM_Y0..CALM_Y1) la junta horneada va AL PASO de su
	# pieza, un paso más que en F2-SALA. La hilada se lee por la fila de sombra de la pieza y, con luz, por la bandera JUNTA.
	if _in_calm(x, y):
		return clampi(brick_v + la - maxi(0, lp - 1), 0, maxi(j + 1, brick_v + la))
	return clampi(brick_v - 1 + la - maxi(0, lp - 1), 0, j + 1)


## Sillería (C19): zócalo de sillares de 3 hiladas (10 px) bajo el ladrillo, de DADO_Y al zócalo de piedra. Rompe el
## ritmo del ladrillo donde están los pies de los actores y, tras los enemigos, queda en sombra (−1) con juntas a −1.
## Los extremos van dentados: los sillares se encajaron en el ladrillo.
const ASHLAR_H := 10
var _ashlars: Array[Rect2i] = []


func _pick_ashlars() -> void:
	_ashlars.clear()
	if kind == "flue":
		_ashlars.append(Rect2i(112, DADO_Y, 152, FY - 16 - DADO_Y))
		_ashlars.append(Rect2i(600, DADO_Y, 40, FY - 16 - DADO_Y))
	else:
		_ashlars.append(Rect2i(112, DADO_Y, 136, FY - 16 - DADO_Y))
		_ashlars.append(Rect2i(392, DADO_Y, 248, FY - 16 - DADO_Y))


func _ashlar(c: BgCanvas, x: int, y: int, s: int) -> bool:
	for r: Rect2i in _ashlars:
		if not r.has_point(Vector2i(x, y)):
			continue
		var k := (y - r.position.y) / ASHLAR_H
		var ry := (y - r.position.y) % ASHLAR_H
		var xl := r.position.x + (int(h3(k, r.position.x, 97) * 2.0) * 8 if r.position.x > 112 else 0)
		var xr := r.end.x - (int(h3(k, r.end.x, 98) * 2.0) * 8 if r.end.x < W else 0)
		if x < xl or x >= xr:
			return false
		var wk := 24 + int(h3(k, r.position.x, 96) * 3.0) * 4
		var u := x - xl + int(h3(k, 7, 99) * float(wk))
		var bi := u / wk
		var rx := u % wk
		var anc := Vector2i(clampi(x - rx + wk / 2, xl, xr - 1), r.position.y + k * ASHLAR_H + ASHLAR_H / 2)
		var row := y / 7
		var stage := _in_stage(anc, row)
		var vb := 2 + s - (1 if stage else 0)
		var hb := h3(bi, k + r.position.x, 100)
		var dv := -1 if hb < 0.2 else (1 if hb > 0.85 else 0)
		if ry == 0 or rx == 0 or x == xl or (x == xr - 1 and xr < W):
			c.joint(x, y, STONE, _joint_v(x, y, anc, vb + (mini(0, dv) if _in_calm(x, y) else 0), s, stage))
			return true
		var v := vb + dv
		if ry == ASHLAR_H - 1:
			v -= 1
		c.put(x, y, STONE, v, anc, BgCanvas.F_BEVEL if (ry == 1 or rx == 1) and s >= -1 else 0)
		return true
	return false


## Vetas de brasa del ciclo II+: GRIETAS que suben atravesando ladrillos en diagonal, siguen a ratos un tendel y se
## ramifican. Rescoldos oscuros en reposo (el pulso de quemar los enciende); se apagan al subir.
var _veins := {}


func _build_veins() -> void:
	_veins.clear()
	if cycle <= 0:
		return
	# Fuera de los huecos de los enemigos (C19): una sube junto a la ventana y otra arranca por encima de sus cabezas.
	var foci: Array = [Vector2i(170, 244), Vector2i(614, 244), Vector2i(436, 146)]
	if cycle >= 2:
		foci.append_array([Vector2i(206, 200), Vector2i(420, 126)])
	for fi in foci.size():
		var o: Vector2i = foci[fi]
		_walk_crack(o, 62 + int(h3(fi, 1, 73) * 40.0) + cycle * 12, -1 if h3(fi, 2, 74) < 0.5 else 1, 0, fi * 37 + 1)


## Tramos rectos de pendiente fija (se leen como grieta, no como escalera), con quiebros y algún tramo por el tendel.
func _walk_crack(start: Vector2i, length: int, dir0: int, depth: int, sd: int) -> void:
	var x := float(start.x)
	var y := start.y
	var dir := dir0
	var t := 0
	while t < length and y >= 62:
		var seg := 7 + int(h3(t, sd, 75) * 13.0)
		var slope: float = [0.0, 0.16, 0.2, 0.25, 0.33][int(h3(t, sd, 76) * 5.0)] * float(dir)
		var x0 := x
		for i in seg:
			if t >= length or y < 62:
				return
			_mark_vein(Vector2i(int(roundf(x0 + slope * i)), y), t, length, depth, sd)
			y -= 1
			t += 1
		x = x0 + slope * seg
		if h3(t, sd, 78) < 0.4:
			dir = -dir
		# La grieta aprovecha el tendel: corre por la junta y vuelve a subir.
		if y % 7 < 3 and h3(t, sd, 79) < 0.5:
			y -= y % 7
			var run := 4 + int(h3(t, sd, 77) * 9.0)
			for i in run:
				_mark_vein(Vector2i(int(x) + dir * i, y), t + i, length, depth, sd)
			x += float(dir * run)
			y -= 1
			t += run
		if depth < 1 and t > 10 and h3(t, sd, 80) < 0.3:
			_walk_crack(Vector2i(int(x), y), length / 3, -dir, depth + 1, sd + t + 101)


func _mark_vein(p: Vector2i, t: int, length: int, depth: int, sd: int) -> void:
	var u := float(t) / length
	if h3(t, sd, 81) > 0.05 + u * 0.3:
		_veins[p] = 2 if u < 0.3 and depth == 0 else 1


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
			# Pie del pilar tras los enemigos, en sombra (por debajo de las alas del murciélago en x 350).
			if x0 >= STAGE_X and y >= PIER_SHADE_Y:
				v -= 1
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
			if x0 >= STAGE_X:
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
				c.joint(x, y, STONE, 1 if x < STAGE_X else 0)
				continue
			# Tras los enemigos el zócalo queda en la sombra del zócalo de ladrillo (C19): canto y cuerpo −1.
			if x / 44 * 44 + 22 >= STAGE_X:
				v -= 2 if t <= 1 else 1
			c.put(x, y, STONE, v, Vector2i(x / 44 * 44 + 22, FY - 8))
	var n := 3 + int(h3(x0, 2, 55) * 3.0)
	for i in n:
		var mx := x0 + 14 + int(h3(i, x0, 55) * float(x1 - x0 - 28))
		if mx < 116 and x0 == 0:
			mx = 116 + int(h3(i, 7, 55) * 100.0)
		# Montones de ceniza fuera de los huecos de los enemigos (x 320–602): no compiten con los pies.
		if mx >= 320 and mx <= 602:
			mx = 612 + int(h3(i, 8, 55) * 12.0)
		var mw := 8 + int(h3(i, x0 + 1, 56) * 10.0)
		for dx in range(-mw, mw + 1):
			var hh := int((1.0 - pow(float(dx) / mw, 2.0)) * (3.0 + mw * 0.4))
			for dy in range(0, hh + 1):
				var v2 := 4 if dy == hh else (3 if dx < -mw / 3 else 2)
				if dy < hh and h3(mx + dx, dy, 57) < 0.1:
					v2 = 1
				c.put(mx + dx, FY - 1 - dy, ASH, v2 + (-1 if mx >= STAGE_X else 1))


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
			var stage := xc >= STAGE_X
			if y == FY or y == FY + 1:
				c.put(x, y, STONE, (5 if y == FY else 4) - (2 if x >= STAGE_X + 16 else 0))
				continue
			if y == FY + 2 or y == FY + 3:
				c.joint(x, y, STONE, 1)
				continue
			if hline or vline:
				c.joint(x, y, STONE, 0 if y > 320 or (stage and y < 300) else 1)
				continue
			var v := 2 if h3(ci, ri, 21) < 0.6 else 1
			if int(prv) != ri:
				v += 1
			if y > 300:
				v -= 1
			if y > 330:
				v -= 1
			# Bajo los enemigos el suelo queda 1 paso más oscuro (C19): las criaturas se leen sobre él y sobre las placas.
			if stage and y < 300:
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
		var hw := 16 + (y - FY - 6) * 3 / 2
		for x in range(GRATE_X - hw, GRATE_X + hw + 1):
			var edge := absi(x - GRATE_X) >= hw - 1 or y <= FY + 7 or y >= FY + 18
			if edge:
				c.put(x, y, IRON, 4 if y == FY + 6 else (2 if y == FY + 7 else 1))
			elif posmod(x - GRATE_X, 5) < 2 or y == FY + 12 or y == FY + 13:
				c.put(x, y, IRON, 2 if posmod(x - GRATE_X, 5) == 0 else 1)
			else:
				var core := absi(x - GRATE_X) < hw / 2 and y > FY + 9 and y < FY + 16
				c.put(x, y, FIRE, 3 + (1 if core else 0) - (1 if absi(x - GRATE_X) > hw - 6 else 0))
	# Cascotes: el deterioro crece con el piso del acto.
	for i in local_floor:
		var rx := 130 + int(h3(i, 5, 99) * 480.0)
		if absi(rx - GRATE_X) < 50:
			continue
		var ry := FY + 6 + int(h3(i, 6, 99) * 18.0)
		var dk := 1 if rx >= STAGE_X else 0
		for dx in 7:
			c.put(rx + dx, ry, BRICK, (6 if dx < 3 else 5) - dk)
			c.put(rx + dx, ry + 1, BRICK, 4 - dk)
			c.put(rx + dx, ry + 2, BRICK, 3 - dk)
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

## Galería del otro lado del tiro: se lee como un vano con fondo de ladrillo, antepecho y un farol; no como marca roja.
func _shaft_gallery(c: BgCanvas, x: int, y: int, u: float, w: float, top: float, lit: bool) -> void:
	var ledge := w > -6.0
	if not lit:
		c.fixed(x, y, BRICK, 0 if not ledge else 1)
		return
	var lamp := Vector2(u - 2.0, w - (top + 13.0)).length()
	if lamp < 1.5:
		c.put(x, y, FIRE, 6)
	elif lamp < 3.0:
		c.put(x, y, FIRE, 4)
	elif ledge:
		var rail := w < -4.0 or posmod(int(u), 4) == 0
		if rail:
			c.fixed(x, y, IRON, 0)
		else:
			c.fixed(x, y, BRICK, 3)
	else:
		var rr := 3 if lamp < 7.0 else (2 if lamp < 12.0 else 1)
		c.fixed(x, y, BRICK, rr if posmod(int(w), 4) != 0 else maxi(0, rr - 1))


## Escena del tiro (F2-PULIDO-C): tras el cuerpo del jefe (14: art 333–572 × 132–205), su lomo y su grúa (x ≥ 440 desde
## y 82) y los élites (x 420–512) el muro lejano no gana detalle; las saeteras y la luz de sus lámparas sólo se marcan fuera.
const SHAFT_CALM: Array[Rect2i] = [Rect2i(326, 128, 256, 80), Rect2i(440, 74, 142, 54)]
## Sobre la cabeza del jefe (x 326–439, y 74–127) el muro también se aquieta, pero la saetera de x 375 sí se marca.
const SHAFT_QUIET := Rect2i(326, 74, 114, 54)
## Hasta dónde baja la luz fría de la cima del tiro: 8 px (2 celdas de la miniatura a 1/4) sobre la grúa del jefe (y 82).
const SHAFT_COLD_Y1 := 74.0


func _shaft_in_calm(x: int, y: int, wall := false) -> bool:
	var p := Vector2i(x, y)
	return SHAFT_CALM[0].has_point(p) or SHAFT_CALM[1].has_point(p) or (wall and SHAFT_QUIET.has_point(p))


## Centro en pantalla de una saetera lejana (arco de 20×29 en coordenadas de cilindro, altura `hgt`).
func _shaft_slit_center(ang: float, hgt: float, cx: float, R: float, eye: float) -> Vector2i:
	var f := 0.62 + 0.38 * cos(ang * 1.5)
	return Vector2i(int(cx + sin(ang) * R), int(eye + (hgt - 14.0 - eye) / f))


func _build_shaft(c: BgCanvas) -> void:
	var R := 220.0
	var cx := 440.0
	var eye := 150.0
	far_lights = [{"t": "pt", "p": Vector2(440, 330), "r": [74.0, 108.0, 146.0, 196.0, 260.0], "ys": 1.2},
		# Luz fría de la Torre: baja por el tiro desde la cima y moja la parte alta del muro en dos bandas que siguen
		# la curva de las hiladas (elipse ancha); se queda sobre la grúa del jefe y el anillo de su miniatura (y ≤ 74).
		{"t": "pt", "p": Vector2(440, -20), "r": [130.0, 184.0], "ys": 2.0, "cold": true, "y1": SHAFT_COLD_Y1}]
	# Galerías del otro lado del tiro (saeteras): [ángulo, altura en el cilindro, encendida].
	var arches := [[-0.62, 120.0, 0], [-0.30, 120.0, 1], [0.34, 120.0, 0], [0.66, 120.0, 1],
		[-0.46, 56.0, 0], [-0.14, 56.0, 1], [0.50, 56.0, 0], [-0.46, 190.0, 1], [0.18, 190.0, 0], [0.50, 190.0, 1],
		# F2-PULIDO-C: una encendida en el flanco izquierdo, entre la jamba del arco y la escena (x ≈ 298, y ≈ 148–178).
		[-0.70, 176.0, 1]]
	# Saeteras que se marcan (fuera de la escena): marco claro, alféizar y sombra bajo él; las encendidas, luz en el muro.
	var vivid: Array[bool] = []
	for ar: Array in arches:
		var sc := _shaft_slit_center(float(ar[0]), float(ar[1]), cx, R, eye)
		vivid.append(not _shaft_in_calm(sc.x, sc.y))
	for y in range(0, FY + 4):
		for x in range(270, 612):
			var dx := clampf((x - cx) / R, -0.98, 0.98)
			var th := asin(dx)
			# Hiladas curvas: un cilindro visto desde dentro (las hiladas se alejan del horizonte hacia los lados).
			var yr := eye + (y - eye) * (0.62 + 0.38 * cos(th * 1.5))
			var iy := int(floor(yr))
			var row := iy / 4 if iy >= 0 else -1
			var ry := posmod(iy, 4)
			# Foso: la luz de la Forja como bruma en bandas, abajo del todo.
			var wave := 4.0 * sin(x * 0.05) + 2.0 * sin(x * 0.13 + 1.0)
			if y > 222 + wave:
				c.put(x, y, FIRE, 3 if y > 230 + wave else 2)
				continue
			if y > 212 + wave:
				c.put(x, y, FIRE, 1)
				continue
			# Oscurece hacia los lados y hacia arriba: profundidad.
			var v := 2
			if absf(dx) > 0.62:
				v -= 1
			if y < 46:
				v -= 1
			# Cornisas anulares cada 66 de altura de cilindro.
			var band := posmod(iy - 40, 66)
			if band < 4:
				var bv := 3 if band == 0 else (2 if band == 1 else (1 if band == 2 else 0))
				c.put(x, y, STONE, bv + (0 if absf(dx) < 0.62 else -1))
				continue
			# Nervios.
			var rib := false
			for rth: float in [-0.92, -0.46, 0.46, 0.92]:
				var rxx := cx + sin(rth) * R
				var rw := 7.0 * cos(rth) + 1.0
				if absf(x - rxx) < rw:
					rib = true
					v = 2 if x < rxx - rw * 0.55 else (0 if x > rxx + rw * 0.45 else 1)
			if rib:
				c.put(x, y, STONE, v)
				continue
			# Arcadas de otras galerías (siguen la curvatura: son coordenadas de cilindro).
			var painted := false
			var sill_shadow := false
			for ai in arches.size():
				var ar: Array = arches[ai]
				var u := (th - float(ar[0])) * R
				var w := yr - float(ar[1])
				var hw := 10.0
				var top := -28.0
				if vivid[ai] and absf(u) < hw + 3.0 and w > 1.0 and w <= 4.0:
					sill_shadow = true
				if absf(u) > hw + 2.0 or w < top - 2.0 or w > 1.0:
					continue
				var inside: bool = (w > top + hw and absf(u) < hw) or Vector2(u, w - (top + hw)).length() < hw
				var trim: bool = (w > top + hw and absf(u) < hw + 2.0) or Vector2(u, w - (top + hw)).length() < hw + 2.0
				if inside:
					_shaft_gallery(c, x, y, u, w, top, int(ar[2]) == 1)
					painted = true
					break
				elif trim:
					var key := absf(u) < 2.0 and w < top + 1.0
					var tv := 3 if key else (2 if u < 0.0 else 1)
					var sill := w > -1.0
					if vivid[ai]:
						# Marco que mira a la luz del foso (abajo y a la izquierda) un paso más claro; alféizar de piedra.
						tv = 5 if key else (4 if u < 0.0 else 2)
						if sill:
							tv = 4 if u < hw else 3
					c.put(x, y, STONE, tv, Vector2i(x, y) if key else Vector2i(int(cx + sin(float(ar[0])) * R), y / 6 * 6))
					painted = true
					break
			if painted:
				continue
			# Sillería: la pieza entera recibe la luz (ancla en coordenadas de cilindro), con zonas de obra y tizne.
			var cc := th / (PI * 0.5) * 60.0 + 0.5 * posmod(row, 2)
			var ci := int(floorf(cc))
			var fr := fposmod(cc, 1.0)
			var below_band := posmod(iy - 40, 66) - 4
			var ath := (float(ci) + 0.5 - 0.5 * posmod(row, 2)) / 60.0 * PI * 0.5
			var ayr := float(row) * 4.0 + 2.0
			var anc := Vector2i(int(cx + sin(ath) * R), int(eye + (ayr - eye) / (0.62 + 0.38 * cos(ath * 1.5))))
			# Zonas de reparación: paños enteros de ladrillo más claro u oscuro (rompen la planitud a gran escala).
			var zone := h3(int((th + 2.0) * 7.0), posmod(iy, 264) / 24, 34)
			# Tras el jefe y los élites (SHAFT_CALM) no hay paños ni ladrillos sueltos más claros: el muro queda más quieto.
			var calm := _shaft_in_calm(x, y, true)
			if zone < 0.18:
				v -= 1
			elif zone > 0.82 and not calm:
				v += 1
			# Sombra de la cornisa encima y hollín que escurre de ella en regueros.
			if below_band >= 0 and below_band < 3:
				v -= 1
			elif below_band >= 0 and below_band < 12 + int(h3(int(x) / 5, iy / 66, 35) * 22.0) and h3(int(x) / 5, iy / 66, 36) < 0.4:
				v -= 1
			# Sombra lateral que proyectan los nervios.
			for rth2: float in [-0.46, 0.46]:
				var dr := float(x) - (cx + sin(rth2) * R)
				if dr > 7.0 and dr < 14.0:
					v -= 1
			if sill_shadow:
				v -= 1
			# Luz de las lámparas de las saeteras encendidas sobre el muro, por pieza (ancla), en dos saltos.
			for ai2 in arches.size():
				var ar2: Array = arches[ai2]
				if not vivid[ai2] or int(ar2[2]) == 0:
					continue
				var dl := Vector2((ath - float(ar2[0])) * R, ayr - float(ar2[1]) + 15.0).length()
				if dl < 22.0:
					v += 2 if dl < 13.0 else 1
			if ry == 0 or fr < 0.12 / maxf(0.4, cos(th)):
				c.joint(x, y, BRICK, v - 1)
			else:
				var hb2 := h3(ci, row, 33)
				if hb2 < 0.16:
					v -= 1
				elif hb2 > 0.9 and not calm:
					v += 1
				c.put(x, y, BRICK, v, anc)
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
