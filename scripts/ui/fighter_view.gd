class_name FighterView
extends Control
## Sprite + barra de vida + bloqueo + estados + intención de un combatiente.
## Reglas de píxel (ver docs/ART_BIBLE.md): el sprite se dibuja SIEMPRE a ×4 (UI.PX), sin escalar ni rotar;
## todo movimiento pasa por `_off` (desplazamiento lógico) que se ajusta a la rejilla de 4 px cada fotograma.
## Los gestos (golpe, embestida, respiración) se hacen con fotogramas, no con transformaciones.

signal clicked(view: FighterView)

const STATUS_ICONS := {"str": "str", "weak": "down", "vuln": "vuln", "scorch": "flame", "thorns": "spikes",
	"regen": "regen", "choke": "choke"}
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
## Compatibilidad: el brazo ya no rota (las poses vienen dibujadas).
const ARM_REST := 0.0
const SPRITE_TOP := 44

var fighter: Fighter
var engine: CombatEngine
## Clave de arte del monstruo (forma, o "forma@2" para élites ampliados). Vacía = fighter.shape.
var art_shape := ""
var sprite: TextureRect
var arm: TextureRect = null
var glow: TextureRect
var targetable := false:
	set(v):
		targetable = v
		queue_redraw()
## Desplazamiento lógico del sprite (px de pantalla); se ajusta a múltiplos de UI.PX al dibujar.
var _off := Vector2.ZERO
var _hover := false
var _hp_label: Label
var _block_label: Label
var _block_icon: TextureRect
var _status_row: HBoxContainer
var _intent_box: HBoxContainer
var _intent_icon: TextureRect
var _intent_label: Label
var _name_label: Label
var _stolen_label: Label
var _mat: ShaderMaterial
var _shown_hp := 0.0
var _sprite_base := Vector2.ZERO
var _t := 0.0
var _dead := false
var _busy_pose := 0.0          # segundos en los que una pose manda sobre la respiración
var _idle_phase := 0.0
var _idle_period := 0.6
var _idle_b := false
var _lift := 0
var _flash_tween: Tween
var _act_tween: Tween


func setup(f: Fighter, eng: CombatEngine, tex: Texture2D, _px_scale: float = 4.0, glow_tex: Texture2D = null) -> void:
	fighter = f
	engine = eng
	var px := float(UI.PX)
	if f.is_player:
		tex = Art.player_pose("idle")
	else:
		if art_shape == "":
			art_shape = f.shape
		_lift = Art.monster_lift(art_shape)
	var spr_size := Vector2(tex.get_width(), tex.get_height()) * px
	# Ancho de la vista: el margen a cada lado debe ser múltiplo de UI.PX.
	var extra := maxf(0.0, ceilf((152.0 - spr_size.x) / (2.0 * px)) * 2.0 * px)
	size = Vector2(spr_size.x + extra, spr_size.y + SPRITE_TOP + 52)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sprite = UI.tex_rect(tex, px)
	_mat = UI.dissolve_material(Vector2(tex.get_width(), tex.get_height()))
	_mat.set_shader_parameter("edge_a", Color("ffe08a"))
	sprite.material = _mat
	_sprite_base = Vector2(extra * 0.5, SPRITE_TOP)
	sprite.position = _sprite_base
	add_child(sprite)
	_shown_hp = f.hp
	if not f.is_player and glow_tex != null:
		glow = UI.tex_rect(glow_tex, px)
		glow.material = UI.add_material(1.0)
		sprite.add_child(glow)
	_idle_phase = randf() * 2.0
	_idle_period = 0.55 + randf() * 0.25

	_intent_box = UI.hbox(4)
	_intent_box.position = Vector2(size.x * 0.5 - 40, 0)
	_intent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_icon = UI.icon("sword", 3)
	_intent_label = UI.plabel("", 3, Color("ffd36a"))
	_intent_box.add_child(_intent_icon)
	_intent_box.add_child(_intent_label)
	_intent_box.visible = not f.is_player
	add_child(_intent_box)

	var base_y := SPRITE_TOP + spr_size.y + 6
	_block_icon = UI.icon("shield", 2)
	_block_icon.position = Vector2(size.x * 0.5 - 75 - 26, base_y - 4)
	add_child(_block_icon)
	_block_label = UI.plabel("", 2, UI.BLUE)
	_block_label.position = _block_icon.position + Vector2(-2, -1)
	_block_label.size = Vector2(28, 26)
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_block_label)

	_hp_label = UI.plabel("", 2)
	_hp_label.position = Vector2(size.x * 0.5 - 75, base_y - 4)
	_hp_label.size = Vector2(150, 26)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hp_label)

	_name_label = UI.label(f.display_name, 13, UI.EMBER if f.is_boss else (Color("ff9a7a") if f.is_elite else UI.DIM))
	_name_label.position = Vector2(0, base_y + 20)
	_name_label.size = Vector2(size.x, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)

	_stolen_label = UI.label("", 12, UI.EMBER)
	_stolen_label.position = Vector2(0, base_y + 54)
	_stolen_label.size = Vector2(size.x, 14)
	_stolen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_stolen_label)

	_status_row = UI.hbox(2)
	_status_row.position = Vector2(size.x * 0.5 - 75, base_y + 36)
	add_child(_status_row)

	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())
	refresh()


## Distancia (px) desde el borde superior de la vista hasta la línea de los pies (incluye vuelo).
func feet_offset() -> float:
	return SPRITE_TOP + sprite.size.y - float(UI.PX) + _lift * UI.PX


func hp_bar_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 75, SPRITE_TOP + sprite.size.y + 4, 150, 18)


func _draw() -> void:
	if fighter == null:
		return
	# Sombra en el suelo (escalonada en píxeles de arte).
	if not _dead:
		var px := float(UI.PX)
		var foot := Vector2(_sprite_base.x + sprite.size.x * 0.5, SPRITE_TOP + sprite.size.y - px + _lift * px)
		var sw := floorf(sprite.size.x * 0.42 / px) * px
		for i in 2:
			draw_rect(Rect2(foot.x - sw + i * px * 2, foot.y - px * 0.5 + i * px * 0.5, (sw - i * px * 2) * 2, px), Color(0, 0, 0, 0.28 - i * 0.08))
	var r := hp_bar_rect()
	draw_rect(r.grow(2), UI.OUTLINE)
	draw_rect(r, Color("2a1418"))
	var ratio := clampf(_shown_hp / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	var real := clampf(float(fighter.hp) / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	draw_rect(Rect2(r.position, Vector2(floorf(r.size.x * ratio / 2.0) * 2.0, r.size.y)), Color("ffe08a"))
	var col := Color("c2321e") if fighter.block <= 0 else Color("4a7aaa")
	var rw := floorf(r.size.x * real / 2.0) * 2.0
	draw_rect(Rect2(r.position, Vector2(rw, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(rw, 4)), col.lightened(0.3))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(rw, 4)), col.darkened(0.3))
	if fighter.st("scorch") > 0:
		var sw2 := r.size.x * minf(float(fighter.st("scorch")) / maxf(1.0, fighter.max_hp), real)
		draw_rect(Rect2(r.position + Vector2(rw - sw2, 0), Vector2(sw2, r.size.y)), Color(1, 0.6, 0.1, 0.55))
	if targetable and _hover:
		var sr := Rect2(_sprite_base - Vector2(8, 8), sprite.size + Vector2(16, 16))
		_corner_brackets(sr, Color("ffe08a"), 4.0)
	elif targetable:
		var a := 0.35 + 0.25 * sin(_t * 6.0)
		_corner_brackets(Rect2(_sprite_base - Vector2(4, 4), sprite.size + Vector2(8, 8)), Color(1, 0.85, 0.5, a), 4.0)


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
	var px := float(UI.PX)
	sprite.position = _sprite_base + (_off / px).round() * px
	if absf(_shown_hp - fighter.hp) > 0.05:
		_shown_hp = move_toward(_shown_hp, fighter.hp, maxf(1.0, fighter.max_hp) * delta * 0.8)
		queue_redraw()
	if targetable:
		queue_redraw()
	if _dead:
		return
	if glow != null:
		# Pulso en 4 pasos (no un degradado continuo).
		glow.modulate.a = 0.45 + 0.1 * floorf(2.0 + 2.0 * sin(_t * 2.6 + fighter.max_hp))
	if _intent_box.visible:
		_intent_box.position.y = -4.0 + 2.0 * roundf(sin(_t * 3.0))
	# Respiración: alterna 2 fotogramas (base / aplastado 1 px).
	if _busy_pose > 0.0:
		_busy_pose -= delta
		if _busy_pose <= 0.0:
			_set_pose("idle")
	else:
		var b := fposmod(_t + _idle_phase, _idle_period * 2.0) > _idle_period
		if b != _idle_b:
			_idle_b = b
			_set_pose("idle_b" if b else "idle")


## Cambia el fotograma del sprite (y de su capa emisiva).
func _set_pose(pose: String) -> void:
	if fighter.is_player:
		sprite.texture = Art.player_pose(pose)
		return
	var mp := "base"
	match pose:
		"idle_b", "crouch", "windup":
			mp = "crouch"
		"stretch", "strike":
			mp = "stretch"
	sprite.texture = Art.monster_pose(art_shape, fighter.sprite_seed, fighter.biome, _cycle(), mp)
	if glow != null:
		glow.texture = Art.monster_pose_glow(art_shape, fighter.sprite_seed, fighter.biome, _cycle(), mp)


func _cycle() -> int:
	return EnemyDB.cycle(engine.floor_num) if engine != null else 0


## Muestra una secuencia de poses: [[pose, segundos], ...]; vuelve a la respiración al final.
func _pose_seq(seq: Array) -> void:
	var total := 0.0
	for step: Array in seq:
		total += float(step[1])
	_busy_pose = total + 0.02
	var tw := create_tween()
	for step: Array in seq:
		var p: String = step[0]
		tw.tween_callback(func() -> void: _set_pose(p))
		tw.tween_interval(float(step[1]))


func refresh() -> void:
	if fighter == null:
		return
	_hp_label.text = "%d/%d" % [fighter.hp, fighter.max_hp]
	_block_icon.visible = fighter.block > 0
	_block_label.visible = fighter.block > 0
	_block_label.text = str(fighter.block)
	_stolen_label.text = "Lleva %s Ascuas robadas" % Num.fmt(fighter.stolen) if fighter.stolen > 0.0 and fighter.alive() else ""
	UI.clear(_status_row)
	for id: String in ["str", "weak", "vuln", "scorch", "thorns", "regen", "choke"]:
		var v := fighter.st(id)
		if v == 0:
			continue
		var b := Control.new()
		b.custom_minimum_size = Vector2(32, 30)
		b.tooltip_text = "%s %d\n%s" % [STATUS_NAMES[id], v, STATUS_DESC[id]]
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		var ic := UI.icon(STATUS_ICONS[id], 2)
		b.add_child(ic)
		var l := UI.plabel(str(v), 1, Color("ffd36a"))
		l.position = Vector2(16, 12)
		b.add_child(l)
		_status_row.add_child(b)
	if fighter.is_player:
		for pid: String in fighter.powers:
			var pb := Control.new()
			pb.custom_minimum_size = Vector2(32, 30)
			var txt: String = CardDB.POWERS.get(pid, "")
			pb.tooltip_text = "Poder\n" + txt.replace("%d", str(fighter.pw(pid)))
			pb.mouse_filter = Control.MOUSE_FILTER_PASS
			pb.add_child(UI.icon(CardDB.POWER_ICONS.get(pid, "star"), 2))
			var pl := UI.plabel(str(fighter.pw(pid)), 1, Color("ffd36a"))
			pl.position = Vector2(16, 12)
			pb.add_child(pl)
			_status_row.add_child(pb)
	_refresh_intent()
	queue_redraw()


func _refresh_intent() -> void:
	if fighter.is_player:
		return
	_intent_box.visible = fighter.alive() and not fighter.intent.is_empty() and not _dead
	if not _intent_box.visible:
		return
	var k: String = fighter.intent.get("kind", "attack")
	var ic := "sword"
	match k:
		"defend": ic = "shield"
		"buff": ic = "up"
		"debuff": ic = "down"
		"steal": ic = "coin"
		"summon": ic = "skull"
		"attack_debuff", "attack_defend", "attack": ic = "sword"
	_intent_icon.texture = Art.icon(ic)
	var dmg := engine.intent_damage(fighter)
	if dmg.x >= 0:
		_intent_label.text = str(dmg.x) if dmg.y <= 1 else "%d×%d" % [dmg.x, dmg.y]
		var total := dmg.x * dmg.y
		_intent_label.add_theme_color_override("font_color", Color("ff6a4a") if total >= 20 else Color("ffd36a"))
	else:
		_intent_label.text = ""
	_intent_box.tooltip_text = _intent_tooltip()
	_intent_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_intent_box.reset_size()
	_intent_box.position.x = roundf((size.x * 0.5 - _intent_box.size.x * 0.5) / 2.0) * 2.0


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


func center() -> Vector2:
	return global_position + _sprite_base + _off + sprite.size * 0.5


## Destello de impacto: 1 fotograma blanco (33 ms) y luego el color dado, que se apaga en 100 ms.
func flash(color: Color = Color.WHITE) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_mat.set_shader_parameter("flash_color", Color.WHITE)
	_mat.set_shader_parameter("flash", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.033)
	_flash_tween.tween_callback(func() -> void: _mat.set_shader_parameter("flash_color", color))
	_flash_tween.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 0.85, 0.0, 0.1)


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


## Golpe recibido: empuje direccional de 3–5 px de arte y vuelta con rebote. Sin temblor aleatorio.
func shake(strength: float = 8.0) -> void:
	var dir := -1.0 if fighter.is_player else 1.0
	var push := clampf(roundf(strength / 4.0), 3.0, 5.0) * UI.PX
	if fighter.is_player:
		_pose_seq([["hurt", 0.22]])
	else:
		_pose_seq([["crouch", 0.12]])
	_tween_off([[Vector2(dir * push, 0), 0.05], [Vector2.ZERO, 0.15, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Embestida enemiga: anticipación agachado (160 ms) → estirado al lanzarse (60 ms) → impacto → vuelta.
func lunge(dir: float) -> void:
	var px := float(UI.PX)
	_pose_seq([["crouch", 0.16], ["stretch", 0.1], ["base", 0.26]])
	_tween_off([[Vector2(-4.0 * px * dir, 0), 0.16, Tween.TRANS_SINE, Tween.EASE_OUT],
		[Vector2(12.0 * px * dir, 0), 0.06, Tween.TRANS_QUAD, Tween.EASE_IN],
		[null, 0.06],
		[Vector2.ZERO, 0.24, Tween.TRANS_QUAD, Tween.EASE_OUT]])


## Martillazo: carga 140 ms → pausa 40 ms → estela 33 ms → impacto 50 ms → recuperación 220 ms.
func swing() -> void:
	if not fighter.is_player:
		lunge(1.0)
		return
	var px := float(UI.PX)
	_pose_seq([["windup", 0.18], ["smear", 0.033], ["strike", 0.09], ["recover", 0.12], ["idle", 0.1]])
	_tween_off([[Vector2(-2.0 * px, 0), 0.14, Tween.TRANS_SINE, Tween.EASE_OUT],
		[null, 0.04],
		[Vector2(6.0 * px, 0), 0.033, Tween.TRANS_LINEAR, Tween.EASE_IN],
		[null, 0.09],
		[Vector2.ZERO, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Gesto enemigo sin ataque (defenderse, fortalecerse…): agacharse y estirarse.
func gesture() -> void:
	_pose_seq([["crouch", 0.1], ["stretch", 0.12], ["base", 0.06]])
	_tween_off([[Vector2(0, -1.0 * UI.PX), 0.1], [Vector2.ZERO, 0.12, Tween.TRANS_BACK, Tween.EASE_OUT]])


## Habilidad/poder: alza el martillo.
func cast() -> void:
	if not fighter.is_player:
		return
	_pose_seq([["cast", 0.3], ["recover", 0.08]])
	_tween_off([[Vector2(0, -1.0 * UI.PX), 0.08], [null, 0.18], [Vector2.ZERO, 0.12]])


## Quemar: echa la carta al horno, que está detrás (a la izquierda).
func toss() -> void:
	if not fighter.is_player:
		return
	_pose_seq([["toss_back", 0.1], ["toss", 0.22], ["recover", 0.08]])


func die() -> void:
	_dead = true
	_intent_box.visible = false
	_stolen_label.text = ""
	if glow != null:
		glow.visible = false
	flash(Color("ffe08a"))
	_set_pose("crouch")
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "_off", Vector2(0, 2.0 * UI.PX), 0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
	queue_redraw()


## Huida (Urraca): salta hacia atrás y se desvanece en humo, sin chispas de Ascuas.
func flee() -> void:
	_dead = true
	_intent_box.visible = false
	_stolen_label.text = ""
	_pose_seq([["crouch", 0.12], ["stretch", 0.4]])
	var px := float(UI.PX)
	var tw := create_tween()
	tw.tween_property(self, "_off", Vector2(-2.0 * px, 0), 0.12)
	tw.tween_property(self, "_off", Vector2(30.0 * px, -16.0 * px), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tw.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
	queue_redraw()


## Aparición (invocaciones): se materializa desde las brasas.
func spawn() -> void:
	_mat.set_shader_parameter("progress", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.5)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()
