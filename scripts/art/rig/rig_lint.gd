class_name RigLint
extends RefCounted
## Reglas del motor de rig como ERRORES DE HORNEADO (TEC · v0.4). Las 7 condiciones de PER + límites de DA:
##   PER-1  material de primera clase con rampa a mano: toda ranura apunta a un material de `Palette`.
##   PER-2  cara, manos, ojos y remaches sólo con sello: una pieza etiquetada face/hand/eye/rivet exige un sello en su hueso.
##   PER-3  nada de elipses/cápsulas lisas de más de 20 px sin aplanado (≥ 0,3) o facetas.
##   PER-4  líneas interiores nunca alrededor de un sello (lo garantiza el renderizador: los sellos van bloqueados).
##   PER-5  las poses rotan primitivas, nunca mapas de bits (lo garantiza el diseño: no hay rotación de imagen).
##   PER-6  parches ≤ 15 px por fotograma (lo comprueba el renderizador por fotograma; aquí, el tamaño declarado).
##   PER-7  horneado determinista (lo comprueba tests/art/test_tec.gd).
##   DA     facetas Voronoi sólo en carbón, escoria y hielo; celda ≥ 24 px²; ≤ 3 planos por masa > 12 px.
##   Modo pequeño: lienzo < 32 px de alto → sólo losas con pasos forzados.

const FACET_MATERIALS: Array[StringName] = [&"coal", &"slag", &"ice"]
const STAMP_TAGS: Array[StringName] = [&"face", &"hand", &"eye", &"rivet"]
const MAX_SMOOTH := 20.0
const MAX_PATCH := 15


static func check(def: RigDef) -> Array[String]:
	var e: Array[String] = []
	var pre := "%s: " % def.id
	if def.id == &"":
		e.append("definición sin id")
	if def.bones.is_empty():
		e.append(pre + "sin huesos")
	var names := {}
	for b in def.bones:
		if names.has(b.name):
			e.append(pre + "hueso repetido %s" % b.name)
		if b.parent != &"" and not names.has(b.parent):
			e.append(pre + "el hueso %s cuelga de %s, que no está declarado antes" % [b.name, b.parent])
		names[b.name] = true
	# PER-1 · materiales
	for slot: StringName in def.materials.keys():
		var ms: RigDef.MatSpec = def.materials[slot]
		if not Palette.has(ms.palette):
			e.append(pre + "PER-1: la ranura %s usa %s, que no es un material de la paleta (nada de rampas propias ni HSV)" % [slot, ms.palette])
		if ms.facet != null:
			if not FACET_MATERIALS.has(ms.palette):
				e.append(pre + "DA: facetas Voronoi sólo en carbón, escoria y hielo (ranura %s = %s)" % [slot, ms.palette])
			if ms.facet.cell_area < 24.0:
				e.append(pre + "DA: celda de faceta de %.0f px² (< 24) en %s" % [ms.facet.cell_area, slot])
			if ms.facet.crack > 0.0 and not def.materials.has(ms.facet.crack_slot):
				e.append(pre + "la grieta de %s usa la ranura %s, que no existe" % [slot, ms.facet.crack_slot])
		if ms.planes > 3:
			e.append(pre + "DA: %s permite %d planos de luz (máx. 3 por masa)" % [slot, ms.planes])
	# piezas
	var stamp_bones := {}
	for s in def.stamps:
		stamp_bones[s.bone] = true
		if not names.has(s.bone):
			e.append(pre + "el sello %s cuelga del hueso inexistente %s" % [s.id, s.bone])
		for ch: String in s.legend.keys():
			var le: Array = s.legend[ch]
			var m := String(le[0])
			var pal: StringName
			if m.begins_with("@"):
				var sl := StringName(m.substr(1))
				if not def.materials.has(sl):
					e.append(pre + "el sello %s usa la ranura %s, que no existe" % [s.id, m])
					continue
				pal = (def.materials[sl] as RigDef.MatSpec).palette
			elif def.materials.has(StringName(m)):
				pal = (def.materials[StringName(m)] as RigDef.MatSpec).palette
			else:
				pal = StringName(m)
			if not Palette.has(pal):
				e.append(pre + "PER-1: el sello %s usa %s, que no está en la paleta" % [s.id, m])
	for pc in def.pieces:
		if not names.has(pc.bone):
			e.append(pre + "la pieza %s cuelga del hueso inexistente %s" % [pc.id, pc.bone])
		if pc.prim != &"slab" and not def.materials.has(pc.slot):
			e.append(pre + "la pieza %s usa la ranura %s, que no existe" % [pc.id, pc.slot])
		if pc.prim == &"slab":
			for v in (pc.p["legend"] as Dictionary).values():
				var sl2 := StringName(v[0]) if v is Array else StringName(v)
				if not def.materials.has(sl2):
					e.append(pre + "la losa %s usa la ranura %s, que no existe" % [pc.id, sl2])
		var ms2: RigDef.MatSpec = def.materials.get(pc.slot)
		var faceted := ms2 != null and ms2.facet != null
		# PER-3
		var diam := 0.0
		match pc.prim:
			&"ell":
				var r: Vector3 = pc.p["r"]
				diam = 2.0 * maxf(r.x, r.y)
			&"cap":
				diam = 2.0 * maxf(float(pc.p["ra"]), float(pc.p["rb"]))
		if diam > MAX_SMOOTH and pc.flat < 0.3 and not faceted:
			e.append(pre + "PER-3: %s %s mide %.0f px sin aplanado (≥ 0,3) ni facetas: salen anillos de vector" % [pc.prim, pc.id, diam])
		# PER-2
		for t in pc.tags:
			if STAMP_TAGS.has(t) and not stamp_bones.has(pc.bone):
				e.append(pre + "PER-2: la pieza %s es '%s' y su hueso %s no tiene sello: caras, manos, ojos y remaches van sellados a mano" % [pc.id, t, pc.bone])
		if def.small and not (pc.prim == &"slab" and _slab_forced(pc)):
			e.append(pre + "modo pequeño: la pieza %s debe ser una losa ASCII con pasos forzados" % pc.id)
	if def.size.y < 32 and not def.small:
		e.append(pre + "lienzo de %d px de alto (< 32): usar el modo pequeño (losas ASCII forzadas)" % def.size.y)
	# PER-6 · tamaño declarado de los parches
	for key: String in def.patches.keys():
		var n := 0
		for s: RigDef.Stamp in def.patches[key]:
			for r: String in s.rows:
				for ch in r:
					if ch != "." and s.legend.has(ch):
						n += 1
		if n > MAX_PATCH:
			e.append(pre + "PER-6: el parche %s tiene %d px (> %d): rediseñar la pose" % [key, n, MAX_PATCH])
	# animaciones
	for an: StringName in def.anims.keys():
		var a: RigDef.Anim = def.anims[an]
		if a.frames < 1:
			e.append(pre + "la animación %s no tiene fotogramas" % an)
		if a.ms.size() != 1 and a.ms.size() != a.frames:
			e.append(pre + "la animación %s tiene %d duraciones para %d fotogramas" % [an, a.ms.size(), a.frames])
		for k: int in a.keys.keys():
			if k < 0 or k >= a.frames:
				e.append(pre + "%s: clave en el fotograma %d fuera de 0..%d" % [an, k, a.frames - 1])
			for ch in (a.keys[k] as Dictionary).keys():
				var c := String(ch)
				if c.begins_with("@") or c.contains(":"):
					if c.begins_with("ik:") and not def.iks.has(StringName(c.substr(3))):
						e.append(pre + "%s: IK %s no declarada" % [an, c])
					continue
				if not names.has(StringName(c)):
					e.append(pre + "%s: la clave %s no es un hueso" % [an, c])
		for f: int in a.smears.keys():
			var sm: RigDef.Smear = a.smears[f]
			if not def.materials.has(sm.slot):
				e.append(pre + "%s: la estela usa la ranura %s, que no existe" % [an, sm.slot])
	for k2 in def.iks.keys():
		var ik: RigDef.Ik = def.iks[k2]
		if not names.has(ik.upper) or not names.has(ik.lower):
			e.append(pre + "IK %s: huesos inexistentes" % k2)
		elif def.bone(ik.lower).parent != ik.upper:
			e.append(pre + "IK %s: %s no cuelga de %s" % [k2, ik.lower, ik.upper])
	for p in def.parts:
		e.append_array(check(p.def))
	return e


static func _slab_forced(pc: RigDef.Piece) -> bool:
	for v in (pc.p["legend"] as Dictionary).values():
		if not (v is Array and (v as Array).size() > 1):
			return false
	return true
