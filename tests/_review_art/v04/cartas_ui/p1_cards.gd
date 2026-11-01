extends Node
## Fase 1 · render REAL de CardView (con ventana) y del tema 9-slice. Guarda en out/:
##   p1_cardview_12.png   las 12 cartas con ilustración propia a resolución de juego
##   p1_cardview_states.png  mejorada, Maestría 1/3/5, Temple Filo/Brasa/Fragua, rara, auras
##   p1_theme.png          botones, paneles, pestañas, tooltip y textos con el tema nuevo
## Ejecutar: godot --path . res://tests/_review_art/v04/cartas_ui/p1_cards.tscn

const OUT := "res://tests/_review_art/v04/cartas_ui/out/"
var root: Control


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	get_window().size = Vector2i(1280, 720)
	root = Control.new()
	root.theme = UI.build_theme()
	root.size = Vector2(1280, 720)
	add_child(root)
	_bg()
	var ids := ["strike", "defend", "kindling", "ember_slash", "heavy_hammer", "sparks", "cleave", "iron_wall", "quench", "bellows", "stoke", "coal"]
	for i in ids.size():
		var cv := CardView.new(Card.new(ids[i]))
		cv.position = Vector2(30 + (i % 6) * 205, 22 + (i / 6) * 352)
		root.add_child(cv)
	await _shot("p1_cardview_12")
	UI.clear(root)
	_bg()
	Game.mastery = {"ember_slash": 6, "coal": 80, "heavy_hammer": 2, "cleave": 35}
	Game.temples = {"coal": "forge", "ember_slash": "edge", "cleave": "ember"}
	var specs := [["strike", true], ["heavy_hammer", false], ["ember_slash", false], ["cleave", false], ["coal", false], ["corona", false]]
	var caps := ["Mejorada", "Maestría 1", "Maestría 3 + Filo", "Maestría 4 + Brasa", "Maestría 5 + Fragua", "Rara (sin tanda)"]
	for i in specs.size():
		var cv2 := CardView.new(Card.new(specs[i][0], specs[i][1]))
		cv2.position = Vector2(30 + i * 205, 40)
		root.add_child(cv2)
		var l := UI.label(caps[i], 14, UI.EMBER)
		l.position = Vector2(30 + i * 205, 280)
		root.add_child(l)
	# Auras (texturas del marco, sin motor): jugable, quemable, en caliente, seleccionada.
	var kinds := ["play", "burn", "hot", "select"]
	for i in kinds.size():
		var a := TextureRect.new()
		var img: Image = load("res://scripts/art/cards/frame.gd").aura(kinds[i], 1)
		img = img.duplicate()
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		a.texture = ImageTexture.create_from_image(img)
		a.position = Vector2(12 + i * 205, 330)
		root.add_child(a)
		var cv3 := CardView.new(Card.new(["defend", "coal", "kindling", "sparks"][i]))
		cv3.position = Vector2(30 + i * 205, 348)
		root.add_child(cv3)
		var l2 := UI.label(["Jugable", "Quemable", "En caliente", "Seleccionada"][i], 14, UI.EMBER)
		l2.position = Vector2(30 + i * 205, 600)
		root.add_child(l2)
	var dummy := CardView.new(Card.new("supernova"))
	dummy.position = Vector2(1080, 348)
	root.add_child(dummy)
	await _shot("p1_cardview_states")
	UI.clear(root)
	_bg()
	var v := UI.vbox(12)
	v.position = Vector2(40, 30)
	root.add_child(v)
	v.add_child(UI.label("Tema v0.4 · Fragua (títulos)", 30, UI.EMBER))
	v.add_child(UI.label("Pavesa 6×9: Inflige 7 de daño. Gana 6 de Bloqueo. ¿Pólvora? ¡Sí! Año, acción, crónica.", 14))
	v.add_child(UI.mlabel("MINI 3×5: ATAQUE · HABILIDAD · PODER · COMBUSTIBLE · Ñandú 0123456789"))
	var hb := UI.hbox(14)
	v.add_child(hb)
	hb.add_child(UI.button("Encender la Forja", func() -> void: pass))
	var b2 := UI.button("Deshabilitado", func() -> void: pass)
	b2.disabled = true
	hb.add_child(b2)
	hb.add_child(UI.button("Un botón con texto largo en Pavesa para ver", func() -> void: pass, 14))
	var p := UI.panel()
	p.custom_minimum_size = Vector2(420, 120)
	var r := UI.rich("[b]Resonancia[/b]\nCon [color=#ffd36a]10[/color] unidades, un generador [color=#b07ae0]Resuena[/color]: te da una ventaja en la Torre.", 14)
	p.add_child(r)
	v.add_child(p)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(600, 150)
	for n in ["Arsenal", "Grimorios", "Archivo", "Crónica"]:
		var c := UI.vbox()
		c.name = n
		c.add_child(UI.label("Contenido de %s · +6 PV máximos. Nivel 3/30" % n, 14))
		tabs.add_child(c)
	tabs.current_tab = 2
	v.add_child(tabs)
	var hb2 := UI.hbox(16)
	v.add_child(hb2)
	var s1 := PanelContainer.new()
	s1.add_theme_stylebox_override("panel", UIKit.sb_stone())
	s1.custom_minimum_size = Vector2(300, 110)
	s1.add_child(UI.label("Panel de piedra (sillares)", 14))
	hb2.add_child(s1)
	var s2 := PanelContainer.new()
	s2.add_theme_stylebox_override("panel", UIKit.sb_parchment())
	s2.custom_minimum_size = Vector2(300, 110)
	var pl := UI.label("Pergamino: «Paga con el calor que guardas abajo.»", 14, Palette.UI[&"ink"])
	pl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s2.add_child(pl)
	hb2.add_child(s2)
	var s3 := PanelContainer.new()
	s3.add_theme_stylebox_override("panel", UI.box(Palette.color(&"furnace_brick", 5), Palette.color(&"ember_ui", 4), 4, 5))
	s3.custom_minimum_size = Vector2(220, 110)
	s3.add_child(UI.label("UI.box teñido (antes StyleBoxFlat)", 14))
	hb2.add_child(s3)
	await _shot("p1_theme")
	get_tree().quit()


func _bg() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.size = Vector2(1280, 720)
	root.add_child(bg)


func _shot(name: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captura: ", name)
