extends Control

func _ready() -> void:
	size = Vector2(1280, 720)
	var bg := ColorRect.new(); bg.color = Color("3a2a2c"); bg.size = size; add_child(bg)
	var f := PixelFont.font()
	var y := 10
	for s in [13, 16, 18, 22, 26, 39, 52]:
		var l := Label.new()
		l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", s)
		l.add_theme_color_override("font_color", Color("ffb43a"))
		l.text = "size %d: Inflige 8 de daño a TODOS, +4 por Calor. ¿Qué? ÁÉÍÓÚ ñ 1234567890 %%" % s
		l.position = Vector2(10, y)
		add_child(l)
		y += s + 30
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/_review_art/out/font_test.png"))
	get_tree().quit()
