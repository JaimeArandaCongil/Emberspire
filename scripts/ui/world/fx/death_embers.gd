class_name DeathEmbers
extends Node2D
## Muerte de monstruo (MV · v0.4): sus brasas (los píxeles encendidos de su sprite) se desprenden y suben por el tiro,
## 1,2 s. `first_out` avisa cuando sale la primera: ahí, y no antes, la pantalla enseña «+Ascuas».
## F2-VIDA (C18): cada brasa es una pieza irregular de 2–4 px con una estela de 1 px detrás, nunca un orbe redondo.
## `fly(from, to, count)`: las Ascuas que van al contador también vuelan como brasas del mundo (sustituye a los orbes
## de 12×12 de `main.fly_embers`).
## API: docs/reviews/v04/mundo_vivo/api_vfx.md

signal first_out(world_pos: Vector2)
signal finished()

const DURATION := 1.2
const MAX_DELAY := 0.3
const MIN_EMBERS := 12
const STEPS: Array[int] = [6, 5, 5, 4, 3, 2]
## Formas de brasa: [dx, dy, pasos menos que el núcleo]. 2–4 px, ninguna simétrica.
const SHAPES := [
	[[0, 0, 0], [1, 0, 1]],
	[[0, 0, 0], [0, 1, 1]],
	[[0, 0, 0], [1, 0, 1], [0, 1, 2]],
	[[0, 0, 0], [1, 0, 1], [1, 1, 2], [0, 1, 1]],
	[[0, 0, 0], [1, 1, 1], [1, 0, 2]],
	[[0, 0, 0], [-1, 0, 1], [0, 1, 2]],
]
const FLY_TIME := 0.6

var _batches: Array = []
var _flights: Array = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 23


## `source`: Texture2D, Image o Rect2 (en mundo). `top_left`: esquina del fotograma en mundo (se ignora con Rect2).
func play(source: Variant, top_left: Vector2, sink: Vector2, max_embers := 40) -> void:
	var pts := sample_points(source, top_left, max_embers)
	var embers: Array = []
	for p: Vector2 in pts:
		embers.append({"from": p, "delay": _rng.randf() * MAX_DELAY, "phase": _rng.randf() * TAU, "shape": _rng.randi() % SHAPES.size()})
	# El más madrugador marca cuándo sale la primera brasa.
	_batches.append({"embers": embers, "sink": sink, "t": 0.0, "out": false})
	queue_redraw()


func playing() -> bool:
	return not _batches.is_empty()


## Ascuas hacia el contador (mundo → mundo): `count` brasas con salida escalonada; llegan en `FLY_TIME` s.
func fly(from: Vector2, to: Vector2, count := 8) -> void:
	var embers: Array = []
	for i in count:
		var off := Vector2(_rng.randi_range(-10, 10), _rng.randi_range(-10, 6))
		embers.append({"from": from + off, "delay": i * 0.03, "bend": _rng.randf_range(-50.0, 50.0), "shape": _rng.randi() % SHAPES.size()})
	_flights.append({"embers": embers, "to": to, "t": 0.0})
	queue_redraw()


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
	if not _flights.is_empty():
		for f: Dictionary in _flights:
			f["t"] = float(f["t"]) + delta
		_flights = _flights.filter(func(f: Dictionary) -> bool: return float(f["t"]) < FLY_TIME + 0.4)
		queue_redraw()
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
			var q := _rise(e, sink, u)
			var prev := _rise(e, sink, maxf(0.0, u - 0.06))
			var step: int = STEPS[mini(STEPS.size() - 1, int(u * STEPS.size()))]
			# Se encogen al apagarse: forma completa hasta la mitad del vuelo, luego sólo núcleo y estela.
			_draw_ember(q, prev, int(e["shape"]) if u < 0.6 else 1, step)
	for f: Dictionary in _flights:
		var to: Vector2 = f["to"]
		for e: Dictionary in f["embers"]:
			var u := (float(f["t"]) - float(e["delay"])) / FLY_TIME
			if u < 0.0 or u >= 1.0:
				continue
			var q := _arc(e, to, u)
			var prev := _arc(e, to, maxf(0.0, u - 0.08))
			_draw_ember(q, prev, int(e["shape"]), 6 if u < 0.5 else 5)


func _rise(e: Dictionary, sink: Vector2, u: float) -> Vector2:
	var from: Vector2 = e["from"]
	var q := from.lerp(sink, u * u)
	q.x += sin(u * 9.0 + float(e["phase"])) * 3.0 * (1.0 - u)
	# Primero suben en vertical y luego el tiro las aspira.
	q.y = minf(q.y, from.y - u * 40.0)
	return q


func _arc(e: Dictionary, to: Vector2, u: float) -> Vector2:
	var from: Vector2 = e["from"]
	var k := u * u
	var mid := from.lerp(to, 0.5) + Vector2(float(e["bend"]), 40.0)
	return from.lerp(mid, k).lerp(mid.lerp(to, k), k)


## Brasa irregular en `q` con estela de 1 px hacia `prev` (2 px como máximo, dos pasos más apagada).
func _draw_ember(q: Vector2, prev: Vector2, shape: int, step: int) -> void:
	var p := q.floor()
	var d := (prev - q)
	if d.length() >= 1.0:
		var dir := d.normalized()
		for i in 2:
			var tp := (q + dir * (2.0 + i)).floor()
			draw_rect(Rect2(tp, Vector2.ONE), Palette.color(&"fire", maxi(1, step - 2 - i)))
	for px: Array in SHAPES[shape]:
		draw_rect(Rect2(p + Vector2(px[0], px[1]), Vector2.ONE), Palette.color(&"fire", maxi(1, step - int(px[2]))))
