extends RefCounted
## EJEMPLO de referencia del motor de rig v1 (TEC). No es el gólem final (ése es de PER en scripts/art/defs/):
## enseña cada función de la API en una criatura real. Hornear: godot --headless --path . -s res://tools/bake_art.gd -- --only=golem_example
##
## Funciones usadas: materiales de paleta con facetas (carbón) y grietas emisivas · textura de material · especular ·
## máscara de material por parámetro (hollín que sube) · accesorio por estado (grillete) · losa biselada (placa) ·
## sellos con ranuras "@" (cara, nudillos) · vista de sello por pose · emisivo animable (ojos) · IK de 2 huesos con
## pies plantados · z animable · overlap · estela en media luna · parche por fotograma · sockets para VFX/UI.

const TAU_ := TAU


static func build() -> RigDef:
	var b := RigBuilder.new(&"golem_example", Vector2i(96, 96), Vector2i(54, 59), -1, &"examples")
	# --- materiales (todos de Palette; facetas sólo en carbón)
	b.material(&"body", &"rock_soot", {"texture": &"soot_grain"})
	b.material(&"limb", &"coal", {"facet": {"cell_area": 48.0, "weight": 0.55, "crack": 0.3, "crack_slot": &"magma"}})
	b.material(&"magma", &"hot")
	b.material(&"horn", &"linen")
	b.material(&"iron", &"iron", {"spec": true, "texture": &"scratches"})
	b.material(&"soot", &"soot")
	b.material(&"trail", &"fire")
	b.mask(&"body", &"soot", &"soot", &"rise")
	# --- esqueleto (ángulos de reposo; las poses SUMAN)
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"leg_f", &"root", Vector2(6, 4), {"z": -7.0, "angle": -0.24})
	b.bone(&"shin_f", &"leg_f", Vector2(0, 11), {"angle": 0.12})
	b.bone(&"leg_n", &"root", Vector2(-5, 5), {"z": 7.0, "angle": 0.3})
	b.bone(&"shin_n", &"leg_n", Vector2(0, 11), {"angle": -0.22})
	b.bone(&"spine", &"root", Vector2(1, -1), {"angle": -0.32})
	b.bone(&"head", &"spine", Vector2(-17, -21), {"z": 9.0, "angle": 0.30})
	b.bone(&"jaw", &"head", Vector2(-2, 1))
	b.bone(&"arm_f", &"spine", Vector2(9, -16), {"z": -12.0, "angle": -0.12})
	b.bone(&"fore_f", &"arm_f", Vector2(0, 12), {"angle": -0.05})
	b.bone(&"arm_n", &"spine", Vector2(-7, -16), {"z": 13.0, "angle": 0.62})
	b.bone(&"fore_n", &"arm_n", Vector2(0, 12), {"angle": 0.1})
	b.ik(&"foot_n", &"leg_n", &"shin_n", Vector2(-1, 8), 1)
	b.ik(&"foot_f", &"leg_f", &"shin_f", Vector2(-1, 8), 1)
	# --- piezas: pierna lejana, brazo lejano, tronco, cabeza, pierna cercana, brazo cercano
	b.cap(&"thigh_f", &"leg_f", &"limb", Vector3(0, 0, 0), Vector3(0, 11, 0), 6.0, 5.0)
	b.cap(&"calf_f", &"shin_f", &"limb", Vector3(0, 0, 0), Vector3(-1, 8, 0), 5.0, 6.0)
	b.ell(&"foot_f", &"shin_f", &"body", Vector3(-3, 11, 0), Vector3(8, 3.6, 6))
	b.ell(&"pauldron_f", &"arm_f", &"body", Vector3(1, -1, 0), Vector3(8, 7, 7))
	b.cap(&"upper_f", &"arm_f", &"limb", Vector3(0, 0, 0), Vector3(0, 12, 0), 6.0, 5.0)
	b.cap(&"fore_f", &"fore_f", &"limb", Vector3(0, 0, 0), Vector3(0, 11, 0), 5.0, 7.0)
	b.ell(&"fist_f", &"fore_f", &"body", Vector3(0, 15, 0), Vector3(7.5, 6.5, 7), {"flat": 0.2})
	b.ell(&"pelvis", &"root", &"body", Vector3(0, 1, 0), Vector3(11, 7, 9), {"flat": 0.35})
	b.ell(&"torso", &"spine", &"body", Vector3(2, -13, 0), Vector3(14, 13, 11), {"flat": 0.4})
	b.ell(&"belly", &"spine", &"body", Vector3(-2, -3, 2), Vector3(11, 8, 10), {"flat": 0.35})
	b.ell(&"hump", &"spine", &"limb", Vector3(9, -21, -2), Vector3(10, 9, 9))
	b.cap(&"chimney", &"spine", &"body", Vector3(10, -24, -1), Vector3(14, -33, -1), 3.6, 2.6)
	b.ell(&"chimney_fire", &"spine", &"magma", Vector3(14, -33.5, -1), Vector3(2.0, 1.2, 2.0))
	# placa del pecho: losa ASCII biselada (lo plano se dibuja a mano)
	b.slab(&"plate", &"spine", [
		"..####..",
		".######.",
		"########",
		"########",
		".######.",
		"..####..",
	], Vector2(-10, -16), {"#": &"iron"}, 12.0, 2.0, 2.0)
	b.ell(&"skull", &"head", &"body", Vector3(-1, -1, 0), Vector3(7.5, 6.5, 6.5), {"tags": [&"face", &"eye"]})
	b.ell(&"brow", &"head", &"limb", Vector3(-4, -4.5, 2), Vector3(6.5, 2.6, 6))
	b.cap(&"horn_a", &"head", &"horn", Vector3(2, -6, -1), Vector3(6, -10, -1), 2.2, 1.6)
	b.cap(&"horn_b", &"head", &"horn", Vector3(6, -10, -1), Vector3(5, -15, -1), 1.6, 0.6)
	b.ell(&"jaw", &"jaw", &"body", Vector3(-2, 2, 0), Vector3(6.5, 3.4, 5.5))
	b.cap(&"thigh_n", &"leg_n", &"limb", Vector3(0, 0, 0), Vector3(0, 11, 0), 6.5, 5.5)
	b.cap(&"calf_n", &"shin_n", &"limb", Vector3(0, 0, 0), Vector3(-1, 8, 0), 5.5, 6.5)
	b.ell(&"foot_n", &"shin_n", &"body", Vector3(-3, 11, 0), Vector3(8.5, 3.8, 6))
	b.ell(&"pauldron_n", &"arm_n", &"limb", Vector3(1, -1, 0), Vector3(7.5, 6.5, 7))
	b.cap(&"upper_n", &"arm_n", &"limb", Vector3(0, 0, 0), Vector3(0, 12, 0), 6.5, 5.5)
	b.cap(&"fore_n", &"fore_n", &"limb", Vector3(0, 0, 0), Vector3(0, 11, 0), 5.5, 7.5)
	b.cap(&"shackle", &"fore_n", &"iron", Vector3(0, 6.5, 0), Vector3(0, 8, 0), 6.9, 7.1, {"accessory": &"shackle", "line": false})
	b.ell(&"fist_n", &"fore_n", &"body", Vector3(0, 15, 0), Vector3(8, 7, 7.5), {"flat": 0.2, "tags": [&"hand"]})
	# --- sellos: cara (ojos emisivos animables, dientes) con vista alternativa, y nudillos
	var face_legend := {
		"k": ["@body", "LINE"], "s": ["@body", "-1"], "h": ["@body", "+1"],
		"Y": [&"hot", 5], "y": [&"hot", 4], "o": [&"hot", 3], "W": ["@horn", 5], "w": ["@horn", 3],
	}
	b.stamp(&"face", &"head", Vector2(-11, -5), [
		"............",
		".kkkkkkk....",
		"..yYYo..s...",
		"..oYYy......",
		"...ooo....s.",
		"............",
		"kkkkkkkk....",
		".WkWkWk.....",
		"..h.h.......",
	], face_legend, {"views": {&"roar": [
		"............",
		"kkkkkkkk....",
		".yYYYo..s...",
		"..oYYy......",
		"............",
		"kkkkkkkk....",
		".WkWkWk.....",
		"..k.k.k.....",
		".WwWwWk.....",
	]}})
	b.stamp(&"knuckles", &"fore_n", Vector2(-8, 14), [
		"..kh.....",
		"...k.....",
		"..k.kh...",
		"...k.k...",
		"....k.kh.",
		".....k.k.",
	], {"k": ["@body", "LINE"], "h": ["@body", "+1"]})
	# --- sockets (posiciones que el juego necesita: impacto, intención, humo)
	b.socket(&"hit", &"fore_n", Vector2(0, 21))
	b.socket(&"intent", &"head", Vector2(0, -16))
	b.socket(&"smoke", &"spine", Vector2(14, -35))
	# --- animaciones
	var feet := {&"ik:foot_n": Vector2(44, 82), &"ik:foot_f": Vector2(62, 82)}
	var idle := {}
	for f in 8:
		var t := TAU * f / 8.0
		var k := feet.duplicate()
		k[&"@root"] = Vector2i(0, 1 if (f >= 3 and f <= 6) else 0)
		k[&"spine"] = 0.035 * sin(t)
		k[&"head"] = 0.05 * sin(t)
		k[&"jaw"] = 0.06 * maxf(0.0, sin(t - 1.4))
		k[&"arm_n"] = 0.05 * sin(t)
		k[&"fore_n"] = 0.06 * sin(t)
		k[&"arm_f"] = 0.045 * sin(t)
		k[&"emit:face"] = 1 if f in [2, 3, 4] else 0
		idle[f] = k
	b.anim(&"idle", 8, 140, idle, {"interp": &"linear", "overlap": {&"head": 1.0, &"arm_n": 1.5, &"fore_n": 2.0, &"arm_f": 1.5}})
	var R := {&"spine": -0.32, &"head": 0.30, &"arm_f": -0.12, &"fore_f": -0.05, &"arm_n": 0.62, &"fore_n": 0.1}
	var abs_keys := [
		{&"spine": -0.12, &"head": 0.2, &"arm_n": -1.2, &"fore_n": -0.9, &"arm_f": 0.8, &"@root": Vector2i(2, 1), &"jaw": 0.15},
		{&"spine": -0.02, &"head": 0.12, &"arm_n": -2.05, &"fore_n": -1.25, &"arm_f": 0.95, &"@root": Vector2i(3, 2), &"jaw": 0.3, &"z:arm_n": -4.0, &"view:head": &"roar", &"emit:face": 1},
		{&"spine": -0.42, &"head": 0.3, &"arm_n": -3.75, &"fore_n": -0.2, &"arm_f": 0.5, &"@root": Vector2i(-2, 0), &"jaw": 0.3, &"view:head": &"roar", &"emit:face": 1},
		{&"spine": -0.62, &"head": 0.42, &"arm_n": 0.78 - TAU_, &"fore_n": 0.0, &"arm_f": 0.2, &"fore_f": 0.3, &"@root": Vector2i(-5, 2), &"jaw": 0.25, &"ik:foot_n": Vector2(38, 82)},
		{&"spine": -0.58, &"head": 0.36, &"arm_n": 0.76 - TAU_, &"fore_n": 0.04, &"arm_f": 0.25, &"fore_f": 0.25, &"@root": Vector2i(-5, 2), &"jaw": 0.1, &"ik:foot_n": Vector2(38, 82)},
		{&"spine": -0.45, &"head": 0.33, &"arm_n": 0.6 - TAU_, &"fore_n": 0.12, &"arm_f": 0.35, &"@root": Vector2i(-2, 1), &"ik:foot_n": Vector2(41, 82)},
	]
	var atk := {}
	for f in abs_keys.size():
		var k2: Dictionary = feet.duplicate()
		for key in abs_keys[f].keys():
			var v: Variant = abs_keys[f][key]
			k2[key] = (float(v) - float(R.get(key, 0.0))) if (R.has(key) or key == &"jaw") else v
		atk[f] = k2
	b.anim(&"attack", 6, [110, 160, 40, 90, 120, 140], atk, {"loop": false, "interp": &"linear"})
	b.smear(&"attack", 2, &"fore_n", Vector2(0, 15), &"trail", 13.0, false)
	# parche por fotograma (≤ 15 px): la mandíbula abierta del impacto deja un hueco que se tapa a mano
	b.patch(&"attack", 3, &"jaw", Vector2(-8, 4), ["kk", ".k"], {"k": ["@body", "LINE"]})
	b.variant(&"chained", {&"shackle": true})
	b.variant(&"sooty", {&"soot": 0.45})
	return b.def
