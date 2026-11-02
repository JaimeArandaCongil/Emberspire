extends RefCounted
## LIMO DE CENIZA (`ash_slime`, acto 1) — PER · v0.4 (F2-CRIA2a: redibujo C5 · F2-CRIA4: base lobulada, goterón, brillo y labio cálido).
## Concepto: una gota de alquitrán blando con una COSTRA de ceniza en la coronilla; por las grietas de la costra asoma la brasa.
## Silueta: domo que cede (barriga ancha abajo, punta de gota arriba y atrás), base con 3 lóbulos en bulbo (muescas de 5–6 px)
## y un goterón-sello en la muesca trasera, sin rectas largas. Alquitrán en pasos 3–5 (luminancia ≥ 0,20) con labio cálido
## de 1 px en la base (`rock_soot`) que lo separa del suelo y brillo húmedo de 2 px (`linen`). Costra sólo en el tercio superior, con lenguas que gotean. Ojos de brasa SIEMPRE visibles.
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
	"L": [&"lip", 6], "l": [&"lip", 5], "W": [&"wet", 5], "w": [&"wet", 4],
}
## Ojos: la palanca `face` sube/baja el sello con la altura del cuerpo (pivote a 34 px por detrás del sello).
const FACE_PIVOT := Vector2(22, -10)
const FACE_AT := Vector2(-34, 0)
## Grietas de brasa relativas a la punta de la costra (orden: tronco caliente primero).
const CRACKS := [[0, 0], [0, 1], [-1, 2], [-2, 3], [-2, 4], [1, 1], [2, 1], [3, 2], [4, 3], [-3, 1], [-4, 1], [-5, 2], [-6, 2], [5, 4], [-7, 3]]
const CRACK_COOL := [4, 8, 12, 13, 14]
## Goterón (vistas del sello `drip`): 0 bulto · 1 lágrima colgando · 2 lágrima larga que toca el suelo · 3 cae y se aplasta.
const DRIP_X := 7
const DRIPS := [
	[".nn.", ".nm.", "....", "....", "....", "...."],
	[".n..", ".nn.", "nWnn", "nnmm", ".mm.", "...."],
	[".n..", ".n..", ".nn.", "nWnn", "nnmm", ".LL."],
	[".n..", "....", "....", "....", ".nm.", "LnmL"],
]
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
	# Muescas de la base (3 lóbulos en bulbo) y goterón en lágrima colgando de la muesca trasera.
	var base: Vector2 = rows[YF]
	var span := base.y - base.x
	var notches: Array = []
	if lobes:
		notches = [Vector3(base.x + span * 0.33, 3.4, 5.0), Vector3(base.x + span * 0.70, 6.2, 6.0)]
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
	# Cada lóbulo acaba en bulbo: se recortan las esquinas exteriores de la fila de apoyo.
	if lobes:
		var cut: Array[Vector2i] = []
		for c: Vector2i in fill.keys():
			if c.y == YF and (not fill.has(Vector2i(c.x - 1, YF)) or not fill.has(Vector2i(c.x + 1, YF))):
				cut.append(c)
		for c in cut:
			fill.erase(c)
	# Sombreado a pasos forzados: luz cálida de la Forja arriba-izquierda-delante. El alquitrán va un paso por encima del
	# suelo (paso 3–5) y la base lleva un labio cálido (reflejo de la Forja en lo mojado) que la separa del suelo.
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
			ch = "5" if v > 0.93 else ("4" if v > -0.05 else "3")
			if y >= ybase:
				ch = "4" if v > 0.3 else "3"
			if crust and y >= cl and y < cl + 1.0:
				ch = "2"   # sombra que arroja la costra
			if sx > 0.82 and t > 0.2 and t < 0.8 and ch == "3":
				ch = "4"   # canto frío de la Torre
			# Labio cálido: la cara inferior de cada lóbulo y de cada muesca.
			if y >= ybase - 2 and not fill.has(Vector2i(x, y + 1)):
				ch = "L" if sx < 0.55 else "l"
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
	# Brillo húmedo: canto mojado de 1 px por dentro del flanco delantero y una chispa de 2 px casi blanca bajo la costra,
	# en el centro del domo (detrás de los ojos); la chispa recorre la coronilla con `gloss`.
	if crust:
		for y in range(ytop, ybase - 1):
			var tt := (y - ytop) / float(maxi(1, hd))
			if tt < 0.4 or tt > 0.78:
				continue
			for x in range(X0, X0 + CW):
				if "345".contains(_px(g, x, y)):
					if "345".contains(_px(g, x + 1, y)):
						_set_px(g, x + 1, y, "5")
					break
	if gloss >= 0:
		var gx := roundi(((rows[ybase] as Vector2).x + (rows[ybase] as Vector2).y) * 0.5) + 3 + gloss
		for y in range(ytop, ybase):
			if "345".contains(_px(g, gx, y)) and "2".contains(_px(g, gx, y - 1)):
				_set_px(g, gx, y + 1, "W")
				_set_px(g, gx + 1, y + 1, "W")
				_set_px(g, gx - 1, y + 2, "w")
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
	b.material(&"lip", &"rock_soot")   # labio cálido de la base (sel-out cálido)
	b.material(&"wet", &"linen", {"rim": false})   # brillo húmedo
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
	# Goterón: lágrima de alquitrán claro con chispa húmeda, colgando del techo de la muesca trasera (x = DRIP_X). Es un sello
	# para que el contorno del motor no se la coma; cada estado (`drip` de la forma) es una vista.
	var dl := {"k": [&"coal", 1], "n": [&"coal", 5], "m": [&"coal", 4], "W": [&"linen", 5], "L": [&"rock_soot", 6]}
	b.stamp(&"drip", &"root", Vector2(DRIP_X, YF - 5), DRIPS[0], dl, {"anchor": Vector2i(1, 0), "views": {
		&"d0": DRIPS[0], &"d1": DRIPS[1], &"d2": DRIPS[2], &"d3": DRIPS[3]}})
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
		&"hide:puff_0": true, &"hide:puff_1": true, &"hide:puff_2": true, &"hide:drip": true}
	# El goterón sólo cuelga en las formas de reposo (y en el rebote del golpe).
	var dr: int = (FORMS[form] as Dictionary).get("drip", -1)
	if dr >= 0 and String(form).begins_with("i"):
		k[&"hide:drip"] = false
		k[&"view:drip"] = StringName("d%d" % dr)
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
