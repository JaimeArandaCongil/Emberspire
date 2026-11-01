extends SceneTree
## Prueba de concepto v0.4 · Cartas e interfaz.
## Ejecutar: godot --headless --path . --script res://tests/_review_art/v04/cartas_ui/gen.gd
## Salida: tests/_review_art/v04/cartas_ui/out/*.png

const PX := preload("res://tests/_review_art/v04/cartas_ui/px.gd")
const CARDS := preload("res://tests/_review_art/v04/cartas_ui/cards.gd")
const ILL := preload("res://tests/_review_art/v04/cartas_ui/illus.gd")
const OUT := "res://tests/_review_art/v04/cartas_ui/out/"


func _init() -> void:
	var defs := [
		[{"name": "Golpe", "type": "attack", "rarity": "starter", "cost": 1, "text": "Inflige {6} de daño."}, ILL.art_strike()],
		[{"name": "Tajo Ígneo", "type": "attack", "rarity": "starter", "cost": 1, "text": "Inflige {6} de daño.\nAplica {2} de [Quemadura]."}, ILL.art_ember_slash()],
		[{"name": "Carbón", "type": "fuel", "rarity": "common", "cost": 1, "text": "[Combustible.]\n[Al quemar:] produce ×{3} Ascuas. Gana {4} de Bloqueo."}, ILL.art_coal()],
		[{"name": "Corona Solar", "type": "power", "rarity": "rare", "cost": 2, "text": "Al inicio de tu turno, inflige {3} de daño a TODOS."}, ILL.art_corona()],
	]
	var bg := Color("140c10")
	# (1) Las cuatro cartas a resolución de juego (×2), en fila.
	var row := PX.new_img(4 * 190 + 20, 264, bg)
	var natives: Array = []
	for i in defs.size():
		var d: Array = defs[i]
		var img: Image = CARDS.render(d[0], d[1])
		PX.blit(row, img, 10 + i * 190, 10)
		natives.append(d[1])
		img.save_png(OUT + "card_%d_x2.png" % i)
	row.save_png(OUT + "cards_game_res.png")
	# (2) Ampliadas ×2 más (×4 efectivo) para revisión píxel a píxel.
	var big := PX.scaled(row, 2)
	big.save_png(OUT + "cards_zoom.png")
	# (3) Ilustraciones sueltas ×6.
	var arts := PX.new_img(4 * (68 * 6 + 12) + 12, 46 * 6 + 24, bg)
	for i in natives.size():
		PX.blit(arts, PX.scaled(natives[i], 6), 12 + i * (68 * 6 + 12), 12)
	arts.save_png(OUT + "illustrations_x6.png")
	print("ok")
	quit()
