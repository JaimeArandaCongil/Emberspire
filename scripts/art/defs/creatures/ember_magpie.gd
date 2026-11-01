extends RefCounted
## URRACA ÍGNEA (`ember_magpie`, acto 1) — PER · v0.4.
## Concepto: una ladrona de brasas, posada, con el botín a la vista.
## Silueta: pájaro de cola larga y recta, pecho ceniza y una bolsita brillante en el pico/garra. ≈ 40×56 px; lienzo 88×64; suelo y = 58.
## Rasgo vivo: mira de lado a saltitos (gira la cabeza), guiña, la cola sube y baja, el botín destella.
## Telegrafía (cast, robar): abre el ala y fija la vista en tu fogón de cinto. Ataque: picotazo con salto. `flee`: salta y se va con el botín.
## Muerte: cae de espaldas, suelta el botín y las plumas.

static func build() -> RigDef:
	var b := RigBuilder.new(&"ember_magpie", Vector2i(88, 64), Vector2i(36, 40), -1)
	b.material(&"plume", &"coal", {"spec": true})
	b.material(&"sheen", &"wool_blue")
	b.material(&"chest", &"linen")
	b.material(&"beak", &"iron", {"tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return mini(st, 5)})
	b.material(&"leg", &"boot")
	b.material(&"pouch", &"leather", {"texture": &"scratches"})
	b.material(&"brass", &"brass")
	b.material(&"fire", &"fire")
	# --- esqueleto
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"leg_f", &"root", Vector2(3, 4), {"z": -5.0})
	b.bone(&"leg_n", &"root", Vector2(-2, 4), {"z": 5.0})
	b.bone(&"body", &"root", Vector2.ZERO, {"angle": 0.5})
	b.bone(&"tail", &"body", Vector2(10, 3), {"z": -3.0, "angle": -0.2})
	b.bone(&"head", &"body", Vector2(-10, -9), {"z": 4.0, "angle": -0.5})
	b.bone(&"wing", &"body", Vector2(-2, -6), {"z": 8.0})
	b.bone(&"wing2", &"wing", Vector2(14, 2))
	b.bone(&"pouch", &"body", Vector2(-9, 5), {"z": 10.0, "angle": -0.5})
	b.bone(&"feather", &"root", Vector2.ZERO, {"z": 20.0})
	# --- patas (tarsos finos y garras)
	for s: String in ["f", "n"]:
		var bn := StringName("leg_" + s)
		b.cap(StringName("tarsus_" + s), bn, &"leg", Vector3(0, 0, 0), Vector3(-1, 12, 0), 1.3, 0.9, {"ao": 1.4 if s == "f" else 1.0})
		b.stamp(StringName("claw_" + s), bn, Vector2(-1, 13), ["kkk.", "k.kk"], {"k": [&"leg", 2]}, {"anchor": Vector2i(2, 0), "z_top": s == "n"})
	# --- cola larga (losa a mano con barras claras: la firma de la silueta)
	b.slab(&"tail", &"tail", [
		"#########################..",
		"##%%%%%%%%%%%%%%%%%%%%#####",
		"##%%%%ssssssssssss%%%%%%%##",
		"##%%%%%%%%%%%%%%%%%%%%#####",
		"#########################..",
	], Vector2(0, -2), {"#": &"plume", "%": &"plume", "s": &"sheen"}, 0.0, 1.5, 2.0)
	# --- cuerpo: dorso de pluma negra azulada + pecho de ceniza
	b.ell(&"back", &"body", &"plume", Vector3(2, -2, 0), Vector3(12.5, 9, 7), {"flat": 0.3})
	b.ell(&"breast", &"body", &"chest", Vector3(-4, 3, 2), Vector3(9, 7.5, 6), {"flat": 0.3, "line": false})
	# --- cabeza: negra, pico robusto, ojo dorado (sello), vista normal / de lado / guiño
	b.ell(&"skull", &"head", &"plume", Vector3(0, 0, 0), Vector3(5.5, 5, 5), {"tags": [&"eye"]})
	b.poly(&"beak_up", &"head", &"beak", PackedVector2Array([Vector2(-4, -2), Vector2(-13, 1), Vector2(-4, 2)]), 4.0, 1.0, 1.0)
	b.poly(&"beak_lo", &"head", &"beak", PackedVector2Array([Vector2(-4, 2), Vector2(-11, 2), Vector2(-4, 4)]), 3.5, 1.0, 1.0, {"ao": 1.5})
	var eye_l := {"k": [&"plume", "LINE"], "w": [&"brass", 4], "W": [&"brass", 5], "E": [&"plume", 0]}
	b.stamp(&"eye", &"head", Vector2(-2, -2), [
		".kkk.",
		"kWEEk",
		"kwEEk",
		".kkk.",
	], eye_l, {"anchor": Vector2i(2, 1), "z_top": false, "views": {
		&"side": [
		".kkk.",
		"kEWWk",
		"kEEwk",
		".kkk.",
	], &"wink": [
		".....",
		"kkkkk",
		".....",
		".....",
	], &"fix": [
		"kkkk.",
		"kWWEk",
		"kwWEk",
		".kkk.",
	], &"dead": [
		"k...k",
		".k.k.",
		"..k..",
		".k.k.",
	]}})
	b.stamp(&"sheen_head", &"head", Vector2(0, -5), ["sSs"], {"s": [&"sheen", 2], "S": [&"sheen", 3]}, {"z_top": false, "anchor": Vector2i(1, 0)})
	# --- ala plegada: dos tramos de losa con filo de cobertoras claras y reflejo azul
	b.slab(&"wing_a", &"wing", [
		"....#######....",
		"..##########...",
		".#####sss#####.",
		"####ss#####sss##",
		"###s####sss#####",
		"##ss##ss########",
		"WWW#WW#WW#WW#W#.",
		".WWWWWWWWWWWW..",
	], Vector2(-3, -2), {"#": &"plume", "s": &"sheen", "S": [&"sheen", 3], "W": [&"chest", 5], "%": &"plume"}, 0.0, 1.2, 1.0)
	b.slab(&"wing_b", &"wing2", [
		"#########.",
		"###########.",
		"..s##########",
		"....ss#######",
		".......####",
	], Vector2(-2, 0), {"#": &"plume", "s": &"sheen"}, 0.0, 1.2, 1.0)
	# --- botín: bolsita de cuero con brasa y moneda, colgada del pecho
	b.ell(&"sack", &"pouch", &"pouch", Vector3(0, 3, 0), Vector3(3.6, 4, 3))
	b.stamp(&"sack_tie", &"pouch", Vector2(-2, -1), ["kkkkk", ".BbB."], {"k": [&"pouch", 1], "B": [&"brass", 5], "b": [&"brass", 3]}, {})
	b.stamp(&"loot", &"pouch", Vector2(-1, 2), [".f.", "fFf", ".f."], {"f": [&"fire", 4], "F": [&"fire", 7]}, {"z_top": false})
	# --- plumas sueltas de la muerte y del golpe (sello con vistas)
	b.stamp(&"feathers", &"feather", Vector2.ZERO, ["."], {"p": [&"plume", 3], "w": [&"chest", 4], "s": [&"sheen", 2]}, {"anchor": Vector2i(20, 24), "views": {
		&"none": ["."],
		&"p0": _pts([[6, 10, "p"], [7, 10, "p"], [34, 8, "w"], [35, 8, "w"], [20, 4, "s"], [21, 4, "p"]]),
		&"p1": _pts([[4, 16, "p"], [5, 16, "p"], [35, 14, "w"], [36, 14, "w"], [22, 12, "p"], [23, 12, "s"], [12, 6, "w"], [13, 6, "w"]]),
		&"p2": _pts([[3, 24, "p"], [4, 24, "p"], [36, 22, "w"], [37, 22, "w"], [24, 20, "p"], [25, 20, "s"], [11, 16, "w"], [12, 16, "w"]]),
	}})
	b.socket(&"hit", &"head", Vector2(-14, 1))
	b.socket(&"intent", &"head", Vector2(0, -10))
	b.socket(&"loot", &"pouch", Vector2(0, 3))
	_anims(b)
	return b.def


static func _pts(pts: Array) -> Array:
	var rows: Array = []
	for y in 34:
		rows.append(".".repeat(42))
	for p: Array in pts:
		var r: String = rows[p[1]]
		rows[p[1]] = r.substr(0, p[0]) + String(p[2]) + r.substr(p[0] + 1)
	return rows


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 8:
		var k := {}
		k[&"@root"] = Vector2i(0, 1 if f in [3, 4] else 0)
		k[&"body"] = 0.03 * sin(TAU * f / 8.0)
		k[&"tail"] = [0.0, 0.05, 0.14, 0.08, 0.0, -0.06, -0.1, -0.04][f]
		k[&"head"] = [0.0, 0.0, -0.12, -0.12, -0.12, 0.05, 0.05, 0.0][f]    # gira a saltos, no suave
		k[&"view:head"] = [&"", &"", &"side", &"side", &"", &"", &"wink", &""][f]
		k[&"pouch"] = 0.08 * sin(TAU * f / 8.0)
		k[&"emit:loot"] = [0, 0, 1, 2, 1, 0, 0, 0][f]
		k[&"view:feather"] = &"none"
		idle[f] = k
	b.anim(&"idle", 8, 140, idle, {"interp": &"hold", "overlap": {}})
	# Telegrafía de robo: se agacha, abre el ala, fija la mirada.
	var c0 := {&"body": -0.25, &"head": 0.1, &"wing": -1.0, &"wing2": -0.6, &"tail": 0.3, &"@root": Vector2i(1, 2), &"view:head": &"fix", &"view:feather": &"none", &"emit:loot": 1, &"z:wing": 4.0}
	var c1 := c0.duplicate()
	c1[&"wing"] = -1.35
	c1[&"wing2"] = -0.75
	c1[&"@root"] = Vector2i(1, 3)
	b.anim(&"cast", 2, [120, 340], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: se recoge, salta y picotea.
	var a0 := {&"body": 0.2, &"head": -0.2, &"tail": -0.3, &"@root": Vector2i(3, 2), &"view:head": &"fix", &"view:feather": &"none"}
	var a1 := {&"body": -0.35, &"head": -0.15, &"wing": -0.9, &"wing2": -0.4, &"tail": -0.2, &"@root": Vector2i(-10, -9), &"view:head": &"fix", &"view:feather": &"none"}
	var a2 := {&"body": -0.6, &"head": -0.35, &"wing": -0.5, &"tail": -0.35, &"@root": Vector2i(-18, -2), &"view:head": &"fix", &"view:feather": &"none", &"emit:loot": 2}
	var a3 := {&"body": -0.2, &"head": -0.1, &"wing": -0.2, &"tail": 0.1, &"@root": Vector2i(-10, 0), &"view:feather": &"none"}
	b.anim(&"attack", 4, [110, 60, 100, 150], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 2, &"head", Vector2(-14, 1), &"brass", 5.0, false).samples = 32
	# Huida (flee): salta con el botín y sale hacia atrás-arriba.
	var fl := {}
	fl[0] = {&"body": 0.3, &"wing": -1.1, &"wing2": -0.5, &"tail": -0.35, &"@root": Vector2i(3, 2), &"view:head": &"side", &"view:feather": &"none"}
	fl[1] = {&"body": 0.2, &"wing": -1.6, &"wing2": -0.9, &"tail": -0.3, &"@root": Vector2i(8, -10), &"view:head": &"side", &"view:feather": &"none"}
	fl[2] = {&"body": 0.25, &"wing": 0.0, &"wing2": 0.3, &"tail": -0.2, &"@root": Vector2i(14, -18), &"view:head": &"side", &"view:feather": &"none"}
	fl[3] = {&"body": 0.3, &"wing": -1.5, &"wing2": -0.8, &"tail": -0.3, &"@root": Vector2i(22, -28), &"view:head": &"side", &"view:feather": &"none"}
	b.anim(&"flee", 4, [100, 80, 80, 90], fl, {"loop": false, "interp": &"hold"})
	var h0 := {&"body": 0.4, &"head": 0.35, &"wing": -0.5, &"tail": -0.5, &"@root": Vector2i(4, 1), &"view:head": &"wink", &"view:feather": &"p0"}
	var h1 := {&"body": 0.15, &"head": 0.1, &"wing": -0.15, &"tail": -0.2, &"@root": Vector2i(2, 0), &"view:feather": &"p1"}
	b.anim(&"hurt", 2, [90, 140], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte: se desploma hacia delante sobre el pecho, suelta el botín, la cola queda alzada; las plumas bajan.
	var d := {}
	d[0] = h0.duplicate()
	d[1] = {&"body": -0.3, &"head": -0.2, &"wing": -0.5, &"tail": 0.1, &"@root": Vector2i(0, 3), &"view:head": &"dead", &"view:feather": &"p0", &"pouch": 0.4, &"emit:loot": 1}
	d[2] = {&"body": -0.6, &"head": -0.35, &"wing": -0.6, &"tail": 0.2, &"@root": Vector2i(-1, 5), &"view:head": &"dead", &"view:feather": &"p1", &"pouch": 0.8}
	d[3] = {&"body": -0.85, &"head": -0.45, &"wing": -0.4, &"tail": 0.3, &"@root": Vector2i(-2, 7), &"view:head": &"dead", &"view:feather": &"p1", &"pouch": 1.1,
		&"hide:tarsus_n": true, &"hide:tarsus_f": true, &"hide:claw_n": true, &"hide:claw_f": true}
	d[4] = {&"body": -0.95, &"head": -0.5, &"wing": -0.2, &"tail": 0.35, &"@root": Vector2i(-2, 8), &"view:head": &"dead", &"view:feather": &"p2", &"pouch": 1.2,
		&"hide:tarsus_n": true, &"hide:tarsus_f": true, &"hide:claw_n": true, &"hide:claw_f": true}
	d[5] = d[4].duplicate()
	d[5][&"emit:loot"] = -2
	b.anim(&"death", 6, [80, 90, 100, 110, 160, 400], d, {"loop": false, "interp": &"hold"})
