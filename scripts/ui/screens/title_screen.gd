extends Screen
## Pantalla de título.


func build() -> void:
	var bg := UI.tex_rect(Art.background(0, 7, 0), UI.PX)
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
	embers.scale_amount_min = float(UI.PX)
	embers.scale_amount_max = float(UI.PX)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color("ffe08a"), Color("ff6a1a"), Color(0.76, 0.2, 0.12, 0.0)])
	embers.color_ramp = grad
	embers.preprocess = 4.0
	add_child(embers)

	# Forja y heroína en la rejilla del mundo (×4), sobre el suelo del fondo.
	var furnace := UI.tex_rect(Art.forge_sprite(0.75), UI.PX)
	furnace.position = Vector2(880, 476 - 224)
	add_child(furnace)
	var halo := UI.halo(Color("ff7a2a"), 220.0, 0.4)
	halo.position = Vector2(992, 412) - halo.size * 0.5
	add_child(halo)
	var fire := UI.fire_emitter(Vector2(40, 8), 30)
	fire.position = Vector2(992, 420)
	add_child(fire)
	var frame := [0]
	var ftw := furnace.create_tween().set_loops()
	ftw.tween_interval(0.14)
	ftw.tween_callback(func() -> void:
		frame[0] = (frame[0] + 1) % 4
		furnace.texture = Art.forge_sprite(0.75, frame[0]))
	var hero := UI.tex_rect(Art.player_pose("idle"), UI.PX)
	hero.position = Vector2(152, 476 - hero.size.y)
	add_child(hero)
	var htw := hero.create_tween().set_loops()
	htw.tween_interval(0.7)
	htw.tween_callback(func() -> void: hero.texture = Art.player_pose("idle_b"))
	htw.tween_interval(0.7)
	htw.tween_callback(func() -> void: hero.texture = Art.player_pose("idle"))

	# Logotipo dibujado (×6, rejilla de interfaz) con un pulso de luz en 3 pasos.
	var logo_tex := Art.logo()
	var title := UI.tex_rect(logo_tex, 6.0)
	title.position = Vector2(roundf((1280 - title.size.x) / 4.0) * 2.0, 96)
	add_child(title)
	var tw := title.create_tween().set_loops()
	for m: Color in [Color(1.1, 1.0, 0.9), Color(1.2, 1.05, 0.9), Color(1.1, 1.0, 0.9), Color.WHITE]:
		tw.tween_callback(func() -> void: title.modulate = m)
		tw.tween_interval(0.35)
	var sub := UI.plabel("Tu mazo es combustible", 2, UI.TEXT)
	sub.size = Vector2(1280, 30)
	sub.position = Vector2(0, 232)
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
	var credit := UI.label("Estudio Brasa · v0.2 · Godot 4.7", 13, Color("6a5a58"))
	credit.position = Vector2(0, 690)
	credit.size = Vector2(1270, 20)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(credit)
