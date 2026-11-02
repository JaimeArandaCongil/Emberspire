extends RefCounted
## LIMO DE CENIZA (`ash_slime`, acto 1) — PER · v0.4.
## Concepto: un charco de alquitrán con una COSTRA de ceniza pálida encima; por las grietas de la costra asoma la brasa.
## Silueta: gota baja y asimétrica (lomo alto atrás), chorretones por la base, cráter humeante, dos brasas por ojos, sin boca en reposo.
## ≈ 22×38 px; lienzo 100×68; suelo y = 58. Cuerpo: LOSA a mano con pasos forzados y dos deformaciones (aplastado/estirado) sin escalar en pantalla.
## Rasgo vivo (6 f): burbuja de humo del cráter, se aplasta al soltarla, brillo húmedo que recorre el flanco, parpadeo, goterón.
## Telegrafía (cast): se aplasta y abre los ojos. Ataque: se encoge, salta en arco, cae y salpica. Muerte: se extiende y se seca.

const BODY := [
	"..........................hhgg........",
	"......................hhhggkkgg.......",
	"....................hhhgkkkkkkgf......",
	"..................hhggkkFFFFkkgff.....",
	"................hhggffgkkFFkkgffdd....",
	"..............hhggfrfffgkkkkgfrfddc...",
	"............hhggfffrfffffgggffrrddcc..",
	"..........hhggffdrrfffggfffffffddccc..",
	"........hhggffdddrdffFgfffdddfdddccc..",
	".......hggffddcccddrrfffddcccdddcccb..",
	"......hgffddcccccddrdfdddcccccddcccb..",
	".....hgfddccccccccddddddcccccccccbbb..",
	"....gfddcccccccccccccccccccccccbbbbb..",
	"...gfdccccccccccccccccccccccbbbbbbbb..",
	"..gfdccccccccccccccccccccbbbbbbbbbbba.",
	".gfdcccccccccccccccccbbbbbbbbbbbbbbaa.",
	".fdccccccccccccccbbbbbbbbbbbbbbbbbaaa.",
	"fdcccccccbbbbbbbbbbbbbbbbbbbbbbaaaaaa.",
	"dccccbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa.",
	"cccbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaa.",
	"bbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaa.",
	".bbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaa.",
	"..aaaaaaaaaa...aaaaaaaaa..aaaaaaaa....",
	"...aaaa.........aaaa.......aaaa.......",
]
const PUDDLE := [
	"..........gggffddddffgg..dd.........",
	"....ddffffddddccccccccddddddcc......",
	"..dddcccccccccbbbbbbbbbbbbbbbbbaa...",
	"bbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaa.",
	".aaaaa...aaaaaaaaa....aaaaaaa...aa..",
]
const LEGEND := {
	"h": [&"ash", 9], "g": [&"ash", 7], "f": [&"ash", 6], "r": [&"fire", 4],
	"d": [&"tar", 5], "c": [&"tar", 4], "b": [&"tar", 3], "a": [&"tar", 2], "k": [&"tar", 0], "F": [&"fire", 5],
}


## Deforma la losa con vecino más próximo AL HORNEAR (sin escalar en pantalla). sx, sy: factores.
static func _scaled(rows: Array, sx: float, sy: float) -> Array:
	var w: int = String(rows[0]).length()
	var h: int = rows.size()
	var nw := int(round(w * sx))
	var nh := int(round(h * sy))
	var out: Array = []
	for y in nh:
		var src: String = rows[mini(h - 1, int(y / sy))]
		var line := ""
		for x in nw:
			var i := mini(w - 1, int(x / sx))
			line += src[i] if i < src.length() else "."
		out.append(line)
	return out


static func build() -> RigDef:
	var b := RigBuilder.new(&"ash_slime", Vector2i(100, 68), Vector2i(62, 55), -1)
	b.material(&"ash", &"ash")
	b.material(&"tar", &"coal")
	b.material(&"smoke", &"smoke", {"rim": false})
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	# Brazos de palanca: al girarlos, los ojos y el cráter suben o bajan con la deformación del cuerpo.
	b.bone(&"face_arm", &"root", Vector2(25, -7), {"z": 10.0})
	b.bone(&"crater_arm", &"root", Vector2(-25, -9), {"z": 10.0})
	b.bone(&"blob_l", &"root", Vector2(-26, 0), {"z": 12.0})
	b.bone(&"blob_r", &"root", Vector2(26, 0), {"z": 12.0})
	b.bone(&"drip", &"root", Vector2(-12, 2), {"z": 11.0})
	var sq := _scaled(BODY, 1.16, 0.75)
	var st := _scaled(BODY, 0.82, 1.25)
	var me := _scaled(BODY, 1.3, 0.45)
	b.slab(&"body", &"root", BODY, Vector2(-19, -21), LEGEND, 0.0, 1.0, 2.0)
	b.slab(&"body_sq", &"root", sq, Vector2(-22, 3 - sq.size()), LEGEND, 0.0, 1.0, 2.0)
	b.slab(&"body_st", &"root", st, Vector2(-16, 3 - st.size()), LEGEND, 0.0, 1.0, 2.0)
	b.slab(&"body_me", &"root", me, Vector2(-25, 3 - me.size()), LEGEND, 0.0, 1.0, 2.0)
	b.slab(&"puddle", &"root", PUDDLE, Vector2(-18, -2), LEGEND, 0.0, 1.0, 1.0)
	# Brillo húmedo del alquitrán (vistas: recorre el flanco).
	b.stamp(&"gloss", &"face_arm", Vector2(-41, 4), ["eee..", "..ee."], {"e": [&"tar", 5]}, {"views": {
		&"g0": ["eee..", "..ee."], &"g1": [".eee.", "...ee"], &"g2": ["..eee", "....e"]}, "z_top": true})
	# Ojos de brasa, hundidos y desiguales.
	var eyes := {"k": [&"tar", 0], "W": [&"fire", 7], "E": [&"fire", 5], "e": [&"fire", 3]}
	b.stamp(&"eyes", &"face_arm", Vector2(-33, -2), [
		".kkkk...kk.",
		"kWWEk..kWek",
		"kWEek..keek",
		".kkk....kk.",
	], eyes, {"anchor": Vector2i(1, 1), "views": {
		&"blink": [
			"...........",
			"kkkkk..kkkk",
			".eee....ee.",
			"...........",
		], &"wide": [
			".kkkkk...kkk.",
			"kWWWEk..kWWek",
			"kWWEek..kWEek",
			"kWEeek..keeek",
			".kkkk....kkk.",
		], &"shut": [
			"...........",
			"...........",
			"kkkkk..kkkk",
			"...........",
		]}})
	# Boca: sólo aparece al atacar (en reposo no tiene: da más miedo y evita la lectura de "muñequito").
	b.stamp(&"maw", &"face_arm", Vector2(-30, 4), [
		"kkkkkkkkk",
		"kWkWkkWkk",
		"kfffffffk",
		".kkkkkkk.",
	], {"k": [&"tar", 0], "W": [&"linen", 5], "f": [&"fire", 3]}, {"anchor": Vector2i(4, 0)})
	# Humo del cráter: burbujas que suben.
	for i in 3:
		var r := 1.6 + i * 0.7
		b.ell(StringName("puff_%d" % i), &"crater_arm", &"smoke", Vector3(35 + i, -14.0 - i * 3.2, 0), Vector3(r, r * 0.9, r), {"line": false, "flat": 0.4})
	b.stamp(&"drip", &"drip", Vector2.ZERO, ["s"], {"s": [&"tar", 3]}, {"views": {
		&"d0": ["s"], &"d1": ["s", "s"], &"d2": [".", "s", "s"], &"d3": [".", ".", ".", "s"]}})
	b.ell(&"splash_l", &"blob_l", &"tar", Vector3(0, 0, 0), Vector3(3.2, 2.2, 2.5), {"line": false})
	b.ell(&"splash_r", &"blob_r", &"tar", Vector3(0, -1, 0), Vector3(2.6, 1.8, 2.5), {"line": false})
	b.socket(&"hit", &"root", Vector2(-18, -4))
	b.socket(&"intent", &"root", Vector2(3, -20))
	b.socket(&"smoke", &"crater_arm", Vector2(35, -12))
	_anims(b)
	return b.def


## form: 0 normal · 1 aplastado · 2 estirado · 3 derretido · 4 sólo charco
static func _pose(form: int, root: Vector2i, extra := {}) -> Dictionary:
	var lift: float = [0.0, -0.09, 0.14, -0.28, -0.28][form]
	var k := {&"@root": root, &"face_arm": lift, &"crater_arm": -lift,
		&"hide:body": form != 0, &"hide:body_sq": form != 1, &"hide:body_st": form != 2, &"hide:body_me": form != 3,
		&"hide:puddle": form < 3, &"hide:splash_l": true, &"hide:splash_r": true, &"hide:maw": true,
		&"hide:puff_0": true, &"hide:puff_1": true, &"hide:puff_2": true, &"hide:gloss": form >= 3}
	for key in extra.keys():
		k[key] = extra[key]
	return k


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 6:
		var k := _pose(1 if f == 3 else 0, Vector2i.ZERO)
		k[&"view:face_arm"] = &"blink" if f == 5 else (&"g1" if f in [1, 2] else (&"g2" if f == 3 else &"g0"))
		k[&"view:drip"] = [&"d0", &"d1", &"d1", &"d2", &"d3", &"d0"][f]
		k[&"emit:body"] = 1 if f in [2, 3] else 0
		var bub := [-1, 0, 1, 1, 2, -1][f] as int
		for i in 3:
			k[StringName("hide:puff_%d" % i)] = i != bub
		idle[f] = k
	b.anim(&"idle", 6, 170, idle, {"interp": &"hold"})
	# Telegrafía: se aplasta, ojos enormes.
	b.anim(&"cast", 2, [140, 400], {
		0: _pose(1, Vector2i(0, 0), {&"view:face_arm": &"wide"}),
		1: _pose(1, Vector2i(1, 0), {&"view:face_arm": &"wide", &"hide:maw": false, &"emit:eyes": 1}),
	}, {"loop": false, "interp": &"hold"})
	# Ataque: encoge → estira y salta → arriba → cae delante y salpica → vuelve.
	b.anim(&"attack", 5, [120, 60, 70, 110, 150], {
		0: _pose(1, Vector2i(2, 0), {&"view:face_arm": &"wide"}),
		1: _pose(2, Vector2i(-6, -8), {&"view:face_arm": &"wide", &"hide:maw": false}),
		2: _pose(2, Vector2i(-14, -11), {&"view:face_arm": &"wide", &"hide:maw": false}),
		3: _pose(1, Vector2i(-20, 0), {&"view:face_arm": &"shut", &"hide:splash_l": false, &"hide:splash_r": false}),
		4: _pose(0, Vector2i(-12, 0), {&"view:face_arm": &"g0"}),
	}, {"loop": false, "interp": &"hold"})
	# Golpe: se abolla hacia atrás y salpica.
	b.anim(&"hurt", 2, [90, 150], {
		0: _pose(1, Vector2i(3, 0), {&"view:face_arm": &"shut", &"hide:splash_l": false, &"hide:splash_r": false}),
		1: _pose(0, Vector2i(2, 0), {&"view:face_arm": &"blink"}),
	}, {"loop": false, "interp": &"hold"})
	# Muerte: se extiende en un charco; las brasas se apagan; queda una mancha seca.
	var d := {}
	d[0] = _pose(1, Vector2i(2, 0), {&"view:face_arm": &"shut"})
	d[1] = _pose(1, Vector2i(0, 0), {&"view:face_arm": &"shut", &"emit:eyes": -1, &"emit:body_sq": -1})
	d[2] = _pose(3, Vector2i(0, 0), {&"view:face_arm": &"shut", &"emit:eyes": -2, &"emit:body_me": -1})
	d[3] = _pose(3, Vector2i(0, 0), {&"view:face_arm": &"shut", &"emit:eyes": -4, &"emit:body_me": -2})
	d[4] = _pose(4, Vector2i(0, 0), {&"hide:eyes": true, &"hide:body_me": true})
	d[5] = d[4].duplicate()
	d[5][&"hide:drip"] = true
	b.anim(&"death", 6, [80, 90, 110, 130, 200, 400], d, {"loop": false, "interp": &"hold"})
