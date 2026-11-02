class_name RigDef
extends RefCounted
## Definición de un personaje/criatura para el motor de rig v1 (TEC · v0.4). DATOS PUROS: el render lo hace
## `RigRenderer`; las reglas, `RigLint`. Se escribe cómodo con `RigBuilder` (ver scripts/art/rig/examples/).
##
## Espacios: cada pieza y sello se define en el espacio de su HUESO (x a la derecha, y hacia abajo, z hacia el
## espectador). Los huesos sólo giran en el plano de pantalla (2D) y se desplazan en píxeles enteros.
## Lienzo: `size` píxeles; `origin` es el punto del lienzo donde va el pivote del hueso raíz.

# --------------------------------------------------------------------------------------------- tipos
class Bone:
	var name: StringName
	var parent: StringName = &""
	var pivot := Vector2.ZERO      # en el espacio del padre (o del lienzo para la raíz, relativo a `origin`)
	var z := 0.0                   # z relativa al padre
	var angle := 0.0               # ángulo de reposo (rad, + = horario en pantalla)


class Facet:
	var cell_area := 36.0          # px² por celda (DA: ≥ 24)
	var weight := 0.6              # 0 = normal suave, 1 = plano puro
	var crack := 0.0               # fracción de juntas que se vuelven emisivas
	var crack_slot: StringName = &""   # material (ranura) de la grieta emisiva


class MatSpec:
	var slot: StringName
	var palette: StringName        # material de `Palette`
	var facet: Facet = null        # sólo carbón, escoria, hielo (regla de DA)
	var texture: StringName = &"none"   # none | mortar | strands | folds | scratches | soot_grain
	var tex_fn: Callable           # opcional: func(local: Vector2, step: int, steps: int) -> int (nuevo paso)
	var spec := false              # brillo especular de 1–2 px en metales
	var planes := 3                # máx. planos de luz por masa > 12 px (DA)
	var rim := true                # luz de borde (bandera CANTO) en la silueta del lado cálido


class Piece:
	var id: StringName
	var bone: StringName
	var prim: StringName           # ell | cap | box | poly | slab
	var slot: StringName
	var p: Dictionary = {}         # parámetros de la primitiva (ver RigBuilder)
	var z := 0.0                   # sesgo de z
	var flat := 0.0                # aplanado 0..1 (normales hacia el espectador)
	var line := true               # genera línea interior con las piezas que tiene delante
	var ao := 1.0
	var tags: Array[StringName] = []   # face | hand | eye | rivet … (exigen sello en su hueso)
	var accessory: StringName = &""    # si no es vacío, sólo existe cuando el parámetro de variante es verdadero


class Stamp:
	var id: StringName
	var bone: StringName
	var at := Vector2.ZERO         # punto del hueso donde se clava el ancla del sello
	var anchor := Vector2i.ZERO    # píxel del sello que cae en `at`
	var rows: Array = []           # Array[String]; "." = transparente
	var views: Dictionary = {}     # {vista: rows}; la pose elige con "view:<hueso>"
	var legend: Dictionary = {}    # {char: [material|"@ranura", paso:int | "LINE" | "+1" | "-1"]}
	var flip := false
	var z_top := true              # siempre encima (si no, sólo sobre píxeles de su hueso)
	var accessory: StringName = &""


class MatMask:
	var slot_from: StringName
	var slot_to: StringName
	var mode: StringName = &"rise"   # rise: sube desde los pies · noise: manchas
	var param: StringName            # parámetro de variante 0..1
	var bones: Array[StringName] = []   # vacío = todas


class Smear:
	var bone: StringName
	var point := Vector2.ZERO      # punto del hueso que deja la estela (cara del martillo, puño)
	var slot: StringName
	var width := 6.0               # grosor máximo (en la cabeza de la estela)
	var front := true              # delante o detrás del cuerpo
	var samples := 0               # 0 = automático según la longitud del arco (sin puntos sueltos)


class Anim:
	var name: StringName
	var frames := 1
	var ms: Array[int] = [120]     # por fotograma (si hay uno solo, vale para todos)
	var loop := true
	var keys: Dictionary = {}      # {fotograma:int -> pose:Dictionary}; se interpola entre claves
	var interp: StringName = &"smooth"   # linear | smooth | hold
	var overlap: Dictionary = {}   # {hueso: retraso en fotogramas (float)} — seguimiento/arrastre
	var smears: Dictionary = {}    # {fotograma:int -> Smear}  (estela desde el fotograma anterior)


class Ik:
	var upper: StringName
	var lower: StringName
	var end := Vector2.ZERO        # efector en el espacio de `lower`
	var bend := 1                  # +1 / −1: lado al que dobla la articulación


class LightSpec:
	var warm_dir := Vector3(-0.70, -0.50, 0.50).normalized()   # la Forja: izquierda, arriba, delante
	var cold_dir := Vector3(0.75, -0.45, 0.45).normalized()    # la Torre: derecha, arriba
	var warm := 1.0
	var cold := 0.45
	var ambient := 0.12


class Part:
	var def: RigDef
	var offset := Vector2i.ZERO    # posición de la parte en el lienzo del jefe
	var phase := 0                 # desfase de bucles (fotogramas)


# --------------------------------------------------------------------------------------------- datos
var id: StringName
var group: StringName = &"creatures"   # creatures | hero | bosses | props
var size := Vector2i(96, 96)
var origin := Vector2i(48, 60)
var facing := -1                       # −1 mira a la izquierda (criaturas), +1 a la derecha (heroína)
var small := false                     # modo pequeño (< 32 px): mandan las losas ASCII, el rig sólo anima
var bones: Array[Bone] = []
var pieces: Array[Piece] = []
var stamps: Array[Stamp] = []
var materials: Dictionary = {}         # {ranura: MatSpec}
var masks: Array[MatMask] = []
var iks: Dictionary = {}               # {nombre: Ik}
var anims: Dictionary = {}             # {nombre: Anim}
var patches: Dictionary = {}           # {"anim:fotograma": Array[Stamp]}  (≤ 15 px por fotograma)
var sockets: Dictionary = {}           # {nombre: [hueso, Vector2]}  → metadatos para VFX/UI
var variants: Dictionary = {&"base": {}}   # {nombre: parámetros}  (accesorios, máscaras, fase de jefe)
var parts: Array[Part] = []            # jefes multiparte: cada parte se hornea por separado
var light := LightSpec.new()
var rng_seed := 1


func bone(name: StringName) -> Bone:
	for b in bones:
		if b.name == name:
			return b
	return null


func has_bone(name: StringName) -> bool:
	return bone(name) != null


func mat(slot: StringName) -> MatSpec:
	return materials.get(slot)


## Texto canónico de la definición (para depurar diferencias de horneado; el manifiesto usa el hash del código fuente).
func describe() -> String:
	return "%s %s %dx%d huesos=%d piezas=%d sellos=%d anims=%s" % [group, id, size.x, size.y, bones.size(),
		pieces.size(), stamps.size(), str(anims.keys())]
