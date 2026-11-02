class_name HitFX
extends Node2D
## Firmas de golpe (MV · v0.4) en la rejilla de arte, con colores de `Palette`. Sustituyen a `UI.sparks` en los impactos.
## Tres tiempos: destello a valor máximo → forma → resto que se disipa. Hitstop, número y sonido son de la pantalla.
## API: docs/reviews/v04/mundo_vivo/api_vfx.md

const HEAVY_FROM := 20
const NORMAL_MS: Array[float] = [0.033, 0.05, 0.066]
const HEAVY_MS: Array[float] = [0.033, 0.05, 0.05, 0.066, 0.066]
const BLOCK_MS: Array[float] = [0.033, 0.033, 0.034]
const PLAYER_MS: Array[float] = [0.04, 0.05, 0.06]
const SWEEP_TIME := 0.18
const DIAGONALS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]

var state: AmbientState
var _fx: Array = []


func setup(p_state: AmbientState = null) -> HitFX:
	state = p_state
	return self


func strike(pos: Vector2, amount: int, biome_ramp: StringName = &"fire") -> void:
	if amount >= HEAVY_FROM:
		heavy(pos, biome_ramp)
	else:
		normal(pos, biome_ramp)
	if state != null:
		state.pulse_strike(amount)


func normal(pos: Vector2, biome_ramp: StringName = &"fire") -> void:
	_add(&"normal", pos, NORMAL_MS, biome_ramp)


func heavy(pos: Vector2, biome_ramp: StringName = &"fire") -> void:
	_add(&"heavy", pos, HEAVY_MS, biome_ramp)


func sweep(x0: float, x1: float, y: float) -> void:
	var fx := _add(&"sweep", Vector2(x0, y), [SWEEP_TIME * 0.25, SWEEP_TIME * 0.25, SWEEP_TIME * 0.25, SWEEP_TIME * 0.25] as Array[float], &"fire")
	fx["x1"] = x1


func blocked(pos: Vector2) -> void:
	_add(&"blocked", pos, BLOCK_MS, &"frost_glow")


func player_hit(pos: Vector2) -> void:
	_add(&"player", pos, PLAYER_MS, &"blood")


func active_count() -> int:
	return _fx.size()


func _add(kind: StringName, pos: Vector2, times: Array[float], ramp: StringName) -> Dictionary:
	var fx := {"kind": kind, "pos": pos.floor(), "t": 0.0, "f": 0, "times": times, "ramp": ramp}
	_fx.append(fx)
	queue_redraw()
	return fx


func _process(delta: float) -> void:
	if _fx.is_empty():
		return
	for fx: Dictionary in _fx:
		fx["t"] = float(fx["t"]) + delta
		var times: Array[float] = fx["times"]
		while int(fx["f"]) < times.size() and float(fx["t"]) >= times[int(fx["f"])]:
			fx["t"] = float(fx["t"]) - times[int(fx["f"])]
			fx["f"] = int(fx["f"]) + 1
	_fx = _fx.filter(func(fx: Dictionary) -> bool: return int(fx["f"]) < (fx["times"] as Array).size())
	queue_redraw()


func _draw() -> void:
	for fx: Dictionary in _fx:
		var f: int = fx["f"]
		var p := Vector2i(fx["pos"])
		match fx["kind"]:
			&"normal":
				_draw_normal(p, f, fx["ramp"])
			&"heavy":
				_draw_heavy(p, f, fx["ramp"])
			&"sweep":
				_draw_sweep(p, f, float(fx["x1"]))
			&"blocked":
				_draw_blocked(p, f)
			&"player":
				_draw_player(p, f)


func _px(x: int, y: int, c: Color) -> void:
	draw_rect(Rect2(x, y, 1, 1), c)


func _line(a: Vector2i, b: Vector2i, c: Color) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var q := Vector2(a).lerp(Vector2(b), float(i) / maxf(1.0, n)).round()
		_px(int(q.x), int(q.y), c)


func _ring(p: Vector2i, r: int, c: Color) -> void:
	var n := r * 8
	var last := Vector2i(-99999, -99999)
	for i in n:
		var a := TAU * i / n
		var q := Vector2i(p.x + int(roundf(cos(a) * r)), p.y + int(roundf(sin(a) * r)))
		if q != last:
			_px(q.x, q.y, c)
			last = q


## Estrella de cuatro puntas: `arm` = largo de cada brazo.
func _star(p: Vector2i, arm: int, core: Color, tip: Color) -> void:
	draw_rect(Rect2(p.x - 1, p.y - 1, 3, 3), core)
	for i in range(2, arm + 1):
		var c := core if i < arm else tip
		_px(p.x + i, p.y, c)
		_px(p.x - i, p.y, c)
		_px(p.x, p.y + i, c)
		_px(p.x, p.y - i, c)


func _shards(p: Vector2i, r0: int, r1: int, c: Color, extra := false) -> void:
	for d: Vector2i in DIAGONALS:
		_line(p + d * r0, p + d * r1, c)
	if extra:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_line(p + d * (r0 + 3), p + d * (r1 + 2), c)


func _draw_normal(p: Vector2i, f: int, ramp: StringName) -> void:
	match f:
		0:
			_star(p, 4, Palette.color(&"fire", 7), Palette.color(&"fire", 6))
		1:
			_ring(p, 6, Palette.color(&"fire", 5))
			_px(p.x, p.y, Palette.color(&"fire", 7))
		_:
			_shards(p, 4, 6, Palette.color(ramp, 4))


func _draw_heavy(p: Vector2i, f: int, ramp: StringName) -> void:
	match f:
		0:
			_star(p, 6, Palette.color(&"fire", 7), Palette.color(&"fire", 6))
			# Líneas de velocidad: 1 fotograma.
			for dy: int in [-7, -3, 3, 7]:
				_line(Vector2i(p.x - 22, p.y + dy), Vector2i(p.x - 9, p.y + dy), Palette.color(&"fire", 6))
				_line(Vector2i(p.x + 9, p.y - dy), Vector2i(p.x + 22, p.y - dy), Palette.color(&"fire", 6))
		1:
			_star(p, 4, Palette.color(&"fire", 7), Palette.color(&"fire", 5))
			_ring(p, 7, Palette.color(&"fire", 6))
		2:
			_ring(p, 10, Palette.color(&"fire", 5))
			_shards(p, 3, 6, Palette.color(&"fire", 6))
		3:
			_shards(p, 6, 10, Palette.color(ramp, 4), true)
		_:
			_shards(p, 10, 12, Palette.color(&"fire", 3), true)


func _draw_sweep(p: Vector2i, f: int, x1: float) -> void:
	var span := x1 - float(p.x)
	var head := float(p.x) + span * float(f + 1) * 0.25
	var ramp_steps: Array[int] = [7, 6, 5, 3]
	var length := int(absf(span) * 0.32) + 12
	for i in length:
		var x := int(head) - i
		if x < p.x:
			break
		var u := float(i) / length
		var y := p.y + int(roundf(sin(u * PI) * -8.0))
		var c := Palette.color(&"fire", ramp_steps[mini(3, int(u * 4.0))])
		var thick := 3 - int(u * 3.0)
		draw_rect(Rect2(x, y, 1, maxi(1, thick)), c)


func _hex(p: Vector2i, r: int, c: Color) -> void:
	var prev := Vector2i.ZERO
	for i in 7:
		var a := PI / 6.0 + TAU * i / 6.0
		var q := p + Vector2i(int(roundf(cos(a) * r)), int(roundf(sin(a) * r)))
		if i > 0:
			_line(prev, q, c)
		prev = q


func _draw_blocked(p: Vector2i, f: int) -> void:
	match f:
		0:
			_hex(p, 6, Palette.color(&"frost_glow", 3))
			draw_rect(Rect2(p.x - 1, p.y - 1, 3, 3), Palette.color(&"frost_glow", 5))
		1:
			_hex(p, 8, Palette.color(&"frost_glow", 3))
		_:
			_hex(p, 9, Palette.color(&"frost_glow", 2))


func _draw_player(p: Vector2i, f: int) -> void:
	var c := Palette.color(&"blood", 4 - f)
	for i in 6:
		var a := TAU * (float(i) + 0.3) / 6.0
		var r0 := 3 + f * 3
		var d := Vector2(cos(a), sin(a))
		_line(p + Vector2i((d * r0).round()), p + Vector2i((d * (r0 + 3)).round()), c)
