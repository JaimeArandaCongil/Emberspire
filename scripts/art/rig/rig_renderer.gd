class_name RigRenderer
extends RefCounted
## Motor de rig v1 (TEC · v0.4): `RigDef` + pose → textura de ÍNDICE (`IndexFormat`) + vista previa en color.
##
## Tubería por fotograma:
##   pose → esqueleto (FK+IK) → rasterizado de primitivas en el espacio de cada hueso (z-buffer → G-buffer)
##   → máscaras de material → limpieza de silueta → luz cálida/fría + sombra arrojada + AO → paso de rampa
##   → facetas/grietas → ≤ N planos por masa → texturas de material → filtro de moda → labio de grietas
##   → especular → luz de borde (CANTO) → líneas interiores → sellos y parches (tono forzado) → estela
##   → huérfanos → contorno selectivo → anclas de pieza → empaquetado.
## Determinista: sin aleatoriedad global (semillas por pieza), sin dependencia del orden de diccionarios no fijado.

const ENGINE_VERSION := 1
const LINE := -100          # paso "LINE" de un sello
const REL := -200           # base de pasos relativos (+1 / −1) de un sello: REL + delta

class Frame:
	var index: Image
	var preview: Image
	var sockets := {}        # {nombre: Vector2i en el lienzo}
	var errors: Array[String] = []
	var patch_px := 0


# --------------------------------------------------------------------------------------------- API
## Renderiza el fotograma `frame` de la animación `anim_name` con los parámetros de variante `params`.
static func render(def: RigDef, anim_name: StringName, frame: int, params := {}) -> Frame:
	var a: RigDef.Anim = def.anims.get(anim_name)
	var pose := {}
	if a != null:
		pose = RigPose.sample(a, float(frame))
	var ctx := _Ctx.new(def, params)
	var out := ctx.run(pose, a, frame)
	return out


## Pose ya muestreada (herramientas y pruebas).
static func render_pose(def: RigDef, pose: Dictionary, params := {}) -> Frame:
	var ctx := _Ctx.new(def, params)
	return ctx.run(pose, null, 0)


# --------------------------------------------------------------------------------------------- contexto
class _Ctx:
	var def: RigDef
	var params: Dictionary
	var W: int
	var H: int
	var N: int
	var slots: Array[StringName] = []      # índice de ranura → nombre
	var slot_idx := {}
	var slot_pal: Array[StringName] = []
	var slot_emit: Array[bool] = []
	# G-buffer
	var piece := PackedInt32Array()
	var zb := PackedFloat32Array()
	var nrm := PackedVector3Array()
	var loc := PackedVector3Array()
	var slot := PackedInt32Array()
	var forced := PackedInt32Array()        # paso forzado (losa pequeña / sello) o −1
	var cell := PackedInt32Array()
	var edge := PackedFloat32Array()
	# resultado
	var step := PackedInt32Array()
	var flags := PackedInt32Array()
	var mat := PackedInt32Array()           # índice de paleta final por píxel
	var anc := PackedVector2Array()
	var locked := PackedByteArray()          # sello/parche: no se limpia ni genera línea
	var solved: RigPose.Solved
	var active: Array[bool] = []            # piezas activas (accesorios / ocultas)
	var seeds: Array = []                   # por pieza: PackedVector3Array
	var slab_cache := {}
	var pose_now := {}                      # pose del fotograma (vistas por pieza)
	var errors: Array[String] = []

	func _init(d: RigDef, p: Dictionary) -> void:
		def = d
		params = p
		W = d.size.x
		H = d.size.y
		N = W * H
		for s: StringName in d.materials.keys():
			slot_idx[s] = slots.size()
			slots.append(s)
			var ms: RigDef.MatSpec = d.materials[s]
			slot_pal.append(ms.palette)
			slot_emit.append(Palette.has(ms.palette) and Palette.is_emissive(ms.palette))
		piece.resize(N); piece.fill(-1)
		zb.resize(N); zb.fill(-1e9)
		nrm.resize(N)
		loc.resize(N)
		slot.resize(N); slot.fill(-1)
		forced.resize(N); forced.fill(-1)
		cell.resize(N); cell.fill(-1)
		edge.resize(N); edge.fill(99.0)
		step.resize(N)
		flags.resize(N)
		mat.resize(N); mat.fill(-1)
		anc.resize(N)
		locked.resize(N)
		_make_seeds()

	# ----------------------------------------------------------------------------------------- run
	func run(pose: Dictionary, a: RigDef.Anim, frame: int) -> Frame:
		pose_now = pose
		solved = RigPose.solve(def, pose)
		active.clear()
		for pc in def.pieces:
			var on := pc.accessory == &"" or bool(params.get(pc.accessory, false))
			if pose.get(StringName("hide:%s" % pc.id), false):
				on = false
			active.append(on)
		var smear: RigDef.Smear = null
		var prev_pose := {}
		if a != null and a.smears.has(frame):
			smear = a.smears[frame]
			prev_pose = RigPose.sample(a, float(frame - 1))
		if smear != null and not smear.front:
			_smear(smear, prev_pose, pose, false)
		_raster()
		_masks()
		_clean_silhouette()
		_shade(pose)
		_stamps(pose, a, frame)
		if smear != null and smear.front:
			_smear(smear, prev_pose, pose, true)
			solved = RigPose.solve(def, pose)
		_orphans()
		_outline()
		var fr := Frame.new()
		fr.index = _pack()
		fr.preview = IndexFormat.preview(fr.index)
		for sk in def.sockets.keys():
			var e: Array = def.sockets[sk]
			if solved.xf.has(e[0]):
				var p: Vector2 = (solved.xf[e[0]] as Transform2D) * Vector2(e[1])
				fr.sockets[sk] = Vector2i(roundi(p.x), roundi(p.y))
		fr.errors = errors
		fr.patch_px = _patch_count
		return fr

	# ----------------------------------------------------------------------------------------- primitivas
	func _bbox(pc: RigDef.Piece) -> Rect2:
		var p := pc.p
		match pc.prim:
			&"ell":
				var c: Vector3 = p["c"]
				var r: Vector3 = p["r"]
				return Rect2(c.x - r.x, c.y - r.y, r.x * 2, r.y * 2)
			&"cap":
				var a: Vector3 = p["a"]
				var b: Vector3 = p["b"]
				var rr: float = maxf(p["ra"], p["rb"])
				var mn := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(rr, rr)
				var mx := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(rr, rr)
				return Rect2(mn, mx - mn)
			&"box":
				var c2: Vector3 = p["c"]
				var d: Vector3 = p["d"]
				return Rect2(c2.x - d.x * 0.5, c2.y - d.y * 0.5, d.x, d.y)
			&"poly":
				var pts: PackedVector2Array = p["pts"]
				var r2 := Rect2(pts[0], Vector2.ZERO)
				for q in pts:
					r2 = r2.expand(q)
				return r2
			&"slab":
				var rows: Array = _slab_rows(pc)
				return Rect2(p["tl"], Vector2(String(rows[0]).length(), rows.size()))
		return Rect2()

	func _center(pc: RigDef.Piece) -> Vector2:
		match pc.prim:
			&"ell", &"box":
				var c: Vector3 = pc.p["c"]
				return Vector2(c.x, c.y)
			&"cap":
				var a: Vector3 = pc.p["a"]
				var b: Vector3 = pc.p["b"]
				return Vector2((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)
		return _bbox(pc).get_center()

	## Superficie frontal en el espacio del hueso: {} o {z, n (local), slot?, forced?}
	func _hit(pi: int, pc: RigDef.Piece, q: Vector2) -> Dictionary:
		var p := pc.p
		match pc.prim:
			&"ell":
				var c: Vector3 = p["c"]
				var r: Vector3 = p["r"]
				var dx := (q.x - c.x) / r.x
				var dy := (q.y - c.y) / r.y
				var s := dx * dx + dy * dy
				if s >= 1.0:
					return {}
				var dz := sqrt(1.0 - s)
				return {"z": c.z + dz * r.z, "n": Vector3(dx / r.x, dy / r.y, dz / r.z).normalized()}
			&"cap":
				var a: Vector3 = p["a"]
				var b: Vector3 = p["b"]
				var ab := Vector2(b.x - a.x, b.y - a.y)
				var l2 := ab.length_squared()
				var t := 0.0
				if l2 > 0.0001:
					t = clampf((q - Vector2(a.x, a.y)).dot(ab) / l2, 0.0, 1.0)
				var rad: float = lerpf(p["ra"], p["rb"], t)
				var cp := a.lerp(b, t)
				var d := q - Vector2(cp.x, cp.y)
				var dd := d.length_squared()
				if dd >= rad * rad:
					return {}
				var hz := sqrt(rad * rad - dd)
				return {"z": cp.z + hz, "n": Vector3(d.x, d.y, hz) / rad}
			&"box":
				var c2: Vector3 = p["c"]
				var dm: Vector3 = p["d"]
				var bev: float = maxf(0.5, p["bevel"])
				var lx := q.x - c2.x
				var ly := q.y - c2.y
				var hx := dm.x * 0.5
				var hy := dm.y * 0.5
				if absf(lx) >= hx or absf(ly) >= hy:
					return {}
				var ex := hx - absf(lx)
				var ey := hy - absf(ly)
				var e := minf(ex, ey)
				var nx := 0.0
				var ny := 0.0
				if e < bev:
					var k := 1.0 - e / bev
					if ex < ey:
						nx = signf(lx) * k
					else:
						ny = signf(ly) * k
				return {"z": c2.z + dm.z * 0.5 * minf(e, bev) / bev, "n": Vector3(nx, ny, 1.0).normalized()}
			&"poly":
				var pts: PackedVector2Array = p["pts"]
				if not Geometry2D.is_point_in_polygon(q, pts):
					return {}
				var best := 1e9
				var bp := q
				for i in pts.size():
					var cpt := Geometry2D.get_closest_point_to_segment(q, pts[i], pts[(i + 1) % pts.size()])
					var dd2 := q.distance_squared_to(cpt)
					if dd2 < best:
						best = dd2
						bp = cpt
				var e2 := sqrt(best)
				var bev2: float = maxf(0.5, p["bevel"])
				var dir := (bp - q).normalized() if e2 > 0.0001 else Vector2.ZERO
				var k2 := clampf(1.0 - e2 / bev2, 0.0, 1.0) * 0.9
				return {"z": float(p["z0"]) + float(p["h"]) * minf(e2, bev2) / bev2, "n": Vector3(dir.x * k2, dir.y * k2, 1.0).normalized()}
			&"slab":
				var sd: Dictionary = _slab(pi, pc)
				var tl: Vector2 = p["tl"]
				var cx := int(floor(q.x - tl.x))
				var cy := int(floor(q.y - tl.y))
				if cx < 0 or cy < 0 or cx >= int(sd["w"]) or cy >= int(sd["h"]):
					return {}
				var ci := cy * int(sd["w"]) + cx
				var dist: PackedFloat32Array = sd["d"]
				if dist[ci] <= 0.0:
					return {}
				var bev3: float = maxf(0.5, p["bevel"])
				var g := Vector2(_sd(sd, cx + 1, cy) - _sd(sd, cx - 1, cy), _sd(sd, cx, cy + 1) - _sd(sd, cx, cy - 1))
				var k3 := clampf(1.0 - dist[ci] / bev3, 0.0, 1.0)
				var gn := -g.normalized() * k3 if g.length() > 0.001 else Vector2.ZERO
				var out := {"z": float(p["z0"]) + float(p["h"]) * minf(dist[ci], bev3) / bev3, "n": Vector3(gn.x, gn.y, 1.0).normalized()}
				var ch: String = (sd["chars"] as Array)[ci]
				var lg: Variant = (p["legend"] as Dictionary)[ch]
				if lg is Array:
					out["slot"] = StringName(lg[0])
					if (lg as Array).size() > 1:
						out["forced"] = int(lg[1])
				else:
					out["slot"] = StringName(lg)
				return out
		return {}

	func _sd(sd: Dictionary, x: int, y: int) -> float:
		if x < 0 or y < 0 or x >= int(sd["w"]) or y >= int(sd["h"]):
			return 0.0
		return (sd["d"] as PackedFloat32Array)[y * int(sd["w"]) + x]

	## Campo de distancia al borde de una losa (una vez por pieza).
	func _slab(pi: int, pc: RigDef.Piece) -> Dictionary:
		var view: Variant = pose_now.get(StringName("view:%s" % pc.id))
		var skey := "%d|%s" % [pi, view]
		if slab_cache.has(skey):
			return slab_cache[skey]
		var rows: Array = _slab_rows(pc)
		var legend: Dictionary = pc.p["legend"]
		var w := 0
		for r: String in rows:
			w = maxi(w, r.length())
		var h := rows.size()
		var d := PackedFloat32Array()
		d.resize(w * h)
		var chars := []
		chars.resize(w * h)
		for y in h:
			var r: String = rows[y]
			for x in w:
				var ch := r[x] if x < r.length() else "."
				chars[y * w + x] = ch
				d[y * w + x] = 99.0 if (ch != "." and legend.has(ch)) else 0.0
		for _pass in 6:
			for y in h:
				for x in w:
					var i := y * w + x
					if d[i] <= 0.0:
						continue
					var m := 99.0
					for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx := x + o.x
						var ny := y + o.y
						m = minf(m, 0.0 if (nx < 0 or ny < 0 or nx >= w or ny >= h) else d[ny * w + nx])
					d[i] = minf(d[i], m + 1.0)
		var sd := {"w": w, "h": h, "d": d, "chars": chars}
		slab_cache[skey] = sd
		return sd

	## Filas de la losa según la vista de la pose (`view:<id de la losa>`).
	func _slab_rows(pc: RigDef.Piece) -> Array:
		var views: Dictionary = pc.p.get("views", {})
		var view: Variant = pose_now.get(StringName("view:%s" % pc.id))
		if view != null and views.has(view):
			return views[view]
		return pc.p["rows"]

	func _make_seeds() -> void:
		seeds.clear()
		for i in def.pieces.size():
			var pc: RigDef.Piece = def.pieces[i]
			var arr := PackedVector3Array()
			var ms: RigDef.MatSpec = def.materials.get(pc.slot)
			if ms != null and ms.facet != null:
				var rng := RandomNumberGenerator.new()
				rng.seed = def.rng_seed * 7919 + i * 131 + 17
				var bb := _bbox(pc)
				var n := maxi(3, int(bb.size.x * bb.size.y / maxf(24.0, ms.facet.cell_area)))
				var tries := 0
				while arr.size() < n and tries < n * 6:
					tries += 1
					var xy := Vector2(rng.randf_range(bb.position.x, bb.end.x), rng.randf_range(bb.position.y, bb.end.y))
					var hit := _hit(i, pc, xy)
					if not hit.is_empty():
						arr.append(Vector3(xy.x, xy.y, hit["z"]))
			seeds.append(arr)

	# ----------------------------------------------------------------------------------------- rasterizado
	func _raster() -> void:
		for i in def.pieces.size():
			if not active[i]:
				continue
			var pc: RigDef.Piece = def.pieces[i]
			if not solved.xf.has(pc.bone):
				continue
			var xf: Transform2D = solved.xf[pc.bone]
			var ix := xf.affine_inverse()
			var bz: float = float(solved.z[pc.bone]) + pc.z
			var bb := _bbox(pc)
			var mn := Vector2(1e9, 1e9)
			var mx := Vector2(-1e9, -1e9)
			for c: Vector2 in [bb.position, Vector2(bb.end.x, bb.position.y), Vector2(bb.position.x, bb.end.y), bb.end]:
				var w := xf * c
				mn = mn.min(w)
				mx = mx.max(w)
			var x0 := maxi(0, int(floor(mn.x)) - 1)
			var x1 := mini(W - 1, int(ceil(mx.x)) + 1)
			var y0 := maxi(0, int(floor(mn.y)) - 1)
			var y1 := mini(H - 1, int(ceil(mx.y)) + 1)
			var ms: RigDef.MatSpec = def.materials.get(pc.slot)
			var sd: PackedVector3Array = seeds[i]
			for y in range(y0, y1 + 1):
				for x in range(x0, x1 + 1):
					var q: Vector2 = ix * Vector2(x + 0.5, y + 0.5)
					var hit := _hit(i, pc, q)
					if hit.is_empty():
						continue
					var z: float = float(hit["z"]) + bz
					var idx := y * W + x
					if z <= zb[idx]:
						continue
					zb[idx] = z
					piece[idx] = i
					var sl: StringName = hit.get("slot", pc.slot)
					slot[idx] = slot_idx.get(sl, -1)
					forced[idx] = int(hit.get("forced", -1))
					var nl: Vector3 = hit["n"]
					if pc.flat > 0.0:
						nl = Vector3(nl.x * (1.0 - pc.flat), nl.y * (1.0 - pc.flat), nl.z).normalized()
					cell[idx] = -1
					edge[idx] = 99.0
					if sd.size() > 0 and ms != null and ms.facet != null:
						var lp := Vector3(q.x, q.y, float(hit["z"]))
						var d1 := 1e9
						var d2 := 1e9
						var c1 := -1
						for s in sd.size():
							var dd: float = lp.distance_squared_to(sd[s])
							if dd < d1:
								d2 = d1
								d1 = dd
								c1 = s
							elif dd < d2:
								d2 = dd
						cell[idx] = i * 1000 + c1
						edge[idx] = sqrt(d2) - sqrt(d1)
						var sh := _hit(i, pc, Vector2(sd[c1].x, sd[c1].y))
						if not sh.is_empty():
							nl = nl.lerp(sh["n"], ms.facet.weight).normalized()
					var nxy := xf.basis_xform(Vector2(nl.x, nl.y))
					nrm[idx] = Vector3(nxy.x, nxy.y, nl.z)
					loc[idx] = Vector3(q.x, q.y, float(hit["z"]))

	# ----------------------------------------------------------------------------------------- máscaras
	func _masks() -> void:
		for mm in def.masks:
			var amt := float(params.get(mm.param, 0.0))
			if amt <= 0.0 or not slot_idx.has(mm.slot_from) or not slot_idx.has(mm.slot_to):
				continue
			var sf: int = slot_idx[mm.slot_from]
			var st: int = slot_idx[mm.slot_to]
			for y in H:
				for x in W:
					var i := y * W + x
					if piece[i] < 0 or slot[i] != sf:
						continue
					var pc: RigDef.Piece = def.pieces[piece[i]]
					if not mm.bones.is_empty() and not mm.bones.has(pc.bone):
						continue
					var on := false
					match mm.mode:
						&"rise":
							var hx := _hash(x * 3 + 1, 7, def.rng_seed) * 3.0
							on = float(H - 1 - y) + hx < amt * H
						_:
							var l := loc[i]
							on = _hash(int(floor(l.x / 3.0)), int(floor(l.y / 3.0)), piece[i]) < amt
					if on:
						slot[i] = st

	# ----------------------------------------------------------------------------------------- silueta
	func _clean_silhouette() -> void:
		for _it in 2:
			var changed := false
			for y in range(1, H - 1):
				for x in range(1, W - 1):
					var i := y * W + x
					if forced[i] >= 0:
						continue
					var nb := 0
					var donor := -1
					for o: int in [-1, 1, -W, W]:
						if piece[i + o] >= 0:
							nb += 1
							donor = i + o
					if piece[i] >= 0 and nb <= 1:
						piece[i] = -1
						changed = true
					elif piece[i] < 0 and nb >= 3 and forced[donor] < 0:
						piece[i] = piece[donor]
						zb[i] = zb[donor]
						nrm[i] = nrm[donor]
						loc[i] = loc[donor]
						slot[i] = slot[donor]
						cell[i] = cell[donor]
						edge[i] = edge[donor]
						changed = true
			if not changed:
				break

	# ----------------------------------------------------------------------------------------- luz
	func _shade(pose: Dictionary) -> void:
		var L := def.light
		var lw := L.warm_dir
		var lc := L.cold_dir
		var val := PackedFloat32Array()
		val.resize(N)
		var cold := PackedByteArray()
		cold.resize(N)
		# 1) valor continuo por píxel
		for y in H:
			for x in W:
				var i := y * W + x
				if piece[i] < 0:
					continue
				var n := nrm[i]
				var sh := _shadow(i, x, y, lw)
				var occ := 0
				for o: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
					var ox := x + o.x
					var oy := y + o.y
					if ox < 0 or oy < 0 or ox >= W or oy >= H:
						continue
					var j := oy * W + ox
					if piece[j] >= 0 and piece[j] != piece[i] and zb[j] > zb[i] + 2.5:
						occ += 1
				var pc: RigDef.Piece = def.pieces[piece[i]]
				var vw := maxf(0.0, n.dot(lw)) * L.warm * sh
				var vc := maxf(0.0, n.dot(lc)) * L.cold
				val[i] = L.ambient + 0.10 * clampf(-n.y, 0.0, 1.0) + 0.85 * vw + 0.55 * vc - 0.06 * occ * pc.ao
				cold[i] = 1 if (vc > vw + 0.05 and vc > 0.12) else 0
		# 2) paso por material
		for i in N:
			if piece[i] < 0:
				continue
			var si := slot[i]
			var pal: StringName = slot_pal[si] if si >= 0 else &"void"
			mat[i] = Palette.index(pal) if Palette.has(pal) else 0
			var iscold := cold[i] == 1
			var n_steps := Palette.steps(pal, iscold)
			flags[i] = IndexFormat.F_COLD if iscold else 0
			if forced[i] >= 0:
				step[i] = clampi(forced[i], 0, n_steps - 1)
				flags[i] = 0
				locked[i] = 1
				continue
			if si >= 0 and slot_emit[si]:
				var e := 1 + int(round(clampf(nrm[i].z, 0.0, 1.0) * (n_steps - 2)))
				step[i] = clampi(e + int(pose.get(StringName("emit:%s" % def.pieces[piece[i]].id), 0)), 1, n_steps - 1)
				flags[i] = IndexFormat.F_EMISSIVE
				continue
			step[i] = 1 + int(floor(clampf(val[i], 0.0, 0.999) * float(n_steps - 1)))
		# 3) facetas: juntas oscuras (JUNTA) o grietas emisivas
		for i in N:
			if piece[i] < 0 or cell[i] < 0 or edge[i] >= 0.85 or locked[i] == 1:
				continue
			var ms: RigDef.MatSpec = def.materials[slots[slot[i]]]
			if ms.facet == null:
				continue
			if ms.facet.crack > 0.0 and _hashi(cell[i]) < ms.facet.crack and slot_idx.has(ms.facet.crack_slot):
				var cs: int = slot_idx[ms.facet.crack_slot]
				slot[i] = cs
				var cp: StringName = slot_pal[cs]
				mat[i] = Palette.index(cp)
				var cn := Palette.steps(cp)
				step[i] = clampi(cn - 3 + int(round(1.0 - edge[i])) + int(pose.get(StringName("emit:%s" % def.pieces[piece[i]].id), 0)), 1, cn - 1)
				flags[i] = IndexFormat.F_EMISSIVE
			else:
				step[i] = maxi(1, step[i] - 1)
				flags[i] |= IndexFormat.F_JOINT
		# 4) ≤ N planos por masa grande (jerarquía de DA)
		_planes(val)
		# 5) filtro de moda (clústeres) + labio iluminado de las juntas
		_mode_filter()
		_lip(lw)
		# 6) texturas de material sobre el paso cuantizado
		_textures()
		# 7) especular de metales
		_specular(lw)
		# 8) luz de borde → CANTO
		_rim(lw, val)
		# 9) líneas interiores entre piezas declaradas
		_inner_lines()
		# anclas de pieza
		var centers := {}
		for i in N:
			if piece[i] < 0:
				continue
			var pi := piece[i]
			if not centers.has(pi):
				var pc: RigDef.Piece = def.pieces[pi]
				var c := (solved.xf[pc.bone] as Transform2D) * _center(pc)
				centers[pi] = Vector2(roundi(c.x), roundi(c.y))
			anc[i] = centers[pi]

	func _shadow(i: int, x: int, y: int, ld: Vector3) -> float:
		var p := Vector3(x + 0.5, y + 0.5, zb[i])
		var st := ld / maxf(0.25, Vector2(ld.x, ld.y).length())
		for _s in 18:
			p += st
			var sx := int(p.x)
			var sy := int(p.y)
			if sx < 0 or sy < 0 or sx >= W or sy >= H:
				break
			var j := sy * W + sx
			if piece[j] >= 0 and piece[j] != piece[i] and zb[j] > p.z + 1.5:
				return 0.35
		return 1.0

	func _planes(val: PackedFloat32Array) -> void:
		var by_piece := {}
		for i in N:
			if piece[i] < 0 or locked[i] == 1 or (flags[i] & (IndexFormat.F_EMISSIVE | IndexFormat.F_JOINT)) != 0:
				continue
			if not by_piece.has(piece[i]):
				by_piece[piece[i]] = PackedInt32Array()
			(by_piece[piece[i]] as PackedInt32Array).append(i)
		for pi: int in by_piece.keys():
			var ids: PackedInt32Array = by_piece[pi]
			var pc: RigDef.Piece = def.pieces[pi]
			var ms: RigDef.MatSpec = def.materials.get(pc.slot)
			var maxp := ms.planes if ms != null else 3
			var bb := _bbox(pc)
			if maxf(bb.size.x, bb.size.y) <= 12.0 or maxp <= 0:
				continue
			var distinct := {}
			for i in ids:
				distinct[step[i]] = true
			if distinct.size() <= maxp:
				continue
			# cuantiles del valor continuo → maxp bandas; cada banda toma el paso de su mediana
			var vs := PackedFloat32Array()
			for i in ids:
				vs.append(val[i])
			vs.sort()
			var cuts: Array[float] = []
			for k in range(1, maxp):
				cuts.append(vs[int(float(vs.size()) * k / maxp)])
			var band_steps := {}
			for k in maxp:
				var lo_i := int(float(vs.size()) * k / maxp)
				var hi_i := int(float(vs.size()) * (k + 1) / maxp) - 1
				var med := vs[clampi((lo_i + hi_i) / 2, 0, vs.size() - 1)]
				band_steps[k] = med
			for i in ids:
				var b := 0
				for c in cuts:
					if val[i] > c:
						b += 1
				var ns := Palette.steps(Palette.material_at(mat[i]), (flags[i] & IndexFormat.F_COLD) != 0)
				step[i] = 1 + int(floor(clampf(float(band_steps[b]), 0.0, 0.999) * float(ns - 1)))

	func _mode_filter() -> void:
		var out := step.duplicate()
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var i := y * W + x
				if piece[i] < 0 or locked[i] == 1 or (flags[i] & (IndexFormat.F_EMISSIVE | IndexFormat.F_JOINT)) != 0:
					continue
				var counts := {}
				var same := 0
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var j := i + oy * W + ox
						if piece[j] != piece[i] or mat[j] != mat[i] or locked[j] == 1 or _cold(j) != _cold(i):
							continue
						counts[step[j]] = int(counts.get(step[j], 0)) + 1
						if step[j] == step[i]:
							same += 1
				if same <= 2:
					var best := step[i]
					var bc := 0
					for k: int in counts.keys():
						if counts[k] > bc or (counts[k] == bc and k < best):
							bc = counts[k]
							best = k
					out[i] = best
		step = out

	func _lip(ld: Vector3) -> void:
		var lo := Vector2i(int(signf(ld.x)) if absf(ld.x) > 0.35 else 0, int(signf(ld.y)) if absf(ld.y) > 0.35 else 0)
		var out := step.duplicate()
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var i := y * W + x
				if piece[i] < 0 or locked[i] == 1 or (flags[i] & (IndexFormat.F_JOINT | IndexFormat.F_EMISSIVE)) != 0:
					continue
				var j := (y + lo.y) * W + (x + lo.x)
				if piece[j] == piece[i] and (flags[j] & IndexFormat.F_JOINT) != 0 and step[i] >= 2:
					var ns := Palette.steps(Palette.material_at(mat[i]), (flags[i] & IndexFormat.F_COLD) != 0)
					out[i] = mini(ns - 1, step[i] + 1)
		step = out

	func _textures() -> void:
		for i in N:
			if piece[i] < 0 or locked[i] == 1 or (flags[i] & IndexFormat.F_EMISSIVE) != 0:
				continue
			var ms: RigDef.MatSpec = def.materials.get(slots[slot[i]]) if slot[i] >= 0 else null
			if ms == null:
				continue
			var ns := Palette.steps(ms.palette, (flags[i] & IndexFormat.F_COLD) != 0)
			var l := Vector2(loc[i].x, loc[i].y)
			var s := step[i]
			var mid := s >= 2 and s <= ns - 2
			match ms.texture:
				&"mortar":
					# ladrillo 6×3 en el espacio del hueso; el mortero sólo se ve en luz media
					var row := int(floor(l.y / 3.0))
					var bx := l.x + (3.0 if row % 2 == 1 else 0.0)
					if mid and (fposmod(l.y, 3.0) < 1.0 or fposmod(bx, 6.0) < 1.0):
						step[i] = s - 1
						flags[i] |= IndexFormat.F_JOINT
				&"strands":
					if mid and fposmod(l.x + 0.35 * l.y, 3.0) < 1.0:
						step[i] = s - 1
				&"folds":
					if mid and sin(l.y * 0.9 + l.x * 0.25) > 0.82:
						step[i] = s - 1
				&"scratches":
					if s >= 2 and _hash(int(floor((l.x - l.y) / 2.0)), int(floor(l.y / 5.0)), piece[i]) > 0.93:
						step[i] = mini(ns - 1, s + 1)
				&"soot_grain":
					if mid and _hash(int(floor(l.x / 2.0)), int(floor(l.y / 2.0)), piece[i] + 3) > 0.86:
						step[i] = s - 1
			if ms.tex_fn.is_valid():
				step[i] = clampi(int(ms.tex_fn.call(l, step[i], ns)), 1, ns - 1)

	func _specular(ld: Vector3) -> void:
		var hv := (ld + Vector3(0, 0, 1)).normalized()
		for i in N:
			if piece[i] < 0 or locked[i] == 1 or (flags[i] & IndexFormat.F_EMISSIVE) != 0 or slot[i] < 0:
				continue
			var ms: RigDef.MatSpec = def.materials[slots[slot[i]]]
			if ms.spec and nrm[i].dot(hv) > 0.94:
				step[i] = Palette.steps(ms.palette, (flags[i] & IndexFormat.F_COLD) != 0) - 1

	func _rim(lw: Vector3, val: PackedFloat32Array) -> void:
		var lxy := Vector2(lw.x, lw.y).normalized()
		for y in H:
			for x in W:
				var i := y * W + x
				if piece[i] < 0 or locked[i] == 1 or (flags[i] & IndexFormat.F_EMISSIVE) != 0 or slot[i] < 0:
					continue
				var ms: RigDef.MatSpec = def.materials[slots[slot[i]]]
				if not ms.rim or not _is_edge(x, y):
					continue
				var n := nrm[i]
				var nxy := Vector2(n.x, n.y)
				if nxy.length() > 0.6 and nxy.normalized().dot(lxy) > 0.75 and n.dot(lw) > 0.3:
					flags[i] |= IndexFormat.F_BEVEL
					var ns := Palette.steps(ms.palette, (flags[i] & IndexFormat.F_COLD) != 0)
					step[i] = mini(ns - 1, step[i] + 1)

	func _is_edge(x: int, y: int) -> bool:
		for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var nx := x + o.x
			var ny := y + o.y
			if nx < 0 or ny < 0 or nx >= W or ny >= H or piece[ny * W + nx] < 0:
				return true
		return false

	func _inner_lines() -> void:
		var out := step.duplicate()
		for y in H:
			for x in W:
				var i := y * W + x
				if piece[i] < 0 or locked[i] == 1 or (flags[i] & IndexFormat.F_EMISSIVE) != 0:
					continue
				var pc: RigDef.Piece = def.pieces[piece[i]]
				if not pc.line:
					continue
				for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var nx := x + o.x
					var ny := y + o.y
					if nx < 0 or ny < 0 or nx >= W or ny >= H:
						continue
					var j := ny * W + nx
					if piece[j] < 0 or piece[j] == piece[i] or locked[j] == 1:
						continue
					if not (def.pieces[piece[j]] as RigDef.Piece).line:
						continue
					if zb[j] > zb[i] + 3.0:
						var ns := Palette.steps(Palette.material_at(mat[i]), (flags[i] & IndexFormat.F_COLD) != 0)
						out[i] = 1 if step[i] >= ns / 2 else 0
						break
		step = out

	# ----------------------------------------------------------------------------------------- sellos
	var _patch_count := 0

	func _stamp_material(s: RigDef.Stamp, m: Variant) -> Array:
		## → [paleta, es_ranura_@]
		var ms := String(m)
		if ms.begins_with("@"):
			var sl := StringName(ms.substr(1))
			if def.materials.has(sl):
				return [(def.materials[sl] as RigDef.MatSpec).palette, true]
			return [&"", true]
		if def.materials.has(StringName(ms)):
			return [(def.materials[StringName(ms)] as RigDef.MatSpec).palette, false]
		return [StringName(ms), false]

	func _stamps(pose: Dictionary, a: RigDef.Anim, frame: int) -> void:
		for s in def.stamps:
			if s.accessory != &"" and not bool(params.get(s.accessory, false)):
				continue
			if pose.get(StringName("hide:%s" % s.id), false):
				continue
			_apply_stamp(s, pose, false)
		if a != null:
			var key := "%s:%d" % [a.name, frame]
			_patch_count = 0
			for s: RigDef.Stamp in def.patches.get(key, []):
				_patch_count += _apply_stamp(s, pose, true)
			if _patch_count > 15:
				errors.append("PER-6: el parche de %s ocupa %d px (> 15): rediseñar la pose" % [key, _patch_count])

	func _apply_stamp(s: RigDef.Stamp, pose: Dictionary, is_patch: bool) -> int:
		if not solved.xf.has(s.bone):
			errors.append("sello %s: hueso %s inexistente" % [s.id, s.bone])
			return 0
		var rows: Array = s.rows
		# La vista del propio sello manda sobre la de su hueso (ojos y brillo en el mismo hueso, vistas distintas).
		var own_view: Variant = pose.get(StringName("view:%s" % s.id))
		var view: Variant = own_view if own_view != null else pose.get(StringName("view:%s" % s.bone))
		if view != null and s.views.has(view):
			rows = s.views[view]
		var at: Vector2 = (solved.xf[s.bone] as Transform2D) * s.at
		var ax := roundi(at.x)
		var ay := roundi(at.y)
		var emit_off := int(pose.get(StringName("emit:%s" % s.id), 0))
		var bone_z := float(solved.z[s.bone])
		var count := 0
		for ry in rows.size():
			var r: String = rows[ry]
			for rx in r.length():
				var ch := r[rx]
				if ch == "." or not s.legend.has(ch):
					continue
				var sx := (s.anchor.x - rx) if s.flip else (rx - s.anchor.x)
				var x := ax + sx
				var y := ay + ry - s.anchor.y
				if x < 0 or y < 0 or x >= W or y >= H:
					continue
				var i := y * W + x
				if not s.z_top and piece[i] >= 0 and (def.pieces[piece[i]] as RigDef.Piece).bone != s.bone:
					continue
				var e: Array = s.legend[ch]
				var mr := _stamp_material(s, e[0])
				var pal: StringName = mr[0]
				if not Palette.has(pal):
					errors.append("sello %s: material %s no está en la paleta" % [s.id, e[0]])
					continue
				var under_same := piece[i] >= 0 and mat[i] == Palette.index(pal)
				var iscold := under_same and (flags[i] & IndexFormat.F_COLD) != 0
				var ns := Palette.steps(pal, iscold)
				var st := 0
				var fl := IndexFormat.F_COLD if iscold else 0
				var sv: Variant = e[1]
				if typeof(sv) == TYPE_STRING or typeof(sv) == TYPE_STRING_NAME:
					var sstr := String(sv)
					if sstr == "LINE":
						st = 0
					else:
						var base := step[i] if under_same else ns / 2
						st = clampi(base + int(sstr), 1, ns - 1)
				else:
					st = int(sv)
					if mr[1]:
						st = int(round(float(st) * float(ns - 1) / 5.0))
					st = clampi(st, 0, ns - 1)
				if Palette.is_emissive(pal):
					fl = IndexFormat.F_EMISSIVE
					st = clampi(st + emit_off, 0, ns - 1)
				if piece[i] < 0:
					# sello fuera de la silueta: ancla propia y z del hueso
					piece[i] = _first_piece_of(s.bone)
					zb[i] = bone_z + 50.0
					anc[i] = Vector2(ax, ay)
				mat[i] = Palette.index(pal)
				step[i] = st
				flags[i] = fl
				locked[i] = 1
				count += 1
		return count

	func _first_piece_of(bone_name: StringName) -> int:
		for i in def.pieces.size():
			if def.pieces[i].bone == bone_name:
				return i
		return 0

	# ----------------------------------------------------------------------------------------- estela
	func _smear(sm: RigDef.Smear, p0: Dictionary, p1: Dictionary, front: bool) -> void:
		if not slot_idx.has(sm.slot):
			errors.append("estela: ranura %s inexistente" % sm.slot)
			return
		var pal: StringName = slot_pal[slot_idx[sm.slot]]
		var ns := Palette.steps(pal)
		var emissive := Palette.is_emissive(pal)
		var best := {}
		var samples := sm.samples if sm.samples > 0 else _smear_samples(sm, p0, p1)
		for k in samples + 1:
			var u := float(k) / samples
			var sp := RigPose.solve(def, RigPose.blend(p0, p1, u))
			if not sp.xf.has(sm.bone):
				return
			var c: Vector2 = (sp.xf[sm.bone] as Transform2D) * sm.point
			# media luna: fina en la cola, gruesa en la cabeza, y se afila en la punta final
			var r := sm.width * 0.5 * pow(u, 0.8) * (1.0 - 0.35 * pow(u, 6.0))
			for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
				for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
					if x < 0 or y < 0 or x >= W or y >= H:
						continue
					if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
						var key := y * W + x
						best[key] = maxf(float(best.get(key, 0.0)), u)
		for key: int in best.keys():
			if front:
				if locked[key] == 1:
					continue
			elif piece[key] >= 0:
				continue
			var u2: float = best[key]
			if u2 < 0.12:
				continue
			var st := clampi(int(round(lerpf(2.0, float(ns - 1), u2))), 1, ns - 1)
			if not front:
				# detrás: se pinta en el G-buffer como una pieza plana muy lejana
				piece[key] = -2
			mat[key] = Palette.index(pal)
			step[key] = st
			flags[key] = IndexFormat.F_EMISSIVE if emissive else 0
			anc[key] = Vector2(key % W, key / W)
			locked[key] = 1
			if front:
				piece[key] = maxi(piece[key], 0)
				zb[key] = 1e6

	## Muestras para que dos discos consecutivos de la estela se solapen: longitud del arco / medio píxel de avance
	## por radio pequeño. Se mide con 12 tramos; acotado para no disparar el coste en arcos enormes.
	func _smear_samples(sm: RigDef.Smear, p0: Dictionary, p1: Dictionary) -> int:
		var length := 0.0
		var prev := Vector2.ZERO
		for k in 13:
			var sp := RigPose.solve(def, RigPose.blend(p0, p1, float(k) / 12.0))
			if not sp.xf.has(sm.bone):
				return 16
			var c: Vector2 = (sp.xf[sm.bone] as Transform2D) * sm.point
			if k > 0:
				length += c.distance_to(prev)
			prev = c
		return clampi(ceili(length / 1.5), 16, 160)

	# ----------------------------------------------------------------------------------------- limpieza y contorno
	func _orphans() -> void:
		var out := step.duplicate()
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var i := y * W + x
				if mat[i] < 0 or locked[i] == 1 or (flags[i] & IndexFormat.F_EMISSIVE) != 0:
					continue
				var match_n := 0
				var valid := 0
				var counts := {}
				for o: int in [-1, 1, -W, W]:
					var j := i + o
					if mat[j] != mat[i] or locked[j] == 1 or _cold(j) != _cold(i):
						continue
					valid += 1
					if step[j] == step[i]:
						match_n += 1
					counts[step[j]] = int(counts.get(step[j], 0)) + 1
				if valid >= 3 and match_n == 0:
					var best := step[i]
					var bc := 0
					for k: int in counts.keys():
						if counts[k] > bc or (counts[k] == bc and k < best):
							bc = counts[k]
							best = k
					out[i] = best
		step = out

	func _outline() -> void:
		var filled := PackedByteArray()
		filled.resize(N)
		for i in N:
			filled[i] = 1 if mat[i] >= 0 else 0
		for y in H:
			for x in W:
				var i := y * W + x
				if filled[i] == 1:
					continue
				var any := false
				var below := false
				var best_lit := -1
				var best_j := -1
				for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var nx := x + o.x
					var ny := y + o.y
					if nx < 0 or ny < 0 or nx >= W or ny >= H:
						continue
					var j := ny * W + nx
					if filled[j] == 0:
						continue
					any = true
					if o.y == -1:
						below = true
					var ns := Palette.steps(Palette.material_at(mat[j]), (flags[j] & IndexFormat.F_COLD) != 0)
					var lit := int(100.0 * float(step[j]) / maxf(1.0, float(ns - 1)))
					if (flags[j] & IndexFormat.F_EMISSIVE) != 0:
						lit = 0
					if lit > best_lit:
						best_lit = lit
						best_j = j
				if not any:
					continue
				# sel-out: el borde del lado iluminado toma el paso 1 del material vecino; sombra y base → contorno
				if not below and best_lit >= 60 and best_j >= 0:
					mat[i] = mat[best_j]
					step[i] = 1
					flags[i] = flags[best_j] & IndexFormat.F_COLD
				else:
					mat[i] = 0
					step[i] = 0
					flags[i] = 0
				anc[i] = anc[best_j] if best_j >= 0 else Vector2(x, y)

	func _pack() -> Image:
		var img := IndexFormat.blank(W, H)
		for y in H:
			for x in W:
				var i := y * W + x
				if mat[i] < 0:
					continue
				var d := Vector2i(roundi(anc[i].x) - x, roundi(anc[i].y) - y)
				# red de seguridad: el paso nunca sale de la rampa (cálida o fría) del píxel
				var ns := Palette.steps(Palette.material_at(mat[i]), _cold(i))
				img.set_pixel(x, y, IndexFormat.pack(mat[i], mini(step[i], ns - 1), flags[i], d))
		return img

	func _cold(i: int) -> bool:
		return (flags[i] & IndexFormat.F_COLD) != 0

	# ----------------------------------------------------------------------------------------- ruido
	static func _hash(x: int, y: int, s: int) -> float:
		return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.17) * 43758.5453, 1.0)

	static func _hashi(n: int) -> float:
		return fposmod(sin(float(n) * 12.9898 + 4.1414) * 43758.5453, 1.0)
