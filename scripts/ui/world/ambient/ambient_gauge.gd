class_name AmbientGauge
extends Node2D
## Aguja del manómetro del fuelle (MV · v0.4): la presión = mezcla de calor y producción. Tiembla ±1 posición
## (de 13) y salta al máximo al quemar. Se dibuja píxel a píxel (sin rotar sprites). `position` = centro de la esfera.

var state: AmbientState
var _t := 0.0
var _pos := 6
var _rng := RandomNumberGenerator.new()


func setup(p_state: AmbientState) -> AmbientGauge:
	state = p_state
	_rng.seed = 11
	return self


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = _rng.randf_range(0.15, 0.4)
	var p := 0.5
	if state != null:
		p = clampf(state.heat * 0.5 + state.production * 0.5 + state.burn_pulse * 0.6, 0.0, 1.0)
	var target := int(roundf(p * 12.0)) + _rng.randi_range(-1, 1)
	var np := clampi(target, 0, 12)
	if np != _pos:
		_pos = np
		queue_redraw()


func _draw() -> void:
	var ang := PI * 0.8 + _pos * PI * 1.4 / 12.0
	var ink := Palette.color(&"iron", 1)
	var tip := Palette.color(&"fire", 4)
	for i in range(0, 6):
		var px := Vector2(roundf(cos(ang) * i), roundf(sin(ang) * i))
		draw_rect(Rect2(px, Vector2.ONE), tip if i == 5 else ink)
