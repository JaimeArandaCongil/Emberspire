extends SceneTree
## Hoja del kit 9-slice + variantes de carta (mejorada, Maestría, Temple, quemable, brillo de rara).
## godot --headless --path . --script res://tests/_review_art/v04/cartas_ui/kit_gen.gd

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const KIT := preload("res://tests/_review_art/v04/cartas_ui/ui_kit.gd")
const CARDS := preload("res://tests/_review_art/v04/cartas_ui/cards.gd")
const ILL := preload("res://tests/_review_art/v04/cartas_ui/illus.gd")
const OUT := "res://tests/_review_art/v04/cartas_ui/out/"
const K := Color("1a0f12")
const TXT := Color("f4e4c8")


func _init() -> void:
	_kit_sheet()
	_variants()
	print("ok")
	quit()


func _label(img: Image, x: int, y: int, t: String, col: Color = TXT) -> void:
	PX.text(img, x, y, t, col, Color(0, 0, 0, 0), K)


func _kit_sheet() -> void:
	# Lienzo nativo 320×180 (se exporta a ×2 = 640×360 y ×4 = 1280×720).
	var img := PX.new_img(320, 200, Color("140c10"))
	# Piezas fuente (tamaño nativo).
	_label(img, 6, 2, "PIEZAS 9-SLICE (nativo)", Color("ffb43a"))
	PX.blit(img, KIT.stone(), 6, 14)
	PX.blit(img, KIT.iron(), 36, 14)
	PX.blit(img, KIT.parchment(), 58, 14)
	var bx := 80
	for s: String in ["normal", "hover", "pressed", "disabled"]:
		PX.blit(img, KIT.button(s), bx, 14)
		bx += 22
	PX.blit(img, KIT.tab(true), 170, 14)
	PX.blit(img, KIT.tab(false), 188, 14)
	PX.blit(img, KIT.ember_icon(), 210, 14)
	PX.blit(img, KIT.heart_icon(), 222, 15)
	PX.blit(img, KIT.shield_icon(), 232, 15)
	# Panel de piedra compuesto (teselado).
	var p1 := KIT.nine(KIT.stone(), 8, 140, 80)
	PX.blit(img, p1, 6, 44)
	_label(img, 16, 52, "Antesala", Color("ffb43a"))
	# Interior: dos filas con barra y botón.
	PX.blit(img, KIT.heart_icon(), 16, 67)
	PX.blit(img, KIT.bar(60, 0.72, [Color("8a1a16"), Color("d2381a"), Color("ff8a6a")]), 26, 67)
	_label(img, 90, 65, "62/86")
	PX.blit(img, KIT.shield_icon(), 16, 79)
	PX.blit(img, KIT.bar(60, 0.35, [Color("2a4a6a"), Color("5a8ac0"), Color("a8d8ff")]), 26, 79)
	_label(img, 90, 77, "12")
	PX.blit(img, KIT.nine(KIT.button("normal"), 6, 56, 14), 16, 96)
	_label(img, 16 + (56 - PX.text_w("Volver")) / 2, 97, "Volver")
	PX.blit(img, KIT.nine(KIT.button("hover"), 6, 56, 14), 78, 96)
	_label(img, 78 + (56 - PX.text_w("ASCENDER")) / 2, 97, "ASCENDER", Color("ffe08a"))
	# Tooltip de hierro.
	var tt := KIT.nine(KIT.iron(Color("2e2830")), 5, 120, 34)
	PX.blit(img, tt, 156, 44)
	PX.blit(img, KIT.ember_icon(), 163, 50)
	_label(img, 175, 49, "Ascuas", Color("ffd36a"))
	# Pergamino.
	var pp := KIT.nine(KIT.parchment(), 5, 120, 46)
	PX.blit(img, pp, 156, 84)
	PX.text(img, 166, 89, "Espíritu de la Forja", Color("6a1a0a"))
	# Pestañas sobre panel.
	var tabs_x := 6
	for i in 4:
		var tb := KIT.nine(KIT.tab(i == 1), 5, 34, 12)
		PX.blit(img, tb, tabs_x + i * 35, 132 + (0 if i == 1 else 1))
	var under := KIT.nine(KIT.iron(Color("3a2a26")), 5, 140, 40)
	PX.blit(img, under, 6, 143)
	var names := ["Arsenal", "Archivo", "Grimor.", "Crónica"]
	for i in 4:
		_label(img, 6 + i * 35 + (34 - PX.text_w(names[i])) / 2, 133 + (0 if i == 1 else 1), names[i], Color("ffe08a") if i == 1 else Color("a08878"))
	# Contador de ascuas del HUD.
	var hud := KIT.nine(KIT.iron(Color("2a2228")), 5, 120, 18)
	PX.blit(img, hud, 156, 140)
	PX.blit(img, KIT.ember_icon(), 162, 144)
	_label(img, 174, 143, "1.32M", Color("ffd36a"))
	_label(img, 214, 143, "+9.1K/s", Color("a08878"))
	var x2 := PX.scaled(img, 2)
	# Cuerpo a ×1 de pantalla con la fuente "Pavesa" (alta).
	PX.text(x2, 326, 120, "1.320.455 Ascuas · +9.150/s", Color("f4e4c8"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	PX.text(x2, 332, 200, "«Paga con el calor que", Color("2a1418"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	PX.text(x2, 332, 213, "guardas abajo y enseñaré", Color("2a1418"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	PX.text(x2, 332, 226, "a una carta a arder.»", Color("2a1418"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	PX.text(x2, 26, 304, "+6 PV máximos.  Nivel 3/30", Color("f4e4c8"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	PX.text(x2, 26, 320, "+10% Ascuas en la Torre.", Color("a08878"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), true)
	x2.save_png(OUT + "ui_kit_x2.png")
	PX.scaled(x2, 2).save_png(OUT + "ui_kit_x4.png")


## Aura de "quemable": contorno exterior de 2 px tramado naranja + pavesas sobre el borde superior.
func _burn_aura(card: Image, frame_t: int, hot: bool) -> Image:
	var w := card.get_width()
	var h := card.get_height()
	var out := PX.new_img(w, h)
	var cols := [Color("ff6a1a"), Color("ffb43a")] if not hot else [Color("ffb43a"), Color("fff4c8")]
	for y in h:
		for x in w:
			if card.get_pixel(x, y).a > 0.0:
				continue
			var d := 99
			for r in range(1, 5):
				for dd: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
					if PX.get_c(card, x + dd.x, y + dd.y).a > 0.0:
						d = mini(d, r)
			if d > 4:
				continue
			# Lengua que sube: más alcance en la parte de arriba y alterna por fotograma.
			var flick := PX.hash2(x / 2, (y + frame_t * 3) / 3, 17)
			var reach := 2.0 + flick * 2.5
			if d <= reach and (d <= 2 or (x + y + frame_t) % 2 == 0):
				out.set_pixel(x, y, cols[1] if d <= 1 else cols[0])
	PX.blit(out, card, 0, 0)
	return out


func _shimmer(card: Image, t: float) -> Image:
	# Banda diagonal de brillo de 6 px que recorre la carta rara (sólo sobre el marco, no sobre el texto).
	var out := card.duplicate() as Image
	var w := out.get_width()
	var h := out.get_height()
	var pos := -h + t * (w + h * 2)
	for y in h:
		for x in w:
			var p := out.get_pixel(x, y)
			if p.a == 0.0:
				continue
			var d := x + y * 0.6 - pos
			if d >= 0.0 and d < 8.0:
				var q := 0.5 if d < 2.0 or d >= 6.0 else 0.75
				if p.get_luminance() > 0.35 and not (y > 140 and y < 214 and x > 18 and x < 162):
					out.set_pixel(x, y, p.lerp(Color("fff4c8"), q * 0.6))
	return out


func _variants() -> void:
	var bg := Color("140c10")
	var row := PX.new_img(5 * 200 + 20, 290, bg)
	var v1 := CARDS.render({"name": "Golpe", "type": "attack", "rarity": "starter", "cost": 1, "up": true,
		"text": "Inflige <9> de daño."}, ILL.art_strike())
	var v2 := CARDS.render({"name": "Tajo Ígneo", "type": "attack", "rarity": "starter", "cost": 1, "mastery": 3,
		"temple": "edge", "text": "Inflige {8} de daño.\nAplica {3} de [Quemadura]."}, ILL.art_ember_slash())
	var v3 := CARDS.render({"name": "Carbón", "type": "fuel", "rarity": "common", "cost": 1, "mastery": 5,
		"temple": "forge", "text": "[Combustible.]\n[Al quemar:] produce ×{3} Ascuas. Gana {6} de Bloqueo."}, ILL.art_coal())
	var v3b := _burn_aura(v3, 0, false)
	var v4 := _shimmer(CARDS.render({"name": "Corona Solar", "type": "power", "rarity": "rare", "cost": 2,
		"text": "Al inicio de tu turno, inflige {3} de daño a TODOS."}, ILL.art_corona()), 0.45)
	var v5 := _burn_aura(CARDS.render({"name": "Carbón", "type": "fuel", "rarity": "common", "cost": 1, "mastery": 5,
		"temple": "rekindle", "text": "[Combustible.]\n[Al quemar:] produce ×{3} Ascuas. Gana {6} de Bloqueo."}, ILL.art_coal()), 1, true)
	var list := [v1, v2, v3b, v4, v5]
	var caps := ["MEJORADA", "MAESTRIA 3 + FILO", "QUEMABLE + FRAGUA", "RARA (brillo)", "EN CALIENTE"]
	for i in list.size():
		PX.blit(row, list[i], 10 + i * 200, 10)
		PX.text(row, 10 + i * 200 + (180 - PX.text_w(caps[i], true)) / 2, 262, caps[i], Color("ffb43a"), Color(0, 0, 0, 0), K, true)
	row.save_png(OUT + "card_states_x2.png")
	# Tira de animación del brillo de rara (6 fotogramas) y del aura (4 fotogramas), ×2 de juego.
	var strip := PX.new_img(6 * 190 + 10, 250, bg)
	var base := CARDS.render({"name": "Corona Solar", "type": "power", "rarity": "rare", "cost": 2,
		"text": "Al inicio de tu turno, inflige {3} de daño a TODOS."}, ILL.art_corona())
	for i in 6:
		PX.blit(strip, _shimmer(base, i / 5.0), 10 + i * 190, 4)
	strip.save_png(OUT + "anim_rare_shimmer.png")
	var strip2 := PX.new_img(4 * 190 + 10, 250, bg)
	for i in 4:
		PX.blit(strip2, _burn_aura(v3, i, false), 10 + i * 190, 4)
	strip2.save_png(OUT + "anim_burnable.png")
