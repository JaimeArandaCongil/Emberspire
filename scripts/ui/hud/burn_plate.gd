class_name BurnPlate
extends Control
## Quemas disponibles: placa de hierro con una rejilla por Quema (encendida / apagada), como las del zócalo de la
## Forja, y "QUEMAS n" en Mini ×2. Tamaño: 132×30 px.
## Uso: `set_burns(cur, max_shown)`; `flash()` al quemar. `cur = 0` apaga la placa.

const SIZE := Vector2(132, 30)
const MAX_GRATES := 5

static var _on: ImageTexture
static var _off: ImageTexture

var _label: Label
var _cur := 0
var _shown_max := 1
var _flash := 0.0


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "Quemas: cartas que puedes arrojar al horno este turno.\nClic derecho en una carta para quemarla."
	_label = UI.mlabel("", Palette.color(&"ember_ui", 4))
	_label.position = Vector2(10, 7)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	set_process(false)


static func _grate(lit: bool) -> ImageTexture:
	if lit and _on != null:
		return _on
	if not lit and _off != null:
		return _off
	var rows := ["kkkkkk", "kyokyk", "kyokok", "koykok", "kkkkkk"]
	var pal := {"k": Palette.color(&"iron", 2), "y": Palette.color(&"fire", 6), "o": Palette.color(&"fire", 4)}
	if not lit:
		pal = {"k": Palette.color(&"iron", 2), "y": Palette.color(&"iron", 1), "o": Palette.color(&"iron", 1)}
	var t := HudArt.tex("grate%s" % lit, HudArt._sprite(rows, pal))
	if lit:
		_on = t
	else:
		_off = t
	return t


func set_burns(cur: int, max_shown: int = 1) -> void:
	_cur = cur
	_shown_max = clampi(maxi(cur, max_shown), 1, MAX_GRATES)
	_label.text = "QUEMAS %d" % cur
	_label.add_theme_color_override("font_color", Palette.color(&"ember_ui", 4) if cur > 0 else UI.DIM)
	queue_redraw()


func flash() -> void:
	_flash = 0.25
	set_process(true)


func _process(delta: float) -> void:
	_flash -= delta
	_label.add_theme_color_override("font_color", Palette.color(&"ember_ui", 6) if _flash > 0.0 else (Palette.color(&"ember_ui", 4) if _cur > 0 else UI.DIM))
	if _flash <= 0.0:
		set_process(false)


func _draw() -> void:
	draw_style_box(UIKit.sb_iron(2, Vector4.ZERO), Rect2(Vector2.ZERO, SIZE))
	# Sólo las 3 rejillas que caben junto al texto a partir de 3 Quemas: el resto lo dice la cifra.
	for i in mini(_shown_max, 3):
		var gx := SIZE.x - 10.0 - (mini(_shown_max, 3) - i) * 14.0 + 2.0
		draw_texture(_grate(i < _cur), Vector2(gx, 10))
