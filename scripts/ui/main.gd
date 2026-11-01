extends Control
## Raíz del juego: gestor de pantallas, HUD persistente, modales, toasts y efectos globales.

const SCREENS := {
	"title": preload("res://scripts/ui/screens/title_screen.gd"),
	"forge": preload("res://scripts/ui/screens/forge_screen.gd"),
	"antesala": preload("res://scripts/ui/screens/antesala_screen.gd"),
	"map": preload("res://scripts/ui/screens/map_screen.gd"),
	"combat": preload("res://scripts/ui/screens/combat_screen.gd"),
	"rest": preload("res://scripts/ui/screens/rest_screen.gd"),
	"shop": preload("res://scripts/ui/screens/shop_screen.gd"),
	"event": preload("res://scripts/ui/screens/event_screen.gd"),
	"summary": preload("res://scripts/ui/screens/summary_screen.gd"),
}

var screen_layer: Control
var hud: PanelContainer
var overlay_layer: Control
var fade: ColorRect
var current: Screen
var current_name := ""

var _embers_label: Label
var _rate_label: Label
var _brazier_label: Label
var _dust_label: Label
var _ember_icon: TextureRect
var _shake := 0.0
var _shown_embers := 0.0


func _ready() -> void:
	theme = UI.build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	screen_layer = Control.new()
	screen_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_layer)
	_build_hud()
	overlay_layer = Control.new()
	overlay_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_layer)
	fade = ColorRect.new()
	fade.color = Color(0.03, 0.02, 0.03, 1.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	Game.embers_gained.connect(_on_gain)
	Game.forge_changed.connect(_refresh_hud)
	Game.hito_unlocked.connect(_on_hito)
	_shown_embers = Game.embers
	go("title")


func go(screen_name: String, p_args: Dictionary = {}) -> void:
	var tw := create_tween()
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if current != null:
		tw.tween_property(fade, "color:a", 1.0, 0.18)
	tw.tween_callback(_swap.bind(screen_name, p_args))
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _swap(screen_name: String, p_args: Dictionary) -> void:
	if current != null:
		current.queue_free()
	UI.clear(overlay_layer)
	var s: Screen = SCREENS[screen_name].new()
	s.main = self
	s.args = p_args
	current = s
	current_name = screen_name
	screen_layer.add_child(s)
	hud.visible = screen_name != "title"
	match screen_name:
		"title", "forge", "summary": Sfx.music("forge")
		_: Sfx.music("tower")
	_refresh_hud()


# --- HUD ------------------------------------------------------------------

func _build_hud() -> void:
	hud = PanelContainer.new()
	hud.add_theme_stylebox_override("panel", UI.box(Color("1c1114"), Color("3d2b2e"), 0, 0))
	hud.position = Vector2.ZERO
	hud.size = Vector2(1280, 46)
	hud.custom_minimum_size = Vector2(1280, 46)
	add_child(hud)
	var row := UI.hbox(10)
	hud.add_child(row)
	_ember_icon = UI.icon("ember", 3)
	_ember_icon.pivot_offset = _ember_icon.custom_minimum_size * 0.5
	row.add_child(_ember_icon)
	_embers_label = UI.label("0", 26, UI.EMBER)
	_embers_label.custom_minimum_size.x = 120
	row.add_child(_embers_label)
	_rate_label = UI.label("", 16, UI.DIM)
	_rate_label.custom_minimum_size.x = 150
	row.add_child(_rate_label)
	row.add_child(UI.expand(UI.spacer()))
	row.add_child(UI.icon("flame", 2))
	_brazier_label = UI.label("", 16)
	_brazier_label.tooltip_text = "Braseros: cada piso récord alcanzado en la Torre\nmultiplica la producción de la Forja un +10%."
	_brazier_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_brazier_label)
	row.add_child(UI.spacer(0, 12))
	row.add_child(UI.icon("star", 2))
	_dust_label = UI.label("", 16, Color("d0b0ff"))
	_dust_label.tooltip_text = "Polvo Estelar (total ganado). Cada uno da +10% de producción.\nEl Polvo sin gastar compra Talentos."
	_dust_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_dust_label)
	row.add_child(UI.spacer(0, 12))
	var vol := UI.button("♪", func() -> void: _toggle_audio(), 16)
	vol.tooltip_text = "Silenciar / activar audio"
	vol.custom_minimum_size = Vector2(36, 32)
	row.add_child(vol)


func _toggle_audio() -> void:
	if Game.sfx_volume > 0.0 or Game.music_volume > 0.0:
		Game.sfx_volume = 0.0
		Game.music_volume = 0.0
		toast("Audio desactivado", UI.DIM)
	else:
		Game.sfx_volume = 0.8
		Game.music_volume = 0.5
		toast("Audio activado", UI.EMBER)
	Sfx.refresh_volume()


func _refresh_hud() -> void:
	_rate_label.text = "+%s/s" % Num.fmt(Game.production())
	_brazier_label.text = "%d  (+%d%%)" % [Game.max_floor, int(Game.BRAZIER_BONUS * 100 * Game.max_floor)]
	_dust_label.text = "%s  (%s)" % [Num.fmt(Game.stardust_total), Num.fmt(Game.stardust)]


func _process(delta: float) -> void:
	# Contador con "rodaje" suave.
	_shown_embers = lerpf(_shown_embers, Game.embers, minf(1.0, delta * 10.0))
	if absf(_shown_embers - Game.embers) < 0.5:
		_shown_embers = Game.embers
	_embers_label.text = Num.fmt(_shown_embers)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 40.0)
		screen_layer.position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		screen_layer.position = Vector2.ZERO
	if Engine.get_process_frames() % 30 == 0:
		_refresh_hud()


func _on_gain(_amount: float, _source: String) -> void:
	UI.punch(_ember_icon, 0.25)


func ember_target() -> Vector2:
	return _ember_icon.global_position + _ember_icon.size * 0.5


# --- Efectos globales -----------------------------------------------------

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Lanza chispas desde un punto hasta el contador de Ascuas.
func fly_embers(from: Vector2, count: int = 6) -> void:
	var target := ember_target()
	for i in count:
		var e := UI.icon("ember", 2)
		e.z_index = 200
		overlay_layer.add_child(e)
		e.position = from + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var mid := e.position.lerp(target, 0.5) + Vector2(randf_range(-120, 120), randf_range(60, 160))
		var tw := e.create_tween()
		var start := e.position
		tw.tween_interval(i * 0.04)
		var curve := func(t: float) -> void:
			var a := start.lerp(mid, t)
			var b := mid.lerp(target - e.size * 0.5, t)
			e.position = a.lerp(b, t)
		tw.tween_method(curve, 0.0, 1.0, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			UI.punch(_embers_label, 0.08)
			e.queue_free())


func _on_hito(h: Dictionary) -> void:
	Sfx.play("rebirth", 0.0, -3.0)
	toast("Hito: %s  ·  %s" % [h["name"], Game.hito_reward_text(h)], Color("d0a8ff") if h.has("dust") else UI.EMBER)


var _toast_slot := 0


func toast(text: String, color: Color = UI.TEXT) -> void:
	var p := UI.panel(Color("1e1216"), color.darkened(0.3))
	var l := UI.label(text, 18, color)
	p.add_child(l)
	overlay_layer.add_child(p)
	p.reset_size()
	# Los avisos simultáneos se apilan en lugar de taparse.
	var y := 60.0 + 48.0 * (_toast_slot % 4)
	_toast_slot += 1
	get_tree().create_timer(1.2).timeout.connect(func() -> void: _toast_slot = maxi(0, _toast_slot - 1))
	p.position = Vector2(640 - p.size.x * 0.5, y - 6)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(p, "position:y", y, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


## Ventana modal. `buttons`: Array de [texto, Callable]. Devuelve el nodo raíz.
func modal(title: String, body: String, buttons: Array, width: int = 520) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.02, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var p := UI.panel(Color("231619"), UI.EMBER.darkened(0.2))
	p.custom_minimum_size = Vector2(width, 0)
	root.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var t := UI.label(title, 28, UI.EMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := UI.rich(body, 17)
	b.custom_minimum_size = Vector2(width - 40, 0)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for spec: Array in buttons:
		var cb: Callable = spec[1]
		row.add_child(UI.button(spec[0], func() -> void:
			root.queue_free()
			cb.call()))
	overlay_layer.add_child(root)
	p.reset_size()
	p.position = Vector2(640, 380) - p.size * 0.5
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.85, 0.85)
	p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return root


## Selector de cartas a pantalla completa. `cb` recibe la Card elegida o null.
func pick_card(title: String, cards: Array, cb: Callable, cancellable: bool = true, show_upgrade: bool = false) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.02, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var t := UI.label(title, 28, UI.EMBER)
	t.position = Vector2(0, 60)
	t.size = Vector2(1280, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 110)
	scroll.size = Vector2(1160, 530)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 26)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(grid)
	scroll.add_child(margin)
	for c: Card in cards:
		var shown := Card.new(c.id, true) if show_upgrade and c.can_upgrade() else c
		var cv := CardView.new(shown)
		var picked := c
		cv.clicked.connect(func(_v: CardView, _b: int) -> void:
			Sfx.play("card")
			root.queue_free()
			cb.call(picked))
		cv.hover_changed.connect(func(v: CardView, h: bool) -> void:
			v.create_tween().tween_property(v, "scale", Vector2.ONE * (1.06 if h else 1.0), 0.08))
		grid.add_child(cv)
	if cards.is_empty():
		var none := UI.label("No hay cartas válidas.", 20, UI.DIM)
		grid.add_child(none)
	if cancellable:
		var b := UI.button("Cancelar", func() -> void:
			root.queue_free()
			cb.call(null), 20)
		b.position = Vector2(560, 656)
		b.size = Vector2(160, 44)
		root.add_child(b)
	overlay_layer.add_child(root)


## Vista de solo lectura del mazo.
func show_deck(cards: Array, title: String = "Tu mazo") -> void:
	pick_card("%s (%d cartas)" % [title, cards.size()], cards, func(_c: Variant) -> void: pass, true)
