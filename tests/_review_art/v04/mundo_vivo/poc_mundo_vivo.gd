extends Node
## PRUEBA DE CONCEPTO · Mundo vivo (v0.4) — Artista de entornos / VFX.
## Genera el fondo del Acto 1 («La Sala de Fogones», Hollín) rediseñado POR CAPAS a 320×180 nativo:
##   L0 exterior (ciudad helada tras la ventana) · L1 tiro de la Torre (lejos) · L2 muro + suelo (plano de juego)
##   L4 primer plano. Más las animaciones ambientales (brasero + humo + pavesas, cadena con crisol que oscila,
##   chispas que suben por el tiro, nieve tras el cristal, motas de polvo) y un GIF animado real.
## Técnica: cada píxel guarda (material, valor) y la luz SUMA PASOS en la rampa del material (no mezcla colores):
## paleta cerrada garantizada, luz «ladrillo a ladrillo» (se muestrea en el centro de cada pieza), sin tramado.
## Ejecutar con ventana:  Godot --path . res://tests/_review_art/v04/mundo_vivo/poc_mundo_vivo.tscn

const OUT := "res://tests/_review_art/v04/mundo_vivo/out/"
const W := 320
const H := 180
const FY := 118
const M0 := 2      # margen de parallax de las capas lejanas
const M4 := 4      # margen de parallax del primer plano

enum {BRICK, STONE, IRON, COPPER, WOOD, ASH, SKY, FIRE, COLD}

const RAMP_HEX := [
	# BRICK (hollín → ladrillo caliente). Sombras hacia violeta, luces hacia naranja.
	["120a0e", "1c1218", "26191e", "312126", "3d2a2d", "4c3331", "613d34", "7c4a35", "9c5a37", "c2723c", "e6924a"],
	# STONE (sillares y losas: más gris)
	["120e12", "1b161b", "262025", "322a2f", "40363a", "524545", "675651", "806858", "a07c62", "c4966c", "e6b47e"],
	# IRON
	["0a070b", "141018", "1f1a24", "2c2632", "3c3544", "524a5a", "6e6674", "948a92", "bcae a6", "e2cdb0", "fff0d2"],
	# COPPER
	["140a0a", "24120e", "3a1c12", "542818", "703620", "8c4626", "a85a2e", "c8723a", "e09048", "f0b060", "ffd890"],
	# WOOD
	["0e0806", "1a0e0a", "26160e", "342014", "422a18", "54341c", "6a4222", "845228", "a06830", "c08440", "e0a050"],
	# ASH (ceniza, humo, montones)
	["161214", "201b1e", "2b2528", "383235", "474142", "5a5352", "706764", "8a7d76", "a69484", "c4ac94", "e0c6a6"],
	# SKY (exterior frío; emisivo)
	["05050c", "090b16", "0f1424", "161f36", "1e2b4a", "283a60", "36507c", "4c6c98", "7094b8", "a8c8e0", "e6f2fa"],
	# FIRE (emisivo)
	["2a0a0a", "5a1410", "7a1a16", "c2321e", "ff6a1a", "ffb43a", "ffe08a", "fff4c8"],
	# COLD (superficies bañadas por la luna)
	["0b0a12", "13131f", "1b1d2c", "25283a", "2f354a", "3b445c", "4a5672", "5c6c8a", "7088a4", "8ab4d0", "b8d4e8"],
]
const EMISSIVE := [false, false, false, false, false, false, true, true, false]

var RAMPS: Array = []


class Layer:
	var w: int
	var h: int
	var mat: PackedInt32Array
	var val: PackedInt32Array
	var sx: PackedInt32Array
	var sy: PackedInt32Array
	var fixed: PackedByteArray

	func _init(pw: int, ph: int) -> void:
		w = pw
		h = ph
		var n := pw * ph
		mat = PackedInt32Array()
		mat.resize(n)
		mat.fill(-1)
		val = PackedInt32Array()
		val.resize(n)
		sx = PackedInt32Array()
		sx.resize(n)
		sx.fill(-1)
		sy = PackedInt32Array()
		sy.resize(n)
		sy.fill(-1)
		fixed = PackedByteArray()
		fixed.resize(n)

	func put(x: int, y: int, m: int, v: int, px: int = -1, py: int = -1, fx: bool = false) -> void:
		if x < 0 or y < 0 or x >= w or y >= h:
			return
		var i := y * w + x
		mat[i] = m
		val[i] = v
		sx[i] = px
		sy[i] = py
		fixed[i] = 1 if fx else 0

	## Junta rehundida: recibe un paso de luz menos que la pieza.
	func joint(x: int, y: int, m: int, v: int) -> void:
		put(x, y, m, v)
		if x >= 0 and y >= 0 and x < w and y < h:
			fixed[y * w + x] = 2

	func has(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h:
			return false
		return mat[y * w + x] >= 0

	func m_at(x: int, y: int) -> int:
		if x < 0 or y < 0 or x >= w or y >= h:
			return -1
		return mat[y * w + x]

	func shift(x: int, y: int, dv: int) -> void:
		if has(x, y):
			val[y * w + x] += dv

	func erase(x: int, y: int) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			mat[y * w + x] = -1


# --- utilidades ---------------------------------------------------------------------

func _hash(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h % 10007) / 10007.0


func col(m: int, v: int) -> Color:
	var r: Array = RAMPS[m]
	return r[clampi(v, 0, r.size() - 1)]


func _ready() -> void:
	for ramp: Array in RAMP_HEX:
		var cs: Array = []
		for hx: String in ramp:
			cs.append(Color(hx.replace(" ", "")))
		RAMPS.append(cs)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var t0 := Time.get_ticks_msec()
	_make_all()
	print("mundo_vivo PoC: %d ms" % (Time.get_ticks_msec() - t0))
	get_tree().quit()


# --- luces ----------------------------------------------------------------------------
# Punto: {"t":"pt","p":Vector2,"r":[radios],"ys":escala vertical,"cold":bool,"y0","y1"}
# Banda (haz de luna): {"t":"band","x0":x en y=0,"k":pendiente,"hw":semiancho,"y0","y1","cold":true}

func _steps(q: Vector2, lights: Array, cold: bool) -> int:
	var best := 0
	for L: Dictionary in lights:
		if bool(L.get("cold", false)) != cold:
			continue
		if q.y < float(L.get("y0", -999)) or q.y > float(L.get("y1", 999)):
			continue
		var s := 0
		if L["t"] == "pt":
			var p: Vector2 = L["p"]
			var d := Vector2(q.x - p.x, (q.y - p.y) * float(L.get("ys", 1.0))).length()
			for r: float in L["r"]:
				if d < r:
					s += 1
		elif L["t"] == "band":
			var cx: float = float(L["x0"]) + float(L["k"]) * q.y
			var dd := absf(q.x - cx)
			var hw: float = L["hw"]
			if dd < hw:
				s = 2 if dd < hw * 0.45 else 1
		elif L["t"] == "skew":
			# Mancha de luz de ventana proyectada sobre el suelo (paralelogramo).
			var t := (q.y - float(L["ya"])) / maxf(1.0, float(L["yb"]) - float(L["ya"]))
			if t >= 0.0 and t <= 1.0:
				var xa: float = lerpf(float(L["xa0"]), float(L["xb0"]), t)
				var xb: float = lerpf(float(L["xa1"]), float(L["xb1"]), t)
				if q.x >= xa and q.x <= xb:
					var edge := minf(q.x - xa, xb - q.x)
					s = 2 if edge > 3.0 and t > 0.1 and t < 0.8 else 1
		s += int(L.get("gain", 0)) if s > 0 else 0
		best = maxi(best, s)
	return best


func render(L: Layer, lights: Array, ox: int) -> Image:
	var img := Image.create(L.w, L.h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cache := {}
	for y in L.h:
		for x in L.w:
			var i := y * L.w + x
			var m := L.mat[i]
			if m < 0:
				continue
			var v := L.val[i]
			var recess := L.fixed[i] == 2
			if EMISSIVE[m] or L.fixed[i] == 1:
				img.set_pixel(x, y, col(m, v))
				continue
			var qx := (L.sx[i] if L.sx[i] >= 0 else x) - ox
			var qy := L.sy[i] if L.sy[i] >= 0 else y
			var key := qy * 4096 + qx + 2048
			var wc: Vector2i
			if cache.has(key):
				wc = cache[key]
			else:
				var q := Vector2(qx, qy)
				wc = Vector2i(_steps(q, lights, false), _steps(q, lights, true))
				cache[key] = wc
			if recess:
				wc = Vector2i(maxi(0, wc.x - 1), maxi(0, wc.y - 1))
			if wc.y > wc.x:
				img.set_pixel(x, y, col(COLD, v + wc.y))
			else:
				img.set_pixel(x, y, col(m, v + wc.x))
	return img


# --- parámetros de escena -------------------------------------------------------------
# floor: 1..10 (deterioro), heat: 0..1 (producción de la Forja → rejilla, tiro, ventanas lejanas),
# cycle: 0.. (ciclo II: vetas de brasa en el ladrillo), k: fotograma (0..15)

const BRAZ := [Vector2i(80, 64), Vector2i(238, 64)]
const FLICK := [0, 1, 0, -1, 1, 0, 1, -1]
const CRUCIBLE_PIVOT := Vector2i(300, 12)
const CHAIN_LEN := 42


func chain_dx(k: int) -> int:
	return int(roundf(3.4 * sin(TAU * float(k % 16) / 16.0)))


func wall_lights(P: Dictionary, k: int) -> Array:
	var lights: Array = []
	var f: int = FLICK[k % 8]
	for b: Vector2i in BRAZ:
		var fb := float(f) * 1.5
		lights.append({"t": "pt", "p": Vector2(b.x, b.y - 6), "r": [4.0, 8.0 + fb, 13.0 + fb, 20.0 + fb, 30.0 + fb, 44.0 + fb], "ys": 1.05, "y1": FY - 1})
		# Charco de luz del brasero en el suelo.
		lights.append({"t": "pt", "p": Vector2(b.x, FY + 3), "r": [10.0 + fb, 22.0 + fb, 36.0 + fb], "ys": 2.6, "y0": FY})
	var heat: float = P["heat"]
	# Resplandor del tiro: la Forja (abajo) ilumina el intradós del arco, el parapeto y las caras internas.
	var up := 0.75 + 0.5 * heat
	lights.append({"t": "pt", "p": Vector2(160, 150), "r": [34.0 * up, 50.0 * up, 66.0 * up], "ys": 1.0, "y1": FY - 1})
	# Rejilla del suelo (calor que sube de la Forja).
	lights.append({"t": "pt", "p": Vector2(160, 124), "r": [8.0 * up, 16.0 * up, 28.0 * up], "ys": 2.4, "y0": FY, "gain": 1 if heat > 0.8 else 0})
	# Crisol que oscila (luz móvil).
	var cx := CRUCIBLE_PIVOT.x + chain_dx(k)
	lights.append({"t": "pt", "p": Vector2(cx, CRUCIBLE_PIVOT.y + CHAIN_LEN + 4), "r": [5.0, 10.0, 15.0], "ys": 1.0, "y1": FY - 1})
	# Luna por la ventana: pared bajo la ventana y mancha en el suelo.
	lights.append({"t": "pt", "p": Vector2(266, 84), "r": [7.0, 13.0], "ys": 2.2, "cold": true, "y0": 80, "y1": 88})
	lights.append({"t": "skew", "cold": true, "ya": FY + 1, "yb": FY + 20, "xa0": 252.0, "xa1": 274.0, "xb0": 236.0, "xb1": 262.0})
	return lights


func far_lights(P: Dictionary) -> Array:
	var heat: float = P["heat"]
	var up := 0.8 + 0.45 * heat
	var lights: Array = []
	lights.append({"t": "pt", "p": Vector2(160, 132), "r": [30.0 * up, 42.0 * up, 56.0 * up, 72.0 * up, 96.0 * up], "ys": 1.15})
	for wpos: Vector3i in _far_windows(P):
		if wpos.z == 1:
			lights.append({"t": "pt", "p": Vector2(wpos.x + 1, wpos.y + 3), "r": [3.0, 6.0], "ys": 1.0})
	return lights


func _far_windows(P: Dictionary) -> Array:
	var base := [Vector3i(134, 38, 1), Vector3i(186, 28, 0), Vector3i(150, 54, 0), Vector3i(192, 52, 1), Vector3i(126, 88, 0),
		Vector3i(140, 86, 1), Vector3i(196, 86, 0), Vector3i(176, 42, 0)]
	var heat: float = P["heat"]
	var out: Array = []
	for i in base.size():
		var w: Vector3i = base[i]
		var lit := w.z == 1 or float(i) / base.size() < heat * 0.9
		out.append(Vector3i(w.x, w.y, 1 if lit else 0))
	return out


# --- L0: exterior (ciudad helada) --------------------------------------------------------

func build_sky(P: Dictionary) -> Layer:
	var L := Layer.new(W + 2 * M0, H)
	for y in H:
		for xl in L.w:
			var x := xl - M0
			var v := 1 + mini(3, int(float(y) / 21.0))
			# Halo de la luna (anillos).
			var dm := Vector2(x - 262, y - 40).length()
			if dm < 9.0:
				v += 1
			if dm < 13.0:
				v += 1
			if y < 64 and _hash(x, y, 91) < 0.010:
				v = 7 if _hash(x, y, 92) < 0.5 else 8
			L.put(xl, y, SKY, v)
	# Luna creciente.
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			if dx * dx + dy * dy <= 20 and (dx + 2) * (dx + 2) + (dy + 1) * (dy + 1) > 14:
				L.put(262 + dx + M0, 40 + dy, SKY, 10 if dx < 1 else 9)
	# Montañas lejanas.
	for x in range(-M0, W + M0):
		var ridge := int(62.0 + 4.0 * sin(x * 0.05) + 3.0 * sin(x * 0.13 + 1.0) + 2.0 * sin(x * 0.31))
		for y in range(ridge, H):
			L.put(x + M0, y, SKY, 3 if y > ridge else 6)
	# Tejados de la ciudad helada (casi todo apagado; una ventana encendida).
	var x0 := -M0
	var n := 0
	while x0 < W + M0:
		var bw := 6 + int(_hash(n, 3, 7) * 8.0)
		var top := 68 + int(_hash(n, 4, 7) * 7.0)
		var roof := 2 + int(_hash(n, 5, 7) * 4.0)
		for x in range(x0, x0 + bw):
			var rx := mini(x - x0, x0 + bw - 1 - x)
			var ry := top - mini(roof, rx)
			for y in range(ry, H):
				var v := 1
				if y == ry:
					v = 8     # nieve en el caballete
				elif y == ry + 1 and rx < roof:
					v = 6
				L.put(x + M0, y, SKY, v)
		if _hash(n, 9, 7) < 0.45:
			var chx := x0 + 1 + int(_hash(n, 10, 7) * (bw - 3))
			var cty := top - roof - 2
			for y in range(cty, top):
				L.put(chx + M0, y, SKY, 1)
				L.put(chx + 1 + M0, y, SKY, 1)
			L.put(chx + M0, cty, SKY, 8)
			L.put(chx + 1 + M0, cty, SKY, 8)
		if n % 5 == 3:
			L.put(x0 + bw / 2 + M0, top + 3, FIRE, 4)
			L.put(x0 + bw / 2 + 1 + M0, top + 3, FIRE, 5)
		x0 += bw
		n += 1
	return L


# --- L1: el tiro de la Torre (lejos) -----------------------------------------------------

func build_far(P: Dictionary) -> Layer:
	var L := Layer.new(W + 2 * M0, H)
	var R := 70.0
	for y in range(0, FY + 2):
		for xl in L.w:
			var x := xl - M0
			if x < 100 or x > 220:
				continue
			# Muro curvo del tiro: ladrillo a MITAD de escala (3 px) que se estrecha hacia los lados (cilindro).
			var dx := clampf((x - 160.0) / R, -0.98, 0.98)
			var th := asin(dx)
			var row := y / 3
			var ry := y % 3
			var cc := th / (PI * 0.5) * 18.0 + 0.5 * (row % 2)
			var fr := fposmod(cc, 1.0)
			var mortar := ry == 0 or fr < 0.2 / maxf(0.4, cos(th))
			var v := 1
			if absf(dx) > 0.7:
				v -= 1
			# Nervios de piedra del tiro (refuerzan la curvatura).
			var rib := false
			for rth: float in [-0.95, -0.32, 0.32, 0.95]:
				var rx := 160.0 + sin(rth) * R
				var rw := 3.0 * cos(rth) + 0.6
				if absf(x - rx) < rw:
					rib = true
					v = 2 if x < rx else 1
			if rib:
				L.put(xl, y, STONE, v + (1 if y % 9 == 0 else 0))
				continue
			var ci := floorf(cc)
			if mortar:
				L.joint(xl, y, BRICK, v - 1)
			else:
				if _hash(int(ci), row, 33) < 0.15:
					v -= 1
				L.put(xl, y, BRICK, v)
	# Ventanas de otras galerías de la torre.
	for wpos: Vector3i in _far_windows(P):
		# Saetera de 2×4 con dintel: luz de otra galería (encendida o muerta).
		for dy in range(0, 4):
			for dx2 in range(0, 2):
				if wpos.z == 1:
					L.put(wpos.x + dx2 + M0, wpos.y + dy, FIRE, 2 if dy == 0 else (3 if dx2 == 0 else 2))
				else:
					L.put(wpos.x + dx2 + M0, wpos.y + dy, BRICK, 0, -1, -1, true)
		for dx3 in range(-1, 3):
			L.put(wpos.x + dx3 + M0, wpos.y + 4, STONE, 2, wpos.x + M0, wpos.y + 4)
	# Pasarela de hierro que cruza el tiro.
	for xl in L.w:
		var x := xl - M0
		if x < 100 or x > 220:
			continue
		L.put(xl, 66, IRON, 3)
		L.put(xl, 67, IRON, 2)
		L.put(xl, 68, IRON, 1)
		L.put(xl, 75, IRON, 1)
		for yy in range(69, 75):
			var t := yy - 69
			if posmod(x + t, 12) == 0 or posmod(x - t, 12) == 0:
				L.put(xl, yy, IRON, 1)
		if posmod(x, 12) == 0:
			for yy2 in range(60, 66):
				L.put(xl, yy2, IRON, 1)
		L.put(xl, 60, IRON, 2 if posmod(x, 12) != 0 else 3)
	# La gran cadena del tiro, con el cubo de colada.
	var chx := 176
	for y in range(0, 88):
		var ph := y % 12
		if ph < 7:
			if ph == 0 or ph == 6:
				L.put(chx + M0, y, IRON, 2)
			else:
				L.put(chx - 1 + M0, y, IRON, 3)
				L.put(chx + 1 + M0, y, IRON, 1)
		else:
			L.put(chx + M0, y, IRON, 2)
	# Gancho y asa del caldero de colada (cuelga sobre el vacío; aún guarda calor).
	for p: Vector2i in [Vector2i(0, 88), Vector2i(-1, 89), Vector2i(1, 89), Vector2i(-2, 90), Vector2i(2, 90), Vector2i(-3, 91),
			Vector2i(3, 91), Vector2i(-4, 92), Vector2i(4, 92), Vector2i(-5, 93), Vector2i(5, 93)]:
		L.put(chx + p.x + M0, p.y, IRON, 2 if p.x <= 0 else 1)
	var prof := [7, 7, 7, 7, 6, 6, 5, 4, 2]
	for i in prof.size():
		var hw: int = prof[i]
		var y := 94 + i
		for dx5 in range(-hw, hw + 1):
			var v2 := 2
			if dx5 <= -hw + 1:
				v2 = 3
			elif dx5 >= hw - 1:
				v2 = 1
			if i == 0:
				v2 = 4
			L.put(chx + dx5 + M0, y, COPPER, v2)
	for dx6 in range(-6, 7):
		L.put(chx + dx6 + M0, 94, FIRE, 3 if absi(dx6) > 3 else 4)
	L.put(chx - 2 + M0, 98, FIRE, 3)
	L.put(chx - 1 + M0, 99, FIRE, 2)
	return L


# --- L2: muro + suelo (plano de juego) --------------------------------------------------

func soot(x: int, y: int) -> int:
	var s := 0
	if y < 20:
		s = -2
	elif y < 32:
		s = -1
	for b: Vector2i in BRAZ:
		if y < b.y - 5 and y > 6:
			var up := b.y - 5 - y
			var wid := 2.0 + up / 9.0
			var dx := absf(x - b.x + (0.0 if up < 20 else 1.0))
			var rag := _hash(x, y / 3, 17) * 1.5
			if dx < wid * 0.45 + rag * 0.5:
				s = mini(s, -2)
			elif dx < wid + rag:
				s = mini(s, -1)
	return s


## Vetas de brasa del ciclo II: siguen las juntas en zigzag desde 3 focos (no rayas sueltas).
func _vein(x: int, y: int) -> bool:
	for o: Vector2i in [Vector2i(40, 96), Vector2i(244, 100), Vector2i(292, 40)]:
		var dy := o.y - y
		if dy < 0 or dy > 46:
			continue
		var row := y / 5
		var ry := y % 5
		var off := (row % 2) * 6
		var wander := int(_hash(row, o.x, 71) * 3.0) - 1
		var cx := o.x + int(dy * 0.35 * (1 if o.x < 160 else -1)) + wander * 6
		# Tendel horizontal corto o llaga vertical cercana.
		if ry == 0 and absi(x - cx) < 5 - dy / 12:
			return true
		var lx := cx - posmod(cx + off, 12)
		if ry != 0 and x == lx and absi(x - cx) < 7:
			return true
	return false


func build_wall(P: Dictionary) -> Layer:
	var L := Layer.new(W, H)
	var fl: int = P["floor"]
	var cyc: int = P["cycle"]
	var decay := 0.03 + float(fl) * 0.006
	# Ladrillo a soga, 12×5, luz por pieza.
	for y in range(0, FY):
		var row := y / 5
		var ry := y % 5
		var off := (row % 2) * 6
		for x in W:
			var xx := x + off
			var ci := xx / 12
			var rx := xx % 12
			var s := soot(x, y)
			var hb := _hash(ci, row, 11)
			if ry == 0 or rx == 0:
				# Llaga/tendel. Ciclo II: grietas de brasa que recorren algunas juntas (la Torre se recalienta).
				if cyc > 0 and y > 30 and _vein(x, y):
					L.put(x, y, FIRE, 2 if _hash(x, y, 5) < 0.7 else 3)
				else:
					L.joint(x, y, BRICK, 1 + mini(0, s + 1))
				continue
			var v := 2
			if cyc > 0 and y > 30 and (_vein(x, y - 1) or _vein(x, y + 1) or _vein(x - 1, y) or _vein(x + 1, y)):
				v += 2
			if hb < 0.13:
				v -= 1
			elif hb > 0.9:
				v += 1
			v += s
			if ry == 4:
				v -= 1
			elif ry == 1 and rx >= 2:
				v += 0 if s < 0 else 1
			var cx := ci * 12 - off + 6
			var cy := row * 5 + 2
			# Desconchones y grietas (más cuanto más alto el piso del acto).
			var hb2 := _hash(ci, row, 12)
			if hb2 < decay and rx == 2 + ry:
				v = 0
			if hb2 > 1.0 - decay * 0.6 and rx >= 7 and ry >= 2:
				L.put(x, y, BRICK, 1)
				continue
			L.put(x, y, BRICK, v, cx, cy)
	# Hollín en el ladrillo junto al techo (manchas irregulares).
	_beam(L, 0, 100)
	_beam(L, 220, 320)
	_arch(L)
	_pier(L, 100)
	_pier(L, 204)
	_parapet(L)
	_plinth(L, 0, 100)
	_plinth(L, 220, 320)
	_pipe(L)
	_tool_rack(L)
	_window(L)
	for b: Vector2i in BRAZ:
		_brazier(L, b)
	_static_chains(L)
	_floor(L, P)
	return L


func _beam(L: Layer, x0: int, x1: int) -> void:
	for x in range(x0, x1):
		for y in range(6, 14):
			var v := 3
			if y == 6:
				v = 4
			elif y == 12:
				v = 2
			elif y == 13:
				v = 1
			if posmod(x - x0, 34) == 33:
				v = 1
			L.put(x, y, WOOD, v)
		# Herrajes con remaches.
		if posmod(x - x0 - 10, 26) < 3:
			for y2 in range(6, 13):
				L.put(x, y2, IRON, 3 if posmod(x - x0 - 10, 26) == 0 else 2)
			if posmod(x - x0 - 10, 26) == 1:
				L.put(x, 8, IRON, 6)
				L.put(x, 11, IRON, 6)
		# Costra de hollín colgando de la viga.
		if _hash(x, 1, 41) < 0.35:
			var ln := 1 + int(_hash(x, 2, 41) * 3.0)
			for y3 in range(14, 14 + ln):
				L.put(x, y3, ASH, 1)
	for y in range(0, 6):
		for x in range(x0, x1):
			L.put(x, y, BRICK, 0)


func _arch(L: Layer) -> void:
	var c := Vector2(160, 62)
	var segs := 15
	for y in range(0, 63):
		for x in range(108, 213):
			var d := Vector2(x - c.x, y - c.y).length()
			if d < 44.0:
				L.erase(x, y)
			elif d < 51.0 or (d < 54.0 and absf(x - c.x) < 4.0):
				var a := atan2(c.y - y, x - c.x)
				var si := int(a / (PI / segs))
				var fr := a / (PI / segs) - si
				var key := si == segs / 2
				if (fr < 0.09 or fr > 0.96) and not key:
					L.joint(x, y, STONE, 1)
					continue
				var ac := (si + 0.5) * PI / segs
				var v := 3
				if key:
					v = 5
				if d > 50.0 or (key and d > 52.0):
					v -= 2
				elif d < 45.0:
					v += 1
				L.put(x, y, STONE, v + soot(x, y) / 2, int(c.x + cos(ac) * 47.0), int(c.y - sin(ac) * 47.0))
			elif d < 46.0:
				pass
	# Intradós visible (2 px): cara inferior del arco, la ilumina el tiro desde abajo.
	for y in range(18, 63):
		for x in range(115, 206):
			var d := Vector2(x - c.x, y - c.y).length()
			if d >= 42.0 and d < 44.0 and y > 30:
				L.put(x, y, STONE, 2)
	# Hueco bajo la línea de impostas.
	for y in range(62, FY):
		for x in range(116, 204):
			L.erase(x, y)
	# Caras internas de las pilastras (mochetas).
	for y in range(30, 108):
		L.put(116, y, STONE, 2)
		L.put(117, y, STONE, 1)
		L.put(202, y, STONE, 1)
		L.put(203, y, STONE, 2)


func _pier(L: Layer, x0: int) -> void:
	for y in range(14, FY):
		var course := (y - 14) / 10
		var ry := (y - 14) % 10
		var split := course % 2 == 1
		for x in range(x0, x0 + 16):
			var rx := x - x0
			if ry == 0 or (split and rx == 8):
				L.joint(x, y, STONE, 1)
				continue
			var v := 3
			if rx == 0 or rx == 15:
				v = 1
			elif rx == 1:
				v = 4
			elif rx >= 13:
				v = 2
			if ry == 9:
				v -= 1
			var bx := x0 + (4 if split and rx < 8 else (12 if split else 8))
			v += soot(x, y) / 2
			L.put(x, y, STONE, v, bx, 14 + course * 10 + 5)
	# Capitel.
	var rows := [[5, 3], [4, 3], [3, 3], [5, 1], [3, 1], [1, 1]]
	for i in rows.size():
		var r: Array = rows[i]
		for x in range(x0 - int(r[1]), x0 + 16 + int(r[1])):
			L.put(x, 14 + i, STONE, int(r[0]) - (1 if i < 3 else 0))
	# Basa.
	var brows := [5, 4, 3, 3, 3, 3, 2, 1]
	for i in brows.size():
		for x in range(x0 - 2, x0 + 18):
			var v: int = brows[i]
			if x == x0 - 2 or x == x0 + 17:
				v -= 1
			L.put(x, 110 + i, STONE, v)


func _parapet(L: Layer) -> void:
	for x in range(116, 204):
		L.put(x, 104, STONE, 5)
		L.put(x, 105, STONE, 4)
		L.put(x, 106, STONE, 1)
		for y in range(107, FY):
			var bi := (x - 116) / 14
			var joint := posmod(x - 116, 14) == 0 or y == 112
			L.put(x, y, STONE, 1 if joint else (3 if y < 112 else 2), 116 + bi * 14 + 7, 110)
	# Barandilla de hierro: silueta contra el resplandor del tiro.
	for x in range(116, 204):
		L.put(x, 94, IRON, 3)
		L.put(x, 95, IRON, 1)
		if posmod(x - 118, 7) == 0:
			for y in range(96, 104):
				L.put(x, y, IRON, 2 if y < 101 else 1)
		if posmod(x - 118, 7) == 3:
			L.put(x, 99, IRON, 1)
		L.put(x, 102, IRON, 1)


func _plinth(L: Layer, x0: int, x1: int) -> void:
	for x in range(x0, x1):
		for y in range(110, FY):
			var v := 2
			if y == 110:
				v = 4
			elif y == 111:
				v = 3
			elif y == FY - 1:
				v = 1
			if posmod(x - x0, 22) == 0 and y > 110:
				v = 1
			L.put(x, y, STONE, v, x0 + (x - x0) / 22 * 22 + 11, 114)
	# Montones de ceniza contra el zócalo.
	for i in 6:
		var mx := x0 + 8 + int(_hash(i, x0, 55) * (x1 - x0 - 16))
		var mw := 4 + int(_hash(i, x0, 56) * 6.0)
		for dx in range(-mw, mw + 1):
			var hh := int((1.0 - pow(float(dx) / mw, 2.0)) * (2.0 + mw * 0.35))
			for dy in range(0, hh + 1):
				var v2 := 3 if dy == hh else (2 if dx < 0 else 1)
				L.put(mx + dx, FY - 1 - dy, ASH, v2 + 1)


func _pipe(L: Layer) -> void:
	# Conducto de cobre del fuelle: baja hasta la chimenea del horno de combate.
	var prof := [2, 6, 4, 3, 1]
	for x in range(0, 96):
		for i in 5:
			L.put(x, 23 + i, COPPER, prof[i])
		if posmod(x - 6, 22) < 2:
			for y in range(22, 29):
				L.put(x, y, IRON, 4 if posmod(x - 6, 22) == 0 else 2)
			L.put(x, 22, IRON, 5)
	for y in range(23, 86):
		for i in 5:
			L.put(23 + i, y, COPPER, prof[i] if y > 27 else maxi(prof[i], 3))
		if posmod(y - 40, 20) < 2:
			for x in range(22, 29):
				L.put(x, y, IRON, 4 if posmod(y - 40, 20) == 0 else 2)
	# Codo redondeado.
	for dy in range(0, 5):
		for dx in range(0, 5):
			if dx + dy >= 6:
				L.put(27 - 4 + dx, 23 + dy, COPPER, 1)
	# Volante de la válvula.
	var vc := Vector2i(64, 25)
	for a in 24:
		var ang := a * TAU / 24.0
		L.put(vc.x + int(roundf(cos(ang) * 4.0)), vc.y + int(roundf(sin(ang) * 4.0)), IRON, 4 if sin(ang) < 0 else 2)
	for d in range(-3, 4):
		L.put(vc.x + d, vc.y, IRON, 3)
		L.put(vc.x, vc.y + d, IRON, 3)
	L.put(vc.x, vc.y, FIRE, 3)


func _tool_rack(L: Layer) -> void:
	# Barra de madera con tenazas, martillo y cazo colgados (fue una herrería).
	for x in range(34, 66):
		L.put(x, 40, WOOD, 5)
		L.put(x, 41, WOOD, 3)
		L.put(x, 42, WOOD, 1)
	for pg: int in [35, 64]:
		L.put(pg, 39, IRON, 4)
		L.put(pg, 43, IRON, 2)
	# Sombra proyectada (la luz viene de abajo-derecha: brasero).
	var tools: Array = []
	# Tenazas.
	for y in range(42, 58):
		var spread := 0 if y < 50 else (y - 50) / 2
		tools.append([39 - spread, y, IRON, 4])
		tools.append([41 + spread, y, IRON, 2])
	tools.append([40, 49, IRON, 5])
	# Martillo.
	for y in range(42, 55):
		tools.append([48, y, WOOD, 5])
		tools.append([49, y, WOOD, 3])
	for y in range(54, 58):
		for x in range(45, 53):
			tools.append([x, y, IRON, 5 if y == 54 else (4 if x < 49 else 2)])
	# Cazo.
	for y in range(42, 53):
		tools.append([57, y, IRON, 3])
	for y in range(53, 57):
		for x in range(54 + (y - 53) / 2, 61 - (y - 53) / 2):
			tools.append([x, y, IRON, 4 if y == 53 else 2])
	for t: Array in tools:
		L.shift(int(t[0]) - 1, int(t[1]) - 1, -2)
	for t: Array in tools:
		L.put(int(t[0]), int(t[1]), int(t[2]), int(t[3]))


func _window(L: Layer) -> void:
	var c := Vector2(266, 42)
	for y in range(26, 82):
		for x in range(250, 283):
			var dx := float(x - c.x)
			if y < c.y:
				var d := Vector2(dx, y - c.y).length()
				if d < 10.0:
					L.erase(x, y)
				elif d < 14.0:
					# Dovelas radiales (7).
					var a := atan2(c.y - y, dx)
					var si := int(a / (PI / 7.0))
					var fr := a / (PI / 7.0) - si
					if fr < 0.12:
						L.joint(x, y, STONE, 1)
						continue
					var ac := (si + 0.5) * PI / 7.0
					var v := 3 if d < 11.0 else (2 if d < 13.0 else 1)
					L.put(x, y, STONE, v, int(c.x + cos(ac) * 12.0), int(c.y - sin(ac) * 12.0))
			else:
				var ax := absf(dx)
				if ax < 10.0:
					L.erase(x, y)
				elif ax < 14.0:
					# Jambas en hiladas de 8 alternas.
					var course := (y - 42) / 8
					var ry := (y - 42) % 8
					var deep := 13.0 if course % 2 == 0 else 12.0
					if ax >= deep + 1.0:
						continue
					if ry == 0:
						L.joint(x, y, STONE, 1)
						continue
					var v2 := 3 if ax < 11.0 else 2
					L.put(x, y, STONE, v2, int(c.x + signf(dx) * 12.0), 42 + course * 8 + 4)
	# Parteluz y travesaños de hierro.
	for y in range(31, 82):
		L.put(266, y, IRON, 1)
	for x in range(256, 277):
		L.put(x, 56, IRON, 1)
		L.put(x, 69, IRON, 1)
	# Escarcha en las esquinas del vidrio.
	for p: Vector2i in [Vector2i(257, 80), Vector2i(258, 81), Vector2i(257, 81), Vector2i(275, 81), Vector2i(274, 81), Vector2i(267, 55), Vector2i(265, 68)]:
		L.put(p.x, p.y, SKY, 8)
	# Alféizar con nieve que ha entrado.
	var sill := [5, 4, 2, 1]
	for i in 4:
		for x in range(251, 282):
			L.put(x, 82 + i, STONE, sill[i])
	for x in range(253, 280):
		var hh := 1 + int(_hash(x, 0, 61) * 1.8) - (1 if x < 256 or x > 276 else 0)
		for y in range(82 - hh, 82):
			L.put(x, y, SKY, 9 if y == 82 - hh else 8)


func _brazier(L: Layer, b: Vector2i) -> void:
	# Sombra del brasero en la pared (la llama está encima: sombra hacia abajo).
	for y in range(b.y + 3, b.y + 14):
		for x in range(-2, 3):
			L.shift(b.x + x, y, -1)
	# Placa y brazo de hierro (valores a mano: la llama no ilumina su propio herraje por debajo).
	for y in range(b.y + 2, b.y + 11):
		L.put(b.x, y, IRON, 2, -1, -1, true)
		L.put(b.x + 1, y, IRON, 1, -1, -1, true)
	for i in 4:
		L.put(b.x - 2 + i, b.y + 7 - i, IRON, 1, -1, -1, true)
	L.put(b.x - 1, b.y + 10, IRON, 3, -1, -1, true)
	L.put(b.x + 2, b.y + 10, IRON, 1, -1, -1, true)
	L.put(b.x, b.y + 11, IRON, 1, -1, -1, true)
	# Cuenco: borde superior encendido por las brasas, cuerpo en sombra.
	var rows := [[-5, 5, 6], [-4, 4, 3], [-3, 3, 2], [-2, 2, 1]]
	for i in rows.size():
		var r: Array = rows[i]
		for x in range(int(r[0]), int(r[1]) + 1):
			var v: int = r[2]
			if x == int(r[0]) and i > 0:
				v += 1
			elif x >= int(r[1]) - 1 and i > 0:
				v -= 1
			L.put(b.x + x, b.y - 1 + i, IRON, v, -1, -1, true)
	# Lecho de brasas (emisivo).
	for x in range(-4, 5):
		L.put(b.x + x, b.y - 2, FIRE, 4 if absi(x) < 3 else 3, -1, -1)


func _static_chains(L: Layer) -> void:
	for cx: int in [230, 312]:
		var ln := 18 if cx == 230 else 30
		for y in range(14, 14 + ln):
			var ph := (y - 14) % 6
			if ph == 0 or ph == 5:
				L.put(cx, y, IRON, 2)
			elif ph < 5 and ((y - 14) / 6) % 2 == 0:
				L.put(cx - 1, y, IRON, 3)
				L.put(cx + 1, y, IRON, 1)
			else:
				L.put(cx, y, IRON, 2)
		L.put(cx, 14 + ln, IRON, 3)
		L.put(cx + 1, 15 + ln, IRON, 2)
		L.put(cx - 1, 15 + ln, IRON, 2)


func _floor(L: Layer, P: Dictionary) -> void:
	var vy := float(FY - 24)
	var heat: float = P["heat"]
	for y in range(FY, H):
		var depth := (H - vy) / (float(y) - vy)
		var rowf := depth * 1.4
		var nxt := (H - vy) / (float(y + 1) - vy) * 1.4
		var hline := int(rowf) != int(nxt)
		var ri := int(rowf)
		for x in W:
			var u := (x - 160.0) * depth / 2.0 + 11.0
			var ci := int(floor(u / 22.0))
			var vline := fposmod(u, 22.0) < depth * 0.5
			var dc := (ri + 0.5) / 1.4
			var yc := int(vy + (H - vy) / dc)
			var xc := int(160.0 + ((ci + 0.5) * 22.0 - 11.0) * 2.0 / dc)
			var v := 2 if _hash(ci, ri, 21) < 0.6 else 1
			if hline or vline:
				L.joint(x, y, STONE, 0 if y > 150 else 1)
				continue
			if y == FY:
				v = 5
			elif y == FY + 1:
				v = 1
			elif y == FY + 2:
				v = mini(v, 2)
			if y > 148:
				v -= 1
			if y > 158:
				v -= 1
			if y > 168:
				v -= 1
			# Hollín y carbonilla.
			# Carbonilla agrupada (no ruido): sólo en manchas, y pocas pavesas cerca de la rejilla.
			var blot := _hash(x / 6, y / 3, 25) < 0.18
			if blot and _hash(x, y, 23) < 0.10 and y > FY + 2 and y < 160:
				L.put(x, y, ASH, 0)
				continue
			if _hash(x, y, 24) < 0.004 and y > FY + 3 and y < 140 and absi(x - 160) < 60:
				L.put(x, y, FIRE, 2 if _hash(x, y, 26) < 0.6 else 3)
				continue
			L.put(x, y, STONE, v, xc, clampi(yc, FY, H - 1))
	# Rejilla central: el calor de la Forja sube por ella.
	var hot := clampi(2 + int(heat * 3.0), 2, 5)
	for y in range(FY + 3, FY + 10):
		var hw := 9 + (y - FY - 3)
		for x in range(160 - hw, 160 + hw + 1):
			var edge := x == 160 - hw or x == 160 + hw or y == FY + 3 or y == FY + 9
			if edge:
				L.put(x, y, IRON, 3 if y == FY + 3 else 1)
			elif posmod(x - 160, 3) == 0 or y == FY + 6:
				L.put(x, y, IRON, 1)
			else:
				var core := absi(x - 160) < hw / 2 and y > FY + 4 and y < FY + 8
				L.put(x, y, FIRE, hot + (1 if core else 0) - (1 if absi(x - 160) > hw - 3 else 0))
	# Cascotes: el deterioro crece con el piso dentro del acto (la torre se desmorona hacia el jefe).
	var fl: int = P["floor"]
	for i in fl:
		var rx := 60 + int(_hash(i, 5, 99) * 210.0)
		if absi(rx - 160) < 24:
			continue
		var ry := FY + 2 + int(_hash(i, 6, 99) * 8.0)
		var big := _hash(i, 7, 99) < 0.4
		for dx in range(0, 4 if big else 3):
			L.put(rx + dx, ry, BRICK, 5 if dx < 2 else 4)
			L.put(rx + dx, ry + 1, BRICK, 3)
		if big:
			for dx2 in range(1, 3):
				L.put(rx + dx2, ry - 1, BRICK, 6)
		L.put(rx + (4 if big else 3), ry + 1, STONE, 0)
	# Ceniza arrastrada hacia la pared y carbón suelto.
	for i in 7:
		var cx := 70 + int(_hash(i, 2, 88) * 180.0)
		if absi(cx - 160) < 22:
			continue
		var cy := FY + 4 + int(_hash(i, 3, 88) * 14.0)
		L.put(cx, cy, ASH, 1)
		L.put(cx + 1, cy, ASH, 0)
		L.put(cx, cy - 1, ASH, 3)


# --- L4: primer plano ---------------------------------------------------------------------

func build_fore(P: Dictionary) -> Layer:
	var L := Layer.new(W + 2 * M4, H)
	# Riostra diagonal tiznada (esquina superior izquierda).
	for i in range(0, 30):
		for t in 5:
			var x := i + M4 - 4
			var y := 26 - i + t
			L.put(x, y, WOOD, 1 if t > 0 and t < 4 else 0, -1, -1, true)
	for x in range(0, 30):
		for y in range(0, 4):
			L.put(x, y, WOOD, 0, -1, -1, true)
	# Cadena con gancho en primer plano (izquierda).
	var cx := 12 + M4
	for y in range(0, 50):
		var ph := y % 8
		if ph == 0 or ph == 7:
			L.put(cx, y, IRON, 0, -1, -1, true)
		elif (y / 8) % 2 == 0:
			L.put(cx - 1, y, IRON, 0, -1, -1, true)
			L.put(cx + 1, y, IRON, 2, -1, -1, true)
			if ph > 1 and ph < 6:
				L.put(cx - 2, y, IRON, 0, -1, -1, true)
				L.put(cx + 2, y, IRON, 1, -1, -1, true)
		else:
			L.put(cx, y, IRON, 1, -1, -1, true)
			L.put(cx + 1, y, IRON, 2, -1, -1, true)
	# Gancho.
	var hook := [Vector2i(0, 50), Vector2i(0, 51), Vector2i(0, 52), Vector2i(1, 53), Vector2i(2, 54), Vector2i(3, 54), Vector2i(4, 53),
		Vector2i(4, 52), Vector2i(-1, 50), Vector2i(-1, 51), Vector2i(-1, 52), Vector2i(0, 53), Vector2i(1, 54), Vector2i(4, 51)]
	for p: Vector2i in hook:
		L.put(cx + p.x, p.y, IRON, 2 if p.x > 0 else 0, -1, -1, true)
	# Polea y cuerda (derecha).
	var pc := Vector2i(W - 12 + M4, 6)
	for dy in range(-6, 7):
		for dx in range(-6, 7):
			var d := dx * dx + dy * dy
			if d <= 36:
				L.put(pc.x + dx, pc.y + dy, IRON, (2 if dx + dy < -2 else 1) if d > 12 else 0, -1, -1, true)
	for y in range(6, 40):
		L.put(pc.x + 6, y, WOOD, 2 if y % 3 else 1, -1, -1, true)
		L.put(pc.x + 7, y, WOOD, 1, -1, -1, true)
	return L


# --- animaciones ambientales (se pintan sobre la imagen compuesta) -------------------------

func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Llama de brasero: base en gota + 3 lenguas que suben, menguan y se separan (bucle de 8 fotogramas).
func draw_flame(img: Image, bx: int, by: int, k: int, big: float = 1.0) -> void:
	var ph := float(k % 8) / 8.0
	for yy in range(-18, 1):
		for xx in range(-6, 7):
			var f := 0.0
			var dy := float(yy) + 2.5
			var ry := 4.2 if dy < 0.0 else 2.6
			f = 1.0 - Vector2(xx / (3.4 * big), dy / (ry * big)).length()
			for j in 3:
				var p := fposmod(ph + j / 3.0, 1.0)
				var ty := (-3.5 - p * 12.0) * big
				var tx := sin(p * TAU + j * 2.1) * 1.2 + (j - 1) * 0.7 * (1.0 - p)
				var tr := (2.5 * (1.0 - p) + 0.7) * big
				var d := Vector2((xx - tx) / tr, (yy - ty) / (tr * 1.6)).length()
				f = maxf(f, (1.0 - d) * (1.0 - p * 0.35))
			if f <= 0.0:
				continue
			var lowness := clampf((yy + 16.0) / 16.0, 0.0, 1.0)
			var hv := f * (0.55 + 0.45 * lowness)
			var v := 2
			if hv > 0.62:
				v = 7
			elif hv > 0.48:
				v = 6
			elif hv > 0.34:
				v = 5
			elif hv > 0.2:
				v = 4
			elif hv > 0.08:
				v = 3
			px(img, bx + xx, by + yy, col(FIRE, v))


## Humo: 3 bocanadas que suben, derivan hacia el tiro y se erosionan (sin transparencia).
func draw_smoke(img: Image, bx: int, top: int, k: int, sd: int) -> void:
	# Las bocanadas viejas primero (detrás). Cada una crece, se aclara hacia el borde de la luz y al final
	# se «deshace» por dentro (huecos estables en coordenadas de la bocanada, no ruido por fotograma).
	var order: Array = []
	for j in 4:
		order.append([fposmod(float(k % 8) / 8.0 + j / 4.0, 1.0), j])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for e: Array in order:
		var p: float = e[0]
		var j: int = e[1]
		var cy := top - 1.0 - p * 22.0
		var cx := bx + p * p * 6.0 + sin(p * 4.0 + sd + j) * 1.2
		var r := 1.0 + p * 2.6
		var icx := int(roundf(cx))
		var icy := int(roundf(cy))
		for dy in range(-5, 6):
			for dx in range(-5, 6):
				var d := Vector2(dx, dy * 1.25).length()
				if d > r:
					continue
				if p > 0.5 and _hash(dx + 7, dy + 7, j + sd * 5) < (p - 0.5) * 1.6:
					continue
				# Iluminada desde abajo por la llama: borde inferior más claro y cálido.
				var v := 3 if p < 0.45 else 2
				if dy > 0 and d > r - 1.2 and p < 0.6:
					px(img, icx + dx, icy + dy, col(BRICK, 5))
					continue
				if dy < 0 and dx < 0 and d > r - 1.2:
					v += 1
				px(img, icx + dx, icy + dy, col(ASH, v))


func draw_embers(img: Image, bx: int, by: int, k: int, sd: int, n: int = 3) -> void:
	for i in n:
		var p := fposmod(float(k % 8) / 8.0 + i * 0.37 + sd * 0.13, 1.0)
		if p > 0.88:
			continue
		var y := by - 6 - int(p * 26.0)
		var x := bx + int(roundf(sin(p * 7.0 + i * 2.0 + sd) * 2.0 + (i - 1) * 1.5))
		var v := 7 - int(p * 4.5)
		px(img, x, y, col(FIRE, v))
		if p < 0.25:
			px(img, x, y + 1, col(FIRE, v - 2))


## Cadena con crisol: péndulo redibujado por fotograma (sin rotar sprites). 16 posiciones.
func draw_crucible(img: Image, k: int) -> void:
	var dxb := chain_dx(k)
	var p0 := CRUCIBLE_PIVOT
	for t in range(0, CHAIN_LEN):
		var x := p0.x + int(roundf(float(dxb) * t / CHAIN_LEN))
		var y := p0.y + t
		var ph := t % 6
		if ph == 0 or ph == 5:
			px(img, x, y, col(IRON, 2))
		elif (t / 6) % 2 == 0:
			px(img, x - 1, y, col(IRON, 4))
			px(img, x + 1, y, col(IRON, 1))
		else:
			px(img, x, y, col(IRON, 3))
	var cx := p0.x + dxb
	var top := p0.y + CHAIN_LEN
	# Asa.
	for p: Vector2i in [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 2), Vector2i(2, 2), Vector2i(-3, 3), Vector2i(3, 3)]:
		px(img, cx + p.x, top + p.y, col(IRON, 4 if p.x <= 0 else 2))
	var glow := 5 + (k / 2) % 2
	for x in range(-4, 5):
		px(img, cx + x, top + 4, col(IRON, 5) if absi(x) == 4 else col(FIRE, glow if absi(x) < 3 else glow - 1))
	var body := [[4, 5], [4, 6], [4, 7], [3, 8], [2, 9]]
	for r: Array in body:
		var hw: int = r[0]
		var y: int = top + int(r[1])
		for x in range(-hw, hw + 1):
			var v := 3
			if x == -hw:
				v = 4
			elif x >= hw - 1:
				v = 1
			elif x > 0:
				v = 2
			px(img, cx + x, y, col(IRON, v))
	px(img, cx - 1, top + 6, col(FIRE, 4))
	px(img, cx - 1, top + 7, col(FIRE, 3))


func draw_shaft_sparks(img: Image, k: int, n: int) -> void:
	for i in n:
		var p := fposmod(float(k) / 16.0 + float(i) / n + _hash(i, 0, 3) * 0.3, 1.0)
		var y := 104 - int(p * 86.0)
		var x := 128 + int(_hash(i, 1, 3) * 64.0) + int(roundf(sin(p * 9.0 + i) * 2.0))
		var v := 6 - int(p * 3.5)
		px(img, x, y, col(FIRE, v))


func draw_snow(img: Image, k: int) -> void:
	for i in 7:
		var p := fposmod(float(k) / 16.0 + float(i) / 7.0, 1.0)
		var y := 30 + int(p * 52.0)
		var x := 257 + (i * 5) % 19 + int(roundf(sin(p * 6.0 + i)))
		px(img, x, y, col(SKY, 9))


func draw_motes(img: Image, k: int) -> void:
	for i in 14:
		var x0 := 20 + int(_hash(i, 7, 9) * 280.0)
		var y0 := 30 + int(_hash(i, 8, 9) * 80.0)
		var a := TAU * float(k % 16) / 16.0 + i
		var x := x0 + int(roundf(1.6 * sin(a)))
		var y := y0 + int(roundf(1.6 * cos(a * 1.0 + i * 0.7)))
		var near := false
		for b: Vector2i in BRAZ:
			if Vector2(x - b.x, y - b.y).length() < 26.0:
				near = true
		px(img, x, y, col(FIRE, 4) if near else col(ASH, 5))


# --- composición -------------------------------------------------------------------------

func blit(dst: Image, src: Image, ox: int, oy: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(ox, oy))


func compose(P: Dictionary, k: int, with_life: bool, fighters: bool, layers: Dictionary, par: int = 0) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color("0b0709"))
	var sky: Image = layers["sky"]
	var far: Image = layers["far"]
	var fore: Image = layers["fore"]
	blit(img, sky, -M0 + par, 0)
	if with_life:
		draw_snow(img, k)
	blit(img, far, -M0 + par, 0)
	if with_life:
		draw_shaft_sparks(img, k, 5 + int(float(P["heat"]) * 6.0))
	var wall := render(layers["wall_l"], wall_lights(P, k if with_life else 0), 0)
	blit(img, wall, 0, 0)
	if with_life:
		for i in BRAZ.size():
			var b: Vector2i = BRAZ[i]
			draw_smoke(img, b.x, b.y - 14, k + i * 3, 5 + i)
			draw_flame(img, b.x, b.y - 2, k + i * 3)
			draw_embers(img, b.x, b.y - 4, k + i * 5, i)
		draw_crucible(img, k)
	else:
		for b: Vector2i in BRAZ:
			draw_flame(img, b.x, b.y - 2, 0)
		draw_crucible(img, 0)
	if fighters:
		_draw_fighters(img, k)
	if with_life:
		draw_motes(img, k)
	blit(img, fore, -M4 - par * 2, 0)
	return img


func _draw_fighters(img: Image, k: int) -> void:
	var fur := Art.furnace_small(0.6, k % 4).get_image()
	fur.convert(Image.FORMAT_RGBA8)
	blit(img, fur, 2, FY - fur.get_height() + 1)
	var pose := "idle" if (k / 4) % 2 == 0 else "idle_b"
	var pl := Art.player_pose(pose).get_image()
	pl.convert(Image.FORMAT_RGBA8)
	blit(img, pl, 30, FY - 46)
	var mons := [["golem", 206], ["bird", 248], ["slime", 288]]
	for i in mons.size():
		var m: Array = mons[i]
		var mp := "base" if ((k + i * 2) / 4) % 2 == 0 else "crouch"
		var t := Art.monster_pose(String(m[0]), "poc%d" % i, 0, 0, mp).get_image()
		t.convert(Image.FORMAT_RGBA8)
		var lift := Art.monster_lift(String(m[0]))
		blit(img, t, int(m[1]) - t.get_width() / 2, FY - t.get_height() + 1 - lift)


func ui_dim(img: Image) -> Image:
	var o := img.duplicate() as Image
	for y in H:
		if y >= 13 and y < 136:
			continue
		for x in W:
			var c := o.get_pixel(x, y)
			o.set_pixel(x, y, Color(c.r * 0.45, c.g * 0.45, c.b * 0.45, 1.0))
	return o


func up(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c


func sheet(imgs: Array, s: int, cols: int, bg: Color, pad: int = 4) -> Image:
	var cw := 0
	var ch := 0
	for i: Image in imgs:
		cw = maxi(cw, i.get_width() * s)
		ch = maxi(ch, i.get_height() * s)
	var rows := int(ceil(imgs.size() / float(cols)))
	var out := Image.create(cols * (cw + pad) + pad, rows * (ch + pad) + pad, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	for n in imgs.size():
		var i: Image = up(imgs[n], s)
		blit(out, i, pad + (n % cols) * (cw + pad), pad + (n / cols) * (ch + pad))
	return out


func checker(w: int, h: int) -> Image:
	var c := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			c.set_pixel(x, y, Color("2a2a30") if ((x / 4 + y / 4) % 2 == 0) else Color("34343c"))
	return c


func make_layers(P: Dictionary) -> Dictionary:
	var sky_l := build_sky(P)
	var far_l := build_far(P)
	var fore_l := build_fore(P)
	return {
		"sky": render(sky_l, [], M0),
		"far": render(far_l, far_lights(P), M0),
		"fore": render(fore_l, [], M4),
		"wall_l": build_wall(P),
	}


func _make_all() -> void:
	var P := {"floor": 4, "heat": 0.5, "cycle": 0}
	var layers := make_layers(P)
	# 1) Fondo limpio ×4 (1280×720) y en contexto (luchadores + zonas de interfaz atenuadas).
	var clean := compose(P, 0, true, false, layers)
	up(clean, 4).save_png(OUT + "a1_fondo_x4.png")
	var ctx := compose(P, 0, true, true, layers)
	up(ui_dim(ctx), 4).save_png(OUT + "a1_contexto_x4.png")
	# 2) Capas por separado (×2) sobre damero.
	var caps: Array = []
	for key: String in ["sky", "far"]:
		var ck := checker(W + 2 * M0, H)
		blit(ck, layers[key], 0, 0)
		caps.append(ck)
	var wl := checker(W, H)
	blit(wl, render(layers["wall_l"], wall_lights(P, 0), 0), 0, 0)
	caps.append(wl)
	var fc := checker(W + 2 * M4, H)
	blit(fc, layers["fore"], 0, 0)
	caps.append(fc)
	sheet(caps, 2, 2, Color("101014"), 8).save_png(OUT + "a1_capas_x2.png")
	# 3) Antes / después (×2).
	var old := Art.background(0, 4, 0).get_image()
	old.convert(Image.FORMAT_RGBA8)
	var oldn := Art.background_near(0, 4, 0).get_image()
	oldn.convert(Image.FORMAT_RGBA8)
	blit(old, oldn, -8, 0)
	var oldc := old.duplicate() as Image
	_draw_fighters(oldc, 0)
	sheet([ui_dim(oldc), ui_dim(ctx)], 2, 2, Color("101014"), 8).save_png(OUT + "a1_antes_despues_x2.png")
	# 4) Hoja de 16 fotogramas de la escena viva (×1) + GIF real ×2.
	var frames: Array = []
	for k in 16:
		frames.append(compose(P, k, true, true, layers))
	sheet(frames.slice(0, 8), 1, 4, Color("101014"), 4).save_png(OUT + "a1_hoja_8f_x1.png")
	var gif_frames: Array = []
	for f: Image in frames:
		gif_frames.append(up(ui_dim(f), 2))
	write_gif(ProjectSettings.globalize_path(OUT + "a1_vivo_x2.gif"), gif_frames, 11)
	# 5) Tiras ampliadas: brasero (8 f, 100 ms) y crisol (8 de las 16 posiciones).
	var braz: Array = []
	var cru: Array = []
	for k in 8:
		var f: Image = compose(P, k, true, false, layers)
		braz.append(f.get_region(Rect2i(62, 22, 36, 56)))
		var f2: Image = compose(P, k * 2, true, false, layers)
		cru.append(f2.get_region(Rect2i(282, 8, 36, 64)))
	sheet(braz, 5, 8, Color("101014"), 4).save_png(OUT + "anim_brasero_8f_x5.png")
	sheet(cru, 5, 8, Color("101014"), 4).save_png(OUT + "anim_crisol_8f_x5.png")
	# 6) Variaciones por estado del juego (×2): piso, calor de la Forja, ciclo.
	var vars: Array = []
	for vp: Dictionary in [{"floor": 1, "heat": 0.1, "cycle": 0}, {"floor": 9, "heat": 0.5, "cycle": 0},
			{"floor": 4, "heat": 1.0, "cycle": 0}, {"floor": 4, "heat": 0.6, "cycle": 1}]:
		var lv := make_layers(vp)
		vars.append(ui_dim(compose(vp, 3, true, true, lv)))
	sheet(vars, 2, 2, Color("101014"), 8).save_png(OUT + "a1_variaciones_x2.png")


# --- GIF89a animado (LZW «sin compresión»: códigos de 9 bits con CLEAR cada 250) -------------

func write_gif(path: String, frames: Array, delay_cs: int) -> void:
	var w: int = (frames[0] as Image).get_width()
	var h: int = (frames[0] as Image).get_height()
	var pal := {}
	var cols: Array = []
	var idx_frames: Array = []
	for img: Image in frames:
		var data := PackedByteArray()
		data.resize(w * h)
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var key := (c.r8 << 16) | (c.g8 << 8) | c.b8
				if not pal.has(key):
					if cols.size() < 256:
						pal[key] = cols.size()
						cols.append(key)
					else:
						pal[key] = _nearest(cols, key)
				data[y * w + x] = pal[key]
		idx_frames.append(data)
	var out := PackedByteArray()
	out.append_array("GIF89a".to_ascii_buffer())
	_u16(out, w)
	_u16(out, h)
	out.append(0xF7)
	out.append(0)
	out.append(0)
	for i in 256:
		var c: int = cols[i] if i < cols.size() else 0
		out.append((c >> 16) & 255)
		out.append((c >> 8) & 255)
		out.append(c & 255)
	out.append_array(PackedByteArray([0x21, 0xFF, 0x0B]))
	out.append_array("NETSCAPE2.0".to_ascii_buffer())
	out.append_array(PackedByteArray([3, 1, 0, 0, 0]))
	for data: PackedByteArray in idx_frames:
		out.append_array(PackedByteArray([0x21, 0xF9, 4, 0x04]))
		_u16(out, delay_cs)
		out.append_array(PackedByteArray([0, 0]))
		out.append(0x2C)
		_u16(out, 0)
		_u16(out, 0)
		_u16(out, w)
		_u16(out, h)
		out.append(0)
		out.append(8)
		var bits := PackedByteArray()
		var acc := 0
		var nb := 0
		var codes := PackedInt32Array()
		codes.append(256)
		var run := 0
		for v: int in data:
			codes.append(v)
			run += 1
			if run >= 250:
				codes.append(256)
				run = 0
		codes.append(257)
		for c2: int in codes:
			acc |= c2 << nb
			nb += 9
			while nb >= 8:
				bits.append(acc & 255)
				acc >>= 8
				nb -= 8
		if nb > 0:
			bits.append(acc & 255)
		var p := 0
		while p < bits.size():
			var n := mini(255, bits.size() - p)
			out.append(n)
			out.append_array(bits.slice(p, p + n))
			p += n
		out.append(0)
	out.append(0x3B)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(out)
	f.close()


func _u16(out: PackedByteArray, v: int) -> void:
	out.append(v & 255)
	out.append((v >> 8) & 255)


func _nearest(cols: Array, key: int) -> int:
	var best := 0
	var bd := 1 << 30
	for i in cols.size():
		var c: int = cols[i]
		var d := absi(((c >> 16) & 255) - ((key >> 16) & 255)) + absi(((c >> 8) & 255) - ((key >> 8) & 255)) + absi((c & 255) - (key & 255))
		if d < bd:
			bd = d
			best = i
	return best
