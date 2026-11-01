extends RefCounted
## Pruebas de mundo vivo (MV · v0.4). `run() -> Array` devuelve los fallos.
##  1. Determinismo: misma sala → mismos bytes de índice.
##  2. Formato y paleta: IndexFormat.validate, vista previa = decodificar el índice, todo en paleta; fotogramas ambientales en paleta.
##  3. Luz por pieza: la mayoría de los píxeles del muro apunta al ancla de su pieza, y las anclas no se salen de la capa.
##  4. Disposición de combate: HUD oscuro, zona de la Forja sin emisivos, mano más oscura que el escenario, valores de fondo.
##  5. Variación por módulo, piso y ciclo.
##  6. ArtParticles: siempre en rejilla, pool acotado, determinista, emisor a 0 no emite.
##  7. AmbientState y parches de parpadeo.


func run() -> Array:
	var f: Array = []
	var normal := BgAct1.build("normal", 4, 0, false)
	var flue := BgAct1.build("flue", 10, 0, false)
	f.append_array(check_determinism(normal))
	for r: Dictionary in [normal, flue]:
		f.append_array(check_layers(r))
		f.append_array(check_anchors(r))
		f.append_array(check_layout(r))
	f.append_array(check_variation(normal, flue))
	f.append_array(check_frames())
	f.append_array(check_patches())
	f.append_array(check_particles())
	f.append_array(check_state())
	return f


func _layer(r: Dictionary, n: String) -> Dictionary:
	for L: Dictionary in r["layers"]:
		if L["name"] == n:
			return L
	return {}


func check_determinism(normal: Dictionary) -> Array:
	var again := BgAct1.build("normal", 4, 0, false)
	var out: Array = []
	for n: String in ["sky", "far", "mid", "fore"]:
		if (_layer(normal, n)["index"] as Image).get_data() != (_layer(again, n)["index"] as Image).get_data():
			out.append("[MV determinismo] la capa %s cambia entre dos construcciones" % n)
	return out


func check_layers(r: Dictionary) -> Array:
	var out: Array = []
	for L: Dictionary in r["layers"]:
		var tag := "%s/%s" % [r["kind"], L["name"]]
		var idx: Image = L["index"]
		var pre: Image = L["preview"]
		for e: String in IndexFormat.validate(idx):
			out.append("[MV índice %s] %s" % [tag, e])
		if IndexFormat.preview(idx).get_data() != pre.get_data():
			out.append("[MV índice %s] la vista previa no coincide con el índice decodificado" % tag)
		var bad := 0
		for y in pre.get_height():
			for x in pre.get_width():
				var c := pre.get_pixel(x, y)
				if c.a8 != 0 and not Palette.is_palette_color(c):
					bad += 1
		if bad > 0:
			out.append("[MV paleta %s] %d píxeles fuera de paleta" % [tag, bad])
	return out


func check_anchors(r: Dictionary) -> Array:
	var out: Array = []
	var idx: Image = _layer(r, "mid")["index"]
	var anchored := 0
	var full := 0
	for y in range(40, BgAct1.FY):
		for x in 640:
			var c := idx.get_pixel(x, y)
			if IndexFormat.is_empty(c):
				continue
			full += 1
			var d := IndexFormat.anchor_delta(c)
			if d != Vector2i.ZERO:
				anchored += 1
			var a := Vector2i(x, y) + d
			if a.x < -8 or a.y < 0 or a.x >= 648 or a.y >= 360:
				out.append("[MV anclas %s] ancla fuera de capa en (%d,%d)" % [r["kind"], x, y])
				return out
	if anchored * 2 < full:
		out.append("[MV anclas %s] sólo %d de %d píxeles usan ancla de pieza" % [r["kind"], anchored, full])
	return out


func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func check_layout(r: Dictionary) -> Array:
	var out: Array = []
	var k: String = r["kind"]
	var mid: Image = _layer(r, "mid")["preview"]
	var idx: Image = _layer(r, "mid")["index"]
	var fire := Palette.index(&"fire")
	var emis := 0
	for y in range(120, BgAct1.FY):
		for x in range(8, 112):
			if idx.get_pixel(x, y).r8 == fire:
				emis += 1
	if emis > 0:
		out.append("[MV disposición %s] %d píxeles emisivos en la zona de la Forja" % [k, emis])
	var sums := {"hud": [0.0, 0], "stage": [0.0, 0], "hand": [0.0, 0]}
	for y in 360:
		var zone := "hud" if y < 16 else ("stage" if y < 296 else "hand")
		for x in range(0, 640, 2):
			var c := mid.get_pixel(x, y)
			if c.a8 != 0:
				sums[zone][0] += _lum(c)
				sums[zone][1] += 1
	var hud: float = sums["hud"][0] / maxf(1.0, sums["hud"][1])
	var stage: float = sums["stage"][0] / maxf(1.0, sums["stage"][1])
	var hand: float = sums["hand"][0] / maxf(1.0, sums["hand"][1])
	if hud > 0.06:
		out.append("[MV valores %s] la franja del HUD no es oscura (%.3f)" % [k, hud])
	if hand >= stage:
		out.append("[MV valores %s] la zona de la mano (%.3f) no es más oscura que el escenario (%.3f)" % [k, hand, stage])
	if stage < 0.03 or stage > 0.40:
		out.append("[MV valores %s] escenario fuera de 3–40 %% (%.3f)" % [k, stage])
	return out


func _fire_count(r: Dictionary) -> int:
	var idx: Image = _layer(r, "mid")["index"]
	var fire := Palette.index(&"fire")
	var n := 0
	for y in range(40, 248):
		for x in 640:
			if idx.get_pixel(x, y).r8 == fire:
				n += 1
	return n


func check_variation(normal: Dictionary, flue: Dictionary) -> Array:
	var out: Array = []
	var base: PackedByteArray = (_layer(normal, "mid")["index"] as Image).get_data()
	if base == (_layer(flue, "mid")["index"] as Image).get_data():
		out.append("[MV variación] los módulos normal y de tiro son iguales")
	if base == (_layer(BgAct1.build("normal", 9, 0, false), "mid")["index"] as Image).get_data():
		out.append("[MV variación] el piso no cambia la sala")
	var veins := _fire_count(BgAct1.build("normal", 4, 1, false))
	var veins0 := _fire_count(normal)
	if veins <= veins0:
		out.append("[MV variación] el ciclo II no añade vetas de brasa (%d vs %d)" % [veins, veins0])
	if (normal["anchors"]["crucibles"] as Array).is_empty():
		out.append("[MV anclas] la sala normal no publica crisol")
	if (flue["anchors"]["flue"] as Rect2i).size == Vector2i.ZERO:
		out.append("[MV anclas] la sala de tiro no publica el vano")
	return out


func check_frames() -> Array:
	var out: Array = []
	AmbientFrames.clear_cache()
	var seen := {}
	for k in 8:
		AmbientFrames.flame(k)
		AmbientFrames.flame(k, -1)
		AmbientFrames.smoke(k)
	for k in 16:
		AmbientFrames.crucible(k, 66)
	var imgs := AmbientFrames.images()
	for im: Image in imgs:
		seen[im.get_data()] = true
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a8 != 0 and not Palette.is_palette_color(c):
					out.append("[MV ambiente] fotograma con color fuera de paleta")
					return out
	if seen.size() < 8 + 8 + 8 + 12:
		out.append("[MV ambiente] demasiados fotogramas repetidos (%d únicos de %d)" % [seen.size(), imgs.size()])
	if AmbientFrames.crucible_dx(0) != 0 or AmbientFrames.crucible_dx(4) != 7 or AmbientFrames.crucible_dx(12) != -7:
		out.append("[MV ambiente] el péndulo del crisol no es simétrico ±7")
	return out


func check_patches() -> Array:
	var out: Array = []
	var r := BgAct1.build("normal", 4, 0, true)
	if (r["flicker"] as Array).size() != 2 or (r["crucible_patches"] as Array).size() != 1:
		out.append("[MV parches] faltan parches de parpadeo o de crisol")
		return out
	var fr: Array = r["flicker"][0]["frames"]
	if (fr[0]["index"] as Image).get_data() == (fr[2]["index"] as Image).get_data():
		out.append("[MV parches] el parpadeo no cambia la luz")
	var rc: Rect2i = r["flicker"][0]["rect"]
	var base: Image = (_layer(r, "mid")["index"] as Image).get_region(rc)
	if base.get_data() != (fr[1]["index"] as Image).get_data():
		out.append("[MV parches] el parche de radio 0 no coincide con la capa media")
	return out


func check_particles() -> Array:
	var out: Array = []
	var p := ArtParticles.new()
	p.seed_value = 42
	p._setup()
	p.burst(Vector2(100.3, 50.7), "spark", 40)
	var em := p.add_emitter(Rect2(0, 0, 640, 100), "ember", 500.0)
	var off_grid := false
	for i in 120:
		p.step(1.0 / 60.0)
		if p.alive_count() > p.max_particles:
			out.append("[MV partículas] el pool se desborda")
			break
		for j in p.alive_count():
			var g := p.grid_pos(j)
			if g.x != floorf(g.x) or g.y != floorf(g.y):
				off_grid = true
	if off_grid:
		out.append("[MV partículas] partícula fuera de rejilla")
	if p.alive_count() == 0:
		out.append("[MV partículas] el emisor no emite")
	p.set_emitter_rate(em, 0.0)
	for i in 600:
		p.step(1.0 / 60.0)
	if p.alive_count() != 0:
		out.append("[MV partículas] emisor a 0 pero quedan %d vivas tras 10 s" % p.alive_count())
	if _particle_run() != _particle_run():
		out.append("[MV partículas] no es determinista con la misma semilla")
	p.free()
	return out


func _particle_run() -> Array:
	var p := ArtParticles.new()
	p.seed_value = 7
	p._setup()
	p.burst(Vector2(10, 10), "spark", 12)
	for i in 10:
		p.step(0.05)
	var out: Array = []
	for j in p.alive_count():
		out.append(p.grid_pos(j))
	p.free()
	return out


func check_state() -> Array:
	var out: Array = []
	var s := AmbientState.new()
	if AmbientState.normalize_production(0.0) != 0.0 or not is_equal_approx(AmbientState.normalize_production(999999999.0), 1.0):
		out.append("[MV estado] normalización de producción incorrecta")
	var hit := [false]
	s.burned.connect(func(_h: bool) -> void: hit[0] = true)
	s.pulse_burn()
	if not hit[0] or s.burn_pulse != 1.0:
		out.append("[MV estado] pulse_burn no avisa")
	s.tick(2.0)
	if s.burn_pulse != 0.0:
		out.append("[MV estado] el pulso no decae")
	AmbientState.from_game()
	return out
