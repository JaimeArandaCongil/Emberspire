extends Node
## Prueba de concepto del "rig renderer" (v0.4, artista técnico).
## Una criatura definida como PIEZAS con volumen (elipsoides y cápsulas cónicas) colgadas de HUESOS 2D.
## Pipeline por fotograma:
##   1. pose → transformaciones de hueso (rotación en el plano de pantalla + traslación entera)
##   2. rasterizado → G-buffer a resolución de arte (pieza, material, normal, profundidad, celda Voronoi, borde)
##   3. limpieza de silueta (espolones y muescas de 1 px)
##   4. sombreado: luz (direccional o puntual) + ambiente cenital + sombra arrojada en pantalla + AO
##      → ÍNDICE de rampa (no color) → filtro de moda para formar clústeres → rampa con desplazamiento de tono
##   5. emisivos (grietas de magma, ojos) + rebote de su luz sobre la roca cercana
##   6. luz de borde 1 px del lado de la luz, contorno selectivo (sel-out), limpieza de huérfanos
## Exporta tiras PNG ampliadas en tests/_review_art/v04/tecnico/out/.

const OUT := "res://tests/_review_art/v04/tecnico/out/"
const W := 96
const H := 84
const FLOOR := 79
const SCALE := 5

# --- Paleta (todas salen de PAL/BIOMES de art.gd o son pasos intermedios de la misma rampa) ----------
const K := Color("1a0f12")
# Roca del acto 1: BIOMES[0] deep→hi + un paso extra de brillo; sombras hacia violeta, luces hacia ocre.
const ROCK := [Color("1f141c"), Color("2a1c26"), Color("473338"), Color("6e5450"), Color("a08270"), Color("ccb09a")]
# La misma roca bañada por el resplandor del magma (rebote): tono desplazado a naranja.
const ROCK_WARM := [Color("2a1c26"), Color("5a2a26"), Color("8a3a26"), Color("b8582a"), Color("e08a3a"), Color("ffb43a")]
const MAGMA := [Color("7a1a16"), Color("c2321e"), Color("ff6a1a"), Color("ffb43a"), Color("ffe08a"), Color("fff4c8")]
const HORN := [Color("2a1c26"), Color("473338"), Color("7a5a52"), Color("a08270"), Color("d8c4a4"), Color("f4e4c8")]
const IRON := [Color("1a1420"), Color("2a2430"), Color("3e3a48"), Color("5e5c6a"), Color("9aa0a8"), Color("d0d4d8")]

const MATS := {
	"rock": {"ramp": ROCK, "facet": 0.42, "cell": 9.0, "crack": 0.0},
	"rockc": {"ramp": ROCK, "facet": 0.42, "cell": 8.0, "crack": 0.35},   # roca con grietas de magma
	"horn": {"ramp": HORN, "facet": 0.0, "cell": 0.0, "crack": 0.0},
	"iron": {"ramp": IRON, "facet": 0.0, "cell": 0.0, "crack": 0.0},
	"eye": {"ramp": MAGMA, "facet": 0.0, "cell": 0.0, "crack": 0.0, "emit": true},
	"core": {"ramp": MAGMA, "facet": 0.0, "cell": 0.0, "crack": 0.0, "emit": true},
}

# --- Esqueleto: [nombre, padre, pivote en el espacio del padre, z relativa] --------------------------
const BONES := [
	["root", "", Vector2(54, 47), 0.0],
	["leg_f", "root", Vector2(6, 4), -7.0],
	["shin_f", "leg_f", Vector2(0, 11), 0.0],
	["leg_n", "root", Vector2(-5, 5), 7.0],
	["shin_n", "leg_n", Vector2(0, 11), 0.0],
	["spine", "root", Vector2(1, -1), 0.0],
	["head", "spine", Vector2(-17, -21), 9.0],
	["jaw", "head", Vector2(-2, 1), 0.0],
	["arm_f", "spine", Vector2(9, -16), -12.0],
	["fore_f", "arm_f", Vector2(0, 12), 0.0],
	["arm_n", "spine", Vector2(-7, -16), 13.0],
	["fore_n", "arm_n", Vector2(0, 12), 0.0],
]

# --- Piezas: [hueso, tipo, material, params] (coordenadas en el espacio del hueso; z hacia el espectador)
# "ell": centro Vector3, radios Vector3 · "cap": a Vector3, b Vector3, ra, rb
const PIECES := [
	# pierna lejana
	["leg_f", "cap", "rock", [Vector3(0, 0, 0), Vector3(0, 11, 0), 6.0, 5.0]],
	["shin_f", "cap", "rock", [Vector3(0, 0, 0), Vector3(-1, 8, 0), 5.0, 6.0]],
	["shin_f", "ell", "rock", [Vector3(-3, 11, 0), Vector3(8, 3.6, 6)]],
	# brazo lejano (detrás del torso)
	["arm_f", "ell", "rock", [Vector3(1, -1, 0), Vector3(8, 7, 7)]],
	["arm_f", "cap", "rock", [Vector3(0, 0, 0), Vector3(0, 12, 0), 6.0, 5.0]],
	["fore_f", "cap", "rockc", [Vector3(0, 0, 0), Vector3(0, 11, 0), 5.0, 7.0]],
	["fore_f", "ell", "rock", [Vector3(0, 15, 0), Vector3(7.5, 6.5, 7)]],
	# tronco
	["root", "ell", "rock", [Vector3(0, 1, 0), Vector3(11, 7, 9)]],
	["spine", "ell", "rockc", [Vector3(2, -13, 0), Vector3(14, 13, 11)]],
	["spine", "ell", "rock", [Vector3(-2, -3, 2), Vector3(11, 8, 10)]],
	["spine", "ell", "rock", [Vector3(9, -21, -2), Vector3(10, 9, 9)]],        # joroba
	["spine", "cap", "rock", [Vector3(10, -24, -1), Vector3(14, -33, -1), 3.6, 2.6]],   # chimenea 1
	["spine", "cap", "rock", [Vector3(3, -26, -4), Vector3(4, -33, -4), 3.0, 2.2]],     # chimenea 2
	["spine", "ell", "core", [Vector3(14, -33.5, -1), Vector3(2.0, 1.2, 2.0)]],
	["spine", "ell", "core", [Vector3(4, -33.2, -4), Vector3(1.6, 1.0, 1.6)]],
	["spine", "ell", "core", [Vector3(-6, -11, 11), Vector3(3.2, 4.2, 2)]],      # núcleo del pecho
	# cabeza hundida entre los hombros
	["head", "ell", "rock", [Vector3(-1, -1, 0), Vector3(7.5, 6.5, 6.5)]],
	["head", "ell", "rock", [Vector3(-4, -4.5, 2), Vector3(6.5, 2.6, 6)]],      # ceja
	["head", "ell", "eye", [Vector3(-7.5, -2.0, 5), Vector3(2.2, 1.6, 1.4)]],
	["head", "cap", "horn", [Vector3(2, -6, -1), Vector3(6, -10, -1), 2.2, 1.6]],
	["head", "cap", "horn", [Vector3(6, -10, -1), Vector3(5, -15, -1), 1.6, 0.6]],
	["jaw", "ell", "rock", [Vector3(-2, 2, 0), Vector3(6.5, 3.4, 5.5)]],
	["jaw", "cap", "horn", [Vector3(-7, 0.5, 5), Vector3(-7.5, -2.5, 5), 1.0, 0.5]],   # colmillo
	# pierna cercana
	["leg_n", "cap", "rock", [Vector3(0, 0, 0), Vector3(0, 11, 0), 6.5, 5.5]],
	["shin_n", "cap", "rock", [Vector3(0, 0, 0), Vector3(-1, 8, 0), 5.5, 6.5]],
	["shin_n", "ell", "rock", [Vector3(-3, 11, 0), Vector3(8.5, 3.8, 6)]],
	# brazo cercano (el que golpea)
	["arm_n", "ell", "rockc", [Vector3(1, -1, 0), Vector3(7.5, 6.5, 7)]],       # hombrera
	["arm_n", "cap", "rock", [Vector3(0, 0, 0), Vector3(0, 12, 0), 6.5, 5.5]],
	["fore_n", "cap", "rockc", [Vector3(0, 0, 0), Vector3(0, 11, 0), 5.5, 7.5]],
	["fore_n", "cap", "iron", [Vector3(0, 6.5, 0), Vector3(0, 8, 0), 6.9, 7.1]],    # grillete
	["fore_n", "ell", "rock", [Vector3(0, 15, 0), Vector3(8, 7, 7.5)]],          # puño
]

# Calcas a mano (ASCII) ancladas a un hueso: el detalle "de autor" que la geometría no da.
# k = línea oscura · W/w = dientes · h = +1 tono · s = -1 tono. Coordenadas en el espacio del hueso.
const DECALS := [
	{"bone": "head", "bones": ["head", "jaw"], "origin": Vector2(-11, -5), "rows": [
		"............",
		".kkkkkkk....",
		"..s.....s...",
		"............",
		"..........s.",
		"............",
		"kkkkkkkk....",
		".WwWwWk.....",
		"..h.h.......",
	]},
	# Nudillos del puño cercano: tres surcos con su labio iluminado.
	{"bone": "fore_n", "bones": ["fore_n"], "origin": Vector2(-8, 14), "rows": [
		"...........",
		"..kh.......",
		"...k.......",
		"..k.kh.....",
		"...k.k.....",
		"....k.kh...",
		".....k.k...",
		".......k...",
	]},
]

# Pose de reposo (ángulos en radianes; positivo = horario en pantalla) y desplazamiento del root.
const REST := {"root": 0.0, "leg_f": -0.24, "shin_f": 0.12, "leg_n": 0.3, "shin_n": -0.22, "spine": -0.32,
	"head": 0.30, "jaw": 0.0, "arm_f": -0.12, "fore_f": -0.05, "arm_n": 0.62, "fore_n": 0.1}

var _bone_xf := {}     # nombre → Transform2D (mundo)
var _bone_z := {}
var _seeds := []       # por pieza: Array de Vector3 (espacio del hueso)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_make_seeds()
	var bg := Color("2e2226")
	var key_fire := {"kind": "dir", "dir": Vector3(-0.70, -0.50, 0.50).normalized(), "rim": Color("ff8a3a"), "warm": true}
	# Idle: 8 fotogramas.
	var idle: Array = []
	var t0 := Time.get_ticks_usec()
	for f in 8:
		idle.append(render(_pose_idle(f), key_fire, f, false))
	print("rig_poc: %.1f ms por fotograma (GDScript, %dx%d, %d piezas)" % [(Time.get_ticks_usec() - t0) / 8000.0, W, H, PIECES.size()])
	_strip(idle, bg, SCALE).save_png(OUT + "idle_8f.png")
	# Ataque: 6 fotogramas.
	var atk: Array = []
	for f in 6:
		atk.append(render(_pose_attack(f), key_fire, f, f == 2))
	_strip(atk, bg, SCALE).save_png(OUT + "attack_6f.png")
	# Luz dinámica: el mismo fotograma con la luz en otras posiciones.
	var lights := [
		key_fire,
		{"kind": "point", "pos": Vector3(12, 78, 26), "range": 150.0, "rim": Color("ff6a1a"), "warm": true},   # brasa baja delante
		{"kind": "point", "pos": Vector3(92, 8, 22), "range": 115.0, "rim": Color("ffb43a"), "warm": true},   # antorcha arriba detrás
		{"kind": "dir", "dir": Vector3(0.7, -0.45, 0.45).normalized(), "rim": Color("8ab4d0"), "warm": false},  # luna fría
	]
	var lit: Array = []
	for L: Dictionary in lights:
		lit.append(render(_pose_idle(0), L, 0, false))
	_strip(lit, bg, SCALE).save_png(OUT + "light_positions.png")
	# Parpadeo de la Forja: 6 fotogramas con la intensidad de la luz oscilando (misma pose).
	var flick: Array = []
	for f in 6:
		var amp: float = [1.0, 0.82, 0.95, 0.7, 0.9, 0.78][f]
		var L2 := key_fire.duplicate()
		L2["gain"] = amp
		flick.append(render(_pose_idle(0), L2, 0, false))
	_strip(flick, bg, SCALE).save_png(OUT + "forge_flicker.png")
	# G-buffer de depuración (lo que el shader de juego recibiría): normales y material.
	var gb := raster(_pose_idle(0))
	_strip([_debug_normals(gb), _debug_ids(gb)], bg, SCALE).save_png(OUT + "gbuffer.png")
	# Tamaño real ×4 (como en el juego) junto al gólem actual y en contexto sobre el fondo del acto 1.
	_context(idle[0], atk[3]).save_png(OUT + "context_x4.png")
	_strip([idle[0], atk[3]], bg, 8).save_png(OUT + "zoom_x8.png")
	print("rig_poc: OK")
	get_tree().quit()


# ============================================================================ esqueleto y poses
func _pose_idle(f: int) -> Dictionary:
	var p := REST.duplicate()
	var t := TAU * f / 8.0
	# Respiración: el pecho sube 1 px (translación entera) y los brazos van con retraso (overlap).
	p["_dy"] = 1 if (f >= 3 and f <= 6) else 0
	p["_dx"] = 0
	p["spine"] = REST["spine"] + 0.035 * sin(t)
	p["head"] = REST["head"] + 0.05 * sin(t - 0.9)
	p["jaw"] = 0.06 * maxf(0.0, sin(t - 1.4))
	p["arm_n"] = REST["arm_n"] + 0.05 * sin(t - 1.2)
	p["fore_n"] = REST["fore_n"] + 0.06 * sin(t - 1.8)
	p["arm_f"] = REST["arm_f"] + 0.045 * sin(t - 1.5)
	p["fore_f"] = REST["fore_f"] + 0.05 * sin(t - 2.1)
	p["_glow"] = 0.5 + 0.5 * sin(t)
	return p


func _pose_attack(f: int) -> Dictionary:
	var p := REST.duplicate()
	p["_dy"] = 0
	p["_dx"] = 0
	p["_glow"] = 0.6
	match f:
		0:  # anticipación: se echa atrás, el brazo sube
			p["spine"] = -0.12; p["head"] = 0.2; p["arm_n"] = -1.2; p["fore_n"] = -0.9; p["arm_f"] = 0.8
			p["_dx"] = 2; p["_dy"] = 1; p["jaw"] = 0.15
		1:  # pico de la carga: aplastado, puño sobre la cabeza
			p["spine"] = -0.02; p["head"] = 0.12; p["arm_n"] = -2.05; p["fore_n"] = -1.25; p["arm_f"] = 0.95
			p["_dx"] = 3; p["_dy"] = 2; p["jaw"] = 0.3; p["_glow"] = 1.0
		2:  # estela (smear): a medio camino
			p["spine"] = -0.42; p["head"] = 0.3; p["arm_n"] = -3.75; p["fore_n"] = -0.2; p["arm_f"] = 0.5
			p["_dx"] = -2; p["_dy"] = 0; p["jaw"] = 0.3; p["_glow"] = 1.0
		3:  # impacto: puño contra el suelo delante
			p["spine"] = -0.62; p["head"] = 0.42; p["arm_n"] = 0.78 - TAU; p["fore_n"] = 0.0; p["arm_f"] = 0.2; p["fore_f"] = 0.3
			p["_dx"] = -5; p["_dy"] = 2; p["jaw"] = 0.25; p["_glow"] = 1.0; p["leg_n"] = 0.4; p["leg_f"] = -0.36
			p["_impact"] = 0
		4:  # mantiene el peso
			p["spine"] = -0.58; p["head"] = 0.36; p["arm_n"] = 0.76; p["fore_n"] = 0.04; p["arm_f"] = 0.25; p["fore_f"] = 0.25
			p["_dx"] = -5; p["_dy"] = 2; p["jaw"] = 0.1; p["_glow"] = 0.8; p["leg_n"] = 0.38; p["leg_f"] = -0.34
			p["_impact"] = 1
		5:  # recuperación
			p["spine"] = -0.45; p["head"] = 0.33; p["arm_n"] = 0.6; p["fore_n"] = 0.12; p["arm_f"] = 0.35
			p["_dx"] = -2; p["_dy"] = 1; p["_glow"] = 0.6
	return p


func _solve(p: Dictionary) -> void:
	_bone_xf.clear()
	_bone_z.clear()
	for b: Array in BONES:
		var name: String = b[0]
		var parent: String = b[1]
		var pivot: Vector2 = b[2]
		var ang: float = p.get(name, 0.0)
		var local := Transform2D(ang, pivot)
		if parent == "":
			local = Transform2D(ang, pivot + Vector2(p.get("_dx", 0), p.get("_dy", 0)))
			_bone_xf[name] = local
			_bone_z[name] = b[3]
		else:
			_bone_xf[name] = _bone_xf[parent] * local
			_bone_z[name] = _bone_z[parent] + b[3]
	# Los pies no se deslizan: el root se mueve, pero las piernas se contrarrestan para clavar los talones.
	# (Simplificación: compensamos el empuje horizontal del root en las piernas.)


func _make_seeds() -> void:
	_seeds.clear()
	for i in PIECES.size():
		var pc: Array = PIECES[i]
		var mat: Dictionary = MATS[pc[2]]
		var arr: Array = []
		var cell: float = mat["cell"]
		if cell > 0.0:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 + i * 7
			var bb := _bbox(pc)
			var area := bb.size.x * bb.size.y
			var n := maxi(3, int(area / (cell * cell)))
			for _k in n:
				var xy := Vector2(rng.randf_range(bb.position.x, bb.end.x), rng.randf_range(bb.position.y, bb.end.y))
				var hit := _prim_local(pc, xy)
				if hit.is_empty():
					continue
				arr.append(Vector3(xy.x, xy.y, hit["z"]))
		_seeds.append(arr)


func _bbox(pc: Array) -> Rect2:
	var pr: Array = pc[3]
	if pc[1] == "ell":
		var c: Vector3 = pr[0]
		var r: Vector3 = pr[1]
		return Rect2(c.x - r.x, c.y - r.y, r.x * 2, r.y * 2)
	var a: Vector3 = pr[0]
	var b: Vector3 = pr[1]
	var rr: float = maxf(pr[2], pr[3])
	var mn := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(rr, rr)
	var mx := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(rr, rr)
	return Rect2(mn, mx - mn)


## Superficie frontal de una primitiva en el espacio del hueso: {} si no hay impacto, o {z, n (local)}.
func _prim_local(pc: Array, q: Vector2) -> Dictionary:
	var pr: Array = pc[3]
	if pc[1] == "ell":
		var c: Vector3 = pr[0]
		var r: Vector3 = pr[1]
		var dx := (q.x - c.x) / r.x
		var dy := (q.y - c.y) / r.y
		var s := dx * dx + dy * dy
		if s >= 1.0:
			return {}
		var dz := sqrt(1.0 - s)
		var n := Vector3(dx / r.x, dy / r.y, dz / r.z).normalized()
		return {"z": c.z + dz * r.z, "n": n}
	var a: Vector3 = pr[0]
	var b: Vector3 = pr[1]
	var ab := Vector2(b.x - a.x, b.y - a.y)
	var l2 := ab.length_squared()
	var t := 0.0
	if l2 > 0.0001:
		t = clampf((q - Vector2(a.x, a.y)).dot(ab) / l2, 0.0, 1.0)
	var rad: float = lerpf(pr[2], pr[3], t)
	var cp := a.lerp(b, t)
	var d := q - Vector2(cp.x, cp.y)
	var dd := d.length_squared()
	if dd >= rad * rad:
		return {}
	var hz := sqrt(rad * rad - dd)
	return {"z": cp.z + hz, "n": Vector3(d.x, d.y, hz) / rad}


# ============================================================================ rasterizado (G-buffer)
func raster(p: Dictionary) -> Dictionary:
	_solve(p)
	var N := W * H
	var piece := PackedInt32Array(); piece.resize(N); piece.fill(-1)
	var zb := PackedFloat32Array(); zb.resize(N); zb.fill(-1e9)
	var nrm: Array = []; nrm.resize(N)
	var cell := PackedInt32Array(); cell.resize(N); cell.fill(-1)
	var edge := PackedFloat32Array(); edge.resize(N); edge.fill(99.0)
	var pos3: Array = []; pos3.resize(N)
	# Inversas por hueso.
	var inv := {}
	for k: String in _bone_xf.keys():
		inv[k] = (_bone_xf[k] as Transform2D).affine_inverse()
	for i in PIECES.size():
		var pc: Array = PIECES[i]
		var bone: String = pc[0]
		var xf: Transform2D = _bone_xf[bone]
		var ix: Transform2D = inv[bone]
		var bz: float = _bone_z[bone]
		# Caja envolvente en pantalla.
		var bb := _bbox(pc)
		var corners := [bb.position, Vector2(bb.end.x, bb.position.y), Vector2(bb.position.x, bb.end.y), bb.end]
		var mn := Vector2(1e9, 1e9)
		var mx := Vector2(-1e9, -1e9)
		for c: Vector2 in corners:
			var w := xf * c
			mn = mn.min(w)
			mx = mx.max(w)
		var x0 := maxi(0, int(floor(mn.x)) - 1)
		var x1 := mini(W - 1, int(ceil(mx.x)) + 1)
		var y0 := maxi(0, int(floor(mn.y)) - 1)
		var y1 := mini(H - 1, int(ceil(mx.y)) + 1)
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var q: Vector2 = ix * Vector2(x + 0.5, y + 0.5)
				var hit := _prim_local(pc, q)
				if hit.is_empty():
					continue
				var z: float = hit["z"] + bz
				var idx := y * W + x
				if z <= zb[idx]:
					continue
				zb[idx] = z
				piece[idx] = i
				var nl: Vector3 = hit["n"]
				# Normal: rotamos sólo xy (los huesos giran en el plano de pantalla).
				var nxy := xf.basis_xform(Vector2(nl.x, nl.y))
				var nw := Vector3(nxy.x, nxy.y, nl.z)
				pos3[idx] = Vector3(x + 0.5, y + 0.5, z)
				# Facetas: Voronoi en el espacio del hueso → la textura viaja con la pieza (coherencia temporal).
				var sd: Array = _seeds[i]
				var mat: Dictionary = MATS[pc[2]]
				if sd.size() > 0:
					var lp := Vector3(q.x, q.y, hit["z"])
					var d1 := 1e9
					var d2 := 1e9
					var c1 := -1
					for s in sd.size():
						var dd: float = lp.distance_squared_to(sd[s])
						if dd < d1:
							d2 = d1; d1 = dd; c1 = s
						elif dd < d2:
							d2 = dd
					cell[idx] = i * 100 + c1
					edge[idx] = sqrt(d2) - sqrt(d1)
					# Normal de faceta: la normal de la superficie en la semilla (estable entre fotogramas).
					var seed_q := Vector2(sd[c1].x, sd[c1].y)
					var sh := _prim_local(pc, seed_q)
					if not sh.is_empty():
						var sn: Vector3 = sh["n"]
						var sxy := xf.basis_xform(Vector2(sn.x, sn.y))
						var fn := Vector3(sxy.x, sxy.y, sn.z)
						nw = nw.lerp(fn, mat["facet"]).normalized()
				nrm[idx] = nw
	var gb := {"piece": piece, "z": zb, "n": nrm, "cell": cell, "edge": edge, "pos": pos3, "pose": p}
	_clean_silhouette(gb)
	return gb


## Limpieza de silueta: quita espolones (≤1 vecino) y rellena muescas (≥3 vecinos sólidos).
func _clean_silhouette(gb: Dictionary) -> void:
	var piece: PackedInt32Array = gb["piece"]
	var zb: PackedFloat32Array = gb["z"]
	var nrm: Array = gb["n"]
	var cell: PackedInt32Array = gb["cell"]
	var edge: PackedFloat32Array = gb["edge"]
	var pos3: Array = gb["pos"]
	for _it in 2:
		var changed := false
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var idx := y * W + x
				var nb := 0
				var donor := -1
				for o: int in [-1, 1, -W, W]:
					if piece[idx + o] >= 0:
						nb += 1
						donor = idx + o
				if piece[idx] >= 0 and nb <= 1:
					piece[idx] = -1
					changed = true
				elif piece[idx] < 0 and nb >= 3:
					piece[idx] = piece[donor]; zb[idx] = zb[donor]; nrm[idx] = nrm[donor]
					cell[idx] = cell[donor]; edge[idx] = edge[donor]
					pos3[idx] = Vector3(x + 0.5, y + 0.5, zb[donor])
					changed = true
		if not changed:
			break
	gb["piece"] = piece; gb["z"] = zb; gb["cell"] = cell; gb["edge"] = edge


# ============================================================================ sombreado
const THRESH := [-1.0, 0.24, 0.42, 0.62, 0.84]   # valor → índice de rampa (0..5)


func render(p: Dictionary, light: Dictionary, frame: int, smear: bool) -> Image:
	var gb := raster(p)
	var piece: PackedInt32Array = gb["piece"]
	var zb: PackedFloat32Array = gb["z"]
	var nrm: Array = gb["n"]
	var pos3: Array = gb["pos"]
	var cell: PackedInt32Array = gb["cell"]
	var edge: PackedFloat32Array = gb["edge"]
	var gain: float = light.get("gain", 1.0)
	var glow: float = p.get("_glow", 0.5)
	var N := W * H
	var ridx := PackedInt32Array(); ridx.resize(N); ridx.fill(-1)
	var emit := PackedInt32Array(); emit.resize(N); emit.fill(-1)   # índice en MAGMA si emisivo
	var lamv := PackedFloat32Array(); lamv.resize(N)
	for y in H:
		for x in W:
			var idx := y * W + x
			var pi := piece[idx]
			if pi < 0:
				continue
			var pc: Array = PIECES[pi]
			var mname: String = pc[2]
			var mat: Dictionary = MATS[mname]
			var n: Vector3 = nrm[idx]
			var P: Vector3 = pos3[idx]
			if mat.get("emit", false):
				# Ojos y núcleos: rampa de magma por "esfericidad" (centro blanco, borde rojo) + pulso.
				var e := 2 + int(round(n.z * 2.4 + glow))
				if mname == "eye":
					e += 1
				emit[idx] = clampi(e, 1, 5)
				continue
			var Ld: Vector3
			var att := 1.0
			if light["kind"] == "dir":
				Ld = light["dir"]
			else:
				var lv: Vector3 = (light["pos"] as Vector3) - P
				att = clampf(1.0 - lv.length() / float(light["range"]), 0.0, 1.0)
				att = att * att * 1.6
				Ld = lv.normalized()
			var lam := maxf(0.0, n.dot(Ld)) * att * gain
			# Sombra arrojada en espacio de pantalla (marcha sobre el z-buffer hacia la luz).
			var sh := 1.0
			var step := Ld / maxf(0.25, Vector2(Ld.x, Ld.y).length())
			var sp := P
			for _s in 18:
				sp += step
				var sx := int(sp.x)
				var sy := int(sp.y)
				if sx < 0 or sy < 0 or sx >= W or sy >= H:
					break
				var j := sy * W + sx
				if piece[j] >= 0 and piece[j] != pi and zb[j] > sp.z + 1.5:
					sh = 0.35
					break
			# AO: vecinos de otras piezas más cerca del espectador.
			var occ := 0
			for o: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				var ox := x + o.x
				var oy := y + o.y
				if ox < 0 or oy < 0 or ox >= W or oy >= H:
					continue
				var j2 := oy * W + ox
				if piece[j2] >= 0 and piece[j2] != pi and zb[j2] > zb[idx] + 2.5:
					occ += 1
			var amb := 0.12 + 0.12 * clampf(-n.y, 0.0, 1.0) + 0.06 * n.z
			var v := amb + 0.80 * lam * sh - 0.07 * occ
			lamv[idx] = lam * sh
			var ri := 0
			for t: float in THRESH:
				if v > t:
					ri += 1
			# Grietas y aristas de las facetas (Voronoi): crevice oscuro o magma.
			if cell[idx] >= 0 and edge[idx] < 0.85:
				var crack: float = mat["crack"]
				var h := _hash(cell[idx])
				if crack > 0.0 and h < crack:
					emit[idx] = 2 + int(glow * 1.6 + (1.0 - edge[idx]))
				else:
					ri = maxi(1, ri - 1)
			ridx[idx] = ri
	# Filtro de moda por pieza: convierte el ruido de cuantización en clústeres limpios.
	ridx = _mode_filter(ridx, piece, emit)
	# Labio iluminado de las grietas: el píxel que tiene una grieta entre él y la luz recibe +1 (piedra tallada).
	var ldir := Vector2(light["dir"].x, light["dir"].y) if light["kind"] == "dir" else Vector2(-0.7, -0.7)
	var lo := Vector2i(int(signf(ldir.x)) if absf(ldir.x) > 0.35 else 0, int(signf(ldir.y)) if absf(ldir.y) > 0.35 else 0)
	var lip := ridx.duplicate()
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var idx := y * W + x
			if ridx[idx] < 1 or emit[idx] >= 0 or edge[idx] < 0.85:
				continue
			var j := (y + lo.y) * W + (x + lo.x)
			if piece[j] == piece[idx] and edge[j] < 0.85 and emit[j] < 0 and ridx[idx] >= 2:
				lip[idx] = mini(5, ridx[idx] + 1)
	ridx = lip
	# Compone colores.
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var near_emit := _near_mask(emit, 1)
	var locked := PackedByteArray(); locked.resize(W * H)
	var rim_col: Color = light["rim"]
	var Lxy: Vector2
	if light["kind"] == "dir":
		Lxy = Vector2(light["dir"].x, light["dir"].y).normalized()
	for y in H:
		for x in W:
			var idx := y * W + x
			var pi := piece[idx]
			if pi < 0:
				continue
			if emit[idx] >= 0:
				img.set_pixel(x, y, MAGMA[clampi(emit[idx], 0, 5)])
				continue
			var mat: Dictionary = MATS[PIECES[pi][2]]
			var ramp: Array = mat["ramp"]
			var ri := ridx[idx]
			var col: Color = ramp[clampi(ri, 0, 5)]
			# Rebote del magma sobre la roca vecina (luz local, otra rampa → mismo valor, tono naranja).
			if near_emit[idx] > 0 and ramp == ROCK and ri <= 3:
				col = ROCK_WARM[clampi(ri + 1, 0, 5)]
			# Línea interior: si una pieza vecina está claramente delante, este píxel es el borde de la de detrás.
			if _behind(piece, zb, x, y):
				col = ramp[1] if ri >= 4 else ramp[0]
			# Luz de borde: 1 px en la silueta del lado de la luz.
			var n: Vector3 = nrm[idx]
			var lxy := Lxy
			if light["kind"] == "point":
				var P: Vector3 = pos3[idx]
				lxy = (Vector2(light["pos"].x, light["pos"].y) - Vector2(P.x, P.y)).normalized()
			var nxy := Vector2(n.x, n.y)
			if nxy.length() > 0.6 and _is_edge(piece, zb, x, y) and nxy.normalized().dot(lxy) > 0.72 and lamv[idx] > 0.3:
				col = rim_col if light.get("warm", true) else rim_col
				if ri >= 4 and light.get("warm", true):
					col = Color("ffb43a")
			var dc := _decal_at(pi, x, y)
			if dc != "":
				locked[idx] = 1
				match dc:
					"k": col = ramp[0] if ri < 4 else ramp[1]
					"W": col = HORN[5] if lamv[idx] > 0.2 else HORN[4]
					"w": col = HORN[3]
					"h": col = ramp[clampi(ri + 1, 0, 5)]
					"s": col = ramp[clampi(ri - 1, 0, 5)]
			img.set_pixel(x, y, col)
	_remove_orphans(img, piece, emit, locked)
	if smear:
		_draw_smear(img, piece)
	img = _sel_out(img, piece, ridx)
	if frame >= 0 and p.has("_glow"):
		_embers(img, frame, p)
	if p.has("_impact"):
		_impact(img, p)
	return img


func _decal_at(pi: int, x: int, y: int) -> String:
	var bone: String = PIECES[pi][0]
	for d: Dictionary in DECALS:
		if not (bone in d["bones"]):
			continue
		var q: Vector2 = (_bone_xf[d["bone"]] as Transform2D).affine_inverse() * Vector2(x + 0.5, y + 0.5) - (d["origin"] as Vector2)
		var cx := int(floor(q.x))
		var cy := int(floor(q.y))
		var rows: Array = d["rows"]
		if cy < 0 or cy >= rows.size() or cx < 0 or cx >= String(rows[0]).length():
			continue
		var ch: String = String(rows[cy])[cx]
		if ch != ".":
			return ch
	return ""


func _behind(piece: PackedInt32Array, zb: PackedFloat32Array, x: int, y: int) -> bool:
	var idx := y * W + x
	for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nx := x + o.x
		var ny := y + o.y
		if nx < 0 or ny < 0 or nx >= W or ny >= H:
			continue
		var j := ny * W + nx
		if piece[j] >= 0 and piece[j] != piece[idx] and zb[j] > zb[idx] + 3.0:
			return true
	return false


func _hash(n: int) -> float:
	return fposmod(sin(float(n) * 12.9898 + 4.1414) * 43758.5453, 1.0)


func _mode_filter(ridx: PackedInt32Array, piece: PackedInt32Array, emit: PackedInt32Array) -> PackedInt32Array:
	var out := ridx.duplicate()
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var idx := y * W + x
			if ridx[idx] < 0 or emit[idx] >= 0:
				continue
			var counts := {}
			var same := 0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var j := idx + oy * W + ox
					if piece[j] != piece[idx] or ridx[j] < 0:
						continue
					counts[ridx[j]] = counts.get(ridx[j], 0) + 1
					if ridx[j] == ridx[idx]:
						same += 1
			# Si el píxel está casi solo (≤2 iguales contándose a sí mismo) toma el valor dominante.
			if same <= 2:
				var best := ridx[idx]
				var bc := 0
				for k: int in counts.keys():
					if counts[k] > bc:
						bc = counts[k]; best = k
				out[idx] = best
	return out


func _near_mask(emit: PackedInt32Array, rad: int) -> PackedInt32Array:
	var out := PackedInt32Array(); out.resize(W * H)
	for y in H:
		for x in W:
			if emit[y * W + x] < 2:
				continue
			for oy in range(-rad, rad + 1):
				for ox in range(-rad, rad + 1):
					var d := absi(ox) + absi(oy)
					if d == 0 or d > rad:
						continue
					var nx := x + ox
					var ny := y + oy
					if nx < 0 or ny < 0 or nx >= W or ny >= H:
						continue
					var v := 2 if d == 1 else 1
					out[ny * W + nx] = maxi(out[ny * W + nx], v)
	return out


func _is_edge(piece: PackedInt32Array, zb: PackedFloat32Array, x: int, y: int) -> bool:
	for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nx := x + o.x
		var ny := y + o.y
		if nx < 0 or ny < 0 or nx >= W or ny >= H:
			return true
		var j := ny * W + nx
		if piece[j] < 0:
			return true
	return false


## Huérfanos: un píxel cuyo color no comparte ningún vecino ortogonal de su misma pieza toma el más común.
func _remove_orphans(img: Image, piece: PackedInt32Array, emit: PackedInt32Array, locked: PackedByteArray) -> void:
	var src := img.duplicate() as Image
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var idx := y * W + x
			if piece[idx] < 0 or emit[idx] >= 0 or locked[idx] == 1:
				continue
			var c := src.get_pixel(x, y)
			var counts := {}
			var match_n := 0
			var valid := 0
			for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var j := (y + o.y) * W + (x + o.x)
				if piece[j] < 0:
					continue
				valid += 1
				var cc := src.get_pixel(x + o.x, y + o.y)
				if cc == c:
					match_n += 1
				counts[cc] = counts.get(cc, 0) + 1
			if valid >= 3 and match_n == 0:
				var best := c
				var bc := 0
				for k: Color in counts.keys():
					if counts[k] > bc:
						bc = counts[k]; best = k
				img.set_pixel(x, y, best)


## Contorno selectivo: exterior de 1 px coloreado según el interior adyacente.
## Lado iluminado (interior claro) → tono oscuro de la rampa; sombra y base → k.
func _sel_out(img: Image, piece: PackedInt32Array, ridx: PackedInt32Array) -> Image:
	var out := img.duplicate() as Image
	for y in H:
		for x in W:
			if img.get_pixel(x, y).a > 0.0:
				continue
			var best_ri := -1
			var below := false
			var any := false
			for o: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx := x + o.x
				var ny := y + o.y
				if nx < 0 or ny < 0 or nx >= W or ny >= H:
					continue
				var c := img.get_pixel(nx, ny)
				if c.a <= 0.0:
					continue
				any = true
				var j := ny * W + nx
				if o.y == -1:
					below = true   # el interior está encima → borde inferior
				var ri := ridx[j] if piece[j] >= 0 else 5
				if c.r > 0.85 and c.g > 0.4:   # luz de borde / magma: cuenta como claro
					ri = 5
				best_ri = maxi(best_ri, ri)
			if not any:
				continue
			var col := K
			if not below and best_ri >= 4:
				col = ROCK[1]
			out.set_pixel(x, y, col)
	return out


## Estela del puño (fotograma de smear): barrido entre la pose cargada y la de impacto.
func _draw_smear(img: Image, piece: PackedInt32Array) -> void:
	var pa := _pose_attack(1)
	var pb := _pose_attack(2)
	var mask := {}
	var lead := {}
	for s in 25:
		var t := s / 24.0
		var pp := pa.duplicate()
		for k: String in ["spine", "head", "arm_n", "fore_n", "_dx", "_dy"]:
			pp[k] = lerpf(float(pa[k]), float(pb[k]), t)
		_solve(pp)
		var xf: Transform2D = _bone_xf["fore_n"]
		var c := xf * Vector2(0, 15)
		var r := 7.0
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				if x < 0 or y < 0 or x >= W or y >= H:
					continue
				if Vector2(x + 0.5, y + 0.5).distance_to(c) < r * (0.55 + 0.45 * t):
					mask[Vector2i(x, y)] = maxf(mask.get(Vector2i(x, y), 0.0), t)
	for k: Vector2i in mask.keys():
		var idx := k.y * W + k.x
		if piece[idx] >= 0:
			continue
		var t: float = mask[k]
		if t < 0.12:
			continue
		var col: Color = MAGMA[1]
		if t > 0.75:
			col = MAGMA[4]
		elif t > 0.45:
			col = MAGMA[3]
		elif t > 0.2:
			col = MAGMA[2]
		img.set_pixel(k.x, k.y, col)


## Impacto: esquirlas y polvo alrededor del punto de contacto del puño (2 fotogramas).
func _impact(img: Image, p: Dictionary) -> void:
	_solve(p)
	var c: Vector2 = (_bone_xf["fore_n"] as Transform2D) * Vector2(0, 21)
	var cx := int(c.x)
	var gy := mini(int(c.y), FLOOR - 1)
	var stage: int = p["_impact"]
	var chips := [Vector2i(-7, -3), Vector2i(-5, -7), Vector2i(-1, -9), Vector2i(4, -8), Vector2i(8, -4), Vector2i(-10, -1), Vector2i(10, -1)]
	for i in chips.size():
		var o: Vector2i = chips[i]
		var q := Vector2i(cx + o.x * (2 + stage) / 2, gy + o.y * (2 + stage) / 2 - stage * 2)
		if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H or img.get_pixel(q.x, q.y).a > 0.0:
			continue
		var col: Color = MAGMA[4 - stage * 2] if i % 2 == 0 else ROCK[4 - stage]
		img.set_pixel(q.x, q.y, col)
		if stage == 0 and i % 2 == 0 and q.y + 1 < H and img.get_pixel(q.x, q.y + 1).a == 0.0:
			img.set_pixel(q.x, q.y + 1, MAGMA[2])
	# polvo a ras de suelo
	for side in [-1, 1]:
		for k in 3 + stage * 2:
			var x: int = cx + side * (9 + k + stage * 3)
			var y: int = gy - (k % 2) - stage
			if x >= 0 and x < W and y >= 0 and y < H and img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, ROCK[3 - stage] if k < 2 else ROCK[2])


## Brasas que salen de las chimeneas de la espalda (vida ambiental, 8 fotogramas en bucle).
func _embers(img: Image, frame: int, p: Dictionary) -> void:
	_solve(p)
	var tips := [(_bone_xf["spine"] as Transform2D) * Vector2(14, -35), (_bone_xf["spine"] as Transform2D) * Vector2(4, -34)]
	for i in tips.size():
		for e in 2:
			var ph := (frame + e * 4 + i * 2) % 8
			var tip: Vector2 = tips[i]
			var x: int = int(tip.x) + [0, 1, 1, 2, 1, 2, 3, 3][ph] * (1 if i == 0 else -1)
			var y := int(tip.y) - 1 - ph
			if x < 0 or y < 0 or x >= W or y >= H or img.get_pixel(x, y).a > 0.0:
				continue
			img.set_pixel(x, y, MAGMA[[5, 4, 4, 3, 3, 2, 2, 1][ph]])


# ============================================================================ exportación
func _strip(imgs: Array, bg: Color, s: int) -> Image:
	var pad := 4
	var cw := W * s
	var out := Image.create(imgs.size() * (cw + pad * s) + pad * s, H * s + pad * s * 2, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	# suelo
	out.fill_rect(Rect2i(0, (pad + FLOOR) * s, out.get_width(), out.get_height() - (pad + FLOOR) * s), bg.darkened(0.25))
	for n in imgs.size():
		var im: Image = (imgs[n] as Image).duplicate()
		im.resize(W * s, H * s, Image.INTERPOLATE_NEAREST)
		out.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(pad * s + n * (cw + pad * s), pad * s))
	return out


func _debug_normals(gb: Dictionary) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var piece: PackedInt32Array = gb["piece"]
	for y in H:
		for x in W:
			var idx := y * W + x
			if piece[idx] < 0:
				continue
			var n: Vector3 = gb["n"][idx]
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, -n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return img


func _debug_ids(gb: Dictionary) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var piece: PackedInt32Array = gb["piece"]
	var cell: PackedInt32Array = gb["cell"]
	for y in H:
		for x in W:
			var idx := y * W + x
			if piece[idx] < 0:
				continue
			var h := _hash(cell[idx] if cell[idx] >= 0 else piece[idx] * 31)
			img.set_pixel(x, y, Color.from_hsv(h, 0.45, 0.4 + 0.5 * _hash(piece[idx] + 7)))
	return img


## A tamaño de juego (×4): gólem actual de art.gd | nuevo idle | nuevo impacto, sobre el fondo real del acto 1.
func _context(a: Image, b: Image) -> Image:
	var bgimg: Image = Art.background(0, 4, 0).get_image()
	bgimg.convert(Image.FORMAT_RGBA8)
	var crop := bgimg.get_region(Rect2i(56, 26, 264, 100))
	var cur: Image = Art.monster("golem", "seedA", 0, 0).get_image()
	cur.convert(Image.FORMAT_RGBA8)
	var floor_y := 118 - 26
	crop.blend_rect(cur, Rect2i(0, 0, cur.get_width(), cur.get_height()), Vector2i(14, floor_y - cur.get_height() + 1))
	crop.blend_rect(a, Rect2i(0, 0, W, H), Vector2i(56, floor_y - FLOOR))
	crop.blend_rect(b, Rect2i(0, 0, W, H), Vector2i(156, floor_y - FLOOR))
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	return crop
