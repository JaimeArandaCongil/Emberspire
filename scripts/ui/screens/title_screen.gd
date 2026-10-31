extends Screen
## Pantalla de título.


func build() -> void:
	var bg := UI.tex_rect(Art.background(0, 7, 0), 4.0)
	bg.modulate = Color(0.5, 0.42, 0.42)
	add_child(bg)
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 6.0
	embers.position = Vector2(640, 740)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(700, 10)
	embers.direction = Vector2.UP
	embers.spread = 15.0
	embers.gravity = Vector2(8, -10)
	embers.initial_velocity_min = 40.0
	embers.initial_velocity_max = 110.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 5.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color("ffe08a"), Color("ff6a1a"), Color(0.76, 0.2, 0.12, 0.0)])
	embers.color_ramp = grad
	embers.preprocess = 4.0
	add_child(embers)

	var hero := UI.tex_rect(Art.player(), 11.0)
	hero.position = Vector2(150, 300)
	add_child(hero)
	var fire := UI.fire_emitter(Vector2(60, 8), 60)
	fire.position = Vector2(1060, 560)
	add_child(fire)
	var furnace := UI.icon("furnace", 14)
	furnace.position = Vector2(976, 430)
	add_child(furnace)

	var title := UI.label("EMBERSPIRE", 96, UI.EMBER)
	title.add_theme_color_override("font_outline_color", Color("5a1a0a"))
	title.add_theme_constant_override("outline_size", 18)
	title.size = Vector2(1280, 120)
	title.position = Vector2(0, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.pivot_offset = Vector2(640, 60)
	add_child(title)
	var tw := title.create_tween().set_loops()
	tw.tween_property(title, "modulate", Color(1.2, 1.0, 0.85), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "modulate", Color(1.0, 0.85, 0.75), 1.4).set_trans(Tween.TRANS_SINE)
	var sub := UI.label("Tu mazo es combustible", 26, UI.TEXT)
	sub.size = Vector2(1280, 40)
	sub.position = Vector2(0, 238)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var v := UI.vbox(14)
	v.position = Vector2(490, 340)
	v.size = Vector2(300, 260)
	add_child(v)
	var has_save := Game.total_embers > 0.0 or Game.runs_started > 0
	var play := UI.button("Continuar" if has_save else "Encender la Forja", func() -> void: main.go("forge"), 24)
	play.custom_minimum_size = Vector2(300, 60)
	v.add_child(play)
	if has_save:
		v.add_child(UI.button("Borrar progreso", func() -> void:
			main.modal("¿Borrar todo?", "Se perderá todo el progreso: Forja, Arsenal, Braseros y Polvo Estelar.",
				[["Borrar", func() -> void:
					Game.reset_all()
					main.go("title")], ["Cancelar", func() -> void: pass]]), 16))
	v.add_child(UI.button("Salir", func() -> void:
		Game.save_game()
		get_tree().quit(), 18))
	if has_save:
		var stats := UI.label("Récord: piso %d   ·   Ascuas históricas: %s   ·   Polvo: %s" % [Game.max_floor, Num.fmt(Game.total_embers), Num.fmt(Game.stardust_total)], 15, UI.DIM)
		stats.size = Vector2(1280, 20)
		stats.position = Vector2(0, 640)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(stats)
	var credit := UI.label("Estudio Brasa · v0.1 · Godot 4.7", 13, Color("6a5a58"))
	credit.position = Vector2(0, 690)
	credit.size = Vector2(1270, 20)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(credit)
