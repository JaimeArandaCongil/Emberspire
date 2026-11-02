class_name SummonFX
extends Node2D
## Invocación (MV · v0.4): el suelo se agrieta 3 f bajo el punto de aparición, polvo de ceniza a los lados y el invocado
## emerge de abajo arriba (lo hace el luchador, a través de `reveal`). 400 ms. API: docs/reviews/v04/mundo_vivo/api_vfx.md

signal finished()

const DURATION := 0.4
const CRACK_FRAME_S := 0.04
const REVEAL_FROM := 0.12

var particles: ArtParticles
var _fx: Array = []


func _ready() -> void:
	_ensure_particles()


func _ensure_particles() -> void:
	if particles == null:
		particles = ArtParticles.new()
		particles.name = "Dust"
		particles.seed_value = 41
		add_child(particles)


## `reveal.call(f)` recibe f 0→1 durante la fase de emerger; 1 está garantizado al terminar.
func play(foot: Vector2, width: int, reveal: Callable = Callable()) -> void:
	_ensure_particles()
	_fx.append({"foot": foot.floor(), "w": maxi(12, width), "t": 0.0, "reveal": reveal, "dust": false})
	queue_redraw()


func playing() -> bool:
	return not _fx.is_empty()


func _process(delta: float) -> void:
	if _fx.is_empty():
		return
	for fx: Dictionary in _fx:
		fx["t"] = float(fx["t"]) + delta
		var t: float = fx["t"]
		var foot: Vector2 = fx["foot"]
		var half := float(fx["w"]) * 0.5
		if not bool(fx["dust"]) and t >= CRACK_FRAME_S * 2.0:
			fx["dust"] = true
			particles.burst(foot + Vector2(-half, -2), "puff", 5, Vector2.LEFT, 60.0)
			particles.burst(foot + Vector2(half, -2), "puff", 5, Vector2.RIGHT, 60.0)
		var rv: Callable = fx["reveal"]
		if rv.is_valid() and t >= REVEAL_FROM:
			rv.call(clampf((t - REVEAL_FROM) / (DURATION - REVEAL_FROM), 0.0, 1.0))
	var keep: Array = []
	for fx: Dictionary in _fx:
		if float(fx["t"]) < DURATION:
			keep.append(fx)
		else:
			finished.emit()
	_fx = keep
	queue_redraw()


func _draw() -> void:
	var dark := Palette.color(&"furnace_brick", 1)
	for fx: Dictionary in _fx:
		var t: float = fx["t"]
		var foot := Vector2i(fx["foot"])
		var half := int(fx["w"]) / 2
		var f := mini(2, int(t / CRACK_FRAME_S))
		var reach := half * (f + 1) / 3
		var glow := Palette.color(&"fire", 4 if t < DURATION * 0.5 else 2)
		for side: int in [-1, 1]:
			var y := foot.y
			for i in reach:
				var x := foot.x + side * i
				if i % 5 == 4:
					y += 1 if (i / 5 + side) % 2 == 0 else 0
				draw_rect(Rect2(x, y, 1, 2), dark)
				if i < reach - 2:
					draw_rect(Rect2(x, y, 1, 1), glow)
			# Ramales.
			if f >= 1:
				for b in 3:
					draw_rect(Rect2(foot.x + side * (half / 3 + b), foot.y + 2 + b, 1, 1), dark)
			if f >= 2:
				for b in 3:
					draw_rect(Rect2(foot.x + side * (half * 2 / 3 - b), foot.y + 2 + b, 1, 1), dark)
