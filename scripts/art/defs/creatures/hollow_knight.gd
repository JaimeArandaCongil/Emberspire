extends RefCounted
## CABALLERO HUECO (`hollow_knight`, élite, acto 1) — PER · v0.4.
## Concepto: una armadura vacía que siguió guardando la torre. Dentro no hay nadie: sólo una brasa.
## Silueta: yelmo de cubo alto, hombrera enorme, escudo torre delante y espadón caído detrás, capa raída.
## ≈ 96 px de alto (élite, §8) en un lienzo de 152×160; pies en y = 136; mira a la izquierda. Sin recortes en ninguna pose.
## Rasgo vivo: la brasa del pecho late y suelta una pavesa que sube; el visor parpadea; la capa ondula en dos tiempos.
## Telegrafía (cast, Fuerza + Bloqueo): planta el escudo y alza el espadón en vertical.
## Muerte por material: la armadura se desarma pieza a pieza (escudo, yelmo que rueda, placas, espada) y queda la coraza vacía con la brasa, que se apaga por pasos.

## Hierro ennegrecido: rampa no monótona (banda oscura de reflejo entre medios y luces), lo que da lectura de metal y no de goma.
const IRON_MAP := [0, 2, 2, 3, 3, 4, 3, 5, 6, 7, 8]

static func _iron(_l: Vector2, st: int, _n: int) -> int:
	return IRON_MAP[clampi(st, 0, 10)]


## Tela: pliegues verticales cada 7 px, borde inferior un paso más oscuro (§5).
static func _cloth(l: Vector2, st: int, n: int) -> int:
	st = mini(st + 1, n - 2)
	var m := fposmod(l.x, 7.0)
	if m < 1.0:
		st -= 3
	elif m < 2.0 or m >= 6.0:
		st -= 1
	return st


## Remache sellado: brillo arriba-izquierda, sombra abajo-derecha (§5).
static func _rivets(b: RigBuilder, id: String, bone: StringName, pts: Array) -> void:
	for i in pts.size():
		b.stamp(StringName("%s_%d" % [id, i]), bone, pts[i], ["h.", ".s"], {"h": [&"iron", 10], "s": [&"iron", 1]}, {"z_top": false})


## Brillo especular a mano: paso máximo pegado al paso 2, sin intermedios (§5).
static func _spec(b: RigBuilder, id: StringName, bone: StringName, at: Vector2, rows: Array) -> void:
	b.stamp(id, bone, at, rows, {"h": [&"iron", 10], "m": [&"iron", 8], "d": [&"iron", 2]}, {"z_top": false})


static func build() -> RigDef:
	var b := RigBuilder.new(&"hollow_knight", Vector2i(152, 160), Vector2i(82, 98), -1)
	b.material(&"iron", &"iron", {"tex_fn": _iron})
	b.material(&"dark", &"coal")
	b.material(&"cloth", &"cloth", {"tex_fn": _cloth})
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
	# Capa: nace de la gola y de los dos hombros (nada de saco suelto); termina en cola de golondrina.
	b.poly(&"cape_a", &"cape", &"cloth", PackedVector2Array([Vector2(-12, -3), Vector2(4, -4), Vector2(11, 2), Vector2(13, 14), Vector2(14, 27), Vector2(-8, 27), Vector2(-12, 12)]), 0.0, 2.0, 2.0)
	b.poly(&"cape_b", &"cape2", &"cloth", PackedVector2Array([Vector2(-10, -3), Vector2(14, -3), Vector2(16, 12), Vector2(17, 25), Vector2(8, 16), Vector2(2, 14), Vector2(-3, 23), Vector2(-9, 12)]), 0.0, 2.0, 2.0)
	b.stamp(&"cape_hem", &"cape2", Vector2(-8, 11), [
		"k...................",
		".kk...........k.....",
		"...k.........k.kk...",
		"....kk......k....k..",
		"......k....k......k.",
		".......k..k........k",
		"........kk..........",
	], {"k": [&"cloth", 2]}, {"z_top": false})
	# Piernas de hierro con rodillera y escarpe.
	for s: String in ["f", "n"]:
		var ao := 1.3 if s == "f" else 1.0
		b.cap(StringName("thigh_%s_p" % s), StringName("thigh_" + s), &"iron", Vector3(0, 0, 0), Vector3(0, 17, 0), 6.0, 4.6, {"ao": ao})
		b.ell(StringName("knee_%s" % s), StringName("shin_" + s), &"iron", Vector3(-1, 0, 2), Vector3(5, 4.4, 4), {"ao": ao})
		b.cap(StringName("shin_%s_p" % s), StringName("shin_" + s), &"iron", Vector3(0, 2, 0), Vector3(0, 16, 0), 4.6, 3.8, {"ao": ao})
		b.poly(StringName("boot_%s" % s), StringName("foot_" + s), &"iron", PackedVector2Array([
			Vector2(4, -3), Vector2(-3, -3), Vector2(-10, 2), Vector2(-11, 6), Vector2(5, 6)]), 3.0, 1.6, 2.0, {"ao": ao})
		b.poly(StringName("tasset_%s" % s), StringName("thigh_" + s), &"iron", PackedVector2Array([Vector2(-6, -3), Vector2(6, -3), Vector2(7, 7), Vector2(0, 10), Vector2(-7, 7)]), 3.0, 1.2, 2.0, {"ao": ao})
		_spec(b, StringName("thigh_%s_spec" % s), StringName("thigh_" + s), Vector2(-4, 1), ["hh", "h.", "d."])
		_spec(b, StringName("knee_%s_spec" % s), StringName("shin_" + s), Vector2(-3, -2), ["h", "d"])
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
	], Vector2(-14, -14), {"#": &"iron", "+": [&"iron", 7], "r": [&"cloth", 5]}, 2.0, 1.6, 2.0)
	_rivets(b, "shield_r", &"shield", [Vector2(-12, -11), Vector2(-3, -13), Vector2(5, -13), Vector2(14, -11), Vector2(-13, 2), Vector2(14, 2)])
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
	_spec(b, &"breast_edge", &"spine", Vector2(-11, -28), ["...hhh", ".hd", "hd", "d"])
	_rivets(b, "rivet", &"spine", [Vector2(-11, -5), Vector2(-5, -4), Vector2(1, -4), Vector2(7, -5)])
	_rivets(b, "gorget_r", &"spine", [Vector2(-5, -31), Vector2(0, -30), Vector2(5, -31)])
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
	_spec(b, &"helm_edge", &"head", Vector2(-10, -18), ["..hhhh", ".hd", "hd"])
	b.stamp(&"visor", &"head", Vector2(-5, -10), [
		"..E.....e.",
	], {"E": [&"fire", 6], "e": [&"fire", 4]}, {"z_top": false})
	# Cresta de hierro rota.
	b.cap(&"crest", &"head", &"iron", Vector3(-1, -19, 0), Vector3(4, -22, 0), 2.0, 1.0, {"line": false})
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
	b.cap(&"forearm_n", &"fore_n", &"iron", Vector3(0, 2, 0), Vector3(0, 12, 0), 5.8, 5.0)
	b.poly(&"pauldron", &"arm_n", &"iron", PackedVector2Array([Vector2(-11, 3), Vector2(-10, -6), Vector2(-4, -11), Vector2(6, -11), Vector2(12, -5), Vector2(13, 4), Vector2(9, 8), Vector2(-7, 8)]), 2.0, 3.0, 5.0)
	b.stamp(&"pauldron_lines", &"arm_n", Vector2(-9, 2), ["j...............", ".jjjjjjjjjjjjjj."], {"j": [&"iron", 1]}, {"z_top": false})
	_spec(b, &"pauldron_spec", &"arm_n", Vector2(-7, -8), ["..hhh", ".hd..", "hd..."])
	_rivets(b, "pauldron_r", &"arm_n", [Vector2(-8, 5), Vector2(-3, 6), Vector2(2, 6), Vector2(7, 5)])
	b.ell(&"gauntlet", &"fore_n", &"iron", Vector3(0, 12, 1), Vector3(5.6, 4.8, 4), {"tags": [&"hand"]})
	b.stamp(&"knuckle_n", &"fore_n", Vector2(0, 12), [".k.k.k.", "k4k4k4k", "k5k5k5k", ".k3k3k."], {"k": [&"iron", 1], "4": [&"iron", 8], "5": [&"iron", 6], "3": [&"iron", 4]}, {"anchor": Vector2i(3, 1), "z_top": false})
	# Pavesa que sube del boquete (rasgo vivo).
	b.bone(&"spark", &"spine", Vector2(-3, -20), {"z": 40.0})
	b.stamp(&"spark_s", &"spark", Vector2.ZERO, ["."], {"s": [&"fire", 5], "t": [&"fire", 3]}, {"views": {&"none": ["."], &"a": ["s"], &"b": ["s", ".", ".", "."], &"c": ["t", ".", ".", ".", ".", "."]}, "anchor": Vector2i(0, 0)})
	# --- Muerte: la armadura en el suelo. Con @root = (0, 26) el suelo queda en y local 12.
	b.bone(&"floor", &"root", Vector2.ZERO, {"z": 16.0})
	b.poly(&"cape_floor", &"floor", &"cloth", PackedVector2Array([Vector2(6, 12), Vector2(10, 5), Vector2(26, 4), Vector2(38, 7), Vector2(42, 12), Vector2(33, 9), Vector2(29, 12)]), 0.0, 1.2, 1.0)
	b.slab(&"tower_flat", &"floor", [
		"..##########################..",
		".##rrrrrrrrrr++rrrrrrrrrrrr##.",
		"##rrrrrrrrrrr++rrrrrrrrrrrrr##",
		"##++++++++++++++++++++++++++##",
		".##rrrrrrrrrr++rrrrrrrrrrr##..",
		"..##########################..",
	], Vector2(-54, 6), {"#": [&"iron", 5], "+": [&"iron", 7], "r": [&"cloth", 4]}, 2.0, 1.0, 1.0)
	b.slab(&"blade_down", &"floor", [
		"...hhhhhhhhhhhhhhhhhhhhhhhhhhhhh..",
		"gg.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.",
		"gg.##############################",
	], Vector2(4, 9), {"#": [&"blade", 5], "h": [&"blade", 9], "%": [&"blade", 7], "g": [&"leather", 3]}, 4.0, 0.8, 1.0)
	b.poly(&"plate_a", &"floor", &"iron", PackedVector2Array([Vector2(-20, 12), Vector2(-17, 6), Vector2(-8, 5), Vector2(-5, 12)]), 3.0, 1.2, 2.0)
	b.poly(&"plate_b", &"floor", &"iron", PackedVector2Array([Vector2(16, 12), Vector2(18, 3), Vector2(26, 2), Vector2(31, 7), Vector2(29, 12)]), 6.0, 1.4, 2.0)
	# Coraza vacía apoyada, con el boquete hacia nosotros: es lo último que queda.
	b.poly(&"cuirass_down", &"floor", &"iron", PackedVector2Array([Vector2(-11, 12), Vector2(-12, 0), Vector2(-16, -10), Vector2(-12, -16), Vector2(-5, -14), Vector2(0, -10), Vector2(5, -14), Vector2(12, -16), Vector2(15, -9), Vector2(11, 0), Vector2(11, 12)]), 8.0, 2.4, 4.0)
	b.stamp(&"hole_down", &"floor", Vector2(-2, -6), [
		"..jjjjj...",
		".jkkkkkj..",
		"jkkkkkkkj.",
		"jkkkkkkkkj",
		"jkkkkkkkkj",
		".jkkkkkkj.",
		"..jkkkkj..",
		"...jjjj...",
	], {"k": [&"dark", 0], "j": [&"iron", 2]}, {"anchor": Vector2i(5, 4)})
	b.stamp(&"core_down", &"floor", Vector2(-2, -5), [".f.", "fFf", "FWF", ".f."], {"f": [&"fire", 3], "F": [&"fire", 5], "W": [&"fire", 7]}, {"anchor": Vector2i(1, 2)})
	_spec(b, &"cuirass_spec", &"floor", Vector2(-14, -13), ["..hh", ".hd", "hd"])
	b.stamp(&"cuirass_collar", &"floor", Vector2(-5, -13), ["k.........k", ".kk.....kk.", "...kk.kk...", ".....k....."], {"k": [&"iron", 1]}, {"z_top": false})
	_rivets(b, "cuirass_r", &"floor", [Vector2(-9, 8), Vector2(-3, 9), Vector2(3, 9), Vector2(8, 8)])
	# Yelmo que rueda: dos posiciones.
	for pos: Array in [[&"roll_a", Vector2(-24, 2), -0.9], [&"roll_b", Vector2(-44, 3), -0.35]]:
		b.bone(pos[0], &"floor", pos[1], {"z": 8.0, "angle": pos[2]})
		b.slab(StringName("helm_" + String(pos[0])), pos[0], ["..##########..", ".############.", "##############", "#kkkkkkkk#++##", "###kkk####++##", "##############", ".############."], Vector2(-7, -3), {"#": &"iron", "+": [&"iron", 7], "k": [&"dark", 0]}, 0.0, 1.5, 2.0)
	b.socket(&"hit", &"sword", Vector2(0, 40))
	b.socket(&"intent", &"head", Vector2(0, -25))
	b.socket(&"core", &"spine", Vector2(-3, -16))
	_anims(b)
	return b.def


const FEET := {&"ik:leg_n": Vector2(70, 133), &"ik:leg_f": Vector2(90, 133)}
const FLOOR := [&"cape_floor", &"tower_flat", &"blade_down", &"plate_a", &"plate_b", &"cuirass_down", &"hole_down", &"core_down", &"cuirass_spec", &"cuirass_collar",
	&"cuirass_r_0", &"cuirass_r_1", &"cuirass_r_2", &"cuirass_r_3", &"helm_roll_a", &"helm_roll_b"]


static func _p(k: Dictionary) -> Dictionary:
	var o := FEET.duplicate()
	for id: StringName in FLOOR:
		o[StringName("hide:%s" % id)] = true
	o[&"view:spark_s"] = &"none"
	for e in k.keys():
		o[e] = k[e]
	return o


## Los sellos no giran: cuando el brazo o el escudo se alejan mucho del reposo, sus detalles se ocultan para no quedar flotando.
static func _no_arm(o: Dictionary) -> Dictionary:
	for pid: String in ["pauldron_lines", "pauldron_spec", "pauldron_r_0", "pauldron_r_1", "pauldron_r_2", "pauldron_r_3"]:
		o[StringName("hide:" + pid)] = true
	return o


static func _no_shield(o: Dictionary) -> Dictionary:
	for i in 6:
		o[StringName("hide:shield_r_%d" % i)] = true
	return o


## Todo lo que está en pie, para los fotogramas en que la armadura ya está en el suelo.
static func _stood(o: Dictionary) -> void:
	for pid: String in ["helm", "helm_edge", "visor", "crest", "tower", "blade", "guard", "grip", "breast", "breast_edge", "gorget", "pelvis", "pauldron", "pauldron_lines", "pauldron_spec",
			"upper_n", "elbow_n", "forearm_n", "gauntlet", "knuckle_n", "upper_f", "forearm_f", "cape_a", "cape_b", "cape_hem", "hole", "core",
			"thigh_f_p", "thigh_n_p", "knee_f", "knee_n", "shin_f_p", "shin_n_p", "boot_f", "boot_n", "tasset_f", "tasset_n", "thigh_f_spec", "thigh_n_spec", "knee_f_spec", "knee_n_spec"]:
		o[StringName("hide:" + pid)] = true
	for pr: Array in [["rivet", 4], ["gorget_r", 3], ["pauldron_r", 4], ["shield_r", 6]]:
		for i in int(pr[1]):
			o[StringName("hide:%s_%d" % [pr[0], i])] = true


static func _anims(b: RigBuilder) -> void:
	# Reposo: el cuerpo quieto (1 px); vive la brasa, la pavesa que sube, el visor y la capa en dos tiempos.
	var idle := {}
	for f in 6:
		idle[f] = _p({&"@root": Vector2i(0, 1 if f in [3, 4] else 0), &"cape2": [0.0, 0.07, 0.07, 0.0, -0.05, -0.05][f],
			&"emit:core": [0, 1, 2, 1, 0, -1][f], &"emit:visor": [0, 0, 1, 0, -2, 0][f], &"view:spark_s": [&"none", &"a", &"b", &"c", &"none", &"none"][f]})
	b.anim(&"idle", 6, 170, idle, {"interp": &"hold"})
	# Telegrafía: planta el escudo y alza el espadón en vertical; las brasas se avivan.
	var c0 := _p({&"spine": 0.06, &"arm_n": 2.4, &"fore_n": 0.5, &"sword": 0.85, &"arm_f": 0.15, &"fore_f": 0.25, &"shield": -0.2, &"@root": Vector2i(1, 1), &"emit:core": 1, &"emit:visor": 1, &"cape": 0.1, &"z:arm_n": 6.0})
	_no_arm(c0)
	var c1 := c0.duplicate()
	c1[&"@root"] = Vector2i(1, 2)
	c1[&"emit:core"] = 2
	b.anim(&"cast", 2, [140, 360], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: espadón por encima, gran tajo hacia delante. La capa cae siempre detrás (compensa el giro del tronco).
	var a0 := _p({&"spine": 0.12, &"head": -0.05, &"arm_n": 2.7, &"fore_n": 0.7, &"sword": 0.75, &"arm_f": -0.1, &"fore_f": 0.3, &"@root": Vector2i(3, 1), &"cape": 0.0, &"emit:visor": 1})
	var a1 := _p({&"spine": -0.1, &"arm_n": 1.2, &"fore_n": 0.2, &"sword": 1.4, &"arm_f": -0.2, &"@root": Vector2i(-3, 0), &"cape": 0.2, &"ik:leg_n": Vector2(64, 133)})
	var a2 := _p({&"spine": -0.22, &"head": 0.1, &"arm_n": 0.95, &"fore_n": 0.35, &"sword": 0.35, &"arm_f": -0.25, &"fore_f": 0.2, &"@root": Vector2i(-8, 2), &"cape": 0.3, &"cape2": 0.08, &"ik:leg_n": Vector2(60, 133), &"emit:core": 1})
	var a3 := _p({&"spine": -0.12, &"arm_n": 0.5, &"fore_n": 0.25, &"sword": 0.25, &"@root": Vector2i(-4, 1), &"cape": 0.15, &"ik:leg_n": Vector2(64, 133)})
	for pz: Dictionary in [a0, a1, a2, a3]:
		_no_arm(pz)
	b.anim(&"attack", 5, [150, 40, 110, 110, 150], {0: a0, 1: a1, 2: a2, 3: a2, 4: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"sword", Vector2(0, 40), &"fire", 11.0, false).samples = 64
	b.smear(&"attack", 2, &"sword", Vector2(0, 40), &"fire", 11.0, false).samples = 64
	var h0 := _p({&"spine": 0.12, &"head": -0.12, &"arm_n": -0.15, &"arm_f": 0.2, &"@root": Vector2i(3, 0), &"cape": 0.1, &"emit:core": -1, &"emit:visor": -2})
	var h1 := _p({&"spine": 0.05, &"head": -0.04, &"arm_n": -0.05, &"@root": Vector2i(2, 0), &"cape": 0.05})
	b.anim(&"hurt", 2, [90, 150], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte por material: se le va la fuerza, cae de rodillas, la armadura se suelta por piezas.
	var d := {}
	d[0] = _p({&"spine": 0.12, &"head": -0.12, &"arm_n": -0.15, &"arm_f": 0.2, &"@root": Vector2i(3, 0), &"emit:core": 2, &"emit:visor": 1})
	d[1] = _no_shield(_p({&"spine": 0.08, &"head": 0.18, &"arm_n": -0.1, &"sword": 0.3, &"arm_f": 0.5, &"@root": Vector2i(2, 5), &"emit:core": 1, &"emit:visor": -3}))
	d[2] = _no_shield(_p({&"spine": -0.12, &"head": 0.35, &"arm_n": 0.1, &"sword": 0.8, &"arm_f": 0.9, &"fore_f": 0.5, &"@root": Vector2i(1, 14), &"hide:visor": true, &"emit:core": 1}))
	# Rodillas en tierra: el yelmo cae hacia delante, el escudo resbala y el brazo se suelta.
	d[3] = _no_arm(_no_shield(_p({&"spine": -0.2, &"head": 0.75, &"arm_n": 0.3, &"fore_n": 0.5, &"sword": 1.2, &"arm_f": 1.3, &"fore_f": 0.8, &"shield": 0.4, &"@root": Vector2i(0, 23), &"hide:visor": true, &"hide:crest": true, &"emit:core": 0})))
	# Se desarma: yelmo rodando, escudo y espada ya planos; aún se sostienen coraza, caderas y muslos.
	var mid := _p({&"@root": Vector2i(0, 26), &"spine": -0.28, &"cape": 0.3, &"hide:tower_flat": false, &"hide:blade_down": false, &"hide:plate_a": false, &"hide:helm_roll_a": false, &"emit:core": -1})
	_stood(mid)
	for pid: String in ["breast", "breast_edge", "gorget", "pelvis", "hole", "core", "cape_a", "cape_b", "cape_hem", "thigh_f_p", "thigh_n_p", "tasset_f", "tasset_n", "knee_f", "knee_n", "boot_f", "boot_n", "shin_f_p", "shin_n_p"]:
		mid[StringName("hide:" + pid)] = false
	d[4] = mid
	# En el suelo: piezas planas, espada visible, yelmo al final de su rodada; la coraza vacía guarda la brasa, que se apaga por pasos.
	var e := {&"@root": Vector2i(0, 26), &"hide:cape_floor": false, &"hide:tower_flat": false, &"hide:blade_down": false, &"hide:plate_a": false, &"hide:plate_b": false, &"hide:cuirass_down": false,
		&"hide:hole_down": false, &"hide:core_down": false, &"hide:cuirass_spec": false, &"hide:cuirass_collar": false, &"hide:cuirass_r_0": false, &"hide:cuirass_r_1": false, &"hide:cuirass_r_2": false, &"hide:cuirass_r_3": false,
		&"hide:helm_roll_b": false}
	d[5] = _p(e)
	_stood(d[5])
	d[6] = d[5].duplicate()
	d[6][&"emit:core_down"] = -2
	d[7] = d[6].duplicate()
	d[7][&"hide:core_down"] = true
	b.anim(&"death", 8, [80, 90, 100, 120, 130, 200, 300, 400], d, {"loop": false, "interp": &"hold"})
