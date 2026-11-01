extends RefCounted
## PixelRig — prueba de concepto del panel de personajes (v0.4).
## Lienzo de MATERIALES (no de colores): cada primitiva escribe material + luz (desde una normal analítica)
## + id de pieza. Los sellos ASCII escriben tonos FORZADOS (la mano del artista manda sobre el render).
## Al final: cuantización a la rampa del material, texturas por material, limpieza de huérfanos,
## líneas internas entre piezas, contorno exterior selectivo y capa emisiva aparte.

var w: int
var h: int
var mat: PackedInt32Array
var lum: PackedFloat32Array
var piece: PackedInt32Array
var forced: PackedInt32Array  # -1 = calcular desde lum · 0..4 tono fijo · 9 = línea (rampa[0] oscurecida)
var mats: Array = []
var mat_idx := {}
var light := Vector3(-0.62, -0.62, 0.48).normalized()
var cur_piece := 0
var piece_sep := {}
var thresholds := [0.30, 0.46, 0.62, 0.80]
var clip: Callable = Callable()


func _init(width: int, height: int) -> void:
	w = width
	h = height
	mat.resize(w * h)
	mat.fill(-1)
	lum.resize(w * h)
	piece.resize(w * h)
	forced.resize(w * h)
	forced.fill(-1)


## ramp: 5 hex de oscuro a claro (con desplazamiento de tono). outline: color del contorno exterior.
func add_mat(name: String, ramp: Array, outline: String, emissive := false, tex: Callable = Callable(), spec := false) -> void:
	var r: Array[Color] = []
	for hx: String in ramp:
		r.append(Color(hx))
	mat_idx[name] = mats.size()
	mats.append({"name": name, "ramp": r, "outline": Color(outline), "emissive": emissive, "tex": tex, "spec": spec})


func begin(sep := true) -> int:
	cur_piece += 1
	piece_sep[cur_piece] = sep
	return cur_piece


func _shade(n: Vector3) -> float:
	var d := n.normalized().dot(light)
	return clampf(0.5 + 0.5 * d, 0.0, 1.0)


func put(x: int, y: int, m: String, l: float, f := -1) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	if clip.is_valid() and not clip.call(x, y):
		return
	var i := y * w + x
	mat[i] = mat_idx[m]
	lum[i] = l
	piece[i] = cur_piece
	forced[i] = f


func ellipse(c: Vector2, rx: float, ry: float, m: String, ao := 0.0, facet := 0.0, seed := 0, tilt := Vector2.ZERO, zb := 0.0) -> void:
	for y in range(int(floor(c.y - ry)) - 1, int(ceil(c.y + ry)) + 1):
		for x in range(int(floor(c.x - rx)) - 1, int(ceil(c.x + rx)) + 1):
			var nx := (x + 0.5 - c.x) / rx
			var ny := (y + 0.5 - c.y) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			var sx := nx
			var sy := ny
			if facet > 0.0:
				# Facetas: la normal se toma en el centro de una celda con jitter (carbón, roca, hielo).
				var cx: float = floorf((x + 0.5) / facet)
				var cy: float = floorf((y + 0.5) / facet)
				var best := 1e9
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var gx: float = cx + ox
						var gy: float = cy + oy
						var hh := _h2(int(gx), int(gy), seed)
						var px: float = (gx + 0.2 + 0.6 * hh) * facet
						var py: float = (gy + 0.2 + 0.6 * _h2(int(gy), int(gx), seed + 7)) * facet
						var dd: float = (px - x - 0.5) * (px - x - 0.5) + (py - y - 0.5) * (py - y - 0.5)
						if dd < best:
							best = dd
							sx = clampf((px - c.x) / rx + (hh - 0.5) * 0.7, -0.98, 0.98)
							sy = clampf((py - c.y) / ry + (_h2(int(gx) + 3, int(gy), seed) - 0.5) * 0.7, -0.98, 0.98)
			var nz := sqrt(maxf(0.0, 1.0 - sx * sx - sy * sy))
			put(x, y, m, _shade(Vector3(sx + tilt.x, sy + tilt.y, nz * (1.0 + zb))) - ao)


func capsule(a: Vector2, b: Vector2, ra: float, rb: float, m: String, ao := 0.0, flat := 0.0) -> void:
	var lo := Vector2(minf(a.x, b.x) - maxf(ra, rb) - 1, minf(a.y, b.y) - maxf(ra, rb) - 1)
	var hi := Vector2(maxf(a.x, b.x) + maxf(ra, rb) + 1, maxf(a.y, b.y) + maxf(ra, rb) + 1)
	var ab := b - a
	var L2 := maxf(ab.length_squared(), 0.0001)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := clampf((p - a).dot(ab) / L2, 0.0, 1.0)
			var q := a + ab * t
			var r := lerpf(ra, rb, t)
			var dv := p - q
			var d := dv.length()
			if d > r:
				continue
			var n2 := dv / maxf(r, 0.001)
			var nz := sqrt(maxf(0.0, 1.0 - n2.length_squared())) + flat
			put(x, y, m, _shade(Vector3(n2.x, n2.y, nz)) - ao)


## Polígono con normal de cara `n` y bisel de `bevel` px hacia los bordes (lee como volumen tallado).
func poly(pts: PackedVector2Array, m: String, n := Vector3(0, 0, 1), bevel := 1.5, ao := 0.0) -> void:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var cen := Vector2.ZERO
	for p in pts:
		cen += p
	cen /= pts.size()
	for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
		for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var dmin := 1e9
			var en := Vector2.ZERO
			for i in pts.size():
				var e0: Vector2 = pts[i]
				var e1: Vector2 = pts[(i + 1) % pts.size()]
				var q := Geometry2D.get_closest_point_to_segment(p, e0, e1)
				var d := p.distance_to(q)
				if d < dmin:
					dmin = d
					en = (q - cen).normalized()
			var nn := n.normalized()
			if dmin < bevel:
				var k := 1.0 - dmin / bevel
				nn = nn.lerp(Vector3(en.x, en.y, 0.35).normalized(), k * 0.85)
			put(x, y, m, _shade(nn) - ao)


## Sello ASCII: leyenda char -> [material, tono] · "k" = línea fija. "." no pinta.
func stamp(rows: Array, o: Vector2i, legend: Dictionary, flip := false) -> void:
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			var ch := r[x]
			if ch == ".":
				continue
			if not legend.has(ch):
				continue
			var e: Array = legend[ch]
			var xx := (o.x + (r.length() - 1 - x)) if flip else (o.x + x)
			put(xx, o.y + y, e[0], 0.5, int(e[1]))


func pix(x: int, y: int, m: String, t: int) -> void:
	put(x, y, m, 0.5, t)


func line(a: Vector2, b: Vector2, m: String, t: int) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxf(n, 1))
		pix(int(floor(p.x)), int(floor(p.y)), m, t)


func _h2(x: int, y: int, s: int) -> float:
	return fposmod(sin(float(x) * 127.1 + float(y) * 311.7 + float(s) * 74.7) * 43758.5453, 1.0)


func at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= w or y >= h:
		return -1
	return y * w + x


## Devuelve {"img": Image, "glow": Image}
func render(outline_lit_soft := true) -> Dictionary:
	var N := w * h
	var tone := PackedInt32Array()
	tone.resize(N)
	for i in N:
		if mat[i] < 0:
			tone[i] = -1
			continue
		if forced[i] >= 0:
			tone[i] = forced[i]
			continue
		var l := lum[i]
		var t := 0
		for th: float in thresholds:
			if l > th:
				t += 1
		tone[i] = t
	# Texturas por material (ladrillo, pliegues, cicatrices…): sólo sobre tonos calculados.
	for y in h:
		for x in w:
			var i := y * w + x
			if mat[i] < 0 or forced[i] >= 0:
				continue
			var tex: Callable = mats[mat[i]]["tex"]
			if tex.is_valid():
				tone[i] = int(tex.call(x, y, tone[i], self))
	# Limpieza de huérfanos: un tono calculado sin vecino 4-conexo igual se funde con la mayoría.
	for _pass in 2:
		var cp := tone.duplicate()
		for y in h:
			for x in w:
				var i := y * w + x
				if mat[i] < 0 or forced[i] >= 0 or tone[i] >= 9:
					continue
				var same := 0
				var votes := {}
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var j := at(x + d.x, y + d.y)
					if j < 0 or mat[j] != mat[i] or tone[j] >= 9:
						continue
					if tone[j] == tone[i]:
						same += 1
					votes[tone[j]] = int(votes.get(tone[j], 0)) + 1
				if same == 0 and votes.size() > 0:
					var best := tone[i]
					var bc := 0
					for k: int in votes:
						if votes[k] > bc:
							bc = votes[k]
							best = k
					cp[i] = best
		tone = cp
	# Líneas internas: el píxel de la pieza de ATRÁS que toca a una pieza de delante se oscurece.
	var line_mark := PackedByteArray()
	line_mark.resize(N)
	for y in h:
		for x in w:
			var i := y * w + x
			if mat[i] < 0 or forced[i] >= 0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j := at(x + d.x, y + d.y)
				if j < 0 or mat[j] < 0:
					continue
				if forced[j] < 0 and piece[j] > piece[i] and piece_sep.get(piece[j], true) and (mat[j] != mat[i] or piece_sep.get(piece[j], true)):
					line_mark[i] = 1
					break
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var glow := Image.create(w, h, false, Image.FORMAT_RGBA8)
	glow.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var i := y * w + x
			if mat[i] < 0:
				continue
			var M: Dictionary = mats[mat[i]]
			var ramp: Array = M["ramp"]
			var c: Color
			if tone[i] == 9:
				c = (M["outline"] as Color)
			elif line_mark[i] == 1:
				c = (ramp[0] as Color).lerp(M["outline"], 0.5) if tone[i] <= 1 else ramp[0]
			else:
				c = ramp[clampi(tone[i], 0, 4)]
			img.set_pixel(x, y, c)
			if M["emissive"] and tone[i] >= 2:
				glow.set_pixel(x, y, c)
	# Contorno exterior selectivo: en bordes iluminados (arriba/izquierda con tono alto) el contorno
	# usa el tono oscuro del material en vez del casi negro (sel-out ligero).
	var out := img.duplicate() as Image
	for y in h:
		for x in w:
			var i := y * w + x
			if mat[i] >= 0:
				continue
			var hit := -1
			var lit := false
			for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var j := at(x + d.x, y + d.y)
				if j >= 0 and mat[j] >= 0:
					if hit < 0:
						hit = j
					if (d == Vector2i(0, 1) or d == Vector2i(1, 0)) and tone[j] >= 3 and tone[j] < 9:
						lit = true
						hit = j
			if hit < 0:
				continue
			var M: Dictionary = mats[mat[hit]]
			var oc: Color = M["outline"]
			if outline_lit_soft and lit:
				oc = (M["ramp"][0] as Color).lerp(oc, 0.35)
			out.set_pixel(x, y, oc)
	return {"img": out, "glow": glow, "tone": tone}


static func up(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c
