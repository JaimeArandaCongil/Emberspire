class_name FighterView
extends Control
## Sprite + barra de vida + bloqueo + estados + intención de un combatiente.

signal clicked(view: FighterView)

const STATUS_ICONS := {"str": "str", "weak": "down", "vuln": "vuln", "scorch": "flame"}
const STATUS_NAMES := {"str": "Fuerza", "weak": "Débil", "vuln": "Vulnerable", "scorch": "Quemadura"}
const STATUS_DESC := {
	"str": "Aumenta el daño de los ataques.",
	"weak": "Inflige un 25% menos de daño.",
	"vuln": "Recibe un 50% más de daño.",
	"scorch": "Pierde PV al inicio del turno; luego baja 1.",
}

var fighter: Fighter
var engine: CombatEngine
var sprite: TextureRect
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
var _mat: ShaderMaterial
var _shown_hp := 0.0
var _sprite_base := Vector2.ZERO
var _bob_tween: Tween
var _scale := 6.0


func setup(f: Fighter, eng: CombatEngine, tex: Texture2D, px_scale: float) -> void:
	fighter = f
	engine = eng
	_scale = px_scale
	var spr_size := Vector2(tex.get_width(), tex.get_height()) * px_scale
	size = Vector2(maxf(spr_size.x, 150.0), spr_size.y + 90)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sprite = UI.tex_rect(tex, px_scale)
	_mat = UI.flash_material()
	sprite.material = _mat
	_sprite_base = Vector2((size.x - spr_size.x) * 0.5, 40)
	sprite.position = _sprite_base
	sprite.pivot_offset = Vector2(spr_size.x * 0.5, spr_size.y)
	add_child(sprite)
	if not f.is_player:
		sprite.flip_h = false
	_shown_hp = f.hp

	_intent_box = UI.hbox(4)
	_intent_box.position = Vector2(size.x * 0.5 - 40, 0)
	_intent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_icon = UI.icon("sword", 3)
	_intent_label = UI.label("", 22, Color("ffd36a"))
	_intent_box.add_child(_intent_icon)
	_intent_box.add_child(_intent_label)
	_intent_box.visible = not f.is_player
	add_child(_intent_box)

	var base_y := 40 + spr_size.y + 6
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

	_name_label = UI.label(f.display_name, 13, UI.DIM)
	_name_label.position = Vector2(0, base_y + 18)
	_name_label.size = Vector2(size.x, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)

	_status_row = UI.hbox(2)
	_status_row.position = Vector2(size.x * 0.5 - 75, base_y + 36)
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
	return Rect2(size.x * 0.5 - 75, 40 + sprite.size.y + 4, 150, 18)


func _draw() -> void:
	if fighter == null:
		return
	var r := hp_bar_rect()
	draw_rect(r.grow(2), UI.OUTLINE)
	draw_rect(r, Color("2a1418"))
	var ratio := clampf(_shown_hp / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	var real := clampf(float(fighter.hp) / maxf(1.0, fighter.max_hp), 0.0, 1.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), Color("ffe08a"))
	var col := Color("c2321e") if fighter.block <= 0 else Color("4a7aaa")
	draw_rect(Rect2(r.position, Vector2(r.size.x * real, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(r.size.x * real, 3)), col.lightened(0.3))
	if fighter.st("scorch") > 0:
		var sw := r.size.x * minf(float(fighter.st("scorch")) / maxf(1.0, fighter.max_hp), real)
		draw_rect(Rect2(r.position + Vector2(r.size.x * real - sw, 0), Vector2(sw, r.size.y)), Color(1, 0.6, 0.1, 0.55))
	if targetable and _hover:
		var sr := Rect2(sprite.position - Vector2(10, 10), sprite.size + Vector2(20, 20))
		draw_rect(sr, Color("ffe08a"), false, 3.0)
	elif targetable:
		var sr2 := Rect2(sprite.position - Vector2(6, 6), sprite.size + Vector2(12, 12))
		draw_rect(sr2, Color(1, 0.85, 0.5, 0.35), false, 2.0)


func _process(delta: float) -> void:
	if fighter == null:
		return
	if absf(_shown_hp - fighter.hp) > 0.05:
		_shown_hp = move_toward(_shown_hp, fighter.hp, maxf(1.0, fighter.max_hp) * delta * 0.8)
		queue_redraw()


func refresh() -> void:
	if fighter == null:
		return
	_hp_label.text = "%d / %d" % [fighter.hp, fighter.max_hp]
	_block_icon.visible = fighter.block > 0
	_block_label.visible = fighter.block > 0
	_block_label.text = str(fighter.block)
	UI.clear(_status_row)
	for id: String in ["str", "weak", "vuln", "scorch"]:
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
			pb.add_child(UI.icon("star", 2))
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
		"attack_debuff", "attack_defend", "attack": ic = "sword"
	_intent_icon.texture = Art.icon(ic)
	var dmg := engine.intent_damage(fighter)
	if dmg.x >= 0:
		_intent_label.text = str(dmg.x) if dmg.y <= 1 else "%d×%d" % [dmg.x, dmg.y]
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
			"heal": parts.append("Se curará")
			"scorch_p": parts.append("Te quemará")
			"weak_p": parts.append("Te debilitará")
			"vuln_p": parts.append("Te hará vulnerable")
			"add_card": parts.append("Ensuciará tu mazo")
	return "Intención: " + ", ".join(parts)


func center() -> Vector2:
	return global_position + sprite.position + sprite.size * 0.5


func flash(color: Color = Color.WHITE) -> void:
	_mat.set_shader_parameter("flash_color", color)
	_mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.18)


func shake(strength: float = 8.0) -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(sprite, "position:x", _sprite_base.x + randf_range(-strength, strength), 0.03)
	tw.tween_property(sprite, "position:x", _sprite_base.x, 0.04)


func lunge(dir: float) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "position:x", _sprite_base.x + 40.0 * dir, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "position:x", _sprite_base.x, 0.16).set_trans(Tween.TRANS_QUAD)


func die() -> void:
	_intent_box.visible = false
	if _bob_tween:
		_bob_tween.kill()
	flash(Color("ffe08a"))
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(sprite, "scale", Vector2(1.3, 0.1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()
