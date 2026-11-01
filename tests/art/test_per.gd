extends RefCounted
## Pruebas de personajes y criaturas (PER). Convención de DA: `run() -> Array` devuelve los FALLOS; vacío = todo pasa.
##
## 1. Biblioteca de sellos: formato, leyenda completa, materiales de la paleta, ancla dentro; caras ≥ 10×10 con ojo y brillo.
## 2. Cada definición de scripts/art/defs/{hero,creatures}/: RigLint sin errores, todas las animaciones se renderizan
##    sin errores, sólo con colores de la paleta, y con el reposo apoyado en el suelo de su lienzo.
## 3. Fogonera: 64–80 px de alto en reposo y pies en y 89–91.
## 4. Siluetas distintas (sin recoloreos): ningún par de criaturas comparte más del 80 % de su silueta de reposo
##    (intersección/unión tras alinear por la base y el centro).

const StampLib = preload("res://scripts/art/defs/stamps/stamp_lib.gd")
const DIRS := ["res://scripts/art/defs/hero/", "res://scripts/art/defs/creatures/"]
const MAX_IOU := 0.80


func run() -> Array:
	var fails: Array = []
	for e: String in StampLib.validate():
		fails.append("[PER sellos] " + e)
	for id: String in StampLib.MAT:
		if not Palette.has(StampLib.MAT[id]):
			fails.append("[PER sellos] material '%s' no existe en Palette" % StampLib.MAT[id])
	fails.append_array(check_faces())
	var sils := {}
	for def: RigDef in all_defs():
		fails.append_array(check_def(def, sils))
	fails.append_array(check_silhouettes(sils))
	return fails


static func all_defs() -> Array:
	var out: Array = []
	for dir: String in DIRS:
		var da := DirAccess.open(dir)
		if da == null:
			continue
		var files := da.get_files()
		files.sort()
		for f in files:
			if f.ends_with(".gd"):
				out.append((load(dir + f) as Script).call("build"))
	return out


func check_faces() -> Array:
	var fails: Array = []
	for id: String in ["face_34", "face_34_effort", "face_34_hurt", "face_profile"]:
		var rows: Array = StampLib.get_stamp(id)["rows"]
		var wmax := 0
		for r: String in rows:
			wmax = maxi(wmax, r.length())
		if rows.size() < 10 or wmax < 10:
			fails.append("[PER cara] %s mide %d×%d (< 10×10)" % [id, wmax, rows.size()])
	var f: Array = StampLib.get_stamp("face_34")["rows"]
	var ok := false
	for y in f.size() - 1:
		for x in String(f[y]).length():
			if String(f[y])[x] == "h" and x < String(f[y + 1]).length() and String(f[y + 1])[x] == "i":
				ok = true
	if not ok:
		fails.append("[PER cara] face_34 sin ojo 1×2 con brillo")
	return fails


func check_def(def: RigDef, sils: Dictionary) -> Array:
	var fails: Array = []
	var pre := "[PER %s] " % def.id
	for e in RigLint.check(def):
		fails.append(pre + "lint: " + e)
	for an: StringName in def.anims.keys():
		var a: RigDef.Anim = def.anims[an]
		for f in a.frames:
			var fr := RigRenderer.render(def, an, f, {})
			for e in fr.errors:
				fails.append(pre + "%s:%d %s" % [an, f, e])
			var off := 0
			for y in fr.preview.get_height():
				for x in fr.preview.get_width():
					var c := fr.preview.get_pixel(x, y)
					if c.a > 0.0 and not Palette.is_palette_color(c):
						off += 1
			if off > 0:
				fails.append(pre + "%s:%d %d píxeles fuera de paleta" % [an, f, off])
			if an == &"idle" and f == 0:
				sils[def.id] = fr.preview
	if not sils.has(def.id):
		fails.append(pre + "sin animación idle")
		return fails
	var img: Image = sils[def.id]
	var bb := _bbox(img)
	if def.group == &"hero":
		if bb.end.y - 1 < 89 or bb.end.y - 1 > 91:
			fails.append(pre + "pies en y=%d (esperado 89–91)" % (bb.end.y - 1))
		if bb.size.y < 64 or bb.size.y > 80:
			fails.append(pre + "alto %d px fuera de 64–80" % bb.size.y)
	return fails


static func _bbox(img: Image) -> Rect2i:
	var mn := Vector2i(9999, 9999)
	var mx := Vector2i(-1, -1)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				mn = mn.min(Vector2i(x, y))
				mx = mx.max(Vector2i(x, y))
	return Rect2i(mn, mx - mn + Vector2i.ONE)


func check_silhouettes(sils: Dictionary) -> Array:
	var fails: Array = []
	var ids: Array = sils.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Image = sils[ids[i]]
			var b: Image = sils[ids[j]]
			var ba := _bbox(a)
			var bbx := _bbox(b)
			var ca := Vector2i(ba.position.x + ba.size.x / 2, ba.end.y)
			var cb := Vector2i(bbx.position.x + bbx.size.x / 2, bbx.end.y)
			var inter := 0
			var uni := 0
			for y in range(-120, 1):
				for x in range(-80, 81):
					var pa := ca + Vector2i(x, y)
					var pb := cb + Vector2i(x, y)
					var ia := pa.x >= 0 and pa.y >= 0 and pa.x < a.get_width() and pa.y < a.get_height() and a.get_pixel(pa.x, pa.y).a > 0.0
					var ib := pb.x >= 0 and pb.y >= 0 and pb.x < b.get_width() and pb.y < b.get_height() and b.get_pixel(pb.x, pb.y).a > 0.0
					if ia and ib:
						inter += 1
					if ia or ib:
						uni += 1
			if uni > 0 and float(inter) / uni > MAX_IOU:
				fails.append("[PER siluetas] %s y %s comparten el %d %% de la silueta" % [ids[i], ids[j], int(100.0 * inter / uni)])
	return fails
