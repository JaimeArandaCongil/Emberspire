class_name AmbientFlue
extends Node
## Chispas del tiro y de la rejilla (MV · v0.4): la producción de la Forja SUBE por la Torre.
## - Tiro (sala de tiro): emisor en la franja inferior del vano, `rate = 3 + 16·producción` chispas/s.
## - Rejilla del suelo (todas las salas): pavesas que suben, `rate = 0.5 + 5·producción`.
## - Quemar una carta: ráfaga de 12 chispas por el tiro y 6 por la rejilla.
## No dibuja nada: usa las ArtParticles que se le pasen (la del tiro va DETRÁS de la capa media).

var state: AmbientState
var back: ArtParticles        # detrás de la capa media (tiro)
var front: ArtParticles       # delante (rejilla)
var flue_rect := Rect2i()
var grate := Vector2i(-1, -1)
var _flue_em := -1
var _grate_em := -1


func setup(p_state: AmbientState, p_back: ArtParticles, p_front: ArtParticles, p_flue: Rect2i, p_grate: Vector2i) -> AmbientFlue:
	state = p_state
	back = p_back
	front = p_front
	flue_rect = p_flue
	grate = p_grate
	if back != null and flue_rect.size != Vector2i.ZERO:
		var band := Rect2(flue_rect.position.x, flue_rect.end.y - 12, flue_rect.size.x, 12)
		_flue_em = back.add_emitter(band, "ember", 0.0, Vector2.UP, 24.0)
	if front != null and grate.x >= 0:
		_grate_em = front.add_emitter(Rect2(grate.x - 22, grate.y - 6, 44, 6), "ember", 0.0, Vector2.UP, 30.0)
	if state != null:
		state.burned.connect(_on_burn)
	_apply()
	return self


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	var p := state.production if state != null else 0.4
	var dim := 0.5 if state != null and state.low_hp else 1.0
	if back != null and _flue_em >= 0:
		back.set_emitter_rate(_flue_em, (3.0 + 16.0 * p) * dim)
	if front != null and _grate_em >= 0:
		front.set_emitter_rate(_grate_em, (0.5 + 5.0 * p) * dim)


func _on_burn(hot: bool) -> void:
	var n := 18 if hot else 12
	if back != null and flue_rect.size != Vector2i.ZERO:
		back.burst(Vector2(flue_rect.get_center().x, flue_rect.end.y - 4), "ember", n, Vector2.UP, 40.0, 2.5)
	if front != null and grate.x >= 0:
		front.burst(Vector2(grate) + Vector2(0, -4), "spark", 6, Vector2.UP, 50.0, 0.6)
