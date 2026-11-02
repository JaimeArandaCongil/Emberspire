class_name StatusRow
extends HBoxContainer
## Fila de estados y poderes: icono 9×9 ×2 con su valor en Mini ×2 y tooltip.
## Uso directo: `set_fighter(f)`. Genérico: `set_items([{"id": "scorch", "value": 3, "tooltip": "..."}])`;
## un elemento puede llevar `"texture"` en vez de `"id"` (Poderes).

const CELL := Vector2(30, 26)
const ORDER := ["str", "weak", "vuln", "scorch", "thorns", "regen", "choke"]


func _init() -> void:
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_items(items: Array) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for it: Dictionary in items:
		var cell := Control.new()
		cell.custom_minimum_size = CELL
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.tooltip_text = String(it.get("tooltip", ""))
		var r := TextureRect.new()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.texture = it["texture"] if it.has("texture") else HudArt.status_texture(String(it.get("id", "")))
		r.size = Vector2(r.texture.get_width(), r.texture.get_height())
		r.position = Vector2(0, 0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(r)
		var l := UI.mlabel(str(int(it.get("value", 0))), Palette.color(&"ember_ui", 5))
		l.position = Vector2(14, 10)
		l.add_theme_color_override("font_shadow_color", Palette.OUTLINE)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(l)
		add_child(cell)


## Lee `Fighter`: estados y, si es la jugadora, sus Poderes.
func set_fighter(f: Fighter) -> void:
	var items: Array = []
	for id: String in ORDER:
		var v := f.st(id)
		if v != 0:
			items.append({"id": id, "value": v, "tooltip": "%s %d\n%s" % [FighterView.STATUS_NAMES[id], v, FighterView.STATUS_DESC[id]]})
	if f.is_player:
		for pid: String in f.powers:
			var txt: String = CardDB.POWERS.get(pid, "")
			items.append({"texture": HudArt.legacy_icon(CardDB.POWER_ICONS.get(pid, "star")), "value": f.pw(pid),
				"tooltip": "Poder\n" + txt.replace("%d", str(f.pw(pid)))})
	set_items(items)
