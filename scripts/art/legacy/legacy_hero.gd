extends "res://scripts/art/legacy/legacy_core.gd"
## Arte LEGADO v0.3 (congelado) — Heroína: reposo y poses compuestas con brazo girado al generar.
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

# --- Heroína -------------------------------------------------------------------

## Heroína en reposo (24×36, brazo incluido). Para pantallas de menú.
func player() -> Texture2D:
	var key := "player_idle_small"
	if not _cache.has(key):
		var img := image_from_rows(SPRITES["player"])
		var arm := image_from_rows(SPRITES["player_arm"])
		img.blend_rect(arm, Rect2i(0, 0, arm.get_width(), arm.get_height()), ARM_ATTACH)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


## Obsoleto: el brazo ya va incluido en player(). Devuelve una textura vacía.
func player_arm() -> Texture2D:
	if not _cache.has("player_arm_empty"):
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		_cache["player_arm_empty"] = ImageTexture.create_from_image(img)
	return _cache["player_arm_empty"]


## Fotograma de la heroína en un lienzo fijo POSE_W×POSE_H (pies en la última fila).
func player_pose(pose: String) -> Texture2D:
	var key := "pp:" + pose
	if _cache.has(key):
		return _cache[key]
	var img: Image
	if pose == "idle_b":
		img = crouch_image(player_pose("idle").get_image(), BODY_ORIGIN.y + 21)
	else:
		img = _compose_pose(POSES.get(pose, POSES["idle"]))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


func _compose_pose(p: Array) -> Image:
	var canvas := Image.create(POSE_W, POSE_H, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var body := image_from_rows(SPRITES["player"])
	var bo := BODY_ORIGIN + Vector2i(int(p[1]), int(p[2]))
	canvas.blend_rect(body, Rect2i(0, 0, body.get_width(), body.get_height()), bo)
	var arm := image_from_rows(SPRITES["player_arm"])
	var angle: float = p[0]
	var shoulder := Vector2(bo) + Vector2(ARM_ATTACH) + ARM_PIVOT
	if p[3] != null:
		_draw_smear(canvas, shoulder, float(p[3]), angle)
	if absf(angle) < 0.01:
		canvas.blend_rect(arm, Rect2i(0, 0, arm.get_width(), arm.get_height()), bo + ARM_ATTACH)
	else:
		var r := rotate_sprite(arm, angle, ARM_PIVOT)
		var ri: Image = r["img"]
		var pv: Vector2 = r["pivot"]
		var dst := Vector2i(int(round(shoulder.x - pv.x - 0.5)), int(round(shoulder.y - pv.y - 0.5)))
		canvas.blend_rect(ri, Rect2i(0, 0, ri.get_width(), ri.get_height()), dst)
	return canvas


## Estela del martillo: arco de 2 px en amarillo→blanco entre dos ángulos.
func _draw_smear(canvas: Image, shoulder: Vector2, a0: float, a1: float) -> void:
	var steps := 40
	for i in steps + 1:
		var t := float(i) / steps
		var a := lerpf(a0, a1, t)
		for rr: float in [15.5, 16.5, 17.5, 18.5]:
			var v: Vector2 = Vector2(-sin(a), cos(a)) * rr
			var px := int(floor(shoulder.x + v.x))
			var py := int(floor(shoulder.y + v.y))
			if px < 0 or py < 0 or px >= POSE_W or py >= POSE_H:
				continue
			if canvas.get_pixel(px, py).a > 0.0:
				continue
			var c: Color = PAL["Y"] if t > 0.55 else (PAL["w"] if t > 0.25 else PAL["y"])
			if rr > 18.0 or rr < 16.0:
				c = PAL["o"] if t > 0.4 else PAL["r"]
			canvas.set_pixel(px, py, c)


## Aplasta 1 px: elimina la fila `row` y baja todo lo de arriba (respiración, anticipación).
static func crouch_image(src: Image, row: int) -> Image:
	var img := src.duplicate() as Image
	var w := img.get_width()
	for y in range(row, 0, -1):
		for x in w:
			img.set_pixel(x, y, src.get_pixel(x, y - 1))
	for x in w:
		img.set_pixel(x, 0, Color(0, 0, 0, 0))
	return img


## Estira 1 px: duplica la fila `row` subiendo todo lo de arriba (la fila 0 debe estar vacía).
static func stretch_image(src: Image, row: int) -> Image:
	var img := src.duplicate() as Image
	var w := img.get_width()
	for y in range(0, row):
		for x in w:
			img.set_pixel(x, y, src.get_pixel(x, y + 1))
	return img
