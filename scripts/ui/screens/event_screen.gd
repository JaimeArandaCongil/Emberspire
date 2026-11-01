extends Screen
## Misterios y tesoros: decisiones narrativas cortas con consecuencias mecánicas.
## Muchos cruzan la Torre con la Forja (Maestría, Ascuas, Polvo Estelar). No se repiten en una ascensión.

const EVENTS := ["altar", "smith", "well", "mirror", "merchant", "forge_spirit", "gambler", "hollow_shrine",
	"frozen_traveller", "library", "anvil_trial", "wind_bellows", "star_fall", "coal_mine", "tinkerer", "burning_bridge"]

var run: RunState
var _text: RichTextLabel
var _buttons: VBoxContainer
var _art: TextureRect
var _title: Label


func build() -> void:
	run = Game.run
	var bg := UI.tex_rect(Art.background(EnemyDB.act_index(run.floor_num), run.floor_num + 13, EnemyDB.cycle(run.floor_num)), 4.0)
	bg.modulate = Color(0.45, 0.4, 0.5)
	add_child(bg)
	add_child(UI.dust(Rect2(0, 60, 1280, 660), Color("d0a8ff"), 20))
	var p := UI.panel(Color(0.1, 0.07, 0.09, 0.95), UI.PURPLE.darkened(0.3))
	p.position = Vector2(290, 100)
	p.custom_minimum_size = Vector2(700, 540)
	add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	_title = UI.label("", 34, UI.PURPLE.lightened(0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	var art_holder := Control.new()
	art_holder.custom_minimum_size = Vector2(660, 120)
	v.add_child(art_holder)
	var halo := UI.halo(Color("b07ae0"), 90.0, 0.35)
	halo.position = Vector2(330, 60) - halo.size * 0.5
	art_holder.add_child(halo)
	_art = UI.icon("eye", 10)
	_art.position = Vector2(330 - 60, 0)
	_art.pivot_offset = Vector2(60, 60)
	art_holder.add_child(_art)
	var tw := _art.create_tween().set_loops()
	tw.tween_property(_art, "position:y", -6.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_art, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	_text = UI.rich("", 18)
	_text.custom_minimum_size = Vector2(660, 90)
	v.add_child(_text)
	_buttons = UI.vbox(10)
	v.add_child(_buttons)

	if args.get("type", "event") == "treasure":
		_title.text = "Tesoro"
		_treasure()
		return
	var pool: Array = []
	for e: String in EVENTS:
		if not run.seen_events.has(e):
			pool.append(e)
	if pool.is_empty():
		run.seen_events.clear()
		pool = EVENTS.duplicate()
	var ev: String = pool[run.rng.randi_range(0, pool.size() - 1)]
	run.seen_events.append(ev)
	call("_ev_" + ev)


func _set_art(id: String) -> void:
	_art.texture = Art.icon(id)


# --- Misterios --------------------------------------------------------------

func _ev_altar() -> void:
	_title.text = "Altar de Ceniza"
	_set_art("skull")
	var cost := maxi(6, run.max_hp / 8)
	_show("Un altar tibio exige sangre. Bajo la ceniza, algo brilla.", [
		["Sangrar (−%d PV): obtén una reliquia" % cost, func() -> void:
			run.hp = maxi(1, run.hp - cost)
			var r := RelicDB.random_unowned(run.relics, run.rng)
			run.add_relic(r)
			Sfx.play("buff")
			_result("El altar acepta tu ofrenda. Obtienes [color=#ffd36a]%s[/color]." % RelicDB.get_def(r)["name"])],
		["Marcharse", _leave]])


func _ev_smith() -> void:
	_title.text = "Herrero Errante"
	_set_art("anvil")
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


func _ev_well() -> void:
	_title.text = "Pozo de Brasas"
	_set_art("flame")
	var heal := int(run.max_hp * 0.25)
	var embers := Game.production() * 30.0 + 30.0 * Game.floor_factor(run.floor_num)
	_show("Un pozo lleno de brasas líquidas. Su calor promete vida… o riqueza.", [
		["Beber (cura %d PV)" % heal, func() -> void:
			run.heal(heal)
			Sfx.play("heal")
			_result("El fuego te recorre. Te sientes renovada.")],
		["Recoger brasas (+%s Ascuas)" % Num.fmt(embers), func() -> void:
			Game.gain_tower_embers(embers, "event")
			main.fly_embers(Vector2(640, 300), 10)
			_result("Tu forja lejana ruge de alegría.")]])


func _ev_mirror() -> void:
	_title.text = "Espejo Fundido"
	_set_art("lens")
	_show("Un espejo de metal líquido refleja tu mazo. Puedes meter la mano.", [
		["Duplicar una carta", func() -> void:
			main.pick_card("Elige una carta para duplicar", run.deck, func(c: Variant) -> void:
				if c == null:
					return
				run.deck.append((c as Card).duplicate_card())
				Sfx.play("buy")
				_result("El espejo devuelve una copia perfecta."))],
		["Marcharse", _leave]])


func _ev_merchant() -> void:
	_title.text = "Mercader de Humo"
	_set_art("smoke")
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


func _ev_forge_spirit() -> void:
	_title.text = "Espíritu de la Forja"
	_set_art("furnace")
	var cost := maxf(Game.embers * 0.25, 50.0 * Game.floor_factor(run.floor_num))
	var can := Game.embers >= cost
	_show("Una figura de humo con tu misma cara. «Paga con el calor que guardas abajo y enseñaré a una de tus cartas a arder mejor.»", [
		["Pagar %s Ascuas: una carta gana 1 nivel de Maestría%s" % [Num.fmt(cost), "" if can else " (no te alcanza)"], func() -> void:
			if not Game.spend(cost):
				Sfx.play("deny")
				return
			var ups: Array = run.deck.filter(func(c: Card) -> bool: return not (c.rarity() in ["status", "token"]) and c.mastery() < Game.MASTERY_MAX)
			main.pick_card("Elige una carta para instruir", ups, func(c: Variant) -> void:
				if c == null:
					Game.refund(cost)
					return
				var card := c as Card
				var lvl := card.mastery()
				var need: int = Game.MASTERY_XP[lvl] - int(Game.mastery.get(card.id, 0))
				Game.add_mastery(card.id, need)
				Sfx.play("rebirth")
				_result("[color=#ffb0ff]%s[/color] alcanza Maestría %d. Recordará este fuego para siempre." % [CardDB.get_def(card.id)["name"], card.mastery()]))],
		["Marcharse", _leave]])


func _ev_gambler() -> void:
	_title.text = "Jugador de Ascuas"
	_set_art("coin")
	var bet := maxf(Game.embers * 0.2, 20.0)
	_show("Un diablillo lanza una brasa al aire. «Seis de cada diez veces gano yo… o eso dicen. Si ganas tú, te llevas casi el doble.»", [
		["Apostar %s Ascuas (60%%: recibes ×1.8)" % Num.fmt(bet), func() -> void:
			if not Game.spend(bet):
				Sfx.play("deny")
				return
			if run.rng.randf() < 0.6:
				Game.refund(bet * 1.8)
				main.fly_embers(Vector2(640, 300), 12)
				Sfx.play("coin")
				_result("¡Cara! Recibes [color=#ffd36a]%s[/color] Ascuas." % Num.fmt(bet * 1.8))
			else:
				Sfx.play("defeat")
				_result("Cruz. El diablillo se ríe y desaparece con tus Ascuas.")],
		["No juego con fuego (marcharse)", _leave]])


func _ev_hollow_shrine() -> void:
	_title.text = "Santuario Hueco"
	_set_art("candle")
	_show("Velas que no queman. Una voz pide que dejes algo atrás… o que cargues con algo nuevo.", [
		["Dejar atrás una carta (eliminarla)", func() -> void:
			main.pick_card("Elige una carta para dejar en el santuario", run.deck, func(c: Variant) -> void:
				if c == null:
					return
				run.deck.erase(c)
				Sfx.play("burn")
				_result("El santuario guarda [color=#ff8a7a]%s[/color]. Tu mazo pesa menos." % (c as Card).title()))],
		["Cargar Ceniza Húmeda: obtén una reliquia", func() -> void:
			run.deck.append(Card.new("wet_ash"))
			var r := RelicDB.random_unowned(run.relics, run.rng)
			run.add_relic(r)
			Sfx.play("buff")
			_result("Una Ceniza Húmeda entra en tu mazo. A cambio: [color=#ffd36a]%s[/color]." % RelicDB.get_def(r)["name"])],
		["Marcharse", _leave]])


func _ev_frozen_traveller() -> void:
	_title.text = "Viajera Congelada"
	_set_art("snowflake")
	var loot := Game.production() * 45.0 + 40.0 * Game.floor_factor(run.floor_num)
	_show("Una ascendente medio congelada abraza su mochila. Aún respira.", [
		["Darle calor (−8 PV): te regala una carta rara", func() -> void:
			run.hp = maxi(1, run.hp - 8)
			var pool := CardDB.ids_in_packs(Game.card_packs(), "rare")
			if pool.is_empty():
				pool = CardDB.ids_in_packs(Game.card_packs())
			var nc := Card.new(pool[run.rng.randi_range(0, pool.size() - 1)])
			run.deck.append(nc)
			Sfx.play("heal")
			_result("Despierta y te da las gracias con [color=#ffd36a]%s[/color]." % nc.title())],
		["Saquear su mochila (+%s Ascuas, +1 Escarcha)" % Num.fmt(loot), func() -> void:
			Game.gain_tower_embers(loot, "event")
			run.deck.append(Card.new("frost"))
			main.fly_embers(Vector2(640, 300), 10)
			_result("El frío de su mochila se te mete en el mazo.")],
		["Marcharse", _leave]])


func _ev_library() -> void:
	_title.text = "Biblioteca Calcinada"
	_set_art("book")
	var heal := int(run.max_hp * 0.2)
	_show("Estanterías de ceniza. Tres tomos han sobrevivido al fuego.", [
		["Estudiar: elige 1 de 3 cartas raras", func() -> void:
			var pool := CardDB.ids_in_packs(Game.card_packs(), "rare")
			if pool.is_empty():
				pool = CardDB.ids_in_packs(Game.card_packs())
			var offer: Array = []
			for i in 3:
				offer.append(Card.new(pool[run.rng.randi_range(0, pool.size() - 1)]))
			main.pick_card("Elige un tomo", offer, func(c: Variant) -> void:
				if c == null:
					return
				run.deck.append(c)
				Sfx.play("buy")
				_result("Aprendes [color=#ffd36a]%s[/color]." % (c as Card).title()), false)],
		["Leer en silencio (cura %d PV)" % heal, func() -> void:
			run.heal(heal)
			Sfx.play("heal")
			_result("Las palabras antiguas te calman.")]])


func _ev_anvil_trial() -> void:
	_title.text = "Prueba del Yunque"
	_set_art("sledge")
	_show("Un yunque gigantesco bloquea el paso. Grabado: «Sólo quien vence a un campeón cruza con honor».", [
		["Aceptar la prueba (combate de élite)", func() -> void:
			main.go("combat", {"kind": "elite"})],
		["Rodearlo (marcharse)", _leave]])


func _ev_wind_bellows() -> void:
	_title.text = "Viento del Fuelle"
	_set_art("wind")
	_show("Una corriente sopla desde la Forja lejana. Arrastra lo viejo y trae lo nuevo.", [
		["Transformar hasta 2 Golpes/Defensas en cartas aleatorias", func() -> void:
			var basics: Array = run.deck.filter(func(c: Card) -> bool: return c.id == "strike" or c.id == "defend")
			basics.shuffle()
			var ids := CardDB.ids_in_packs(Game.card_packs())
			var names: PackedStringArray = []
			for i in mini(2, basics.size()):
				run.deck.erase(basics[i])
				var nc := Card.new(ids[run.rng.randi_range(0, ids.size() - 1)])
				run.deck.append(nc)
				names.append(nc.title())
			Sfx.play("buy")
			_result("El viento te trae: [color=#ffd36a]%s[/color]." % (", ".join(names) if not names.is_empty() else "nada"))],
		["Marcharse", _leave]])


func _ev_star_fall() -> void:
	_title.text = "Lluvia de Estrellas"
	_set_art("star")
	_show("Por una grieta del techo cae polvo luminoso. Recogerlo quema la piel.", [
		["Recoger el polvo: +1 Polvo Estelar, −6 PV máximos", func() -> void:
			Game.add_stardust(1)
			run.max_hp = maxi(10, run.max_hp - 6)
			run.hp = mini(run.hp, run.max_hp)
			Sfx.play("rebirth")
			_result("Tu Forja brilla un 10% más para siempre. Tu cuerpo, algo menos.")],
		["Contemplarlo (cura 10 PV)", func() -> void:
			run.heal(10)
			Sfx.play("heal")
			_result("Una calma antigua te envuelve.")]])


func _ev_coal_mine() -> void:
	_title.text = "Veta de Carbón"
	_set_art("coal")
	var embers := Game.production() * 30.0 + 40.0 * Game.floor_factor(run.floor_num)
	_show("Una veta negra recorre el muro. Puedes llevártela al mazo… o enviarla a la Forja.", [
		["Excavar: añade 2 Carbón a tu mazo", func() -> void:
			run.deck.append(Card.new("coal"))
			run.deck.append(Card.new("coal"))
			Sfx.play("buy")
			_result("Combustible para el camino.")],
		["Enviarla a la Forja (+%s Ascuas)" % Num.fmt(embers), func() -> void:
			Game.gain_tower_embers(embers, "event")
			main.fly_embers(Vector2(640, 300), 10)
			_result("La Forja se lo traga entero.")]])


func _ev_tinkerer() -> void:
	_title.text = "Hojalatera"
	_set_art("tongs")
	_show("Una anciana con mil herramientas. «Tus combustibles arden mal. Déjame verlos.»", [
		["Mejorar todo tu Combustible", func() -> void:
			var n := 0
			for c in run.deck:
				if c.type() == "fuel" and c.can_upgrade():
					c.upgraded = true
					n += 1
			if n == 0:
				var k := Card.new("kindling", true)
				run.deck.append(k)
				_result("No llevas combustible. Te regala una [color=#ffd36a]Leña+[/color].")
			else:
				_result("%d carta%s de Combustible mejorada%s." % [n, "" if n == 1 else "s", "" if n == 1 else "s"])
			Sfx.play("buy")],
		["Marcharse", _leave]])


func _ev_burning_bridge() -> void:
	_title.text = "Puente en Llamas"
	_set_art("fire_wall")
	var dmg := int(run.max_hp * 0.15)
	var embers := Game.burn_value(2, 3, run.floor_num)
	_show("El único puente arde. Cruzar corriendo duele; apagarlo cuesta algo de tu mazo.", [
		["Cruzar corriendo (−%d PV)" % dmg, func() -> void:
			run.hp = maxi(1, run.hp - dmg)
			Sfx.play("hit")
			main.shake(6.0)
			_result("Llegas al otro lado chamuscada.")],
		["Sofocarlo con una carta (la pierdes, +%s Ascuas)" % Num.fmt(embers), func() -> void:
			main.pick_card("Elige una carta para sofocar el fuego", run.deck, func(c: Variant) -> void:
				if c == null:
					return
				run.deck.erase(c)
				Game.gain_tower_embers(embers, "event")
				main.fly_embers(Vector2(640, 300), 8)
				Sfx.play("burn")
				_result("[color=#ff8a7a]%s[/color] se convierte en vapor. El puente queda libre." % (c as Card).title()), false)]])


## Tesoro con precio: el cofre está cerrado y abrirlo cuesta algo.
func _treasure() -> void:
	_set_art("chest")
	var cost_hp := maxi(4, int(run.max_hp * 0.10))
	_show("Un cofre de hierro sellado por otro ascendente. La cerradura aún está caliente.", [
		["Forzarlo (−%d PV)" % cost_hp, func() -> void:
			run.hp = maxi(1, run.hp - cost_hp)
			Sfx.play("hit")
			_open_chest()],
		["Fundir la cerradura: quema una carta de tu mazo para siempre", func() -> void:
			main.pick_card("Elige la carta que fundirá la cerradura", run.deck, func(c: Variant) -> void:
				if c == null:
					return
				run.deck.erase(c)
				Sfx.play("burn")
				_open_chest())],
		["Dejarlo", _leave]])


func _open_chest() -> void:
	var r := RelicDB.random_unowned(run.relics, run.rng)
	var embers := Game.production() * 15.0 + 40.0 * Game.floor_factor(run.floor_num)
	run.add_relic(r)
	Game.gain_tower_embers(embers, "treasure")
	Sfx.play("coin")
	main.fly_embers(Vector2(640, 300), 10)
	var txt := "El cofre cede.\n+%s Ascuas." % Num.fmt(embers)
	if r != "":
		var rd := RelicDB.get_def(r)
		txt += "\nReliquia: [color=#ffd36a]%s[/color] — %s" % [rd["name"], rd["desc"]]
	_show(txt, [["Continuar", _leave]])


func _show(text: String, options: Array) -> void:
	_text.text = "[center]%s[/center]" % text
	UI.clear(_buttons)
	for o: Array in options:
		var b := UI.button(o[0], o[1], 17)
		b.custom_minimum_size = Vector2(660, 46)
		_buttons.add_child(b)


func _result(text: String) -> void:
	_show(text, [["Continuar", _leave]])


func _leave() -> void:
	main.go("map")
