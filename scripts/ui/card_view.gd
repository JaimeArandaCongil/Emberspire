class_name CardView
extends Control
## Representación visual de una carta. Emite `clicked(view, button)`.

signal clicked(view: CardView, button: int)
signal hover_changed(view: CardView, hovering: bool)

const SIZE := Vector2(150, 210)

var card: Card
var engine: CombatEngine
var interactive := true
var selected := false:
	set(v):
		selected = v
		_update_frame()
var hovering := false
var home_pos := Vector2.ZERO
var home_rot := 0.0

var _bg: Panel
var _art_bg: Panel
var _cost_panel: Panel
var _cost: Label
var _name: Label
var _type: Label
var _desc: RichTextLabel
var _art: TextureRect
var _burn_hint: Label


func _init(p_card: Card = null, p_engine: CombatEngine = null) -> void:
	card = p_card
	engine = p_engine


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var tcol: Color = UI.TYPE_COLORS.get(card.type(), UI.EDGE)

	_bg = Panel.new()
	_bg.size = SIZE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var title := card.title()
	var name_size := 15 if title.length() <= 14 else (13 if title.length() <= 18 else 12)
	_name = UI.label(title, name_size, Color("ffe08a") if card.upgraded else UI.TEXT)
	_name.position = Vector2(8, 8)
	_name.size = Vector2(SIZE.x - 16, 20)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.clip_text = true
	add_child(_name)

	_art_bg = Panel.new()
	_art_bg.position = Vector2(14, 32)
	_art_bg.size = Vector2(SIZE.x - 28, 66)
	_art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_bg.add_theme_stylebox_override("panel", UI.box(tcol.darkened(0.55), UI.OUTLINE, 2, 0))
	add_child(_art_bg)
	_art = UI.icon(card.def()["icon"], 5)
	_art.position = _art_bg.position + (_art_bg.size - _art.custom_minimum_size) * 0.5
	_art.size = _art.custom_minimum_size
	add_child(_art)

	_type = UI.label(CardDB.TYPE_NAMES.get(card.type(), ""), 11, tcol.lightened(0.45))
	_type.position = Vector2(0, 99)
	_type.size = Vector2(SIZE.x, 14)
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_type)

	_desc = UI.rich("", 13)
	_desc.position = Vector2(10, 116)
	_desc.size = Vector2(SIZE.x - 20, 90)
	_desc.fit_content = false
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_desc)

	_cost_panel = Panel.new()
	_cost_panel.position = Vector2(-8, -8)
	_cost_panel.size = Vector2(32, 32)
	_cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cost_panel)
	_cost = UI.label("", 18)
	_cost.size = Vector2(32, 32)
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_panel.add_child(_cost)

	_burn_hint = UI.label("CLIC DCHO: QUEMAR", 10, UI.EMBER)
	_burn_hint.position = Vector2(0, SIZE.y - 2)
	_burn_hint.size = Vector2(SIZE.x, 14)
	_burn_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_burn_hint.visible = false
	add_child(_burn_hint)

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	refresh()


func refresh() -> void:
	if _desc == null:
		return
	_desc.text = CardDB.describe(card, engine)
	var playable := card.is_playable()
	_cost_panel.visible = playable or card.type() == "status"
	_cost.text = "X" if card.is_x_cost() else str(card.cost())
	var affordable := true
	if engine != null and playable:
		affordable = engine.can_play(card)
	_cost.add_theme_color_override("font_color", UI.TEXT if affordable else Color("ff6a6a"))
	_cost_panel.add_theme_stylebox_override("panel", UI.box(Color("8a3a1a") if affordable else Color("3a2a2a"), Color("ffe08a") if affordable else UI.EDGE, 2, 0))
	_update_frame()


func _update_frame() -> void:
	if _bg == null:
		return
	var tcol: Color = UI.TYPE_COLORS.get(card.type(), UI.EDGE)
	var border := tcol.lightened(0.25)
	if card.upgraded:
		border = Color("ffd36a")
	if selected:
		border = Color("ffffff")
	_bg.add_theme_stylebox_override("panel", UI.box(Color("261a1d").lerp(tcol, 0.12), border, 4 if selected else 3, 5))


func _on_enter() -> void:
	hovering = true
	if engine != null and interactive:
		_burn_hint.visible = engine.can_burn(card)
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
