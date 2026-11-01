extends Node
## EMBERSPIRE v0.4 — KEYFRAME de dirección de arte (director).
## Pantalla de combate del acto 1 (Hollín) generada 100 % por código a la resolución nativa propuesta
## 640×360 (rejilla ÚNICA para mundo e interfaz, ×2 → 1280×720).
## Técnica que demuestra (y que propongo para producción):
##   · Mapa de luz por fuentes: la Forja (cálida, detrás de la heroína) y la Torre (fría, delante).
##   · Rampas con desplazamiento de tono (sombras a violeta, luces a ámbar / a cian) y bandas escalonadas.
##   · Personajes por PARTES (cápsulas/elipses/polígonos con normales) → iluminación → cuantización a rampa
##     → líneas de contacto entre partes → contorno selectivo (sel-out) → detalles a mano.
##   · Roca por FACETAS (Voronoi de normales) con grietas emisivas: gólem y carbón de la carta.
##   · El estado del juego cambia la imagen: `heat` (calor de la Forja) reescribe luz, fuego, antorchas,
##     brasas, pelo de la heroína y el martillo. Se exportan dos variantes: Forja viva y Forja moribunda.

const OUT := "res://tests/_review_art/v04/director/"
const W := 640
const H := 360
const FLOOR_Y := 232
const HORIZON := 140.0
const FORGE := Vector2(62, 228)
const TORCH := [Vector2(217, 146), Vector2(423, 146)]

const HEX := {
	# Piedra del Hollín: base común oscura (violeta) que se calienta hacia ámbar…
	"stone_w": ["0b080e", "140e16", "1e141e", "2b1a26", "3b222c", "522c30", "6e3a32", "965034", "c26e3c"],
	# …o se enfría hacia azul pizarra cuando domina la luz de la Torre.
	"stone_c": ["0b080e", "120f1a", "191826", "222334", "2c3044", "384058", "48546e", "5c6c86", "7a8ca4"],
	"brick_w": ["0e090c", "1c0f14", "2e1418", "44191a", "5e2420", "7c3222", "a04626", "c8642e", "f08c42"],
	"fire": ["2a0a10", "5a1216", "92201a", "cc3c1c", "f26a22", "ffa03a", "ffd468", "fff6d4"],
	"gold": ["1a0e08", "4a2c10", "8a5a18", "c8902a", "f0c050", "fff0a0"],
	"cloth_w": ["12070c", "2a0c12", "4a1218", "6e1a1a", "98281c", "c43e20", "e8622c"],
	"cloth_c": ["12070c", "1e0c18", "2e1222", "401a2e", "52243a"],
	"metal_w": ["0c0a10", "1e1820", "382a2c", "5a4038", "8a6048", "c48a5c", "f0c08a"],
	"metal_c": ["0c0a10", "1a1a26", "2c3040", "465062", "687a90", "9cb0c4", "d8e6f0"],
	"sky": ["0c1020", "121a32", "1a2846", "24385a", "2e486c"],
	"moon": ["5a7088", "8aa4bc", "b8ccdc", "e4eef4"],
	"parch": ["4a3020", "8a6a4a", "c4a47a", "dcc49a", "ecdab4", "f8ecd0"],
	"ink": ["2a1418"],
	"blood": ["2a0a10", "5c1418", "9a2018", "d23a22", "ff6a48"],
	"smoke": ["1a1420", "2a2232", "3e3446", "564a5c"],
	# Materiales de personaje: [cálida] y [fría]
	"skin_w": ["24101a", "4e2026", "844030", "b86444", "e09464", "ffc890"],
	"skin_c": ["24101a", "3e2430", "6a4650", "9a7276", "c8a4a0"],
	"hair_w": ["24080e", "561216", "92201a", "cc361c", "f4622a", "ffa24e"],
	"hair_c": ["24080e", "3a1222", "561c30", "72283c"],
	"shirt_w": ["1e161c", "403032", "6e5648", "a4846a", "d6b892", "fbe8c4"],
	"shirt_c": ["1e161c", "302c40", "4a4a62", "6a7090", "96a2be"],
	"apron_w": ["1a0e12", "341a18", "562c20", "804428", "ac6634", "d88c48"],
	"apron_c": ["1a0e12", "281a24", "3c2a36", "54404a"],
	"trous_w": ["100c14", "1e1626", "342634", "52383e", "7a544c"],
	"trous_c": ["100c14", "1a1a2c", "282c44", "3a425e"],
	"boot_w": ["120a0e", "261412", "422218", "663622", "8e502c"],
	"boot_c": ["120a0e", "221e2c", "34303e", "48445a"],
	"scarf_w": ["0c1224", "182a48", "284670", "3e6c9a", "6496bc", "9cc4d8"],
	"scarf_c": ["0c1224", "182a48", "2a4a7a", "4474ac", "74a8d8", "b4e0fa"],
	"wood_w": ["140a0c", "2e1814", "4c2a1a", "704022", "98602e"],
	"wood_c": ["140a0c", "22182a", "342838"],
	"rock_w": ["0a080c", "151018", "221822", "32222a", "462e32", "623c38", "8a523c", "b46e44"],
	"rock_c": ["0a080c", "121220", "1a1c2e", "262a40", "343c54", "48546e", "62748e", "8ca2ba"],
	"rockfar_w": ["0a080c", "120e16", "1a141e", "261a24", "34222a", "462c30"],
	"rockfar_c": ["0a080c", "0f0f1a", "151726", "1e2234", "282e44", "343c56"],
}

var R := {}
var img: Image
var LWm := PackedFloat32Array()
var LCm := PackedFloat32Array()
var heat := 1.0
var rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------- arranque
func _ready() -> void:
	for k: String in HEX:
		var a := PackedColorArray()
		for hx: String in HEX[k]:
			a.append(Color(hx))
		R[k] = a
	for v: Array in [["hot", 1.0], ["cold", 0.15]]:
		heat = v[1]
		render()
		img.save_png(OUT + "keyframe_%s_640.png" % v[0])
		var big: Image = img.duplicate()
		big.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
		big.save_png(OUT + "keyframe_%s_1280.png" % v[0])
		# recortes ×4 para revisar a nivel de píxel
		for c: Array in [["hero", Rect2i(96, 176, 160, 96)], ["golem", Rect2i(410, 150, 150, 120)],
				["cards", Rect2i(170, 246, 300, 114)], ["forge", Rect2i(0, 150, 160, 120)]]:
			var crop := img.get_region(c[1])
			crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
			crop.save_png(OUT + "crop_%s_%s.png" % [v[0], c[0]])
	print("KEYFRAME OK")
	get_tree().quit()

func render() -> void:
	rng.seed = 7
	img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color("0b080e"))
	build_light()
	paint_wall()
	paint_pillar(206, 228)
	paint_pillar(412, 434)
	paint_arch()
	paint_window()
	paint_banner(236)
	paint_banner(386)
	paint_chain(128, 70)
	paint_chain(560, 96)
	paint_chain(600, 52)
	paint_tools()
	for t: Vector2 in TORCH:
		paint_torch(int(t.x), int(t.y))
	paint_floor()
	paint_forge()
	paint_anvil()
	floor_shadow(184, 264, 22, 3)
	floor_shadow(482, 265, 36, 4)
	paint_hero()
	paint_golem()
	paint_particles()
	paint_world_ui()
	paint_cards()
	paint_hud()

# ---------------------------------------------------------------- utilidades
func h2(x: int, y: int, s: int = 0) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n % 10007) / 10007.0

func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)

func getp(x: int, y: int) -> Color:
	return img.get_pixel(clampi(x, 0, W - 1), clampi(y, 0, H - 1))

func rc(name: String, i: int) -> Color:
	var r: PackedColorArray = R[name]
	return r[clampi(i, 0, r.size() - 1)]

func rect(x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			px(x, y, c)

# ---------------------------------------------------------------- luz
func light_raw(x: float, y: float) -> Vector2:
	var w := 0.0
	var c := 0.05 + 0.10 * (1.0 - heat)
	var d := Vector2(x - FORGE.x, (y - FORGE.y) * 1.25).length()
	var fr := 90.0 + 210.0 * heat
	w += (0.18 + 1.0 * heat) * pow(clampf(1.0 - d / fr, 0.0, 1.0), 1.35)
	for t: Vector2 in TORCH:
		var dt := Vector2(x - t.x, (y - t.y) * 1.1).length()
		w += (0.10 + 0.30 * heat) * pow(clampf(1.0 - dt / (30.0 + 36.0 * heat), 0.0, 1.0), 1.5)
	var da := Vector2(x - 320.0, (y - 200.0) * 1.3).length()
	c += 0.42 * pow(clampf(1.0 - da / 110.0, 0.0, 1.0), 1.5)
	var dw := Vector2(x - 468.0, (y - 96.0) * 0.9).length()
	c += 0.45 * pow(clampf(1.0 - dw / 84.0, 0.0, 1.0), 1.4)
	c += 0.45 * shaft(x, y)
	var dp := Vector2(x - 420.0, (y - 266.0) * 3.0).length()
	c += 0.35 * pow(clampf(1.0 - dp / 60.0, 0.0, 1.0), 1.2)
	return Vector2(w, c)

func shaft(x: float, y: float) -> float:
	if y < 136.0 or y > 268.0:
		return 0.0
	var t := (y - 136.0) / 132.0
	var xl := lerpf(455.0, 380.0, t)
	var xr := lerpf(482.0, 446.0, t)
	if x < xl or x > xr:
		return 0.0
	var u := (x - xl) / (xr - xl)
	return 1.0 if (u > 0.25 and u < 0.75) else 0.5

func build_light() -> void:
	LWm.resize(W * H)
	LCm.resize(W * H)
	for y in H:
		for x in W:
			var l := light_raw(x + 0.5, y + 0.5)
			LWm[y * W + x] = l.x
			LCm[y * W + x] = l.y

## Sombreado de superficie: albedo × luz → índice de rampa (cálida o fría según qué fuente domina),
## con una única costura tramada (25 %) en el borde de cada banda.
func shade_at(rw: String, rcn: String, alb: float, lx: int, ly: int, x: int, y: int, bonus := Vector2.ZERO, dith := true) -> Color:
	var i := clampi(ly, 0, H - 1) * W + clampi(lx, 0, W - 1)
	var lw := LWm[i] + bonus.x
	var lc := LCm[i] + bonus.y
	var tot := alb * (0.32 + lw * 1.7 + lc * 1.25)
	var warm := lw * 1.7 >= lc * 1.25
	var r: PackedColorArray = R[rw] if warm else R[rcn]
	var f := clampf(tot, 0.0, 1.0) * float(R[rw].size() - 1)
	var k := int(f)
	if dith and f - k > 0.78 and ((x + y) & 1) == 0:
		k += 1
	return r[clampi(k, 0, r.size() - 1)]

# ---------------------------------------------------------------- fondo
func paint_wall() -> void:
	for y in range(0, FLOOR_Y):
		var row := y / 8
		var off := (row % 2) * 7
		var soot := lerpf(0.30, 1.0, smoothstep(0.0, 150.0, float(y)))
		for x in W:
			var lx := (x + off) % 15
			var ly := y % 8
			var bx := (x + off) / 15
			var alb: float
			if lx == 14 or ly == 7:
				alb = 0.12
			else:
				alb = 0.40 + (h2(bx, row, 1) - 0.5) * 0.18
				if lx == 0 or ly == 0:
					alb += 0.07
				elif lx == 13 or ly == 6:
					alb -= 0.06
				if h2(bx, row, 2) > 0.86 and lx > 8 and ly < 3:
					alb = 0.15
				if h2(bx, row, 4) > 0.93 and lx > 2 and lx < 9 and ly == 3:
					alb -= 0.12
			alb *= soot
			var sd := absf(x - 62.0) / 64.0
			if sd < 1.0:
				alb *= lerpf(0.5, 1.0, sd * sd)
			if y > FLOOR_Y - 5:
				alb *= 0.65
			var cx := clampi((bx * 15) - off + 7, 0, W - 1)
			img.set_pixel(x, y, shade_at("stone_w", "stone_c", alb, cx, row * 8 + 3, x, y))

func paint_pillar(x0: int, x1: int) -> void:
	for y in range(0, FLOOR_Y + 1):
		var cap := y >= 30 and y < 40
		var base := y >= FLOOR_Y - 12
		var e := 3 if (cap or base) else 0
		if y == FLOOR_Y - 12 or y == 30:
			e = 2
		var soot := lerpf(0.30, 1.0, smoothstep(0.0, 150.0, float(y)))
		for x in range(x0 - e, x1 + e):
			var lx := x - (x0 - e)
			var w := (x1 + e) - (x0 - e)
			var blk := (y - 40) / 13 if y >= 40 else -1
			var ly := (y - 40) % 13 if y >= 40 else 0
			var alb := 0.50 + (h2(x0, blk, 5) - 0.5) * 0.12
			if not cap and not base and ly == 12:
				alb = 0.14
			if y == 40 or y == FLOOR_Y - 13:
				alb = 0.10
			if cap and y == 30:
				alb += 0.15
			if lx <= 1:
				alb += 0.14
			elif lx >= w - 5:
				alb -= 0.20
			if lx == 0 or lx == w - 1:
				alb = 0.09
			img.set_pixel(x, y, shade_at("stone_w", "stone_c", alb * soot, x, y, x, y))

func in_parch(x: float, y: float, cx: float, half: float, spring: float, bottom: float, k: float = 1.5) -> bool:
	if y > bottom or absf(x - cx) > half:
		return false
	if y >= spring:
		return true
	var rr := half * k
	var cl := Vector2(cx - half + rr, spring)
	var cr := Vector2(cx + half - rr, spring)
	var p := Vector2(x, y)
	return p.distance_to(cl) <= rr and p.distance_to(cr) <= rr

func ring_block(x: int, y: int) -> int:
	if y >= 150:
		return (0 if x < 320 else 500) + int((y - 150) / 10)
	var left := x < 320
	var rr := 50.0 * 1.5
	var c := Vector2(320.0 - 50.0 + rr, 150.0) if left else Vector2(320.0 + 50.0 - rr, 150.0)
	var a := atan2(y + 0.5 - c.y, x + 0.5 - c.x)
	return 100 + (0 if left else 300) + int(floor(a * rr / 9.0))

# escala respecto al punto de fuga del corredor
const VP := Vector2(320, 158)
const DEPTHS := [1.0, 0.70, 0.50, 0.36]

func corridor_depth(x: float, y: float) -> int:
	var d := 0
	for k in range(1, DEPTHS.size()):
		var s: float = DEPTHS[k]
		var bottom := VP.y + (FLOOR_Y - VP.y) * s
		var spring := VP.y + (150.0 - VP.y) * s
		if in_parch(x, y, 320.0, 46.0 * s, spring, bottom):
			d = k
	return d

func paint_arch() -> void:
	for y in range(20, FLOOR_Y):
		for x in range(250, 391):
			var fx := x + 0.5
			var fy := y + 0.5
			var inside := in_parch(fx, fy, 320, 46, 150, FLOOR_Y)
			var ring := (not inside) and in_parch(fx, fy, 320, 55, 150, FLOOR_Y)
			if inside:
				img.set_pixel(x, y, corridor(x, y))
			elif ring:
				var b := ring_block(x, y)
				var joint := ring_block(x + 1, y) != b or ring_block(x, y + 1) != b
				var alb := 0.52 + (h2(b, 3, 9) - 0.5) * 0.14
				if joint:
					alb = 0.14
				var in_edge := in_parch(fx + 1, fy, 320, 46, 150, FLOOR_Y) or in_parch(fx - 1, fy, 320, 46, 150, FLOOR_Y) or in_parch(fx, fy + 1, 320, 46, 150, FLOOR_Y)
				var out_edge := not in_parch(fx - 1, fy - 1, 320, 55, 150, FLOOR_Y) or not in_parch(fx + 1, fy - 1, 320, 55, 150, FLOOR_Y)
				if out_edge:
					alb = 0.10
				var c := shade_at("stone_w", "stone_c", alb * lerpf(0.4, 1.0, smoothstep(40.0, 150.0, fy)), x, y, x, y)
				if in_edge:
					c = rc("stone_c", 5)  # canto iluminado por la luz fría del fondo
				img.set_pixel(x, y, c)

func corridor(x: int, y: int) -> Color:
	var fx := x + 0.5
	var fy := y + 0.5
	var d := corridor_depth(fx, fy)
	var lit := 1.0
	# borde de cada arco interior (marco iluminado desde dentro)
	var edge := false
	if d < DEPTHS.size() - 1:
		edge = corridor_depth(fx + 1, fy) > d or corridor_depth(fx - 1, fy) > d or corridor_depth(fx, fy + 1) > d
	if d == DEPTHS.size() - 1:
		# boca de luz: la cima de la Torre
		var dist := Vector2(fx - 320.0, (fy - 176.0) * 0.8).length() / 22.0
		var k := int(clampf(8.4 - dist * 5.0, 3.0, 8.0))
		if dist > 0.55 and dist < 0.75 and ((x + y) & 1) == 0:
			k -= 1
		return rc("stone_c", k)
	var s0: float = DEPTHS[d]
	var s1: float = DEPTHS[d + 1]
	var b0 := VP.y + (FLOOR_Y - VP.y) * s0
	var b1 := VP.y + (FLOOR_Y - VP.y) * s1
	var base := 1 + d
	if edge:
		return rc("stone_c", base + 3)
	if fy > b1:
		# peldaños entre profundidades
		var t := (fy - b1) / maxf(b0 - b1, 1.0)
		var steps := 4
		var st := t * steps
		var frac: float = st - floor(st)
		if frac < 1.0 / ((b0 - b1) / steps):
			return rc("stone_c", base + 2)
		return rc("stone_c", base)
	# paredes del corredor: hiladas tenues
	var k2 := base
	if int(fy) % 6 == 0:
		k2 = maxi(base - 1, 0)
	var mid := absf(fx - 320.0) / (46.0 * s0)
	if mid < 0.55 and d >= 1:
		k2 += 1
	return rc("stone_c", k2)

func paint_window() -> void:
	var cx := 468.0
	for y in range(36, 142):
		for x in range(446, 491):
			var fx := x + 0.5
			var fy := y + 0.5
			var glass := in_parch(fx, fy, cx, 13, 76, 134)
			var frame := (not glass) and in_parch(fx, fy, cx, 18, 76, 138)
			if glass:
				var c: Color
				if absf(fx - cx) < 1.2:
					c = rc("stone_c", 4)
				else:
					var t := (fy - 48.0) / 86.0
					var k := int(clampf(t * 5.0, 0.0, 4.0))
					if fmod(t * 5.0, 1.0) > 0.75 and ((x + y) & 1) == 0:
						k = mini(k + 1, 4)
					c = rc("sky", k)
					var md := Vector2(fx - 474.0, fy - 70.0).length()
					if md < 6.5:
						var sh := Vector2(fx - 476.5, fy - 68.5).length()
						var mk := 3 if md < 4.5 else 2
						if sh < 5.0:
							mk = 0 if md > 4.0 else 1
						if md >= 5.5:
							mk = mini(mk, 1)
						c = rc("moon", mk)
					elif md < 9.0:
						c = rc("sky", 4)
					if ((x - y) % 6 == 0 or (x + y) % 6 == 0):
						c = rc("stone_c", 1)
					if h2(x, y, 31) > 0.985 and md > 9.0:
						c = rc("moon", 2)
				img.set_pixel(x, y, c)
			elif frame:
				var alb := 0.55
				var outer := not in_parch(fx, fy - 1.5, cx, 18, 76, 138) or not in_parch(fx + 1.5, fy, cx, 18, 76, 138) or not in_parch(fx - 1.5, fy, cx, 18, 76, 138)
				if outer:
					alb = 0.12
				if fx > cx + 13:
					alb -= 0.12
				img.set_pixel(x, y, shade_at("stone_w", "stone_c", alb, x, y, x, y, Vector2(0, 0.25)))
	# alféizar
	for x in range(448, 489):
		px(x, 138, rc("stone_c", 7))
		px(x, 139, rc("stone_c", 5))
		px(x, 140, rc("stone_c", 2))
		px(x, 141, rc("stone_c", 1))

func paint_banner(x0: int) -> void:
	var w := 18
	var c := x0 + w / 2.0
	# varilla
	for x in range(x0 - 3, x0 + w + 3):
		px(x, 33, shade_at("metal_w", "metal_c", 0.5, x, 33, x, 33))
		px(x, 34, shade_at("metal_w", "metal_c", 0.25, x, 34, x, 34))
	for e: int in [x0 - 4, x0 + w + 3]:
		px(e, 32, rc("metal_c", 3)); px(e, 33, shade_at("metal_w", "metal_c", 0.6, e, 33, e, 33)); px(e, 34, rc("metal_c", 1))
	for y in range(35, 140):
		for x in range(x0, x0 + w):
			var bottom := 122.0 + absf(x + 0.5 - c) * 1.3
			if y > bottom:
				continue
			var lx := x - x0
			var alb := 0.46 + 0.16 * sin(lx * 0.85 + 0.4) + 0.03 * sin(y * 0.35 + lx * 0.5)
			if lx == 0 or lx == w - 1 or y >= bottom - 1.0:
				alb = 0.16
			if lx == 2 or lx == w - 3:
				alb -= 0.08
			if y == 35:
				alb = 0.12
			img.set_pixel(x, y, shade_at("cloth_w", "cloth_c", alb, x, y, x, y))
	# emblema: llama de la Forja
	var E := [
		"....o....",
		"...oo....",
		"...ooo...",
		"..oooo.o.",
		"..ooooo..",
		".ooooooo.",
		".oooYoooo",
		"ooooYYooo",
		"oooYYYooo",
		".ooYYYoo.",
		"..ooooo..",
		"...ooo...",
	]
	var ex := x0 + 4
	var ey := 64
	for j in E.size():
		var rowstr: String = E[j]
		for i in rowstr.length():
			var ch := rowstr[i]
			if ch == ".":
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var ii := i + d.x
				var jj := j + d.y
				var empty := jj < 0 or jj >= E.size() or ii < 0 or ii >= rowstr.length() or (E[jj] as String)[ii] == "."
				if empty:
					px(ex + ii, ey + jj, rc("cloth_w", 1))
			var lw := LWm[(ey + j) * W + ex + i]
			var g := 2 + int(clampf(lw * 2.5, 0.0, 2.0))
			if ch == "Y":
				g += 1
			if i <= 3 and ch == "o":
				g += 0
			elif ch == "o":
				g -= 1
			px(ex + i, ey + j, rc("gold", g))

func paint_chain(x: int, length: int) -> void:
	for y in range(0, length):
		var link := (y / 4) % 2
		var ly := y % 4
		if link == 0:
			for dx: int in [-1, 1]:
				px(x + dx, y, shade_at("metal_w", "metal_c", 0.55 if dx < 0 else 0.3, x, y, x, y))
			if ly == 0 or ly == 3:
				px(x, y, shade_at("metal_w", "metal_c", 0.45, x, y, x, y))
		else:
			px(x, y, shade_at("metal_w", "metal_c", 0.5, x, y, x, y))
	# gancho
	var y0 := length
	for p: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 2), Vector2i(2, 1)]:
		px(x + p.x, y0 + p.y, shade_at("metal_w", "metal_c", 0.55, x, y0, x, y0))

func line_m(a: Vector2, b: Vector2, alb: float, thick: int = 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n:
		var p := a.lerp(b, float(i) / maxf(n - 1, 1))
		for t in thick:
			var x := int(p.x) + t
			var y := int(p.y)
			px(x, y, shade_at("metal_w", "metal_c", alb if t == 0 else alb * 0.6, x, y, x, y))

func paint_tools() -> void:
	# repisa de herramientas sobre la Forja: cuentan el oficio de la Fogonera
	for x in range(108, 200):
		px(x, 126, shade_at("wood_w", "wood_c", 0.55, x, 126, x, 126))
		px(x, 127, shade_at("wood_w", "wood_c", 0.35, x, 127, x, 127))
		px(x, 128, rc("stone_w", 0))
	for x: int in [112, 196]:
		for y in range(128, 133):
			px(x, y, shade_at("metal_w", "metal_c", 0.4, x, y, x, y))
	# tenazas
	line_m(Vector2(122, 129), Vector2(117, 162), 0.55)
	line_m(Vector2(125, 129), Vector2(130, 162), 0.40)
	px(123, 140, rc("metal_w", 4)); px(124, 140, rc("metal_w", 3))
	line_m(Vector2(116, 162), Vector2(118, 166), 0.5)
	line_m(Vector2(131, 162), Vector2(129, 166), 0.4)
	# martillo de bola
	line_m(Vector2(146, 129), Vector2(146, 154), 0.5, 2)
	for y in range(154, 159):
		for x in range(141, 152):
			var alb := 0.6 if y == 154 else (0.25 if y == 158 else 0.42)
			if x == 141:
				alb += 0.15
			px(x, y, shade_at("metal_w", "metal_c", alb, x, y, x, y))
	# atizador
	line_m(Vector2(168, 129), Vector2(168, 170), 0.5)
	px(169, 170, rc("metal_w", 3)); px(170, 169, rc("metal_w", 3))
	# pala de carbón
	line_m(Vector2(186, 129), Vector2(186, 152), 0.45)
	for y in range(152, 164):
		var hw := 3 + (y - 152) / 4
		for x in range(186 - hw, 186 + hw + 1):
			var alb := 0.42 - (x - 186 + hw) * 0.03
			if y == 163:
				alb = 0.2
			px(x, y, shade_at("metal_w", "metal_c", alb, x, y, x, y))
	# sombras de herramientas sobre el muro (la luz viene de la Forja, abajo-izquierda → sombra arriba-derecha)

func paint_torch(x: int, y: int) -> void:
	for yy in range(y + 2, y + 9):
		px(x, yy, rc("metal_w", 2))
	for xx in range(x - 3, x + 4):
		px(xx, y + 2, rc("metal_w", 3))
		px(xx, y + 3, rc("metal_w", 1))
	px(x - 3, y + 1, rc("metal_w", 2)); px(x + 3, y + 1, rc("metal_w", 2))
	var fh := int(4 + 6 * heat)
	for j in fh:
		var hw := int(round((1.0 - float(j) / fh) * 2.4 + 0.3))
		var sway := int(round(sin(j * 0.9 + x) * (j / 4.0)))
		for i in range(-hw, hw + 1):
			var k := 7 - int(float(j) / fh * 4.0) - absi(i)
			px(x + i + sway, y + 1 - j, rc("fire", clampi(k, 2, 7)))

func tile_id(x: float, y: float) -> Vector2i:
	var z := 1100.0 / maxf(y - HORIZON, 1.0)
	var row := int(floor(z / 1.7))
	var u := (x - 320.0) * z / 110.0
	var off := 1.5 if (row % 2) == 1 else 0.0
	return Vector2i(int(floor((u + off) / 3.0)), row)

func paint_floor() -> void:
	for y in range(FLOOR_Y, H):
		var depth := float(y - FLOOR_Y) / float(H - FLOOR_Y)
		for x in W:
			var tid := tile_id(x + 0.5, y + 0.5)
			var joint := tile_id(x + 1.5, y + 0.5) != tid or tile_id(x + 0.5, y + 1.5) != tid
			var alb := 0.34 + (h2(tid.x, tid.y, 7) - 0.5) * 0.12
			if joint:
				alb = 0.12
			elif tile_id(x - 0.5, y + 0.5) != tid or tile_id(x + 0.5, y - 0.5) != tid:
				alb += 0.06
			if y < FLOOR_Y + 3:
				alb *= 0.55
			alb *= lerpf(1.0, 0.62, depth)
			var bonus := Vector2.ZERO
			# reflejo de la boca del horno sobre el suelo pulido por el hollín
			var rx := absf(x - 62.0)
			if rx < 22.0 and y > 264 and not joint:
				var fall := (1.0 - rx / 22.0) * clampf(1.0 - (y - 264.0) / 56.0, 0.0, 1.0)
				if (x / 2 + y) % 3 != 0 or fall > 0.5:
					bonus.x += 0.9 * heat * fall
			# charco de luz fría bajo el arco
			img.set_pixel(x, y, shade_at("stone_w", "stone_c", alb, x, y, x, y, bonus))
	# carbonilla y ceniza junto a la Forja
	rng.seed = 11
	for i in 46:
		var x := rng.randi_range(4, 150)
		var y := rng.randi_range(266, 300)
		var c := shade_at("stone_w", "stone_c", 0.12, x, y, x, y)
		px(x, y, c)
		px(x + 1, y, c)
		if rng.randf() < 0.3 * heat + 0.05:
			px(x + 1, y - 1, rc("fire", 4))

# ---------------------------------------------------------------- forja
func paint_forge() -> void:
	var cx := 62.0
	var by := 252.0
	var rx := 52.0
	var ry := 68.0
	# chimenea
	for y in range(0, 192):
		for x in range(50, 75):
			var lx := x - 50
			var row := y / 5
			var off := (row % 2) * 4
			var joint := ((x + off) % 8 == 0) or (y % 5 == 4)
			var alb := 0.45 + (h2((x + off) / 8, row, 21) - 0.5) * 0.14
			if joint:
				alb = 0.14
			if lx <= 1:
				alb += 0.1
			elif lx >= 20:
				alb -= 0.16
			if lx == 0 or lx == 24:
				alb = 0.08
			var band := (y >= 58 and y < 62) or (y >= 136 and y < 140)
			var c: Color
			if band:
				var a2 := 0.55 if y % 4 == 0 else 0.32
				if lx == 0 or lx == 24:
					a2 = 0.1
				c = shade_at("metal_w", "metal_c", a2, x, y, x, y)
			else:
				var glow := heat * 0.5 * clampf((y - 120.0) / 70.0, 0.0, 1.0)
				c = shade_at("brick_w", "stone_c", alb * lerpf(0.5, 1.0, smoothstep(0.0, 180.0, float(y))), x, y, x, y, Vector2(glow, 0))
			px(x, y, c)
		# remaches en las bandas
	for y: int in [59, 137]:
		for x: int in [53, 62, 71]:
			px(x, y, rc("metal_w", 5 if heat > 0.5 else 3))
	# cúpula de ladrillo (colmena) + boca
	for y in range(int(by - ry) - 1, int(by) + 1):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var fx := x + 0.5
			var fy := y + 0.5
			var nx := (fx - cx) / rx
			var ny := (fy - by) / ry
			var d2 := nx * nx + ny * ny
			if d2 > 1.0 or fy > by:
				continue
			var mdx := (fx - cx) / 21.0
			var mdy := (fy - by) / 34.0
			var md := sqrt(mdx * mdx + mdy * mdy)
			if md <= 1.0:
				px(x, y, forge_fire(fx - cx, by - fy))
				continue
			var rdx := (fx - cx) / 28.0
			var rdy := (fy - by) / 41.0
			var rd := sqrt(rdx * rdx + rdy * rdy)
			var glow := heat * 1.3 * pow(clampf(1.0 - (md - 1.0) / 1.1, 0.0, 1.0), 1.6) + 0.12 * heat
			var nz := sqrt(maxf(0.0, 1.0 - d2))
			var cold := 0.22 * maxf(0.0, nx * 0.9 - ny * 0.2) + 0.08
			var c: Color
			if rd <= 1.0:
				# dovelas de la boca
				var a := atan2(fy - by, fx - cx)
				var bi := int(floor(a * 10.0 / PI * 1.6))
				var bj := int(floor(atan2(fy + 1 - by, fx - cx) * 10.0 / PI * 1.6))
				var bk := int(floor(atan2(fy - by, fx + 1 - cx) * 10.0 / PI * 1.6))
				var alb := 0.62 + (h2(bi, 5, 23) - 0.5) * 0.12
				if bi != bj or bi != bk:
					alb = 0.18
				if rd > 0.94:
					alb = 0.14
				c = shade_at("brick_w", "stone_c", alb, x, y, x, y, Vector2(glow * 0.9 - LWm[y * W + x] * 0.6, cold))
			else:
				var course := int((by - fy) / 6.0)
				var rr := sqrt(maxf(0.02, 1.0 - ny * ny))
				var u := asin(clampf(nx / rr, -1.0, 1.0))
				var bi := int(floor(u * rx * rr / 9.0 + 0.5 * (course % 2)))
				var nyb := (fy + 1.0 - by) / ry
				var rrb := sqrt(maxf(0.02, 1.0 - nyb * nyb))
				var ub := asin(clampf(nx / rrb, -1.0, 1.0))
				var course_b := int((by - fy - 1.0) / 6.0)
				var bib := int(floor(ub * rx * rrb / 9.0 + 0.5 * (course_b % 2)))
				var nxr := (fx + 1.0 - cx) / rx
				var bir := int(floor(asin(clampf(nxr / rr, -1.0, 1.0)) * rx * rr / 9.0 + 0.5 * (course % 2)))
				var joint := course_b != course or bib != bi or bir != bi
				var alb := 0.5 + (h2(bi, course, 22) - 0.5) * 0.16
				if joint:
					alb = 0.16
				alb *= lerpf(0.55, 1.0, nz)
				alb *= lerpf(0.55, 1.0, smoothstep(by - ry, by - ry + 34.0, fy))
				if d2 > 0.93:
					alb = 0.1
				c = shade_at("brick_w", "stone_c", alb, x, y, x, y, Vector2(glow - LWm[y * W + x] * 0.7, cold))
			px(x, y, c)
	# zócalo de piedra
	for y in range(250, 268):
		for x in range(4, 121):
			var top := y < 253
			var lx := x - 4
			var row := (y - 253) / 7
			var joint := (not top) and (((lx + (row % 2) * 8) % 16 == 0) or (y - 253) % 7 == 6)
			var alb := 0.5 if top else 0.40
			if y == 250:
				alb = 0.62
			if y == 253:
				alb = 0.14
			if joint:
				alb = 0.12
			if lx == 0 or lx == 116 or y == 267:
				alb = 0.08
			var md := absf(x - cx) / 40.0
			var b := Vector2(heat * 0.8 * clampf(1.0 - md, 0.0, 1.0), 0.0) if top else Vector2.ZERO
			px(x, y, shade_at("stone_w", "stone_c", alb, x, y, x, y, b))
	# Quemas diegéticas: tres rejillas en el zócalo (1 encendida = 1 quema disponible)
	for i in 3:
		var gx := 34 + i * 20
		for y in range(256, 262):
			for x in range(gx, gx + 12):
				var edge := y == 256 or y == 261 or x == gx or x == gx + 11
				var c: Color
				if edge:
					c = rc("metal_w", 1)
				elif i == 0:
					var k := 6 - absi(y - 259) - (1 if (x % 3 == 0) else 0)
					c = rc("fire", clampi(int(k * (0.5 + 0.5 * heat)), 1, 7))
				else:
					c = rc("stone_w", 1) if (x % 3 != 0) else rc("metal_w", 2)
				px(x, y, c)

func forge_fire(dx: float, h: float) -> Color:
	# h: altura sobre la base de la boca; dx: desplazamiento horizontal
	var coal_h := 6.0 + 2.0 * sin(dx * 0.9) + 1.5 * sin(dx * 2.3)
	var xi := int(dx + 100)
	var yi := int(h)
	if h < coal_h:
		var cell := h2(int((dx + 100) / 4.0), int(h / 3.0), 41)
		var k := 1 if cell < 0.5 else 0
		if h > coal_h - 1.6:
			k = int(3 + 3 * heat)
		elif (xi + yi * 3) % 7 == 0:
			k = int(2 + 3 * heat)
		return rc("fire", k)
	var th := (15.0 + 8.0 * sin(dx * 0.42 + 1.0) + 5.0 * sin(dx * 1.07 + 2.0)) * (0.3 + 0.8 * heat)
	var v := 1.0 - (h - coal_h) / maxf(th, 1.0)
	var centre := 1.0 - absf(dx) / 21.0
	if v > 0.0:
		var f := 2.0 + v * 4.0 + centre * 1.6 * heat
		var k := int(f)
		if f - k > 0.7 and ((xi + yi) & 1) == 0:
			k += 1
		return rc("fire", clampi(k, 2, 7))
	var back := int(1 + heat * 1.5 - (h - coal_h) / 40.0)
	return rc("fire", clampi(back, 0, 2)) if ((xi * 3 + yi) % 11 != 0) else rc("fire", clampi(back + 1, 0, 3))

func paint_anvil() -> void:
	var rows := [
		# y, x0, x1
		[244, 116, 146], [245, 115, 150], [246, 116, 147], [247, 118, 141], [248, 120, 138],
		[249, 125, 134], [250, 125, 134], [251, 125, 134], [252, 125, 134], [253, 124, 135],
		[254, 122, 137], [255, 120, 139], [256, 119, 140], [257, 119, 140], [258, 118, 141],
	]
	for r: Array in rows:
		var y: int = r[0]
		for x in range(r[1], r[2] + 1):
			var alb := 0.42
			if y == 244 or y == 245:
				alb = 0.75
			elif y >= 254:
				alb = 0.36
			if x == r[1]:
				alb += 0.2
			elif x >= r[2] - 2:
				alb -= 0.18
			if x == r[1] or x == r[2] or y == 258:
				alb = 0.1 if not (y == 244 or y == 245) else alb
			px(x, y, shade_at("metal_w", "metal_c", alb, x, y, x, y))
	for x in range(116, 147):
		px(x, 243, rc("stone_w", 0))
	px(146, 244, rc("stone_w", 0)); px(150, 245, rc("stone_w", 0)); px(147, 246, rc("stone_w", 0))
	# tocón de madera
	for y in range(259, 266):
		for x in range(117, 143):
			var alb := 0.42 + 0.06 * sin(x * 0.9)
			if y == 259:
				alb = 0.6
			if x == 117 or x == 142 or y == 265:
				alb = 0.1
			px(x, y, shade_at("wood_w", "wood_c", alb, x, y, x, y))

func floor_shadow(cx: int, cy: int, rx: int, ry: int) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var d := Vector2((x - cx) / float(rx), (y - cy) / float(ry)).length()
			if d <= 1.0:
				var c := getp(x, y)
				var k := 0.55 if d < 0.6 else 0.75
				px(x, y, Color(c.r * k, c.g * k, c.b * k * 1.05))

# ---------------------------------------------------------------- personajes por partes
class CB:
	var x0: int
	var y0: int
	var w: int
	var h: int
	var mat := PackedInt32Array()
	var nrm := PackedVector3Array()
	var grp := PackedInt32Array()
	var ordr := PackedInt32Array()
	var col := PackedColorArray()
	var warmlit := PackedByteArray()
	var cur := 0
	var cur_grp := 0
	func _init(ax: int, ay: int, aw: int, ah: int) -> void:
		x0 = ax; y0 = ay; w = aw; h = ah
		mat.resize(w * h); mat.fill(-1)
		nrm.resize(w * h); grp.resize(w * h); ordr.resize(w * h)
		col.resize(w * h); warmlit.resize(w * h)
	func idx(x: int, y: int) -> int:
		var lx := x - x0
		var ly := y - y0
		if lx < 0 or ly < 0 or lx >= w or ly >= h:
			return -1
		return ly * w + lx
	func put(x: int, y: int, m: int, n: Vector3) -> void:
		var i := idx(x, y)
		if i < 0:
			return
		mat[i] = m; nrm[i] = n; grp[i] = cur_grp; ordr[i] = cur

const MAT_NAMES := ["skin", "hair", "shirt", "apron", "trous", "boot", "scarf", "glove", "wood", "iron", "cream", "rock", "magma", "gold"]
const M_SKIN := 0
const M_HAIR := 1
const M_SHIRT := 2
const M_APRON := 3
const M_TROUS := 4
const M_BOOT := 5
const M_SCARF := 6
const M_GLOVE := 7
const M_WOOD := 8
const M_IRON := 9
const M_CREAM := 10
const M_ROCK := 11
const M_MAGMA := 12
const M_GOLD := 13
const M_FAR := 14

func mat_ramps(m: int) -> Array:
	match m:
		M_SKIN: return ["skin_w", "skin_c"]
		M_HAIR: return ["hair_w", "hair_c"]
		M_SHIRT, M_CREAM: return ["shirt_w", "shirt_c"]
		M_APRON, M_GLOVE: return ["apron_w", "apron_c"]
		M_TROUS: return ["trous_w", "trous_c"]
		M_BOOT: return ["boot_w", "boot_c"]
		M_SCARF: return ["scarf_w", "scarf_c"]
		M_WOOD: return ["wood_w", "wood_c"]
		M_IRON: return ["metal_w", "metal_c"]
		M_ROCK: return ["rock_w", "rock_c"]
		M_GOLD: return ["gold", "gold"]
		M_FAR: return ["rockfar_w", "rockfar_c"]
	return ["fire", "fire"]

func part_begin(cb: CB, new_group: bool = true) -> void:
	cb.cur += 1
	if new_group:
		cb.cur_grp += 1

func ell(cb: CB, cx: float, cy: float, rx: float, ry: float, m: int, new_group: bool = true) -> void:
	part_begin(cb, new_group)
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var d2 := dx * dx + dy * dy
			if d2 <= 1.0:
				cb.put(x, y, m, Vector3(dx, dy, sqrt(1.0 - d2)).normalized())

func cap(cb: CB, a: Vector2, b: Vector2, ra: float, rb: float, m: int, new_group: bool = true) -> void:
	part_begin(cb, new_group)
	var mn := Vector2(minf(a.x, b.x) - maxf(ra, rb) - 1, minf(a.y, b.y) - maxf(ra, rb) - 1)
	var mx := Vector2(maxf(a.x, b.x) + maxf(ra, rb) + 1, maxf(a.y, b.y) + maxf(ra, rb) + 1)
	var ab := b - a
	var l2 := maxf(ab.length_squared(), 0.0001)
	for y in range(int(mn.y), int(mx.y) + 1):
		for x in range(int(mn.x), int(mx.x) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			var c := a + ab * t
			var r := lerpf(ra, rb, t)
			var d := p - c
			if d.length() <= r:
				var q := d / r
				cb.put(x, y, m, Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - q.length_squared()))).normalized())

func poly(cb: CB, pts: PackedVector2Array, m: int, curve: float = 0.25, new_group: bool = true) -> void:
	part_begin(cb, new_group)
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	var cx := r.get_center().x
	for y in range(int(r.position.y) - 1, int(r.end.y) + 2):
		for x in range(int(r.position.x) - 1, int(r.end.x) + 2):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				var nx := (x + 0.5 - cx) / maxf(r.size.x * 0.5, 1.0) * curve * 2.0
				cb.put(x, y, m, Vector3(nx, -0.05, 1.0).normalized())

## Roca por facetas: la normal es constante por celda de Voronoi → talla de cincel.
func rock(cb: CB, cx: float, cy: float, rx: float, ry: float, sd: int, m: int = M_ROCK) -> void:
	part_begin(cb, true)
	var r2 := RandomNumberGenerator.new()
	r2.seed = sd
	var k := maxi(3, int(rx * ry / 45.0))
	var seeds: Array[Vector2] = []
	var norms: Array[Vector3] = []
	for i in k:
		var a := r2.randf() * TAU
		var rr := sqrt(r2.randf()) * 0.95
		var sp := Vector2(cos(a) * rr, sin(a) * rr)
		seeds.append(Vector2(cx + sp.x * rx, cy + sp.y * ry))
		var nz := sqrt(maxf(0.0, 1.0 - sp.length_squared()))
		var n := Vector3(sp.x * 1.1, sp.y * 1.1, nz) + Vector3(r2.randf_range(-0.12, 0.12), r2.randf_range(-0.12, 0.12), 0)
		norms.append(n.normalized())
	var ph := r2.randf() * TAU
	for y in range(int(cy - ry * 1.25) - 1, int(cy + ry * 1.25) + 2):
		for x in range(int(cx - rx * 1.25) - 1, int(cx + rx * 1.25) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var ang := atan2(dy, dx)
			var lim := 1.0 + 0.10 * sin(ang * 5.0 + ph) + 0.06 * sin(ang * 9.0 + ph * 2.0)
			if dx * dx + dy * dy > lim * lim:
				continue
			var best := 0
			var bd := 1e9
			for i in seeds.size():
				var dd := Vector2(x + 0.5, y + 0.5).distance_squared_to(seeds[i])
				if dd < bd:
					bd = dd
					best = i
			cb.put(x, y, m, norms[best])

## Iluminación de un personaje: luz cálida de la Forja (izquierda) y fría de la Torre (derecha).
func shade_cb(cb: CB, warm_i: float, cold_i: float, lw: Vector3, lc: Vector3, amb: float = 0.14) -> void:
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			var m := cb.mat[i]
			if m < 0:
				continue
			if m == M_MAGMA:
				continue
			var n := cb.nrm[i]
			var vw := warm_i * maxf(0.0, n.dot(lw))
			var vc := cold_i * maxf(0.0, n.dot(lc))
			var tot := amb + vw + vc
			var rr: Array = mat_ramps(m)
			var use_w := vw >= vc
			var ramp: PackedColorArray = R[rr[0]] if use_w else R[rr[1]]
			var wl: PackedColorArray = R[rr[0]]
			var k := int(clampf(tot, 0.0, 1.0) * (wl.size() - 1) + 0.25)
			# líneas de contacto: la parte de detrás se oscurece donde la tapa otra parte
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j := cb.idx(cb.x0 + lx + d.x, cb.y0 + ly + d.y)
				if j >= 0 and cb.mat[j] >= 0 and cb.grp[j] != cb.grp[i] and cb.ordr[j] > cb.ordr[i]:
					k -= 2
					break
			cb.col[i] = ramp[clampi(k, 0, ramp.size() - 1)]
			cb.warmlit[i] = 1 if (use_w and vw > 0.45) else 0

## Composición con contorno selectivo: oscuro por defecto; en el lado que mira a la Forja el contorno
## toma el tono más oscuro de la rampa cálida (el borde "brilla" en vez de cortar).
func composite(cb: CB) -> void:
	for ly in range(-1, cb.h + 1):
		for lx in range(-1, cb.w + 1):
			var x := cb.x0 + lx
			var y := cb.y0 + ly
			var i := cb.idx(x, y)
			if i >= 0 and cb.mat[i] >= 0:
				px(x, y, cb.col[i])
				continue
			var near := -1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j := cb.idx(x + d.x, y + d.y)
				if j >= 0 and cb.mat[j] >= 0:
					near = j
					if d.x == 1:
						break
			if near >= 0:
				var c := Color("0b080e")
				if cb.warmlit[near] == 1 and heat > 0.4:
					c = Color("3a1214")
				px(x, y, c)

# ---------------------------------------------------------------- heroína (≈64 px)
func paint_hero() -> void:
	var o := Vector2(6, 0)
	var cb := CB.new(120, 180, 100, 90)
	var V := func(x: float, y: float) -> Vector2: return Vector2(x, y) + o
	# coleta (detrás)
	cap(cb, V.call(164, 198), V.call(159, 203), 2.8, 2.4, M_HAIR)
	cap(cb, V.call(159, 203), V.call(156, 210), 2.4, 1.8, M_HAIR, false)
	cap(cb, V.call(156, 210), V.call(155, 216), 1.8, 1.0, M_HAIR, false)
	# cola de la bufanda: cae por la espalda, el tiro del horno la empuja un poco hacia la Forja
	cap(cb, V.call(164, 213), V.call(159, 219), 2.4, 2.2, M_SCARF)
	cap(cb, V.call(159, 219), V.call(156, 226), 2.2, 1.6, M_SCARF, false)
	cap(cb, V.call(156, 226), V.call(153, 230), 1.6, 1.0, M_SCARF, false)
	# brazo trasero
	cap(cb, V.call(165, 214), V.call(162, 224), 3.0, 2.6, M_SHIRT)
	cap(cb, V.call(162, 224), V.call(170, 232), 2.5, 2.2, M_SKIN, false)
	ell(cb, V.call(171.5, 233).x, V.call(171.5, 233).y, 3.0, 2.8, M_GLOVE, false)
	# pierna trasera
	cap(cb, V.call(166, 233), V.call(161, 246), 5.0, 4.0, M_TROUS)
	cap(cb, V.call(161, 246), V.call(158, 256), 4.0, 3.4, M_TROUS, false)
	cap(cb, V.call(158, 252), V.call(158, 259), 4.0, 4.0, M_BOOT, false)
	ell(cb, V.call(161, 259.5).x, V.call(161, 259.5).y, 6.0, 3.0, M_BOOT, false)
	# torso y cadera
	ell(cb, V.call(170, 233).x, V.call(170, 233).y, 8.5, 5.0, M_TROUS)
	ell(cb, V.call(170, 221).x, V.call(170, 221).y, 9.0, 11.0, M_SHIRT)
	# pierna delantera
	cap(cb, V.call(174, 233), V.call(181, 246), 5.2, 4.2, M_TROUS)
	cap(cb, V.call(181, 246), V.call(182, 256), 4.2, 3.6, M_TROUS, false)
	cap(cb, V.call(182, 252), V.call(182, 259), 4.3, 4.3, M_BOOT, false)
	ell(cb, V.call(186, 259.5).x, V.call(186, 259.5).y, 6.5, 3.0, M_BOOT, false)
	# delantal de cuero
	var ap := PackedVector2Array()
	for p: Vector2 in [Vector2(165, 213), Vector2(178, 213), Vector2(181, 230), Vector2(186, 249), Vector2(167, 250), Vector2(164, 231)]:
		ap.append(p + o)
	poly(cb, ap, M_APRON, 0.35)
	# cinturón
	part_begin(cb)
	for x in range(160, 182):
		for y in range(229, 232):
			var xx := x + int(o.x)
			if cb.idx(xx, y) >= 0 and (cb.mat[cb.idx(xx, y)] >= 0):
				cb.put(xx, y, M_WOOD, Vector3(float(x - 170) / 14.0, -0.3 if y == 229 else 0.2, 1).normalized())
	# cuello y cabeza
	cap(cb, V.call(170, 209), V.call(171, 214), 2.6, 2.8, M_SKIN)
	ell(cb, V.call(171.5, 203).x, V.call(171.5, 203).y, 6.5, 7.0, M_SKIN)
	# pelo (masa superior y trasera)
	part_begin(cb)
	var hc: Vector2 = V.call(170, 200)
	for y in range(188, 212):
		for x in range(158, 182):
			var dx := (x + 0.5 - hc.x) / 7.6
			var dy := (y + 0.5 - hc.y) / 7.2
			if dx * dx + dy * dy > 1.0:
				continue
			var lx := x + 0.5 - o.x
			var ly := y + 0.5
			var is_hair := ly < 199.0 or (lx < 167.0 and ly < 209.0) or (lx < 169.5 and ly < 203.5)
			if lx > 176.0 and ly > 197.5:
				is_hair = false
			if is_hair:
				cb.put(x, y, M_HAIR, Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - dx * dx - dy * dy))).normalized())
	# mechones sobre la frente
	for p: Vector2i in [Vector2i(176, 199), Vector2i(177, 199), Vector2i(177, 200), Vector2i(174, 199), Vector2i(175, 200)]:
		cb.put(p.x + int(o.x), p.y, M_HAIR, Vector3(0.6, -0.2, 0.7).normalized())
	# pañuelo (banda clara) + nudo y puntas
	part_begin(cb)
	for x in range(158, 182):
		for y in range(195, 199):
			var lx := x - int(o.x)
			var band_y := 196.0 + (lx - 164) * 0.08
			if absf(y + 0.5 - band_y) <= 1.1:
				var j := cb.idx(x, y)
				if j >= 0 and cb.mat[j] == M_HAIR:
					cb.put(x, y, M_CREAM, Vector3(float(lx - 170) / 8.0, -0.2, 1).normalized())
	ell(cb, V.call(162.5, 197).x, V.call(162.5, 197).y, 2.0, 1.8, M_CREAM, false)
	cap(cb, V.call(161, 197), V.call(155, 195), 1.2, 0.8, M_CREAM, false)
	cap(cb, V.call(161, 198), V.call(156, 201), 1.1, 0.8, M_CREAM, false)
	# bufanda al cuello
	ell(cb, V.call(170, 212).x, V.call(170, 212).y, 7.0, 2.8, M_SCARF)
	ell(cb, V.call(174.5, 214.5).x, V.call(174.5, 214.5).y, 2.2, 2.2, M_SCARF, false)
	# martillo: mango
	var hA: Vector2 = V.call(168, 238)
	var hB: Vector2 = V.call(194, 202)
	cap(cb, hA, hB, 1.5, 1.5, M_WOOD)
	# cabeza del martillo (polígono girado, perpendicular al mango)
	var dd := (hB - hA).normalized()
	var pp := Vector2(-dd.y, dd.x)
	var hc2 := hB + dd * 2.0
	var head := PackedVector2Array([hc2 + pp * 9.0 + dd * 4.5, hc2 + pp * 9.0 - dd * 4.5, hc2 - pp * 6.0 - dd * 4.0, hc2 - pp * 6.0 + dd * 4.0])
	poly(cb, head, M_IRON, 0.3)
	# brazo delantero y guante
	cap(cb, V.call(176, 214), V.call(181, 222), 3.3, 2.9, M_SHIRT)
	cap(cb, V.call(181, 222), V.call(179, 228), 2.8, 2.6, M_SKIN, false)
	ell(cb, V.call(178.5, 229).x, V.call(178.5, 229).y, 3.4, 3.0, M_GLOVE, false)

	var lw := Vector3(-0.85, -0.35, 0.45).normalized()
	var lc := Vector3(0.65, -0.45, 0.55).normalized()
	shade_cb(cb, 0.35 + 0.85 * heat, 0.55 + 0.2 * (1.0 - heat), lw, lc, 0.2)

	# --- detalles a mano ---
	var ox := int(o.x)
	var S := func(x: int, y: int, c: Color) -> void:
		var j := cb.idx(x + ox, y)
		if j >= 0:
			cb.col[j] = c
			if cb.mat[j] < 0:
				cb.mat[j] = M_SKIN
	var dark := Color("1a0c14")
	# ojo, ceja, boca, mejilla, oreja
	S.call(174, 202, rc("hair_w", 1)); S.call(175, 202, rc("hair_w", 1)); S.call(173, 201, rc("hair_w", 2))
	S.call(174, 203, dark); S.call(174, 204, dark); S.call(175, 203, rc("shirt_w", 5)); S.call(175, 204, rc("skin_w", 2))
	S.call(176, 207, rc("blood", 2)); S.call(177, 207, rc("blood", 1))
	S.call(176, 205, rc("skin_w", 4)); S.call(175, 206, Color("d07058"))
	S.call(178, 204, rc("skin_c", 3)); S.call(178, 203, rc("skin_c", 3))
	S.call(167, 203, rc("skin_w", 2)); S.call(167, 204, rc("skin_w", 3)); S.call(166, 204, rc("skin_w", 1))
	# hebilla
	S.call(176, 230, rc("gold", 4)); S.call(177, 230, rc("gold", 3)); S.call(176, 231, rc("gold", 2))
	# bolsillo del delantal y quemaduras
	for x in range(171, 177):
		S.call(x, 237, rc("apron_w", 1))
	S.call(171, 238, rc("apron_w", 1)); S.call(176, 238, rc("apron_w", 1))
	S.call(180, 243, rc("apron_w", 0)); S.call(181, 243, rc("apron_w", 1)); S.call(169, 223, rc("apron_w", 1))
	# remache de correa
	S.call(166, 214, rc("gold", 3))
	# suela de las botas
	for x in range(155, 168):
		var j := cb.idx(x + ox, 262)
		if j >= 0 and cb.mat[j] >= 0:
			cb.col[j] = rc("boot_w", 0)
	for x in range(178, 193):
		var j := cb.idx(x + ox, 262)
		if j >= 0 and cb.mat[j] >= 0:
			cb.col[j] = rc("boot_w", 0)
	# martillo al rojo: la cara de golpe guarda el calor de la Forja
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if cb.mat[i] != M_IRON:
				continue
			var p := Vector2(cb.x0 + lx + 0.5, cb.y0 + ly + 0.5)
			var along := (p - hc2).dot(pp)  # +9 cara de golpe (abajo-derecha) … −6 peña
			var t := clampf((along + 2.0) / 9.0, 0.0, 1.0) * heat
			if t > 0.25:
				var k := int(1 + t * 6.0)
				if absf((p - hc2).dot(dd)) > 3.6:
					k -= 1
				cb.col[i] = rc("fire", clampi(k, 1, 7))
	# puntas del pelo como brasas (se apagan con la Forja)
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if cb.mat[i] != M_HAIR:
				continue
			var y := cb.y0 + ly
			var x := cb.x0 + lx
			if y >= 210 and x < 166 and x > 156:
				var k := int(3 + 3 * heat) - (1 if (x + y) % 2 == 0 else 0)
				cb.col[i] = rc("fire", clampi(k, 1, 6))
			if heat > 0.5 and y <= 192 and (x + y) % 3 == 0:
				cb.col[i] = rc("hair_w", 5)
	composite(cb)

# ---------------------------------------------------------------- gólem de hollín
func paint_golem() -> void:
	var cb := CB.new(410, 150, 150, 120)
	var o := Vector2(0, 0)
	var V := func(x: float, y: float) -> Vector2: return Vector2(x, y) + o
	# brazo trasero (separado del torso: aire entre brazo y cuerpo = silueta legible)
	rock(cb, 514, 212, 6, 10, 101, M_FAR)
	rock(cb, 518, 230, 7, 9, 102, M_FAR)
	rock(cb, 520, 247, 8, 7, 103, M_FAR)
	# chimenea en la espalda
	part_begin(cb)
	for y in range(170, 190):
		for x in range(500, 510):
			var lx := x - 500
			var n := Vector3(-0.6 if lx < 3 else (0.7 if lx > 6 else 0.0), 0.0, 0.8).normalized()
			cb.put(x, y, M_ROCK, n)
	# piernas separadas
	rock(cb, 467, 250, 8, 13, 104)
	rock(cb, 500, 250, 8, 13, 105, M_FAR)
	# pelvis y torso en barril
	rock(cb, 483, 234, 15, 7, 106)
	rock(cb, 482, 210, 20, 17, 107)
	# hombros
	rock(cb, 506, 194, 11, 10, 109)
	rock(cb, 460, 196, 10, 9, 108)
	# cabeza adelantada con ceja pesada
	rock(cb, 471, 185, 9, 8, 110)
	rock(cb, 472, 179, 10, 3.5, 114)
	# brazo delantero colgando hacia la heroína
	rock(cb, 448, 212, 6, 10, 111)
	rock(cb, 443, 231, 7, 9, 112)
	rock(cb, 441, 249, 9, 8, 113)

	var lw := Vector3(-0.85, -0.3, 0.45).normalized()
	var lc := Vector3(0.8, -0.45, -0.05).normalized()
	shade_cb(cb, 0.18 + 0.34 * heat, 0.85, lw, lc, 0.12)

	# grietas de magma en las juntas (la parte de detrás arde donde la tapa la de delante)
	var mag := PackedByteArray()
	mag.resize(cb.w * cb.h)
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if cb.mat[i] < 0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j := cb.idx(cb.x0 + lx + d.x, cb.y0 + ly + d.y)
				if j >= 0 and cb.mat[j] >= 0 and cb.grp[j] != cb.grp[i] and cb.ordr[j] > cb.ordr[i]:
					mag[i] = 1
					break
	# fisuras internas del pecho desde el núcleo
	var core: Vector2 = V.call(478, 208)
	var r3 := RandomNumberGenerator.new()
	r3.seed = 5
	for f in 5:
		var p := core
		var a := r3.randf() * TAU
		for s in r3.randi_range(6, 13):
			a += r3.randf_range(-0.7, 0.7)
			p += Vector2(cos(a), sin(a))
			var j := cb.idx(int(p.x), int(p.y))
			if j >= 0 and cb.mat[j] >= 0:
				mag[j] = 2
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if mag[i] == 0:
				continue
			var hv := h2(lx, ly, 77)
			var k := 3 + int(hv * 3.0)
			if mag[i] == 2:
				k = 4 + int(hv * 2.0)
			k = int(k * (0.55 + 0.45 * heat))
			cb.col[i] = rc("fire", clampi(k, 1, 6))
			cb.mat[i] = M_MAGMA
	# rebote de la luz de las grietas sobre la roca vecina
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if cb.mat[i] != M_ROCK:
				continue
			var nearm := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0)]:
				var j := cb.idx(cb.x0 + lx + d.x, cb.y0 + ly + d.y)
				if j >= 0 and cb.mat[j] == M_MAGMA:
					nearm = true
					break
			if nearm and cb.col[i].get_luminance() < 0.3:
				var cur := R["rock_w"] as PackedColorArray
				var best := 0
				for q in cur.size():
					if cur[q].get_luminance() <= cb.col[i].get_luminance() + 0.001:
						best = q
				cb.col[i] = cur[clampi(best + 2, 0, 5)]
	# núcleo y ojos
	for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(2, 1), Vector2i(1, 2)]:
		var j := cb.idx(int(core.x) + d.x, int(core.y) + d.y)
		if j >= 0:
			cb.col[j] = rc("fire", 7 if (d.x >= 0 and d.y >= 0 and d.x < 2 and d.y < 2) else 5)
			cb.mat[j] = M_MAGMA
	for e: Vector2i in [Vector2i(465, 185), Vector2i(472, 185)]:
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0)]:
			var j := cb.idx(e.x + d.x, e.y + d.y)
			if j >= 0:
				cb.col[j] = rc("fire", 7)
		for d: Vector2i in [Vector2i(-1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var j := cb.idx(e.x + d.x, e.y + d.y)
			if j >= 0:
				cb.col[j] = rc("fire", 4)
	# luz de contorno fría: la ventana de la Torre recorta al gólem por la derecha y por arriba
	for ly in cb.h:
		for lx in cb.w:
			var i := ly * cb.w + lx
			if cb.mat[i] < 0 or cb.mat[i] == M_MAGMA:
				continue
			var xr := cb.idx(cb.x0 + lx + 1, cb.y0 + ly)
			var yu := cb.idx(cb.x0 + lx, cb.y0 + ly - 1)
			var er := xr < 0 or cb.mat[xr] < 0
			var eu := yu < 0 or cb.mat[yu] < 0
			if er and eu:
				cb.col[i] = rc("rock_c", 7)
			elif er or (eu and cb.x0 + lx > 470):
				cb.col[i] = rc("rock_c", 6 if cb.mat[i] == M_ROCK else 5)
	# boca de la chimenea dorsal
	for x in range(501, 509):
		var j := cb.idx(x, 170)
		if j >= 0:
			cb.col[j] = rc("fire", 3 + int(2 * heat) - (1 if x % 2 == 0 else 0))
	composite(cb)
	# humo de la chimenea del gólem
	var r4 := RandomNumberGenerator.new()
	r4.seed = 9
	for b in 6:
		var bc := Vector2(507 + b * 4 + r4.randf_range(-2, 2), 164 - b * 7)
		var br := 3.0 + b * 0.9
		for y in range(int(bc.y - br), int(bc.y + br) + 1):
			for x in range(int(bc.x - br), int(bc.x + br) + 1):
				var dd := Vector2(x + 0.5 - bc.x, y + 0.5 - bc.y).length() / br
				if dd > 1.0:
					continue
				if b >= 3 and ((x + y) & 1) == 1:
					continue
				var k := 2 if dd > 0.6 else 3
				if (x - bc.x) > br * 0.3:
					k = 1 if dd > 0.6 else 2
				px(x, y, rc("smoke", k - (1 if b >= 4 else 0)))

# ---------------------------------------------------------------- partículas
func paint_particles() -> void:
	var r5 := RandomNumberGenerator.new()
	r5.seed = 21
	# brasas que suben desde la boca y la chimenea, arrastradas hacia la Torre
	var n := int(10 + 46 * heat)
	for i in n:
		var t := r5.randf()
		var x := 50.0 + t * 260.0 * r5.randf() + r5.randf_range(-10, 10)
		var y := 232.0 - t * 200.0 * r5.randf_range(0.5, 1.1)
		y += sin(x * 0.07 + i) * 6.0
		var hot := r5.randf()
		var k := 6 if hot > 0.7 else (5 if hot > 0.35 else 4)
		if t > 0.7:
			k -= 1
		px(int(x), int(y), rc("fire", k))
		px(int(x) - 1, int(y) + 1, rc("fire", k - 2))
		if hot > 0.92:
			px(int(x) + 1, int(y), rc("fire", k - 1))
			px(int(x), int(y) - 1, rc("fire", k - 1))
	# polvo en el haz de luna
	for i in 26:
		var y := r5.randf_range(140, 262)
		var t := (y - 136.0) / 132.0
		var x := r5.randf_range(lerpf(455.0, 380.0, t), lerpf(482.0, 446.0, t))
		px(int(x), int(y), rc("stone_c", 7 if r5.randf() > 0.5 else 6))
	# chispas del gólem
	for i in 7:
		var x := r5.randf_range(440, 500)
		var y := r5.randf_range(168, 200)
		px(int(x), int(y), rc("fire", 5))

# ---------------------------------------------------------------- fuente 3×5
const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"], "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"Ñ": [".##.", "....", "#..#", "##.#", "#.##", "#..#", "#..#"],
	"O": [".##.", "#..#", "#..#", "#..#", ".##."], "P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".##.", "#..#", "#..#", "#.#.", ".#.#"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"],
	"Í": [".#.", "...", "###", ".#.", ".#.", ".#.", "###"], "Ó": ["..#.", "....", ".##.", "#..#", "#..#", "#..#", ".##."],
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	"/": ["..#", "..#", ".#.", "#..", "#.."], ".": [".", ".", ".", ".", "#"],
	"·": [".", ".", "#", ".", "."], "+": ["...", ".#.", "###", ".#.", "..."],
	"-": ["...", "...", "###", "...", "..."], ":": [".", "#", ".", "#", "."],
	"×": ["...", "#.#", ".#.", "#.#", "..."],
}

func text_w(s: String) -> int:
	var w := 0
	for ch in s:
		if ch == " ":
			w += 2
		elif GLYPHS.has(ch):
			w += (GLYPHS[ch][0] as String).length() + 1
	return maxi(w - 1, 0)

func text(s: String, x: int, y: int, c: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	var cx := x
	for ch in s:
		if ch == " ":
			cx += 2
			continue
		if not GLYPHS.has(ch):
			continue
		var g: Array = GLYPHS[ch]
		var oy := y - (g.size() - 5)
		var gw := (g[0] as String).length()
		if outline.a > 0.0:
			for j in g.size():
				for i in gw:
					if (g[j] as String)[i] == "#":
						for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
							px(cx + i + d.x, oy + j + d.y, outline)
		for j in g.size():
			for i in gw:
				if (g[j] as String)[i] == "#":
					px(cx + i, oy + j, c)
		cx += gw + 1

func text_c(s: String, cx: int, y: int, c: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	text(s, cx - text_w(s) / 2, y, c, outline)

# ---------------------------------------------------------------- interfaz en el mundo
func plate_bar(x: int, y: int, w: int, frac: float, fill: String, label: String) -> void:
	var h := 9
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var edge := yy == y or yy == y + h - 1 or xx == x or xx == x + w - 1
			var c: Color
			if edge:
				c = Color("0b080e")
			elif yy == y + 1 or xx == x + 1:
				c = rc("metal_w", 3)
			elif yy == y + h - 2 or xx == x + w - 2:
				c = rc("metal_w", 1)
			else:
				var inner := float(xx - x - 2) / float(w - 4)
				if inner <= frac:
					var k := 3
					if yy == y + 2:
						k = 4
					elif yy >= y + h - 3:
						k = 2
					c = rc(fill, k)
				else:
					c = rc("stone_w", 1)
			px(xx, yy, c)
	# remaches
	px(x + 2, y + 2, rc("metal_w", 4)); px(x + w - 3, y + 2, rc("metal_w", 4))
	text_c(label, x + w / 2, y + 2, rc("shirt_w", 5), Color("1a0a10"))

func icon_sword(x: int, y: int) -> void:
	var S := [
		"........kk",
		".......kMk",
		"......kMmk",
		".....kMmk.",
		"..k.kMmk..",
		"..kkMmk...",
		"...kyk....",
		"..kykkk...",
		".kyk..k...",
		"kkk.......",
	]
	for j in S.size():
		var row: String = S[j]
		for i in row.length():
			var c := row[i]
			match c:
				"k": px(x + i, y + j, Color("0b080e"))
				"M": px(x + i, y + j, rc("metal_c", 6))
				"m": px(x + i, y + j, rc("metal_c", 4))
				"y": px(x + i, y + j, rc("gold", 3))

func paint_world_ui() -> void:
	# PV heroína + bloqueo
	plate_bar(158, 270, 54, 1.0, "blood", "86/86")
	# escudo de bloqueo
	var sh := ["kkkkkk", "kccbbk", "kccbbk", "kcbbbk", ".kbbk.", "..kk.."]
	for j in sh.size():
		for i in 6:
			var ch := (sh[j] as String)[i]
			if ch == "k":
				px(150 + i, 271 + j, Color("0b080e"))
			elif ch == "c":
				px(150 + i, 271 + j, rc("scarf_c", 5))
			elif ch == "b":
				px(150 + i, 271 + j, rc("scarf_c", 3))
	text("5", 152, 279, rc("shirt_w", 5), Color("0b080e"))
	# PV gólem
	plate_bar(452, 270, 60, 0.82, "blood", "38/46")
	# intención: ataque 12, flota sobre la cabeza
	icon_sword(462, 158)
	text("12", 475, 162, rc("fire", 6), Color("1a0a10"))
	# nombre
	text_c("GÓLEM DE HOLLÍN", 482, 282, rc("stone_c", 7), Color("0b080e"))
	text_c("LA FOGONERA", 185, 282, rc("hair_w", 5), Color("0b080e"))

# ---------------------------------------------------------------- cartas (75×105 en la MISMA rejilla)
const CARD_RIMS := {
	"attack": ["1a0a0e", "4a1414", "7a2218", "b03a1e", "e0622a"],
	"skill": ["0a0e18", "1a2a44", "2e4a70", "4a74a4", "8ab4d8"],
	"power": ["140e08", "4a3010", "8a6018", "c8962a", "ffd66a"],
	"fuel": ["100a0a", "3a2418", "5e3c26", "8a5a34", "c08a50"],
}

func paint_cards() -> void:
	var hand := [
		["GOLPE", "attack", 1, "strike", 0, ["INFLIGE 7", "DE DAÑO."]],
		["DEFENSA", "skill", 1, "shield", 0, ["GANA 5 DE", "BLOQUEO."]],
		["TAJO ÍGNEO", "attack", 1, "slash", 3, ["INFLIGE 8.", "APLICA 3 DE", "QUEMADURA."]],
		["CARBÓN", "fuel", 0, "coal", 1, ["AL QUEMAR:", "+3 ASCUAS", "Y 6 BLOQUEO"]],
		["FUEGO INTERIOR", "power", 1, "flame", 0, ["AL QUEMAR,", "4 DE DAÑO", "A TODOS."]],
	]
	var hover := 2
	var order := [0, 1, 2, 3, 4]
	for i: int in order:
		if i == hover:
			continue
		var x := 320 + (i - 2) * 56 - 37
		var y := 296 + absi(i - 2) * 4
		draw_card(x, y, hand[i])
	# carta señalada: sube entera
	draw_card(283, 242, hand[hover])

func draw_card(x0: int, y0: int, c: Array) -> void:
	var rim := PackedColorArray()
	for hx: String in CARD_RIMS[c[1]]:
		rim.append(Color(hx))
	var cw := 75
	var ch := 105
	var mastery: int = c[4]
	for y in range(ch):
		for x in range(cw):
			var X := x0 + x
			var Y := y0 + y
			var col: Color
			var cut := (x + y < 3) or (cw - 1 - x + y < 3) or (x + ch - 1 - y < 3) or (cw - 1 - x + ch - 1 - y < 3)
			if cut:
				continue
			var border := x == 0 or y == 0 or x == cw - 1 or y == ch - 1 or (x + y == 3) or (cw - 1 - x + y == 3)
			if border:
				col = Color("0b080e")
			elif x <= 3 or y <= 3 or x >= cw - 4 or y >= ch - 4:
				# marco metálico con bisel: arriba/izquierda claro, abajo/derecha oscuro
				var k := 2
				if x == 1 or y == 1:
					k = 4
				elif x == cw - 2 or y == ch - 2:
					k = 1
				elif x == 3 or y == 3 or x == cw - 4 or y == ch - 4:
					k = 0
				col = rim[k]
				# Maestría: el marco se calienta (brasas incrustadas)
				if mastery >= 2 and (x == 1 or y == 1 or x == cw - 2) and h2(x, y, 51) > 0.7:
					col = rc("fire", 4 + (1 if h2(x, y, 52) > 0.6 else 0))
			else:
				col = rim[0].lerp(Color("0b080e"), 0.3)
			px(X, Y, col)
	# placa de nombre
	for y in range(5, 14):
		for x in range(12, cw - 5):
			var k := Color("0b080e") if (y == 5 or y == 13 or x == 12 or x == cw - 6) else rim[0].lerp(rim[1], 0.5)
			if y == 6 and x > 12 and x < cw - 6:
				k = rim[1]
			px(x0 + x, y0 + y, k)
	text_c(c[0], x0 + 12 + (cw - 17) / 2, y0 + 7, rc("parch", 5) if c[1] != "power" else rc("gold", 5), Color(0, 0, 0, 0))
	# ventana de ilustración por tipo
	var ax := x0 + 5
	var ay := y0 + 15
	var aw := 65
	var ah := 38
	for y in range(-1, ah + 1):
		for x in range(-1, aw + 1):
			if not card_window(c[1], x, y, aw, ah, 1):
				continue
			var inside := card_window(c[1], x, y, aw, ah, 0)
			if not inside:
				px(ax + x, ay + y, Color("0b080e"))
			else:
				px(ax + x, ay + y, card_art(c[3], x, y, aw, ah))
	# bisel de la ventana
	for y in range(0, ah):
		for x in range(0, aw):
			if card_window(c[1], x, y, aw, ah, 0) and not card_window(c[1], x, y - 1, aw, ah, 0):
				px(ax + x, ay + y, rim[4].lerp(getp(ax + x, ay + y), 0.4))
	# cinta de tipo
	for y in range(55, 60):
		for x in range(22, cw - 22):
			var k := 2
			if y == 55:
				k = 3
			elif y == 59:
				k = 0
			if x == 22 or x == cw - 23:
				k = 0
			px(x0 + x, y0 + y, rim[k])
	px(x0 + cw / 2, y0 + 57, rc("parch", 5))
	# pergamino
	for y in range(62, ch - 6):
		for x in range(7, cw - 7):
			var k := 3
			if y == 62 or x == 7:
				k = 2
			if y == ch - 7 or x == cw - 8:
				k = 2
			if h2(x0 + x, y0 + y, 61) > 0.93:
				k = 4 if k == 3 else k
			if h2(x0 + x, y0 + y, 62) > 0.97:
				k = 2
			px(x0 + x, y0 + y, rc("parch", k))
	var lines: Array = c[5]
	for i in lines.size():
		text_c(lines[i], x0 + cw / 2, y0 + 67 + i * 8, rc("ink", 0))
	# pips de Maestría (abajo) y gema de rareza
	for i in 3:
		var lit := i < mastery
		px(x0 + 9 + i * 4, y0 + ch - 4, rc("fire", 6) if lit else rim[1])
		px(x0 + 10 + i * 4, y0 + ch - 4, rc("fire", 4) if lit else rim[0])
	# orbe de coste: crisol de metal fundido
	var oc := Vector2(x0 + 4, y0 + 4)
	for y in range(-8, 9):
		for x in range(-8, 9):
			var d := Vector2(x + 0.5, y + 0.5).length()
			if d > 7.5:
				continue
			var col: Color
			if d > 6.5:
				col = Color("0b080e")
			elif d > 5.2:
				col = rc("metal_w", 3 if (x + y) < 0 else 1)
			else:
				var k := int(6.5 - d * 0.75 - (y + 3) * 0.18)
				col = rc("fire", clampi(k, 2, 7))
			px(int(oc.x) + x, int(oc.y) + y, col)
	text(str(c[2]), int(oc.x) - 1, int(oc.y) - 2, rc("parch", 5), Color("3a0c10"))

func card_window(type: String, x: int, y: int, w: int, h: int, grow: int) -> bool:
	var g := grow
	if x < -g or y < -g or x >= w + g or y >= h + g:
		return false
	match type:
		"attack":
			var cc := 6 + g
			var xx := x + g
			var yy := y + g
			var W2 := w + 2 * g
			var H2 := h + 2 * g
			return not (xx + yy < cc or (W2 - 1 - xx) + yy < cc or xx + (H2 - 1 - yy) < cc or (W2 - 1 - xx) + (H2 - 1 - yy) < cc)
		"power":
			var dx := (x + 0.5 - w / 2.0) / (w / 2.0 + g)
			var dy := (y + 0.5 - h / 2.0) / (h / 2.0 + g)
			return dx * dx * 0.55 + dy * dy * 0.75 <= 1.0 and absf(dx) <= 1.0
		"fuel":
			if y >= 14:
				return true
			var dx2 := (x + 0.5 - w / 2.0) / (w / 2.0 + g)
			var dy2 := (y + 0.5 - 14.0) / (14.0 + g)
			return dx2 * dx2 + dy2 * dy2 <= 1.0
	return true

func card_art(id: String, x: int, y: int, w: int, h: int) -> Color:
	var fx := x + 0.5
	var fy := y + 0.5
	match id:
		"strike":
			# yunque y martillo con estallido de chispas
			var t := fy / h
			var k := int(t * 4.0)
			var col := rc("cloth_w", clampi(1 + k, 1, 4))
			var bd := Vector2(fx - 34.0, (fy - 24.0) * 1.3).length()
			if bd < 18.0:
				col = rc("fire", 3 if bd > 12 else (4 if bd > 7 else 5))
			if bd < 4.0:
				col = rc("fire", 7)
			# rayos
			var ang := atan2(fy - 24.0, fx - 34.0)
			if bd < 26.0 and bd > 5.0 and fmod(ang * 8.0 / PI + 8.0, 2.0) < 0.22:
				col = rc("fire", 6)
			# yunque
			if fy > 27 and fy < 31 and fx > 18 and fx < 52:
				col = rc("metal_c", 4) if fy < 28 else rc("metal_w", 2)
			if fy >= 31 and fx > 29 and fx < 41:
				col = rc("metal_w", 1)
			if fy > 27 and fy < 29 and fx >= 52 and fx < 58 - (fy - 27) * 2:
				col = rc("metal_c", 3)
			# martillo
			var hd := Vector2(fx - 40.0, fy - 16.0)
			var along := hd.dot(Vector2(0.6, -0.8))
			var perp := hd.dot(Vector2(0.8, 0.6))
			if absf(perp) < 1.3 and along > 0 and along < 20:
				col = rc("wood_w", 3 if perp < 0 else 2)
			if absf(along) < 4.5 and perp > -9 and perp < 7:
				col = rc("metal_c", 5 if along < -2 else 3)
				if perp > 5:
					col = rc("fire", 6)
			if h2(x, y, 71) > 0.97:
				col = rc("fire", 6)
			return col
		"shield":
			var t2 := fy / h
			var col := rc("sky", clampi(int(t2 * 4.0) + 1, 0, 4))
			if h2(x, y, 72) > 0.975:
				col = rc("moon", 2)
			var sx := absf(fx - 32.5)
			var top := 5.0
			var bottom := 34.0 - sx * sx * 0.06
			var half := 13.0 if fy < 20 else 13.0 - (fy - 20.0) * 0.8
			if fy > top and fy < bottom and sx < half:
				var edge := sx > half - 1.6 or fy < top + 1.6
				if edge:
					col = rc("gold", 3 if fx < 32.5 else 2)
				else:
					var lit := 5 if fx < 26 else (4 if fx < 33 else 3)
					col = rc("metal_c", lit)
					if fx < 23:
						col = rc("metal_w", 5)  # la Forja se refleja en el lado izquierdo
					if Vector2(fx - 32.5, fy - 17.0).length() < 3.5:
						col = rc("gold", 4 if fx < 32 else 3)
			return col
		"coal":
			var col := rc("brick_w", clampi(int(fy / h * 3.0), 0, 3))
			if fy > 31:
				col = rc("metal_w", 1) if int(fx) % 6 != 0 else rc("fire", 3)
				if fy < 33:
					col = rc("fire", 4) if int(fx) % 6 != 0 else rc("metal_w", 2)
			var d := Vector2((fx - 33.0) / 16.0, (fy - 21.0) / 10.5)
			var ang := atan2(d.y, d.x)
			var lim := 1.0 + 0.12 * sin(ang * 5.0) + 0.06 * sin(ang * 11.0)
			if d.length() < lim:
				# facetas de Voronoi: misma técnica que el gólem, a escala de carta
				var seeds := [Vector2(24, 16), Vector2(33, 13), Vector2(42, 17), Vector2(21, 24), Vector2(31, 22), Vector2(41, 26), Vector2(28, 29), Vector2(37, 30), Vector2(47, 22)]
				var lits := [5, 4, 3, 4, 3, 2, 2, 1, 2]
				var best := 0
				var bd := 1e9
				var second := 1e9
				for i in seeds.size():
					var dd: float = Vector2(fx, fy).distance_squared_to(seeds[i])
					if dd < bd:
						second = bd
						bd = dd
						best = i
					elif dd < second:
						second = dd
				col = rc("rock_w", lits[best])
				if sqrt(second) - sqrt(bd) < 1.0:
					col = rc("fire", 4 + (1 if h2(x, y, 74) > 0.6 else 0))
				if d.length() > lim - 0.1:
					col = rc("rock_w", 0)
			elif h2(x, y, 75) > 0.965 and fy < 30:
				col = rc("fire", 5)
			return col
		"flame":
			var dx := fx - 32.5
			var dy := fy - 20.0
			var ang := atan2(dy, dx)
			var col := rc("gold", 1) if fmod(ang * 6.0 / PI + 12.0, 1.0) < 0.5 else Color("2a1640")
			if Vector2(dx, dy).length() > 26:
				col = Color("1c1030")
			var fl := 1.0 - (34.0 - fy) / (26.0 - absf(dx) * 0.9 + 3.0 * sin(fy * 0.6))
			if fy < 34 and absf(dx) < 10.0 - (34.0 - fy) * 0.32 and fy > 6:
				var k := int(7.5 - (34.0 - fy) / 5.0 - absf(dx) * 0.35)
				col = rc("fire", clampi(k, 2, 7))
			return col
		"slash":
			var t3 := fy / h
			var col := rc("cloth_w", clampi(int(t3 * 3.0) + 1, 1, 3))
			if h2(x, y, 76) > 0.96:
				col = rc("fire", 4)
			var r := Vector2(fx - 18.0, fy - 46.0).length()
			var a := atan2(fy - 46.0, fx - 18.0)
			if r > 30 and r < 40 and a < -0.35 and a > -1.75:
				var tt := (a + 1.75) / 1.4
				var thick := 10.0 * sin(tt * PI)
				if r < 30 + thick:
					var k := int(3 + tt * 4.0 + (r - 30) / thick * 1.5)
					col = rc("fire", clampi(k, 2, 7))
			# hoja
			var hd := Vector2(fx - 50.0, fy - 12.0)
			var along := hd.dot(Vector2(0.75, -0.66))
			var perp := hd.dot(Vector2(0.66, 0.75))
			if along > -14 and along < 10 and absf(perp) < 1.6:
				col = rc("metal_c", 6 if perp < 0 else 4)
				if along < -9:
					col = rc("gold", 3)
			return col
	return Color.MAGENTA

# ---------------------------------------------------------------- HUD superior y controles
func paint_hud() -> void:
	for y in range(0, 15):
		for x in W:
			var c := Color("120c12")
			if y == 13:
				c = rc("metal_w", 2)
			elif y == 14:
				c = Color("0b080e")
			elif y == 0:
				c = Color("0b080e")
			px(x, y, c)
	# Ascuas
	for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]:
		var k := 6 if (d.x == 1 and d.y == 1) else (5 if d.x <= 1 else 4)
		px(7 + d.x, 4 + d.y, rc("fire", k))
	text("548K", 14, 4, rc("gold", 4))
	text("+3.1K/S", 34, 4, rc("stone_c", 6))
	text_c("PISO 4 · HOLLÍN", 320, 4, rc("parch", 4))
	# calor y polvo estelar
	text("CALOR 3", 540, 4, rc("fire", 5))
	text("12", 600, 4, rc("hair_w", 5))
	px(594, 5, rc("fire", 6)); px(593, 6, rc("fire", 5)); px(594, 6, rc("fire", 6)); px(595, 6, rc("fire", 5)); px(594, 7, rc("fire", 4)); px(594, 4, rc("fire", 4))
	# crisol de energía
	var cc := Vector2(30, 322)
	for y in range(-17, 18):
		for x in range(-17, 18):
			var d := Vector2(x + 0.5, y + 0.5).length()
			if d > 16.0:
				continue
			var col: Color
			if d > 15.0:
				col = Color("0b080e")
			elif d > 12.0:
				col = rc("metal_w", 4 if (x + y < -8) else (2 if x + y < 8 else 1))
			elif d > 11.0:
				col = Color("0b080e")
			else:
				var k := int(7.2 - d * 0.42 - (y + 6) * 0.12)
				if ((x + y) & 1) == 0 and fmod(7.2 - d * 0.42 - (y + 6) * 0.12, 1.0) > 0.8:
					k += 1
				col = rc("fire", clampi(k, 2, 7))
			px(int(cc.x) + x, int(cc.y) + y, col)
	text_c("3/3", int(cc.x), int(cc.y) - 2, rc("parch", 5), Color("3a0c10"))
	# pilas
	text("ROBO 8", 8, 345, rc("stone_c", 6), Color("0b080e"))
	text("DESCARTE 0", 586, 345, rc("stone_c", 6), Color("0b080e"))
	# botón fin de turno: placa de hierro remachada
	for y in range(312, 332):
		for x in range(566, 634):
			var edge := y == 312 or y == 331 or x == 566 or x == 633
			var c: Color
			if edge:
				c = Color("0b080e")
			elif y == 313 or x == 567:
				c = rc("metal_w", 4)
			elif y == 330 or x == 632:
				c = rc("metal_w", 1)
			else:
				c = rc("metal_w", 2)
				if y > 322:
					c = rc("metal_w", 2).lerp(rc("metal_w", 1), 0.0)
			px(x, y, c)
	for p: Vector2i in [Vector2i(570, 316), Vector2i(629, 316), Vector2i(570, 327), Vector2i(629, 327)]:
		px(p.x, p.y, rc("metal_w", 5)); px(p.x + 1, p.y + 1, rc("metal_w", 0))
	text_c("FIN DE TURNO", 600, 319, rc("parch", 5), Color("1a0a10"))
