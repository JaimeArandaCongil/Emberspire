class_name WorldView
extends SubViewportContainer
## Mundo a resolución de arte (TEC · v0.4): SubViewport de 640×360 mostrado a ×2 en la ventana de 1280×720, con la
## interfaz encima a resolución completa. Todo lo que vive dentro queda en la rejilla de arte (imposible un píxel
## fuera de rejilla). Trae su propio `LightRig` (luz de escena para `palette_lit`).
##
##   var wv := WorldView.new()
##   add_child(wv)                          # ocupa la ventana (o coloca/dimensiona el contenedor: debe ser 1280×720)
##   wv.world.add_child(sprite)             # coordenadas de MUNDO (px de arte, 640×360)
##   label.position = wv.world_to_ui(Vector2(466, 140))     # para colocar UI sobre el mundo
##   var p := wv.ui_to_world(get_global_mouse_position())   # para elegir objetivos con el ratón
##   wv.lights.burn()                       # onda de quemar carta
## Conversión: ui = posición_global_del_contenedor + mundo × SCALE (y a la inversa); todo en enteros.

const WORLD_SIZE := Vector2i(640, 360)
const SCALE := 2

var viewport: SubViewport
## Raíz de los nodos del mundo (Node2D en coordenadas de arte).
var world: Node2D
var lights: LightRig
## Material compartido para sprites de índice (texturas `_idx.png`).
var lit_material: ShaderMaterial


func _init() -> void:
	stretch = true
	stretch_shrink = SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WORLD_SIZE * SCALE)
	viewport = SubViewport.new()
	viewport.name = "World"
	viewport.size = WORLD_SIZE
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.handle_input_locally = false
	viewport.gui_disable_input = true
	add_child(viewport)
	world = Node2D.new()
	world.name = "Root"
	viewport.add_child(world)
	lights = LightRig.new()
	lights.name = "LightRig"
	viewport.add_child(lights)
	lit_material = make_lit_material()


func _ready() -> void:
	# El tamaño del contenedor fija el del SubViewport (stretch): se fuerza 1280×720 para el ×2 exacto.
	size = Vector2(WORLD_SIZE * SCALE)


static func make_lit_material() -> ShaderMaterial:
	LightRig.ensure_globals()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/palette_lit.gdshader")
	return m


## Mundo (px de arte) → coordenadas globales de lienzo de la interfaz.
func world_to_ui(p: Vector2) -> Vector2:
	return global_position + (p * SCALE).floor()


## Coordenadas globales de la interfaz → mundo (px de arte, redondeado hacia abajo).
func ui_to_world(p: Vector2) -> Vector2:
	return ((p - global_position) / SCALE).floor()


func world_rect_to_ui(r: Rect2) -> Rect2:
	return Rect2(world_to_ui(r.position), r.size * SCALE)


func ui_rect_to_world(r: Rect2) -> Rect2:
	return Rect2(ui_to_world(r.position), (r.size / SCALE).floor())


## ¿Está el punto de mundo dentro del lienzo?
static func in_world(p: Vector2) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < WORLD_SIZE.x and p.y < WORLD_SIZE.y


## Crea un AnimatedSprite2D con una hoja horneada (índices + palette_lit), con respaldo a la vista previa en color.
func make_baked_sprite(id: StringName, anim: StringName = &"idle", variant: StringName = &"") -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.centered = false
	s.sprite_frames = SpriteBank.sprite_frames(id, true, variant)
	s.material = lit_material
	if s.sprite_frames.has_animation(anim):
		s.play(anim)
	return s
