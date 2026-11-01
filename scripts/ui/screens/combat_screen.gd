extends Screen
## Combate: representa CombatEngine. Clic = jugar · Clic derecho / horno = QUEMAR.

const HAND_Y := 548.0
const FLOOR_Y := 472.0
const PLAYER_SCALE := 6.0
const DRAW_POS := Vector2(40, 650)
const DISCARD_POS := Vector2(1200, 690)

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.32, 0.75, length(d * vec2(1.2, 1.0)));
	COLOR = vec4(0.75, 0.05, 0.02, v * amount);
}
"""

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
var _heat_label: Label
var _furnace: Control
var _furnace_img: TextureRect
var _furnace_fire: CPUParticles2D
var _furnace_halo: TextureRect
var _draw_label: Label
var _discard_label: Label
var _end_btn: Button
var _hint: Label
var _turn_banner: Label
var _banner_bg: ColorRect
var _vignette: ColorRect
var _vig_mat: ShaderMaterial
var _cyc := 0
var _t := 0.0


func build() -> void:
	run = Game.run
	kind = args.get("kind", "combat")
	var biome := EnemyDB.act_index(run.floor_num)
	_cyc = EnemyDB.cycle(run.floor_num)
	var bg := UI.tex_rect(Art.background(biome, run.floor_num, _cyc), 4.0)
	add_child(bg)
	_build_ambience(biome)

	engine = CombatEngine.new()
	var ids: Array = args.get("enemies", EnemyDB.pick_encounter(kind, run.floor_num, run.rng))
	engine.setup(run, ids, run.floor_num, kind)
	engine.event.connect(_on_event)

	# Jugador
	player_view = FighterView.new()
	add_child(player_view)
	player_view.setup(engine.player, engine, Art.player(), PLAYER_SCALE)
	player_view.position = Vector2(140, FLOOR_Y + 50.0 - player_view.size.y)

	# Enemigos
	for e in engine.enemies:
		_add_enemy_view(e)
	_layout_enemies(false)

	var top := UI.label("Piso %d · %s" % [run.floor_num, EnemyDB.act_name(run.floor_num)], 18, UI.DIM)
	top.position = Vector2(0, 56)
	top.size = Vector2(1280, 24)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(top)
	if run.heat() > 0:
		var hl := UI.label("Calor de Pacto %d · +%d%% Ascuas" % [run.heat(), int(Game.heat_bonus_each() * 100 * run.heat())], 13, Color("ff8a4a"))
		hl.position = Vector2(0, 100)
		hl.size = Vector2(1280, 18)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(hl)
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

	_vignette = ColorRect.new()
	_vignette.size = Vector2(1280, 720)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vig_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	_vig_mat.shader = sh
	_vignette.material = _vig_mat
	add_child(_vignette)

	_banner_bg = ColorRect.new()
	_banner_bg.color = Color(0.05, 0.02, 0.03, 0.75)
	_banner_bg.size = Vector2(1280, 70)
	_banner_bg.position = Vector2(0, 245)
	_banner_bg.modulate.a = 0.0
	_banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner_bg)
	_turn_banner = UI.label("", 44, UI.EMBER)
	_turn_banner.size = Vector2(1280, 60)
	_turn_banner.position = Vector2(0, 250)
	_turn_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_banner.modulate.a = 0.0
	add_child(_turn_banner)

	engine.start()
	_relayout(true)
	if kind == "boss":
		Sfx.play("heavy")
		main.shake(10.0)
		_banner(engine.enemies[0].display_name, UI.EMBER)
	elif kind == "elite":
		_banner("Élite", Color("ff8a6a"))


func _build_ambience(biome: int) -> void:
	var glow_col: Color = Art.biome_colors(biome, _cyc)["glow"]
	for tp: Vector2i in Art.TORCHES:
		var pos := Vector2(tp.x * 4 + 2, tp.y * 4 - 4)
		var h := UI.halo(Color("ff8a3a"), 90.0, 0.35)
		h.position = pos - h.size * 0.5
		add_child(h)
		var tw := h.create_tween().set_loops()
		tw.tween_property(h, "modulate:a", 0.22, 0.25 + randf() * 0.2)
		tw.tween_property(h, "modulate:a", 0.38, 0.25 + randf() * 0.2)
		var f := UI.fire_emitter(Vector2(10, 4), 16)
		f.position = pos
		f.scale_amount_max = 6.0
		f.lifetime = 0.6
		add_child(f)
	for wx: int in [64, 256]:
		var wh := UI.halo(glow_col, 110.0, 0.18)
		wh.position = Vector2(wx * 4, 230) - wh.size * 0.5
		add_child(wh)
	var dust_col := Color("ffb070") if biome != 2 else Color("e0f4ff")
	add_child(UI.dust(Rect2(0, 80, 1280, 420), dust_col, 26))


func _add_enemy_view(e: Fighter) -> FighterView:
	var tex := Art.monster(e.shape, e.sprite_seed, e.biome, _cyc)
	var gtex := Art.monster_glow(e.shape, e.sprite_seed, e.biome, _cyc)
	var sc := 8.0 if e.is_boss else (7.0 if e.is_elite else 6.0)
	if e.shape == "mite":
		sc = 5.0
	var v := FighterView.new()
	add_child(v)
	v.setup(e, engine, tex, sc, gtex)
	v.clicked.connect(_on_enemy_clicked)
	enemy_views.append(v)
	return v


func _layout_enemies(animate: bool) -> void:
	var alive: Array[FighterView] = []
	for v in enemy_views:
		if v.fighter.alive():
			alive.append(v)
	var total_w := 0.0
	for v in alive:
		total_w += v.size.x
	var gap := 14.0
	var n := alive.size()
	var x := 1200.0 - total_w - gap * maxf(0, n - 1)
	x = maxf(x, 470.0)
	var step_scale := 1.0
	if 1200.0 - 470.0 < total_w + gap * (n - 1):
		step_scale = (1200.0 - 470.0) / (total_w + gap * (n - 1))
	for v in alive:
		var target := Vector2(x, FLOOR_Y + 50.0 - v.size.y)
		if animate:
			v.create_tween().tween_property(v, "position", target, 0.3).set_trans(Tween.TRANS_QUAD)
		else:
			v.position = target
		x += (v.size.x + gap) * step_scale


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
	if not run.perks.is_empty():
		row.add_child(UI.spacer(0, 8))
		for id in run.perks:
			var d2 := RelicDB.get_def(id)
			var holder := PanelContainer.new()
			holder.add_theme_stylebox_override("panel", UI.box(Color("2a1a30"), Color("8a5ad0"), 1, 0))
			holder.mouse_filter = Control.MOUSE_FILTER_PASS
			holder.tooltip_text = "Resonancia: %s\n%s" % [d2["name"], d2["desc"]]
			holder.add_child(UI.icon(d2["icon"], 2))
			row.add_child(holder)


func _build_controls() -> void:
	# Orbe de energía
	var orb := TextureRect.new()
	orb.texture = Art.cost_orb(true, false)
	orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb.stretch_mode = TextureRect.STRETCH_SCALE
	orb.position = Vector2(24, 548)
	orb.size = Vector2(88, 88)
	orb.tooltip_text = "Energía: se gasta al jugar cartas."
	orb.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(orb)
	_energy_label = UI.label("3/3", 28, Color("fff4c8"))
	_energy_label.size = orb.size
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(_energy_label)

	# Horno (quemar)
	_furnace = Control.new()
	_furnace.position = Vector2(6, 318)
	_furnace.size = Vector2(120, 150)
	_furnace.mouse_filter = Control.MOUSE_FILTER_STOP
	_furnace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_furnace.tooltip_text = "EL HORNO\nClic derecho en una carta (o selecciónala y pulsa aquí) para QUEMARLA:\nla pierdes este combate, ganas Ascuas permanentes, activas su efecto 'Al quemar'\ny la carta gana Maestría para siempre.\n\nCALOR: cartas quemadas en este combate."
	add_child(_furnace)
	_furnace_halo = UI.halo(Color("ff7a2a"), 80.0, 0.4)
	_furnace_halo.position = Vector2(60, 100) - _furnace_halo.size * 0.5
	_furnace.add_child(_furnace_halo)
	_furnace_img = UI.tex_rect(Art.forge_sprite(0.5), 2.5)
	_furnace_img.position = Vector2(0, 50)
	_furnace_img.pivot_offset = _furnace_img.size * Vector2(0.5, 1.0)
	_furnace.add_child(_furnace_img)
	_furnace_fire = UI.fire_emitter(Vector2(34, 6), 26)
	_furnace_fire.position = Vector2(60, 118)
	_furnace.add_child(_furnace_fire)
	_burns_label = UI.label("", 16, UI.EMBER)
	_burns_label.position = Vector2(-10, 0)
	_burns_label.size = Vector2(140, 22)
	_burns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_furnace.add_child(_burns_label)
	_heat_label = UI.label("", 14, Color("ff8a4a"))
	_heat_label.position = Vector2(-10, 22)
	_heat_label.size = Vector2(140, 20)
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_furnace.add_child(_heat_label)
	_furnace.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and selected != null:
			_try_burn(selected))

	# Pilas
	var draw_btn := _pile_button(Vector2(14, 648), func() -> void:
		var cs: Array = engine.draw_pile.duplicate()
		cs.sort_custom(func(a: Card, b: Card) -> bool: return a.id < b.id)
		main.show_deck(cs, "Mazo de robo"))
	_draw_label = UI.label("", 14, UI.DIM)
	_draw_label.position = Vector2(36, 0)
	_draw_label.size = Vector2(120, 60)
	draw_btn.add_child(_draw_label)
	var disc_btn := _pile_button(Vector2(1146, 676), func() -> void: main.show_deck(engine.discard.duplicate(), "Descarte"))
	_discard_label = UI.label("", 14, UI.DIM)
	_discard_label.position = Vector2(36, 4)
	_discard_label.size = Vector2(100, 30)
	disc_btn.add_child(_discard_label)

	_end_btn = UI.button("Fin de turno", _end_turn, 20)
	_end_btn.position = Vector2(1110, 604)
	_end_btn.size = Vector2(150, 56)
	add_child(_end_btn)

	_hint = UI.label("Clic: jugar   ·   Clic derecho: QUEMAR   ·   Espacio / E: fin de turno", 13, UI.DIM)
	_hint.position = Vector2(0, 82)
	_hint.size = Vector2(1280, 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)


func _pile_button(pos: Vector2, cb: Callable) -> Control:
	var b := Control.new()
	b.position = pos
	b.size = Vector2(130, 50)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Ver cartas"
	var back := UI.tex_rect(Art.card_back(), 0.4)
	back.position = Vector2(0, 2)
	b.add_child(back)
	b.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not busy:
			cb.call())
	add_child(b)
	return b


# --- Mano -----------------------------------------------------------------

func _add_card_view(c: Card, from: Vector2 = DRAW_POS) -> CardView:
	var cv := CardView.new(c, engine)
	cv.position = from - CardView.SIZE * 0.5
	cv.scale = Vector2(0.25, 0.25)
	cv.rotation = -0.6
	cv.clicked.connect(_on_card_clicked)
	cv.hover_changed.connect(_on_card_hover)
	_hand_layer.add_child(cv)
	card_views[c.uid] = cv
	return cv


func _relayout(instant: bool = false) -> void:
	var n := engine.hand.size()
	var spacing := minf(124.0, 690.0 / maxf(1.0, n))
	var cx := 640.0
	var hovered_i := -1
	for i in n:
		var cvh: CardView = card_views.get(engine.hand[i].uid)
		if cvh != null and cvh.hovering and not busy:
			hovered_i = i
	for i in n:
		var c: Card = engine.hand[i]
		var cv: CardView = card_views.get(c.uid)
		if cv == null:
			continue
		var off := i - (n - 1) * 0.5
		var target := Vector2(cx + off * spacing - CardView.SIZE.x * 0.5, HAND_Y + absf(off) * absf(off) * 3.0)
		# Las vecinas se apartan de la carta señalada.
		if hovered_i >= 0 and i != hovered_i:
			target.x += 26.0 * signf(i - hovered_i) / maxf(1.0, absf(i - hovered_i) * 0.7)
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
			tw.tween_property(cv, "position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(cv, "rotation", rot, 0.18)
			tw.tween_property(cv, "scale", sc, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_labels()


func _refresh_labels() -> void:
	_energy_label.text = "%d/%d" % [engine.energy, run.max_energy]
	_burns_label.text = "Quemas: %d" % engine.burns_left
	_burns_label.add_theme_color_override("font_color", UI.EMBER if engine.burns_left > 0 else UI.DIM)
	_heat_label.text = "Calor %d" % engine.heat() if engine.heat() > 0 else ""
	_furnace_fire.emitting = engine.burns_left > 0
	_furnace_fire.amount = 26
	_furnace_halo.modulate.a = 0.25 + minf(0.5, engine.heat() * 0.06) if engine.burns_left > 0 else 0.12
	var pc := engine.pile_counts()
	_draw_label.text = "Robo: %d\nExilio: %d" % [pc["draw"], pc["exhaust"]]
	_discard_label.text = "Descarte: %d" % pc["discard"]
	_end_btn.disabled = busy or engine.over
	for v in enemy_views:
		v.targetable = selected != null and selected.card.needs_target() and v.fighter.alive()
	var low := engine.player.hp > 0 and engine.player.hp * 4 <= engine.player.max_hp
	_vignette.visible = low


func _process(delta: float) -> void:
	_t += delta
	if _vignette != null and _vignette.visible:
		_vig_mat.set_shader_parameter("amount", 0.35 + 0.25 * maxf(0.0, sin(_t * 5.0)))


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
		if c.type() == "fuel":
			main.toast("Combustible: sólo puede QUEMARSE (clic derecho)", UI.EMBER)
		elif not c.is_playable():
			main.toast("Esta carta no se puede jugar", UI.DIM)
		else:
			main.toast("No tienes energía suficiente", UI.RED)
		_deny(cv)
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


func _deny(cv: CardView) -> void:
	var tw := cv.create_tween()
	for i in 4:
		tw.tween_property(cv, "rotation", cv.home_rot + (0.08 if i % 2 == 0 else -0.08), 0.04)
	tw.tween_property(cv, "rotation", cv.home_rot, 0.05)


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
		player_view.swing()
	else:
		player_view.cast()
	engine.play_card(c, target)
	_after_action()


func _try_burn(cv: CardView) -> void:
	if busy or engine.over:
		return
	if not engine.can_burn(cv.card):
		Sfx.play("deny")
		if not cv.card.is_burnable():
			main.toast("La Ceniza Húmeda no prende: no se puede quemar", UI.BLUE)
		else:
			main.toast("El horno necesita respirar: no te quedan Quemas este turno", UI.DIM)
		_deny(cv)
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
	_banner("Turno enemigo", Color("ff8a6a"), 0.35)
	engine.begin_enemy_phase()
	for v in enemy_views:
		v.refresh()
	if engine.over:
		_finish()
		return
	await get_tree().create_timer(0.3).timeout
	for v in enemy_views.duplicate():
		if engine.over:
			break
		if not v.fighter.alive():
			continue
		var is_atk := String(v.fighter.intent.get("kind", "")).begins_with("attack")
		if is_atk:
			v.lunge(-1.0)
			await get_tree().create_timer(0.17).timeout
		else:
			UI.punch(v, 0.06)
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


func _banner(text: String, color: Color = UI.EMBER, hold: float = 0.5) -> void:
	_turn_banner.text = text
	_turn_banner.add_theme_color_override("font_color", color)
	_turn_banner.modulate.a = 0.0
	_turn_banner.position.x = -60
	_banner_bg.scale = Vector2(1.0, 0.0)
	_banner_bg.pivot_offset = Vector2(640, 35)
	var tw := create_tween()
	tw.tween_property(_banner_bg, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(_banner_bg, "scale:y", 1.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_turn_banner, "modulate:a", 1.0, 0.14)
	tw.parallel().tween_property(_turn_banner, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(_turn_banner, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(_turn_banner, "position:x", 60.0, 0.25)
	tw.parallel().tween_property(_banner_bg, "modulate:a", 0.0, 0.25)


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


func _local(p: Vector2) -> Vector2:
	return p - global_position


func _furnace_mouth() -> Vector2:
	return _furnace.global_position + Vector2(60, 110)


func _on_event(k: String, d: Dictionary) -> void:
	match k:
		"draw":
			var from := DRAW_POS
			if d.get("recalled", false):
				from = _furnace_mouth()
				UI.sparks(_fx_layer, _local(from), UI.FIRE, 20)
			elif d.get("created", false):
				from = player_view.center()
				UI.sparks(_fx_layer, _local(from), Color("ffd36a"), 14)
			_add_card_view(d["card"], from)
			Sfx.play("card", 0.15, -8.0)
		"discard", "exhaust":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				if k == "exhaust":
					cv.burn_away(0.45).chain().tween_callback(cv.queue_free)
				else:
					var tw := cv.create_tween().set_parallel()
					tw.tween_property(cv, "position", DISCARD_POS - CardView.SIZE * 0.5, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.tween_property(cv, "scale", Vector2(0.2, 0.2), 0.25)
					tw.tween_property(cv, "rotation", 0.8, 0.25)
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
				var stage := Vector2(640 - CardView.SIZE.x * 0.5, 230)
				var tgt: Fighter = d.get("target")
				if c.type() == "attack" and tgt != null and _view_for(tgt) != null:
					stage = _local(_view_for(tgt).center()) - CardView.SIZE * 0.5 + Vector2(-90, -40)
				tw.tween_property(cv, "position", stage, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(cv, "rotation", 0.0, 0.12)
				tw.parallel().tween_property(cv, "scale", Vector2(0.9, 0.9), 0.12)
				tw.tween_interval(0.06)
				if c.type() == "power":
					tw.tween_property(cv, "position", _local(player_view.center()) - CardView.SIZE * 0.5, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.parallel().tween_property(cv, "scale", Vector2(0.15, 0.15), 0.22)
					tw.parallel().tween_property(cv, "modulate", Color(2, 1.6, 0.6, 0.0), 0.22)
					tw.tween_callback(cv.queue_free)
					Sfx.play("buff")
					UI.sparks(_fx_layer, _local(player_view.center()), Color("ffd36a"), 30)
				elif c.exhausts():
					tw.tween_callback(func() -> void: cv.burn_away(0.4).chain().tween_callback(cv.queue_free))
				else:
					tw.tween_property(cv, "position", DISCARD_POS - CardView.SIZE * 0.5, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.parallel().tween_property(cv, "scale", Vector2(0.15, 0.15), 0.22)
					tw.parallel().tween_property(cv, "rotation", 0.8, 0.22)
					tw.parallel().tween_property(cv, "modulate:a", 0.0, 0.22)
					tw.tween_callback(cv.queue_free)
		"card_burned":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			Sfx.play("burn")
			player_view.toss()
			var fpos := _furnace_mouth()
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				cv.z_index = 80
				var tw := cv.create_tween().set_parallel()
				var dest := _local(fpos) - CardView.SIZE * 0.5 + Vector2(40, -90)
				tw.tween_property(cv, "position", dest, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(cv, "rotation", -0.35, 0.32)
				tw.tween_property(cv, "scale", Vector2(0.75, 0.75), 0.32)
				cv.burn_away(0.6).chain().tween_callback(cv.queue_free)
			var ember_amt: float = d["embers"]
			var timer := get_tree().create_timer(0.32)
			timer.timeout.connect(func() -> void:
				if not is_inside_tree():
					return
				UI.sparks(_fx_layer, _local(fpos), UI.FIRE, 46, 70.0)
				UI.float_text(_fx_layer, _local(fpos) + Vector2(120, -150), "+%s" % Num.fmt(ember_amt), UI.EMBER, 26)
				main.fly_embers(fpos, 5)
				main.shake(4.0)
				var ftw := _furnace_img.create_tween()
				ftw.tween_property(_furnace_img, "scale", Vector2(1.12, 0.9), 0.06)
				ftw.tween_property(_furnace_img, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				var htw := _furnace_halo.create_tween()
				htw.tween_property(_furnace_halo, "scale", Vector2(1.8, 1.8), 0.08)
				htw.tween_property(_furnace_halo, "scale", Vector2.ONE, 0.4))
		"mastery":
			var c: Card = d["card"]
			var lvl: int = d["level"]
			var col := Color("ff8ad8") if lvl >= Game.MASTERY_MAX else Color("ffd36a")
			main.toast("%s · Maestría %d%s" % [CardDB.get_def(c.id)["name"], lvl, " (¡máxima!)" if lvl >= Game.MASTERY_MAX else ""], col)
			UI.sparks(_fx_layer, _local(_furnace_mouth()) + Vector2(0, -40), col, 40, 120.0)
			Sfx.play("rebirth", 0.0, -8.0)
			for cvm: CardView in card_views.values():
				if cvm.card.id == c.id:
					cvm.refresh()
					UI.punch(cvm, 0.08)
		"upgraded":
			var cvu: CardView = card_views.get((d["card"] as Card).uid)
			if cvu != null:
				cvu.refresh()
				UI.punch(cvu, 0.1)
				UI.sparks(_fx_layer, cvu.position + CardView.SIZE * 0.5, Color("ffd36a"), 16)
				Sfx.play("buy", 0.1, -8.0)
		"damage":
			var v := _view_for(d["target"])
			if v == null:
				return
			var amt: int = d["amount"]
			var blocked: int = d["blocked"]
			var pos := _local(v.center())
			if amt > 0:
				v.flash(Color.WHITE if not v.fighter.is_player else Color("ff6a5a"))
				v.shake(6.0 + minf(amt, 30.0) * 0.4)
				var big := amt >= 20
				UI.float_text(_fx_layer, pos, str(amt) + ("!" if big else ""), Color("ff5a4a") if v.fighter.is_player else (Color("ffe08a") if big else Color.WHITE), 30 + mini(amt, 40) / 2)
				UI.sparks(_fx_layer, pos, Color("ff3a2a") if v.fighter.is_player else UI.FIRE, 10 + mini(amt, 30))
				Sfx.play("heavy" if amt >= 15 else "hit")
				main.shake(3.0 + minf(amt, 40.0) * 0.25)
				if amt >= 15:
					_hitstop(0.06)
			elif blocked > 0:
				UI.float_text(_fx_layer, pos, "Bloqueado", UI.BLUE, 22)
				Sfx.play("block")
			v.refresh()
			_refresh_vignette_only()
		"block":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, _local(v.center()) + Vector2(0, 30), "+%d" % d["amount"], UI.BLUE, 22)
				Sfx.play("block", 0.05, -4.0)
		"status":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				var amt: int = d["amount"]
				var id: String = d["id"]
				if amt > 0 and id != "":
					var good := id in ["str", "thorns", "regen"]
					if v.fighter.is_player and id in ["thorns", "regen"]:
						good = true
					UI.float_text(_fx_layer, _local(v.center()) + Vector2(0, -40), "%s +%d" % [FighterView.STATUS_NAMES.get(id, id), amt],
						UI.GREEN if good else (UI.FIRE if id == "scorch" else UI.PURPLE), 20)
					Sfx.play("buff" if good else "debuff", 0.05, -4.0)
				if id == "choke" and amt > 0:
					_refresh_labels()
		"heal":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, _local(v.center()), "+%d" % d["amount"], UI.GREEN, 26)
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
			if k == "shuffle" and _fx_layer != null:
				_shuffle_fx()
		"card_added":
			var src := _view_for(d["source"])
			if src != null:
				var from := _local(src.center())
				UI.float_text(_fx_layer, from + Vector2(0, -60), "+%s" % (d["card"] as Card).title(), UI.DIM, 18)
				var ghost := UI.tex_rect(Art.card_back(), 0.6)
				ghost.position = from
				ghost.z_index = 90
				_fx_layer.add_child(ghost)
				var gtw := ghost.create_tween()
				gtw.tween_property(ghost, "position", DISCARD_POS, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				gtw.parallel().tween_property(ghost, "rotation", 3.0, 0.45)
				gtw.tween_callback(ghost.queue_free)
		"turn_start":
			for v in enemy_views:
				v.refresh()
			player_view.refresh()
			if engine.turn > 1:
				_banner("Tu turno", UI.EMBER, 0.35)
				Sfx.play("turn")
		"enemy_died":
			var v := _view_for(d["target"])
			if v != null:
				v.die()
				var pos := _local(v.center())
				Sfx.play("death")
				UI.sparks(_fx_layer, pos, UI.FIRE, 60, 140.0)
				UI.float_text(_fx_layer, pos + Vector2(0, -50), "+%s" % Num.fmt(d["embers"]), UI.EMBER, 24)
				main.fly_embers(v.center(), 8)
				_hitstop(0.08)
				get_tree().create_timer(0.9).timeout.connect(func() -> void:
					if is_inside_tree():
						_layout_enemies(true))
		"summon":
			var nv := _add_enemy_view(d["fighter"])
			_layout_enemies(false)
			nv.spawn()
			Sfx.play("debuff")
			UI.sparks(_fx_layer, _local(nv.center()), UI.FIRE, 30)
			_layout_enemies(true)
		"steal":
			var sv := _view_for(d["source"])
			var amt2: float = d["amount"]
			if sv != null and amt2 > 0.0:
				_coins(main.ember_target(), sv.center(), 6)
				UI.float_text(_fx_layer, _local(sv.center()) + Vector2(0, -70), "−%s Ascuas" % Num.fmt(amt2), Color("ff6a4a"), 22)
				Sfx.play("coin", 0.3, -2.0)
				main.toast("¡Te roba %s Ascuas de la Forja! Mátala para recuperarlas ×2" % Num.fmt(amt2), Color("ff8a6a"))
				sv.refresh()
		"refund":
			var rv := _view_for(d["source"])
			if rv != null:
				main.fly_embers(rv.center(), 12)
				UI.float_text(_fx_layer, _local(rv.center()) + Vector2(0, -90), "¡Recuperadas ×2! +%s" % Num.fmt(d["amount"]), UI.EMBER, 24)
				Sfx.play("coin")
		"embers_gain":
			main.fly_embers(player_view.center(), 8)
			UI.float_text(_fx_layer, _local(player_view.center()) + Vector2(0, -90), "+%s" % Num.fmt(d["amount"]), UI.EMBER, 24)
			Sfx.play("coin")
		"thorns":
			var tv := _view_for(d["target"])
			if tv != null:
				UI.float_text(_fx_layer, _local(tv.center()) + Vector2(0, -20), "Espinas", Color("c0c8d0"), 16)
		"revive":
			player_view.refresh()
			_banner("¡FÉNIX!", UI.EMBER)
			UI.sparks(_fx_layer, _local(player_view.center()), UI.EMBER, 80)
			Sfx.play("rebirth")


func _refresh_vignette_only() -> void:
	if _vignette != null:
		_vignette.visible = engine.player.hp > 0 and engine.player.hp * 4 <= engine.player.max_hp


func _coins(from: Vector2, to: Vector2, count: int) -> void:
	for i in count:
		var e := UI.icon("coin", 2)
		e.z_index = 200
		_fx_layer.add_child(e)
		e.position = _local(from)
		var tw := e.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(e, "position", _local(to) + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(e.queue_free)


func _shuffle_fx() -> void:
	for i in 6:
		var g := UI.tex_rect(Art.card_back(), 0.4)
		g.position = DISCARD_POS - Vector2(15, 20)
		g.z_index = 90
		_fx_layer.add_child(g)
		var tw := g.create_tween()
		tw.tween_interval(i * 0.04)
		tw.tween_property(g, "position", DRAW_POS - Vector2(15, 20), 0.35).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(g, "rotation", -TAU, 0.35)
		tw.tween_callback(g.queue_free)
	Sfx.play("card", 0.3, -6.0)


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
		_banner("DERROTA", UI.RED, 0.8)
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
	var relics: Array[String] = []
	if kind == "boss":
		relics = RelicDB.choices(run.relics, run.rng, 3, "boss")
		if not run.has_pact("pact_hunger"):
			run.heal(run.max_hp)
	elif kind == "elite":
		var roll := run.rng.randf()
		var rar := "rare" if roll < 0.2 else ("uncommon" if roll < 0.6 else "common")
		var r := RelicDB.random_unowned(run.relics, run.rng, rar)
		if r != "":
			run.add_relic(r)
			relics = [r]
	var rewards := run.roll_card_rewards(Game.card_packs(), 3, kind != "combat")
	Game.save_game()
	_show_rewards(total, wave, relics, rewards)


func _show_rewards(total: float, wave: float, relics: Array[String], rewards: Array[Card]) -> void:
	var root := Control.new()
	root.size = Vector2(1280, 720)
	root.z_index = 150
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.84)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	add_child(root)
	var v := UI.vbox(10)
	v.position = Vector2(140, 70)
	v.size = Vector2(1000, 620)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(v)
	var title := UI.label("¡JEFE DERROTADO!" if kind == "boss" else "VICTORIA", 48, UI.EMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UI.rich("[center]Ascuas de este combate: [color=#ffd36a]%s[/color]   (oleada de la Forja: %s)[/center]" % [Num.fmt(total), Num.fmt(wave)], 18)
	v.add_child(sub)
	var cards_box := UI.vbox(10)
	if kind == "boss" and not relics.is_empty():
		v.add_child(_center_label("Las llamas del acto te restauran." if not run.has_pact("pact_hunger") else "El Hambre no te deja descansar.", UI.GREEN))
		v.add_child(_center_label("Elige una reliquia de jefe", UI.EMBER))
		var rrow := UI.hbox(20)
		rrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(rrow)
		cards_box.modulate.a = 0.35
		for id in relics:
			var rd := RelicDB.get_def(id)
			var b := Button.new()
			b.custom_minimum_size = Vector2(290, 120)
			b.focus_mode = Control.FOCUS_NONE
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var hb := UI.hbox(8)
			hb.position = Vector2(10, 10)
			hb.size = Vector2(270, 100)
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(UI.icon(rd["icon"], 5))
			var rt := UI.rich("[color=#ffd36a]%s[/color]\n%s" % [rd["name"], rd["desc"]], 14)
			rt.custom_minimum_size.x = 190
			hb.add_child(rt)
			b.add_child(hb)
			var rid := id
			b.pressed.connect(func() -> void:
				run.add_relic(rid)
				Sfx.play("rebirth")
				main.toast("Obtienes %s" % rd["name"], UI.EMBER)
				for other in rrow.get_children():
					(other as Button).disabled = true
				b.modulate = Color(1.3, 1.2, 0.8)
				cards_box.modulate.a = 1.0)
			rrow.add_child(b)
	elif not relics.is_empty():
		var rd := RelicDB.get_def(relics[0])
		var rr := UI.hbox(10)
		rr.alignment = BoxContainer.ALIGNMENT_CENTER
		rr.add_child(UI.icon(rd["icon"], 4))
		var rt2 := UI.rich("[color=#ffd36a]Reliquia: %s[/color]\n%s" % [rd["name"], rd["desc"]], 17)
		rt2.custom_minimum_size.x = 380
		rr.add_child(rt2)
		v.add_child(rr)
	v.add_child(cards_box)
	cards_box.add_child(_center_label("Elige una carta para tu mazo", UI.TEXT))
	var row := UI.hbox(30 if rewards.size() <= 3 else 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 240
	cards_box.add_child(row)
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
			if cards_box.modulate.a < 0.9:
				main.toast("Primero elige una reliquia", UI.EMBER)
				return
			run.deck.append(c)
			Sfx.play("buy")
			_leave())
	var skip := UI.button("Quemar las ofrendas (+%s Ascuas)" % Num.fmt(skip_value), func() -> void:
		if cards_box.modulate.a < 0.9:
			main.toast("Primero elige una reliquia", UI.EMBER)
			return
		Game.gain_tower_embers(skip_value, "skip")
		main.fly_embers(Vector2(640, 600), 6)
		_leave(), 18)
	skip.custom_minimum_size = Vector2(360, 44)
	var srow := UI.hbox()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_child(skip)
	cards_box.add_child(srow)
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.3)


func _center_label(text: String, color: Color) -> Label:
	var l := UI.label(text, 20, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _leave() -> void:
	main.go("map")
