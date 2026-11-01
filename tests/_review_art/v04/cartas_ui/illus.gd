extends RefCounted
## Ilustraciones de carta 68×46 (prueba de concepto v0.4).
## GRAMÁTICA (ver propuesta.md §4): cada ilustración = FONDO (decorado reutilizable) + LUZ (fuente y color
## clave) + SUJETO (sprite a mano o primitiva) + FX (estela, chispas, humo) + ENCUADRE (máscara del tipo).
## Paletas: rampas cortas con desplazamiento de tono (sombras frías/violáceas, luces cálidas).

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const W := 68
const H := 46
const INK := Color("0e070a")


static func c(h: String) -> Color:
	return Color(h)


# ---------------------------------------------------------------------------------------
# FONDOS reutilizables
# ---------------------------------------------------------------------------------------

## Muro de la Torre (Hollín): ladrillo 11×5 con luz puntual `lp` (radio `lr`) y viñeta.
static func bg_tower_wall(img: Image, lp: Vector2, lr: float, warm: float = 1.0) -> void:
	var wall := [c("0c070b"), c("170e13"), c("24161a"), c("341f20"), c("4a2b26"), c("64392c"), c("844c34")]
	for y in H:
		for x in W:
			var row := y / 5
			var bx := x + (5 if row % 2 == 1 else 0)
			var mortar := y % 5 == 4 or bx % 11 == 10
			var l := clampf(1.0 - Vector2(x, y).distance_to(lp) / lr, 0.0, 1.0) * warm
			l = l * 0.85 + 0.12 + (PX.hash2(bx / 11, row, 3) - 0.5) * 0.10
			if y % 5 == 0 and not mortar:
				l += 0.07
			if bx % 11 == 0 and not mortar:
				l += 0.04
			if mortar:
				l -= 0.20
			img.set_pixel(x, y, PX.ramp_pick(wall, l, x, y))


static func floor_slabs(img: Image, y0: int, lit_x: float) -> void:
	var fl := [c("0c070b"), c("1a1014"), c("2a1a1c"), c("3e2622"), c("5a3628")]
	for y in range(y0, H):
		for x in W:
			var l := clampf(0.55 - (y - y0) * 0.06 - absf(x - lit_x) / 90.0, 0.0, 1.0)
			var col := PX.ramp_pick(fl, l, x, y)
			if y == y0:
				col = fl[4] if absf(x - lit_x) < 22.0 else fl[3]
			elif (x + (y - y0) * 4) % 19 == 0:
				col = fl[0]
			img.set_pixel(x, y, col)


# ---------------------------------------------------------------------------------------
# GOLPE — la hoja de hierro cae sobre el hombro de un Gólem de Hollín. Luz: el chispazo del impacto.
# ---------------------------------------------------------------------------------------

const GOLEM := [
	"........kkkkkkk.........",
	"......kkaaabbbckk.......",
	".....kaabbbbbbbcck......",
	"....kaabbbbbbbbbcck.....",
	"....kaeyybbbbbbbbck.....",
	"....kabbbbbbbbbbbck.....",
	"....kaabbbbbbbbbcck.....",
	".....kkcbbbbbbbcckk.....",
	"...kkkaakccccckkaakkk...",
	".kkaaabbbbkkkkbbbbbcckk.",
	"kaaabbbbbbbbbbbbbbbbbcck",
	"kaabbbboobbbbbbbbbbbbbck",
	"kabbbbbbbyobbbbbbbbbbbck",
	"kabbbbbbbbobbbbbbbbbbbck",
	"kaabbbbbbbbbbbbbbbobbbck",
	".kabbbbbbbbbbbbbbbyobcck",
	".kabbbbbbbbbbbbbbbbbbck.",
	".kaabbbbbbbobbbbbbbbcck.",
	"..kabbbbbbbyobbbbbbbbck.",
	"..kabbbbbbbbbobbbbbbbck.",
	"..kaabbbbbbbbbbbbbbbcck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kaabbbbbbbbbbbobbbcck.",
	"..kabbbbbbbbbbbbbybbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kaabbbbbbbbbbbbbbbcck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
	"..kabbbbbbbbbbbbbbbbbck.",
]


static func golem_sprite() -> Image:
	# Busto de gólem (mira a la izquierda): cabeza pequeña, joroba de hombros enorme, brazo delantero.
	var gw := 30
	var gh := 44
	var occ := func(x: int, y: int) -> int:
		# 1 cabeza, 2 hombros/torso, 3 brazo
		var hx := (x - 8.5) / 6.5
		var hy := (y - 6.5) / 6.0
		if absf(hx) < 1.0 and absf(hy) < 1.0 and absf(hx) + absf(hy) < 1.6:
			return 1
		var ax := (x - 5.0) / 6.0
		var ay := (y - 24.0) / 10.0
		if ax * ax + ay * ay <= 1.0:
			return 3
		var sx := (x - 19.0) / 12.0
		var sy := (y - 17.0) / 10.0
		if sx * sx + sy * sy <= 1.0 or (x >= 8 and x <= 29 and y >= 17):
			return 2
		return 0
	var img := PX.new_img(gw, gh)
	var stone := [c("1e1a24"), c("2e2834"), c("443c4a"), c("5e5464"), c("7e7284"), c("a898a4")]
	for y in gh:
		for x in gw:
			var part: int = occ.call(x, y)
			if part == 0:
				continue
			# Luz desde arriba-izquierda (el chispazo): distancia al borde en esa dirección.
			var lit := 0.35
			if int(occ.call(x - 1, y - 1)) != part:
				lit = 0.95
			elif int(occ.call(x - 2, y - 2)) != part:
				lit = 0.7
			elif int(occ.call(x + 2, y + 1)) != part:
				lit = 0.12
			lit -= (y / float(gh)) * 0.2
			# Juntas de bloques de piedra.
			var by := (y + (3 if (x / 7) % 2 == 0 else 0)) % 8
			if part != 1 and (by == 0 or x % 7 == 0) and lit < 0.9:
				lit -= 0.18
			if part == 3:
				lit += 0.08
			img.set_pixel(x, y, PX.ramp_pick(stone, lit, x, y, 0.2))
	# Ojos y boca incandescentes; grietas de magma.
	for e: Vector2i in [Vector2i(4, 6), Vector2i(8, 6)]:
		img.set_pixel(e.x, e.y, c("fff4c8"))
		img.set_pixel(e.x + 1, e.y, c("ffd36a"))
		img.set_pixel(e.x, e.y + 1, c("ff6a1a"))
	for x in range(4, 11):
		img.set_pixel(x, 10, c("ff6a1a") if x % 2 == 0 else c("a8300c"))
	for crack: Array in [[[16, 12], [18, 15], [17, 18], [20, 22]], [[24, 20], [23, 25], [25, 29], [24, 33]], [[13, 30], [15, 34], [14, 38]], [[4, 20], [6, 24], [5, 28]]]:
		for i in crack.size() - 1:
			var p0: Array = crack[i]
			var p1: Array = crack[i + 1]
			PX.line(img, p0[0], p0[1], p1[0], p1[1], c("ff6a1a"))
		var m: Array = crack[1]
		img.set_pixel(m[0], m[1], c("ffe08a"))
	return PX.outline(img, INK)


static func art_strike() -> Image:
	var img := PX.new_img(W, H)
	var hit := Vector2i(48, 8)
	bg_tower_wall(img, Vector2(hit.x, hit.y), 46.0, 1.0)
	floor_slabs(img, 41, 46.0)
	# Gólem: a la derecha, cortado por el encuadre; luz de borde en el lado del impacto.
	PX.blit(img, golem_sprite(), 45, 4)
	# Estela fina: media luna que termina en la hoja (de izquierda a 45°).
	var pivot := Vector2(13.5, 41.5)
	var a_end := -PI * 0.25
	var a_start := -PI * 0.86
	var R := 52.0
	for y in H:
		for x in W:
			var v := Vector2(x + 0.5, y + 0.5) - pivot
			var r := v.length()
			var ang := atan2(v.y, v.x)
			if ang < a_start or ang > a_end:
				continue
			var p := (ang - a_start) / (a_end - a_start)
			var thick := 1.0 + p * p * 7.0
			if r > R - 2.0 or r < R - 2.0 - thick:
				continue
			var depth := (R - 2.0 - r) / thick
			var col: Color = c("fff4c8") if depth < 0.4 else (c("ffe8b0") if p > 0.6 else c("c8b8a8"))
			if p < 0.35 and PX.bayer(x, y) > p * 2.5:
				continue
			if depth > 0.7 and (x + y) % 2 == 0:
				continue
			img.set_pixel(x, y, col)
	# Espada a 45°: 3 diagonales (x+y = S-1, S, S+1) + guarda perpendicular + puño + pomo.
	var sw := PX.new_img(W, H)
	var base := Vector2i(14, 38)
	var L := 34
	for i in L:
		var px := base.x + i
		var py := base.y - i
		PX.put(sw, px, py, c("c4c8d6"))
		if i < L - 1:
			PX.put(sw, px - 1, py, c("f8faff"))     # filo de luz (S-1)
			PX.put(sw, px, py + 1, c("7a7e92"))     # sombra (S+1)
		if i < L - 3 and i > 2:
			PX.put(sw, px + 1, py + 1, c("4a4c5e"))  # contrafilo
		if i % 9 == 4 and i < L - 4:
			PX.put(sw, px, py, c("eef0f8"))
	# Brillo especular cerca de la punta (el impacto ilumina).
	for i in range(L - 8, L - 2):
		PX.put(sw, base.x + i - 1, base.y - i, c("ffffff"))
	for j in range(-4, 5):
		var gx := base.x - 1 + j
		var gy := base.y + 1 + j
		var tip := absi(j) == 4
		PX.put(sw, gx, gy, c("fff0a0") if tip else c("d0a030"))
		PX.put(sw, gx + 1, gy, c("8a5a14"))
	for i in range(1, 6):
		var hx := base.x - 1 - i
		var hy := base.y + 2 + i
		PX.put(sw, hx, hy, c("9a5a34") if i % 2 == 0 else c("5e3420"))
		PX.put(sw, hx + 1, hy, c("6e3c22") if i % 2 == 0 else c("40220f"))
	PX.put(sw, base.x - 8, base.y + 9, c("fff0a0"))
	PX.put(sw, base.x - 7, base.y + 9, c("d0a030"))
	PX.put(sw, base.x - 8, base.y + 10, c("8a5a14"))
	PX.put(sw, base.x - 7, base.y + 10, c("5a3a0a"))
	PX.blit(img, PX.outline(sw, INK), 0, 0)
	# Chispazo del impacto: estrella de 4+4 rayos.
	var star := [[0, -1, 5], [0, 1, 4], [-1, 0, 5], [1, 0, 6], [1, -1, 3], [-1, 1, 3], [1, 1, 3], [-1, -1, 3]]
	for s: Array in star:
		for k in int(s[2]):
			var col3 := c("ffffff") if k < 2 else (c("ffe08a") if k < 4 else c("ff8a2a"))
			PX.put(img, hit.x + int(s[0]) * k, hit.y + int(s[1]) * k, col3)
	# Chispas (trazos cortos en la dirección del corte) y lascas de piedra.
	for sp: Array in [[57, 3, 1, -1], [60, 9, 1, 0], [55, 15, 1, 1], [42, 4, -1, -1], [62, 4, 1, -1], [52, 17, 0, 1]]:
		PX.put(img, sp[0], sp[1], c("ffe08a"))
		PX.put(img, int(sp[0]) - int(sp[2]), int(sp[1]) - int(sp[3]), c("ff8a2a"))
	for ch: Vector2i in [Vector2i(44, 14), Vector2i(41, 18), Vector2i(46, 21)]:
		PX.put(img, ch.x, ch.y, c("8a7c86"))
		PX.put(img, ch.x + 1, ch.y, INK)
	return img


# ---------------------------------------------------------------------------------------
# TAJO ÍGNEO — la hoja al rojo barre la escena dejando una media luna de fuego. Luz: la propia llama.
# ---------------------------------------------------------------------------------------

static func art_ember_slash() -> Image:
	var img := PX.new_img(W, H)
	var dark := [c("0c0408"), c("1a080c"), c("2e0c10"), c("481410"), c("6a1e12"), c("8e2c14")]
	for y in H:
		for x in W:
			var l := clampf(1.0 - Vector2((x - 40) / 1.5, (y - 30)).length() / 40.0, 0.0, 1.0)
			l = l * 0.85 + (PX.fbm(x / 10.0, y / 7.0, 21) - 0.5) * 0.12
			img.set_pixel(x, y, PX.ramp_pick(dark, l, x, y))
	# Pilares a contraluz (profundidad).
	for px in [[3, 6], [61, 6]]:
		for y in H:
			for x in range(px[0], px[0] + px[1]):
				img.set_pixel(x, y, c("0a0306") if x != px[0] + px[1] - 1 or px[0] < 30 else c("3a0e10"))
		for y in range(0, H, 9):
			for x in range(px[0], px[0] + px[1]):
				img.set_pixel(x, y, c("1e080c"))
	# Media luna de fuego: dos círculos (A − B). Gruesa junto a la hoja, afilada en la cola.
	var fire := [c("5a0e10"), c("9a1c14"), c("d2381a"), c("ff6a1a"), c("ffb43a"), c("ffe08a"), c("fff4c8")]
	var hilt := Vector2(21.5, 42.5)
	var RA := 36.0
	var RB := 32.5
	var off := Vector2(-1, 1).normalized() * 8.0
	for y in H:
		for x in W:
			var v := Vector2(x + 0.5, y + 0.5) - hilt
			var ang := atan2(v.y, v.x)
			if ang > -PI * 0.12:
				continue
			var lick := (PX.vnoise(ang * 26.0, 0.0, 5) - 0.35) * 3.0
			var rA := v.length()
			var rB := (v - off).length()
			if rA > RA + maxf(0.0, lick) or rB < RB:
				continue
			var depth := RA - rA
			var front := clampf((ang + PI) / (PI * 0.75), 0.0, 1.0)
			var reach := 2.0 + front * 8.0
			if depth > reach and PX.bayer(x, y) > 0.25:
				continue
			var heat := clampf(1.0 - depth / reach, 0.0, 1.0) * (0.35 + front * 0.65) + 0.08
			if rA > RA:
				heat = 0.3 + front * 0.2
			if front < 0.25 and PX.bayer(x, y) > front * 4.0:
				continue
			img.set_pixel(x, y, PX.ramp_pick(fire, heat, x, y, 0.3))
	# Hoja al rojo (45°) que remata la media luna.
	var bl := PX.new_img(W, H)
	var hx := int(hilt.x) + 1
	var hy := int(hilt.y) - 1
	var L := 25
	for i in L:
		var x := hx + i
		var y := hy - i
		PX.put(bl, x, y, c("fff4c8") if i > 3 else c("ffe08a"))
		if i < L - 1:
			PX.put(bl, x - 1, y, c("ffe08a"))
			PX.put(bl, x, y + 1, c("ff8a2a"))
		if i > 2 and i < L - 3:
			PX.put(bl, x + 1, y + 1, c("c2321e"))
	for j in range(-4, 5):
		PX.put(bl, hx - 1 + j, hy + 1 + j, c("8a5a14") if absi(j) == 4 else c("4a2a1e"))
		PX.put(bl, hx + j, hy + 1 + j, c("2a1812"))
	for i in range(1, 5):
		PX.put(bl, hx - 1 - i, hy + 2 + i, c("3a2014") if i % 2 == 0 else c("1e100c"))
		PX.put(bl, hx - i, hy + 2 + i, c("2a1610"))
	PX.blit(img, PX.outline(bl, c("2a0606")), 0, 0)
	# Quemadura que prende: tres llamitas en el suelo.
	for fx: Array in [[14, 5], [22, 3], [50, 4]]:
		var fh: int = fx[1]
		for k in fh:
			var w := maxi(0, (fh - k) / 2)
			for dx in range(-w, w + 1):
				var t := float(k) / fh
				PX.put(img, int(fx[0]) + dx, H - 1 - k, fire[clampi(int(6.0 - t * 4.0 - absi(dx) * 1.5), 1, 6)])
	for i in 14:
		var ex := 8 + int(PX.hash2(i, 3, 41) * 52.0)
		var ey := 2 + int(PX.hash2(i, 5, 41) * 30.0)
		PX.put(img, ex, ey, fire[5] if i % 3 == 0 else fire[3])
	return img


# ---------------------------------------------------------------------------------------
# CARBÓN — un trozo de hulla facetada sobre la rejilla, en la boca del horno. Luz: el lecho de abajo.
# ---------------------------------------------------------------------------------------

const COAL := [
	"...........kkkk...........",
	"........kkkHHHhk..........",
	".....kkkHHHHHhhhkk........",
	"...kkHHHHHHhhhhhhhkkk.....",
	"..kHHHHHhhhhhhhhhhmmmk....",
	".kHHHhhhhhhhhhhhhmmmmmkk..",
	".khhhhhhhhhhhhhhmmmmmmmmk.",
	"kGhhhhhhhhhhhmmmmmOmmmmddk",
	"kGGhhhhhhhhmmmmmmOmmmmdddk",
	"kGGGgmmmmmmmmmmmOmmmmddddk",
	"kGGgggmmmmmmOOOmmmmmddddk.",
	".kGgggggmmmmmmOmmmmddddk..",
	".kGggggggmmmmmmOmmmddddk..",
	"..kgggggggggmmmmOdddddk...",
	"..kgggOgggggggmmdddddk....",
	"...kgggOOggggggddddkk.....",
	"....kkgggOgggggddkk.......",
	"......kkkkkkkkkkk.........",
]


static func art_coal() -> Image:
	var img := PX.new_img(W, H)
	var inner := [c("1e0806"), c("3e1008"), c("6a1c0a"), c("a0300e"), c("d85016"), c("ff8a2a")]
	var brick := [c("0e0605"), c("1c0e0a"), c("2e1810"), c("462616"), c("643820"), c("885030")]
	var ac := Vector2(34.0, 44.0)
	var ri := 30.0
	var ro := 37.0
	for y in H:
		for x in W:
			var v := Vector2((x + 0.5 - ac.x) / 1.15, y + 0.5 - ac.y)
			var r := v.length()
			if r < ri:
				var l := clampf(1.0 - Vector2((x - 34) / 1.8, y - 46).length() / 34.0, 0.0, 1.0)
				l += (PX.fbm(x / 6.0, y / 4.0, 3) - 0.5) * 0.12
				img.set_pixel(x, y, PX.ramp_pick(inner, l, x, y))
			elif r < ro:
				# Dovelas radiales del arco, iluminadas desde dentro.
				var ang := atan2(v.y, v.x)
				var seg := int(floor((ang + PI) / (PI / 11.0)))
				var mortar := absf(fposmod((ang + PI) / (PI / 11.0), 1.0)) < 0.09 or r > ro - 1.0
				var l2 := 0.75 - (r - ri) / (ro - ri) * 0.5 + (PX.hash2(seg, 0, 8) - 0.5) * 0.15
				if r < ri + 1.0:
					l2 = 0.95
				if mortar:
					l2 = 0.08
				img.set_pixel(x, y, PX.ramp_pick(brick, l2, x, y))
			else:
				var row := y / 4
				var bx := x + (4 if row % 2 == 1 else 0)
				var m2 := y % 4 == 3 or bx % 9 == 8
				var l3 := 0.18 + clampf(1.0 - (r - ro) / 12.0, 0.0, 1.0) * 0.18 + (PX.hash2(bx / 9, row, 2) - 0.5) * 0.1
				if m2:
					l3 = 0.02
				img.set_pixel(x, y, PX.ramp_pick(brick, l3, x, y))
	# Lecho de brasas bajo la rejilla: oscuro con focos.
	for y in range(39, H):
		for x in range(6, 63):
			var v2 := Vector2((x + 0.5 - ac.x) / 1.15, y + 0.5 - ac.y)
			if v2.length() >= ri:
				continue
			var n := PX.vnoise(x / 2.0, y / 1.5, 77) + (PX.hash2(x, y, 4) - 0.5) * 0.25
			var col: Color = c("2a0a06")
			if n > 0.86:
				col = c("ffe08a")
			elif n > 0.74:
				col = c("ff8a2a")
			elif n > 0.58:
				col = c("c2401a")
			elif n > 0.4:
				col = c("6a1c0a")
			img.set_pixel(x, y, col)
	# Rejilla de hierro.
	for x in range(6, 63):
		if Vector2((x + 0.5 - ac.x) / 1.15, 37.5 - ac.y).length() >= ri:
			continue
		PX.put(img, x, 37, c("8a8a96"))
		PX.put(img, x, 38, c("3a3842"))
		PX.put(img, x, 39, INK)
	for x in range(9, 60, 5):
		for y in range(40, H):
			if Vector2((x + 0.5 - ac.x) / 1.15, y + 0.5 - ac.y).length() < ri:
				PX.put(img, x, y, c("16141a"))
	# Hulla facetada: G = cara iluminada por el lecho (cálida), H = cara superior fría.
	var cpal := {"k": INK, "H": c("9a98b4"), "h": c("5a5872"), "m": c("33303e"), "d": c("1c1a24"),
		"g": c("6a3020"), "G": c("c06030"), "O": c("ff6a1a")}
	var cimg := PX.sprite(COAL, cpal)
	for y in cimg.get_height():
		for x in cimg.get_width():
			if cimg.get_pixel(x, y) == cpal["O"]:
				var nb := 0
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if PX.get_c(cimg, x + d.x, y + d.y) == cpal["O"]:
						nb += 1
				if nb >= 2:
					cimg.set_pixel(x, y, c("ffe08a"))
	# Brillo especular en la arista superior.
	cimg.set_pixel(11, 1, c("e0e4f8"))
	cimg.set_pixel(12, 1, c("c8ccdc"))
	cimg.set_pixel(5, 3, c("c8ccdc"))
	PX.blit(img, cimg, 21, 20)
	# Humo violáceo que escapa por la clave del arco.
	for y in range(5, 22):
		for x in range(22, 48):
			var sx := 34.0 + sin(y * 0.45) * 3.0
			var fall := 1.0 - absf(x - sx) / (5.0 + (22 - y) * 0.3)
			var a := PX.fbm(x / 4.0, y / 3.0, 12) * fall * 1.6
			if a > 0.55:
				PX.tint(img, x, y, c("7a6878"), 0.5 if a > 0.8 else 0.25)
	for i in 9:
		var ex := 16 + int(PX.hash2(i, 9, 3) * 36.0)
		var ey := 10 + int(PX.hash2(i, 4, 3) * 16.0)
		PX.put(img, ex, ey, c("ffb43a") if i % 2 == 0 else c("ffe08a"))
	return img


# ---------------------------------------------------------------------------------------
# CORONA SOLAR — el sol se alza sobre la llanura de ceniza y sus llamaradas forman una corona.
# ---------------------------------------------------------------------------------------

static func art_corona() -> Image:
	var img := PX.new_img(W, H)
	var sky := [c("120820"), c("22103a"), c("3a184c"), c("5c224e"), c("86304a"), c("b84436"), c("e46c2a")]
	var sun := Vector2(34.0, 33.0)
	for y in H:
		for x in W:
			var t := float(y) / 34.0
			var gl := clampf(1.0 - Vector2(x - sun.x, (y - sun.y) * 1.6).length() / 46.0, 0.0, 1.0)
			var l := t * 0.55 + gl * 0.55
			var ang := atan2(y - sun.y, x - sun.x)
			if int(floor((ang + PI) / (PI / 10.0))) % 2 == 0 and gl > 0.15:
				l += 0.10
			img.set_pixel(x, y, PX.ramp_pick(sky, l, x, y, 0.5))
	# Corona: cinco puntas (como la corona de un rey) + halo punteado.
	var fl := [c("a8261a"), c("e0441a"), c("ff8a2a"), c("ffc040"), c("ffe8a0")]
	var spikes := [[-90.0, 25.0, 6.0], [-60.0, 21.0, 5.5], [-120.0, 21.0, 5.5], [-32.0, 17.0, 5.0], [-148.0, 17.0, 5.0],
		[-8.0, 15.0, 4.0], [-172.0, 15.0, 4.0]]
	for y in H:
		for x in W:
			var v := Vector2(x + 0.5 - sun.x, y + 0.5 - sun.y)
			var r := v.length()
			if r < 12.0:
				continue
			var a := rad_to_deg(atan2(v.y, v.x))
			var best := -1.0
			for s: Array in spikes:
				var da := absf(a - float(s[0]))
				var half_w := float(s[2]) * (1.0 - (r - 12.0) / (float(s[1]) - 12.0 + 0.001))
				if r <= float(s[1]) and da * PI / 180.0 * r <= half_w:
					best = maxf(best, 1.0 - (r - 12.0) / (float(s[1]) - 12.0))
			if best >= 0.0:
				img.set_pixel(x, y, PX.ramp_pick(fl, best * 0.9 + 0.1, x, y, 0.4))
			elif r < 14.5 and y < sun.y and (x + y) % 2 == 0:
				img.set_pixel(x, y, fl[2])
	# Gemas en las puntas de la corona.
	for s: Array in spikes.slice(0, 5):
		var ang2 := deg_to_rad(float(s[0]))
		var tip := sun + Vector2(cos(ang2), sin(ang2)) * (float(s[1]) + 1.0)
		PX.put(img, int(tip.x), int(tip.y), c("fff4c8"))
	# Disco solar.
	var disc := [c("ff7a20"), c("ffb43a"), c("ffd870"), c("fff0b8"), c("ffffff")]
	for y in H:
		for x in W:
			var v2 := Vector2(x + 0.5 - sun.x, y + 0.5 - sun.y)
			var r2 := v2.length()
			if r2 <= 11.5:
				var lit := 1.05 - r2 / 13.0 + (-v2.x - v2.y) / 50.0
				img.set_pixel(x, y, PX.ramp_pick(disc, lit, x, y, 0.3))
			elif r2 <= 12.5:
				img.set_pixel(x, y, c("ff6a1a"))
	# Llanura de ceniza con dos líneas de dunas y borde encendido de cara al sol.
	for x in W:
		var h1 := 37 + int(round(sin(x * 0.10 + 1.2) * 1.5 + sin(x * 0.31) * 0.7))
		var h2 := 42 + int(round(sin(x * 0.07 + 3.0) * 1.6))
		for y in range(h1, H):
			var near := absf(x - sun.x)
			var col: Color = c("2a1228") if y < h2 else c("180a18")
			if y == h1:
				col = c("ffb43a") if near < 9.0 else (c("e46c2a") if near < 20.0 else c("86304a"))
			elif y == h1 + 1:
				col = c("86304a") if near < 16.0 else c("3a184c")
			elif y == h2:
				col = c("b84436") if near < 12.0 else c("3a184c")
			elif y > h2 + 1:
				col = c("0e0610")
			img.set_pixel(x, y, col)
	# La Torre en silueta, con ventanas encendidas.
	var tw := [
		"...k...", "...k...", "..kkk..", "..kok..", ".kkkkk.", "..kkk..", "..kok..", "..kkk..", ".kkkkk.",
		"..kkk..", "..kkk..", "..kok..", "..kkk..", ".kkkkk.", ".kkkkk.", ".kkokk.", ".kkkkk.", ".kkkkk.",
		"kkkkkkk", ".kkkkk.", ".kkkok.", ".kkkkk.", ".kkkkk.", ".kokkk.", ".kkkkk.", "kkkkkkk", "kkkkkkk",
		"kkkkkkk", "kkkkkkk", "kkkkkkk", "kkkkkkk", "kkkkkkk", "kkkkkkk", "kkkkkkk",
	]
	PX.blit(img, PX.sprite(tw, {"k": c("0e0610"), "o": c("ffb43a")}), 7, 6)
	for b: Vector2i in [Vector2i(52, 10), Vector2i(58, 14), Vector2i(48, 15)]:
		PX.put(img, b.x - 1, b.y - 1, c("1a0c1a"))
		PX.put(img, b.x, b.y, c("1a0c1a"))
		PX.put(img, b.x + 1, b.y - 1, c("1a0c1a"))
	return img
