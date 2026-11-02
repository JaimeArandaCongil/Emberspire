class_name BgRamps
extends RefCounted
## Materiales de los fondos (MV) sobre la paleta maestra de DA (`Palette`). Aquí sólo hay un enum corto para que
## el generador sea legible; el color y el índice de material salen SIEMPRE de `Palette` (nadie escribe hex).
## La luz fría no es un material: es la rampa fría de cada material (`cold = true`).

enum {EMPTY = 0, BRICK = 1, STONE = 2, IRON = 3, COPPER = 4, WOOD = 5, ASH = 6, SKY = 7, FIRE = 8, CLOTH = 9, FURNACE = 10, COAL = 11}

const NAMES: Array[StringName] = [&"void", &"brick", &"stone", &"iron", &"copper", &"wood", &"ash", &"sky", &"fire", &"cloth", &"furnace_brick", &"coal"]


static func pal_name(m: int) -> StringName:
	return NAMES[m]


## Índice de material de la paleta (canal R de la textura de índice).
static func pal_index(m: int) -> int:
	return Palette.index(NAMES[m])


static func color(m: int, step: int, cold: bool = false) -> Color:
	return Palette.color(NAMES[m], step, cold)


static func steps(m: int, cold: bool = false) -> int:
	return Palette.steps(NAMES[m], cold)


static func is_emissive(m: int) -> bool:
	return Palette.is_emissive(NAMES[m])
