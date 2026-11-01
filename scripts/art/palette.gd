class_name Palette
extends RefCounted
## Paleta maestra de EMBERSPIRE v0.4 (dueño: dirección de arte). FUENTE ÚNICA de color del juego.
##
## Cada MATERIAL tiene dos rampas hechas A MANO (prohibido generarlas por HSV), de oscuro a claro:
##   · cálida  → la superficie la ilumina la Forja (luces hacia ámbar)
##   · fría    → la superficie la ilumina la Torre (luces hacia azul pizarra)
## Reglas: el paso 0 es COMÚN a las dos rampas de un material (no hay costura al cambiar de luz); las rampas cálida y
## fría pueden tener distinta longitud (el shader recorta). Emisivos: la fría es igual a la cálida.
## Una rampa tiene como máximo LUT_W (16) pasos.
##
## ÍNDICE ESTABLE (canal de material de la textura de índice; fila de LUT = índice*2 + (1 si fría)).
## SÓLO SE AÑADE AL FINAL. Nunca se reordena ni se borra (marcar como obsoleto en el comentario).
##   0 void           11 sky*           22 coal           33 heal           44 parch_power
##   1 stone          12 moon*          23 rock_soot      34 frame_attack   45 parch_fuel
##   2 brick          13 skin           24 slag           35 frame_skill    46 parch_status
##   3 furnace_brick  14 hair           25 slag_glow*     36 frame_power    47 plate
##   4 fire*          15 linen          26 ice            37 frame_fuel     48 burlap
##   5 gold           16 leather        27 ash            38 frame_status   49 steel  
##   6 cloth          17 wool_blue      28 smoke          39 ink            50 ember_ui*
##   7 iron           18 canvas         29 parchment      40 blood
##   8 copper         19 boot           30 parch_skill    41 magic
##   9 brass          20 soot           31 hot*           42 frost_glow*
##  10 wood           21 rock_far       32 shadow_ui      43 parch_attack
## (* = emisivo: no recibe luz; el shader sólo le aplica desplazamientos de paso de "pulso")
## Notas: `iron` = hierro de arquitectura, rejas, herramientas de fondo (11 pasos); `steel` = acero de personajes y armas
## (7 pasos, con especular). No existe un material "cold": la luz fría es la rampa fría de CADA material.
##
## Uso:
##   Palette.ramp(&"stone")              → PackedColorArray cálida
##   Palette.ramp(&"stone", true)        → fría
##   Palette.color(&"fire", 6)           → un color (paso recortado a la rampa)
##   Palette.index(&"skin")              → 13 (para el canal de material)
##   Palette.build_lut()                 → ImageTexture LUT_W × (n·2) para `palette_lit.gdshader`
##   Palette.all_colors()                → Dictionary {Color(rgb8) → true}: la prueba de paleta cerrada
##   Palette.UI                          → colores fijos de interfaz (tintas de texto, contorno universal)

const LUT_W := 16
const OUTLINE := Color("0b080e")  # contorno universal (nunca negro puro); = void

## Orden = índice. SÓLO AÑADIR AL FINAL.
const ORDER: Array[StringName] = [
	&"void", &"stone", &"brick", &"furnace_brick", &"fire", &"gold", &"cloth", &"iron", &"copper", &"brass",
	&"wood", &"sky", &"moon", &"skin", &"hair", &"linen", &"leather", &"wool_blue", &"canvas", &"boot",
	&"soot", &"rock_far", &"coal", &"rock_soot", &"slag", &"slag_glow", &"ice", &"ash", &"smoke", &"parchment",
	&"parch_skill", &"hot", &"shadow_ui", &"heal", &"frame_attack", &"frame_skill", &"frame_power", &"frame_fuel", &"frame_status", &"ink",
	&"blood", &"magic", &"frost_glow", &"parch_attack", &"parch_power", &"parch_fuel", &"parch_status", &"plate", &"burlap", &"steel",
	&"ember_ui",
]

## Emisivos (no reciben luz; cálida == fría).
const EMISSIVE: Array[StringName] = [&"fire", &"sky", &"moon", &"slag_glow", &"hot", &"frost_glow", &"ember_ui"]

## [cálida, fría]. Si la fría es [] se usa la cálida (emisivos y materiales de interfaz).
const RAMPS := {
	&"void": [["0b080e"], []],
	# --- arquitectura (rampas largas: la luz por pieza necesita muchos escalones) ---
	&"stone": [["120e12", "1b161b", "262025", "322a2f", "40363a", "524545", "675651", "806858", "a07c62", "c4966c", "e6b47e"],
		["120e12", "16141e", "1c1b28", "232434", "2b2e40", "35394e", "41475e", "4f5870", "606c84", "7684a0", "92a2bc"]],
	&"brick": [["120a0e", "1c1218", "26191e", "312126", "3d2a2d", "4c3331", "613d34", "7c4a35", "9c5a37", "c2723c", "e6924a"],
		["120a0e", "18121c", "1e1826", "261e30", "2e263a", "383046", "443a54", "524864", "645a78", "7a6e8e", "948aa8"]],
	&"furnace_brick": [["0e090c", "1c0f14", "2e1418", "44191a", "5e2420", "7c3222", "a04626", "c8642e", "f08c42"],
		["0e090c", "18101a", "221626", "2c1c30", "38243a", "462e46", "563a54"]],
	&"iron": [["0a070b", "141018", "1f1a24", "2c2632", "3c3544", "524a5a", "6e6674", "948a92", "bcaea6", "e2cdb0", "fff0d2"],
		["0a070b", "121220", "1a1c2c", "24283a", "30364a", "3e465e", "505a74", "667290", "8090ac", "a2b2c8", "c8d6e4"]],
	&"copper": [["140a0a", "24120e", "3a1c12", "542818", "703620", "8c4626", "a85a2e", "c8723a", "e09048", "f0b060", "ffd890"],
		["140a0a", "1c1218", "261a24", "322432", "3e2e40", "4c3a50", "5c4862", "6e5a76"]],
	&"wood": [["0e0806", "1a0e0a", "26160e", "342014", "422a18", "54341c", "6a4222", "845228", "a06830", "c08440", "e0a050"],
		["0e0806", "16101a", "1e1824", "28202e", "322a3a", "3e3446", "4a4054", "5a4e64"]],
	&"ash": [["161214", "201b1e", "2b2528", "383235", "474142", "5a5352", "706764", "8a7d76", "a69484", "c4ac94", "e0c6a6"],
		["161214", "1a1820", "20202c", "282a38", "323648", "3e4458", "4c546a", "5e687e", "748098", "8e9cb2", "aab8cc"]],
	&"smoke": [["0e0a10", "1e1a22", "2a2430", "3a3240", "4c4450", "625a64"],
		["0e0a10", "1a1a26", "242634", "30344a", "3e4460", "50587a"]],
	# --- emisivos ---
	&"fire": [["2a0a10", "5a1216", "92201a", "cc3c1c", "f26a22", "ffa03a", "ffd468", "fff6d4"], []],
	&"hot": [["3a0a0c", "6a1414", "b8281a", "f45a18", "ffa834", "fff0b8"], []],
	&"sky": [["05050c", "090b16", "0f1424", "161f36", "1e2b4a", "283a60", "36507c", "4c6c98", "7094b8", "a8c8e0", "e6f2fa"], []],
	&"moon": [["0c1020", "2e486c", "5a7088", "8aa4bc", "b8ccdc", "e4eef4"], []],
	&"slag_glow": [["0e1a0a", "1e4a1a", "3a7a28", "5aa83a", "8ae048", "c0f070", "eaffb0"], []],
	&"frost_glow": [["0a1020", "1e3c64", "3a78b0", "70c8ff", "b4ecff", "f2fcff"], []],
	&"ember_ui": [["2a0a10", "7a1a16", "c2321e", "ff6a1a", "ffb43a", "ffe08a", "fff4c8"], []],
	# --- metales ---
	&"gold": [["1a0e08", "4a2c10", "8a5a18", "c8902a", "f0c050", "fff0a0"],
		["1a0e08", "2e2420", "4a4034", "6e6450", "9a927a", "c4bea4"]],
	&"steel": [["0c0a10", "1e1820", "382a2c", "5a4038", "8a6048", "c48a5c", "f0c08a"],
		["0c0a10", "1a1a26", "2c3040", "465062", "687a90", "9cb0c4", "d8e6f0"]],
	&"brass": [["1a0e08", "34200e", "64401a", "a06c22", "d8a440", "fae088"],
		["1a0e08", "2a2024", "44383a", "625650", "8a806e", "b0aa96"]],
	# --- tela ---
	&"cloth": [["14080a", "220c0e", "321214", "461818", "5c1e1a", "74261e", "8e3020", "a83e22", "c25028", "d8682e", "ea8a3a"],
		["14080a", "1c0c14", "26101c", "321626", "3e1c30", "4c243c", "5c2e4a", "6e3a5a"]],
	&"linen": [["1c1424", "3a3048", "665a6c", "9a8a88", "ccbaa2", "eedfc0", "fbf0d8"],
		["1c1424", "302c40", "4a4a62", "6a7090", "96a2be", "b8c4dc"]],
	&"wool_blue": [["0c1024", "161e3a", "243a62", "36628e", "5c96be", "a0d0e8"],
		["0c1024", "161e3a", "2a4a7a", "4474ac", "74a8d8", "b4e0fa"]],
	&"canvas": [["0e0c14", "16141e", "2a2434", "40384a", "584c5e", "726474"],
		["0e0c14", "16162a", "202440", "2e3456", "404a6c", "586488"]],
	&"burlap": [["160e0c", "2a1e1a", "4a3628", "6a5234", "8c7246", "ae9660"],
		["160e0c", "221c22", "342e36", "4a4450", "625e6c"]],
	# --- personajes ---
	&"skin": [["24101a", "4a1e2e", "843c38", "bc6648", "e09868", "f6c890"],
		["24101a", "3e2430", "6a4650", "9a7276", "c8a4a0"]],
	&"hair": [["1c0612", "2c0a1c", "561424", "862420", "b23a22", "e07034", "ffa24e"],
		["1c0612", "2a0e20", "3a1426", "561c30", "72283c", "8a3a4c"]],
	&"leather": [["120a10", "1e121c", "3a1e26", "60342c", "8a5236", "b07646", "d88c48"],
		["120a10", "1e1620", "2c2230", "3c3040", "524458", "6a5a70"]],
	&"boot": [["0c0608", "160e12", "2c1a1c", "482a24", "6a4032", "8a5a42"],
		["0c0608", "161420", "221e30", "302c40", "403c54"]],
	&"soot": [["120c12", "1a1420", "2c2230", "44363f", "62504c", "84705e"],
		["120c12", "18162a", "22203a", "302e4a", "403e5c"]],
	# --- criaturas ---
	&"rock_soot": [["0a080c", "151018", "221822", "32222a", "462e32", "623c38", "8a523c", "b46e44"],
		["0a080c", "121220", "1a1c2e", "262a40", "343c54", "48546e", "62748e", "8ca2ba"]],
	&"rock_far": [["0a080c", "120e16", "1a141e", "261a24", "34222a", "462c30"],
		["0a080c", "0f0f1a", "151726", "1e2234", "282e44", "343c56"]],
	&"coal": [["050308", "0e0c14", "181622", "262433", "3a3a4e", "52546c"],
		["050308", "0e0e1a", "18182a", "26283e", "383c56", "50587a"]],
	&"slag": [["0c0a0a", "1a1612", "2a2418", "3e3a1e", "5a5a22", "86862a", "b0b048"],
		["0c0a0a", "141618", "1c2224", "263032", "323e40", "405050"]],
	&"ice": [["0a1020", "2a2438", "4a3a4a", "7a5a58", "b08068", "e0b090", "fff0d0"],
		["0a1020", "142440", "1e3c64", "3070a0", "5aa8d0", "a0e0f0", "eafcff"]],
	&"blood": [["2a0a10", "5c1418", "9a2018", "d23a22", "ff6a48"], []],
	&"magic": [["1c0e2a", "3a1a5a", "6a3a9a", "9a5ad0", "d0a8ff"], []],
	&"heal": [["0e2414", "1e4a28", "3a7a3a", "6ac46a", "b0f0a0"], []],
	# --- interfaz y cartas (paso 0 = tinta/contorno común) ---
	&"parchment": [["2a1418", "4a3020", "8a6a4a", "c4a47a", "dcc49a", "ecdab4", "f8ecd0"], []],
	&"parch_attack": [["2a1418", "8a6a4c", "c8a47c", "e4c8a0", "f2e0be"], []],
	&"parch_skill": [["2a1418", "74706a", "b0aca0", "d8d4c4", "ecead8"], []],
	&"parch_power": [["2a1418", "8a7048", "c8a868", "e8d29a", "f6e8c0"], []],
	&"parch_fuel": [["2a1418", "80603e", "c09a70", "e0c49a", "f0dcb8"], []],
	&"parch_status": [["2a1418", "5e5a58", "8e8884", "b4aea8", "cac4bc"], []],
	&"ink": [["0e070a", "1a0f12", "2a1418"], []],
	&"frame_attack": [["1a0f12", "240a0e", "4e1216", "86201a", "bc3a1e", "f07a3a"], []],
	&"frame_skill": [["1a0f12", "0c1222", "1a2c4a", "2e4c74", "5a80aa", "a8d0f0"], []],
	&"frame_power": [["1a0f12", "2a1606", "5a360e", "946616", "d0a030", "fff0a0"], []],
	&"frame_fuel": [["1a0f12", "1a0e0a", "3a1e14", "643420", "94502e", "d08048"], []],
	&"frame_status": [["1a0f12", "141218", "2a2830", "46424e", "6e6876", "a8a0a8"], []],
	&"plate": [["0b080e", "120c12", "1a1420", "2a2430", "3a3440", "4e4858", "6a6474"], []],
	&"shadow_ui": [["0b080e", "1a0f12", "1e100c", "2a0a0c"], []],
}

## Colores fijos de interfaz (texto sobre pergamino, avisos). Entran en la prueba de paleta.
const UI := {
	&"outline": Color("0b080e"), &"k": Color("1a0f12"), &"ink": Color("2a1418"), &"ink_deep": Color("0e070a"),
	&"num": Color("a8300c"), &"keyword": Color("8a1a0a"), &"upgraded": Color("1e7a1e"),
	&"text": Color("f4e4c8"), &"text_dim": Color("a08878"), &"title": Color("ffb43a"),
	# placas del nombre de carta por tipo (UI)
	&"plate_attack": Color("2a0a0c"), &"plate_skill": Color("0e1830"), &"plate_power": Color("2a1236"),
	&"plate_fuel": Color("1e100c"), &"plate_status": Color("1a181e"),
}

static var _ramps_cache: Dictionary = {}
static var _all_cache: Dictionary = {}
static var _lut: ImageTexture

static func count() -> int:
	return ORDER.size()

static func index(material: StringName) -> int:
	var i := ORDER.find(material)
	assert(i >= 0, "Palette: material desconocido %s" % material)
	return i

static func material_at(i: int) -> StringName:
	return ORDER[i] if i >= 0 and i < ORDER.size() else &"void"

static func has(material: StringName) -> bool:
	return RAMPS.has(material)

static func is_emissive(material: StringName) -> bool:
	return EMISSIVE.has(material)

## Rampa como colores. `cold` = rampa fría (o la cálida si el material no tiene fría).
static func ramp(material: StringName, cold := false) -> PackedColorArray:
	var key := "%s:%d" % [material, int(cold)]
	if _ramps_cache.has(key):
		return _ramps_cache[key]
	var def: Array = RAMPS.get(material, RAMPS[&"void"])
	var hexes: Array = def[1] if (cold and (def[1] as Array).size() > 0) else def[0]
	var out := PackedColorArray()
	for h: String in hexes:
		out.append(Color(h))
	_ramps_cache[key] = out
	return out

static func steps(material: StringName, cold := false) -> int:
	return ramp(material, cold).size()

static func color(material: StringName, step: int, cold := false) -> Color:
	var r := ramp(material, cold)
	return r[clampi(step, 0, r.size() - 1)]

## Fila de la LUT para un material.
static func lut_row(material: StringName, cold := false) -> int:
	return index(material) * 2 + (1 if cold else 0)

## LUT LUT_W × (count·2), RGBA8, sin filtro. Fila 2i = cálida, 2i+1 = fría. Las rampas cortas se rellenan
## repitiendo su último paso (el shader puede recortar con `steps()` o confiar en el relleno).
static func build_lut_image() -> Image:
	var img := Image.create_empty(LUT_W, ORDER.size() * 2, false, Image.FORMAT_RGBA8)
	for i in ORDER.size():
		for c in 2:
			var r := ramp(ORDER[i], c == 1)
			for x in LUT_W:
				img.set_pixel(x, i * 2 + c, r[mini(x, r.size() - 1)])
	return img

static func build_lut() -> ImageTexture:
	if _lut == null:
		_lut = ImageTexture.create_from_image(build_lut_image())
	return _lut

## Conjunto de todos los colores permitidos (clave = Color redondeado a 8 bits, opaco).
static func all_colors() -> Dictionary:
	if not _all_cache.is_empty():
		return _all_cache
	for m: StringName in ORDER:
		for c in 2:
			for col in ramp(m, c == 1):
				_all_cache[key8(col)] = true
	for col: Color in UI.values():
		_all_cache[key8(col)] = true
	_all_cache[key8(OUTLINE)] = true
	return _all_cache

## Clave canónica de 8 bits (ignora alfa).
static func key8(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8

static func is_palette_color(c: Color) -> bool:
	return all_colors().has(key8(c))

## Búsqueda inversa: (material, paso, fría) del color, o null. Útil para hornear a índices.
static func find(c: Color) -> Variant:
	var k := key8(c)
	for m: StringName in ORDER:
		for cold in 2:
			var r := ramp(m, cold == 1)
			for s in r.size():
				if key8(r[s]) == k:
					return [m, s, cold == 1]
	return null

## Comprobación de coherencia de los datos (la usa la prueba): devuelve errores.
static func validate() -> Array[String]:
	var errs: Array[String] = []
	if ORDER.size() * 2 > 256:
		errs.append("demasiados materiales para un canal de 8 bits")
	for m: StringName in ORDER:
		if not RAMPS.has(m):
			errs.append("material sin rampa: %s" % m)
			continue
		var w := ramp(m)
		var cl := ramp(m, true)
		if w.size() > LUT_W or cl.size() > LUT_W:
			errs.append("%s: rampa de más de %d pasos" % [m, LUT_W])
		if key8(w[0]) != key8(cl[0]):
			errs.append("%s: el paso 0 no es común a cálida y fría" % m)
		if is_emissive(m) and (RAMPS[m][1] as Array).size() > 0:
			errs.append("%s: un emisivo no lleva rampa fría" % m)
		# las rampas van de oscuro a claro
		for r: PackedColorArray in [w, cl]:
			for s in range(1, r.size()):
				if r[s].get_luminance() + 0.02 < r[s - 1].get_luminance():
					errs.append("%s: la rampa no sube de luminancia en el paso %d" % [m, s])
					break
	for m: StringName in RAMPS.keys():
		if not ORDER.has(m):
			errs.append("rampa sin índice estable: %s" % m)
	return errs
