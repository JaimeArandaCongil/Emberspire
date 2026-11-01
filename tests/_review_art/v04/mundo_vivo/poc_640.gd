extends "res://tests/_review_art/v04/mundo_vivo/poc_mundo_vivo.gd"
## Ronda 1 · C1: el mismo lugar (Acto 1, Salas de Fogones) REDIBUJADO a 640×360 nativo (no ampliado).
## Recorte: x 0..400, y 0..272 (conducto, herramientero, brasero, pilastra, arco y tiro, suelo).
## Mismo modelo material+paso; novedades a 640: canto iluminado por pieza (sólo si la luz llega a ≥2 pasos),
## desconchones de esquina, grano interno, herrajes con tornillos, llama de 4 lenguas con contorno.
## Salidas: out/a1_640_crop.png (×2 = como se verá a 1280×720), out/a1_320_vs_640.png, out/anim_brasero640_8f_x3.png

const W2 := 640
const H2 := 360
const FY2 := 236
const CW := 400
const CH := 272
const BR2 := Vector2i(160, 128)
const BEV := 3      # código en `fixed`: +1 si la pieza recibe ≥2 pasos de luz (canto)


func _ready() -> void:
	for ramp: Array in RAMP_HEX:
		var cs: Array = []
		for hx: String in ramp:
			cs.append(Color(hx.replace(" ", "")))
		RAMPS.append(cs)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var t0 := Time.get_ticks_msec()
	_make_640()
	print("poc_640: %d ms" % (Time.get_ticks_msec() - t0))
	get_tree().quit()


func render2(L: Layer, lights: Array) -> Image:
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
			var fx := L.fixed[i]
			if EMISSIVE[m] or fx == 1:
				img.set_pixel(x, y, col(m, v))
				continue
			var qx := L.sx[i] if L.sx[i] >= 0 else x
			var qy := L.sy[i] if L.sy[i] >= 0 else y
			var key := qy * 4096 + qx
			var wc: Vector2i
			if cache.has(key):
				wc = cache[key]
			else:
				var q := Vector2(qx, qy)
				wc = Vector2i(_steps(q, lights, false), _steps(q, lights, true))
				cache[key] = wc
			if fx == 2:
				wc = Vector2i(maxi(0, wc.x - 1), maxi(0, wc.y - 1))
			elif fx == BEV and wc.x >= 2:
				v += 1
			if wc.y > wc.x:
				img.set_pixel(x, y, col(COLD, v + wc.y))
			else:
				img.set_pixel(x, y, col(m, v + wc.x))
	return img


func lights2(k: int, heat: float) -> Array:
	var f: int = FLICK[k % 8]
	var fb := float(f) * 3.0
	var up := 0.75 + 0.5 * heat
	return [
		{"t": "pt", "p": Vector2(BR2.x, BR2.y - 12), "r": [8.0, 16.0 + fb, 26.0 + fb, 40.0 + fb, 60.0 + fb, 88.0 + fb], "ys": 1.05, "y1": FY2 - 1},
		{"t": "pt", "p": Vector2(BR2.x, FY2 + 6), "r": [20.0 + fb, 44.0 + fb, 72.0 + fb], "ys": 2.6, "y0": FY2},
		{"t": "pt", "p": Vector2(320, 300), "r": [68.0 * up, 100.0 * up, 132.0 * up], "ys": 1.0, "y1": FY2 - 1},
		{"t": "pt", "p": Vector2(320, 248), "r": [16.0 * up, 32.0 * up, 56.0 * up], "ys": 2.4, "y0": FY2},
	]


func soot2(x: int, y: int) -> int:
	var s := 0
	if y < 40:
		s = -2
	elif y < 64:
		s = -1
	if y < BR2.y - 10 and y > 12:
		var up := BR2.y - 10 - y
		var wid := 4.0 + up / 9.0
		var dx := absf(x - BR2.x + (0.0 if up < 40 else 2.0))
		var rag := _hash(x / 2, y / 5, 17) * 3.0
		if dx < wid * 0.45 + rag * 0.5:
			s = mini(s, -2)
		elif dx < wid + rag:
			s = mini(s, -1)
	return s


# --- muro -------------------------------------------------------------------------------------

func _bricks2(L: Layer) -> void:
	for y in range(0, FY2):
		var row := y / 7
		var ry := y % 7
		var off := (row % 2) * 8
		for x in CW:
			var xx := x + off
			var ci := xx / 16
			var rx := xx % 16
			var s := soot2(x, y)
			if ry == 0 or rx == 0:
				L.joint(x, y, BRICK, 1 + mini(0, s + 1))
				continue
			var hb := _hash(ci, row, 11)
			var v := 2
			if hb < 0.14:
				v -= 1
			elif hb > 0.88:
				v += 1
			v += s
			# Desconchón de esquina (una por pieza, esquina elegida por hash).
			var hc := _hash(ci, row, 13)
			if hc < 0.22:
				var cx := 1 if hc < 0.11 else 15
				var cy := 1 if _hash(ci, row, 14) < 0.5 else 6
				var dd := absi(rx - cx) + absi(ry - cy)
				if dd <= 1 + int(hc * 12.0) % 3:
					L.joint(x, y, BRICK, 1 + mini(0, s + 1))
					continue
			var pcx := ci * 16 - off + 8
			var pcy := row * 7 + 3
			if ry == 6:
				L.put(x, y, BRICK, v - 1, pcx, pcy)
				continue
			# Grano interno (estable) y grieta ocasional.
			if _hash(x, y, 15) < 0.05:
				v -= 1
			if _hash(ci, row, 12) < 0.05 and rx == 4 + ry:
				v = 0
			L.put(x, y, BRICK, v, pcx, pcy)
			if (ry == 1 or rx == 1) and s >= -1:
				L.fixed[y * L.w + x] = BEV


func _beam2(L: Layer) -> void:
	for x in range(0, 200):
		for y in range(12, 28):
			var v := 3
			if y == 12:
				v = 5
			elif y == 13:
				v = 4
			elif y >= 25:
				v = 1 if y == 27 else 2
			elif (x * 3 + y * 7) % 23 == 0 or _hash(x / 9, y, 44) < 0.08:
				v = 2   # veta
			if posmod(x, 68) == 67:
				v = 1
			L.put(x, y, WOOD, v)
		if posmod(x - 20, 52) < 6:
			for y2 in range(12, 26):
				var fx := posmod(x - 20, 52)
				L.put(x, y2, IRON, 4 if fx == 0 else (1 if fx == 5 else 2))
			if posmod(x - 20, 52) == 2 or posmod(x - 20, 52) == 3:
				for yr: int in [16, 22]:
					L.put(x, yr, IRON, 7 if posmod(x - 20, 52) == 2 else 3)
		if _hash(x, 1, 41) < 0.4:
			var ln := 1 + int(_hash(x, 2, 41) * 5.0)
			for y3 in range(28, 28 + ln):
				L.put(x, y3, ASH, 1 if y3 < 28 + ln - 1 else 2)
	for y in range(0, 12):
		for x in range(0, 200):
			L.put(x, y, BRICK, 0)
	# Chorretones de hollín bajo la viga (el humo se condensa y escurre).
	for i in 9:
		var dx := 8 + int(_hash(i, 3, 47) * 184.0)
		var ln := 10 + int(_hash(i, 4, 47) * 34.0)
		for y4 in range(28, 28 + ln):
			var wdt := 2 if y4 < 28 + ln * 2 / 3 else 1
			for xx in range(dx, dx + wdt):
				L.shift(xx, y4, -1)


func _pipe2(L: Layer) -> void:
	var prof := [1, 3, 5, 8, 6, 5, 4, 3, 2, 1]
	for x in range(0, 192):
		for i in 10:
			L.put(x, 46 + i, COPPER, prof[i])
		# Pátina: manchas verdinosas no; hollín en la parte alta del tubo.
		if _hash(x / 3, 0, 81) < 0.45:
			L.put(x, 46, ASH, 1)
			L.put(x, 47, COPPER, 2)
		if posmod(x, 22) == 11:
			for i2 in range(1, 9):
				L.put(x, 46 + i2, COPPER, maxi(1, int(prof[i2]) - 2))
		if posmod(x, 22) == 12:
			L.put(x, 49, COPPER, 9)
		L.put(x, 54, COPPER, 4 if posmod(x, 5) != 0 else 3)
	for y in range(46, 172):
		for i in 10:
			var v: int = prof[i]
			if y < 56:
				v = maxi(v, 3)
			L.put(46 + i, y, COPPER, v)
	# Codo.
	for dy in 10:
		for dx in 10:
			if dx + dy >= 13:
				L.put(46 + dx, 46 + dy, COPPER, 1)
			elif dx + dy == 12:
				L.put(46 + dx, 46 + dy, COPPER, 3)
	# Bridas con tornillos.
	for fx0: int in [96, 140, 184]:
		for x in range(fx0, fx0 + 4):
			for y in range(43, 59):
				L.put(x, y, IRON, 5 if x == fx0 else (4 if x == fx0 + 1 else (2 if x == fx0 + 2 else 1)))
		for yb: int in [44, 57]:
			L.put(fx0 + 1, yb, IRON, 7)
			L.put(fx0 + 2, yb, IRON, 3)
	for fy0: int in [80, 124]:
		for y in range(fy0, fy0 + 4):
			for x in range(43, 59):
				L.put(x, y, IRON, 5 if y == fy0 else (4 if y == fy0 + 1 else (2 if y == fy0 + 2 else 1)))
		for xb: int in [44, 57]:
			L.put(xb, fy0 + 1, IRON, 7)
	# Abrazaderas a la pared (con sombra en el muro).
	for ax: int in [24, 118, 162]:
		for y in range(44, 60):
			L.shift(ax + 3, y + 2, -2)
			L.put(ax, y, IRON, 3)
			L.put(ax + 1, y, IRON, 2)
		L.put(ax, 60, IRON, 1)
		L.put(ax + 1, 60, IRON, 4)
	# Volante de la válvula sobre su vástago.
	var vc := Vector2i(128, 50)
	for y in range(50, 62):
		L.put(vc.x, y, IRON, 2)
	for a in 64:
		var ang := a * TAU / 64.0
		for rr: float in [7.5, 8.5]:
			var px2 := vc.x + int(roundf(cos(ang) * rr))
			var py2 := vc.y - 8 + int(roundf(sin(ang) * rr * 0.9))
			var v := 5 if sin(ang) < -0.3 else (3 if cos(ang) < 0 else 2)
			if rr > 8.0:
				v -= 1
			L.put(px2, py2, IRON, v)
	for d in range(-7, 8):
		L.put(vc.x + d, vc.y - 8, IRON, 3)
		L.put(vc.x, vc.y - 8 + int(d * 0.9), IRON, 3)
	for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		L.put(vc.x - 1 + p.x, vc.y - 9 + p.y, COPPER, 7 if p == Vector2i.ZERO else 4)


func _tools2(L: Layer) -> void:
	for x in range(68, 134):
		L.put(x, 80, WOOD, 6)
		L.put(x, 81, WOOD, 5 if _hash(x / 5, 0, 3) < 0.7 else 4)
		L.put(x, 82, WOOD, 3)
		L.put(x, 83, WOOD, 1)
	for pg: int in [70, 131]:
		for y in range(78, 86):
			L.put(pg, y, IRON, 4 if y < 80 else 2)
	var t: Array = []
	# Tenazas (dos brazos con remache y bocas curvas).
	for y in range(84, 110):
		var sp := 0 if y < 98 else (y - 98) / 3
		t.append([77 - sp, y, IRON, 5])
		t.append([78 - sp, y, IRON, 3])
		t.append([80 + sp, y, IRON, 3])
		t.append([81 + sp, y, IRON, 1])
	for p: Vector2i in [Vector2i(78, 97), Vector2i(79, 97), Vector2i(78, 98), Vector2i(79, 98)]:
		t.append([p.x, p.y, IRON, 7 if p == Vector2i(78, 97) else 4])
	for p2: Vector2i in [Vector2i(72, 110), Vector2i(73, 111), Vector2i(86, 110), Vector2i(85, 111)]:
		t.append([p2.x, p2.y, IRON, 3])
	# Martillo de forja.
	for y in range(84, 108):
		t.append([95, y, WOOD, 6])
		t.append([96, y, WOOD, 4])
		t.append([97, y, WOOD, 2])
	for y in range(106, 114):
		for x in range(89, 104):
			var v := 4
			if y == 106:
				v = 6
			elif y == 113:
				v = 1
			elif x == 89:
				v = 5
			elif x >= 102:
				v = 2
			t.append([x, y, IRON, v])
	t.append([90, 107, IRON, 7])
	# Cazo de colada.
	for y in range(84, 104):
		t.append([112, y, IRON, 4])
		t.append([113, y, IRON, 2])
	for i in 7:
		var hw := 7 - i / 2
		for x in range(113 - hw, 113 + hw + 1):
			var v2 := 2
			if i == 0:
				v2 = 5
			elif x <= 113 - hw + 1:
				v2 = 4
			elif x >= 113 + hw - 1:
				v2 = 1
			t.append([x, 104 + i, IRON, v2])
	for x in range(108, 119):
		t.append([x, 105, ASH, 1])
	# Herradura en el último gancho.
	for a in 20:
		var ang := PI * 0.15 + a * PI * 1.7 / 20.0
		t.append([126 + int(roundf(cos(ang + PI * 0.5) * 5.0)), 92 + int(roundf(sin(ang + PI * 0.5) * 6.0)), IRON, 4 if a < 10 else 2])
	for y in range(84, 88):
		t.append([126, y, IRON, 2])
	# Sombra proyectada hacia arriba-izquierda (luz del brasero abajo-derecha).
	for e: Array in t:
		L.shift(int(e[0]) - 2, int(e[1]) - 2, -2)
	for e: Array in t:
		L.put(int(e[0]), int(e[1]), int(e[2]), int(e[3]))


func _brazier2(L: Layer) -> void:
	var b := BR2
	for y in range(b.y + 6, b.y + 28):
		for x in range(-5, 6):
			L.shift(b.x + x, y, -1)
	# Placa con dos remaches y brazo en voluta.
	for y in range(b.y + 6, b.y + 26):
		L.put(b.x - 2, y, IRON, 3, -1, -1, true)
		L.put(b.x - 1, y, IRON, 2, -1, -1, true)
		L.put(b.x, y, IRON, 2, -1, -1, true)
		L.put(b.x + 1, y, IRON, 1, -1, -1, true)
	L.put(b.x - 1, b.y + 9, IRON, 6, -1, -1, true)
	L.put(b.x - 1, b.y + 22, IRON, 6, -1, -1, true)
	for i in 10:
		L.put(b.x - 6 + i, b.y + 18 - i, IRON, 2, -1, -1, true)
		L.put(b.x - 6 + i, b.y + 19 - i, IRON, 1, -1, -1, true)
	for p: Vector2i in [Vector2i(-7, 18), Vector2i(-8, 17), Vector2i(-8, 16), Vector2i(-7, 15), Vector2i(-6, 16)]:
		L.put(b.x + p.x, b.y + p.y, IRON, 2, -1, -1, true)
	# Cuenco con labio.
	var rows := [[11, 7], [11, 6], [10, 3], [9, 3], [8, 2], [7, 2], [5, 1], [3, 1]]
	for i in rows.size():
		var hw: int = rows[i][0]
		for x in range(-hw, hw + 1):
			var v: int = rows[i][1]
			if i >= 2:
				if x <= -hw + 1:
					v += 1
				elif x >= hw - 2:
					v -= 1
				if i == 2 and absi(x) < hw - 1:
					v = 1   # sombra bajo el labio
			L.put(b.x + x, b.y - 2 + i, IRON, v, -1, -1, true)
	# Lecho de brasas: terrones con grietas.
	for x in range(-9, 10):
		for y in range(-4, -1):
			var lump := _hash((x + 20) / 3, y, 61)
			var v2 := 3 if lump < 0.3 else (5 if lump > 0.8 else 4)
			if y == -4 and absi(x) > 6:
				continue
			if posmod(x, 3) == 0 and y == -2:
				v2 = 2
			L.put(b.x + x, b.y + y, FIRE, v2)


func _pier2(L: Layer, x0: int) -> void:
	for y in range(28, FY2):
		var course := (y - 28) / 20
		var ry := (y - 28) % 20
		var split := course % 2 == 1
		for x in range(x0, x0 + 32):
			var rx := x - x0
			if ry == 0 or (split and rx == 16):
				L.joint(x, y, STONE, 1)
				continue
			var v := 3
			if rx == 0 or rx == 31:
				v = 1
			elif rx <= 2:
				v = 4
			elif rx >= 27:
				v = 2
			if ry == 19:
				v -= 1
			elif ry == 1:
				v += 1
			# Marcas de trinchante (diagonales finas).
			if _hash(course, rx / 6, 70) < 0.5 and posmod(rx + ry * 2, 7) == 0 and rx > 3 and rx < 27 and ry > 2 and ry < 18:
				v -= 1
			var bx := x0 + (8 if split and rx < 16 else (24 if split else 16))
			v += soot2(x, y) / 2
			L.put(x, y, STONE, v, bx, 28 + course * 20 + 10)
			if ry == 1 and rx > 2 and rx < 27:
				L.fixed[y * L.w + x] = BEV
	var rows := [[6, 6], [5, 6], [4, 6], [3, 6], [6, 3], [5, 3], [3, 3], [2, 2], [1, 2], [1, 1], [0, 1]]
	for i in rows.size():
		var r: Array = rows[i]
		for x in range(x0 - int(r[1]), x0 + 32 + int(r[1])):
			var v2: int = int(r[0]) - (1 if i < 4 else 0)
			if x == x0 - int(r[1]):
				v2 += 1
			L.put(x, 28 + i, STONE, v2)
	var brows := [6, 5, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, 1]
	for i in brows.size():
		for x in range(x0 - 4, x0 + 36):
			var v3: int = brows[i]
			if x <= x0 - 3:
				v3 -= 1
			L.put(x, 220 + i, STONE, v3)


func _arch2(L: Layer) -> void:
	var c := Vector2(320, 124)
	var segs := 15
	for y in range(0, 125):
		for x in range(216, CW):
			var d := Vector2(x - c.x, y - c.y).length()
			if d < 88.0:
				L.erase(x, y)
			elif d < 102.0 or (d < 108.0 and absf(x - c.x) < 8.0):
				var a := atan2(c.y - y, x - c.x)
				var si := int(a / (PI / segs))
				var fr := a / (PI / segs) - si
				var key := si == segs / 2
				if (fr < 0.06 or fr > 0.975) and not key:
					L.joint(x, y, STONE, 1)
					continue
				var ac := (si + 0.5) * PI / segs
				var v := 3 if not key else 4
				if d > 100.0 or (key and d > 106.0):
					v -= 2
				elif d < 90.0:
					v += 1
				if _hash(si, int(d) / 3, 72) < 0.12:
					v -= 1
				L.put(x, y, STONE, v + soot2(x, y) / 2, int(c.x + cos(ac) * 95.0), int(c.y - sin(ac) * 95.0))
				if d < 89.0:
					L.fixed[y * L.w + x] = BEV
	for y in range(36, 125):
		for x in range(230, CW):
			var d2 := Vector2(x - c.x, y - c.y).length()
			if d2 >= 84.0 and d2 < 88.0 and y > 56:
				L.put(x, y, STONE, 2 if d2 < 86.0 else 1)
	for y in range(124, FY2):
		for x in range(232, CW):
			L.erase(x, y)
	for y in range(60, 216):
		for i in 4:
			L.put(232 + i, y, STONE, [2, 2, 1, 0][i])


func _parapet2(L: Layer) -> void:
	for x in range(232, CW):
		L.put(x, 208, STONE, 6)
		L.put(x, 209, STONE, 5)
		L.put(x, 210, STONE, 4)
		L.put(x, 211, STONE, 1)
		L.put(x, 212, STONE, 0)
		for y in range(213, FY2):
			var bi := (x - 232) / 28
			var joint := posmod(x - 232, 28) == 0 or y == 224
			if joint:
				L.joint(x, y, STONE, 1)
			else:
				L.put(x, y, STONE, 3 if y < 224 else 2, 232 + bi * 28 + 14, 220)
	for x in range(232, CW):
		L.put(x, 186, IRON, 4)
		L.put(x, 187, IRON, 3)
		L.put(x, 188, IRON, 1)
		L.put(x, 202, IRON, 2)
		L.put(x, 203, IRON, 1)
		var pp := posmod(x - 236, 14)
		if pp < 2:
			for y in range(189, 208):
				L.put(x, y, IRON, (3 if pp == 0 else 1) if y < 200 else (2 if pp == 0 else 0))
		elif pp == 7:
			for y in range(191, 200):
				if y % 2 == 0:
					L.put(x, y, IRON, 1)
	# Remate de la barandilla en las pilastras.
	for y in range(184, 190):
		for x in range(232, 236):
			L.put(x, y, IRON, 4 if y == 184 else 2)


func _plinth2(L: Layer) -> void:
	for x in range(0, 200):
		for y in range(220, FY2):
			var v := 2
			if y == 220:
				v = 5
			elif y == 221:
				v = 4
			elif y == 222:
				v = 3
			elif y >= FY2 - 2:
				v = 1
			if posmod(x, 44) == 0 and y > 221:
				L.joint(x, y, STONE, 1)
				continue
			L.put(x, y, STONE, v, x / 44 * 44 + 22, 228)
	for i in 4:
		var mx := 90 + i * 34 + int(_hash(i, 0, 55) * 16.0)
		var mw := 8 + int(_hash(i, 1, 56) * 10.0)
		for dx in range(-mw, mw + 1):
			var hh := int((1.0 - pow(float(dx) / mw, 2.0)) * (3.0 + mw * 0.4))
			for dy in range(0, hh + 1):
				var v2 := 4 if dy == hh else (3 if dx < -mw / 3 else 2)
				if dy < hh and _hash(mx + dx, dy, 57) < 0.1:
					v2 = 1
				L.put(mx + dx, FY2 - 1 - dy, ASH, v2 + 1)


func _floor2(L: Layer, heat: float) -> void:
	var vy := float(FY2 - 48)
	for y in range(FY2, CH):
		var depth := (H2 - vy) / (float(y) - vy)
		var rowf := depth * 1.4
		var nxt := (H2 - vy) / (float(y + 1) - vy) * 1.4
		var hline := int(rowf) != int(nxt)
		var ri := int(rowf)
		for x in CW:
			var u := (x - 320.0) * depth / 2.0 + 22.0
			var ci := int(floor(u / 44.0))
			var vline := fposmod(u, 44.0) < depth * 0.6
			var dc := (ri + 0.5) / 1.4
			var yc := int(vy + (H2 - vy) / dc)
			var xc := int(320.0 + ((ci + 0.5) * 44.0 - 22.0) * 2.0 / dc)
			if y == FY2 or y == FY2 + 1:
				L.put(x, y, STONE, 5 if y == FY2 else 4)
				continue
			if y == FY2 + 2 or y == FY2 + 3:
				L.joint(x, y, STONE, 1)
				continue
			if hline or vline:
				L.joint(x, y, STONE, 1)
				continue
			var v := 2 if _hash(ci, ri, 21) < 0.6 else 1
			# Desgaste: borde superior de la losa un paso más claro.
			if not int((H2 - vy) / (float(y - 1) - vy) * 1.4) == ri:
				v += 1
			var blot := _hash(x / 10, y / 4, 25) < 0.16
			if blot and _hash(x, y, 23) < 0.12:
				L.put(x, y, ASH, 0)
				continue
			if _hash(x, y, 24) < 0.002 and absi(x - 320) < 120:
				L.put(x, y, FIRE, 3)
				continue
			L.put(x, y, STONE, v, xc, clampi(yc, FY2, H2 - 1))
	var hot := clampi(2 + int(heat * 3.0), 2, 5)
	for y in range(FY2 + 6, FY2 + 20):
		var hw := 18 + (y - FY2 - 6) * 2
		for x in range(320 - hw, mini(CW, 320 + hw + 1)):
			var edge := absi(x - 320) >= hw - 1 or y <= FY2 + 7 or y >= FY2 + 18
			if edge:
				L.put(x, y, IRON, 4 if y == FY2 + 6 else (2 if y == FY2 + 7 else 1))
			elif posmod(x - 320, 5) < 2 or y == FY2 + 12 or y == FY2 + 13:
				L.put(x, y, IRON, 2 if posmod(x - 320, 5) == 0 else 1)
			else:
				var core := absi(x - 320) < hw / 2 and y > FY2 + 9 and y < FY2 + 16
				L.put(x, y, FIRE, hot + (1 if core else 0) - (1 if absi(x - 320) > hw - 6 else 0))
	for i in 5:
		var rx := 150 + int(_hash(i, 5, 99) * 200.0)
		if absi(rx - 320) < 50:
			continue
		var ry := FY2 + 6 + int(_hash(i, 6, 99) * 16.0)
		for dx in 7:
			L.put(rx + dx, ry, BRICK, 6 if dx < 3 else 5)
			L.put(rx + dx, ry + 1, BRICK, 4)
			L.put(rx + dx, ry + 2, BRICK, 3)
		for dx2 in range(1, 7):
			L.put(rx + dx2 + 1, ry + 3, STONE, 0)


# --- tiro (lejos) a 640 ---------------------------------------------------------------------------

func _far2(heat: float) -> Image:
	var L := Layer.new(CW, CH)
	var R := 140.0
	for y in range(0, FY2 + 4):
		for x in range(200, CW):
			var dx := clampf((x - 320.0) / R, -0.98, 0.98)
			var th := asin(dx)
			var row := y / 5
			var ry := y % 5
			var cc := th / (PI * 0.5) * 30.0 + 0.5 * (row % 2)
			var fr := fposmod(cc, 1.0)
			var mortar := ry == 0 or fr < 0.12 / maxf(0.4, cos(th))
			var v := 1
			if absf(dx) > 0.7:
				v -= 1
			var rib := false
			for rth: float in [-0.95, -0.32, 0.32, 0.95]:
				var rxx := 320.0 + sin(rth) * R
				var rw := 5.0 * cos(rth) + 1.0
				if absf(x - rxx) < rw:
					rib = true
					v = 1 if x < rxx - rw * 0.5 else (0 if x > rxx + rw * 0.4 else 1)
			if rib:
				L.put(x, y, STONE, v + (1 if y % 18 == 0 else 0))
				continue
			if mortar:
				L.joint(x, y, BRICK, v - 1)
			else:
				if _hash(int(floorf(cc)), row, 33) < 0.15:
					v -= 1
				L.put(x, y, BRICK, v)
	var wins := [Vector3i(268, 76, 1), Vector3i(300, 108, 0), Vector3i(384, 104, 1), Vector3i(252, 176, 0), Vector3i(280, 172, 1), Vector3i(352, 84, 0)]
	var lights: Array = [{"t": "pt", "p": Vector2(320, 250), "r": [44.0, 64.0, 86.0, 112.0, 146.0, 196.0], "ys": 1.25, "gain": 1}]
	for w: Vector3i in wins:
		var lit := w.z == 1 or heat > 0.7
		for dy in range(-1, 8):
			for dx2 in range(0, 4):
				if dy == -1 and (dx2 == 0 or dx2 == 3):
					continue
				if lit:
					L.put(w.x + dx2, w.y + dy, FIRE, 2 if dy < 1 else (3 if dx2 < 2 else 2))
				else:
					L.put(w.x + dx2, w.y + dy, BRICK, 0, -1, -1, true)
		for dx3 in range(-1, 5):
			L.put(w.x + dx3, w.y + 8, STONE, 3)
		if lit:
			lights.append({"t": "pt", "p": Vector2(w.x + 2, w.y + 5), "r": [5.0, 10.0], "ys": 1.0})
	for x in range(200, CW):
		L.put(x, 120, IRON, 3)
		for y in range(132, 135):
			L.put(x, y, IRON, 3 if y == 132 else (2 if y == 133 else 1))
		L.put(x, 150, IRON, 1)
		L.put(x, 151, IRON, 0)
		for yy in range(135, 150):
			var t := yy - 135
			if posmod(x + t, 24) == 0 or posmod(x - t, 24) == 0:
				L.put(x, yy, IRON, 1)
		if posmod(x, 24) == 0:
			for yy2 in range(121, 132):
				L.put(x, yy2, IRON, 1)
	var chx := 352
	for y in range(0, 176):
		var ph := y % 22
		if ph < 13:
			if ph < 2 or ph > 10:
				L.put(chx, y, IRON, 2)
				L.put(chx + 1, y, IRON, 1)
			else:
				L.put(chx - 2, y, IRON, 3)
				L.put(chx - 1, y, IRON, 2)
				L.put(chx + 2, y, IRON, 1)
				L.put(chx + 3, y, IRON, 0)
		else:
			L.put(chx, y, IRON, 3)
			L.put(chx + 1, y, IRON, 1)
	for i in 11:
		L.put(chx - i, 176 + i, IRON, 2)
		L.put(chx + 1 + i, 176 + i, IRON, 1)
	var prof := [14, 14, 14, 14, 14, 13, 13, 12, 12, 11, 10, 9, 8, 6, 4]
	for i in prof.size():
		var hw: int = prof[i]
		for dx5 in range(-hw, hw + 1):
			var v2 := 2
			if dx5 <= -hw + 2:
				v2 = 4
			elif dx5 >= hw - 2:
				v2 = 1
			if i <= 1:
				v2 = 5 if i == 0 else 3
			L.put(chx + dx5, 188 + i, COPPER, v2)
	for dx6 in range(-12, 13):
		L.put(chx + dx6, 189, FIRE, 4 if absi(dx6) < 8 else 3)
	for p: Vector2i in [Vector2i(-4, 196), Vector2i(-4, 197), Vector2i(-3, 198), Vector2i(-3, 199)]:
		L.put(chx + p.x, p.y, FIRE, 3)
	return render2(L, lights)


# --- animación a 640 ---------------------------------------------------------------------------------

func flame2(img: Image, bx: int, by: int, k: int) -> void:
	var ph := float(k % 8) / 8.0
	for yy in range(-38, 1):
		for xx in range(-13, 14):
			var dy := float(yy) + 5.0
			var ry := 9.0 if dy < 0.0 else 5.5
			var f := 1.0 - Vector2(xx / 7.2, dy / ry).length()
			for j in 4:
				var p := fposmod(ph + j / 4.0, 1.0)
				var ty := -7.0 - p * 26.0
				var tx := sin(p * TAU + j * 1.7) * 2.6 + (j - 1.5) * 1.4 * (1.0 - p)
				var tr := 5.2 * (1.0 - p) + 1.4
				var d := Vector2((xx - tx) / tr, (yy - ty) / (tr * 1.7)).length()
				f = maxf(f, (1.0 - d) * (1.0 - p * 0.35))
			if f <= 0.0:
				continue
			var lowness := clampf((yy + 34.0) / 34.0, 0.0, 1.0)
			var hv := f * (0.55 + 0.45 * lowness)
			var v := 2
			if hv > 0.64:
				v = 7
			elif hv > 0.5:
				v = 6
			elif hv > 0.36:
				v = 5
			elif hv > 0.22:
				v = 4
			elif hv > 0.09:
				v = 3
			px(img, bx + xx, by + yy, col(FIRE, v))


func smoke2(img: Image, bx: int, top: int, k: int) -> void:
	var order: Array = []
	for j in 6:
		order.append([fposmod(float(k % 8) / 8.0 + j / 6.0, 1.0), j])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for e: Array in order:
		var p: float = e[0]
		var j: int = e[1]
		var cy := int(roundf(top - 2.0 - p * 46.0))
		var cx := int(roundf(bx + p * p * 12.0 + sin(p * 4.0 + j) * 2.4))
		var r := 2.4 + p * 5.6
		for dy in range(-10, 11):
			for dx in range(-10, 11):
				var d := Vector2(dx, dy * 0.75).length()
				if d > r:
					continue
				if p > 0.62 and _hash(dx + 11, dy / 2 + 11, j + 9) < (p - 0.62) * 2.2:
					continue
				var v := 4 if p < 0.45 else 3
				if dy > 0 and d > r - 1.6 and p < 0.6:
					px(img, cx + dx, cy + dy, col(BRICK, 5))
					continue
				if dy < 0 and dx < 0 and d > r - 1.6:
					v += 1
				px(img, cx + dx, cy + dy, col(ASH, v))


func embers2(img: Image, bx: int, by: int, k: int) -> void:
	for i in 5:
		var p := fposmod(float(k % 8) / 8.0 + i * 0.29, 1.0)
		if p > 0.9:
			continue
		var y := by - 12 - int(p * 52.0)
		var x := bx + int(roundf(sin(p * 7.0 + i * 2.0) * 4.0 + (i - 2) * 2.0))
		var v := 7 - int(p * 4.5)
		px(img, x, y, col(FIRE, v))
		if p < 0.3:
			px(img, x, y + 1, col(FIRE, v - 2))
			px(img, x, y + 2, col(FIRE, maxi(1, v - 4)))


func compose2(k: int, heat: float, far: Image, wall_l: Layer) -> Image:
	var img := Image.create(CW, CH, false, Image.FORMAT_RGBA8)
	img.fill(Color("0b0709"))
	blit(img, far, 0, 0)
	for i in 7:
		var p := fposmod(float(k) / 16.0 + float(i) / 7.0 + _hash(i, 0, 3) * 0.3, 1.0)
		var y := 206 - int(p * 170.0)
		var x := 250 + int(_hash(i, 1, 3) * 140.0) + int(roundf(sin(p * 9.0 + i) * 4.0))
		px(img, x, y, col(FIRE, 6 - int(p * 3.5)))
	blit(img, render2(wall_l, lights2(k, heat)), 0, 0)
	smoke2(img, BR2.x, BR2.y - 28, k)
	flame2(img, BR2.x, BR2.y - 4, k)
	embers2(img, BR2.x, BR2.y - 8, k)
	return img


func _make_640() -> void:
	var heat := 0.5
	var L := Layer.new(CW, CH)
	_bricks2(L)
	_beam2(L)
	_arch2(L)
	_pier2(L, 200)
	_parapet2(L)
	_plinth2(L)
	_pipe2(L)
	_tools2(L)
	_brazier2(L)
	_floor2(L, heat)
	var far := _far2(heat)
	var crop := compose2(0, heat, far, L)
	var crop2 := up(crop, 2)
	crop2.save_png(OUT + "a1_640_crop.png")
	# Comparación a la MISMA escala de pantalla: 320 ×4 (izq.) vs 640 ×2 (der.).
	var P := {"floor": 4, "heat": 0.5, "cycle": 0}
	var old := compose(P, 0, true, false, make_layers(P)).get_region(Rect2i(0, 0, CW / 2, CH / 2))
	sheet([up(old, 2), crop], 2, 2, Color("101014"), 6).save_png(OUT + "a1_320_vs_640.png")
	# Tira del brasero a 640 (8 f, 100 ms).
	var fr: Array = []
	for k in 8:
		fr.append(compose2(k, heat, far, L).get_region(Rect2i(126, 40, 68, 116)))
	sheet(fr, 3, 8, Color("101014"), 4).save_png(OUT + "anim_brasero640_8f_x3.png")
