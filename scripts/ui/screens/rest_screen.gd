extends Screen
## Hoguera: descansar, templar una carta o arrojar una carta al fuego (eliminarla por Ascuas).

var run: RunState


func build() -> void:
	run = Game.run
	var bg := UI.tex_rect(Art.background(EnemyDB.act_index(run.floor_num), run.floor_num + 50, EnemyDB.cycle(run.floor_num)), UI.PX)
	bg.modulate = Color(0.6, 0.5, 0.45)
	add_child(bg)
	# Hoguera dibujada (32×24 ×4) sobre el suelo, con 4 fotogramas de llama.
	var glow := UI.halo(Color("ff8a3a"), 240.0, 0.45)
	glow.position = Vector2(704, 420) - glow.size * 0.5
	add_child(glow)
	var gtw := glow.create_tween().set_loops()
	gtw.tween_property(glow, "modulate:a", 0.3, 0.4)
	gtw.tween_property(glow, "modulate:a", 0.5, 0.3)
	add_child(UI.dust(Rect2(300, 100, 700, 400), Color("ffb070"), 30))
	var fire_img := UI.tex_rect(Art.bonfire(0), UI.PX)
	fire_img.position = Vector2(640, 476 - fire_img.size.y)
	add_child(fire_img)
	var fr := [0]
	var frt := fire_img.create_tween().set_loops()
	frt.tween_interval(0.12)
	frt.tween_callback(func() -> void:
		fr[0] = (fr[0] + 1) % 4
		fire_img.texture = Art.bonfire(fr[0]))
	var sparks := UI.fire_emitter(Vector2(40, 8), 14)
	sparks.position = Vector2(704, 400)
	sparks.initial_velocity_max = 120.0
	add_child(sparks)
	var pl := UI.tex_rect(Art.player_pose("idle"), UI.PX)
	pl.position = Vector2(400, 476 - pl.size.y)
	add_child(pl)
	var ptw := pl.create_tween().set_loops()
	ptw.tween_interval(0.8)
	ptw.tween_callback(func() -> void: pl.texture = Art.player_pose("idle_b"))
	ptw.tween_interval(0.8)
	ptw.tween_callback(func() -> void: pl.texture = Art.player_pose("idle"))

	var title := UI.label("Hoguera", 44, UI.EMBER)
	title.position = Vector2(0, 70)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := UI.label("PV %d / %d" % [run.hp, run.max_hp], 20, Color("ff8a7a"))
	sub.position = Vector2(0, 122)
	sub.size = Vector2(1280, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var heal_pct := 30 + 10 * Game.arsenal_level("hearth")
	var heal_amt := int(ceil(run.max_hp * heal_pct / 100.0))
	if run.has_pact("pact_rest"):
		heal_amt = int(heal_amt / 2)
	if run.has_relic("healing_salve"):
		heal_amt += 10
	var row := UI.hbox(28)
	row.position = Vector2(80, 470)
	row.size = Vector2(1120, 120)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	row.add_child(_option("Descansar", "Cura %d PV (%d%%)." % [heal_amt, heal_pct], "heart", func() -> void:
		run.heal(heal_amt)
		Sfx.play("heal")
		main.go("map")))
	row.add_child(_option("Templar", "Mejora una carta de tu mazo.", "anvil", func() -> void:
		var ups: Array = run.deck.filter(func(c: Card) -> bool: return c.can_upgrade())
		main.pick_card("Elige una carta para templar", ups, func(c: Variant) -> void:
			if c == null:
				return
			(c as Card).upgraded = true
			Sfx.play("buy")
			main.go("map"), true, true)))
	if run.pot > 0.0:
		row.add_child(_option("Enviar las Brasas", "Cobra el bote de Brasas Vivas:\n+%s Ascuas.\nLa racha vuelve a 0." % Num.fmt(run.pot), "ember", func() -> void:
			var v := Game.cash_pot()
			Sfx.play("coin")
			main.fly_embers(Vector2(640, 330), 14)
			main.toast("Brasas Vivas cobradas: +%s" % Num.fmt(v), UI.EMBER)
			main.go("map")))
	var burn_value := Game.burn_value(2, 3, run.floor_num)
	row.add_child(_option("Ofrenda", "Arroja una carta al fuego para siempre.\n+%s Ascuas." % Num.fmt(burn_value), "flame", func() -> void:
		main.pick_card("Elige una carta para quemar para siempre", run.deck, func(c: Variant) -> void:
			if c == null:
				return
			run.deck.erase(c)
			Game.gain_tower_embers(burn_value, "offering")
			Sfx.play("burn")
			main.fly_embers(Vector2(640, 330), 10)
			main.go("map"), true)))


func _option(title: String, desc: String, icon_id: String, cb: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(250, 170)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var v := UI.vbox(6)
	v.position = Vector2(10, 10)
	v.size = Vector2(230, 150)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var ic := UI.tex_rect(Art.icon_big(icon_id), UI.UI_PX)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var t := UI.label(title, 22, UI.EMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d := UI.rich("[center]%s[/center]" % desc, 14)
	v.add_child(d)
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		cb.call())
	return b
