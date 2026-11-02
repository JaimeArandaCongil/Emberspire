extends RefCounted
## POLILLA DE LLAMA (`flame_moth`, acto 1) — PER · v0.4.
## Concepto: una polilla adicta a tu fuego: cada carta que quemas enciende más los ocelos de sus alas (`on_burn str+1`).
## Silueta: alas grandes y REDONDAS de terciopelo (el murciélago las tiene en punta y raídas), cuerpo peludo gordo, antenas de pluma.
## ≈ 50×84 px de envergadura en un lienzo de 128×128. Vuela: socket `ground` = suelo bajo el cuerpo (idle:0).
## Rasgo vivo: aleteo lento de 6 fotogramas, polvo de escamas que cae, ocelos que laten.
## Animaciones: idle, react (al quemar: alas abiertas, ocelos al blanco), cast (bloqueo: se envuelve en las alas), attack, hurt, death.

const HOVER := 42

const FORE := [
	"................11111111...",
	".............1112222222211.",
	"...........1122222333332221",
	".........112222333333333321",
	"........12222333rrrrrr33321",
	".......12222333rrOOOOrr3321",
	"......122223333rOWWWWOr3321",
	".....1222233333rOWYYWOr3321",
	"....12222333333rOWWWWOr321.",
	"...122223333333rrOOOOrr321.",
	"..12222233333333rrrrrr321..",
	".122222233333333333322211..",
	"122222222333333222211......",
	"12222222222221111..........",
	".1111222211................",
	"......11...................",
]
const HIND := [
	"122222211......",
	"1222233222111..",
	".12223rr3322221",
	".1222rOr3333321",
	"..1222rr333321.",
	"...1122233321..",
	".....11111.....",
]


static func _mirror(rows: Array) -> Array:
	var out: Array = []
	for r: String in rows:
		out.append(r.reverse())
	return out


static func build() -> RigDef:
	var b := RigBuilder.new(&"flame_moth", Vector2i(128, 128), Vector2i(72, 68), -1)
	b.material(&"wing", &"cloth")
	b.material(&"fur", &"leather", {"texture": &"strands"})
	b.material(&"chitin", &"soot")
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"far_fore", &"root", Vector2(-2, -6), {"z": -8.0})
	b.bone(&"far_hind", &"root", Vector2(-2, -2), {"z": -9.0})
	b.bone(&"body", &"root", Vector2.ZERO)
	b.bone(&"abdomen", &"body", Vector2(1, 3), {"z": -1.0})
	b.bone(&"head", &"body", Vector2(-3, -10), {"z": 3.0})
	b.bone(&"near_hind", &"body", Vector2(3, -2), {"z": 7.0})
	b.bone(&"near_fore", &"body", Vector2(3, -6), {"z": 8.0})
	b.bone(&"dust", &"root", Vector2.ZERO, {"z": 20.0})
	# Alas lejanas: espejo, más oscuras y con el ocelo apagado (detrás del cuerpo).
	var far := {"1": [&"wing", 2], "2": [&"wing", 4], "3": [&"wing", 5], "r": [&"wing", 6], "O": [&"wing", 7], "W": [&"wing", 8], "Y": [&"wing", 8]}
	b.slab(&"ff", &"far_fore", _mirror(FORE), Vector2(-27, -15), far, 0.0, 1.0, 1.0)
	b.slab(&"fh", &"far_hind", _mirror(HIND), Vector2(-14, 0), far, 0.0, 1.0, 1.0)
	# Cuerpo: abdomen anillado que cuelga, tórax de pelo, cabeza con ojos enormes.
	b.ell(&"abd", &"abdomen", &"fur", Vector3(0, 6, 0), Vector3(5, 9, 5), {"flat": 0.3})
	b.stamp(&"rings", &"abdomen", Vector2(-3, 2), ["kkkkkk", "......", "......", ".kkkkk", "......", "......", "..kkk."], {"k": [&"fur", 2]}, {"z_top": false})
	b.ell(&"thorax", &"body", &"fur", Vector3(0, -4, 0), Vector3(7, 7, 6), {"flat": 0.2})
	b.ell(&"skull", &"head", &"chitin", Vector3(0, 0, 0), Vector3(4.5, 4, 4), {"tags": [&"eye"]})
	b.stamp(&"eyes", &"head", Vector2(-5, -2), [
		".kk...",
		"kWEk.k",
		"kEek.k",
		".kk...",
	], {"k": [&"chitin", 0], "W": [&"fire", 7], "E": [&"fire", 4], "e": [&"fire", 2]}, {"views": {
		&"shut": ["......", "kkkk..", "......", "......"]}})
	# Antenas de pluma (la firma de la cabeza).
	b.stamp(&"antennae", &"head", Vector2(-4, -5), [
		"h.h.........",
		".hkh...k.h..",
		"h.kh..hkh...",
		"..h.k.h.k...",
		"....kk..k...",
		"....k.......",
	], {"k": [&"fur", 3], "h": [&"fur", 5]}, {"anchor": Vector2i(4, 5)})
	# Alas cercanas: anterior con ocelo emisivo, posterior más pequeña. Rampa un paso más clara (F2-PULIDO-D: contraste ≥ 0,10).
	var near := {"1": [&"wing", 4], "2": [&"wing", 6], "3": [&"wing", 8], "r": [&"fire", 2], "O": [&"fire", 4], "W": [&"fire", 6], "Y": [&"fire", 7]}
	b.slab(&"nh", &"near_hind", HIND, Vector2(0, 0), near, 0.0, 1.0, 1.0)
	b.slab(&"nf", &"near_fore", FORE, Vector2(0, -15), near, 0.0, 1.0, 1.0)
	# Polvo de escamas: cae en bucle bajo las alas.
	b.stamp(&"powder", &"dust", Vector2.ZERO, ["."], {"o": [&"cloth", 8], "y": [&"fire", 4]}, {"anchor": Vector2i(20, 8), "views": {
		&"none": ["."],
		&"p0": _pts([[30, 18, "o"], [10, 20, "o"], [34, 26, "y"]]),
		&"p1": _pts([[30, 22, "o"], [10, 24, "o"], [34, 30, "o"]]),
		&"p2": _pts([[31, 26, "y"], [9, 28, "o"], [13, 18, "o"]]),
		&"p3": _pts([[31, 30, "o"], [9, 32, "y"], [13, 22, "y"]]),
		&"burst": _pts([[4, 6, "y"], [36, 6, "y"], [2, 14, "o"], [38, 12, "o"], [8, 22, "y"], [32, 22, "o"], [20, 30, "y"], [14, 28, "o"], [26, 34, "o"]]),
		&"ash": _pts([[8, 18, "o"], [14, 34, "o"], [30, 24, "o"], [26, 36, "y"], [36, 30, "o"]]),
	}})
	# Ceniza que queda en el suelo (sólo existe en la vista `pile`, último fotograma de la muerte).
	b.stamp(&"ash_pile", &"root", Vector2(-8, 12), ["."], {"a": [&"ash", 6], "A": [&"ash", 8], "d": [&"ash", 4], "e": [&"fire", 3]}, {"views": {
		&"pile": [
		"......aA.........",
		"...aaAAAaa..e....",
		".daaaAAaaaaad..a.",
		"ddaaaaaaaaaaaddd.",
	],
	}})
	b.socket(&"ground", &"root", Vector2(0, HOVER))
	b.socket(&"hit", &"head", Vector2(-6, 0))
	b.socket(&"intent", &"head", Vector2(0, -14))
	b.socket(&"ocelli", &"near_fore", Vector2(18, -7))
	_anims(b)
	return b.def


static func _pts(pts: Array) -> Array:
	var rows: Array = []
	for y in 40:
		rows.append(".".repeat(40))
	for p: Array in pts:
		var r: String = rows[p[1]]
		rows[p[1]] = r.substr(0, p[0]) + String(p[2]) + r.substr(p[0] + 1)
	return rows


## a = ángulo de las alas (+ abajo); las lejanas son espejo.
static func _w(a: float, extra := {}) -> Dictionary:
	var k := {&"near_fore": a, &"near_hind": a * 0.6, &"far_fore": -a * 0.9, &"far_hind": -a * 0.55}
	for e in extra.keys():
		k[e] = extra[e]
	return k


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 6:
		var t := TAU * f / 6.0
		var k := _w(-0.05 + 0.32 * sin(t), {&"@root": Vector2i(0, -1 if f in [1, 2] else 0), &"abdomen": 0.08 * sin(t - 1.0), &"head": 0.04 * sin(t)})
		k[&"view:dust"] = [&"none", &"p0", &"p1", &"p2", &"p3", &"none"][f]
		k[&"view:head"] = &"shut" if f == 5 else StringName()
		k[&"emit:nf"] = 0
		idle[f] = k
	b.anim(&"idle", 6, 160, idle, {"interp": &"hold"})
	# Reacción a quemar: alas abiertas de golpe, ocelos encendidos, polvo incandescente.
	b.anim(&"react", 3, [70, 110, 160], {
		0: _w(-0.45, {&"@root": Vector2i(0, -2), &"view:dust": &"burst", &"view:head": &"", &"emit:nf": 2}),
		1: _w(-0.6, {&"@root": Vector2i(0, -3), &"view:dust": &"burst", &"view:head": &"", &"emit:nf": 3}),
		2: _w(-0.3, {&"@root": Vector2i(0, -2), &"view:dust": &"p1", &"view:head": &""}),
	}, {"loop": false, "interp": &"hold"})
	# Bloqueo (cast): se envuelve en las alas, plegadas hacia abajo por delante del cuerpo.
	b.anim(&"cast", 2, [120, 340], {
		0: _w(0.7, {&"@root": Vector2i(1, 1), &"view:dust": &"none", &"view:head": &""}),
		1: _w(0.95, {&"@root": Vector2i(1, 2), &"view:dust": &"none", &"view:head": &""}),
	}, {"loop": false, "interp": &"hold"})
	# Ataque: se recoge, cae sobre el objetivo con las alas altas, sacude polvo.
	b.anim(&"attack", 4, [110, 50, 110, 140], {
		0: _w(-0.65, {&"@root": Vector2i(4, -5), &"view:dust": &"none", &"view:head": &""}),
		1: _w(-0.8, {&"body": -0.3, &"@root": Vector2i(-14, 4), &"view:dust": &"none", &"view:head": &""}),
		2: _w(0.45, {&"body": -0.4, &"head": -0.2, &"@root": Vector2i(-20, 6), &"view:dust": &"burst", &"view:head": &""}),
		3: _w(-0.1, {&"@root": Vector2i(-8, 1), &"view:dust": &"p2", &"view:head": &""}),
	}, {"loop": false, "interp": &"hold"})
	b.anim(&"hurt", 2, [80, 140], {
		0: _w(0.6, {&"body": 0.25, &"head": 0.2, &"abdomen": 0.3, &"@root": Vector2i(4, 2), &"view:dust": &"burst", &"view:head": &"shut"}),
		1: _w(0.2, {&"body": 0.1, &"@root": Vector2i(2, 1), &"view:dust": &"p1", &"view:head": &""}),
	}, {"loop": false, "interp": &"hold"})
	# Muerte: las alas arden hacia dentro; el cuerpo cae y queda ceniza.
	var d := {}
	d[0] = _w(0.6, {&"body": 0.25, &"@root": Vector2i(3, 2), &"view:dust": &"burst", &"view:head": &"shut"})
	d[1] = _w(0.9, {&"body": 0.25, &"@root": Vector2i(2, 7), &"view:dust": &"burst", &"view:head": &"shut", &"hide:ff": true})
	d[2] = _w(1.1, {&"body": 0.3, &"@root": Vector2i(2, 13), &"view:dust": &"ash", &"view:head": &"shut", &"hide:ff": true, &"hide:nf": true})
	d[3] = _w(1.1, {&"body": 0.3, &"@root": Vector2i(2, 20), &"view:dust": &"ash", &"view:head": &"shut", &"hide:ff": true, &"hide:nf": true, &"hide:fh": true, &"hide:nh": true})
	d[4] = _w(1.1, {&"body": 0.3, &"hide:skull": true, &"hide:eyes": true, &"@root": Vector2i(2, 24), &"view:dust": &"ash", &"view:head": &"shut", &"hide:ff": true, &"hide:nf": true, &"hide:fh": true, &"hide:nh": true, &"hide:antennae": true})
	d[5] = {&"@root": Vector2i(2, 26), &"view:ash_pile": &"pile", &"view:dust": &"ash", &"hide:ff": true, &"hide:nf": true, &"hide:fh": true, &"hide:nh": true, &"hide:antennae": true,
		&"hide:abd": true, &"hide:rings": true, &"hide:thorax": true, &"hide:skull": true, &"hide:eyes": true}
	b.anim(&"death", 6, [80, 90, 100, 110, 130, 300], d, {"loop": false, "interp": &"hold"})
