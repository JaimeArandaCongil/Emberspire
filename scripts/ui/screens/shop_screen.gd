extends Screen
## Yunque Errante: gasta Ascuas de la Forja durante la ascensión.
## Los precios escalan con tu producción: comprar aquí compite con invertir en la Forja.

const RARITY_SECS := {"common": 25.0, "uncommon": 45.0, "rare": 80.0}
const RARITY_BASE := {"common": 50.0, "uncommon": 90.0, "rare": 170.0}

var run: RunState
var _offers: Array[Card] = []
var _sold := {}
var _relic := ""
var _removed := false
var _upgraded := false
var _body: Control


func build() -> void:
	run = Game.run
	var bg := UI.tex_rect(Art.background(EnemyDB.act_index(run.floor_num), run.floor_num + 77, EnemyDB.cycle(run.floor_num)), 4.0)
	bg.modulate = Color(0.45, 0.42, 0.45)
	add_child(bg)
	_offers = run.roll_card_rewards(Game.card_packs(), 5, true)
	_relic = RelicDB.random_unowned(run.relics, run.rng)
	_body = Control.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_body)
	Game.embers_changed.connect(_on_embers)
	_rebuild()


func _on_embers(_v: float) -> void:
	# Refresco barato: sólo estados de botones.
	for b in get_tree().get_nodes_in_group("shop_buy"):
		var btn := b as Button
		btn.disabled = Game.embers < float(btn.get_meta("price")) or btn.get_meta("sold", false)


func _price(base: float, secs: float) -> float:
	return roundf(base * (1.0 + 0.15 * run.floor_num) + Game.production() * secs)


func _rebuild() -> void:
	UI.clear(_body)
	var title := UI.label("Yunque Errante", 40, Color("8ab4d0"))
	title.position = Vector2(0, 64)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(title)
	var sub := UI.label("«Todo se paga en Ascuas, forastera. Tu forja lo entiende.»", 16, UI.DIM)
	sub.position = Vector2(0, 112)
	sub.size = Vector2(1280, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(sub)

	var x := 640.0 - (5 * 150 + 4 * 40) * 0.5
	for i in _offers.size():
		var c := _offers[i]
		var rarity: String = c.def()["rarity"]
		var price := _price(RARITY_BASE.get(rarity, 60.0), RARITY_SECS.get(rarity, 30.0))
		var cv := CardView.new(c)
		cv.position = Vector2(x + i * 190, 150)
		cv.interactive = false
		_body.add_child(cv)
		if _sold.has(i):
			cv.modulate = Color(1, 1, 1, 0.25)
		var idx := i
		var b := _buy_button(price, func() -> void:
			run.deck.append(c)
			_sold[idx] = true
			_rebuild())
		b.position = Vector2(x + i * 190, 370)
		b.size = Vector2(150, 40)
		if _sold.has(i):
			b.text = "Vendida"
			b.set_meta("sold", true)
			b.disabled = true
		_body.add_child(b)

	var services := UI.hbox(24)
	services.position = Vector2(150, 450)
	services.size = Vector2(980, 160)
	services.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(services)
	var rm_price := _price(70.0, 30.0)
	services.add_child(_service("Fundir carta", "Elimina una carta del mazo.", "flame", rm_price, _removed, func() -> void:
		main.pick_card("Elige una carta para fundir", run.deck, func(c: Variant) -> void:
			if c == null:
				Game.embers += rm_price
				Game.embers_changed.emit(Game.embers)
				return
			run.deck.erase(c)
			_removed = true
			_rebuild())))
	var up_price := _price(60.0, 25.0)
	services.add_child(_service("Templar", "Mejora una carta.", "anvil", up_price, _upgraded, func() -> void:
		var ups: Array = run.deck.filter(func(c: Card) -> bool: return c.can_upgrade())
		main.pick_card("Elige una carta para templar", ups, func(c: Variant) -> void:
			if c == null:
				Game.embers += up_price
				Game.embers_changed.emit(Game.embers)
				return
			(c as Card).upgraded = true
			_upgraded = true
			_rebuild(), true, true)))
	if _relic != "":
		var rd := RelicDB.get_def(_relic)
		var r_price := _price(220.0, 90.0)
		services.add_child(_service(rd["name"], rd["desc"], rd["icon"], r_price, false, func() -> void:
			run.add_relic(_relic)
			_relic = ""
			_rebuild()))
	var leave := UI.button("Seguir subiendo", func() -> void: main.go("map"), 20)
	leave.position = Vector2(540, 640)
	leave.size = Vector2(200, 50)
	_body.add_child(leave)


func _buy_button(price: float, on_buy: Callable) -> Button:
	var b := Button.new()
	b.text = "%s Ascuas" % Num.fmt(price)
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("price", price)
	b.add_to_group("shop_buy")
	b.disabled = Game.embers < price
	b.pressed.connect(func() -> void:
		if Game.spend(price):
			Sfx.play("buy")
			on_buy.call()
		else:
			Sfx.play("deny"))
	return b


func _service(title: String, desc: String, icon_id: String, price: float, used: bool, on_buy: Callable) -> Control:
	var p := UI.panel(Color(0.12, 0.08, 0.09, 0.95))
	p.custom_minimum_size = Vector2(290, 160)
	var v := UI.vbox(6)
	p.add_child(v)
	var h := UI.hbox(8)
	h.add_child(UI.icon(icon_id, 3))
	h.add_child(UI.label(title, 18, UI.EMBER))
	v.add_child(h)
	var d := UI.rich(desc, 14)
	d.custom_minimum_size = Vector2(260, 40)
	v.add_child(d)
	var b := _buy_button(price, on_buy)
	if used:
		b.text = "Agotado"
		b.set_meta("sold", true)
		b.disabled = true
	v.add_child(b)
	return p
