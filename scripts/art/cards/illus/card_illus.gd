class_name CardIllus
extends RefCounted
## Registro de ilustraciones de carta v0.4 (68×46 nativos, se muestran a ×2 dentro de la ventana del marco).
##
## GRAMÁTICA (docs/reviews/v04/cartas_ui/propuesta.md §4): ilustración = FONDO (`IllusBg`, decorado reutilizable
## con su luz como parámetro) + LUZ (una fuente clave motivada) + SUJETO (`IllusSubj` o sprite propio) + FX
## (estela, chispas, humo, vapor) + ENCUADRE (máscara de ventana por tipo, la aplica `CardFrame`).
## Regla C5: ninguna carta repite la combinación fondo + encuadre + sujeto + posición.
##
## Tandas implementadas: `set_base.gd` (mazo inicial + 8 del Grimorio Base). Las demás cartas usan `fallback()`
## (composición provisional: fondo por tipo + icono v0.3) hasta que llegue su tanda.

const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const _Bg := preload("res://scripts/art/cards/illus/backdrops.gd")
const _Pal := preload("res://scripts/art/cards/card_pal.gd")
const _SetBase := preload("res://scripts/art/cards/illus/set_base.gd")
const _SetPyre := preload("res://scripts/art/cards/illus/set_pyre.gd")
const W := 68
const H := 46

static var _img_cache := {}
static var _tex_cache := {}


static func has(id: String) -> bool:
	return _SetBase.IDS.has(id) or _SetPyre.IDS.has(id)


static func ids() -> Array[String]:
	var out: Array[String] = []
	out.append_array(_SetBase.IDS)
	out.append_array(_SetPyre.IDS)
	return out


## Imagen nativa 68×46 (en paleta) de la carta; si no tiene ilustración propia, la provisional.
static func image(id: String, type: String = "attack", icon: String = "") -> Image:
	var key := id + ":" + type
	if _img_cache.has(key):
		return _img_cache[key]
	var img: Image = null
	if _SetBase.IDS.has(id):
		img = _SetBase.build(id)
	elif _SetPyre.IDS.has(id):
		img = _SetPyre.build(id)
	if img == null:
		img = fallback(type, icon)
	_img_cache[key] = img
	return img


## Provisional: fondo por tipo + icono v0.3 ajustado a la paleta. Sólo para cartas aún sin tanda.
static func fallback(type: String, icon: String) -> Image:
	var img := _Px.new_img()
	match type:
		"attack":
			_Bg.forge_dark(img, Vector2(34, 30), 38.0)
		"skill":
			_Bg.tower_wall(img, Vector2(34, 20), 40.0, -1.0, 0.08, 7)
		"fuel":
			_Bg.furnace_mouth(img, Vector2(34, 44), 30.0, 37.0)
		"power":
			for y in H:
				for x in W:
					img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"magic", 0, 2), 0.8 - y / 60.0 - absf(x - 34) / 120.0, x, y))
		_:
			for y in H:
				for x in W:
					img.set_pixel(x, y, _Px.ramp_pick(_Px.R(&"ash", 1, 4), 0.5 - y / 90.0, x, y))
	if icon != "" and Engine.get_main_loop() != null:
		var art: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Art")
		if art != null and art.has_method("icon_image") and art.has_method("has_icon") and art.call("has_icon", icon):
			var ic: Image = art.call("icon_image", icon)
			ic = ic.duplicate() as Image
			ic.convert(Image.FORMAT_RGBA8)
			ic.resize(ic.get_width() * 2, ic.get_height() * 2, Image.INTERPOLATE_NEAREST)
			for y in ic.get_height():
				for x in ic.get_width():
					var p := ic.get_pixel(x, y)
					if p.a > 0.0:
						ic.set_pixel(x, y, _Pal.snap(Color(p, 1.0)))
			var ox := (W - ic.get_width()) / 2
			var oy := (H - ic.get_height()) / 2
			for y in ic.get_height():
				for x in ic.get_width():
					if ic.get_pixel(x, y).a > 0.0:
						_Px.put(img, ox + x + 2, oy + y + 2, _Px.ink())
			_Px.blit(img, _Px.outline(ic, _Px.ink()), ox, oy)
	return img
