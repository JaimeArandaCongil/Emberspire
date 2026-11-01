extends Screen
## La Forja: hub incremental. Generadores (con Resonancias), Arsenal, Grimorios, Archivo, Crónica y Renacer.

var _gen_rows: Array[Dictionary] = []       # {g, btn, count, rate, row, pips}
var _arsenal_rows: Array[Dictionary] = []   # {a, btn, lvl}
var _grim_rows: Array[Dictionary] = []
var _talent_rows: Array[Dictionary] = []
var _gen_list: VBoxContainer
var _arsenal_list: VBoxContainer
var _grim_list: VBoxContainer
var _archive_list: VBoxContainer
var _chronicle_list: VBoxContainer
var _rebirth_box: VBoxContainer
var _tabs: TabContainer
var _mode_btn: Button
var _click_label: Label
var _breakdown: RichTextLabel
var _furnace_icon: TextureRect
var _furnace_halo: TextureRect
var _fx: Control
var _tick := 0.0
var _heat_lvl := -1
var _archive_dirty := true


func build() -> void:
	var bg := UI.tex_rect(Art.background(0, 1, 0), 4.0)
	bg.modulate = Color(0.42, 0.36, 0.36)
	add_child(bg)
	add_child(UI.dust(Rect2(0, 60, 1280, 660), Color("ffb070"), 20))
	_build_left()
	_build_generators()
	_build_tabs()
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	Game.forge_changed.connect(_on_forge_changed)
	_refresh_all()
	_show_welcome.call_deferred()


func _show_welcome() -> void:
	if not Game.seen_intro:
		Game.seen_intro = true
		main.modal("La Forja", "Eres [color=#ffb43a]la Fogonera[/color]. La ciudad se congela y sólo tu forja late.\n\n" +
			"• [color=#ffd36a]Aviva el horno[/color] y compra generadores: producen Ascuas incluso con el juego cerrado.\n" +
			"• Con 10, 50 y 100 unidades, cada generador [color=#d0a8ff]Resuena[/color]: te da una ventaja en la Torre.\n" +
			"• [color=#ffd36a]Asciende a la Torre[/color]: combate con cartas. Cualquier carta puede [color=#ff8a4a]QUEMARSE[/color]: da Ascuas y gana [color=#ffb0ff]Maestría[/color] para siempre.\n" +
			"• Cada piso récord enciende un [color=#ffb43a]Brasero[/color]: +10% de producción para siempre.\n" +
			"• Morir no te quita nada. Todo vuelve a la Forja.",
			[["Encender la forja", func() -> void: pass]], 680)
	elif not Game.offline_report.is_empty():
		var r: Dictionary = Game.offline_report
		Game.offline_report = {}
		main.modal("Mientras dormías…", "La forja ha seguido ardiendo durante [color=#ffd36a]%s[/color].\n\n+[color=#ffb43a]%s[/color] Ascuas" % [Num.fmt_time(r["seconds"]), Num.fmt(r["embers"])],
			[["¡A trabajar!", func() -> void: Sfx.play("coin")]])


# --- Columna izquierda: el horno ------------------------------------------

func _build_left() -> void:
	var p := UI.panel(Color(0.1, 0.06, 0.07, 0.9))
	p.position = Vector2(14, 58)
	p.custom_minimum_size = Vector2(370, 650)
	p.size = Vector2(370, 650)
	add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	var t := UI.label("LA FORJA", 30, UI.EMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(340, 226)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	holder.tooltip_text = "Clic para avivar el fuego"
	v.add_child(holder)
	_furnace_halo = UI.halo(Color("ff7a2a"), 130.0, 0.45)
	_furnace_halo.position = Vector2(170, 150) - _furnace_halo.size * 0.5
	holder.add_child(_furnace_halo)
	var htw := _furnace_halo.create_tween().set_loops()
	htw.tween_property(_furnace_halo, "scale", Vector2(1.08, 1.08), 0.9).set_trans(Tween.TRANS_SINE)
	htw.tween_property(_furnace_halo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	_furnace_icon = UI.tex_rect(Art.forge_sprite(0.0), 5.0)
	_furnace_icon.position = Vector2(170 - 120, 20)
	_furnace_icon.pivot_offset = _furnace_icon.size * Vector2(0.5, 1.0)
	holder.add_child(_furnace_icon)
	var fire := UI.fire_emitter(Vector2(80, 10), 60)
	fire.position = Vector2(170, 170)
	fire.initial_velocity_max = 120.0
	holder.add_child(fire)
	var smoke := CPUParticles2D.new()
	smoke.amount = 14
	smoke.lifetime = 2.4
	smoke.position = Vector2(170, 20)
	smoke.direction = Vector2.UP
	smoke.spread = 20.0
	smoke.gravity = Vector2(10, -20)
	smoke.initial_velocity_min = 20.0
	smoke.initial_velocity_max = 40.0
	smoke.scale_amount_min = 5.0
	smoke.scale_amount_max = 12.0
	smoke.color = Color(0.4, 0.35, 0.35, 0.35)
	holder.add_child(smoke)
	holder.gui_input.connect(_on_furnace_input)
	_click_label = UI.label("", 15, UI.DIM)
	_click_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_click_label)

	var asc_text := "ASCENDER A LA TORRE"
	if Game.run != null:
		asc_text = "CONTINUAR (Piso %d)" % Game.run.floor_num
	var asc := UI.button(asc_text, _ascend, 24)
	asc.custom_minimum_size = Vector2(340, 64)
	asc.add_theme_stylebox_override("normal", UI.box(Color("8a3a1a"), Color("ffb43a"), 4, 5))
	asc.add_theme_stylebox_override("hover", UI.box(Color("b04a1a"), Color("ffe08a"), 4, 5))
	v.add_child(asc)
	var pulse := asc.create_tween().set_loops()
	pulse.tween_property(asc, "modulate", Color(1.15, 1.05, 0.9), 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(asc, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)

	_breakdown = UI.rich("", 14)
	_breakdown.custom_minimum_size = Vector2(340, 200)
	v.add_child(_breakdown)


func _on_furnace_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var gained := Game.click_forge()
		Sfx.play("coin", 0.15, -6.0)
		var pos := get_local_mouse_position()
		UI.float_text(_fx, pos, "+%s" % Num.fmt(gained), UI.EMBER, 24, 60.0)
		UI.sparks(_fx, pos, UI.FIRE, 8, 120.0)
		var tw := _furnace_icon.create_tween()
		tw.tween_property(_furnace_icon, "scale", Vector2(1.06, 0.94), 0.05)
		tw.tween_property(_furnace_icon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)


func _ascend() -> void:
	Sfx.play("door")
	if Game.run == null:
		main.go("antesala")
	else:
		main.go("map")


# --- Generadores ----------------------------------------------------------

func _build_generators() -> void:
	var p := UI.panel(Color(0.1, 0.06, 0.07, 0.9))
	p.position = Vector2(396, 58)
	p.custom_minimum_size = Vector2(460, 650)
	p.size = Vector2(460, 650)
	add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	var head := UI.hbox(8)
	var t := UI.label("Generadores", 24, UI.EMBER)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_mode_btn = UI.button("", _cycle_mode, 15)
	_mode_btn.custom_minimum_size = Vector2(90, 30)
	_mode_btn.tooltip_text = "Cantidad a comprar"
	head.add_child(_mode_btn)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(436, 590)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_gen_list = UI.vbox(6)
	_gen_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_gen_list)
	for i in ForgeDB.GENERATORS.size():
		var g: Dictionary = ForgeDB.GENERATORS[i]
		var row := UI.panel(Color("1e1418"), Color("3d2b2e"))
		row.custom_minimum_size = Vector2(420, 78)
		var h := UI.hbox(10)
		row.add_child(h)
		var ic := UI.icon(g["icon"], 4)
		h.add_child(ic)
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_l := UI.label(g["name"], 18)
		var count_l := UI.label("", 13, UI.DIM)
		var rate_l := UI.label("", 13, UI.EMBER)
		info.add_child(name_l)
		info.add_child(count_l)
		info.add_child(rate_l)
		var pips := UI.hbox(3)
		pips.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(pips)
		for tier in RelicDB.RESONANCE_TIERS.size():
			var pid := RelicDB.perk_for(g["id"], tier)
			var pd := RelicDB.get_def(pid)
			var pip := PanelContainer.new()
			pip.mouse_filter = Control.MOUSE_FILTER_PASS
			var pl := UI.label("", 11, Color("d0a8ff"))
			pip.add_child(pl)
			pip.set_meta("perk", pid)
			pip.set_meta("tier", tier)
			pip.tooltip_text = "Resonancia (%d): %s\n%s" % [Game.resonance_threshold(tier), pd["name"], pd["desc"]]
			pips.add_child(pip)
		h.add_child(info)
		var id: String = g["id"]
		var btn := UI.button("", func() -> void: _buy_gen(id), 15)
		btn.custom_minimum_size = Vector2(120, 56)
		h.add_child(btn)
		row.tooltip_text = "%s\n«%s»\nProduce %s/s cada uno. ×2 a las 25, 50, 100 y 200 unidades." % [g["name"], g["flavor"], Num.fmt(g["rate"])]
		_gen_list.add_child(row)
		_gen_rows.append({"g": g, "btn": btn, "count": count_l, "rate": rate_l, "row": row, "name": name_l, "index": i, "pips": pips})


func _cycle_mode() -> void:
	match Game.buy_mode:
		1: Game.buy_mode = 10
		10: Game.buy_mode = -1
		_: Game.buy_mode = 1
	_refresh_dynamic()


func _buy_gen(id: String) -> void:
	var g := ForgeDB.generator(id)
	var n := Game.buy_amount_for(g)
	var perks_before := Game.perk_ids().size()
	if Game.buy_generator(id, n):
		Sfx.play("buy", 0.05, -3.0)
		for r in _gen_rows:
			if r["g"]["id"] == id:
				UI.punch(r["row"], 0.04)
				var row: Control = r["row"]
				UI.sparks(_fx, row.global_position - global_position + Vector2(40, 36), UI.EMBER, 12)
		if Game.perk_ids().size() > perks_before:
			var newest := ""
			for pid in Game.perk_ids():
				if RelicDB.PERKS[pid]["gen"] == id:
					newest = pid
			if newest != "":
				var pd := RelicDB.get_def(newest)
				Sfx.play("rebirth", 0.0, -4.0)
				main.toast("¡Resonancia! %s: %s" % [pd["name"], pd["desc"]], Color("d0a8ff"))
	else:
		Sfx.play("deny")


# --- Pestañas -------------------------------------------------------------

func _build_tabs() -> void:
	_tabs = TabContainer.new()
	_tabs.position = Vector2(868, 58)
	_tabs.custom_minimum_size = Vector2(398, 650)
	_tabs.size = Vector2(398, 650)
	_tabs.add_theme_font_size_override("font_size", 13)
	add_child(_tabs)
	_arsenal_list = _tab_page(_tabs, "Arsenal")
	_grim_list = _tab_page(_tabs, "Grimorios")
	_archive_list = _tab_page(_tabs, "Archivo")
	_chronicle_list = _tab_page(_tabs, "Crónica")
	_rebirth_box = _tab_page(_tabs, "Renacer")
	_build_arsenal()
	_build_grimoires()
	_build_rebirth()
	_tabs.tab_changed.connect(func(i: int) -> void:
		if i == 2:
			_build_archive()
		elif i == 3:
			_build_chronicle())


func _tab_page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	return v


func _build_arsenal() -> void:
	UI.clear(_arsenal_list)
	_arsenal_rows.clear()
	var intro := UI.rich("[color=#a08878]Mejoras permanentes para la Fogonera en la Torre.[/color]", 14)
	_arsenal_list.add_child(intro)
	for a in ForgeDB.ARSENAL:
		var row := UI.panel(Color("1e1418"), Color("3d2b2e"))
		row.custom_minimum_size = Vector2(360, 0)
		var h := UI.hbox(8)
		row.add_child(h)
		h.add_child(UI.icon(a["icon"], 3))
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := UI.label(a["name"], 16)
		var dl := UI.rich("[color=#a08878]%s[/color]" % a["desc"], 13)
		dl.custom_minimum_size.x = 170
		var ll := UI.label("", 12, UI.EMBER)
		info.add_child(nl)
		info.add_child(dl)
		info.add_child(ll)
		h.add_child(info)
		var id: String = a["id"]
		var btn := UI.button("", func() -> void:
			if Game.buy_arsenal(id):
				Sfx.play("buy")
				UI.punch(row, 0.04)
			else:
				Sfx.play("deny"), 14)
		btn.custom_minimum_size = Vector2(100, 48)
		h.add_child(btn)
		_arsenal_list.add_child(row)
		_arsenal_rows.append({"a": a, "btn": btn, "lvl": ll})


func _build_grimoires() -> void:
	UI.clear(_grim_list)
	_grim_rows.clear()
	_grim_list.add_child(UI.rich("[color=#a08878]Los grimorios añaden nuevas cartas a las recompensas de la Torre.[/color]", 14))
	for g in ForgeDB.GRIMOIRES:
		var row := UI.panel(Color("1e1418"), Color("3d2b2e"))
		var v := UI.vbox(4)
		row.add_child(v)
		var h := UI.hbox(8)
		h.add_child(UI.icon("book", 3))
		var nl := UI.label(g["name"], 17, UI.EMBER)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		var id: String = g["id"]
		var btn := UI.button("", func() -> void:
			if Game.buy_grimoire(id):
				Sfx.play("buy")
				main.toast("¡%s desbloqueado!" % g["name"], UI.EMBER)
			else:
				Sfx.play("deny"), 14)
		btn.custom_minimum_size = Vector2(110, 40)
		h.add_child(btn)
		v.add_child(h)
		v.add_child(UI.rich("[color=#a08878]%s[/color]" % g["desc"], 13))
		var preview_btn := UI.button("Ver cartas (%d)" % CardDB.ids_in_packs([id]).size(), func() -> void:
			var cs: Array = []
			for cid in CardDB.ids_in_packs([id]):
				cs.append(Card.new(cid))
			main.show_deck(cs, g["name"]), 13)
		v.add_child(preview_btn)
		_grim_list.add_child(row)
		_grim_rows.append({"g": g, "btn": btn})


## Archivo: Códice (Maestría por carta) y Reliquario (colección de reliquias).
func _build_archive() -> void:
	UI.clear(_archive_list)
	var codex_bonus := int(round((Game.codex_mult() - 1.0) * 100))
	_archive_list.add_child(UI.label("Reliquario", 18, UI.EMBER))
	_archive_list.add_child(UI.rich("[color=#a08878]Cada reliquia encontrada en la Torre queda aquí y da [color=#ffd36a]+%d%%[/color] de producción.\nTotal: [color=#ffd36a]%d / %d[/color] → [color=#ffd36a]+%d%%[/color][/color]" % [
		int(Game.codex_bonus_each() * 100), Game.relic_codex.size(), RelicDB.RELICS.size(), codex_bonus], 13))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for id: String in RelicDB.RELICS:
		var d := RelicDB.get_def(id)
		var cell := PanelContainer.new()
		cell.add_theme_stylebox_override("panel", UI.box(Color("1e1418"), Color("3d2b2e") if not Game.relic_codex.has(id) else Color("8a5a2a"), 1, 0))
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		var ic := UI.icon(d["icon"], 2)
		if not Game.relic_codex.has(id):
			ic.modulate = Color(0, 0, 0, 0.6)
			cell.tooltip_text = "???"
		else:
			cell.tooltip_text = "%s (%s)\n%s" % [d["name"], d.get("rarity", ""), d["desc"]]
		cell.add_child(ic)
		grid.add_child(cell)
	_archive_list.add_child(grid)
	_archive_list.add_child(UI.spacer(8))
	_archive_list.add_child(UI.label("Códice de Maestría", 18, Color("ffb0ff")))
	_archive_list.add_child(UI.rich("[color=#a08878]Cada vez que quemas una carta en la Torre gana Maestría (para siempre). Cada nivel: [color=#ffd36a]+10%[/color] a sus números y [color=#ffd36a]+20%[/color] Ascuas al quemarla.[/color]", 13))
	var packs := Game.card_packs()
	var ids: Array[String] = []
	for id in CardDB.collectible_ids():
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ma := Game.mastery.get(a, 0) as int
		var mb := Game.mastery.get(b, 0) as int
		if ma != mb:
			return ma > mb
		return a < b)
	for id in ids:
		var d2 := CardDB.get_def(id)
		var known: bool = packs.has(d2["pack"])
		var row := UI.hbox(6)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var ic2 := UI.icon(d2["icon"], 2)
		if not known:
			ic2.modulate = Color(0, 0, 0, 0.5)
		row.add_child(ic2)
		var nl := UI.label(d2["name"] if known else "???", 14, UI.TEXT if known else UI.DIM)
		nl.custom_minimum_size.x = 170
		nl.clip_text = true
		row.add_child(nl)
		var lvl := Game.mastery_level(id)
		var pips := ""
		for i in Game.MASTERY_MAX:
			pips += "◆" if i < lvl else "◇"
		var pl := UI.label(pips, 13, Color("ff8ad8") if lvl >= Game.MASTERY_MAX else Color("ffb43a"))
		row.add_child(pl)
		var prog := Game.mastery_progress(id)
		var xl := UI.label("%d/%d" % [prog.x, prog.y] if lvl < Game.MASTERY_MAX else "MÁX", 11, UI.DIM)
		row.add_child(xl)
		if known:
			row.tooltip_text = "%s\n%s" % [d2["name"], CardDB.describe_plain(Card.new(id))]
		_archive_list.add_child(row)


func _build_chronicle() -> void:
	UI.clear(_chronicle_list)
	var done := Game.hitos.size()
	_chronicle_list.add_child(UI.label("Crónica de la Fogonera", 18, UI.EMBER))
	_chronicle_list.add_child(UI.rich("[color=#a08878]Hitos completados: [color=#ffd36a]%d / %d[/color]. Cada hito da una recompensa única al cumplirse.[/color]" % [done, ForgeDB.HITOS.size()], 13))
	for h in ForgeDB.HITOS:
		var claimed := Game.hitos.has(h["id"])
		var row := UI.panel(Color("1e1418") if not claimed else Color("2a2014"), Color("3d2b2e") if not claimed else Color("8a6a2a"))
		var v := UI.vbox(2)
		row.add_child(v)
		var top := UI.hbox(6)
		top.add_child(UI.icon("star" if claimed else "unknown", 2))
		var nl := UI.label(h["name"], 15, UI.EMBER if claimed else UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nl)
		top.add_child(UI.label(Game.hito_reward_text(h), 12, Color("d0a8ff") if h.has("dust") else UI.EMBER))
		v.add_child(top)
		v.add_child(UI.label(h["desc"], 12, UI.DIM))
		if not claimed:
			var cur := Game.stat_value(h["stat"])
			var goal := float(h["goal"])
			var bar := ProgressBar.new()
			bar.custom_minimum_size = Vector2(340, 8)
			bar.max_value = goal
			bar.value = minf(cur, goal)
			bar.show_percentage = false
			bar.add_theme_stylebox_override("background", UI.box(Color("120a0c"), Color("3d2b2e"), 1, 0))
			bar.add_theme_stylebox_override("fill", UI.box(Color("c25a1a"), Color("c25a1a"), 0, 0))
			v.add_child(bar)
			v.add_child(UI.label("%s / %s" % [Num.fmt(cur), Num.fmt(goal)], 11, UI.DIM))
		_chronicle_list.add_child(row)


func _build_rebirth() -> void:
	UI.clear(_rebirth_box)
	_talent_rows.clear()
	_rebirth_box.add_child(UI.label("Renacer en Ceniza", 20, Color("d0b0ff")))
	_rebirth_box.add_child(UI.rich("[color=#a08878]Reinicia Ascuas y generadores (¡y sus Resonancias!) a cambio de [color=#d0b0ff]Polvo Estelar[/color]. Conservas Arsenal, Grimorios, Maestría, Reliquario y Braseros. Cada Polvo ganado da +10% de producción para siempre.[/color]", 13))
	var gain_l := UI.rich("", 15)
	gain_l.name = "Gain"
	_rebirth_box.add_child(gain_l)
	var rb := UI.button("RENACER", func() -> void:
		var gain := Game.rebirth_gain()
		if gain < 1:
			Sfx.play("deny")
			return
		main.modal("¿Renacer en Ceniza?", "Perderás tus Ascuas, generadores y Resonancias.\nObtendrás [color=#d0b0ff]%d Polvo Estelar[/color]." % gain,
			[["Renacer", func() -> void:
				if Game.run != null:
					Game.end_run()
				Game.rebirth()
				Sfx.play("rebirth")
				main.shake(12.0)
				main.go("forge")], ["Todavía no", func() -> void: pass]]), 18)
	rb.name = "RebirthBtn"
	rb.custom_minimum_size = Vector2(360, 48)
	_rebirth_box.add_child(rb)
	_rebirth_box.add_child(UI.spacer(6))
	_rebirth_box.add_child(UI.label("Talentos", 18, Color("d0b0ff")))
	for t in ForgeDB.TALENTS:
		var row := UI.panel(Color("1a1420"), Color("3d2b4e"))
		var h := UI.hbox(8)
		row.add_child(h)
		h.add_child(UI.icon("star", 3))
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UI.label(t["name"], 15))
		var d := UI.rich("[color=#a08878]%s[/color]" % t["desc"], 12)
		d.custom_minimum_size.x = 180
		info.add_child(d)
		h.add_child(info)
		var id: String = t["id"]
		var btn := UI.button("", func() -> void:
			if Game.buy_talent(id):
				Sfx.play("rebirth", 0.0, -6.0)
			else:
				Sfx.play("deny"), 14)
		btn.custom_minimum_size = Vector2(90, 44)
		h.add_child(btn)
		_rebirth_box.add_child(row)
		_talent_rows.append({"t": t, "btn": btn})


# --- Refresco -------------------------------------------------------------

func _on_forge_changed() -> void:
	_refresh_all()


func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 0.2:
		_tick = 0.0
		_refresh_dynamic()


func _refresh_all() -> void:
	_refresh_dynamic()


func _refresh_dynamic() -> void:
	var heat := clampf(log(maxf(Game.production(), 1.0)) / log(10.0) / 8.0, 0.0, 1.0)
	var lvl := clampi(int(heat * 4.0), 0, 4)
	if lvl != _heat_lvl:
		_heat_lvl = lvl
		_furnace_icon.texture = Art.forge_sprite(heat)
		_furnace_halo.modulate.a = 0.3 + 0.1 * lvl
	_mode_btn.text = "Comprar: " + ("Máx" if Game.buy_mode < 0 else "x%d" % Game.buy_mode)
	_click_label.text = "Clic en el horno: +%s Ascuas" % Num.fmt(Game.click_value())
	for r in _gen_rows:
		var g: Dictionary = r["g"]
		var owned := Game.gen_count(g["id"])
		var visible_now := Game.generator_visible(r["index"])
		var row: Control = r["row"]
		row.visible = visible_now or r["index"] <= _first_hidden_index()
		var name_l: Label = r["name"]
		name_l.text = g["name"] if visible_now else "???"
		var n := Game.buy_amount_for(g)
		var cost := Game.gen_cost(g, n)
		var btn: Button = r["btn"]
		btn.text = "+%d\n%s" % [n, Num.fmt(cost)]
		btn.disabled = Game.embers < cost or not visible_now
		var next_m := 0
		for m in ForgeDB.MILESTONES:
			if owned < m:
				next_m = m
				break
		(r["count"] as Label).text = "Tienes %d" % owned + ("   ·   próximo ×2 a %d" % next_m if next_m > 0 else "")
		(r["rate"] as Label).text = "+%s/s" % Num.fmt(Game.generator_rate(g)) if owned > 0 else ""
		var pips: HBoxContainer = r["pips"]
		pips.visible = visible_now
		for pip: PanelContainer in pips.get_children():
			var tier: int = pip.get_meta("tier")
			var th := Game.resonance_threshold(tier)
			var on := owned >= th
			pip.add_theme_stylebox_override("panel", UI.box(Color("3a2250") if on else Color("1a1218"), Color("b07ae0") if on else Color("3d2b4e"), 1, 0))
			var pl: Label = pip.get_child(0)
			pl.text = ("◆ " if on else "◇ ") + str(th)
			pl.add_theme_color_override("font_color", Color("e0c8ff") if on else Color("7a6a8a"))
	for r in _arsenal_rows:
		var a: Dictionary = r["a"]
		var lvl2 := Game.arsenal_level(a["id"])
		var btn: Button = r["btn"]
		(r["lvl"] as Label).text = "Nivel %d / %d" % [lvl2, a["max"]]
		if lvl2 >= int(a["max"]):
			btn.text = "MÁX"
			btn.disabled = true
		else:
			var c := ForgeDB.arsenal_cost(a, lvl2)
			btn.text = Num.fmt(c)
			btn.disabled = Game.embers < c
	for r in _grim_rows:
		var g: Dictionary = r["g"]
		var btn: Button = r["btn"]
		if Game.grimoires.has(g["id"]):
			btn.text = "Aprendido"
			btn.disabled = true
		else:
			btn.text = Num.fmt(g["cost"])
			btn.disabled = Game.embers < float(g["cost"])
	for r in _talent_rows:
		var t: Dictionary = r["t"]
		var btn: Button = r["btn"]
		if Game.talents.has(t["id"]):
			btn.text = "Activo"
			btn.disabled = true
		else:
			btn.text = "%d ★" % t["cost"]
			btn.disabled = Game.stardust < float(t["cost"])
	var gain := Game.rebirth_gain()
	var gain_l := _rebirth_box.get_node_or_null("Gain") as RichTextLabel
	if gain_l != null:
		gain_l.text = "Ascuas en esta vida: [color=#ffd36a]%s[/color]\nRenacer ahora: [color=#d0b0ff]+%d Polvo[/color]%s" % [
			Num.fmt(Game.life_embers), gain, "" if gain >= 1 else "  [color=#806860](necesitas 1M de Ascuas en esta vida)[/color]"]
	var rb := _rebirth_box.get_node_or_null("RebirthBtn") as Button
	if rb != null:
		rb.disabled = gain < 1
	var base := 0.0
	for g in ForgeDB.GENERATORS:
		base += float(g["rate"]) * Game.gen_count(g["id"]) * ForgeDB.milestone_mult(Game.gen_count(g["id"]))
	_breakdown.text = "[color=#a08878]Producción[/color]\nBase: [color=#ffd36a]%s/s[/color]\n× Braseros (%d): [color=#ffd36a]×%.1f[/color]\n× Polvo Estelar (%s): [color=#d0b0ff]×%.1f[/color]\n× Reliquario (%d): [color=#ffd36a]×%.2f[/color]\n= [color=#ffb43a]%s/s[/color]\n[color=#806860]Resonancias activas: %d · Maestrías: %d · Hitos: %d/%d\nAscensiones: %d · Renacimientos: %d[/color]" % [
		Num.fmt(base), Game.max_floor, 1.0 + Game.BRAZIER_BONUS * Game.max_floor, Num.fmt(Game.stardust_total),
		1.0 + Game.STARDUST_BONUS * Game.stardust_total, Game.relic_codex.size(), Game.codex_mult(), Num.fmt(Game.production()),
		Game.perk_ids().size(), Game.mastered_count(1), Game.hitos.size(), ForgeDB.HITOS.size(), Game.runs_started, Game.rebirths]


func _first_hidden_index() -> int:
	for i in ForgeDB.GENERATORS.size():
		if not Game.generator_visible(i):
			return i
	return ForgeDB.GENERATORS.size()
