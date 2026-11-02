extends RefCounted
## GÓLEM DE HOLLÍN (`soot_golem`, acto 1) — PER · v0.4, motor de rig v1.
## Concepto: un horno de ladrillo encorvado que anda con los nudillos y lleva el fuego en la barriga.
## Silueta: joroba alta con chimenea detrás, cabeza de carbón ARRIBA sobre el hombro delantero, puño enorme apoyado (gorila).
## ≈ 88 px de alto en un lienzo de 128×128; pies en y = 120; mira a la izquierda.
## Rasgo vivo (6 f): la chimenea humea, la puerta late, cae una gota de hollín; el cuerpo sólo sube y baja 1 px.
## Muerte por material: se agrieta, se le van las extremidades de carbón, la bóveda de ladrillo se hunde y queda un muñón de muro con la puerta apagándose.
## Telegrafía (cast): alza el puño por delante de la cabeza (despejado, sin taparla) y la puerta se pone al blanco.
## Ataque: carga el peso atrás y descarga el puño avanzando 9 px; recupera a 4 px.

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
	var b := RigBuilder.new(&"soot_golem", Vector2i(128, 128), Vector2i(76, 100), -1)
	b.material(&"brick", &"furnace_brick", {"tex_fn": _bricks})
	b.material(&"coal", &"coal", {"facet": {"cell_area": 40.0, "weight": 0.6, "crack": 0.18, "crack_slot": &"magma"}, "spec": true})
	# Hollín gris ceniza mate (pasos 4–6): sólo lo usa la variante `sooty`; separa el valor del muro (F2-PULIDO-D).
	b.material(&"soot", &"ash", {"texture": &"soot_grain", "tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return clampi(st, 4, 6)})
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
	b.bone(&"head", &"spine", Vector2(-21, -42), {"z": 22.0})
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
	# Muerte: grietas de fuego, ladrillos que saltan, muñón de muro y cabeza caída (con @root = (0, 19), y local 1 = suelo).
	b.stamp(&"cracks", &"spine", Vector2(-14, -40), [
		"......h..........h....",
		".......h........hH....",
		"......hH.......hH.....",
		".....hH.........H.....",
		"......H.........hH....",
		"......hH.........H....",
		".......H........hH....",
		".......h........H.....",
	], {"h": [&"hot", 2], "H": [&"hot", 4]}, {"z_top": false})
	var br := {"#": [&"brick", 6], "%": [&"brick", 4]}
	b.stamp(&"bricks_fly", &"root", Vector2(-30, -58), ["."], br, {"views": {
		&"none": ["."],
		&"b0": _pts(66, 44, [[8, 16], [22, 6], [40, 2], [56, 10], [60, 22], [2, 26]]),
		&"b1": _pts(66, 44, [[4, 26], [18, 18], [44, 12], [58, 22], [62, 34], [0, 36], [30, 8]]),
	}})
	b.poly(&"stump", &"root", &"brick", PackedVector2Array([Vector2(-30, 1), Vector2(-31, -9), Vector2(-24, -15), Vector2(-18, -12), Vector2(-13, -22), Vector2(-5, -20), Vector2(-1, -27), Vector2(8, -24), Vector2(12, -30), Vector2(20, -20), Vector2(25, -21), Vector2(32, -10), Vector2(33, 1)]), 12.0, 3.0, 5.0)
	b.stamp(&"stump_door", &"root", Vector2(-12, -14), [
		".iiiiiiiiiiiii.",
		"iihHHHHHHHHHhii",
		"iHHkHHkHHkHHkHi",
		"iHHkHHkHHkHHkHi",
		"iHhkhhkhhkhhkhi",
		"iiiiiiiiiiiiiii",
	], {"i": [&"iron", 5], "k": [&"iron", 2], "h": [&"fire", 2], "H": [&"fire", 4]}, {})
	for i in 5:
		var rb: Vector2 = [Vector2(-42, -5), Vector2(-20, -3), Vector2(24, -4), Vector2(36, -5), Vector2(44, -3)][i]
		b.box(StringName("brick_down_%d" % i), &"root", &"brick", Vector3(rb.x, rb.y, 16), Vector3(9, 5, 5), 1.0)
	b.ell(&"skull_down", &"root", &"coal", Vector3(-37, -7, 18), Vector3(10.5, 8, 7), {"flat": 0.3})
	b.stamp(&"face_down", &"root", Vector2(-46, -8), ["kkkkk..kkkk", "...........", "kkkkkkkkkk.", "khkhkhkhk.."], {"k": [&"coal", 0], "h": [&"fire", 1]}, {})
	b.socket(&"hit", &"fore_n", Vector2(0, 28))
	b.socket(&"intent", &"head", Vector2(0, -18))
	b.socket(&"smoke", &"spine", Vector2(19, -58))
	b.socket(&"heart", &"spine", Vector2(-4, -15))
	_anims(b)
	b.variant(&"sooty", {&"soot": 0.5})
	return b.def


const PUFFS := ["puff_0", "puff_1", "puff_2", "puff_3"]
const DEATH_PARTS := [&"cracks", &"stump", &"stump_door", &"brick_down_0", &"brick_down_1", &"brick_down_2", &"brick_down_3", &"brick_down_4", &"skull_down", &"face_down", &"rubble_0", &"rubble_1", &"rubble_2", &"rubble_3"]


## Ladrillos sueltos para el sello de vistas: bloque de 3×2.
static func _pts(w: int, h: int, pts: Array) -> Array:
	var rows: Array = []
	for y in h:
		rows.append(".".repeat(w))
	for p: Array in pts:
		for dy in 2:
			var r: String = rows[p[1] + dy]
			rows[p[1] + dy] = r.substr(0, p[0]) + ("###" if dy == 0 else "%%%") + r.substr(p[0] + 3)
	return rows


## Oculta lo de la muerte en cualquier pose viva.
static func _alive(k: Dictionary) -> Dictionary:
	for id: StringName in DEATH_PARTS:
		k[StringName("hide:%s" % id)] = true
	k[&"view:bricks_fly"] = &"none"
	return k


static func _puffs(k: Dictionary, f: int) -> void:
	# Ciclo de humo: la columna crece y mengua desde la boca de la chimenea; nunca se despega.
	var n: int = [2, 3, 4, 3][f % 4]
	for i in 4:
		k[StringName("hide:" + PUFFS[i])] = i >= n


static func _anims(b: RigBuilder) -> void:
	# Reposo 6 f: el cuerpo no se mece; humo, goteo y puerta que late hacen el rasgo vivo. Cabeza y brazo: 1 paso con retraso.
	var idle := {}
	for f in 6:
		var k := {}
		k[&"@root"] = Vector2i(0, 1 if f in [3, 4] else 0)
		k[&"head"] = 0.05 if f in [2, 3] else 0.0
		k[&"emit:door_fire"] = [0, 1, 2, 1, 0, -1][f]
		k[&"emit:face"] = [0, 0, 0, 0, -2, 0][f]   # parpadeo de las brasas
		k[&"view:drip"] = [&"d0", &"d0", &"d1", &"d2", &"d3", &"d0"][f]
		_puffs(k, f)
		idle[f] = _alive(k)
	b.anim(&"idle", 6, 170, idle, {"interp": &"hold"})
	# Telegrafía (cast): se encabrita (columna atrás: la cabeza sube por encima del hombro) rugiendo; el brazo cercano sale
	# horizontal por DELANTE y por DEBAJO de la cara y el antebrazo sube vertical: el puño queda delante, a la altura de la
	# frente y separado de la cara (silueta despejada).
	var tell := {&"spine": 0.24, &"head": -0.1, &"arm_n": 0.52, &"fore_n": 1.6, &"arm_f": -0.2, &"leg_n": -0.05, &"@root": Vector2i(2, -1),
		&"emit:door_fire": 2, &"emit:face": 1, &"view:head": &"roar", &"view:drip": &"d0", &"hide:knuckles": true}
	var tell2 := tell.duplicate()
	tell2[&"@root"] = Vector2i(3, -2)
	tell2[&"spine"] = 0.28
	tell2[&"emit:door_fire"] = 3
	_puffs(tell, 0)
	_puffs(tell2, 1)
	_alive(tell)
	_alive(tell2)
	b.anim(&"cast", 2, [120, 400], {0: tell, 1: tell2}, {"loop": false, "interp": &"hold"})
	# Ataque: carga atrás (= telegrafía) → estela con el cuerpo ya en marcha → puñetazo al suelo 9 px por delante, pierna
	# cercana adelantada y la lejana estirada atrás (el peso cae sobre el puño) → recuperación a medio camino.
	var swing := {&"spine": -0.06, &"head": 0.02, &"arm_n": 0.45, &"fore_n": 0.2, &"arm_f": 0.1, &"leg_n": 0.12, &"leg_f": -0.08,
		&"@root": Vector2i(-5, 0), &"emit:door_fire": 2, &"emit:knuckles": 2, &"view:head": &"roar", &"view:drip": &"d0", &"z:arm_n": 24.0}
	var smash := {&"spine": -0.16, &"head": 0.08, &"arm_n": 0.05, &"fore_n": 0.05, &"arm_f": 0.2, &"leg_n": 0.22, &"leg_f": -0.16,
		&"@root": Vector2i(-9, 2), &"emit:door_fire": 2, &"emit:knuckles": 3, &"view:head": &"roar", &"view:drip": &"d0"}
	var settle := {&"spine": -0.07, &"head": 0.04, &"arm_n": 0.04, &"fore_n": 0.03, &"leg_n": 0.1, &"leg_f": -0.06,
		&"@root": Vector2i(-4, 1), &"emit:door_fire": 1, &"view:drip": &"d0"}
	_puffs(swing, 2)
	_puffs(smash, 2)
	_puffs(settle, 3)
	_alive(swing)
	_alive(smash)
	_alive(settle)
	b.anim(&"attack", 4, [140, 40, 110, 160], {0: tell2, 1: swing, 2: smash, 3: settle}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"fore_n", Vector2(0, 24), &"fire", 15.0, false).samples = 48
	# Golpe recibido: retrocede, la cabeza atrás, ojos cerrados un instante.
	var h1 := {&"spine": 0.1, &"head": -0.2, &"arm_n": 0.15, &"@root": Vector2i(3, 0), &"view:head": &"hurt", &"emit:door_fire": -1}
	var h2 := {&"spine": 0.05, &"head": -0.1, &"arm_n": 0.08, &"@root": Vector2i(2, 0), &"emit:door_fire": 0}
	_puffs(h1, 1)
	_puffs(h2, 2)
	_alive(h1)
	_alive(h2)
	h1[&"view:drip"] = &"d0"
	h2[&"view:drip"] = &"d0"
	b.anim(&"hurt", 2, [90, 150], {0: h1, 1: h2}, {"loop": false, "interp": &"hold"})
	# Muerte por material: el horno se agrieta → se le van puños y patas de carbón → la bóveda cae, saltan ladrillos → muñón de muro; la puerta se apaga.
	var coal_gone := {&"hide:fist_f": true, &"hide:fore_f2": true, &"hide:fore_f1": true, &"hide:fist_n": true, &"hide:knuckles": true, &"hide:fore_n2": true, &"hide:foot_f": true, &"hide:foot_n": true, &"hide:calf_f": true, &"hide:calf_n": true}
	var d := {}
	d[0] = h1.duplicate()
	d[0][&"emit:door_fire"] = 2
	d[1] = _alive({&"spine": -0.04, &"head": 0.2, &"arm_n": -0.1, &"@root": Vector2i(1, 1), &"view:head": &"hurt", &"emit:door_fire": 3, &"hide:cracks": false})
	d[2] = _alive({&"spine": -0.08, &"head": 0.4, &"arm_n": -0.2, &"fore_n": 0.2, &"@root": Vector2i(0, 5), &"view:head": &"dead", &"emit:door_fire": 2, &"hide:cracks": false, &"hide:chimney_fire": true, &"hide:fist_f": true, &"hide:fist_n": true, &"hide:knuckles": true, &"view:bricks_fly": &"b0"})
	d[3] = _alive({&"spine": -0.1, &"head": 0.5, &"arm_n": -0.35, &"fore_n": 0.4, &"@root": Vector2i(0, 11), &"view:head": &"dead", &"emit:door_fire": 1, &"hide:cracks": false, &"hide:chimney_fire": true, &"hide:chimney": true, &"hide:chimney_cap": true, &"view:bricks_fly": &"b1"})
	d[3].merge(coal_gone)
	# Muñón: se oculta todo lo que estaba en pie.
	var fall := _alive({&"@root": Vector2i(0, 19), &"emit:stump_door": -1, &"view:head": &"dead", &"view:bricks_fly": &"none"})
	fall.merge(coal_gone)
	for pid: String in ["torso", "hump", "pelvis", "chimney", "chimney_cap", "chimney_fire", "door", "door_fire", "skull", "brow", "face", "upper_n", "upper_f", "cuff_n", "cuff_rivets", "fore_n1", "thigh_f", "thigh_n", "drip", "hoop_38", "hoop_27"]:
		fall[StringName("hide:" + pid)] = true
	for y0: int in [38, 27]:
		for i in 7:
			fall[StringName("hide:rivet_%d_%d" % [y0, i])] = true
	for id: StringName in DEATH_PARTS:
		fall[StringName("hide:%s" % id)] = id == &"cracks"
	d[4] = fall
	d[5] = fall.duplicate()
	d[5][&"emit:stump_door"] = -1
	d[6] = fall.duplicate()
	d[6][&"emit:stump_door"] = -2
	d[7] = fall.duplicate()
	d[7][&"emit:stump_door"] = -4
	for f in [0, 1, 2, 3, 4, 5, 6, 7]:
		for i in 4:
			(d[f] as Dictionary)[StringName("hide:rubble_%d" % i)] = f < 3
		for i in 4:
			(d[f] as Dictionary)[StringName("hide:" + PUFFS[i])] = f > 3 or i > 2 - mini(f, 3)
	b.anim(&"death", 8, [80, 100, 110, 120, 140, 160, 200, 400], d, {"loop": false, "interp": &"hold"})
	# Los escombros sólo existen al final de la muerte.
	for an: StringName in b.def.anims.keys():
		if an == &"death":
			continue
		var a: RigDef.Anim = b.def.anims[an]
		for f: int in a.keys.keys():
			for i in 4:
				(a.keys[f] as Dictionary)[StringName("hide:rubble_%d" % i)] = true
