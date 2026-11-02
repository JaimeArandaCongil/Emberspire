class_name CardView
extends Control
## Vista de carta v0.4: marco 80×112 nativo con su ilustración 68×46 (`CardFrame` + `CardIllus`) mostrado a ×2
## (160×224). Nombre en Fragua ×2 (o Pavesa ×1 si no cabe), tipo en Mini ×2, cuerpo en Pavesa ×1 (tinta sobre
## pergamino, cifras en negrita). Auras animadas: jugable, quemable, en caliente (Mayús) y seleccionada.
## Brillo de rara (6 fotogramas cada 4 s). Emite `clicked(view, button)` y `hover_changed(view, hovering)`.
## `burn_away()` la disuelve en llamas.
##
## Métricas para la mano (combate): tamaño 160×224; el orbe sobresale 12 px arriba-izquierda; el aura 18 px por
## cada lado; en reposo asoman 128 px (64 nativos: placa + ilustración); al pasar el ratón sube entera.

signal clicked(view: CardView, button: int)
signal hover_changed(view: CardView, hovering: bool)

const _Frame := preload("res://scripts/art/cards/frame.gd")
const _Illus := preload("res://scripts/art/cards/illus/card_illus.gd")

const SIZE := Vector2(160, 224)
const PEEK := 128.0                      # px visibles en reposo (placa + ilustración)
const S := 2
const HINT_H := 38.0                     # alto de la placa "QUEMAR" que aparece sobre la carta
const NAME_X0 := 26.0                    # zona del nombre en px de pantalla: el orbe propio llega a x 23
const NAME_X1 := 118.0                   # y el del vecino en la mano empieza en x 122 (paso 132)
## Paso de la mano en px de arte (`combat_screen.HAND_MAX_STEP` / 2): el orbe de la carta vecina tapa la placa desde
## aquí. El nombre se coloca para no rozar ni el orbe propio ni ése, igual en mano, recompensa y tienda.
const ORB_STEP := 81
const NAME_GAP := 1                      # px de arte de placa libres entre el nombre y cualquier orbe
const NAME_ROW := 3                      # fila de arte del contorno superior de la celda del glifo con `_name.y` = 8 (mayúsculas en 6–12)
const NAME_Y := 8.0
const BODY := Rect2(18, 144, 124, 64)    # caja del texto sobre el pergamino (px de pantalla, relativos a la carta)

static var _tex_cache := {}

var card: Card
var engine: CombatEngine
var interactive := true
var selected := false:
	set(v):
		selected = v
		_update_glow()
var hovering := false
var home_pos := Vector2.ZERO
var home_rot := 0.0

var _aura: TextureRect
var _frame: TextureRect
var _orb: TextureRect
var _cost: Label
var _name: Label
var _type: Label
var _desc: RichTextLabel
var _burn_hint: Label
var _frame_mat: ShaderMaterial
var _frame_key := ""
var _shimmer: Array = []
var _aura_kind := ""
var _t := 0.0


func _init(p_card: Card = null, p_engine: CombatEngine = null) -> void:
	card = p_card
	engine = p_engine


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_aura = _texrect(Vector2(-(_Frame.M + 4) * S, -(_Frame.M + 4) * S))
	_aura.visible = false
	add_child(_aura)

	_frame = _texrect(Vector2(-_Frame.M * S, -_Frame.M * S))
	_frame_mat = UI.dissolve_material(Vector2(_Frame.CW + _Frame.M * 2, _Frame.CH + _Frame.M * 2))
	_frame.material = _frame_mat
	add_child(_frame)

	_name = Label.new()
	_name.position = Vector2(12, 10)
	_name.size = Vector2(SIZE.x - 24, 22)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.clip_text = true
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)

	_type = UI.mlabel(String(CardDB.TYPE_NAMES.get(card.type(), "")).to_upper())
	_type.position = Vector2(0, _Frame.RIBBON_Y * S)
	_type.size = Vector2(SIZE.x, 14)
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_type)

	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.fit_content = false
	_desc.scroll_active = false
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc.position = BODY.position
	_desc.size = BODY.size
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_desc.add_theme_font_override("normal_font", PixelFont.pavesa())
	_desc.add_theme_font_override("bold_font", PixelFont.pavesa_bold())
	_desc.add_theme_font_size_override("normal_font_size", PixelFont.P_LINE)
	_desc.add_theme_font_size_override("bold_font_size", PixelFont.P_LINE)
	_desc.add_theme_color_override("default_color", Palette.UI[&"ink"])
	_desc.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_desc.add_theme_constant_override("outline_size", 0)
	_desc.add_theme_constant_override("line_separation", -2)
	add_child(_desc)

	_orb = _texrect(Vector2(-6 * S, -6 * S))
	add_child(_orb)
	_cost = UI.plabel("", 2)
	_cost.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))   # Fragua ya lleva contorno
	_cost.position = Vector2(0, 0)
	_cost.size = Vector2(19 * S, 19 * S)
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_orb.add_child(_cost)

	_burn_hint = UI.label("CLIC DCHO: QUEMAR", 12, UI.EMBER)
	# Encima de la carta: al pasar el ratón la carta sube entera y debajo ya no queda pantalla.
	_burn_hint.position = Vector2(-30, -HINT_H - 16)
	_burn_hint.size = Vector2(SIZE.x + 60, HINT_H)
	_burn_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_burn_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_burn_hint.add_theme_stylebox_override("normal", UIKit.sb_plate(Palette.color(&"plate", 2), Palette.color(&"copper", 5), 1, 0, Vector4(4, 2, 4, 2)))
	_burn_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_burn_hint.visible = false
	add_child(_burn_hint)

	tooltip_text = _tooltip()
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	refresh()


func _texrect(pos: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.position = pos
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _set_tex(r: TextureRect, t: Texture2D) -> void:
	r.texture = t
	if t != null:
		r.size = Vector2(t.get_width(), t.get_height())


static func _tex(key: String, img: Image) -> ImageTexture:
	if _tex_cache.has(key):
		return _tex_cache[key]
	var big := img.duplicate() as Image
	big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(big)
	_tex_cache[key] = t
	return t


func _tooltip() -> String:
	var lvl := card.mastery()
	var prog := Game.mastery_progress(card.id)
	var t := "%s · %s" % [CardDB.RARITY_NAMES.get(card.rarity(), ""), CardDB.PACK_NAMES.get(card.def()["pack"], "")]
	if card.rarity() in ["status", "token"]:
		return t
	if lvl >= Game.MASTERY_MAX:
		t += "\nMaestría %d (máx.): +%d%% números, +%d%% Ascuas al quemar" % [lvl, lvl * 10, lvl * 20]
	else:
		t += "\nMaestría %d · %d/%d quemas para el nivel %d" % [lvl, prog.x, prog.y, lvl + 1]
		if lvl > 0:
			t += "\n(+%d%% números, +%d%% Ascuas al quemar)" % [lvl * 10, lvl * 20]
	var tb: String = Game.temples.get(card.id, "")
	if tb != "":
		t += "\n" + CardDB.temple_desc(card.id, tb)
	return t


## Disposición del nombre de carta: {"big": Fragua ×2 (si no, Pavesa ×1), "x": px de pantalla del origen del texto,
## siempre par (rejilla ×2)}. Fragua se comprueba píxel a píxel (glifo + contorno + `NAME_GAP` en cruz) contra el rombo del
## orbe propio y el del vecino de la mano; se elige la posición válida más cercana al centro de la carta.
static func title_layout(title: String) -> Dictionary:
	var ink := {}
	var pen := 0
	for i in title.length():
		var ch := title[i]
		if ch == " ":
			pen += 3
			continue
		var g := PixelFont.glyph(ch)
		var rows: Array = g["rows"]
		for r in rows.size():
			var row: String = rows[r]
			for gx in row.length():
				if row[gx] == "#":
					# Glifo + contorno horneado (3×3).
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							ink[Vector2i(pen + gx + dx, NAME_ROW + 1 + r + dy)] = true
		pen += int(g["w"]) + 1
	# Hueco de placa: `NAME_GAP` px libres en horizontal y vertical (un roce en diagonal de esquina no cuenta).
	for _k in NAME_GAP:
		var grown := ink.duplicate()
		for p0: Vector2i in ink:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				grown[p0 + d] = true
		ink = grown
	var tw := PixelFont.text_width(title)
	var center := int(round((_Frame.CW - tw) / 2.0))
	var best := -1
	for s in range(7, _Frame.CW - 6 - tw):
		var ok := true
		for p: Vector2i in ink:
			if _in_orb(p.x + s, p.y) or _in_orb(p.x + s - ORB_STEP, p.y):
				ok = false
				break
		if ok and (best < 0 or absi(s - center) < absi(best - center)):
			best = s
	if best >= 0:
		return {"big": true, "x": best * S, "text": title}
	var pw := PixelFont.pavesa_width(title)
	var px := clampf(round((SIZE.x - pw) * 0.5), NAME_X0, maxf(NAME_X0, NAME_X1 - pw))
	return {"big": false, "x": int(px / 2.0) * 2, "text": title}


## Rombo del orbe de coste en px de arte de la carta (centro (3, 3), como `CardFrame.cost_gem` en (-6, -6)).
static func _in_orb(x: int, y: int) -> bool:
	var ax := absi(x - 3)
	var ay := absi(y - 3)
	return ax + ay <= 12 and ax <= 8 and ay <= 8


## Estado visual del marco (lo que cambia la textura).
func frame_state() -> Dictionary:
	return {"type": card.type(), "rarity": card.rarity(), "up": card.is_up(), "mastery": card.mastery(),
		"temple": Game.temples.get(card.id, "")}


func refresh() -> void:
	if _desc == null:
		return
	var st := frame_state()
	var key := "%s:%s:%s:%s:%d:%s" % [card.id, st["type"], st["rarity"], st["up"], st["mastery"], st["temple"]]
	if key != _frame_key:
		_frame_key = key
		var img: Image = _Frame.build(st, _Illus.image(card.id, card.type(), card.def().get("icon", "")))
		_set_tex(_frame, _tex("f:" + key, img))
		_shimmer.clear()
		if card.rarity() == "rare":
			var frames: Array[Image] = _Frame.shimmer_frames(img)
			for i in frames.size():
				_shimmer.append(_tex("f:%s:sh%d" % [key, i], frames[i]))
	# Si el nombre cabe en Fragua pero el «+» no, la mejora la dicen la placa de oro y la tinta de ascua: así una
	# carta no cambia de letra al mejorarse.
	var lay := title_layout(card.title())
	if not lay["big"] and card.is_up() and title_layout(String(card.def()["name"]))["big"]:
		lay = title_layout(String(card.def()["name"]))
	var title: String = lay["text"]
	_name.text = title
	# Mismo nombre, misma letra y sitio en todo el juego (C17): Fragua ×2 en la rejilla ×2 si cabe sin rozar ningún
	# orbe; si no, Pavesa ×1 (los largos). Fragua lleva el contorno horneado: sin sombra (la de 1 px de pantalla
	# quedaba a medio píxel de arte y fuera de paleta).
	if lay["big"]:
		var tw := PixelFont.text_width(title) * 2
		UI.pixelize(_name, 2)
		_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		_name.position = Vector2(float(lay["x"]), NAME_Y)
		_name.size = Vector2(tw + 4, 26)
	else:
		var pw := PixelFont.pavesa_width(title)
		_name.add_theme_font_override("font", PixelFont.pavesa())
		_name.add_theme_font_size_override("font_size", PixelFont.P_LINE)
		_name.add_theme_constant_override("outline_size", 0)
		_name.add_theme_color_override("font_shadow_color", Palette.UI[&"k"])
		_name.add_theme_constant_override("shadow_offset_x", 1)
		_name.add_theme_constant_override("shadow_offset_y", 1)
		_name.position = Vector2(float(lay["x"]), 12)
		_name.size = Vector2(pw + 4, 18)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.add_theme_color_override("font_color", Palette.color(&"ember_ui", 5) if card.is_up() else UI.TEXT)
	_desc.text = ink(CardDB.describe(card, engine))
	var playable := card.is_playable()
	_orb.visible = playable or card.type() == "status"
	_cost.text = "X" if card.is_x_cost() else str(card.cost())
	# Cifra centrada a mano en el rombo (centro en x 19 del orbe), en columna par: el centrado de Label la dejaba a
	# medio píxel de arte cuando el ancho del glifo es par.
	var cw := PixelFont.text_width(_cost.text) * S
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cost.position.x = floorf((19.0 - cw * 0.5) / S) * S
	var affordable := true
	if engine != null and playable:
		affordable = engine.can_play(card)
	var gem_state := "status" if card.type() == "status" else ("no" if not affordable else ("up" if card.is_up() else "ok"))
	_set_tex(_orb, _tex("gem:" + gem_state, _Frame.cost_gem(gem_state)))
	_cost.add_theme_color_override("font_color", UI.TEXT if affordable else Palette.color(&"ash", 7))
	_update_glow()


## Los colores de resalte de `CardDB.describe` están pensados para fondo oscuro: sobre pergamino pasan a tinta
## de la paleta, y las cifras van en negrita (Pavesa doble trazo).
static func ink(t: String) -> String:
	var num := Palette.UI[&"num"].to_html(false)
	var up := Palette.UI[&"upgraded"].to_html(false)
	var down := Palette.color(&"blood", 2).to_html(false)
	var key := Palette.UI[&"keyword"].to_html(false)
	var cold := Palette.color(&"wool_blue", 2).to_html(false)
	var mag := Palette.color(&"magic", 1).to_html(false)
	var base := Palette.UI[&"ink"].to_html(false)
	var rx := RegEx.new()
	rx.compile("\\[color=(#[0-9a-fA-F]{6})\\]([^\\[]*)\\[/color\\]")
	var out := ""
	var last := 0
	for m in rx.search_all(t):
		out += t.substr(last, m.get_start() - last)
		var c := m.get_string(1).to_lower()
		var body := m.get_string(2)
		var col := base
		var bold := false
		match c:
			"#ffd36a", "#ffb43a":
				col = num
				bold = true
			"#7dff7d", "#7ad47a":
				col = up
				bold = true
			"#ff7d7d", "#ff6a4a":
				col = down
				bold = true
			"#ff9a4a", "#ff8a4a":
				col = key
			"#8ab4d0":
				col = cold
			"#ffb0ff", "#ff8ad8", "#b07ae0":
				col = mag
		var seg := "[color=#%s]%s[/color]" % [col, body]
		out += ("[b]%s[/b]" % seg) if bold else seg
		last = m.get_end()
	out += t.substr(last)
	return out


func _process(delta: float) -> void:
	_t += delta
	if _aura_kind == "burn" or _aura_kind == "hot":
		var f := int(_t * 8.0) % 4
		_set_tex(_aura, _tex("aura:%s:%d:%s" % [_aura_kind, f, _orb.visible], _Frame.aura(_aura_kind, f, _orb.visible)))
	if not _shimmer.is_empty():
		var cyc := fmod(_t, 4.0)
		var i := int(cyc * 12.0)
		var tex: Texture2D = _shimmer[i] if i < _shimmer.size() else _tex_cache.get("f:" + _frame_key)
		if _frame.texture != tex:
			_frame.texture = tex
	if hovering and engine != null and interactive:
		var want_hot := Input.is_key_pressed(KEY_SHIFT) and engine.can_burn_hot(card)
		if want_hot != (_aura_kind == "hot"):
			_update_glow()


func _update_glow() -> void:
	if _aura == null:
		return
	var kind := ""
	if selected:
		kind = "select"
	elif engine != null and interactive and engine.hand.has(card):
		if hovering and Input.is_key_pressed(KEY_SHIFT) and engine.can_burn_hot(card):
			kind = "hot"
		elif engine.can_play(card):
			kind = "play"
		elif engine.can_burn(card):
			kind = "burn"
	_aura_kind = kind
	_aura.visible = kind != ""
	if kind != "":
		_set_tex(_aura, _tex("aura:%s:0:%s" % [kind, _orb.visible], _Frame.aura(kind, 0, _orb.visible)))


## Se quema: el texto se apaga y marco e ilustración se deshacen en brasas.
func burn_away(duration: float = 0.55) -> Tween:
	interactive = false
	_burn_hint.visible = false
	_aura.visible = false
	_shimmer.clear()
	var tw := create_tween().set_parallel()
	for n: CanvasItem in [_name, _type, _desc, _orb]:
		tw.tween_property(n, "modulate:a", 0.0, duration * 0.3)
	tw.tween_method(func(v: float) -> void:
		_frame_mat.set_shader_parameter("progress", v), 0.0, 1.0, duration).set_ease(Tween.EASE_IN)
	return tw


func _on_enter() -> void:
	hovering = true
	if engine != null and interactive:
		_burn_hint.visible = engine.can_burn(card)
		if _burn_hint.visible:
			var pv: Dictionary = engine.burn_preview(card, false)
			var prog := Game.mastery_progress(card.id)
			var t := "QUEMAR +%s · Maestría %d/%d" % [Num.fmt(float(pv["embers"])), prog.x, prog.y]
			if engine.can_burn_hot(card):
				var hc := engine.hot_burn_cost(card)
				t += "\nMAYÚS: EN CALIENTE ×2 (%s)" % ("gratis" if hc == 0 else "−%d Energía" % hc)
			_burn_hint.text = t
	_update_glow()
	hover_changed.emit(self, true)


func _on_exit() -> void:
	hovering = false
	_burn_hint.visible = false
	_update_glow()
	hover_changed.emit(self, false)


func _gui_input(ev: InputEvent) -> void:
	if not interactive:
		return
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			clicked.emit(self, mb.button_index)
			accept_event()
