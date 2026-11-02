extends RefCounted
## URRACA ÍGNEA (`ember_magpie`, acto 1) — PER · v0.4.
## Concepto: una ladrona de brasas, posada, con el botín a la vista.
## Silueta: pájaro erguido de patas altas, cola larga ahorquillada y bolsita brillante en el pecho. ≈ 50 px de alto (medio, §8); lienzo 124×96; suelo y = 88.
## Rasgo vivo: ladea la cabeza a saltitos, guiña, la cola sube y baja, el botín destella.
## Telegrafía (cast, robar): abanica el ala en tres primarias y fija la vista en tu fogón de cinto. Ataque: picotazo con salto. `flee`: salta y se va con el botín.
## Muerte por material: estalla en plumas, cae sobre el costado, el botín rueda fuera y la brasa se apaga por pasos mientras bajan las plumas.

static func build() -> RigDef:
	var b := RigBuilder.new(&"ember_magpie", Vector2i(124, 96), Vector2i(58, 64), -1)
	b.material(&"plume", &"coal", {"spec": true})
	b.material(&"sheen", &"wool_blue")
	b.material(&"chest", &"linen")
	b.material(&"beak", &"iron", {"tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return mini(st + 1, 6)})
	b.material(&"leg", &"leather")
	b.material(&"pouch", &"leather", {"texture": &"scratches"})
	b.material(&"brass", &"brass")
	b.material(&"fire", &"fire")
	# --- esqueleto
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"leg_f", &"root", Vector2(3, 4), {"z": -5.0})
	b.bone(&"leg_n", &"root", Vector2(-2, 4), {"z": 5.0})
	b.bone(&"body", &"root", Vector2.ZERO, {"angle": 0.72})
	b.bone(&"tail", &"body", Vector2(11, 2), {"z": -3.0, "angle": -0.28})
	b.bone(&"head", &"body", Vector2(-11, -11), {"z": 4.0, "angle": -0.72})
	b.bone(&"wing", &"body", Vector2(-2, -6), {"z": 8.0})
	b.bone(&"wing2", &"wing", Vector2(14, 2))
	b.bone(&"pouch", &"body", Vector2(-8, 6), {"z": 10.0, "angle": -0.72})
	b.bone(&"feather", &"root", Vector2.ZERO, {"z": 20.0})
	# --- patas (tarsos finos y garras)
	for s: String in ["f", "n"]:
		var bn := StringName("leg_" + s)
		b.cap(StringName("tarsus_" + s), bn, &"leg", Vector3(0, 0, 0), Vector3(2, 8, 0), 2.2, 1.3, {"ao": 1.4 if s == "f" else 1.0})
		b.cap(StringName("shank_" + s), bn, &"leg", Vector3(2, 8, 0), Vector3(-1, 18, 0), 1.3, 1.0, {"ao": 1.4 if s == "f" else 1.0})
		b.stamp(StringName("claw_" + s), bn, Vector2(-1, 19), ["kkk.", "k.kk"], {"k": [&"leg", 3]}, {"anchor": Vector2i(2, 0), "z_top": s == "n"})
	# --- cola larga: tres plumas, extremo abierto en tres puntas (la firma de la silueta)
	b.slab(&"tail", &"tail", [
		"########################........",
		"##%%%%%%%%%%%%%%%%%%%%%%####....",
		"##%%%%ssssssssssss%%%%%%%%%#####",
		"##%%%%%%%%%%%%%%%%%%%%%%%#####..",
		"##########################......",
		"##%%%%ssssssssssss%%%%%%######..",
		"##%%%%%%%%%%%%%%%%%%%%####......",
		"#####################...........",
	], Vector2(0, -3), {"#": &"plume", "%": &"plume", "s": &"sheen"}, 0.0, 1.2, 2.0)
	# Dos plumas cortas de transición: la cola nace del cuerpo, no se pega.
	b.poly(&"tail_cov_a", &"body", &"plume", PackedVector2Array([Vector2(6, -6), Vector2(22, -3), Vector2(19, 1), Vector2(6, 2)]), 2.0, 1.2, 2.0, {"line": false})
	b.poly(&"tail_cov_b", &"body", &"sheen", PackedVector2Array([Vector2(7, 1), Vector2(21, 2), Vector2(17, 6), Vector2(6, 6)]), 2.0, 1.2, 2.0, {"line": false})
	# --- cuerpo: dorso de pluma negra azulada + pecho de ceniza
	b.ell(&"back", &"body", &"plume", Vector3(2, -2, 0), Vector3(14.5, 10.5, 8), {"flat": 0.35})
	b.poly(&"breast", &"body", &"chest", PackedVector2Array([Vector2(-15, 2), Vector2(-14, -5), Vector2(-7, -8), Vector2(1, -5), Vector2(6, 2), Vector2(4, 8), Vector2(-5, 10), Vector2(-12, 8)]), 2.0, 3.5, 6.0, {"line": false})
	# Cuello: la cabeza se funde con el cuerpo, ya no es un gorro.
	b.cap(&"neck", &"body", &"plume", Vector3(-3, -5, 3), Vector3(-10, -10, 3), 6.5, 5.5, {"line": false})
	# Collar dentado de plumaje oscuro sobre el blanco; grupos de plumas de 2 px en el paso inferior del pecho.
	b.stamp(&"collar", &"body", Vector2(-18, 0), [
		"kkkkkkkkkkkkkk",
		"kkkkkkkkkkkkkk",
		"kk.kkkk.kkk.kk",
		"k...kk...k...k",
		"....k.........",
	], {"k": [&"plume", 2]}, {"z_top": false})
	b.stamp(&"breast_tufts", &"body", Vector2(-13, 6), [
		"...........",
		".dd.....dd.",
		"..d......d.",
		"...........",
		".....dd....",
		"......d....",
		".dd........",
		"..d.....dd.",
		".........d.",
	], {"d": [&"chest", 3]}, {"z_top": false})
	# --- cabeza: negra, pico robusto, ojo dorado (sello), vista normal / de lado / guiño
	b.ell(&"skull", &"head", &"plume", Vector3(0, 0, 0), Vector3(5.5, 5, 5), {"tags": [&"eye"]})
	b.poly(&"beak_up", &"head", &"beak", PackedVector2Array([Vector2(-3, -3), Vector2(-16, 1), Vector2(-3, 2)]), 4.0, 1.0, 1.5)
	b.poly(&"beak_lo", &"head", &"beak", PackedVector2Array([Vector2(-3, 2), Vector2(-14, 2), Vector2(-3, 5)]), 3.5, 1.0, 1.0, {"ao": 1.5})
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
	], Vector2(-2, 0), {"#": &"plume", "s": &"sheen"}, 0.0, 1.2, 1.0, {"views": {
		# Abanico: tres primarias separadas por muescas de 1 px, en lugar de una pala.
		&"fan": [
		"######sss#####....",
		"#####s##########..",
		"#####ss###########",
		"###########.......",
		"######s###########",
		"#####ss###########",
		"#####sss#########.",
		"###########.......",
		"#####s###########.",
		"####ss##########..",
		"...###ss#####.....",
	]}})
	# --- botín: bolsita de cuero con brasa y moneda, colgada del pecho
	b.ell(&"sack", &"pouch", &"pouch", Vector3(0, 3, 0), Vector3(3.6, 4, 3))
	b.stamp(&"sack_tie", &"pouch", Vector2(-2, -1), ["kkkkk", ".BbB."], {"k": [&"pouch", 1], "B": [&"brass", 5], "b": [&"brass", 3]}, {})
	b.stamp(&"loot", &"pouch", Vector2(-2, 1), ["..h..", ".hfh.", "hfFfh", ".hfh.", "..h.."], {"h": [&"fire", 2], "f": [&"fire", 4], "F": [&"fire", 7]}, {"z_top": false})
	# El botín caído (muerte): bolsita rota y brasa suelta en el suelo. Con @root = (0, 14), y local 10 = suelo.
	b.stamp(&"loot_down", &"feather", Vector2(-40, 4), ["..kk...hh..", ".kbbk.hffh.", "kbbbbkfFFfh", "kbbbb.hffh."], {"k": [&"pouch", 1], "b": [&"pouch", 3], "h": [&"fire", 2], "f": [&"fire", 4], "F": [&"fire", 7]}, {})
	# --- plumas sueltas de la muerte y del golpe (sello con vistas)
	b.stamp(&"feathers", &"feather", Vector2.ZERO, ["."], {"p": [&"plume", 3], "w": [&"chest", 4], "s": [&"sheen", 2]}, {"anchor": Vector2i(32, 40), "views": {
		&"none": ["."],
		&"p0": _pts([[16, 16, "p"], [17, 16, "p"], [46, 12, "w"], [47, 12, "w"], [30, 8, "s"], [31, 8, "p"], [38, 20, "w"]]),
		&"p1": _pts([[10, 22, "p"], [11, 23, "p"], [50, 20, "w"], [51, 20, "w"], [32, 14, "p"], [33, 14, "s"], [22, 10, "w"], [23, 10, "w"], [42, 26, "s"]]),
		&"p2": _pts([[8, 30, "p"], [9, 31, "p"], [52, 28, "w"], [53, 29, "w"], [34, 24, "p"], [35, 24, "s"], [20, 22, "w"], [21, 23, "w"], [44, 34, "s"], [28, 36, "p"]]),
		&"p3": _pts([[6, 38, "p"], [7, 38, "p"], [54, 38, "w"], [55, 38, "w"], [34, 34, "p"], [35, 35, "s"], [18, 34, "w"], [19, 35, "w"], [44, 42, "s"], [28, 44, "p"]]),
		&"p4": _pts([[4, 48, "p"], [5, 48, "p"], [56, 47, "w"], [57, 47, "w"], [36, 48, "p"], [37, 48, "s"], [16, 46, "w"], [17, 47, "w"], [46, 48, "s"], [26, 48, "p"]]),
	}})
	b.socket(&"hit", &"head", Vector2(-14, 1))
	b.socket(&"intent", &"head", Vector2(0, -10))
	b.socket(&"loot", &"pouch", Vector2(0, 3))
	_anims(b)
	return b.def


static func _pts(pts: Array) -> Array:
	var rows: Array = []
	for y in 54:
		rows.append(".".repeat(64))
	for p: Array in pts:
		var r: String = rows[p[1]]
		rows[p[1]] = r.substr(0, p[0]) + String(p[2]) + String(p[2]) + r.substr(p[0] + 2)
		var r2: String = rows[p[1] + 1]
		rows[p[1] + 1] = r2.substr(0, p[0] + 1) + String(p[2]) + r2.substr(p[0] + 2)
	return rows


static func _anims(b: RigBuilder) -> void:
	# Reposo: el cuerpo no se mece; viven la cabeza (1 px a saltos), la cola y el botín.
	var idle := {}
	for f in 6:
		var k := {}
		k[&"@root"] = Vector2i(0, 1 if f == 3 else 0)
		k[&"tail"] = [0.0, 0.1, 0.16, 0.06, -0.08, -0.04][f]
		k[&"head"] = [0.0, -0.12, -0.12, 0.0, 0.08, 0.0][f]
		k[&"view:head"] = [&"", &"side", &"side", &"", &"wink", &""][f]
		k[&"emit:loot"] = [0, 1, 2, 1, 0, 0][f]
		k[&"view:feather"] = &"none"
		k[&"hide:loot_down"] = true
		idle[f] = k
	b.anim(&"idle", 6, [180, 160, 200, 160, 140, 180], idle, {"interp": &"hold"})
	# Telegrafía de robo: se agacha, abanica el ala, fija la mirada.
	var c0 := {&"body": -0.25, &"head": 0.1, &"wing": -1.0, &"wing2": -0.6, &"tail": 0.3, &"@root": Vector2i(1, 2), &"view:head": &"fix", &"view:feather": &"none", &"emit:loot": 1, &"z:wing": 4.0, &"view:wing_b": &"fan", &"hide:collar": true, &"hide:breast_tufts": true, &"hide:loot_down": true}
	var c1 := c0.duplicate()
	c1[&"wing"] = -1.35
	c1[&"wing2"] = -0.75
	c1[&"@root"] = Vector2i(1, 3)
	b.anim(&"cast", 2, [120, 340], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: se recoge, salta y picotea.
	var off := {&"hide:collar": true, &"hide:breast_tufts": true, &"view:feather": &"none", &"hide:loot_down": true}
	var a0 := {&"body": 0.2, &"head": -0.2, &"tail": -0.3, &"@root": Vector2i(3, 2), &"view:head": &"fix"}
	var a1 := {&"body": -0.35, &"head": -0.15, &"wing": -0.9, &"wing2": -0.4, &"tail": -0.2, &"@root": Vector2i(-10, -9), &"view:head": &"fix", &"view:wing_b": &"fan"}
	var a2 := {&"body": -0.6, &"head": -0.35, &"wing": -0.5, &"tail": -0.35, &"@root": Vector2i(-18, -2), &"view:head": &"fix", &"emit:loot": 2}
	var a3 := {&"body": -0.2, &"head": -0.1, &"wing": -0.2, &"tail": 0.1, &"@root": Vector2i(-10, 0)}
	for k2: Dictionary in [a0, a1, a2, a3]:
		k2.merge(off)
	b.anim(&"attack", 4, [110, 60, 100, 150], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 2, &"head", Vector2(-14, 1), &"brass", 5.0, false).samples = 32
	# Huida (flee): salta con el botín y sale hacia atrás-arriba, sin salirse de la celda.
	var fl := {}
	fl[0] = {&"body": 0.3, &"wing": -1.1, &"wing2": -0.5, &"tail": -0.35, &"@root": Vector2i(3, 2), &"view:head": &"side", &"view:wing_b": &"fan"}
	fl[1] = {&"body": 0.2, &"wing": -1.6, &"wing2": -0.9, &"tail": -0.3, &"@root": Vector2i(6, -10), &"view:head": &"side", &"view:wing_b": &"fan"}
	fl[2] = {&"body": 0.25, &"wing": 0.0, &"wing2": 0.3, &"tail": -0.2, &"@root": Vector2i(10, -18), &"view:head": &"side"}
	fl[3] = {&"body": 0.3, &"wing": -1.5, &"wing2": -0.8, &"tail": -0.3, &"@root": Vector2i(14, -26), &"view:head": &"side", &"view:wing_b": &"fan"}
	for k3: int in fl.keys():
		(fl[k3] as Dictionary).merge(off)
	b.anim(&"flee", 4, [100, 80, 80, 90], fl, {"loop": false, "interp": &"hold"})
	var h0 := {&"body": 0.4, &"head": 0.35, &"wing": -0.5, &"tail": -0.5, &"@root": Vector2i(4, 1), &"view:head": &"wink", &"view:feather": &"p0", &"hide:collar": true, &"hide:breast_tufts": true, &"hide:loot_down": true}
	var h1 := {&"body": 0.15, &"head": 0.1, &"wing": -0.15, &"tail": -0.2, &"@root": Vector2i(2, 0), &"view:feather": &"p1", &"hide:loot_down": true, &"hide:collar": true, &"hide:breast_tufts": true}
	b.anim(&"hurt", 2, [90, 140], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte por material: estalla en plumas → cae de costado → el botín rueda fuera → plumas al suelo → la brasa se apaga por pasos.
	var gone := {&"hide:tarsus_n": true, &"hide:tarsus_f": true, &"hide:shank_n": true, &"hide:shank_f": true, &"hide:claw_n": true, &"hide:claw_f": true, &"hide:collar": true, &"hide:breast_tufts": true, &"hide:sack": true, &"hide:sack_tie": true, &"hide:loot": true}
	var d := {}
	d[0] = {&"body": 0.4, &"head": 0.35, &"wing": -0.9, &"wing2": -0.5, &"tail": -0.5, &"@root": Vector2i(3, 1), &"view:head": &"wink", &"view:wing_b": &"fan", &"view:feather": &"p0", &"hide:collar": true, &"hide:breast_tufts": true, &"hide:loot_down": true, &"emit:loot": 2}
	d[1] = {&"body": -0.5, &"head": -0.25, &"wing": -0.7, &"tail": 0.1, &"@root": Vector2i(1, 5), &"view:head": &"dead", &"view:feather": &"p1", &"pouch": 0.5, &"hide:collar": true, &"hide:breast_tufts": true, &"hide:loot_down": true}
	d[2] = {&"body": -0.95, &"head": -0.4, &"wing": -0.5, &"tail": 0.3, &"@root": Vector2i(0, 10), &"view:head": &"dead", &"view:feather": &"p2", &"hide:collar": true, &"hide:breast_tufts": true, &"hide:loot_down": true, &"pouch": 0.9,
		&"hide:tarsus_n": true, &"hide:tarsus_f": true, &"hide:shank_n": true, &"hide:shank_f": true, &"hide:claw_n": true, &"hide:claw_f": true}
	d[3] = {&"body": -1.25, &"head": -0.5, &"wing": -0.2, &"tail": 0.4, &"@root": Vector2i(0, 14), &"view:head": &"dead", &"view:feather": &"p3"}
	d[3].merge(gone)
	d[3][&"hide:loot_down"] = false
	d[4] = d[3].duplicate()
	d[4][&"view:feather"] = &"p4"
	d[4][&"tail"] = 0.46
	d[5] = d[4].duplicate()
	d[5][&"emit:loot_down"] = -1
	d[6] = d[5].duplicate()
	d[6][&"emit:loot_down"] = -3
	d[7] = d[6].duplicate()
	d[7][&"emit:loot_down"] = -6
	b.anim(&"death", 8, [80, 90, 100, 110, 130, 160, 220, 400], d, {"loop": false, "interp": &"hold"})
