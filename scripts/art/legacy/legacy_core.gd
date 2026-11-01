extends "res://scripts/art/legacy/legacy_monster_data.gd"
## Arte LEGADO v0.3 (congelado) — Constantes de escena/pose, caché, iconos y operaciones de píxel (EPX, RotSprite, crouch/stretch).
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

## Posiciones (px de arte del fondo 320×180) de las antorchas del acto 1; ver torches(biome).
const TORCHES: Array[Vector2i] = [Vector2i(24, 70), Vector2i(86, 66), Vector2i(234, 66), Vector2i(296, 70)]
const FLOOR_Y := 118

## Poses de la heroína: [ángulo del brazo (rad, + = horario), dx cuerpo, dy cuerpo, estela desde (rad) o null]
const POSES := {
	"idle": [0.0, 0, 0, null],
	"windup": [2.45, -1, 1, null],
	"smear": [5.18, 1, 0, 2.2],
	"strike": [-1.55, 2, 0, null],
	"recover": [-0.75, 1, 0, null],
	"cast": [-2.6, 0, -1, null],
	"toss_back": [-0.9, 0, 0, null],
	"toss": [1.15, -1, 0, null],
	"hurt": [0.45, -2, 0, null],
}
const POSE_W := 52
const POSE_H := 48
const BODY_ORIGIN := Vector2i(14, 12)
const ARM_ATTACH := Vector2i(12, 16)     # dónde se pega el brazo sobre el cuerpo
const ARM_PIVOT := Vector2(3.5, 1.5)     # hombro dentro del sprite del brazo

var _cache := {}


func has_icon(id: String) -> bool:
	return SPRITES.has(id) or VARIANTS.has(id)


func has_shape(id: String) -> bool:
	var base := id.get_slice("@", 0)
	return SHAPES.has(base) or BASES.has(base)


func icon(id: String) -> Texture2D:
	var key := "i:" + id
	if _cache.has(key):
		return _cache[key]
	var t := ImageTexture.create_from_image(icon_image(id))
	_cache[key] = t
	return t


func icon_image(id: String) -> Image:
	if VARIANTS.has(id):
		var v: Array = VARIANTS[id]
		return image_from_rows(SPRITES[v[0]], v[1])
	if SPRITES.has(id):
		return image_from_rows(SPRITES[id])
	return image_from_rows(SPRITES["unknown"])


## Icono 24×24 suavizado con EPX (para ilustraciones y paneles a ×2 sin mezclar píxeles).
func icon_big(id: String) -> Texture2D:
	var key := "ib:" + id
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(scale2x(icon_image(id)))
	return _cache[key]


static func image_from_rows(rows: Array, remap: Dictionary = {}) -> Image:
	var h := rows.size()
	var w := String(rows[0]).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in mini(w, row.length()):
			var ch := row[x]
			if remap.has(ch):
				ch = remap[ch]
			if ch != "." and PAL.has(ch):
				img.set_pixel(x, y, PAL[ch])
	return img


static func dither(x: int, y: int, t: float) -> bool:
	return t * 16.0 > float(BAYER4[y % 4][x % 4]) + 0.5


## Escalado ×2 EPX/Scale2x: mantiene el contorno y suaviza diagonales sin inventar colores.
static func scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := src.get_pixel(x, y)
			var a := src.get_pixel(x, y - 1) if y > 0 else p
			var b := src.get_pixel(x + 1, y) if x < w - 1 else p
			var c := src.get_pixel(x - 1, y) if x > 0 else p
			var d := src.get_pixel(x, y + 1) if y < h - 1 else p
			var e0 := p
			var e1 := p
			var e2 := p
			var e3 := p
			if not c.is_equal_approx(b) and not a.is_equal_approx(d):
				if a.is_equal_approx(c):
					e0 = a
				if a.is_equal_approx(b):
					e1 = b
				if d.is_equal_approx(c):
					e2 = c
				if d.is_equal_approx(b):
					e3 = b
			out.set_pixel(x * 2, y * 2, e0)
			out.set_pixel(x * 2 + 1, y * 2, e1)
			out.set_pixel(x * 2, y * 2 + 1, e2)
			out.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return out


## Rotación tipo RotSprite simplificada: superresolución ×4 con EPX, giro al vecino y muestreo al centro.
## Devuelve {img, pivot} donde `pivot` es la posición (px) del pivote en la imagen girada.
static func rotate_sprite(src: Image, angle: float, pivot: Vector2) -> Dictionary:
	var big := scale2x(scale2x(src))
	var bw := big.get_width()
	var bh := big.get_height()
	var r := 0.0
	for c: Vector2 in [Vector2.ZERO, Vector2(src.get_width(), 0), Vector2(0, src.get_height()), Vector2(src.get_width(), src.get_height())]:
		r = maxf(r, c.distance_to(pivot))
	var R := int(ceil(r)) + 1
	var size := R * 2 + 1
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ca := cos(-angle)
	var sa := sin(-angle)
	for y in size:
		for x in size:
			# Centro del píxel destino relativo al pivote (en px de arte).
			var vx := float(x - R)
			var vy := float(y - R)
			var sx := vx * ca - vy * sa
			var sy := vx * sa + vy * ca
			var bx := int(floor((pivot.x + sx) * 4.0))
			var by := int(floor((pivot.y + sy) * 4.0))
			if bx < 0 or by < 0 or bx >= bw or by >= bh:
				continue
			var p := big.get_pixel(bx, by)
			if p.a > 0.0:
				out.set_pixel(x, y, p)
	return {"img": out, "pivot": Vector2(R, R)}


## Ruido por coordenada (movido aquí desde Escenarios: también lo usan las cartas).
func _hash2(x: int, y: int, s: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.17) * 43758.5453, 1.0)
