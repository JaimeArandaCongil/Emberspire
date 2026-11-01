extends Node
## QA visual: recorre el bucle completo del juego y guarda capturas en screenshots/.
## Ejecutar (con ventana): godot --path . res://tests/smoke.tscn

var main: Control


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
	await _wait(3.2)
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
	print("SMOKE OK")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://screenshots/%s.png" % name)
	img.save_png(path)
	print("captura: ", name)
