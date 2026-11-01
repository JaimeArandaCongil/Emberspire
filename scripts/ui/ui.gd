class_name UI
extends RefCounted
## Kit de UI: tema, constructores de widgets y efectos reutilizables.
## Rejillas: el MUNDO se dibuja a ×4 (PX) y la INTERFAZ a ×2 (UI_PX). Nada de escalas fraccionarias
## ni rotaciones sobre pixel art del mundo (ver docs/ART_BIBLE.md).

const PX := 4
const UI_PX := 2

const BG := Color("140c10")
const PANEL := Color("231619")
const PANEL2 := Color("2e1d21")
const OUTLINE := Color("1a0f12")
const EDGE := Color("5a4040")
const TEXT := Color("f4e4c8")
const DIM := Color("a08878")
const EMBER := Color("ffb43a")
const FIRE := Color("ff6a1a")
const RED := Color("e0442a")
const BLUE := Color("8ab4d0")
const GREEN := Color("7ad47a")
const PURPLE := Color("b07ae0")

const TYPE_COLORS := {"attack": Color("c2321e"), "skill": Color("4a6a8a"), "power": Color("d08a20"),
	"fuel": Color("6a5048"), "status": Color("3a3038")}

const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a * COLOR.a);
}
"""

## Disolución pixelada con borde incandescente: cartas quemadas y enemigos muertos.
## `cells` = resolución de la rejilla de ruido (en píxeles de arte, no de pantalla).
const DISSOLVE_SHADER := """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec2 cells = vec2(75.0, 105.0);
uniform vec4 edge_a : source_color = vec4(1.0, 0.88, 0.45, 1.0);
uniform vec4 edge_b : source_color = vec4(1.0, 0.35, 0.08, 1.0);
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = h(i); float b = h(i + vec2(1.0, 0.0)); float c = h(i + vec2(0.0, 1.0)); float d = h(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	vec2 cell = floor(UV * cells);
	float v = n(cell / 6.0) * 0.7 + h(cell) * 0.3;
	// La llama sube desde abajo.
	v = v * 0.75 + (1.0 - UV.y) * 0.25;
	float p = progress * 1.15;
	if (v < p - 0.0) { discard; }
	if (v < p + 0.06) { c.rgb = mix(edge_b.rgb, edge_a.rgb, step(p + 0.03, v)); }
	COLOR = vec4(c.rgb, c.a * COLOR.a);
}
"""

## Mezcla aditiva para capas de brillo (ojos y venas de los monstruos, halos).
const ADD_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float strength = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(c.rgb * strength * COLOR.a, c.a);
}
"""

static var _flash_shader: Shader
static var _dissolve_shader: Shader
static var _add_shader: Shader


static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	return m


static func dissolve_material(cells: Vector2) -> ShaderMaterial:
	if _dissolve_shader == null:
		_dissolve_shader = Shader.new()
		_dissolve_shader.code = DISSOLVE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _dissolve_shader
	m.set_shader_parameter("cells", cells)
	return m


static func add_material(strength: float = 1.0) -> ShaderMaterial:
	if _add_shader == null:
		_add_shader = Shader.new()
		_add_shader.code = ADD_SHADER
	var m := ShaderMaterial.new()
	m.shader = _add_shader
	m.set_shader_parameter("strength", strength)
	return m


## Halo suave (textura radial) para luces de antorchas, horno, etc.
static var _halo: Texture2D


static func halo_texture() -> Texture2D:
	if _halo == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_halo = t
	return _halo


static func halo(color: Color, radius: float, strength: float = 0.6) -> TextureRect:
	var r := TextureRect.new()
	r.texture = halo_texture()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = Vector2(radius, radius) * 2.0
	r.pivot_offset = r.size * 0.5
	r.modulate = Color(color, strength)
	r.material = add_material(1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Motas de polvo/ceniza flotando en el aire de una sala.
static func dust(rect: Rect2, color: Color, amount: int = 30) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = rect.get_center()
	p.amount = amount
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect.size * 0.5
	p.direction = Vector2(0.3, -1)
	p.spread = 60.0
	p.gravity = Vector2(0, -4)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = float(PX)
	p.scale_amount_max = float(PX)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	grad.colors = PackedColorArray([Color(color, 0.0), Color(color, 0.7), Color(color, 0.5), Color(color, 0.0)])
	p.color_ramp = grad
	return p


## Panel en la rejilla de interfaz (bordes y sombra en múltiplos de 2 px).
static func box(bg: Color, border: Color = EDGE, bw: int = 4, shadow: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	bw = maxi(2, bw + bw % 2) if bw > 1 else bw
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)
	s.anti_aliasing = false
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.55)
		s.shadow_size = 0
		s.shadow_offset = Vector2(shadow, shadow)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_constant("outline_size", "Label", 4)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_outline_color", "RichTextLabel", OUTLINE)
	t.set_constant("outline_size", "RichTextLabel", 3)
	t.set_stylebox("normal", "Button", box(Color("4a2a22"), Color("8a4a2a")))
	t.set_stylebox("hover", "Button", box(Color("6a3424"), EMBER))
	t.set_stylebox("pressed", "Button", box(Color("8a3a1a"), Color("ffe08a"), 3, 1))
	t.set_stylebox("disabled", "Button", box(Color("2a2024"), Color("3d2b2e")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color("ffe08a"))
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("6a5a58"))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 4)
	t.set_stylebox("panel", "PanelContainer", box(PANEL))
	t.set_stylebox("panel", "Panel", box(PANEL))
	t.set_stylebox("panel", "TooltipPanel", box(Color("1e1216"), EMBER, 2, 3))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("tab_selected", "TabContainer", box(Color("4a2a22"), EMBER, 3, 0))
	t.set_stylebox("tab_unselected", "TabContainer", box(Color("2a1a1e"), EDGE, 3, 0))
	t.set_stylebox("tab_hovered", "TabContainer", box(Color("3a2226"), Color("8a4a2a"), 3, 0))
	t.set_stylebox("panel", "TabContainer", box(PANEL, EDGE, 3, 4))
	t.set_color("font_selected_color", "TabContainer", Color("ffe08a"))
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_stylebox("scroll", "VScrollBar", box(Color("1a1014"), OUTLINE, 1, 0))
	t.set_stylebox("grabber", "VScrollBar", box(EDGE, OUTLINE, 1, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color("8a4a2a"), OUTLINE, 1, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(EMBER, OUTLINE, 1, 0))
	t.set_stylebox("slider", "HSlider", box(Color("1a1014"), EDGE, 2, 0))
	return t


## Etiqueta. Desde 20 px usa la fuente pixel a escala entera (títulos, cifras); por debajo, la lisa.
static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	if size >= 20:
		return plabel(text, pixel_scale(size), color)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", maxi(3, size / 5))
	return l


## Escala entera de la fuente pixel equivalente a un tamaño de fuente liso.
static func pixel_scale(size: int) -> int:
	return clampi(int(round(size / 11.0)), 1, 8)


## Etiqueta con la fuente pixel a escala entera `scale` (contorno horneado en el glifo).
static func plabel(text: String, scale: int = 2, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.px_size(scale))
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("line_spacing", 0)
	return l


## Aplica la fuente pixel a un control con texto (Button, Label…).
static func pixelize(c: Control, scale: int = 2) -> void:
	c.add_theme_font_override("font", PixelFont.font())
	c.add_theme_font_size_override("font_size", PixelFont.px_size(scale))
	c.add_theme_constant_override("outline_size", 0)


static func rich(text: String, size: int = 15) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.text = text
	return r


static func button(text: String, cb: Callable, size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	# Botones cortos con la fuente pixel (los largos conservan la lisa para no desbordar).
	if text.length() <= 26 and size >= 16:
		pixelize(b, 2 if size < 30 else 3)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			Sfx.play("hover", 0.1, -6.0))
	return b


static func icon(id: String, scale: int = 3) -> TextureRect:
	var r := TextureRect.new()
	var tex := Art.icon(id)
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(tex.get_width(), tex.get_height()) * scale
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func tex_rect(tex: Texture2D, scale: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = Vector2(tex.get_width(), tex.get_height()) * scale
	r.custom_minimum_size = r.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func panel(bg: Color = PANEL, border: Color = EDGE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(h: int = 0, w: int = 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


## Texto flotante (daño, ascuas...).
## Texto flotante (daño, ascuas...) con la fuente pixel: aparece con "pop" de escala entera
## (×s−1 → ×s+1 → ×s en 120 ms), sube y se apaga. Alto máximo ≈ 40 px.
static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size: int = 30, rise: float = 70.0) -> void:
	var s := clampi(pixel_scale(size), 2, 3)
	var l := plabel(text, s + 1, color)
	l.z_index = 100
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	l.reset_size()
	var p0 := (pos - l.size * 0.5 + Vector2(randf_range(-12, 12), 0)).round()
	l.position = p0
	var tw := l.create_tween()
	tw.tween_interval(0.06)
	tw.tween_callback(func() -> void:
		l.add_theme_font_size_override("font_size", PixelFont.px_size(s))
		l.reset_size()
		l.position = (pos - l.size * 0.5).round())
	var y0 := pos.y
	tw.tween_method(func(v: float) -> void: l.position.y = roundf((y0 - l.size.y * 0.5 - rise * v) / 2.0) * 2.0, 0.0, 1.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tw.tween_callback(l.queue_free)


## Pulso de escala para elementos de INTERFAZ (nunca para sprites del mundo: usar FighterView).
static func punch(c: CanvasItem, amount: float = 0.15) -> void:
	if not (c is Control or c is Node2D) or c is FighterView:
		return
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * (1.0 + amount), 0.06)
	tw.tween_property(c, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)


## Partículas de chispas en un punto (CPUParticles2D, se autodestruyen).
static func sparks(parent: Node, pos: Vector2, color: Color = FIRE, amount: int = 24, spread: float = 180.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.7
	p.spread = spread
	p.direction = Vector2.UP
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = float(PX)
	p.scale_amount_max = float(PX * 2)
	# Rampa escalonada de la paleta de fuego (sin degradado continuo).
	var grad := Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.55, 0.85])
	grad.colors = PackedColorArray([Color("fff4c8"), Color("ffe08a"), color, Color(color.darkened(0.4), 0.6)])
	p.color_ramp = grad
	p.z_index = 90
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Fuego continuo para hornos y braseros.
static func fire_emitter(size: Vector2, amount: int = 40) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = size * 0.5
	p.direction = Vector2.UP
	p.spread = 12.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = float(PX)
	p.scale_amount_max = float(PX * 2)
	var grad := Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.45, 0.75])
	grad.colors = PackedColorArray([Color("fff4c8"), Color("ffb43a"), Color("ff6a1a"), Color(0.76, 0.2, 0.12, 0.7)])
	p.color_ramp = grad
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
