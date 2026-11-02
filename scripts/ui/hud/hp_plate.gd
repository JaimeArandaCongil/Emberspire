class_name HpPlate
extends Control
## Vida + bloqueo: placa de hierro remachada de 156×22 px, con escudo de bloqueo a la izquierda (28×28 px) sólo
## cuando hay bloqueo. El daño deja un tramo ámbar que se consume; la quemadura pendiente va tramada al final de la vida.
## Uso: `set_values(hp, max_hp, block, scorch)`. `snap()` salta la animación.

const SIZE := Vector2(156, 22)
const NATIVE := Vector2i(78, 11)
const BLOCK_W := 28.0

static var _plate_tex: ImageTexture
static var _shield_tex: ImageTexture

var _hp := 1
var _max := 1
var _block := 0
var _scorch := 0
var _shown := 1.0
var _label: Label
var _block_label: Label


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UI.plabel("", 2)
	_label.position = Vector2(0, -3)
	_label.size = Vector2(SIZE.x, 26)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_block_label = UI.mlabel("")
	_block_label.position = Vector2(-BLOCK_W - 2, -5)
	_block_label.size = Vector2(BLOCK_W, 26)
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_label.add_theme_color_override("font_shadow_color", Palette.OUTLINE)
	add_child(_block_label)


func set_values(hp: int, max_hp: int, block: int = 0, scorch: int = 0) -> void:
	_hp = hp
	_max = maxi(1, max_hp)
	_block = block
	_scorch = scorch
	_label.text = "%d/%d" % [hp, max_hp]
	_block_label.text = str(block) if block > 0 else ""
	queue_redraw()


func snap() -> void:
	_shown = float(_hp)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_equal_approx(_shown, float(_hp)):
		if _shown < _hp:
			_shown = float(_hp)
		else:
			_shown = move_toward(_shown, float(_hp), _max * delta * 0.5)
		queue_redraw()


static func _plate() -> ImageTexture:
	if _plate_tex != null:
		return _plate_tex
	var w := NATIVE.x
	var h := NATIVE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
				continue
			var e := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			var col := Palette.color(&"plate", 3)
			if e == 0:
				col = Palette.OUTLINE
			elif y == 1 or x == 1:
				col = Palette.color(&"iron", 7)
			elif y == h - 2 or x == w - 2:
				col = Palette.color(&"plate", 2)
			elif x <= 3 or x >= w - 4:
				col = Palette.color(&"plate", 4)
			else:
				col = Palette.color(&"plate", 1)
			img.set_pixel(x, y, col)
	for rx: int in [2, w - 3]:
		img.set_pixel(rx, h / 2, Palette.color(&"iron", 9))
		img.set_pixel(rx, h / 2 + 1, Palette.color(&"plate", 1))
	_plate_tex = HudArt.tex("hp_plate", img)
	return _plate_tex


static func _shield() -> ImageTexture:
	if _shield_tex != null:
		return _shield_tex
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 14:
		for x in 14:
			var t := float(y) / 13.0
			var half := 7.0 if t < 0.45 else 7.0 * sqrt(maxf(0.0, 1.0 - pow((t - 0.45) / 0.55, 1.6)))
			var dx := absf(x + 0.5 - 7.0)
			if dx > half:
				continue
			var col := Palette.color(&"steel", 3, true) if x >= 7 else Palette.color(&"steel", 4, true)
			if dx > half - 1.0 or y == 0:
				col = Palette.OUTLINE
			elif dx > half - 2.0 or y == 1:
				col = Palette.color(&"steel", 6, true) if x < 7 else Palette.color(&"steel", 4, true)
			img.set_pixel(x, y, col)
	_shield_tex = HudArt.tex("hp_shield", img)
	return _shield_tex


func _draw() -> void:
	draw_texture(_plate(), Vector2.ZERO)
	# Relleno en la rejilla ×2: 8..(78-8) nativos.
	var x0 := 8
	var wn := NATIVE.x - 16
	var y0 := 4
	var hn := NATIVE.y - 8
	var real := int(round(wn * clampf(float(_hp) / _max, 0.0, 1.0)))
	var chip := int(round(wn * clampf(_shown / _max, 0.0, 1.0)))
	var sc := mini(real, int(round(wn * clampf(float(_scorch) / _max, 0.0, 1.0))))
	var hi := Palette.color(&"blood", 4)
	var mid := Palette.color(&"blood", 3)
	var lo := Palette.color(&"blood", 1)
	if _block > 0:
		hi = Palette.color(&"steel", 6, true)
		mid = Palette.color(&"steel", 4, true)
		lo = Palette.color(&"steel", 2, true)
	if chip > real:
		_rect(x0 + real, y0, chip - real, hn, Palette.color(&"ember_ui", 5))
	if real > 0:
		_rect(x0, y0, real, hn, mid)
		_rect(x0, y0, real, 1, hi)
		_rect(x0, y0 + hn - 1, real, 1, lo)
	if sc > 0:
		for i in sc:
			var col := Palette.color(&"fire", 5) if i % 2 == 0 else Palette.color(&"fire", 3)
			_rect(x0 + real - 1 - i, y0, 1, hn, col)
	if _block > 0:
		draw_texture(_shield(), Vector2(-BLOCK_W - 2, -3))


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	draw_rect(Rect2(x * 2, y * 2, w * 2, h * 2), c)
