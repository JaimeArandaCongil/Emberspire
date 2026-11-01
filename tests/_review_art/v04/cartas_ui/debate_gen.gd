extends SceneTree
## Debate ronda 1 (C3 y C4).
##  C4: texto de cuerpo de 3 cartas largas en (A) Pavesa 6×9 a ×1 de pantalla sobre la carta 80×112,
##      (B) "Hollín 3×5" (mejor alternativa a ×2: 3×5 con minúsculas, x-altura 4) sobre la carta 80×112,
##      (C) Hollín 3×5 ×2 sobre el pergamino del director (75×105, 59×35 útiles).
##  C3: mano de 5 y de 10 cartas 80×112 sobre el keyframe del director a 1280×720.
## godot --headless --path . --script res://tests/_review_art/v04/cartas_ui/debate_gen.gd

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const CARDS := preload("res://tests/_review_art/v04/cartas_ui/cards.gd")
const OUT := "res://tests/_review_art/v04/cartas_ui/out/"
const K := Color("1a0f12")

## Fuente compacta 3×5 (mayúsculas y cifras 5 filas; minúsculas x-altura 4; acento en la fila 0; descendente fila 6).
## Clave: lista de filas empezando en la fila indicada por el primer carácter ("1" = mayúscula/ascendente, "2" = x-altura).
const MINI := {
	"A": "1.#.|#.#|###|#.#|#.#", "B": "1##.|#.#|##.|#.#|##.", "C": "1.##|#..|#..|#..|.##", "D": "1##.|#.#|#.#|#.#|##.",
	"E": "1###|#..|##.|#..|###", "F": "1###|#..|##.|#..|#..", "G": "1.##|#..|#.#|#.#|.##", "H": "1#.#|#.#|###|#.#|#.#",
	"I": "1###|.#.|.#.|.#.|###", "J": "1..#|..#|..#|#.#|.#.", "K": "1#.#|#.#|##.|#.#|#.#", "L": "1#..|#..|#..|#..|###",
	"M": "1#.#|###|###|#.#|#.#", "N": "1##.|#.#|#.#|#.#|#.#", "O": "1.#.|#.#|#.#|#.#|.#.", "P": "1##.|#.#|##.|#..|#..",
	"Q": "1.#.|#.#|#.#|###|.##", "R": "1##.|#.#|##.|#.#|#.#", "S": "1.##|#..|.#.|..#|##.", "T": "1###|.#.|.#.|.#.|.#.",
	"U": "1#.#|#.#|#.#|#.#|###", "V": "1#.#|#.#|#.#|.#.|.#.", "W": "1#.#|#.#|###|###|#.#", "X": "1#.#|#.#|.#.|#.#|#.#",
	"Y": "1#.#|#.#|.#.|.#.|.#.", "Z": "1###|..#|.#.|#..|###",
	"a": "2##.|..#|#.#|.##", "b": "1#..|##.|#.#|#.#|##.", "c": "2.##|#..|#..|.##", "d": "1..#|.##|#.#|#.#|.##",
	"e": "2.#.|#.#|##.|.##", "f": "1.##|#..|##.|#..|#..", "g": "2.##|#.#|.##|..#|##.", "h": "1#..|##.|#.#|#.#|#.#",
	"i": "1#|.|#|#|#", "j": "1.#|..|.#|.#|.#|#.", "k": "1#..|#.#|##.|##.|#.#", "l": "1#.|#.|#.|#.|.#",
	"m": "2##.#.|#.#.#|#.#.#|#.#.#", "n": "2##.|#.#|#.#|#.#", "o": "2.#.|#.#|#.#|.#.", "p": "2##.|#.#|#.#|##.|#..",
	"q": "2.##|#.#|#.#|.##|..#", "r": "2#.#|##.|#..|#..", "s": "2.##|##.|..#|##.", "t": "1.#.|###|.#.|.#.|.##",
	"u": "2#.#|#.#|#.#|.##", "v": "2#.#|#.#|#.#|.#.", "w": "2#...#|#.#.#|#.#.#|.#.#.", "x": "2#.#|.#.|.#.|#.#",
	"y": "2#.#|#.#|.##|..#|##.", "z": "2###|..#|.#.|###",
	"0": "1###|#.#|#.#|#.#|###", "1": "1.#.|##.|.#.|.#.|###", "2": "1##.|..#|.#.|#..|###", "3": "1##.|..#|.#.|..#|##.",
	"4": "1#.#|#.#|###|..#|..#", "5": "1###|#..|##.|..#|##.", "6": "1.##|#..|###|#.#|###", "7": "1###|..#|.#.|.#.|.#.",
	"8": "1###|#.#|###|#.#|###", "9": "1###|#.#|###|..#|##.",
	".": "5#", ",": "5#|#", ":": "3#|.|#", "(": "1.#|#.|#.|#.|.#", ")": "1#.|.#|.#|.#|#.", "+": "2...|.#.|###|.#.",
	"-": "3###", "×": "2...|#.#|.#.|#.#", "%": "1#.#|..#|.#.|#..|#.#",
}
const MINI_ACC := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ñ": "n"}


func mini_glyph(ch: String) -> Dictionary:
	var acc := ""
	if MINI_ACC.has(ch):
		acc = "tilde" if ch == "ñ" else "acute"
		ch = MINI_ACC[ch]
	var src: String = MINI.get(ch, MINI.get(ch.to_upper(), "1###|#.#|#.#|#.#|###"))
	var top := int(src.substr(0, 1))
	var parts := src.substr(1).split("|")
	var w := 0
	for p in parts:
		w = maxi(w, p.length())
	var rows: Array = []
	for i in 7:
		rows.append(".".repeat(w))
	for i in parts.size():
		if top + i < 7:
			rows[top + i] = parts[i].rpad(w, ".")
	if acc != "":
		var r: String = rows[0]
		if w == 1:
			r = "#"
		elif acc == "acute":
			r = ".".repeat(w - 2) + "#." if w >= 2 else "#"
			r = r.rpad(w, ".")
		else:
			r = "##.".substr(0, w).rpad(w, ".")
		rows[0] = r
	return {"w": w, "rows": rows}


func mini_w(t: String) -> int:
	var w := 0
	for i in t.length():
		w += 3 if t[i] == " " else int(mini_glyph(t[i])["w"]) + 1
	return maxi(0, w - 1)


func mini_text(img: Image, x: int, y: int, t: String, col: Color) -> void:
	var cx := x
	for i in t.length():
		if t[i] == " ":
			cx += 3
			continue
		var g := mini_glyph(t[i])
		var rows: Array = g["rows"]
		for yy in rows.size():
			var r: String = rows[yy]
			for xx in r.length():
				if r[xx] == "#":
					PX.put(img, cx + xx, y + yy, col)
		cx += int(g["w"]) + 1


## Texto plano con números en color (sin negrita: a 3 px no cabe). Devuelve nº de líneas.
func mini_rich(img: Image, rect: Rect2i, src: String, pitch: int) -> int:
	var words := src.split(" ")
	var lines: Array = []
	var cur := ""
	for wd in words:
		var cand := wd if cur == "" else cur + " " + wd
		if mini_w(cand) > rect.size.x and cur != "":
			lines.append(cur)
			cur = wd
		else:
			cur = cand
	if cur != "":
		lines.append(cur)
	var y := rect.position.y
	for ln: String in lines:
		var x := rect.position.x + (rect.size.x - mini_w(ln)) / 2
		var col := Color("2a1418") if y + 6 <= rect.end.y else Color("c01010")
		for wd2 in ln.split(" "):
			var isnum := wd2.length() > 0 and (wd2[0] >= "0" and wd2[0] <= "9" or wd2[0] == "×")
			mini_text(img, x, y, wd2, Color("a8300c") if isnum and col != Color("c01010") else col)
			x += mini_w(wd2) + 3
		y += pitch
	return lines.size()


func parch(img: Image, r: Rect2i) -> void:
	for y in range(r.position.y - 2, r.end.y + 2):
		for x in range(r.position.x - 2, r.end.x + 2):
			var e := mini(mini(x - r.position.x + 2, r.end.x + 1 - x), mini(y - r.position.y + 2, r.end.y + 1 - y))
			PX.put(img, x, y, K if e == 0 else (Color("c8a47c") if e == 1 else Color("e4c8a0")))


const TEXTS := [
	["Tormenta de Cisco", "[Combustible.]\n[Al quemar:] {5} de daño a un enemigo al azar {3} veces. Aplica {2} de [Quemadura] a TODOS.",
		"Combustible. Al quemar: 5 de daño a un enemigo al azar 3 veces. Aplica 2 de Quemadura a TODOS."],
	["Transmutar", "Transforma {1} carta al azar de tu mano en una carta aleatoria mejorada.\n[Agotar.]",
		"Transforma 1 carta al azar de tu mano en una carta aleatoria mejorada. Agotar."],
	["Eco del Reliquario", "Gana {4} de Bloqueo (+1 por cada {4} reliquias del Reliquario).",
		"Gana 4 de Bloqueo (+1 por cada 4 reliquias del Reliquario)."],
]


func _init() -> void:
	_c4()
	_c3()
	print("ok")
	quit()


func _c4() -> void:
	# Lienzo a resolución final (1:1 de pantalla). 3 filas (cartas) × 3 columnas (opciones).
	var cw := 170
	var img := PX.new_img(30 + cw * 3 + 20, 40 + 3 * 120, Color("140c10"))
	var heads := ["A · Pavesa 6x9 a x1 (80x112)", "B · Mini 3x5 a x2 (80x112)", "C · Mini 3x5 a x2 (75x105 DA)"]
	for i in 3:
		PX.text(img, 30 + i * cw, 10, heads[i], Color("ffb43a"), Color(0, 0, 0, 0), K)
	for r in TEXTS.size():
		var t: Array = TEXTS[r]
		var y0 := 34 + r * 120
		PX.text(img, 4, y0 - 2, str(r + 1), Color("a08878"))
		# A: pergamino de la carta 80×112: 64×32 útiles nativos → 128×64 de pantalla.
		var ra := Rect2i(30, y0 + 8, 128, 64)
		parch(img, ra)
		CARDS.draw_rich(img, Rect2i(ra.position.x + 2, ra.position.y + 2, ra.size.x - 4, ra.size.y - 2), t[1],
			Color("2a1418"), Color("a8300c"), Color("8a1a0a"), Color("1e7a1e"))
		# B y C: texto mini en nativo y escalado ×2.
		for opt in 2:
			var nw := 64 if opt == 0 else 59
			var nh := 32 if opt == 0 else 35
			var nat := PX.new_img(nw + 4, nh + 4)
			parch(nat, Rect2i(2, 2, nw, nh))
			var n := mini_rich(nat, Rect2i(3, 3, nw - 2, nh - 1), t[2], 8)
			var sc := PX.scaled(nat, 2)
			PX.blit(img, sc, 30 + (opt + 1) * cw - 4, y0 + 4)
			var note := "%d líneas" % n + (" · NO CABE" if n * 8 > nh else "")
			PX.text(img, 30 + (opt + 1) * cw, y0 + 4 + sc.get_height() + 2, note, Color("ff6a6a") if n * 8 > nh else Color("7ad47a"))
		PX.text(img, 30, y0 + 78, t[0], Color("a08878"))
	img.save_png(OUT + "c4_text_test.png")
	PX.scaled(img, 2).save_png(OUT + "c4_text_test_zoom.png")


func _c3() -> void:
	var kf := Image.load_from_file(ProjectSettings.globalize_path("res://tests/_review_art/v04/director/keyframe_hot_1280.png"))
	kf.convert(Image.FORMAT_RGBA8)
	var cards: Array = []
	for i in 4:
		var c := Image.load_from_file(ProjectSettings.globalize_path(OUT + "card_%d_x2.png" % i))
		c.convert(Image.FORMAT_RGBA8)
		cards.append(c)
	for n: int in [5, 10]:
		var img := kf.duplicate() as Image
		# Borra la mano del director repitiendo la fila de suelo y=598 (sólo en la zona de la mano).
		for y in range(478, 720):
			for x in range(330, 945):
				if y >= 596 or (x > 550 and x < 725):
					img.set_pixel(x, y, kf.get_pixel(x, mini(y, 595) if y < 596 else 595 - (y % 8)))
		# Zona útil de la mano: entre el crisol de energía (x≈130) y "Fin de turno" (x≈1125).
		var x0 := 150
		var x1 := 1120
		var cwid := 160
		var step := mini(170, int(float(x1 - x0 - cwid) / (n - 1)))
		var total := step * (n - 1) + cwid
		var sx := (x0 + x1 - total) / 2
		var hov := n / 2
		for i in n:
			if i == hov:
				continue
			var cimg: Image = cards[i % 4]
			# En reposo se ve placa + ilustración (126 px): el borde superior de la carta en y = 720 - 126.
			PX.blit(img, cimg, sx + i * step - 10, 720 - 126 - 10)
		var ch: Image = cards[hov % 4]
		PX.blit(img, ch, sx + hov * step - 10, 720 - 224 - 4 - 10)
		img.save_png(OUT + "c3_hand_%d.png" % n)
