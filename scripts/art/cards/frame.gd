class_name CardFrame
extends RefCounted
## Marco de carta v0.4: 80×112 nativos (se muestra a ×2 = 160×224) + margen M = 5 para el orbe de coste.
## Anatomía (coordenadas de la carta, sin margen):
##   y 0        contorno · y 1–4 canto de material (bisel), remaches en esquinas
##   y 5–15     placa del nombre (achaflanada)
##   y 17–62    ventana de ilustración 68×46 (x 6–73) con silueta por tipo
##   y 62–68    cinta del tipo (colas en muesca)
##   y 70–105   pergamino 68×36
##   y 106–111  canto inferior: muescas de Maestría (izq.), gema de rareza (centro), sello de Temple (der.)
## Estados: tipo (material + silueta), rareza (trazo + gema), mejorada (canto y costura al rojo), Maestría (muescas y
## calor del marco: 1–2 remaches encendidos, 3–4 brasas incrustadas, 5 canto incandescente + muescas mágicas),
## Temple (Filo/Brasa/Fragua/Rescoldo), auras de "jugable", "quemable", "en caliente" y "seleccionada" (`aura()`),
## brillo de rara (`shimmer_frames()`).
## Colores: rampas `frame_<tipo>`, `parch_<tipo>`, `Palette.UI` (placas y tintas), `ember_ui`, `gold`, `steel`, `magic`.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")

const M := 5
const CW := 80
const CH := 112
const ART := Rect2i(6, 17, 68, 46)
const PARCH := Rect2i(6, 70, 68, 36)
const RIBBON_Y := 62
const MASTERY_MAX := 5

static var _cache := {}


static func P(mat: StringName, step: int, cold := false) -> Color:
	return Palette.color(mat, step, cold)


static func K() -> Color:
	return Palette.UI[&"k"]


## mat[0..4] del tipo (paso 1..5 de `frame_<tipo>`; el paso 0 es la tinta común).
static func mat_of(type: String) -> Array:
	var m := StringName("frame_" + (type if type in ["attack", "skill", "power", "fuel", "status"] else "status"))
	return [P(m, 1), P(m, 2), P(m, 3), P(m, 4), P(m, 5)]


static func parch_of(type: String) -> Array:
	var m := StringName("parch_" + (type if type in ["attack", "skill", "power", "fuel", "status"] else "status"))
	return [P(m, 1), P(m, 2), P(m, 3), P(m, 4)]


static func plate_of(type: String) -> Color:
	return Palette.UI.get(StringName("plate_" + type), Palette.UI[&"plate_status"])


# ------------------------------------------------------------------------------------------- silueta de ventana

static func window_mask(type: String, x: int, y: int) -> bool:
	var w := ART.size.x
	var h := ART.size.y
	match type:
		"attack":
			# Filo: esquinas superiores achaflanadas y borde inferior en V suave.
			if x + y < 5 or (w - 1 - x) + y < 5:
				return false
			var cx := absf(x - (w - 1) * 0.5)
			return y < h - 4 + int((w * 0.5 - cx) / 8.5)
		"skill":
			# Escudo: esquinas superiores redondeadas, base en arco.
			var r := 5.0
			if y < r and (x < r or x > w - 1 - r):
				var cc := Vector2(r, r) if x < r else Vector2(w - 1 - r, r)
				if Vector2(x, y).distance_to(cc) > r + 0.3:
					return false
			var ex := (x - (w - 1) * 0.5) / (w * 0.5)
			return y < h - 5 + int((1.0 - ex * ex) * 5.0)
		"power":
			# Capilla: arco de medio punto arriba.
			var ex2 := absf(x - (w - 1) * 0.5) / (w * 0.5)
			return y >= int(14.0 * (1.0 - sqrt(maxf(0.0, 1.0 - ex2 * ex2))))
		"fuel":
			# Boca de horno: arco rebajado arriba.
			var ex3 := (x - (w - 1) * 0.5) / (w * 0.5)
			return y >= int(ex3 * ex3 * 7.0)
		"status":
			# Bordes mordidos.
			if y < 2 and _Px.hash2(x / 3, 0, 9) > 0.6:
				return false
			if y > h - 3 and _Px.hash2(x / 3, 1, 9) > 0.6:
				return false
			return true
	return true


# ------------------------------------------------------------------------------------------- marco

## Imagen nativa (90×122) del marco con la ilustración dentro. `st`: {type, rarity, up, mastery, temple}.
static func build(st: Dictionary, art: Image) -> Image:
	var type: String = st.get("type", "attack")
	var rarity: String = st.get("rarity", "common")
	var up: bool = st.get("up", false)
	var mastery: int = clampi(int(st.get("mastery", 0)), 0, MASTERY_MAX)
	var temple: String = st.get("temple", "")
	var mat := mat_of(type)
	var k := K()
	var img := _Px.new_img(CW + M * 2, CH + M * 2)
	var O := Vector2i(M, M)
	var hot_edge := mastery >= MASTERY_MAX
	# Canto de material con bisel.
	for y in CH:
		for x in CW:
			var e := mini(mini(x, CW - 1 - x), mini(y, CH - 1 - y))
			var tl := (y == e and x < CW - 1 - e) or (x == e and y < CH - 1 - e)
			var col: Color = mat[1]
			if e == 0:
				col = k
			elif e == 1:
				col = mat[4] if tl else mat[1]
				if up and tl:
					col = P(&"ember_ui", 5)
				if hot_edge:
					col = P(&"hot", 5) if tl else P(&"hot", 3)
			elif e <= 3:
				col = mat[2]
				var n := _Px.hash2(x, y, 11)
				match type:
					"attack", "skill":
						if n > 0.93:
							col = mat[3]
						elif n < 0.06:
							col = mat[1]
					"fuel":
						var bx := x + (2 if (y / 3) % 2 == 1 else 0)
						if y % 3 == 0 or bx % 5 == 0:
							col = mat[1]
						elif n > 0.8:
							col = mat[3]
					"power":
						if (x + y) % 4 == 0 and e == 2:
							col = mat[3]
					"status":
						if n > 0.85:
							col = mat[1]
				# Maestría 3–4: brasas incrustadas en el canto.
				if mastery >= 3 and e == 2 and _Px.hash2(x, y, 31) > (0.9 if mastery == 3 else 0.84):
					col = P(&"ember_ui", 4) if _Px.hash2(x, y, 32) > 0.5 else P(&"ember_ui", 3)
				if hot_edge and e == 3:
					col = P(&"hot", 2)
			elif e == 4:
				col = mat[0] if tl else mat[3]
			img.set_pixel(O.x + x, O.y + y, col)
	# Trazo de rareza en el canto interior.
	var trim := Color(0, 0, 0, 0)
	var trim_lo := Color(0, 0, 0, 0)
	match rarity:
		"uncommon":
			trim = P(&"steel", 5, true)
			trim_lo = P(&"steel", 3, true)
		"rare":
			trim = P(&"gold", 5)
			trim_lo = P(&"gold", 3)
	if trim.a > 0.0:
		for y in CH:
			for x in CW:
				if mini(mini(x, CW - 1 - x), mini(y, CH - 1 - y)) == 2:
					var tl2 := x < CW / 2 and y < CH / 2
					img.set_pixel(O.x + x, O.y + y, trim if (tl2 or (x + y) % 2 == 0) else trim_lo)
	# Remaches (Maestría 1+: arden).
	for p: Vector2i in [Vector2i(2, 2), Vector2i(CW - 4, 2), Vector2i(2, CH - 4), Vector2i(CW - 4, CH - 4)]:
		var rc: Color = P(&"gold", 5) if rarity == "rare" else mat[4]
		var rm: Color = mat[3]
		var rd: Color = mat[0]
		if mastery >= 1:
			rc = P(&"ember_ui", 6)
			rm = P(&"ember_ui", 4)
			rd = P(&"ember_ui", 2)
		img.set_pixel(O.x + p.x, O.y + p.y, rc)
		img.set_pixel(O.x + p.x + 1, O.y + p.y, rm)
		img.set_pixel(O.x + p.x, O.y + p.y + 1, rm)
		img.set_pixel(O.x + p.x + 1, O.y + p.y + 1, rd)
	# Placa del nombre.
	var plate := plate_of(type)
	var plate_hi := _Px.shifted(plate, 1)
	var plate_lo := k
	if up:
		plate = P(&"gold", 1)
		plate_hi = P(&"gold", 2)
	for y in range(5, 16):
		for x in range(5, CW - 5):
			var ch := mini(x - 5, CW - 6 - x)
			if ch + mini(y - 5, 15 - y) < 2:
				continue
			var col2 := plate
			if y == 5 or y == 15 or ch == 0:
				col2 = k
			elif y == 6:
				col2 = plate_hi
			elif y == 14:
				col2 = plate_lo if not up else P(&"gold", 1)
			img.set_pixel(O.x + x, O.y + y, col2)
	# Ventana: contorno + bisel hundido.
	var ar := ART
	for y in range(ar.position.y - 2, ar.end.y + 2):
		for x in range(ar.position.x - 2, ar.end.x + 2):
			var lx := x - ar.position.x
			var ly := y - ar.position.y
			if lx >= 0 and ly >= 0 and lx < ar.size.x and ly < ar.size.y and window_mask(type, lx, ly):
				continue
			var n1 := false
			var n2 := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var qx := lx + dx
					var qy := ly + dy
					if qx >= 0 and qy >= 0 and qx < ar.size.x and qy < ar.size.y and window_mask(type, qx, qy):
						if absi(dx) <= 1 and absi(dy) <= 1:
							n1 = true
						else:
							n2 = true
			if n1:
				img.set_pixel(O.x + x, O.y + y, k)
			elif n2:
				img.set_pixel(O.x + x, O.y + y, mat[0] if ly < ar.size.y / 2 else mat[3])
	if art != null:
		var a2 := _Px.masked(art, func(x: int, y: int) -> bool: return window_mask(type, x, y))
		_Px.blit(img, a2, O.x + ar.position.x, O.y + ar.position.y)
	if up:
		# Costura incandescente bajo el borde superior de la ventana.
		for x in ar.size.x:
			for y in ar.size.y:
				if window_mask(type, x, y):
					if (x + y) % 2 == 0:
						img.set_pixel(O.x + ar.position.x + x, O.y + ar.position.y + y, P(&"ember_ui", 4))
					break
	# Cinta del tipo.
	var rb0 := 14
	var rb1 := CW - 15
	for y in range(RIBBON_Y, RIBBON_Y + 7):
		for x in range(rb0 - 4, rb1 + 5):
			var tail := x < rb0 or x > rb1
			var col3: Color = mat[2]
			if tail:
				var tx := rb0 - x if x < rb0 else x - rb1
				if y == RIBBON_Y + 3 and tx >= 3:
					continue
				if tx == 4 and (y == RIBBON_Y + 2 or y == RIBBON_Y + 4):
					continue
				if y == RIBBON_Y or y == RIBBON_Y + 6 or tx == 4 or (y == RIBBON_Y + 3 and tx >= 2):
					col3 = k
				else:
					col3 = mat[0]
			else:
				if y == RIBBON_Y or y == RIBBON_Y + 6 or x == rb0 or x == rb1:
					col3 = k
				elif y == RIBBON_Y + 1:
					col3 = mat[3]
				elif y == RIBBON_Y + 5:
					col3 = mat[1]
			img.set_pixel(O.x + x, O.y + y, col3)
	# Pergamino plano (legibilidad), fibras sueltas, sombra superior y esquinas tostadas.
	var pr := parch_of(type)
	var pa := PARCH
	var base: Color = pr[3] if up else pr[2]
	for y in range(pa.position.y, pa.end.y):
		for x in range(pa.position.x, pa.end.x):
			var lx2 := x - pa.position.x
			var ly2 := y - pa.position.y
			var e3 := mini(mini(lx2, pa.size.x - 1 - lx2), mini(ly2, pa.size.y - 1 - ly2))
			var col4: Color
			if e3 == 0:
				col4 = k
			elif e3 == 1:
				col4 = pr[1]
			else:
				col4 = base
				if ly2 == 2 or (ly2 == 3 and x % 2 == 0):
					col4 = pr[1] if not up else pr[2]
				elif _Px.hash2(x, y, 2) > 0.985:
					col4 = pr[1]
				var cd := minf(Vector2(lx2 - 1, ly2 - 1).length(), Vector2(pa.size.x - 2 - lx2, pa.size.y - 2 - ly2).length())
				if cd < 2.5 or (cd < 4.0 and (x + y) % 2 == 0):
					col4 = pr[1]
			img.set_pixel(O.x + x, O.y + y, col4)
	# Muescas de Maestría.
	var my := CH - 3
	for i in MASTERY_MAX:
		var mx := 7 + i * 4
		var lit := i < mastery
		var c0: Color = P(&"magic", 4) if hot_edge else P(&"ember_ui", 5)
		var c1: Color = P(&"magic", 3) if hot_edge else P(&"ember_ui", 4)
		var c2: Color = P(&"magic", 2) if hot_edge else P(&"ember_ui", 3)
		var c3: Color = P(&"magic", 1) if hot_edge else P(&"ember_ui", 2)
		if lit:
			img.set_pixel(O.x + mx, O.y + my, c0)
			img.set_pixel(O.x + mx + 1, O.y + my, c1)
			img.set_pixel(O.x + mx, O.y + my + 1, c2)
			img.set_pixel(O.x + mx + 1, O.y + my + 1, c3)
		else:
			img.set_pixel(O.x + mx, O.y + my, mat[0])
			img.set_pixel(O.x + mx + 1, O.y + my, mat[0])
			img.set_pixel(O.x + mx, O.y + my + 1, mat[0])
			img.set_pixel(O.x + mx + 1, O.y + my + 1, mat[3])
	# Sello de Temple.
	if temple != "":
		var seal := {
			"edge": ["....##", "...#w#", "..#w#.", "##w#..", ".##...", "#.#..."],
			"ember": [".#.#..", "..#...", ".###..", "#ooo#.", "#oyo#.", ".###.."],
			"forge": ["......", "#####.", ".###..", "..#...", ".###..", "#####."],
			"rekindle": ["..#...", ".#o#..", "#oyo#.", "#ooo#.", ".###..", "......"],
		}
		if seal.has(temple):
			var spal := {"#": k, "w": P(&"steel", 6, true), "o": P(&"ember_ui", 3), "y": P(&"ember_ui", 5)}
			if temple == "edge":
				spal["#"] = P(&"steel", 3, true)
			if temple == "forge":
				spal["#"] = P(&"iron", 7)
			var simg := _Px.sprite(seal[temple], spal)
			_Px.blit(img, _Px.outline(simg, k), O.x + CW - 15, O.y + CH - 8)
		# Filo: hilo de acero en el canto izquierdo. Brasa: dos ascuas en las esquinas del pergamino.
		if temple == "edge":
			for y in range(8, CH - 8):
				if y % 3 != 0:
					img.set_pixel(O.x + 2, O.y + y, P(&"steel", 6, true))
		elif temple == "ember":
			for p2: Vector2i in [Vector2i(pa.position.x + 2, pa.end.y - 3), Vector2i(pa.end.x - 3, pa.end.y - 3)]:
				img.set_pixel(O.x + p2.x, O.y + p2.y, P(&"ember_ui", 4))
				img.set_pixel(O.x + p2.x + 1, O.y + p2.y, P(&"ember_ui", 3))
				img.set_pixel(O.x + p2.x, O.y + p2.y - 1, P(&"ember_ui", 5))
	_gem(img, O.x + CW / 2, O.y + CH - 3, rarity)
	return img


static func _gem(img: Image, gx: int, gy: int, rarity: String) -> void:
	var k := K()
	var gem := {
		"starter": [P(&"leather", 3), P(&"leather", 4), P(&"leather", 5)],
		"common": [P(&"ash", 3, true), P(&"ash", 6, true), P(&"ash", 9, true)],
		"uncommon": [P(&"frost_glow", 1), P(&"frost_glow", 2), P(&"frost_glow", 4)],
		"rare": [P(&"blood", 1), P(&"blood", 3), P(&"ember_ui", 5)],
		"token": [P(&"ember_ui", 1), P(&"ember_ui", 3), P(&"ember_ui", 5)],
		"status": [P(&"plate", 2), P(&"plate", 3), P(&"plate", 5)],
	}
	var gc: Array = gem.get(rarity, gem["common"])
	var gr := 4 if rarity == "rare" else 3
	for dy in range(-gr, gr + 1):
		for dx in range(-gr, gr + 1):
			var md := absi(dx) + absi(dy)
			if md > gr:
				continue
			var col: Color = k
			if md < gr:
				col = gc[1]
				if dx + dy < -1:
					col = gc[2]
				elif dx + dy > 0:
					col = gc[0]
			img.set_pixel(gx + dx, gy + dy, col)
	if rarity == "rare":
		for s: int in [-6, 6]:
			img.set_pixel(gx + s, gy, P(&"gold", 5))
			img.set_pixel(gx + s - signi(s), gy, k)


# ------------------------------------------------------------------------------------------- orbe de coste

## Orbe de coste: ascua tallada octogonal 19×19 nativa (sin la cifra: la pone la vista con Fragua).
## `state`: "ok" | "no" (no asequible) | "up" (mejorada) | "status".
static func cost_gem(state: String) -> Image:
	var key := "gem:" + state
	if _cache.has(key):
		return _cache[key]
	var ramp: Array = _Px.R(&"ember_ui", 1, 6)
	if state == "no" or state == "status":
		ramp = _Px.R(&"plate", 1, 6)
	var img := _Px.new_img(19, 19)
	var k := K()
	for y in range(-9, 10):
		for x in range(-9, 10):
			var ax := absi(x)
			var ay := absi(y)
			if ax + ay > 12 or ax > 8 or ay > 8:
				continue
			var col: Color
			if ax + ay == 12 or ax == 8 or ay == 8:
				col = k
			else:
				var lit := (-x - y) / 16.0 + 0.45
				if ax + ay >= 10 or ax == 7 or ay == 7:
					lit += -0.25 if x + y > 0 else 0.25
				col = _Px.ramp_pick(ramp, lit, x + 100, y + 100, 0.25)
			img.set_pixel(x + 9, y + 9, col)
	img.set_pixel(5, 4, ramp[5])
	img.set_pixel(4, 5, ramp[5])
	img.set_pixel(5, 5, ramp[4])
	if state == "up":
		for p: Vector2i in [Vector2i(9, 1), Vector2i(17, 9), Vector2i(9, 17), Vector2i(1, 9)]:
			img.set_pixel(p.x, p.y, P(&"ember_ui", 5))
	_cache[key] = img
	return img


# ------------------------------------------------------------------------------------------- auras y brillo

## Silueta de la carta (cuerpo + orbe) en el lienzo con margen.
static func _silhouette(x: int, y: int, orb: bool) -> bool:
	var lx := x - M
	var ly := y - M
	if lx >= 0 and ly >= 0 and lx < CW and ly < CH:
		return true
	if not orb:
		return false
	var gx := x - (M + 3)
	var gy := y - (M + 3)
	return absi(gx) + absi(gy) <= 12 and absi(gx) <= 8 and absi(gy) <= 8


## Aura animada alrededor de la carta (lienzo con margen 4 extra: 98×130). `kind`: play | burn | hot | select.
## 4 fotogramas para burn/hot (lenguas que suben); play/select son fijas. `orb`: la carta muestra orbe de coste.
static func aura(kind: String, frame: int = 0, orb: bool = true) -> Image:
	var key := "aura:%s:%d:%s" % [kind, frame, orb]
	if _cache.has(key):
		return _cache[key]
	var pad := 4
	var w := CW + M * 2 + pad * 2
	var h := CH + M * 2 + pad * 2
	var img := _Px.new_img(w, h)
	var cols: Array
	match kind:
		"burn":
			cols = [P(&"ember_ui", 4), P(&"ember_ui", 3), P(&"ember_ui", 2)]
		"hot":
			cols = [P(&"ember_ui", 6), P(&"ember_ui", 5), P(&"ember_ui", 4)]
		"select":
			cols = [P(&"ember_ui", 6), P(&"ember_ui", 6), P(&"ember_ui", 6)]
		_:
			cols = [P(&"ember_ui", 5), P(&"ember_ui", 4), P(&"ember_ui", 4)]
	for y in h:
		for x in w:
			if _silhouette(x - pad, y - pad, orb):
				continue
			var d := 99
			for r in range(1, 5):
				for dd: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
					if _silhouette(x - pad + dd.x, y - pad + dd.y, orb):
						d = mini(d, r)
			if d > 4:
				continue
			if kind == "play" or kind == "select":
				if d == 1 or (kind == "select" and d == 2):
					img.set_pixel(x, y, cols[0] if d == 1 else cols[1])
				continue
			# Lenguas: alcance variable por columna que sube con los fotogramas; más largas arriba.
			var flick := _Px.hash2(x / 2, (y + frame * 3) / 3, 17)
			var reach := 1.5 + flick * 2.6 + (0.8 if y < h / 3 else 0.0)
			if d <= reach and (d <= 2 or (x + y + frame) % 2 == 0):
				img.set_pixel(x, y, cols[0] if d <= 1 else (cols[1] if d <= 2 else cols[2]))
	_cache[key] = img
	return img


## 6 fotogramas del brillo de rara: banda diagonal de 8 px que sube un paso de rampa a los píxeles claros del
## marco (nunca a la ilustración ni al pergamino). Devuelve imágenes nativas con el mismo tamaño que `base`.
static func shimmer_frames(base: Image, n: int = 6) -> Array[Image]:
	var out: Array[Image] = []
	var w := base.get_width()
	var h := base.get_height()
	for f in n:
		var img := base.duplicate() as Image
		var pos := -h * 0.6 + (f / float(n - 1)) * (w + h * 1.2)
		for y in h:
			for x in w:
				var p := img.get_pixel(x, y)
				if p.a == 0.0:
					continue
				var lx := x - M
				var ly := y - M
				if ART.has_point(Vector2i(lx, ly)) or PARCH.has_point(Vector2i(lx, ly)):
					continue
				var d := x + y * 0.6 - pos
				if d >= 0.0 and d < 8.0 and p.get_luminance() > 0.25:
					img.set_pixel(x, y, _Px.shifted(p, 2 if d >= 2.0 and d < 6.0 else 1))
		out.append(img)
	return out
