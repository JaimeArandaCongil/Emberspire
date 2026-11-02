extends RefCounted
## Pruebas de cartas e interfaz (UI). Convención: `run() -> Array` devuelve los FALLOS; vacío = todo pasa.
## Fuentes, tema sin StyleBoxFlat, kit 9-slice, marco en todos sus estados, ilustraciones (paleta, unicidad,
## miniatura 34×23), encaje del texto de TODAS las cartas y comportamiento de CardView.

const _Frame := preload("res://scripts/art/cards/frame.gd")
const _Illus := preload("res://scripts/art/cards/illus/card_illus.gd")
const _Kit := preload("res://scripts/art/ui_kit.gd")

const TYPES := ["attack", "skill", "power", "fuel", "status"]
const RARITIES := ["starter", "common", "uncommon", "rare", "status", "token"]
const BODY_W := 124
const BODY_LINES := 5
## Nombres que ni en Mini ×2 caben entre el orbe y el canto de la placa (F2-ILUS3); la cifra sólo puede bajar.
const TITLES_PAVESA_MAX := 18
## Diferencia media mínima (0–1) entre dos miniaturas en grises para considerarlas composiciones distintas.
const MIN_THUMB_DIFF := 0.03

var fails: Array = []


func run() -> Array:
	fails = []
	_fonts()
	_theme()
	_kit()
	_frames()
	_illustrations()
	_text_fit()
	_card_view()
	_dim_steps()
	return fails


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _closed(img: Image, name: String) -> void:
	var off := {}
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a > 0.0 and not Palette.is_palette_color(p):
				off[p.to_html(false)] = true
	_check(off.is_empty(), "%s: colores fuera de paleta %s" % [name, str(off.keys().slice(0, 5))])


# ------------------------------------------------------------------------------------------- fuentes

func _body_rows(g: Dictionary) -> int:
	var n := 0
	for r: String in g["rows"]:
		if r.contains("#"):
			n += 1
	return n


func _fonts() -> void:
	var fallback_p: Dictionary = PixelFont.pavesa_glyph("?")
	var fallback_m: Dictionary = PixelFont.mini_glyph("?")
	for ch: String in "abcdefghijklmnñopqrstuvwxyzABCDEFGHIJKLMNÑOPQRSTUVWXYZáéíóúÁÉÍÓÚü0123456789.,:;¡!¿()+-×%/":
		_check(PixelFont.pavesa_glyph(ch) != fallback_p, "Pavesa sin glifo propio: %s" % ch)
		_check(PixelFont.mini_glyph(ch) != fallback_m, "Mini sin glifo propio: %s" % ch)
	_check(_body_rows(PixelFont.pavesa_glyph("H")) == 9, "Pavesa: la mayúscula debe medir 9 filas")
	_check(_body_rows(PixelFont.mini_glyph("H")) == 5, "Mini: la mayúscula debe medir 5 filas")
	# Un acento debe cambiar el glifo y quedar encima del cuerpo.
	for pair: Array in [["a", "á"], ["e", "é"], ["i", "í"], ["o", "ó"], ["u", "ú"], ["n", "ñ"]]:
		_check(PixelFont.pavesa_glyph(pair[0]) != PixelFont.pavesa_glyph(pair[1]), "Pavesa: %s = %s" % pair)
		_check(PixelFont.mini_glyph(pair[0]) != PixelFont.mini_glyph(pair[1]), "Mini: %s = %s" % pair)
	var fp := PixelFont.pavesa()
	_check(fp.get_height(PixelFont.P_LINE) == PixelFont.P_LINE, "Pavesa: alto de línea a ×1")
	_check(fp.get_height(13) == PixelFont.P_LINE, "Pavesa: un tamaño menor no debe escalar fraccionariamente")
	var fm := PixelFont.mini()
	_check(fm.get_height(PixelFont.mini_size(2)) == PixelFont.M_LINE * 2, "Mini: alto de línea a ×2")
	# DECISIONES «Etiquetas del HUD»: Mini ×2 por debajo de 20; Pavesa ×1 sólo en cuerpo de carta y tooltips.
	var l := UI.label("Inflige", 14)
	_check(l.get_theme_font("font") == fm and l.get_theme_font_size("font_size") == PixelFont.mini_size(2), "UI.label(<20) debe usar Mini ×2")
	_check(l.get_theme_constant("shadow_offset_x") == 2 and l.get_theme_constant("shadow_offset_y") == 2, "UI.label(<20): sombra en la rejilla ×2")
	l.free()
	var lb := UI.label("Chispa", 18)
	_check(lb.get_theme_font("font") == fm, "UI.label(16–19) debe usar Mini ×2")
	lb.free()
	var l2 := UI.label("Título", 30)
	_check(l2.get_theme_font("font") == PixelFont.font(), "UI.label(>=20) debe usar Fragua")
	_check(l2.material == UI.fragua_material(), "Fragua lleva el material que no tiñe su contorno")
	l2.free()
	var r := UI.rich("x")
	_check(r.get_theme_font("normal_font") == fp, "UI.rich debe usar Pavesa")
	r.free()


# ------------------------------------------------------------------------------------------- tema

func _theme() -> void:
	var t := UI.build_theme()
	_check(t.default_font == PixelFont.mini() and t.default_font_size == PixelFont.mini_size(2), "tema: fuente por defecto Mini ×2")
	_check(t.get_font("font", "TooltipLabel") == PixelFont.pavesa(), "tema: tooltips en Pavesa ×1")
	_check(t.get_constant("shadow_offset_x", "Label") == 2, "tema: sombra de etiqueta en la rejilla ×2")
	var n := 0
	for type_name: String in t.get_stylebox_type_list():
		for sb_name: String in t.get_stylebox_list(type_name):
			var sb := t.get_stylebox(sb_name, type_name)
			n += 1
			_check(not (sb is StyleBoxFlat), "tema: StyleBoxFlat en %s/%s" % [type_name, sb_name])
			if sb is StyleBoxTexture:
				var st := sb as StyleBoxTexture
				_check(st.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE
					and st.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_TILE, "tema: %s/%s no tesela" % [type_name, sb_name])
	_check(n >= 15, "tema: faltan estilos (%d)" % n)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		_check(t.has_stylebox(state, "Button"), "tema: Button sin estado %s" % state)
	_check(UI.box(UI.PANEL, UI.EDGE) is StyleBoxTexture, "UI.box debe devolver un 9-slice")
	# Los colores de UI están en paleta.
	for c: Color in [UI.BG, UI.PANEL, UI.PANEL2, UI.OUTLINE, UI.EDGE, UI.TEXT, UI.DIM, UI.EMBER, UI.FIRE, UI.RED, UI.BLUE, UI.GREEN, UI.PURPLE]:
		_check(Palette.is_palette_color(c), "UI: constante fuera de paleta %s" % c.to_html(false))


func _kit() -> void:
	_closed(_Kit.stone(), "stone")
	for b in range(2, 6):
		_closed(_Kit.iron(b), "iron %d" % b)
	_closed(_Kit.parchment(), "parchment")
	for s: String in ["normal", "hover", "pressed", "disabled"]:
		_closed(_Kit.button(s), "button " + s)
	_closed(_Kit.tab(true), "tab activa")
	_closed(_Kit.tab(false), "tab inactiva")
	_closed(_Kit.tab(false, true), "tab hover")
	_closed(_Kit.bar(40, 0.5, [Palette.color(&"blood", 1), Palette.color(&"blood", 3), Palette.color(&"blood", 4)]), "bar")
	_closed(_Kit.plate(Color("8a3a1a"), Color("ffb43a"), 2, 2), "plate ajustada")
	_closed(_Kit.ember_icon(), "ember_icon")
	# Teselado: el 9-slice conserva las esquinas (el margen debe ser menor que la mitad de la pieza).
	_check(_Kit.stone().get_width() > 8 * 2, "stone: el margen no deja centro")
	_check(_Kit.iron().get_width() > 5 * 2, "iron: el margen no deja centro")


# ------------------------------------------------------------------------------------------- marco

func _frames() -> void:
	var art := _Illus.image("strike", "attack")
	for type: String in TYPES:
		for rarity: String in RARITIES:
			var img := _Frame.build({"type": type, "rarity": rarity}, art)
			_check(img.get_width() == _Frame.CW + _Frame.M * 2 and img.get_height() == _Frame.CH + _Frame.M * 2, "marco: tamaño")
			_closed(img, "marco %s/%s" % [type, rarity])
	_check(_Frame.CW == 80 and _Frame.CH == 112, "marco: 80×112")
	_check(_Frame.ART.size == Vector2i(68, 46), "ventana: 68×46")
	var base := _Frame.build({"type": "attack", "rarity": "common"}, art)
	var variants := {
		"mejorada": {"up": true}, "maestría 1": {"mastery": 1}, "maestría 3": {"mastery": 3}, "maestría 5": {"mastery": 5},
		"filo": {"temple": "edge"}, "brasa": {"temple": "ember"}, "fragua": {"temple": "forge"}, "rescoldo": {"temple": "rekindle"},
	}
	var seen: Array = [base.get_data()]
	for vn: String in variants:
		var st := {"type": "attack", "rarity": "common"}
		st.merge(variants[vn])
		var v := _Frame.build(st, art)
		_closed(v, "marco " + vn)
		_check(not seen.has(v.get_data()), "marco: el estado %s no se distingue" % vn)
		seen.append(v.get_data())
	# Las siluetas de ventana son distintas entre tipos.
	var masks := {}
	for type2: String in TYPES:
		var bits := PackedByteArray()
		for y in _Frame.ART.size.y:
			for x in _Frame.ART.size.x:
				bits.append(1 if _Frame.window_mask(type2, x, y) else 0)
		_check(not masks.has(bits), "ventana: silueta repetida en %s" % type2)
		masks[bits] = true
	for k: String in ["play", "burn", "hot", "select"]:
		for orb: bool in [true, false]:
			_closed(_Frame.aura(k, 0, orb), "aura " + k)
	_check(_Frame.aura("burn", 0).get_data() != _Frame.aura("burn", 1).get_data(), "aura burn: sin animación")
	_check(_Frame.aura("burn", 0).get_data() != _Frame.aura("hot", 0).get_data(), "aura: quemable = en caliente")
	for g: String in ["ok", "no", "up", "status"]:
		_closed(_Frame.cost_gem(g), "orbe " + g)
	var sh := _Frame.shimmer_frames(_Frame.build({"type": "power", "rarity": "rare"}, art))
	_check(sh.size() == 6, "brillo: 6 fotogramas")
	for f in sh:
		_closed(f, "brillo de rara")
	_check(sh[0].get_data() != sh[3].get_data(), "brillo: no se mueve")


# ------------------------------------------------------------------------------------------- ilustraciones

func _thumb(img: Image) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for y in range(0, img.get_height() - 1, 2):
		for x in range(0, img.get_width() - 1, 2):
			var s := 0.0
			for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				s += img.get_pixel(x + d.x, y + d.y).get_luminance()
			out.append(s / 4.0)
	return out


func _illustrations() -> void:
	var ids := _Illus.ids()
	_check(ids.size() >= 12, "ilustraciones: faltan (%d)" % ids.size())
	for must: String in ["strike", "defend", "kindling", "ember_slash"]:
		_check(ids.has(must), "ilustraciones: falta el mazo inicial %s" % must)
	var thumbs := {}
	for id: String in ids:
		_check(CardDB.CARDS.has(id), "ilustración de carta inexistente: %s" % id)
		var img := _Illus.image(id, CardDB.get_def(id)["type"])
		_check(img.get_width() == 68 and img.get_height() == 46, "%s: tamaño" % id)
		_closed(img, "ilustración " + id)
		var holes := 0
		var colors := {}
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a < 1.0:
					holes += 1
				colors[Palette.key8(p)] = true
		_check(holes == 0, "%s: %d píxeles transparentes" % [id, holes])
		_check(colors.size() >= 12, "%s: sólo %d colores (¿plana?)" % [id, colors.size()])
		# Regla de color (DECISIONES): ≤ 30 colores visibles en la ventana; ninguno con < 10 px salvo 3 chispas u ojos.
		var type: String = CardDB.get_def(id)["type"]
		var vis := IllusPx.color_counts(img, func(x: int, y: int) -> bool: return _Frame.window_mask(type, x, y))
		var tiny := 0
		for k: int in vis:
			if int(vis[k]) < 10:
				tiny += 1
		_check(vis.size() <= 30, "%s: %d colores en la ventana (máx. 30)" % [id, vis.size()])
		_check(tiny <= 3, "%s: %d colores con menos de 10 px (máx. 3)" % [id, tiny])
		thumbs[id] = _thumb(img)
	# Prueba de miniatura 34×23: dos composiciones no pueden confundirse.
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: PackedFloat32Array = thumbs[ids[i]]
			var b: PackedFloat32Array = thumbs[ids[j]]
			var diff := 0.0
			for k in a.size():
				diff += absf(a[k] - b[k])
			diff /= a.size()
			_check(diff >= MIN_THUMB_DIFF, "miniaturas casi iguales: %s / %s (%.3f)" % [ids[i], ids[j], diff])


# ------------------------------------------------------------------------------------------- texto

func _lines(text: String) -> int:
	var total := 0
	for para: String in text.split("\n"):
		var cur := 0
		var n := 1
		for wd: String in para.split(" ", false):
			var w := PixelFont.pavesa_width(wd, true)
			if cur > 0 and cur + 4 + w > BODY_W:
				n += 1
				cur = w
			else:
				cur += (4 if cur > 0 else 0) + w
		total += n
	return total


func _text_fit() -> void:
	for id: String in CardDB.CARDS:
		for up: bool in [false, true]:
			var c := Card.new(id, up)
			var n := _lines(CardDB.describe_plain(c))
			_check(n <= BODY_LINES, "texto de %s%s: %d líneas (máx. %d)" % [id, "+" if up else "", n, BODY_LINES])
	# N4 / DECISIONES «Títulos de carta»: Fragua ×2 si cabe sin rozar orbes; si no, Mini ×2. Se comprueban los nombres
	# con y sin «+»: rejilla ×2, sin orbe (lo mide `title_layout` píxel a píxel) y dentro de la placa. Pavesa ×1 queda
	# sólo para los que ni en Mini ×2 caben (F2-ILUS3: pendiente de dirección) y no puede crecer.
	var tiers := {"fragua": [], "mini": [], "pavesa": []}
	for id2: String in CardDB.CARDS:
		var base: String = CardDB.get_def(id2)["name"]
		for t: String in [base, base + "+"]:
			var lay := CardView.title_layout(t)
			_check(int(lay["x"]) % 2 == 0, "nombre fuera de la rejilla ×2: %s (x %d)" % [t, int(lay["x"])])
			var w := PixelFont.pavesa_width(t) + 1
			if lay["font"] == "fragua":
				w = PixelFont.text_width(t) * CardView.S
			elif lay["font"] == "mini":
				w = (PixelFont.mini_width(t) + 1) * CardView.S
			_check(int(lay["x"]) >= CardView.PLATE_X0 * CardView.S and int(lay["x"]) + w <= (CardView.PLATE_X1 + 1) * CardView.S,
				"nombre fuera de la placa: %s" % t)
			_check(bool(lay["fits"]) == (lay["font"] != "pavesa"), "title_layout: «fits» incoherente en %s" % t)
			if t == base:
				(tiers[lay["font"]] as Array).append(t)
	if OS.get_environment("TITULOS") != "":
		print("    · títulos: %d Fragua ×2, %d Mini ×2, %d Pavesa ×1 %s" % [tiers["fragua"].size(), tiers["mini"].size(),
			tiers["pavesa"].size(), str(tiers["pavesa"])])
	_check((tiers["pavesa"] as Array).size() <= TITLES_PAVESA_MAX, "títulos en Pavesa ×1: %d (máx. %d)" % [tiers["pavesa"].size(), TITLES_PAVESA_MAX])
	_check(CardView.title_layout("Tajo Ígneo")["big"], "Tajo Ígneo debe caber en Fragua ×2 sin rozar orbes")
	_check(not CardView.title_layout("Fuego Interior")["big"], "Fuego Interior pasa a Mini ×2")
	var hand_step: float = (load("res://scripts/ui/screens/combat_screen.gd") as Script).get_script_constant_map().get("HAND_MAX_STEP", 0.0)
	_check(int(hand_step) == CardView.ORB_STEP * CardView.S, "CardView.ORB_STEP no sigue al paso de la mano (%d)" % int(hand_step))


# ------------------------------------------------------------------------------------------- CardView

func _card_view() -> void:
	_check(CardView.SIZE == Vector2(160, 224), "CardView: 160×224")
	_check(CardView.PEEK == 128.0, "CardView: asoma 64 px nativos en reposo")
	# La raíz está ocupada mientras la escena de pruebas ejecuta _ready: se cuelga de esa escena.
	var tree := Engine.get_main_loop() as SceneTree
	var host: Node = tree.root.get_child(tree.root.get_child_count() - 1)
	for id: String in ["strike", "coal", "corona", "wet_ash"]:
		var cv := CardView.new(Card.new(id))
		host.add_child(cv)
		_check(cv.has_signal("clicked") and cv.has_signal("hover_changed"), "CardView: señales")
		_check(cv.size == CardView.SIZE, "CardView %s: tamaño" % id)
		var tw: Tween = cv.burn_away(0.01)
		_check(tw != null, "CardView: burn_away debe devolver un Tween")
		tw.kill()
		for n: CanvasItem in [cv._frame, cv._name, cv._type, cv._desc, cv._orb, cv._cost]:
			var bm := n.material as ShaderMaterial
			_check(bm != null and bm.shader == CardView._burn_shader, "CardView %s: la quema cubre %s (sin alfa)" % [id, n.name])
		cv._burn_step(1.0, [])
		_check(not cv.visible, "CardView %s: al acabar la quema no queda nada" % id)
		cv.free()
	var src := FileAccess.get_file_as_string("res://scripts/ui/card_view.gd")
	_check(not src.contains("modulate:a") and not src.contains("modulate.a"), "CardView: la quema no funde con alfa")
	var cv2 := CardView.new(Card.new("strike"))
	host.add_child(cv2)
	cv2.selected = true
	_check(cv2._aura.visible, "CardView: la selección muestra el aura")
	cv2.selected = false
	_check(not cv2._aura.visible, "CardView: sin motor no hay aura")
	_check(cv2._desc.text.contains("[b]"), "CardView: las cifras van en negrita")
	# N2 y N3 (F2-ILUS3): placa QUEMAR y cinta de tipo en la rejilla ×2 (origen en x e y pares).
	for t: String in ["QUEMAR +1 · Maestría 0/3", "QUEMAR +16.1K · Maestría 2/6\nMAYÚS: EN CALIENTE ×2 (−1 Energía)"]:
		cv2.set_burn_hint(t)
		for hl: Label in cv2._hint_lines:
			if hl.visible:
				_check(int(hl.position.x) % 2 == 0 and int(hl.position.y) % 2 == 0, "placa QUEMAR fuera de la rejilla ×2: %s" % hl.text)
	_check(int(cv2._type.position.x) % 2 == 0 and int(cv2._type.position.y) % 2 == 0
		and cv2._type.vertical_alignment == VERTICAL_ALIGNMENT_TOP, "cinta de tipo fuera de la rejilla ×2")
	cv2.free()
	var inked := CardView.ink("Inflige [color=#ffd36a]6[/color] y [color=#ff9a4a]Agotar.[/color]")
	_check(inked.contains("[b][color=#%s]6" % Palette.UI[&"num"].to_html(false)), "ink: cifra")
	_check(inked.contains("[color=#%s]Agotar" % Palette.UI[&"keyword"].to_html(false)), "ink: palabra clave")


# ------------------------------------------------------------------------- atenuar por pasos (§12, F2-VIDA2)

## Textos flotantes y recompensas bloqueadas se apagan por pasos de rampa, nunca con alfa.
func _dim_steps() -> void:
	for c: Color in [UI.TEXT, UI.DIM, UI.EMBER, UI.RED, UI.BLUE, UI.GREEN, Palette.color(&"gold", 5)]:
		for d in [1, 2, 3]:
			var o := UI.step_color(c, -d)
			_check(Palette.is_palette_color(o), "step_color(%s, -%d) fuera de paleta" % [c.to_html(false), d])
		_check(UI.step_color(c, -3).get_luminance() < c.get_luminance(), "step_color(%s, -3) no oscurece" % c.to_html(false))
	var lut := UI.dim_lut(-2).get_image()
	_check(lut.get_width() == 1024 and lut.get_height() == 512 * UI.DIM_LAYERS, "dim_lut: 1024 × 512·capas (64³ celdas)")
	var bad := 0
	var filled := 0
	for y in lut.get_height():
		for x in 512:
			var src := lut.get_pixel(x + 512, y)
			if src.a > 0.5:
				filled += 1
				var dst := lut.get_pixel(x, y)
				if not Palette.is_palette_color(dst) or not Palette.is_palette_color(src):
					bad += 1
	_check(bad == 0, "dim_lut: %d entradas fuera de paleta" % bad)
	_check(filled + UI.dim_lut_collisions == Palette.all_colors().size(), "dim_lut: faltan colores (%d)" % filled)
	_check(UI.dim_lut_collisions == 0, "dim_lut: %d colores de paleta sin sitio (más capas que DIM_LAYERS)" % UI.dim_lut_collisions)
	var src := FileAccess.get_file_as_string("res://scripts/ui/ui.gd")
	var ft := src.substr(src.find("static func float_text"), 1400)
	_check(not ft.contains("modulate:a"), "UI.float_text no debe fundirse con alfa")
	var cs := FileAccess.get_file_as_string("res://scripts/ui/screens/combat_screen.gd")
	_check(not cs.contains("cards_box.modulate"), "recompensas: las cartas bloqueadas no se atenúan con alfa")
	# F2-VIDA3: las cartas que vuelan al descarte (o a la heroína) bajan por pasos y desaparecen, sin alfa.
	_check(not cs.contains("\"modulate:a\""), "combate: ninguna carta se funde con alfa (§12)")
	# F2-VIDA3 (C2): el jefe destella sólo en la pieza golpeada.
	var sh := FileAccess.get_file_as_string("res://shaders/palette_lit.gdshader")
	_check(sh.contains("uniform vec3 flash_piece"), "palette_lit: falta `flash_piece` (destello por pieza del jefe)")
	# F2-VIDA4 (#2): fuera de la pieza, sólo `flash_rest_steps` durante el blanco; el jefe sube ≤ 2 f a 60 fps.
	_check(sh.contains("uniform int flash_rest_steps"), "palette_lit: falta `flash_rest_steps` (no lavar el cuerpo del jefe)")
	var boss_s := 0.0
	for st: Array in FighterView.FLASH_BOSS_STEPS:
		boss_s += float(st[1])
	_check(boss_s <= 2.0 / 60.0 + 0.001, "destello del jefe: subida de pasos de %.3f s (máx. 2 f a 60 fps)" % boss_s)
	# F2-VIDA4 (#3): Quemadura fuerte con lenguas de 5–6 px.
	var sfx: StatusFX = StatusFX.new()
	for v: int in [StatusFX.SCORCH_HOT, 9]:
		sfx._statuses = {"scorch": v}
		_check(sfx.flame_height() >= 5 and sfx.flame_height() <= 6, "Quemadura %d: lenguas de %d px (5–6)" % [v, sfx.flame_height()])
	sfx.free()
	# F2-VIDA4 (#4, N1 y N5): flotantes del combate en la cola sobre la cabeza; dorso fantasma en paleta.
	_check(not cs.contains("UI.float_text(_fx_layer, _local(v.center())"), "combate: flotante sobre el cuerpo (usa `_float_over`)")
	_check(not cs.contains("Art.card_back_small()"), "combate: dorso fantasma legado fuera de paleta (N5)")
