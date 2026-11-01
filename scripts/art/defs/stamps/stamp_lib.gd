extends RefCounted
## Biblioteca de SELLOS (calcas) de personajes y criaturas — PER, v0.4.
##
## Cada sello es un dibujo a mano píxel a píxel que el motor de rig pega con TONO FORZADO: no se cuantiza,
## no genera línea interior y no pasa por la limpieza de huérfanos (condiciones PER-2 y PER-4 de DEBATE.md).
##
## Formato (compatible con `Stamp` de la API de TEC):
##   {rows: Array[String], legend: {char: [material, paso]}, anchor: Vector2i, faces: "right"|"front", note: String}
##   - material: id de rampa de `scripts/art/palette.gd` (DA). Los ids "@algo" son RANURAS: quien usa el sello
##     las resuelve (p. ej. "@hand" → &"skin" en la heroína, &"soot_rock" en el gólem). Ver `MAT` abajo.
##   - paso: entero = paso ABSOLUTO de la rampa · "LINE" = contorno del material · "+1"/"-1" = relativo a la luz horneada.
##     En ranuras "@", los pasos están en escala de 6 (0..5) y se reescalan a la longitud de la rampa real
##     con `resolve_step()`; así un mismo sello de mano vale para piel (6 pasos) y roca (8 pasos).
##   - "." = transparente (deja ver lo que pinte el rig debajo).
##   - anchor: el píxel del sello que se coloca sobre el punto de anclaje del hueso (ojo, centro de la palma…).
##   - Todos miran a la DERECHA (la heroína) salvo `faces: "front"`. Las criaturas miran a la izquierda: `flip = true`.
##
## Reglas de dibujo (biblia v0.4): ojo de la heroína 1×2 con brillo; ninguna línea de 2 px no intencionada;
## manos de 5–6 px que se leen como mano en la miniatura; sin negro puro (LINE usa el contorno del material).

## Ids de material de la paleta maestra del DA. ÚNICO punto que cambiar si palette.gd usa otros nombres.
const MAT := {
	"skin": &"skin", "hair": &"hair", "linen": &"linen", "leather": &"leather", "wool": &"wool_blue",
	"metal_c": &"steel", "metal_w": &"iron", "fire": &"fire", "gold": &"brass", "soot": &"soot",
	"rock": &"rock_soot", "brick": &"furnace_brick", "bone": &"linen", "coal": &"coal", "hot": &"hot",
}


static func resolve_step(step: Variant, ramp_len: int) -> Variant:
	if typeof(step) != TYPE_INT:
		return step
	return clampi(int(round(float(step) * float(ramp_len - 1) / 5.0)), 0, ramp_len - 1)


# ===========================================================================================
# CARAS DE LA FOGONERA (≥ 10×10, enmienda de DA). Luz principal: Forja detrás a la izquierda.
# Leyenda común de cara:
#   1..5 piel (paso) · k línea · b ceja (pelo 2) · w blanco del ojo (lino 5) · i iris (lana 0)
#   h brillo del iris (lana 4) · m boca (piel 1) · n sombra de nariz (piel 2) · t tizne (soot 3) · G H J flequillo (pelo 3-5)
const FACE_LEGEND := {
	"1": ["skin", 1], "2": ["skin", 2], "3": ["skin", 3], "4": ["skin", 4], "5": ["skin", 5],
	"k": ["skin", "LINE"], "b": ["hair", 2], "w": ["linen", 5], "i": ["wool", 0], "h": ["wool", 4],
	"m": ["skin", 1], "n": ["skin", 2], "t": ["soot", 3],
	"G": ["hair", 3], "H": ["hair", 4], "J": ["hair", 5],
}

const STAMPS := {
	# --- Cara ¾ hacia la derecha (12×12). Fila 0 = flequillo (el pelo baja sobre la frente: sin frente calva).
	# Ojo cercano 1×2 con brillo + blanco; ojo lejano 1×2; ceja de 3 px; la nariz rompe la silueta 2 px (col. 10-11).
	# La mandíbula NO se oscurece por debajo (evita la "barba" que señaló DA).
	"face_34": {
		"rows": [
			"GHJHHGGHG...",
			"4bbb4444b3..",
			"44kk4444k3..",
			"4wh44444i3..",
			"44i44444i3..",
			"455444444332",
			"45544444n3..",
			"44444444433.",
			"4444444mm3..",
			"3444444443..",
			".33444443...",
			"..333333....",
		],
		"legend": FACE_LEGEND, "anchor": Vector2i(2, 3), "faces": "right",
		"note": "Ancla = ojo cercano. Ojo 1×2 (h sobre i) con blanco a la izquierda; ceja de 3 px; nariz 2 px fuera.",
	},
	# --- Cara ¾ con esfuerzo (carga/golpe): ceja fruncida en diagonal, ojo entornado, dientes apretados.
	"face_34_effort": {
		"rows": [
			"GHJHHGGHG...",
			"4b4b4444bb..",
			"44bkk444k3..",
			"4wh44444i3..",
			"44i444444k..",
			"455444444332",
			"45544444n3..",
			"4444444kwk..",
			"4444444kk3..",
			"3444444443..",
			".33444443...",
			"..333333....",
		],
		"legend": FACE_LEGEND, "anchor": Vector2i(2, 3), "faces": "right",
		"note": "Para windup/strike: ceja baja hacia la nariz, dientes (w) entre labios.",
	},
	# --- Cara herida: ojo cerrado en arco, boca abierta.
	"face_34_hurt": {
		"rows": [
			"GHJHHGGHG...",
			"44bbb444b3..",
			"4444444kk3..",
			"4kkk4444k3..",
			"444444444k..",
			"455444444332",
			"45544444n3..",
			"4444444kk3..",
			"444444k1k3..",
			"3444444kk...",
			".33444443...",
			"..333333....",
		],
		"legend": FACE_LEGEND, "anchor": Vector2i(2, 3), "faces": "right",
	},
	# --- Perfil a la derecha (10×12): pose al hombro (mirada al frente) y retrato del Archivo.
	"face_profile": {
		"rows": [
			"GHJHHG....",
			"44444bb3..",
			"444444k3..",
			"44444wi3..",
			"444444i3..",
			"4544444332",
			"45444443n.",
			"44444443..",
			"44444443m.",
			"344444443.",
			".3444443..",
			"..33333...",
		],
		"legend": FACE_LEGEND, "anchor": Vector2i(6, 3), "faces": "right",
	},

	# ===========================================================================================
	# MANOS (@hand = piel o tizne o pellejo de criatura; @tool = lo que agarra). Escala de 6 pasos.
	# Vistas desde el lado de la luz; miran a la derecha. Ancla = centro de la palma / del mango.
	"hand_open": {
		"rows": [
			"..k.k.",
			".k3k3k",
			"k43434",
			"k44443",
			"k4443.",
			".k33..",
		],
		"legend": {"k": ["@hand", "LINE"], "3": ["@hand", 2], "4": ["@hand", 3]},
		"anchor": Vector2i(2, 3), "faces": "right", "note": "Mano abierta, dedos separados (lanzar carta al fogón).",
	},
	"hand_grip": {
		"rows": [
			".k44k.",
			"k4554k",
			"k3443k",
			"k3333k",
			".k22k.",
		],
		"legend": {"k": ["@hand", "LINE"], "2": ["@hand", 1], "3": ["@hand", 2], "4": ["@hand", 3], "5": ["@hand", 4]},
		"anchor": Vector2i(2, 2), "faces": "right",
		"note": "Puño cerrado alrededor de un mango que pasa en vertical por la col. 2-3 (el mango se pinta DETRÁS y asoma arriba y abajo).",
	},
	"hand_grip_knuckles": {
		"rows": [
			".k4k4k",
			"k45454",
			"k34443",
			"k3333k",
			".k22k.",
		],
		"legend": {"k": ["@hand", "LINE"], "2": ["@hand", 1], "3": ["@hand", 2], "4": ["@hand", 3], "5": ["@hand", 4]},
		"anchor": Vector2i(2, 2), "faces": "right", "note": "Agarre visto por los nudillos (brazo extendido hacia delante).",
	},
	"hand_fist": {
		"rows": [
			".kkkk.",
			"k5454k",
			"k4444k",
			"k3332k",
			".kkkk.",
		],
		"legend": {"k": ["@hand", "LINE"], "2": ["@hand", 1], "3": ["@hand", 2], "4": ["@hand", 3], "5": ["@hand", 4]},
		"anchor": Vector2i(2, 2), "faces": "right",
	},
	"hand_point": {
		"rows": [
			".....kk.",
			"..kkk45k",
			".k4444k.",
			"k44333k.",
			".k333k..",
			"..kkk...",
		],
		"legend": {"k": ["@hand", "LINE"], "3": ["@hand", 2], "4": ["@hand", 3], "5": ["@hand", 4]},
		"anchor": Vector2i(3, 3), "faces": "right", "note": "Índice extendido (el Carbonero señala; habilidades de la heroína).",
	},
	"claw_3": {
		"rows": [
			"k.k.k.",
			"5k5k5k",
			"4k4k4k",
			"k444k.",
			".k33k.",
		],
		"legend": {"k": ["@hand", "LINE"], "3": ["@hand", 2], "4": ["@hand", 3], "5": ["bone", 5]},
		"anchor": Vector2i(2, 3), "faces": "right", "note": "Garra de 3 uñas (diablillo, sabueso, bruja).",
	},

	# ===========================================================================================
	# OJOS
	"eye_hero_1x2": {"rows": ["h", "i"], "legend": {"h": ["wool", 4], "i": ["wool", 0]}, "anchor": Vector2i(0, 0), "faces": "right"},
	"eye_ember_2x1": {"rows": ["kEe"], "legend": {"k": ["@socket", "LINE"], "E": ["fire", 7], "e": ["fire", 4]},
		"anchor": Vector2i(1, 0), "faces": "right", "note": "Brasa hundida (gólem, caballero hueco). E emisivo."},
	"eye_ember_2x2": {"rows": ["kEek", "keek"], "legend": {"k": ["@socket", "LINE"], "E": ["fire", 7], "e": ["fire", 5]},
		"anchor": Vector2i(1, 0), "faces": "right"},
	"eye_bird": {"rows": [".kk.", "kwEk", ".kk."], "legend": {"k": ["@socket", "LINE"], "w": ["gold", 4], "E": ["@socket", 0]},
		"anchor": Vector2i(2, 1), "faces": "right", "note": "Ojo de urraca: anillo dorado, pupila oscura."},
	"eye_slit": {"rows": ["kEk", "kek", "kEk"], "legend": {"k": ["@socket", "LINE"], "E": ["fire", 6], "e": ["@socket", 0]},
		"anchor": Vector2i(1, 1), "faces": "right", "note": "Pupila vertical (sierpe, diablillo)."},
	"eye_molten": {
		"rows": [
			"..kkkk..",
			".k6776k.",
			"k676676k",
			"k77kk77k",
			"k77kk67k",
			"k676776k",
			".k6776k.",
			"..kkkk..",
		],
		"legend": {"k": ["fire", 1], "6": ["fire", 6], "7": ["fire", 7]},
		"anchor": Vector2i(4, 4), "faces": "front", "note": "Iris del Ojo Fundido (oro líquido); la pupila se desplaza con un parche."},

	# ===========================================================================================
	# METAL: remaches, hebillas, bisagras
	"rivet": {"rows": ["5", "2"], "legend": {"5": ["@metal", 5], "2": ["@metal", 1]}, "anchor": Vector2i(0, 0), "faces": "front",
		"note": "Remache 1 px con su sombra debajo."},
	"rivet_2": {"rows": ["54", "32"], "legend": {"5": ["@metal", 5], "4": ["@metal", 4], "3": ["@metal", 2], "2": ["@metal", 1]},
		"anchor": Vector2i(0, 0), "faces": "front"},
	"bolt_big": {"rows": [".kk.", "k54k", "k32k", ".kk."],
		"legend": {"k": ["@metal", "LINE"], "5": ["@metal", 5], "4": ["@metal", 4], "3": ["@metal", 2], "2": ["@metal", 1]},
		"anchor": Vector2i(1, 1), "faces": "front"},
	"buckle": {"rows": ["5554", "5..2", "4322"], "legend": {"5": ["gold", 5], "4": ["gold", 4], "3": ["gold", 3], "2": ["gold", 2]},
		"anchor": Vector2i(1, 1), "faces": "front", "note": "Hebilla de latón 4×3 (cinturón de la heroína)."},
	"buckle_small": {"rows": ["54", "32"], "legend": {"5": ["gold", 5], "4": ["gold", 4], "3": ["gold", 3], "2": ["gold", 2]},
		"anchor": Vector2i(0, 0), "faces": "front"},
	"hinge": {"rows": ["k5k", "k3k", "k5k"], "legend": {"k": ["@metal", "LINE"], "5": ["@metal", 4], "3": ["@metal", 2]},
		"anchor": Vector2i(1, 1), "faces": "front"},

	# ===========================================================================================
	# DIENTES Y BOCAS
	"teeth_grate": {"rows": ["kWkWkWk", "kwkwkwk"], "legend": {"k": ["@mouth", "LINE"], "W": ["fire", 5], "w": ["fire", 3]},
		"anchor": Vector2i(3, 0), "faces": "front", "note": "Mandíbula de rejilla con fuego detrás (gólem, Gran Fuelle)."},
	"fangs_row": {"rows": ["kkkkkkk", "W.W.W.W", "w...w.."], "legend": {"k": ["@mouth", "LINE"], "W": ["bone", 5], "w": ["bone", 3]},
		"anchor": Vector2i(3, 0), "faces": "front"},
	"fangs_pair": {"rows": ["kkkk", "W..W", "w..w"], "legend": {"k": ["@mouth", "LINE"], "W": ["bone", 5], "w": ["bone", 3]},
		"anchor": Vector2i(1, 0), "faces": "front", "note": "Murciélago, sabueso."},
	"grin_imp": {"rows": ["k.....k", "kWkWkWk", ".kkkkk."], "legend": {"k": ["@mouth", "LINE"], "W": ["bone", 5]},
		"anchor": Vector2i(3, 1), "faces": "front"},

	# ===========================================================================================
	# CUERNOS
	"horn_curl": {
		"rows": [
			"..kk.",
			".k54k",
			"k43k.",
			"k32k.",
			".k2k.",
		],
		"legend": {"k": ["@horn", "LINE"], "5": ["@horn", 5], "4": ["@horn", 4], "3": ["@horn", 3], "2": ["@horn", 2]},
		"anchor": Vector2i(2, 4), "faces": "right"},
	"horn_crystal": {
		"rows": [
			"..k..",
			".k5k.",
			".k53k",
			"k542k",
			"k432k",
		],
		"legend": {"k": ["@horn", "LINE"], "5": ["@horn", 5], "4": ["@horn", 4], "3": ["@horn", 3], "2": ["@horn", 2]},
		"anchor": Vector2i(2, 4), "faces": "right", "note": "Cristal de azufre (Diablillo, corona de la Reina)."},
	"horn_ram": {
		"rows": [
			".kkkk.",
			"k5543k",
			"k4kk3k",
			"k3k.k.",
			".k2k..",
		],
		"legend": {"k": ["@horn", "LINE"], "5": ["@horn", 5], "4": ["@horn", 4], "3": ["@horn", 3], "2": ["@horn", 2]},
		"anchor": Vector2i(1, 4), "faces": "right"},

	# ===========================================================================================
	# HEROÍNA: piezas de firma
	# Fogón de cinto: farol de latón 5×6 con rejilla; las barras de fuego (f/g) siguen al estado "case_glow".
	"belt_lantern": {
		"rows": [
			".k5k.",
			"k545k",
			"kfgfk",
			"k3g3k",
			"kfgfk",
			".k3k.",
		],
		"legend": {"k": ["gold", 1], "5": ["gold", 5], "4": ["gold", 4], "3": ["gold", 2], "f": ["fire", 4], "g": ["fire", 6]},
		"anchor": Vector2i(2, 0), "faces": "front",
		"note": "f y g son EMISIVOS: el shader les suma el pulso de quemar (emit_boost).",
	},
	# Gafas de forja: latón + cristal ahumado que refleja la Forja (lo emisivo es el reflejo).
	"goggles": {
		"rows": [
			".kkk.",
			"k5f4k",
			"k3ffk",
			".kkk.",
		],
		"legend": {"k": ["gold", 1], "5": ["gold", 5], "4": ["gold", 4], "3": ["gold", 3], "f": ["fire", 5]},
		"anchor": Vector2i(2, 1), "faces": "right"},
	# Asas del fuelle sobre el hombro (enmienda DA: sólo asoman 2 asas).
	"bellows_handles": {
		"rows": [
			"k...k",
			"5k..4k",
			"4k.k4k",
			".43.3k",
			".k3k3k",
		],
		"legend": {"k": ["leather", "LINE"], "5": ["leather", 5], "4": ["leather", 4], "3": ["leather", 2]},
		"anchor": Vector2i(2, 4), "faces": "right"},
	# Mechones de pelo (3 formas). El último paso se sustituye por la rampa de Fuego según el CALOR (puntas que arden).
	"lock_fringe": {
		"rows": [
			"kk....",
			"k54k..",
			".k43k.",
			"..k32k",
			"...kFk",
		],
		"legend": {"k": ["hair", "LINE"], "5": ["hair", 5], "4": ["hair", 4], "3": ["hair", 3], "2": ["hair", 2], "F": ["fire", 5]},
		"anchor": Vector2i(1, 1), "faces": "right", "note": "Flequillo que cae sobre la sien; F = punta-brasa (calor)."},
	"lock_nape": {
		"rows": [
			".kk.",
			"k43k",
			"k32k",
			".k2k",
			".kFk",
			"..F.",
		],
		"legend": {"k": ["hair", "LINE"], "4": ["hair", 4], "3": ["hair", 3], "2": ["hair", 2], "F": ["fire", 5]},
		"anchor": Vector2i(1, 0), "faces": "right", "note": "Mechón de la nuca que sale bajo el moño."},
	"lock_bun_tail": {
		"rows": [
			"kk...",
			"k4kk.",
			".k33k",
			"..kFk",
			"...F.",
		],
		"legend": {"k": ["hair", "LINE"], "4": ["hair", 4], "3": ["hair", 3], "F": ["fire", 6]},
		"anchor": Vector2i(0, 0), "faces": "right", "note": "Puntas del moño: brasa más viva (siempre visibles en silueta)."},
}


static func get_stamp(id: String) -> Dictionary:
	return STAMPS.get(id, {})


static func ids() -> Array:
	return STAMPS.keys()


## Valida el formato (usado por tests/art/test_per.gd). Devuelve lista de errores.
static func validate() -> Array:
	var errs: Array = []
	for id: String in STAMPS:
		var s: Dictionary = STAMPS[id]
		var rows: Array = s.get("rows", [])
		if rows.is_empty():
			errs.append("%s: sin filas" % id)
			continue
		var legend: Dictionary = s.get("legend", {})
		for y in rows.size():
			var r: String = rows[y]
			for ch in r:
				if ch != "." and not legend.has(ch):
					errs.append("%s: carácter '%s' sin leyenda (fila %d)" % [id, ch, y])
		for ch: String in legend:
			var e: Array = legend[ch]
			var m: String = e[0]
			if not m.begins_with("@") and not MAT.has(m):
				errs.append("%s: material '%s' fuera de MAT" % [id, m])
			var st: Variant = e[1]
			if typeof(st) == TYPE_STRING and not (st in ["LINE", "+1", "-1"]):
				errs.append("%s: paso '%s' inválido" % [id, st])
		var a: Vector2i = s.get("anchor", Vector2i.ZERO)
		if a.y >= rows.size() or a.x >= String(rows[a.y]).length():
			errs.append("%s: ancla fuera del sello" % id)
	return errs
