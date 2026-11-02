extends RefCounted
## LIMO DE CENIZA (`ash_slime`, acto 1) — PER · v0.4 (F2-CRIA2a: redibujo C5).
## Concepto: una gota de alquitrán blando con una COSTRA de ceniza en la coronilla; por las grietas de la costra asoma la brasa.
## Silueta: domo que cede (barriga ancha abajo, punta de gota arriba y atrás), base con 3 lóbulos y un goterón en la muesca
## trasera, sin rectas largas. Costra sólo en el tercio superior, con lenguas que gotean. Ojos de brasa SIEMPRE visibles.
## ≈ 44×29 px; lienzo 100×68; suelo y = 58. El cuerpo es una LOSA generada por parámetros (`_body`): cada deformación es una
## vista propia redibujada a su tamaño, nunca un escalado.
## Rasgo vivo (6 f): la base se aplasta 1–2 px y la cima llega un fotograma tarde y retrasada; el brillo húmedo recorre el
## flanco; crece y cae el goterón; parpadeo (rendija encendida) y burbuja de humo de la grieta.
## Telegrafía (cast): se aplasta y abre los ojos; las grietas al blanco. Ataque: se encoge, salta en arco, cae y salpica.
## Muerte: se derrite en un charco, la costra se apaga y queda una mancha seca.

const X0 := -32   # esquina de la losa en el espacio del root
const Y0 := -37
const CW := 64
const CH := 40
const YF := 2     # fila de apoyo (el suelo queda en +3)
const LEGEND := {
	"1": [&"tar", 1], "2": [&"tar", 2], "3": [&"tar", 3], "4": [&"tar", 4], "5": [&"tar", 5],
	"E": [&"ash", 4], "D": [&"ash", 5], "C": [&"ash", 6], "B": [&"ash", 7], "A": [&"ash", 8], "H": [&"ash", 9],
	"r": [&"fire", 3], "R": [&"fire", 4], "F": [&"fire", 5],
}
## Ojos: la palanca `face` sube/baja el sello con la altura del cuerpo (pivote a 34 px por detrás del sello).
const FACE_PIVOT := Vector2(22, -10)
const FACE_AT := Vector2(-34, 0)
## Grietas de brasa relativas a la punta de la costra (orden: tronco caliente primero).
const CRACKS := [[0, 0], [0, 1], [-1, 2], [-2, 3], [-2, 4], [1, 1], [2, 1], [3, 2], [4, 3], [-3, 1], [-4, 1], [-5, 2], [-6, 2], [5, 4], [-7, 3]]
const CRACK_COOL := [4, 8, 12, 13, 14]
const WOB := [0, 0, 1, 0, 0, 2, 3, 1, 0, 0, 0, 1, 0, 2, 1, 0, 0, 1]


## Altura del cuerpo → y local del centro de los ojos.
static func _eye_y(hd: int) -> float:
	return YF - 0.45 * hd


## Silueta y pasos del cuerpo. p: hd (alto), hw (medio ancho), apex (punta atrás, px), spread (base que se abre), tm (altura
## de la barriga 0..1), heat (-1 apagada · 0..3), gloss (-1 sin brillo · 0..2 recorrido), drip (-1 · 0..3), crust, lobes.
static func _body(p: Dictionary) -> Array:
	var hd: int = p.get("hd", 26)
	var hw: float = p.get("hw", 21.0)
	var apex: float = p.get("apex", 3.0)
	var spread: float = p.get("spread", 0.0)
	var tm: float = p.get("tm", 0.7)
	var heat: int = p.get("heat", 2)
	var gloss: int = p.get("gloss", 0)
	var drip: int = p.get("drip", 1)
	var crust: bool = p.get("crust", true)
	var lobes: bool = p.get("lobes", true)
	var g: Array = []
	for y in CH:
		var r: Array = []
		r.resize(CW)
		r.fill(".")
		g.append(r)
	var ytop := YF - hd
	var ybase := YF - 3
	var rows := {}
	for y in range(ytop, YF + 1):
		var t := (y - ytop + 0.5) / float(hd + 1)
		var gq: float
		if t < tm:
			var sv := t / tm
			gq = pow(sv * (2.0 - sv), 0.72)
		else:
			gq = 1.0 - 0.2 * pow((t - tm) / (1.0 - tm), 1.6)
		var w := (hw + spread * t * t) * gq
		var cx := apex * pow(1.0 - t, 1.6) + 0.5
		rows[y] = Vector2(cx - w, cx + w)
	# Muescas de la base (3 lóbulos) y goterón en la trasera.
	var base: Vector2 = rows[YF]
	var span := base.y - base.x
	var notches: Array = []
	if lobes:
		notches = [Vector3(base.x + span * 0.36, 3.2, 2.6), Vector3(base.x + span * 0.68, 3.6, 3.0)]
	var fill := {}
	for y: int in rows.keys():
		var lr: Vector2 = rows[y]
		for x in range(roundi(lr.x), roundi(lr.y)):
			var depth := 0.0
			for n: Vector3 in notches:
				depth = maxf(depth, n.z * (1.0 - pow(absf(x + 0.5 - n.x) / n.y, 2.0)))
			if y > YF - depth:
				continue
			fill[Vector2i(x, y)] = true
	_soften(fill)
	if lobes and drip >= 0:
		var dx := int(notches[1].x)
		var tn := YF - 3
		var drops: Array = [[Vector2i(dx, tn + 1)], [Vector2i(dx, tn + 1), Vector2i(dx, tn + 2)],
			[Vector2i(dx, tn + 1), Vector2i(dx, tn + 2), Vector2i(dx, tn + 3), Vector2i(dx - 1, tn + 3)],
			[Vector2i(dx, tn + 1), Vector2i(dx, tn + 3)]][drip]
		for d: Vector2i in drops:
			fill[d] = true
	# Sombreado a pasos forzados: luz cálida de la Forja arriba-izquierda-delante.
	var lgt := Vector3(-0.62, -0.55, 0.56)
	for c: Vector2i in fill.keys():
		var x := c.x
		var y := c.y
		var lr: Vector2 = rows[clampi(y, ytop, YF)]
		var cx := (lr.x + lr.y) * 0.5
		var w := maxf(1.0, (lr.y - lr.x) * 0.5)
		var sx := clampf((x + 0.5 - cx) / w, -1.0, 1.0)
		var t := (y - ytop) / float(maxi(1, hd))
		var ny := -(1.0 - minf(1.0, t / tm)) * 0.9 if t < tm else 0.25
		var nz := sqrt(maxf(0.05, 1.0 - sx * sx * 0.85 - ny * ny))
		var v := sx * lgt.x + ny * lgt.y + nz * lgt.z
		var cl: float = ytop + hd * 0.28 + float(WOB[posmod(x, WOB.size())])
		var ch := ""
		if crust and y < cl and y <= ybase - 4:
			ch = "H" if v > 0.85 else ("A" if v > 0.62 else ("B" if v > 0.35 else ("C" if v > 0.05 else "D")))
			if y >= cl - 1.0:
				ch = "E" if v < 0.5 else "D"
		else:
			ch = "4" if v > 0.7 else ("3" if v > 0.3 else "2")
			if y >= ybase:
				ch = "2" if v > 0.4 else "1"
			if y >= YF:
				ch = "1"
			if crust and y >= cl and y < cl + 1.0:
				ch = "1"   # sombra que arroja la costra
			if sx > 0.82 and t > 0.2 and t < 0.8 and ch == "2":
				ch = "3"   # canto frío de la Torre
		_set_px(g, x, y, ch)
	# Grietas de brasa en la costra.
	if crust and heat >= 0:
		var ax := int(apex * 0.7)
		for i in CRACKS.size():
			var x: int = ax + CRACKS[i][0]
			var y: int = ytop + 2 + CRACKS[i][1]
			if not "HABCDE".contains(_px(g, x, y)):
				continue
			var ch := "r"
			if i < 2 and heat >= 2:
				ch = "F"
			elif heat >= 1 and not CRACK_COOL.has(i):
				ch = "R"
			if heat >= 3 and ch == "r":
				ch = "R"
			_set_px(g, x, y, ch)
	# Brillo húmedo (2 px) bajo la costra, en el flanco iluminado.
	if gloss >= 0:
		var gx := roundi((rows[ybase] as Vector2).x) + 5 + gloss
		for y in range(ytop, ybase):
			if "234".contains(_px(g, gx, y)) and "1E".contains(_px(g, gx, y - 1)):
				_set_px(g, gx, y + 1, "5")
				_set_px(g, gx - 1, y + 2, "5")
				break
	var out: Array = []
	for r: Array in g:
		out.append("".join(PackedStringArray(r)))
	return out


## La gelatina cede: todo tramo recto de contorno de más de 4 px (flancos y coronilla) se rompe con un abombamiento de
## 1 px en su centro, de modo que ningún tramo pasa de 4.
static func _soften(fill: Dictionary) -> void:
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for c: Vector2i in fill.keys():
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var add: Array[Vector2i] = []
	# flancos: borde izquierdo y derecho por fila (sin las 3 filas de la base, que llevan los lóbulos)
	for side: int in [-1, 1]:
		var edge := {}
		for y in range(lo.y, hi.y - 2):
			for x in (range(lo.x, hi.x + 1) if side < 0 else range(hi.x, lo.x - 1, -1)):
				if fill.has(Vector2i(x, y)):
					edge[y] = x
					break
		_bulge(edge, range(lo.y, hi.y - 2), side, true, add)
	# coronilla: borde superior por columna
	var top := {}
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			if fill.has(Vector2i(x, y)):
				top[x] = y
				break
	_bulge(top, range(lo.x, hi.x + 1), -1, false, add)
	for c in add:
		fill[c] = true


## Recorre `edge` (clave → coordenada del borde) y abomba hacia `out` el centro de cada tramo igual de más de 4.
static func _bulge(edge: Dictionary, keys: Array, out: int, vertical: bool, add: Array[Vector2i]) -> void:
	var i := 0
	while i < keys.size():
		if not edge.has(keys[i]):
			i += 1
			continue
		var j := i
		while j + 1 < keys.size() and edge.has(keys[j + 1]) and edge[keys[j + 1]] == edge[keys[i]]:
			j += 1
		var n := j - i + 1
		if n > 4:
			var m := mini(4, n - 4)
			var s := i + (n - m) / 2
			for k in range(s, s + m):
				var e: int = edge[keys[k]] + out
				add.append(Vector2i(e, keys[k]) if vertical else Vector2i(keys[k], e))
		i = j + 1


static func _set_px(g: Array, x: int, y: int, ch: String) -> void:
	if x >= X0 and x < X0 + CW and y >= Y0 and y < Y0 + CH:
		(g[y - Y0] as Array)[x - X0] = ch


static func _px(g: Array, x: int, y: int) -> String:
	if x >= X0 and x < X0 + CW and y >= Y0 and y < Y0 + CH:
		return (g[y - Y0] as Array)[x - X0]
	return "."


## Formas del cuerpo (vista de la losa → parámetros).
const FORMS := {
	&"i0": {"hd": 26, "gloss": 0, "drip": 0},
	&"i1": {"hd": 26, "spread": 1.0, "gloss": 0, "drip": 1},
	&"i2": {"hd": 25, "spread": 1.0, "apex": 4.0, "gloss": 1, "drip": 1},
	&"i3": {"hd": 24, "spread": 1.0, "apex": 5.0, "gloss": 1, "drip": 2},
	&"i4": {"hd": 24, "apex": 4.0, "gloss": 2, "drip": 3},
	&"i5": {"hd": 25, "apex": 3.0, "gloss": 1, "drip": 0},
	&"sq": {"hd": 22, "hw": 23.0, "spread": 2.0, "apex": 1.0, "heat": 3, "drip": 0},
	&"low": {"hd": 20, "hw": 24.0, "spread": 2.0, "apex": 2.0, "heat": 3, "drip": -1},
	&"st": {"hd": 31, "hw": 17.0, "apex": 5.0, "tm": 0.62, "heat": 3, "drip": -1, "lobes": false},
	&"splat": {"hd": 18, "hw": 26.0, "spread": 3.0, "apex": -2.0, "heat": 2, "drip": -1},
	&"dent": {"hd": 23, "hw": 22.0, "spread": 1.0, "apex": 7.0, "heat": 1, "drip": 0},
	&"m1": {"hd": 17, "hw": 25.0, "spread": 3.0, "apex": 1.0, "heat": 1, "gloss": -1, "drip": -1},
	&"m2": {"hd": 12, "hw": 27.0, "spread": 3.0, "apex": 1.0, "heat": 0, "gloss": -1, "drip": -1},
	&"m3": {"hd": 8, "hw": 28.0, "spread": 2.0, "apex": 0.0, "heat": -1, "gloss": -1, "drip": -1, "lobes": false},
	&"pu": {"hd": 4, "hw": 28.0, "spread": 1.0, "apex": 0.0, "heat": -1, "gloss": -1, "drip": -1, "lobes": false, "crust": false},
}


static func build() -> RigDef:
	var b := RigBuilder.new(&"ash_slime", Vector2i(100, 68), Vector2i(62, 55), -1)
	b.material(&"ash", &"ash")
	b.material(&"tar", &"coal")
	b.material(&"smoke", &"smoke", {"rim": false})
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	# Palancas: al girarlas, los ojos y la grieta humeante suben o bajan con la altura del cuerpo.
	b.bone(&"face", &"root", FACE_PIVOT, {"z": 10.0})
	b.bone(&"crater_arm", &"root", Vector2(-30, -25), {"z": 10.0})
	b.bone(&"blob_l", &"root", Vector2(-27, 1), {"z": 12.0})
	b.bone(&"blob_r", &"root", Vector2(27, 1), {"z": 12.0})
	var views := {}
	for k: StringName in FORMS.keys():
		views[k] = _body(FORMS[k])
	b.slab(&"body", &"root", views[&"i0"], Vector2(X0, Y0), LEGEND, 0.0, 1.0, 2.0, {"views": views})
	# Ojos de brasa, desiguales (el cercano más grande). Todas las vistas dejan brasa a la vista.
	var eyes := {"k": [&"tar", 0], "W": [&"fire", 7], "E": [&"fire", 5], "e": [&"fire", 3]}
	b.stamp(&"eyes", &"face", FACE_AT, [
		".kkkk...kkk.",
		"kWWEk..kWEk.",
		"kWEek..keek.",
		".kkk....kk..",
	], eyes, {"anchor": Vector2i(1, 2), "views": {
		&"blink": [
			"............",
			"kkkkk..kkkk.",
			"keeek..keek.",
			".kkk....kk..",
		], &"wide": [
			".kkkkk..kkkk",
			"kWWWEk.kWWEk",
			"kWWEek.kWEek",
			"kWEeek.keeek",
			".kkkk...kkk.",
		], &"shut": [
			"............",
			"kkkkk..kkkk.",
			"kEeek..kEek.",
			".kkk....kk..",
		], &"dim": [
			"............",
			"kkkkk..kkkk.",
			"keekk..kekk.",
			".kkk....kk..",
		]}})
	# Boca: sólo al atacar (en reposo no tiene: evita la lectura de "muñequito").
	b.stamp(&"maw", &"face", FACE_AT + Vector2(3, 5), [
		"kkkkkkkk",
		"kWkWkkWk",
		"kffffffk",
		".kkkkkk.",
	], {"k": [&"tar", 0], "W": [&"linen", 5], "f": [&"fire", 3]}, {"anchor": Vector2i(1, 0)})
	# Humo de la grieta: burbujas que suben.
	for i in 3:
		var r := 1.6 + i * 0.7
		b.ell(StringName("puff_%d" % i), &"crater_arm", &"smoke", Vector3(33 + i, -1.0 - i * 3.2, 0), Vector3(r, r * 0.9, r), {"line": false, "flat": 0.4})
	b.ell(&"splash_l", &"blob_l", &"tar", Vector3(0, 0, 0), Vector3(3.2, 2.2, 2.5), {"line": false})
	b.ell(&"splash_r", &"blob_r", &"tar", Vector3(0, -1, 0), Vector3(2.6, 1.8, 2.5), {"line": false})
	b.socket(&"hit", &"root", Vector2(-16, -9))
	b.socket(&"intent", &"root", Vector2(3, -26))
	b.socket(&"smoke", &"crater_arm", Vector2(33, -2))
	_anims(b)
	return b.def


## Pose de una forma: vista del cuerpo + palancas de ojos y humo a la altura que toca.
static func _pose(form: StringName, root: Vector2i, extra := {}) -> Dictionary:
	var hd: int = (FORMS[form] as Dictionary).get("hd", 26)
	var dy := _eye_y(hd) - _eye_y(26)
	var ty := float(26 - hd)   # la punta baja lo que baja el cuerpo
	var k := {&"@root": root, &"view:body": form,
		&"face": asin(clampf(-dy / FACE_AT.length(), -1.0, 1.0)),
		&"crater_arm": asin(clampf(ty / 33.0, -1.0, 1.0)),
		&"hide:splash_l": true, &"hide:splash_r": true, &"hide:maw": true,
		&"hide:puff_0": true, &"hide:puff_1": true, &"hide:puff_2": true}
	for key in extra.keys():
		k[key] = extra[key]
	return k


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 6:
		var k := _pose(StringName("i%d" % f), Vector2i.ZERO)
		if f == 5:
			k[&"view:face"] = &"blink"
		var bub := [-1, 0, 1, 1, 2, -1][f] as int
		for i in 3:
			k[StringName("hide:puff_%d" % i)] = i != bub
		idle[f] = k
	b.anim(&"idle", 6, 170, idle, {"interp": &"hold"})
	# Telegrafía: se aplasta, ojos enormes, grietas al blanco.
	b.anim(&"cast", 2, [140, 400], {
		0: _pose(&"sq", Vector2i(0, 0), {&"view:face": &"wide"}),
		1: _pose(&"low", Vector2i(1, 0), {&"view:face": &"wide", &"hide:maw": false}),
	}, {"loop": false, "interp": &"hold"})
	# Ataque: encoge → estira y salta (la punta se queda atrás) → arriba → cae delante y salpica → vuelve.
	b.anim(&"attack", 5, [120, 60, 70, 110, 150], {
		0: _pose(&"low", Vector2i(2, 0), {&"view:face": &"wide"}),
		1: _pose(&"st", Vector2i(-6, -8), {&"view:face": &"wide", &"hide:maw": false}),
		2: _pose(&"st", Vector2i(-14, -11), {&"view:face": &"wide", &"hide:maw": false}),
		3: _pose(&"splat", Vector2i(-20, 0), {&"view:face": &"shut", &"hide:splash_l": false, &"hide:splash_r": false}),
		4: _pose(&"i0", Vector2i(-12, 0)),
	}, {"loop": false, "interp": &"hold"})
	# Golpe: se abolla hacia atrás (la punta se va lejos) y salpica.
	b.anim(&"hurt", 2, [90, 150], {
		0: _pose(&"dent", Vector2i(3, 0), {&"view:face": &"shut", &"hide:splash_l": false, &"hide:splash_r": false}),
		1: _pose(&"i1", Vector2i(2, 0), {&"view:face": &"blink"}),
	}, {"loop": false, "interp": &"hold"})
	# Muerte: se derrite en un charco; las brasas se apagan; queda una mancha seca.
	var d := {}
	d[0] = _pose(&"dent", Vector2i(2, 0), {&"view:face": &"shut"})
	d[1] = _pose(&"m1", Vector2i(0, 0), {&"view:face": &"shut"})
	d[2] = _pose(&"m2", Vector2i(0, 0), {&"view:face": &"dim"})
	d[3] = _pose(&"m3", Vector2i(0, 0), {&"view:face": &"dim", &"emit:eyes": -2})
	d[4] = _pose(&"pu", Vector2i(0, 0), {&"hide:eyes": true})
	d[5] = d[4].duplicate()
	b.anim(&"death", 6, [80, 90, 110, 130, 200, 400], d, {"loop": false, "interp": &"hold"})
