extends Node
## F2-VIDA · capturas fotograma a fotograma del combate del acto 1 (golpe, turno enemigo, Quemadura, muerte, reposo) para
## medir tiempos y píxeles en movimiento. No es parte de la QA: es la herramienta de evidencia del paquete.
## Uso (con ventana y fps fijos; VIDA_MODE = golpe | turno | estado | muerte | reposo):
##   VIDA_DIR=/ruta VIDA_MODE=golpe xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --fixed-fps 60 res://tests/art/vida_capturas.tscn
## `reposo` se mide a --fixed-fps 30 (12 s = 360 fotogramas, como F2-REV). Guarda PNG a 640×360 (un píxel de arte = 1 px)
## y escribe en la salida estándar una línea por fotograma con la animación de la heroína y los eventos del motor.

var main: Control
var cs
var dir := ""
var _frame := 0
var _events: PackedStringArray = []


func _ready() -> void:
	dir = OS.get_environment("VIDA_DIR")
	if dir == "":
		dir = ProjectSettings.globalize_path("user://vida")
	DirAccess.make_dir_recursive_absolute(dir)
	Game.autosave_enabled = false
	Game.reset_all()
	Game.seen_intro = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	Game.start_run(1234)
	Game.run.floor_num = 4
	main.go("combat", {"kind": "combat", "enemies": ["soot_golem", "ember_magpie", "ash_slime"]})
	await _frames(90)
	cs = main.current
	cs.engine.event.connect(func(k: String, _d: Dictionary) -> void: _events.append(k))
	match OS.get_environment("VIDA_MODE"):
		"turno":
			await _turno()
		"estado":
			await _estado()
		"muerte":
			await _muerte()
		"reposo":
			await _reposo()
		"mano":
			await _mano()
		_:
			await _golpe()
	print("VIDA fin")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Captura el fotograma ya dibujado; `every` > 1 guarda sólo uno de cada `every`.
func _grab(tag: String, n: int, every := 1) -> void:
	for i in n:
		await RenderingServer.frame_post_draw
		var hv: FighterView = cs.player_view
		var anim := "%s:%d" % [hv._anim.animation, hv._anim.frame] if hv._anim != null else "-"
		print("VIDA %s %03d t=%d ms héroe=%s eventos=%s" % [tag, i, Time.get_ticks_msec(), anim, ",".join(_events)])
		_events.clear()
		if i % every == 0:
			var img := get_viewport().get_texture().get_image()
			if not tag.begins_with("mano"):
				img.resize(640, 360, Image.INTERPOLATE_NEAREST)
			img.save_png(dir.path_join("%s_%03d.png" % [tag, i]))


func _golpe() -> void:
	for c: Card in cs.engine.hand.duplicate():
		if cs.engine.can_play(c) and c.type() == "attack":
			cs._play(cs.card_views[c.uid], cs.engine.living_enemies()[0])
			break
	await _grab("golpe", 42)


func _turno() -> void:
	# El gólem ataca seguro: así se ve el orden embestida → impacto → reacción.
	cs.engine.enemies[0].intent = {"kind": "attack", "ops": [["atk", 6, 1]]}
	cs._end_turn()
	await _grab("turno", 120, 2)


func _estado() -> void:
	var g: Fighter = cs.engine.enemies[0]
	for v: int in [0, 3, 9]:
		g.statuses["scorch"] = v
		g.block = 5 if v == 9 else 0
		cs.enemy_views[0].refresh()
		print("VIDA estado %d: lenguas %d, bucle %s" % [v, cs.enemy_views[0].status_fx.flame_count(), cs.enemy_views[0].status_fx.active_loop()])
		await _frames(20)
		await _grab("estado%d" % v, 4)


func _muerte() -> void:
	var g: Fighter = cs.engine.enemies[0]
	cs.engine._damage(g, 9999, false)
	await _grab("muerte", 80, 2)


func _reposo() -> void:
	await _frames(60)
	await _grab("reposo", 360)


## Mano de 5 (paso máximo) y mano llena (10): la mano no pisa la Forja ni «Fin de turno» y ningún título queda bajo un orbe.
func _mano() -> void:
	await _grab("mano5", 1)
	cs.engine.draw_cards(10 - cs.engine.hand.size())
	cs._relayout(true)
	await _frames(40)
	await _grab("mano10", 1)
