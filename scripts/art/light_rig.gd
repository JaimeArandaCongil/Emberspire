class_name LightRig
extends Node
## Luz de escena en tiempo real (TEC · v0.4). Escribe los GLOBALES de shader que lee `shaders/palette_lit.gdshader`
## (declarados en project.godot [shader_globals]). Un LightRig por mundo (WorldView crea uno).
##
##   rig.heat = Game.forge_heat_ratio()           calor de la Forja 0..1 (radio y fuerza de su luz)
##   rig.burn(Vector2(60, 230))                   onda de quemar carta (sale de la Forja; los emisivos suben)
##   rig.low_hp = 0.8                             bordes de la escena más oscuros
##   var id := rig.add_light(pos, 90, 1.5)        luz móvil (antorcha, proyectil, golpe); máx. 4
##   rig.move_light(id, pos) · rig.remove_light(id)
##   rig.cold = true                              ambiente frío: rampas frías en toda la escena
##   rig.gold = true                              Resplandor: la luz cálida pasa a oro (cantos a la rampa `gold`, Forja +1 paso)
##   rig.set_mask(img, Rect2(0, 0, 640, 360))     máscara local de baja resolución (R8: 128 = 0 pasos, ±4)
##   rig.dim = 2                                  la sala entera baja N pasos (transición a recompensas, biblia §12; no alfa)
## Todo se expresa en PASOS de rampa; nada sale de la paleta.

const FLICKER_HZ := 12.0          # cadencia del parpadeo: la de una animación de pixel art
const MAX_LIGHTS := 4
const FLICKER_STEP := 0.12        # cambio máximo del parpadeo por tic, relativo a la amplitud
## C20: una luz móvil no salta de paso de golpe: su fuerza persigue el objetivo a esta velocidad (pasos/s). Un salto de 1
## paso de un brasero volteaba un disco entero de sillares en un fotograma; así el borde barre como un anillo en ~4 f.
const LIGHT_SLEW := 7.0
const GOLD_STEPS := 1.0           # pasos extra de la Forja y de las luces cálidas con Resplandor

## Posición y radio de la luz de la Forja (mundo 640×360; Forja de combate x 8–112, suelo y = 264).
@export var forge_pos := Vector2(60, 230)
@export var forge_radius := 320.0
## Pasos de diferencia en el centro entre calor 0 y calor 1 (la luz nominal, calor 0,5, ya va horneada).
@export var forge_range := 3.0
@export var flicker_amp := 0.6
@export var heat := 0.5:
	set(v):
		heat = clampf(v, 0.0, 1.0)
@export var low_hp := 0.0:
	set(v):
		low_hp = clampf(v, 0.0, 1.0)
		_dirty = true
@export var cold := false:
	set(v):
		cold = v
		_dirty = true
@export var gold := false:
	set(v):
		gold = v
		_dirty = true

## Pasos que baja toda la escena (0..4), emisivos incluidos. Usa la máscara global (constante) y `emit_pulse`.
@export var dim := 0:
	set(v):
		dim = clampi(v, 0, 4)
		_dim_dirty = true
		_dirty = true

var _dim_dirty := false
var _targets: Array = [NAN, NAN, NAN, NAN]   # fuerza objetivo de cada luz (move_light); la real la persigue
var _lights: Array = []           # [pos: Vector2, radius: float, steps: float, cold: bool] o null
var _burn_t := -1.0
var _burn_origin := Vector2.ZERO
var _burn_strength := 2.6
var _burn_speed := 1100.0
var _burn_len := 0.6
var _flicker := 0.0
var _flicker_acc := 0.0
var _rng := RandomNumberGenerator.new()
var _dirty := true
var _mask_tex: ImageTexture


static func ensure_globals() -> void:
	## La LUT no puede ir en project.godot (se construye de `Palette`): se fija aquí, una vez.
	RenderingServer.global_shader_parameter_set(&"palette_lut", Palette.build_lut())
	# Constantes de `palette_lit`: si la paleta se reordena, hay que actualizarlas allí.
	if Palette.index(&"fire") != 4 or Palette.index(&"gold") != 5 or Palette.index(&"hair") != 14 or Palette.index(&"hot") != 31:
		push_error("LightRig: los índices MAT_* de palette_lit no coinciden con Palette")


func _ready() -> void:
	ensure_globals()
	_rng.seed = 7
	for i in MAX_LIGHTS:
		_lights.append(null)
	_push()


## Onda de quemar carta: sale de `origin` a `speed` px/s, +`strength` pasos en el frente, dura `length` s.
func burn(origin: Vector2 = forge_pos, strength := 2.6, speed := 1100.0, length := 0.6) -> void:
	_burn_origin = origin
	_burn_strength = strength
	_burn_speed = speed
	_burn_len = length
	_burn_t = 0.0


func add_light(pos: Vector2, radius: float, steps: float, is_cold := false) -> int:
	for i in MAX_LIGHTS:
		if _lights[i] == null:
			_lights[i] = [pos, radius, steps, is_cold]
			_targets[i] = NAN
			_dirty = true
			return i
	push_warning("LightRig: máximo %d luces móviles" % MAX_LIGHTS)
	return -1


func move_light(id: int, pos: Vector2, steps := NAN) -> void:
	if id >= 0 and id < MAX_LIGHTS and _lights[id] != null:
		if _lights[id][0] != pos:
			_lights[id][0] = pos
			_dirty = true
		if not is_nan(steps):
			_targets[id] = steps


func remove_light(id: int) -> void:
	if id >= 0 and id < MAX_LIGHTS:
		_lights[id] = null
		_dirty = true


func set_mask(img: Image, rect: Rect2) -> void:
	if img == null:
		RenderingServer.global_shader_parameter_set(&"light_mask_on", 0.0)
		return
	if _mask_tex == null or _mask_tex.get_size() != Vector2(img.get_size()):
		_mask_tex = ImageTexture.create_from_image(img)
	else:
		_mask_tex.update(img)
	RenderingServer.global_shader_parameter_set(&"light_mask", _mask_tex)
	RenderingServer.global_shader_parameter_set(&"light_mask_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	RenderingServer.global_shader_parameter_set(&"light_mask_on", 1.0)


## Pasos de luz dinámica en un punto (lo mismo que calcula el shader; para pruebas y lógica de juego).
func steps_at(p: Vector2) -> float:
	var f := _forge_steps() * _fall(p, forge_pos, forge_radius)
	for l in _lights:
		if l != null:
			f += _light_steps(l) * _fall(p, l[0], l[1])
	return f


func _light_steps(l: Array) -> float:
	# El parpadeo de un brasero baja de 0 sin dejar de ser luz cálida; las sombras reales son de −1 o menos.
	var warm: bool = not bool(l[3]) and float(l[2]) > -1.0
	return float(l[2]) + (GOLD_STEPS if gold and warm else 0.0)


func _fall(p: Vector2, c: Vector2, r: float) -> float:
	return 0.0 if r <= 0.0 else clampf(1.0 - p.distance_to(c) / r, 0.0, 1.0)


func _forge_steps() -> float:
	return (heat - 0.5) * 2.0 * forge_range * 0.5 + _flicker + (GOLD_STEPS if gold else 0.0)


func _process(delta: float) -> void:
	_flicker_acc += delta
	if _flicker_acc >= 1.0 / FLICKER_HZ:
		_flicker_acc = fmod(_flicker_acc, 1.0 / FLICKER_HZ)
		# paseo aleatorio acotado, más vivo con más calor
		var amp := flicker_amp * (0.5 + heat)
		# C20: el radio de la Forja (320) es casi media sala; un salto grande de parpadeo hacía cruzar el redondeo a un
		# anillo enorme de piezas a la vez (pico de 18–21 mil píxeles en reposo). Paso máximo pequeño: anillos finos.
		_flicker = clampf(_flicker + _rng.randf_range(-FLICKER_STEP, FLICKER_STEP) * amp, -amp, amp)
		_dirty = true
	for i in MAX_LIGHTS:
		if _lights[i] != null and not is_nan(float(_targets[i])) and float(_lights[i][2]) != float(_targets[i]):
			_lights[i][2] = move_toward(float(_lights[i][2]), float(_targets[i]), LIGHT_SLEW * delta)
			_dirty = true
	if _burn_t >= 0.0:
		_burn_t += delta
		if _burn_t > _burn_len:
			_burn_t = -1.0
		_dirty = true
	if _dirty:
		_push()


func _push() -> void:
	_dirty = false
	var rs := RenderingServer
	rs.global_shader_parameter_set(&"forge_light", Vector4(forge_pos.x, forge_pos.y, forge_radius, _forge_steps()))
	rs.global_shader_parameter_set(&"forge_heat", heat)
	rs.global_shader_parameter_set(&"low_hp", low_hp)
	rs.global_shader_parameter_set(&"cold_bias", 1.0 if cold else (-1.0 if gold else 0.0))   # el frío manda sobre el oro
	var colds := Vector4.ZERO
	for i in MAX_LIGHTS:
		var l: Variant = _lights[i]
		var v := Vector4.ZERO
		if l != null:
			v = Vector4(l[0].x, l[0].y, l[1], _light_steps(l))
			colds[i] = 1.0 if l[3] else 0.0
		rs.global_shader_parameter_set(StringName("light_%d" % i), v)
	rs.global_shader_parameter_set(&"light_cold", colds)
	if _dim_dirty:
		_dim_dirty = false
		if dim > 0:
			# Máscara constante: R = 0,5 − pasos/8 (el shader la lee como ±4 pasos).
			var img := Image.create(4, 4, false, Image.FORMAT_R8)
			img.fill(Color(0.5 - dim / 8.0, 0, 0))
			set_mask(img, Rect2(-64, -64, 768, 488))
		else:
			set_mask(null, Rect2())
	if _burn_t >= 0.0:
		var fade := clampf(1.0 - _burn_t / _burn_len, 0.0, 1.0)
		rs.global_shader_parameter_set(&"burn_pulse", Vector4(_burn_origin.x, _burn_origin.y, _burn_t * _burn_speed, _burn_strength * fade))
		rs.global_shader_parameter_set(&"emit_pulse", (2 if _burn_t < _burn_len * 0.4 else (1 if fade > 0.0 else 0)) - dim)
	else:
		rs.global_shader_parameter_set(&"burn_pulse", Vector4.ZERO)
		rs.global_shader_parameter_set(&"emit_pulse", -dim)


func _exit_tree() -> void:
	# deja la escena en reposo para la siguiente pantalla
	_lights.fill(null)
	_burn_t = -1.0
	_flicker = 0.0
	heat = 0.5
	low_hp = 0.0
	cold = false
	gold = false
	dim = 0
	_push()
	RenderingServer.global_shader_parameter_set(&"light_mask_on", 0.0)
