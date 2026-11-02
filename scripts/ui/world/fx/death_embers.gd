class_name DeathEmbers
extends Node2D
## Muerte de monstruo (MV · v0.4): sus brasas (los píxeles encendidos de su sprite) se desprenden y suben por el tiro,
## 1 px cada una, 1,2 s. `first_out` avisa cuando sale la primera: ahí, y no antes, la pantalla enseña «+Ascuas».
## API: docs/reviews/v04/mundo_vivo/api_vfx.md

signal first_out(world_pos: Vector2)
signal finished()

const DURATION := 1.2
const MAX_DELAY := 0.3
const MIN_EMBERS := 12
const STEPS: Array[int] = [6, 5, 5, 4, 3, 2]

var _batches: Array = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 23


## `source`: Texture2D, Image o Rect2 (en mundo). `top_left`: esquina del fotograma en mundo (se ignora con Rect2).
func play(source: Variant, top_left: Vector2, sink: Vector2, max_embers := 40) -> void:
	var pts := sample_points(source, top_left, max_embers)
	var embers: Array = []
	for p: Vector2 in pts:
		embers.append({"from": p, "delay": _rng.randf() * MAX_DELAY, "phase": _rng.randf() * TAU})
	# El más madrugador marca cuándo sale la primera brasa.
	_batches.append({"embers": embers, "sink": sink, "t": 0.0, "out": false})
	queue_redraw()


func playing() -> bool:
	return not _batches.is_empty()


## Puntos de mundo donde nacen las brasas: primero lo encendido del sprite y, si no llega, muestras de su cuerpo.
func sample_points(source: Variant, top_left: Vector2, max_embers: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if source is Rect2:
		var r: Rect2 = source
		for i in max_embers:
			out.append(r.position + Vector2(_rng.randf() * r.size.x, _rng.randf() * r.size.y))
		return out
	var img: Image = null
	if source is Image:
		img = source
	elif source is Texture2D:
		img = (source as Texture2D).get_image()
	if img == null or img.is_empty():
		return out
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var hot: Array[Vector2] = []
	var body: Array[Vector2] = []
	var is_index := _looks_like_index(img)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			var p := top_left + Vector2(x, y)
			if _is_ember(c, is_index):
				hot.append(p)
			else:
				body.append(p)
	_pick(hot, max_embers, out)
	if out.size() < MIN_EMBERS:
		_pick(body, mini(max_embers, MIN_EMBERS) - out.size(), out)
	return out


func _pick(from: Array[Vector2], count: int, into: Array[Vector2]) -> void:
	if from.is_empty() or count <= 0:
		return
	var stride := maxf(1.0, float(from.size()) / count)
	var i := 0.0
	var taken := 0
	while int(i) < from.size() and taken < count:
		into.append(from[int(i)])
		i += stride
		taken += 1


## En una textura de índice el alfa guarda el ancla, casi nunca 255; en una de color, siempre.
func _looks_like_index(img: Image) -> bool:
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var a := img.get_pixel(x, y).a8
			if a != 0 and a != 255:
				return true
	return false


func _is_ember(c: Color, is_index: bool) -> bool:
	if is_index:
		return (c.g8 & IndexFormat.F_EMISSIVE) != 0
	return c.r > 0.65 and c.g > 0.2 and c.b < 0.5 and c.r > c.g * 1.2


func _process(delta: float) -> void:
	if _batches.is_empty():
		return
	for b: Dictionary in _batches:
		b["t"] = float(b["t"]) + delta
		if not bool(b["out"]):
			for e: Dictionary in b["embers"]:
				if float(b["t"]) >= float(e["delay"]) + _flight():
					b["out"] = true
					first_out.emit(Vector2(b["sink"]))
					break
	var before := _batches.size()
	_batches = _batches.filter(func(b: Dictionary) -> bool: return float(b["t"]) < DURATION)
	for i in before - _batches.size():
		finished.emit()
	queue_redraw()


func _flight() -> float:
	return DURATION - MAX_DELAY


func _draw() -> void:
	for b: Dictionary in _batches:
		var t: float = b["t"]
		var sink: Vector2 = b["sink"]
		for e: Dictionary in b["embers"]:
			var u := (t - float(e["delay"])) / _flight()
			if u < 0.0 or u >= 1.0:
				continue
			var from: Vector2 = e["from"]
			var q := from.lerp(sink, u * u)
			q.x += sin(u * 9.0 + float(e["phase"])) * 3.0 * (1.0 - u)
			# Primero suben en vertical y luego el tiro las aspira.
			q.y = minf(q.y, from.y - u * 40.0)
			var step: int = STEPS[mini(STEPS.size() - 1, int(u * STEPS.size()))]
			draw_rect(Rect2(q.floor(), Vector2.ONE), Palette.color(&"fire", step))
