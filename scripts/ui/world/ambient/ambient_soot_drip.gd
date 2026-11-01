class_name AmbientSootDrip
extends Node2D
## Goteo de hollín bajo las vigas (MV · v0.4): en cada punto se forma una gota (3 fotogramas: 1, 2 y 3 px) cada
## 2–5 s; al soltarse cae como copo («soot» en ArtParticles). Nunca durante el turno enemigo si `paused`.

var particles: ArtParticles
var points: Array = []
var paused := false

var _timers: Array = []
var _stage: Array = []
var _rng := RandomNumberGenerator.new()


func setup(p_particles: ArtParticles, p_points: Array, p_seed: int = 3) -> AmbientSootDrip:
	particles = p_particles
	points = p_points
	_rng.seed = p_seed
	for i in points.size():
		_timers.append(_rng.randf_range(0.5, 4.0))
		_stage.append(0)
	return self


func _process(delta: float) -> void:
	if paused:
		return
	var changed := false
	for i in points.size():
		_timers[i] -= delta
		if _timers[i] > 0.0:
			continue
		_stage[i] += 1
		changed = true
		if _stage[i] > 3:
			_stage[i] = 0
			_timers[i] = _rng.randf_range(2.0, 5.0)
			if particles != null:
				particles.burst(Vector2(points[i]) + Vector2(0, 3), "soot", 1, Vector2.DOWN, 10.0)
		else:
			_timers[i] = 0.18
	if changed:
		queue_redraw()


func _draw() -> void:
	var c1 := Palette.color(&"smoke", 1)
	var c2 := Palette.color(&"smoke", 2)
	for i in points.size():
		var s: int = _stage[i]
		var p: Vector2i = points[i]
		for k in s:
			draw_rect(Rect2(p.x, p.y + k, 1, 1), c1 if k < s - 1 else c2)
