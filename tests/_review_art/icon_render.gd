extends Node
func _ready() -> void:
	var src := FileAccess.get_file_as_string("res://tests/_review_art/icons_src.txt").split("\n")
	var blocks := {}
	var cur := ""
	for l: String in src:
		l = l.strip_edges()
		if l.begins_with("#"):
			cur = l.substr(1); blocks[cur] = []
		elif l != "":
			blocks[cur].append(l)
	var out := Image.create(blocks.size() * 110 + 10, 230, false, Image.FORMAT_RGBA8)
	out.fill(Color("3a2a2c"))
	var i := 0
	for k: String in blocks:
		var old := Art.icon_image(k if Art.has_icon(k) else "unknown")
		old.resize(96, 96, Image.INTERPOLATE_NEAREST)
		out.blend_rect(old, Rect2i(0, 0, 96, 96), Vector2i(10 + i * 110, 10))
		var nw := Art.image_from_rows(blocks[k])
		nw.resize(96, 96, Image.INTERPOLATE_NEAREST)
		out.blend_rect(nw, Rect2i(0, 0, 96, 96), Vector2i(10 + i * 110, 120))
		i += 1
	out.save_png(ProjectSettings.globalize_path("res://tests/_review_art/out/proposal_icons.png"))
	print("ICONS OK")
	get_tree().quit()
