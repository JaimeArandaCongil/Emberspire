extends Node
## Captura fotogramas de animación (swing, golpe enemigo, muerte, quemar) recortados.

var main: Control
var frames: Array[Image] = []

func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.seen_intro = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	Game.start_run(99)
	Game.run.floor_num = 4
	main.go("combat", {"kind": "combat", "enemies": ["soot_golem", "ember_magpie"]})
	await _wait(1.4)
	var cs = main.current
	# Swing de la heroína: fotogramas cada ~33 ms
	cs.player_view.swing()
	frames.clear()
	for i in 14:
		await _grab(Rect2i(100, 260, 420, 240))
		await _wait(0.033)
	_strip("swing")
	await _wait(0.5)
	# Golpe recibido por enemigo
	var ev = cs.enemy_views[0]
	frames.clear()
	ev.flash()
	ev.shake(10.0)
	for i in 10:
		await _grab(Rect2i(660, 280, 420, 220))
		await _wait(0.033)
	_strip("enemy_hit")
	await _wait(0.5)
	# Embestida enemiga
	frames.clear()
	ev.lunge(-1.0)
	for i in 12:
		await _grab(Rect2i(560, 280, 520, 220))
		await _wait(0.033)
	_strip("enemy_lunge")
	await _wait(0.5)
	# Quemar
	frames.clear()
	if not cs.engine.hand.is_empty():
		var c: Card = cs.engine.hand[0]
		cs._try_burn(cs.card_views[c.uid])
	for i in 12:
		await _grab(Rect2i(0, 150, 640, 570))
		await _wait(0.07)
	_strip("burn", 2)
	await _wait(0.8)
	# Muerte
	frames.clear()
	ev.die()
	for i in 12:
		await _grab(Rect2i(660, 250, 420, 250))
		await _wait(0.08)
	_strip("death")
	print("ANIM OK")
	get_tree().quit()

func _grab(r: Rect2i) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	frames.append(img.get_region(r))

func _strip(name: String, rows: int = 2) -> void:
	var w := frames[0].get_width()
	var h := frames[0].get_height()
	var cols := int(ceil(frames.size() / float(rows)))
	var out := Image.create(cols * w, rows * h, false, frames[0].get_format())
	for i in frames.size():
		out.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(ProjectSettings.globalize_path("res://tests/_review_art/out/anim_%s.png" % name))

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
