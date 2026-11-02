class_name UI
extends RefCounted
## Kit de UI: tema, constructores de widgets y efectos reutilizables.
## Rejillas: el MUNDO se dibuja a ×4 (PX) y la INTERFAZ a ×2 (UI_PX). Nada de escalas fraccionarias
## ni rotaciones sobre pixel art del mundo (ver docs/ART_BIBLE.md).
## v0.4: paneles y botones son 9-slice teselados (`UIKit`); etiquetas y avisos en Mini 3×5 ×2, Pavesa 6×9 ×1 sólo en tooltips y cuerpo,
## títulos en Fragua 5×7 a escala entera. Colores de la paleta maestra (`Palette`).

## Precargas (no dependen de la caché de class_name: el juego arranca aunque no se haya reimportado).
const _Kit := preload("res://scripts/art/ui_kit.gd")

const PX := 4
const UI_PX := 2

## Colores de interfaz: todos salen de la paleta maestra de DA (`Palette`).
static var BG: Color = Palette.color(&"plate", 1)
static var PANEL: Color = Palette.color(&"plate", 2)
static var PANEL2: Color = Palette.color(&"plate", 3)
static var OUTLINE: Color = Palette.UI[&"k"]
static var EDGE: Color = Palette.color(&"stone", 5)
static var TEXT: Color = Palette.UI[&"text"]
static var DIM: Color = Palette.UI[&"text_dim"]
static var EMBER: Color = Palette.color(&"ember_ui", 4)
static var FIRE: Color = Palette.color(&"ember_ui", 3)
static var RED: Color = Palette.color(&"blood", 3)
static var BLUE: Color = Palette.color(&"moon", 3)
static var GREEN: Color = Palette.color(&"heal", 3)
static var PURPLE: Color = Palette.color(&"magic", 3)

static var TYPE_COLORS := {"attack": Palette.color(&"frame_attack", 3), "skill": Palette.color(&"frame_skill", 4),
	"power": Palette.color(&"frame_power", 4), "fuel": Palette.color(&"frame_fuel", 4), "status": Palette.color(&"frame_status", 3)}

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


## Panel en la rejilla de interfaz: placa 9-slice teselada teñida con `bg` (cara) y `border` (canto).
## v0.4: ya no hay StyleBoxFlat; el grosor `bw` (px de pantalla) se lleva a píxeles nativos ×2.
static func box(bg: Color, border: Color = EDGE, bw: int = 4, shadow: int = 4) -> StyleBox:
	var thick := clampi(int(round(bw / 2.0)), 0, 3)
	if border.a == 0.0 or bw <= 0:
		thick = 0
	var sh := clampi(int(round(shadow / 2.0)), 0, 3)
	return _Kit.sb_plate(bg, border, maxi(thick, 1) if thick > 0 else 0, sh)


static func build_theme() -> Theme:
	var t := Theme.new()
	# Tipografía (DECISIONES «Etiquetas del HUD»): Mini 3×5 ×2 por defecto (etiquetas, avisos, pestañas, botones largos);
	# Pavesa 6×9 ×1 sólo en tooltips y cuerpo de texto (`rich()`); Fragua 5×7 en títulos y cifras vía plabel()/pixelize().
	t.default_font = PixelFont.mini()
	t.default_font_size = PixelFont.mini_size(2)
	for cls: String in ["Label", "Button", "RichTextLabel", "TooltipLabel", "TabContainer", "CheckBox", "LineEdit"]:
		t.set_color("font_shadow_color", cls, OUTLINE)
		# Sombra en la rejilla ×2; sólo el texto Pavesa ×1 (tooltip, cuerpo) la lleva de 1 px.
		var sh := 1 if cls in ["RichTextLabel", "TooltipLabel"] else UI_PX
		t.set_constant("shadow_offset_x", cls, sh)
		t.set_constant("shadow_offset_y", cls, sh)
		t.set_constant("outline_size", cls, 0)
		t.set_constant("shadow_outline_size", cls, 0)
	t.set_font("font", "TooltipLabel", PixelFont.pavesa())
	t.set_font_size("font_size", "TooltipLabel", PixelFont.P_LINE)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_outline_color", "RichTextLabel", OUTLINE)
	t.set_font("bold_font", "RichTextLabel", PixelFont.pavesa_bold())
	t.set_font("normal_font", "RichTextLabel", PixelFont.pavesa())
	t.set_font_size("normal_font_size", "RichTextLabel", PixelFont.P_LINE)
	t.set_font_size("bold_font_size", "RichTextLabel", PixelFont.P_LINE)
	# Botones: botón de forja 9-slice en cuatro estados.
	t.set_stylebox("normal", "Button", _Kit.sb_button("normal"))
	t.set_stylebox("hover", "Button", _Kit.sb_button("hover"))
	t.set_stylebox("pressed", "Button", _Kit.sb_button("pressed"))
	t.set_stylebox("hover_pressed", "Button", _Kit.sb_button("pressed"))
	t.set_stylebox("disabled", "Button", _Kit.sb_button("disabled"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Palette.color(&"ember_ui", 5))
	t.set_color("font_pressed_color", "Button", Palette.color(&"ember_ui", 6))
	t.set_color("font_hover_pressed_color", "Button", Palette.color(&"ember_ui", 6))
	t.set_color("font_disabled_color", "Button", Palette.color(&"ash", 5))
	t.set_color("font_outline_color", "Button", OUTLINE)
	# Paneles: chapa de hierro; tooltip de hierro oscuro.
	t.set_stylebox("panel", "PanelContainer", _Kit.sb_iron(3))
	t.set_stylebox("panel", "Panel", _Kit.sb_iron(3))
	t.set_stylebox("panel", "TooltipPanel", _Kit.sb_iron(2, Vector4(10, 6, 10, 6)))
	t.set_color("font_color", "TooltipLabel", TEXT)
	# Pestañas.
	t.set_stylebox("tab_selected", "TabContainer", _Kit.sb_tab(true))
	t.set_stylebox("tab_unselected", "TabContainer", _Kit.sb_tab(false))
	t.set_stylebox("tab_hovered", "TabContainer", _Kit.sb_tab(false, true))
	t.set_stylebox("tab_disabled", "TabContainer", _Kit.sb_tab(false))
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "TabContainer", _Kit.sb_iron(3))
	t.set_color("font_selected_color", "TabContainer", Palette.color(&"ember_ui", 5))
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	# Barras de desplazamiento y deslizadores: placas finas.
	t.set_stylebox("scroll", "VScrollBar", _Kit.sb_plate(Palette.color(&"plate", 2), Palette.OUTLINE, 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("grabber", "VScrollBar", _Kit.sb_plate(Palette.color(&"plate", 5), Palette.color(&"plate", 6), 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("grabber_highlight", "VScrollBar", _Kit.sb_plate(Palette.color(&"copper", 5), Palette.color(&"copper", 7), 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("grabber_pressed", "VScrollBar", _Kit.sb_plate(Palette.color(&"ember_ui", 4), Palette.color(&"ember_ui", 5), 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("slider", "HSlider", _Kit.sb_plate(Palette.color(&"plate", 2), EDGE, 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("background", "ProgressBar", _Kit.sb_plate(Palette.color(&"plate", 1), Palette.color(&"stone", 4), 1, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("fill", "ProgressBar", _Kit.sb_plate(Palette.color(&"ember_ui", 2), Palette.color(&"ember_ui", 3), 1, 0, Vector4(2, 2, 2, 2)))
	return t


## Etiqueta. Desde 20 px usa Fragua a escala entera (títulos, cifras); por debajo, Mini 3×5 a ×2 (DECISIONES: Pavesa ×1
## queda sólo para cuerpo de carta y tooltips). `size` ya no cambia el cuerpo de letra por debajo de 20.
static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	if size >= 20:
		return plabel(text, pixel_scale(size), color)
	var l := mlabel(text, color)
	l.add_theme_constant_override("line_spacing", 2)
	return l


## Etiqueta pequeña en Mini 3×5 a ×2 (cintas de tipo, intenciones, contadores).
static func mlabel(text: String, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", PixelFont.mini())
	l.add_theme_font_size_override("font_size", PixelFont.mini_size(2))
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


## Centra el texto de `l` en [x0, x0 + width] con el desplazamiento en la rejilla ×2. El centrado de Label/Button cae en
## píxel impar cuando (ancho − texto) / 2 es impar: medio píxel de arte (F2-BASE). Llamar tras cambiar el texto.
static func snap_center(l: Label, x0: float, width: float) -> void:
	var tw := text_width(l)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.position.x = x0 + roundf((width - tw) / (2.0 * UI_PX)) * UI_PX
	l.size.x = tw


## Ancho en píxeles de pantalla del texto de una etiqueta (con su fuente y tamaño actuales).
static func text_width(c: Control) -> float:
	var f := c.get_theme_font("font")
	var fs := c.get_theme_font_size("font_size")
	var t: String = c.get("text")
	return ceilf(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) if f != null else 0.0


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
	l.material = fragua_material()
	return l


## Fragua lleva el contorno horneado en el glifo (`UI.k`); sin esto, `font_color` lo tiñe y sale de la paleta
## (`1a0a04` en las Ascuas, `190d0e` en el texto claro, `020101` en su sombra). El material deja el contorno intacto.
static var _fragua_mat: ShaderMaterial

static func fragua_material() -> ShaderMaterial:
	if _fragua_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
varying vec4 v_col;
void vertex() { v_col = COLOR; }
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 k = vec3(26.0, 15.0, 18.0) / 255.0;
	if (t.a > 0.5 && distance(t.rgb, k) < 0.012) {
		COLOR = vec4(k, t.a * v_col.a);
	} else {
		COLOR = t * v_col;
	}
}
"""
		_fragua_mat = ShaderMaterial.new()
		_fragua_mat.shader = sh
	return _fragua_mat


## Aplica la fuente pixel a un control con texto (Button, Label…).
static func pixelize(c: Control, scale: int = 2) -> void:
	c.add_theme_font_override("font", PixelFont.font())
	c.add_theme_font_size_override("font_size", PixelFont.px_size(scale))
	c.add_theme_constant_override("outline_size", 0)
	if c.material == null:
		c.material = fragua_material()


static func rich(text: String, size: int = 15) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pavesa a ×1 (o ×2 si se pide un tamaño de título); los tamaños intermedios caen a ×1 (escala entera).
	var fs := PixelFont.P_LINE * (2 if size >= 26 else 1)
	r.add_theme_font_override("normal_font", PixelFont.pavesa())
	r.add_theme_font_override("bold_font", PixelFont.pavesa_bold())
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_font_size_override("bold_font_size", fs)
	r.add_theme_constant_override("outline_size", 0)
	r.add_theme_constant_override("line_separation", 1)
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


## Texto flotante (daño, ascuas...) con la fuente pixel, siempre a `FLOAT_SCALE` (×2, rejilla 640×360; F2-PULIDO-A, N8:
## antes ×3 desde `size` 30 y "pop" de escala ×s+1, fuera de rejilla). `_size` ya no cambia la escala: la cola entera va igual.
## El "pop" es de color: los primeros 60 ms, un paso más claro de su rampa (si la tiene); luego sube y se apaga.
## F2-VIDA4 (cola sobre la cabeza): con `bottom` = true, `pos` es el centro del borde INFERIOR (el texto queda encima
## de ese punto). La meta `lift` (px, la tween `FloatQueue`) sube el texto además de `rise` y la meta `ceil` (y local) es
## el techo que no cruza; la subida es lineal para que un texto nuevo no alcance al anterior. Devuelve la etiqueta.
static func float_text(parent: Node, pos: Vector2, text: String, color: Color, _size: int = 30, rise: float = 70.0,
		bottom := false) -> Label:
	color = float_color(color)
	var l := plabel(text, FLOAT_SCALE, float_pop_color(color))
	l.z_index = 100
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	l.reset_size()
	var jitter := 0.0 if bottom else randf_range(-12, 12)
	var cy := func() -> float: return pos.y - (l.size.y if bottom else l.size.y * 0.5)
	l.position = (Vector2(pos.x - l.size.x * 0.5 + jitter, cy.call()) / 2.0).round() * 2.0   # rejilla ×2
	var tw := l.create_tween()
	tw.tween_interval(0.06)
	tw.tween_callback(func() -> void:
		l.add_theme_color_override("font_color", color))
	tw.tween_method(func(v: float) -> void:
		var y: float = cy.call() - rise * v - float(l.get_meta(&"lift", 0.0))
		y = maxf(y, float(l.get_meta(&"ceil", -INF)))
		l.position.y = roundf(y / 2.0) * 2.0, 0.0, 1.0, 0.8).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_LINEAR if bottom else Tween.TRANS_CUBIC)   # en cola, todos a la misma velocidad: no se alcanzan
	# Se apaga por pasos de su rampa (§12: nunca alfa): −1, −2, −3 cada 90 ms desde los 450 ms y desaparece.
	var fade := l.create_tween()
	fade.tween_interval(0.45)
	for d in FADE_STEPS:
		var c := step_color(color, -d)
		fade.tween_callback(func() -> void: l.add_theme_color_override("font_color", c))
		fade.tween_interval(0.09)
	tw.tween_callback(l.queue_free)
	return l


## Escala única de los textos flotantes (N8): ×2 como el resto de la interfaz.
const FLOAT_SCALE := 2


## Color legible de un flotante: sube por su rampa hasta ≥ 4,5:1 sobre el contorno horneado de la fuente (`ink` 1);
## a ×2 el trazo es fino y `blood` 3 (3,9:1) o `magic` 3 (4,2:1) no llegaban. Los fijos de `Palette.UI` no cambian.
static func float_color(c: Color) -> Color:
	if Palette.find(c) == null:
		return c
	var ink := Palette.color(&"ink", 1)
	var out := c
	for d in 3:
		if contrast(out, ink) >= 4.5:
			break
		out = step_color(c, d + 1)
	return out


## Contraste WCAG entre dos colores (1–21).
static func contrast(a: Color, b: Color) -> float:
	var lum := func(c: Color) -> float:
		var ch := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
		return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)
	var la: float = lum.call(a)
	var lb: float = lum.call(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Color del "pop" de un flotante: un paso más claro de su rampa; los fijos de `Palette.UI` (sin rampa) no cambian.
static func float_pop_color(c: Color) -> Color:
	return step_color(c, 1) if Palette.find(c) != null else c


## Pasos con que se apagan los textos flotantes (desde su color de rampa).
const FADE_STEPS: Array[int] = [1, 2, 3]


## Mueve `d` pasos dentro de la rampa del color. Los colores fijos de `Palette.UI` (texto, tenue…) no están en ninguna
## rampa: se toma la rampa cálida de color más parecido. El resultado siempre es de paleta.
static var _ramp_of: Dictionary = {}

static func step_color(c: Color, d: int) -> Color:
	var k := Palette.key8(c)
	var f: Variant = _ramp_of.get(k)
	if f == null:
		f = Palette.find(c)
		if f == null:
			var bd := INF
			for m: StringName in Palette.ORDER:
				var r := Palette.ramp(m)
				if r.size() < 4:
					continue
				for s in r.size():
					var e := Vector3(c.r - r[s].r, c.g - r[s].g, c.b - r[s].b).length_squared()
					if e < bd:
						bd = e
						f = [m, s, false]
		_ramp_of[k] = f
	var a: Array = f
	return Palette.color(a[0], int(a[1]) + d, a[2])


## Atenuado por pasos de paleta (§12, «la sala baja 2 pasos, no alfa») para INTERFAZ ya dibujada: un rectángulo encima
## lee la pantalla y cambia cada color de paleta por el mismo color `d` pasos más abajo de su rampa. LUT de 64³ celdas
## (6 bits por canal) con `DIM_LAYERS` capas; cada capa guarda origen y destino, así dos colores de paleta que comparten celda no se
## confunden. Lo que no es de paleta se deja igual. Uso: `var c := UI.dim_cover(control, -2)`; `c.queue_free()` para quitarlo.
const DIM_SHADER := """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D dim_lut : filter_nearest, repeat_disable;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	ivec3 k = ivec3(floor(c * 255.0 + 0.5));
	ivec3 q = k / 4;
	ivec2 cell = ivec2(q.r + 64 * (q.b % 8), q.g + 64 * (q.b / 8));
	vec3 o = c;
	for (int layer = 0; layer < 4; layer++) {
		ivec2 base = cell + ivec2(0, 512 * layer);
		vec4 src = texelFetch(dim_lut, base + ivec2(512, 0), 0);
		if (src.a > 0.5 && ivec3(floor(src.rgb * 255.0 + 0.5)) == k) {
			o = texelFetch(dim_lut, base, 0).rgb;
			break;
		}
	}
	COLOR = vec4(o, 1.0);
}
"""
static var _dim_shader: Shader
static var _dim_luts: Dictionary = {}
const DIM_LAYERS := 4   # = bucle del shader
## Colores de paleta sin sitio en la LUT (más de `DIM_LAYERS` en la misma celda): se quedan sin atenuar. Lo mide `test_ui`.
static var dim_lut_collisions := 0

## `keep`: colores que no cambian (p. ej. la cara del panel de debajo, para que no se vea la caja del atenuado).
## Disposición 1024 × 512·capas: x < 512 destino, x ≥ 512 origen; capa n en y 512·n.
static func dim_lut(d: int, keep: Array = []) -> ImageTexture:
	var lk := "%d|%s" % [d, keep]
	if _dim_luts.has(lk):
		return _dim_luts[lk]
	var kept := {}
	for kc: Color in keep:
		kept[Palette.key8(kc)] = true
	var img := Image.create_empty(1024, 512 * DIM_LAYERS, false, Image.FORMAT_RGBA8)
	var used := {}
	dim_lut_collisions = 0
	for k: int in Palette.all_colors():
		var c := Color8((k >> 16) & 255, (k >> 8) & 255, k & 255)
		var cell := Vector2i((c.r8 >> 2) + 64 * ((c.b8 >> 2) % 8), (c.g8 >> 2) + 64 * ((c.b8 >> 2) / 8))
		var layer: int = used.get(cell, 0)
		if layer >= DIM_LAYERS:
			dim_lut_collisions += 1
			continue
		used[cell] = layer + 1
		var at := cell + Vector2i(0, 512 * layer)
		img.set_pixelv(at, c if kept.has(k) else step_color(c, d))
		img.set_pixelv(at + Vector2i(512, 0), c)
	var t := ImageTexture.create_from_image(img)
	_dim_luts[lk] = t
	return t


static func dim_cover(target: Control, d: int = -2, keep: Array = []) -> ColorRect:
	if _dim_shader == null:
		_dim_shader = Shader.new()
		_dim_shader.code = DIM_SHADER
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.top_level = true
	# `top_level` deja de heredar la z: se pone la z absoluta del destino + 1.
	var z := 0
	var n: Node = target
	while n is CanvasItem:
		z += (n as CanvasItem).z_index
		if not (n as CanvasItem).z_as_relative:
			break
		n = n.get_parent()
	r.z_as_relative = false
	r.z_index = z + 1
	var m := ShaderMaterial.new()
	m.shader = _dim_shader
	m.set_shader_parameter("dim_lut", dim_lut(d, keep))
	r.material = m
	target.add_child(r)
	var follow := func() -> void:
		r.global_position = target.global_position
		r.size = target.size
	follow.call()
	target.get_tree().process_frame.connect(follow)
	r.tree_exiting.connect(func() -> void:
		if target.get_tree().process_frame.is_connected(follow):
			target.get_tree().process_frame.disconnect(follow))
	return r


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
	grad.colors = PackedColorArray([Palette.color(&"ember_ui", 6), Palette.color(&"ember_ui", 5), color, Color(Palette.color(&"ember_ui", 2), 0.6)])
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
	grad.colors = PackedColorArray([Palette.color(&"ember_ui", 6), Palette.color(&"ember_ui", 4), Palette.color(&"ember_ui", 3), Color(Palette.color(&"ember_ui", 2), 0.7)])
	p.color_ramp = grad
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
