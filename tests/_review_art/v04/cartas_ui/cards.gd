extends RefCounted
## Carta v0.4 (prueba de concepto). Anatomía nativa 80×112 (+5 px de margen para el orbe de coste),
## mostrada a ×2 (160×224). Ilustración 68×46 nativa. El TEXTO del cuerpo va a ×1 de pantalla con la
## fuente pixel del juego (5×7), el nombre a ×2 (rejilla de la carta) si cabe.

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")

const M := 5                       # margen del lienzo (orbe de coste sobresale)
const CW := 80
const CH := 112
const ART := Rect2i(6, 17, 68, 46)
const PARCH := Rect2i(6, 70, 68, 36)

const K := Color("1a0f12")
const INK := Color("0e070a")

## Material del marco por tipo: 0 (más oscuro) → 4 (luz).
const MAT := {
	"attack": [Color("240a0e"), Color("4e1216"), Color("86201a"), Color("bc3a1e"), Color("f07a3a")],
	"skill": [Color("0c1222"), Color("1a2c4a"), Color("2e4c74"), Color("5a80aa"), Color("a8d0f0")],
	"power": [Color("2a1606"), Color("5a360e"), Color("946616"), Color("d0a030"), Color("fff0a0")],
	"fuel": [Color("1a0e0a"), Color("3a1e14"), Color("643420"), Color("94502e"), Color("d08048")],
	"status": [Color("141218"), Color("2a2830"), Color("46424e"), Color("6e6876"), Color("a8a0a8")],
}
## Placa del nombre (fondo) por tipo.
const PLATE := {"attack": Color("2a0a0c"), "skill": Color("0e1830"), "power": Color("2a1236"),
	"fuel": Color("1e100c"), "status": Color("1a181e")}
const PARCH_RAMP := {
	"attack": [Color("8a6a4c"), Color("c8a47c"), Color("e4c8a0"), Color("f2e0be")],
	"skill": [Color("74706a"), Color("b0aca0"), Color("d8d4c4"), Color("ecead8")],
	"power": [Color("8a7048"), Color("c8a868"), Color("e8d29a"), Color("f6e8c0")],
	"fuel": [Color("80603e"), Color("c09a70"), Color("e0c49a"), Color("f0dcb8")],
	"status": [Color("5e5a58"), Color("8e8884"), Color("b4aea8"), Color("cac4bc")],
}
const TYPE_LABEL := {"attack": "ATAQUE", "skill": "HABILIDAD", "power": "PODER", "fuel": "COMBUSTIBLE", "status": "ESTADO"}

const TXT_INK := Color("2a1418")
const TXT_NUM := Color("a8300c")
const TXT_KEY := Color("8a1a0a")
const TXT_UP := Color("1e7a1e")


static func c(h: String) -> Color:
	return Color(h)


# =====================================================================================
# Máscaras de ventana por tipo (silueta reconocible también en escala de grises)
# =====================================================================================

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
			for cc: Vector2 in [Vector2(r, r), Vector2(w - 1 - r, r)]:
				if (x < r and y < r and cc.x == r) or (x > w - 1 - r and y < r and cc.x != r):
					if Vector2(x, y).distance_to(cc) > r + 0.3:
						return false
			var ex := (x - (w - 1) * 0.5) / (w * 0.5)
			return y < h - 5 + int((1.0 - ex * ex) * 5.0)
		"power":
			# Capilla: arco apuntado arriba.
			var ex2 := absf(x - (w - 1) * 0.5) / (w * 0.5)
			var top := int(14.0 * (1.0 - sqrt(maxf(0.0, 1.0 - ex2 * ex2))))
			return y >= top - 0
		"fuel":
			# Boca de horno: arco rebajado arriba.
			var ex3 := (x - (w - 1) * 0.5) / (w * 0.5)
			return y >= int(ex3 * ex3 * 7.0)
		"status":
			# Bordes mordidos.
			if y < 2 and PX.hash2(x / 3, 0, 9) > 0.6:
				return false
			return true
	return true


# =====================================================================================
# Marco
# =====================================================================================

## Dibuja el marco nativo (90×122 con margen). `st`: {type, rarity, up, mastery, temple, burnable, hot, cost, name}
static func frame(st: Dictionary, art: Image) -> Image:
	var type: String = st["type"]
	var rarity: String = st["rarity"]
	var up: bool = st.get("up", false)
	var mastery: int = st.get("mastery", 0)
	var mat: Array = MAT[type]
	var img := PX.new_img(CW + M * 2, CH + M * 2)
	var O := Vector2i(M, M)
	# Cuerpo y biseles del marco.
	for y in CH:
		for x in CW:
			var e := mini(mini(x, CW - 1 - x), mini(y, CH - 1 - y))
			var tl := (y == e and x < CW - 1 - e) or (x == e and y < CH - 1 - e)
			var col: Color = mat[1]
			if e == 0:
				col = K
			elif e == 1:
				col = mat[4] if tl else mat[1]
				if up and tl:
					col = c("ffe08a")
			elif e <= 3:
				col = mat[2]
				var n := PX.hash2(x, y, 11)
				match type:
					"attack", "skill":
						if n > 0.93:
							col = mat[3]
						elif n < 0.06:
							col = mat[1]
					"fuel":
						# Ladrillo refractario en el canto.
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
			elif e == 4:
				col = mat[0] if tl else mat[3]
			img.set_pixel(O.x + x, O.y + y, col)
	# Trazo de rareza (canto interior).
	var trim := Color(0, 0, 0, 0)
	match rarity:
		"uncommon":
			trim = c("c8d4e4")
		"rare":
			trim = c("ffd84a")
	if trim.a > 0.0:
		for y in CH:
			for x in CW:
				var e2 := mini(mini(x, CW - 1 - x), mini(y, CH - 1 - y))
				if e2 == 2:
					var tl2 := x < CW / 2 and y < CH / 2
					img.set_pixel(O.x + x, O.y + y, trim if (tl2 or (x + y) % 2 == 0) else trim.darkened(0.35))
	# Remaches en las esquinas.
	for p: Vector2i in [Vector2i(2, 2), Vector2i(CW - 4, 2), Vector2i(2, CH - 4), Vector2i(CW - 4, CH - 4)]:
		var rc: Color = c("fff0a0") if rarity == "rare" else mat[4]
		img.set_pixel(O.x + p.x, O.y + p.y, rc)
		img.set_pixel(O.x + p.x + 1, O.y + p.y, mat[3])
		img.set_pixel(O.x + p.x, O.y + p.y + 1, mat[3])
		img.set_pixel(O.x + p.x + 1, O.y + p.y + 1, mat[0])
	# Placa del nombre (y 5..15) con cantos achaflanados.
	var plate: Color = PLATE[type]
	if up:
		plate = plate.lerp(c("4a2a08"), 0.6)
	for y in range(5, 16):
		for x in range(5, CW - 5):
			var ch := mini(x - 5, CW - 6 - x)
			if ch + mini(y - 5, 15 - y) < 2:
				continue
			var col2 := plate
			if y == 5 or y == 15 or ch == 0:
				col2 = K
			elif y == 6:
				col2 = plate.lightened(0.18)
			elif y == 14:
				col2 = plate.darkened(0.4)
			img.set_pixel(O.x + x, O.y + y, col2)
	# Ventana de la ilustración.
	var ar := ART
	for y in range(ar.position.y - 2, ar.end.y + 2):
		for x in range(ar.position.x - 2, ar.end.x + 2):
			var lx := x - ar.position.x
			var ly := y - ar.position.y
			var inside := lx >= 0 and ly >= 0 and lx < ar.size.x and ly < ar.size.y and window_mask(type, lx, ly)
			if inside:
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
				img.set_pixel(O.x + x, O.y + y, K)
			elif n2:
				img.set_pixel(O.x + x, O.y + y, mat[0] if (ly < ar.size.y / 2) else mat[3])
	var a2 := art.duplicate() as Image
	PX.mask(a2, func(x: int, y: int) -> bool: return window_mask(type, x, y))
	PX.blit(img, a2, O.x + ar.position.x, O.y + ar.position.y)
	if up:
		# Costura incandescente bajo el borde superior de la ventana (carta mejorada).
		for x in range(ar.size.x):
			for y in range(ar.size.y):
				if window_mask(type, x, y):
					if not window_mask(type, x, y - 1) and (x + y) % 2 == 0:
						PX.tint(img, O.x + ar.position.x + x, O.y + ar.position.y + y, c("ffb43a"), 0.5)
					break
	# Cinta del tipo (y 62..68).
	var rb_y := 62
	var rb0 := 18
	var rb1 := CW - 19
	for y in range(rb_y, rb_y + 7):
		for x in range(rb0 - 4, rb1 + 5):
			var tail := x < rb0 or x > rb1
			var col3: Color = mat[2]
			if tail:
				var tx := rb0 - x if x < rb0 else x - rb1
				# Cola con muesca.
				if y == rb_y or y == rb_y + 6 or (y == rb_y + 3 and tx >= 3):
					col3 = K
				elif tx == 4:
					col3 = K
				else:
					col3 = mat[0]
				if y == rb_y + 3 and tx >= 3:
					continue
				if tx == 4 and (y == rb_y + 2 or y == rb_y + 4):
					continue
			else:
				if y == rb_y or y == rb_y + 6 or x == rb0 or x == rb1:
					col3 = K
				elif y == rb_y + 1:
					col3 = mat[3]
				elif y == rb_y + 5:
					col3 = mat[1]
			img.set_pixel(O.x + x, O.y + y, col3)
	# Pergamino.
	var pr: Array = PARCH_RAMP[type]
	var pa := PARCH
	for y in range(pa.position.y, pa.end.y):
		for x in range(pa.position.x, pa.end.x):
			var lx2 := x - pa.position.x
			var ly2 := y - pa.position.y
			var e3 := mini(mini(lx2, pa.size.x - 1 - lx2), mini(ly2, pa.size.y - 1 - ly2))
			var col4: Color
			if e3 == 0:
				col4 = K
			elif e3 == 1:
				col4 = pr[1]
			else:
				# Papel plano (legibilidad) con fibras sueltas, sombra superior y esquinas tostadas.
				col4 = pr[2]
				if ly2 == 2:
					col4 = pr[1]
				elif ly2 == 3 and x % 2 == 0:
					col4 = pr[1]
				elif PX.hash2(x, y, 2) > 0.985:
					col4 = pr[1]
				elif lx2 >= 3 and lx2 <= 5 and ly2 >= 4 and ly2 <= 6 and false:
					col4 = pr[3]
				var cd := minf(Vector2(lx2 - 1, ly2 - 1).length(), Vector2(pa.size.x - 2 - lx2, pa.size.y - 2 - ly2).length())
				if cd < 4.0 and (x + y) % 2 == 0:
					col4 = pr[1]
				if cd < 2.5:
					col4 = pr[1]
			if up and e3 >= 2:
				col4 = col4.lerp(c("fff0c0"), 0.18)
			img.set_pixel(O.x + x, O.y + y, col4)
	# Muescas de Maestría (5) en el canto inferior izquierdo.
	var my := CH - 3
	for i in 5:
		var mx := 7 + i * 4
		var lit := i < mastery
		var mc := c("ff8ad8") if mastery >= 5 else c("ffb43a")
		if lit:
			img.set_pixel(O.x + mx, O.y + my, mc.lightened(0.4))
			img.set_pixel(O.x + mx + 1, O.y + my, mc)
			img.set_pixel(O.x + mx, O.y + my + 1, mc.darkened(0.25))
			img.set_pixel(O.x + mx + 1, O.y + my + 1, mc.darkened(0.45))
		else:
			img.set_pixel(O.x + mx, O.y + my, mat[0])
			img.set_pixel(O.x + mx + 1, O.y + my, mat[0])
			img.set_pixel(O.x + mx, O.y + my + 1, mat[0])
			img.set_pixel(O.x + mx + 1, O.y + my + 1, mat[3])
	# Temple (sello a la derecha del canto inferior).
	var temple: String = st.get("temple", "")
	if temple != "":
		var seal := {
			"edge": ["....##", "...#w#", "..#w#.", "##w#..", ".##...", "#.#..."],
			"ember": [".#.#..", "..#...", ".###..", "#ooo#.", "#oyo#.", ".###.."],
			"forge": ["......", "#####.", ".###..", "..#...", ".###..", "#####."],
			"rekindle": ["..#...", ".#o#..", "#oyo#.", "#ooo#.", ".###..", "......"],
		}
		var spal := {"#": K, "w": c("e8ecf6"), "o": c("ff6a1a"), "y": c("ffe08a")}
		if temple == "edge":
			spal["#"] = c("6a6c7c")
		var simg := PX.sprite(seal[temple], spal)
		PX.blit(img, PX.outline(simg, K), O.x + CW - 15, O.y + CH - 8)
	# Gema de rareza (centro del canto inferior).
	var gem := {"starter": [c("5a4038"), c("8a6a5a"), c("b0907a")], "common": [c("4a4650"), c("8a8690"), c("c8c4cc")],
		"uncommon": [c("1a3a7a"), c("3a7ad0"), c("a0d0ff")], "rare": [c("8a1a10"), c("e0442a"), c("ffd36a")],
		"token": [c("6a2a10"), c("ff8a4a"), c("ffe08a")], "status": [c("2a2830"), c("4a4652"), c("6e6876")]}
	var gc: Array = gem.get(rarity, gem["common"])
	var gx := O.x + CW / 2
	var gy := O.y + CH - 3
	var gr := 4 if rarity == "rare" else 3
	for dy in range(-gr, gr + 1):
		for dx in range(-gr, gr + 1):
			var md := absi(dx) + absi(dy)
			if md > gr:
				continue
			var col5: Color = K
			if md < gr:
				col5 = gc[1]
				if dx + dy < -1:
					col5 = gc[2]
				elif dx + dy > 0:
					col5 = gc[0]
			img.set_pixel(gx + dx, gy + dy, col5)
	if rarity == "rare":
		for s: Vector2i in [Vector2i(-6, 0), Vector2i(6, 0)]:
			img.set_pixel(gx + s.x, gy + s.y, c("ffd84a"))
			img.set_pixel(gx + s.x - signi(s.x), gy + s.y, K)
	# Orbe de coste: ascua facetada 17×17 que sobresale por la esquina.
	if st.has("cost"):
		_cost_gem(img, O.x + 3, O.y + 3, str(st["cost"]), up, type)
	return img


static func _cost_gem(img: Image, cx: int, cy: int, label: String, up: bool, type: String) -> void:
	var ramp := [c("5a0e10"), c("a8260e"), c("e0441a"), c("ff8a2a"), c("ffd36a"), c("fff4c8")]
	if type == "status":
		ramp = [c("1a181e"), c("2a2830"), c("46424e"), c("6e6876"), c("a8a0a8"), c("d8d0d8")]
	for y in range(-9, 10):
		for x in range(-9, 10):
			# Octógono (piedra tallada).
			var ax := absi(x)
			var ay := absi(y)
			if ax + ay > 12 or ax > 8 or ay > 8:
				continue
			var edge := ax + ay == 12 or ax == 8 or ay == 8
			var col: Color
			if edge:
				col = K
			else:
				var lit := (-x - y) / 16.0 + 0.45
				# Facetas: tres planos.
				if ax + ay >= 10 or ax == 7 or ay == 7:
					lit -= 0.25 if x + y > 0 else -0.25
				col = PX.ramp_pick(ramp, lit, x + 100, y + 100, 0.25)
			PX.put(img, cx + x, cy + y, col)
	# Brillo especular.
	PX.put(img, cx - 4, cy - 5, ramp[5])
	PX.put(img, cx - 5, cy - 4, ramp[5])
	PX.put(img, cx - 4, cy - 4, ramp[4])
	if up:
		for p: Vector2i in [Vector2i(0, -8), Vector2i(8, 0), Vector2i(0, 8), Vector2i(-8, 0)]:
			PX.put(img, cx + p.x, cy + p.y, c("ffe08a"))
	var w := PX.text_w(label)
	PX.text(img, cx - w / 2, cy - 6, label, c("fff4c8"), Color(0, 0, 0, 0), K)


# =====================================================================================
# Texto a ×1 de pantalla y composición final
# =====================================================================================

## Marcado: "{n}" número resaltado (negrita), "[k]" palabra clave, "<u>" valor mejorado (verde).
## Tokeniza en palabras; cada palabra es una lista de piezas [texto, modo] (una palabra puede mezclar modos: "×{3}").
static func _words(para: String) -> Array:
	var words: Array = []
	var cur: Array = []
	var piece := ""
	var mode := 0
	for i in para.length():
		var ch := para[i]
		if ch == "{" or ch == "[" or ch == "<" or ch == "}" or ch == "]" or ch == ">":
			if piece != "":
				cur.append([piece, mode])
			piece = ""
			mode = 0 if (ch == "}" or ch == "]" or ch == ">") else (1 if ch == "{" else (2 if ch == "[" else 3))
		elif ch == " ":
			if piece != "":
				cur.append([piece, mode])
			piece = ""
			if not cur.is_empty():
				words.append(cur)
			cur = []
		else:
			piece += ch
	if piece != "":
		cur.append([piece, mode])
	if not cur.is_empty():
		words.append(cur)
	return words


static func _piece_w(pc: Array, tall: bool) -> int:
	var bold := int(pc[1]) == 1 or int(pc[1]) == 3
	return PX.text_w(pc[0], tall) + (1 if bold else 0)


static func _word_w(wd: Array, tall: bool) -> int:
	var w := 0
	for i in wd.size():
		w += _piece_w(wd[i], tall) + (1 if i > 0 else 0)
	return w


static func _wrap(src: String, maxw: int, tall: bool) -> Array:
	var lines: Array = []
	var sp := 5 if tall else 4
	for para: String in src.split(String.chr(10)):
		var line: Array = []
		var lw := 0
		for wd: Array in _words(para):
			var ww := _word_w(wd, tall)
			if not line.is_empty() and lw + sp + ww > maxw:
				lines.append(line)
				line = []
				lw = 0
			lw += ww + (sp if not line.is_empty() else 0)
			line.append(wd)
		if not line.is_empty():
			lines.append(line)
	return lines


static func _line_w(line: Array, tall: bool) -> int:
	var w := 0
	for i in line.size():
		w += _word_w(line[i], tall) + ((5 if tall else 4) if i > 0 else 0)
	return w


static func draw_rich(img: Image, rect: Rect2i, src: String, base: Color, num: Color, key: Color, up_col: Color, tall: bool = true) -> void:
	var pitch := 12 if tall else 9
	var lines := _wrap(src, rect.size.x, tall)
	var total := lines.size() * pitch
	var y := rect.position.y + maxi(0, (rect.size.y - total) / 2) - 2
	for line: Array in lines:
		var x := rect.position.x + (rect.size.x - _line_w(line, tall)) / 2
		for i in line.size():
			if i > 0:
				x += 5 if tall else 4
			var wd: Array = line[i]
			for j in wd.size():
				if j > 0:
					x += 1
				var pc: Array = wd[j]
				var t: String = pc[0]
				var col := base
				var bold := false
				match int(pc[1]):
					1:
						col = num
						bold = true
					2:
						col = key
					3:
						col = up_col
						bold = true
				PX.text(img, x, y, t, col, Color(0, 0, 0, 0), Color(0, 0, 0, 0), tall)
				if bold:
					PX.text(img, x + 1, y, t, col, Color(0, 0, 0, 0), Color(0, 0, 0, 0), tall)
				x += _piece_w(pc, tall)
		y += pitch


## Carta completa a resolución de juego (×2): 180×244 px (160×224 de carta + margen).
static func render(st: Dictionary, art: Image) -> Image:
	var native := frame(st, art)
	# Nombre a ×1 nativo (= ×2 en pantalla) si cabe en la placa; si no, a ×1 de pantalla.
	var name: String = st["name"] + ("+" if st.get("up", false) else "")
	var nw := PX.text_w(name)
	var name_col := c("ffe08a") if st.get("up", false) else c("f4e4c8")
	var big_name := nw <= CW - 14
	if big_name:
		PX.text(native, M + (CW - nw) / 2, M + 5, name, name_col, Color(0, 0, 0, 0), K)
	var scr := PX.scaled(native, 2)
	if not big_name:
		PX.text(scr, (M + CW / 2) * 2 - nw / 2, (M + 6) * 2 + 3, name, name_col, Color(0, 0, 0, 0), K)
	# Tipo en la cinta (×1 de pantalla, versalitas).
	var tl: String = TYPE_LABEL[st["type"]]
	var tw := PX.text_w(tl)
	var mat: Array = MAT[st["type"]]
	PX.text(scr, (M + CW / 2) * 2 - tw / 2, (M + 62) * 2 + 1, tl, c("f4e4c8"), mat[0])
	# Cuerpo.
	var r := Rect2i((M + PARCH.position.x + 3) * 2, (M + PARCH.position.y + 2) * 2, (PARCH.size.x - 6) * 2, (PARCH.size.y - 4) * 2)
	draw_rich(scr, r, st["text"], TXT_INK, TXT_NUM, TXT_KEY, TXT_UP)
	return scr
