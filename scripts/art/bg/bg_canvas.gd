class_name BgCanvas
extends RefCounted
## Lienzo de fondo en formato ÍNDICE (MV · v0.4). Cada píxel guarda material, valor base, banderas y el
## ANCLA de su pieza (centro del ladrillo / sillar / losa). La luz se evalúa en el ancla → cae pieza a pieza.
##
## Formato: textura de índice v1 de TEC (`IndexFormat`, docs/reviews/v04/tecnico/formato_indice.md). Todo el
## empaquetado pasa por `_pack()` → `IndexFormat.pack()`. R = `Palette.index(material)`, G = paso + JUNTA/CANTO/EMISIVO/FRÍO,
## B/A = 128 + (ancla − píxel). CANTO: si la luz horneada ya da ≥ 2 pasos, el +1 se hornea y la bandera se QUITA
## (para que la luz dinámica no lo sume dos veces); si no, se deja para que el shader lo active con luz dinámica.
## La vista previa en color es exactamente lo que el shader produce con luz dinámica 0.

const F_JOINT := 1
const F_BEVEL := 2
const F_FIXED := 4

var w: int
var h: int
## Desplazamiento de este lienzo respecto a las coordenadas del mundo (márgenes de parallax).
var ox: int = 0
var mat: PackedByteArray
var val: PackedInt32Array
var ax: PackedInt32Array
var ay: PackedInt32Array
var flags: PackedByteArray


func _init(pw: int, ph: int, p_ox: int = 0) -> void:
	w = pw
	h = ph
	ox = p_ox
	var n := pw * ph
	mat = PackedByteArray()
	mat.resize(n)
	val = PackedInt32Array()
	val.resize(n)
	ax = PackedInt32Array()
	ax.resize(n)
	ax.fill(-1)
	ay = PackedInt32Array()
	ay.resize(n)
	ay.fill(-1)
	flags = PackedByteArray()
	flags.resize(n)


## Pinta en coordenadas del MUNDO (se suma `ox`). Ancla (-1,-1) = el propio píxel.
func put(x: int, y: int, m: int, v: int, anc: Vector2i = Vector2i(-1, -1), f: int = 0) -> void:
	var lx := x + ox
	if lx < 0 or y < 0 or lx >= w or y >= h:
		return
	var i := y * w + lx
	mat[i] = m
	val[i] = v
	ax[i] = anc.x + ox if anc.x >= 0 else -1
	ay[i] = anc.y if anc.x >= 0 else -1
	flags[i] = f


func joint(x: int, y: int, m: int, v: int) -> void:
	put(x, y, m, v, Vector2i(-1, -1), F_JOINT)


func fixed(x: int, y: int, m: int, v: int) -> void:
	put(x, y, m, v, Vector2i(-1, -1), F_FIXED)


func has(x: int, y: int) -> bool:
	var lx := x + ox
	return lx >= 0 and y >= 0 and lx < w and y < h and mat[y * w + lx] != 0


func mat_at(x: int, y: int) -> int:
	var lx := x + ox
	if lx < 0 or y < 0 or lx >= w or y >= h:
		return 0
	return mat[y * w + lx]


func shift(x: int, y: int, dv: int) -> void:
	if has(x, y):
		val[y * w + x + ox] += dv


func add_flag(x: int, y: int, f: int) -> void:
	if has(x, y):
		flags[y * w + x + ox] |= f


func erase(x: int, y: int) -> void:
	var lx := x + ox
	if lx >= 0 and y >= 0 and lx < w and y < h:
		mat[y * w + lx] = 0


# --- luces ---------------------------------------------------------------------------------------
# Punto: {"t":"pt","p":Vector2,"r":[radios],"ys":escala vertical,"cold":bool,"y0","y1","gain"}
# Paralelogramo (luz de ventana en el suelo): {"t":"skew","cold":true,"ya","yb","xa0","xa1","xb0","xb1"}

static func steps_at(q: Vector2, lights: Array, cold: bool) -> int:
	var best := 0
	for L: Dictionary in lights:
		if bool(L.get("cold", false)) != cold:
			continue
		if q.y < float(L.get("y0", -9999)) or q.y > float(L.get("y1", 9999)):
			continue
		if q.x < float(L.get("x0", -9999)) or q.x > float(L.get("x1", 9999)):
			continue
		var s := 0
		if L["t"] == "pt":
			var p: Vector2 = L["p"]
			var d := Vector2(q.x - p.x, (q.y - p.y) * float(L.get("ys", 1.0))).length()
			for r: float in L["r"]:
				if d < r:
					s += 1
		elif L["t"] == "skew":
			var t := (q.y - float(L["ya"])) / maxf(1.0, float(L["yb"]) - float(L["ya"]))
			if t >= 0.0 and t <= 1.0:
				var xa: float = lerpf(float(L["xa0"]), float(L["xb0"]), t)
				var xb: float = lerpf(float(L["xa1"]), float(L["xb1"]), t)
				if q.x >= xa and q.x <= xb:
					s = 2 if minf(q.x - xa, xb - q.x) > 6.0 and t > 0.1 and t < 0.8 else 1
		if s > 0:
			s += int(L.get("gain", 0))
		best = maxi(best, s)
	return best


## Hornea el lienzo (o un rectángulo de él, en coordenadas locales) a índice + vista previa.
func bake(lights: Array, rect: Rect2i = Rect2i()) -> Dictionary:
	if rect.size == Vector2i.ZERO:
		rect = Rect2i(0, 0, w, h)
	var idx := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var pre := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	idx.fill(Color(0, 0, 0, 0))
	pre.fill(Color(0, 0, 0, 0))
	var cache := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var i := y * w + x
			var m := mat[i]
			if m == 0:
				continue
			var f := flags[i]
			var v := val[i]
			var step := v
			var cold := false
			var emissive: bool = BgRamps.is_emissive(m) or (f & F_FIXED) != 0
			var bevel_left := (f & F_BEVEL) != 0
			var qx := ax[i] if ax[i] >= 0 else x
			var qy := ay[i] if ay[i] >= 0 else y
			if not emissive:
				var key := qy * 8192 + qx
				var wc: Vector2i
				if cache.has(key):
					wc = cache[key]
				else:
					var q := Vector2(qx - ox, qy)
					wc = Vector2i(steps_at(q, lights, false), steps_at(q, lights, true))
					cache[key] = wc
				if (f & F_JOINT) != 0:
					wc = Vector2i(maxi(0, wc.x - 1), maxi(0, wc.y - 1))
				if wc.y > wc.x:
					cold = true
					step = v + wc.y
				else:
					step = v + wc.x
					if bevel_left and wc.x >= 2:
						step += 1
						bevel_left = false
			step = clampi(step, 0, BgRamps.steps(m, cold) - 1)
			var px := Vector2i(x - rect.position.x, y - rect.position.y)
			idx.set_pixel(px.x, px.y, _pack(m, step, (f & F_JOINT) != 0, bevel_left and not emissive, emissive, cold, Vector2i(qx - x, qy - y)))
			pre.set_pixel(px.x, px.y, BgRamps.color(m, step, cold))
	return {"index": idx, "preview": pre}


## ÚNICO punto de empaquetado de los fondos.
static func _pack(m: int, step: int, joint: bool, bevel: bool, emissive: bool, cold: bool, anchor_d: Vector2i) -> Color:
	var fl := 0
	if joint:
		fl |= IndexFormat.F_JOINT
	if bevel:
		fl |= IndexFormat.F_BEVEL
	if emissive:
		fl |= IndexFormat.F_EMISSIVE
	if cold:
		fl |= IndexFormat.F_COLD
	return IndexFormat.pack(BgRamps.pal_index(m), step, fl, anchor_d)


## Decodifica un píxel de índice al color que vería el shader con luz dinámica 0 (para pruebas).
static func decode(c: Color) -> Color:
	return IndexFormat.preview_color(c)


## Ruido estable (determinista entre plataformas: sólo aritmética entera).
static func hash3(x: int, y: int, s: int) -> float:
	var hh := (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7fffffff
	hh = ((hh ^ (hh >> 13)) * 1274126177) & 0x7fffffff
	hh = hh ^ (hh >> 16)
	return float(hh % 10007) / 10007.0
