extends RefCounted
## DEVORADOR DE CENIZA (`ash_glutton`, normal, acto 2) — F2-CRIA · rehecho desde cero.
## Concepto: un carroñero de los ceniceros de la Torre. Bestia a cuatro patas que traga ceniza caliente hasta reventar;
## la escoria se le ha cuajado en el lomo y por las costuras de la panza asoma lo que aún arde.
## Silueta: cráneo-máscara enorme a ras de suelo con colmillos hacia arriba, cresta de cinco esquirlas que cae de la cruz
## a la grupa, panza colgante entre las patas, rabo corto. Cuadrúpedo: ningún otro enemigo del corte comparte esa forma.
## ≈ 70 px de alto en un lienzo de 168×116; suelo en y = 104; mira a la izquierda.
## Materiales: escoria vítrea (lomo), piel de ceniza (cuerpo), hueso (máscara, colmillos), brasa (garganta, costuras).
## Rasgo vivo: mastica; al cerrar la mandíbula traga, la garganta y las costuras se avivan y se le cae ceniza de la boca.
## Telegrafía (cast): alza la cabeza y abre la boca al máximo. Ataque: embestida con mordisco.
## Muerte: la piel se agrieta y se deshace en ceniza, las esquirlas se sueltan, asoman las costillas y queda un montón con el cráneo.

const G := 104   # fila del suelo en el lienzo
const ORIGIN := Vector2i(100, G - 18)
const FEET := {
	&"ik:fore_n": Vector2(77, G - 3), &"ik:fore_f": Vector2(90, G - 4),
	&"ik:hind_n": Vector2(121, G - 3), &"ik:hind_f": Vector2(134, G - 4),
}
const HIDE_DEAD := [&"heap", &"heap_top", &"skull_down", &"tusk_down", &"ribs_down", &"scrap_a", &"scrap_b", &"scrap_c", &"ribs", &"cavity", &"coals", &"crumble"]
const ALL_BODY := [&"torso", &"belly", &"neck", &"tail_p", &"thigh_n_p", &"shin_n_p", &"paw_n_h", &"thigh_f_p", &"shin_f_p", &"paw_f_h",
	&"arm_n_p", &"fore_n_p", &"paw_n_f", &"arm_f_p", &"fore_f_p", &"paw_f_f", &"skull", &"brow", &"snout_plate", &"jaw_p", &"tusk_n", &"tusk_f", &"maw", &"ruff"]
const STAMPS_BODY := [&"seams", &"throat", &"bubbles", &"eye", &"nostril", &"teeth_up", &"teeth_lo", &"cracks_skull", &"claws_nf", &"claws_ff", &"claws_nh", &"claws_fh"]


## Pelaje de hollín: mechones de 1 px cortados, más oscuro hacia el lomo.
static func _hide(l: Vector2, st: int, n: int) -> int:
	st = mini(st, n - 1)
	if l.y < -20.0:
		st -= 1
	if st >= 3 and fposmod(l.x + 0.6 * l.y, 7.0) < 1.0 and fposmod(l.y, 6.0) < 4.0:
		st -= 1
	return st


## Patas: calzas negras de hollín hacia la pezuña.
static func _leg(l: Vector2, st: int, n: int) -> int:
	st = mini(st, n - 1)
	if l.y > 7.0:
		st -= 1
	return st


## Panza de ceniza clara, distendida: pliegues que cuelgan.
static func _belly(l: Vector2, st: int, n: int) -> int:
	st = mini(st, n - 2)
	if st >= 3 and fposmod(l.y + 0.03 * l.x * l.x, 6.0) < 1.0:
		st -= 2
	return st


## Escoria vítrea: oscura, el especular y el canto hacen el trabajo.
static func _glass(_l: Vector2, st: int, _n: int) -> int:
	return maxi(1, st - 1)


static func build() -> RigDef:
	var b := RigBuilder.new(&"ash_glutton", Vector2i(168, 116), ORIGIN, -1)
	b.material(&"slag", &"slag", {"facet": {"cell_area": 26.0, "weight": 0.9}, "spec": true, "tex_fn": _glass})
	b.material(&"hide", &"soot", {"tex_fn": _hide})
	b.material(&"belly", &"ash", {"tex_fn": _belly})
	b.material(&"leg", &"soot", {"tex_fn": _leg})
	b.material(&"bone", &"linen")
	b.material(&"dark", &"coal")
	b.material(&"hot", &"hot")
	b.material(&"fire", &"fire")
	# --- esqueleto (`body`: 10 px sobre la raíz; suelo a +18 de la raíz)
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"body", &"root", Vector2(0, -10))
	b.bone(&"tail", &"body", Vector2(31, -8), {"z": -6.0})
	b.bone(&"hind_f", &"body", Vector2(27, -2), {"z": -12.0})
	b.bone(&"shin_hf", &"hind_f", Vector2(4, 15))
	b.bone(&"hind_n", &"body", Vector2(17, -2), {"z": 10.0})
	b.bone(&"shin_hn", &"hind_n", Vector2(4, 15))
	b.bone(&"fore_f", &"body", Vector2(-12, -6), {"z": -12.0})
	b.bone(&"shin_ff", &"fore_f", Vector2(0, 16))
	b.bone(&"fore_n", &"body", Vector2(-24, -6), {"z": 12.0})
	b.bone(&"shin_fn", &"fore_n", Vector2(0, 16))
	for i in 5:
		var at: Vector2 = [Vector2(-25, -21), Vector2(-14, -25), Vector2(-3, -25), Vector2(10, -19), Vector2(22, -12)][i]
		b.bone(StringName("pl%d" % i), &"body", at, {"z": 4.0})
	b.bone(&"neck", &"body", Vector2(-27, -10), {"z": 14.0})
	b.bone(&"head", &"neck", Vector2(-12, 11), {"z": 8.0})
	b.bone(&"jaw", &"head", Vector2(9, 1), {"z": -2.0})
	b.bone(&"dust", &"root", Vector2.ZERO, {"z": 30.0})
	b.ik(&"hind_f", &"hind_f", &"shin_hf", Vector2(0, 14), -1)
	b.ik(&"hind_n", &"hind_n", &"shin_hn", Vector2(0, 14), -1)
	b.ik(&"fore_f", &"fore_f", &"shin_ff", Vector2(0, 14), 1)
	b.ik(&"fore_n", &"fore_n", &"shin_fn", Vector2(0, 14), 1)
	# --- patas lejanas (más oscuras por AO)
	_leg_h(b, "f", -12.0, 1.6)
	_leg_fr(b, "f", -12.0, 1.6)
	# --- rabo corto, roto
	b.poly(&"tail_p", &"tail", &"leg", PackedVector2Array([Vector2(-3, -5), Vector2(5, -6), Vector2(14, -14), Vector2(18, -13), Vector2(14, -4), Vector2(7, 3), Vector2(-3, 5)]), 0.0, 1.6, 3.0)
	# --- cuerpo: cruz alta, lomo que cae, cintura estrecha. Polígono quebrado, ni una elipse.
	b.poly(&"torso", &"body", &"hide", PackedVector2Array([
		Vector2(-34, -10), Vector2(-30, -20), Vector2(-20, -27), Vector2(-8, -28), Vector2(4, -24), Vector2(16, -16), Vector2(28, -11), Vector2(35, -4), Vector2(35, 4),
		Vector2(29, 8), Vector2(20, 5), Vector2(11, 3), Vector2(-16, 4), Vector2(-27, 8), Vector2(-34, 2)]), 0.0, 3.5, 7.0)
	# --- panza que cuelga entre las patas (colgajo asimétrico)
	b.poly(&"belly", &"body", &"belly", PackedVector2Array([
		Vector2(-19, -7), Vector2(-6, -10), Vector2(9, -6), Vector2(16, 0), Vector2(14, 7), Vector2(8, 11), Vector2(2, 14), Vector2(-6, 15), Vector2(-14, 12), Vector2(-20, 5)]), 3.0, 3.0, 5.0)
	b.stamp(&"seams", &"body", Vector2(-13, -6), [
		".....h..............",
		".....Hh.......h.....",
		"......H.......Hh....",
		"......Hh.......H....",
		".......H......hH....",
		"..h....Hh.....H.....",
		"..Hh....H....hH.....",
		"...H....hF...H......",
		"...Hh....H..hH......",
		"....H....h..h.......",
	], {"h": [&"hot", 2], "H": [&"hot", 3], "F": [&"hot", 4]}, {"z_top": false})
	# --- esquirlas de escoria, barridas hacia atrás; dos grandes en la cruz, tres menguantes. Cada una en su hueso: se sueltan al morir.
	b.poly(&"plate0", &"pl0", &"slag", PackedVector2Array([Vector2(-7, 5), Vector2(-5, -7), Vector2(2, -17), Vector2(4, -6), Vector2(7, 5)]), 0.0, 1.2, 3.0)
	b.poly(&"plate1", &"pl1", &"slag", PackedVector2Array([Vector2(-6, 5), Vector2(-3, -9), Vector2(6, -18), Vector2(7, -8), Vector2(9, 5)]), 0.0, 1.2, 3.0)
	b.poly(&"plate2", &"pl2", &"slag", PackedVector2Array([Vector2(-7, 5), Vector2(-2, -5), Vector2(9, -14), Vector2(8, -2), Vector2(8, 6)]), 0.0, 1.2, 3.0)
	b.poly(&"plate3", &"pl3", &"slag", PackedVector2Array([Vector2(-6, 4), Vector2(-1, -3), Vector2(9, -8), Vector2(8, 1), Vector2(6, 6)]), 0.0, 1.2, 3.0)
	b.poly(&"plate4", &"pl4", &"slag", PackedVector2Array([Vector2(-6, 3), Vector2(1, -2), Vector2(10, -4), Vector2(8, 2), Vector2(4, 6)]), 0.0, 1.0, 2.0)
	b.stamp(&"bubbles", &"body", Vector2(-27, -36), [
		"..............e.........",
		"........................",
		"..e.......e.............",
		"........................",
		"................e.......",
		".......e................",
		"....................e...",
	], {"e": [&"hot", 4]}, {"z_top": false})
	# --- patas cercanas
	_leg_h(b, "n", 3.0, 1.0)
	_leg_fr(b, "n", 3.0, 1.0)
	# --- cuello largo y colgante con gorguera quebrada
	b.poly(&"neck", &"neck", &"hide", PackedVector2Array([Vector2(-8, -9), Vector2(-16, 0), Vector2(-20, 7), Vector2(-14, 18), Vector2(-4, 16), Vector2(6, 14), Vector2(10, 8), Vector2(9, -6), Vector2(3, -13)]), 2.0, 3.0, 5.0)
	b.poly(&"ruff", &"neck", &"slag", PackedVector2Array([Vector2(-3, -10), Vector2(-14, -11), Vector2(-9, -3), Vector2(-17, 0), Vector2(-10, 5), Vector2(-3, 3)]), 8.0, 1.0, 2.0)
	# --- cabeza: mandíbula (detrás), garganta oscura con la brasa al fondo, máscara de hueso (delante)
	b.poly(&"maw", &"head", &"dark", PackedVector2Array([Vector2(10, -2), Vector2(-26, 0), Vector2(-26, 10), Vector2(-6, 15), Vector2(10, 9)]), -1.0, 1.0, 1.0, {"line": false})
	b.stamp(&"throat", &"head", Vector2(-9, 2), [
		"....hhh.",
		"..hHHHHh",
		".hHFFFHh",
		"hHFWWFHh",
		".hHFFHh.",
		"..hhHh..",
	], {"h": [&"hot", 2], "H": [&"hot", 3], "F": [&"hot", 4], "W": [&"hot", 5]}, {"z_top": false})
	b.poly(&"jaw_p", &"jaw", &"bone", PackedVector2Array([Vector2(5, -5), Vector2(6, 6), Vector2(-3, 12), Vector2(-20, 15), Vector2(-34, 14), Vector2(-37, 8), Vector2(-26, 6), Vector2(-10, 5), Vector2(-3, 1)]), 0.0, 1.6, 3.0)
	b.stamp(&"teeth_lo", &"jaw", Vector2(-34, 3), [
		"C...C..C...C..C",
		"c...c..c...c..c",
		"c..cc.cc..cc.cc",
	], {"c": [&"bone", 4], "C": [&"bone", 6]}, {})
	b.poly(&"tusk_f", &"jaw", &"bone", PackedVector2Array([Vector2(-24, 8), Vector2(-28, -4), Vector2(-28, -13), Vector2(-22, -4), Vector2(-18, 7)]), -3.0, 1.0, 2.0, {"ao": 1.4})
	b.poly(&"skull", &"head", &"bone", PackedVector2Array([
		Vector2(12, -8), Vector2(9, -13), Vector2(-3, -15), Vector2(-14, -11), Vector2(-27, -6), Vector2(-34, -3), Vector2(-35, 2), Vector2(-26, 3),
		Vector2(-10, 3), Vector2(4, 4), Vector2(11, 1)]), 4.0, 2.4, 5.0, {"tags": [&"eye"]})
	b.poly(&"snout_plate", &"head", &"dark", PackedVector2Array([Vector2(-35, -2), Vector2(-27, -6), Vector2(-22, -4), Vector2(-26, 1), Vector2(-35, 2)]), 7.0, 0.8, 1.0, {"line": false})
	b.poly(&"brow", &"head", &"slag", PackedVector2Array([Vector2(10, -14), Vector2(5, -21), Vector2(-3, -19), Vector2(-5, -25), Vector2(-16, -14), Vector2(-18, -9), Vector2(-8, -11), Vector2(0, -11), Vector2(10, -9)]), 8.0, 1.0, 2.0, {"line": false})
	b.poly(&"tusk_n", &"jaw", &"bone", PackedVector2Array([Vector2(-34, 9), Vector2(-40, -5), Vector2(-43, -17), Vector2(-36, -9), Vector2(-28, 7)]), 16.0, 1.0, 2.0, {"line": false})
	b.stamp(&"eye", &"head", Vector2(-13, -9), [
		".kkkkk.",
		"kkEFkkk",
		"kkFFkkk",
		".kkkk..",
	], {"k": [&"dark", 0], "E": [&"fire", 7], "F": [&"fire", 4]}, {"z_top": false, "views": {
		&"shut": [".kkkkk.", "kkkkkkk", "kFFFkkk", ".kkkk.."],
		&"dead": [".kkkkk.", "kkkkkkk", "kkkkkkk", ".kkkk.."],
	}})
	b.stamp(&"nostril", &"head", Vector2(-32, -2), ["kk", ".k"], {"k": [&"dark", 0]}, {"z_top": false})
	b.stamp(&"teeth_up", &"head", Vector2(-33, 3), [
		"CC.C..C.C..C.C",
		".c.c..c.c..c.c",
		".c....c....c..",
	], {"c": [&"bone", 4], "C": [&"bone", 6]}, {})
	b.stamp(&"cracks_skull", &"head", Vector2(0, -12), ["k....", ".k...", ".kk..", "...k.", "...k."], {"k": [&"bone", 2]}, {"z_top": false})
	# --- muerte. Con @root = (0, 18), y local 0 = suelo.
	b.poly(&"cavity", &"body", &"dark", PackedVector2Array([Vector2(-20, -10), Vector2(14, -8), Vector2(18, 2), Vector2(8, 11), Vector2(-12, 12), Vector2(-22, 4)]), 8.0, 2.0, 2.0, {"line": false})
	b.stamp(&"coals", &"body", Vector2(-14, 4), [
		"....h.......h.....",
		"..hHHh....hHHh..h.",
		".hHFFHh..hHFHh.hHh",
		"hHFFFFHhhHFFFHhHFH",
	], {"h": [&"hot", 2], "H": [&"hot", 3], "F": [&"hot", 4]}, {})
	b.stamp(&"ribs", &"body", Vector2(-20, -11), [
		".CC....CC....CC....CC.",
		"cc....cc....cc....cc..",
		"c....c.c...c.c...c.c..",
		"c....c.c...c.c...c.c..",
		"c....c.c...c.c...c.c..",
		"c....c.c...c.c...c....",
		"c.....cc....cc...c....",
		".c....c.....c....c....",
		".c....c.....c.........",
		"..c...c.....c.........",
	], {"c": [&"bone", 3], "C": [&"bone", 5]}, {})
	b.poly(&"crumble", &"body", &"belly", PackedVector2Array([
		Vector2(-34, 4), Vector2(-26, -6), Vector2(-17, 2), Vector2(-8, 0), Vector2(2, 5), Vector2(14, -1), Vector2(26, -9), Vector2(38, -2), Vector2(36, 9), Vector2(20, 13), Vector2(-18, 14), Vector2(-30, 11)]), 6.0, 3.0, 4.0)
	b.poly(&"heap", &"root", &"belly", PackedVector2Array([
		Vector2(-44, 0), Vector2(-34, -5), Vector2(-24, -6), Vector2(-14, -13), Vector2(-2, -17), Vector2(8, -14), Vector2(20, -10), Vector2(32, -6), Vector2(42, -3), Vector2(50, 0)]), 4.0, 3.0, 5.0)
	b.poly(&"heap_top", &"root", &"hide", PackedVector2Array([Vector2(-22, -4), Vector2(-10, -11), Vector2(-1, -15), Vector2(9, -11), Vector2(20, -5), Vector2(10, -2), Vector2(-10, -2)]), 8.0, 2.0, 2.0)
	# Caja torácica medio enterrada y cráneo caído con su colmillo: se reconoce qué era.
	b.stamp(&"ribs_down", &"root", Vector2(-1, -21), [
		"..CC...CC...CC.",
		".cc...cc...cc..",
		"c....c..c....c.",
		"c....c..c....c.",
		"c....c..c.....c",
		"c....c..c.....c",
	], {"c": [&"bone", 3], "C": [&"bone", 5]}, {})
	b.poly(&"skull_down", &"root", &"bone", PackedVector2Array([Vector2(-16, -1), Vector2(-20, -10), Vector2(-30, -14), Vector2(-40, -9), Vector2(-50, -4), Vector2(-52, 0), Vector2(-20, 0)]), 12.0, 1.6, 3.0)
	b.poly(&"tusk_down", &"root", &"bone", PackedVector2Array([Vector2(-51, 0), Vector2(-55, -8), Vector2(-58, -15), Vector2(-52, -9), Vector2(-46, 0)]), 13.0, 1.0, 2.0, {"line": false})
	b.poly(&"scrap_a", &"root", &"slag", PackedVector2Array([Vector2(20, 0), Vector2(25, -9), Vector2(36, -13), Vector2(38, 0)]), 14.0, 1.2, 2.0)
	b.poly(&"scrap_b", &"root", &"slag", PackedVector2Array([Vector2(-8, -4), Vector2(-3, -14), Vector2(10, -10), Vector2(8, -3)]), 15.0, 1.2, 2.0)
	b.poly(&"scrap_c", &"root", &"slag", PackedVector2Array([Vector2(42, 1), Vector2(47, -5), Vector2(57, -5), Vector2(56, 1)]), 13.0, 1.0, 2.0)
	b.stamp(&"skull_eye", &"root", Vector2(-36, -8), [".kkkk.", "kkkkkk", ".kkk.."], {"k": [&"dark", 0]}, {"z_top": true})
	b.stamp(&"skull_teeth", &"root", Vector2(-50, -1), ["C.c.C.c.C.c.C"], {"c": [&"bone", 3], "C": [&"bone", 5]}, {"z_top": true})
	b.stamp(&"last_coal", &"root", Vector2(14, -5), [".h.", "hFh", "HFH"], {"h": [&"hot", 2], "H": [&"hot", 3], "F": [&"hot", 5]}, {"z_top": true})
	# --- ceniza que cae
	var dust := {"a": [&"ash", 8], "A": [&"ash", 10], "d": [&"ash", 5]}
	b.stamp(&"spill", &"head", Vector2(-29, 17), ["."], dust, {"views": {
		&"none": ["."],
		&"s0": ["a.", "d.", "..", "..", ".."],
		&"s1": ["d.", "a.", ".d", "a.", ".."],
		&"s2": ["..", ".d", "..", "a.", "aA"],
	}})
	b.stamp(&"fall", &"dust", Vector2(-44, -40), ["."], dust, {"views": {
		&"none": ["."],
		&"f0": _pts(90, 52, [[10, 24, "a"], [24, 18, "d"], [38, 28, "A"], [52, 20, "a"], [66, 26, "d"], [17, 30, "d"], [46, 32, "a"], [60, 34, "A"]]),
		&"f1": _pts(90, 52, [[6, 34, "d"], [20, 30, "a"], [34, 40, "a"], [50, 36, "A"], [70, 40, "a"], [13, 44, "A"], [42, 46, "d"], [58, 44, "a"], [30, 28, "d"]]),
		&"f2": _pts(90, 52, [[4, 38, "a"], [18, 36, "d"], [28, 39, "A"], [48, 38, "a"], [72, 38, "d"], [60, 39, "d"], [84, 37, "a"]]),
	}})
	b.socket(&"hit", &"jaw", Vector2(-30, 4))
	b.socket(&"intent", &"head", Vector2(-6, -32))
	b.socket(&"maw", &"head", Vector2(-12, 5))
	_anims(b)
	return b.def


## Pata trasera corta y acodada, muslo en pera. `s`: f lejana, n cercana. La zarpa va en su hueso y queda plana (ver `_flat_paws`).
static func _leg_h(b: RigBuilder, s: String, z: float, ao: float) -> void:
	var t := StringName("hind_" + s)
	var c := StringName("shin_h" + s)
	var f := StringName("paw_h" + s)
	b.bone(f, c, Vector2(0, 14))
	b.poly(StringName("thigh_%s_p" % s), t, &"leg", PackedVector2Array([Vector2(-6, -9), Vector2(5, -10), Vector2(10, -3), Vector2(10, 6), Vector2(7, 15), Vector2(1, 17), Vector2(-4, 10), Vector2(-8, 1)]), z, 2.6, 3.5, {"ao": ao})
	b.poly(StringName("shin_%s_p" % s), c, &"leg", PackedVector2Array([Vector2(-4, -2), Vector2(4, -3), Vector2(3, 8), Vector2(4, 13), Vector2(-5, 13), Vector2(-4, 7)]), z, 1.6, 2.5, {"ao": ao})
	b.poly(StringName("paw_%s_h" % s), f, &"dark", PackedVector2Array([Vector2(4, -3), Vector2(6, 3), Vector2(-11, 3), Vector2(-10, -2), Vector2(-4, -4)]), z + 1.0, 1.0, 2.0)
	b.stamp(StringName("claws_%sh" % s), f, Vector2(-12, 1), ["C..C..C", "c..c..c"], {"c": [&"bone", 4], "C": [&"bone", 6]}, {})


## Pata delantera larga y ancha: es la que levanta la cruz. Hombro redondeado que entra en el cuerpo.
static func _leg_fr(b: RigBuilder, s: String, z: float, ao: float) -> void:
	var t := StringName("fore_" + s)
	var c := StringName("shin_f" + s)
	var f := StringName("paw_f" + s)
	b.bone(f, c, Vector2(0, 14))
	b.poly(StringName("arm_%s_p" % s), t, &"leg", PackedVector2Array([Vector2(-5, -12), Vector2(5, -12), Vector2(10, -5), Vector2(9, 5), Vector2(6, 17), Vector2(-4, 17), Vector2(-7, 7), Vector2(-9, -4)]), z, 2.6, 4.0, {"ao": ao})
	b.poly(StringName("fore_%s_p" % s), c, &"leg", PackedVector2Array([Vector2(-5, -1), Vector2(5, -1), Vector2(4, 8), Vector2(5, 13), Vector2(-6, 13), Vector2(-5, 7)]), z, 1.8, 3.0, {"ao": ao})
	b.poly(StringName("paw_%s_f" % s), f, &"dark", PackedVector2Array([Vector2(5, -3), Vector2(7, 3), Vector2(-13, 3), Vector2(-12, -2), Vector2(-5, -4)]), z + 1.0, 1.0, 2.0)
	b.stamp(StringName("claws_%sf" % s), f, Vector2(-14, 1), ["C..C..C.C", "c..c..c.c"], {"c": [&"bone", 4], "C": [&"bone", 6]}, {})


## Las zarpas no heredan el giro de la espinilla: se calcula el mismo ángulo que la IK y se resta.
## (El cuerpo no rota en ninguna pose de esta criatura, así que el cálculo es directo.)
static func _flat_paws(o: Dictionary) -> void:
	var r: Vector2 = Vector2(ORIGIN) + Vector2(o.get(&"@root", Vector2i.ZERO)) + Vector2(0, -10)
	for leg: Array in [[&"ik:fore_n", Vector2(-24, -6), Vector2(0, 16), 1, &"paw_fn"], [&"ik:fore_f", Vector2(-12, -6), Vector2(0, 16), 1, &"paw_ff"],
			[&"ik:hind_n", Vector2(17, -2), Vector2(4, 15), -1, &"paw_hn"], [&"ik:hind_f", Vector2(27, -2), Vector2(4, 15), -1, &"paw_hf"]]:
		var tgt: Vector2 = o[leg[0]]
		var p0: Vector2 = r + leg[1]
		var l1: float = (leg[2] as Vector2).length()
		var l2 := 14.0
		var d: Vector2 = tgt - p0
		var dl := clampf(d.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
		var c1 := clampf((l1 * l1 + dl * dl - l2 * l2) / (2.0 * l1 * dl), -1.0, 1.0)
		var up := d.angle() - float(leg[3]) * acos(c1)
		var p1 := p0 + Vector2.from_angle(up) * l1
		var th_l := (tgt - p1).angle() - PI / 2.0
		o[leg[4]] = -th_l


static func _pts(w: int, h: int, pts: Array) -> Array:
	var rows: Array = []
	for y in h:
		rows.append(".".repeat(w))
	for p: Array in pts:
		var r: String = rows[p[1]]
		rows[p[1]] = r.substr(0, p[0]) + String(p[2]) + r.substr(p[0] + 1)
	return rows


## Pose base: pies plantados y todo lo de la muerte oculto.
static func _p(k: Dictionary) -> Dictionary:
	var o := FEET.duplicate()
	for id: StringName in HIDE_DEAD:
		o[StringName("hide:%s" % id)] = true
	o[&"hide:skull_eye"] = true
	o[&"hide:skull_teeth"] = true
	o[&"hide:last_coal"] = true
	o[&"view:spill"] = &"none"
	o[&"view:fall"] = &"none"
	for e in k.keys():
		o[e] = k[e]
	_flat_paws(o)
	return o


static func _anims(b: RigBuilder) -> void:
	# Reposo: un ciclo de masticar y tragar. Sólo se mueven mandíbula, garganta y ceniza; el cuerpo, 1 px.
	var jaw := [-0.05, -0.22, -0.34, -0.2, 0.0, 0.0]
	var maw := [-1, 0, 1, 1, 2, 0]
	var seam := [-1, -1, 0, 0, 1, 2]
	var spill := [&"none", &"none", &"s0", &"s1", &"s2", &"none"]
	var idle := {}
	for f in 6:
		idle[f] = _p({&"jaw": jaw[f], &"emit:throat": maw[f], &"emit:seams": seam[f], &"view:spill": spill[f],
			&"@root": Vector2i(0, 1 if f in [4, 5] else 0), &"head": 0.05 if f in [2, 3] else 0.0, &"view:eye": &"shut" if f == 4 else &""})
	b.anim(&"idle", 6, [160, 140, 160, 140, 200, 160], idle, {"interp": &"hold"})
	# Telegrafía: alza la cabeza, boca abierta al máximo, la garganta al blanco.
	var c0 := _p({&"neck": 0.42, &"head": 0.1, &"jaw": -0.62, &"@root": Vector2i(2, 1), &"emit:throat": 1, &"emit:seams": 1})
	var c1 := c0.duplicate()
	c1[&"@root"] = Vector2i(2, 2)
	c1[&"emit:throat"] = 2
	c1[&"emit:seams"] = 2
	_flat_paws(c1)
	b.anim(&"cast", 2, [120, 400], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: se recoge → estela → mordisco → recuperación.
	var a0 := _p({&"neck": 0.5, &"jaw": -0.7, &"@root": Vector2i(6, 2), &"emit:throat": 2, &"emit:seams": 1})
	var a1 := _p({&"neck": -0.12, &"head": -0.1, &"jaw": -0.8, &"@root": Vector2i(-12, -1), &"emit:throat": 2, &"ik:fore_n": Vector2(62, G - 3), &"ik:fore_f": Vector2(78, G - 4)})
	var a2 := _p({&"neck": -0.3, &"head": -0.08, &"jaw": 0.0, &"@root": Vector2i(-20, 1), &"emit:throat": 2, &"emit:seams": 2, &"view:spill": &"s1", &"ik:fore_n": Vector2(56, G - 3), &"ik:fore_f": Vector2(70, G - 4), &"ik:hind_n": Vector2(112, G - 3)})
	var a3 := _p({&"neck": -0.1, &"jaw": -0.15, &"@root": Vector2i(-9, 0), &"view:spill": &"s2", &"ik:fore_n": Vector2(68, G - 3), &"ik:fore_f": Vector2(82, G - 4)})
	b.anim(&"attack", 4, [90, 40, 90, 150], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"jaw", Vector2(-34, 8), &"fire", 8.0, false).samples = 32
	# Golpe: se le va la cabeza atrás y escupe ceniza.
	var h0 := _p({&"neck": 0.26, &"head": 0.12, &"jaw": -0.3, &"@root": Vector2i(4, 0), &"emit:throat": -1, &"view:eye": &"shut", &"view:spill": &"s1", &"view:fall": &"none"})
	var h1 := _p({&"neck": 0.1, &"jaw": -0.12, &"@root": Vector2i(2, 0), &"view:spill": &"s2"})
	b.anim(&"hurt", 2, [90, 140], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte por material: las costuras revientan → la piel se deshace → costillas y brasas → montón de ceniza.
	var d := {}
	d[0] = _p({&"neck": 0.26, &"jaw": -0.4, &"@root": Vector2i(3, 0), &"view:eye": &"shut", &"emit:seams": 2, &"emit:throat": 2})
	d[1] = _p({&"neck": 0.18, &"jaw": -0.5, &"@root": Vector2i(2, 2), &"view:eye": &"shut", &"emit:seams": 3, &"emit:throat": 2,
		&"pl1": 0.25, &"pl3": -0.3, &"view:spill": &"s0", &"view:fall": &"f0"})
	d[2] = _p({&"neck": 0.05, &"jaw": -0.55, &"@root": Vector2i(1, 5), &"view:eye": &"dead", &"hide:belly": true, &"hide:seams": true,
		&"hide:cavity": false, &"hide:ribs": false, &"hide:coals": false, &"pl0": -0.4, &"pl1": 0.5, &"pl2": 0.35, &"pl3": -0.55, &"pl4": 0.5, &"view:fall": &"f1"})
	var d3 := _p({&"neck": 0.2, &"jaw": -0.08, &"@root": Vector2i(1, 11), &"view:eye": &"dead", &"hide:belly": true, &"hide:seams": true,
		&"hide:cavity": false, &"hide:ribs": false, &"hide:coals": false, &"emit:coals": -1, &"pl0": -0.8, &"pl2": 0.75, &"pl4": 0.9,
		&"hide:plate1": true, &"hide:plate3": true, &"hide:tail_p": true, &"hide:arm_f_p": true, &"hide:fore_f_p": true, &"hide:paw_f_f": true, &"hide:claws_ff": true,
		&"hide:thigh_f_p": true, &"hide:shin_f_p": true, &"hide:paw_f_h": true, &"hide:claws_fh": true, &"view:fall": &"f1"})
	d[3] = d3
	var d4 := d3.duplicate()
	d4[&"@root"] = Vector2i(1, 15)
	d4[&"hide:torso"] = true
	d4[&"hide:crumble"] = false
	d4[&"hide:bubbles"] = true
	d4[&"hide:plate0"] = true
	d4[&"hide:plate2"] = true
	d4[&"hide:plate4"] = true
	d4[&"hide:scrap_a"] = false
	d4[&"hide:scrap_b"] = false
	d4[&"neck"] = 0.42
	d4[&"jaw"] = 0.0
	_flat_paws(d4)
	d4[&"emit:coals"] = -1
	d4[&"view:fall"] = &"f2"
	d[4] = d4
	var last := _p({&"@root": Vector2i(1, 18), &"hide:heap": false, &"hide:tusk_down": false, &"hide:ribs_down": false, &"hide:heap_top": false, &"hide:skull_down": false, &"hide:skull_eye": false, &"hide:skull_teeth": false,
		&"hide:scrap_a": false, &"hide:scrap_b": false, &"hide:scrap_c": false, &"hide:last_coal": false, &"view:fall": &"f2"})
	for id: StringName in ALL_BODY:
		last[StringName("hide:%s" % id)] = true
	for id: StringName in STAMPS_BODY:
		last[StringName("hide:%s" % id)] = true
	for i in 5:
		last[StringName("hide:plate%d" % i)] = true
	d[5] = last
	d[6] = last.duplicate()
	d[6][&"view:fall"] = &"none"
	d[6][&"emit:last_coal"] = -2
	d[7] = d[6].duplicate()
	d[7][&"emit:last_coal"] = -4
	b.anim(&"death", 8, [70, 80, 90, 90, 100, 130, 200, 400], d, {"loop": false, "interp": &"hold"})
