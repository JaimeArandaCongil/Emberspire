class_name FighterView
extends Control
## Sprite + barra de vida + bloqueo + estados + intención de un combatiente.
## La heroína tiene el brazo del martillo como pieza aparte (golpes animados);
## los monstruos tienen una capa emisiva (ojos y venas) que late.

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
const ARM_REST := -0.12

var fighter: Fighter
var engine: CombatEngine
var sprite: TextureRect
var arm: TextureRect
var glow: TextureRect
var targetable := false:
	set(v):
		targetable = v
		queue_redraw()
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
var _bob_tween: Tween
var _scale := 6.0
var _t := 0.0
var _dead := false


func setup(f: Fighter, eng: CombatEngine, tex: Texture2D, px_scale: float, glow_tex: Texture2D = null) -> void:
	fighter = f
	engine = eng
	_scale = px_scale
	var spr_size := Vector2(tex.get_width(), tex.get_height()) * px_scale
	size = Vector2(maxf(spr_size.x, 150.0), spr_size.y + 92)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sprite = UI.tex_rect(tex, px_scale)
	_mat = UI.dissolve_material(Vector2(tex.get_width(), tex.get_height()))
	_mat.set_shader_parameter("edge_a", Color("ffe08a"))
	sprite.material = _mat
	_sprite_base = Vector2((size.x - spr_size.x) * 0.5, 42)
	sprite.position = _sprite_base
	sprite.pivot_offset = Vector2(spr_size.x * 0.5, spr_size.y)
	add_child(sprite)
	_shown_hp = f.hp
	if f.is_player:
		arm = UI.tex_rect(Art.player_arm(), px_scale)
		arm.position = Vector2(12, 13) * px_scale
		arm.pivot_offset = Vector2(3.5, 1.5) * px_scale
		arm.rotation = ARM_REST
		sprite.add_child(arm)
	elif glow_tex != null:
		glow = UI.tex_rect(glow_tex, px_scale)
		glow.material = UI.add_material(1.0)
		sprite.add_child(glow)

	_intent_box = UI.hbox(4)
	_intent_box.position = Vector2(size.x * 0.5 - 40, 0)
	_intent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_icon = UI.icon("sword", 3)
	_intent_label = UI.label("", 22, Color("ffd36a"))
	_intent_box.add_child(_intent_icon)
	_intent_box.add_child(_intent_label)
	_intent_box.visible = not f.is_player
	add_child(_intent_box)

	var base_y := 42 + spr_size.y + 6
	_block_icon = UI.icon("shield", 2)
	_block_icon.position = Vector2(size.x * 0.5 - 75 - 22, base_y - 6)
	add_child(_block_icon)
	_block_label = UI.label("", 16, UI.BLUE)
	_block_label.position = _block_icon.position + Vector2(2, 2)
	_block_label.size = Vector2(24, 20)
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_block_label)

	_hp_label = UI.label("", 14)
	_hp_label.position = Vector2(size.x * 0.5 - 75, base_y - 1)
	_hp_label.size = Vector2(150, 16)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hp_label)

	_name_label = UI.label(f.display_name, 13, UI.EMBER if f.is_boss else (Color("ff9a7a") if f.is_elite else UI.DIM))
	_name_label.position = Vector2(0, base_y + 18)
	_name_label.size = Vector2(size.x, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)

	_stolen_label = UI.label("", 12, UI.EMBER)
	_stolen_label.position = Vector2(0, base_y + 52)
	_stolen_label.size = Vector2(size.x, 14)
	_stolen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_stolen_label)

	_status_row = UI.hbox(2)
	_status_row.position = Vector2(size.x * 0.5 - 75, base_y + 34)
	add_child(_status_row)

	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())
	_start_bob()
	refresh()


func _start_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	_bob_tween = create_tween().set_loops()
	var dur := 0.9 + randf() * 0.4
	# Respiración: squash & stretch sutil anclado en los pies.
	_bob_tween.tween_property(sprite, "scale", Vector2(1.03, 0.97), dur).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(sprite, "scale", Vector2(0.98, 1.02), dur).set_trans(Tween.TRANS_SINE)


func hp_bar_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 75, 42 + sprite.size.y + 4, 150, 18)


func _draw() -> void:
	if fighter == null:
		return
	# Sombra en el suelo.
	if not _dead:
		var foot := Vector2(sprite.position.x + sprite.size.x * 0.5, 42 + sprite.size.y - 2)
		var sw := sprite.size.x * 0.42
		for i in 3:
			draw_rect(Rect2(foot.x - sw + i * 8, foot.y - 4 + i * 2, (sw - i * 8) * 2, 6 - i * 2), Color(0, 0, 0, 0.18))
	var r := hp_bar_rect()
	draw_rect(r.grow(2), UI.OUTLINE)
	draw_rect(r, Color("2a1418"))
	var ratio := clampf(_shown_hp / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	var real := clampf(float(fighter.hp) / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), Color("ffe08a"))
	var col := Color("c2321e") if fighter.block <= 0 else Color("4a7aaa")
	draw_rect(Rect2(r.position, Vector2(r.size.x * real, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(r.size.x * real, 3)), col.lightened(0.3))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x * real, 3)), col.darkened(0.3))
	if fighter.st("scorch") > 0:
		var sw2 := r.size.x * minf(float(fighter.st("scorch")) / maxf(1.0, fighter.max_hp), real)
		draw_rect(Rect2(r.position + Vector2(r.size.x * real - sw2, 0), Vector2(sw2, r.size.y)), Color(1, 0.6, 0.1, 0.55))
	if targetable and _hover:
		var sr := Rect2(sprite.position - Vector2(10, 10), sprite.size + Vector2(20, 20))
		_corner_brackets(sr, Color("ffe08a"), 4.0)
	elif targetable:
		var a := 0.35 + 0.25 * sin(_t * 6.0)
		_corner_brackets(Rect2(sprite.position - Vector2(6, 6), sprite.size + Vector2(12, 12)), Color(1, 0.85, 0.5, a), 3.0)


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
	if absf(_shown_hp - fighter.hp) > 0.05:
		_shown_hp = move_toward(_shown_hp, fighter.hp, maxf(1.0, fighter.max_hp) * delta * 0.8)
		queue_redraw()
	if targetable:
		queue_redraw()
	if glow != null and not _dead:
		glow.modulate.a = 0.45 + 0.35 * sin(_t * 2.6 + fighter.max_hp)
	if _intent_box.visible:
		_intent_box.position.y = -4.0 + 3.0 * sin(_t * 3.0)


func refresh() -> void:
	if fighter == null:
		return
	_hp_label.text = "%d / %d" % [fighter.hp, fighter.max_hp]
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
		b.custom_minimum_size = Vector2(30, 30)
		b.tooltip_text = "%s %d\n%s" % [STATUS_NAMES[id], v, STATUS_DESC[id]]
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		var ic := UI.icon(STATUS_ICONS[id], 2)
		b.add_child(ic)
		var l := UI.label(str(v), 13, Color("ffd36a"))
		l.position = Vector2(14, 12)
		b.add_child(l)
		_status_row.add_child(b)
	if fighter.is_player:
		for pid: String in fighter.powers:
			var pb := Control.new()
			pb.custom_minimum_size = Vector2(30, 30)
			var txt: String = CardDB.POWERS.get(pid, "")
			pb.tooltip_text = "Poder\n" + txt.replace("%d", str(fighter.pw(pid)))
			pb.mouse_filter = Control.MOUSE_FILTER_PASS
			pb.add_child(UI.icon(CardDB.POWER_ICONS.get(pid, "star"), 2))
			var pl := UI.label(str(fighter.pw(pid)), 13, Color("ffd36a"))
			pl.position = Vector2(14, 12)
			pb.add_child(pl)
			_status_row.add_child(pb)
	_refresh_intent()
	queue_redraw()


func _refresh_intent() -> void:
	if fighter.is_player:
		return
	_intent_box.visible = fighter.alive() and not fighter.intent.is_empty()
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
	_intent_box.position.x = size.x * 0.5 - _intent_box.size.x * 0.5


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
	return global_position + sprite.position + sprite.size * 0.5


func flash(color: Color = Color.WHITE) -> void:
	_mat.set_shader_parameter("flash_color", color)
	_mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.18)


## Golpe recibido: retroceso en la dirección del impacto + aplastamiento.
func shake(strength: float = 8.0) -> void:
	var dir := -1.0 if fighter.is_player else 1.0
	var tw := create_tween()
	tw.tween_property(sprite, "position:x", _sprite_base.x + dir * minf(strength * 1.6, 26.0), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", dir * 0.06, 0.05)
	for i in 3:
		tw.tween_property(sprite, "position:x", _sprite_base.x + dir * strength * 0.5 + randf_range(-strength, strength) * 0.4, 0.03)
	tw.tween_property(sprite, "position:x", _sprite_base.x, 0.12).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.12)


## Embestida con anticipación (los enemigos se encogen antes de saltar).
func lunge(dir: float) -> void:
	var tw := create_tween()
	if not fighter.is_player:
		tw.tween_property(sprite, "position:x", _sprite_base.x - 14.0 * dir, 0.1).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(sprite, "rotation", -0.08 * dir, 0.1)
	tw.tween_property(sprite, "position:x", _sprite_base.x + 46.0 * dir, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", 0.1 * dir, 0.07)
	tw.tween_property(sprite, "position:x", _sprite_base.x, 0.2).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.2)


## Martillazo de la heroína: carga hacia atrás, golpe adelante y vuelta.
func swing() -> void:
	if arm == null:
		lunge(1.0)
		return
	var tw := create_tween()
	tw.tween_property(arm, "rotation", 2.7, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", -0.06, 0.09)
	tw.tween_property(arm, "rotation", -1.45, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "position:x", _sprite_base.x + 42.0, 0.07)
	tw.parallel().tween_property(sprite, "rotation", 0.08, 0.07)
	tw.tween_interval(0.05)
	tw.tween_property(arm, "rotation", ARM_REST, 0.26).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(sprite, "position:x", _sprite_base.x, 0.22).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.22)


## Gesto de habilidad/poder: alza el martillo.
func cast() -> void:
	if arm == null:
		return
	var tw := create_tween()
	tw.tween_property(arm, "rotation", -2.4, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "scale", Vector2(0.96, 1.06), 0.12)
	tw.tween_interval(0.12)
	tw.tween_property(arm, "rotation", ARM_REST, 0.25).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.2)


## Gesto de quemar: echa la carta al horno (hacia atrás).
func toss() -> void:
	if arm == null:
		return
	var tw := create_tween()
	tw.tween_property(arm, "rotation", -0.9, 0.08)
	tw.tween_property(arm, "rotation", 1.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(arm, "rotation", ARM_REST, 0.3).set_trans(Tween.TRANS_BACK)


func die() -> void:
	_dead = true
	_intent_box.visible = false
	_stolen_label.text = ""
	if _bob_tween:
		_bob_tween.kill()
	if glow != null:
		glow.visible = false
	flash(Color("ffe08a"))
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_property(sprite, "scale", Vector2(1.12, 0.9), 0.12)
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "position:y", _sprite_base.y + 10.0, 0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
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
