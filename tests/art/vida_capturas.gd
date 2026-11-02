extends Node
## F2-VIDA · capturas fotograma a fotograma del combate del acto 1 (golpe, turno enemigo, Quemadura, muerte, reposo) para
## medir tiempos y píxeles en movimiento. No es parte de la QA: es la herramienta de evidencia del paquete.
## Uso (con ventana y fps fijos; VIDA_MODE = golpe | turno | estado | muerte | reposo):
## F2-VIDA5 añade rotulo y rotulo_jefe: solapes de los rótulos de turno («Turno enemigo», «Tu turno») con flotantes,
## intenciones y reliquias en 300 f desde el fin de turno (ROT_STRESS=1 mete flotantes extra cada 4 f; 1280×720 cada 3 f).
## F2-PULIDO-A añade recoloca (N7: se quema la primera carta y la mano se recoloca; x de cada carta por fotograma, 1280×720).
## F2-VIDA4 añade cola (flotantes apilados sobre la cabeza del gólem: daño, y en su turno bloqueo + 2 «+Hollín»; 1280×720).
## F2-VIDA3 añade descarte (las cartas vuelan al descarte al acabar el turno; 1280×720, cada fotograma).
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
	if mode in ["jefe", "recompensa", "fase2", "invoca", "rotulo_jefe"]:
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
		"descarte":
			await _descarte()
		"cola":
			await _cola()
		"rotulo", "rotulo_jefe":
			await _rotulo(mode)
		"recoloca":
			await _recoloca()
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
		if tag.begins_with("full_cola"):
			_check_floats(tag, i)
		if tag.begins_with("full_recoloca"):
			_check_hand(tag, i)
		if OS.get_environment("VIDA_DBG") == "1" and not cs.enemy_views.is_empty():
			var ev: FighterView = cs.enemy_views[0]
			if ev._lit_mat != null and ev._anim != null:
				print("  DBG piece=%s white=%s steps=%s anim=%s:%d pos=%s flip=%s xf=%s mat_propio=%s" % [ev._lit_mat.get_shader_parameter(&"flash_piece"), ev._lit_mat.get_shader_parameter(&"flash_white"), ev._lit_mat.get_shader_parameter(&"flash_steps"), ev._anim.animation, ev._anim.frame, ev._anim.position, ev._anim.flip_h, ev.actor.get_global_transform(), ev._anim.material == ev._lit_mat])
		if i % every == 0:
			var img := get_viewport().get_texture().get_image()
			if not (tag.begins_with("mano") or tag.begins_with("recomp") or tag.begins_with("flot") or tag.begins_with("full") or tag.begins_with("desc")):
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
	# F2-VIDA4: reposo congelado en el f0 para comparar Q0/Q1/Q3/Q9 píxel a píxel (sólo cambia el estado y la luz).
	var ev: FighterView = cs.enemy_views[0]
	if ev._anim != null:
		ev._anim.frame = 0
		ev._anim.speed_scale = 0.0
	for v: int in [0, 1, 3, 9]:
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


## Fin de turno: la mano vuela al descarte (antes: alfa; ahora −2 pasos de paleta a mitad de vuelo y desaparece).
func _descarte() -> void:
	cs._end_turn()
	await _grab("desc", 24)


## F2-VIDA4 (N1): la heroína golpea al gólem y, en el turno enemigo, el gólem se cubre y mete 2 Hollín (caso 10b). Cada
## flotante debe quedar sobre la cabeza y la intención, sin pisarse con los demás. Captura completa cada 3 fotogramas.
func _cola() -> void:
	var g: Fighter = cs.engine.enemies[0]
	for c: Card in cs.engine.hand.duplicate():
		if cs.engine.can_play(c) and c.type() == "attack":
			cs._play(cs.card_views[c.uid], g)
			break
	await _grab("full_cola_golpe", 30, 3)
	g.intent = {"kind": "defend", "ops": [["block", 8], ["add_card", "soot", 2]]}
	cs._end_turn()
	await _grab("full_cola_turno", 90, 3)


## Solapes de la cola: flotante con flotante, con la intención y con la caja del cuerpo (pantalla, px).
func _check_floats(tag: String, i: int) -> void:
	var rects: Array[Rect2] = []
	for n: Node in cs._fx_layer.get_children():
		if n is Label and (n as Label).visible and (n as Label).z_index == 100:
			rects.append((n as Label).get_global_rect())
	var pares := 0
	for a in rects.size():
		for b in range(a + 1, rects.size()):
			if rects[a].intersects(rects[b]):
				pares += 1
	var con_intencion := 0
	var con_cuerpo := 0
	for v: FighterView in cs.enemy_views + [cs.player_view]:
		var ir: Rect2 = v._intent.get_global_rect() if v._intent.visible else Rect2()
		var br := Rect2(v.wv.world_to_ui(v.body_world().position), v.body_world().size * FighterView.WS)
		for r in rects:
			if ir.has_area() and r.intersects(ir):
				con_intencion += 1
			if r.intersects(br):
				con_cuerpo += 1
	print("COLA %s %03d flotantes=%d solapes=%d sobre_intencion=%d sobre_cuerpo=%d" % [tag, i, rects.size(), pares, con_intencion, con_cuerpo])


## F2-VIDA5: la heroína golpea y acaba el turno; por fotograma, rectángulo del rótulo de turno visible (el nuevo `_tag_bg`
## o, en el código anterior, `_banner_bg` con «Turno enemigo» / «Tu turno») contra flotantes, intenciones y reliquias.
func _rotulo(mode: String) -> void:
	var g: Fighter = cs.engine.living_enemies()[0]
	for c: Card in cs.engine.hand.duplicate():
		if cs.engine.can_play(c) and c.type() == "attack":
			cs._play(cs.card_views[c.uid], g)
			break
	await _frames(12)
	g.intent = {"kind": "defend", "ops": [["block", 8], ["add_card", "soot", 2]]}
	var stress := OS.get_environment("ROT_STRESS") == "1"
	var stats := {}
	cs._end_turn()
	for i in 300:
		await RenderingServer.frame_post_draw
		if stress and i % 4 == 0:
			for v: FighterView in cs.enemy_views + [cs.player_view]:
				cs._float_over(v, "+%d Bloqueo" % i, Color.WHITE)
		var bg: Control = cs.get("_tag_bg")
		var txt := ""
		if bg != null and bg.visible:
			txt = String(cs._tag_label.text)
		elif cs._banner_bg.visible and String(cs._turn_banner.text) in ["Turno enemigo", "Tu turno"]:
			bg = cs._banner_bg
			txt = String(cs._turn_banner.text)
		if txt != "" and bg.size.y > 0.0:
			var r: Rect2 = bg.get_global_rect()
			var st: Dictionary = stats.get(txt, {"f": 0, "desde": i, "hasta": i, "flot": 0, "int": 0, "rel": 0, "rect": r})
			st["f"] += 1
			st["hasta"] = i
			if r.size.y >= (st["rect"] as Rect2).size.y:
				st["rect"] = r
			var fl := 0
			for n: Node in cs._fx_layer.get_children():
				if n is Label and (n as Label).visible and (n as Label).z_index == 100 and (n as Label).get_global_rect().intersects(r):
					fl += 1
			var it := 0
			for v: FighterView in cs.enemy_views:
				if v._intent.visible and v._intent.get_global_rect().intersects(r):
					it += 1
			var rel: Variant = cs.get("_relic_row")
			st["flot"] += 1 if fl > 0 else 0
			st["int"] += 1 if it > 0 else 0
			st["rel"] += 1 if rel != null and is_instance_valid(rel) and (rel as Control).get_global_rect().intersects(r) else 0
			stats[txt] = st
		if i % 3 == 0:
			get_viewport().get_texture().get_image().save_png(dir.path_join("%s%s_%03d.png" % [mode, "_estres" if stress else "", i]))
	for k: String in stats:
		var st: Dictionary = stats[k]
		print("ROT %s%s «%s» visible_f=%d (f%d–f%d = %d ms) rect=%s f_con_flotante=%d f_con_intencion=%d f_con_reliquias=%d" % [
			mode, " estrés" if stress else "", k, st["f"], st["desde"], st["hasta"], int((st["hasta"] - st["desde"] + 1) * 1000 / 60.0),
			st["rect"], st["flot"], st["int"], st["rel"]])


## F2-PULIDO-A (N7): se quema la primera carta y la mano se recoloca. Por fotograma, x e y de cada carta de la mano y
## cuántas quedan fuera de la rejilla ×2 (px impares o fraccionarios).
func _recoloca() -> void:
	var c: Card = cs.engine.hand[0]
	cs._try_burn(cs.card_views[c.uid])
	await _grab("full_recoloca", 24)


func _check_hand(tag: String, i: int) -> void:
	var xs: PackedStringArray = []
	var off := 0
	for c: Card in cs.engine.hand:
		var cv: CardView = cs.card_views.get(c.uid)
		if cv == null:
			continue
		var p: Vector2 = cv.get_global_rect().position
		xs.append("%.2f,%.2f" % [p.x, p.y])
		if fposmod(p.x, 2.0) != 0.0 or fposmod(p.y, 2.0) != 0.0:
			off += 1
	print("MANO %s %03d fuera_de_rejilla=%d pos=%s" % [tag, i, off, " ".join(xs)])
