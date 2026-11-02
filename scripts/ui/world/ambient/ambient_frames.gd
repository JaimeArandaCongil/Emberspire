class_name AmbientFrames
extends RefCounted
## Fotogramas de las animaciones ambientales (MV · v0.4), generados una vez y cacheados. Todo en píxeles de arte
## (rejilla 640×360). Cada fotograma se pinta en formato ÍNDICE (`IndexFormat`), de modo que con `palette_lit` recibe la
## luz de la escena (el hierro del crisol reacciona a la onda de quemar; las llamas, al pulso emisivo). `index = false`
## devuelve la versión en color para la vista previa sin shader.
##   flame(k, lean)   llama de brasero 27×40, 8 fotogramas (100 ms), 4 lenguas; `lean` = inclinada hacia el horno (quemar)
##   smoke(k)         columna de humo 30×56, 8 fotogramas, 6 bocanadas que derivan y se deshacen
##   crucible(k, amp) cadena + crisol, 16 posiciones de péndulo (110 ms)

const FLAME_W := 27
const FLAME_H := 40
const FLAME_BASE := Vector2i(13, 38)   # punto del lecho de brasas dentro del fotograma
const SMOKE_W := 30
const SMOKE_H := 56
const SMOKE_BASE := Vector2i(8, 55)

static var _cache := {}
static var _previews: Array[Image] = []


static func _h(x: int, y: int, s: int) -> float:
	return BgCanvas.hash3(x, y, s)


## Pinta en un fotograma de índice. `anchor` = ancla de la pieza dentro del fotograma (-1 = el propio píxel).
static func _put(img: Image, x: int, y: int, mat: StringName, step: int, anchor := Vector2i(-1, -1)) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var fl := IndexFormat.F_EMISSIVE if Palette.is_emissive(mat) else 0
	var d := Vector2i.ZERO if anchor.x < 0 else anchor - Vector2i(x, y)
	img.set_pixel(x, y, IndexFormat.pack(Palette.index(mat), clampi(step, 0, Palette.steps(mat) - 1), fl, d))


static func _store(key: String, idx: Image, index: bool) -> ImageTexture:
	var pre := IndexFormat.preview(idx)
	_previews.append(pre)
	_cache[key + ":1"] = ImageTexture.create_from_image(idx)
	_cache[key + ":0"] = ImageTexture.create_from_image(pre)
	return _cache[key + (":1" if index else ":0")]


static func flame(k: int, lean: int = 0, size: float = 1.0, index := false) -> ImageTexture:
	var key := "fl:%d:%d:%d" % [k % 8, lean, int(size * 10.0)]
	var ck := key + (":1" if index else ":0")
	if _cache.has(ck):
		return _cache[ck]
	var img := IndexFormat.blank(FLAME_W, FLAME_H)
	var ph := float(k % 8) / 8.0
	var bx := FLAME_BASE.x
	var by := FLAME_BASE.y
	for yy in range(-38, 1):
		for xx in range(-13, 14):
			var hgt := clampf(-yy / 38.0, 0.0, 1.0)
			# La inclinación crece con la altura (el tiro del horno aspira la llama).
			var sx := float(xx) - float(lean) * hgt * hgt * 7.0
			var dy := float(yy) + 5.0
			var ry := (9.0 if dy < 0.0 else 5.5) * size
			var f := 1.0 - Vector2(sx / (7.2 * size), dy / ry).length()
			for j in 4:
				var p := fposmod(ph + j / 4.0, 1.0)
				var ty := (-7.0 - p * 26.0) * size
				var tx := sin(p * TAU + j * 1.7) * 2.6 + (j - 1.5) * 1.4 * (1.0 - p)
				var tr := (5.2 * (1.0 - p) + 1.4) * size
				var d := Vector2((sx - tx) / tr, (yy - ty) / (tr * 1.7)).length()
				f = maxf(f, (1.0 - d) * (1.0 - p * 0.35))
			if f <= 0.0:
				continue
			var lowness := clampf((yy + 34.0) / 34.0, 0.0, 1.0)
			var hv := f * (0.55 + 0.45 * lowness)
			var v := 2
			if hv > 0.64:
				v = 7
			elif hv > 0.5:
				v = 6
			elif hv > 0.36:
				v = 5
			elif hv > 0.22:
				v = 4
			elif hv > 0.09:
				v = 3
			_put(img, bx + xx, by + yy, &"fire", v)
	return _store(key, img, index)


static func smoke(k: int, density: int = 0, index := false) -> ImageTexture:
	var key := "sm:%d:%d" % [k % 8, density]
	var ck := key + (":1" if index else ":0")
	if _cache.has(ck):
		return _cache[ck]
	var img := IndexFormat.blank(SMOKE_W, SMOKE_H)
	var order: Array = []
	for j in 6:
		order.append([fposmod(float(k % 8) / 8.0 + j / 6.0, 1.0), j])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for e: Array in order:
		var p: float = e[0]
		var j: int = e[1]
		var cy := int(roundf(SMOKE_BASE.y - 2.0 - p * 46.0))
		var cx := int(roundf(SMOKE_BASE.x + p * p * 12.0 + sin(p * 4.0 + j) * 2.4))
		# Al envejecer la bocanada crece y luego ADELGAZA: se deshace por el borde, nunca con huecos por dentro.
		var r := (2.4 + minf(p, 0.6) * 5.6 + density * 0.8) * (1.0 - maxf(0.0, p - 0.6) * 1.6)
		var anc := Vector2i(cx, cy)
		for dy in range(-10, 11):
			for dx in range(-10, 11):
				var d := Vector2(dx, dy * 0.75).length()
				if d > r:
					continue
				if p > 0.5 and d > r - 1.5 and _h(dx + 11, dy + 11, j + 9) < (p - 0.5) * 1.6:
					continue
				if dy > 0 and d > r - 1.6 and p < 0.6:
					_put(img, cx + dx, cy + dy, &"brick", 5, anc)      # borde inferior lamido por la llama
				else:
					var v := (4 if p < 0.45 else 3) + density
					if dy < 0 and dx < 0 and d > r - 1.6:
						v += 1
					_put(img, cx + dx, cy + dy, &"ash", v, anc)
	return _store(key, img, index)


## Desplazamiento horizontal (px de arte) del crisol en la posición k de 16.
static func crucible_dx(k: int, amp: int = 7) -> int:
	return int(roundf(float(amp) * sin(TAU * float(k % 16) / 16.0)))


## Cadena + crisol. El centro del fotograma en x es el pivote. Redibujado por posición (sin rotar sprites).
static func crucible(k: int, ln: int, amp: int = 7, glow: int = 0, index := false) -> ImageTexture:
	var key := "cr:%d:%d:%d:%d" % [k % 16, ln, amp, glow]
	var ck := key + (":1" if index else ":0")
	if _cache.has(ck):
		return _cache[ck]
	var w := 2 * (amp + 14)
	var hh := ln + 22
	var img := IndexFormat.blank(w, hh)
	var ox := w / 2
	var dxb := crucible_dx(k, amp)
	var cx := ox + dxb
	var top := ln
	var body_anchor := Vector2i(cx, top + 10)
	for t in range(0, ln):
		var x := ox + int(roundf(float(dxb) * t / ln))
		var ph := t % 10
		var link := Vector2i(x, t / 10 * 10 + 4)
		if ph < 7:
			if ph == 0 or ph == 6:
				_put(img, x, t, &"iron", 2, link)
			else:
				_put(img, x - 1, t, &"iron", 4, link)
				_put(img, x + 1, t, &"iron", 1, link)
		else:
			_put(img, x, t, &"iron", 3, link)
	for p: Vector2i in [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 2), Vector2i(2, 2), Vector2i(-3, 3),
			Vector2i(3, 3), Vector2i(-4, 4), Vector2i(4, 4), Vector2i(-5, 5), Vector2i(5, 5)]:
		_put(img, cx + p.x, top + p.y, &"iron", 5 if p.x <= 0 else 2, body_anchor)
	var body := [[8, 6], [8, 7], [8, 8], [8, 9], [7, 10], [7, 11], [6, 12], [5, 13], [4, 14], [2, 15]]
	for r: Array in body:
		var hw: int = r[0]
		var y: int = top + int(r[1])
		for x in range(-hw, hw + 1):
			var v := 3
			if x <= -hw + 1:
				v = 5
			elif x >= hw - 1:
				v = 1
			elif x > 1:
				v = 2
			_put(img, cx + x, y, &"iron", v, body_anchor)
	# Metal fundido: superficie que pulsa (2 tonos) y una grieta encendida en el cuerpo.
	var g := 5 + ((k / 2) % 2) + glow
	for x in range(-7, 8):
		_put(img, cx + x, top + 6, &"fire", clampi(g if absi(x) < 5 else g - 1, 0, 7))
	_put(img, cx - 2, top + 9, &"fire", 4)
	_put(img, cx - 3, top + 10, &"fire", 3)
	_put(img, cx - 3, top + 11, &"fire", 3)
	return _store(key, img, index)


## Vistas previas generadas hasta ahora (para la prueba de paleta cerrada).
static func images() -> Array[Image]:
	return _previews


static func clear_cache() -> void:
	_cache.clear()
	_previews.clear()
