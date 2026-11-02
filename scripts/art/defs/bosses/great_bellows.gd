extends RefCounted
## EL GRAN FUELLE (`great_bellows`, jefe del acto 1) — PER · F2-JEFE, motor de rig v1.
## Concepto: el fuelle de la forja mayor, un fuelle de palanca DE VERDAD que ha echado a andar. Dos tablas de roble en
## pera, cuero plegado entre ellas, cabezal herrado con dos brasas por ojos y tobera de cobre por hocico. Va montado en un
## caballete de hierro de patas de garra; de su lomo sale el poste con el balancín, la cadena que levanta la tabla y el
## contrapeso de piedra colgado al otro lado (la «cola»). Dentro arde la forja: se ve por las juntas del cuero.
## Silueta: horca alta (poste + balancín) sobre una cuña horizontal con hocico hacia la heroína. ≈ 200 px de alto y ≈ 230 de
## ancho en un lienzo de 340×204; suelo y = 196; mira a la izquierda.
## Partes animadas (7): caballete y patas · tabla inferior + cabezal (cabeza) · tabla superior (tapa) · cuero en 4 pliegues ·
## tobera · balancín con cadena (mecanismo resuelto como varillaje real: la cadena mide siempre lo mismo) · contrapeso.
## Fase 2 (variante `phase2`): tapa reventada por detrás, cuero roto con el fuego al aire y llamas sobre la tapa, contrapeso
## caído al suelo con la cadena rota, grietas al rojo en la tabla inferior y ojos al blanco. Misma caja, otra silueta.
## Animaciones: idle (respira: los pliegues se abren y cierran, la tobera bufa) · cast (telegrafía/gesto: inspira hondo) ·
## attack (inspira, cierra de golpe y escupe un chorro de fuego avanzando 9 px; impacto en el fotograma 2) · hurt ·
## summon (soplo que expulsa dos ácaros-vela) · choke (nube de hollín) · death (revienta la tapa, el caballete cede y
## queda un montón de tablas y hierros con la forja apagándose).

const HINGE := Vector2(-58, -78)     # bisagra de las tablas (espacio de la raíz)
const RING := Vector2(78, -44)       # argolla de la tapa (espacio de la tapa)
const POST_FOOT := Vector2(76, 0)
const POST_H := 170.0
const ARM_L := 68.0                  # brazo del balancín hacia la tapa
const ARM_R := 24.0                  # brazo del contrapeso
const ROD := 32.0                    # largo fijo de la cadena de la tapa
const CHAIN_LINKS := 8
const PLEATS := 4
const LEG_Y := -64.0                 # altura de la cuna (arranque de las patas)
const TH0 := 0.1                     # apertura mínima de la cámara: en reposo los pliegues se ven abiertos


# --------------------------------------------------------------------------------------------- texturas
static func _wood_top(l: Vector2, st: int, n: int) -> int:
	# Tablas a lo largo (vetas cada 5 px en luz media), un paso más claras que el canto: la cara mira arriba.
	st = mini(st + 1, n - 2)
	if st >= 3 and st <= n - 3 and fposmod(l.y, 5.0) < 1.0:
		return st - 1
	return st


static func _wood_edge(l: Vector2, st: int, _n: int) -> int:
	# Canto de la tabla: un paso más oscuro, con la junta de las dos tablas a media altura.
	st = maxi(1, st - 1)
	if st >= 3 and absf(l.y + 4.0) < 0.5:
		return st - 1
	return st


static func _leather(l: Vector2, st: int, n: int) -> int:
	# Cuero en rollos: cada pliegue enseña su mitad baja bajo el de encima. Sombra justo debajo del rollo de arriba
	# (−2), cara iluminada en medio y el canto que se mete por debajo (−1). Costura de 1 px cada 3 en la cara.
	var s := clampi(st, 2, n - 3)
	if l.x < 24.0:
		return s
	var v := l.y / maxf(1.0, 0.7 + (l.x - 10.0) * 9.3 / 126.0)
	if v < 0.25:
		return s - 2
	if v > 0.72:
		return s - 1
	if l.x > 120.0 and l.x < 140.0 and fposmod(l.x, 3.0) < 1.0 and absf(v - 0.48) < 0.08:
		return s - 1
	return s


static func _stone(l: Vector2, st: int, _n: int) -> int:
	if st >= 3 and (fposmod(l.x + l.y * 0.5, 7.0) < 1.0 and fposmod(l.y, 6.0) < 3.0):
		return st - 1
	return st


# --------------------------------------------------------------------------------------------- generadores de sellos
## Llamas de abajo arriba: lenguas que suben 1 px por fotograma y núcleo claro abajo (§5 Fuego).
static func _flames(w: int, h: int, f: int) -> Array:
	var rows: Array = []
	var hts: Array[int] = []
	for x in w:
		var env := 1.0 - absf(x - (w - 1) * 0.5) / (w * 0.5 + 0.5)
		var wave := 0.55 + 0.3 * sin(x * 1.7 + f * 2.1) + 0.15 * sin(x * 0.6 - f * 1.3)
		hts.append(clampi(int(round(h * (0.25 + 0.75 * env) * wave)), 1, h))
	for y in h:
		var r := ""
		for x in w:
			var d := h - 1 - y
			if d >= hts[x]:
				r += "."
				continue
			var t := float(d) / float(hts[x])
			r += "Y" if t < 0.3 else ("W" if t < 0.55 else ("F" if t < 0.8 else "f"))
		rows.append(r)
	return rows


## Chorro horizontal de la tobera (la boca a la derecha, la punta a la izquierda).
static func _jet(w: int, h: int, f: int) -> Array:
	var rows: Array = []
	var mid := (h - 1) * 0.5
	for y in h:
		var r := ""
		for x in w:
			var u := float(x) / float(w - 1)          # 0 punta · 1 boca
			var half := (h * 0.5) * sin(PI * clampf(0.15 + u * 0.95, 0.0, 1.0)) * (0.8 + 0.2 * sin(x * 0.9 + f * 2.0))
			var d := absf(y - mid)
			if d > half or (u < 0.25 and fposmod(x + y + f, 3.0) == 0.0):
				r += "."
				continue
			var t := d / maxf(0.5, half)
			r += "Y" if t < 0.3 and u > 0.3 else ("W" if t < 0.55 else ("F" if t < 0.85 else "f"))
		rows.append(r)
	return rows


const MITE := ["...F...", "..FfF..", "...f...", "..www..", ".wWWw..", ".wWwwk.", "sssssss", "s.s.s.s"]
const MITE_LEG := {"F": [&"fire", 5], "f": [&"fire", 6], "w": [&"linen", 3], "W": [&"linen", 5], "s": [&"leather", 2], "k": [&"hot", 4]}
const FIRE_LEG := {"f": [&"fire", 2], "F": [&"fire", 4], "W": [&"fire", 5], "Y": [&"fire", 6]}


# --------------------------------------------------------------------------------------------- definición
static func build() -> RigDef:
	var b := RigBuilder.new(&"great_bellows", Vector2i(340, 204), Vector2i(206, 196), -1, &"bosses")
	b.material(&"wood", &"wood", {"tex_fn": _wood_top})
	b.material(&"wood_e", &"wood", {"tex_fn": _wood_edge})
	b.material(&"leather", &"leather", {"tex_fn": _leather})
	b.material(&"iron", &"iron", {"spec": true, "tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return mini(st, 5)})
	b.material(&"copper", &"copper", {"spec": true, "tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return clampi(st - 1, 1, 6)})
	b.material(&"brass", &"brass", {"spec": true, "tex_fn": func(_l: Vector2, st: int, _n: int) -> int: return clampi(st - 1, 1, 3)})
	b.material(&"stone", &"stone", {"tex_fn": _stone})
	b.material(&"fire", &"fire")
	b.material(&"hot", &"hot")
	b.material(&"smoke", &"smoke", {"rim": false})
	b.material(&"soot", &"soot", {"rim": false})

	# --- esqueleto
	b.bone(&"root", &"", Vector2.ZERO)
	b.bone(&"frame", &"root", Vector2.ZERO)
	b.bone(&"leg_ff", &"frame", Vector2(-44, LEG_Y), {"z": -14.0})
	b.bone(&"leg_bf", &"frame", Vector2(50, LEG_Y), {"z": -14.0})
	b.bone(&"post", &"frame", POST_FOOT, {"z": -10.0})
	b.bone(&"beam", &"post", Vector2(0, -POST_H), {"z": 2.0})
	b.bone(&"cw", &"beam", Vector2(ARM_R, 0), {"z": -2.0})
	b.bone(&"body", &"frame", HINGE)
	for i in PLEATS:
		b.bone(StringName("pleat_%d" % i), &"body", Vector2.ZERO)
	b.bone(&"lid", &"body", Vector2.ZERO)
	b.bone(&"rod", &"lid", RING, {"z": 6.0})
	b.bone(&"head", &"body", Vector2.ZERO, {"z": 2.0})
	b.bone(&"nozzle", &"head", Vector2(-34, 4))
	b.bone(&"puff", &"nozzle", Vector2(-30, 4), {"z": 4.0})
	b.bone(&"leg_fn", &"frame", Vector2(-52, LEG_Y), {"z": 8.0})
	b.bone(&"leg_bn", &"frame", Vector2(58, LEG_Y), {"z": 8.0})
	b.bone(&"fly", &"root", Vector2(40, -150), {"z": 20.0})

	# --- poste, balancín y contrapeso (detrás)
	b.cap(&"post_bar", &"post", &"iron", Vector3(0, -2, 0), Vector3(0, -POST_H + 2, 0), 3.5, 3.0, {"ao": 1.3})
	b.poly(&"post_foot", &"post", &"iron", PackedVector2Array([Vector2(-10, 0), Vector2(-7, -5), Vector2(-3, -15), Vector2(3, -15),
		Vector2(7, -5), Vector2(10, 0)]), 2.0, 1.5, 2.0)
	b.box(&"post_fork", &"post", &"iron", Vector3(0, -POST_H + 1, 2), Vector3(10, 9, 6), 1.5)
	b.cap(&"beam_bar", &"beam", &"wood_e", Vector3(-ARM_L, 0, 3), Vector3(ARM_R + 2, 0, 3), 3.0, 3.5)
	b.box(&"beam_cap_l", &"beam", &"iron", Vector3(-ARM_L + 2, 0, 5), Vector3(6, 8, 4), 1.0)
	b.box(&"beam_cap_r", &"beam", &"iron", Vector3(ARM_R, 0, 5), Vector3(6, 9, 4), 1.0)
	b.stamp(&"beam_pin", &"beam", Vector2(0, 0), [".5.", "565", ".6."], {"5": [&"iron", 8], "6": [&"iron", 3]}, {"anchor": Vector2i(1, 1)})
	for i in 4:
		b.stamp(StringName("beam_riv_%d" % i), &"beam", Vector2([-ARM_L + 1, -ARM_L + 3, ARM_R - 1, ARM_R + 1][i], [-2, 2, -2, 2][i]), ["5"],
			{"5": [&"iron", 9]}, {"z_top": false})
	b.stamp(&"strut_riv", &"post", Vector2(-1, -108), ["5", "6"], {"5": [&"iron", 8], "6": [&"iron", 2]})
	# cadena del contrapeso (entera en la fase 1; rota y colgando en la fase 2)
	for i in 8:
		b.stamp(StringName("cw_link_%d" % i), &"cw", Vector2(0, 3 + i * 4), ([".7.", "7.7", "7.7"] if i % 2 == 0 else ["7", "4", "4", "7"]),
			{"7": [&"iron", 7], "4": [&"iron", 4]}, {"anchor": Vector2i(1 if i % 2 == 0 else 0, 0), "accessory": &"whole"})
	for i in 3:
		b.stamp(StringName("cw_snap_%d" % i), &"cw", Vector2(0, 3 + i * 4), ([".7.", "7.7", "7.7"] if i % 2 == 0 else ["7", "4", "4", "7"]),
			{"7": [&"iron", 7], "4": [&"iron", 4]}, {"anchor": Vector2i(1 if i % 2 == 0 else 0, 0), "accessory": &"broken"})
	b.stamp(&"cw_snap_end", &"cw", Vector2(0, 15), ["7.", ".4"], {"7": [&"iron", 6], "4": [&"iron", 3]}, {"accessory": &"broken"})
	# contrapeso: piedra de molino tallada en bloque, zunchada de hierro, con argolla
	b.poly(&"weight", &"cw", &"stone", PackedVector2Array([Vector2(-9, 35), Vector2(9, 35), Vector2(14, 41), Vector2(14, 62), Vector2(10, 67),
		Vector2(-10, 67), Vector2(-14, 62), Vector2(-14, 41)]), 4.0, 3.0, 4.0, {"accessory": &"whole"})
	b.poly(&"weight_band", &"cw", &"iron", PackedVector2Array([Vector2(-15, 48), Vector2(15, 48), Vector2(15, 54), Vector2(-15, 54)]), 7.0, 1.0, 2.0, {"accessory": &"whole"})
	b.stamp(&"weight_ring", &"cw", Vector2(0, 33), [".777.", "7...7"], {"7": [&"iron", 7]}, {"anchor": Vector2i(2, 0), "accessory": &"whole"})
	b.stamp(&"weight_riv", &"cw", Vector2(-12, 50), ["5.....5.....5...5", "6.....6.....6...6"], {"5": [&"iron", 9], "6": [&"iron", 3]}, {"accessory": &"whole", "z_top": false})

	# --- caballete: patas de garra lejanas
	for s: String in ["ff", "bf"]:
		_leg(b, StringName("leg_" + s), -1.0 if s == "ff" else 1.0, 1.4)
	b.cap(&"stretcher", &"frame", &"iron", Vector3(-50, -28, -6), Vector3(58, -28, -6), 2.5, 2.5, {"ao": 1.2})
	b.cap(&"strut", &"frame", &"iron", Vector3(68, -64, -4), Vector3(75, -108, -4), 2.0, 2.0, {"ao": 1.2})
	b.box(&"cradle", &"frame", &"wood_e", Vector3(6, -66, 0), Vector3(134, 8, 10), 2.0)
	b.box(&"cradle_cap_l", &"frame", &"iron", Vector3(-58, -66, 3), Vector3(8, 10, 6), 1.0)
	b.box(&"cradle_cap_r", &"frame", &"iron", Vector3(70, -66, 3), Vector3(8, 10, 6), 1.0)
	b.stamp(&"cradle_riv", &"frame", Vector2(-60, -69), ["5" + ".".repeat(129) + "5", ".".repeat(131), "5" + ".".repeat(129) + "5"],
		{"5": [&"iron", 9]}, {"z_top": false})

	# --- cuerpo: forja interior (sólo se ve por las juntas y cuando el cuero revienta)
	b.poly(&"core", &"body", &"fire", PackedVector2Array([Vector2(24, -2), Vector2(130, -13), Vector2(134, -6), Vector2(130, 2), Vector2(24, 0)]),
		-8.0, 2.0, 1.0, {"line": false})
	b.poly(&"core_top", &"pleat_3", &"fire", PackedVector2Array([Vector2(60, -6), Vector2(126, -13), Vector2(132, 0), Vector2(126, 10), Vector2(60, 6)]),
		-8.0, 2.0, 1.0, {"line": false, "accessory": &"broken"})
	# cuero en pliegues: 4 cuñas que se reparten la apertura de la tapa (siempre tapan el hueco; las líneas de contacto son los pliegues)
	for i in PLEATS:
		var pb := StringName("pleat_%d" % i)
		var pts := PackedVector2Array([Vector2(10, -0.7), Vector2(136, -10), Vector2(144, -9), Vector2(150, -5), Vector2(152, 0),
			Vector2(150, 5), Vector2(144, 9), Vector2(136, 10), Vector2(10, 0.7)])
		if i == PLEATS - 1:
			b.poly(StringName("leather_%d" % i), pb, &"leather", pts, 0.0, 4.0, 4.0, {"z": i * 0.4, "accessory": &"whole"})
			b.poly(&"leather_torn", pb, &"leather", PackedVector2Array([Vector2(10, -0.7), Vector2(78, -5.5), Vector2(84, -1), Vector2(90, -5),
				Vector2(95, 0), Vector2(101, -2), Vector2(106, 4), Vector2(98, 7.5), Vector2(10, 0.7)]), 0.0, 4.0, 4.0, {"z": i * 0.4, "accessory": &"broken"})
		else:
			b.poly(StringName("leather_%d" % i), pb, &"leather", pts, 0.0, 4.0, 4.0, {"z": i * 0.4})
		if i < PLEATS - 1:
			# brasas por la junta con el pliegue de encima
			b.stamp(StringName("seam_%d" % i), pb, Vector2(118 + i * 3, -7), ["hHh", ".h."] if i % 2 == 0 else [".hHHh", "h..h."],
				{"h": [&"hot", 2], "H": [&"hot", 3]}, {"anchor": Vector2i(1, 0)})
	# tabla inferior y sus zunchos
	b.poly(&"board_lo", &"body", &"wood_e", PackedVector2Array([Vector2(0, 0), Vector2(140, 0), Vector2(146, 4), Vector2(144, 10),
		Vector2(137, 12), Vector2(4, 12), Vector2(0, 8)]), 4.0, 2.0, 4.0)
	for x: int in [44, 98]:
		b.poly(StringName("strap_lo_%d" % x), &"body", &"iron", PackedVector2Array([Vector2(x, -1), Vector2(x + 5, -1), Vector2(x + 5, 13),
			Vector2(x, 13)]), 8.0, 1.0, 1.5)
		b.stamp(StringName("strap_lo_riv_%d" % x), &"body", Vector2(x + 2, 2), ["5", "6", ".", ".", "5", "6"], {"5": [&"iron", 9], "6": [&"iron", 3]})
	b.stamp(&"cracks_lo", &"body", Vector2(20, 2), [
		"..h.........H........h....hH.........",
		".hH........hH.......hH.....H....h....",
		"hH..........Hh.......H......hH.hH....",
		"..............h.............h........",
	], {"h": [&"hot", 2], "H": [&"hot", 4]}, {"accessory": &"broken", "z_top": false})

	# --- tapa (tabla superior): canto + cara en pera vista desde arriba, zunchos, argolla
	b.poly(&"lid_face", &"lid", &"wood", PackedVector2Array([Vector2(2, -10), Vector2(144, -10), Vector2(148, -20), Vector2(144, -34),
		Vector2(132, -44), Vector2(112, -48), Vector2(84, -45), Vector2(54, -36), Vector2(24, -24), Vector2(6, -14)]), 3.0, 2.0, 3.0,
		{"accessory": &"whole"})
	b.poly(&"lid_face_broken", &"lid", &"wood", PackedVector2Array([Vector2(2, -10), Vector2(132, -10), Vector2(134, -14), Vector2(128, -17),
		Vector2(124, -26), Vector2(118, -20), Vector2(112, -34), Vector2(105, -26), Vector2(100, -46), Vector2(84, -45), Vector2(54, -36),
		Vector2(24, -24), Vector2(6, -14)]), 3.0, 2.0, 3.0, {"accessory": &"broken"})
	b.poly(&"lid_edge", &"lid", &"wood_e", PackedVector2Array([Vector2(2, -10), Vector2(141, -10), Vector2(146, -6), Vector2(143, 0),
		Vector2(4, 0), Vector2(0, -4)]), 5.0, 2.0, 4.0, {"accessory": &"whole"})
	b.poly(&"lid_edge_broken", &"lid", &"wood_e", PackedVector2Array([Vector2(2, -10), Vector2(133, -10), Vector2(130, -6), Vector2(136, -3),
		Vector2(132, 0), Vector2(4, 0), Vector2(0, -4)]), 5.0, 2.0, 4.0, {"accessory": &"broken"})
	b.poly(&"lid_strap_a", &"lid", &"iron", PackedVector2Array([Vector2(75, 0), Vector2(81, 0), Vector2(82, -42), Vector2(76, -42)]), 8.0, 1.0, 1.5)
	b.poly(&"lid_strap_b", &"lid", &"iron", PackedVector2Array([Vector2(106, 0), Vector2(111, 0), Vector2(112, -47), Vector2(107, -47)]), 8.0, 1.0, 1.5,
		{"accessory": &"whole"})
	b.stamp(&"lid_riv", &"lid", Vector2(77, -37), ["5...", "6...", "....", "....", "....", "..5.", "..6.", "....", "....", "....", "5...", "6...",
		"....", "....", "....", "..5.", "..6."],
		{"5": [&"iron", 9], "6": [&"iron", 3]})
	b.stamp(&"lid_riv_b", &"lid", Vector2(108, -42), ["5", "6", ".", ".", ".", ".", ".", "5", "6", ".", ".", ".", ".", "5", "6", ".", ".", ".", ".", ".", "5", "6"],
		{"5": [&"iron", 9], "6": [&"iron", 3]}, {"accessory": &"whole"})
	b.stamp(&"ring", &"lid", RING, [".777.", "7...7", "7...7"], {"7": [&"iron", 7]}, {"anchor": Vector2i(2, 2)})
	for f in 4:
		b.stamp(StringName("lid_fire_%d" % f), &"lid", Vector2(100, -8), _flames(44, 40, f), FIRE_LEG,
			{"anchor": Vector2i(0, 39), "accessory": &"broken"})
	# cadena de la tapa al balancín (eslabones a lo largo de su hueso: siguen la cadena sin rotar píxeles)
	for i in CHAIN_LINKS:
		b.stamp(StringName("rod_link_%d" % i), &"rod", Vector2(0, -3 - i * 4), ([".7.", "7.7", ".4."] if i % 2 == 0 else ["7", "4"]),
			{"7": [&"iron", 7], "4": [&"iron", 3]}, {"anchor": Vector2i(1 if i % 2 == 0 else 0, 1)})

	# --- cabezal (la cabeza): bloque herrado con ceño y dos brasas por ojos
	b.poly(&"headblock", &"head", &"wood_e", PackedVector2Array([Vector2(-36, -12), Vector2(-28, -27), Vector2(6, -36), Vector2(6, 22),
		Vector2(-28, 21), Vector2(-39, 9)]), 8.0, 3.0, 7.0, {"tags": [&"eye"]})
	b.poly(&"brow", &"head", &"iron", PackedVector2Array([Vector2(-42, -16), Vector2(-31, -30), Vector2(7, -41), Vector2(7, -31),
		Vector2(-17, -21), Vector2(-40, -10)]), 15.0, 1.5, 2.0)
	b.poly(&"jaw_band", &"head", &"iron", PackedVector2Array([Vector2(-38, 10), Vector2(7, 10), Vector2(7, 18), Vector2(-30, 22)]), 15.0, 1.0, 2.0)
	b.stamp(&"head_riv", &"head", Vector2(-30, 13), ["5.......5.......5.......5.......5", "6.......6.......6.......6.......6"], {"5": [&"iron", 9], "6": [&"iron", 3]})
	b.stamp(&"brow_riv", &"head", Vector2(-30, -24), ["5............", "6............", "......5......", "......6.....5", "............6"], {"5": [&"iron", 9], "6": [&"iron", 3]})
	var eyes := {&"open": [
		"kkkk................",
		"kkkkkkkk......kkkkk.",
		"khWWWWWHk....kHWWWk.",
		"kHWYYYYWk....kWYYWk.",
		".kHWYYWHk....kHYWHk.",
		"..kHWWHk.....kkHHk..",
		"...khhk.......kkk...",
		"....kk..............",
	], &"wide": [
		"kkkk................",
		"kHWWWWWHk....kHWWWk.",
		"kWYYYYYWk....kWYYYk.",
		"kWYYYYYWk....kWYYYk.",
		".kWYYYWHk....kWYYWk.",
		"..kHWWHk.....kHWHk..",
		"...khhk.......khk...",
		"....kk.........k....",
	], &"squint": [
		"....................",
		"kkkk................",
		"kkkkkkkkk....kkkkkk.",
		"khHHHHHhk....khHHhk.",
		".kkkkkkk......kkkk..",
		"....................",
		"....................",
		"....................",
	], &"dead": [
		"....................",
		"....................",
		"....................",
		"kkkkkkkkk....kkkkkk.",
		"....................",
		"....................",
		"....................",
		"....................",
	]}
	var eye_leg := {"k": [&"iron", "LINE"], "h": [&"hot", 2], "H": [&"hot", 4], "W": [&"hot", 5], "Y": [&"fire", 7]}
	b.stamp(&"eyes", &"head", Vector2(-37, -14), eyes[&"open"], eye_leg, {"views": eyes, "accessory": &"whole"})
	var eyes2 := eyes.duplicate()
	eyes2[&"open"] = eyes[&"wide"]
	b.stamp(&"eyes2", &"head", Vector2(-37, -14), eyes[&"wide"], eye_leg, {"views": eyes2, "accessory": &"broken"})
	b.stamp(&"grill", &"head", Vector2(-27, 1), ["k.k.k.k.k.k.k", "hkHkWkWkWkHkh", "hkHkWkHkWkHkh", "hkhkHkhkHkhkh"], {"k": [&"iron", "LINE"], "h": [&"hot", 2], "H": [&"hot", 3]})

	# --- tobera de cobre (el hocico)
	b.cap(&"nozzle_tube", &"nozzle", &"copper", Vector3(0, 0, 8), Vector3(-28, 4, 8), 6.5, 3.6, {"flat": 0.3})
	b.cap(&"nozzle_ring_a", &"nozzle", &"brass", Vector3(-3, 0.4, 9), Vector3(-6, 0.9, 9), 7.2, 6.9, {"flat": 0.3})
	b.cap(&"nozzle_ring_b", &"nozzle", &"brass", Vector3(-23, 3.3, 9), Vector3(-25, 3.6, 9), 4.4, 4.2, {"flat": 0.3})
	var mouth := {&"g0": ["k", "H", "h"], &"g1": ["k", "W", "H"], &"g2": ["h", "H", "k"], &"g3": ["H", "W", "h"]}
	b.stamp(&"mouth", &"nozzle", Vector2(-30, 4), mouth[&"g0"], {"k": [&"hot", 1], "h": [&"hot", 2], "H": [&"hot", 3], "W": [&"hot", 5]},
		{"views": mouth, "anchor": Vector2i(0, 1)})

	# --- bocanadas, chorro, hollín y ácaros (en el hueso de la boca de la tobera)
	for i in 4:
		var r := 2.5 + i * 1.0
		b.ell(StringName("puff_%d" % i), &"puff", &"smoke", Vector3(-3 - i * 6, -1 - i * 3, 0), Vector3(r, r * 0.8, r), {"line": false, "flat": 0.4})
	var cl := [[-6, -1, 7, 6], [-17, -8, 11, 10], [-18, 6, 10, 9], [-34, -12, 15, 12], [-36, 7, 14, 11], [-54, -15, 17, 14], [-56, 6, 16, 12], [-42, -27, 13, 11]]
	for i in cl.size():
		var c: Array = cl[i]
		b.ell(StringName("soot_%d" % i), &"puff", &"soot", Vector3(c[0], c[1], 2 + i * 0.2), Vector3(c[2], c[3], c[2] * 0.6), {"line": false, "flat": 0.8})
	b.stamp(&"soot_sparks", &"puff", Vector2(-56, -18), ["h...............", "........h.......", "................", "............h...", "...h............", "................", "..........h.....", "......h........."],
		{"h": [&"hot", 3]})
	for f in 3:
		b.stamp(StringName("jet_%d" % f), &"puff", Vector2(1, 0), _jet([18, 34, 28][f], [5, 9, 7][f], f), FIRE_LEG,
			{"anchor": Vector2i([18, 34, 28][f] - 1, [2, 4, 3][f])})
	for m in 6:
		var mp: Vector2 = [Vector2(-6, -9), Vector2(-9, 1), Vector2(-24, -17), Vector2(-27, -3), Vector2(-42, -13), Vector2(-48, 4)][m]
		b.stamp(StringName("mite_%d" % m), &"puff", mp, MITE, MITE_LEG, {"anchor": Vector2i(3, 4)})

	# --- patas de garra cercanas (delante)
	for s: String in ["fn", "bn"]:
		_leg(b, StringName("leg_" + s), -1.0 if s == "fn" else 1.0, 1.0)

	# --- fase 2: el contrapeso en el suelo
	b.poly(&"weight_ground", &"frame", &"stone", PackedVector2Array([Vector2(88, 0), Vector2(90, -9), Vector2(96, -14), Vector2(108, -14),
		Vector2(114, -9), Vector2(114, 0)]), 6.0, 3.0, 4.0, {"accessory": &"broken"})
	b.poly(&"weight_ground_band", &"frame", &"iron", PackedVector2Array([Vector2(98, -14), Vector2(103, -14), Vector2(103, 0), Vector2(98, 0)]),
		9.0, 1.0, 2.0, {"accessory": &"broken"})

	# --- muerte: tapa volando, restos en el suelo (con @root = (0, 32): y local −32 = suelo)
	b.poly(&"fly_lid", &"fly", &"wood", PackedVector2Array([Vector2(-30, -4), Vector2(30, -6), Vector2(34, 0), Vector2(28, 5), Vector2(-32, 4)]),
		10.0, 2.0, 3.0)
	b.poly(&"fly_strap", &"fly", &"iron", PackedVector2Array([Vector2(-2, -6), Vector2(3, -6), Vector2(3, 5), Vector2(-2, 5)]), 13.0, 1.0, 1.5)
	b.poly(&"down_lid", &"root", &"wood", PackedVector2Array([Vector2(50, -32), Vector2(118, -32), Vector2(116, -37), Vector2(106, -41),
		Vector2(62, -39), Vector2(52, -36)]), 14.0, 2.0, 3.0)
	b.cap(&"down_post", &"root", &"iron", Vector3(20, -36, 2), Vector3(110, -44, 2), 3.0, 3.0, {"ao": 1.2})
	b.cap(&"down_beam", &"root", &"wood_e", Vector3(-6, -42, 4), Vector3(62, -34, 4), 3.0, 3.0)
	b.poly(&"down_weight", &"root", &"stone", PackedVector2Array([Vector2(96, -32), Vector2(98, -41), Vector2(104, -46), Vector2(116, -46),
		Vector2(122, -41), Vector2(122, -32)]), 6.0, 3.0, 4.0)
	for f in 3:
		b.stamp(StringName("burst_%d" % f), &"body", Vector2(30, -2), _flames(100, [34, 26, 14][f], f + 1), FIRE_LEG, {"anchor": Vector2i(0, [33, 25, 13][f])})
	b.stamp(&"embers_end", &"body", Vector2(36, -3), ["..h.....H......h....h.....H....h..", "hH..hH.hHh..hH..hH.hHh.hH..hHh..hH"],
		{"h": [&"hot", 1], "H": [&"hot", 2]})

	b.socket(&"hit", &"puff", Vector2(-4, 0))
	b.socket(&"intent", &"beam", Vector2(0, -12))
	b.socket(&"smoke", &"puff", Vector2(0, 0))
	b.socket(&"heart", &"body", Vector2(90, -10))
	_anims(b)
	b.variant(&"base", {&"whole": true})
	b.variant(&"phase2", {&"broken": true})
	return b.def


## Pata de hierro con pie de garra (tres dedos hacia fuera).
static func _leg(b: RigBuilder, bn: StringName, side: float, ao: float) -> void:
	# Pata de hierro gruesa en dos tramos (muslo de 15 px, caña de 12) con rodilla de bola y pie de garra ancho.
	var dx := 4.0 * side
	var kx := 11.0 * side
	b.cap(StringName("%s_bar" % bn), bn, &"iron", Vector3(0, 0, 0), Vector3(kx, 26, 0), 7.5, 6.0, {"ao": ao})
	b.cap(StringName("%s_shin" % bn), bn, &"iron", Vector3(kx, 26, 0), Vector3(dx, 54, 0), 6.0, 4.8, {"ao": ao})
	b.cap(StringName("%s_knee" % bn), bn, &"iron", Vector3(kx, 25, 2), Vector3(kx, 28, 2), 7.0, 7.0, {"ao": ao})
	b.poly(StringName("%s_paw" % bn), bn, &"iron", PackedVector2Array([Vector2(dx - 7 * side, 51), Vector2(dx + 4 * side, 51),
		Vector2(dx + 13 * side, 57), Vector2(dx + 15 * side, 64), Vector2(dx - 9 * side, 64), Vector2(dx - 10 * side, 57)]), 2.0, 1.5, 3.0, {"ao": ao})
	var claw := ["5.5.5.5", "6.6.6.6"]
	b.stamp(StringName("%s_claw" % bn), bn, Vector2(dx + (7.0 if side > 0 else -14.0), 62), claw, {"5": [&"iron", 8], "6": [&"iron", 1]},
		{"z_top": false})


# --------------------------------------------------------------------------------------------- poses
const FX := ["puff_0", "puff_1", "puff_2", "puff_3", "soot_0", "soot_1", "soot_2", "soot_3", "soot_4", "soot_5", "soot_6", "soot_7",
	"soot_sparks", "jet_0", "jet_1", "jet_2", "mite_0", "mite_1", "mite_2", "mite_3", "mite_4", "mite_5",
	"fly_lid", "fly_strap", "down_lid", "down_post", "down_beam", "down_weight", "burst_0", "burst_1", "burst_2", "embers_end"]
const LID := ["lid_face", "lid_face_broken", "lid_edge", "lid_edge_broken", "lid_strap_a", "lid_strap_b", "lid_riv", "lid_riv_b", "ring",
	"lid_fire_0", "lid_fire_1", "lid_fire_2", "lid_fire_3"]
const RIG_UP := ["post_bar", "post_foot", "post_fork", "beam_bar", "beam_cap_l", "beam_cap_r", "beam_pin", "beam_riv_0", "beam_riv_1",
	"beam_riv_2", "beam_riv_3", "strut_riv", "strut", "weight", "weight_band", "weight_ring", "weight_riv", "cw_snap_end", "weight_ground",
	"weight_ground_band"]


## Pose base: todo lo de efectos y muerte oculto; tapa, pliegues, balancín y cadena resueltos para una apertura `th`.
static func _pose(th: float, f: int, shift := 0, ba := 0.0) -> Dictionary:
	th += TH0
	var k := {}
	for id: String in FX:
		k[StringName("hide:" + id)] = true
	k[&"@root"] = Vector2i(shift, 0)
	# patas: los pies se quedan plantados cuando el cuerpo avanza o retrocede
	var la := -float(shift) / 50.0
	for l: String in ["leg_fn", "leg_ff", "leg_bn", "leg_bf"]:
		k[StringName(l)] = la
	k[&"post"] = la * 0.3
	_mech(k, th, ba, la * 0.3)
	# fuego vivo: nunca dos fotogramas iguales seguidos
	k[&"view:mouth"] = [&"g0", &"g1", &"g2", &"g3"][f % 4]
	for i in 4:
		k[StringName("hide:lid_fire_%d" % i)] = i != f % 4
	return k


static func _mech(k: Dictionary, th: float, ba: float, post: float) -> void:
	k[&"body"] = ba
	k[&"lid"] = -th
	for i in PLEATS:
		k[StringName("pleat_%d" % i)] = -th * (2 * i + 1) / (2.0 * PLEATS)
	# Varillaje: la argolla de la tapa tira de la cadena (largo fijo) y el balancín gira lo justo.
	var r := HINGE + RING.rotated(ba - th)
	var top := POST_FOOT + Vector2(0, -POST_H).rotated(post)
	var best := 0.0
	var err := 1e9
	for s in 601:
		var phi := -0.6 + s * 0.002
		var bl := top + Vector2(-ARM_L, 0).rotated(post + phi)
		var e := absf(bl.distance_to(r) - ROD)
		if e < err - 0.0001:
			err = e
			best = phi
	k[&"beam"] = best
	var bend := top + Vector2(-ARM_L, 0).rotated(post + best)
	var d := (bend - r).normalized()
	k[&"rod"] = atan2(d.x, -d.y) - (ba - th)
	k[&"cw"] = -(post + best)


static func _show(k: Dictionary, ids: Array) -> Dictionary:
	for id: String in ids:
		k[StringName("hide:" + id)] = false
	return k


static func _anims(b: RigBuilder) -> void:
	# Reposo 6 f: inspira despacio (la tapa sube, los pliegues se abren, el contrapeso baja) y espira con un bufido.
	var idle := {}
	var ths := [0.2, 0.27, 0.34, 0.38, 0.29, 0.21]
	var puffs := [[], [], [], [], ["puff_0"], ["puff_1", "puff_2"]]
	for f in 6:
		var k := _pose(ths[f], f)
		_show(k, puffs[f])
		k[&"emit:core"] = [0, -1, -1, 0, 1, 1][f]
		for i in 3:
			k[StringName("emit:seam_%d" % i)] = [0, -1, -1, 0, 1, 1][(f + i) % 6]
		k[&"emit:eyes"] = [0, 0, 0, 0, -1, 0][f]
		k[&"view:head"] = &"squint" if f == 4 else &"open"
		idle[f] = k
	b.anim(&"idle", 6, [190, 170, 170, 220, 140, 170], idle, {"interp": &"hold"})

	# Telegrafía / gesto (bloqueo + fuerza): inspira hasta arriba, la forja se aviva, el cabezal se alza.
	var t0 := _pose(0.44, 0, 2, 0.0)
	t0[&"head"] = -0.04
	t0[&"view:head"] = &"wide"
	t0[&"emit:core"] = 1
	var t1 := _pose(0.48, 1, 3, 0.0)
	t1[&"head"] = -0.06
	t1[&"view:head"] = &"wide"
	t1[&"emit:core"] = 2
	for i in 3:
		t0[StringName("emit:seam_%d" % i)] = 1
		t1[StringName("emit:seam_%d" % i)] = 2
	b.anim(&"cast", 2, [120, 400], {0: t0, 1: t1}, {"loop": false, "interp": &"hold"})

	# Ataque: inspira (peso atrás) → cierra de golpe avanzando → chorro de fuego (impacto, f2) → recupera.
	var a0 := _pose(0.46, 0, 5)
	a0[&"nozzle"] = -0.08
	a0[&"head"] = -0.04
	a0[&"view:head"] = &"wide"
	a0[&"emit:core"] = 2
	var a1 := _show(_pose(0.18, 1, -3), ["jet_0", "puff_0"])
	a1[&"nozzle"] = 0.03
	a1[&"view:head"] = &"wide"
	var a2 := _show(_pose(0.04, 2, -9), ["jet_1"])
	a2[&"nozzle"] = 0.06
	a2[&"head"] = 0.03
	a2[&"view:head"] = &"wide"
	a2[&"emit:core"] = 2
	var a3 := _show(_pose(0.12, 3, -5), ["jet_2", "puff_1", "puff_2"])
	a3[&"nozzle"] = 0.03
	for i in 3:
		a0[StringName("emit:seam_%d" % i)] = 2
		a2[StringName("emit:seam_%d" % i)] = 2
	b.anim(&"attack", 4, [240, 50, 130, 220], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})

	# Golpe recibido: la tapa se cierra de golpe, recula, ojos apretados, chispas por las juntas.
	var h0 := _show(_pose(0.08, 1, 4), ["puff_0"])
	h0[&"view:head"] = &"squint"
	h0[&"head"] = -0.05
	h0[&"emit:core"] = 2
	var h1 := _pose(0.16, 2, 2)
	h1[&"view:head"] = &"squint"
	for i in 3:
		h0[StringName("emit:seam_%d" % i)] = 2
	b.anim(&"hurt", 2, [90, 160], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})

	# Invocación: inspira hondo → sopla y escupe dos ácaros-vela que salen volando de la tobera.
	var s0 := _pose(0.42, 0, 3)
	s0[&"view:head"] = &"wide"
	var s1 := _pose(0.48, 1, 4)
	s1[&"view:head"] = &"wide"
	s1[&"emit:core"] = 2
	s1[&"nozzle"] = -0.1
	var s2 := _show(_pose(0.1, 2, -5), ["mite_0", "mite_1", "puff_0", "jet_0"])
	s2[&"nozzle"] = -0.06
	s2[&"view:head"] = &"wide"
	var s3 := _show(_pose(0.06, 3, -4), ["mite_2", "mite_3", "puff_1", "puff_0"])
	s3[&"nozzle"] = -0.04
	var s4 := _show(_pose(0.12, 0, -2), ["mite_4", "mite_5", "puff_2", "puff_3"])
	var s5 := _show(_pose(0.2, 1, -1), ["puff_3"])
	b.anim(&"summon", 6, [160, 220, 60, 110, 130, 200], {0: s0, 1: s1, 2: s2, 3: s3, 4: s4, 5: s5}, {"loop": false, "interp": &"hold"})

	# Ahogo: inspira y suelta una nube de hollín negro que se extiende y se queda flotando.
	var c0 := _pose(0.4, 0, 2)
	var c1 := _pose(0.46, 1, 3)
	c1[&"view:head"] = &"wide"
	c1[&"emit:core"] = -2
	var c2 := _show(_pose(0.08, 2, -4), ["soot_0", "soot_1", "soot_2"])
	c2[&"emit:core"] = -2
	var c3 := _show(_pose(0.05, 3, -5), ["soot_0", "soot_1", "soot_2", "soot_3", "soot_4"])
	c3[&"emit:core"] = -2
	var c4 := _show(_pose(0.12, 0, -3), ["soot_1", "soot_2", "soot_3", "soot_4", "soot_5", "soot_6", "soot_7", "soot_sparks"])
	c4[&"emit:core"] = -1
	var c5 := _show(_pose(0.2, 1, -1), ["soot_3", "soot_5", "soot_6", "soot_7"])
	for k: Dictionary in [c2, c3, c4]:
		k[&"view:head"] = &"squint"
		k[&"emit:mouth"] = -2
	b.anim(&"choke", 6, [160, 160, 60, 140, 220, 260], {0: c0, 1: c1, 2: c2, 3: c3, 4: c4, 5: c5}, {"loop": false, "interp": &"hold"})

	# Muerte por material: la forja revienta la tapa → la tapa sale volando → el caballete cede y el poste cae →
	# montón de tablas y hierros con la forja apagándose.
	var d := {}
	d[0] = _pose(0.08, 0, 4)
	d[0][&"view:head"] = &"squint"
	d[0][&"emit:core"] = 2
	d[1] = _show(_pose(0.5, 1, 2), ["burst_2"])
	d[1][&"view:head"] = &"wide"
	d[1][&"emit:core"] = 2
	d[2] = _show(_pose(0.3, 2, 1), ["burst_0", "fly_lid", "fly_strap"])
	d[2][&"view:head"] = &"dead"
	for id: String in LID:
		d[2][StringName("hide:" + id)] = true
	d[2][&"fly"] = -0.35
	var heap := _pose(0.04, 3, 0)
	heap[&"@root"] = Vector2i(0, 32)
	for l: String in ["leg_fn", "leg_ff"]:
		heap[StringName(l)] = 1.1
	for l: String in ["leg_bn", "leg_bf"]:
		heap[StringName(l)] = -1.1
	heap[&"view:head"] = &"dead"
	heap[&"head"] = 0.12
	heap[&"nozzle"] = 0.25
	for id: String in LID + RIG_UP:
		heap[StringName("hide:" + id)] = true
	for i in 8:
		heap[StringName("hide:cw_link_%d" % i)] = true
	for i in 3:
		heap[StringName("hide:cw_snap_%d" % i)] = true
	_show(heap, ["down_lid", "down_post", "down_beam", "down_weight"])
	for f in range(3, 8):
		var k: Dictionary = heap.duplicate()
		k[&"view:mouth"] = [&"g0", &"g1", &"g2", &"g3"][f % 4]
		k[&"emit:core"] = [1, 0, -1, -2, -3][f - 3]
		k[&"emit:mouth"] = [0, -1, -2, -3, -4][f - 3]
		for i in 3:
			k[StringName("emit:seam_%d" % i)] = [1, 0, -1, -2, -3][f - 3]
		if f == 3:
			_show(k, ["burst_1", "puff_2", "puff_3"])
		elif f == 4:
			_show(k, ["burst_2", "puff_3"])
		else:
			_show(k, ["embers_end"])
			k[&"emit:embers_end"] = [1, 0, -1][f - 5]
		d[f] = k
	# la cadena de la tapa también cae con ella
	for f in range(2, 8):
		for i in CHAIN_LINKS:
			(d[f] as Dictionary)[StringName("hide:rod_link_%d" % i)] = true
	b.anim(&"death", 8, [100, 120, 130, 140, 160, 200, 240, 500], d, {"loop": false, "interp": &"hold"})
