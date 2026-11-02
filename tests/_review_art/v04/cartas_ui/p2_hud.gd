extends Node
## Fase 2 · render real de los widgets del HUD sobre el keyframe de DA (posiciones de la disposición aprobada).
## Ejecutar: godot --path . res://tests/_review_art/v04/cartas_ui/p2_hud.tscn  → out/p2_hud.png, out/p2_hud_icons.png

const OUT := "res://tests/_review_art/v04/cartas_ui/out/"


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.embers = 548000.0
	Game.max_floor = 12
	Game.stardust_total = 2
	Game.stardust = 2
	get_window().size = Vector2i(1280, 720)
	var root := Control.new()
	root.theme = UI.build_theme()
	root.size = Vector2(1280, 720)
	add_child(root)
	var kf := Image.load_from_file(ProjectSettings.globalize_path("res://tests/_review_art/v04/director/keyframe_hot_1280.png"))
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(kf)
	root.add_child(bg)
	var cover := ColorRect.new()
	cover.color = Palette.color(&"plate", 1)
	cover.position = Vector2(0, 592)
	cover.size = Vector2(1280, 128)
	root.add_child(cover)
	var hud := TopHud.new()
	root.add_child(hud)
	var fl := FloorLabel.new()
	fl.position.y = 30
	root.add_child(fl)
	fl.set_floor(4, "Hollín", "Calor de Pacto 3 · +60% Ascuas")
	var cru := EnergyCrucible.new()
	cru.position = Vector2(26, 610)
	root.add_child(cru)
	cru.set_energy(2, 3)
	var bp := BurnPlate.new()
	bp.position = Vector2(26, 568)
	root.add_child(bp)
	bp.set_burns(2, 3)
	var hp := HpPlate.new()
	hp.position = Vector2(292, 540)
	root.add_child(hp)
	hp.set_values(61, 86, 12)
	hp.snap()
	var hp2 := HpPlate.new()
	hp2.position = Vector2(884, 540)
	root.add_child(hp2)
	hp2.set_values(30, 46, 0, 6)
	hp2.snap()
	hp2.set_values(24, 46, 0, 6)
	var st := StatusRow.new()
	st.position = Vector2(884, 566)
	root.add_child(st)
	st.set_items([{"id": "scorch", "value": 6, "tooltip": ""}, {"id": "vuln", "value": 2, "tooltip": ""}, {"id": "weak", "value": 1, "tooltip": ""}])
	var iv := IntentView.new()
	root.add_child(iv)
	iv.set_intent("attack", 12, 1, "Atacará")
	iv.place_above(960, 320)
	var p1 := PileCounter.new("draw")
	p1.position = Vector2(130, 650)
	root.add_child(p1)
	p1.set_count(8)
	var p2 := PileCounter.new("discard")
	p2.position = Vector2(1000, 662)
	root.add_child(p2)
	p2.set_count(2)
	var p3 := PileCounter.new("exhaust")
	p3.position = Vector2(1140, 662)
	root.add_child(p3)
	p3.set_count(0)
	var et := EndTurnButton.new()
	et.position = Vector2(1130, 606)
	root.add_child(et)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "p2_hud.png"))
	# Hoja de iconos ×4 (9×9 → 36 px) y niveles del crisol.
	var kinds: Array = HudArt.INTENTS
	var sts: Array = HudArt.STATUSES
	var sheet := Image.create(11 * 44 + 8, 44 * 2 + 200, false, Image.FORMAT_RGBA8)
	sheet.fill(Palette.color(&"plate", 2))
	for i in kinds.size():
		var im: Image = HudArt.intent_image(kinds[i]).duplicate()
		im.resize(36, 36, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im, Rect2i(0, 0, 36, 36), Vector2i(8 + i * 44, 6))
	for i in sts.size():
		var im2: Image = HudArt.status_image(sts[i]).duplicate()
		im2.resize(36, 36, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im2, Rect2i(0, 0, 36, 36), Vector2i(8 + i * 44, 50))
	for i in 5:
		var c: Image = HudArt.crucible_image(i * 2, i).duplicate()
		c.resize(c.get_width() * 2, c.get_height() * 2, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(c, Rect2i(0, 0, 92, 88), Vector2i(4 + i * 96, 96))
	sheet.save_png(ProjectSettings.globalize_path(OUT + "p2_hud_icons.png"))
	get_tree().quit()
