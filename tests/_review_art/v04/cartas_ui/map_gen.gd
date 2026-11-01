extends SceneTree
## Boceto del MAPA v0.4: la Torre en corte, que se escala de verdad. 1280×720 (mundo ×4 + interfaz ×2).
## godot --headless --path . --script res://tests/_review_art/v04/cartas_ui/map_gen.gd

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const KIT := preload("res://tests/_review_art/v04/cartas_ui/ui_kit.gd")
const OUT := "res://tests/_review_art/v04/cartas_ui/out/"
const K := Color("1a0f12")
const INK := Color("0e070a")
const W := 320
const H := 180

# Torre
const TX0 := 92
const TX1 := 228
const WALL := 8
const FLOORS := [[-20, 22], [26, 69], [74, 117], [122, 165]]   # interiores (y0, y1): piso 7?, 6, 5, 4
const SLAB := 4


static func c(h: String) -> Color:
	return Color(h)


func _init() -> void:
	var img := PX.new_img(W, H)
	_sky(img)
	_tower(img)
	_level_done(img, FLOORS[3])
	_level_current(img, FLOORS[2])
	_level_next(img, FLOORS[1])
	_level_unknown(img, FLOORS[0])
	_ash(img)
	img.save_png(OUT + "map_world_native.png")
	var ui := PX.scaled(img, 2)
	_ui(ui)
	var final := PX.scaled(ui, 2)
	_ui_text_x1(final)
	final.save_png(OUT + "map_mockup_1280x720.png")
	print("ok")
	quit()


func _sky(img: Image) -> void:
	var sky := [c("100818"), c("1a0c22"), c("2a1230"), c("401838"), c("5e2238"), c("843030"), c("a84428")]
	for y in H:
		for x in W:
			var t := float(y) / H
			var l := t * 0.95 + (PX.fbm(x / 40.0, y / 9.0, 4) - 0.5) * 0.25
			img.set_pixel(x, y, PX.ramp_pick(sky, l, x, y, 0.4))
	# Bandas de humo.
	for y in H:
		for x in W:
			var n := PX.fbm(x / 22.0 + y / 30.0, y / 6.0, 9)
			if n > 0.62:
				PX.tint(img, x, y, c("120a14"), 0.25 if n < 0.7 else 0.5)
	# Agujas lejanas (siluetas en dos planos).
	for sp: Array in [[18, 70, 9, 0], [44, 96, 6, 0], [262, 60, 10, 0], [292, 88, 7, 0], [60, 120, 14, 1], [250, 112, 16, 1], [300, 128, 12, 1]]:
		var x0: int = sp[0]
		var top: int = sp[1]
		var w: int = sp[2]
		var far: bool = sp[3] == 0
		var col: Color = c("2a1430") if far else c("180a1a")
		for y in range(top, H):
			var hw := maxi(1, int(w * 0.5 * clampf(float(y - top) / 14.0, 0.15, 1.0)))
			for x in range(x0 - hw, x0 + hw + 1):
				PX.put(img, x, y, col)
		if far:
			PX.put(img, x0, top + 6, c("ff8a2a"))
		else:
			PX.put(img, x0 - 2, top + 16, c("ffb43a"))
			PX.put(img, x0 + 1, top + 26, c("ffb43a"))
	# Llanura de escoria al fondo.
	for x in W:
		var hh := 160 + int(sin(x * 0.05) * 3.0 + sin(x * 0.13) * 1.5)
		for y in range(hh, H):
			PX.put(img, x, y, c("140810") if y > hh else c("5e2238"))


func _tower(img: Image) -> void:
	var st := [c("120a0e"), c("1e1418"), c("2e2026"), c("443036"), c("5e4448"), c("82605a"), c("a8806a")]
	for y in H:
		for x in range(TX0 - 4, TX1 + 4):
			var outer_l := x < TX0 + WALL
			var outer_r := x >= TX1 - WALL
			if not (outer_l or outer_r):
				continue
			# Contrafuertes: el muro se ensancha 4 px fuera cada 48 filas (ritmo vertical).
			if x < TX0 or x >= TX1:
				if (y + 10) % 48 > 6:
					continue
			var row := y / 6
			var bx := x + (4 if row % 2 == 1 else 0)
			var mortar := y % 6 == 5 or bx % 8 == 7
			var l := 0.35 + (PX.hash2(bx / 8, row, 2) - 0.5) * 0.14
			# Luz de poniente desde la izquierda; el muro derecho, a la sombra, recibe rebote cálido.
			if outer_l:
				l += 0.25 - (x - TX0) * 0.02
			else:
				l -= 0.1
			if y % 6 == 0 and not mortar:
				l += 0.08
			if mortar:
				l -= 0.25
			img.set_pixel(x, y, PX.ramp_pick(st, l, x, y))
		# Contorno exterior.
	for y in H:
		PX.put(img, TX0 - 1 if (y + 10) % 48 > 6 else TX0 - 5, y, INK)
		PX.put(img, TX1 if (y + 10) % 48 > 6 else TX1 + 4, y, INK)
		PX.put(img, TX0 + WALL, y, INK)
		PX.put(img, TX1 - WALL - 1, y, INK)
	# Forjados (losas entre pisos), con canto iluminado.
	for f: Array in FLOORS:
		var y1: int = f[1]
		for y in range(y1 + 1, y1 + 1 + SLAB):
			for x in range(TX0 + WALL, TX1 - WALL):
				var col := c("2e2026")
				if y == y1 + 1:
					col = c("82605a")
				elif y == y1 + SLAB:
					col = INK
				elif (x / 12 + y) % 7 == 0:
					col = c("1e1418")
				img.set_pixel(x, y, col)
	# Placas de piso en el muro izquierdo (exterior).
	var labels := ["?", "6", "5", "4"]
	for i in FLOORS.size():
		var f2: Array = FLOORS[i]
		var py: int = int(f2[0]) + (int(f2[1]) - int(f2[0])) / 2 - 5
		if py < 2:
			py = 4
		for y in range(py, py + 11):
			for x in range(TX0 + 1, TX0 + 8):
				var e := y == py or y == py + 10 or x == TX0 + 1 or x == TX0 + 7
				img.set_pixel(x, y, INK if e else (c("6a4a30") if i != 2 else c("8a3a1a")))
		var lab: String = labels[i]
		PX.text(img, TX0 + 4 - PX.text_w(lab) / 2, py, lab, c("ffe08a") if i == 2 else c("e0c8a0"))


func _back_wall(img: Image, y0: int, y1: int, light: Callable) -> void:
	var wall := [c("0a0609"), c("140c10"), c("201418"), c("2e1c1e"), c("442824"), c("603828"), c("80502e")]
	for y in range(maxi(0, y0), y1 + 1):
		for x in range(TX0 + WALL + 1, TX1 - WALL - 1):
			var row := y / 5
			var bx := x + (5 if row % 2 == 1 else 0)
			var mortar := y % 5 == 4 or bx % 10 == 9
			var l: float = light.call(x, y)
			l += (PX.hash2(bx / 10, row, 6) - 0.5) * 0.08
			if mortar:
				l -= 0.15
			img.set_pixel(x, y, PX.ramp_pick(wall, l, x, y))


func _brazier(img: Image, x: int, y: int, frame: int) -> void:
	# Brasero de pie: cuenco de hierro y llama de 3 tonos.
	for i in range(-3, 4):
		PX.put(img, x + i, y, c("3a3440") if absi(i) < 3 else INK)
	for i in range(-2, 3):
		PX.put(img, x + i, y + 1, c("2a2430"))
	PX.vline(img, x, y + 2, y + 7, c("2a2430"))
	PX.put(img, x - 1, y + 7, INK)
	PX.put(img, x + 1, y + 7, INK)
	var flame := [".y.", "yoy", "ooo", "ror", ".r."]
	var fl := ["..y..", ".yoy.", ".ywo.", "yoooy", "roror"]
	var src: Array = fl if frame == 0 else flame
	var pal := {"y": c("ffd36a"), "o": c("ff6a1a"), "w": c("fff4c8"), "r": c("c2321e")}
	PX.blit(img, PX.sprite(src, pal), x - src[0].length() / 2, y - src.size())


func _level_done(img: Image, f: Array) -> void:
	var y0: int = f[0]
	var y1: int = f[1]
	var lights := [Vector2(118, y1 - 10), Vector2(204, y1 - 10)]
	_back_wall(img, y0, y1, func(x: int, y: int) -> float:
		var l := 0.1
		for p: Vector2 in lights:
			l = maxf(l, 0.95 - Vector2(x, y).distance_to(p) / 34.0)
		return l)
	_brazier(img, 118, y1 - 8, 0)
	_brazier(img, 204, y1 - 8, 1)
	# Puerta ya cruzada (abierta, cálida) y montón de ceniza del enemigo derrotado.
	_arch(img, 160, y1, 18, 26, [c("2a1410"), c("5a2614"), c("8a3a1a")], false)
	for x in range(138, 150):
		var hh := 3 - absi(x - 144) / 2
		for k in hh:
			PX.put(img, x, y1 - k, c("6a5a5a") if k == hh - 1 else c("3a3034"))
	# Estandarte colgado.
	_banner(img, 182, y0 + 4, c("8a2a1a"))


func _level_current(img: Image, f: Array) -> void:
	var y0: int = f[0]
	var y1: int = f[1]
	_back_wall(img, y0, y1, func(x: int, y: int) -> float:
		var l := 0.1 + maxf(0.0, 0.85 - Vector2(x, y).distance_to(Vector2(130, y0 + 14)) / 40.0)
		l = maxf(l, 0.6 - Vector2(x, y).distance_to(Vector2(176, y1 - 8)) / 30.0)
		return l)
	# Antorcha de pared.
	PX.rect(img, 129, y0 + 16, 2, 6, c("4a2a1e"))
	_brazier(img, 130, y0 + 14, 1)
	# Escalera de caracol que sube al piso siguiente por la derecha (peldaños de 4×3).
	var sx := TX1 - WALL - 4
	var top: int = FLOORS[1][1] + 1
	var steps := (y1 - top) / 3
	for i in steps:
		var yy := y1 - i * 3
		var xx := sx - (steps - 1 - i) * 0 - 34 + i * 2
		for y in range(yy - 2, yy + 1):
			for x in range(xx, mini(xx + 6, TX1 - WALL - 1)):
				var col := c("5e4448")
				if y == yy - 2:
					col = c("a8806a")
				elif x == xx:
					col = c("2e2026")
				PX.put(img, x, y, col)
		PX.put(img, xx - 1, yy, INK)
	# Hueco en el forjado donde llega la escalera.
	for y in range(top - 1, top + SLAB):
		for x in range(196, TX1 - WALL - 1):
			PX.put(img, x, y, c("0e070a") if y > top - 1 else c("82605a"))
	# La Fogonera, a punto de subir (mira a la derecha).
	var hero := [
		"..rrr....",
		".rrrrr...",
		"rrwwwww..",
		".rssss...",
		"..sss....",
		".bbcbb...",
		"bbcccbbs.",
		"sbnnnbs..",
		".snnns...",
		"..nyn....",
		"..nnn....",
		"..d.d....",
		"..d.d....",
		".hh.hh...",
	]
	var pal := {"r": c("c2321e"), "w": c("f4e4c8"), "s": c("e0a080"), "b": c("4a6a8a"), "c": c("8ab4d0"),
		"n": c("8a5030"), "y": c("ffb43a"), "d": c("3d2b2e"), "h": c("6a3020")}
	var hs := PX.outline(PX.sprite(hero, pal), INK)
	PX.blit(img, hs, 150, y1 - 14)
	# Sombra proyectada.
	PX.hline(img, 151, 159, y1, c("140c10"))


func _arch(img: Image, cx: int, base: int, w: int, h: int, inner: Array, glow: bool) -> void:
	var hw := w / 2
	for y in range(base - h - 3, base + 1):
		for x in range(cx - hw - 3, cx + hw + 4):
			var dx := float(x - cx)
			var top := base - h + int(hw - sqrt(maxf(0.0, hw * hw - dx * dx)))
			var inside := absf(dx) < hw and y >= top
			var jamb := absf(dx) < hw + 3 and y >= top - 3 and not inside
			if inside:
				var t := clampf(float(y - top) / h, 0.0, 1.0)
				var col: Color = inner[0]
				if t > 0.55:
					col = inner[2] if (x + y) % 2 == 0 or t > 0.75 else inner[1]
				elif t > 0.25:
					col = inner[1]
				PX.put(img, x, y, col)
			elif jamb:
				var e := absf(dx) >= hw + 2 or y < top - 2
				var col2 := INK if e else c("82605a") if dx < 0 else c("443036")
				if not e and (y - top) % 5 == 0:
					col2 = INK
				PX.put(img, x, y, col2)
	if glow:
		# Derrame de luz sobre el suelo y el muro alrededor.
		for y in range(base - h - 8, base + 1):
			for x in range(cx - hw - 10, cx + hw + 11):
				var d := Vector2((x - cx) / 1.5, (y - base) * 1.0).length()
				if d < 16.0 and absf(x - cx) > hw + 3 and (x + y) % 2 == 0:
					PX.tint(img, x, y, inner[2], 0.25)


func _plaque(img: Image, cx: int, y: int, icon: Array, pal: Dictionary, hot: bool) -> void:
	var w := 11
	for yy in range(y, y + 9):
		for xx in range(cx - w / 2, cx + w / 2 + 1):
			var e := yy == y or yy == y + 8 or xx == cx - w / 2 or xx == cx + w / 2
			PX.put(img, xx, yy, INK if e else (c("8a5a14") if yy == y + 1 else (c("d0a030") if hot else c("5e4448"))))
	var ic := PX.sprite(icon, pal)
	PX.blit(img, ic, cx - ic.get_width() / 2, y + 1)


func _level_next(img: Image, f: Array) -> void:
	var y0: int = f[0]
	var y1: int = f[1]
	var doors := [[120, "combat"], [150, "elite"], [180, "rest"]]
	var cols := {"combat": [c("2a0a0c"), c("8a1c16"), c("e0442a")], "elite": [c("24082a"), c("7a1a5a"), c("d84a9a")],
		"rest": [c("2a1408"), c("a84a14"), c("ffb43a")]}
	_back_wall(img, y0, y1, func(x: int, y: int) -> float:
		var l := 0.06
		for d: Array in doors:
			var k := 0.75 if d[1] == "elite" else 0.5
			l = maxf(l, k - Vector2(x, y).distance_to(Vector2(d[0], y1 - 8)) / 28.0)
		return l)
	var icons := {
		"combat": [["k.....k", ".k...k.", "..k.k..", "...k...", "..k.k..", ".k...k."], {"k": c("e0e4f0")}],
		"elite": [["k.....k", "kk...kk", ".kkkkk.", ".kakak.", "..kkk..", "..k.k.."], {"k": c("e8d8d0"), "a": c("d84a9a")}],
		"rest": [["...y...", "..yoy..", "..ooo..", ".rooor.", "kk.k.kk", "..kkk.."], {"y": c("ffe08a"), "o": c("ff6a1a"), "r": c("c2321e"), "k": c("6a3020")}],
	}
	for d: Array in doors:
		var kind: String = d[1]
		var hovered := kind == "elite"
		_arch(img, d[0], y1, 16 if not hovered else 18, 24 if not hovered else 26, cols[kind], true)
		var ic: Array = icons[kind]
		_plaque(img, d[0], y1 - 38, ic[0], ic[1], hovered)
	# Silueta del élite asomando en la puerta resaltada: dos ojos y cuernos.
	PX.put(img, 147, y1 - 16, c("fff4c8"))
	PX.put(img, 152, y1 - 16, c("fff4c8"))
	PX.put(img, 146, y1 - 21, c("e8d8d0"))
	PX.put(img, 153, y1 - 21, c("e8d8d0"))


func _level_unknown(img: Image, f: Array) -> void:
	var y1: int = f[1]
	_back_wall(img, 0, y1, func(x: int, y: int) -> float:
		return 0.04 + (0.15 if y < 6 else 0.0))
	# Niebla tramada que esconde el piso siguiente; brillo violáceo del jefe arriba.
	for y in range(0, y1 + 1):
		for x in range(TX0 + WALL + 1, TX1 - WALL - 1):
			var n := PX.fbm(x / 14.0, y / 5.0, 31)
			if n > 0.45:
				PX.tint(img, x, y, c("3a2a40"), 0.25 if n < 0.6 else 0.5)
	for x in range(130, 190):
		if (x % 3) == 0:
			PX.put(img, x, 0, c("b07ae0"))
	PX.text(img, 157, 6, "?", c("6a5a70"))


func _banner(img: Image, x: int, y: int, col: Color) -> void:
	for yy in range(y, y + 18):
		for xx in range(x, x + 9):
			var tail := yy > y + 13 and absi(xx - (x + 4)) < (yy - (y + 13))
			if tail:
				continue
			var e := xx == x or xx == x + 8 or yy == y
			PX.put(img, xx, yy, INK if e else (col.lightened(0.2) if xx == x + 1 else col))
	PX.put(img, x + 4, y + 6, c("ffb43a"))
	PX.put(img, x + 3, y + 7, c("ff6a1a"))
	PX.put(img, x + 4, y + 7, c("ffe08a"))
	PX.put(img, x + 5, y + 7, c("ff6a1a"))


func _ash(img: Image) -> void:
	for i in 90:
		var x := int(PX.hash2(i, 1, 55) * W)
		var y := int(PX.hash2(i, 2, 55) * H)
		var inside := x > TX0 + WALL and x < TX1 - WALL
		if inside and PX.hash2(i, 3, 55) > 0.3:
			continue
		PX.put(img, x, y, c("8a7070") if i % 3 else c("ff8a2a"))


# --------------------------------------------------------------------------- Interfaz (rejilla ×2)

func _ui(ui: Image) -> void:
	# Barra superior de hierro.
	PX.blit(ui, KIT.nine(KIT.iron(Color("221a20")), 5, 640, 20), 0, 0)
	PX.blit(ui, KIT.ember_icon(), 8, 5)
	PX.text(ui, 21, 4, "536K", Color("ffd36a"), Color(0, 0, 0, 0), K)
	PX.text(ui, 60, 4, "+3.1K/s", Color("a08878"), Color(0, 0, 0, 0), K)
	PX.text(ui, 520, 4, "Calor 3", Color("ff8a4a"), Color(0, 0, 0, 0), K)
	PX.text(ui, 574, 4, "Polvo 2", Color("d0a8ff"), Color(0, 0, 0, 0), K)
	# Estandarte del acto (izquierda).
	var bx := 22
	for y in range(20, 92):
		for x in range(bx, bx + 120):
			var tail := y > 80 and absi(x - (bx + 60)) < (y - 80) * 5
			if tail:
				continue
			var e := x == bx or x == bx + 119 or y == 91 or (y > 80 and absi(x - (bx + 60)) == (y - 80) * 5)
			var col := Color("6a1c14")
			if e:
				col = K
			elif x == bx + 1 or x == bx + 2:
				col = Color("8e2a1a")
			elif x >= bx + 116:
				col = Color("4a1210")
			elif y % 2 == 0 and x % 2 == 0 and y > 74:
				col = Color("5a1612")
			PX.put(ui, x, y, col)
	PX.hline(ui, bx + 4, bx + 115, 25, Color("d0a030"))
	PX.hline(ui, bx + 4, bx + 115, 70, Color("d0a030"))
	PX.text(ui, bx + 60 - PX.text_w("ACTO I") / 2, 29, "ACTO I", Color("ffd36a"), Color(0, 0, 0, 0), K)
	PX.text(ui, bx + 60 - PX.text_w("HOLLÍN") / 2, 43, "HOLLÍN", Color("f4e4c8"), Color(0, 0, 0, 0), K)
	PX.text(ui, bx + 60 - PX.text_w("Piso 6 de 10") / 2, 57, "Piso 6 de 10", Color("e0c8a0"), Color(0, 0, 0, 0), K)
	# Panel derecho de piedra: estado de la expedición.
	var px0 := 478
	PX.blit(ui, KIT.nine(KIT.stone(), 8, 152, 196), px0, 28)
	PX.text(ui, px0 + 12, 38, "La Fogonera", Color("ffb43a"), Color(0, 0, 0, 0), K)
	PX.blit(ui, KIT.heart_icon(), px0 + 12, 55)
	PX.blit(ui, KIT.bar(96, 1.0, [Color("8a1a16"), Color("d2381a"), Color("ff8a6a")]), px0 + 22, 55)
	PX.text(ui, px0 + 122, 52, "86", Color("f4e4c8"), Color(0, 0, 0, 0), K)
	# Reliquias en ranuras.
	for i in 5:
		var sx := px0 + 12 + i * 26
		PX.blit(ui, KIT.nine(KIT.iron(Color("2a2228")), 5, 22, 22), sx, 136)
	PX.blit(ui, KIT.ember_icon(), px0 + 12 + 6, 142)
	PX.blit(ui, KIT.heart_icon(), px0 + 38 + 7, 143)
	PX.blit(ui, KIT.shield_icon(), px0 + 64 + 7, 143)
	PX.text(ui, px0 + 12, 124, "Reliquias", Color("a08878"), Color(0, 0, 0, 0), K)
	PX.blit(ui, KIT.nine(KIT.button("normal"), 6, 128, 16), px0 + 12, 170)
	PX.text(ui, px0 + 76 - PX.text_w("Ver mazo (13)") / 2, 172, "Ver mazo (13)", Color("f4e4c8"), Color(0, 0, 0, 0), K)
	PX.blit(ui, KIT.nine(KIT.button("normal"), 6, 128, 16), px0 + 12, 194)
	PX.text(ui, px0 + 76 - PX.text_w("Volver a la Forja") / 2, 196, "Volver a la Forja", Color("f4e4c8"), Color(0, 0, 0, 0), K)
	# Tooltip anclado a la puerta resaltada (élite).
	var tx := 225
	var ty := 21
	PX.blit(ui, KIT.nine(KIT.iron(Color("2e2230")), 5, 150, 36), tx, ty)
	PX.text(ui, tx + 8, ty + 6, "ÉLITE", Color("d84a9a"), Color(0, 0, 0, 0), K)
	PX.text(ui, tx + 8 + PX.text_w("ÉLITE") + 5, ty + 6, "Gólem Coronado", Color("f4e4c8"), Color(0, 0, 0, 0), K)
	# Puntero del tooltip hacia la puerta.
	for i in 4:
		PX.hline(ui, 300 - (3 - i), 300 + (3 - i), ty + 36 + i, Color("2e2230") if i < 3 else K)
	# Leyenda inferior: rastro de pisos (mini-torre horizontal).
	var ly := 340
	for i in 10:
		var lx := 200 + i * 24
		var done := i < 5
		var cur := i == 5
		var col := Color("ffb43a") if done else (Color("ffe08a") if cur else Color("3d2b2e"))
		PX.rect(ui, lx, ly, 14, 8, K)
		PX.rect(ui, lx + 1, ly + 1, 12, 6, col.darkened(0.3) if done else col)
		if i < 9:
			PX.hline(ui, lx + 14, lx + 23, ly + 4, Color("5a4040"))
		if done:
			PX.put(ui, lx + 6, ly + 2, Color("fff4c8"))
	PX.rect(ui, 200 + 9 * 24 + 2, ly - 2, 10, 12, Color("b07ae0"))


func _ui_text_x1(img: Image) -> void:
	var col := Color("f4e4c8")
	var dim := Color("a08878")
	var t := func(x: int, y: int, s: String, cc: Color) -> void:
		PX.text(img, x, y, s, cc, Color("0e070a"), Color(0, 0, 0, 0), true)
	# Panel derecho (rejilla ×1 → coordenadas de 1280×720).
	var px0 := 478 * 2
	t.call(px0 + 24, 140, "Energía 3   Robo 5", col)
	t.call(px0 + 24, 158, "Quemas/turno 1", col)
	t.call(px0 + 24, 182, "Racha de Brasas: 0", dim)
	t.call(px0 + 24, 200, "Ascuas en la Torre: 0", dim)
	t.call(px0 + 24, 224, "Calor de Pacto 3 (×1.6)", Color("ff8a4a"))
	# Tooltip del élite.
	t.call(225 * 2 + 16, 21 * 2 + 32, "Recompensa: reliquia + carta", Color("ffd36a"))
	t.call(225 * 2 + 16, 21 * 2 + 48, "Ascuas ×1.5 · Rasgo: Coronado", dim)
