class_name EnergyCrucible
extends Control
## Energía de combate: crisol de metal fundido (92×88 px). El nivel baja al gastar, con oleaje de 4 fotogramas.
## Uso: `set_energy(cur, max)`; `deny()` al intentar pagar sin energía.

const SIZE := Vector2(92, 88)

var _img: TextureRect
var _label: Label
var _cur := 0
var _max := 3
var _level := 0.0
var _frame := 0
var _t := 0.0
var _shake := 0.0


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	tooltip_text = "Energía: se gasta al jugar cartas."
	mouse_filter = Control.MOUSE_FILTER_PASS
	_img = TextureRect.new()
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_SCALE
	_img.size = SIZE
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_img)
	_label = UI.plabel("", 2)
	_label.size = Vector2(SIZE.x, 40)
	_label.position = Vector2(0, 21)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_apply()


func set_energy(cur: int, max_energy: int) -> void:
	_cur = cur
	_max = maxi(1, max_energy)
	_label.text = "%d/%d" % [_cur, _max]
	_label.add_theme_color_override("font_color", UI.TEXT if _cur > 0 else UI.DIM)


## Sacudida de 1 px de arte: no hay energía para pagar.
func deny() -> void:
	_shake = 0.3


func _process(delta: float) -> void:
	_t += delta
	var target := 8.0 * clampf(float(_cur) / _max, 0.0, 1.0)
	_level = move_toward(_level, target, delta * 16.0)
	_frame = int(_t * 6.0) % HudArt.CRUCIBLE_FRAMES
	_apply()
	if _shake > 0.0:
		_shake -= delta
		_img.position.x = 2.0 if int(_t * 30.0) % 2 == 0 else -2.0
		_label.add_theme_color_override("font_color", UI.RED)
	elif _img.position.x != 0.0:
		_img.position.x = 0.0
		_label.add_theme_color_override("font_color", UI.TEXT if _cur > 0 else UI.DIM)


func _apply() -> void:
	var lv := int(ceil(_level))
	var key := "cru:%d:%d" % [lv, _frame]
	_img.texture = HudArt.tex(key, HudArt.crucible_image(lv, _frame))
