class_name TopHud
extends Control
## Barra superior (franja de arte y 0–15 = 30 px): Ascuas (rodante, con brasa que late), producción, Braseros,
## Calor de Pacto (sólo en la Torre), Polvo Estelar y música. Lee `Game`; `refresh()` para actualizar los fijos.
## Señal `audio_pressed`. `ember_anchor()` = destino global de las monedas-brasa; `pulse()` al recibir Ascuas.

signal audio_pressed

const H := 30.0

var _ember: TextureRect
var _embers: Label
var _rate: Label
var _braziers: Label
var _heat_icon: TextureRect
var _heat: Label
var _dust: Label
var _shown := 0.0
var _t := 0.0
var _pulse := 0.0


func _init() -> void:
	size = Vector2(1280, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", UIKit.stylebox("hudbar", UIKit.iron(2), 5, Vector4.ZERO))
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_ember = _icon(HudArt.intent_texture("steal"), 10)
	_embers = UI.plabel("0", 2, UI.EMBER)
	_embers.position = Vector2(32, 2)
	add_child(_embers)
	_rate = UI.label("", 14, UI.DIM)
	_rate.position = Vector2(140, 8)
	add_child(_rate)
	# Derecha, de derecha a izquierda: música, polvo, calor, braseros.
	var music := Button.new()
	music.text = "♪"
	# Fragua ×2 en la rejilla (antes ×1 en y 3: medio píxel de arte).
	UI.pixelize(music, 2)
	music.alignment = HORIZONTAL_ALIGNMENT_LEFT
	music.position = Vector2(1240, 2)
	music.custom_minimum_size = Vector2(32, 28)
	music.size = Vector2(32, 28)
	music.focus_mode = Control.FOCUS_NONE
	var pad := Vector4(roundf((32.0 - PixelFont.text_width("♪") * 2.0) / 4.0) * 2.0 - 2.0, 0, 0, 2)
	music.add_theme_stylebox_override("normal", UIKit.sb_iron(3, pad))
	music.add_theme_stylebox_override("hover", UIKit.sb_plate(Palette.color(&"plate", 3), Palette.color(&"ember_ui", 3), 1, 0, pad))
	music.add_theme_stylebox_override("pressed", UIKit.sb_iron(2, pad))
	music.tooltip_text = "Silenciar / activar audio"
	music.pressed.connect(func() -> void: audio_pressed.emit())
	add_child(music)
	_icon(HudArt.tex("star9", _star()), 1120)
	_dust = UI.label("", 14, Palette.color(&"magic", 4))
	_dust.position = Vector2(1142, 8)
	_dust.mouse_filter = Control.MOUSE_FILTER_PASS
	_dust.tooltip_text = "Polvo Estelar (total ganado). Cada uno da +10% de producción.\nEl Polvo sin gastar compra Talentos."
	add_child(_dust)
	_heat_icon = _icon(HudArt.status_texture("scorch"), 1020)
	_heat = UI.label("", 14, Palette.color(&"ember_ui", 3))
	_heat.position = Vector2(1042, 8)
	_heat.mouse_filter = Control.MOUSE_FILTER_PASS
	_heat.tooltip_text = "Calor de Pacto: más Ascuas en la Torre y enemigos más duros."
	add_child(_heat)
	_icon(HudArt.tex("brazier9", _brazier()), 900)
	_braziers = UI.label("", 14)
	_braziers.position = Vector2(922, 8)
	_braziers.mouse_filter = Control.MOUSE_FILTER_PASS
	_braziers.tooltip_text = "Braseros: cada piso récord alcanzado en la Torre\nmultiplica la producción de la Forja un +10%."
	add_child(_braziers)
	_shown = Game.embers
	refresh()


func _icon(t: Texture2D, x: float) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture = t
	r.size = Vector2(18, 18)
	r.position = Vector2(x, 6)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


## Segundo fotograma del latido: la brasa un paso más apagada.
static func _ember_dim() -> Image:
	return HudArt._sprite(HudArt.COIN, {"k": Palette.OUTLINE, "w": Palette.color(&"ember_ui", 5), "y": Palette.color(&"ember_ui", 4),
		"o": Palette.color(&"ember_ui", 2), "r": Palette.color(&"ember_ui", 1), "R": Palette.color(&"ember_ui", 0)})


static func _star() -> Image:
	return HudArt._sprite(["....k....", "...kwk...", "kkkkwkkkk", "kwwwwwmmk", ".kwwwmmk.", "..kwmmk..", ".kwmkmmk.", ".kmk.kmk.", ".kk...kk."],
		{"k": Palette.OUTLINE, "w": Palette.color(&"magic", 4), "m": Palette.color(&"magic", 3)})


static func _brazier() -> Image:
	return HudArt._sprite(["...yk....", "..kyok...", "..koyok..", ".kooyok..", "kkkkkkkkk", "kmmmmmbbk", ".kmmmbbk.", "..kmbbk..", ".kkkkkkk."],
		{"k": Palette.OUTLINE, "y": Palette.color(&"ember_ui", 5), "o": Palette.color(&"ember_ui", 3),
			"m": Palette.color(&"iron", 7), "b": Palette.color(&"iron", 4)})


func refresh() -> void:
	_rate.text = "+%s/s" % Num.fmt(Game.production())
	_braziers.text = "%d  (+%d%%)" % [Game.max_floor, int(Game.BRAZIER_BONUS * 100 * Game.max_floor)]
	_dust.text = "%s  (%s)" % [Num.fmt(Game.stardust_total), Num.fmt(Game.stardust)]
	var h := 0
	if Game.run != null:
		h = Game.run.heat()
	_heat_icon.visible = h > 0
	_heat.visible = h > 0
	_heat.text = str(h)


func ember_anchor() -> Vector2:
	return global_position + Vector2(19, 15)


func pulse() -> void:
	_pulse = 0.25


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, Game.embers, minf(1.0, delta * 10.0))
	if absf(_shown - Game.embers) < 0.5:
		_shown = Game.embers
	_embers.text = Num.fmt(_shown)
	# La brasa late (2 fotogramas: paso de rampa); salta 2 px al recibir Ascuas.
	_pulse = maxf(0.0, _pulse - delta)
	_ember.position.y = 4.0 if _pulse > 0.0 else 6.0
	_ember.texture = HudArt.intent_texture("steal") if int(_t / 0.6) % 2 == 0 else HudArt.tex("ember_dim", _ember_dim())
