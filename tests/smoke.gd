extends Node
## QA visual: recorre el bucle completo del juego y guarda capturas en screenshots/.
## Ejecutar (con ventana): godot --path . res://tests/smoke.tscn

var main: Control
var _fails := 0


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.seen_intro = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.0)
	await _shot("01_title")

	Game.embers = 25000.0
	Game.generators = {"spark": 55, "bellows": 26, "furnace": 12, "crucible": 3}
	Game.max_floor = 12
	Game.grimoires = {"pyre": true, "forge": true}
	Game.arsenal = {"vitality": 3, "greed": 2, "heirloom": 1}
	Game.relic_codex = {"whetstone": true, "iron_lung": true, "bone_tinder": true, "pyre_mask": true, "gold_bellows": true}
	Game.mastery = {"strike": 7, "kindling": 40, "defend": 2, "coal": 90, "ember_slash": 16}
	Game.stats = {"burns": 60, "kills": 70}
	Game.seen_tips = {"pacts": true}
	Game.check_hitos()
	main.go("forge")
	await _wait(1.4)
	await _shot("02_forge")
	var fs = main.current
	fs._tabs.current_tab = 2
	await _wait(0.5)
	await _shot("03_forge_archive")
	fs._tabs.current_tab = 3
	await _wait(0.5)
	await _shot("04_forge_chronicle")

	Game.active_pacts = ["pact_hp", "pact_burn"]
	Game.heirloom_picks = ["gold_bellows"]
	main.go("antesala")
	await _wait(1.0)
	await _shot("05_antesala")

	Game.start_run(1234)
	Game.run.add_relic("whetstone")
	Game.run.deck.append(Card.new("coal"))
	Game.run.deck.append(Card.new("inner_fire"))
	Game.run.deck.append(Card.new("brazier_flame", true))
	main.go("map")
	await _wait(1.0)
	await _shot("06_map")

	Game.run.floor_num = 4
	main.go("combat", {"kind": "combat", "enemies": ["soot_golem", "ember_magpie", "ash_slime"]})
	await _wait(1.4)
	await _shot("07_combat")
	var cs = main.current
	await _check_light(cs)
	await _check_block_edge(cs)
	await _check_intents(cs)
	await _check_glow(cs)
	var views: Array = cs.card_views.values()
	if views.size() > 2:
		var cv: CardView = views[2]
		cv._on_enter()
		await _wait(0.4)
		await _shot("08_combat_hover")
		cv._on_exit()
	# Quemar una carta (captura a mitad de la disolución) y jugar un ataque.
	if not cs.engine.hand.is_empty():
		var c: Card = cs.engine.hand[0]
		cs._try_burn(cs.card_views[c.uid])
	await _check_burn_flight(cs)
	await _shot("09_burn")
	_check(not _rect_hits_floor_label(cs), "los avisos no tapan el rótulo del piso")
	await _wait(0.8)
	for c: Card in cs.engine.hand.duplicate():
		if cs.engine.can_play(c) and c.type() == "attack":
			cs._play(cs.card_views[c.uid], cs.engine.living_enemies()[0])
			break
	await _wait(0.12)
	await _shot("10_swing")
	await _wait(0.6)
	cs._end_turn()
	await _wait(1.0)
	await _shot("10b_enemy_turn")
	await _wait(2.2)
	await _shot("11_after_enemy_turn")
	for e in cs.engine.enemies:
		if e.alive():
			cs.engine._damage(e, 9999, false)
	await _wait(0.35)
	await _shot("12_death_dissolve")
	cs.engine._check_end()
	cs._finish()
	await _wait(2.4)
	await _shot("13_rewards")

	Game.run.floor_num = 10
	main.go("combat", {"kind": "boss", "enemies": ["great_bellows"]})
	await _wait(1.6)
	cs = main.current
	var before_summon: int = cs.enemy_views.size()
	cs.engine._enemy_op(cs.engine.enemies[0], ["summon", "candle_mite", 2])
	await _check_summon_reveal(cs, before_summon)
	await _wait(0.5)
	await _shot("14_boss_summon")
	for e in cs.engine.enemies:
		if e.alive():
			cs.engine._damage(e, 99999, false)
	cs.engine._check_end()
	cs._finish()
	await _wait(2.4)
	await _shot("15_boss_relics")

	Game.run.floor_num = 20
	main.go("combat", {"kind": "boss", "enemies": ["slag_hydra"]})
	await _wait(1.6)
	await _shot("16_act2_hydra")
	Game.run.floor_num = 25
	main.go("combat", {"kind": "elite", "enemies": ["rime_knight", "ice_moth"]})
	await _wait(1.4)
	await _shot("17_act3")
	Game.run.floor_num = 30
	main.go("combat", {"kind": "boss", "enemies": ["frost_king"]})
	await _wait(1.6)
	await _shot("18_frost_king")
	await _check_layout()
	main.go("shop")
	await _wait(1.0)
	await _shot("19_shop")
	main.go("rest")
	await _wait(1.0)
	await _shot("20_rest")
	Game.run.seen_events.clear()
	for e: String in ["altar", "smith", "well", "mirror", "merchant", "gambler", "hollow_shrine", "frozen_traveller",
			"library", "anvil_trial", "wind_bellows", "star_fall", "coal_mine", "tinkerer", "burning_bridge"]:
		Game.run.seen_events.append(e)
	main.go("event", {"type": "event"})
	await _wait(1.0)
	await _shot("21_event_forge_spirit")
	main.go("summary", {"died": true})
	await _wait(2.6)
	await _shot("22_summary")
	var deck: Array = []
	for id in ["strike", "ember_slash", "pyroclasm", "ember_cannon", "transmute", "gunpowder", "spark_card", "wet_ash", "corona", "kindling", "coal", "anvil_ward"]:
		deck.append(Card.new(id, id == "pyroclasm"))
	main.show_deck(deck, "Muestra")
	await _wait(0.6)
	await _shot("23_cards")
	print("SMOKE OK" if _fails == 0 else "SMOKE CON %d FALLOS" % _fails)
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	# SHOTS_DIR (ruta absoluta) permite a varios agentes capturar a la vez sin pisarse; por defecto, screenshots/.
	var dir := OS.get_environment("SHOTS_DIR")
	if dir == "":
		dir = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join("%s.png" % name))
	print("captura: ", name)


func _check(ok: bool, msg: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + msg)
	if not ok:
		_fails += 1


## Cuenta los píxeles de pantalla de un rectángulo que usan alguno de los colores dados.
func _count_colors(rect: Rect2i, colors: Array) -> int:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image().get_region(rect)
	img.convert(Image.FORMAT_RGB8)
	var n := 0
	var keys := {}
	for c: Color in colors:
		keys[c.to_html(false)] = true
	for y in img.get_height():
		for x in img.get_width():
			if keys.has(img.get_pixel(x, y).to_html(false)):
				n += 1
	return n


func _mean_luma(rect: Rect2i) -> float:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image().get_region(rect)
	img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	return img.get_pixel(0, 0).get_luminance()


func _mouse_move(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	get_viewport().push_input(ev)
	await get_tree().process_frame
	await get_tree().process_frame


func _mouse_click(p: Vector2) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = p
		ev.global_position = p
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		get_viewport().push_input(ev)
		await get_tree().process_frame


## LightRig conectado al estado real: pelo y martillo siguen al calor, onda al quemar, PV bajos.
func _check_light(cs) -> void:
	var hv: FighterView = cs.player_view
	hv._anim.pause()
	hv._anim.frame = 0
	var r := hv.body_world()
	var rect := Rect2i(Vector2i(r.position * 2) - Vector2i(24, 24), Vector2i(r.size * 2) + Vector2i(48, 48))
	var hot_hi: Array = [Palette.color(&"hot", 5), Palette.color(&"hot", 4)]
	var hot_lo: Array = [Palette.color(&"hot", 1), Palette.color(&"hot", 0)]
	var tips: Array = [Palette.color(&"fire", 5), Palette.color(&"fire", 6)]
	var results := {}
	for heat: float in [0.1, 0.9]:
		cs._state.heat = heat
		await _wait(0.15)
		results[heat] = [await _count_colors(rect, hot_hi), await _count_colors(rect, hot_lo), await _count_colors(rect, tips)]
	print("calor 0.1 / 0.9 [martillo vivo, martillo frío, puntas]: ", results[0.1], " / ", results[0.9])
	_check(results[0.9][0] > results[0.1][0] and results[0.1][1] > results[0.9][1], "la cara del martillo sigue al calor")
	_check(results[0.9][2] > results[0.1][2], "las puntas del pelo siguen al calor")
	# Un único shader: la heroína sólo cambia de parámetro; los demás no tienen el calor activado.
	var base_sh: Shader = load("res://shaders/palette_lit.gdshader")
	_check(hv._hero_mat.shader == base_sh and hv._hero_mat.get_shader_parameter(&"hero_heat") == true, "la heroína usa palette_lit con hero_heat")
	var others_off := true
	for ev: FighterView in cs.enemy_views:
		if ev._anim != null:
			var em := ev._anim.material as ShaderMaterial
			others_off = others_off and em == cs._wv.lit_material and em.get_shader_parameter(&"hero_heat") != true
	_check(others_off, "los enemigos no siguen al calor")
	# Heat real: producción y quemas del combate.
	var h0: float = cs._wv.lights.heat
	cs._sync_light()
	_check(is_equal_approx(cs._state.heat, 0.2 + 0.8 * AmbientState.normalize_production(Game.production()) + 0.05 * cs.engine.heat()) or cs._state.heat == 1.0, "calor según producción (%.2f → %.2f)" % [h0, cs._state.heat])
	# PV bajos: oscurece los bordes de la escena, no el centro.
	var corner := Rect2i(0, 200, 120, 200)
	var before: float = await _mean_luma(corner)
	var hp: int = cs.engine.player.hp
	cs.engine.player.hp = 1
	cs._sync_light()
	await _wait(0.2)
	var after: float = await _mean_luma(corner)
	_check(after < before, "PV bajos oscurecen los bordes (%.3f → %.3f)" % [before, after])
	cs.engine.player.hp = hp
	cs._sync_light()
	# Pulso de quemar: el rig recibe la onda.
	cs._state.pulse_burn(false)
	_check(cs._wv.lights._burn_t >= 0.0, "cada quema lanza la onda de LightRig")
	await _wait(0.8)
	hv._anim.play(&"idle")


## El contorno de bloqueo y demás efectos de estado siguen la silueta del fotograma actual, en cualquier luchador y pose.
func _check_block_edge(cs) -> void:
	var cases: Array = [[cs.player_view, [&"idle", &"toss", &"attack", &"hurt", &"cast"]]]
	for v: FighterView in cs.enemy_views:
		cases.append([v, [&"idle", &"attack", &"hurt"]])
	var t0 := Time.get_ticks_usec()
	var hv: FighterView = cs.player_view
	hv.status_fx.set_mask(hv.body_mask())
	print("set_mask, coste por cambio de fotograma: %d µs" % (Time.get_ticks_usec() - t0))
	for pair: Array in cases:
		var v: FighterView = pair[0]
		var name_v: String = v.fighter.def_id if v.fighter.def_id != "" else "heroina"
		var saved: int = v.fighter.block
		v.fighter.block = 5
		v.refresh()
		var bad := 0
		var rows := 0
		for an: StringName in pair[1]:
			if not v._anim.sprite_frames.has_animation(an):
				continue
			for f in v._anim.sprite_frames.get_frame_count(an):
				v._anim.play(an)
				v._anim.pause()
				v._anim.frame = f
				await get_tree().process_frame
				await get_tree().process_frame
				var fx: StatusFX = v.status_fx
				var frame := v.current_frame().get_image()
				var origin := v.canvas_world()
				var edges: PackedInt32Array = fx._right if v.fighter.is_player else fx._left
				for i in edges.size():
					if edges[i] < 0:
						continue
					rows += 1
					var solid := Vector2(fx._body_x() + edges[i], fx._body_y() + i) - origin
					var out := solid + (Vector2.RIGHT if v.fighter.is_player else Vector2.LEFT)
					var inside := Rect2(Vector2.ZERO, frame.get_size()).has_point(out)
					if frame.get_pixelv(Vector2i(solid)).a8 == 0 or (inside and frame.get_pixelv(Vector2i(out)).a8 != 0):
						bad += 1
		_check(rows > 0 and bad == 0, "bloqueo pegado a la silueta en %s: %d filas, %d fuera" % [name_v, rows, bad])
		if v.fighter.is_player:
			v._anim.play(&"toss")
			v._anim.pause()
			v._anim.frame = 1
			await _wait(0.1)
			await _shot("09a_block_toss")
		v.fighter.block = saved
		v.refresh()
		v._anim.play(&"idle")
	await _wait(0.4)


## Placa de intención: dentro de la rejilla ×2, sobre su luchador y sin invadir la placa de vida ni el rótulo.
func _check_intents(cs) -> void:
	for v: FighterView in cs.enemy_views:
		var r: Rect2 = v._intent.get_global_rect()
		_check(int(r.size.x) % 2 == 0 and int(r.size.y) % 2 == 0 and v._intent._plate.texture != null, "placa de intención en la rejilla ×2 (%s)" % [r.size])
		_check(r.end.y <= v._plate.get_global_rect().position.y and r.position.y >= 88.0 - IntentView.H, "la intención no invade otros elementos (y %d–%d)" % [r.position.y, r.end.y])


## Resplandor: los cantos con luz cálida pasan a la rampa de oro y vuelven al apagarse.
func _check_glow(cs) -> void:
	var golds: Array = []
	for i in 6:
		golds.append(Palette.color(&"gold", i))
	var rect := Rect2i(0, 110, 480, 420)
	var off0: int = await _count_colors(rect, golds)
	var until: float = Game.glow_until
	var value: float = Game.glow_value
	Game.glow_value = 2.0
	Game.glow_until = Time.get_unix_time_from_system() + 60.0
	await _wait(0.2)
	_check(cs._wv.lights.gold, "LightRig recibe el Resplandor")
	var on: int = await _count_colors(rect, golds)
	await _shot("07b_glow")
	Game.glow_until = until
	Game.glow_value = value
	await _wait(0.2)
	var off1: int = await _count_colors(rect, golds)
	print("píxeles de oro sin/con/sin Resplandor: ", off0, " / ", on, " / ", off1)
	_check(on > off0 and off1 <= off0 + 40 and not cs._wv.lights.gold, "la luz cálida pasa a oro y vuelve (%d → %d → %d)" % [off0, on, off1])


## La carta quemada vuela por detrás de la heroína: se dibuja antes que su actor en el mundo.
func _check_burn_flight(cs) -> void:
	var waited := 0.0
	var seen := false
	var hv: FighterView = cs.player_view
	while waited < 0.33:
		await get_tree().process_frame
		waited += get_process_delta_time()
		var sp: Sprite2D = cs._burn_card_sprite
		if not seen and is_instance_valid(sp) and sp.get_parent() != null:
			seen = true
			_check(sp.get_index() < hv.actor.get_index() and sp.get_parent() == hv.actor.get_parent(), "la carta vuela por detrás de la heroína")
			while is_instance_valid(sp) and sp.position.x > float(hv.center_x()) + 4.0:
				await get_tree().process_frame
				waited += get_process_delta_time()
			if is_instance_valid(sp):
				var tm := Engine.time_scale
				Engine.time_scale = 0.01
				await _shot("09b_burn_flight")
				Engine.time_scale = tm
	_check(seen, "la carta llegó a cruzar a la heroína")


func _rect_hits_floor_label(cs) -> bool:
	var fl: Rect2 = Rect2()
	for ch: Node in cs.get_children():
		if ch is FloorLabel:
			fl = (ch as FloorLabel).get_global_rect()
	for ch: Node in main.overlay_layer.get_children():
		if ch is PanelContainer and (ch as Control).get_global_rect().intersects(fl):
			return true
	return false


## Invocación: el recién llegado emerge de abajo arriba por `reveal` y vuelve al material común.
func _check_summon_reveal(cs, before: int) -> void:
	await _wait(0.26)
	if cs.enemy_views.size() <= before:
		_check(false, "la invocación añade luchadores")
		return
	var nv: FighterView = cs.enemy_views[before]
	if nv._anim != null:
		_check(nv._reveal_mat != null, "el invocado emerge por `reveal` (y = %s)" % [nv._reveal_mat.get_shader_parameter(&"reveal_y") if nv._reveal_mat != null else "?"])
		var tm := Engine.time_scale
		Engine.time_scale = 0.01
		await _shot("14a_summon_reveal")
		Engine.time_scale = tm
	await _wait(0.3)
	if nv._anim != null:
		_check(nv._reveal_mat == null and nv._anim.material == cs._wv.lit_material, "el invocado vuelve al material común")


## Mano de 10, altura de vuelo y centros de la disposición.
func _check_layout() -> void:
	Game.run.floor_num = 4
	main.go("combat", {"kind": "combat", "enemies": ["cinder_bat", "flame_moth", "candle_mite"]})
	await _wait(1.0)
	var cs = main.current
	var xs: Array = []
	for v: FighterView in cs.enemy_views:
		xs.append(v.center_x())
	_check(xs == [350, 460, 572], "centros de 3 enemigos: %s" % [xs])
	var bat: FighterView = cs.enemy_views[0]
	_check(bat.body_world().end.y < FighterView.FLOOR_Y - 20, "el murciélago vuela (base %d, suelo 264)" % bat.body_world().end.y)
	_check(cs.enemy_views[2].body_world().end.y == FighterView.FLOOR_Y, "el ácaro pisa el suelo")
	while cs.engine.hand.size() < 10:
		var c := Card.new("strike")
		cs.engine.hand.append(c)
		cs._add_card_view(c, Vector2(640, 600))
	cs._relayout(true)
	var ok := true
	for i in 10:
		var cv: CardView = cs.card_views[cs.engine.hand[i].uid]
		ok = ok and cv.position == Vector2(150 + 90 * i, 592)
	_check(ok, "mano de 10: paso 90 en x 150–1120, reposo y=592")
	var last: CardView = cs.card_views[cs.engine.hand[9].uid]
	last._on_enter()
	await _wait(0.3)
	_check(last.position.y <= 496.0, "al pasar el ratón y ≤ 496 (y=%d)" % last.position.y)
	_check(last.position.x + CardView.SIZE.x + 30.0 <= 1280.0 and last.position.y - 54.0 >= 0.0, "la placa de quemar cabe en pantalla")
	last._on_exit()
	# Ratón real por la ventana, no llamadas directas: la interfaz sobre WorldView debe recibirlo.
	var card3: CardView = cs.card_views[cs.engine.hand[3].uid]
	await _mouse_move(card3.global_position + Vector2(40, 60))
	_check(card3.hovering, "el ratón real activa el hover de la carta")
	await _wait(0.3)
	_check(card3.position.y <= 496.0, "la carta sube y sigue bajo el ratón (y=%d)" % card3.position.y)
	await _mouse_move(cs._end_btn.get_global_rect().get_center())
	_check(not card3.hovering, "el hover termina al salir")
	await _wait(0.3)
	await _mouse_click(cs._end_btn.get_global_rect().get_center())
	_check(cs.busy, "el clic real en Fin de turno lo pulsa")
	await _wait(2.5)
	var bp: Rect2 = cs._end_btn.get_global_rect()
	_check(bp.position.x >= 1120.0 + 18.0, "fin de turno fuera de la franja de la mano")
	cs.player_view.die()
	await _wait(1.0)
	await _shot("18b_hero_death")
