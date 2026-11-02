class_name BurnFX
extends Node2D
## QUEMAR UNA CARTA, momento estrella (MV · v0.4). La carta alimenta el edificio entero, y se ve:
##    0 ms  inspiración: las llamas de la sala se inclinan y la Forja abre la boca.
##   80 ms  la carta vuela (la mueve la pantalla) soltando 4 copos de papel ardiendo.
##  340 ms  impacto: boca en blanco, silueta de la carta, onda de luz. Señal `impact` (sacudida y hitstop los pone la pantalla).
## 340–700  columna del color del tipo de carta en la junta de tiro; conducto encendido brida a brida; al final, tiro y rejilla.
##  380 ms  monedas-brasa de 3×3 de la chimenea al contador.
## En caliente: columna doble, boca 4 f en blanco, sacudida 8 y 1 f del Espíritu de la Forja en el humo.
## Todo se dibuja en la rejilla con colores de `Palette`. API: docs/reviews/v04/mundo_vivo/api_vfx.md

signal impact(hot: bool, shake_px: float, hitstop_s: float)
signal interactive()
signal coin_arrived()
signal finished()

const FLIGHT_START := 0.08
const FLIGHT_TIME := 0.26
const T_IMPACT := 0.34
const T_INTERACTIVE := 0.35
const T_COINS := 0.38
const T_END := 0.9
const COLUMN_FRAME_S := 0.045
const COLUMN_FRAMES := 8
const COLUMN_W := 16
const COLUMN_H := 40
const FLANGE_STEP_S := 0.06
const FLANGE_GLOW_S := 0.2
const COIN_TIME := 0.42
const RUNE_TIME := 0.6
const RUNE_DELAY := 0.36
## Bridas del conducto, de la Forja al muro. Coinciden con `BgAct1._pipe_intake` y `BgForge._bellows`.
const FLANGES: Array[Rect2i] = [Rect2i(97, 192, 16, 4), Rect2i(97, 160, 16, 4), Rect2i(97, 110, 16, 4), Rect2i(144, 61, 4, 16),
	Rect2i(206, 61, 4, 16), Rect2i(236, 58, 8, 22)]
## Tramo de cobre que recorre el calor para llegar a cada brida.
const PIPE_SEGMENTS: Array[Rect2i] = [Rect2i(100, 196, 10, 14), Rect2i(100, 164, 10, 28), Rect2i(100, 114, 10, 46), Rect2i(100, 64, 44, 10),
	Rect2i(148, 64, 58, 10), Rect2i(210, 64, 26, 10)]
const DIGITS := {1: ["010", "110", "010", "010", "111"], 2: ["110", "001", "010", "100", "111"], 3: ["110", "001", "010", "001", "110"],
	4: ["101", "101", "111", "001", "001"], 5: ["111", "100", "110", "001", "110"], 6: ["011", "100", "110", "101", "010"],
	7: ["111", "001", "010", "010", "010"], 8: ["010", "101", "010", "101", "010"], 9: ["010", "101", "011", "001", "110"]}

var forge: CombatForge
var state: AmbientState
var rig: LightRig
var particles: ArtParticles

var _active := false
var _t := 0.0
var _hot := false
var _type := "attack"
var _origin := Vector2.ZERO
var _coin_target := Vector2(-1, -1)
var _rune := 0
var _rune_t := -1.0
var _flakes := 0
var _light := -1
var _did := {}
var _coins: Array = []
var _coin_sent := false


func setup(p_forge: CombatForge, p_state: AmbientState, p_rig: LightRig = null) -> BurnFX:
	forge = p_forge
	state = p_state
	rig = p_rig
	if particles == null:
		particles = ArtParticles.new()
		particles.name = "Paper"
		particles.seed_value = 31
		add_child(particles)
	return self


## Arco de vuelo de la carta en mundo: pasa por detrás y por encima de la heroína. `t` 0..1.
static func flight_point(origin: Vector2, mouth: Vector2, t: float) -> Vector2:
	var u := clampf(t, 0.0, 1.0)
	var e := u * u * (3.0 - 2.0 * u)
	var ctrl := Vector2((origin.x + mouth.x) * 0.5, minf(origin.y, mouth.y) - 70.0)
	return origin.lerp(ctrl, e).lerp(ctrl.lerp(mouth, e), e)


func play(card_type: String, hot: bool, origin: Vector2, coin_target := Vector2(-1, -1), mastery_level := 0) -> void:
	_release_light()
	_active = true
	_t = 0.0
	_hot = hot
	_type = card_type
	_origin = origin
	_coin_target = coin_target
	_rune = mastery_level
	_rune_t = -1.0
	_flakes = 0
	_did.clear()
	_coins.clear()
	_coin_sent = false
	if state != null:
		state.pulse_inhale()
	if forge != null:
		forge.swallow(T_IMPACT)
	queue_redraw()


## La maestría sube después de quemar: añade la runa al efecto en curso.
func show_mastery(level: int) -> void:
	_rune = level
	if not _active:
		_active = true
		_t = T_END
		_rune_t = 0.0


func is_playing() -> bool:
	return _active


func _once(key: StringName, at: float) -> bool:
	if _t < at or _did.has(key):
		return false
	_did[key] = true
	return true


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	if _rune_t >= 0.0:
		_rune_t += delta
	# Copos de papel ardiendo: uno cada 60 ms durante el vuelo.
	while _flakes < 4 and _t >= FLIGHT_START + 0.02 + _flakes * 0.06 and particles != null:
		var u := (_t - FLIGHT_START) / FLIGHT_TIME
		particles.burst(flight_point(_origin, _mouth(), u), "paper", 1, Vector2.DOWN, 120.0)
		_flakes += 1
	if _once(&"impact", T_IMPACT):
		_on_impact()
	if _once(&"interactive", T_INTERACTIVE):
		interactive.emit()
	if _once(&"coins", T_COINS):
		_launch_coins()
	if _once(&"column_end", T_IMPACT + COLUMN_FRAME_S * COLUMN_FRAMES):
		_release_light()
	if _once(&"flue", T_IMPACT + FLANGE_STEP_S * FLANGES.size()) and state != null:
		state.pulse_flue(_hot)
	if _once(&"rune", T_IMPACT + RUNE_DELAY) and _rune > 0:
		_rune_t = 0.0
	_step_coins(delta)
	if _t >= T_END and (_rune_t < 0.0 or _rune_t >= RUNE_TIME):
		_active = false
		_release_light()
		finished.emit()
	queue_redraw()


func _mouth() -> Vector2:
	return forge.mouth_pos() if forge != null else Vector2(BgForge.CX, 226)


func _chimney() -> Vector2:
	return forge.chimney_top() if forge != null else Vector2(BgForge.CX, BgForge.GAP_BOTTOM)


func _on_impact() -> void:
	if forge != null:
		forge.flash(4 if _hot else 2)
	if state != null:
		state.pulse_burn(_hot, false)
	if rig != null:
		_light = rig.add_light(_chimney() + Vector2(0, -20), 96.0, 4.0 if _hot else 3.0)
	impact.emit(_hot, 8.0 if _hot else 4.0, 0.06)


func _release_light() -> void:
	if rig != null and _light >= 0:
		rig.remove_light(_light)
	_light = -1


func _launch_coins() -> void:
	if _coin_target.x < 0.0:
		_coin_sent = true
		coin_arrived.emit()
		return
	var n := 8 if _hot else 5
	for i in n:
		_coins.append({"t": -0.04 * i, "from": _chimney() + Vector2(float((i * 7) % 13) - 6.0, -30.0)})


func _step_coins(delta: float) -> void:
	for c: Dictionary in _coins:
		c["t"] = float(c["t"]) + delta
		if float(c["t"]) >= COIN_TIME and not _coin_sent:
			_coin_sent = true
			coin_arrived.emit()
	_coins = _coins.filter(func(c: Dictionary) -> bool: return float(c["t"]) < COIN_TIME)


## Colores [corazón, cuerpo, borde] de la columna según el tipo de carta.
static func column_palette(card_type: String) -> Array[Color]:
	match card_type:
		"attack":
			return [Palette.color(&"fire", 6), Palette.color(&"fire", 3), Palette.color(&"fire", 2)]
		"skill":
			return [Palette.color(&"frost_glow", 3), Palette.color(&"fire", 5), Palette.color(&"fire", 3)]
		"power":
			return [Palette.color(&"gold", 5), Palette.color(&"gold", 4), Palette.color(&"gold", 2)]
		"fuel":
			return [Palette.color(&"fire", 7), Palette.color(&"fire", 5), Palette.color(&"fire", 4)]
	return [Palette.color(&"ash", 7), Palette.color(&"fire", 3), Palette.color(&"smoke", 3)]


func _draw() -> void:
	if not _active:
		return
	var since := _t - T_IMPACT
	if since >= 0.0:
		var f := int(since / COLUMN_FRAME_S)
		if f < COLUMN_FRAMES:
			var base := _chimney()
			if _hot:
				_draw_column(int(base.x) - 9, int(base.y), f, 11, 0.8)
				_draw_column(int(base.x) + 9, int(base.y), f, 23, 0.8)
			else:
				_draw_column(int(base.x), int(base.y), f, 11)
		if _hot and f == 3:
			_draw_spirit(base_spirit())
		_draw_conduit(since)
	for c: Dictionary in _coins:
		_draw_coin(c)
	if _rune_t >= 0.0 and _rune_t < RUNE_TIME:
		_draw_rune()


func base_spirit() -> Vector2i:
	return Vector2i(BgForge.CX + 24, 86)


## Columna de 16×40 px, 8 fotogramas: nace, llena la junta y se rompe hacia arriba, aspirada por la campana.
## Cada borde ondula por su cuenta y el dibujo sube con los fotogramas: masa de fuego, no una cinta.
func _draw_column(cx: int, bottom: int, f: int, sd: int, size := 1.0) -> void:
	var pal := column_palette(_type)
	var hgt: int = [14, 28, COLUMN_H, COLUMN_H, COLUMN_H, COLUMN_H, COLUMN_H, COLUMN_H][f]
	var cut: int = [0, 0, 0, 0, 0, 4, 14, 26][f]
	for i in range(cut, hgt):
		var up := float(i) / COLUMN_H
		var sc := float(i - f * 6)
		var half := float(COLUMN_W) * 0.5 * (1.0 - up * 0.3) * size
		if i >= hgt - 7:
			half *= float(hgt - i) / 7.0
		if i < cut + 4 and cut > 0:
			half *= float(i - cut + 1) / 4.0
		var left := half + sin(sc * 0.37 + sd) * 1.4 + sin(sc * 0.91 + sd * 2.0)
		var right := half + sin(sc * 0.29 + sd * 3.0 + 1.0) * 1.4 + sin(sc * 0.77 + sd)
		var x0 := cx - maxi(1, int(roundf(left)))
		var x1 := cx + maxi(1, int(roundf(right)))
		var y := bottom - 1 - i
		draw_rect(Rect2(x0, y, x1 - x0, 1), pal[2])
		var inset := 1 + int(roundf(1.0 + sin(sc * 0.53 + sd)))
		if x1 - x0 > inset * 2:
			draw_rect(Rect2(x0 + inset, y, x1 - x0 - inset * 2, 1), pal[1])
		# El corazón se deshace hacia arriba, a jirones.
		var core_w := int(roundf(float(x1 - x0) * (0.5 - up * 0.3) + sin(sc * 0.61 + sd) * 1.5))
		if core_w > 0 and BgCanvas.hash3(int(sc) / 3, 0, sd) > up * 0.55:
			var mid := (x0 + x1) / 2 + int(roundf(sin(sc * 0.23 + sd)))
			draw_rect(Rect2(mid - core_w / 2, y, core_w, 1), pal[0])


## Calor que recorre el conducto: cada brida y su tramo se encienden 1 paso por 60 ms y se enfrían.
func _draw_conduit(since: float) -> void:
	for i in FLANGES.size():
		var local := since - i * FLANGE_STEP_S
		if local < 0.0 or local > FLANGE_GLOW_S:
			continue
		var bright := local < FLANGE_GLOW_S * 0.5
		var seg: Rect2i = PIPE_SEGMENTS[i]
		var horizontal := seg.size.x > seg.size.y
		var glow_a := Palette.color(&"copper", 10 if bright else 8)
		var glow_b := Palette.color(&"copper", 8 if bright else 6)
		if horizontal:
			draw_rect(Rect2(seg.position.x, seg.position.y + 3, seg.size.x, 2), glow_a)
			draw_rect(Rect2(seg.position.x, seg.position.y + 5, seg.size.x, 1), glow_b)
		else:
			draw_rect(Rect2(seg.position.x + 3, seg.position.y, 2, seg.size.y), glow_a)
			draw_rect(Rect2(seg.position.x + 5, seg.position.y, 1, seg.size.y), glow_b)
		var fl: Rect2i = FLANGES[i]
		draw_rect(Rect2(fl), Palette.color(&"fire", 5 if bright else 4))
		var inner := fl.grow(-1)
		if inner.size.x > 0 and inner.size.y > 0:
			draw_rect(Rect2(inner), Palette.color(&"fire", 6 if bright else 5))


func _draw_coin(c: Dictionary) -> void:
	var t: float = c["t"]
	if t < 0.0:
		return
	var u := t / COIN_TIME
	var from: Vector2 = c["from"]
	var ctrl := Vector2(lerpf(from.x, _coin_target.x, 0.35), minf(from.y, _coin_target.y) - 10.0)
	var p := from.lerp(ctrl, u).lerp(ctrl.lerp(_coin_target, u), u).floor()
	draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 3)), Palette.color(&"fire", 5))
	draw_rect(Rect2(p + Vector2(0, 1), Vector2(3, 1)), Palette.color(&"fire", 5))
	draw_rect(Rect2(p + Vector2(1, 1), Vector2.ONE), Palette.color(&"fire", 7))


## El Espíritu de la Forja: 1 fotograma de silueta en el humo, sólo en caliente.
func _draw_spirit(at: Vector2i) -> void:
	var ink := Palette.color(&"smoke", 1)
	var rows := [[3, 2], [2, 4], [2, 5], [2, 4], [3, 3], [1, 7], [0, 9], [0, 9], [1, 7], [1, 7], [2, 6], [2, 5], [3, 4], [3, 3], [4, 2], [4, 1]]
	for i in rows.size():
		var r: Array = rows[i]
		draw_rect(Rect2(at.x + int(r[0]), at.y + i, int(r[1]), 1), ink)
	draw_rect(Rect2(at.x + 3, at.y + 2, 1, 1), Palette.color(&"fire", 7))
	draw_rect(Rect2(at.x + 5, at.y + 2, 1, 1), Palette.color(&"fire", 7))


## Runa de 8×8 con el nivel de Maestría, flotando en la junta de tiro.
func _draw_rune() -> void:
	var at := Vector2i(BgForge.CX - 4, 88 - int(_rune_t * 10.0))
	var edge := Palette.color(&"gold", 5 if _rune_t < RUNE_TIME * 0.7 else 3)
	var dark := Palette.color(&"gold", 1)
	draw_rect(Rect2(at.x - 1, at.y - 1, 9, 9), edge)
	draw_rect(Rect2(at.x, at.y, 7, 7), dark)
	var rows: Array = DIGITS.get(clampi(_rune, 1, 9), DIGITS[1])
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(at.x + 2 + x, at.y + 1 + y, 1, 1), Palette.color(&"gold", 5))
