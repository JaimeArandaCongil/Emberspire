extends SceneTree
## Primer plano de fotogramas: Godot --headless --path . -s res://scripts/art/defs/tools/zoom_per.gd -- <id> <anim:f> [<anim:f> ...] [cold]
## Salida: docs/reviews/v04/personajes/img/<id>_zoom_x8.png (fotogramas en fila a ×8 sobre piedra).

const OUT := "res://docs/reviews/v04/personajes/img/"
const DIRS := ["res://scripts/art/defs/hero/", "res://scripts/art/defs/creatures/"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0]
	var script: Script = null
	for d: String in DIRS:
		if ResourceLoader.exists(d + id + ".gd"):
			script = load(d + id + ".gd")
	var def: RigDef = script.call("build")
	var frames: Array = []
	for i in range(1, args.size()):
		frames.append(args[i])
	var W := def.size.x
	var H := def.size.y
	var img := Image.create(W * frames.size(), H, false, Image.FORMAT_RGBA8)
	img.fill(Palette.color(&"stone", 3))
	for n in frames.size():
		var parts: PackedStringArray = String(frames[n]).split(":")
		var fr := RigRenderer.render(def, StringName(parts[0]), int(parts[1]), {})
		for e in fr.errors:
			print("RENDER ", e)
		img.blend_rect(fr.preview, Rect2i(0, 0, W, H), Vector2i(n * W, 0))
	img.resize(img.get_width() * 8, H * 8, Image.INTERPOLATE_NEAREST)
	img.save_png(OUT + "%s_zoom_x8.png" % id)
	quit()
