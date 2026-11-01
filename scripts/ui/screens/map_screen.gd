extends Screen
## La Torre: elige una puerta por piso. Muestra la columna de la torre con los braseros encendidos.

var run: RunState


func build() -> void:
	run = Game.run
	if run == null:
		main.go("forge")
		return
	var biome := EnemyDB.act_index(maxi(1, run.floor_num + 1))
	var cyc := EnemyDB.cycle(maxi(1, run.floor_num + 1))
	var bg := UI.tex_rect(Art.background(biome, 999, cyc), 4.0)
	bg.modulate = Color(0.55, 0.5, 0.5)
	add_child(bg)
	run.in_room = false
	Game.save_game()
	if run.pending_doors.is_empty() or run.door_meta.size() != run.pending_doors.size():
		run.pending_doors = run.roll_doors(1 if Game.talents.has("star_map") else 0)
	add_child(UI.dust(Rect2(0, 60, 1280, 660), Color("ffb070"), 18))

	var tower := TowerColumn.new()
	tower.run = run
	tower.position = Vector2(24, 70)
	tower.size = Vector2(230, 630)
	add_child(tower)

	_build_doors()
	_build_info()
	_process_drafts.call_deferred()


## Compensación del punto de control: cartas a elegir y reliquias de jefe.
func _process_drafts() -> void:
	if run.pending_drafts > 0:
		var offer := run.roll_card_rewards(Game.card_packs(), 3, true)
		main.pick_card("Punto de control: elige una carta (%d restantes)" % run.pending_drafts, offer, func(c: Variant) -> void:
			run.pending_drafts -= 1
			if c != null:
				run.deck.append(c)
			Game.save_game()
			_process_drafts.call_deferred(), true)
		return
	if run.pending_boss_relics > 0:
		var opts := RelicDB.choices(run.relics, run.rng, 3, "boss")
		var buttons: Array = []
		for id in opts:
			var rid: String = id
			buttons.append([RelicDB.get_def(rid)["name"], func() -> void:
				run.add_relic(rid)
				run.pending_boss_relics -= 1
				Game.save_game()
				main.go("map")])
		var body := ""
		for id in opts:
			body += "[color=#ffd36a]%s[/color]: %s\n" % [RelicDB.get_def(id)["name"], RelicDB.get_def(id)["desc"]]
		main.modal("Reliquia del guardián saltado", body, buttons, 620)


func _build_doors() -> void:
	var next := run.floor_num + 1
	var title := UI.label("Piso %d" % next, 40, UI.EMBER)
	title.position = Vector2(280, 78)
	title.size = Vector2(720, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := UI.label(EnemyDB.act_name(next) + "  ·  Elige una puerta", 18, UI.DIM)
	sub.position = Vector2(280, 128)
	sub.size = Vector2(720, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var doors := run.pending_doors
	var w := 200.0
	var gap := 24.0
	var total := doors.size() * w + (doors.size() - 1) * gap
	var x0 := 640.0 - total * 0.5
	for i in doors.size():
		var kind: String = doors[i]
		var b := _door_button(kind, i)
		b.position = Vector2(x0 + i * (w + gap), 190)
		add_child(b)
		b.modulate.a = 0.0
		b.position.y += 30
		var tw := b.create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(b, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(b, "position:y", 190.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _door_button(kind: String, idx: int) -> Control:
	var info: Dictionary = RunState.DOOR_INFO[kind]
	var col := UI.EDGE
	match kind:
		"elite": col = Color("c2321e")
		"boss": col = Color("ffb43a")
		"rest": col = Color("6ac46a")
		"shop": col = Color("8ab4d0")
		"event": col = Color("9a5ad0")
		"treasure": col = Color("ffd36a")
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 290)
	b.size = Vector2(200, 290)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UI.box(Color("1e1418"), col.darkened(0.2), 4, 6))
	b.add_theme_stylebox_override("hover", UI.box(Color("2e1c1c"), col.lightened(0.3), 4, 6))
	b.add_theme_stylebox_override("pressed", UI.box(Color("3e2420"), Color.WHITE, 4, 2))
	var v := UI.vbox(8)
	v.position = Vector2(10, 16)
	v.size = Vector2(180, 260)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	# Arco de la puerta
	var arch := ArchIcon.new()
	arch.color = col
	arch.icon_id = info["icon"]
	arch.custom_minimum_size = Vector2(180, 140)
	arch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(arch)
	var n := UI.label(info["name"], 22, col.lightened(0.35))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var d := UI.rich("[center]%s[/center]" % _door_desc(kind, idx), 13)
	d.custom_minimum_size = Vector2(180, 52)
	v.add_child(d)
	b.mouse_entered.connect(func() -> void:
		Sfx.play("hover", 0.1, -6.0)
		b.pivot_offset = b.size * 0.5
		b.create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1))
	b.mouse_exited.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	b.pressed.connect(func() -> void: _enter(kind, idx))
	return b


## Descripción con información parcial: quién espera detrás y qué rasgo tiene la puerta.
func _door_desc(kind: String, idx: int) -> String:
	var info: Dictionary = RunState.DOOR_INFO[kind]
	var meta: Dictionary = run.door_meta[idx] if idx < run.door_meta.size() else {}
	if not meta.has("enemies"):
		return info["desc"]
	var names: PackedStringArray = []
	var counts := {}
	for eid: String in meta["enemies"]:
		counts[eid] = int(counts.get(eid, 0)) + 1
	for eid: String in counts:
		var nm: String = EnemyDB.ENEMIES[eid]["name"]
		names.append(nm if counts[eid] == 1 else "%d× %s" % [counts[eid], nm])
	var t := "[color=#c8b0a0]%s[/color]" % ", ".join(names)
	var tr: String = RunState.DOOR_TRAITS.get(meta.get("trait", "none"), "")
	if tr != "":
		t += "\n[color=#ffd36a]%s[/color]" % tr
	return t


func _enter(kind: String, idx: int = 0) -> void:
	Sfx.play("door")
	var meta: Dictionary = run.door_meta[idx] if idx < run.door_meta.size() else {}
	run.floor_num += 1
	run.floors_climbed += 1
	run.streak_floors += 1
	run.pending_doors.clear()
	run.door_meta = []
	run.in_room = true
	run.combat_mods = {}
	if meta.get("trait", "none") != "none" and meta.has("trait"):
		run.combat_mods[meta["trait"]] = true
	Game.reach_floor(run.floor_num)
	match kind:
		"combat", "elite", "boss":
			var a := {"kind": kind}
			if meta.has("enemies"):
				a["enemies"] = meta["enemies"]
			main.go("combat", a)
		"rest": main.go("rest")
		"shop": main.go("shop")
		"event": main.go("event", {"type": "event"})
		"treasure": main.go("event", {"type": "treasure"})


func _build_info() -> void:
	var p := UI.panel(Color(0.12, 0.08, 0.09, 0.92))
	p.position = Vector2(1030, 70)
	p.custom_minimum_size = Vector2(230, 0)
	add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label("La Fogonera", 22, UI.EMBER))
	var hp := UI.hbox(6)
	hp.add_child(UI.icon("heart", 2))
	hp.add_child(UI.label("%d / %d" % [run.hp, run.max_hp], 20, Color("ff8a7a")))
	v.add_child(hp)
	v.add_child(UI.rich("Energía [color=#ffd36a]%d[/color] · Robo [color=#ffd36a]%d[/color]\nQuemas/turno [color=#ffd36a]%d[/color]" % [run.max_energy, run.draw_per_turn, run.burns_per_turn], 15))
	v.add_child(UI.rich("Ascuas en esta ascensión:\n[color=#ffd36a]%s[/color]" % Num.fmt(run.embers_earned), 15))
	var pot_l := UI.rich("Brasas Vivas: racha [color=#ffd36a]%d[/color] pisos (+%d%%)\nBote: [color=#ffb43a]%s[/color]" % [run.streak_floors, int(run.streak_mult() * 100), Num.fmt(run.pot)], 14)
	pot_l.mouse_filter = Control.MOUSE_FILTER_PASS
	pot_l.tooltip_text = "Cada piso sin volver a la Forja suma +4% (máx. +100%) a un bote aparte.\nSe cobra al retirarte o en una Hoguera. Si mueres, el bote se pierde (tus Ascuas no)."
	v.add_child(pot_l)
	if run.heat() > 0:
		var names: PackedStringArray = []
		for id in run.pacts:
			names.append(ForgeDB.pact(id)["name"])
		var hl := UI.rich("Calor de Pacto [color=#ff8a4a]%d[/color] (×%.2f Ascuas)" % [run.heat(), 1.0 + Game.heat_bonus_each() * run.heat()], 14)
		hl.mouse_filter = Control.MOUSE_FILTER_PASS
		hl.tooltip_text = "\n".join(names)
		v.add_child(hl)
	if not run.perks.is_empty():
		var pl := UI.rich("Resonancias activas: [color=#d0a8ff]%d[/color]" % run.perks.size(), 14)
		pl.mouse_filter = Control.MOUSE_FILTER_PASS
		var pn: PackedStringArray = []
		for id in run.perks:
			pn.append("%s: %s" % [RelicDB.get_def(id)["name"], RelicDB.get_def(id)["desc"]])
		pl.tooltip_text = "\n".join(pn)
		v.add_child(pl)
	v.add_child(UI.button("Ver mazo (%d)" % run.deck.size(), func() -> void: main.show_deck(run.deck), 16))
	if not run.relics.is_empty():
		v.add_child(UI.label("Reliquias", 16, UI.DIM))
		var grid := GridContainer.new()
		grid.columns = 5
		for id in run.relics:
			var rd := RelicDB.get_def(id)
			var ic := UI.icon(rd["icon"], 3)
			ic.mouse_filter = Control.MOUSE_FILTER_PASS
			ic.tooltip_text = "%s\n%s" % [rd["name"], rd["desc"]]
			grid.add_child(ic)
		v.add_child(grid)
	v.add_child(UI.spacer(10))
	var retire := UI.button("Volver a la Forja", func() -> void:
		main.modal("¿Retirarte?", "Volverás a la Forja con todas las Ascuas ganadas y cobrarás el bote de Brasas Vivas (+%s).\nTu récord de pisos se conserva." % Num.fmt(run.pot),
			[["Retirarme", func() -> void: main.go("summary", {"died": false})], ["Seguir subiendo", func() -> void: pass]]), 16)
	v.add_child(retire)


## Columna de la torre: pisos, braseros encendidos y posición actual.
class TowerColumn extends Control:
	var run: RunState
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var floor_h := 52.0
		var cur := run.floor_num
		var top_floor := cur + 6
		draw_rect(Rect2(Vector2(60, 0), Vector2(110, size.y)), Color("1c1214"))
		for i in 13:
			var f := top_floor - i
			if f < 0:
				continue
			var y := i * floor_h
			var r := Rect2(Vector2(60, y), Vector2(110, floor_h - 4))
			var in_act := (f - 1) % 10 + 1 if f > 0 else 0
			var base := Color("3a2a2c").lerp(Color("4a3a3c"), 0.5 if f % 2 == 0 else 0.0)
			if f == 0:
				base = Color("2a2024")
			draw_rect(r, base)
			draw_rect(r, Color("1a0f12"), false, 2.0)
			var lit := f > 0 and f <= Game.max_floor
			if lit:
				var flick := 0.8 + 0.2 * sin(_t * 6.0 + f)
				draw_rect(Rect2(r.position + Vector2(8, 14), Vector2(14, 18)), Color(1.0, 0.45, 0.1, flick))
				draw_rect(Rect2(r.position + Vector2(11, 10), Vector2(8, 10)), Color(1.0, 0.85, 0.4, flick))
			var label := "Piso %d" % f if f > 0 else "Base"
			var col := Color("f4e4c8") if f == cur else Color("a08878")
			if in_act == 10:
				label = "JEFE %d" % f
				col = Color("ffb43a")
			draw_string(font, r.position + Vector2(28, 30), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
			if f == cur:
				var pt := Art.player()
				draw_texture_rect(pt, Rect2(Vector2(26, y + 12), Vector2(pt.get_width(), pt.get_height())), false)
			if f == cur + 1:
				var a := 0.5 + 0.5 * sin(_t * 4.0)
				draw_rect(r.grow(2), Color(1.0, 0.7, 0.3, a), false, 3.0)
		draw_string(font, Vector2(60, size.y - 4), "Récord: %d" % Game.max_floor, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffb43a"))


## Arco de puerta dibujado con el icono del destino.
class ArchIcon extends Control:
	var color := Color.WHITE
	var icon_id := "unknown"

	func _draw() -> void:
		var c := size * 0.5
		var w := 110.0
		var h := 130.0
		var r := Rect2(c.x - w * 0.5, size.y - h, w, h)
		draw_rect(r, Color("1a0f12"))
		draw_rect(r.grow(-6), Color("120a0c"))
		draw_circle(Vector2(c.x, r.position.y + 55), 49.0, Color("120a0c"))
		draw_rect(Rect2(r.position.x + 6, r.position.y + 55, w - 12, h - 61), Color("120a0c"))
		var glow := Color(color, 0.25)
		draw_rect(Rect2(r.position.x + 12, r.end.y - 30, w - 24, 24), glow)
		var tex := Art.icon(icon_id)
		var s := 5.0
		var ts := Vector2(tex.get_width(), tex.get_height()) * s
		draw_texture_rect(tex, Rect2(Vector2(c.x - ts.x * 0.5, r.position.y + 40), ts), false)
		for i in 5:
			draw_rect(Rect2(r.position.x - 4 + i * 0.0, r.position.y + 50 + i * 16, 8, 12), color.darkened(0.4))
			draw_rect(Rect2(r.end.x - 4, r.position.y + 50 + i * 16, 8, 12), color.darkened(0.4))
