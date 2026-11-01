extends SceneTree
## Horneador de arte v0.4 (TEC). Convierte las definiciones de rig (código, fuente de verdad) en atlas PNG versionados.
##
## Uso (headless, desde la raíz del proyecto):
##   godot --headless --path . -s res://tools/bake_art.gd                    hornea todo
##   godot --headless --path . -s res://tools/bake_art.gd -- --only=golem_example,soot_golem
##   godot --headless --path . -s res://tools/bake_art.gd -- --check         sólo comprueba frescura (no escribe)
##   godot --headless --path . -s res://tools/bake_art.gd -- --list          lista las definiciones encontradas
## Después de hornear, `godot --headless --path . --import` importa los PNG nuevos (el horneador deja los .import).
##
## Descubre definiciones en DEF_DIRS: cualquier .gd con `static func build() -> RigDef` (un fichero por criatura,
## sin registro compartido). Salida por definición en assets/baked/<grupo>/:
##   <id>_idx.png      atlas de índices (filas = animaciones, columnas = fotogramas), formato IndexFormat v1
##   <id>_prev.png     el mismo atlas en color (luz dinámica 0) — revisable en PR, en paleta
##   <id>@<var>_idx.png / _prev.png   variantes (accesorios, máscaras, fases)
##   <id>.json         metadatos: lienzo, origen, animaciones (fila, fotogramas, ms, bucle, sockets por fotograma)
## y la hoja de QA (silueta en negro, miniatura a 32 px, recorte ×8) en tests/art/out/qa/<id>_qa.png.
## Manifiesto: assets/baked/manifest.json con el hash de las fuentes de cada definición (prueba de frescura).
## Código de salida: 0 bien · 1 errores de horneado o de frescura.

const DEF_DIRS := ["res://scripts/art/defs/creatures", "res://scripts/art/defs/hero", "res://scripts/art/defs/heroine", "res://scripts/art/defs/bosses",
	"res://scripts/art/defs/props", "res://scripts/art/rig/examples"]
const OUT := "res://assets/baked/"
const QA := "res://tests/art/out/qa/"
const MANIFEST := "res://assets/baked/manifest.json"
## Fuentes comunes que invalidan TODO el horneado si cambian.
const ENGINE_SOURCES := ["res://scripts/art/rig/rig_def.gd", "res://scripts/art/rig/rig_builder.gd",
	"res://scripts/art/rig/rig_pose.gd", "res://scripts/art/rig/rig_renderer.gd", "res://scripts/art/rig/rig_lint.gd",
	"res://scripts/art/rig/index_format.gd", "res://scripts/art/palette.gd", "res://scripts/art/defs/stamps/stamp_lib.gd"]


func _initialize() -> void:
	await process_frame
	var only: Array[String] = []
	var check := false
	var list := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for s in a.substr(7).split(",", false):
				only.append(s.strip_edges())
		elif a == "--check":
			check = true
		elif a == "--list":
			list = true
	var defs := discover()
	if list:
		for id: String in defs.keys():
			print("%s\t%s" % [id, defs[id]])
		quit(0)
		return
	if check:
		var errs := freshness_errors()
		for e in errs:
			print("  ✗ ", e)
		print("bake_art --check: %s" % ("al día" if errs.is_empty() else "%d hojas desactualizadas" % errs.size()))
		quit(0 if errs.is_empty() else 1)
		return
	var manifest := load_manifest()
	var failed := 0
	var done := 0
	var t0 := Time.get_ticks_msec()
	for id: String in defs.keys():
		if not only.is_empty() and not only.has(id):
			continue
		var res := bake_one(id, defs[id])
		if res.is_empty():
			failed += 1
			continue
		manifest["entries"][id] = res
		done += 1
	manifest["engine"] = RigRenderer.ENGINE_VERSION
	save_manifest(manifest)
	print("bake_art: %d horneadas, %d con errores, %.1f s" % [done, failed, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(0 if failed == 0 else 1)


# --------------------------------------------------------------------------------------------- descubrimiento
## {id: ruta} de todas las definiciones (id = nombre de archivo sin .gd).
static func discover() -> Dictionary:
	var out := {}
	for d: String in DEF_DIRS:
		if not DirAccess.dir_exists_absolute(d):
			continue
		var files := Array(DirAccess.get_files_at(d))
		files.sort()
		for f: String in files:
			if f.ends_with(".gd") and not f.begins_with("_") and is_def(d.path_join(f)):
				out[f.get_basename()] = d.path_join(f)
	return out


## ¿Es una definición de rig? (script con `static func build()`; los demás .gd de esas carpetas se ignoran)
static func is_def(path: String) -> bool:
	var scr: Variant = load(path)
	if not (scr is Script):
		return false
	for m: Dictionary in (scr as Script).get_script_method_list():
		if m.get("name", "") == "build":
			return true
	return false


static func build_def(path: String) -> RigDef:
	var scr: GDScript = load(path)
	if scr == null or not scr.has_method("build"):
		return null
	var d: Variant = scr.call("build")
	return d as RigDef


# --------------------------------------------------------------------------------------------- hash de fuentes
static func source_hash(def_path: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(("engine:%d\n" % RigRenderer.ENGINE_VERSION).to_utf8_buffer())
	for p: String in ENGINE_SOURCES + [def_path]:
		if FileAccess.file_exists(p):
			# normaliza finales de línea: el hash no depende de CRLF/LF del checkout
			ctx.update(FileAccess.get_file_as_string(p).replace("\r\n", "\n").to_utf8_buffer())
		ctx.update(("|" + p + "\n").to_utf8_buffer())
	return ctx.finish().hex_encode()


static func load_manifest() -> Dictionary:
	if FileAccess.file_exists(MANIFEST):
		var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if m is Dictionary and (m as Dictionary).has("entries"):
			return m
	return {"engine": RigRenderer.ENGINE_VERSION, "entries": {}}


static func save_manifest(m: Dictionary) -> void:
	var keys: Array = (m["entries"] as Dictionary).keys()
	keys.sort()
	var sorted := {}
	for k in keys:
		sorted[k] = m["entries"][k]
	m["entries"] = sorted
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var f := FileAccess.open(MANIFEST, FileAccess.WRITE)
	f.store_string(JSON.stringify(m, "\t", false) + "\n")
	f.close()


## Errores de frescura: entradas cuyo hash de fuentes ya no coincide, archivos que faltan o definiciones sin hornear.
static func freshness_errors() -> Array[String]:
	var errs: Array[String] = []
	var m := load_manifest()
	var entries: Dictionary = m["entries"]
	var defs := discover()
	for id: String in entries.keys():
		var e: Dictionary = entries[id]
		var src: String = e.get("src", "")
		if not FileAccess.file_exists(src):
			errs.append("%s: su fuente %s ya no existe (borrar la entrada o volver a hornear)" % [id, src])
			continue
		if source_hash(src) != e.get("hash", ""):
			errs.append("%s: las fuentes cambiaron desde el último horneado → godot -s res://tools/bake_art.gd -- --only=%s" % [id, id])
		for f: String in e.get("files", []):
			if not FileAccess.file_exists(f):
				errs.append("%s: falta %s" % [id, f])
	for id: String in defs.keys():
		if not entries.has(id):
			errs.append("%s: definición sin hornear (%s)" % [id, defs[id]])
	return errs


# --------------------------------------------------------------------------------------------- horneado
## Hornea una definición. Devuelve la entrada del manifiesto o {} si hubo errores.
static func bake_one(id: String, path: String) -> Dictionary:
	var def := build_def(path)
	if def == null:
		printerr("✗ %s: %s no tiene `static func build() -> RigDef`" % [id, path])
		return {}
	if String(def.id) != id:
		printerr("✗ %s: el id de la definición (%s) debe coincidir con el nombre del archivo" % [id, def.id])
		return {}
	var errs := RigLint.check(def)
	if not errs.is_empty():
		for e in errs:
			printerr("✗ ", e)
		return {}
	var dir := OUT + String(def.group) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(QA))
	var files: Array[String] = []
	var md5 := {}
	var meta := {"id": id, "group": String(def.group), "size": [def.size.x, def.size.y], "origin": [def.origin.x, def.origin.y],
		"facing": def.facing, "engine": RigRenderer.ENGINE_VERSION, "anims": {}, "variants": [], "parts": []}
	var first_idle: Image = null
	for vname: StringName in def.variants.keys():
		var params: Dictionary = def.variants[vname]
		var sheet := bake_sheet(def, params, meta if vname == &"base" else {})
		if sheet.has("errors"):
			for e in sheet["errors"]:
				printerr("✗ %s@%s: %s" % [id, vname, e])
			return {}
		var suffix := "" if vname == &"base" else "@" + String(vname)
		var pi := dir + id + suffix + "_idx.png"
		var pp := dir + id + suffix + "_prev.png"
		(sheet["index"] as Image).save_png(pi)
		(sheet["preview"] as Image).save_png(pp)
		write_import(pi)
		write_import(pp)
		files.append(pi)
		files.append(pp)
		md5[pi] = image_md5(sheet["index"])
		md5[pp] = image_md5(sheet["preview"])
		if vname != &"base":
			(meta["variants"] as Array).append(String(vname))
		elif sheet.has("first"):
			first_idle = sheet["first"]
	# partes de jefe
	for k in def.parts.size():
		var part: RigDef.Part = def.parts[k]
		var pmeta := {"id": String(part.def.id), "offset": [part.offset.x, part.offset.y], "phase": part.phase, "anims": {},
			"size": [part.def.size.x, part.def.size.y], "origin": [part.def.origin.x, part.def.origin.y], "variants": []}
		# Cada parte hornea también sus variantes: el cambio de silueta de la fase 2 es una variante de la parte.
		for pv: StringName in part.def.variants.keys():
			var ps := bake_sheet(part.def, part.def.variants[pv], pmeta if pv == &"base" else {})
			if ps.has("errors"):
				for e in ps["errors"]:
					printerr("✗ %s/%s@%s: %s" % [id, part.def.id, pv, e])
				return {}
			var psuf := "" if pv == &"base" else "@" + String(pv)
			var ppi := dir + id + "." + String(part.def.id) + psuf + "_idx.png"
			var ppp := dir + id + "." + String(part.def.id) + psuf + "_prev.png"
			(ps["index"] as Image).save_png(ppi)
			(ps["preview"] as Image).save_png(ppp)
			write_import(ppi)
			write_import(ppp)
			files.append(ppi)
			files.append(ppp)
			md5[ppi] = image_md5(ps["index"])
			md5[ppp] = image_md5(ps["preview"])
			if pv != &"base":
				(pmeta["variants"] as Array).append(String(pv))
		(meta["parts"] as Array).append(pmeta)
	var pj := dir + id + ".json"
	var fj := FileAccess.open(pj, FileAccess.WRITE)
	fj.store_string(JSON.stringify(meta, "\t", false) + "\n")
	fj.close()
	files.append(pj)
	if first_idle != null:
		qa_sheet(first_idle).save_png(QA + id + "_qa.png")
	print("✓ %s (%s) → %s" % [id, def.describe(), dir])
	return {"src": path, "hash": source_hash(path), "group": String(def.group), "files": files, "md5": md5}


## Atlas de una variante: filas = animaciones (orden de declaración), columnas = fotogramas.
## Rellena `meta.anims` si se le pasa un diccionario no vacío.
static func bake_sheet(def: RigDef, params: Dictionary, meta: Dictionary) -> Dictionary:
	var names: Array = def.anims.keys()
	var cols := 1
	for n in names:
		cols = maxi(cols, (def.anims[n] as RigDef.Anim).frames)
	var rows := maxi(1, names.size())
	var W := def.size.x
	var H := def.size.y
	var idx := IndexFormat.blank(W * cols, H * rows)
	var prev := Image.create_empty(W * cols, H * rows, false, Image.FORMAT_RGBA8)
	prev.fill(Color(0, 0, 0, 0))
	var errs: Array[String] = []
	var first: Image = null
	for r in names.size():
		var a: RigDef.Anim = def.anims[names[r]]
		var sockets: Array = []
		for f in a.frames:
			var fr := RigRenderer.render(def, a.name, f, params)
			if not fr.errors.is_empty():
				errs.append_array(fr.errors)
			idx.blit_rect(fr.index, Rect2i(0, 0, W, H), Vector2i(f * W, r * H))
			prev.blit_rect(fr.preview, Rect2i(0, 0, W, H), Vector2i(f * W, r * H))
			if first == null:
				first = fr.preview
			var sk := {}
			for k in fr.sockets.keys():
				sk[String(k)] = [fr.sockets[k].x, fr.sockets[k].y]
			sockets.append(sk)
		if not meta.is_empty():
			var ms: Array = []
			for f in a.frames:
				ms.append(a.ms[f] if a.ms.size() == a.frames else a.ms[0])
			meta["anims"][String(a.name)] = {"row": r, "frames": a.frames, "ms": ms, "loop": a.loop, "sockets": sockets}
	if not errs.is_empty():
		return {"errors": errs}
	return {"index": idx, "preview": prev, "first": first}


static func image_md5(img: Image) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(img.get_data())
	return ctx.finish().hex_encode()


## Importación sin pérdidas, sin mipmaps, sin premultiplicar ni "arreglar" el borde alfa: los canales son DATOS.
static func write_import(png_path: String) -> void:
	var ip := png_path + ".import"
	if FileAccess.file_exists(ip):
		var txt := FileAccess.get_file_as_string(ip)
		if txt.contains("process/fix_alpha_border=false") and txt.contains("compress/mode=0"):
			return
	var f := FileAccess.open(ip, FileAccess.WRITE)
	f.store_string("""[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
""" % png_path)
	f.close()


## Hoja de QA: silueta en negro, miniatura a 32 px de alto (vecino más cercano) y recorte ×8 del centro.
static func qa_sheet(prev: Image) -> Image:
	var W := prev.get_width()
	var H := prev.get_height()
	var sil := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	sil.fill(Color(1, 1, 1, 1))
	for y in H:
		for x in W:
			if prev.get_pixel(x, y).a > 0.0:
				sil.set_pixel(x, y, Color(0, 0, 0, 1))
	var thumb := prev.duplicate() as Image
	var th := 32
	var tw := maxi(1, int(round(float(W) * th / H)))
	thumb.resize(tw, th, Image.INTERPOLATE_NEAREST)
	var crop := prev.get_region(Rect2i(W / 4, H / 4, W / 2, H / 2))
	crop.resize(crop.get_width() * 8, crop.get_height() * 8, Image.INTERPOLATE_NEAREST)
	var big := prev.duplicate() as Image
	big.resize(W * 4, H * 4, Image.INTERPOLATE_NEAREST)
	var sil4 := sil.duplicate() as Image
	sil4.resize(W * 4, H * 4, Image.INTERPOLATE_NEAREST)
	var out := Image.create_empty(W * 8 + crop.get_width() + 40, maxi(H * 4, crop.get_height()) + 20, false, Image.FORMAT_RGBA8)
	out.fill(Color("2b1a26"))
	out.blend_rect(sil4, Rect2i(0, 0, W * 4, H * 4), Vector2i(10, 10))
	out.blend_rect(big, Rect2i(0, 0, W * 4, H * 4), Vector2i(W * 4 + 20, 10))
	out.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(W * 8 + 30, 10))
	out.blend_rect(thumb, Rect2i(0, 0, tw, th), Vector2i(10, 10 + H * 4 - th))
	return out
