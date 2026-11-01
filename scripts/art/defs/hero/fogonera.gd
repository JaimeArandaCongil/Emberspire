extends RefCounted
## LA FOGONERA — definición de rig (PER · v0.4) sobre el motor v1 de TEC.
## 66 px de alto (+ moño) en un lienzo de 96×96, pies en y = 89, mira a la DERECHA (facing = +1).
## Diseño y enmiendas de DA: docs/reviews/v04/personajes/fogonera_final.md.
##
## Las poses se escriben como ARTICULACIONES en el lienzo (hombro, codo, muñeca, cadera, tobillo, cabeza, martillo…)
## y `_keys()` las convierte en ángulos de hueso + objetivos de IK. Así una pose se lee y se corrige como un dibujo.
##
## Animaciones: idle (8) · idle_shoulder (6) · windup (1) · smear (2, estela en el 1) · strike (1) · recover (2) ·
## attack (5: carga, estela, impacto, recuperación ×2) · cast (2) · toss (2: toss_back, toss) · hurt (2) · death (8).

const StampLib = preload("res://scripts/art/defs/stamps/stamp_lib.gd")

const ORIGIN := Vector2i(45, 59)
const WAIST0 := Vector2(45, 55)
const HEAD_REST := 0.1107  # ángulo de (cabeza - pecho) en reposo

# ------------------------------------------------------------------------------------------------- poses
## Articulaciones de cada pose clave (lienzo 96×96). `hf` = el martillo va en la mano LEJANA.
const J := {
	"idle": {
		"head": Vector2(47, 27), "chest": Vector2(45, 45), "waist": Vector2(45, 55),
		"sh_n": Vector2(51.5, 40), "el_n": Vector2(55, 50), "wr_n": Vector2(56.5, 58.5),
		"sh_f": Vector2(38, 40), "el_f": Vector2(35.5, 50), "wr_f": Vector2(38, 57),
		"kn_b": Vector2(38.5, 72), "an_b": Vector2(37, 83), "kn_f": Vector2(52, 72), "an_f": Vector2(54, 83),
		"hammer": Vector2(61, 78),
	},
	"shoulder": {
		"head": Vector2(47, 27), "chest": Vector2(45, 45), "waist": Vector2(45, 55),
		"sh_n": Vector2(51.5, 40), "el_n": Vector2(57, 49), "wr_n": Vector2(53, 44),
		"sh_f": Vector2(38, 40), "el_f": Vector2(36, 50), "wr_f": Vector2(40, 55),
		"kn_b": Vector2(39, 72), "an_b": Vector2(38, 83), "kn_f": Vector2(51, 72), "an_f": Vector2(52, 83),
		"hammer": Vector2(31, 37),
	},
	"windup": {
		"head": Vector2(45, 29), "chest": Vector2(43, 47), "waist": Vector2(43, 57),
		"sh_n": Vector2(47, 41), "el_n": Vector2(42, 32), "wr_n": Vector2(37, 24),
		"sh_f": Vector2(38, 42), "el_f": Vector2(47, 49), "wr_f": Vector2(55, 51),
		"kn_b": Vector2(34, 72), "an_b": Vector2(31, 83), "kn_f": Vector2(56, 71), "an_f": Vector2(59, 83),
		"hammer": Vector2(24, 12),
	},
	"smear": {
		"head": Vector2(51, 30), "chest": Vector2(48, 47), "waist": Vector2(46, 57),
		"sh_n": Vector2(53, 41), "el_n": Vector2(61, 35), "wr_n": Vector2(68, 31),
		"sh_f": Vector2(41, 42), "el_f": Vector2(40, 50), "wr_f": Vector2(37, 55),
		"kn_b": Vector2(35, 72), "an_b": Vector2(30, 83), "kn_f": Vector2(58, 71), "an_f": Vector2(61, 83),
		"hammer": Vector2(85, 26),
	},
	"strike": {
		"head": Vector2(55, 31), "chest": Vector2(51, 48), "waist": Vector2(48, 57),
		"sh_n": Vector2(57, 42), "el_n": Vector2(65, 49), "wr_n": Vector2(71, 55),
		"sh_f": Vector2(44, 42), "el_f": Vector2(38, 49), "wr_f": Vector2(33, 52),
		"kn_b": Vector2(36, 72), "an_b": Vector2(29, 83), "kn_f": Vector2(59, 71), "an_f": Vector2(62, 83),
		"hammer": Vector2(82, 74),
	},
	"recover": {
		"head": Vector2(52, 29), "chest": Vector2(49, 46), "waist": Vector2(47, 56),
		"sh_n": Vector2(55, 41), "el_n": Vector2(61, 49), "wr_n": Vector2(65, 57),
		"sh_f": Vector2(42, 41), "el_f": Vector2(38, 50), "wr_f": Vector2(37, 56),
		"kn_b": Vector2(37, 72), "an_b": Vector2(32, 83), "kn_f": Vector2(56, 71), "an_f": Vector2(59, 83),
		"hammer": Vector2(75, 79),
	},
	"cast": {
		"head": Vector2(48, 27), "chest": Vector2(46, 45), "waist": Vector2(45, 55),
		"sh_n": Vector2(52, 40), "el_n": Vector2(60, 44), "wr_n": Vector2(66, 39),
		"sh_f": Vector2(38, 40), "el_f": Vector2(37, 50), "wr_f": Vector2(41, 57),
		"kn_b": Vector2(38, 72), "an_b": Vector2(36, 83), "kn_f": Vector2(53, 72), "an_f": Vector2(56, 83),
		"hammer": Vector2(31, 79), "hf": true,
	},
	"toss_back": {
		"head": Vector2(46, 27), "chest": Vector2(45, 45), "waist": Vector2(45, 55),
		"sh_n": Vector2(51.5, 40), "el_n": Vector2(58, 46), "wr_n": Vector2(60, 37),
		"sh_f": Vector2(38, 40), "el_f": Vector2(37, 50), "wr_f": Vector2(41, 57),
		"kn_b": Vector2(38.5, 72), "an_b": Vector2(37, 83), "kn_f": Vector2(52, 72), "an_f": Vector2(54, 83),
		"hammer": Vector2(31, 79), "hf": true,
	},
	"toss": {
		"head": Vector2(48, 28), "chest": Vector2(46, 46), "waist": Vector2(45, 56),
		"sh_n": Vector2(52, 41), "el_n": Vector2(58, 49), "wr_n": Vector2(57, 57),
		"sh_f": Vector2(38, 41), "el_f": Vector2(37, 51), "wr_f": Vector2(41, 58),
		"kn_b": Vector2(38.5, 72), "an_b": Vector2(37, 83), "kn_f": Vector2(52, 72), "an_f": Vector2(54, 83),
		"hammer": Vector2(31, 80), "hf": true,
	},
	"hurt": {
		"head": Vector2(43, 29), "chest": Vector2(42, 46), "waist": Vector2(43, 56),
		"sh_n": Vector2(48, 41), "el_n": Vector2(52, 51), "wr_n": Vector2(53, 60),
		"sh_f": Vector2(35, 41), "el_f": Vector2(31, 49), "wr_f": Vector2(29, 55),
		"kn_b": Vector2(36, 72), "an_b": Vector2(34, 83), "kn_f": Vector2(50, 72), "an_f": Vector2(51, 83),
		"hammer": Vector2(59, 79),
	},
	"hurt2": {
		"head": Vector2(41, 30), "chest": Vector2(41, 47), "waist": Vector2(42, 57),
		"sh_n": Vector2(47, 42), "el_n": Vector2(51, 52), "wr_n": Vector2(52, 61),
		"sh_f": Vector2(34, 42), "el_f": Vector2(29, 49), "wr_f": Vector2(27, 54),
		"kn_b": Vector2(35, 72), "an_b": Vector2(33, 83), "kn_f": Vector2(49, 72), "an_f": Vector2(50, 83),
		"hammer": Vector2(58, 80),
	},
	"die1": {
		"head": Vector2(49, 33), "chest": Vector2(46, 50), "waist": Vector2(45, 60),
		"sh_n": Vector2(52, 45), "el_n": Vector2(55, 55), "wr_n": Vector2(57, 64),
		"sh_f": Vector2(39, 45), "el_f": Vector2(37, 55), "wr_f": Vector2(39, 63),
		"kn_b": Vector2(40, 75), "an_b": Vector2(36, 83), "kn_f": Vector2(55, 74), "an_f": Vector2(55, 83),
		"hammer": Vector2(62, 82),
	},
	"die2": {
		"head": Vector2(51, 41), "chest": Vector2(47, 57), "waist": Vector2(44, 67),
		"sh_n": Vector2(53, 52), "el_n": Vector2(57, 62), "wr_n": Vector2(60, 70),
		"sh_f": Vector2(40, 52), "el_f": Vector2(39, 62), "wr_f": Vector2(42, 70),
		"kn_b": Vector2(36, 80), "an_b": Vector2(30, 84), "kn_f": Vector2(57, 77), "an_f": Vector2(56, 84),
		"hammer": Vector2(68, 83),
	},
	"die3": {
		"head": Vector2(53, 47), "chest": Vector2(48, 61), "waist": Vector2(44, 70),
		"sh_n": Vector2(54, 56), "el_n": Vector2(58, 66), "wr_n": Vector2(61, 73),
		"sh_f": Vector2(41, 56), "el_f": Vector2(41, 66), "wr_f": Vector2(44, 73),
		"kn_b": Vector2(35, 82), "an_b": Vector2(27, 84), "kn_f": Vector2(57, 78), "an_f": Vector2(56, 84),
		"hammer": Vector2(70, 83),
	},
	"die4": {
		"head": Vector2(54, 50), "chest": Vector2(48, 63), "waist": Vector2(44, 71),
		"sh_n": Vector2(54, 58), "el_n": Vector2(58, 68), "wr_n": Vector2(61, 75),
		"sh_f": Vector2(41, 58), "el_f": Vector2(42, 68), "wr_f": Vector2(45, 75),
		"kn_b": Vector2(35, 82), "an_b": Vector2(27, 84), "kn_f": Vector2(57, 78), "an_f": Vector2(56, 84),
		"hammer": Vector2(70, 83),
	},
}

## Sellos de cara y mano por pose (vistas).
const VIEWS := {
	"idle": ["n", "grip", "fist"], "shoulder": ["n", "knuckles", "fist"], "windup": ["e", "grip", "open"],
	"smear": ["e", "grip", "fist"], "strike": ["e", "knuckles", "fist"], "recover": ["n", "grip", "fist"],
	"cast": ["n", "open", "grip"], "toss_back": ["n", "open", "grip"], "toss": ["e", "open", "grip"],
	"hurt": ["h", "grip", "open"], "hurt2": ["h", "grip", "open"], "die1": ["h", "grip", "open"],
	"die2": ["h", "grip", "open"], "die3": ["h", "open", "open"], "die4": ["h", "open", "open"],
}


static func _abs_down(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return atan2(-d.x, d.y)


static func _abs_up(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return atan2(d.x, -d.y)


## Articulaciones → claves de pose del motor.
static func _keys(name: String, extra := {}) -> Dictionary:
	var P: Dictionary = J[name]
	var k := {}
	var waist: Vector2 = P["waist"]
	var chest: Vector2 = P["chest"]
	var sp := _abs_up(waist, chest)
	k[&"@root"] = Vector2i(roundi(waist.x - WAIST0.x), roundi(waist.y - WAIST0.y))
	k[&"spine"] = sp
	k[&"head"] = _abs_up(chest, P["head"]) - HEAD_REST - sp
	var hf: bool = P.get("hf", false)
	for side: String in ["n", "f"]:
		var sh: Vector2 = P["sh_" + side]
		var el: Vector2 = P["el_" + side]
		var wr: Vector2 = P["wr_" + side]
		var ua := _abs_down(sh, el)
		var fa := _abs_down(el, wr)
		k[StringName("arm_" + side)] = ua - sp
		k[StringName("fore_" + side)] = fa - ua
		var holds := (side == "n" and not hf) or (side == "f" and hf)
		if holds:
			k[StringName("hammer_" + side)] = _abs_down(wr, P["hammer"]) - fa
	k[&"ik:leg_b"] = P["an_b"]
	k[&"ik:leg_f"] = P["an_f"]
	k[&"foot_b"] = -_abs_down(P["kn_b"], P["an_b"])
	k[&"foot_f"] = -_abs_down(P["kn_f"], P["an_f"])
	# martillo en una sola mano
	for id: String in HAMMER_PIECES:
		k[StringName("hide:%s_%s" % [id, "n" if hf else "f"])] = true
	k[&"hide:hotface_f"] = true   # en la mano lejana el martillo va frío (y la franja no asoma entre las piernas)
	# vistas de cara y manos
	var v: Array = VIEWS[name]
	k[&"view:head"] = StringName(v[0])
	k[&"view:fore_n"] = StringName(v[1])
	k[&"view:fore_f"] = StringName(v[2])
	for e in extra.keys():
		k[e] = extra[e]
	return k


const HAMMER_PIECES := ["handle", "hhead", "groove", "collar", "hotface"]


# ------------------------------------------------------------------------------------------------- definición
static func build() -> RigDef:
	var b := RigBuilder.new(&"fogonera", Vector2i(96, 96), ORIGIN, 1, &"hero")
	# --- materiales (todos de Palette)
	b.material(&"skin", &"skin")
	b.material(&"hair", &"hair", {"texture": &"strands"})
	b.material(&"linen", &"linen", {"texture": &"folds"})
	b.material(&"leather", &"leather", {"texture": &"scratches"})
	b.material(&"canvas", &"canvas", {"texture": &"folds", "rim": false})
	b.material(&"boot", &"boot")
	b.material(&"soot", &"soot")
	b.material(&"iron", &"iron", {"spec": true, "tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return mini(st, 6)})
	b.material(&"steel", &"steel", {"spec": true})
	b.material(&"wood", &"wood")
	b.material(&"wool", &"wool_blue")
	b.material(&"brass", &"brass", {"spec": true})
	b.material(&"hot", &"hot")
	b.material(&"trail", &"fire")

	# --- esqueleto (reposo = pose "idle"; ejes de los miembros hacia +y)
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"thigh_b", &"root", Vector2(-4, 1), {"z": -3.0})
	b.bone(&"shin_b", &"thigh_b", Vector2(0, 12))
	b.bone(&"foot_b", &"shin_b", Vector2(0, 11))
	b.bone(&"thigh_f", &"root", Vector2(4, 1), {"z": 2.0})
	b.bone(&"shin_f", &"thigh_f", Vector2(0, 12))
	b.bone(&"foot_f", &"shin_f", Vector2(0, 11))
	b.bone(&"spine", &"root", Vector2(0, -2))
	b.bone(&"head", &"spine", Vector2(1, -22), {"z": 3.0})
	b.bone(&"bun", &"head", Vector2(-6, -16))
	b.bone(&"scarf", &"head", Vector2(-6, 5), {"z": -6.0})
	b.bone(&"arm_f", &"spine", Vector2(-7, -17), {"z": -8.0})
	b.bone(&"fore_f", &"arm_f", Vector2(0, 10.5))
	b.bone(&"hammer_f", &"fore_f", Vector2(0, 8.5), {"z": -1.0})
	b.bone(&"arm_n", &"spine", Vector2(6.5, -17), {"z": 9.0})
	b.bone(&"fore_n", &"arm_n", Vector2(0, 10.5))
	b.bone(&"hammer_n", &"fore_n", Vector2(0, 8.5), {"z": -1.0})
	b.ik(&"leg_b", &"thigh_b", &"shin_b", Vector2(0, 11), 1)
	b.ik(&"leg_f", &"thigh_f", &"shin_f", Vector2(0, 11), 1)

	# --- piernas
	for s: String in ["b", "f"]:
		var ao := 1.3 if s == "b" else 1.0
		b.cap(StringName("thigh_" + s), StringName("thigh_" + s), &"canvas", Vector3(0, 0, 0), Vector3(0, 12, 0), 4.5, 3.8, {"ao": ao})
		b.cap(StringName("calf_" + s), StringName("shin_" + s), &"canvas", Vector3(0, 0, 0), Vector3(0, 10, 0), 3.7, 3.1, {"ao": ao})
		b.poly(StringName("boot_" + s), StringName("foot_" + s), &"boot", PackedVector2Array([
			Vector2(-3.5, -3.0), Vector2(3.0, -3.0), Vector2(7.5, 2.5), Vector2(8.0, 6.0), Vector2(-4.0, 6.0), Vector2(-4.0, 0.5)]),
			3.0, 1.6, 2.0, {"ao": ao})
		b.stamp(StringName("toecap_" + s), StringName("foot_" + s), Vector2(6, 3), ["5", "3", "k"],
			{"5": [&"steel", 5], "3": [&"steel", 3], "k": [&"boot", 1]}, {"z_top": false})

	# --- torso: lino, delantal, cinturón, correa del fuelle, tenazas
	b.ell(&"chest", &"spine", &"linen", Vector3(0, -14, 0), Vector3(9.5, 8.5, 7), {"flat": 0.3})
	b.ell(&"belly", &"spine", &"linen", Vector3(0, -3, 0), Vector3(7.5, 6.0, 6), {"flat": 0.3})
	b.cap(&"shoulders", &"spine", &"linen", Vector3(-7, -17, 0), Vector3(6.5, -17, 0), 3.4, 3.8)
	b.cap(&"strap", &"spine", &"leather", Vector3(-6, -19, 6.5), Vector3(7, -4, 6.5), 0.8, 0.8)
	b.poly(&"apron", &"spine", &"leather", PackedVector2Array([
		Vector2(-3, -15), Vector2(7, -15), Vector2(9, -2), Vector2(12, 16), Vector2(-7, 16), Vector2(-5, -2)]), 7.0, 2.2, 2.0)
	b.cap(&"belt", &"spine", &"leather", Vector3(-9, -1, 7), Vector3(10, -1, 9.5), 1.4, 1.4)
	b.cap(&"tong_a", &"spine", &"steel", Vector3(-6, 1, 2), Vector3(-9, 14, 2), 0.7, 0.6, {"line": false})
	b.cap(&"tong_b", &"spine", &"steel", Vector3(-5, 1, 2.5), Vector3(-7, 14, 2.5), 0.7, 0.6, {"line": false})
	_lib(b, &"buckle", &"spine", Vector2(2, -1), "buckle", {}, {"z_top": false})
	_lib(b, &"rivet_l", &"spine", Vector2(-2, -13), "rivet", {"@metal": "@brass"}, {"z_top": false})
	_lib(b, &"rivet_r", &"spine", Vector2(6, -13), "rivet", {"@metal": "@brass"}, {"z_top": false})
	_lib(b, &"lantern", &"spine", Vector2(9, 0), "belt_lantern", {}, {"z_top": false})
	_lib(b, &"bellows", &"spine", Vector2(-10, -20), "bellows_handles", {}, {"z_top": false})

	# --- cabeza: cuello, bufanda, pelo, cráneo, cara sellada, oreja, mechones, gafas
	b.cap(&"neck", &"head", &"skin", Vector3(0, -2, 0), Vector3(-0.5, 3, 0), 3.0, 3.2, {"ao": 1.4})
	b.ell(&"scarf_ring", &"head", &"wool", Vector3(-0.5, 3.5, 2), Vector3(6.5, 2.6, 5))
	b.cap(&"scarf_tail", &"scarf", &"wool", Vector3(0, 0, 0), Vector3(-4, 5, 0), 2.0, 1.2)
	b.cap(&"scarf_end", &"scarf", &"wool", Vector3(-4, 5, 0), Vector3(-7, 4, 0), 1.2, 0.9)
	b.ell(&"hair_back", &"head", &"hair", Vector3(-4.5, -8, -2), Vector3(5.5, 7, 5))
	b.ell(&"hair_cap", &"head", &"hair", Vector3(-1, -11, 0), Vector3(8, 7, 6.5), {"flat": 0.3})
	b.ell(&"skull", &"head", &"skin", Vector3(1.5, -7.5, 1), Vector3(6, 6.5, 6), {"flat": 0.95, "tags": [&"face"]})
	b.ell(&"bun", &"bun", &"hair", Vector3(0, -2.5, -1), Vector3(4.4, 3.9, 4))
	b.cap(&"bun_tie", &"head", &"wool", Vector3(-7, -15, 2), Vector3(-3, -15, 2), 1.2, 1.2)
	b.ell(&"ear", &"head", &"skin", Vector3(-2.5, -6.5, 7), Vector3(1.5, 2.2, 1.5), {"line": false})
	b.cap(&"goggle_strap", &"head", &"leather", Vector3(-7, -15.5, 7), Vector3(2, -17.5, 7), 0.9, 0.9, {"line": false})
	# Cara: vistas n(eutra) · e(sfuerzo) · h(erida). Oculta por la mano/brazo cuando van delante (z_top = false).
	var face := StampLib.get_stamp("face_34")
	b.stamp(&"face", &"head", Vector2(0, -9), face["rows"], _legend(face["legend"], {}), {
		"anchor": face["anchor"], "z_top": false, "views": {
			&"n": face["rows"], &"e": StampLib.get_stamp("face_34_effort")["rows"], &"h": StampLib.get_stamp("face_34_hurt")["rows"]}})
	_lib(b, &"goggles", &"head", Vector2(4, -17), "goggles", {}, {"z_top": false})
	_lib(b, &"lock_fringe", &"head", Vector2(2, -14), "lock_fringe", {}, {"z_top": false})
	_lib(b, &"lock_nape", &"head", Vector2(-7, -6), "lock_nape", {}, {"z_top": false})
	_lib(b, &"lock_bun", &"bun", Vector2(-5, -4), "lock_bun_tail", {}, {"z_top": false})
	b.stamp(&"ear_in", &"head", Vector2(-2.5, -6.5), ["k"], {"k": [&"skin", 2]}, {"z_top": false})

	# --- brazos (lino remangado + antebrazo tiznado con cicatrices de chispa) + martillo en cada mano
	for s: String in ["f", "n"]:
		var ao := 1.4 if s == "f" else 1.0
		var arm := StringName("arm_" + s)
		var fore := StringName("fore_" + s)
		b.cap(StringName("upper_" + s), arm, &"linen", Vector3(0, 0, 0), Vector3(0, 10.5, 0), 3.9, 3.3, {"ao": ao})
		b.cap(StringName("cuff_" + s), arm, &"linen", Vector3(0, 7.5, 0.5), Vector3(0, 10.5, 0.5), 3.7, 3.5, {"ao": ao})
		b.cap(StringName("forearm_" + s), fore, &"soot", Vector3(0, 0, 0), Vector3(0, 8.5, 0), 3.1, 2.6, {"ao": ao})
		b.stamp(StringName("scars_" + s), fore, Vector2(0, 4), ["F", ".", ".f"], {"F": [&"hot", 3], "f": [&"hot", 2]}, {"z_top": false})
		var hm := StringName("hammer_" + s)
		b.cap(StringName("handle_" + s), hm, &"wood", Vector3(0, -3, 0), Vector3(0, 16, 0), 1.5, 1.6)
		b.poly(StringName("hhead_" + s), hm, &"iron", PackedVector2Array([
			Vector2(-8.5, 16), Vector2(8.5, 16), Vector2(8.5, 26), Vector2(-8.5, 26)]), 0.0, 1.8, 3.0)
		b.cap(StringName("groove_" + s), hm, &"iron", Vector3(-6, 21, 3.2), Vector3(5, 21, 3.2), 0.5, 0.5, {"line": false, "ao": 2.0})
		b.cap(StringName("collar_" + s), hm, &"steel", Vector3(-1.8, 15.6, 3.5), Vector3(1.8, 15.6, 3.5), 1.1, 1.1)
		b.poly(StringName("hotface_" + s), hm, &"hot", PackedVector2Array([
			Vector2(6.2, 16), Vector2(8.6, 16), Vector2(8.6, 26), Vector2(6.2, 26)]), 0.2, 0.8, 3.0, {"line": false})
		# Mano: agarre / nudillos / puño / abierta (sello con vistas; la ranura @hand = tizne).
		_hand(b, StringName("hand_" + s), fore, Vector2(0, 8.5), s == "f")

	# --- sockets
	b.socket(&"hit", &"hammer_n", Vector2(8.5, 21))
	b.socket(&"lantern", &"spine", Vector2(9, 2))
	b.socket(&"head", &"head", Vector2(0, -20))
	b.socket(&"chest", &"spine", Vector2(0, -12))

	_anims(b)
	return b.def


## Sello de la biblioteca con los alias de material de `StampLib.MAT` resueltos a materiales de paleta.
static func _legend(src: Dictionary, remap: Dictionary) -> Dictionary:
	var out := {}
	for ch: String in src.keys():
		var e: Array = src[ch]
		var m: String = String(e[0])
		if remap.has(m):
			m = String(remap[m])
		elif StampLib.MAT.has(m):
			m = String(StampLib.MAT[m])
		out[ch] = [m, e[1]]
	return out


static func _lib(b: RigBuilder, id: StringName, bone: StringName, at: Vector2, lib_id: String, remap: Dictionary, opts: Dictionary) -> void:
	var s := StampLib.get_stamp(lib_id)
	var o := opts.duplicate()
	o["anchor"] = s["anchor"]
	b.stamp(id, bone, at, s["rows"], _legend(s["legend"], remap), o)


## Mano con vistas. Las filas se rellenan para que todas compartan el ancla (2, 3).
static func _hand(b: RigBuilder, id: StringName, bone: StringName, at: Vector2, far: bool) -> void:
	var views := {}
	var legend := {}
	for pair: Array in [[&"grip", "hand_grip"], [&"knuckles", "hand_grip_knuckles"], [&"fist", "hand_fist"], [&"open", "hand_open"]]:
		var s := StampLib.get_stamp(pair[1])
		var rows: Array = s["rows"]
		var a: Vector2i = s["anchor"]
		var padded: Array = []
		for i in 3 - a.y:
			padded.append("")
		for r: String in rows:
			padded.append(".".repeat(2 - a.x) + r)
		views[pair[0]] = padded
		for ch: String in s["legend"].keys():
			legend[ch] = s["legend"][ch]
	var lg := _legend(legend, {"@hand": "@soot"})
	b.stamp(id, bone, at, views[&"grip"], lg, {"anchor": Vector2i(2, 3), "views": views, "z_top": not far})


# ------------------------------------------------------------------------------------------------- animaciones
## Desenrolla los ángulos de `k` para que cada hueso gire por el camino corto desde `prev` (el martillazo da la vuelta por arriba).
static func _unwrap(k: Dictionary, prev: Dictionary) -> void:
	for key in k.keys():
		if String(key).contains(":") or String(key).begins_with("@") or not prev.has(key):
			continue
		if typeof(k[key]) != TYPE_FLOAT or typeof(prev[key]) != TYPE_FLOAT:
			continue
		var v: float = k[key]
		var p: float = prev[key]
		while v - p > PI:
			v -= TAU
		while v - p < -PI:
			v += TAU
		k[key] = v


static func _anims(b: RigBuilder) -> void:
	# Reposo: respiración de 1 px, cabeza/brazos con retraso, moño y bufanda siguen, el fogón de cinto parpadea.
	var base := _keys("idle")
	var idle := {}
	for f in 8:
		var t := TAU * f / 8.0
		var k := base.duplicate()
		k[&"@root"] = Vector2i(0, 1 if (f >= 3 and f <= 6) else 0)
		k[&"ik:leg_b"] = J["idle"]["an_b"]
		k[&"ik:leg_f"] = J["idle"]["an_f"]
		k[&"spine"] = float(base[&"spine"]) + 0.03 * sin(t)
		k[&"head"] = float(base[&"head"]) + 0.04 * sin(t)
		k[&"arm_n"] = float(base[&"arm_n"]) + 0.04 * sin(t)
		k[&"arm_f"] = float(base[&"arm_f"]) + 0.04 * sin(t)
		k[&"bun"] = 0.10 * sin(t)
		k[&"scarf"] = 0.14 * sin(t)
		k[&"emit:lantern"] = [0, 0, 1, 1, 0, -1, 0, 1][f]
		idle[f] = k
	b.anim(&"idle", 8, 150, idle, {"interp": &"linear", "overlap": {&"head": 1.0, &"arm_n": 1.5, &"arm_f": 1.5, &"bun": 2.0, &"scarf": 2.5}})
	var sb := _keys("shoulder", {&"z:hammer_n": -16.0})
	var sh := {}
	for f in 6:
		var t := TAU * f / 6.0
		var k := sb.duplicate()
		k[&"@root"] = Vector2i(0, 1 if (f >= 2 and f <= 4) else 0)
		k[&"ik:leg_b"] = J["shoulder"]["an_b"]
		k[&"ik:leg_f"] = J["shoulder"]["an_f"]
		k[&"spine"] = float(sb[&"spine"]) + 0.025 * sin(t)
		k[&"bun"] = 0.1 * sin(t)
		k[&"scarf"] = 0.12 * sin(t)
		k[&"emit:lantern"] = [0, 1, 1, 0, -1, 0][f]
		sh[f] = k
	b.anim(&"idle_shoulder", 6, 160, sh, {"interp": &"linear", "overlap": {&"bun": 2.0, &"scarf": 2.0}})
	# Parche (PER-6): la mano tiznada sobre el pecho de lino se separa con dos brillos de nudillo y un canto.
	for f in 6:
		b.patch(&"idle_shoulder", f, &"fore_n", Vector2(-2, 6), ["5.5.5", ".....", "4...."], {"5": [&"soot", 5], "4": [&"soot", 4]})
	# Ataque completo y sus piezas sueltas (el juego encadena windup → smear → strike → recover).
	var wk := _keys("windup", {&"z:arm_n": -2.0, &"hide:hand_n": true, &"bun": -0.3, &"scarf": -0.3, &"emit:lantern": 1})
	var mk := _keys("smear", {&"bun": 0.2, &"scarf": 0.3, &"emit:lantern": 1})
	var tk := _keys("strike", {&"bun": 0.4, &"scarf": 0.5, &"emit:lantern": 2, &"emit:hotface_n": 1})
	var rk := _keys("recover", {&"bun": 0.1, &"scarf": 0.2})
	var rk2 := _keys("recover", {&"bun": -0.1, &"scarf": 0.0, &"@root": Vector2i(1, 0)})
	_unwrap(mk, wk)
	_unwrap(tk, mk)
	_unwrap(rk, tk)
	_unwrap(rk2, rk)
	b.anim(&"windup", 1, 140, {0: wk}, {"loop": false})
	b.anim(&"smear", 2, [40, 33], {0: wk, 1: mk}, {"loop": false, "interp": &"hold"})
	b.smear(&"smear", 1, &"hammer_n", Vector2(8.5, 21), &"trail", 9.0, false).samples = 64
	b.anim(&"strike", 2, [33, 90], {0: mk, 1: tk}, {"loop": false, "interp": &"hold"})
	b.smear(&"strike", 1, &"hammer_n", Vector2(8.5, 21), &"trail", 9.0, false).samples = 64
	b.anim(&"recover", 2, [90, 120], {0: rk, 1: rk2}, {"loop": false, "interp": &"hold"})
	b.anim(&"attack", 5, [140, 33, 90, 90, 120], {0: wk, 1: mk, 2: tk, 3: rk, 4: rk2}, {"loop": false, "interp": &"hold"})
	b.smear(&"attack", 1, &"hammer_n", Vector2(8.5, 21), &"trail", 9.0, false).samples = 64
	b.smear(&"attack", 2, &"hammer_n", Vector2(8.5, 21), &"trail", 9.0, false).samples = 64
	# Habilidad: alza la mano abierta (las tenazas/brasa las pone el VFX en el socket); martillo a la otra mano.
	var ck := _keys("cast", {&"emit:lantern": 1, &"bun": 0.1})
	b.anim(&"cast", 2, [100, 200], {0: _keys("toss_back"), 1: ck}, {"loop": false, "interp": &"hold"})
	# Quemar: la carta va al fogón de cinto; el farol estalla (+2) en el segundo fotograma.
	b.anim(&"toss", 2, [120, 260], {0: _keys("toss_back", {&"emit:lantern": 0}), 1: _keys("toss", {&"emit:lantern": 3, &"bun": 0.2})},
		{"loop": false, "interp": &"hold"})
	b.anim(&"hurt", 2, [80, 160], {0: _keys("hurt", {&"bun": -0.4, &"scarf": -0.4}), 1: _keys("hurt2", {&"bun": -0.2, &"scarf": -0.5})},
		{"loop": false, "interp": &"hold"})
	# Muerte: se dobla, cae de rodillas, se apoya en el martillo y el fogón de cinto se apaga.
	var d := {}
	d[0] = _keys("hurt2", {&"emit:lantern": 0})
	d[1] = _keys("die1", {&"emit:lantern": 0, &"bun": 0.2})
	d[2] = _keys("die2", {&"emit:lantern": -1, &"bun": 0.35})
	d[3] = _keys("die3", {&"emit:lantern": -1, &"bun": 0.4, &"scarf": 0.4})
	d[4] = _keys("die4", {&"emit:lantern": -2, &"bun": 0.3, &"scarf": 0.5})
	d[5] = _keys("die4", {&"emit:lantern": -2, &"bun": 0.35, &"scarf": 0.55})
	d[6] = _keys("die4", {&"emit:lantern": -3, &"bun": 0.35, &"scarf": 0.55, &"emit:hotface_n": -2})
	d[7] = _keys("die4", {&"emit:lantern": -4, &"bun": 0.35, &"scarf": 0.55, &"emit:hotface_n": -3})
	b.anim(&"death", 8, [80, 90, 100, 110, 140, 180, 220, 400], d, {"loop": false, "interp": &"hold"})
