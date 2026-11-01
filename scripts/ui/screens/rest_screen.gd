extends Screen
## Hoguera: descansar, templar una carta o arrojar una carta al fuego (eliminarla por Ascuas).

var run: RunState


func build() -> void:
	run = Game.run
	var bg := UI.tex_rect(Art.background(EnemyDB.act_index(run.floor_num), run.floor_num + 50, EnemyDB.cycle(run.floor_num)), 4.0)
	bg.modulate = Color(0.6, 0.5, 0.45)
	add_child(bg)
	var fire := UI.fire_emitter(Vector2(90, 10), 90)
	fire.position = Vector2(640, 330)
	fire.scale_amount_max = 10.0
	fire.initial_velocity_max = 160.0
	add_child(fire)
	var logs := UI.icon("log", 10)
	logs.position = Vector2(580, 300)
	add_child(logs)
	var glow := UI.halo(Color("ff8a3a"), 220.0, 0.45)
	glow.position = Vector2(640, 330) - glow.size * 0.5
	add_child(glow)
	var gtw := glow.create_tween().set_loops()
	gtw.tween_property(glow, "modulate:a", 0.3, 0.4)
	gtw.tween_property(glow, "modulate:a", 0.5, 0.3)
	add_child(UI.dust(Rect2(300, 100, 700, 400), Color("ffb070"), 30))
	var pl := UI.tex_rect(Art.player(), 6.0)
	pl.position = Vector2(390, 216)
	add_child(pl)
	var arm := UI.tex_rect(Art.player_arm(), 6.0)
	arm.position = Vector2(12, 13) * 6.0
	arm.pivot_offset = Vector2(3.5, 1.5) * 6.0
	arm.rotation = FighterView.ARM_REST
	pl.add_child(arm)

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
	row.position = Vector2(220, 470)
	row.size = Vector2(840, 120)
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
	var ic := UI.icon(icon_id, 4)
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
