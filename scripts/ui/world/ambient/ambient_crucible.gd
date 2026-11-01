class_name AmbientCrucible
extends Node2D
## Cadena con crisol que oscila (MV · v0.4): 16 posiciones de péndulo a 110 ms (periodo 1,76 s), redibujadas por
## posición (nunca se rota el sprite). Su luz se mueve con él: sin shader, 16 parches horneados del muro.
## `shake()` (golpes fuertes) dobla la amplitud durante 6 posiciones. `position` = pivote (px de arte).

var state: AmbientState
var length := 66
var amp := 7
var patches: Array = []
var patch_rect := Rect2i()
var use_patches := true

var _t := 0.0
var _k := 0
var _shake := 0
var _patch_tex: Array = []


func setup(p_state: AmbientState, p_len: int, p_patches: Dictionary = {}) -> AmbientCrucible:
	state = p_state
	length = p_len
	if not p_patches.is_empty():
		patch_rect = p_patches["rect"]
		for f: Dictionary in p_patches["frames"]:
			_patch_tex.append(ImageTexture.create_from_image(f["preview"]))
	if state != null:
		state.struck.connect(func(a: int) -> void:
			if a >= 20:
				shake())
	return self


func shake() -> void:
	_shake = 6


func current_dx() -> int:
	return AmbientFrames.crucible_dx(_k, 11 if _shake > 0 else amp)


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.11:
		_t -= 0.11
		_k = (_k + 1) % 16
		if _shake > 0:
			_shake -= 1
		queue_redraw()


func _draw() -> void:
	if use_patches and _patch_tex.size() == 16:
		draw_texture(_patch_tex[_k], Vector2(patch_rect.position) - position)
	var a := 11 if _shake > 0 else amp
	var glow := 1 if state != null and state.heat > 0.7 else 0
	var tex := AmbientFrames.crucible(_k, length, a, glow)
	draw_texture(tex, Vector2(-tex.get_width() / 2, 0))


func light_info() -> Dictionary:
	return {"pos": position + Vector2(current_dx(), length + 8), "radii": [8.0, 16.0, 26.0], "step": 0}
