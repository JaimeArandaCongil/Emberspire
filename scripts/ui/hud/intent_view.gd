class_name IntentView
extends Control
## Intención de un enemigo: icono 9×9 ×2 + cifra en Fragua ×2. Forma + número (nunca sólo color).
## Uso: `set_intent(kind, damage, hits, tooltip)`. `damage < 0` = sin cifra. Golpes de 20+ pasan a "attack_heavy".
## `kind`: los de `fighter.intent["kind"]`: attack, attack_debuff, attack_defend, defend, buff, debuff, steal, summon.
## Se ancla por su centro inferior: `place_above(x, y)`.

const HEAVY_FROM := 20

var _icon: TextureRect
var _label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.size = Vector2(18, 18)
	_icon.position = Vector2(0, 2)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_label = UI.plabel("", 2)
	_label.position = Vector2(20, -3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	size = Vector2(18, 22)


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
	var w := 20 + PixelFont.text_width(txt) * 2 + 2 if txt != "" else 18
	size = Vector2(w, 22)
	_label.size = Vector2(w - 20, 26)


## Coloca el widget centrado en x con su base en y (coordenadas del padre), en la rejilla ×2.
func place_above(x: float, y: float) -> void:
	position = (Vector2(x - size.x * 0.5, y - size.y) / 2.0).round() * 2.0
