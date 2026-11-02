class_name PileCounter
extends Control
## Pila de cartas: dorsos pequeños apilados (hasta 3) + nombre en Mini ×2 + cifra en Fragua ×2. 96×46 px.
## Uso: `PileCounter.new("draw")` ("draw" | "discard" | "exhaust"), `set_count(n)`, señal `pressed`.
## `card_anchor()` = centro global de la pila, para las cartas en vuelo.

signal pressed

const SIZE := Vector2(96, 46)
const NAMES := {"draw": "ROBO", "discard": "DESCARTE", "exhaust": "EXILIO"}

var kind := "draw"
var _back: TextureRect
var _count: Label
var _n := -1
var enabled := true


func _init(p_kind: String = "draw") -> void:
	kind = p_kind
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Ver cartas"
	_back = TextureRect.new()
	_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back.stretch_mode = TextureRect.STRETCH_SCALE
	_back.position = Vector2(0, 0)
	_back.size = Vector2(34, 46)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)
	var l := UI.mlabel(NAMES.get(kind, ""), UI.DIM)
	l.position = Vector2(38, 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	_count = UI.plabel("0", 2)
	_count.position = Vector2(38, 18)
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)
	set_count(0)


func set_count(n: int) -> void:
	if n == _n:
		return
	_n = n
	_count.text = str(n)
	var layers := clampi(n, 0, 3)
	_back.texture = HudArt.tex("pile:%s:%d" % [kind, layers], HudArt.pile_image(kind, layers))


func card_anchor() -> Vector2:
	return global_position + Vector2(17, 23)


func _gui_input(ev: InputEvent) -> void:
	if enabled and ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
