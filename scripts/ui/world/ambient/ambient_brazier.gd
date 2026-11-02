class_name AmbientBrazier
extends Node2D
## Brasero de pared vivo (MV · v0.4): llama (8 f · 100 ms), humo (8 f), pavesas (ArtParticles) y parpadeo de luz.
## Coordenadas en px de arte; `position` = ancla del brasero que publica BgAct1 (centro del cuenco).
## Estado: lee `state` (AmbientState). Calor → tamaño de llama y densidad de humo; quemar → la llama se inclina hacia
## el horno (izquierda) y escupe pavesas; PV bajos → llama menor y parpadeo irregular.
## Luz: `flicker_step` (−1, 0, +1) es lo que LightRig debe pasar al shader. Sin shader, `patches` (3 parches horneados
## del muro: radio −1/0/+1) se dibujan aquí para que la luz parpadee igual en la vista previa.

const FLICK := [0, 1, 0, -1, 1, 0, 1, -1]
## El shader redondea pasos·caída: con ±0,75 y radio 88 sólo cambian las piezas a menos de ~29 px de la llama.
## Con ±1 saltaría un disco de 44 px entero (más su canto): demasiado movimiento para un parpadeo en reposo.
const FLICKER_STEPS := 0.75

var state: AmbientState
var particles: ArtParticles
var phase := 0
var patches: Array = []      # [{"preview": Image}, …] ×3 (radio −1, 0, +1)
var patch_rect := Rect2i()
var use_patches := true
## Con `palette_lit` en `material`, dibuja los fotogramas de índice (llama con pulso emisivo, humo con luz).
var use_index := false
var flicker_step := 0

var _t := 0.0
var _frame := 0
var _flick_i := 0
var _flick_t := 0.0
var _ember_t := 0.4
var _patch_tex: Array = []
var _rng := RandomNumberGenerator.new()


func setup(p_state: AmbientState, p_particles: ArtParticles, p_phase: int, flicker: Dictionary = {}) -> AmbientBrazier:
	state = p_state
	particles = p_particles
	phase = p_phase
	_rng.seed = 7 + p_phase * 131
	_flick_i = p_phase % FLICK.size()
	if not flicker.is_empty():
		patch_rect = flicker["rect"]
		patches = flicker["frames"]
		for f: Dictionary in patches:
			_patch_tex.append(ImageTexture.create_from_image(f["preview"]))
	return self


func _process(delta: float) -> void:
	_t += delta
	var f := (int(_t / 0.1) + phase) % 8
	var redraw := f != _frame
	_frame = f
	_flick_t -= delta
	if _flick_t <= 0.0:
		_flick_i = (_flick_i + 1) % FLICK.size()
		var low := state != null and state.low_hp
		_flick_t = _rng.randf_range(0.08, 0.32) if low else _rng.randf_range(0.1, 0.2)
		var fs: int = FLICK[_flick_i]
		if low:
			fs = mini(fs, 0) - (1 if _rng.randf() < 0.3 else 0)
		if state != null and state.burn_pulse > 0.5:
			fs = 1
		flicker_step = clampi(fs, -1, 1)
		redraw = true
	_ember_t -= delta
	if _ember_t <= 0.0 and particles != null:
		var n := 1
		if state != null and state.burn_pulse > 0.3:
			n = 3
		particles.burst(position + Vector2(_rng.randi_range(-4, 4), -6), "ember", n, Vector2.UP, 50.0)
		_ember_t = _rng.randf_range(0.25, 0.8) * (0.6 if state != null and state.heat > 0.7 else 1.0)
	if redraw:
		queue_redraw()


func _lean() -> int:
	return -1 if state != null and state.burn_pulse > 0.25 else 0


func _size() -> float:
	if state == null:
		return 1.0
	if state.low_hp:
		return 0.8
	return 0.9 if state.heat < 0.35 else (1.0 if state.heat < 0.75 else 1.1)


func _draw() -> void:
	if use_patches and _patch_tex.size() == 3:
		var tex: Texture2D = _patch_tex[flicker_step + 1]
		draw_texture(tex, Vector2(patch_rect.position) - position)
	var dens := 1 if state != null and state.heat > 0.7 else 0
	var sm := AmbientFrames.smoke(_frame, dens, use_index)
	draw_texture(sm, Vector2(-AmbientFrames.SMOKE_BASE.x, -AmbientFrames.SMOKE_BASE.y - 30))
	var fl := AmbientFrames.flame(_frame, _lean(), _size(), use_index)
	draw_texture(fl, Vector2(-AmbientFrames.FLAME_BASE.x, -AmbientFrames.FLAME_BASE.y - 2))


## Datos para LightRig/shader: posición, radios de banda y desplazamiento de parpadeo.
func light_info() -> Dictionary:
	return {"pos": position + Vector2(0, -12), "radii": BgAct1.BRAZIER_R, "step": float(flicker_step) * FLICKER_STEPS}
