class_name RigPose
extends RefCounted
## Muestreo de poses y esqueleto (FK + IK de 2 huesos) del motor de rig v1 (TEC · v0.4).

## Pose del fotograma `f` (puede ser fraccionario) de una animación: interpola las claves, aplica el retraso
## (overlap) de cada hueso y mantiene las claves no numéricas (vistas, ocultar) desde la última clave.
static func sample(a: RigDef.Anim, f: float) -> Dictionary:
	var ks: Array = a.keys.keys()
	ks.sort()
	var channels := {}
	for k: int in ks:
		for ch in (a.keys[k] as Dictionary).keys():
			channels[ch] = true
	var out := {}
	for ch in channels.keys():
		var lag := 0.0
		var name := String(ch)
		if not name.contains(":") and not name.begins_with("@"):
			lag = float(a.overlap.get(StringName(name), a.overlap.get(name, 0.0)))
		out[ch] = _channel(a, ks, ch, f - lag)
	return out


static func _wrap(a: RigDef.Anim, t: float) -> float:
	if a.loop:
		return fposmod(t, float(a.frames))
	return clampf(t, 0.0, float(a.frames - 1))


static func _default(ch: Variant, sample_val: Variant) -> Variant:
	if String(ch).begins_with("z:"):
		return null   # z sin clave = la z de reposo del hueso
	match typeof(sample_val):
		TYPE_VECTOR2I:
			return Vector2i.ZERO
		TYPE_VECTOR2:
			return null   # objetivos de IK: sin valor = sin IK
		TYPE_INT, TYPE_FLOAT:
			return 0.0
	return null


static func _channel(a: RigDef.Anim, ks: Array, ch: Variant, t: float) -> Variant:
	t = _wrap(a, t)
	# claves que tienen este canal; las que no lo tienen valen "por defecto" (0) para los numéricos
	var any_val: Variant = null
	for k: int in ks:
		if (a.keys[k] as Dictionary).has(ch):
			any_val = a.keys[k][ch]
			break
	var numeric := typeof(any_val) in [TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR2I]
	var vals := []
	for k: int in ks:
		var d: Dictionary = a.keys[k]
		vals.append(d[ch] if d.has(ch) else (_default(ch, any_val) if numeric else null))
	# clave anterior y siguiente
	var i0 := -1
	for i in ks.size():
		if float(ks[i]) <= t + 0.0001:
			i0 = i
	var k0: float
	var v0: Variant
	var k1: float
	var v1: Variant
	if i0 < 0:
		if a.loop:
			k0 = float(ks[-1]) - a.frames
			v0 = vals[-1]
		else:
			return vals[0]
		k1 = float(ks[0])
		v1 = vals[0]
	else:
		k0 = float(ks[i0])
		v0 = vals[i0]
		if i0 + 1 < ks.size():
			k1 = float(ks[i0 + 1])
			v1 = vals[i0 + 1]
		elif a.loop:
			k1 = float(ks[0]) + a.frames
			v1 = vals[0]
		else:
			return v0
	if not numeric:
		# no numéricos: se mantiene el último valor definido
		var j := i0 if i0 >= 0 else ks.size() - 1
		while j >= 0 and vals[j] == null:
			j -= 1
		return vals[j] if j >= 0 else null
	if v0 == null or v1 == null:
		return v0 if v1 == null else (v1 if t >= k1 - 0.0001 else null)
	var u := 0.0 if k1 <= k0 else (t - k0) / (k1 - k0)
	match a.interp:
		&"linear":
			pass
		&"hold":
			u = 0.0
		_:
			u = u * u * (3.0 - 2.0 * u)
	if v0 is Vector2i:
		var w := Vector2(v0).lerp(Vector2(v1), u)
		return Vector2i(roundi(w.x), roundi(w.y))
	if v0 is Vector2:
		return (v0 as Vector2).lerp(v1, u)
	return lerpf(float(v0), float(v1), u)


## Mezcla lineal de dos poses (para la estela: posiciones intermedias entre fotogramas).
static func blend(p0: Dictionary, p1: Dictionary, u: float) -> Dictionary:
	var out := p1.duplicate()
	for k in p0.keys():
		if not p1.has(k):
			continue
		var a: Variant = p0[k]
		var b: Variant = p1[k]
		if (a is float or a is int) and (b is float or b is int):
			out[k] = lerpf(float(a), float(b), u)
		elif a is Vector2 and b is Vector2:
			out[k] = (a as Vector2).lerp(b, u)
		elif a is Vector2i and b is Vector2i:
			out[k] = Vector2(a).lerp(Vector2(b), u)   # sin redondear: es una posición de muestreo
	return out


## Esqueleto resuelto: {hueso: Transform2D en el lienzo}, {hueso: z}.
class Solved:
	var xf := {}
	var z := {}


static func solve(def: RigDef, pose: Dictionary) -> Solved:
	var angles := {}
	for b in def.bones:
		angles[b.name] = b.angle + float(pose.get(b.name, pose.get(String(b.name), 0.0)))
	var s := _fk(def, pose, angles)
	# IK de 2 huesos (en orden de declaración)
	for ik_name in def.iks.keys():
		var tgt: Variant = pose.get(StringName("ik:%s" % ik_name), pose.get("ik:%s" % ik_name))
		if tgt == null:
			continue
		var k: RigDef.Ik = def.iks[ik_name]
		_solve_ik(def, k, Vector2(tgt), angles, s)
		s = _fk(def, pose, angles)
	return s


static func _fk(def: RigDef, pose: Dictionary, angles: Dictionary) -> Solved:
	var s := Solved.new()
	var root_off: Variant = pose.get(&"@root", pose.get("@root", Vector2i.ZERO))
	for b in def.bones:
		var a: float = angles[b.name]
		var zo: Variant = pose.get(StringName("z:%s" % b.name), pose.get("z:%s" % b.name))
		if b.parent == &"":
			var o := Vector2(def.origin) + b.pivot + Vector2(root_off)
			s.xf[b.name] = Transform2D(a, o)
			s.z[b.name] = b.z if zo == null else float(zo)
		else:
			s.xf[b.name] = (s.xf[b.parent] as Transform2D) * Transform2D(a, b.pivot)
			s.z[b.name] = float(s.z[b.parent]) + (b.z if zo == null else float(zo))
	return s


static func _solve_ik(def: RigDef, k: RigDef.Ik, target: Vector2, angles: Dictionary, s: Solved) -> void:
	var up := def.bone(k.upper)
	var lo := def.bone(k.lower)
	if up == null or lo == null:
		return
	var up_xf: Transform2D = s.xf[k.upper]
	var parent_rot := 0.0
	if up.parent != &"":
		parent_rot = (s.xf[up.parent] as Transform2D).get_rotation()
	var p0 := up_xf.origin
	var l1 := lo.pivot.length()
	var l2 := k.end.length()
	if l1 < 0.001 or l2 < 0.001:
		return
	var d := target - p0
	var dl := clampf(d.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var ad := d.angle()
	var c1 := clampf((l1 * l1 + dl * dl - l2 * l2) / (2.0 * l1 * dl), -1.0, 1.0)
	var upper_dir := ad - float(k.bend) * acos(c1)
	var th_u := upper_dir - lo.pivot.angle()
	var p1 := p0 + Vector2.from_angle(upper_dir) * l1
	var th_l := (target - p1).angle() - k.end.angle()
	angles[k.upper] = th_u - parent_rot
	angles[k.lower] = th_l - th_u
