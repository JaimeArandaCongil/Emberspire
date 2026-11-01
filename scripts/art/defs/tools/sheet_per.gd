extends SceneTree
## Hojas de revisión de PER sobre el motor de rig v1 de TEC.
## Godot --headless --path . -s res://scripts/art/defs/tools/sheet_per.gd -- [id ...]
## Sin ids: todas las definiciones de scripts/art/defs/{hero,creatures}/. Salida: docs/reviews/v04/personajes/img/
##   <id>_sheet_x3.png  — una fila por animación (fotogramas en orden), fondo de piedra cálida
##   <id>_frio_x3.png   — reposo + ataque con la luz fría dominante (sólo para comprobar la rampa fría)
## Imprime los errores de RigLint y del renderizador.

const OUT := "res://docs/reviews/v04/personajes/img/"
const DIRS := ["res://scripts/art/defs/hero/", "res://scripts/art/defs/creatures/"]


func _init() -> void:
	var want: Array = []
	for a in OS.get_cmdline_user_args():
		want.append(a)
	for dir: String in DIRS:
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			if not f.ends_with(".gd"):
				continue
			var id := f.get_basename()
			if not want.is_empty() and not want.has(id):
				continue
			sheet(load(dir + f))
	quit()


func sheet(script: Script) -> void:
	var def: RigDef = script.call("build")
	var errs := RigLint.check(def)
	for e in errs:
		print("LINT ", e)
	var names: Array = def.anims.keys()
	var maxf_ := 1
	for n in names:
		maxf_ = maxi(maxf_, (def.anims[n] as RigDef.Anim).frames)
	var W := def.size.x
	var H := def.size.y
	var img := Image.create(W * maxf_, H * names.size(), false, Image.FORMAT_RGBA8)
	img.fill(Palette.color(&"stone", 2))
	for r in names.size():
		var a: RigDef.Anim = def.anims[names[r]]
		for f in a.frames:
			var fr := RigRenderer.render(def, names[r], f, {})
			for e in fr.errors:
				print("RENDER %s %s:%d %s" % [def.id, names[r], f, e])
			img.blend_rect(fr.preview, Rect2i(0, 0, W, H), Vector2i(f * W, r * H))
			# separador sutil de fotograma
			for y in H:
				img.set_pixel(f * W, r * H + y, Palette.color(&"stone", 1))
	var up := img.duplicate() as Image
	up.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	up.save_png(OUT + "%s_sheet_x3.png" % def.id)
	# Fotogramas clave a ×6 (último fotograma de cada animación, que es la pose "llegada").
	var keys := Image.create(W * names.size(), H, false, Image.FORMAT_RGBA8)
	keys.fill(Palette.color(&"stone", 2))
	for r in names.size():
		var a2: RigDef.Anim = def.anims[names[r]]
		var fr2 := RigRenderer.render(def, names[r], a2.frames - 1, {})
		keys.blend_rect(fr2.preview, Rect2i(0, 0, W, H), Vector2i(r * W, 0))
	keys.resize(keys.get_width() * 4, H * 4, Image.INTERPOLATE_NEAREST)
	keys.save_png(OUT + "%s_keys_x4.png" % def.id)
	print("OK %s anims=%s" % [def.id, str(names)])
