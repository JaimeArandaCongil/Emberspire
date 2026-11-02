class_name FloorLabel
extends Control
## Rótulo del piso: placa de hierro de una línea dentro de la barra superior ("Piso 4 · Hollín" en Fragua ×2) con el
## rasgo opcional a su derecha en Mini ×2 (Calor de Pacto, rasgo de la sala). Se centra en `center_x`.
## F2-VIDA: deja libre la banda de intención de jefe (arte y 22–44): antes colgaba bajo la barra, en y 30–80 de pantalla.
## Uso: añadirlo como hijo de `TopHud` en y = 2 y llamar a `set_floor(n, act_name, extra)`.

const H := 26.0
const PAD := 10.0
const GAP := 12.0

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
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_extra = UI.mlabel("", Palette.color(&"ember_ui", 4))
	_extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_extra)


func set_floor(n: int, act_name: String, extra: String = "") -> void:
	_title.text = "Piso %d · %s" % [n, act_name]
	_extra.text = extra
	_extra.visible = extra != ""
	var tw := PixelFont.text_width(_title.text) * 2.0
	var ew := PixelFont.mini_width(extra) * 2.0 if extra != "" else 0.0
	var w := PAD * 2.0 + tw + (GAP + ew if extra != "" else 0.0)
	w = ceilf(w / 2.0) * 2.0
	size = Vector2(w, H)
	position.x = roundf((center_x - w * 0.5) / 2.0) * 2.0
	_plate.size = size
	_title.position = Vector2(PAD, 0)
	_title.size = Vector2(tw + 4.0, H)
	# Línea base común: Fragua ×2 sube 20 px desde arriba; Mini ×2, 12.
	_extra.position = Vector2(PAD + tw + GAP, 8)
	_extra.size = Vector2(ew + 4.0, 16)
