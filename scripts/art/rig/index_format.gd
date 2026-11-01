class_name IndexFormat
extends RefCounted
## Formato de TEXTURA DE ÍNDICE v1 (TEC · v0.4). Único punto de empaquetado/desempaquetado: si el formato cambia,
## cambia aquí. Especificación completa: docs/reviews/v04/tecnico/formato_indice.md.
##
##   R = índice de material de la paleta maestra (`Palette.index`, 0 = void/contorno)
##   G = bits 0–3 PASO de rampa horneado (0–15; el paso 0 nunca se mueve: líneas y contornos)
##       bit 4 JUNTA     rehundida: la luz dinámica positiva le llega con un paso menos
##       bit 5 CANTO     arista/borde iluminable: +1 cuando la luz dinámica en su ancla es ≥ +1
##       bit 6 EMISIVO   ignora toda luz; sólo recibe el pulso emisivo global
##       bit 7 FRÍO      en el horneado dominó la luz fría → fila fría de la LUT
##   B = 128 + (ancla.x − x)   A = 128 + (ancla.y − y)   (ancla = centro de la PIEZA, desplazamiento ±127)
##   A = 0  ⇔  píxel vacío (transparente). Un píxel lleno nunca tiene A = 0.
## Archivos horneados: sufijo `_idx.png` (la prueba de paleta de DA los salta) + vista previa `_prev.png` en color.

const F_JOINT := 16
const F_BEVEL := 32
const F_EMISSIVE := 64
const F_COLD := 128
const STEP_MASK := 15
const MAX_OFFSET := 127


## Empaqueta un píxel. `anchor_d` = ancla − píxel (en píxeles de arte).
static func pack(material: int, step: int, flags: int, anchor_d: Vector2i) -> Color:
	var dx := clampi(anchor_d.x, -MAX_OFFSET, MAX_OFFSET)
	var dy := clampi(anchor_d.y, -MAX_OFFSET, MAX_OFFSET)
	return Color8(clampi(material, 0, 255), (clampi(step, 0, STEP_MASK)) | (flags & 0xF0), 128 + dx, 128 + dy)


static func is_empty(c: Color) -> bool:
	return c.a8 == 0


static func material_of(c: Color) -> int:
	return c.r8


static func step_of(c: Color) -> int:
	return c.g8 & STEP_MASK


static func flags_of(c: Color) -> int:
	return c.g8 & 0xF0


static func anchor_delta(c: Color) -> Vector2i:
	return Vector2i(c.b8 - 128, c.a8 - 128)


## Color de vista previa (luz dinámica 0): exactamente lo que dibuja `palette_lit.gdshader` sin luces.
static func preview_color(c: Color) -> Color:
	if is_empty(c):
		return Color(0, 0, 0, 0)
	var m := Palette.material_at(material_of(c))
	return Palette.color(m, step_of(c), (flags_of(c) & F_COLD) != 0)


static func preview(idx: Image) -> Image:
	var out := Image.create_empty(idx.get_width(), idx.get_height(), false, Image.FORMAT_RGBA8)
	for y in idx.get_height():
		for x in idx.get_width():
			var c := idx.get_pixel(x, y)
			if not is_empty(c):
				out.set_pixel(x, y, preview_color(c))
	return out


## Imagen de índice vacía (todo transparente) del tamaño dado.
static func blank(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## Errores de coherencia de una imagen de índice (lo usan las pruebas).
static func validate(idx: Image) -> Array[String]:
	var errs: Array[String] = []
	if idx.get_format() != Image.FORMAT_RGBA8:
		errs.append("formato %d (se esperaba RGBA8)" % idx.get_format())
		return errs
	for y in idx.get_height():
		for x in idx.get_width():
			var c := idx.get_pixel(x, y)
			if is_empty(c):
				continue
			var mi := material_of(c)
			if mi >= Palette.count():
				errs.append("(%d,%d): material %d fuera de la paleta" % [x, y, mi])
			elif step_of(c) >= Palette.steps(Palette.material_at(mi), (flags_of(c) & F_COLD) != 0):
				errs.append("(%d,%d): paso %d fuera de la rampa %s" % [x, y, step_of(c), Palette.material_at(mi)])
			if errs.size() > 20:
				return errs
	return errs
