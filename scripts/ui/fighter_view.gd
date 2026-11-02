class_name FighterView
extends Control
## Luchador de combate en dos mitades (v0.4):
## - `actor` (Node2D) vive en el mundo de `WorldView`, en px de arte: hoja horneada con `palette_lit` (`SpriteBank`), o
##   arte legado v0.3 a ×2 si la pieza no está migrada. Todo desplazamiento se redondea a px enteros.
## - Este Control vive en la interfaz, a ×2 sobre el actor: clic, HpPlate, StatusRow e IntentView.
## La posición en el mundo es la X del centro del cuerpo sobre la línea de suelo: ver `place()`.

signal clicked(view: FighterView)

const STATUS_NAMES := {"str": "Fuerza", "weak": "Débil", "vuln": "Vulnerable", "scorch": "Quemadura",
	"thorns": "Espinas", "regen": "Regeneración", "choke": "Ahogo"}
const STATUS_DESC := {
	"str": "Aumenta el daño de los ataques.",
	"weak": "Inflige un 25% menos de daño.",
	"vuln": "Recibe un 50% más de daño.",
	"scorch": "Pierde PV al inicio del turno; luego baja 1.",
	"thorns": "Quien le ataque recibe este daño.",
	"regen": "Cura estos PV al inicio de su turno.",
	"choke": "Tu horno se ahoga: tendrás menos Quemas el próximo turno.",
}
const FLOOR_Y := 264            # suelo, en px de arte (docs/DECISIONES.md)
const WS := WorldView.SCALE     # px de interfaz por px de arte
const LEGACY_SCALE := 2         # arte legado: 1 px legado = 2 px de arte
const PLATE_Y := 532.0          # placa de vida, en px de pantalla
const STATUS_Y := 556.0
const VIEW_BOTTOM := 582.0      # por debajo sólo hay mano
const INTENT_GAP := 36.0        # 18 px de arte sobre la cabeza
const INTENT_MIN_Y := 88.0      # base de la banda de intención de jefe (y de arte 44)
## Pelo y martillo de la Fogonera siguen al calor (docs/reviews/v04/personajes/fogonera_final.md).
const TIP_HEAT := 0.35
const TIP_RADIUS := 26.0
const HERO_ID := &"fogonera"
const FLASH_SHADER := """
shader_type canvas_item;
uniform vec4 tint = vec4(1.0);
void fragment() {
	if (texture(TEXTURE, UV).a < 0.002) {
		discard;
	}
	COLOR = tint;
}
"""

static var _hero_shader: Shader
static var _flash_shader: Shader

var fighter: Fighter
var engine: CombatEngine
var wv: WorldView
## Nodo del mundo que contiene al luchador.
var actor: Node2D
## Clave de arte legada del monstruo (forma, o "forma@2" para élites ampliados).
var art_shape := ""
## Efecto de estados de F2-FX, si existe: se sincroniza en cada refresh.
var status_fx: Node
var targetable := false:
	set(v):
		targetable = v
		queue_redraw()

var _baked_id := &""
var _anim: AnimatedSprite2D     # hoja horneada, o null
var _legacy: Sprite2D           # arte legado, o null
var _legacy_glow: Sprite2D
var _legacy_mat: ShaderMaterial
var _flash_spr: Sprite2D
var _flash_mat: ShaderMaterial
var _hero_mat: ShaderMaterial
var _shadow: _ShadowNode
var _base := Vector2.ZERO       # esquina del lienzo respecto al actor
var _body := Rect2()            # cuerpo respecto al actor, en px de arte
var _off := Vector2.ZERO        # desplazamiento lógico en px de arte; se redondea al dibujar
var _center_x := 0
var _hover := false
var _t := 0.0
var _dead := false
var _busy_pose := 0.0
var _idle_phase := 0.0
var _idle_period := 0.6
var _idle_b := false
var _lift := 0
var _flash_tween: Tween
var _act_tween: Tween
var _plate: HpPlate
var _status: StatusRow
var _intent: IntentView
var _name_label: Label
var _stolen_label: Label
var _intent_y := 0.0


## `parent`: nodo del mundo donde va el actor. `shape_key`: forma legada si la criatura no tiene hoja horneada.
func setup(f: Fighter, eng: CombatEngine, world_view: WorldView, parent: Node, shape_key := "") -> void:
	fighter = f
	engine = eng
	wv = world_view
	art_shape = shape_key if shape_key != "" else f.shape
	actor = Node2D.new()
	actor.name = "Actor_" + (f.def_id if f.def_id != "" else "heroina")
	parent.add_child(actor)
	_shadow = _ShadowNode.new()
	actor.add_child(_shadow)
	_baked_id = HERO_ID if f.is_player else StringName(f.def_id)
	if SpriteBank.has(_baked_id) and SpriteBank.has_anim(_baked_id, &"idle"):
		_build_baked()
	else:
		_baked_id = &""
		_build_legacy()
	_shadow.setup(int(_body.size.x * 0.42), _is_grounded())
	_build_ui()
	_idle_phase = randf() * 2.0
	_idle_period = 0.55 + randf() * 0.25
	mouse_entered.connect(func() -> void:
		_hover = true
		_name_label.visible = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		_name_label.visible = false
		queue_redraw())
	place(_center_x)
	_plate.set_values(f.hp, f.max_hp, f.block, f.st("scorch"))
	_plate.snap()
	refresh()


func _is_grounded() -> bool:
	return _baked_id == &"" or SpriteBank.socket(_baked_id, &"idle", 0, &"ground") == null


func _build_baked() -> void:
	_anim = AnimatedSprite2D.new()
	_anim.centered = false
	_anim.sprite_frames = SpriteBank.sprite_frames(_baked_id)
	if fighter.is_player:
		_hero_mat = ShaderMaterial.new()
		_hero_mat.shader = _hero_heat_shader()
		_anim.material = _hero_mat
	else:
		_anim.material = wv.lit_material
	actor.add_child(_anim)
	var r := SpriteBank.body_rect(_baked_id)
	var g := SpriteBank.ground_y(_baked_id)
	var cx := r.position.x + r.size.x / 2
	_base = Vector2(-cx, -g)
	_body = Rect2(_base + Vector2(r.position), Vector2(r.size))
	_anim.position = _base
	_anim.animation_finished.connect(_on_anim_finished)
	_anim.play(&"idle")
	_anim.set_frame_and_progress(randi() % maxi(1, _anim.sprite_frames.get_frame_count(&"idle")), randf())
	_flash_spr = Sprite2D.new()
	_flash_spr.centered = false
	_flash_spr.visible = false
	_flash_mat = ShaderMaterial.new()
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER
	_flash_mat.shader = _flash_shader
	_flash_spr.material = _flash_mat
	actor.add_child(_flash_spr)


func _build_legacy() -> void:
	var tex: Texture2D
	if fighter.is_player:
		tex = Art.player_pose("idle")
	else:
		tex = Art.monster(art_shape, fighter.sprite_seed, fighter.biome, _cycle())
		_lift = Art.monster_lift(art_shape)
	_legacy = Sprite2D.new()
	_legacy.centered = false
	_legacy.texture = tex
	_legacy.scale = Vector2(LEGACY_SCALE, LEGACY_SCALE)
	_legacy_mat = UI.dissolve_material(Vector2(tex.get_width(), tex.get_height()))
	_legacy_mat.set_shader_parameter("edge_a", Palette.color(&"gold", 5))
	_legacy.material = _legacy_mat
	actor.add_child(_legacy)
	var used := tex.get_image().get_used_rect()
	var cx := (used.position.x + used.size.x / 2) * LEGACY_SCALE
	var ground := used.end.y * LEGACY_SCALE
	_base = Vector2(-cx, -ground - _lift * LEGACY_SCALE)
	_body = Rect2(_base + Vector2(used.position * LEGACY_SCALE), Vector2(used.size * LEGACY_SCALE))
	_legacy.position = _base
	if not fighter.is_player:
		var gt := Art.monster_glow(art_shape, fighter.sprite_seed, fighter.biome, _cycle())
		if gt != null:
			_legacy_glow = Sprite2D.new()
			_legacy_glow.centered = false
			_legacy_glow.texture = gt
			_legacy_glow.material = UI.add_material(1.0)
			_legacy.add_child(_legacy_glow)


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_plate = HpPlate.new()
	add_child(_plate)
	_status = StatusRow.new()
	add_child(_status)
	_intent = IntentView.new()
	_intent.visible = false
	add_child(_intent)
	var name_col: Color = UI.EMBER if fighter.is_boss else (Palette.color(&"blood", 4) if fighter.is_elite else UI.TEXT)
	_name_label = UI.label(fighter.display_name, 14, name_col)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.visible = false
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	_stolen_label = UI.label("", 14, UI.EMBER)
	_stolen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stolen_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stolen_label)


## Copia de `palette_lit` sólo para la heroína: la cara `hot` del martillo va del paso 1 al 5 con `forge_heat` y las puntas
## de `fire` junto a la cabeza pasan a `hair 2` con poco calor. El shader base no usa `forge_heat`: si algún día lo hace,
## esto desaparece. Si el texto base cambia, respaldo al shader base.
static func _hero_heat_shader() -> Shader:
	if _hero_shader != null:
		return _hero_shader
	var base: Shader = load("res://shaders/palette_lit.gdshader")
	var needle := "s = clamp(stp + emit_pulse, 0, 15);"
	var decl := "uniform bool unlit = false;"
	if not (base.code.contains(needle) and base.code.contains(decl)):
		push_warning("FighterView: palette_lit cambió; pelo y martillo no siguen al calor")
		_hero_shader = base
		return base
	var body := """%s
		if (mat_i == %d) {
			s = clamp(stp - 4 + int(round(forge_heat * 4.0)) + emit_pulse, 1, 15);
		} else if (mat_i == %d && tips_follow_heat && forge_heat <= %f && distance(px, head_pos) < %f) {
			mat_i = %d;
			s = 2;
		}""" % [needle, Palette.index(&"hot"), Palette.index(&"fire"), TIP_HEAT, TIP_RADIUS, Palette.index(&"hair")]
	var sh := Shader.new()
	sh.code = base.code.replace(needle, body).replace(decl, decl + "\nuniform vec2 head_pos = vec2(0.0);\nuniform bool tips_follow_heat = true;")
	_hero_shader = sh
	return sh


# --- Colocación -----------------------------------------------------------------------------------

## Coloca el centro del cuerpo en la X de mundo `cx`, con los pies sobre el suelo. También recoloca la mitad de interfaz.
func place(cx: int) -> void:
	_center_x = cx
	actor.position = Vector2(cx, FLOOR_Y)
	var w := maxf(_body.size.x * WS, HpPlate.SIZE.x)
	var top := minf((FLOOR_Y + _body.position.y) * WS, PLATE_Y - 40.0)
	position = (Vector2(cx * WS - w * 0.5, top) / 2.0).round() * 2.0
	size = Vector2(w, VIEW_BOTTOM - position.y)
	_plate.position = Vector2(roundf((w - HpPlate.SIZE.x) * 0.25) * 2.0, PLATE_Y - position.y)
	_status.position = Vector2(_plate.position.x, STATUS_Y - position.y)
	_name_label.size = Vector2(w + 80.0, 16)
	_name_label.position = Vector2(-40, _plate.position.y - 18.0)
	_stolen_label.size = Vector2(w + 120.0, 16)
	_intent_y = maxf(top - INTENT_GAP, INTENT_MIN_Y) - position.y
	_stolen_label.position = Vector2(-60, _intent_y - 40.0)
	_place_intent()
	if status_fx != null:
		status_fx.call(&"set_body", body_world())


func center_x() -> int:
	return _center_x


func body_width() -> float:
	return _body.size.x


## Caja del cuerpo en el mundo (sin el desplazamiento de animación).
func body_world() -> Rect2:
	return Rect2(actor.position + _body.position, _body.size)


## Silueta en reposo del tamaño del cuerpo, para que StatusFX siga el contorno.
func body_mask() -> Image:
	var img: Image
	if _anim != null:
		var m := SpriteBank.meta(_baked_id)
		var src := SpriteBank.atlas_image(_baked_id)
		if src == null:
			return null
		var row := int(m["anims"]["idle"]["row"]) * int(m["size"][1])
		var r := SpriteBank.body_rect(_baked_id)
		img = src.get_region(Rect2i(r.position + Vector2i(0, row), r.size))
	else:
		var src := _legacy.texture.get_image()
		img = src.get_region(src.get_used_rect())
		img.resize(img.get_width() * LEGACY_SCALE, img.get_height() * LEGACY_SCALE, Image.INTERPOLATE_NEAREST)
	return img


## Centro de los pies en el mundo.
func foot_world() -> Vector2:
	return Vector2(_center_x, FLOOR_Y)


## Esquina superior izquierda del lienzo en el mundo.
func canvas_world() -> Vector2:
	return actor.position + _base + _off.round()


## Fotograma actual, para DeathEmbers.
func current_frame() -> Texture2D:
	if _anim != null:
		return _anim.sprite_frames.get_frame_texture(_anim.animation, _anim.frame)
	return _legacy.texture


## Centro del cuerpo en coordenadas globales de interfaz.
func center() -> Vector2:
	return wv.world_to_ui(actor.position + _body.get_center() + _off.round())


# --- Dibujo y bucle --------------------------------------------------------------------------------

func _draw() -> void:
	if fighter == null or not targetable:
		return
	var r := Rect2((actor.position + _body.position) * WS - position, _body.size * WS)
	if _hover:
		_corner_brackets(r.grow(8.0), Palette.color(&"ember_ui", 5), 4.0)
	else:
		# Parpadeo en dos pasos: sin alfa continua.
		var col := Palette.color(&"ember_ui", 4 if fmod(_t, 0.5) < 0.25 else 2)
		_corner_brackets(r.grow(4.0), col, 4.0)


func _corner_brackets(r: Rect2, c: Color, w: float) -> void:
	var l := minf(28.0, r.size.x * 0.3)
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		draw_rect(Rect2(corner.x - (w if sx < 0 else 0.0), corner.y - (w if sy < 0 else 0.0), l * sx, w).abs(), c)
		draw_rect(Rect2(corner.x - (w if sx < 0 else 0.0), corner.y - (w if sy < 0 else 0.0), w, l * sy).abs(), c)


func _process(delta: float) -> void:
	if fighter == null:
		return
	_t += delta
	var p := _base + _off.round()
	if _anim != null:
		_anim.position = p
		if _flash_spr.visible:
			_flash_spr.position = p
			_flash_spr.texture = current_frame()
		if _hero_mat != null:
			_update_hero_uniforms()
	elif _legacy != null:
		_legacy.position = p
	if targetable:
		queue_redraw()
	if _dead:
		return
	if _intent.visible:
		_intent.position.y = _intent_y - _intent.size.y + 2.0 * roundf(sin(_t * 3.0))
	if _legacy == null:
		return
	if _legacy_glow != null:
		_legacy_glow.modulate.a = 0.45 + 0.1 * floorf(2.0 + 2.0 * sin(_t * 2.6 + fighter.max_hp))
	# Arte legado: respiración de dos fotogramas.
	if _busy_pose > 0.0:
		_busy_pose -= delta
		if _busy_pose <= 0.0:
			_set_legacy_pose("idle")
	else:
		var b := fposmod(_t + _idle_phase, _idle_period * 2.0) > _idle_period
		if b != _idle_b:
			_idle_b = b
			_set_legacy_pose("idle_b" if b else "idle")


func _update_hero_uniforms() -> void:
	var head: Variant = SpriteBank.socket(_baked_id, _anim.animation, _anim.frame, &"head")
	if head != null:
		_hero_mat.set_shader_parameter(&"head_pos", _anim.global_position + Vector2(head as Vector2i))
	# La estela del martillazo también es `fire`: no debe confundirse con las puntas.
	var a := _anim.animation
	var smear := a == &"smear" or (a == &"attack" and _anim.frame in [1, 2]) or (a == &"strike" and _anim.frame == 1)
	_hero_mat.set_shader_parameter(&"tips_follow_heat", not smear)


func _on_anim_finished() -> void:
	if not _dead:
		_anim.play(&"idle")


func _play(anim: StringName) -> void:
	if _anim != null and _anim.sprite_frames.has_animation(anim):
		_anim.play(anim)


func _set_legacy_pose(pose: String) -> void:
	if _legacy == null:
		return
	if fighter.is_player:
		_legacy.texture = Art.player_pose(pose)
		return
	var mp := "base"
	match pose:
		"idle_b", "crouch", "windup":
			mp = "crouch"
		"stretch", "strike":
			mp = "stretch"
	_legacy.texture = Art.monster_pose(art_shape, fighter.sprite_seed, fighter.biome, _cycle(), mp)
	if _legacy_glow != null:
		_legacy_glow.texture = Art.monster_pose_glow(art_shape, fighter.sprite_seed, fighter.biome, _cycle(), mp)


func _cycle() -> int:
	return EnemyDB.cycle(engine.floor_num) if engine != null else 0


func _legacy_seq(seq: Array) -> void:
	if _legacy == null:
		return
	var total := 0.0
	for step: Array in seq:
		total += float(step[1])
	_busy_pose = total + 0.02
	var tw := create_tween()
	for step: Array in seq:
		var p: String = step[0]
		tw.tween_callback(func() -> void: _set_legacy_pose(p))
		tw.tween_interval(float(step[1]))


# --- Estado ------------------------------------------------------------------------------------------

func refresh() -> void:
	if fighter == null:
		return
	_plate.set_values(fighter.hp, fighter.max_hp, fighter.block, fighter.st("scorch"))
	_status.set_fighter(fighter)
	_stolen_label.text = "Lleva %s Ascuas robadas" % Num.fmt(fighter.stolen) if fighter.stolen > 0.0 and fighter.alive() else ""
	_refresh_intent()
	if status_fx != null:
		status_fx.call(&"sync", fighter.statuses, fighter.block)
	queue_redraw()


func _refresh_intent() -> void:
	if fighter.is_player:
		return
	_intent.visible = fighter.alive() and not fighter.intent.is_empty() and not _dead
	if not _intent.visible:
		return
	var dmg := engine.intent_damage(fighter)
	_intent.set_intent(String(fighter.intent.get("kind", "attack")), dmg.x, dmg.y, _intent_tooltip())
	_place_intent()


func _place_intent() -> void:
	_intent.place_above(size.x * 0.5, _intent_y)


func _intent_tooltip() -> String:
	var parts: PackedStringArray = []
	for op: Array in fighter.intent.get("ops", []):
		match op[0]:
			"atk": parts.append("Atacará")
			"block", "block_all": parts.append("Se defenderá")
			"str", "str_all": parts.append("Se fortalecerá")
			"heal", "heal_all": parts.append("Se curará")
			"scorch_p": parts.append("Te quemará")
			"weak_p": parts.append("Te debilitará")
			"vuln_p": parts.append("Te hará vulnerable")
			"add_card": parts.append("Ensuciará tu mazo")
			"steal": parts.append("Robará %s Ascuas de tu Forja (las devuelve dobles si muere)" % Num.fmt(engine.steal_amount(float(op[1]))))
			"choke": parts.append("Ahogará tu horno (−%d Quema)" % op[1])
			"summon": parts.append("Invocará aliados")
			"thorns": parts.append("Se cubrirá de espinas")
			"regen": parts.append("Regenerará")
	return "Intención: " + ", ".join(parts)


# --- Gestos ------------------------------------------------------------------------------------------

## Destello de impacto: 1 fotograma blanco (33 ms) y luego el color dado durante 100 ms. Sin fundidos.
func flash(color: Color = Color.WHITE) -> void:
	if _flash_tween:
		_flash_tween.kill()
	if _anim != null:
		_flash_spr.visible = true
		_flash_spr.position = _base + _off.round()
		_flash_spr.texture = current_frame()
		_flash_mat.set_shader_parameter(&"tint", Color.WHITE)
		_flash_tween = create_tween()
		_flash_tween.tween_interval(0.033)
		_flash_tween.tween_callback(func() -> void: _flash_mat.set_shader_parameter(&"tint", color))
		_flash_tween.tween_interval(0.1)
		_flash_tween.tween_callback(func() -> void: _flash_spr.visible = false)
		return
	_legacy_mat.set_shader_parameter("flash_color", Color.WHITE)
	_legacy_mat.set_shader_parameter("flash", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.033)
	_flash_tween.tween_callback(func() -> void: _legacy_mat.set_shader_parameter("flash_color", color))
	_flash_tween.tween_method(func(v: float) -> void: _legacy_mat.set_shader_parameter("flash", v), 0.85, 0.0, 0.1)


func _tween_off(seq: Array) -> Tween:
	if _act_tween:
		_act_tween.kill()
	_act_tween = create_tween()
	for st: Array in seq:
		var tr: Tween.TransitionType = st[2] if st.size() > 2 else Tween.TRANS_QUAD
		var ea: Tween.EaseType = st[3] if st.size() > 3 else Tween.EASE_OUT
		if st[0] is Vector2:
			_act_tween.tween_property(self, "_off", st[0], float(st[1])).set_trans(tr).set_ease(ea)
		else:
			_act_tween.tween_interval(float(st[1]))
	return _act_tween


## Golpe recibido: empuje de 6–10 px de arte en dirección contraria al rival y vuelta con rebote.
func shake(strength: float = 8.0) -> void:
	var dir := -1.0 if fighter.is_player else 1.0
	var push := clampf(roundf(strength / 4.0), 3.0, 5.0) * LEGACY_SCALE
	_play(&"hurt")
	_legacy_seq([["hurt", 0.22]] if fighter.is_player else [["crouch", 0.12]])
	_tween_off([[Vector2(dir * push, 0), 0.05], [Vector2.ZERO, 0.15, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Embestida enemiga: anticipación → lanzamiento → impacto → vuelta.
func lunge(dir: float) -> void:
	_play(&"attack")
	_legacy_seq([["crouch", 0.16], ["stretch", 0.1], ["base", 0.26]])
	_tween_off([[Vector2(-8.0 * dir, 0), 0.16, Tween.TRANS_SINE, Tween.EASE_OUT],
		[Vector2(24.0 * dir, 0), 0.06, Tween.TRANS_QUAD, Tween.EASE_IN],
		[null, 0.06],
		[Vector2.ZERO, 0.24, Tween.TRANS_QUAD, Tween.EASE_OUT]])


## Martillazo de la heroína.
func swing() -> void:
	if not fighter.is_player:
		lunge(1.0)
		return
	_play(&"attack")
	_legacy_seq([["windup", 0.18], ["smear", 0.033], ["strike", 0.09], ["recover", 0.12], ["idle", 0.1]])
	_tween_off([[Vector2(-4.0, 0), 0.14, Tween.TRANS_SINE, Tween.EASE_OUT],
		[null, 0.04],
		[Vector2(12.0, 0), 0.033, Tween.TRANS_LINEAR, Tween.EASE_IN],
		[null, 0.09],
		[Vector2.ZERO, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Gesto enemigo sin ataque (defenderse, fortalecerse…).
func gesture() -> void:
	_play(&"cast")
	_legacy_seq([["crouch", 0.1], ["stretch", 0.12], ["base", 0.06]])
	_tween_off([[Vector2(0, -2.0), 0.1], [Vector2.ZERO, 0.12, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Habilidad o poder: alza el martillo.
func cast() -> void:
	if not fighter.is_player:
		return
	_play(&"cast")
	_legacy_seq([["cast", 0.3], ["recover", 0.08]])
	_tween_off([[Vector2(0, -2.0), 0.08], [null, 0.18], [Vector2.ZERO, 0.12]])


## Quemar: echa la carta a la Forja, a su izquierda.
func toss() -> void:
	if not fighter.is_player:
		return
	_play(&"toss")
	_legacy_seq([["toss_back", 0.1], ["toss", 0.22], ["recover", 0.08]])


func _retire_ui() -> void:
	_dead = true
	_intent.visible = false
	_stolen_label.text = ""
	_plate.visible = false
	_status.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.visible = false
	if status_fx != null:
		status_fx.queue_free()
		status_fx = null
	queue_redraw()


func die() -> void:
	if _dead:
		return
	_retire_ui()
	flash(Palette.color(&"gold", 5))
	if _anim != null:
		_anim.play(&"death" if _anim.sprite_frames.has_animation(&"death") else &"hurt")
		if not fighter.is_player:
			var dur := 0.1
			for ms: Variant in SpriteBank.frame_ms(_baked_id, _anim.animation):
				dur += float(ms) / 1000.0
			var hide_tw := create_tween()
			hide_tw.tween_interval(dur)
			hide_tw.tween_callback(func() -> void: actor.visible = false)
		return
	if _legacy_glow != null:
		_legacy_glow.visible = false
	_set_legacy_pose("crouch")
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_method(func(v: float) -> void: _legacy_mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "_off", Vector2(0, 4.0), 0.7)
	tw.tween_callback(func() -> void: actor.visible = false)


## Huida (Urraca): salta hacia atrás y sale del encuadre.
func flee() -> void:
	_retire_ui()
	_play(&"flee")
	_legacy_seq([["crouch", 0.12], ["stretch", 0.4]])
	var tw := create_tween()
	tw.tween_property(self, "_off", Vector2(-4.0, 0), 0.12)
	tw.tween_property(self, "_off", Vector2(240.0, -96.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: actor.visible = false)


## Aparición (invocaciones): sube del suelo con un gesto; el arte legado se materializa desde las brasas.
func spawn() -> void:
	if _anim != null:
		_off = Vector2(0, 8.0)
		_play(&"cast")
		flash(Palette.color(&"fire", 5))
		_tween_off([[Vector2.ZERO, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT]])
		return
	_legacy_mat.set_shader_parameter("progress", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _legacy_mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.5)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func _exit_tree() -> void:
	if actor != null and is_instance_valid(actor):
		actor.queue_free()


## Sombra tramada sobre el suelo (sin alfa): más pequeña si el luchador vuela.
class _ShadowNode extends Node2D:
	var half := 8
	var rows := 3

	func setup(half_width: int, grounded: bool) -> void:
		half = maxi(4, half_width if grounded else half_width / 2)
		rows = 3 if grounded else 2
		queue_redraw()

	func _draw() -> void:
		for y in rows:
			var w := half - y * 3
			for x in range(-w, w + 1):
				if (x + y) % 2 == 0:
					draw_rect(Rect2(x, y - 1, 1, 1), Palette.OUTLINE)
