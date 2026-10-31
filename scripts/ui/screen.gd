class_name Screen
extends Control
## Base de todas las pantallas. `main` es el gestor raíz; `args` los parámetros de entrada.

var main: Node
var args: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	build()


## Sobrescribir: construir la UI de la pantalla.
func build() -> void:
	pass


## Área útil bajo el HUD superior.
func content_rect() -> Rect2:
	return Rect2(0, 52, 1280, 668)
