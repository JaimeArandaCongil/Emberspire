class_name IntentView
extends Control
## Intención de un enemigo: icono 9×9 ×2 + cifra en Fragua ×2. Forma + número (nunca sólo color).
## Uso: `set_intent(kind, damage, hits, tooltip)`. `damage < 0` = sin cifra. Golpes de 20+ pasan a "attack_heavy".
## `kind`: los de `fighter.intent["kind"]`: attack, attack_debuff, attack_defend, defend, buff, debuff, steal, summon.
## Va sobre una placa opaca (`HudArt.intent_plate`) con una punta hacia su dueño: se lee igual sobre muro, arco o cielo.
## Se ancla por la punta de la placa: `place_above(x, y)`.

const HEAVY_FROM := 20
const PAD := 4.0          # placa: 2 px de arte de marco
const ICON := 18.0
const GAP := 4.0
const TIP := 4.0          # punta: 2 px de arte
const H := PAD * 2.0 + ICON + TIP

var _plate: TextureRect

var _icon: TextureRect
var _label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_plate = TextureRect.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.size = Vector2(ICON, ICON)
	_icon.position = Vector2(PAD, PAD)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_label = UI.plabel("", 2)
	_label.position = Vector2(PAD + ICON + GAP, PAD - 4.0)   # rejilla ×2 (antes −1: medio píxel)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	size = Vector2(PAD * 2.0 + ICON, H)


func set_intent(kind: String, damage: int = -1, hits: int = 1, tip: String = "") -> void:
	var k := kind
	var total := damage * maxi(1, hits)
	if kind == "attack" and total >= HEAVY_FROM:
		k = "attack_heavy"
	_icon.texture = HudArt.intent_texture(k if HudArt.INTENTS.has(k) else "unknown")
	var txt := ""
	if damage >= 0:
		txt = str(damage) if hits <= 1 else "%d×%d" % [damage, hits]
	_label.text = txt
	_label.add_theme_color_override("font_color", Palette.color(&"blood", 4) if total >= HEAVY_FROM else Palette.color(&"ember_ui", 5))
	tooltip_text = tip
	var w := PAD * 2.0 + ICON
	if txt != "":
		w += GAP + PixelFont.text_width(txt) * 2.0
	size = Vector2(w, H)
	_label.size = Vector2(w - _label.position.x, 26)
	_plate.texture = HudArt.intent_plate(int(w / HudArt.S))
	_plate.size = size


## Coloca el widget centrado en x con su base en y (coordenadas del padre), en la rejilla ×2.
func place_above(x: float, y: float) -> void:
	position = (Vector2(x - size.x * 0.5, y - size.y) / 2.0).round() * 2.0
