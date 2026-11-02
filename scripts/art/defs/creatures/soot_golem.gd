extends RefCounted
## GÓLEM DE HOLLÍN (`soot_golem`, acto 1) — PER · v0.4, motor de rig v1.
## Concepto: un horno de ladrillo encorvado que anda con los nudillos y lleva el fuego en la barriga.
## Silueta: joroba alta con chimenea detrás, cabeza de carbón hundida delante, puño enorme apoyado (gorila).
## ≈ 84 px de alto en un lienzo de 112×112; pies en y = 104; mira a la izquierda.
## Rasgo vivo: la chimenea humea (bocanadas que suben) y cae una gota de hollín bajo el vientre; la puerta late.
## Telegrafía (cast): alza el puño sobre la cabeza y la puerta del horno se pone al blanco.

static func _bricks(l: Vector2, st: int, n: int) -> int:
	# Ladrillo refractario 9×4 en el espacio del hueso; el mortero sólo en luz media (en sombra se pierde).
	st = mini(st, 6)
	if l.y < -46.0:
		st = maxi(1, st - 3)
	elif l.y < -40.0 and l.x > 8.0:
		st = maxi(1, st - 2)
	if st < 3 or st > n - 3:
		return st
	var row := int(floor(l.y / 4.0))
	var bx := l.x + (4.5 if row % 2 == 1 else 0.0)
	if fposmod(l.y, 4.0) < 1.0 or fposmod(bx, 9.0) < 1.0:
		return st - 1
	return st


static func build() -> RigDef:
	var b := RigBuilder.new(&"soot_golem", Vector2i(112, 112), Vector2i(62, 84), -1)
	b.material(&"brick", &"furnace_brick", {"tex_fn": _bricks})
	b.material(&"coal", &"coal", {"facet": {"cell_area": 40.0, "weight": 0.6, "crack": 0.18, "crack_slot": &"magma"}, "spec": true})
	b.material(&"soot", &"rock_soot", {"texture": &"soot_grain"})
	b.material(&"iron", &"iron", {"tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return mini(st, 6)})
	b.material(&"magma", &"hot")
	b.material(&"fire", &"fire")
	b.material(&"smoke", &"smoke", {"rim": false})
	b.mask(&"brick", &"soot", &"soot", &"rise")

	# --- esqueleto
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"leg_f", &"root", Vector2(9, -3), {"z": -8.0})
	b.bone(&"leg_n", &"root", Vector2(-9, -3), {"z": 6.0})
	b.bone(&"spine", &"root", Vector2(0, -2))
	b.bone(&"smoke", &"spine", Vector2(20, -60))
	b.bone(&"drip", &"spine", Vector2(-4, 0))
	b.bone(&"head", &"spine", Vector2(-27, -31), {"z": 22.0})
	b.bone(&"arm_f", &"spine", Vector2(15, -28), {"z": -14.0, "angle": -0.55})
	b.bone(&"fore_f", &"arm_f", Vector2(0, 20), {"angle": 0.5})
	b.bone(&"arm_n", &"spine", Vector2(-16, -28), {"z": 16.0, "angle": 0.75})
	b.bone(&"fore_n", &"arm_n", Vector2(0, 22), {"angle": -0.36})

	# --- brazo lejano (detrás)
	b.cap(&"upper_f", &"arm_f", &"brick", Vector3(0, 0, 0), Vector3(0, 20, 0), 8.0, 7.0, {"ao": 1.4})
	b.ell(&"fore_f1", &"fore_f", &"coal", Vector3(0, 5, 0), Vector3(7.5, 6.5, 6.5), {"ao": 1.3})
	b.ell(&"fore_f2", &"fore_f", &"coal", Vector3(0, 13, 0), Vector3(8.5, 7, 7), {"ao": 1.3})
	b.ell(&"fist_f", &"fore_f", &"coal", Vector3(0, 21, 0), Vector3(9, 6.5, 7.5), {"ao": 1.3})
	# --- piernas (troncos de carbón cortos)
	for s: String in ["f", "n"]:
		var bn := StringName("leg_" + s)
		var ao := 1.3 if s == "f" else 1.0
		b.ell(StringName("thigh_" + s), bn, &"coal", Vector3(0, 0, 0), Vector3(8.5, 7, 7), {"ao": ao})
		b.ell(StringName("calf_" + s), bn, &"coal", Vector3(-1, 9, 1), Vector3(8, 6.5, 7), {"ao": ao})
		b.ell(StringName("foot_" + s), bn, &"coal", Vector3(-3, 16, 2), Vector3(10.5, 5, 8), {"ao": ao, "flat": 0.3})
	# --- torso: horno encorvado + joroba + chimenea
	b.ell(&"torso", &"spine", &"brick", Vector3(2, -22, 0), Vector3(25, 22, 18), {"flat": 0.45})
	b.ell(&"hump", &"spine", &"brick", Vector3(10, -36, -3), Vector3(16, 14, 13), {"flat": 0.45})
	b.ell(&"pelvis", &"spine", &"coal", Vector3(0, -2, 0), Vector3(15, 7, 12), {"flat": 0.3})
	b.cap(&"chimney", &"spine", &"brick", Vector3(18, -46, -4), Vector3(19, -53, -4), 5.2, 4.6)
	b.box(&"chimney_cap", &"spine", &"iron", Vector3(19, -56, -3), Vector3(13, 4, 6), 1.5)
	b.stamp(&"chimney_fire", &"spine", Vector2(19, -58), ["hHHh"], {"h": [&"hot", 3], "H": [&"hot", 4]}, {"anchor": Vector2i(2, 0)})
	# aros de hierro remachados que siguen la curva del cuerpo (losas en arco)
	for band: Array in [[-38.0, 1.0], [-27.0, 0.7]]:
		var pts := PackedVector2Array()
		var y0: float = band[0]
		var bend: float = band[1]
		for i in 13:
			var x := -20.0 + i * 3.6
			pts.append(Vector2(x, y0 + bend * 0.012 * (x - 4) * (x - 4)))
		for i in range(12, -1, -1):
			var x := -20.0 + i * 3.6
			pts.append(Vector2(x, y0 + 3 + bend * 0.012 * (x - 4) * (x - 4)))
		b.poly(StringName("hoop_%d" % int(-y0)), &"spine", &"iron", pts, 17.5, 1.2, 1.0)
		for i in 7:
			var rx := -16.0 + i * 6.0
			b.stamp(StringName("rivet_%d_%d" % [int(-y0), i]), &"spine", Vector2(rx, y0 + 1 + bend * 0.012 * (rx - 4) * (rx - 4)), ["5"],
				{"5": [&"iron", 8]}, {"z_top": false})
	# puerta del horno en el vientre (el corazón: telegrafía)
	b.slab(&"door", &"spine", [
		".#############.",
		"###############",
		"###############",
		"###############",
		"###############",
		"###############",
		"###############",
		"###############",
		"###############",
		".#############.",
	], Vector2(-12, -21), {"#": &"iron"}, 19.0, 1.5, 2.0)
	b.stamp(&"door_fire", &"spine", Vector2(-10, -19), [
		".hHHHHHHHHh",
		"hHkHHkHHkHh",
		"hHkHWkWHkHh",
		"hHkWWkWWkHh",
		"hHkHWkWHkHh",
		".hkhhkhhkh.",
	], {"h": [&"fire", 3], "H": [&"fire", 4], "W": [&"fire", 6], "k": [&"iron", 1]}, {"z_top": false})
	# gota de hollín (vistas d0..d3 en el hueso "drip")
	b.stamp(&"drip", &"drip", Vector2(0, 0), ["s", "S"], {"s": [&"rock_soot", 3], "S": [&"rock_soot", 2]}, {"z_top": false, "views": {
		&"d0": ["s", "S"], &"d1": ["s", "S", "S"], &"d2": [".", ".", "s", ".", "S"], &"d3": [".", ".", ".", ".", ".", ".", "s"]}})
	# humo de chimenea: 4 bocanadas a distintas alturas; la animación enseña una u otra (suben)
	for i in 4:
		var r := 3.0 + i * 0.7
		b.ell(StringName("puff_%d" % i), &"smoke", &"smoke", Vector3(i * 1.5, 1.0 - i * 4.0, 0), Vector3(r, r * 0.85, r), {"line": false, "flat": 0.4})
	# --- pierna cercana, cabeza, brazo cercano (delante)
	b.ell(&"skull", &"head", &"coal", Vector3(0, 0, 0), Vector3(10.5, 9, 8.5), {"tags": [&"face", &"eye"]})
	b.poly(&"brow", &"head", &"brick", PackedVector2Array([Vector2(-11, -4), Vector2(7, -10), Vector2(11, -4), Vector2(-9, -1)]), 7.0, 1.4, 2.0)
	b.stamp(&"face", &"head", Vector2(-8, -1), [
		"kkkkk..kkkk.",
		"kWEek..kEek.",
		".kkk....kk..",
		"............",
		"............",
		"kgkgkgkgk...",
		"khkhkhkhk...",
	], {"k": [&"coal", 0], "W": [&"fire", 7], "E": [&"fire", 6], "e": [&"fire", 4], "g": [&"fire", 4], "h": [&"fire", 2]},
		{"views": {&"roar": [
		"kkkkk..kkkk.",
		"kWWEk..kWEk.",
		".kkk....kk..",
		"............",
		"kgkgkgkgk...",
		"k.k.k.k.k...",
		"khkhkhkhk...",
	], &"hurt": [
		"............",
		"kkkkk..kkkk.",
		".kek....ke..",
		"............",
		"............",
		"kgkgkgkgk...",
		"khkhkhkhk...",
	], &"dead": [
		"............",
		"kkkkk..kkkk.",
		"............",
		"............",
		"............",
		"kkkkkkkkk...",
		"khkhkhkhk...",
	]}})
	b.cap(&"upper_n", &"arm_n", &"brick", Vector3(0, 0, 0), Vector3(0, 21, 0), 9.5, 8.0)
	b.cap(&"cuff_n", &"arm_n", &"iron", Vector3(0, 20.5, 1), Vector3(0, 22.5, 1), 8.6, 8.6)
	b.ell(&"fore_n1", &"fore_n", &"coal", Vector3(0, 5, 0), Vector3(8, 6.5, 7))
	b.ell(&"fore_n2", &"fore_n", &"coal", Vector3(0, 13, 0), Vector3(9.5, 7.5, 8))
	b.ell(&"fist_n", &"fore_n", &"coal", Vector3(0, 22, 0), Vector3(11.5, 8, 9), {"tags": [&"hand"]})
	b.stamp(&"knuckles", &"fore_n", Vector2(-9, 22), ["h.h.h", "HhHhH"], {"h": [&"hot", 2], "H": [&"hot", 3]}, {"z_top": false})
	b.stamp(&"cuff_rivets", &"arm_n", Vector2(-6, 19), ["5...5"], {"5": [&"iron", 8]}, {"z_top": false})

	# escombros de carbón de la muerte (a la altura del suelo cuando el root baja 19 px)
	for i in 4:
		var rp: Vector2 = [Vector2(-26, -3), Vector2(-14, -2), Vector2(22, -2), Vector2(32, -3)][i]
		b.ell(StringName("rubble_%d" % i), &"root", &"coal", Vector3(rp.x, rp.y, 14), Vector3(6.5 - i * 0.6, 4.0, 5), {"flat": 0.3})
	b.socket(&"hit", &"fore_n", Vector2(0, 28))
	b.socket(&"intent", &"head", Vector2(0, -18))
	b.socket(&"smoke", &"spine", Vector2(19, -58))
	b.socket(&"heart", &"spine", Vector2(-4, -15))
	_anims(b)
	b.variant(&"sooty", {&"soot": 0.45})
	return b.def


const PUFFS := ["puff_0", "puff_1", "puff_2", "puff_3"]


static func _puffs(k: Dictionary, f: int) -> void:
	# Ciclo de humo de 8 fotogramas: la columna crece y mengua desde la boca de la chimenea; nunca se despega.
	var n: int = [2, 3, 4, 3][(f / 2) % 4]
	for i in 4:
		k[StringName("hide:" + PUFFS[i])] = i >= n


static func _anims(b: RigBuilder) -> void:
	# Reposo 8 f: respira (la joroba sube 1 px), cabeza y brazo con retraso, humo, goteo, la puerta late.
	var idle := {}
	for f in 8:
		var t := TAU * f / 8.0
		var k := {}
		k[&"@root"] = Vector2i(0, 1 if (f >= 4) else 0)
		k[&"spine"] = 0.025 * sin(t)
		k[&"head"] = 0.05 * sin(t)
		k[&"arm_n"] = -0.03 * sin(t)
		k[&"fore_n"] = 0.03 * sin(t)
		k[&"arm_f"] = 0.03 * sin(t)
		k[&"smoke"] = 0.08 * sin(t)
		k[&"emit:door_fire"] = [0, 0, 1, 1, 0, 0, -1, 0][f]
		k[&"emit:face"] = [0, 0, 0, 0, 0, 0, -2, 0][f]   # parpadeo de las brasas
		k[&"view:drip"] = [&"d0", &"d0", &"d0", &"d1", &"d1", &"d2", &"d3", &"d0"][f]
		_puffs(k, f)
		idle[f] = k
	b.anim(&"idle", 8, 150, idle, {"interp": &"linear", "overlap": {&"head": 1.0, &"arm_n": 1.5, &"fore_n": 2.0, &"arm_f": 1.5}})
	# Telegrafía (cast): puño alzado sobre la cabeza, la puerta al blanco, rugido.
	var tell := {&"spine": 0.12, &"head": -0.15, &"arm_n": 2.3, &"fore_n": 0.9, &"arm_f": -0.2, &"@root": Vector2i(2, -1),
		&"emit:door_fire": 2, &"emit:face": 1, &"view:head": &"roar", &"z:arm_n": 4.0, &"view:drip": &"d0", &"hide:knuckles": true}
	var tell2 := tell.duplicate()
	tell2[&"@root"] = Vector2i(2, -2)
	tell2[&"emit:door_fire"] = 3
	_puffs(tell, 0)
	_puffs(tell2, 2)
	b.anim(&"cast", 2, [120, 400], {0: tell, 1: tell2}, {"loop": false, "interp": &"hold"})
	# Ataque: carga (= telegrafía) → estela → puñetazo al suelo → recuperación.
	var smash := {&"spine": -0.08, &"head": 0.1, &"arm_n": 0.1, &"fore_n": 0.08, &"arm_f": 0.15, &"@root": Vector2i(-3, 2),
		&"emit:door_fire": 2, &"emit:knuckles": 3, &"view:head": &"roar", &"view:drip": &"d0"}
	var settle := {&"spine": -0.04, &"head": 0.05, &"arm_n": 0.05, &"fore_n": 0.04, &"@root": Vector2i(-1, 1), &"emit:door_fire": 1,
		&"view:drip": &"d0"}
	_puffs(smash, 4)
	_puffs(settle, 6)
	b.anim(&"attack", 4, [140, 40, 110, 160], {0: tell2, 1: smash, 2: smash, 3: settle}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"fore_n", Vector2(0, 24), &"fire", 15.0, false).samples = 48
	# Golpe recibido: retrocede, la cabeza atrás, ojos cerrados un instante.
	var h1 := {&"spine": 0.1, &"head": -0.2, &"arm_n": 0.15, &"@root": Vector2i(3, 0), &"view:head": &"hurt", &"emit:door_fire": -1}
	var h2 := {&"spine": 0.05, &"head": -0.1, &"arm_n": 0.08, &"@root": Vector2i(2, 0), &"emit:door_fire": 0}
	_puffs(h1, 2)
	_puffs(h2, 4)
	h1[&"view:drip"] = &"d0"
	h2[&"view:drip"] = &"d0"
	b.anim(&"hurt", 2, [90, 150], {0: h1, 1: h2}, {"loop": false, "interp": &"hold"})
	# Muerte (se desmorona): se encoge, las extremidades de carbón caen, queda el horno roto con la puerta apagándose.
	var legs_gone := {&"hide:foot_f": true, &"hide:foot_n": true, &"hide:calf_f": true, &"hide:calf_n": true}
	var arm_f_gone := {&"hide:fist_f": true, &"hide:fore_f2": true, &"hide:fore_f1": true}
	var d := {}
	d[0] = h1.duplicate()
	d[1] = {&"spine": -0.12, &"head": 0.25, &"arm_n": -0.15, &"@root": Vector2i(0, 2), &"view:head": &"hurt", &"emit:door_fire": 0}
	d[2] = {&"spine": -0.22, &"head": 0.4, &"arm_n": -0.3, &"fore_n": 0.25, &"@root": Vector2i(-1, 5), &"view:head": &"dead", &"emit:door_fire": -1, &"hide:fist_f": true, &"hide:fist_n": true, &"hide:knuckles": true}
	d[3] = {&"spine": -0.3, &"head": 0.5, &"arm_n": -0.4, &"fore_n": 0.45, &"@root": Vector2i(-2, 10), &"view:head": &"dead", &"emit:door_fire": -1, &"hide:fist_n": true, &"hide:knuckles": true, &"hide:fore_n2": true}
	d[3].merge(legs_gone)
	d[3].merge(arm_f_gone)
	d[4] = {&"spine": -0.34, &"head": 0.55, &"arm_n": -0.5, &"fore_n": 0.6, &"@root": Vector2i(-2, 15), &"view:head": &"dead", &"emit:door_fire": -2,
		&"hide:thigh_f": true, &"hide:thigh_n": true, &"hide:chimney_fire": true, &"hide:fist_n": true, &"hide:knuckles": true, &"hide:fore_n2": true, &"hide:fore_n1": true, &"hide:cuff_n": true, &"hide:cuff_rivets": true}
	d[4].merge(legs_gone)
	d[4].merge(arm_f_gone)
	for f in [5, 6, 7]:
		var dd: Dictionary = d[4].duplicate()
		dd[&"@root"] = Vector2i(-2, 19)
		dd[&"hide:upper_n"] = true
		dd[&"hide:pelvis"] = true
		dd[&"hide:upper_f"] = true
		dd[&"emit:door_fire"] = -2 - (f - 4)
		for i in 4:
			dd[StringName("hide:rubble_%d" % i)] = false
		d[f] = dd
	for f in [0, 1, 2, 3, 4]:
		for i in 4:
			(d[f] as Dictionary)[StringName("hide:rubble_%d" % i)] = true
		for i in 4:
			(d[f] as Dictionary)[StringName("hide:" + PUFFS[i])] = i > 2 - mini(f, 3)
	for f in [5, 6, 7]:
		for i in 4:
			(d[f] as Dictionary)[StringName("hide:" + PUFFS[i])] = true
	b.anim(&"death", 8, [80, 100, 110, 120, 140, 160, 200, 400], d, {"loop": false, "interp": &"hold"})
	# Los escombros sólo existen al final de la muerte.
	for an: StringName in b.def.anims.keys():
		if an == &"death":
			continue
		var a: RigDef.Anim = b.def.anims[an]
		for f: int in a.keys.keys():
			for i in 4:
				(a.keys[f] as Dictionary)[StringName("hide:rubble_%d" % i)] = true
