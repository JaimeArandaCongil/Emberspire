class_name AmbientFrames
extends RefCounted
## Fotogramas de las animaciones ambientales (MV · v0.4), generados una vez y cacheados. Todo en píxeles de arte
## (rejilla 640×360) y sólo con colores de `Palette`. Se dibujan a escala entera por el nodo padre.
##   flame(k, lean)   llama de brasero 27×40, 8 fotogramas (100 ms), 4 lenguas; `lean` = inclinada hacia el horno (quemar)
##   smoke(k)         columna de humo 30×56, 8 fotogramas, 6 bocanadas que derivan y se deshacen
##   crucible(k, amp) cadena + crisol 24×(len+20), 16 posiciones de péndulo (110 ms)

const FLAME_W := 27
const FLAME_H := 40
const FLAME_BASE := Vector2i(13, 38)   # punto del lecho de brasas dentro del fotograma
const SMOKE_W := 30
const SMOKE_H := 56
const SMOKE_BASE := Vector2i(8, 55)

static var _cache := {}
static var _images: Array[Image] = []


static func _fire(step: int) -> Color:
	return Palette.color(&"fire", step)


static func _h(x: int, y: int, s: int) -> float:
	return BgCanvas.hash3(x, y, s)


static func flame(k: int, lean: int = 0, size: float = 1.0) -> ImageTexture:
	var key := "fl:%d:%d:%d" % [k % 8, lean, int(size * 10.0)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(FLAME_W, FLAME_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
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
			var px := bx + xx
			var py := by + yy
			if px >= 0 and py >= 0 and px < FLAME_W and py < FLAME_H:
				img.set_pixel(px, py, _fire(v))
	_images.append(img)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func smoke(k: int, density: int = 0) -> ImageTexture:
	var key := "sm:%d:%d" % [k % 8, density]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(SMOKE_W, SMOKE_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
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
		for dy in range(-10, 11):
			for dx in range(-10, 11):
				var d := Vector2(dx, dy * 0.75).length()
				if d > r:
					continue
				if p > 0.5 and d > r - 1.5 and _h(dx + 11, dy + 11, j + 9) < (p - 0.5) * 1.6:
					continue
				var c: Color
				if dy > 0 and d > r - 1.6 and p < 0.6:
					c = Palette.color(&"brick", 5)      # borde inferior lamido por la llama
				else:
					var v := (4 if p < 0.45 else 3) + density
					if dy < 0 and dx < 0 and d > r - 1.6:
						v += 1
					c = Palette.color(&"ash", v)
				var px := cx + dx
				var py := cy + dy
				if px >= 0 and py >= 0 and px < SMOKE_W and py < SMOKE_H:
					img.set_pixel(px, py, c)
	_images.append(img)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Desplazamiento horizontal (px de arte) del crisol en la posición k de 16.
static func crucible_dx(k: int, amp: int = 7) -> int:
	return int(roundf(float(amp) * sin(TAU * float(k % 16) / 16.0)))


## Cadena + crisol. El origen del fotograma es (12, 0) = pivote. Redibujado por posición (sin rotar sprites).
static func crucible(k: int, ln: int, amp: int = 7, glow: int = 0) -> ImageTexture:
	var key := "cr:%d:%d:%d:%d" % [k % 16, ln, amp, glow]
	if _cache.has(key):
		return _cache[key]
	var w := 2 * (amp + 14)
	var hh := ln + 22
	var img := Image.create_empty(w, hh, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ox := w / 2
	var dxb := crucible_dx(k, amp)
	var iron := func(s: int) -> Color: return Palette.color(&"iron", s)
	for t in range(0, ln):
		var x := ox + int(roundf(float(dxb) * t / ln))
		var ph := t % 10
		if ph < 7:
			if ph == 0 or ph == 6:
				_px(img, x, t, iron.call(2))
			else:
				_px(img, x - 1, t, iron.call(4))
				_px(img, x + 1, t, iron.call(1))
		else:
			_px(img, x, t, iron.call(3))
	var cx := ox + dxb
	var top := ln
	for p: Vector2i in [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 2), Vector2i(2, 2), Vector2i(-3, 3),
			Vector2i(3, 3), Vector2i(-4, 4), Vector2i(4, 4), Vector2i(-5, 5), Vector2i(5, 5)]:
		_px(img, cx + p.x, top + p.y, iron.call(5 if p.x <= 0 else 2))
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
			_px(img, cx + x, y, iron.call(v))
	# Metal fundido: superficie que pulsa (2 tonos) y una grieta encendida en el cuerpo.
	var g := 5 + ((k / 2) % 2) + glow
	for x in range(-7, 8):
		_px(img, cx + x, top + 6, _fire(clampi(g if absi(x) < 5 else g - 1, 0, 7)))
	_px(img, cx - 2, top + 9, _fire(4))
	_px(img, cx - 3, top + 10, _fire(3))
	_px(img, cx - 3, top + 11, _fire(3))
	_images.append(img)
	var t2 := ImageTexture.create_from_image(img)
	_cache[key] = t2
	return t2


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Imágenes generadas hasta ahora (para la prueba de paleta cerrada).
static func images() -> Array[Image]:
	return _images


static func clear_cache() -> void:
	_cache.clear()
	_images.clear()
