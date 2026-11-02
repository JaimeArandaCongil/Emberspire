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
	await _wait(0.33)
	await _shot("09_burn")
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
	cs.engine._enemy_op(cs.engine.enemies[0], ["summon", "candle_mite", 2])
	await _wait(0.8)
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
	var path := ProjectSettings.globalize_path("res://screenshots/%s.png" % name)
	img.save_png(path)
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
