extends RefCounted
## EJEMPLO de jefe MULTIPARTE (TEC): cada parte es un RigDef con su atlas, su desfase de bucle y sus variantes.
## La fase 2 de un jefe es una VARIANTE de la parte que cambia de silueta (aquí, la puerta pierde la hoja).
## También enseña las primitivas planas con bisel: box, poly y slab sin pasos forzados.


static func door() -> RigDef:
	var b := RigBuilder.new(&"boss_door", Vector2i(64, 72), Vector2i(32, 36), -1, &"examples")
	b.material(&"brick", &"furnace_brick", {"texture": &"mortar"})
	b.material(&"iron", &"iron", {"spec": true})
	b.material(&"glow", &"hot")
	b.bone(&"root", &"", Vector2.ZERO)
	b.box(&"frame_box", &"root", &"brick", Vector3(0, 0, 0), Vector3(44, 56, 6), 3.0, {"line": false})
	b.ell(&"maw", &"root", &"glow", Vector3(0, 8, 4), Vector3(12, 9, 2), {"flat": 0.3, "line": false})
	var leaf := PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(16, -4), Vector2(-16, -4)])
	b.poly(&"plate_poly", &"root", &"iron", leaf, 8.0, 3.0, 2.0, {"accessory": &"door_shut"})
	b.slab(&"rune_slab", &"root", [
		"..###..",
		".#####.",
		"#######",
		".#####.",
		"..###..",
	], Vector2(-3.5, -18), {"#": &"brick"}, 12.0, 2.0, 2.0)
	var idle := {}
	for f in 6:
		idle[f] = {&"emit:maw": 1 if f in [2, 3] else 0}
	b.anim(&"idle", 6, 160, idle, {"interp": &"hold"})
	b.variant(&"base", {&"door_shut": true})
	b.variant(&"phase2", {})
	return b.def


static func stack() -> RigDef:
	var b := RigBuilder.new(&"boss_stack", Vector2i(40, 64), Vector2i(20, 50), -1, &"examples")
	b.material(&"coal", &"coal", {"facet": {"cell_area": 40.0, "weight": 0.6}})
	b.bone(&"root", &"", Vector2.ZERO)
	b.cap(&"flue", &"root", &"coal", Vector3(0, 0, 0), Vector3(0, -34, 0), 11.0, 7.0)
	b.anim(&"idle", 4, 200, {0: {}, 2: {&"root": 0.05}})
	return b.def


static func build() -> RigDef:
	var b := RigBuilder.new(&"boss_example", Vector2i(120, 96), Vector2i(60, 90), -1, &"examples")
	b.bone(&"root", &"", Vector2.ZERO)
	b.part(door(), Vector2i(10, 20))
	b.part(stack(), Vector2i(70, 8), 3)
	return b.def
