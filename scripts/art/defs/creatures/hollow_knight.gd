extends RefCounted
## CABALLERO HUECO (`hollow_knight`, élite, acto 1) — PER · v0.4.
## Concepto: una armadura vacía que siguió guardando la torre. Dentro no hay nadie: sólo una brasa.
## Silueta: yelmo de cubo alto, hombrera enorme, escudo torre delante y espadón caído detrás, capa raída.
## ≈ 92 px de alto en un lienzo de 120×112; pies en y = 104; mira a la izquierda.
## Rasgo vivo: la brasa del pecho (se ve por el boquete de la coraza) y la del visor respiran; la capa se mece con la corriente.
## Telegrafía (cast, Fuerza + Bloqueo): planta el escudo y alza el espadón en vertical. Muerte: la armadura se derrumba y la brasa es lo último.

static func _iron(_l: Vector2, st: int, _n: int) -> int:
	# Hierro ennegrecido: dos pasos más oscuro y con techo; el brillo lo ponen las aristas selladas.
	return clampi(st - 2, 1, 5)


static func build() -> RigDef:
	var b := RigBuilder.new(&"hollow_knight", Vector2i(120, 112), Vector2i(62, 66), -1)
	b.material(&"iron", &"iron", {"tex_fn": _iron, "texture": &"scratches"})
	b.material(&"dark", &"coal")
	b.material(&"cloth", &"cloth", {"texture": &"folds"})
	b.material(&"blade", &"iron")
	b.material(&"leather", &"leather")
	b.material(&"hot", &"hot")
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"thigh_f", &"root", Vector2(5, 2), {"z": -5.0})
	b.bone(&"shin_f", &"thigh_f", Vector2(0, 17))
	b.bone(&"foot_f", &"shin_f", Vector2(0, 17))
	b.bone(&"thigh_n", &"root", Vector2(-5, 2), {"z": 4.0})
	b.bone(&"shin_n", &"thigh_n", Vector2(0, 17))
	b.bone(&"foot_n", &"shin_n", Vector2(0, 17))
	b.bone(&"spine", &"root", Vector2(0, -2))
	b.bone(&"cape", &"spine", Vector2(12, -26), {"z": -10.0, "angle": -0.22})
	b.bone(&"cape2", &"cape", Vector2(2, 24))
	b.bone(&"head", &"spine", Vector2(-1, -31), {"z": 3.0})
	# Brazo lejano: sostiene el escudo torre por delante.
	b.bone(&"arm_f", &"spine", Vector2(-11, -24), {"z": -6.0, "angle": 0.5})
	b.bone(&"fore_f", &"arm_f", Vector2(0, 13), {"angle": -0.9})
	b.bone(&"shield", &"fore_f", Vector2(0, 12), {"z": 2.0, "angle": 0.4})
	# Brazo cercano: el espadón.
	b.bone(&"arm_n", &"spine", Vector2(9, -25), {"z": 10.0, "angle": -0.25})
	b.bone(&"fore_n", &"arm_n", Vector2(0, 14), {"angle": 0.25})
	b.bone(&"sword", &"fore_n", Vector2(0, 12), {"z": -1.0, "angle": -0.6})
	b.bone(&"ember", &"root", Vector2(0, -14), {"z": 30.0})
	b.ik(&"leg_f", &"thigh_f", &"shin_f", Vector2(0, 17), 1)
	b.ik(&"leg_n", &"thigh_n", &"shin_n", Vector2(0, 17), 1)
	# Capa raída (losas a mano en dos tramos).
	b.slab(&"cape_a", &"cape", [
		"..######....",
		".########...",
		"##########..",
		"###########.",
		"###########.",
		"####%######.",
		"####%######.",
		"####%######.",
		"####%#######",
		"####%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%#######",
	], Vector2(-4, 0), {"#": &"cloth", "%": [&"cloth", 3]}, 0.0, 2.0, 2.0)
	b.slab(&"cape_b", &"cape2", [
		"###%%#######",
		"###%%#######",
		"###%%#######",
		"###%%####.##",
		"###%%####.#.",
		"##.%%##.#.#.",
		"##.%###.#...",
		"#..%#.#.....",
		"...%#.......",
		"...#........",
	], Vector2(-6, -1), {"#": &"cloth", "%": [&"cloth", 3]}, 0.0, 2.0, 2.0)
	# Piernas de hierro con rodillera y escarpe.
	for s: String in ["f", "n"]:
		var ao := 1.3 if s == "f" else 1.0
		b.cap(StringName("thigh_%s_p" % s), StringName("thigh_" + s), &"iron", Vector3(0, 0, 0), Vector3(0, 17, 0), 6.0, 4.6, {"ao": ao})
		b.ell(StringName("knee_%s" % s), StringName("shin_" + s), &"iron", Vector3(-1, 0, 2), Vector3(5, 4.4, 4), {"ao": ao})
		b.cap(StringName("shin_%s_p" % s), StringName("shin_" + s), &"iron", Vector3(0, 2, 0), Vector3(0, 16, 0), 4.6, 3.8, {"ao": ao})
		b.poly(StringName("boot_%s" % s), StringName("foot_" + s), &"iron", PackedVector2Array([
			Vector2(4, -3), Vector2(-3, -3), Vector2(-10, 2), Vector2(-11, 6), Vector2(5, 6)]), 3.0, 1.6, 2.0, {"ao": ao})
	# Brazo lejano + escudo torre.
	b.cap(&"upper_f", &"arm_f", &"iron", Vector3(0, 0, 0), Vector3(0, 13, 0), 5.0, 4.2, {"ao": 1.4})
	b.cap(&"forearm_f", &"fore_f", &"iron", Vector3(0, 0, 0), Vector3(0, 12, 0), 4.2, 3.6, {"ao": 1.4})
	b.slab(&"tower", &"shield", [
		"...############...",
		".################.",
		"##################",
		"##rrrr##++##rrrr##",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"##rrrrr#++#rrrrr##",
		"#++++++#++#++++++#",
		"#++++++#++#++++++#",
		"##rrrrr#++#rrrrr##",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrrr#",
		"#rrrrrr#++#rrrrr##",
		"#rrrrrr#++#rrrr###",
		"##rrrrr#++#rrr###.",
		".##rrrr#++#rr###..",
		".###rrr#++#r###...",
		"..###rr#++####....",
		"...###r#++###.....",
		"....####++##......",
		"......#####.......",
		"........##........",
	], Vector2(-14, -14), {"#": &"iron", "+": [&"iron", 6], "r": [&"cloth", 4]}, 2.0, 1.6, 2.0)
	# Torso: coraza con BOQUETE (la firma): dentro hay vacío y una brasa.
	b.ell(&"pelvis", &"spine", &"iron", Vector3(0, 0, 0), Vector3(10, 7, 8), {"flat": 0.3})
	b.ell(&"breast", &"spine", &"iron", Vector3(0, -17, 0), Vector3(13, 15, 10), {"flat": 0.5})
	b.ell(&"gorget", &"spine", &"iron", Vector3(0, -30, 2), Vector3(8, 4, 6), {"flat": 0.3})
	b.stamp(&"hole", &"spine", Vector2(-3, -17), [
		"..jjjjj...",
		".jkkkkkj..",
		"jkkkkkkkj.",
		"jkkkkkkkkj",
		"jkkkkkkkkj",
		".jkkkkkkj.",
		"..jkkkkj..",
		"...jjjj...",
	], {"k": [&"dark", 0], "j": [&"iron", 1]}, {"anchor": Vector2i(5, 4), "z_top": false})
	b.stamp(&"core", &"spine", Vector2(-3, -16), [
		".f.",
		"fFf",
		"FWF",
		".f.",
	], {"f": [&"fire", 3], "F": [&"fire", 5], "W": [&"fire", 7]}, {"anchor": Vector2i(1, 2), "z_top": false})
	b.stamp(&"breast_edge", &"spine", Vector2(-12, -28), ["...hhhh", ".hh", "h", "h"], {"h": [&"iron", 7]}, {"z_top": false})
	for i in 5:
		b.stamp(StringName("rivet_%d" % i), &"spine", Vector2(-10 + i * 5, -6 + absi(i - 2)), ["5"], {"5": [&"iron", 7]}, {"z_top": false})
	# Yelmo de cubo: losa con rendija en T; el vacío asoma con un punto de brasa.
	b.slab(&"helm", &"head", [
		"....##########....",
		"..##############..",
		".################.",
		"##################",
		"##%%%%%%%%%%%%%%##",
		"##################",
		"##################",
		"#############++###",
		"##kkkkkkkkkk#++###",
		"##kkkkkkkkkk#++###",
		"#####kkk#####++###",
		"#####kkk#####++###",
		"#####kkk#####++###",
		"##################",
		"#o#o#o#o##########",
		"##################",
		"##################",
		".################.",
		"..##############..",
	], Vector2(-11, -19), {"#": &"iron", "%": [&"iron", 3], "+": [&"iron", 6], "k": [&"dark", 0], "o": [&"iron", 2]}, 1.0, 2.0, 3.0, {"tags": [&"eye"]})
	b.stamp(&"helm_edge", &"head", Vector2(-10, -18), ["..hhhhhhhhh", ".h", "h"], {"h": [&"iron", 7]}, {"z_top": false})
	b.stamp(&"visor", &"head", Vector2(-5, -10), [
		"..E.....e.",
	], {"E": [&"fire", 6], "e": [&"fire", 4]}, {"z_top": false})
	# Cresta de hierro rota.
	b.cap(&"crest", &"head", &"iron", Vector3(-1, -19, 0), Vector3(5, -24, 0), 2.0, 1.0, {"line": false})
	# Brazo cercano + espadón.
	b.slab(&"blade", &"sword", [
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%%",
		"#hh%.",
		"#h%%.",
		".h%..",
		".%...",
	], Vector2(-2.5, 8), {"#": [&"blade", 4], "h": [&"blade", 8], "%": [&"blade", 5]}, 0.0, 1.0, 1.0)
	b.box(&"guard", &"sword", &"blade", Vector3(0, 6.5, 0.5), Vector3(14, 3.4, 3), 1.2)
	b.cap(&"grip", &"sword", &"leather", Vector3(0, -3, 0), Vector3(0, 5, 0), 1.6, 1.6)
	b.cap(&"upper_n", &"arm_n", &"iron", Vector3(0, 0, 0), Vector3(0, 14, 0), 5.5, 4.6)
	b.ell(&"elbow_n", &"fore_n", &"iron", Vector3(0, 0, 1), Vector3(5, 4.2, 4))
	b.cap(&"forearm_n", &"fore_n", &"iron", Vector3(0, 2, 0), Vector3(0, 12, 0), 4.6, 4.0)
	b.ell(&"pauldron", &"arm_n", &"iron", Vector3(0, -2, 2), Vector3(9.5, 8, 7), {"flat": 0.3})
	b.stamp(&"pauldron_lines", &"arm_n", Vector2(-7, 2), ["j.........", ".jjjjjjj.."], {"j": [&"iron", 2]}, {"z_top": false})
	b.ell(&"gauntlet", &"fore_n", &"iron", Vector3(0, 12, 1), Vector3(4.6, 4.2, 4), {"tags": [&"hand"]})
	b.stamp(&"knuckle_n", &"fore_n", Vector2(0, 12), [".k.k.", "k4k4k", "..3.."], {"k": [&"iron", 1], "4": [&"iron", 7], "3": [&"iron", 5]}, {"anchor": Vector2i(2, 1), "z_top": false})
	# Montón de armadura de la muerte: se ve al final, en el suelo (y ≈ 104 con @root = (0, 28)).
	b.ell(&"heap_a", &"root", &"iron", Vector3(-6, 3, 14), Vector3(17, 7, 8), {"flat": 0.5})
	b.ell(&"heap_b", &"root", &"iron", Vector3(10, 5, 16), Vector3(12, 5, 7), {"flat": 0.5})
	b.bone(&"fallen", &"root", Vector2(-24, 0), {"z": 20.0, "angle": -0.5})
	b.slab(&"helm_down", &"fallen", ["..##########..", ".############.", "##############", "#kkkkkkkk#++##", "###kkk####++##", "##############", ".############."], Vector2(-6, -3), {"#": &"iron", "+": [&"iron", 6], "k": [&"dark", 0]}, 0.0, 1.5, 2.0)
	b.bone(&"fallen2", &"root", Vector2(20, 4), {"z": 22.0, "angle": 1.42})
	b.slab(&"blade_down", &"fallen2", [".#hhh%%%hhh%%%hhh%%%hhh%%%", "##hhh%%%hhh%%%hhh%%%hhh%%."], Vector2(-2, 0), {"#": [&"iron", 2], "h": [&"blade", 7], "%": [&"blade", 5]}, 0.0, 1.0, 1.0)
	b.socket(&"hit", &"sword", Vector2(0, 40))
	b.socket(&"intent", &"head", Vector2(0, -28))
	b.socket(&"core", &"spine", Vector2(-3, -16))
	_anims(b)
	return b.def


const FEET := {&"ik:leg_n": Vector2(50, 101), &"ik:leg_f": Vector2(70, 101)}


static func _p(k: Dictionary) -> Dictionary:
	var o := FEET.duplicate()
	o[&"hide:heap_a"] = true
	o[&"hide:heap_b"] = true
	o[&"hide:helm_down"] = true
	o[&"hide:blade_down"] = true
	for e in k.keys():
		o[e] = k[e]
	# El escarpe no rota con la espinilla: compensación aproximada.
	return o


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 8:
		var t := TAU * f / 8.0
		idle[f] = _p({&"@root": Vector2i(0, 1 if f >= 4 else 0), &"spine": 0.015 * sin(t), &"arm_n": 0.03 * sin(t), &"arm_f": 0.02 * sin(t),
			&"cape": 0.05 * sin(t + 1.0), &"cape2": 0.09 * sin(t), &"emit:core": [0, 1, 1, 0, 0, -1, -1, 0][f], &"emit:visor": [0, 0, 1, 1, 0, 0, -2, 0][f]})
	b.anim(&"idle", 8, 170, idle, {"interp": &"linear", "overlap": {&"arm_n": 1.0, &"cape2": 1.5}})
	# Telegrafía: planta el escudo y alza el espadón en vertical; las brasas se avivan.
	var c0 := _p({&"spine": 0.06, &"arm_n": 2.4, &"fore_n": 0.5, &"sword": 0.85, &"arm_f": 0.15, &"fore_f": 0.25, &"shield": -0.2, &"@root": Vector2i(1, 1), &"emit:core": 1, &"emit:visor": 1, &"cape": 0.15, &"z:arm_n": 6.0})
	var c1 := c0.duplicate()
	c1[&"@root"] = Vector2i(1, 2)
	c1[&"emit:core"] = 2
	b.anim(&"cast", 2, [140, 360], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: espadón por encima, gran tajo hacia delante.
	var a0 := _p({&"spine": 0.12, &"head": -0.05, &"arm_n": 2.7, &"fore_n": 0.7, &"sword": 0.75, &"arm_f": -0.1, &"fore_f": 0.3, &"@root": Vector2i(3, 1), &"cape": 0.2, &"emit:visor": 1})
	var a1 := _p({&"spine": -0.1, &"arm_n": 1.2, &"fore_n": 0.2, &"sword": 1.4, &"arm_f": -0.2, &"@root": Vector2i(-3, 0), &"cape": 0.05, &"ik:leg_n": Vector2(44, 101)})
	var a2 := _p({&"spine": -0.22, &"head": 0.1, &"arm_n": 0.95, &"fore_n": 0.35, &"sword": 0.35, &"arm_f": -0.25, &"fore_f": 0.2, &"@root": Vector2i(-8, 2), &"cape": -0.2, &"cape2": -0.15, &"ik:leg_n": Vector2(40, 101), &"emit:core": 1})
	var a3 := _p({&"spine": -0.12, &"arm_n": 0.5, &"fore_n": 0.25, &"sword": 0.25, &"@root": Vector2i(-4, 1), &"cape": -0.1, &"ik:leg_n": Vector2(44, 101)})
	b.anim(&"attack", 5, [150, 40, 110, 110, 150], {0: a0, 1: a1, 2: a2, 3: a2, 4: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"sword", Vector2(0, 40), &"fire", 11.0, false).samples = 64
	b.smear(&"attack", 2, &"sword", Vector2(0, 40), &"fire", 11.0, false).samples = 64
	var h0 := _p({&"spine": 0.12, &"head": -0.12, &"arm_n": -0.15, &"arm_f": 0.2, &"@root": Vector2i(3, 0), &"cape": 0.2, &"emit:core": -1, &"emit:visor": -2})
	var h1 := _p({&"spine": 0.05, &"head": -0.04, &"arm_n": -0.05, &"@root": Vector2i(2, 0), &"cape": 0.1})
	b.anim(&"hurt", 2, [90, 150], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte: la armadura se suelta por piezas y la brasa flota hasta apagarse.
	var d := {}
	d[0] = h0.duplicate()
	d[1] = _p({&"spine": 0.1, &"head": 0.2, &"arm_n": -0.1, &"sword": 0.3, &"arm_f": 0.5, &"@root": Vector2i(2, 6), &"emit:core": -1, &"emit:visor": -3})
	d[2] = _p({&"spine": -0.2, &"head": 0.4, &"arm_n": 0.2, &"sword": 0.9, &"arm_f": 0.8, &"fore_f": 0.5, &"@root": Vector2i(1, 14), &"hide:visor": true, &"emit:core": -1})
	d[3] = _p({&"spine": -0.45, &"head": 0.6, &"arm_n": 0.5, &"fore_n": 0.5, &"sword": 1.4, &"arm_f": 1.1, &"fore_f": 0.7, &"@root": Vector2i(0, 22), &"hide:visor": true, &"hide:crest": true, &"emit:core": -2})
	var last := {&"@root": Vector2i(0, 28), &"hide:heap_a": false, &"hide:heap_b": false, &"hide:helm_down": false, &"hide:blade_down": false, &"hide:visor": true, &"hide:helm_edge": true, &"hide:breast_edge": true,  &"hide:hole": true, &"hide:rivet_0": true, &"hide:rivet_1": true, &"hide:rivet_2": true, &"hide:rivet_3": true, &"hide:rivet_4": true,
		&"hide:knuckle_n": true, &"hide:pauldron_lines": true, &"hide:crest": true, &"spine": -0.8, &"head": 0.9, &"arm_n": 1.1, &"fore_n": 0.7, &"sword": 1.5}
	for pid: String in ["helm", "tower", "blade", "guard", "grip", "breast", "gorget", "pelvis", "pauldron", "upper_n", "elbow_n", "forearm_n", "gauntlet", "upper_f", "forearm_f", "cape_a", "cape_b", "thigh_f_p", "thigh_n_p", "knee_f", "knee_n", "shin_f_p", "shin_n_p"]:
		last[StringName("hide:" + pid)] = true
	d[4] = _p(last)
	d[4][&"emit:core"] = -2
	d[5] = d[4].duplicate()
	d[5][&"emit:core"] = -3
	d[6] = d[5].duplicate()
	d[6][&"emit:core"] = -5
	d[7] = d[6].duplicate()
	d[7][&"hide:core"] = true
	b.anim(&"death", 8, [80, 100, 110, 120, 200, 240, 300, 400], d, {"loop": false, "interp": &"hold"})
