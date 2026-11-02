class_name StatusFX
extends Node2D
## Estados sobre un luchador (MV · v0.4), en coordenadas de mundo. Una sola animación en bucle por luchador
## (prioridad: quemadura > débil > fuerza); bloqueo y vulnerable son estáticos, con un evento al ganarlos o perderlos.
##   quemadura  llamitas de 3×5 sobre el contorno superior, min(3, ceil(valor/3)), 4 f a 120 ms
##   bloqueo    contorno de 1 px en el borde que mira al rival; escudo que gira 4 f al ganar; 5 esquirlas al perder
##   fuerza     venas de brasa, 2 f; 2 anillos que suben al ganar (6 f)
##   débil      gotas violeta que caen del sprite, 6 f
##   vulnerable grietas blancas de 1 px; destello al ganar
## API: docs/reviews/v04/mundo_vivo/api_vfx.md

const FLAME_S := 0.12
const WEAK_S := 0.11
const VEIN_S := 0.28
const SHIELD_S := 0.06
const SHATTER_S := 0.06
const RING_S := 0.06
const FLASH_S := 0.1
const JUMP_S := 0.2
## Llamita de 3×5 en 4 fotogramas: [x, y, paso de fuego].
const FLAME_FRAMES := [
	[[1, 0, 4], [0, 1, 4], [1, 1, 5], [2, 1, 4], [0, 2, 4], [1, 2, 6], [2, 2, 5], [0, 3, 5], [1, 3, 6], [2, 3, 5], [1, 4, 5]],
	[[0, 0, 4], [1, 1, 5], [0, 1, 4], [2, 1, 3], [0, 2, 5], [1, 2, 6], [2, 2, 4], [0, 3, 4], [1, 3, 6], [2, 3, 5], [1, 4, 5]],
	[[1, 1, 4], [0, 2, 4], [1, 2, 5], [2, 2, 4], [0, 3, 5], [1, 3, 7], [2, 3, 5], [1, 4, 6]],
	[[2, 0, 4], [1, 1, 5], [2, 1, 4], [0, 1, 3], [0, 2, 4], [1, 2, 6], [2, 2, 5], [0, 3, 5], [1, 3, 6], [2, 3, 4], [1, 4, 5]],
]

var body := Rect2(0, 0, 40, 60)
var is_player := false

var _statuses := {}
var _block := 0
var _synced := false
var _t := 0.0
var _k := 0
var _top := PackedInt32Array()
var _left := PackedInt32Array()
var _right := PackedInt32Array()
var _shield_t := -1.0
var _shatter_t := -1.0
var _rings_t := -1.0
var _flash_t := -1.0
var _jump_t := -1.0


func setup(p_body: Rect2, p_is_player: bool, mask: Image = null) -> StatusFX:
	body = Rect2(p_body.position.floor(), p_body.size.floor())
	is_player = p_is_player
	set_mask(mask)
	return self


func set_body(p_body: Rect2) -> void:
	body = Rect2(p_body.position.floor(), p_body.size.floor())
	queue_redraw()


## Fotograma actual (índice o color): el contorno y las llamas siguen la silueta. El tamaño debe ser el de `body`.
func set_mask(mask: Image) -> void:
	_top.clear()
	_left.clear()
	_right.clear()
	if mask == null or mask.is_empty():
		return
	var img := mask.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	_top.resize(w)
	_top.fill(-1)
	_left.resize(h)
	_left.fill(-1)
	_right.resize(h)
	_right.fill(-1)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a8 == 0:
				continue
			if _top[x] < 0:
				_top[x] = y
			if _left[y] < 0:
				_left[y] = x
			_right[y] = x


## En cada refresco del luchador. Detecta solo las ganancias y pérdidas.
func sync(statuses: Dictionary, block: int) -> void:
	if _synced:
		if block > _block:
			_shield_t = 0.0
		elif block <= 0 and _block > 0:
			_shatter_t = 0.0
		if int(statuses.get("str", 0)) > int(_statuses.get("str", 0)):
			_rings_t = 0.0
		if int(statuses.get("vuln", 0)) > int(_statuses.get("vuln", 0)):
			_flash_t = 0.0
	_statuses = statuses.duplicate()
	_block = block
	_synced = true
	queue_redraw()


func scorch_tick() -> void:
	_jump_t = 0.0


func flame_count() -> int:
	var v: int = int(_statuses.get("scorch", 0))
	return 0 if v <= 0 else mini(3, ceili(float(v) / 3.0))


## Qué animación en bucle está activa: &"scorch", &"weak", &"str" o &"".
func active_loop() -> StringName:
	if flame_count() > 0:
		return &"scorch"
	if int(_statuses.get("weak", 0)) > 0:
		return &"weak"
	if int(_statuses.get("str", 0)) > 0:
		return &"str"
	return &""


func _loop_period(loop: StringName) -> float:
	match loop:
		&"scorch":
			return FLAME_S
		&"weak":
			return WEAK_S
		&"str":
			return VEIN_S
	return 0.0


func _process(delta: float) -> void:
	var redraw := false
	var period := _loop_period(active_loop())
	if period > 0.0:
		_t += delta
		if _t >= period:
			_t -= period
			_k += 1
			redraw = true
	for pair: Array in [[&"_shield_t", SHIELD_S * 4.0], [&"_shatter_t", SHATTER_S * 5.0], [&"_rings_t", RING_S * 6.0], [&"_flash_t", FLASH_S], [&"_jump_t", JUMP_S]]:
		var cur: float = get(pair[0])
		if cur >= 0.0:
			cur += delta
			set(pair[0], cur if cur < float(pair[1]) else -1.0)
			redraw = true
	if redraw:
		queue_redraw()


func _body_x() -> int:
	return int(body.position.x)


func _body_y() -> int:
	return int(body.position.y)


## Altura del contorno superior a `fx` (0..1) del ancho del sprite.
func _top_at(fx: float) -> Vector2i:
	var w := int(body.size.x)
	var x := clampi(int(fx * w), 0, maxi(0, w - 1))
	var y := 0
	if x < _top.size():
		if _top[x] >= 0:
			y = _top[x]
		else:
			for d in range(1, w):
				if x - d >= 0 and _top[x - d] >= 0:
					y = _top[x - d]
					break
				if x + d < _top.size() and _top[x + d] >= 0:
					y = _top[x + d]
					break
	return Vector2i(_body_x() + x, _body_y() + y)


func _draw() -> void:
	if _synced:
		if _block > 0:
			_draw_block_edge()
		if int(_statuses.get("vuln", 0)) > 0:
			_draw_cracks()
		match active_loop():
			&"scorch":
				_draw_flames()
			&"weak":
				_draw_drips()
			&"str":
				_draw_veins()
	if _shield_t >= 0.0:
		_draw_shield(int(_shield_t / SHIELD_S))
	if _shatter_t >= 0.0:
		_draw_shatter(int(_shatter_t / SHATTER_S))
	if _rings_t >= 0.0:
		_draw_rings(int(_rings_t / RING_S))
	if _jump_t >= 0.0:
		_draw_jump(_jump_t / JUMP_S)


func _draw_flames() -> void:
	var n := flame_count()
	var slots: Array = [[0.5], [0.34, 0.66], [0.22, 0.5, 0.78]][n - 1]
	for i in n:
		var at := _top_at(float(slots[i])) - Vector2i(1, 4)
		var fr: Array = FLAME_FRAMES[(_k + i * 2) % FLAME_FRAMES.size()]
		for px: Array in fr:
			draw_rect(Rect2(at.x + int(px[0]), at.y + int(px[1]), 1, 1), Palette.color(&"fire", int(px[2])))


func _draw_jump(u: float) -> void:
	var at := _top_at(0.5) - Vector2i(0, 5 + int(u * 14.0))
	var c := Palette.color(&"fire", 6 if u < 0.5 else 4)
	draw_rect(Rect2(at.x, at.y, 2, 3), c)


## El borde que mira al rival.
func _draw_block_edge() -> void:
	var c := Palette.color(&"frost_glow", 3)
	var x := _body_x() + int(body.size.x) if is_player else _body_x() - 1
	var h := int(body.size.y)
	for i in h:
		var px := x
		if i < _left.size() and _left[i] >= 0:
			px = _body_x() + (_right[i] + 1 if is_player else _left[i] - 1)
		elif not _left.is_empty():
			continue
		draw_rect(Rect2(px, _body_y() + i, 1, 1), c)


## Escudo 7×8 que gira: el ancho aparente cambia en 4 fotogramas.
func _draw_shield(f: int) -> void:
	var half: int = [3, 2, 0, 2][clampi(f, 0, 3)]
	var cx := _body_x() + int(body.size.x) + 4 if is_player else _body_x() - 5
	var cy := _body_y() + int(body.size.y) / 2 - 4
	for y in 8:
		var hw := half if y < 5 else maxi(0, half - (y - 4))
		draw_rect(Rect2(cx - hw, cy + y, hw * 2 + 1, 1), Palette.color(&"frost_glow", 3 if y > 0 else 4))
	draw_rect(Rect2(cx, cy + 1, 1, 6), Palette.color(&"frost_glow", 5))


func _draw_shatter(f: int) -> void:
	var cx := _body_x() + int(body.size.x) + 4 if is_player else _body_x() - 5
	var cy := _body_y() + int(body.size.y) / 2
	var c := Palette.color(&"frost_glow", clampi(4 - f, 1, 4))
	for i in 5:
		var a := TAU * (float(i) + 0.5) / 5.0
		var r := 3 + f * 3
		draw_rect(Rect2(cx + int(cos(a) * r), cy + int(sin(a) * r) + f, 2, 1), c)


func _draw_veins() -> void:
	var step := 4 if _k % 2 == 0 else 3
	var c := Palette.color(&"fire", step)
	var bx := _body_x()
	var by := _body_y()
	var w := int(body.size.x)
	var h := int(body.size.y)
	for i in 3:
		var x := bx + w * (i + 1) / 4
		var y0 := by + h * (35 + i * 8) / 100
		for j in 6:
			var ox := (i + j) % 3 - 1
			draw_rect(Rect2(x + ox, y0 + j, 1, 1), c)


func _draw_rings(f: int) -> void:
	var cx := _body_x() + int(body.size.x) / 2
	var hw := int(body.size.x) / 2 + 2 - f
	for i in 2:
		var y := _body_y() + int(body.size.y) - 4 - f * 9 - i * 12
		var c := Palette.color(&"fire", clampi(6 - f / 2, 3, 6))
		draw_rect(Rect2(cx - hw, y, hw * 2, 1), c)


func _draw_drips() -> void:
	var c := Palette.color(&"magic", 3)
	var c2 := Palette.color(&"magic", 2)
	var w := int(body.size.x)
	var h := int(body.size.y)
	for i in 3:
		var ph := (_k + i * 2) % 6
		var x := _body_x() + w * (i * 2 + 1) / 6
		var y := _body_y() + h * 55 / 100 + ph * 3 + i * 4
		draw_rect(Rect2(x, y, 1, 2), c if ph < 4 else c2)


func _draw_cracks() -> void:
	var white := Palette.color(&"fire", 7)
	var bx := _body_x()
	var by := _body_y()
	var w := int(body.size.x)
	var h := int(body.size.y)
	var seeds: Array[Vector2i] = [Vector2i(w * 35 / 100, h * 30 / 100), Vector2i(w * 62 / 100, h * 52 / 100)]
	var flashing := _flash_t >= 0.0
	for s: Vector2i in seeds:
		var x := bx + s.x
		var y := by + s.y
		for j in (11 if flashing else 7):
			draw_rect(Rect2(x, y, 1, 1), white)
			y += 1
			x += [1, 0, -1, 1, 1, 0, -1][j % 7]
