extends Screen
## Antesala: preparación antes de ascender. Muestra lo que la Forja aporta a esta ascensión
## (Arsenal, Resonancias), permite firmar Pactos de Brasa y elegir reliquias heredadas del Reliquario.

var _pact_box: VBoxContainer
var _heat_label: RichTextLabel
var _heir_box: VBoxContainer
var _stats: RichTextLabel
var _res_box: VBoxContainer
var _grim_box: HBoxContainer
var _start_floor := 1


func build() -> void:
	var bg := UI.tex_rect(Art.background(0, 404, 0), 4.0)
	bg.modulate = Color(0.5, 0.42, 0.42)
	add_child(bg)
	add_child(UI.dust(Rect2(0, 60, 1280, 660), Color("ffb070"), 22))
	var title := UI.label("Antesala de la Torre", 36, UI.EMBER)
	title.position = Vector2(0, 54)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := UI.label("Lo que forjaste abajo te acompaña arriba.", 16, UI.DIM)
	sub.position = Vector2(0, 98)
	sub.size = Vector2(1280, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	# Saneado de selecciones guardadas.
	var keep: Array[String] = []
	for id in Game.active_pacts:
		if not ForgeDB.pact(id).is_empty():
			keep.append(id)
	Game.active_pacts = keep
	_build_hero()
	_build_pacts()
	_build_heirlooms()
	var cps := Game.checkpoints()
	if cps.size() > 1:
		var cp_row := UI.hbox(6)
		cp_row.position = Vector2(30, 646)
		cp_row.add_child(UI.label("Empezar en:", 14, UI.DIM))
		for f in cps:
			var fl: int = f
			var cb := Button.new()
			cb.toggle_mode = true
			cb.button_pressed = fl == _start_floor
			cb.text = "Piso %d" % fl
			cb.focus_mode = Control.FOCUS_NONE
			cb.add_theme_font_size_override("font_size", 13)
			cb.tooltip_text = "Empieza en el piso %d.\nCompensación: 1 carta a elegir por cada 3 pisos saltados y 1 reliquia de jefe por cada jefe saltado.\nLos pisos saltados no dan Ascuas." % fl if fl > 1 else "Desde el principio."
			cb.add_theme_stylebox_override("pressed", UI.box(Color("5a3a14"), Color("ffd36a"), 2, 0))
			cb.pressed.connect(func() -> void:
				_start_floor = fl
				for other in cp_row.get_children():
					if other is Button:
						(other as Button).button_pressed = (other as Button).text == "Piso %d" % fl
				Sfx.play("click"))
			cp_row.add_child(cb)
		add_child(cp_row)
	var go_btn := UI.button("ASCENDER", _go, 26)
	go_btn.position = Vector2(490, 640)
	go_btn.size = Vector2(300, 60)
	go_btn.add_theme_stylebox_override("normal", UI.box(Color("8a3a1a"), Color("ffb43a"), 4, 5))
	go_btn.add_theme_stylebox_override("hover", UI.box(Color("b04a1a"), Color("ffe08a"), 4, 5))
	add_child(go_btn)
	var back := UI.button("Volver a la Forja", func() -> void: main.go("forge"), 16)
	back.position = Vector2(820, 652)
	back.size = Vector2(190, 40)
	add_child(back)
	_refresh()


func _panel(pos: Vector2, sz: Vector2, title: String, color: Color) -> VBoxContainer:
	var p := UI.panel(Color(0.1, 0.06, 0.07, 0.92), color.darkened(0.3))
	p.position = pos
	p.custom_minimum_size = sz
	p.size = sz
	add_child(p)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.label(title, 20, color))
	return v


func _build_hero() -> void:
	var v := _panel(Vector2(30, 132), Vector2(380, 490), "La Fogonera", UI.EMBER)
	var row := UI.hbox(12)
	v.add_child(row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(110, 160)
	var pl := UI.tex_rect(Art.player(), 5.0)
	holder.add_child(pl)
	var arm := UI.tex_rect(Art.player_arm(), 5.0)
	arm.position = Vector2(12, 13) * 5.0
	arm.pivot_offset = Vector2(3.5, 1.5) * 5.0
	arm.rotation = FighterView.ARM_REST
	pl.add_child(arm)
	var tw := pl.create_tween().set_loops()
	pl.pivot_offset = pl.size * Vector2(0.5, 1.0)
	tw.tween_property(pl, "scale", Vector2(1.02, 0.98), 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pl, "scale", Vector2(0.99, 1.01), 1.0).set_trans(Tween.TRANS_SINE)
	row.add_child(holder)
	_stats = UI.rich("", 15)
	_stats.custom_minimum_size = Vector2(230, 150)
	row.add_child(_stats)
	v.add_child(UI.label("Resonancias (elige versión)", 16, Color("d0a8ff")))
	_res_box = UI.vbox(3)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(356, 230)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(_res_box)
	v.add_child(sc)
	_build_resonances()


func _build_resonances() -> void:
	UI.clear(_res_box)
	var any := false
	for g in ForgeDB.GENERATORS:
		for tier in RelicDB.RESONANCE_TIERS.size():
			if Game.gen_count(g["id"]) < Game.resonance_threshold(tier):
				continue
			any = true
			var key := "%s:%d" % [g["id"], tier]
			var row := UI.hbox(4)
			for variant: String in ["a", "b"]:
				var pid := RelicDB.perk_for(g["id"], tier, variant)
				var d := RelicDB.get_def(pid)
				var b := Button.new()
				b.toggle_mode = true
				b.button_pressed = Game.perk_choices.get(key, "a") == variant
				b.focus_mode = Control.FOCUS_NONE
				b.custom_minimum_size = Vector2(172, 30)
				b.text = d["name"]
				b.add_theme_font_size_override("font_size", 12)
				b.tooltip_text = "%s (%d): %s" % [g["name"], Game.resonance_threshold(tier), d["desc"]]
				b.add_theme_stylebox_override("pressed", UI.box(Color("3a2250"), Color("b07ae0"), 2, 0))
				b.pressed.connect(func() -> void:
					Game.perk_choices[key] = variant
					Sfx.play("click")
					_build_resonances.call_deferred()
					_refresh())
				row.add_child(b)
			_res_box.add_child(row)
	if not any:
		_res_box.add_child(UI.rich("[color=#806860]Ninguna todavía. Ten 10 unidades de un generador para que Resuene.[/color]", 13))


func _build_pacts() -> void:
	var v := _panel(Vector2(430, 132), Vector2(420, 490), "Pactos de Brasa", Color("ff8a4a"))
	if not Game.pacts_unlocked():
		v.add_child(UI.rich("[color=#a08878]Derrota al primer jefe (piso 10) para poder firmar Pactos: dificultad opcional que aumenta las Ascuas que ganas en la Torre.[/color]", 15))
		var lock := UI.icon("key", 8)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lock.modulate = Color(1, 1, 1, 0.3)
		v.add_child(lock)
		return
	v.add_child(UI.rich("[color=#a08878]Cada punto de Calor da [color=#ffd36a]+%d%%[/color] Ascuas en la Torre. Los jefes derrotados con Calor alto cuentan para la Crónica.[/color]" % int(Game.heat_bonus_each() * 100), 13))
	_heat_label = UI.rich("", 17)
	v.add_child(_heat_label)
	_pact_box = UI.vbox(4)
	v.add_child(_pact_box)
	for p in ForgeDB.PACTS:
		var id: String = p["id"]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = Game.active_pacts.has(id)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(396, 44)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("pressed", UI.box(Color("5a2014"), Color("ff8a4a"), 3, 1))
		var h := UI.hbox(8)
		h.position = Vector2(8, 4)
		h.size = Vector2(380, 36)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(UI.icon(p["icon"], 2))
		var l := UI.rich("[color=#ffd36a]%s[/color] [color=#ff8a4a](%d)[/color]\n[color=#a08878]%s[/color]" % [p["name"], p["heat"], p["desc"]], 12)
		l.custom_minimum_size.x = 340
		h.add_child(l)
		b.add_child(h)
		b.toggled.connect(func(on: bool) -> void:
			if on and not Game.active_pacts.has(id):
				Game.active_pacts.append(id)
			elif not on:
				Game.active_pacts.erase(id)
			Sfx.play("burn" if on else "click", 0.1, -6.0)
			_refresh())
		_pact_box.add_child(b)


func _build_heirlooms() -> void:
	_heir_box = _panel(Vector2(870, 132), Vector2(380, 490), "Grimorios y Herencia", UI.EMBER)
	_rebuild_heirlooms()


func _rebuild_heirlooms() -> void:
	while _heir_box.get_child_count() > 1:
		var c := _heir_box.get_child(1)
		_heir_box.remove_child(c)
		c.queue_free()
	_build_grimoire_picks()
	_heir_box.add_child(UI.label("Herencia", 16, UI.EMBER))
	var slots := Game.arsenal_level("heirloom")
	if slots <= 0:
		_heir_box.add_child(UI.rich("[color=#a08878]Mejora [color=#ffd36a]Herencia[/color] en el Arsenal para empezar cada ascensión con reliquias de tu Reliquario.[/color]", 15))
		return
	if Game.relic_codex.is_empty():
		_heir_box.add_child(UI.rich("[color=#a08878]Tu Reliquario está vacío: empezarás con %d reliquia%s al azar.[/color]" % [slots, "" if slots == 1 else "s"], 15))
		return
	# Recorta selecciones inválidas.
	var keep: Array[String] = []
	for id in Game.heirloom_picks:
		if Game.relic_codex.has(id) and keep.size() < slots:
			keep.append(id)
	Game.heirloom_picks = keep
	_heir_box.add_child(UI.rich("[color=#a08878]Elige hasta [color=#ffd36a]%d[/color] (%d elegida%s). Las plazas vacías se rellenan al azar.[/color]" % [slots, keep.size(), "" if keep.size() == 1 else "s"], 13))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(360, 230)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(grid)
	_heir_box.add_child(sc)
	for id: String in RelicDB.RELICS:
		if not Game.relic_codex.has(id):
			continue
		var d := RelicDB.get_def(id)
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = keep.has(id)
		b.custom_minimum_size = Vector2(44, 44)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "%s\n%s" % [d["name"], d["desc"]]
		b.add_theme_stylebox_override("pressed", UI.box(Color("5a3a14"), Color("ffd36a"), 3, 1))
		var ic := UI.icon(d["icon"], 3)
		ic.position = Vector2(4, 4)
		b.add_child(ic)
		b.toggled.connect(func(on: bool) -> void:
			if on and Game.heirloom_picks.size() >= slots:
				Game.heirloom_picks.remove_at(0)
			if on and not Game.heirloom_picks.has(id):
				Game.heirloom_picks.append(id)
			elif not on:
				Game.heirloom_picks.erase(id)
			Sfx.play("click")
			_rebuild_heirlooms.call_deferred())
		grid.add_child(b)


## Grimorios activos: sólo sus cartas salen en las recompensas (arquetipos coherentes).
func _build_grimoire_picks() -> void:
	var learned: Array[String] = []
	for g in ForgeDB.GRIMOIRES:
		if Game.grimoires.has(g["id"]):
			learned.append(g["id"])
	if learned.is_empty():
		_heir_box.add_child(UI.rich("[color=#806860]Aprende Grimorios en la Forja para añadir arquetipos a las recompensas.[/color]", 13))
		return
	var active := Game.active_grimoire_list()
	_heir_box.add_child(UI.rich("[color=#a08878]Activos: [color=#ffd36a]%d / %d[/color]. Las recompensas salen de Base + estos.[/color]" % [active.size(), Game.max_active_grimoires()], 13))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	for gid in learned:
		var g := ForgeDB.grimoire(gid)
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = active.has(gid)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(176, 30)
		b.text = String(g["name"]).replace("Grimorio ", "")
		b.add_theme_font_size_override("font_size", 13)
		b.tooltip_text = g["desc"]
		b.add_theme_stylebox_override("pressed", UI.box(Color("5a3a14"), Color("ffd36a"), 2, 0))
		b.pressed.connect(func() -> void:
			var cur := Game.active_grimoire_list()
			if cur.has(gid):
				cur.erase(gid)
			else:
				cur.append(gid)
				while cur.size() > Game.max_active_grimoires():
					cur.pop_front()
			Game.active_grimoires = cur
			Sfx.play("click")
			_rebuild_heirlooms.call_deferred())
		grid.add_child(b)
	_heir_box.add_child(grid)
	_heir_box.add_child(UI.spacer(6))


func _refresh() -> void:
	var vit := Game.arsenal_level("vitality")
	var hp := int((60 + 6 * vit) * pow(1.04, Game.arsenal_level("skin")))
	var perks := Game.perk_ids()
	if perks.has("res_furnace1"):
		hp += 8
	var energy := 3 + Game.arsenal_level("core") + (1 if perks.has("res_heart2") else 0)
	var burns := 1 + Game.arsenal_level("flue") + (1 if perks.has("res_sun3") else 0)
	var str0 := Game.arsenal_level("arm") + (1 if perks.has("res_furnace3") else 0) + (2 if perks.has("res_heart1") else 0)
	_stats.text = "PV [color=#ff8a7a]%d[/color]\nEnergía [color=#ffd36a]%d[/color] · Robo [color=#ffd36a]%d[/color]\nQuemas/turno [color=#ffd36a]%d[/color]\nFuerza inicial [color=#ffd36a]%d[/color]\nDaño ×[color=#ffd36a]%.2f[/color]\nCartas templadas [color=#ffd36a]%d[/color]\n[color=#806860]Grimorios: %d · Maestrías: %d[/color]" % [
		hp, energy, 5 + Game.arsenal_level("hands"), burns, str0, pow(1.04, Game.arsenal_level("edge")),
		mini(10, Game.arsenal_level("temper")), Game.grimoires.size(), Game.mastered_count(1)]
	if _heat_label != null:
		var heat := Game.pact_heat(Game.active_pacts)
		_heat_label.text = "Calor: [color=#ff8a4a]%d[/color]  →  Ascuas en la Torre ×[color=#ffd36a]%.2f[/color]" % [heat, 1.0 + Game.heat_bonus_each() * heat]


func _go() -> void:
	Game.start_run(-1, _start_floor)
	Sfx.play("door")
	main.shake(6.0)
	main.go("map")
