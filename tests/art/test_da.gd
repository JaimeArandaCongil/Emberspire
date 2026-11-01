extends RefCounted
## Pruebas de dirección de arte (DA). Convención: `run() -> Array` devuelve los FALLOS (cadenas); vacío = todo pasa.
## Las puede llamar la escena de TEC (`tests/art/art_tests.tscn`) o cualquier script.
##
## 1. Datos de la paleta maestra (`Palette.validate()`).
## 2. PALETA CERRADA: todo PNG de `res://assets/baked/` y toda textura de la lista ART_CALLS usa sólo colores de la paleta.
## 3. Ayudante de MINIATURA EN GRISES: `thumbnail_separation()` / `check_separation()` para las pruebas de los demás.
##
## Para añadir texturas generadas al control de paleta, añade una entrada a ART_CALLS: [nombre, método de Art, args].
## Sólo arte v0.4: el respaldo v0.3 (scripts/art/legacy) queda EXENTO hasta que se retire.

const BAKED_DIR := "res://assets/baked/"
## Cobertura mínima para contar un píxel (los píxeles con alfa < esto se ignoran: bordes de luz aditiva).
const MIN_ALPHA := 0.02
## Máximo de colores fuera de paleta que se informan por imagen.
const MAX_REPORT := 6
## Separación mínima de luminancia (0–1) entre figura y entorno en la miniatura en grises.
const MIN_SEPARATION := 0.10

## [nombre, método de Art, argumentos]. Cada experto añade las suyas cuando su pieza v0.4 entra detrás de la fachada.
const ART_CALLS := [
	# ["lut", "", []],  # ejemplo; la LUT se comprueba aparte
]

## Carpetas exentas dentro de assets/baked (p. ej. capturas de referencia que no son arte del juego).
const EXEMPT := ["_ref/", "_tmp/"]

func run() -> Array:
	var fails: Array = []
	for e: String in Palette.validate():
		fails.append("[DA paleta] " + e)
	fails.append_array(check_lut())
	fails.append_array(check_baked())
	fails.append_array(check_art_calls())
	fails.append_array(self_test())
	return fails

# ---------------------------------------------------------------- paleta cerrada
## Colores de `img` que no están en la paleta. Devuelve [{color, count, first:Vector2i}].
static func off_palette(img: Image) -> Array:
	var allowed := Palette.all_colors()
	var src := img
	if src.is_compressed():
		src = src.duplicate()
		src.decompress()
	if src.get_format() != Image.FORMAT_RGBA8:
		src = src.duplicate()
		src.convert(Image.FORMAT_RGBA8)
	var found := {}
	var w := src.get_width()
	var h := src.get_height()
	var data := src.get_data()
	for y in h:
		for x in w:
			var o := (y * w + x) * 4
			if data[o + 3] < int(MIN_ALPHA * 255.0):
				continue
			var k := (data[o] << 16) | (data[o + 1] << 8) | data[o + 2]
			if allowed.has(k):
				continue
			if found.has(k):
				found[k]["count"] += 1
			else:
				found[k] = {"color": Color8(data[o], data[o + 1], data[o + 2]), "count": 1, "first": Vector2i(x, y)}
	return found.values()

static func check_image(img: Image, name: String) -> Array:
	var bad := off_palette(img)
	if bad.is_empty():
		return []
	bad.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["count"] > b["count"])
	var total := 0
	for b: Dictionary in bad:
		total += b["count"]
	var parts: Array[String] = []
	for i in mini(bad.size(), MAX_REPORT):
		var b: Dictionary = bad[i]
		parts.append("#%s×%d @%s" % [(b["color"] as Color).to_html(false), b["count"], b["first"]])
	return ["[DA paleta] %s: %d colores fuera de paleta (%d px): %s" % [name, bad.size(), total, ", ".join(parts)]]

func check_lut() -> Array:
	var lut := Palette.build_lut_image()
	var fails := check_image(lut, "LUT")
	if lut.get_width() != Palette.LUT_W or lut.get_height() != Palette.count() * 2:
		fails.append("[DA paleta] LUT con tamaño %s" % lut.get_size())
	return fails

func check_baked() -> Array:
	var fails: Array = []
	if not DirAccess.dir_exists_absolute(BAKED_DIR):
		return fails  # aún no hay horneado: no es un fallo
	for path: String in _pngs(BAKED_DIR):
		var rel := path.trim_prefix(BAKED_DIR)
		var exempt := false
		for e: String in EXEMPT:
			if rel.begins_with(e):
				exempt = true
		if exempt:
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.is_empty():
			fails.append("[DA paleta] no se pudo leer %s" % path)
			continue
		# Las texturas de ÍNDICE (R material, G paso…) no son color: el manifiesto las marca con sufijo _idx
		if rel.get_file().get_basename().ends_with("_idx"):
			continue
		fails.append_array(check_image(img, rel))
	return fails

static func _pngs(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.get_extension().to_lower() == "png":
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_pngs(dir.path_join(sub)))
	return out

func check_art_calls() -> Array:
	var fails: Array = []
	var art: Object = Engine.get_main_loop().root.get_node_or_null("/root/Art") if Engine.get_main_loop() is SceneTree else null
	for c: Array in ART_CALLS:
		var name: String = c[0]
		var method: String = c[1]
		if method == "":
			continue
		if art == null or not art.has_method(method):
			fails.append("[DA paleta] Art.%s no existe (entrada %s de ART_CALLS)" % [method, name])
			continue
		var tex: Variant = art.callv(method, c[2])
		var img: Image = null
		if tex is Texture2D:
			img = (tex as Texture2D).get_image()
		elif tex is Image:
			img = tex
		if img == null:
			fails.append("[DA paleta] Art.%s no devolvió textura" % method)
			continue
		fails.append_array(check_image(img, "Art.%s%s" % [method, c[2]]))
	return fails

# ---------------------------------------------------------------- miniatura en grises
## Reduce `img` por `factor` (media de caja) y la pasa a luminancia (0–1). Devuelve PackedFloat32Array w*h.
static func gray_thumb(img: Image, factor: int) -> Dictionary:
	var src := img.duplicate() as Image
	src.convert(Image.FORMAT_RGBA8)
	var tw := maxi(1, src.get_width() / factor)
	var th := maxi(1, src.get_height() / factor)
	var lum := PackedFloat32Array()
	lum.resize(tw * th)
	for ty in th:
		for tx in tw:
			var s := 0.0
			var n := 0
			for y in range(ty * factor, mini((ty + 1) * factor, src.get_height())):
				for x in range(tx * factor, mini((tx + 1) * factor, src.get_width())):
					var c := src.get_pixel(x, y)
					s += c.get_luminance() * c.a
					n += 1
			lum[ty * tw + tx] = s / maxf(n, 1)
	return {"w": tw, "h": th, "lum": lum}

## Separación de una figura respecto a su entorno en la miniatura en grises.
## `scene`: la captura completa (p. ej. 640×360 nativa). `mask`: misma talla; alfa > 0,5 = píxel de la figura.
## Compara la luminancia media de la figura con la de un anillo de `ring` celdas a su alrededor, a resolución 1/`factor`.
## Devuelve |Δ luminancia| (0–1). Criterio de la biblia: ≥ MIN_SEPARATION a factor 4 (160×90 desde 640×360).
static func thumbnail_separation(scene: Image, mask: Image, factor: int = 4, ring: int = 2) -> float:
	var t := gray_thumb(scene, factor)
	var m := gray_thumb(_alpha_as_gray(mask), factor)
	var tw: int = t["w"]
	var th: int = t["h"]
	var lum: PackedFloat32Array = t["lum"]
	var cov: PackedFloat32Array = m["lum"]
	var fig := 0.0
	var nf := 0
	var env := 0.0
	var ne := 0
	for y in th:
		for x in tw:
			var i := y * tw + x
			if cov[i] > 0.5:
				fig += lum[i]
				nf += 1
				continue
			# anillo: celdas sin figura a ≤ ring de una celda de figura
			var near := false
			for dy in range(-ring, ring + 1):
				for dx in range(-ring, ring + 1):
					var xx := x + dx
					var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < tw and yy < th and cov[yy * tw + xx] > 0.5:
						near = true
			if near:
				env += lum[i]
				ne += 1
	if nf == 0 or ne == 0:
		return 0.0
	return absf(fig / nf - env / ne)

static func _alpha_as_gray(mask: Image) -> Image:
	var m := mask.duplicate() as Image
	m.convert(Image.FORMAT_RGBA8)
	for y in m.get_height():
		for x in m.get_width():
			var a := m.get_pixel(x, y).a
			m.set_pixel(x, y, Color(a, a, a, 1.0))
	return m

## Atajo para las pruebas de los demás: devuelve [] o [fallo].
static func check_separation(name: String, scene: Image, mask: Image, factor: int = 4) -> Array:
	var s := thumbnail_separation(scene, mask, factor)
	if s < MIN_SEPARATION:
		return ["[DA miniatura] %s: separación %.3f < %.2f en gris a 1/%d" % [name, s, MIN_SEPARATION, factor]]
	return []

## Componer una figura (sprite con alfa) sobre un fondo en (x, y) y devolver [escena, máscara] listas para check_separation.
static func compose(bg: Image, sprite: Image, at: Vector2i) -> Array:
	var scene := bg.duplicate() as Image
	scene.convert(Image.FORMAT_RGBA8)
	var spr := sprite.duplicate() as Image
	spr.convert(Image.FORMAT_RGBA8)
	scene.blend_rect(spr, Rect2i(Vector2i.ZERO, spr.get_size()), at)
	var mask := Image.create_empty(bg.get_width(), bg.get_height(), false, Image.FORMAT_RGBA8)
	mask.blit_rect(spr, Rect2i(Vector2i.ZERO, spr.get_size()), at)
	return [scene, mask]

# ---------------------------------------------------------------- autoprueba de los ayudantes
func self_test() -> Array:
	var fails: Array = []
	# 1) una imagen con colores de paleta pasa; con un color ajeno falla
	var img := Image.create_empty(4, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Palette.color(&"stone", 3))
	img.set_pixel(1, 0, Palette.color(&"fire", 7))
	img.set_pixel(2, 0, Palette.color(&"skin", 2, true))
	img.set_pixel(3, 0, Color(0, 0, 0, 0))
	if not check_image(img, "ok").is_empty():
		fails.append("[DA autoprueba] una imagen de paleta no pasa")
	img.set_pixel(3, 0, Color("ff00ff"))
	if check_image(img, "mal").is_empty():
		fails.append("[DA autoprueba] no detecta un color fuera de paleta")
	# 2) miniatura: figura clara sobre fondo oscuro separa; figura igual al fondo no
	var bg := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	bg.fill(Palette.color(&"stone", 2))
	var fig := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	fig.fill(Palette.color(&"linen", 5))
	var sm: Array = compose(bg, fig, Vector2i(24, 20))
	if thumbnail_separation(sm[0], sm[1]) < MIN_SEPARATION:
		fails.append("[DA autoprueba] la miniatura no separa una figura clara")
	fig.fill(Palette.color(&"stone", 2))
	sm = compose(bg, fig, Vector2i(24, 20))
	if thumbnail_separation(sm[0], sm[1]) >= MIN_SEPARATION:
		fails.append("[DA autoprueba] la miniatura separa una figura invisible")
	return fails
