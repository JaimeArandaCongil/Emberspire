class_name Act1RoomView
extends Node2D
## Sala del acto 1 lista para usar (MV · v0.4), en px de arte (1 unidad = 1 px de 640×360). Fuera de WorldView,
## ponla bajo un padre con escala ×2 entera.
## Orden de dibujo: cielo → tiro/corredor → chispas del tiro → capa media (+parches de luz) → ambiente →
## `actors` (heroína, Forja, enemigos: los pone la pantalla) → partículas delanteras → `fx_layer` (efectos) → primer plano.
## En juego la sala sale de `BakedRooms.load_room()`: capas ya horneadas, nada se genera. `BgAct1.build()` también vale (pruebas).
## Mientras el shader `palette_lit` no esté conectado, muestra las vistas previas en color de cada capa; con
## `use_index = true` expone las texturas de índice para que WorldView/LightRig las sombreen.
##
##   var view := Act1RoomView.new()
##   view.build(BgAct1.build("normal", floor_num, cycle), AmbientState.from_game())
##   view.actors.add_child(mi_luchador)
##   view.set_parallax(raton_x_normalizado)   # −1..1, en pasos de 1 px de arte
##   view.state.pulse_burn()                  # al quemar una carta
## Con shader (dentro de WorldView): `view.build(sala, estado, wv.lights, wv.lit_material)` → capas de índice con
## `palette_lit`, braseros y crisol como luces de LightRig, y quemar/calor/PV bajos pasan al rig.

const FORGE_FLICKER := 0.3

var room: Dictionary
var state: AmbientState
var particles_back: ArtParticles
var particles_front: ArtParticles
var actors: Node2D
var braziers: Array[AmbientBrazier] = []
var crucibles: Array[AmbientCrucible] = []
var drip: AmbientSootDrip
var gauge: AmbientGauge
var flue: AmbientFlue
## Efectos de combate (BurnFX, HitFX, StatusFX…): encima de los actores, debajo del primer plano.
var fx_layer: Node2D
var use_index := false
var rig: LightRig
var lit_material: ShaderMaterial

var _layer_nodes := {}
var _light_ids: Array = []


func build(p_room: Dictionary, p_state: AmbientState = null, p_rig: LightRig = null, p_material: ShaderMaterial = null) -> Act1RoomView:
	room = p_room
	state = p_state if p_state != null else AmbientState.new()
	rig = p_rig
	lit_material = p_material
	use_index = rig != null and lit_material != null
	for c in get_children():
		c.queue_free()
	braziers.clear()
	crucibles.clear()
	var anchors: Dictionary = room["anchors"]
	var layers := {}
	for L: Dictionary in room["layers"]:
		layers[L["name"]] = L
	_add_layer(layers["sky"])
	_add_layer(layers["far"])
	if room["kind"] == "flue":
		var halo := AmbientGlow.new()
		halo.setup(state)
		add_child(halo)
	particles_back = ArtParticles.new()
	particles_back.name = "ParticlesBack"
	particles_back.seed_value = 5
	add_child(particles_back)
	_add_layer(layers["mid"])
	var amb := Node2D.new()
	amb.name = "Ambient"
	add_child(amb)
	particles_front = ArtParticles.new()
	particles_front.name = "ParticlesFront"
	particles_front.seed_value = 9
	var flick: Array = room.get("flicker", [])
	var bz: Array = anchors["braziers"]
	for i in bz.size():
		var b := AmbientBrazier.new()
		b.position = Vector2(bz[i])
		b.setup(state, particles_front, i * 3, flick[i] if i < flick.size() else {})
		b.use_patches = not use_index
		b.use_index = use_index
		if use_index:
			b.material = lit_material
		amb.add_child(b)
		braziers.append(b)
	var cps: Array = room.get("crucible_patches", [])
	var crs: Array = anchors["crucibles"]
	for i in crs.size():
		var cr := AmbientCrucible.new()
		cr.position = Vector2(crs[i]["pivot"])
		cr.setup(state, int(crs[i]["len"]), cps[i] if i < cps.size() else {})
		cr.use_patches = not use_index
		cr.use_index = use_index
		if use_index:
			cr.material = lit_material
		amb.add_child(cr)
		crucibles.append(cr)
	if (anchors["gauge"] as Vector2i).x >= 0:
		gauge = AmbientGauge.new()
		gauge.position = Vector2(anchors["gauge"])
		gauge.setup(state)
		amb.add_child(gauge)
	drip = AmbientSootDrip.new()
	drip.setup(particles_front, anchors["drips"], int(room["floor"]) * 7 + 1)
	amb.add_child(drip)
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	add_child(particles_front)
	flue = AmbientFlue.new()
	flue.setup(state, particles_back, particles_front, anchors["flue"], anchors["grate"])
	add_child(flue)
	fx_layer = Node2D.new()
	fx_layer.name = "FX"
	add_child(fx_layer)
	# Polvo en el aire: pocas motas, lentas (presupuesto de movimiento).
	particles_front.add_emitter(Rect2(120, 60, 500, 180), "dust", 2.2, Vector2.UP, 120.0)
	_add_layer(layers["fore"])
	if rig != null:
		# Con el valor por defecto del rig (0,6) el parpadeo de la Forja mueve 19.000 px en un fotograma: fuera de presupuesto.
		rig.flicker_amp = FORGE_FLICKER
		_light_ids.clear()
		for b in braziers:
			_light_ids.append(rig.add_light(b.light_info()["pos"], 88.0, 0.0))
		for c in crucibles:
			_light_ids.append(rig.add_light(c.light_info()["pos"], 34.0, AmbientCrucible.IDLE_STEPS))
		state.burned.connect(func(hot: bool) -> void:
			if rig != null:
				rig.burn(rig.forge_pos, 3.2 if hot else 2.6))
	return self


func _add_layer(L: Dictionary) -> void:
	var s := Sprite2D.new()
	s.name = "Layer_" + String(L["name"])
	s.centered = false
	if L.has("index_tex"):
		s.texture = L["index_tex"] if use_index else L["preview_tex"]
	else:
		s.texture = ImageTexture.create_from_image(L["index"] if use_index else L["preview"])
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if use_index:
		s.material = lit_material
	s.position = Vector2(-int(L["margin"]), 0)
	s.set_meta("margin", int(L["margin"]))
	s.set_meta("parallax", int(L["parallax"]))
	add_child(s)
	_layer_nodes[L["name"]] = s


## Parallax por ratón: `mx` en −1..1. Cada capa se mueve un número ENTERO de px de arte (cielo ±1, lejos ±2, primer plano ∓4).
func set_parallax(mx: float) -> void:
	for n: String in _layer_nodes:
		var s: Sprite2D = _layer_nodes[n]
		var par: int = s.get_meta("parallax")
		s.position.x = -int(s.get_meta("margin")) + roundf(clampf(mx, -1.0, 1.0) * par)


func _process(delta: float) -> void:
	if state != null:
		state.tick(delta)
	if rig != null and state != null:
		rig.heat = state.heat
		rig.low_hp = 0.8 if state.low_hp else 0.0
		var i := 0
		for b in braziers:
			if i < _light_ids.size():
				var li := b.light_info()
				rig.move_light(_light_ids[i], li["pos"], float(li["step"]))
			i += 1
		for c in crucibles:
			if i < _light_ids.size():
				var cl := c.light_info()
				rig.move_light(_light_ids[i], cl["pos"], float(cl["step"]))
			i += 1


## Adónde suben las brasas de los muertos: el vacío del tiro o el fondo del corredor.
func ember_sink() -> Vector2:
	return Vector2(room["anchors"]["ember_sink"])


## Luces dinámicas actuales (para LightRig): braseros con su parpadeo y crisoles móviles.
func dynamic_lights() -> Array:
	var out: Array = []
	for b in braziers:
		out.append(b.light_info())
	for c in crucibles:
		out.append(c.light_info())
	return out
