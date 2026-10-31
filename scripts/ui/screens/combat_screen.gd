extends Screen
## Combate: representa CombatEngine. Clic = jugar · Clic derecho / horno = QUEMAR.

const HAND_Y := 548.0
const FLOOR_Y := 472.0
const PLAYER_SCALE := 7.0

var engine: CombatEngine
var run: RunState
var kind := "combat"
var player_view: FighterView
var enemy_views: Array[FighterView] = []
var card_views := {}           # uid -> CardView
var selected: CardView = null
var busy := false              # bloquea input durante el turno enemigo/animaciones

var _hand_layer: Control
var _fx_layer: Control
var _energy_label: Label
var _burns_label: Label
var _furnace: Control
var _furnace_fire: CPUParticles2D
var _draw_label: Label
var _discard_label: Label
var _end_btn: Button
var _hint: Label
var _turn_banner: Label


func build() -> void:
	run = Game.run
	kind = args.get("kind", "combat")
	var biome := EnemyDB.act_index(run.floor_num)
	var cyc := EnemyDB.cycle(run.floor_num)
	var bg := UI.tex_rect(Art.background(biome, run.floor_num, cyc), 4.0)
	add_child(bg)

	engine = CombatEngine.new()
	var ids: Array = args.get("enemies", EnemyDB.pick_encounter(kind, run.floor_num, run.rng))
	engine.setup(run, ids, run.floor_num, kind)
	engine.event.connect(_on_event)

	# Jugador
	player_view = FighterView.new()
	add_child(player_view)
	player_view.setup(engine.player, engine, Art.player(), PLAYER_SCALE)
	player_view.position = Vector2(150, FLOOR_Y + 50.0 - player_view.size.y)

	# Enemigos
	var n := engine.enemies.size()
	var total_w := 0.0
	for e in engine.enemies:
		var tex := Art.monster(e.shape, e.sprite_seed, e.biome, cyc)
		var sc := 8.0 if e.is_boss else (7.0 if e.is_elite else 6.0)
		var v := FighterView.new()
		add_child(v)
		v.setup(e, engine, tex, sc)
		v.clicked.connect(_on_enemy_clicked)
		enemy_views.append(v)
		total_w += v.size.x
	var gap := 20.0
	var x := 1180.0 - total_w - gap * (n - 1)
	x = maxf(x, 560.0)
	for v in enemy_views:
		v.position = Vector2(x, FLOOR_Y + 50.0 - v.size.y)
		x += v.size.x + gap

	var top := UI.label("Piso %d · %s" % [run.floor_num, EnemyDB.act_name(run.floor_num)], 18, UI.DIM)
	top.position = Vector2(0, 56)
	top.size = Vector2(1280, 24)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(top)
	_build_relic_bar()

	_build_controls()
	_hand_layer = Control.new()
	_hand_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hand_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_layer)
	_fx_layer = Control.new()
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)

	_turn_banner = UI.label("", 44, UI.EMBER)
	_turn_banner.size = Vector2(1280, 60)
	_turn_banner.position = Vector2(0, 250)
	_turn_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_banner.modulate.a = 0.0
	add_child(_turn_banner)

	if kind == "boss":
		Sfx.play("heavy")
		main.shake(10.0)
	engine.start()
	_relayout(true)


func _build_relic_bar() -> void:
	var row := UI.hbox(4)
	row.position = Vector2(12, 56)
	add_child(row)
	for id in run.relics:
		var d := RelicDB.get_def(id)
		var ic := UI.icon(d["icon"], 2)
		ic.mouse_filter = Control.MOUSE_FILTER_PASS
		ic.tooltip_text = "%s\n%s" % [d["name"], d["desc"]]
		row.add_child(ic)


func _build_controls() -> void:
	# Orbe de energía
	var orb := Panel.new()
	orb.position = Vector2(26, 552)
	orb.size = Vector2(84, 84)
	orb.add_theme_stylebox_override("panel", UI.box(Color("8a3a1a"), Color("ffe08a"), 4, 4))
	orb.tooltip_text = "Energía: se gasta al jugar cartas."
	add_child(orb)
	_energy_label = UI.label("3/3", 28, Color("ffe08a"))
	_energy_label.size = orb.size
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(_energy_label)

	# Horno (quemar)
	_furnace = Control.new()
	_furnace.position = Vector2(14, 330)
	_furnace.size = Vector2(96, 140)
	_furnace.mouse_filter = Control.MOUSE_FILTER_STOP
	_furnace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_furnace.tooltip_text = "EL HORNO\nClic derecho en una carta (o selecciónala y pulsa aquí) para QUEMARLA:\nla pierdes este combate, ganas Ascuas permanentes y activas su efecto 'Al quemar'."
	add_child(_furnace)
	var fic := UI.icon("furnace", 8)
	fic.position = Vector2(0, 30)
	_furnace.add_child(fic)
	_furnace_fire = UI.fire_emitter(Vector2(30, 6), 26)
	_furnace_fire.position = Vector2(48, 80)
	_furnace.add_child(_furnace_fire)
	_burns_label = UI.label("", 16, UI.EMBER)
	_burns_label.position = Vector2(-10, 0)
	_burns_label.size = Vector2(116, 24)
	_burns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_furnace.add_child(_burns_label)
	_furnace.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and selected != null:
			_try_burn(selected))

	# Pilas
	_draw_label = UI.label("", 14, UI.DIM)
	_draw_label.position = Vector2(14, 650)
	_draw_label.size = Vector2(120, 60)
	_draw_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_draw_label.tooltip_text = "Mazo de robo / Exiliadas"
	add_child(_draw_label)
	_discard_label = UI.label("", 14, UI.DIM)
	_discard_label.position = Vector2(1150, 680)
	_discard_label.size = Vector2(120, 30)
	_discard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_discard_label)

	_end_btn = UI.button("Fin de turno", _end_turn, 20)
	_end_btn.position = Vector2(1110, 610)
	_end_btn.size = Vector2(150, 56)
	add_child(_end_btn)

	_hint = UI.label("Clic: jugar   ·   Clic derecho: QUEMAR   ·   Espacio / E: fin de turno", 13, UI.DIM)
	_hint.position = Vector2(0, 84)
	_hint.size = Vector2(1280, 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)


# --- Mano -----------------------------------------------------------------

func _add_card_view(c: Card) -> void:
	var cv := CardView.new(c, engine)
	cv.position = Vector2(40, 660)
	cv.scale = Vector2(0.3, 0.3)
	cv.clicked.connect(_on_card_clicked)
	cv.hover_changed.connect(_on_card_hover)
	_hand_layer.add_child(cv)
	card_views[c.uid] = cv


func _relayout(instant: bool = false) -> void:
	var n := engine.hand.size()
	var spacing := minf(124.0, 690.0 / maxf(1.0, n))
	var cx := 640.0
	for i in n:
		var c: Card = engine.hand[i]
		var cv: CardView = card_views.get(c.uid)
		if cv == null:
			continue
		var off := i - (n - 1) * 0.5
		var target := Vector2(cx + off * spacing - CardView.SIZE.x * 0.5, HAND_Y + absf(off) * absf(off) * 3.0)
		var rot := deg_to_rad(off * 3.5)
		if cv.hovering and not busy:
			target.y = HAND_Y - 72.0
			rot = 0.0
		if cv == selected:
			target.y = HAND_Y - 92.0
			rot = 0.0
		cv.home_pos = target
		cv.home_rot = rot
		cv.z_index = 50 if (cv.hovering or cv == selected) else i
		cv.refresh()
		var sc := Vector2.ONE * (1.12 if cv.hovering or cv == selected else 1.0)
		if instant:
			cv.position = target
			cv.rotation = rot
			cv.scale = sc
		else:
			var tw := cv.create_tween().set_parallel()
			tw.tween_property(cv, "position", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(cv, "rotation", rot, 0.16)
			tw.tween_property(cv, "scale", sc, 0.12)
	_refresh_labels()


func _refresh_labels() -> void:
	_energy_label.text = "%d/%d" % [engine.energy, run.max_energy]
	_burns_label.text = "Quemas: %d" % engine.burns_left
	_burns_label.add_theme_color_override("font_color", UI.EMBER if engine.burns_left > 0 else UI.DIM)
	_furnace_fire.emitting = engine.burns_left > 0
	var pc := engine.pile_counts()
	_draw_label.text = "Robo: %d\nExilio: %d" % [pc["draw"], pc["exhaust"]]
	_discard_label.text = "Descarte: %d" % pc["discard"]
	_end_btn.disabled = busy or engine.over
	for v in enemy_views:
		v.targetable = selected != null and selected.card.needs_target() and v.fighter.alive()


func _on_card_hover(_cv: CardView, _h: bool) -> void:
	if not busy:
		_relayout()


func _on_card_clicked(cv: CardView, button: int) -> void:
	if busy or engine.over:
		return
	if button == MOUSE_BUTTON_RIGHT:
		_try_burn(cv)
		return
	var c := cv.card
	if not engine.can_play(c):
		Sfx.play("deny")
		if not c.is_playable():
			main.toast("Combustible: sólo puede QUEMARSE (clic derecho)", UI.EMBER)
		else:
			main.toast("No tienes energía suficiente", UI.RED)
		UI.punch(cv, 0.05)
		return
	if c.needs_target() and engine.living_enemies().size() > 1:
		if selected == cv:
			_set_selected(null)
		else:
			_set_selected(cv)
			Sfx.play("hover")
			main.toast("Elige un objetivo", UI.EMBER)
		return
	_play(cv, null)


func _set_selected(cv: CardView) -> void:
	if selected != null and is_instance_valid(selected):
		selected.selected = false
	selected = cv
	if cv != null:
		cv.selected = true
	_relayout()


func _on_enemy_clicked(v: FighterView) -> void:
	if busy or selected == null or not v.fighter.alive():
		return
	var cv := selected
	_set_selected(null)
	_play(cv, v.fighter)


func _play(cv: CardView, target: Fighter) -> void:
	var c := cv.card
	if c.type() == "attack":
		player_view.lunge(1.0)
	engine.play_card(c, target)
	_after_action()


func _try_burn(cv: CardView) -> void:
	if busy or engine.over:
		return
	if not engine.can_burn(cv.card):
		Sfx.play("deny")
		main.toast("El horno necesita respirar: no te quedan Quemas este turno", UI.DIM)
		return
	if selected == cv:
		_set_selected(null)
	engine.burn_card(cv.card)
	_after_action()


func _after_action() -> void:
	_relayout()
	if engine.over:
		_finish()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_SPACE or k == KEY_E:
			_end_turn()
		elif k == KEY_ESCAPE:
			_set_selected(null)
	elif ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_set_selected(null)


# --- Turno enemigo --------------------------------------------------------

func _end_turn() -> void:
	if busy or engine.over:
		return
	busy = true
	_set_selected(null)
	engine.end_player_turn()
	_relayout()
	await get_tree().create_timer(0.35).timeout
	engine.begin_enemy_phase()
	for v in enemy_views:
		v.refresh()
	if engine.over:
		_finish()
		return
	await get_tree().create_timer(0.25).timeout
	for v in enemy_views:
		if engine.over:
			break
		if not v.fighter.alive():
			continue
		var is_atk := String(v.fighter.intent.get("kind", "")).begins_with("attack")
		if is_atk:
			v.lunge(-1.0)
			await get_tree().create_timer(0.08).timeout
		engine.enemy_act(v.fighter)
		v.refresh()
		player_view.refresh()
		await get_tree().create_timer(0.45).timeout
	if engine.over:
		_finish()
		return
	engine.end_enemy_phase()
	busy = false
	if engine.over:
		_finish()
		return
	_relayout()


func _banner(text: String, color: Color = UI.EMBER) -> void:
	_turn_banner.text = text
	_turn_banner.add_theme_color_override("font_color", color)
	_turn_banner.modulate.a = 0.0
	_turn_banner.scale = Vector2(1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(_turn_banner, "modulate:a", 1.0, 0.12)
	tw.tween_interval(0.5)
	tw.tween_property(_turn_banner, "modulate:a", 0.0, 0.3)


# --- Eventos del motor ----------------------------------------------------

func _view_for(f: Fighter) -> FighterView:
	if f == null:
		return null
	if f.is_player:
		return player_view
	for v in enemy_views:
		if v.fighter == f:
			return v
	return null


func _on_event(k: String, d: Dictionary) -> void:
	match k:
		"draw":
			_add_card_view(d["card"])
			Sfx.play("card", 0.15, -8.0)
		"discard", "exhaust":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			if cv != null:
				card_views.erase(c.uid)
				var dest := Vector2(1200, 700) if k == "discard" else Vector2(60, 700)
				var tw := cv.create_tween().set_parallel()
				tw.tween_property(cv, "position", dest, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.tween_property(cv, "scale", Vector2(0.2, 0.2), 0.25)
				tw.tween_property(cv, "modulate:a", 0.0, 0.25)
				tw.chain().tween_callback(cv.queue_free)
		"card_played":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			Sfx.play("card")
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				cv.z_index = 80
				var tw := cv.create_tween()
				tw.tween_property(cv, "position", Vector2(640 - CardView.SIZE.x * 0.5, 250), 0.12).set_trans(Tween.TRANS_QUAD)
				tw.parallel().tween_property(cv, "rotation", 0.0, 0.12)
				tw.tween_interval(0.08)
				var dest := Vector2(1200, 700)
				if c.type() == "power":
					dest = player_view.center()
				tw.tween_property(cv, "position", dest, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(cv, "scale", Vector2(0.15, 0.15), 0.22)
				tw.parallel().tween_property(cv, "modulate:a", 0.0, 0.22)
				tw.tween_callback(cv.queue_free)
				if c.type() == "power":
					Sfx.play("buff")
					UI.sparks(_fx_layer, player_view.center(), Color("ffd36a"), 30)
		"card_burned":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			Sfx.play("burn")
			var fpos := _furnace.global_position + Vector2(48, 70)
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				cv.z_index = 80
				var tw := cv.create_tween()
				tw.tween_property(cv, "modulate", Color(2.0, 1.1, 0.4), 0.1)
				tw.tween_property(cv, "position", fpos - CardView.SIZE * 0.5, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(cv, "scale", Vector2(0.1, 0.1), 0.25)
				tw.parallel().tween_property(cv, "rotation", 1.5, 0.25)
				tw.tween_callback(cv.queue_free)
			var ember_amt: float = d["embers"]
			var timer := get_tree().create_timer(0.3)
			timer.timeout.connect(func() -> void:
				UI.sparks(_fx_layer, fpos, UI.FIRE, 40, 70.0)
				UI.float_text(_fx_layer, fpos + Vector2(40, -60), "+%s" % Num.fmt(ember_amt), UI.EMBER, 26)
				main.fly_embers(fpos, 5)
				main.shake(4.0))
		"damage":
			var v := _view_for(d["target"])
			if v == null:
				return
			var amt: int = d["amount"]
			var blocked: int = d["blocked"]
			var pos := v.center() - global_position
			if amt > 0:
				v.flash(Color.WHITE)
				v.shake(6.0 + minf(amt, 30.0) * 0.4)
				UI.float_text(_fx_layer, pos, str(amt), Color("ff5a4a") if v.fighter.is_player else Color.WHITE, 30 + mini(amt, 40) / 2)
				UI.sparks(_fx_layer, pos, Color("ff3a2a") if v.fighter.is_player else UI.FIRE, 10 + mini(amt, 30))
				Sfx.play("heavy" if amt >= 15 else "hit")
				main.shake(3.0 + minf(amt, 40.0) * 0.25)
				if amt >= 15:
					_hitstop(0.06)
			elif blocked > 0:
				UI.float_text(_fx_layer, pos, "Bloqueado", UI.BLUE, 22)
				Sfx.play("block")
			v.refresh()
		"block":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, v.center() - global_position + Vector2(0, 30), "+%d" % d["amount"], UI.BLUE, 22)
				Sfx.play("block", 0.05, -4.0)
		"status":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				var amt: int = d["amount"]
				var id: String = d["id"]
				if amt > 0 and id != "":
					var good := id == "str"
					UI.float_text(_fx_layer, v.center() - global_position + Vector2(0, -40), "%s +%d" % [FighterView.STATUS_NAMES.get(id, id), amt],
						UI.GREEN if good else (UI.FIRE if id == "scorch" else UI.PURPLE), 20)
					Sfx.play("buff" if good else "debuff", 0.05, -4.0)
		"heal":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, v.center() - global_position, "+%d" % d["amount"], UI.GREEN, 26)
				Sfx.play("heal")
		"power":
			player_view.refresh()
		"intent":
			var v := _view_for(d["fighter"])
			if v != null:
				v.refresh()
		"energy", "burns", "shuffle":
			if is_inside_tree() and _energy_label != null:
				_refresh_labels()
		"card_added":
			var src := _view_for(d["source"])
			if src != null:
				UI.float_text(_fx_layer, src.center() - global_position + Vector2(0, -60), "+%s" % (d["card"] as Card).title(), UI.DIM, 18)
		"turn_start":
			for v in enemy_views:
				v.refresh()
			player_view.refresh()
			if engine.turn > 1:
				_banner("Tu turno")
				Sfx.play("turn")
		"enemy_died":
			var v := _view_for(d["target"])
			if v != null:
				v.die()
				var pos := v.center() - global_position
				Sfx.play("death")
				UI.sparks(_fx_layer, pos, UI.FIRE, 50)
				UI.float_text(_fx_layer, pos + Vector2(0, -50), "+%s" % Num.fmt(d["embers"]), UI.EMBER, 24)
				main.fly_embers(v.center(), 8)
				_hitstop(0.08)
		"revive":
			player_view.refresh()
			_banner("¡FÉNIX!", UI.EMBER)
			UI.sparks(_fx_layer, player_view.center() - global_position, UI.EMBER, 80)
			Sfx.play("rebirth")


func _hitstop(dur: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# --- Fin del combate ------------------------------------------------------

func _finish() -> void:
	if not busy:
		busy = true
	_end_btn.disabled = true
	await get_tree().create_timer(0.9).timeout
	if engine.won:
		_victory()
	else:
		Sfx.play("defeat")
		_banner("DERROTA", UI.RED)
		await get_tree().create_timer(1.2).timeout
		main.go("summary", {"died": true})


func _victory() -> void:
	Sfx.play("victory")
	for cv: CardView in card_views.values():
		cv.queue_free()
	card_views.clear()
	var wave := Game.gain_tower_embers(Game.victory_wave(kind), "wave")
	main.fly_embers(Vector2(640, 300), 14)
	var total := engine.embers_this_combat + wave
	var relic := ""
	if kind == "elite" or kind == "boss":
		relic = RelicDB.random_unowned(run.relics, run.rng)
		run.add_relic(relic)
	if kind == "boss":
		run.heal(run.max_hp)
	var rewards := run.roll_card_rewards(Game.card_packs(), 3, kind != "combat")
	_show_rewards(total, wave, relic, rewards)


func _show_rewards(total: float, wave: float, relic: String, rewards: Array[Card]) -> void:
	var root := Control.new()
	root.size = Vector2(1280, 720)
	root.z_index = 150
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.82)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	add_child(root)
	var v := UI.vbox(12)
	v.position = Vector2(140, 100)
	v.size = Vector2(1000, 560)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(v)
	var title := UI.label("¡JEFE DERROTADO!" if kind == "boss" else "VICTORIA", 48, UI.EMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UI.rich("[center]Ascuas de este combate: [color=#ffd36a]%s[/color]   (oleada de la Forja: %s)[/center]" % [Num.fmt(total), Num.fmt(wave)], 18)
	v.add_child(sub)
	if relic != "":
		var rd := RelicDB.get_def(relic)
		var rr := UI.hbox(10)
		rr.alignment = BoxContainer.ALIGNMENT_CENTER
		rr.add_child(UI.icon(rd["icon"], 4))
		rr.add_child(UI.rich("[color=#ffd36a]Reliquia: %s[/color]\n%s" % [rd["name"], rd["desc"]], 17))
		(rr.get_child(1) as Control).custom_minimum_size.x = 380
		v.add_child(rr)
	if kind == "boss":
		v.add_child(_center_label("Las llamas del acto te restauran por completo.", UI.GREEN))
	v.add_child(_center_label("Elige una carta para tu mazo", UI.TEXT))
	var row := UI.hbox(40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 240
	v.add_child(row)
	var skip_value := Game.burn_value(1, 2, run.floor_num)
	for c in rewards:
		var holder := Control.new()
		holder.custom_minimum_size = CardView.SIZE + Vector2(0, 20)
		var cv := CardView.new(c)
		cv.position = Vector2(0, 10)
		holder.add_child(cv)
		row.add_child(holder)
		cv.hover_changed.connect(func(view: CardView, h: bool) -> void:
			view.create_tween().tween_property(view, "scale", Vector2.ONE * (1.08 if h else 1.0), 0.08))
		cv.clicked.connect(func(_view: CardView, _b: int) -> void:
			run.deck.append(c)
			Sfx.play("buy")
			_leave())
	var skip := UI.button("Quemar las ofrendas (+%s Ascuas)" % Num.fmt(skip_value), func() -> void:
		Game.gain_tower_embers(skip_value, "skip")
		main.fly_embers(Vector2(640, 600), 6)
		_leave(), 18)
	skip.custom_minimum_size = Vector2(360, 48)
	var srow := UI.hbox()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_child(skip)
	v.add_child(srow)
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.3)


func _center_label(text: String, color: Color) -> Label:
	var l := UI.label(text, 20, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _leave() -> void:
	main.go("map")
