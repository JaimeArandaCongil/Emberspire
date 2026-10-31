extends Node
## QA visual: recorre el bucle completo del juego y guarda capturas en screenshots/.
## Ejecutar (con ventana): godot --path . res://tests/smoke.tscn

var main: Control
var _errors := 0


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.seen_intro = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.0)
	await _shot("01_title")

	Game.embers = 2500.0
	Game.generators = {"spark": 30, "bellows": 12, "furnace": 3}
	Game.max_floor = 7
	Game.grimoires = {"pyre": true}
	Game.arsenal = {"vitality": 3, "greed": 2}
	main.go("forge")
	await _wait(1.2)
	await _shot("02_forge")

	Game.start_run(1234)
	Game.run.add_relic("whetstone")
	Game.run.deck.append(Card.new("coal"))
	Game.run.deck.append(Card.new("inner_fire"))
	main.go("map")
	await _wait(1.0)
	await _shot("03_map")

	Game.run.floor_num = 4
	main.go("combat", {"kind": "combat", "enemies": ["soot_golem", "cinder_bat", "ash_slime"]})
	await _wait(1.2)
	await _shot("04_combat")
	var cs = main.current
	# Hover sobre una carta para ver el realce.
	var views: Array = cs.card_views.values()
	if views.size() > 2:
		var cv: CardView = views[2]
		cv._on_enter()
		await _wait(0.4)
		await _shot("05_combat_hover")
		cv._on_exit()
	# Quemar una carta y jugar otra.
	if not cs.engine.hand.is_empty():
		var c: Card = cs.engine.hand[0]
		cs._try_burn(cs.card_views[c.uid])
	await _wait(0.15)
	await _shot("06_burn")
	await _wait(0.8)
	for c: Card in cs.engine.hand.duplicate():
		if cs.engine.can_play(c) and c.type() == "attack":
			cs._play(cs.card_views[c.uid], cs.engine.living_enemies()[0])
			break
	await _wait(0.6)
	cs._end_turn()
	await _wait(3.0)
	await _shot("07_after_enemy_turn")
	# Forzar victoria para ver recompensas.
	for e in cs.engine.enemies:
		if e.alive():
			cs.engine._damage(e, 9999, false)
	cs.engine._check_end()
	cs._finish()
	await _wait(2.4)
	await _shot("08_rewards")

	Game.run.floor_num = 10
	main.go("combat", {"kind": "boss"})
	await _wait(1.4)
	await _shot("09_boss")
	Game.run.floor_num = 15
	main.go("combat", {"kind": "elite"})
	await _wait(1.2)
	await _shot("10_act2")
	Game.run.floor_num = 25
	main.go("combat", {"kind": "combat"})
	await _wait(1.2)
	await _shot("11_act3")
	main.go("shop")
	await _wait(1.0)
	await _shot("12_shop")
	main.go("rest")
	await _wait(1.0)
	await _shot("13_rest")
	main.go("event", {"type": "event"})
	await _wait(1.0)
	await _shot("14_event")
	main.go("summary", {"died": true})
	await _wait(2.2)
	await _shot("15_summary")
	main.show_deck(Game.start_run(5).deck)
	await _wait(0.6)
	await _shot("16_deck")
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
