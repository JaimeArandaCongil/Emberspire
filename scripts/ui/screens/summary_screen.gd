extends Screen
## Resumen de la ascensión: nunca un "Game Over" seco; siempre muestra lo ganado.


func build() -> void:
	var run := Game.run
	var died: bool = args.get("died", true)
	var floor_reached := run.floor_num if run != null else 0
	var s := Game.end_run()
	var bg := UI.tex_rect(Art.background(0, 3, 0), 4.0)
	bg.modulate = Color(0.35, 0.3, 0.3)
	add_child(bg)
	var v := UI.vbox(14)
	v.position = Vector2(340, 90)
	v.size = Vector2(600, 560)
	add_child(v)
	var t := UI.label("Caíste en la Torre" if died else "Regresas a la Forja", 44, UI.RED if died else UI.EMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := UI.label("Pero el fuego recuerda.", 20, UI.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UI.spacer(10))
	var rows := [
		["flame", "Piso alcanzado", str(floor_reached)],
		["ember", "Ascuas ganadas", Num.fmt(float(s.get("embers", 0.0)))],
		["skull", "Enemigos derrotados", str(s.get("kills", 0))],
		["furnace", "Cartas quemadas", str(s.get("burned", 0))],
		["book", "Niveles de Maestría ganados", str(s.get("mastery_ups", 0))],
		["chest", "Reliquias", str(s.get("relics", 0))],
	]
	if int(s.get("heat", 0)) > 0:
		rows.append(["fang", "Calor de Pacto", str(s.get("heat", 0))])
	for i in rows.size():
		var r: Array = rows[i]
		var h := UI.hbox(12)
		h.add_child(UI.icon(r[0], 3))
		var l := UI.label(r[1], 22)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UI.label(r[2], 24, UI.EMBER))
		v.add_child(h)
		h.modulate.a = 0.0
		var tw := h.create_tween()
		tw.tween_interval(0.25 + 0.2 * i)
		tw.tween_callback(func() -> void: Sfx.play("coin", 0.1, -6.0))
		tw.tween_property(h, "modulate:a", 1.0, 0.2)
	var nb: int = s.get("new_braziers", 0)
	if nb > 0:
		var bl := UI.rich("[center][color=#ffb43a]¡%d brasero%s nuevo%s encendido%s![/color]\nLa Forja produce ahora un [color=#ffd36a]+%d%%[/color] gracias a la Torre.[/center]" % [nb, "" if nb == 1 else "s", "" if nb == 1 else "s", "" if nb == 1 else "s", int(Game.BRAZIER_BONUS * 100 * Game.max_floor)], 20)
		v.add_child(bl)
		var fire := UI.fire_emitter(Vector2(300, 10), 60)
		fire.position = Vector2(640, 700)
		add_child(fire)
	v.add_child(UI.spacer(10))
	var b := UI.button("Volver a la Forja", func() -> void: main.go("forge"), 22)
	b.custom_minimum_size = Vector2(300, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
