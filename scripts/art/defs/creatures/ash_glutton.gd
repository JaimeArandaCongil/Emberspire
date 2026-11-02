extends RefCounted
## DEVORADOR DE CENIZA (`ash_glutton`, acto 2) — PER · v0.4, motor de rig v1.
## Concepto: un hambriento de ceniza pálida, todo barriga; la barriga ES la boca. Come lo que el jugador quema (on_burn: cura 5).
## Silueta: pera invertida y encorvada — cabecita hundida entre hombros, joroba trasera con jirones de cartas quemadas pegados,
## panza enorme y baja que se adelanta, boca-gajo con dos filas de dientes en la panza, brazos larguísimos que casi arrastran.
## ≈ 76 px de alto en un lienzo de 104×96; pies en y = 88; mira a la izquierda.
## Rasgo vivo: la garganta late como una brasa y la baba cuelga del labio; los jirones de carta de la espalda se mecen; parpadea.
## Telegrafía (cast): alza los brazos hacia delante y abre la boca de par en par, la garganta al blanco (traga cartas).

const StampLib = preload("res://scripts/art/defs/stamps/stamp_lib.gd")

const MAW_W := 21
const MAW_X := -21.0
const MAW_Y := -9.0   # primera fila del interior (en el hueso "belly"); encima van los colmillos
const LEVELS := [1, 3, 7, 12]   # filas de interior de cada apertura; la mandíbula baja con ellas


static func _maw_rows(n: int) -> Array:
	# Garganta: brasa en degradado (borde rojo, centro blanco) entre dos labios de contorno.
	var rows: Array = []
	for r in n:
		var s := ""
		var mid := float(n - 1) / 2.0
		var hot := 1.0 - absf(r - mid) / maxf(mid + 0.5, 1.0)   # 0 en los bordes, 1 en el centro
		for c in MAW_W:
			if c == 0 or c == MAW_W - 1:
				s += "k"
			elif c == 1 or c == MAW_W - 2:
				s += "h"
			elif c < 4 or c > MAW_W - 5:
				s += "H" if hot > 0.3 else "h"
			elif hot > 0.75 and c > 5 and c < MAW_W - 6:
				s += "W"
			else:
				s += "e" if hot > 0.3 else "H"
		rows.append(s)
	return rows


static func _mouth(k: Dictionary, lvl: int) -> void:
	# lvl 0..3 = cerrada, entreabierta, abierta, de par en par. Muestra la mandíbula y el interior que tocan.
	k[&"view:belly"] = [&"shut", &"slack", &"open", &"gape"][lvl]
	for i in 4:
		k[StringName("hide:jaw_%d" % i)] = i != lvl
	if lvl == 3:
		k[&"hide:drip"] = true


static func build() -> RigDef:
	var b := RigBuilder.new(&"ash_glutton", Vector2i(104, 96), Vector2i(56, 70), -1)
	b.material(&"flesh", &"ash", {"texture": &"folds"})
	b.material(&"hide", &"ash")
	b.material(&"crust", &"soot", {"texture": &"soot_grain"})
	b.material(&"scrap", &"parchment", {"texture": &"scratches"})
	b.material(&"fire", &"fire")
	b.mask(&"hide", &"crust", &"soot", &"rise")

	# --- esqueleto
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"leg_f", &"root", Vector2(8, -3), {"z": -8.0})
	b.bone(&"leg_n", &"root", Vector2(-8, -3), {"z": 6.0})
	b.bone(&"spine", &"root", Vector2(0, -2))
	b.bone(&"belly", &"spine", Vector2(-4, -22), {"z": 8.0})
	b.bone(&"drip", &"belly", Vector2(-17, 5))
	b.bone(&"head", &"spine", Vector2(-9, -47), {"z": 22.0})
	b.bone(&"scraps", &"spine", Vector2(18, -46), {"z": -4.0})
	b.bone(&"arm_f", &"spine", Vector2(7, -37), {"z": -14.0, "angle": 0.2})
	b.bone(&"fore_f", &"arm_f", Vector2(0, 22), {"angle": 0.2})
	b.bone(&"arm_n", &"spine", Vector2(-9, -37), {"z": 16.0, "angle": 0.4})
	b.bone(&"fore_n", &"arm_n", Vector2(0, 23), {"angle": 0.45})

	# --- brazo lejano (detrás)
	b.cap(&"upper_f", &"arm_f", &"hide", Vector3(0, 0, 0), Vector3(0, 22, 0), 6.5, 5.0, {"ao": 1.4})
	b.cap(&"fore_f1", &"fore_f", &"hide", Vector3(0, 0, 0), Vector3(0, 19, 0), 5.0, 4.5, {"ao": 1.4})
	b.ell(&"hand_f", &"fore_f", &"hide", Vector3(0, 24, 0), Vector3(6.5, 7, 5.5), {"ao": 1.4, "tags": [&"hand"]})
	b.stamp_lib(&"hand_f_st", &"fore_f", Vector2(0, 24), StampLib.get_stamp("hand_open"), {"@hand": "@hide"}, {"z_top": false})
	# --- piernas: zancos cortos y combados bajo la panza
	for s: String in ["f", "n"]:
		var bn := StringName("leg_" + s)
		var ao := 1.4 if s == "f" else 1.0
		b.ell(StringName("thigh_" + s), bn, &"hide", Vector3(0, 1, 0), Vector3(6.5, 7, 6), {"ao": ao})
		b.ell(StringName("shin_" + s), bn, &"hide", Vector3(1, 9, 0), Vector3(5, 6, 5), {"ao": ao})
		b.ell(StringName("foot_" + s), bn, &"hide", Vector3(-4, 15, 1), Vector3(9.5, 4.5, 7), {"ao": ao, "flat": 0.3})
	# --- torso: joroba trasera, pecho estrecho, pelvis
	b.ell(&"pelvis", &"spine", &"hide", Vector3(2, -8, 0), Vector3(13, 9, 11), {"flat": 0.3})
	b.ell(&"chest", &"spine", &"flesh", Vector3(4, -35, 0), Vector3(12, 12, 11), {"flat": 0.4})
	b.ell(&"hump", &"spine", &"flesh", Vector3(14, -42, -3), Vector3(12, 12, 9), {"flat": 0.4})
	# jirones de cartas quemadas pegados a la espalda (se mecen)
	var tatter := [
		PackedVector2Array([Vector2(0, 0), Vector2(8, 1), Vector2(9, 12), Vector2(4, 10), Vector2(1, 15), Vector2(-1, 8)]),
		PackedVector2Array([Vector2(0, 0), Vector2(7, 2), Vector2(8, 9), Vector2(5, 17), Vector2(1, 11)]),
		PackedVector2Array([Vector2(0, 0), Vector2(6, -1), Vector2(10, 7), Vector2(4, 8)]),
	]
	for i in 3:
		b.poly(StringName("scrap_%d" % i), &"scraps", &"scrap", _scale(_shift(tatter[i], Vector2(i * 5 - 3, i * 7)), 1.7), -10.0 + i * 3.0, 1.0, 1.5, {"line": true})
	# --- la panza (la boca)
	b.ell(&"gut", &"belly", &"flesh", Vector3(-2, 0, 0), Vector3(26, 20, 19), {"flat": 0.4})
	b.ell(&"gut_low", &"belly", &"hide", Vector3(-4, 12, 0), Vector3(21, 12, 16), {"flat": 0.4})
	# colmillos de arriba (biblioteca) y las cuatro mandíbulas posibles de abajo
	var remap := {"@mouth": "@hide", "bone": &"linen"}
	b.stamp_lib(&"fangs_a", &"belly", Vector2(MAW_X + 3.0, MAW_Y - 3.0), StampLib.get_stamp("fangs_row"), remap, {"z_top": false})
	b.stamp_lib(&"fangs_b", &"belly", Vector2(MAW_X + 10.0, MAW_Y - 3.0), StampLib.get_stamp("fangs_row"), remap, {"z_top": false})
	b.stamp_lib(&"fangs_c", &"belly", Vector2(MAW_X + 17.0, MAW_Y - 3.0), StampLib.get_stamp("fangs_row"), remap, {"z_top": false})
	var maw_legend := {"k": ["@hide", "LINE"], "h": [&"fire", 2], "H": [&"fire", 3], "e": [&"fire", 4], "W": [&"fire", 6]}
	b.stamp(&"maw", &"belly", Vector2(MAW_X, MAW_Y), _maw_rows(LEVELS[1]), maw_legend, {"z_top": false, "views": {
		&"shut": _maw_rows(LEVELS[0]), &"slack": _maw_rows(LEVELS[1]), &"open": _maw_rows(LEVELS[2]), &"gape": _maw_rows(LEVELS[3])}})
	for i in 4:
		var top: float = MAW_Y + LEVELS[i]
		b.stamp_lib(StringName("jaw_%d" % i), &"belly", Vector2(MAW_X + 3.0, top), StampLib.get_stamp("teeth_grate"), remap, {"z_top": false})
		b.stamp_lib(StringName("jaw_%d_b" % i), &"belly", Vector2(MAW_X + 10.0, top), StampLib.get_stamp("teeth_grate"), remap, {"z_top": false})
		b.stamp_lib(StringName("jaw_%d_c" % i), &"belly", Vector2(MAW_X + 17.0, top), StampLib.get_stamp("teeth_grate"), remap, {"z_top": false})
	# baba de ceniza que cuelga del labio (vistas d0..d3)
	b.stamp(&"drip", &"drip", Vector2(0, 0), ["s", "S"], {"s": [&"ash", 6], "S": [&"ash", 4]}, {"z_top": false, "views": {
		&"d0": ["s", "S"], &"d1": ["s", "S", "S"], &"d2": [".", "s", "S", ".", "S"], &"d3": [".", ".", ".", ".", ".", "s"]}})
	# --- cabeza hundida, brazo cercano (delante)
	b.ell(&"skull", &"head", &"flesh", Vector3(0, 0, 0), Vector3(8.5, 8, 7.5), {"tags": [&"eye"]})
	b.poly(&"brow", &"head", &"crust", PackedVector2Array([Vector2(-10, -3), Vector2(4, -8), Vector2(9, -3), Vector2(-8, 0)]), 6.0, 1.2, 1.5)
	b.stamp_lib(&"eye_n", &"head", Vector2(-6, -1), StampLib.get_stamp("eye_ember_2x1"), {"@socket": "@hide"})
	b.stamp_lib(&"eye_f", &"head", Vector2(1, -2), StampLib.get_stamp("eye_ember_2x1"), {"@socket": "@hide"})
	b.cap(&"upper_n", &"arm_n", &"hide", Vector3(0, 0, 0), Vector3(0, 23, 0), 7.5, 5.5)
	b.cap(&"fore_n1", &"fore_n", &"hide", Vector3(0, 0, 0), Vector3(0, 20, 0), 5.5, 5.0)
	b.ell(&"hand_n", &"fore_n", &"hide", Vector3(0, 25, 0), Vector3(7.5, 8, 6.5), {"tags": [&"hand"]})
	b.stamp_lib(&"hand_n_st", &"fore_n", Vector2(0, 25), StampLib.get_stamp("hand_open"), {"@hand": "@hide"})

	# montón de ceniza de la muerte (a la altura del suelo cuando el root baja)
	for i in 4:
		var rp: Vector2 = [Vector2(-24, -3), Vector2(-10, -1), Vector2(10, -2), Vector2(26, -3)][i]
		b.ell(StringName("heap_%d" % i), &"root", &"flesh", Vector3(rp.x * 0.6, rp.y, 12), Vector3(12.0 - i * 1.5, 5.5, 7), {"flat": 0.3})
	b.socket(&"hit", &"fore_n", Vector2(0, 31))
	b.socket(&"intent", &"head", Vector2(0, -16))
	b.socket(&"mouth", &"belly", Vector2(MAW_X + 7.0, MAW_Y + 3.0))
	b.socket(&"heart", &"belly", Vector2(-6, 0))
	_anims(b)
	b.variant(&"sooty", {&"soot": 0.45})
	return b.def


static func _scale(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p * f)
	return o


static func _shift(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p + d)
	return o


static func _pose(base: Dictionary, over: Dictionary, lvl: int) -> Dictionary:
	var k := base.duplicate()
	k.merge(over, true)
	_mouth(k, lvl)
	return k


static func _anims(b: RigBuilder) -> void:
	# Reposo 8 f: la panza respira, la garganta late, la baba cuelga, los jirones se mecen, parpadea.
	var idle := {}
	for f in 8:
		var t := TAU * f / 8.0
		var k := {}
		k[&"@root"] = Vector2i(0, 1 if (f >= 4) else 0)
		k[&"spine"] = 0.02 * sin(t)
		k[&"belly"] = 0.025 * sin(t + 0.8)
		k[&"head"] = 0.05 * sin(t - 0.6)
		k[&"arm_n"] = -0.04 * sin(t)
		k[&"fore_n"] = 0.05 * sin(t - 0.5)
		k[&"arm_f"] = 0.03 * sin(t + 0.4)
		k[&"scraps"] = 0.1 * sin(t - 1.0)
		k[&"emit:maw"] = [0, 1, 1, 0, 0, -1, 0, 0][f]
		k[&"view:drip"] = [&"d0", &"d0", &"d1", &"d1", &"d2", &"d2", &"d3", &"d0"][f]
		k[&"hide:eye_n"] = f == 6
		k[&"hide:eye_f"] = f == 6
		_mouth(k, 1 if (f % 8) in [2, 3, 4] else 0)
		idle[f] = k
	b.anim(&"idle", 8, 150, idle, {"interp": &"linear", "overlap": {&"head": 1.0, &"arm_n": 1.5, &"fore_n": 2.0, &"arm_f": 1.5, &"scraps": 2.0}})

	# Telegrafía (cast): brazos al frente, cabeza atrás, boca de par en par con la garganta al blanco.
	var base_up := {&"spine": 0.1, &"belly": 0.05, &"head": -0.18, &"arm_n": 1.35, &"fore_n": 0.45, &"arm_f": 1.2, &"fore_f": 0.4,
		&"@root": Vector2i(2, -1), &"emit:maw": 1, &"view:drip": &"d0", &"scraps": 0.2}
	var c0 := _pose(base_up, {&"arm_n": 0.8, &"arm_f": 0.7, &"spine": 0.05, &"@root": Vector2i(1, 0), &"emit:maw": 0}, 2)
	var c1 := _pose(base_up, {}, 3)
	var c2 := _pose(base_up, {&"@root": Vector2i(2, -2), &"emit:maw": 3, &"arm_n": 1.5}, 3)
	b.anim(&"cast", 3, [110, 130, 380], {0: c0, 1: c1, 2: c2}, {"loop": false, "interp": &"hold"})

	# Ataque: se encoge y abre la boca → se lanza de bruces, mordisco y zarpazo → vuelve.
	var a0 := _pose({&"spine": 0.14, &"belly": 0.05, &"head": -0.12, &"arm_n": -0.5, &"fore_n": 0.2, &"arm_f": -0.4,
		&"@root": Vector2i(2, 0), &"emit:maw": 2, &"view:drip": &"d0", &"scraps": 0.2}, {}, 3)
	var a1 := _pose({&"spine": -0.28, &"belly": -0.1, &"head": 0.1, &"arm_n": 1.4, &"fore_n": 0.2, &"arm_f": 1.2, &"fore_f": 0.1,
		&"@root": Vector2i(-8, 2), &"emit:maw": 3, &"view:drip": &"d0", &"scraps": -0.15}, {}, 3)
	var a2 := _pose({&"spine": -0.34, &"belly": -0.12, &"head": 0.15, &"arm_n": 1.7, &"fore_n": 0.1, &"arm_f": 1.4,
		&"@root": Vector2i(-11, 3), &"emit:maw": 2, &"view:drip": &"d0", &"scraps": -0.2}, {}, 0)
	var a3 := _pose({&"spine": -0.1, &"belly": -0.03, &"head": 0.05, &"arm_n": 0.9, &"fore_n": 0.3, &"arm_f": 0.5,
		&"@root": Vector2i(-4, 1), &"emit:maw": 1, &"view:drip": &"d0"}, {}, 1)
	b.anim(&"attack", 4, [180, 70, 110, 170], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"fore_n", Vector2(0, 24), &"fire", 13.0, true).samples = 48

	# Golpe recibido: la boca se cierra de golpe, la cabeza atrás, ojos cerrados.
	var h1 := _pose({&"spine": 0.12, &"belly": 0.06, &"head": -0.25, &"arm_n": 0.9, &"fore_n": 0.5, &"arm_f": 0.5, &"@root": Vector2i(3, 0),
		&"emit:maw": -1, &"view:drip": &"d0", &"hide:eye_n": true, &"hide:eye_f": true, &"scraps": 0.3}, {}, 0)
	var h2 := _pose({&"spine": 0.06, &"belly": 0.03, &"head": -0.12, &"arm_n": 0.6, &"fore_n": 0.45, &"arm_f": 0.35, &"@root": Vector2i(2, 0),
		&"emit:maw": 0, &"view:drip": &"d0", &"scraps": 0.1}, {}, 1)
	b.anim(&"hurt", 2, [90, 150], {0: h1, 1: h2}, {"loop": false, "interp": &"hold"})

	# Muerte (se vacía): suelta un último rugido, se desinfla hacia atrás, los miembros caen y queda un montón de ceniza.
	var legs_gone := {&"hide:foot_f": true, &"hide:foot_n": true, &"hide:shin_f": true, &"hide:shin_n": true}
	var arm_f_gone := {&"hide:hand_f": true, &"hide:hand_f_st": true, &"hide:fore_f1": true}
	var d := {}
	d[0] = h1.duplicate()
	d[1] = _pose({&"spine": 0.2, &"belly": 0.1, &"head": -0.4, &"arm_n": 0.4, &"fore_n": 0.3, &"@root": Vector2i(3, 2), &"emit:maw": 3,
		&"view:drip": &"d0", &"hide:eye_n": true, &"hide:eye_f": true}, {}, 3)
	d[2] = _pose({&"spine": 0.3, &"belly": 0.12, &"head": -0.55, &"arm_n": 0.2, &"fore_n": 0.5, &"@root": Vector2i(2, 6), &"emit:maw": 1,
		&"hide:eye_n": true, &"hide:eye_f": true, &"hide:hand_f": true, &"hide:hand_f_st": true}, {}, 2)
	d[3] = _pose({&"spine": 0.4, &"belly": 0.15, &"head": -0.6, &"arm_n": 0.1, &"fore_n": 0.7, &"@root": Vector2i(2, 11), &"emit:maw": 0,
		&"hide:eye_n": true, &"hide:eye_f": true, &"hide:hand_n": true, &"hide:hand_n_st": true}, {}, 1)
	d[3].merge(legs_gone)
	d[3].merge(arm_f_gone)
	d[4] = _pose({&"spine": 0.5, &"belly": 0.2, &"head": -0.7, &"arm_n": 0.0, &"fore_n": 0.8, &"@root": Vector2i(2, 16), &"emit:maw": -1,
		&"hide:eye_n": true, &"hide:eye_f": true, &"hide:hand_n": true, &"hide:hand_n_st": true, &"hide:thigh_f": true, &"hide:thigh_n": true,
		&"hide:fore_n1": true, &"hide:scrap_0": true, &"hide:hump": true}, {}, 0)
	d[4].merge(legs_gone)
	d[4].merge(arm_f_gone)
	for f in [5, 6, 7]:
		var dd: Dictionary = d[4].duplicate()
		dd[&"@root"] = Vector2i(2, 17)
		dd[&"hide:upper_n"] = true
		dd[&"hide:upper_f"] = true
		dd[&"hide:pelvis"] = true
		dd[&"hide:scrap_1"] = true
		dd[&"hide:scrap_2"] = true
		dd[&"hide:chest"] = true
		dd[&"hide:gut"] = true
		dd[&"hide:skull"] = true
		dd[&"hide:brow"] = true
		dd[&"hide:fangs_a"] = true
		dd[&"hide:fangs_b"] = true
		dd[&"hide:fangs_c"] = true
		dd[&"hide:gut_low"] = true
		dd[&"hide:maw"] = true
		dd[&"hide:drip"] = true
		for j in 4:
			dd[StringName("hide:jaw_%d" % j)] = true
		dd[&"emit:maw"] = -2 - (f - 4)
		d[f] = dd
	for f in [5, 6, 7]:
		_mouth(d[f], 0)
		d[f][&"view:belly"] = &"shut"
		for j in 4:
			d[f][StringName("hide:jaw_%d" % j)] = true
	b.anim(&"death", 8, [80, 100, 110, 120, 140, 160, 200, 400], d, {"loop": false, "interp": &"hold"})

	# Cada hueco de mandíbula tiene dos sellos (_b): se muestran y ocultan juntos. El montón de ceniza sólo existe al final de la muerte.
	for an: StringName in b.def.anims.keys():
		var a: RigDef.Anim = b.def.anims[an]
		for f: int in a.keys.keys():
			var kk: Dictionary = a.keys[f]
			for i in 4:
				kk[StringName("hide:jaw_%d_b" % i)] = kk.get(StringName("hide:jaw_%d" % i), true)
				kk[StringName("hide:jaw_%d_c" % i)] = kk.get(StringName("hide:jaw_%d" % i), true)
			for i in 4:
				var hide_heap := true
				if an == &"death" and f >= 5:
					hide_heap = false
				kk[StringName("hide:heap_%d" % i)] = hide_heap
