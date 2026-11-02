extends RefCounted
## MURCIÉLAGO BRASA (`cinder_bat`, acto 1) — PER · v0.4. (El encargo lo llamaba "ember_bat"; el id real de enemy_db es cinder_bat.)
## Concepto: un murciélago que anida en las chimeneas, con las alas quemadas.
## Silueta: gran triángulo de alas raídas a ¾ (una a cada lado del cuerpo), orejas en punta, núcleo encendido en el pecho.
## ≈ 44×84 px de envergadura en un lienzo de 124×128. Vuela: sin suelo; el centro del cuerpo está en y = 70.
## Rasgo vivo: aleteo de 6 fotogramas con vaivén, venas de brasa en las alas, chispas que caen por los agujeros, parpadeo.
## Telegrafía (cast): pliega las alas hacia arriba y se inclina para caer en picado. Ataque: dos pasadas. Muerte: se deshace en pavesas.

## Altura de vuelo: px de arte del origen (centro del cuerpo) al suelo.
const HOVER := 46

## Alas v2 (F2-CRIA2b, C13): membrana llena y oscura con festones entre dedos, para que el ala pese como una mancha
## contra el arco gris y el ladrillo. B = hueso del borde de ataque (canto cálido), f = dedos, # = membrana,
## % = borde de fuga (mismo paso que # en el ala cercana: masa máxima), v = vena de brasa, e = labio encendido de un agujero quemado.
## Tramo interior (brazo): hombro a la izquierda (col 0, fila 7), muñeca arriba a la derecha (col 18, fila 0); la membrana
## baja hasta el tobillo (fila 20) como en un murciélago real.
const IN := [
	".................BB",
	"..............BBBf#",
	"............BB###f#",
	".........BBB#####f#",
	".......BBB######f##",
	".....BB#v#######f##",
	"..BBB###v#######f##",
	"BB######v#######f##",
	"#######v#######f###",
	"#######v#######f###",
	"######v########f###",
	"######v########f##%",
	"######v###e###ff##%",
	"######v##e.e##f##%.",
	"######v###e###f#%%.",
	"######v#######f#%..",
	"######vv######f%...",
	"#######v#####f#%...",
	"%###%%#v#####f%....",
	"%%%%%%%v%####f%....",
	".%%%..%%%%%##f.....",
	".........%%%f%.....",
	"...........%f......",
	"............f......",
]
## Tramo exterior (mano): muñeca en (1, 10); dedos a la punta, al festón medio y al bajo.
const OUT := [
	".....................BB",
	"...................BB%.",
	".................BB##%.",
	"..............BBB####..",
	"............BB#######..",
	"...........B#####e###..",
	".........BB#####e.e###.",
	"......BBBv#######e###%.",
	"....BB####v######ffffff",
	"...BB##ffffffffff##%%..",
	"Bffffff###########%%...",
	"##ff#############%%....",
	"####f#v##########%.....",
	"#####f#v########%......",
	"######ffv#######%......",
	"##%%%###fv#####%.......",
	"%%%%%%%%ff#####%.......",
	"%%...%%%%%f%###........",
	".........%%f%%#........",
	"............ff%........",
	"..............f........",
]


static func _mirror(rows: Array) -> Array:
	var out: Array = []
	for r: String in rows:
		out.append(r.reverse())
	return out


static func build() -> RigDef:
	var b := RigBuilder.new(&"cinder_bat", Vector2i(124, 128), Vector2i(68, 70), -1)
	b.material(&"fur", &"soot", {"texture": &"soot_grain"})
	b.material(&"skin", &"rock_soot")
	b.material(&"magma", &"hot")
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"wing_f", &"root", Vector2(-3, -6), {"z": -8.0})
	b.bone(&"wing_f2", &"wing_f", Vector2(-16, -12))
	b.bone(&"body", &"root", Vector2.ZERO)
	b.bone(&"head", &"body", Vector2(-3, -11), {"z": 4.0})
	b.bone(&"foot", &"body", Vector2(1, 8), {"z": -2.0})
	b.bone(&"wing_n", &"body", Vector2(3, -5), {"z": 8.0})
	b.bone(&"wing_n2", &"wing_n", Vector2(16, -12))
	b.bone(&"spark", &"root", Vector2.ZERO, {"z": 20.0})
	# Ala lejana: el espejo de la cercana, un paso más oscura (detrás de la cabeza).
	var far := {"#": [&"skin", 1], "%": [&"skin", 1], "f": [&"skin", 3], "v": [&"magma", 1], "e": [&"magma", 2], "B": [&"skin", 3]}
	b.slab(&"wing_f_in", &"wing_f", _mirror(IN), Vector2(-16, -12), far, 0.0, 1.0, 1.0)
	b.slab(&"wing_f_out", &"wing_f2", _mirror(OUT), Vector2(-21, -10), far, 0.0, 1.0, 1.0)
	# Cuerpo: tronco peludo pequeño, núcleo de brasa, patas colgando.
	b.stamp(&"feet", &"foot", Vector2.ZERO, ["k.k", "k.k", "h.h"], {"k": [&"skin", 3], "h": [&"skin", 5]}, {"anchor": Vector2i(1, 0)})
	b.ell(&"belly", &"body", &"fur", Vector3(0, 0, 0), Vector3(6.5, 9, 6), {"flat": 0.2})
	b.ell(&"scruff", &"body", &"fur", Vector3(-1, -7, 1), Vector3(6.5, 4.5, 5.5), {"line": false})
	b.stamp(&"core", &"body", Vector2(-2, 1), [
		".ff.",
		"fFFf",
		"fWFf",
		".ff.",
	], {"f": [&"fire", 3], "F": [&"fire", 5], "W": [&"fire", 7]}, {"anchor": Vector2i(2, 2), "z_top": false})
	# Cabeza: orejas grandes en punta, ojo de brasa, hocico chato y colmillos (mira a la izquierda).
	b.ell(&"skull", &"head", &"fur", Vector3(0, 0, 0), Vector3(6, 5, 5.5), {"tags": [&"face"]})
	b.slab(&"ear_n", &"head", ["...#", "..##", ".###", ".#a#", "##a#", "##a#"], Vector2(0, -10), {"#": &"fur", "a": [&"magma", 2]}, 5.0, 1.0, 1.0)
	b.slab(&"ear_f", &"head", ["#..", "##.", "##.", "###", "###"], Vector2(-6, -9), {"#": [&"skin", 3]}, -2.0, 1.0, 1.0)
	b.stamp(&"face", &"head", Vector2(-7, -2), [
		".kk....",
		"kWEk...",
		".kk....",
		"sn.....",
		"skkkkk.",
		".W.W...",
	], {"k": [&"fur", "LINE"], "W": [&"linen", 5], "E": [&"fire", 6], "s": [&"fur", 4], "n": [&"fur", 3], "m": [&"magma", 1]}, {"views": {
		&"open": [
		".kk....",
		"kWEk...",
		".kk....",
		"kkkkkk.",
		"kmmmmk.",
		"W.WmWk.",
		"...kk..",
	], &"shut": [
		".......",
		"kkk....",
		".......",
		"sn.....",
		"skkkkk.",
		".W.W...",
	]}, "z_top": false})
	# Ala cercana: dos tramos de membrana oscura llena, borde de ataque con canto cálido, dedos, venas y un agujero quemado.
	var near := {"#": [&"skin", 1], "%": [&"skin", 1], "f": [&"skin", 5], "v": [&"magma", 2], "e": [&"magma", 3], "B": [&"skin", 6]}
	b.slab(&"wing_n_in", &"wing_n", IN, Vector2(-2, -12), near, 0.0, 1.0, 1.0)
	b.slab(&"wing_n_out", &"wing_n2", OUT, Vector2(-1, -10), near, 0.0, 1.0, 1.0)
	# Chispas por los agujeros y pavesas de la muerte (rejilla 40×36 centrada en el cuerpo).
	b.stamp(&"sparks", &"spark", Vector2.ZERO, ["."], {"o": [&"fire", 4], "y": [&"fire", 6]}, {"anchor": Vector2i(20, 18), "views": {
		&"none": ["."],
		&"s0": _sparks([[30, 18, "o"], [33, 22, "y"]]),
		&"s1": _sparks([[30, 22, "y"], [34, 26, "o"]]),
		&"s2": _sparks([[29, 27, "o"], [35, 31, "o"]]),
		&"d0": _sparks([[6, 6, "y"], [24, 4, "o"], [10, 18, "y"], [32, 12, "y"], [20, 28, "o"], [14, 10, "y"], [28, 20, "o"], [4, 14, "o"]]),
		&"d1": _sparks([[3, 3, "o"], [25, 1, "y"], [8, 24, "y"], [35, 10, "o"], [22, 30, "o"], [13, 5, "y"], [30, 24, "y"]]),
		&"d2": _sparks([[1, 8, "o"], [22, 3, "o"], [6, 30, "o"], [36, 14, "o"], [20, 34, "y"]]),
	}})
	# Vuelo: el socket `ground` es el suelo bajo el cuerpo (idle:0); colocar el lienzo para que caiga en la línea de suelo.
	# Ceniza que queda en el suelo (sólo existe en la vista `pile`, último fotograma de la muerte).
	b.stamp(&"ash_pile", &"root", Vector2(-8, 20), ["."], {"a": [&"ash", 6], "A": [&"ash", 8], "d": [&"ash", 4], "e": [&"fire", 3]}, {"views": {
		&"pile": [
		"......aA.........",
		"...aaAAAaa..e....",
		".daaaAAaaaaad..a.",
		"ddaaaaaaaaaaaddd.",
	],
	}})
	b.socket(&"ground", &"root", Vector2(0, HOVER))
	b.socket(&"hit", &"head", Vector2(-8, 3))
	b.socket(&"intent", &"head", Vector2(0, -14))
	b.socket(&"core", &"body", Vector2(-2, 1))
	_anims(b)
	return b.def


## Filas de un sello de chispas sueltas ([x, y, char]) en una rejilla de 40×36.
static func _sparks(pts: Array) -> Array:
	var rows: Array = []
	for y in 36:
		rows.append(".".repeat(40))
	for p: Array in pts:
		var r: String = rows[p[1]]
		rows[p[1]] = r.substr(0, p[0]) + String(p[2]) + r.substr(p[0] + 1)
	return rows


## Pose de alas: a = ángulo (+ abajo), fold = pliegue del tramo exterior. Las alas son espejo: giran en sentidos opuestos.
static func _wings(a: float, fold: float, extra := {}) -> Dictionary:
	var k := {&"wing_n": a, &"wing_n2": fold, &"wing_f": -a * 0.9, &"wing_f2": -fold * 0.9}
	for e in extra.keys():
		k[e] = extra[e]
	return k


static func _anims(b: RigBuilder) -> void:
	# Aleteo de 6: golpe rápido hacia abajo (2 f), subida lenta (4 f); el cuerpo sube cuando el ala baja.
	var ang := [-0.35, 0.15, 0.6, 0.35, 0.05, -0.2]
	var fold := [-0.15, 0.1, 0.5, 0.45, 0.25, 0.0]
	var dy := [0, -2, -3, -2, -1, 0]
	var idle := {}
	for f in 6:
		var k := _wings(ang[f], fold[f], {&"@root": Vector2i(0, dy[f]), &"head": 0.05 * sin(TAU * f / 6.0), &"body": 0.04 * sin(TAU * f / 6.0)})
		k[&"view:spark"] = [&"none", &"s0", &"s1", &"s2", &"none", &"none"][f]
		k[&"view:head"] = &"shut" if f == 4 else StringName()
		k[&"emit:core"] = [0, 1, 1, 0, -1, 0][f]
		idle[f] = k
	b.anim(&"idle", 6, 140, idle, {"interp": &"linear", "overlap": {&"head": 1.0}})
	# Telegrafía: alas plegadas arriba, morro abajo, el núcleo se aviva.
	var c0 := _wings(-0.7, -0.5, {&"body": -0.25, &"head": -0.2, &"@root": Vector2i(3, -2), &"view:spark": &"none", &"view:head": &"open", &"emit:core": 1})
	var c1 := _wings(-0.85, -0.6, {&"body": -0.3, &"head": -0.25, &"@root": Vector2i(4, -3), &"view:spark": &"none", &"view:head": &"open", &"emit:core": 2})
	b.anim(&"cast", 2, [110, 300], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque (doble pasada): cae en picado, muerde, remonta, muerde otra vez.
	var a0 := c1.duplicate()
	var a1 := _wings(-1.0, -0.7, {&"body": -0.5, &"head": -0.3, &"@root": Vector2i(-16, 10), &"view:head": &"open", &"view:spark": &"none", &"emit:core": 2})
	var a2 := _wings(0.5, 0.4, {&"body": -0.1, &"@root": Vector2i(-20, 8), &"view:head": &"open", &"view:spark": &"s1", &"emit:core": 1})
	var a3 := _wings(-0.5, -0.3, {&"body": -0.2, &"@root": Vector2i(-8, -6), &"view:head": &"", &"view:spark": &"s0"})
	var a4 := _wings(0.4, 0.3, {&"body": -0.3, &"@root": Vector2i(-18, 8), &"view:head": &"open", &"view:spark": &"s2", &"emit:core": 1})
	var a5 := _wings(-0.1, 0.1, {&"@root": Vector2i(-6, 2), &"view:head": &"", &"view:spark": &"none"})
	b.anim(&"attack", 6, [100, 50, 80, 70, 80, 120], {0: a0, 1: a1, 2: a2, 3: a3, 4: a4, 5: a5}, {"loop": false, "interp": &"hold"})
	# Golpe: se encoge, alas revueltas, suelta chispas.
	b.anim(&"hurt", 2, [80, 130], {
		0: _wings(0.8, 0.6, {&"body": 0.3, &"head": 0.25, &"@root": Vector2i(4, 2), &"view:head": &"shut", &"view:spark": &"d1", &"emit:core": -1}),
		1: _wings(0.35, 0.25, {&"body": 0.12, &"@root": Vector2i(2, 1), &"view:head": &"", &"view:spark": &"s0"}),
	}, {"loop": false, "interp": &"hold"})
	# Muerte: las alas se deshacen en pavesas de fuera adentro; el núcleo se apaga mientras cae.
	var d := {}
	d[0] = _wings(0.8, 0.6, {&"body": 0.3, &"head": 0.25, &"@root": Vector2i(4, 2), &"view:head": &"shut", &"view:spark": &"d1"})
	d[1] = _wings(1.0, 0.9, {&"body": 0.3, &"head": 0.3, &"@root": Vector2i(3, 5), &"view:head": &"shut", &"view:spark": &"d0", &"hide:wing_f_out": true, &"emit:core": -1})
	d[2] = _wings(1.1, 1.0, {&"body": 0.3, &"head": 0.35, &"@root": Vector2i(3, 9), &"view:head": &"shut", &"view:spark": &"d0", &"hide:wing_f_out": true, &"hide:wing_n_out": true, &"emit:core": -2})
	d[3] = _wings(1.1, 1.0, {&"body": 0.3, &"head": 0.4, &"@root": Vector2i(3, 14), &"view:head": &"shut", &"view:spark": &"d1", &"hide:wing_f_out": true, &"hide:wing_n_out": true, &"hide:wing_f_in": true, &"emit:core": -3})
	d[4] = _wings(1.1, 1.0, {&"body": 0.3, &"head": 0.4, &"@root": Vector2i(3, 19), &"hide:skull": true, &"hide:ear_n": true, &"hide:ear_f": true, &"hide:face": true, &"view:head": &"shut", &"view:spark": &"d1", &"hide:wing_f_out": true, &"hide:wing_n_out": true, &"hide:wing_f_in": true, &"hide:wing_n_in": true, &"emit:core": -4})
	d[5] = {&"@root": Vector2i(3, 22), &"view:ash_pile": &"pile", &"view:spark": &"d2", &"hide:wing_f_out": true, &"hide:wing_n_out": true, &"hide:wing_f_in": true, &"hide:wing_n_in": true,
		&"hide:belly": true, &"hide:scruff": true, &"hide:skull": true, &"hide:ear_n": true, &"hide:ear_f": true, &"hide:face": true, &"hide:feet": true, &"hide:core": true}
	b.anim(&"death", 6, [80, 90, 100, 110, 130, 300], d, {"loop": false, "interp": &"hold"})
