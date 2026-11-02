class_name EndTurnButton
extends Button
## Fin de turno: placa de hierro remachada, 136×40 px, Fragua ×2. Señal: `pressed` de Button.
## `set_hint(true)`: no quedan jugadas y el borde late al rojo (2 Hz). `disabled` durante el turno enemigo.

const SIZE := Vector2(136, 40)

var _hint := false
var _t := 0.0


func _init() -> void:
	text = "Fin de turno"
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.pixelize(self, 2)
	# Texto a la izquierda con margen par: el centrado de Button caía en x impar (medio píxel de arte, F2-BASE).
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	var pad := _pad(2, 4)
	add_theme_stylebox_override("normal", UIKit.sb_iron(4, pad))
	add_theme_stylebox_override("hover", UIKit.sb_plate(Palette.color(&"plate", 4), Palette.color(&"ember_ui", 3), 2, 0, pad))
	add_theme_stylebox_override("pressed", UIKit.sb_iron(3, _pad(4, 2)))
	add_theme_stylebox_override("hover_pressed", UIKit.sb_iron(3, _pad(4, 2)))
	add_theme_stylebox_override("disabled", UIKit.sb_iron(2, pad))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_color_override("font_color", UI.TEXT)
	add_theme_color_override("font_hover_color", Palette.color(&"ember_ui", 5))
	add_theme_color_override("font_disabled_color", Palette.color(&"ash", 5))
	pressed.connect(func() -> void: Sfx.play("click"))


## Márgenes con el texto centrado en par. Fragua ×2: 2 px por píxel lógico (`PixelFont.text_width`).
func _pad(top: float, bottom: float) -> Vector4:
	var tw := PixelFont.text_width(text) * 2.0
	var left := roundf((SIZE.x - tw) / 4.0) * 2.0
	return Vector4(left, top, 0, bottom)


func set_hint(on: bool) -> void:
	_hint = on
	set_process(on)
	if not on:
		remove_theme_stylebox_override("normal")
		add_theme_stylebox_override("normal", UIKit.sb_iron(4, _pad(2, 4)))


func _process(delta: float) -> void:
	_t += delta
	var pad := _pad(2, 4)
	if int(_t * 4.0) % 2 == 0:
		add_theme_stylebox_override("normal", UIKit.sb_plate(Palette.color(&"plate", 4), Palette.color(&"ember_ui", 4), 2, 0, pad))
	else:
		add_theme_stylebox_override("normal", UIKit.sb_iron(4, pad))
