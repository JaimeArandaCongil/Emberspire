class_name ArtParticles
extends Node2D
## Partículas EN LA REJILLA DE ARTE (MV · v0.4). Sustituye a `UI.sparks`, `UI.dust` y `UI.fire_emitter` para el mundo.
## - Simula en coordenadas de arte (float) y dibuja cada partícula en floor(pos) · `art_px`: nunca hay medio píxel.
## - Pool fijo (MAX = 256 por defecto) sin asignaciones por fotograma; si se llena, se recicla la más vieja.
## - Color escalonado por edad con rampas de `Palette` (sin degradados continuos ni alfa).
## - Determinista con `seed_value`.
## Uso: dentro de WorldView (1 unidad = 1 px de arte) deja art_px = 1; fuera, pon el nodo bajo un padre con escala ×2.

signal emptied

const PRESETS := {
	# Chispa de impacto: sale disparada, cae con gravedad, se enfría.
	"spark": {"ramp": [[&"fire", 7], [&"fire", 6], [&"fire", 5], [&"fire", 4], [&"fire", 3]], "life": [0.35, 0.7],
		"speed": [60.0, 160.0], "gravity": Vector2(0, 260), "drag": 1.5, "streak": true},
	# Pavesa/ascua: sube con oscilación lateral y se apaga.
	"ember": {"ramp": [[&"fire", 6], [&"fire", 5], [&"fire", 4], [&"fire", 3], [&"fire", 2]], "life": [1.0, 2.2],
		"speed": [10.0, 26.0], "gravity": Vector2(0, -14), "drag": 0.4, "wobble": 9.0},
	# Fuego continuo (lenguas cortas sobre un brasero o el horno).
	"fire": {"ramp": [[&"fire", 7], [&"fire", 6], [&"fire", 5], [&"fire", 4]], "life": [0.25, 0.5],
		"speed": [14.0, 34.0], "gravity": Vector2(0, -40), "drag": 0.5, "wobble": 4.0},
	# Polvo/ceniza flotando en el aire.
	"dust": {"ramp": [[&"ash", 4], [&"ash", 5], [&"ash", 5], [&"ash", 4]], "life": [4.0, 7.0],
		"speed": [1.0, 4.0], "gravity": Vector2(0, -0.6), "drag": 0.1, "wobble": 2.0},
	# Copo de hollín que cae del techo.
	"soot": {"ramp": [[&"smoke", 1], [&"smoke", 2], [&"smoke", 2]], "life": [2.0, 2.6],
		"speed": [0.0, 2.0], "gravity": Vector2(0, 28), "drag": 0.9, "wobble": 3.0},
	# Nieve (acto 3 y tras las ventanas).
	"snow": {"ramp": [[&"sky", 9], [&"sky", 10]], "life": [3.0, 5.0], "speed": [6.0, 12.0], "gravity": Vector2(0, 8),
		"drag": 0.6, "wobble": 5.0},
	# Chispa fría (Bloqueo).
	"frost": {"ramp": [[&"frost_glow", 5], [&"frost_glow", 4], [&"frost_glow", 3], [&"frost_glow", 2]], "life": [0.3, 0.6],
		"speed": [50.0, 120.0], "gravity": Vector2(0, 200), "drag": 1.8, "streak": true},
}

@export var art_px := 1.0
@export var max_particles := 256
@export var seed_value := 1

var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _vx := PackedFloat32Array()
var _vy := PackedFloat32Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _ph := PackedFloat32Array()
var _preset := PackedInt32Array()
var _alive := 0
var _ramps: Array = []          # por preset: Array[Color]
var _pdefs: Array = []          # por preset: Dictionary
var _pid := {}                  # nombre → id
var _emitters: Array = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_setup()


func _ready() -> void:
	if _x.size() != max_particles:
		_setup()


## (Re)inicia el pool y los presets. Llamable antes de entrar en el árbol (pruebas).
func _setup() -> void:
	_rng.seed = seed_value
	_x.resize(max_particles)
	_y.resize(max_particles)
	_vx.resize(max_particles)
	_vy.resize(max_particles)
	_age.resize(max_particles)
	_life.resize(max_particles)
	_ph.resize(max_particles)
	_preset.resize(max_particles)
	_alive = 0
	for pname: String in PRESETS:
		register_preset(pname, PRESETS[pname])


## Registra un preset (o lo reemplaza). `def.ramp` = [[material, paso], …] de joven a vieja.
func register_preset(pname: String, def: Dictionary) -> void:
	var ramp: Array = []
	for e: Array in def["ramp"]:
		ramp.append(Palette.color(e[0], int(e[1])))
	if _pid.has(pname):
		_ramps[_pid[pname]] = ramp
		_pdefs[_pid[pname]] = def
		return
	_pid[pname] = _pdefs.size()
	_pdefs.append(def)
	_ramps.append(ramp)


func alive_count() -> int:
	return _alive


## Ráfaga en `pos` (px de arte, coordenadas locales). `spread_deg` alrededor de `dir`.
func burst(pos: Vector2, preset: String, count: int, dir: Vector2 = Vector2.UP, spread_deg: float = 180.0, speed_mul: float = 1.0) -> void:
	var id: int = _pid.get(preset, -1)
	if id < 0:
		push_warning("ArtParticles: preset desconocido '%s'" % preset)
		return
	var d: Dictionary = _pdefs[id]
	var base := dir.angle()
	for i in count:
		var a := base + deg_to_rad(_rng.randf_range(-spread_deg, spread_deg) * 0.5)
		var sp := _rng.randf_range(d["speed"][0], d["speed"][1]) * speed_mul
		_spawn(id, pos, Vector2.from_angle(a) * sp)


## Emisor continuo en un rectángulo (px de arte). Devuelve su id. `rate` = partículas/segundo.
func add_emitter(rect: Rect2, preset: String, rate: float, dir: Vector2 = Vector2.UP, spread_deg: float = 30.0) -> int:
	_emitters.append({"rect": rect, "id": _pid.get(preset, 0), "rate": rate, "acc": _rng.randf(), "dir": dir, "spread": spread_deg})
	return _emitters.size() - 1


func set_emitter_rate(i: int, rate: float) -> void:
	if i >= 0 and i < _emitters.size():
		_emitters[i]["rate"] = maxf(0.0, rate)


func clear() -> void:
	_alive = 0
	queue_redraw()


func _spawn(id: int, pos: Vector2, vel: Vector2) -> void:
	var i := _alive
	if _alive >= max_particles:
		# Recicla la más vieja (mayor fracción de vida consumida).
		var worst := 0.0
		i = 0
		for j in _alive:
			var f := _age[j] / _life[j]
			if f > worst:
				worst = f
				i = j
	else:
		_alive += 1
	var d: Dictionary = _pdefs[id]
	_x[i] = pos.x
	_y[i] = pos.y
	_vx[i] = vel.x
	_vy[i] = vel.y
	_age[i] = 0.0
	_life[i] = _rng.randf_range(d["life"][0], d["life"][1])
	_ph[i] = _rng.randf() * TAU
	_preset[i] = id


func step(delta: float) -> void:
	for e: Dictionary in _emitters:
		e["acc"] += float(e["rate"]) * delta
		while e["acc"] >= 1.0:
			e["acc"] -= 1.0
			var r: Rect2 = e["rect"]
			var p := r.position + Vector2(_rng.randf() * r.size.x, _rng.randf() * r.size.y)
			var d: Dictionary = _pdefs[e["id"]]
			var a := (e["dir"] as Vector2).angle() + deg_to_rad(_rng.randf_range(-1.0, 1.0) * float(e["spread"]) * 0.5)
			_spawn(e["id"], p, Vector2.from_angle(a) * _rng.randf_range(d["speed"][0], d["speed"][1]))
	var i := 0
	var had := _alive > 0
	while i < _alive:
		_age[i] += delta
		if _age[i] >= _life[i]:
			_alive -= 1
			_x[i] = _x[_alive]
			_y[i] = _y[_alive]
			_vx[i] = _vx[_alive]
			_vy[i] = _vy[_alive]
			_age[i] = _age[_alive]
			_life[i] = _life[_alive]
			_ph[i] = _ph[_alive]
			_preset[i] = _preset[_alive]
			continue
		var d: Dictionary = _pdefs[_preset[i]]
		var g: Vector2 = d["gravity"]
		var drag: float = d["drag"]
		_vx[i] += g.x * delta
		_vy[i] += g.y * delta
		_vx[i] *= maxf(0.0, 1.0 - drag * delta)
		_vy[i] *= maxf(0.0, 1.0 - drag * delta)
		var wob: float = d.get("wobble", 0.0)
		_x[i] += (_vx[i] + (sin(_age[i] * 3.0 + _ph[i]) * wob if wob > 0.0 else 0.0)) * delta
		_y[i] += _vy[i] * delta
		i += 1
	if had and _alive == 0:
		emptied.emit()


func _process(delta: float) -> void:
	step(delta)
	queue_redraw()


## Posición de dibujo (rejilla) de la partícula i: para pruebas.
func grid_pos(i: int) -> Vector2:
	return Vector2(floorf(_x[i]), floorf(_y[i])) * art_px


func _draw() -> void:
	for i in _alive:
		var ramp: Array = _ramps[_preset[i]]
		var t := _age[i] / _life[i]
		var c: Color = ramp[mini(ramp.size() - 1, int(t * ramp.size()))]
		var p := Vector2(floorf(_x[i]), floorf(_y[i])) * art_px
		draw_rect(Rect2(p, Vector2(art_px, art_px)), c)
		if _pdefs[_preset[i]].get("streak", false) and t < 0.4:
			# Estela de 1 px en la dirección opuesta al movimiento (sólo mientras va rápida).
			var back := Vector2(-signf(_vx[i]) if absf(_vx[i]) > absf(_vy[i]) else 0.0, -signf(_vy[i]) if absf(_vy[i]) >= absf(_vx[i]) else 0.0)
			draw_rect(Rect2(p + back * art_px, Vector2(art_px, art_px)), ramp[mini(ramp.size() - 1, int(t * ramp.size()) + 1)])


## Rampa de la paleta más parecida a un color legado (para migrar llamadas a `UI.sparks(color)`).
static func preset_for_color(c: Color) -> String:
	if c.b > c.r and c.b > 0.5:
		return "frost"
	return "spark"
