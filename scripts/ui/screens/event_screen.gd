extends Screen
## Misterios y tesoros: decisiones narrativas cortas con consecuencias mecánicas.

var run: RunState
var _text: RichTextLabel
var _buttons: VBoxContainer
var _art: TextureRect


func build() -> void:
	run = Game.run
	var bg := UI.tex_rect(Art.background(EnemyDB.act_index(run.floor_num), run.floor_num + 13, EnemyDB.cycle(run.floor_num)), 4.0)
	bg.modulate = Color(0.45, 0.4, 0.5)
	add_child(bg)
	var p := UI.panel(Color(0.1, 0.07, 0.09, 0.95), UI.PURPLE.darkened(0.3))
	p.position = Vector2(290, 110)
	p.custom_minimum_size = Vector2(700, 520)
	add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var title := UI.label("", 34, UI.PURPLE.lightened(0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_art = UI.icon("eye", 10)
	_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_art)
	_text = UI.rich("", 18)
	_text.custom_minimum_size = Vector2(660, 90)
	v.add_child(_text)
	_buttons = UI.vbox(10)
	v.add_child(_buttons)

	if args.get("type", "event") == "treasure":
		title.text = "Tesoro"
		_treasure()
		return
	var events := ["altar", "smith", "well", "mirror", "merchant"]
	var ev: String = events[run.rng.randi_range(0, events.size() - 1)]
	match ev:
		"altar":
			title.text = "Altar de Ceniza"
			_art.texture = Art.icon("skull")
			var cost := maxi(6, run.max_hp / 8)
			_show("Un altar tibio exige sangre. Bajo la ceniza, algo brilla.", [
				["Sangrar (−%d PV): obtén una reliquia" % cost, func() -> void:
					run.hp = maxi(1, run.hp - cost)
					var r := RelicDB.random_unowned(run.relics, run.rng)
					run.add_relic(r)
					Sfx.play("buff")
					_result("El altar acepta tu ofrenda. Obtienes [color=#ffd36a]%s[/color]." % RelicDB.get_def(r)["name"])],
				["Marcharse", _leave]])
		"smith":
			title.text = "Herrero Errante"
			_art.texture = Art.icon("anvil")
			_show("Un herrero sin rostro golpea un yunque que no existe. Te ofrece su martillo.", [
				["Mejorar 2 cartas al azar", func() -> void:
					var ups: Array = run.deck.filter(func(c: Card) -> bool: return c.can_upgrade())
					ups.shuffle()
					var names: PackedStringArray = []
					for i in mini(2, ups.size()):
						(ups[i] as Card).upgraded = true
						names.append((ups[i] as Card).title())
					Sfx.play("buy")
					_result("Templadas: [color=#ffd36a]%s[/color]." % ", ".join(names) if not names.is_empty() else "No había nada que templar.")],
				["Marcharse", _leave]])
		"well":
			title.text = "Pozo de Brasas"
			_art.texture = Art.icon("flame")
			var heal := int(run.max_hp * 0.25)
			var embers := Game.production() * 60.0 + 30.0 * Game.floor_factor(run.floor_num)
			_show("Un pozo lleno de brasas líquidas. Su calor promete vida… o riqueza.", [
				["Beber (cura %d PV)" % heal, func() -> void:
					run.heal(heal)
					Sfx.play("heal")
					_result("El fuego te recorre. Te sientes renovada.")],
				["Recoger brasas (+%s Ascuas)" % Num.fmt(embers), func() -> void:
					Game.gain_tower_embers(embers, "event")
					main.fly_embers(Vector2(640, 300), 10)
					_result("Tu forja lejana ruge de alegría.")]])
		"mirror":
			title.text = "Espejo Fundido"
			_art.texture = Art.icon("drop")
			_show("Un espejo de metal líquido refleja tu mazo. Puedes meter la mano.", [
				["Duplicar una carta", func() -> void:
					main.pick_card("Elige una carta para duplicar", run.deck, func(c: Variant) -> void:
						if c == null:
							return
						run.deck.append((c as Card).duplicate_card())
						Sfx.play("buy")
						_result("El espejo devuelve una copia perfecta."))],
				["Marcharse", _leave]])
		"merchant":
			title.text = "Mercader de Humo"
			_art.texture = Art.icon("smoke")
			_show("«Dame algo tuyo y te daré algo raro.» Su sonrisa se disuelve en el aire.", [
				["Cambiar una carta al azar por una rara", func() -> void:
					var pool := CardDB.ids_in_packs(Game.card_packs(), "rare")
					if run.deck.size() > 1 and not pool.is_empty():
						var old: Card = run.deck[run.rng.randi_range(0, run.deck.size() - 1)]
						run.deck.erase(old)
						var nc := Card.new(pool[run.rng.randi_range(0, pool.size() - 1)])
						run.deck.append(nc)
						_result("Pierdes [color=#ff8a7a]%s[/color]. Obtienes [color=#ffd36a]%s[/color]." % [old.title(), nc.title()])
					else:
						_result("El mercader se aburre y desaparece.")],
				["Marcharse", _leave]])


func _treasure() -> void:
	_art.texture = Art.icon("chest")
	var r := RelicDB.random_unowned(run.relics, run.rng)
	var embers := Game.production() * 30.0 + 40.0 * Game.floor_factor(run.floor_num)
	run.add_relic(r)
	Game.gain_tower_embers(embers, "treasure")
	Sfx.play("coin")
	main.fly_embers(Vector2(640, 300), 10)
	var txt := "Un cofre olvidado por otro ascendente.\n+%s Ascuas." % Num.fmt(embers)
	if r != "":
		var rd := RelicDB.get_def(r)
		txt += "\nReliquia: [color=#ffd36a]%s[/color] — %s" % [rd["name"], rd["desc"]]
	_show(txt, [["Continuar", _leave]])


func _show(text: String, options: Array) -> void:
	_text.text = "[center]%s[/center]" % text
	UI.clear(_buttons)
	for o: Array in options:
		var b := UI.button(o[0], o[1], 18)
		b.custom_minimum_size = Vector2(660, 46)
		_buttons.add_child(b)


func _result(text: String) -> void:
	_show(text, [["Continuar", _leave]])


func _leave() -> void:
	main.go("map")
