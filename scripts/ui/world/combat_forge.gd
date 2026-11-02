class_name CombatForge
extends Node2D
## Forja de combate (MV · v0.4). Dibuja en coordenadas de mundo con `position = (0, 0)`: horno en x 8–112 con chimenea
## hasta el borde superior. Sale horneada (`BgForge`, `BakedRooms.load_forge`), con `palette_lit` si se le da material.
## Estado: `set_heat` (llama de la boca y de la junta de tiro), `set_burns` (rejillas del zócalo).
## Eventos: `swallow` (boca abierta), `flash` (boca en blanco), `deny` (sin Quemas). API: docs/reviews/v04/mundo_vivo/api_vfx.md

const MOUTH_FRAME_S := 0.11
const LICK_FRAME_S := 0.125
const GRATE_FRAME_S := 0.14
const FLASH_FRAME_S := 1.0 / 30.0
const DENY_S := 0.5
const MAX_GRATES := 5

var heat := 0.3
var burns := 0
var use_index := false

var _data := {}
var _tex := {}
var _t_mouth := 0.0
var _t_lick := 0.0
var _t_grate := 0.0
var _k_mouth := 0
var _k_lick := 3
var _k_grate := 0
var _swallow_left := 0.0
var _flash_left := 0.0
var _flash_total := 0.0
var _flash_card := false
var _deny_left := 0.0
var _smoke_k := 0
var _smoke_t := 0.0


func setup(p_material: ShaderMaterial = null) -> CombatForge:
	_data = BakedRooms.load_forge()
	use_index = p_material != null
	material = p_material
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	return self


func has_art() -> bool:
	return not _data.is_empty()


func set_heat(v: float) -> void:
	var lvl := _level()
	heat = clampf(v, 0.0, 1.0)
	if _level() != lvl:
		queue_redraw()


func set_burns(left: int) -> void:
	if left != burns:
		burns = maxi(0, left)
		queue_redraw()


## Rejillas encendidas ahora.
func lit_grates() -> int:
	return mini(burns, MAX_GRATES)


func swallow(duration := 0.26) -> void:
	_swallow_left = duration
	_flash_left = 0.0
	queue_redraw()


func flash(frames := 2, with_card := true) -> void:
	_flash_left = frames * FLASH_FRAME_S
	_flash_total = _flash_left
	_flash_card = with_card
	_swallow_left = 0.0
	queue_redraw()


func deny() -> void:
	_deny_left = DENY_S
	_smoke_k = 0
	_smoke_t = 0.0
	queue_redraw()


func mouth_pos() -> Vector2:
	return Vector2(BgForge.CX, 226)


## Labio del tiro bajo: de aquí sube la columna hasta la campana (y 78–118).
func chimney_top() -> Vector2:
	return Vector2(BgForge.CX, BgForge.GAP_BOTTOM)


func mouth_state() -> StringName:
	if _flash_left > 0.0:
		return &"flash"
	if _swallow_left > 0.0:
		return &"swallow"
	return StringName("mouth_%d" % _level())


func _level() -> int:
	if heat < 0.35:
		return 0
	return 1 if heat < 0.72 else 2


func _process(delta: float) -> void:
	var redraw := false
	_t_mouth += delta
	if _t_mouth >= MOUTH_FRAME_S:
		_t_mouth -= MOUTH_FRAME_S
		_k_mouth = (_k_mouth + 1) % 6
		redraw = true
	_t_lick += delta
	if _t_lick >= LICK_FRAME_S:
		_t_lick -= LICK_FRAME_S
		_k_lick = (_k_lick + 1) % 6
		redraw = true
	_t_grate += delta
	if _t_grate >= GRATE_FRAME_S:
		_t_grate -= GRATE_FRAME_S
		_k_grate += 1
		redraw = redraw or burns > 0
	if _swallow_left > 0.0:
		_swallow_left -= delta
		redraw = true
	if _flash_left > 0.0:
		_flash_left -= delta
		redraw = true
	if _deny_left > 0.0:
		_deny_left -= delta
		_smoke_t += delta
		if _smoke_t >= 0.08:
			_smoke_t -= 0.08
			_smoke_k += 1
		redraw = true
	if redraw:
		queue_redraw()


func _frame(fname: String, i: int) -> Texture2D:
	var list: Array = (_data["rects"] as Dictionary).get(fname, [])
	if list.is_empty():
		return null
	var n: int = posmod(i, list.size())
	var key := "%s:%d" % [fname, n]
	if _tex.has(key):
		return _tex[key]
	var at := AtlasTexture.new()
	at.atlas = _data["idx"] if use_index else _data["prev"]
	at.region = Rect2(list[n])
	_tex[key] = at
	return at


func _draw_frame(fname: String, i: int, extra := Vector2.ZERO) -> void:
	var t := _frame(fname, i)
	if t != null:
		var off := Vector2((_data["offsets"] as Dictionary).get(fname, Vector2i.ZERO))
		draw_texture(t, off + extra)


func _draw() -> void:
	if _data.is_empty():
		return
	_draw_frame("base", 0)
	_draw_frame("lick_%d" % _level(), _k_lick)
	if _flash_left > 0.0:
		# La silueta de la carta dura sólo el primer fotograma del destello.
		var first := _flash_card and _flash_left > _flash_total - FLASH_FRAME_S
		_draw_frame("flash_card" if first else "flash", 0)
	elif _swallow_left > 0.0:
		_draw_frame("swallow", 1 if _swallow_left < 0.13 else 0)
	else:
		_draw_frame("mouth_%d" % _level(), _k_mouth)
	var blink := _deny_left > 0.0 and int(_deny_left / 0.1) % 2 == 0
	if not blink:
		for i in lit_grates():
			_draw_frame("grate", _k_grate + i * 2, Vector2(int(BgForge.GRATE_X[i]), BgForge.GRATE_Y))
	if _deny_left > 0.0:
		var sm := AmbientFrames.smoke(_smoke_k, 1, use_index)
		draw_texture(sm, mouth_pos() + Vector2(-AmbientFrames.SMOKE_BASE.x, -AmbientFrames.SMOKE_BASE.y - 14))
