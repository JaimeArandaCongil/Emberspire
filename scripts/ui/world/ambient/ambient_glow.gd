class_name AmbientGlow
extends Node2D
## Resplandor en la sala de tiro (MV · v0.4; biblia §11): halo escalonado de oro que sube por los nervios del tiro.
## Se dibuja detrás de la capa media. Sin Resplandor no dibuja nada. Las motas son de AmbientFlue y la llama, de AmbientBrazier.

const RIB_X := [343, 537]
const TOP := 46
const BOTTOM := 212
const PERIOD := 0.14

var state: AmbientState
var _t := 0.0
var _k := 0
var _was := false


func setup(p_state: AmbientState) -> AmbientGlow:
	state = p_state
	return self


func active() -> bool:
	return state != null and state.glow


func _process(delta: float) -> void:
	var on := active()
	if on != _was:
		_was = on
		queue_redraw()
	if not on:
		return
	_t += delta
	if _t >= PERIOD:
		_t -= PERIOD
		_k += 1
		queue_redraw()


func _draw() -> void:
	if not active():
		return
	for x: int in RIB_X:
		for y in range(TOP, BOTTOM):
			# Tramos que suben: dos pasos de oro y un hueco, siempre sobre el canto del nervio.
			var band := posmod(y + _k * 3, 28)
			if band < 10:
				draw_rect(Rect2(x, y, 1, 1), Palette.color(&"gold", 4 if band < 4 else 3))
				if band < 2:
					draw_rect(Rect2(x + 1, y, 1, 1), Palette.color(&"gold", 2))
