class_name FloorLabel
extends Control
## Rótulo del piso: placa de hierro colgada bajo la barra superior ("Piso 4 · Hollín" en Fragua ×2) con una línea
## opcional en Pavesa (Calor de Pacto, rasgo de la sala). Se centra en `center_x`.
## Uso: `set_floor(n, act_name, extra)`.

var center_x := 640.0
var _plate: Panel
var _title: Label
var _extra: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate = Panel.new()
	_plate.add_theme_stylebox_override("panel", UIKit.sb_iron(2, Vector4.ZERO))
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_title = UI.plabel("", 2)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_extra = UI.label("", 14, Palette.color(&"ember_ui", 3))
	_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_extra)


func set_floor(n: int, act_name: String, extra: String = "") -> void:
	_title.text = "Piso %d · %s" % [n, act_name]
	_extra.text = extra
	_extra.visible = extra != ""
	var w := maxf(PixelFont.text_width(_title.text) * 2.0, PixelFont.pavesa_width(extra)) + 32.0
	w = ceilf(w / 2.0) * 2.0
	var h := 34.0 if extra == "" else 50.0
	size = Vector2(w, h)
	position.x = roundf((center_x - w * 0.5) / 2.0) * 2.0
	_plate.size = size
	_title.position = Vector2(0, 4)
	_title.size = Vector2(w, 26)
	_extra.position = Vector2(0, 28)
	_extra.size = Vector2(w, 16)
