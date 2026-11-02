extends Screen
## Combate: representa CombatEngine. Clic = jugar · Clic derecho / Forja = QUEMAR.
## Mundo en WorldView 640×360 (disposición en docs/DECISIONES.md); interfaz encima a 1280×720.
## Los efectos de F2-FX (docs/reviews/v04/mundo_vivo/api_vfx.md) se enganchan si sus clases existen; si no, respaldo.

# Disposición del mundo, en px de arte.
# La banda de intención de jefe (arte y 22–44 = pantalla 44–88) queda libre: el rótulo del piso va dentro de la barra
# superior y el consejo, justo debajo de la banda (F2-VIDA).
const HINT_Y := 92.0               # consejo del tutorial: arte y 46–58
const HINT_TURNS := 2              # el consejo desaparece al empezar el turno 3
const TOAST_Y := 124.0             # avisos: bajo el consejo
const BANNER_Y := 152.0            # banner de turno: arte y 76–108, por encima de las intenciones de enemigos normales
const BANNER_H := 64.0
const HERO_X := 162
const ENEMY_X := Vector2i(300, 632)
const SLOTS := {1: [466], 2: [396, 540], 3: [350, 460, 572]}
const FORGE_RECT := Rect2(8, 120, 104, 144)
const LEGACY_FORGE_POS := Vector2(24, 198)
const LEGACY_MOUTH := Vector2(60, 244)
# Mano, en px de pantalla (medidas de CardView).
const HAND_Y := 592.0
const HOVER_Y := 496.0
const SELECT_Y := 480.0
const HAND_X := Vector2(150.0, 1120.0)
const HAND_MAX_STEP := 162.0
const HAND_NUDGE := 26.0

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform vec4 tint = vec4(0.75, 0.05, 0.02, 1.0);
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.32, 0.75, length(d * vec2(1.2, 1.0)));
	COLOR = vec4(tint.rgb, v * amount);
}
"""

## Sólo como respaldo mientras no haya salas horneadas: construir una sala cuesta ~7 s.
static var _room_cache := {}

var engine: CombatEngine
var run: RunState
var kind := "combat"
var player_view: FighterView
var enemy_views: Array[FighterView] = []
var card_views := {}           # uid -> CardView
var selected: CardView = null
var busy := false              # bloquea input durante el turno enemigo/animaciones

var _wv: WorldView
var _state: AmbientState
var _room: Act1RoomView        # null en biomas sin migrar
var _actors: Node2D            # luchadores
var _fx_root: Node2D           # efectos, encima de los luchadores
var _particles: ArtParticles   # partículas de combate
var _legacy_near: Sprite2D
var _forge: Node2D             # CombatForge de F2-FX, o null
var _legacy_forge: Sprite2D
var _forge_emitter := -1
var _forge_frame := 0
var _forge_tick := 0.0
var _forge_squash := 0.0
var _burn_fx: Node2D
var _hit_fx: Node2D
var _death_fx: Node2D
var _summon_fx: Node2D
var _status_fx_script: Script
var _pending_mastery := 0
var _pending_embers := 0.0

var _fighters_ui: Control
var _hand_layer: Control
var _fx_layer: Control
var _behind_layer: Control
var _top_hud: TopHud
var _crucible: EnergyCrucible
var _burn_plate: BurnPlate
var _burn_card_sprite: Sprite2D   # carta en vuelo por detrás de la heroína
var _toast_slot := 0
var _heat_label: Label
var _furnace: Control
var _draw_pile: PileCounter
var _discard_pile: PileCounter
var _exhaust_pile: PileCounter
var _end_btn: EndTurnButton
var _turn_banner: Label
var _banner_bg: Panel
var _banner_tw: Tween
var _hint_plate: Control
var _vignette: ColorRect
var _vig_mat: ShaderMaterial
var _cyc := 0
var _t := 0.0


func build() -> void:
	run = Game.run
	kind = args.get("kind", "combat")
	var biome := EnemyDB.act_index(run.floor_num)
	_cyc = EnemyDB.cycle(run.floor_num)

	_wv = WorldView.new()
	add_child(_wv)
	_state = AmbientState.from_game()
	_build_world(biome)

	engine = CombatEngine.new()
	var ids: Array = args.get("enemies", EnemyDB.pick_encounter(kind, run.floor_num, run.rng))
	engine.setup(run, ids, run.floor_num, kind)
	engine.event.connect(_on_event)

	# Lo que vuela de la mano a la Forja pasa bajo las placas de los luchadores.
	_behind_layer = _full_layer()
	_fighters_ui = _full_layer()

	player_view = FighterView.new()
	_fighters_ui.add_child(player_view)
	player_view.setup(engine.player, engine, _wv, _actors)
	player_view.place(HERO_X)
	_attach_status_fx(player_view)
	for e in engine.enemies:
		_add_enemy_view(e)
	_layout_enemies(false)

	_build_top()
	_build_controls()
	_hand_layer = _full_layer()
	_fx_layer = _full_layer()

	_vignette = ColorRect.new()
	_vignette.size = Vector2(1280, 720)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = false
	_vig_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	_vig_mat.shader = sh
	_vig_mat.set_shader_parameter("tint", Palette.color(&"blood", 3))
	_vignette.material = _vig_mat
	add_child(_vignette)

	# Banner de turno: placa opaca de paleta (sin alfa), se abre y se cierra por escalones de 2 px.
	_banner_bg = Panel.new()
	_banner_bg.add_theme_stylebox_override("panel", UIKit.sb_plate(Palette.color(&"plate", 1), Palette.color(&"plate", 5), 2, 0, Vector4.ZERO))
	_banner_bg.clip_contents = true
	_banner_bg.visible = false
	_banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_bg.z_index = 140
	add_child(_banner_bg)
	_turn_banner = UI.plabel("", 4, UI.EMBER)
	_turn_banner.visible = false
	_banner_bg.add_child(_turn_banner)

	engine.start()
	_relayout(true)
	if kind == "boss":
		Sfx.play("heavy")
		main.shake(10.0)
		_banner(engine.enemies[0].display_name, UI.EMBER)
	elif kind == "elite":
		_banner("Élite", Palette.color(&"blood", 4))
	if run.tutorial and run.floor_num <= 1:
		_toast("Clic derecho en la Leña para QUEMARLA: +1 Energía y Ascuas para tu Forja", UI.EMBER)
	if run.combat_mods.has("burn"):
		_toast("Puerta avivada: +1 Quema cada turno", UI.EMBER)


func _full_layer() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


# --- Mundo ----------------------------------------------------------------------------------------

func _build_world(biome: int) -> void:
	var host: Node = _wv.world
	if biome == 0:
		_room = _build_room()
	if _room != null:
		host = _room.actors
	else:
		_build_legacy_scene(biome)
	_build_forge(host)
	_actors = Node2D.new()
	_actors.name = "Luchadores"
	host.add_child(_actors)
	_fx_root = Node2D.new()
	_fx_root.name = "Efectos"
	var fx_layer: Variant = _room.get("fx_layer") if _room != null else null
	if fx_layer is Node:
		(fx_layer as Node).add_child(_fx_root)
	else:
		host.add_child(_fx_root)
	_particles = ArtParticles.new()
	_particles.seed_value = run.floor_num * 13 + 1
	_fx_root.add_child(_particles)
	if _legacy_near != null:
		_wv.world.move_child(_legacy_near, -1)
	if _forge == null:
		_forge_emitter = _particles.add_emitter(Rect2(LEGACY_MOUTH + Vector2(-12, -2), Vector2(24, 4)), "fire", 8.0, Vector2.UP, 25.0)
	_build_fx()


## Sala del acto 1: horneada por F2-FX (`BakedRooms`). Hasta que exista, se construye en tiempo real con caché por variante.
func _build_room() -> Act1RoomView:
	var data := _load_room()
	if data.is_empty():
		return null
	var view := Act1RoomView.new()
	_wv.world.add_child(view)
	view.build(data, _state, _wv.lights, _wv.lit_material)
	return view


func _load_room() -> Dictionary:
	var baked := _fx_script("BakedRooms")
	var special := kind == "elite" or kind == "boss"
	if baked != null:
		var room_kind: String = baked.call(&"kind_for", kind == "elite", kind == "boss")
		var data: Dictionary = baked.call(&"load_room", room_kind, run.floor_num)
		if not data.is_empty():
			return data
	var room_kind := "flue" if special else "normal"
	var variant := 1 + posmod(hash(run.floor_num), 2 if special else 4)
	var key := "%s|%d|%d" % [room_kind, variant, mini(_cyc, 1)]
	if not _room_cache.has(key):
		if _room_cache.size() >= 4:
			_room_cache.clear()
		_room_cache[key] = BgAct1.build(room_kind, variant, mini(_cyc, 1))
	return _room_cache[key]


## Clase global de F2-FX por nombre; null si todavía no existe o no compila.
static func _fx_script(cls: String) -> Script:
	for c: Dictionary in ProjectSettings.get_global_class_list():
		if c["class"] == cls:
			var s := load(c["path"]) as Script
			return s if s != null and s.can_instantiate() else null
	return null


## Biomas sin migrar: fondo y primer plano legados a ×2 dentro del mundo, y ambiente con ArtParticles.
func _build_legacy_scene(biome: int) -> void:
	var bg := _legacy_sprite(Art.background(biome, run.floor_num, _cyc))
	if kind == "boss":
		bg.modulate = Palette.color(&"ash", 4)
	_wv.world.add_child(bg)
	var amb := ArtParticles.new()
	amb.seed_value = 3
	_wv.world.add_child(amb)
	for tp: Vector2i in Art.torches(biome):
		amb.add_emitter(Rect2(Vector2(tp.x * 2 - 3, tp.y * 2 - 4), Vector2(8, 4)), "fire", 6.0, Vector2.UP, 25.0)
	amb.add_emitter(Rect2(0, 40, 640, 210), "snow" if biome == 2 else "dust", 2.2, Vector2.UP, 120.0)
	if kind == "boss":
		amb.add_emitter(Rect2(280, 30, 360, 20), "soot", 5.0, Vector2.DOWN, 20.0)
	_legacy_near = _legacy_sprite(Art.background_near(biome, run.floor_num, _cyc))
	_legacy_near.position = Vector2(-16, 0)
	_wv.world.add_child(_legacy_near)


func _legacy_sprite(tex: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = tex
	s.scale = Vector2(FighterView.LEGACY_SCALE, FighterView.LEGACY_SCALE)
	return s


func _build_forge(host: Node) -> void:
	var cls := _fx_script("CombatForge")
	if cls != null:
		var forge: Node2D = cls.new()
		host.add_child(forge)
		forge.call(&"setup", _wv.lit_material)
		if forge.call(&"has_art"):
			_forge = forge
			return
		host.remove_child(forge)
		forge.free()
	_legacy_forge = _legacy_sprite(Art.furnace_small(0.5))
	_legacy_forge.position = LEGACY_FORGE_POS
	host.add_child(_legacy_forge)


## Efectos de F2-FX. Cada uno es opcional: lo que falte usa el respaldo de `_on_event`.
func _build_fx() -> void:
	var cls := _fx_script("BurnFX")
	if cls != null and _forge != null:
		_burn_fx = cls.new()
		_fx_root.add_child(_burn_fx)
		_burn_fx.call(&"setup", _forge, _state, _wv.lights)
		_burn_fx.connect(&"impact", _on_burn_impact)
		_burn_fx.connect(&"coin_arrived", _on_burn_coin)
	cls = _fx_script("HitFX")
	if cls != null:
		_hit_fx = cls.new()
		_fx_root.add_child(_hit_fx)
		_hit_fx.call(&"setup", _state)
	cls = _fx_script("DeathEmbers")
	if cls != null and _room != null:
		_death_fx = cls.new()
		_fx_root.add_child(_death_fx)
	cls = _fx_script("SummonFX")
	if cls != null:
		_summon_fx = cls.new()
		_fx_root.add_child(_summon_fx)
	_status_fx_script = _fx_script("StatusFX")


func _attach_status_fx(v: FighterView) -> void:
	if _status_fx_script == null:
		return
	var fx: Node2D = _status_fx_script.new()
	_fx_root.add_child(fx)
	fx.call(&"setup", v.body_world(), v.fighter.is_player, v.body_mask())
	v.status_fx = fx
	v.refresh()


func _add_enemy_view(e: Fighter) -> FighterView:
	# Élites legados: la misma base ampliada ×2 (EPX antes de sombrear). Los migrados ya traen su tamaño.
	var shape_key := e.shape
	if e.is_elite and Art.BASES.has(e.shape) and not e.shape.begins_with("boss_"):
		shape_key = e.shape + "@2"
	var v := FighterView.new()
	_fighters_ui.add_child(v)
	v.setup(e, engine, _wv, _actors, shape_key)
	v.clicked.connect(_on_enemy_clicked)
	enemy_views.append(v)
	_attach_status_fx(v)
	return v


## Centros de los enemigos vivos: los de DECISIONES si caben; si no, repartidos en x 300–632 según su ancho.
func _enemy_centers(alive: Array[FighterView]) -> Array[int]:
	var n := alive.size()
	var out: Array[int] = []
	if SLOTS.has(n):
		var fits := true
		for i in n - 1:
			var gap: int = SLOTS[n][i + 1] - SLOTS[n][i]
			if (alive[i].body_width() + alive[i + 1].body_width()) * 0.5 > gap:
				fits = false
		if fits:
			out.assign(SLOTS[n])
			return out
	var boss_fit := _boss_centers(alive)
	if not boss_fit.is_empty():
		return boss_fit
	var total := 0.0
	for v in alive:
		total += v.body_width()
	var span := float(ENEMY_X.y - ENEMY_X.x)
	var k := minf(1.0, span / maxf(1.0, total))
	var gap := maxf(0.0, (span - total * k) / (n + 1))
	var x := ENEMY_X.x + gap
	for v in alive:
		var w := v.body_width() * k
		out.append(int(round(x + w * 0.5)))
		x += w + gap
	return out


## Jefe ancho con invocaciones (F2-VIDA2): el jefe apoya su borde izquierdo en x 300 y cada invocación va a un hueco libre
## (a su derecha hasta x 632 o a ras de suelo bajo su cuerpo, p. ej. bajo la tobera), sin pisarle ni pisarse, y con las
## placas de PV separadas al menos su ancho. Si no caben, vacío (reparto general).
func _boss_centers(alive: Array[FighterView]) -> Array[int]:
	var bi := -1
	for i in alive.size():
		if alive[i].fighter.is_boss:
			bi = i
	if bi < 0 or alive.size() < 2:
		return []
	var boss := alive[bi]
	var plate_w := ceili(HpPlate.SIZE.x / FighterView.WS) + 2
	var cb := ENEMY_X.x + ceili(boss.body_width() * 0.5)
	var right0 := cb + ceili(boss.body_width() * 0.5)
	var mw := 0.0
	var mh := 0
	for v in alive:
		if v != boss:
			mw = maxf(mw, v.body_width())
			mh = maxi(mh, int(v.body_world().size.y))
	var need := int(ceil(mw)) + 4
	var spots: Array[int] = []
	# A la derecha: ni el cuerpo ni la placa pasan de x 632.
	var x := mini(ENEMY_X.y - int(ceil(mw * 0.5)) - 2, ENEMY_X.y - plate_w / 2)
	while x - int(ceil(mw * 0.5)) >= right0 + 2:
		spots.append(x)
		x -= maxi(plate_w, need)
	for g: Vector2i in boss.ground_gaps(mh + 2, need):
		var c := cb + (g.x + g.y) / 2
		if c - mw * 0.5 >= ENEMY_X.x:
			spots.append(c)
	if spots.size() < alive.size() - 1:
		return []
	# Placas: la del jefe y las elegidas no se solapan.
	var chosen: Array[int] = []
	for c in spots:
		if chosen.size() == alive.size() - 1:
			break
		var ok := absi(c - cb) >= plate_w
		for o in chosen:
			ok = ok and absi(c - o) >= plate_w
		if ok:
			chosen.append(c)
	if chosen.size() < alive.size() - 1:
		return []
	var out: Array[int] = []
	var k := 0
	for i in alive.size():
		if i == bi:
			out.append(cb)
		else:
			out.append(chosen[k])
			k += 1
	return out


## `snap`: vista que se coloca ya en su sitio aunque las demás se deslicen (la recién invocada).
func _layout_enemies(animate: bool, snap: FighterView = null) -> void:
	var alive: Array[FighterView] = []
	for v in enemy_views:
		if v.fighter.alive():
			alive.append(v)
	var centers := _enemy_centers(alive)
	for i in alive.size():
		var v := alive[i]
		var target := centers[i]
		if animate and v != snap:
			var from := v.center_x()
			v.create_tween().tween_method(func(t: float) -> void:
				v.place(int(round(lerpf(from, target, t)))), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_QUAD)
		else:
			v.place(target)


# --- Interfaz fija ----------------------------------------------------------------------------------

func _build_top() -> void:
	_top_hud = TopHud.new()
	_top_hud.z_index = 160
	add_child(_top_hud)
	_top_hud.audio_pressed.connect(main._toggle_audio)
	_top_hud.refresh()
	Game.embers_gained.connect(_on_embers_gained)
	Game.forge_changed.connect(_top_hud.refresh)

	var extra := ""
	if run.heat() > 0:
		extra = "Calor de Pacto %d · +%d%% Ascuas" % [run.heat(), int(Game.heat_bonus_each() * 100 * run.heat())]
	var fl := FloorLabel.new()
	fl.position.y = 2
	_top_hud.add_child(fl)
	fl.set_floor(run.floor_num, EnemyDB.act_name(run.floor_num), extra)
	_build_relic_bar()
	if run.tutorial:
		_build_hint("Clic: jugar  ·  Clic dcho: QUEMAR  ·  Mayús + clic dcho: QUEMAR EN CALIENTE (×2)  ·  Espacio: fin de turno")


## Consejo del tutorial sobre placa opaca, justo bajo la banda de intención de jefe; en Mini ×2. Desaparece al empezar
## el turno `HINT_TURNS + 1` (C16).
func _build_hint(text: String) -> void:
	var w := PixelFont.mini_width(text) * 2.0 + 24.0
	var plate := Panel.new()
	_hint_plate = plate
	plate.add_theme_stylebox_override("panel", UIKit.sb_plate(Palette.color(&"plate", 1), Palette.color(&"plate", 4), 1, 0, Vector4.ZERO))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.position = Vector2(roundf((1280.0 - w) / 4.0) * 2.0, HINT_Y)
	plate.size = Vector2(w, 24)
	add_child(plate)
	var hint := UI.mlabel(text, UI.TEXT)
	hint.position = Vector2(12, 4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(hint)


## Aviso de combate. Como `main.toast`, pero bajo el rótulo del piso y el consejo: ni los tapa ni se apila sobre ellos.
func _toast(text: String, color: Color = UI.TEXT) -> void:
	var p := UI.panel(Palette.color(&"plate", 1), color.darkened(0.3))
	p.add_child(UI.plabel(text, 2, color) if text.length() <= 60 else UI.label(text, 18, color))
	main.overlay_layer.add_child(p)
	p.reset_size()
	var y := TOAST_Y + 48.0 * (_toast_slot % 4)
	_toast_slot += 1
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if is_inside_tree():
			_toast_slot = maxi(0, _toast_slot - 1))
	p.position = Vector2(roundf((1280.0 - p.size.x) / 4.0) * 2.0, y)
	var tw := p.create_tween()
	tw.tween_interval(1.9)
	tw.tween_callback(p.queue_free)


func _on_embers_gained(_amount: float, _source: String) -> void:
	_top_hud.pulse()


func _build_relic_bar() -> void:
	var row := UI.hbox(4)
	row.position = Vector2(8, 34)
	add_child(row)
	for id in run.relics:
		var d := RelicDB.get_def(id)
		row.add_child(_relic_icon(d["icon"], "%s\n%s" % [d["name"], d["desc"]]))
	if not run.perks.is_empty():
		row.add_child(UI.spacer(0, 8))
		for id in run.perks:
			var d2 := RelicDB.get_def(id)
			var holder := PanelContainer.new()
			holder.add_theme_stylebox_override("panel", UI.box(Palette.color(&"magic", 1), Palette.color(&"magic", 3), 1, 0))
			holder.mouse_filter = Control.MOUSE_FILTER_PASS
			holder.tooltip_text = "Resonancia: %s\n%s" % [d2["name"], d2["desc"]]
			holder.add_child(_relic_icon(d2["icon"], ""))
			row.add_child(holder)


func _relic_icon(id: String, tip: String) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = HudArt.legacy_icon(id)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(ic.texture.get_width(), ic.texture.get_height())
	ic.tooltip_text = tip
	ic.mouse_filter = Control.MOUSE_FILTER_PASS if tip != "" else Control.MOUSE_FILTER_IGNORE
	return ic


## Las columnas libres de la mano son x < 132 y x > 1138 (la décima carta y su aura llegan a 132–1138).
func _build_controls() -> void:
	_furnace = Control.new()
	_furnace.position = FORGE_RECT.position * WorldView.SCALE
	_furnace.size = FORGE_RECT.size * WorldView.SCALE
	_furnace.mouse_filter = Control.MOUSE_FILTER_STOP
	_furnace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_furnace.tooltip_text = "LA FORJA\nClic derecho en una carta (o selecciónala y pulsa aquí) para QUEMARLA:\nla pierdes este combate, ganas Ascuas permanentes, activas su efecto 'Al quemar'\ny la carta gana Maestría para siempre.\n\nCALOR: cartas quemadas en este combate."
	add_child(_furnace)
	_furnace.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and selected != null:
			_try_burn(selected))

	_burn_plate = BurnPlate.new()
	_burn_plate.position = Vector2(8, 534)
	add_child(_burn_plate)
	_heat_label = UI.mlabel("", Palette.color(&"ember_ui", 4))
	_heat_label.position = Vector2(146, 540)
	_heat_label.add_theme_color_override("font_shadow_color", Palette.OUTLINE)
	_heat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_heat_label)

	_crucible = EnergyCrucible.new()
	_crucible.position = Vector2(26, 568)
	_crucible.tooltip_text = "Energía: se gasta al jugar cartas."
	add_child(_crucible)

	_draw_pile = _pile("draw", Vector2(18, 662), func() -> void:
		var cs: Array = engine.draw_pile.duplicate()
		cs.sort_custom(func(a: Card, b: Card) -> bool: return a.id < b.id)
		main.show_deck(cs, "Mazo de robo"))
	_discard_pile = _pile("discard", Vector2(1160, 628), func() -> void: main.show_deck(engine.discard.duplicate(), "Descarte"))
	_exhaust_pile = _pile("exhaust", Vector2(1160, 674), func() -> void: main.show_deck(engine.exhaust_pile.duplicate(), "Exilio"))

	_end_btn = EndTurnButton.new()
	_end_btn.position = Vector2(1138, 586)
	_end_btn.tooltip_text = "Espacio: fin de turno"
	_end_btn.pressed.connect(_end_turn)
	add_child(_end_btn)


func _pile(pile_kind: String, pos: Vector2, cb: Callable) -> PileCounter:
	var p := PileCounter.new(pile_kind)
	p.position = pos
	p.pressed.connect(func() -> void:
		if not busy:
			cb.call())
	add_child(p)
	return p


# --- Mano -----------------------------------------------------------------------------------------

func _add_card_view(c: Card, from: Vector2) -> CardView:
	var cv := CardView.new(c, engine)
	cv.position = from - CardView.SIZE * 0.5
	cv.scale = Vector2(0.25, 0.25)
	cv.rotation = -0.3
	cv.clicked.connect(_on_card_clicked)
	cv.hover_changed.connect(_on_card_hover)
	_hand_layer.add_child(cv)
	card_views[c.uid] = cv
	return cv


func _draw_pos() -> Vector2:
	return _local(_draw_pile.card_anchor())


func _discard_pos() -> Vector2:
	return _local(_discard_pile.card_anchor())


## Fila plana: reposo y=592 (asoman 128 px), al pasar el ratón y=496, mano de 10 con paso de 90 px en x 150–1120.
func _relayout(instant: bool = false) -> void:
	var n := engine.hand.size()
	var span := HAND_X.y - HAND_X.x - CardView.SIZE.x
	var step := minf(HAND_MAX_STEP, span / maxf(1.0, n - 1))
	var x0 := (HAND_X.x + HAND_X.y) * 0.5 - CardView.SIZE.x * 0.5 - step * (n - 1) * 0.5
	var hovered_i := -1
	for i in n:
		var cvh: CardView = card_views.get(engine.hand[i].uid)
		if cvh != null and cvh.hovering and not busy:
			hovered_i = i
	for i in n:
		var c: Card = engine.hand[i]
		var cv: CardView = card_views.get(c.uid)
		if cv == null:
			continue
		var target := Vector2(x0 + i * step, HAND_Y)
		# Las vecinas se apartan de la carta señalada, sin salir de la franja de la mano.
		if hovered_i >= 0 and i != hovered_i:
			target.x += HAND_NUDGE * signf(i - hovered_i) / maxf(1.0, absf(i - hovered_i) * 0.7)
			target.x = clampf(target.x, HAND_X.x, HAND_X.y - CardView.SIZE.x)
		if cv.hovering and not busy:
			target.y = HOVER_Y
		if cv == selected:
			target.y = SELECT_Y
		target = (target / UI.UI_PX).round() * UI.UI_PX
		cv.home_pos = target
		cv.home_rot = 0.0
		cv.z_index = 50 if (cv.hovering or cv == selected) else i
		cv.refresh()
		if instant:
			cv.position = target
			cv.rotation = 0.0
			cv.scale = Vector2.ONE
		else:
			var tw := cv.create_tween().set_parallel()
			tw.tween_property(cv, "position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(cv, "rotation", 0.0, 0.18)
			tw.tween_property(cv, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_labels()


func _refresh_labels() -> void:
	_crucible.set_energy(engine.energy, run.max_energy)
	_burn_plate.set_burns(engine.burns_left, maxi(run.burns_per_turn, engine.burns_left))
	_heat_label.text = "CALOR %d" % engine.heat() if engine.heat() > 0 else ""
	var pc := engine.pile_counts()
	_draw_pile.set_count(pc["draw"])
	_discard_pile.set_count(pc["discard"])
	_exhaust_pile.set_count(pc["exhaust"])
	for p: PileCounter in [_draw_pile, _discard_pile, _exhaust_pile]:
		p.enabled = not busy
	_end_btn.disabled = busy or engine.over
	var can_act := false
	for c: Card in engine.hand:
		if engine.can_play(c) or engine.can_burn(c):
			can_act = true
			break
	_end_btn.set_hint(not can_act and not busy and not engine.over)
	for v in enemy_views:
		v.targetable = selected != null and selected.card.needs_target() and v.fighter.alive()
	_sync_light()


## Estado real → luz: calor por producción de la Forja (más lo quemado en este combate), Resplandor y PV bajos.
func _sync_light() -> void:
	var prod := AmbientState.normalize_production(Game.production())
	var h := clampf(0.2 + 0.8 * prod + 0.05 * engine.heat(), 0.0, 1.0)
	var low := engine.player.hp > 0 and engine.player.hp * 4 <= engine.player.max_hp
	_state.production = prod
	_state.heat = h
	_state.low_hp = low
	_state.glow = Game.glow_active() > 0.0
	_wv.lights.gold = _state.glow
	_wv.lights.heat = h
	_wv.lights.low_hp = 0.8 if low else 0.0
	_vignette.visible = low and _room == null
	if _forge != null:
		_forge.call(&"set_heat", h)
		_forge.call(&"set_burns", engine.burns_left)
	if _forge_emitter >= 0:
		_particles.set_emitter_rate(_forge_emitter, 8.0 + 16.0 * h if engine.burns_left > 0 else 2.0)


func _process(delta: float) -> void:
	_t += delta
	# El HUD v0.3 de main no se usa en combate: main lo reactiva al cambiar de pantalla.
	if main.hud.visible:
		main.hud.visible = false
	_top_hud.position = -main.screen_layer.position
	if (Game.glow_active() > 0.0) != _wv.lights.gold:   # el Resplandor caduca o se enciende sin evento de combate
		_sync_light()
	# Parallax por ratón, en px de arte enteros.
	var mx := clampf((get_viewport().get_mouse_position().x - 640.0) / 640.0, -1.0, 1.0)
	if _room != null:
		_room.set_parallax(mx)
	if _legacy_near != null:
		_legacy_near.position.x = -16.0 - roundf(mx * 2.0) * FighterView.LEGACY_SCALE
	if _legacy_forge != null:
		_animate_legacy_forge(delta)
	if _vignette.visible:
		_vig_mat.set_shader_parameter("amount", 0.35 + 0.25 * maxf(0.0, sin(_t * 5.0)))


## Forja legada: 4 fotogramas a ~7 fps; se traga la carta con 1 px legado de aplastamiento.
func _animate_legacy_forge(delta: float) -> void:
	_forge_tick += delta
	if _forge_tick > 0.14:
		_forge_tick = 0.0
		_forge_frame = (_forge_frame + 1) % 4
		var hot := 0.25 + (0.25 if engine.burns_left > 0 else 0.0) + minf(0.5, engine.heat() * 0.12)
		if _forge_squash > 0.0:
			hot = 1.0
		_legacy_forge.texture = Art.furnace_small(hot, _forge_frame)
	if _forge_squash > 0.0:
		_forge_squash -= delta
		_legacy_forge.position.y = LEGACY_FORGE_POS.y + (FighterView.LEGACY_SCALE if _forge_squash > 0.22 else 0)


func _on_card_hover(_cv: CardView, _h: bool) -> void:
	if not busy:
		_relayout()


func _on_card_clicked(cv: CardView, button: int) -> void:
	if busy or engine.over:
		return
	if button == MOUSE_BUTTON_RIGHT:
		_try_burn(cv, Input.is_key_pressed(KEY_SHIFT))
		return
	var c := cv.card
	if not engine.can_play(c):
		Sfx.play("deny")
		if c.type() == "fuel":
			_toast("Combustible: sólo puede QUEMARSE (clic derecho)", UI.EMBER)
		elif not c.is_playable():
			_toast("Esta carta no se puede jugar", UI.DIM)
		else:
			_toast("No tienes energía suficiente", UI.RED)
			_crucible.deny()
		_deny(cv)
		return
	if c.needs_target() and engine.living_enemies().size() > 1:
		if selected == cv:
			_set_selected(null)
		else:
			_set_selected(cv)
			Sfx.play("hover")
			_toast("Elige un objetivo", UI.EMBER)
		return
	_play(cv, null)


func _deny(cv: CardView) -> void:
	# "No": vaivén horizontal (sin rotar el pixel art).
	var tw := cv.create_tween()
	for i in 4:
		tw.tween_property(cv, "position:x", cv.home_pos.x + (8.0 if i % 2 == 0 else -8.0), 0.04)
	tw.tween_property(cv, "position:x", cv.home_pos.x, 0.05)


func _set_selected(cv: CardView) -> void:
	if selected != null and is_instance_valid(selected):
		selected.selected = false
	selected = cv
	if cv != null:
		cv.selected = true
	_relayout()


func _on_enemy_clicked(v: FighterView) -> void:
	if busy or selected == null or not v.fighter.alive():
		return
	var cv := selected
	_set_selected(null)
	_play(cv, v.fighter)


## C1: la carta se resuelve en el fotograma de impacto del martillazo (o en el gesto de `cast`), no al hacer clic.
## Mientras tanto la entrada está bloqueada y la carta ya se alza para responder al clic.
func _play(cv: CardView, target: Fighter) -> void:
	var c := cv.card
	var wait := player_view.swing() if c.type() == "attack" else player_view.cast()
	if wait > 0.0:
		busy = true
		cv.interactive = false
		cv.create_tween().tween_property(cv, "position:y", SELECT_Y - 16.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_refresh_labels()
		await get_tree().create_timer(wait).timeout
		if not is_inside_tree():
			return
		busy = false
		cv.interactive = true
		if engine.over:
			return
	engine.play_card(c, target)
	_after_action()


func _try_burn(cv: CardView, hot: bool = false) -> void:
	if busy or engine.over:
		return
	if not engine.can_burn(cv.card):
		Sfx.play("deny")
		if not cv.card.is_burnable():
			_toast("La Ceniza Húmeda no prende: no se puede quemar", UI.BLUE)
		else:
			_toast("El horno necesita respirar: no te quedan Quemas este turno", UI.DIM)
			if _forge != null:
				_forge.call(&"deny")
		_deny(cv)
		return
	if hot and not engine.can_burn_hot(cv.card):
		Sfx.play("deny")
		if cv.card.hot_cost(engine.energy) < 0:
			_toast("Sólo las cartas jugables de coste 1 o más se queman en caliente", UI.DIM)
		else:
			_toast("No tienes Energía para quemarla en caliente", UI.RED)
			_crucible.deny()
		_deny(cv)
		return
	if selected == cv:
		_set_selected(null)
	engine.burn_card(cv.card, hot)
	if hot:
		_toast("¡En caliente! ×2 Ascuas y Maestría", UI.FIRE)
	if run.tutorial and not Game.seen_tips.has("mastery"):
		Game.seen_tips["mastery"] = true
		_toast("Cada carta que quemas gana Maestría para siempre (+10% por nivel)", Palette.color(&"magic", 5))
	_after_action()


func _after_action() -> void:
	_relayout()
	if engine.over:
		_finish()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_SPACE or k == KEY_E:
			_end_turn()
		elif k == KEY_ESCAPE:
			_set_selected(null)
	elif ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_set_selected(null)


# --- Turno enemigo --------------------------------------------------------------------------------

func _end_turn() -> void:
	if busy or engine.over:
		return
	busy = true
	_set_selected(null)
	engine.end_player_turn()
	_relayout()
	await get_tree().create_timer(0.35).timeout
	_banner("Turno enemigo", Palette.color(&"blood", 4), 0.35)
	engine.begin_enemy_phase()
	for v in enemy_views:
		v.refresh()
	if engine.over:
		_finish()
		return
	await get_tree().create_timer(0.3).timeout
	for v in enemy_views.duplicate():
		if engine.over:
			break
		if not v.fighter.alive():
			continue
		var is_atk := String(v.fighter.intent.get("kind", "")).begins_with("attack")
		# Invocar / ahogar tienen animación propia en el jefe (F2-JEFE): se resuelven en su soplo aunque también ataquen.
		var special := _move_anim(v.fighter)
		var key: float = v.gesture(special) if special != &"" and v.has_anim(special) else 0.0
		if key > 0.0:
			await get_tree().create_timer(key).timeout
		elif is_atk:
			# C1: el daño cae en el fotograma de impacto del ataque.
			await get_tree().create_timer(v.lunge(-1.0)).timeout
		else:
			v.gesture()
		engine.enemy_act(v.fighter)
		v.refresh()
		player_view.refresh()
		await get_tree().create_timer(0.45).timeout
	if engine.over:
		_finish()
		return
	engine.end_enemy_phase()
	busy = false
	if engine.over:
		_finish()
		return
	_relayout()


## Animación propia del movimiento del enemigo: `summon` si invoca, `choke` si ahoga el horno; si no, vacío.
func _move_anim(f: Fighter) -> StringName:
	for op: Variant in f.intent.get("ops", []):
		if op is Array and not (op as Array).is_empty():
			match String(op[0]):
				"summon":
					return &"summon"
				"choke":
					return &"choke"
	return &""


## Banner de turno (C16 y F2-BASE c): placa opaca de paleta sobre las intenciones, nunca encima; cifra Fragua ×4 en el
## color dado (contraste ≥ 4,5:1 sobre `plate 1`). Se abre y se cierra en 3 escalones de 33 ms, sin fundidos.
func _banner(text: String, color: Color = UI.EMBER, hold: float = 0.5) -> void:
	if _banner_tw != null:
		_banner_tw.kill()
	_turn_banner.text = text
	_turn_banner.add_theme_color_override("font_color", color)
	var tw := PixelFont.text_width(text) * 4.0
	var w := ceilf((tw + 64.0) / 4.0) * 4.0
	var lh := float(PixelFont.px_size(4))
	_banner_bg.size = Vector2(w, 0)
	_banner_bg.position = Vector2(roundf((1280.0 - w) / 4.0) * 2.0, BANNER_Y)
	_banner_bg.visible = true
	_turn_banner.visible = false
	_turn_banner.size = Vector2(tw + 8.0, lh)
	_turn_banner.position = Vector2(roundf((w - tw) / 4.0) * 2.0, roundf((BANNER_H - lh) / 4.0) * 2.0)
	_banner_tw = create_tween()
	for h: float in [16.0, 40.0, BANNER_H]:
		_banner_tw.tween_callback(_banner_open.bind(h))
		_banner_tw.tween_interval(0.033)
	_banner_tw.tween_callback(func() -> void: _turn_banner.visible = true)
	_banner_tw.tween_interval(hold + 0.12)
	_banner_tw.tween_callback(func() -> void: _turn_banner.visible = false)
	for h2: float in [40.0, 16.0]:
		_banner_tw.tween_callback(_banner_open.bind(h2))
		_banner_tw.tween_interval(0.033)
	_banner_tw.tween_callback(func() -> void: _banner_bg.visible = false)


func _banner_open(h: float) -> void:
	_banner_bg.size.y = h
	_banner_bg.position.y = BANNER_Y + (BANNER_H - h) * 0.5
	_turn_banner.position.y = roundf((BANNER_H - float(PixelFont.px_size(4))) / 4.0) * 2.0 - (BANNER_H - h) * 0.5


# --- Efectos: F2-FX o respaldo con ArtParticles -------------------------------------------------------

## Ráfaga de partículas en un punto global de interfaz, siempre en la rejilla de arte.
func _burst(global_pos: Vector2, preset: String, count: int, spread := 180.0, speed := 1.0) -> void:
	_particles.burst(_wv.ui_to_world(global_pos), preset, count, Vector2.UP, spread, speed)


func _fx_damage(v: FighterView, amt: int, blocked: int) -> void:
	var w := _wv.ui_to_world(v.center())
	if amt > 0:
		if _hit_fx != null:
			if v.fighter.is_player:
				_hit_fx.call(&"player_hit", w)
			else:
				_hit_fx.call(&"strike", w, amt)
			return
		_particles.burst(w, "spark", 6 + mini(amt, 24) / 2, Vector2.UP, 60.0)
		_state.pulse_strike(amt)
	elif blocked > 0:
		if _hit_fx != null:
			_hit_fx.call(&"blocked", w)
			return
		_particles.burst(w, "frost", 8, Vector2.UP, 90.0)


func _fx_enemy_death(v: FighterView, embers: float) -> void:
	var pos := _local(v.center())
	if _death_fx != null:
		_death_fx.call(&"play", v.current_frame(), v.canvas_world(), _room.call(&"ember_sink"))
		var txt := "+%s" % Num.fmt(embers)
		var cb := func(_p: Vector2) -> void:
			if is_inside_tree():
				UI.float_text(_fx_layer, pos + Vector2(0, -50), txt, UI.EMBER, 24)
		_death_fx.connect(&"first_out", cb, CONNECT_ONE_SHOT)
		return
	_burst(v.center(), "ember", 24, 140.0, 2.0)
	UI.float_text(_fx_layer, pos + Vector2(0, -50), "+%s" % Num.fmt(embers), UI.EMBER, 24)


func _fx_summon(nv: FighterView) -> void:
	if _summon_fx != null:
		nv.reveal(0.0)   # oculto hasta que SummonFX abre el suelo
		_summon_fx.call(&"play", nv.foot_world(), int(nv.body_width()), nv.reveal)
	else:
		_burst(nv.center(), "spark", 14)
	if _summon_fx == null:
		nv.spawn()


## Vuelo de la carta a la Forja y efecto de quemar.
func _fx_burn(cv: CardView, c: Card, d: Dictionary) -> void:
	var hot_burn: bool = d.get("hot", false)
	var ember_amt: float = d["embers"]
	_pending_embers = ember_amt
	if _burn_fx != null:
		var origin := _wv.ui_to_world(cv.global_position + CardView.SIZE * 0.5) if cv != null else _wv.ui_to_world(player_view.center())
		_burn_fx.call(&"play", c.type(), hot_burn, origin, _wv.ui_to_world(_top_hud.ember_anchor()), _pending_mastery)
		_pending_mastery = 0
		if cv != null:
			var cs: Dictionary = _burn_fx.get_script().get_script_constant_map()
			_fly_card_to_forge(cv, c, origin, cs["FLIGHT_START"], cs["FLIGHT_TIME"])
		return
	_state.pulse_inhale()
	var fpos := _forge_mouth()
	if cv != null:
		var tw := cv.create_tween().set_parallel()
		var dest := _local(fpos) - CardView.SIZE * 0.5 + Vector2(0, -40)
		tw.tween_property(cv, "position", dest, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(cv, "rotation", -0.35, 0.26)
		tw.tween_property(cv, "scale", Vector2(0.5, 0.5), 0.26)
		tw.chain().tween_callback(func() -> void: cv.burn_away(0.35).chain().tween_callback(cv.queue_free))
	get_tree().create_timer(0.28).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		_state.pulse_burn(hot_burn)
		if _room == null:
			_wv.lights.burn(_wv.lights.forge_pos, 3.2 if hot_burn else 2.6)
		_burst(fpos, "spark", 28 if hot_burn else 18, 70.0)
		UI.float_text(_fx_layer, _local(fpos) + Vector2(120, -170), "+%s" % Num.fmt(ember_amt), UI.EMBER, 26)
		main.fly_embers(fpos, 5)
		main.shake(8.0 if hot_burn else 4.0)
		_forge_squash = 0.3
		_forge_tick = 1.0)


## La carta vuela como interfaz sobre la mano y, al llegar a la heroína, pasa al mundo por DETRÁS de ella: una copia en un
## SubViewport (preparada antes de despegar para que no parpadee) dibujada como sprite justo bajo su actor.
func _fly_card_to_forge(cv: CardView, c: Card, origin_world: Vector2, start: float, dur: float) -> void:
	var mouth: Vector2 = _forge.call(&"mouth_pos")
	var from := cv.position
	var sv := SubViewport.new()
	sv.size = Vector2i(CardView.SIZE)
	sv.transparent_bg = true
	sv.gui_disable_input = true
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var copy := CardView.new(c, engine)
	copy.interactive = false
	sv.add_child(copy)
	add_child(sv)
	var hero_box := player_view.body_world().grow(2.0)
	_burn_card_sprite = null
	var sprite: Array[Sprite2D] = [null]
	var fly := func(t: float) -> void:
		var p: Vector2 = _burn_fx.get_script().call(&"flight_point", origin_world, mouth, t)
		var k: float = cv.scale.x
		cv.position = _local(_wv.world_to_ui(p)) - CardView.SIZE * 0.5   # pivote en el centro de la carta
		if sprite[0] == null:
			var half := CardView.SIZE * 0.25 * k   # media carta, en px de arte
			if not hero_box.intersects(Rect2(p - half, half * 2.0)):
				return
			sprite[0] = Sprite2D.new()
			sprite[0].name = "CartaQuemada"
			sprite[0].texture = sv.get_texture()
			_actors.add_child(sprite[0])
			_actors.move_child(sprite[0], player_view.actor.get_index())
			_burn_card_sprite = sprite[0]
			cv.visible = false
		sprite[0].position = p
		sprite[0].scale = Vector2.ONE * (0.5 * k)
	cv.position = from + Vector2(0, -6)
	var tw := cv.create_tween()
	tw.tween_interval(start)
	tw.tween_method(fly, 0.0, 1.0, dur)
	tw.parallel().tween_property(cv, "scale", Vector2(0.25, 0.25), dur)
	tw.tween_callback(func() -> void:
		if sprite[0] != null:
			sprite[0].queue_free()
		sv.queue_free()
		cv.queue_free())


func _on_burn_impact(_hot: bool, shake_px: float, hitstop_s: float) -> void:
	main.shake(shake_px)
	_hitstop(hitstop_s)


func _on_burn_coin() -> void:
	if not is_inside_tree():
		return
	_top_hud.pulse()
	UI.float_text(_fx_layer, _local(_top_hud.ember_anchor()) + Vector2(40, 30), "+%s" % Num.fmt(_pending_embers), UI.EMBER, 26)


func _forge_mouth() -> Vector2:
	if _forge != null:
		return _wv.world_to_ui(_forge.call(&"mouth_pos"))
	return _wv.world_to_ui(LEGACY_MOUTH)


# --- Eventos del motor ----------------------------------------------------------------------------

func _view_for(f: Fighter) -> FighterView:
	if f == null:
		return null
	if f.is_player:
		return player_view
	for v in enemy_views:
		if v.fighter == f:
			return v
	return null


func _local(p: Vector2) -> Vector2:
	return p - global_position


func _on_event(k: String, d: Dictionary) -> void:
	match k:
		"draw":
			var from := _draw_pos()
			if d.get("recalled", false):
				var mouth := _forge_mouth()
				from = _local(mouth)
				_burst(mouth, "spark", 10)
			elif d.get("created", false):
				from = _local(player_view.center())
				_burst(player_view.center(), "glow", 8)
			_add_card_view(d["card"], from)
			Sfx.play("card", 0.15, -8.0)
		"discard", "exhaust":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				if k == "exhaust":
					cv.burn_away(0.45).chain().tween_callback(cv.queue_free)
				else:
					var tw := cv.create_tween().set_parallel()
					tw.tween_property(cv, "position", _discard_pos() - CardView.SIZE * 0.5, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.tween_property(cv, "scale", Vector2(0.2, 0.2), 0.25)
					tw.tween_property(cv, "rotation", 0.8, 0.25)
					tw.tween_property(cv, "modulate:a", 0.0, 0.25)
					tw.chain().tween_callback(cv.queue_free)
		"card_played":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			Sfx.play("card")
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				cv.z_index = 80
				var tw := cv.create_tween()
				var stage := Vector2(640 - CardView.SIZE.x * 0.5, 230)
				var tgt: Fighter = d.get("target")
				if c.type() == "attack" and tgt == null and _hit_fx != null and engine.living_enemies().size() > 1:
					_hit_fx.call(&"sweep", float(ENEMY_X.x), float(ENEMY_X.y), float(FighterView.FLOOR_Y - 40))
				if c.type() == "attack" and tgt != null and _view_for(tgt) != null:
					stage = _local(_view_for(tgt).center()) - CardView.SIZE * 0.5 + Vector2(-200, -60)
				tw.tween_property(cv, "position", stage, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(cv, "rotation", 0.0, 0.12)
				tw.parallel().tween_property(cv, "scale", Vector2.ONE, 0.12)
				tw.tween_interval(0.06)
				if c.type() == "power":
					tw.tween_property(cv, "position", _local(player_view.center()) - CardView.SIZE * 0.5, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.parallel().tween_property(cv, "scale", Vector2(0.15, 0.15), 0.22)
					tw.parallel().tween_property(cv, "modulate:a", 0.0, 0.22)
					tw.tween_callback(cv.queue_free)
					Sfx.play("buff")
					_burst(player_view.center(), "glow", 14)
				elif c.exhausts():
					tw.tween_callback(func() -> void: cv.burn_away(0.4).chain().tween_callback(cv.queue_free))
				else:
					tw.tween_property(cv, "position", _discard_pos() - CardView.SIZE * 0.5, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.parallel().tween_property(cv, "scale", Vector2(0.15, 0.15), 0.22)
					tw.parallel().tween_property(cv, "rotation", 0.8, 0.22)
					tw.parallel().tween_property(cv, "modulate:a", 0.0, 0.22)
					tw.tween_callback(cv.queue_free)
		"card_burned":
			var c: Card = d["card"]
			var cv: CardView = card_views.get(c.uid)
			Sfx.play("burn")
			player_view.toss()
			_burn_plate.flash()
			if cv != null:
				card_views.erase(c.uid)
				cv.interactive = false
				cv.reparent(_behind_layer)
			_fx_burn(cv, c, d)
		"mastery":
			var c: Card = d["card"]
			var lvl: int = d["level"]
			var col: Color = Palette.color(&"magic", 5) if lvl >= Game.MASTERY_MAX else Palette.color(&"gold", 5)
			_toast("%s · Maestría %d%s" % [CardDB.get_def(c.id)["name"], lvl, " (¡máxima!)" if lvl >= Game.MASTERY_MAX else ""], col)
			_pending_mastery = lvl
			if _burn_fx == null:
				_burst(_forge_mouth() + Vector2(0, -40), "glow", 16)
			Sfx.play("rebirth", 0.0, -8.0)
			for cvm: CardView in card_views.values():
				if cvm.card.id == c.id:
					cvm.refresh()
					UI.punch(cvm, 0.08)
		"upgraded":
			var cvu: CardView = card_views.get((d["card"] as Card).uid)
			if cvu != null:
				cvu.refresh()
				UI.punch(cvu, 0.1)
				_burst(cvu.global_position + CardView.SIZE * 0.5 - Vector2(0, 40), "glow", 8)
				Sfx.play("buy", 0.1, -8.0)
		"damage":
			var v := _view_for(d["target"])
			if v == null:
				return
			var amt: int = d["amount"]
			var blocked: int = d["blocked"]
			var pos := _local(v.center())
			if amt > 0:
				# Curva de impacto estándar: destello 1 fotograma → color, empuje direccional,
				# hitstop por escalones (50/80/120 ms), sacudida direccional y chispas.
				v.flash(Palette.color(&"blood", 4) if v.fighter.is_player else Palette.color(&"fire", 6))
				v.shake(6.0 + minf(amt, 30.0) * 0.4)
				var big := amt >= 20
				var num_col: Color = UI.RED if v.fighter.is_player else (Palette.color(&"gold", 5) if big else UI.TEXT)
				UI.float_text(_fx_layer, pos + Vector2(0, -20), str(amt) + ("!" if big else ""), num_col, 22 if amt < 10 else 33)
				var dir := Vector2.LEFT if v.fighter.is_player else Vector2.RIGHT
				_fx_damage(v, amt, blocked)
				Sfx.play("heavy" if amt >= 15 else "hit")
				main.shake(3.0 + minf(amt, 40.0) * 0.25, dir)
				_hitstop(0.05 if amt < 10 else (0.08 if amt <= 30 else 0.12))
			elif blocked > 0:
				UI.float_text(_fx_layer, pos, "Bloqueado", UI.BLUE, 22)
				_fx_damage(v, 0, blocked)
				Sfx.play("block")
			v.refresh()
			_sync_light()
		"block":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, _local(v.center()) + Vector2(0, 30), "+%d" % d["amount"], UI.BLUE, 22)
				Sfx.play("block", 0.05, -4.0)
		"status":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				var amt: int = d["amount"]
				var id: String = d["id"]
				if amt > 0 and id != "":
					var good := id in ["str", "thorns", "regen"]
					if v.fighter.is_player and id in ["thorns", "regen"]:
						good = true
					UI.float_text(_fx_layer, _local(v.center()) + Vector2(0, -40), "%s +%d" % [FighterView.STATUS_NAMES.get(id, id), amt],
						UI.GREEN if good else (UI.FIRE if id == "scorch" else UI.PURPLE), 20)
					Sfx.play("buff" if good else "debuff", 0.05, -4.0)
				if id == "choke" and amt > 0:
					_refresh_labels()
				if id == "scorch" and amt < 0 and v.status_fx != null:
					v.status_fx.call(&"scorch_tick")
		"heal":
			var v := _view_for(d["target"])
			if v != null:
				v.refresh()
				UI.float_text(_fx_layer, _local(v.center()), "+%d" % d["amount"], UI.GREEN, 26)
				Sfx.play("heal")
				_sync_light()
		"power":
			player_view.refresh()
		"intent":
			var v := _view_for(d["fighter"])
			if v != null:
				v.refresh()
		"energy", "burns", "shuffle":
			if is_inside_tree() and _crucible != null:
				_refresh_labels()
			if k == "shuffle" and _fx_layer != null:
				_shuffle_fx()
		"card_added":
			var src := _view_for(d["source"])
			if src != null:
				var from := _local(src.center())
				# A la altura del cuerpo, no de la intención (C16: «+Hollín» pisaba la cifra de intención).
				UI.float_text(_fx_layer, from + Vector2(0, 10), "+%s" % (d["card"] as Card).title(), UI.TEXT, 18, 40.0)
				var ghost := UI.tex_rect(Art.card_back_small(), UI.UI_PX)
				ghost.position = from
				ghost.z_index = 90
				_fx_layer.add_child(ghost)
				var gtw := ghost.create_tween()
				gtw.tween_property(ghost, "position", _discard_pos(), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				gtw.parallel().tween_property(ghost, "rotation", 3.0, 0.45)
				gtw.tween_callback(ghost.queue_free)
		"turn_start":
			for v in enemy_views:
				v.refresh()
			player_view.refresh()
			if engine.turn > 1:
				_banner("Tu turno", UI.EMBER, 0.35)
				Sfx.play("turn")
			if _hint_plate != null and engine.turn > HINT_TURNS:
				_hint_plate.queue_free()
				_hint_plate = null
		"enemy_died":
			var v := _view_for(d["target"])
			if v != null:
				v.die()
				Sfx.play("death")
				_fx_enemy_death(v, d["embers"])
				_fly_embers(v.center(), 8)
				_hitstop(0.08)
				get_tree().create_timer(0.9).timeout.connect(func() -> void:
					if is_inside_tree():
						_layout_enemies(true))
		"fled":
			var fv := _view_for(d["target"])
			if fv != null:
				_burst(fv.center(), "puff", 14, 120.0)
				fv.flee()
				get_tree().create_timer(0.7).timeout.connect(func() -> void:
					if is_inside_tree():
						_layout_enemies(true))
		"summon":
			var nv := _add_enemy_view(d["fighter"])
			_layout_enemies(true, nv)   # el jefe se aparta deslizándose; la invocación aparece ya en su hueco
			_fx_summon(nv)
			Sfx.play("debuff")
		"steal":
			var sv := _view_for(d["source"])
			var amt2: float = d["amount"]
			if sv != null and amt2 > 0.0:
				_coins(_top_hud.ember_anchor(), sv.center(), 6)
				UI.float_text(_fx_layer, _local(sv.center()) + Vector2(0, -70), "−%s Ascuas" % Num.fmt(amt2), UI.RED, 22)
				Sfx.play("coin", 0.3, -2.0)
				_toast("¡Te roba %s Ascuas de la Forja! Mátala para recuperarlas ×2" % Num.fmt(amt2), Palette.color(&"blood", 4))
				sv.refresh()
		"refund":
			var rv := _view_for(d["source"])
			if rv != null:
				_fly_embers(rv.center(), 12)
				UI.float_text(_fx_layer, _local(rv.center()) + Vector2(0, -90), "¡Recuperadas ×2! +%s" % Num.fmt(d["amount"]), UI.EMBER, 24)
				Sfx.play("coin")
		"embers_gain":
			_fly_embers(player_view.center(), 8)
			UI.float_text(_fx_layer, _local(player_view.center()) + Vector2(0, -90), "+%s" % Num.fmt(d["amount"]), UI.EMBER, 24)
			Sfx.play("coin")
		"thorns":
			var tv := _view_for(d["target"])
			if tv != null:
				UI.float_text(_fx_layer, _local(tv.center()) + Vector2(0, -20), "Espinas", UI.DIM, 16)
		"revive":
			player_view.refresh()
			_banner("¡FÉNIX!", UI.EMBER)
			_burst(player_view.center(), "ember", 40, 180.0, 2.0)
			Sfx.play("rebirth")


## Ascuas hacia el contador como brasas del mundo (C18); sin efectos de F2-FX, los orbes de `main`.
func _fly_embers(global_from: Vector2, count: int) -> void:
	if _death_fx == null or not _death_fx.has_method(&"fly"):
		main.fly_embers(global_from, count)
		return
	_death_fx.call(&"fly", _wv.ui_to_world(global_from), _wv.ui_to_world(_top_hud.ember_anchor()), count)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_inside_tree():
			_top_hud.pulse())


func _coins(from: Vector2, to: Vector2, count: int) -> void:
	for i in count:
		var e := UI.icon("coin", 2)
		e.z_index = 200
		_fx_layer.add_child(e)
		e.position = _local(from)
		var tw := e.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(e, "position", _local(to) + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(e.queue_free)


func _shuffle_fx() -> void:
	for i in 6:
		var g := UI.tex_rect(Art.card_back_small(), UI.UI_PX)
		g.position = _discard_pos() - Vector2(15, 20)
		g.z_index = 90
		_fx_layer.add_child(g)
		var tw := g.create_tween()
		tw.tween_interval(i * 0.04)
		tw.tween_property(g, "position", _draw_pos() - Vector2(15, 20), 0.35).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(g, "rotation", -TAU, 0.35)
		tw.tween_callback(g.queue_free)
	Sfx.play("card", 0.3, -6.0)


func _hitstop(dur: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	main.hud.visible = true


# --- Fin del combate ------------------------------------------------------

func _finish() -> void:
	if not busy:
		busy = true
	_end_btn.disabled = true
	await get_tree().create_timer(0.9).timeout
	if engine.won:
		_victory()
	else:
		player_view.die()
		Sfx.play("defeat")
		_banner("DERROTA", UI.RED, 0.8)
		await get_tree().create_timer(1.2).timeout
		main.go("summary", {"died": true})


func _victory() -> void:
	Sfx.play("victory")
	for cv: CardView in card_views.values():
		cv.queue_free()
	card_views.clear()
	var wave := Game.gain_tower_embers(Game.victory_wave(kind), "wave")
	_fly_embers(Vector2(640, 300), 14)
	var total := engine.embers_this_combat + wave
	var relics: Array[String] = []
	if kind == "boss":
		relics = RelicDB.choices(run.relics, run.rng, 3, "boss")
		if not run.has_pact("pact_hunger"):
			run.heal(run.max_hp)
	elif kind == "elite":
		var roll := run.rng.randf()
		var rar := "rare" if roll < 0.2 else ("uncommon" if roll < 0.6 else "common")
		relics = RelicDB.choices(run.relics, run.rng, 2, rar)
	var rewards := run.roll_card_rewards(Game.card_packs(), 3, kind != "combat")
	Game.save_game()
	_show_rewards(total, wave, relics, rewards)


func _show_rewards(total: float, wave: float, relics: Array[String], rewards: Array[Card]) -> void:
	var root := Control.new()
	root.size = Vector2(1280, 720)
	root.z_index = 150
	add_child(root)
	# §12: combate → recompensa en 400 ms, la sala baja 2 pasos de rampa (no alfa). La interfaz de combate se retira y
	# las recompensas van sobre una placa opaca. Sin sala con luz (biomas legados) se mantiene el velo anterior.
	if _room != null:
		for n: CanvasItem in [_fighters_ui, _crucible, _burn_plate, _heat_label, _draw_pile, _discard_pile, _exhaust_pile, _end_btn, _hand_layer, _hint_plate]:
			if n != null:
				n.visible = false
		_wv.lights.dim = 1
		get_tree().create_timer(0.2).timeout.connect(func() -> void:
			if is_inside_tree():
				_wv.lights.dim = 2)
	else:
		var dim := ColorRect.new()
		dim.color = Color(0.03, 0.02, 0.03, 0.84)
		dim.size = Vector2(1280, 720)
		root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.sb_iron(3, Vector4(24, 16, 24, 20)))
	panel.position = Vector2(140, 56)
	root.add_child(panel)
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(760, 0)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(v)
	var title := UI.label("¡JEFE DERROTADO!" if kind == "boss" else "VICTORIA", 48, UI.EMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UI.mlabel("Ascuas de este combate: %s   (oleada de la Forja: %s)" % [Num.fmt(total), Num.fmt(wave)], UI.EMBER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var cards_box := UI.vbox(10)
	var lock := {"on": false, "cover": null}   # diccionario: las lambdas copian las variables locales
	if relics.size() > 1:
		if kind == "boss":
			v.add_child(_center_label("Las llamas del acto te restauran." if not run.has_pact("pact_hunger") else "El Hambre no te deja descansar.", UI.GREEN))
		v.add_child(_center_label("Elige una reliquia de jefe" if kind == "boss" else "Elige una reliquia", UI.EMBER))
		var rrow := UI.hbox(20)
		rrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(rrow)
		# Las cartas esperan 2 pasos más abajo hasta elegir reliquia (§12: pasos de paleta, nunca alfa).
		lock["on"] = true
		for id in relics:
			var rd := RelicDB.get_def(id)
			var b := Button.new()
			b.custom_minimum_size = Vector2(290, 120)
			b.focus_mode = Control.FOCUS_NONE
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var hb := UI.hbox(8)
			hb.position = Vector2(10, 10)
			hb.size = Vector2(270, 100)
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(UI.icon(rd["icon"], 4))   # ×4 (antes ×5: fuera de la rejilla ×2)
			var rt := UI.rich("[color=#%s]%s[/color]\n%s" % [Palette.UI[&"title"].to_html(false), rd["name"], rd["desc"]], 14)
			rt.custom_minimum_size.x = 190
			hb.add_child(rt)
			b.add_child(hb)
			var rid := id
			b.pressed.connect(func() -> void:
				run.add_relic(rid)
				Sfx.play("rebirth")
				_toast("Obtienes %s" % rd["name"], UI.EMBER)
				for other in rrow.get_children():
					(other as Button).disabled = true
				# La elegida conserva el aspecto de «hover» (antes `modulate` 1,3: fuera de paleta); las demás, inhabilitadas.
				b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("hover"))
				b.add_theme_color_override("font_disabled_color", b.get_theme_color("font_hover_color"))
				lock["on"] = false
				if lock["cover"] != null:
					(lock["cover"] as Node).queue_free()
					lock["cover"] = null)
			rrow.add_child(b)
	elif not relics.is_empty():
		var rd := RelicDB.get_def(relics[0])
		var rr := UI.hbox(10)
		rr.alignment = BoxContainer.ALIGNMENT_CENTER
		rr.add_child(UI.icon(rd["icon"], 4))
		var rt2 := UI.rich("[color=#%s]Reliquia: %s[/color]\n%s" % [Palette.UI[&"title"].to_html(false), rd["name"], rd["desc"]], 17)
		rt2.custom_minimum_size.x = 380
		rr.add_child(rt2)
		v.add_child(rr)
	v.add_child(cards_box)
	if lock["on"]:
		lock["cover"] = UI.dim_cover(cards_box, -2, [UI.PANEL])   # la cara del panel (placa 2) no cambia
	cards_box.add_child(_center_label("Elige una carta para tu mazo", UI.TEXT))
	var row := UI.hbox(30 if rewards.size() <= 3 else 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 240
	cards_box.add_child(row)
	var skip_value := Game.burn_value(1, 2, run.floor_num)
	for c in rewards:
		var holder := Control.new()
		holder.custom_minimum_size = CardView.SIZE + Vector2(0, 20)
		var cv := CardView.new(c)
		cv.position = Vector2(0, 10)
		holder.add_child(cv)
		row.add_child(holder)
		cv.hover_changed.connect(func(view: CardView, h: bool) -> void:
			view.create_tween().tween_property(view, "position:y", 2.0 if h else 10.0, 0.08))
		cv.clicked.connect(func(_view: CardView, _b: int) -> void:
			if lock["on"]:
				_toast("Primero elige una reliquia", UI.EMBER)
				return
			run.deck.append(c)
			Sfx.play("buy")
			_leave())
	if kind == "elite" and run.has_relic("res_crucible2b"):
		var purge := UI.button("Purga: eliminar una carta", func() -> void:
			main.pick_card("Purga: elige una carta para eliminar", run.deck, func(c: Variant) -> void:
				if c != null:
					run.deck.erase(c)
					Sfx.play("burn")))
		purge.custom_minimum_size = Vector2(260, 36)
		var prow := UI.hbox()
		prow.alignment = BoxContainer.ALIGNMENT_CENTER
		prow.add_child(purge)
		cards_box.add_child(prow)
	var skip := UI.button("Quemar las ofrendas (+%s Ascuas)" % Num.fmt(skip_value), func() -> void:
		if lock["on"]:
			_toast("Primero elige una reliquia", UI.EMBER)
			return
		Game.gain_tower_embers(skip_value, "skip")
		main.fly_embers(Vector2(640, 600), 6)
		_leave(), 18)
	# 362×46 (antes 360×44): el Button centra el texto Mini y con 360×44 caía en columna y fila impares.
	skip.custom_minimum_size = Vector2(362, 46)
	skip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var srow := UI.hbox()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_child(skip)
	cards_box.add_child(srow)
	# Aparece al final de la bajada de la sala, centrada en la rejilla ×2.
	root.visible = false
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	_grid_rows(cards_box)
	_grid_rows(v)
	var ps := panel.get_combined_minimum_size()
	panel.size = ps
	panel.position = Vector2(roundf((1280.0 - ps.x) / 4.0) * 2.0, maxf(48.0, roundf((720.0 - ps.y) / 4.0) * 2.0))
	root.visible = true


## Rejilla ×2 en columnas centradas: cada fila mide múltiplos de 4 px y se centra como caja (no el texto dentro de una
## etiqueta ancha ni el contenido dentro de una fila ancha), así (ancho − fila) / 2 cae siempre en par.
func _grid_rows(box: BoxContainer) -> void:
	for c: Node in box.get_children():
		var ctl := c as Control
		if ctl == null or ctl.top_level:
			continue
		if ctl is Label or ctl is RichTextLabel:
			if ctl is Label:
				(ctl as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				ctl.custom_minimum_size.x = UI.text_width(ctl)
		elif ctl is BoxContainer and ctl != box:
			(ctl as BoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
		var m := ctl.get_combined_minimum_size()
		ctl.custom_minimum_size = Vector2(ceilf(m.x / 4.0) * 4.0, ceilf(m.y / 4.0) * 4.0)
		ctl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _center_label(text: String, color: Color) -> Label:
	var l := UI.label(text, 20, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _leave() -> void:
	main.go("map")
