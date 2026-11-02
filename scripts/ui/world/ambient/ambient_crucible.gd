class_name AmbientCrucible
extends Node2D
## Cadena con crisol que oscila (MV · v0.4): 16 posiciones de péndulo a 110 ms (periodo 1,76 s), redibujadas por
## posición (nunca se rota el sprite). Su luz se mueve con él: sin shader, 16 parches horneados del muro.
## `shake()` (golpes fuertes) dobla la amplitud durante 6 posiciones. `position` = pivote (px de arte).
## Onda de quemar: el calor tarda lo que tarda en cruzar la sala. Al llegar, el hierro se enciende (luz propia en LightRig,
## +`RING_STEPS` pasos sobre las piezas de hierro), el metal fundido sube un paso y el golpe de aire lo balancea.

const WAVE_SPEED := 1100.0
const RING_TIME := 0.3
const RING_STEPS := 4.0
const IDLE_STEPS := 2.0

var state: AmbientState
## Origen de la onda de quemar (la boca de la Forja).
var wave_origin := Vector2(60, 230)
var length := 66
var amp := 7
var patches: Array = []
var patch_rect := Rect2i()
var use_patches := true
## Con `palette_lit` en `material`, el hierro recibe la luz de la escena (reacciona a la onda de quemar).
var use_index := false

var _t := 0.0
var _k := 0
var _shake := 0
var _ring := 0.0
var _wave_delay := -1.0
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
		state.burned.connect(on_burn_wave)
	return self


func shake() -> void:
	_shake = 6


func on_burn_wave(_hot: bool = false) -> void:
	_wave_delay = (position + Vector2(0, length + 8)).distance_to(wave_origin) / WAVE_SPEED


## ¿Le está dando ahora mismo la onda?
func ringing() -> bool:
	return _ring > 0.0


func current_dx() -> int:
	return AmbientFrames.crucible_dx(_k, 11 if _shake > 0 else amp)


func _process(delta: float) -> void:
	if _wave_delay >= 0.0:
		_wave_delay -= delta
		if _wave_delay < 0.0:
			_ring = RING_TIME
			shake()
			queue_redraw()
	elif _ring > 0.0:
		_ring -= delta
		if _ring <= 0.0:
			queue_redraw()
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
	var glow := 1 if (state != null and state.heat > 0.7) or _ring > 0.0 else 0
	var tex := AmbientFrames.crucible(_k, length, a, glow, use_index)
	draw_texture(tex, Vector2(-tex.get_width() / 2, 0))


func light_info() -> Dictionary:
	return {"pos": position + Vector2(current_dx(), length + 8), "radii": [8.0, 16.0, 26.0], "step": IDLE_STEPS + (RING_STEPS if _ring > 0.0 else 0.0)}
