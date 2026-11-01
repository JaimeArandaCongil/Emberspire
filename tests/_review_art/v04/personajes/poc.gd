extends SceneTree
## Prueba de concepto del panel de personajes v0.4.
## Ejecutar:  Godot --headless --path . -s res://tests/_review_art/v04/personajes/poc.gd
## Salida: tests/_review_art/v04/personajes/out/*.png (nativo + ampliados)
## Resolución nativa del mundo propuesta: 640×360 (×2 en 1280×720). Heroína ≈ 66 px de alto.

const Rig = preload("res://tests/_review_art/v04/personajes/rig.gd")
const OUT := "res://tests/_review_art/v04/personajes/out/"

# --- Paletas por material (oscuro -> claro; sombras hacia violeta/azul, luces hacia amarillo) -------
const RAMPS := {
	"skin": [["4a1e2e", "843c38", "bc6648", "e09868", "f6c890"], "2a1018"],
	"soot": [["1a1420", "2c2230", "44363f", "62504c", "84705e"], "120c12"],
	"hair": [["2c0a1c", "561424", "862420", "b23a22", "e07034"], "1c0612"],
	"linen": [["3a3048", "665a6c", "9a8a88", "ccbaa2", "eedfc0"], "1c1424"],
	"leather": [["1e121c", "3a1e26", "60342c", "8a5236", "b07646"], "120a10"],
	"pleat": [["1e121c", "3a1e26", "60342c", "8a5236", "b07646"], "120a10"],
	"canvas": [["16141e", "2a2434", "40384a", "584c5e", "726474"], "0e0c14"],
	"boot": [["160e12", "2c1a1c", "482a24", "6a4032", "8a5a42"], "0c0608"],
	"steel": [["14141e", "2a2c3e", "4a4e66", "7a8298", "c8d0dc"], "0a0a12"],
	"hot": [["6a1414", "b8281a", "f45a18", "ffa834", "fff0b8"], "3a0a0c"],
	"scarf": [["161e3a", "243a62", "36628e", "5c96be", "a0d0e8"], "0c1024"],
	"wood": [["24120e", "48261a", "724024", "9a6034", "c08a52"], "140a08"],
	"brass": [["34200e", "64401a", "a06c22", "d8a440", "fae088"], "1c1008"],
	"coal": [["060408", "0e0c14", "181622", "262433", "52546c"], "050308"],
	"burlap": [["2a1e1a", "4a3628", "6a5234", "8c7246", "ae9660"], "160e0c"],
	# Gólem
	"brick": [["22101a", "381a22", "552a2a", "783a30", "9a563c"], "140a0e"],
	"iron": [["121220", "222436", "383a50", "56566c", "8a8698"], "08080e"],
	"smoke": [["1e1a22", "2a2430", "3a3240", "4c4450", "625a64"], "120e14"],
	# Boceto de jefe: pocos valores + fuego
	"sk_body": [["120c12", "1a1216", "241a1e", "32242a", "463234"], "080406"],
	"sk_mound": [["1a1214", "261a1c", "342422", "48322a", "604236"], "080406"],
	"sk_fire": [["7a1a16", "c2321e", "ff6a1a", "ffb43a", "fff4c8"], "3a0a0c"],
	"sk_hero": [["3a2226", "4a2c30", "5a3638", "6a4240", "7a4e48"], "0c0608"],
}

var r  # rig actual


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var frames := {}
	for pose in ["idle", "windup", "strike"]:
		frames[pose] = fogonera(pose)
	var golem := soot_golem("idle")
	var golem_tel := soot_golem("tell")
	var boss := carbonero_sketch()
	for k in frames:
		(frames[k]["img"] as Image).save_png(OUT + "fogonera_%s_x1.png" % k)
		Rig.up(frames[k]["img"], 6).save_png(OUT + "fogonera_%s_x6.png" % k)
	golem["img"].save_png(OUT + "golem_idle_x1.png")
	Rig.up(golem["img"], 6).save_png(OUT + "golem_idle_x6.png")
	Rig.up(golem_tel["img"], 6).save_png(OUT + "golem_tell_x6.png")
	boss["img"].save_png(OUT + "carbonero_boceto_x1.png")
	Rig.up(boss["img"], 2).save_png(OUT + "carbonero_boceto_x2.png")
	var bg := Color("2a2026")
	var sheet := Image.create(96 * 3 * 4 + 16 * 4, 96 * 4 + 32, false, Image.FORMAT_RGBA8)
	sheet.fill(bg)
	var i := 0
	for k in ["idle", "windup", "strike"]:
		var u := Rig.up(frames[k]["img"], 4)
		sheet.blend_rect(u, Rect2i(Vector2i.ZERO, u.get_size()), Vector2i(16 + i * (96 * 4 + 16), 16))
		i += 1
	sheet.save_png(OUT + "fogonera_sheet_x4.png")
	var hcrop := (frames["idle"]["img"] as Image).get_region(Rect2i(30, 10, 34, 34))
	Rig.up(hcrop, 12).save_png(OUT + "fogonera_cabeza_x12.png")
	var gs := Image.create(112 * 4 * 2 + 48, 96 * 4 + 32, false, Image.FORMAT_RGBA8)
	gs.fill(bg)
	var g1 := Rig.up(golem["img"], 4)
	var g2 := Rig.up(golem_tel["img"], 4)
	gs.blend_rect(g1, Rect2i(Vector2i.ZERO, g1.get_size()), Vector2i(16, 16))
	gs.blend_rect(g2, Rect2i(Vector2i.ZERO, g2.get_size()), Vector2i(32 + 112 * 4, 16))
	gs.save_png(OUT + "golem_sheet_x4.png")
	scene_mock(frames["idle"]["img"], golem["img"], boss["img"])
	quit()


func new_rig(W: int, H: int):
	r = Rig.new(W, H)
	for k: String in RAMPS:
		var e: Array = RAMPS[k]
		var tex := Callable()
		match k:
			"brick": tex = _tex_brick
			"leather": tex = _tex_leather
			"pleat": tex = _tex_pleat
			"hair": tex = _tex_hair
			"sk_mound": tex = _tex_logs
		r.add_mat(k, e[0], e[1], k in ["hot", "sk_fire"], tex)
	return r


# ---------------------------------------------------------------------------------------------
# Texturas de material (sólo sobre tonos calculados; los forzados son de la mano del artista)
func _tex_brick(x: int, y: int, t: int, rg) -> int:
	# Ladrillo sólo donde la luz lo deja leer (tonos 2-3); en sombra se pierde (detalle selectivo).
	if t < 2 or t > 3:
		return t
	var row := int(floor(y / 4.0))
	var off := 4 if row % 2 == 0 else 0
	if y % 4 == 0:
		return t - 1
	if (x + off) % 9 == 0:
		return t - 1
	if (x + off) % 9 == 1 and y % 4 == 1 and t == 3:
		return 4
	return t


func _tex_leather(x: int, y: int, t: int, rg) -> int:
	var hsh: float = rg._h2(x, y, 31)
	if t == 2 and hsh < 0.035:
		return 1
	if t == 3 and hsh < 0.03:
		return 4
	return t


func _tex_pleat(x: int, y: int, t: int, rg) -> int:
	return maxi(0, t - 1) if y % 3 == 0 else t


func _tex_hair(x: int, y: int, t: int, rg) -> int:
	# Mechones: diagonales sueltas, nunca en la sombra profunda ni en el brillo.
	if t >= 2 and t <= 3 and (x * 2 + y) % 7 == 0 and rg._h2(x, y, 5) < 0.7:
		return t - 1
	return t


func _tex_logs(x: int, y: int, t: int, rg) -> int:
	if (x + y * 2) % 11 == 0:
		return maxi(0, t - 1)
	return t


# ---------------------------------------------------------------------------------------------
# LA FOGONERA · 96×96, pies en y=89. Mira a la derecha. Altura del personaje ≈ 66 px (+ moño).
const POSE := {
	"idle": {
		"head": Vector2(47, 27), "tilt": 0,
		"chest": Vector2(45, 45), "waist": Vector2(45, 55),
		"sh_n": Vector2(51.5, 40), "el_n": Vector2(55, 50), "wr_n": Vector2(56.5, 58.5),
		"sh_f": Vector2(38, 40), "el_f": Vector2(35, 50), "wr_f": Vector2(37.5, 57),
		"hip_b": Vector2(41, 60), "kn_b": Vector2(38.5, 72), "an_b": Vector2(37, 83),
		"hip_f": Vector2(49, 60), "kn_f": Vector2(52, 72), "an_f": Vector2(54, 83),
		"hammer": Vector2(61, 78), "case_glow": 2, "lean": 0.0,
	},
	"windup": {
		"head": Vector2(45, 29), "tilt": -1,
		"chest": Vector2(43, 47), "waist": Vector2(43, 57),
		"sh_n": Vector2(47, 41), "el_n": Vector2(41, 27), "wr_n": Vector2(35, 18),
		"sh_f": Vector2(38, 42), "el_f": Vector2(47, 50), "wr_f": Vector2(55, 52),
		"hip_b": Vector2(40, 61), "kn_b": Vector2(34, 72), "an_b": Vector2(31, 83),
		"hip_f": Vector2(48, 61), "kn_f": Vector2(56, 71), "an_f": Vector2(59, 83),
		"hammer": Vector2(23, 7), "case_glow": 2, "lean": -0.15,
	},
	"strike": {
		"head": Vector2(55, 31), "tilt": 1,
		"chest": Vector2(51, 48), "waist": Vector2(48, 57),
		"sh_n": Vector2(57, 42), "el_n": Vector2(65, 49), "wr_n": Vector2(71, 55),
		"sh_f": Vector2(44, 42), "el_f": Vector2(38, 49), "wr_f": Vector2(33, 52),
		"hip_b": Vector2(43, 62), "kn_b": Vector2(36, 72), "an_b": Vector2(29, 83),
		"hip_f": Vector2(51, 62), "kn_f": Vector2(59, 71), "an_f": Vector2(62, 83),
		"hammer": Vector2(82, 72), "case_glow": 4, "lean": 0.2,
	},
}


func fogonera(pose: String) -> Dictionary:
	new_rig(96, 96)
	var P: Dictionary = POSE[pose]
	var head: Vector2 = P["head"]
	var chest: Vector2 = P["chest"]
	var waist: Vector2 = P["waist"]

	# 0) Estela del martillazo (media luna continua, detrás de todo) — sólo en el golpe.
	if pose == "strike":
		r.begin(false)
		var sh: Vector2 = P["sh_n"]
		var a0 := -2.45
		var a1 := 0.62
		for k in 90:
			var t := k / 89.0
			var a := lerpf(a0, a1, t)
			var thick := lerpf(0.5, 4.5, t * t)
			var rad0 := 27.0 - thick * 0.5
			var rr := rad0
			while rr <= rad0 + thick:
				var p := sh + Vector2(cos(a), sin(a)) * rr
				var edge := rr > rad0 + thick - 1.0
				var tt := 1
				if t > 0.25: tt = 2
				if t > 0.55: tt = 3
				if t > 0.8 and not edge: tt = 4
				if edge and tt > 1: tt -= 1
				r.pix(int(p.x), int(p.y), "hot", tt)
				rr += 0.5

	# 1) Brazo lejano (detrás del torso).
	r.begin()
	r.capsule(P["sh_f"], P["el_f"], 3.6, 3.0, "linen", 0.18)
	r.capsule(P["el_f"], P["wr_f"], 2.8, 2.4, "soot", 0.18)
	r.ellipse(P["wr_f"], 2.6, 2.4, "soot", 0.15)

	# 2) Fuelle a la espalda: asas, fuelle de cuero plisado, pala de madera y boquilla de latón.
	var bo := Vector2(chest.x - 11, chest.y - 2) + Vector2(P["lean"] * -6, 0)
	r.begin()
	r.capsule(bo + Vector2(-1, -7), bo + Vector2(-3, -14), 1.1, 0.9, "wood", 0.0)
	r.capsule(bo + Vector2(3, -7), bo + Vector2(4, -14), 1.1, 0.9, "wood", 0.05)
	r.begin()
	r.ellipse(bo + Vector2(-2.0, 1), 5.0, 8.5, "pleat", 0.0)
	r.begin()
	r.ellipse(bo + Vector2(1.5, 0), 4.6, 9.0, "wood", 0.0, 0.0, 0, Vector2.ZERO, 0.6)
	r.pix(int(bo.x + 1), int(bo.y - 4), "brass", 4)
	r.pix(int(bo.x + 1), int(bo.y + 4), "brass", 3)
	r.capsule(bo + Vector2(0, 8), bo + Vector2(-2, 14), 1.8, 1.0, "brass", 0.0)

	# 3) Pierna trasera.
	r.begin()
	r.capsule(P["hip_b"], P["kn_b"], 4.4, 3.7, "canvas", 0.12)
	r.capsule(P["kn_b"], P["an_b"], 3.6, 3.0, "canvas", 0.12)
	r.begin()
	_boot(P["an_b"], 0.1)

	# 4) Torso: camisa de lino, delantal de cuero, cinturón.
	r.begin()
	r.ellipse(chest + Vector2(0, -1), 9.5, 8.5, "linen", 0.0, 0.0, 0, Vector2.ZERO, 0.3)
	r.ellipse(waist, 7.5, 6.0, "linen", 0.05)
	r.capsule(P["sh_f"], P["sh_n"], 3.4, 3.8, "linen", 0.0)
	# correa del fuelle cruzando el pecho
	r.begin()
	r.line(P["sh_f"] + Vector2(1, -2), Vector2(chest.x + 6, waist.y - 3), "leather", 1)
	r.line(P["sh_f"] + Vector2(2, -2), Vector2(chest.x + 7, waist.y - 3), "leather", 2)
	r.begin()
	var ax := chest.x + 2.0
	var ap := PackedVector2Array([
		Vector2(ax - 5, chest.y - 3), Vector2(ax + 5, chest.y - 3), Vector2(ax + 7, waist.y),
		Vector2(ax + 10 + P["lean"] * 8, 73), Vector2(ax - 9 + P["lean"] * 8, 73), Vector2(ax - 7, waist.y)])
	r.poly(ap, "leather", Vector3(0.15, 0.1, 1.0), 2.2)
	r.line(Vector2(ax - 1, waist.y + 3), Vector2(ax - 2 + P["lean"] * 6, 71), "leather", 1)
	r.line(Vector2(ax + 4, waist.y + 4), Vector2(ax + 6 + P["lean"] * 7, 71), "leather", 1)
	r.pix(int(ax - 4), int(chest.y - 2), "brass", 4)
	r.pix(int(ax + 4), int(chest.y - 2), "brass", 3)
	r.begin()
	r.capsule(Vector2(waist.x - 9, waist.y + 1), Vector2(waist.x + 9, waist.y + 1), 1.4, 1.4, "leather", 0.08)
	r.stamp(["kk", "yY"], Vector2i(int(waist.x + 1), int(waist.y)), {"k": ["brass", 1], "y": ["brass", 3], "Y": ["brass", 4]})
	# Tenazas colgando del cinto y saco de carbón.
	r.begin()
	r.line(Vector2(waist.x - 6, waist.y + 2), Vector2(waist.x - 9, waist.y + 16), "steel", 2)
	r.line(Vector2(waist.x - 5, waist.y + 2), Vector2(waist.x - 7, waist.y + 16), "steel", 3)
	r.pix(int(waist.x - 10), int(waist.y + 16), "steel", 1)
	r.begin()
	var sack := Vector2(waist.x - 9, waist.y + 6)
	r.ellipse(sack, 4.2, 4.8, "burlap", 0.0)
	r.capsule(sack + Vector2(0, -5), sack + Vector2(1, -7), 1.6, 1.2, "burlap", 0.0)
	r.stamp([".c.c", "cCcc"], Vector2i(int(sack.x - 2), int(sack.y - 4)), {"c": ["coal", 1], "C": ["coal", 4]})
	r.pix(int(sack.x - 1), int(sack.y - 3), "hot", 3)

	# 5) Pierna delantera.
	r.begin()
	r.capsule(P["hip_f"], P["kn_f"], 4.6, 3.8, "canvas", 0.0)
	r.capsule(P["kn_f"], P["an_f"], 3.7, 3.1, "canvas", 0.0)
	r.begin()
	_boot(P["an_f"], 0.0)

	# 6) Fogón de cinto: farol de latón con rejilla donde arde la carta quemada (mazo = combustible).
	r.begin()
	var cb := Vector2i(int(waist.x + 5), int(waist.y + 2))
	var g := int(P["case_glow"])
	r.stamp([
		".yYy.",
		"yfgfy",
		"ykgky",
		"yfgfy",
		".yyy."], cb, {"y": ["brass", 2], "Y": ["brass", 4], "k": ["brass", 0], "f": ["hot", g - 1], "g": ["hot", g]})

	# 7) Cabeza + cuello + bufanda. En la carga el brazo pasa POR DETRÁS de la cabeza.
	if pose == "windup":
		_near_arm(P, pose)
	_head(head, int(P["tilt"]))
	if pose != "windup":
		_near_arm(P, pose)

	# 9) Chispas de impacto.
	if pose == "strike":
		r.begin(false)
		var hp: Vector2 = P["hammer"]
		for s: Array in [[9, 11, 4], [12, 6, 3], [14, 10, 2], [5, 15, 3], [11, 1, 4], [13, 3, 2], [2, 15, 2], [9, 14, 4], [15, 13, 3]]:
			r.pix(int(hp.x) + s[0] - 4, int(hp.y) + s[1] - 6, "hot", s[2])
	return r.render()


func _near_arm(P: Dictionary, pose: String) -> void:
	r.begin()
	r.capsule(P["sh_n"], P["el_n"], 3.9, 3.3, "linen", 0.0)
	r.begin()
	var mid: Vector2 = P["sh_n"].lerp(P["el_n"], 0.7)
	r.capsule(mid, P["el_n"], 3.6, 3.4, "linen", 0.0)  # manga remangada (rollo)
	r.capsule(P["el_n"], P["wr_n"], 3.1, 2.6, "soot", 0.0)
	var fa: Vector2 = P["el_n"].lerp(P["wr_n"], 0.45)
	r.pix(int(fa.x), int(fa.y), "hot", 2)
	r.pix(int(fa.x) - 1, int(fa.y) + 2, "hot", 1)
	_hammer(P["wr_n"], P["hammer"], pose)
	r.begin()
	r.ellipse(P["wr_n"], 3.0, 2.8, "soot", 0.0)
	var wr: Vector2 = P["wr_n"]
	r.pix(int(wr.x) + 1, int(wr.y) - 1, "soot", 4)
	r.pix(int(wr.x), int(wr.y) - 2, "soot", 3)


func _boot(an: Vector2, ao: float) -> void:
	var b := PackedVector2Array([an + Vector2(-3.5, -2.5), an + Vector2(3.0, -2.5), an + Vector2(7.5, 3.0),
		an + Vector2(8.0, 6.0), an + Vector2(-4.0, 6.0), an + Vector2(-4.0, 1.0)])
	r.poly(b, "boot", Vector3(0, -0.2, 1), 1.6, ao)
	r.line(an + Vector2(-4, 6), an + Vector2(7.5, 6), "boot", 0)
	r.pix(int(an.x + 6), int(an.y + 3), "steel", 3)
	r.pix(int(an.x + 6), int(an.y + 4), "steel", 2)


func _hammer(hand: Vector2, hd: Vector2, pose: String) -> void:
	var d := (hd - hand).normalized()
	var pp := Vector2(-d.y, d.x)
	if pp.x < 0:
		pp = -pp
	r.begin()
	r.capsule(hand - d * 3.0, hd - d * 2.0, 1.5, 1.6, "wood", 0.0)
	r.begin()
	var L := 8.5
	var T := 5.0
	# Cuerpo del mazo: cara frontal en tono medio; el bisel da la arista iluminada arriba-izquierda.
	var head := PackedVector2Array([hd - pp * L - d * T, hd + pp * L - d * T, hd + pp * L + d * T, hd - pp * L + d * T])
	r.poly(head, "steel", Vector3(0.35, 0.3, 1.0), 1.6)
	# Línea de forja (ranura) a lo largo del mazo.
	r.line(hd - pp * (L - 2.5), hd + pp * (L - 3.5), "steel", 1)
	r.capsule(hd - pp * 1.6 - d * 4.6, hd + pp * 1.6 - d * 4.6, 1.0, 1.0, "iron", 0.0)
	# Cara de golpe al rojo (la que mira al enemigo).
	r.begin(false)
	var hot := PackedVector2Array([hd + pp * (L - 2.4) - d * T, hd + pp * L - d * T, hd + pp * L + d * T, hd + pp * (L - 2.4) + d * T])
	r.poly(hot, "hot", Vector3(0.3, -0.3, 1.0), 1.2)
	var hotp := hd + pp * (L - 0.6)
	r.pix(int(hotp.x), int(hotp.y), "hot", 4)


func _head(c: Vector2, tilt: int) -> void:
	# Cuello.
	r.begin()
	r.capsule(c + Vector2(0, 6), c + Vector2(-0.5, 11), 3.0, 3.2, "skin", 0.15)
	# Bufanda azul: el único frío de la heroína (contrasta con pelo y fuego). Cola al aire, atrás.
	r.begin()
	r.capsule(c + Vector2(-6, 12), c + Vector2(-10, 17), 2.0, 1.2, "scarf", 0.1)
	r.capsule(c + Vector2(-10, 17), c + Vector2(-13, 16), 1.2, 0.9, "scarf", 0.1)
	r.begin()
	r.ellipse(c + Vector2(-0.5, 11.5), 6.5, 2.6, "scarf", 0.0)
	# Pelo trasero (nuca) + moño alto atado con un trapo azul.
	r.begin()
	r.ellipse(c + Vector2(-4.5, 0), 5.5, 7.0, "hair", 0.05)
	r.ellipse(c + Vector2(-6 + tilt, -10), 4.4, 3.9, "hair", 0.0)
	r.begin()
	r.capsule(c + Vector2(-7 + tilt, -6.5), c + Vector2(-3 + tilt, -6.5), 1.2, 1.2, "scarf", 0.0)
	# Cráneo y mandíbula.
	r.begin()
	r.ellipse(c + Vector2(0.5, -0.5), 7.0, 7.5, "skin", 0.0, 0.0, 0, Vector2.ZERO, 1.6)
	r.ellipse(c + Vector2(2.5, 3.0), 5.0, 4.6, "skin", 0.0, 0.0, 0, Vector2.ZERO, 1.4)
	# Casquete de pelo: cubre la parte alta y la nuca; la cara (abajo-derecha) queda libre.
	r.clip = func(x: int, y: int) -> bool:
		var fx := x - c.x
		var fy := y - c.y
		return fy < -3.5 + maxf(0.0, -fx - 1.0) * 1.6 or fx < -2.0
	r.ellipse(c + Vector2(-0.5, -2.0), 8.0, 7.0, "hair", 0.0)
	r.clip = Callable()
	# Flequillo: un mechón que cae sobre la sien hacia la cara.
	r.capsule(c + Vector2(2, -6), c + Vector2(6.5, -2.5), 1.5, 0.6, "hair", 0.0)
	# Oreja (en el borde pelo/cara, sin línea de separación).
	r.begin(false)
	r.ellipse(c + Vector2(-2.5, 1.5), 1.6, 2.2, "skin", 0.0)
	r.pix(int(c.x - 2.5), int(c.y + 1.5), "skin", 1)
	# Gafas de forja sobre el pelo (latón + cristal que refleja el fuego).
	r.begin()
	r.capsule(c + Vector2(-7, -5.5), c + Vector2(2, -7.5), 0.9, 0.9, "leather", 0.0)
	r.begin()
	r.ellipse(c + Vector2(3.0, -7.0), 2.6, 2.2, "brass", 0.0)
	r.stamp(["gG", "gg"], Vector2i(int(c.x + 2), int(c.y - 8)), {"g": ["hot", 1], "G": ["hot", 3]})
	# Rasgos a mano (origen = centro de la cabeza): ceja, ojo grande con brillo, nariz que rompe
	# la silueta, boca, tizne en la mejilla. Aquí manda el artista, no el render.
	var f := Vector2i(int(c.x), int(c.y))
	r.stamp([
		"..bbb.b.",
		"..kkk...",
		"..wik.k.",
		"......nN",
		"......n.",
		"..s.....",
		".....mm.",
	], f + Vector2i(1, -3), {
		"b": ["hair", 1], "k": ["skin", 9], "w": ["linen", 4], "i": ["scarf", 1],
		"n": ["skin", 1], "N": ["skin", 3], "t": ["soot", 3], "m": ["skin", 1], "s": ["skin", 2]})


# ---------------------------------------------------------------------------------------------
# GÓLEM DE HOLLÍN · 112×96, mira a la izquierda. Horno andante de ladrillo y carbón con aros de hierro.
func soot_golem(pose: String) -> Dictionary:
	new_rig(112, 96)
	var tell := pose == "tell"
	var dy := -3.0 if tell else 0.0
	var gx := 3.0 if tell else 0.0
	# Humo de la chimenea (detrás).
	r.begin(false)
	var puff := [Vector2(81, 10), Vector2(86, 5), Vector2(83, 1), Vector2(90, 2)]
	var pr := [4.2, 3.4, 2.4, 1.8]
	for i in puff.size():
		r.ellipse(puff[i] + Vector2(gx, dy * (1.0 + i)), pr[i], pr[i] * 0.85, "smoke", 0.0, 0.0, 0, Vector2.ZERO, 0.8)
	# Brazo lejano.
	r.begin()
	r.capsule(Vector2(74, 40) + Vector2(gx, dy), Vector2(84, 56), 8.0, 7.0, "brick", 0.25)
	r.begin()
	r.ellipse(Vector2(84, 61), 7.5, 6.5, "coal", 0.15, 4.0, 51)
	r.ellipse(Vector2(83, 70), 8.0, 6.5, "coal", 0.15, 4.0, 52)
	r.ellipse(Vector2(83, 79), 9.0, 6.5, "coal", 0.12, 4.0, 11)
	# Pierna lejana.
	r.begin()
	r.ellipse(Vector2(70, 66), 8.0, 6.5, "coal", 0.12, 4.0, 23)
	r.ellipse(Vector2(71, 76), 7.5, 6.0, "coal", 0.12, 4.0, 29)
	r.ellipse(Vector2(72, 84), 9.0, 5.0, "coal", 0.12, 4.0, 5)
	# Torso: horno de ladrillo encorvado (joroba alta detrás, pecho hundido delante).
	r.begin()
	r.ellipse(Vector2(62, 44) + Vector2(gx, dy), 25.0, 22.0, "brick", 0.0, 0.0, 0, Vector2.ZERO, 0.7)
	r.ellipse(Vector2(71, 31) + Vector2(gx, dy), 16.0, 14.0, "brick", 0.0, 0.0, 0, Vector2.ZERO, 0.7)
	# Hollín: la mitad baja del horno está ennegrecida (gradiente por material, no por color plano).
	for y in range(52, 68):
		for x in range(38, 90):
			var i: int = r.at(x, y + int(dy))
			if i >= 0 and r.mat[i] == r.mat_idx["brick"] and r._h2(x, y, 3) < float(y - 50) / 18.0:
				r.mat[i] = r.mat_idx["coal"]
	for y in range(8, 40):
		for x in range(50, 96):
			var i2: int = r.at(x, y + int(dy))
			if i2 >= 0 and r.mat[i2] == r.mat_idx["brick"] and absf(x - 80.0 - (y - 8) * 0.15) < 8.0 - (y - 8) * 0.22 + 1.5 * sin(y * 0.9):
				r.mat[i2] = r.mat_idx["coal"]
	# Chimenea en la joroba.
	r.begin()
	var ch := Vector2(80, 19) + Vector2(gx, dy)
	r.poly(PackedVector2Array([ch + Vector2(-5, 0), ch + Vector2(5, 0), ch + Vector2(4, -9), ch + Vector2(-4, -9)]), "brick", Vector3(-0.2, 0, 1), 1.5)
	r.poly(PackedVector2Array([ch + Vector2(-6, -9), ch + Vector2(6, -9), ch + Vector2(6, -12), ch + Vector2(-6, -12)]), "iron", Vector3(0, -0.4, 1), 1.0)
	r.stamp(["hHHh"], Vector2i(int(ch.x - 2), int(ch.y - 12)), {"h": ["hot", 2], "H": ["hot", 3 if not tell else 4]})
	# Aros de hierro remachados (siguen la curvatura del cuerpo).
	r.begin()
	for band: Array in [[31.0, 0.008], [46.0, 0.006]]:
		for x in range(40, 90):
			var yy: float = band[0] + dy + float(band[1]) * pow(x - 66.0, 2.0)
			var nx := (x + 0.5 - (62.0 + gx)) / 25.0
			var ny := (yy - (44.0 + dy)) / 22.0
			if nx * nx + ny * ny > 0.93:
				continue
			for t in 3:
				var tone := 3 if t == 0 else (1 if t == 1 else 0)
				r.pix(x, int(yy) + t, "iron", tone)
			if x % 6 == 0:
				r.pix(x, int(yy) + 1, "iron", 4)
	# Puerta del horno en el vientre: la boca de fuego que telegrafía el golpe.
	r.begin()
	var dc := Vector2(62, 54) + Vector2(gx, dy)
	r.poly(PackedVector2Array([dc + Vector2(-8, -6), dc + Vector2(7, -7), dc + Vector2(8, 6), dc + Vector2(-7, 7)]), "iron", Vector3(-0.3, -0.1, 1), 1.6)
	var heat := 4 if tell else 3
	r.stamp([
		"..hhhhhhh..",
		".hHkHHkHHh.",
		"hHHkHWkHHHh",
		"hHHkWWkHHhh",
		".hhkHHkHhh.",
		"..hhhhhhh..",
	], Vector2i(int(dc.x) - 5, int(dc.y) - 3), {"h": ["hot", heat - 2], "H": ["hot", heat - 1], "W": ["hot", heat], "k": ["iron", 0]})
	# Pierna cercana (corta, tronco de carbón).
	r.begin()
	r.ellipse(Vector2(52, 67), 8.5, 6.5, "coal", 0.0, 4.0, 13)
	r.ellipse(Vector2(50, 76), 8.0, 6.0, "coal", 0.0, 4.0, 17)
	r.line(Vector2(47, 71), Vector2(54, 72), "hot", 1)
	r.ellipse(Vector2(48, 84), 10.5, 5.0, "coal", 0.0, 4.0, 9)
	# Brazo cercano: hombro de ladrillo, aro de hierro, antebrazo de carbón, puño enorme.
	# Reposo: nudillos apoyados (gorila). Telegrafía: puño alzado sobre la cabeza, horno al blanco.
	r.begin()
	var sh := Vector2(46, 40) if not tell else Vector2(52, 35)
	var el := Vector2(31, 56) if not tell else Vector2(48, 20)
	var fist := Vector2(22, 80) if not tell else Vector2(38, 9)
	r.capsule(sh, el, 9.5, 8.0, "brick", 0.0)
	r.begin()
	r.capsule(el + Vector2(1, -1), el + Vector2(-1, 2), 8.6, 8.6, "iron", 0.0)
	r.pix(int(el.x - 6), int(el.y - 3), "iron", 4)
	r.pix(int(el.x - 3), int(el.y - 6), "iron", 4)
	r.begin()
	var fd := (fist - el).normalized()
	for k in 3:
		var cc := el.lerp(fist - fd * 5.0, (k + 0.5) / 3.0)
		r.ellipse(cc, 7.5 + k, 6.5 + k * 0.5, "coal", 0.0, 4.0, 40 + k)
	r.begin()
	r.ellipse(fist, 11.5, 8.0, "coal", 0.0, 4.0, 4)
	r.stamp(["h.h.h", "HhHhH"], Vector2i(int(fist.x) - 9, int(fist.y) - 2), {"h": ["hot", 1], "H": ["hot", 2 if not tell else 4]})
	var cr := el.lerp(fist, 0.4)
	r.line(cr + Vector2(-1, -3), cr + Vector2(-4, 3), "hot", 2)
	r.pix(int(cr.x - 5), int(cr.y + 4), "hot", 1)
	# Cabeza: bloque de carbón facetado, hundido entre los hombros, bajo una visera de ladrillo.
	r.begin()
	var hc := Vector2(32, 36) + Vector2(gx * 2, dy * 1.5)
	r.ellipse(hc, 10.5, 9.0, "coal", 0.0, 4.0, 21)
	r.begin()
	r.poly(PackedVector2Array([hc + Vector2(-11, -5), hc + Vector2(7, -10), hc + Vector2(11, -4), hc + Vector2(-9, -1)]), "brick", Vector3(-0.2, -0.6, 1), 1.4)
	# Ojos de brasa hundidos + mandíbula de rejilla.
	r.begin(false)
	r.stamp([
		"kkkkk..kkkk",
		"kWEek..kEek",
		".kkk....kk.",
	], Vector2i(int(hc.x) - 8, int(hc.y) - 1), {"k": ["coal", 0], "W": ["hot", 4], "E": ["hot", 3], "e": ["hot", 1]})
	r.stamp([
		"kWkWkWkWk",
		"khkhkhkhk",
	], Vector2i(int(hc.x) - 8, int(hc.y) + 4), {"k": ["coal", 0], "W": ["hot", 3 if tell else 2], "h": ["hot", 1]})
	r.line(hc + Vector2(5, -4), hc + Vector2(8, 2), "hot", 1)
	# Goteo de hollín (rasgo vivo en reposo: cae una gota cada ~1,2 s).
	r.begin(false)
	r.pix(57, 72, "coal", 2)
	r.pix(57, 73, "coal", 1)
	return r.render()


# ---------------------------------------------------------------------------------------------
# BOCETO DE SILUETA — EL CARBONERO (jefe acto 1). 320×250 dentro del lienzo 640×360.
# Gigante encorvado cuya espalda ES una carbonera (montículo de leña cubierto de tierra que humea).
func carbonero_sketch() -> Dictionary:
	new_rig(320, 250)
	r.light = Vector3(-0.85, -0.35, 0.4).normalized()
	r.thresholds = [0.45, 0.6, 0.72, 0.86]
	var Z := 1.4
	r.begin(false)
	for p: Array in [[196, 20, 10], [210, 10, 8], [222, 4, 6], [150, 30, 7], [160, 18, 6], [250, 44, 7], [262, 32, 5]]:
		r.ellipse(Vector2(p[0], p[1]), p[2], p[2] * 0.8, "smoke", 0.0, 0.0, 0, Vector2.ZERO, Z)
	# Brazo lejano con la pala (detrás).
	r.begin()
	r.capsule(Vector2(230, 120), Vector2(262, 170), 16, 13, "sk_body", 0.15, Z)
	r.capsule(Vector2(262, 170), Vector2(250, 214), 13, 11, "sk_body", 0.15, Z)
	r.begin()
	r.capsule(Vector2(238, 40), Vector2(256, 240), 3, 3, "sk_body", 0.1)
	r.poly(PackedVector2Array([Vector2(246, 222), Vector2(270, 222), Vector2(272, 246), Vector2(244, 246)]), "sk_body", Vector3(0, 0, 1), 2.0)
	# Piernas cortas como tocones.
	r.begin()
	r.capsule(Vector2(220, 190), Vector2(226, 236), 18, 16, "sk_body", 0.1, Z)
	r.capsule(Vector2(170, 190), Vector2(160, 236), 18, 16, "sk_body", 0.0, Z)
	# El montículo-carbonera (espalda) con respiraderos encendidos.
	r.begin()
	r.ellipse(Vector2(205, 108), 70, 72, "sk_mound", 0.0, 9.0, 3, Vector2.ZERO, Z)
	r.ellipse(Vector2(180, 150), 52, 44, "sk_body", 0.0, 0.0, 0, Vector2.ZERO, Z)
	r.begin(false)
	for v: Array in [[196, 46], [232, 70], [162, 62], [248, 112], [214, 96], [180, 92], [258, 150]]:
		r.ellipse(Vector2(v[0], v[1]), 4.5, 3.0, "sk_fire", 0.0)
		r.pix(v[0], v[1] - 1, "sk_fire", 4)
	# Cabeza bajo un sombrero de ala ancha; sólo dos ojos.
	r.begin()
	r.ellipse(Vector2(124, 100), 18, 17, "sk_body", 0.0, 0.0, 0, Vector2.ZERO, Z)
	r.begin()
	r.ellipse(Vector2(124, 86), 34, 7, "sk_body", 0.0, 0.0, 0, Vector2.ZERO, Z)
	r.ellipse(Vector2(128, 74), 16, 13, "sk_body", 0.0, 0.0, 0, Vector2.ZERO, Z)
	r.begin(false)
	r.stamp(["WW....WW", "ww....ww"], Vector2i(112, 98), {"W": ["sk_fire", 4], "w": ["sk_fire", 2]})
	# Brazo cercano: largo, la mano abierta hacia la heroína (agarre = telegrafía de "Hollín ×3").
	r.begin()
	r.capsule(Vector2(158, 130), Vector2(118, 170), 17, 14, "sk_body", 0.0, Z)
	r.capsule(Vector2(118, 170), Vector2(84, 196), 14, 12, "sk_body", 0.0, Z)
	r.ellipse(Vector2(74, 204), 16, 13, "sk_body", 0.0, 0.0, 0, Vector2.ZERO, Z)
	for f: Array in [[60, 192, 50, 214], [64, 200, 54, 224], [72, 208, 66, 232], [84, 210, 84, 230]]:
		r.capsule(Vector2(f[0], f[1]), Vector2(f[2], f[3]), 4, 2, "sk_body", 0.0, Z)
	r.begin(false)
	r.stamp(["ff", "Ff"], Vector2i(70, 202), {"f": ["sk_fire", 1], "F": ["sk_fire", 3]})
	# Heroína a escala (silueta de 66 px) para medir presencia.
	r.begin()
	r.capsule(Vector2(20, 196), Vector2(20, 218), 7, 6, "sk_hero", 0.0, Z)
	r.ellipse(Vector2(21, 188), 6, 6.5, "sk_hero", 0.0, 0.0, 0, Vector2.ZERO, Z)
	r.ellipse(Vector2(16, 180), 3, 3, "sk_hero", 0.0)
	r.capsule(Vector2(18, 218), Vector2(15, 246), 4, 3, "sk_hero", 0.0, Z)
	r.capsule(Vector2(24, 218), Vector2(27, 246), 4, 3, "sk_hero", 0.0, Z)
	r.capsule(Vector2(26, 204), Vector2(32, 232), 1.5, 1.5, "sk_hero", 0.0)
	r.poly(PackedVector2Array([Vector2(26, 228), Vector2(40, 228), Vector2(40, 236), Vector2(26, 236)]), "sk_hero", Vector3(0, 0, 1), 1)
	return r.render()


func scene_mock(hero: Image, golem: Image, boss: Image) -> void:
	# Mock de escena 640×360 (nuevo lienzo del mundo) ampliado ×2 = 1280×720 real.
	var img := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in 360:
		var t := float(y) / 360.0
		var c := Color("2a1e22").lerp(Color("140c10"), t)
		if y > 236:
			c = Color("2c2024").lerp(Color("181014"), (y - 236) / 124.0)
		for x in 640:
			img.set_pixel(x, y, c)
	img.blend_rect(hero, Rect2i(0, 0, 96, 96), Vector2i(150, 236 - 89))
	img.blend_rect(golem, Rect2i(0, 0, 112, 96), Vector2i(380, 236 - 90))
	Rig.up(img, 2).save_png(OUT + "mock_combate_1280.png")
	var img2 := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in 360:
		var c := Color("2a1e22").lerp(Color("140c10"), float(y) / 360.0)
		if y > 236:
			c = Color("2c2024")
		for x in 640:
			img2.set_pixel(x, y, c)
	img2.blend_rect(boss, Rect2i(0, 0, 320, 250), Vector2i(300, 236 - 246))
	img2.blend_rect(hero, Rect2i(0, 0, 96, 96), Vector2i(150, 236 - 89))
	Rig.up(img2, 2).save_png(OUT + "mock_jefe_1280.png")
