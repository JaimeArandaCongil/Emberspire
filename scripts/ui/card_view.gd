class_name CardView
extends Control
## Representación visual de una carta: marco e ilustración en la MISMA rejilla ×2, cuerpo de pergamino
## con texto oscuro, nombre y coste en fuente pixel. Sin escalado ni rotación al pasar el ratón.
## Emite `clicked(view, button)`. `burn_away()` la disuelve en llamas.

signal clicked(view: CardView, button: int)
signal hover_changed(view: CardView, hovering: bool)

const SIZE := Vector2(150, 210)
const INK := Color("2a1418")

var card: Card
var engine: CombatEngine
var interactive := true
var selected := false:
	set(v):
		selected = v
		_update_glow()
var hovering := false
var home_pos := Vector2.ZERO
var home_rot := 0.0

var _glow: Panel
var _frame: TextureRect
var _art: TextureRect
var _orb: TextureRect
var _cost: Label
var _name: Label
var _type: Label
var _desc: RichTextLabel
var _burn_hint: Label
var _frame_mat: ShaderMaterial
var _art_mat: ShaderMaterial
var _frame_key := ""


func _init(p_card: Card = null, p_engine: CombatEngine = null) -> void:
	card = p_card
	engine = p_engine


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_glow = Panel.new()
	_glow.position = Vector2(-5, -5)
	_glow.size = SIZE + Vector2(10, 10)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.visible = false
	add_child(_glow)

	_frame = TextureRect.new()
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_frame.size = SIZE
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_mat = UI.dissolve_material(Vector2(75, 105))
	_frame.material = _frame_mat
	add_child(_frame)

	_art = TextureRect.new()
	_art.texture = Art.card_art(card.id, card.type(), card.def()["icon"])
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.position = Vector2(14, 32)
	_art.size = Vector2(120, 60)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_mat = UI.dissolve_material(Vector2(30, 15))
	_art.material = _art_mat
	add_child(_art)

	_name = UI.plabel("", 1)
	_name.position = Vector2(18, 6)
	_name.size = Vector2(SIZE.x - 26, 22)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.clip_text = true
	add_child(_name)

	_type = UI.label(CardDB.TYPE_NAMES.get(card.type(), ""), 10, Color("f4e4c8"))
	_type.position = Vector2(0, 95)
	_type.size = Vector2(SIZE.x, 12)
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_type)

	# Texto sobre pergamino: tinta oscura sin contorno.
	_desc = UI.rich("", 13)
	_desc.position = Vector2(16, 114)
	_desc.size = Vector2(SIZE.x - 32, 82)
	_desc.fit_content = false
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.add_theme_color_override("default_color", INK)
	_desc.add_theme_constant_override("outline_size", 0)
	_desc.add_theme_constant_override("line_separation", -1)
	add_child(_desc)

	_orb = TextureRect.new()
	_orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_orb.stretch_mode = TextureRect.STRETCH_SCALE
	_orb.position = Vector2(-10, -10)
	_orb.size = Vector2(32, 32)
	_orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_orb)
	_cost = UI.plabel("", 2)
	_cost.position = Vector2(0, 1)
	_cost.size = Vector2(32, 32)
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_orb.add_child(_cost)

	_burn_hint = UI.label("CLIC DCHO: QUEMAR", 10, UI.EMBER)
	_burn_hint.position = Vector2(0, SIZE.y + 1)
	_burn_hint.size = Vector2(SIZE.x, 30)
	_burn_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_burn_hint.visible = false
	add_child(_burn_hint)

	tooltip_text = _tooltip()
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	refresh()


func _tooltip() -> String:
	var lvl := card.mastery()
	var prog := Game.mastery_progress(card.id)
	var t := "%s · %s" % [CardDB.RARITY_NAMES.get(card.rarity(), ""), CardDB.PACK_NAMES.get(card.def()["pack"], "")]
	if card.rarity() in ["status", "token"]:
		return t
	if lvl >= Game.MASTERY_MAX:
		t += "\nMaestría %d (máx.): +%d%% números, +%d%% Ascuas al quemar" % [lvl, lvl * 10, lvl * 20]
	else:
		t += "\nMaestría %d · %d/%d quemas para el nivel %d" % [lvl, prog.x, prog.y, lvl + 1]
		if lvl > 0:
			t += "\n(+%d%% números, +%d%% Ascuas al quemar)" % [lvl * 10, lvl * 20]
	return t


func refresh() -> void:
	if _desc == null:
		return
	var lvl := card.mastery()
	var key := "%s:%s:%s:%d" % [card.type(), card.rarity(), card.is_up(), lvl]
	if key != _frame_key:
		_frame_key = key
		_frame.texture = Art.card_frame(card.type(), card.rarity(), card.is_up(), lvl)
	var title := card.title()
	_name.text = title
	# Nombre en fuente pixel ×2 si cabe en la banda (67 px de arte); si no, fuente lisa seminegrita.
	if PixelFont.text_width(title) * 2 <= 114:
		UI.pixelize(_name, 2)
	else:
		_name.remove_theme_font_override("font")
		_name.add_theme_font_size_override("font_size", 14 if title.length() <= 18 else 12)
		_name.add_theme_constant_override("outline_size", 4)
	_name.add_theme_color_override("font_color", Color("ffe08a") if card.is_up() else UI.TEXT)
	_desc.text = _ink(CardDB.describe(card, engine))
	var plain_len := _desc.get_parsed_text().length()
	var fs := 13 if plain_len <= 56 else (12 if plain_len <= 74 else 11)
	_desc.add_theme_font_size_override("normal_font_size", fs)
	_desc.add_theme_font_size_override("bold_font_size", fs)
	var playable := card.is_playable()
	_orb.visible = playable or card.type() == "status"
	_cost.text = "X" if card.is_x_cost() else str(card.cost())
	var affordable := true
	if engine != null and playable:
		affordable = engine.can_play(card)
	_orb.texture = Art.cost_orb(affordable, card.is_up())
	_cost.add_theme_color_override("font_color", UI.TEXT if affordable else Color("c0a0a0"))
	_update_glow()


## Los colores de resalte del texto están pensados para fondo oscuro: sobre pergamino se oscurecen.
static func _ink(t: String) -> String:
	for pair: Array in [["#ffd36a", "#a8400c"], ["#ff9a4a", "#9a2a0c"], ["#7dff7d", "#1e7a1e"], ["#ff7d7d", "#a81a1a"], ["#ffb43a", "#a8400c"], ["#ff8a4a", "#b03a10"], ["#8ab4d0", "#2a5a8a"],
			["#b07ae0", "#6a2a9a"], ["#7ad47a", "#2a7a2a"], ["#ff6a4a", "#b02a1a"], ["#ff8ad8", "#a02a80"], ["#a08878", "#6a5048"],
			["#f4e4c8", "#2a1418"], ["#ffe08a", "#8a5a0c"]]:
		t = t.replace(pair[0], pair[1]).replace(pair[0].to_upper(), pair[1])
	return t


func _update_glow() -> void:
	if _glow == null:
		return
	var vis := selected
	var col := Color("ffffff")
	if not vis and engine != null and interactive and engine.hand.has(card):
		if engine.can_play(card):
			vis = true
			col = Color("ffd36a")
		elif card.type() == "fuel" and engine.can_burn(card):
			vis = true
			col = Color("ff6a1a")
	_glow.visible = vis
	if vis:
		_glow.add_theme_stylebox_override("panel", UI.box(Color(0, 0, 0, 0), Color(col, 0.75 if selected else 0.45), 3, 0))


## Se quema: el texto se apaga y marco e ilustración se deshacen en brasas.
func burn_away(duration: float = 0.55) -> Tween:
	interactive = false
	_burn_hint.visible = false
	_glow.visible = false
	var tw := create_tween().set_parallel()
	for n: CanvasItem in [_name, _type, _desc, _orb]:
		tw.tween_property(n, "modulate:a", 0.0, duration * 0.3)
	tw.tween_method(func(v: float) -> void:
		_frame_mat.set_shader_parameter("progress", v)
		_art_mat.set_shader_parameter("progress", v), 0.0, 1.0, duration).set_ease(Tween.EASE_IN)
	return tw


func _on_enter() -> void:
	hovering = true
	if engine != null and interactive:
		_burn_hint.visible = engine.can_burn(card)
		if _burn_hint.visible:
			var pv: Dictionary = engine.burn_preview(card, false)
			var prog := Game.mastery_progress(card.id)
			var t := "QUEMAR +%s · Maestría %d/%d" % [Num.fmt(float(pv["embers"])), prog.x, prog.y]
			if engine.can_burn_hot(card):
				var hc := engine.hot_burn_cost(card)
				t += "\nMAYÚS: EN CALIENTE ×2 (%s)" % ("gratis" if hc == 0 else "−%d Energía" % hc)
			_burn_hint.text = t
	hover_changed.emit(self, true)


func _on_exit() -> void:
	hovering = false
	_burn_hint.visible = false
	hover_changed.emit(self, false)


func _gui_input(ev: InputEvent) -> void:
	if not interactive:
		return
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			clicked.emit(self, mb.button_index)
			accept_event()
