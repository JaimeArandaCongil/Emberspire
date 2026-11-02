extends Node
## F2-VIDA · capturas fotograma a fotograma del combate del acto 1 (golpe, turno enemigo, Quemadura, muerte, reposo) para
## medir tiempos y píxeles en movimiento. No es parte de la QA: es la herramienta de evidencia del paquete.
## Uso (con ventana y fps fijos; VIDA_MODE = golpe | turno | estado | muerte | reposo):
## F2-VIDA2 añade: jefe (golpe al jefe del acto 1), recompensa (reliquias de jefe antes/después de elegir) y flotante
## (texto flotante apagándose por pasos). Las capturas de `mano`, `recompensa` y `flotante` van a 1280×720.
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
	var mode := OS.get_environment("VIDA_MODE")
	if mode in ["jefe", "recompensa", "fase2", "invoca"]:
		Game.run.floor_num = 10
		main.go("combat", {"kind": "boss", "enemies": ["great_bellows"]})
	else:
		main.go("combat", {"kind": "combat", "enemies": ["soot_golem", "ember_magpie", "ash_slime"]})
	await _frames(90)
	cs = main.current
	cs.engine.event.connect(func(k: String, _d: Dictionary) -> void: _events.append(k))
	match mode:
		"jefe":
			await _golpe()
		"recompensa":
			await _recompensa()
		"fase2":
			await _fase2()
		"invoca":
			await _invoca()
		"flotante":
			await _flotante()
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
			if not (tag.begins_with("mano") or tag.begins_with("recomp") or tag.begins_with("flot") or tag.begins_with("full")):
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


## Reliquias de jefe: cartas 2 pasos más abajo hasta elegir; después, a su color.
func _recompensa() -> void:
	for e in cs.engine.enemies:
		if e.alive():
			cs.engine._damage(e, 99999, false)
	cs.engine._check_end()
	cs._finish()
	await _frames(150)
	await _grab("recomp_antes", 1)
	for b: Node in cs.find_children("*", "Button", true, false):
		if (b as Button).custom_minimum_size == Vector2(290, 120):
			(b as Button).pressed.emit()
			break
	await _frames(20)
	await _grab("recomp_despues", 1)


## Texto flotante: sube y se apaga por pasos de rampa (sin alfa). Una captura cada 3 fotogramas.
## VIDA_OLD=1 reproduce el fundido anterior (modulate:a de 1 a 0 en 350 ms desde los 450) para medir el antes.
func _flotante() -> void:
	for t: Array in [[Vector2(470, 300), "12", UI.TEXT, 33], [Vector2(820, 300), "+1.2K", UI.EMBER, 24]]:
		UI.float_text(cs._fx_layer, t[0], t[1], t[2], t[3])
		if OS.get_environment("VIDA_OLD") == "1":
			var l: Label = cs._fx_layer.get_child(cs._fx_layer.get_child_count() - 1)
			l.create_tween().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	await _grab("flot", 54, 3)


## Jefe: intención en la banda (captura completa), golpe que lo baja del 50 % → fase 2 (cada 3 f) y fase 2 asentada.
func _fase2() -> void:
	await _grab("full_jefe_intencion", 1)
	var b: Fighter = cs.engine.enemies[0]
	cs.engine._damage(b, int(ceil(b.max_hp * 0.55)), false)
	await _grab("fase2", 36, 3)
	await _frames(60)
	await _grab("full_jefe_fase2", 1)


## Turno del jefe con invocación forzada: anima `summon`, el jefe se aparta y los ácaros salen en sus huecos.
func _invoca() -> void:
	cs.engine.enemies[0].intent = {"kind": "summon", "ops": [["summon", "candle_mite", 2]]}
	cs._end_turn()
	await _grab("invoca", 120, 4)
	await _frames(60)
	await _grab("full_invoca", 1)
