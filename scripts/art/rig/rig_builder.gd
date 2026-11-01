class_name RigBuilder
extends RefCounted
## Escritura cómoda de un `RigDef` (TEC · v0.4). Todas las llamadas devuelven el objeto creado para retocarlo.
##
##   var b := RigBuilder.new(&"golem_hollin", Vector2i(96, 96), Vector2i(52, 58))
##   b.material(&"body", &"coal", {facet = {cell_area = 40, weight = 0.6}})
##   b.bone(&"root", &"", Vector2.ZERO)
##   b.bone(&"spine", &"root", Vector2(1, -1), {angle = -0.3})
##   b.ell(&"torso", &"spine", &"body", Vector3(2, -13, 0), Vector3(14, 13, 11), {flat = 0.35})
##   b.stamp(&"face", &"head", Vector2(-8, -2), ["kkk", "kEk"], {"k": [&"@body", "LINE"], "E": [&"hot", 4]})
##   b.anim(&"idle", 8, 140, {0: {}, 4: {&"spine": -0.28, &"@root": Vector2i(0, 1)}})
##   return b.def
##
## Claves de POSE (en `anim()` y `key()`):
##   <hueso>: float           ángulo (rad) SUMADO al de reposo
##   &"@root": Vector2i       desplazamiento entero del hueso raíz
##   &"z:<hueso>": float      z animable (pasar el brazo detrás de la cabeza)
##   &"ik:<cadena>": Vector2  objetivo de IK de 2 huesos en el lienzo (pies plantados, mano en el mango)
##   &"view:<hueso>": StringName   vista de los sellos de ese hueso (34 | profile | back …)
##   &"emit:<sello|pieza>": int    desplazamiento de paso de un emisivo (fogón, ojos, puerta del horno)
##   &"hide:<pieza|sello>": bool   oculta una pieza o sello en esa clave

var def: RigDef


func _init(id: StringName, size: Vector2i, origin: Vector2i, facing := -1, group: StringName = &"creatures") -> void:
	def = RigDef.new()
	def.id = id
	def.size = size
	def.origin = origin
	def.facing = facing
	def.group = group


# ------------------------------------------------------------------------------------- materiales
## opts: facet {cell_area, weight, crack, crack_slot}, texture, tex_fn, spec, planes, rim
func material(slot: StringName, palette: StringName, opts := {}) -> RigDef.MatSpec:
	var m := RigDef.MatSpec.new()
	m.slot = slot
	m.palette = palette
	if opts.has("facet"):
		var f := RigDef.Facet.new()
		var fo: Dictionary = opts["facet"]
		f.cell_area = fo.get("cell_area", 36.0)
		f.weight = fo.get("weight", 0.6)
		f.crack = fo.get("crack", 0.0)
		f.crack_slot = fo.get("crack_slot", &"")
		m.facet = f
	m.texture = opts.get("texture", &"none")
	if opts.has("tex_fn"):
		m.tex_fn = opts["tex_fn"]
	m.spec = opts.get("spec", false)
	m.planes = opts.get("planes", 3)
	m.rim = opts.get("rim", true)
	def.materials[slot] = m
	return m


## Máscara de cambio de material por parámetro (hollín que sube, escarcha según PV…).
func mask(slot_from: StringName, slot_to: StringName, param: StringName, mode: StringName = &"rise", bones: Array[StringName] = []) -> RigDef.MatMask:
	var mm := RigDef.MatMask.new()
	mm.slot_from = slot_from
	mm.slot_to = slot_to
	mm.param = param
	mm.mode = mode
	mm.bones = bones
	def.masks.append(mm)
	return mm


# ------------------------------------------------------------------------------------- esqueleto
func bone(name: StringName, parent: StringName, pivot: Vector2, opts := {}) -> RigDef.Bone:
	var b := RigDef.Bone.new()
	b.name = name
	b.parent = parent
	b.pivot = pivot
	b.z = opts.get("z", 0.0)
	b.angle = opts.get("angle", 0.0)
	def.bones.append(b)
	return b


func ik(name: StringName, upper: StringName, lower: StringName, end: Vector2, bend := 1) -> RigDef.Ik:
	var k := RigDef.Ik.new()
	k.upper = upper
	k.lower = lower
	k.end = end
	k.bend = bend
	def.iks[name] = k
	return k


func socket(name: StringName, bone_name: StringName, at: Vector2) -> void:
	def.sockets[name] = [bone_name, at]


# ------------------------------------------------------------------------------------- piezas
func _piece(id: StringName, bone_name: StringName, prim: StringName, slot: StringName, p: Dictionary, opts: Dictionary) -> RigDef.Piece:
	var pc := RigDef.Piece.new()
	pc.id = id
	pc.bone = bone_name
	pc.prim = prim
	pc.slot = slot
	pc.p = p
	pc.z = opts.get("z", 0.0)
	pc.flat = opts.get("flat", 0.0)
	pc.line = opts.get("line", true)
	pc.ao = opts.get("ao", 1.0)
	var tg: Array = opts.get("tags", [])
	for t in tg:
		pc.tags.append(StringName(t))
	pc.accessory = opts.get("accessory", &"")
	def.pieces.append(pc)
	return pc


## Elipsoide: centro y radios en el espacio del hueso.
func ell(id: StringName, bone_name: StringName, slot: StringName, center: Vector3, radii: Vector3, opts := {}) -> RigDef.Piece:
	return _piece(id, bone_name, &"ell", slot, {"c": center, "r": radii}, opts)


## Cápsula cónica de `a` a `b` con radios `ra` → `rb`.
func cap(id: StringName, bone_name: StringName, slot: StringName, a: Vector3, b: Vector3, ra: float, rb: float, opts := {}) -> RigDef.Piece:
	return _piece(id, bone_name, &"cap", slot, {"a": a, "b": b, "ra": ra, "rb": rb}, opts)


## Caja biselada: centro, medidas (ancho, alto, fondo) y bisel en px.
func box(id: StringName, bone_name: StringName, slot: StringName, center: Vector3, dims: Vector3, bevel := 2.0, opts := {}) -> RigDef.Piece:
	return _piece(id, bone_name, &"box", slot, {"c": center, "d": dims, "bevel": bevel}, opts)


## Polígono plano con bisel (martillo, placas, puertas). `height` = relieve en z del centro.
func poly(id: StringName, bone_name: StringName, slot: StringName, pts: PackedVector2Array, z0 := 0.0, bevel := 2.0, height := 3.0, opts := {}) -> RigDef.Piece:
	return _piece(id, bone_name, &"poly", slot, {"pts": pts, "z0": z0, "bevel": bevel, "h": height}, opts)


## Losa: silueta ASCII a mano extruida con bisel. `legend` {char: ranura | [ranura, paso_forzado]}.
## Con pasos forzados es el "modo pequeño": la losa manda y el rig sólo la mueve.
func slab(id: StringName, bone_name: StringName, rows: Array, top_left: Vector2, legend: Dictionary, z0 := 0.0, bevel := 2.0, height := 3.0, opts := {}) -> RigDef.Piece:
	var first_slot: StringName = &""
	for v in legend.values():
		first_slot = StringName(v[0]) if v is Array else StringName(v)
		break
	return _piece(id, bone_name, &"slab", first_slot, {"rows": rows, "tl": top_left, "legend": legend, "z0": z0, "bevel": bevel, "h": height}, opts)


# ------------------------------------------------------------------------------------- sellos
## legend {char: [material|"@ranura", paso|"LINE"|"+1"|"-1"]}; opts: anchor, views, flip, z_top, accessory
func stamp(id: StringName, bone_name: StringName, at: Vector2, rows: Array, legend: Dictionary, opts := {}) -> RigDef.Stamp:
	var s := _make_stamp(id, bone_name, at, rows, legend, opts)
	def.stamps.append(s)
	return s


## Sello de la biblioteca de PER (`scripts/art/defs/stamps/stamp_lib.gd`): {rows, legend, anchor, faces}.
## `remap` resuelve las ranuras "@x" del sello a ranuras de esta definición.
func stamp_lib(id: StringName, bone_name: StringName, at: Vector2, lib_stamp: Dictionary, remap := {}, opts := {}) -> RigDef.Stamp:
	var legend := {}
	var src: Dictionary = lib_stamp.get("legend", {})
	for ch: String in src.keys():
		var e: Array = src[ch]
		var m = e[0]
		if remap.has(m):
			m = remap[m]
		legend[ch] = [m, e[1]]
	var o := opts.duplicate()
	o["anchor"] = lib_stamp.get("anchor", Vector2i.ZERO)
	if lib_stamp.get("faces", "right") == "right" and def.facing < 0:
		o["flip"] = not o.get("flip", false)
	return stamp(id, bone_name, at, lib_stamp["rows"], legend, o)


func _make_stamp(id: StringName, bone_name: StringName, at: Vector2, rows: Array, legend: Dictionary, opts: Dictionary) -> RigDef.Stamp:
	var s := RigDef.Stamp.new()
	s.id = id
	s.bone = bone_name
	s.at = at
	s.rows = rows
	s.legend = legend
	s.anchor = opts.get("anchor", Vector2i.ZERO)
	s.views = opts.get("views", {})
	s.flip = opts.get("flip", false)
	s.z_top = opts.get("z_top", true)
	s.accessory = opts.get("accessory", &"")
	return s


## Parche a mano para un fotograma concreto (≤ 15 px; si hace falta más, se rediseña la pose).
func patch(anim_name: StringName, frame: int, bone_name: StringName, at: Vector2, rows: Array, legend: Dictionary, opts := {}) -> RigDef.Stamp:
	var key := "%s:%d" % [anim_name, frame]
	var s := _make_stamp(StringName("patch_%s" % key), bone_name, at, rows, legend, opts)
	if not def.patches.has(key):
		def.patches[key] = []
	(def.patches[key] as Array).append(s)
	return s


# ------------------------------------------------------------------------------------- animación
## keys {fotograma: pose}. ms: int o Array[int]. opts: loop, interp, overlap {hueso: retraso}
func anim(name: StringName, frames: int, ms: Variant, keys: Dictionary, opts := {}) -> RigDef.Anim:
	var a := RigDef.Anim.new()
	a.name = name
	a.frames = frames
	a.ms.clear()
	if ms is Array:
		for v in ms:
			a.ms.append(int(v))
	else:
		a.ms.append(int(ms))
	a.keys = keys
	a.loop = opts.get("loop", true)
	a.interp = opts.get("interp", &"smooth")
	a.overlap = opts.get("overlap", {})
	def.anims[name] = a
	return a


## Estela en media luna en el fotograma `frame` (barrido desde el fotograma anterior).
func smear(anim_name: StringName, frame: int, bone_name: StringName, point: Vector2, slot: StringName, width := 6.0, front := true) -> RigDef.Smear:
	var s := RigDef.Smear.new()
	s.bone = bone_name
	s.point = point
	s.slot = slot
	s.width = width
	s.front = front
	(def.anims[anim_name] as RigDef.Anim).smears[frame] = s
	return s


func variant(name: StringName, params: Dictionary) -> void:
	def.variants[name] = params


func part(part_def: RigDef, offset: Vector2i, phase := 0) -> RigDef.Part:
	var pt := RigDef.Part.new()
	pt.def = part_def
	pt.offset = offset
	pt.phase = phase
	def.parts.append(pt)
	return pt
