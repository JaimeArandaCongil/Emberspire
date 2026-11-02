extends RefCounted
## Pruebas de mundo vivo (MV · v0.4). `run() -> Array` devuelve los fallos.
##  1. Determinismo: misma sala → mismos bytes de índice.
##  2. Formato y paleta: IndexFormat.validate, vista previa = decodificar el índice, todo en paleta; fotogramas ambientales en paleta.
##  3. Luz por pieza: la mayoría de los píxeles del muro apunta al ancla de su pieza, y las anclas no se salen de la capa.
##  4. Disposición de combate: HUD oscuro, zona de la Forja sin emisivos, mano más oscura que el escenario, valores de fondo.
##  5. Variación por módulo, piso y ciclo.
##  6. ArtParticles: siempre en rejilla, pool acotado, determinista, emisor a 0 no emite.
##  7. AmbientState y parches de parpadeo.
##  8. F2-FX: frescura y variantes de las salas horneadas, Forja casada con el conducto, tiempos y firmas de los efectos,
##     calidad de sala (vetas, muro del tiro, galerías), Resplandor y reacción del crisol.


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
	f.append_array(check_baked())
	f.append_array(check_room_view_baked())
	f.append_array(check_forge())
	f.append_array(check_burn_fx())
	f.append_array(check_hit_fx())
	f.append_array(check_death_embers())
	f.append_array(check_status_fx())
	f.append_array(check_summon_fx())
	f.append_array(check_room_quality())
	f.append_array(check_glow_and_wave())
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
	AmbientFrames.use_baked = false
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
	AmbientFrames.clear_cache()
	AmbientFrames.use_baked = true
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


# --- F2-FX: salas horneadas, Forja y efectos -----------------------------------------------------

const RoomBaker = preload("res://tools/bake_rooms.gd")


func check_baked() -> Array:
	var out: Array = []
	for e: String in RoomBaker.freshness_errors():
		out.append("[MV horneado] %s" % e)
	if not out.is_empty():
		return out
	# Todas las variantes de docs/DECISIONES.md, y todas alcanzables por piso.
	for kind: String in BakedRooms.VARIANT_FLOORS:
		var n: int = (BakedRooms.VARIANT_FLOORS[kind] as Array).size()
		if n != (4 if kind == "normal" else 2):
			out.append("[MV variantes] %s tiene %d variantes" % [kind, n])
		var seen := {}
		for fl in range(1, 61):
			seen[BakedRooms.variant_for(kind, fl)] = true
		if seen.size() != n:
			out.append("[MV variantes] %s: sólo %d de %d variantes salen en 60 pisos" % [kind, seen.size(), n])
		for v in n:
			for band in 2:
				if not FileAccess.file_exists(BakedRooms.DIR + BakedRooms.room_id(kind, v, band) + ".txt"):
					out.append("[MV variantes] falta %s" % BakedRooms.room_id(kind, v, band))
	if BakedRooms.cycle_band(0) != 0 or BakedRooms.cycle_band(1) != 1 or BakedRooms.cycle_band(5) != 1:
		out.append("[MV variantes] los ciclos posteriores deben usar la banda II")
	var room := BakedRooms.load_room("normal", _floor_for_variant("normal", 1), 0)
	if room.is_empty():
		out.append("[MV horneado] no carga la sala normal")
		return out
	for L: Dictionary in room["layers"]:
		if not L.has("index_tex") or not L.has("preview_tex"):
			out.append("[MV horneado] la capa %s no trae texturas horneadas" % L["name"])
	if not (room["anchors"]["crucibles"][0]["pivot"] is Vector2i):
		out.append("[MV horneado] las anclas pierden su tipo")
	# Los bytes horneados son los que salen del generador.
	var fresh := BgAct1.build("normal", int(BakedRooms.VARIANT_FLOORS["normal"][1]), 0, false)
	var png := Image.load_from_file(ProjectSettings.globalize_path(BakedRooms.DIR + "mid_normal_v1_c0_idx.png"))
	png.convert(Image.FORMAT_RGBA8)
	if png.get_data() != (_layer(fresh, "mid")["index"] as Image).get_data():
		out.append("[MV horneado] el índice horneado no coincide con BgAct1 (¿rehornear?)")
	return out


func _floor_for_variant(kind: String, v: int) -> int:
	for fl in range(1, 200):
		if BakedRooms.variant_for(kind, fl) == v:
			return fl
	return 1


func check_room_view_baked() -> Array:
	var out: Array = []
	var view := Act1RoomView.new()
	var st := AmbientState.new()
	AmbientFrames.clear_cache()
	AmbientFrames.use_baked = true
	view.build(BakedRooms.load_room("flue", 10, 1), st)
	# El ambiente sale del atlas: con horneado disponible no se genera ningún fotograma.
	AmbientFrames.flame(0, 0, 1.0, true)
	AmbientFrames.flame(3, -1, 1.1, false)
	AmbientFrames.flame(5, 0, 1.0, true, true)
	AmbientFrames.smoke(1, 1, true)
	AmbientFrames.crucible(3, 66, 11, 1, true)
	if not AmbientFrames.images().is_empty():
		out.append("[MV horneado] el ambiente genera %d fotogramas en ejecución" % AmbientFrames.images().size())
	if view.fx_layer == null or view.fx_layer.get_index() <= view.actors.get_index():
		out.append("[MV sala] fx_layer debe ir encima de los actores")
	if view.ember_sink() != Vector2(440, 44):
		out.append("[MV sala] sumidero de brasas de la sala de tiro incorrecto")
	view.free()
	# Brasero de la sala de tiro fuera del hueco del tercer enemigo (docs/DECISIONES.md).
	for b: Vector2i in BgAct1.build("flue", 5, 0, false)["anchors"]["braziers"]:
		if b.x - 12 < 572 + 40 and b.x + 12 > 572 - 40:
			out.append("[MV sala] brasero en x %d sobre el tercer enemigo" % b.x)
	return out


func _alpha_at(img: Image, p: Vector2i) -> bool:
	return img.get_pixelv(p).a8 != 0


func check_forge() -> Array:
	var out: Array = []
	var built := BgForge.build()
	var base: Image = built["base"]["index"]
	for e: String in IndexFormat.validate(base):
		out.append("[MV Forja] %s" % e)
	# Ocupa x 8–112 (más la chimenea) y llega hasta el borde superior.
	for y in base.get_height():
		for x in base.get_width():
			if _alpha_at(base, Vector2i(x, y)) and (x < 8 or x > 112 or y >= 268):
				out.append("[MV Forja] se sale de x 8–112 en (%d,%d)" % [x, y])
				return out
	if not _alpha_at(base, Vector2i(BgForge.CX, 0)):
		out.append("[MV Forja] la chimenea no llega al borde superior")
	if _alpha_at(base, Vector2i(BgForge.CX, 100)):
		out.append("[MV Forja] la junta de tiro debe quedar abierta para la columna")
	# Casada con el conducto: mismo cobre en x 100–109 a ambos lados del collarín.
	var mid: Image = _layer(BgAct1.build("normal", 2, 0, false), "mid")["index"]
	var copper := Palette.index(&"copper")
	for x in range(BgForge.PIPE_X, BgForge.PIPE_X + 10):
		var pm := mid.get_pixel(x, 189)
		var pf := base.get_pixel(x, 200)
		if pm.r8 != copper or pf.r8 != copper:
			out.append("[MV Forja] el conducto no es de cobre a ambos lados en x %d" % x)
			break
		if absi((pm.g8 & 15) - (pf.g8 & 15)) > 1:
			out.append("[MV Forja] salto de valor entre conducto y Forja en x %d (%d, %d)" % [x, pm.g8 & 15, pf.g8 & 15])
			break
	var frames: Dictionary = built["frames"]
	for fname: String in ["mouth_0", "mouth_1", "mouth_2", "lick_0", "lick_1", "lick_2", "swallow", "flash", "flash_card", "grate"]:
		if not frames.has(fname):
			out.append("[MV Forja] falta el fotograma %s" % fname)
			continue
		for fr: Dictionary in frames[fname]:
			for e: String in IndexFormat.validate(fr["index"]):
				out.append("[MV Forja %s] %s" % [fname, e])
	if _fire_px(frames["mouth_0"][0]["index"]) >= _fire_px(frames["mouth_2"][0]["index"]):
		out.append("[MV Forja] la llama de la boca no crece con el calor")
	if (frames["swallow"][0]["index"] as Image).get_data() == (frames["mouth_1"][0]["index"] as Image).get_data():
		out.append("[MV Forja] tragar no cambia la boca")
	# Estado.
	var fg := CombatForge.new().setup()
	if not fg.has_art():
		out.append("[MV Forja] no carga la Forja horneada")
	fg.set_burns(7)
	if fg.lit_grates() != CombatForge.MAX_GRATES:
		out.append("[MV Forja] rejillas mal limitadas")
	fg.set_burns(2)
	if fg.lit_grates() != 2:
		out.append("[MV Forja] rejillas no siguen a las Quemas")
	fg.set_heat(0.9)
	if fg.mouth_state() != &"mouth_2":
		out.append("[MV Forja] la boca no sigue al calor")
	fg.swallow()
	if fg.mouth_state() != &"swallow":
		out.append("[MV Forja] no traga")
	fg.flash()
	if fg.mouth_state() != &"flash":
		out.append("[MV Forja] no destella")
	fg.free()
	return out


func _fire_px(im: Image) -> int:
	var n := 0
	var fire := Palette.index(&"fire")
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a8 != 0 and c.r8 == fire and (c.g8 & 15) >= 3:
				n += 1
	return n


func check_burn_fx() -> Array:
	var out: Array = []
	var st := AmbientState.new()
	var fg := CombatForge.new().setup()
	var bf := BurnFX.new().setup(fg, st)
	var ev := {"impact": 0.0, "interactive": 0.0, "coin": 0.0, "end": 0.0, "shake": 0.0, "burned": 0.0, "flue": 0.0}
	var clock := [0.0]
	bf.impact.connect(func(_h: bool, s: float, _t: float) -> void:
		ev["impact"] = clock[0]
		ev["shake"] = s)
	bf.interactive.connect(func() -> void: ev["interactive"] = clock[0])
	bf.coin_arrived.connect(func() -> void: ev["coin"] = clock[0])
	bf.finished.connect(func() -> void: ev["end"] = clock[0])
	st.burned.connect(func(_h: bool) -> void: ev["burned"] = clock[0])
	st.burn_reached_flue.connect(func(_h: bool) -> void: ev["flue"] = clock[0])
	bf.play("attack", true, Vector2(300, 320), Vector2(40, 6))
	if st.burn_pulse < 0.5:
		out.append("[MV quemar] sin inspiración previa")
	if fg.mouth_state() != &"swallow":
		out.append("[MV quemar] la Forja no abre la boca")
	while bf.is_playing() and clock[0] < 3.0:
		clock[0] += 1.0 / 60.0
		bf._process(1.0 / 60.0)
		fg._process(1.0 / 60.0)
	if absf(float(ev["impact"]) - BurnFX.T_IMPACT) > 0.04:
		out.append("[MV quemar] impacto a %.2f s" % ev["impact"])
	if absf(float(ev["interactive"]) - 0.35) > 0.04:
		out.append("[MV quemar] interactivo a %.2f s" % ev["interactive"])
	if float(ev["shake"]) != 8.0:
		out.append("[MV quemar] la sacudida en caliente debe ser 8")
	if absf(float(ev["burned"]) - float(ev["impact"])) > 0.001:
		out.append("[MV quemar] la onda no sale en el impacto")
	if float(ev["flue"]) <= float(ev["impact"]) + 0.2:
		out.append("[MV quemar] el tiro debe recibir el calor tras recorrer el conducto")
	if float(ev["coin"]) <= BurnFX.T_COINS or float(ev["coin"]) > 0.95:
		out.append("[MV quemar] primera moneda a %.2f s" % ev["coin"])
	if absf(float(ev["end"]) - BurnFX.T_END) > 0.05:
		out.append("[MV quemar] termina a %.2f s" % ev["end"])
	# La columna es distinta para cada tipo de carta.
	var seen := {}
	for t: String in ["attack", "skill", "power", "fuel", "status"]:
		seen[BurnFX.column_palette(t)[0].to_html() + BurnFX.column_palette(t)[1].to_html()] = true
		for c: Color in BurnFX.column_palette(t):
			if not Palette.is_palette_color(c):
				out.append("[MV quemar] color fuera de paleta en %s" % t)
	if seen.size() != 5:
		out.append("[MV quemar] tipos de carta sin columna propia")
	if BurnFX.FLANGES.size() != 6:
		out.append("[MV quemar] el conducto debe tener 6 pasos")
	var a := Vector2(300, 320)
	var b := Vector2(55, 226)
	if BurnFX.flight_point(a, b, 0.0) != a or BurnFX.flight_point(a, b, 1.0) != b:
		out.append("[MV quemar] el arco no une carta y boca")
	bf.free()
	fg.free()
	return out


func _settle_hit(h: HitFX) -> void:
	for i in 60:
		h._process(1.0 / 60.0)


func check_hit_fx() -> Array:
	var out: Array = []
	var st := AmbientState.new()
	var got := [-1]
	st.struck.connect(func(a: int) -> void: got[0] = a)
	var h := HitFX.new().setup(st)
	h.strike(Vector2(10, 10), 7)
	if h.active_count() != 1 or h._fx[0]["kind"] != &"normal" or got[0] != 7:
		out.append("[MV golpe] golpe normal mal elegido o sin aviso a la sala")
	_settle_hit(h)
	h.strike(Vector2(10, 10), 20)
	if h._fx[0]["kind"] != &"heavy":
		out.append("[MV golpe] 20 o más debe ser golpe fuerte")
	_settle_hit(h)
	h.sweep(300, 620, 180)
	h.blocked(Vector2(1, 1))
	h.player_hit(Vector2(2, 2))
	if h.active_count() != 3:
		out.append("[MV golpe] faltan efectos activos")
	_settle_hit(h)
	if h.active_count() != 0:
		out.append("[MV golpe] los efectos no terminan")
	h.free()
	return out


func check_death_embers() -> Array:
	var out: Array = []
	var d := DeathEmbers.new()
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := IndexFormat.pack(Palette.index(&"iron"), 3, 0, Vector2i(2, 2))
	var hot := IndexFormat.pack(Palette.index(&"fire"), 5, IndexFormat.F_EMISSIVE, Vector2i.ZERO)
	for x in 8:
		img.set_pixel(x, 6, body)
	img.set_pixel(3, 2, hot)
	var pts := d.sample_points(img, Vector2(100, 200), 40)
	if not pts.has(Vector2(103, 202)):
		out.append("[MV muerte] no parte de los píxeles emisivos")
	if pts.size() > 12:
		out.append("[MV muerte] rellena de más (%d)" % pts.size())
	var ev := {"first": -1.0, "end": -1.0}
	var clock := [0.0]
	d.first_out.connect(func(_p: Vector2) -> void: ev["first"] = clock[0])
	d.finished.connect(func() -> void: ev["end"] = clock[0])
	d.play(Rect2(330, 200, 40, 60), Vector2.ZERO, Vector2(440, 44))
	while d.playing() and clock[0] < 3.0:
		clock[0] += 1.0 / 60.0
		d._process(1.0 / 60.0)
	if float(ev["first"]) < 0.8 or float(ev["first"]) > float(ev["end"]):
		out.append("[MV muerte] +Ascuas debe salir con la primera brasa fuera (%.2f)" % ev["first"])
	if absf(float(ev["end"]) - DeathEmbers.DURATION) > 0.05:
		out.append("[MV muerte] dura %.2f s" % ev["end"])
	d.free()
	return out


func check_status_fx() -> Array:
	var out: Array = []
	var s := StatusFX.new().setup(Rect2(10, 10, 40, 60), false)
	s.sync({}, 0)
	if s.active_loop() != &"":
		out.append("[MV estados] sin estados no debe animar nada")
	s.sync({"str": 1}, 0)
	if s.active_loop() != &"str" or s._rings_t < 0.0:
		out.append("[MV estados] la fuerza debe animar y lanzar anillos al ganarse")
	s.sync({"str": 1, "weak": 2}, 0)
	if s.active_loop() != &"weak":
		out.append("[MV estados] débil debe tener prioridad sobre fuerza")
	s.sync({"str": 1, "weak": 2, "scorch": 4}, 4)
	if s.active_loop() != &"scorch" or s.flame_count() != 4:
		out.append("[MV estados] quemadura: prioridad y número de lenguas (C6: 3–5)")
	if s._shield_t < 0.0:
		out.append("[MV estados] ganar bloqueo no gira el escudo")
	s.sync({"scorch": 30}, 0)
	if s.flame_count() != 5 or s.flame_height() != 6:
		out.append("[MV estados] como mucho 5 lenguas de 6 px")
	if s._shatter_t < 0.0:
		out.append("[MV estados] perder bloqueo no rompe el escudo")
	s.sync({"scorch": 30, "vuln": 1}, 0)
	if s._flash_t < 0.0:
		out.append("[MV estados] ganar vulnerable no destella")
	for i in 120:
		s._process(1.0 / 60.0)
	if s._shatter_t >= 0.0 or s._flash_t >= 0.0 or s._shield_t >= 0.0 or s._rings_t >= 0.0:
		out.append("[MV estados] los eventos no terminan")
	var mask := Image.create(40, 60, false, Image.FORMAT_RGBA8)
	mask.fill(Color(0, 0, 0, 0))
	mask.fill_rect(Rect2i(10, 20, 20, 30), Color(1, 1, 1, 1))
	s.set_mask(mask)
	if s._top_at(0.5) != Vector2i(30, 30):
		out.append("[MV estados] la llama no sigue el contorno (%s)" % s._top_at(0.5))
	s.free()
	return out


func check_summon_fx() -> Array:
	var out: Array = []
	var sm := SummonFX.new()
	var seen := {"max": 0.0, "first": -1.0, "end": false}
	var clock := [0.0]
	sm.finished.connect(func() -> void: seen["end"] = true)
	sm.play(Vector2(460, 264), 40, func(f: float) -> void:
		if float(seen["first"]) < 0.0:
			seen["first"] = clock[0]
		seen["max"] = maxf(float(seen["max"]), f))
	while sm.playing() and clock[0] < 2.0:
		clock[0] += 1.0 / 60.0
		sm._process(1.0 / 60.0)
	if not bool(seen["end"]) or absf(clock[0] - SummonFX.DURATION) > 0.05:
		out.append("[MV invocación] dura %.2f s" % clock[0])
	if float(seen["first"]) < SummonFX.REVEAL_FROM:
		out.append("[MV invocación] emerge antes de agrietarse el suelo")
	if float(seen["max"]) < 0.9:
		out.append("[MV invocación] no llega a emerger del todo (%.2f)" % seen["max"])
	sm.free()
	return out


func check_room_quality() -> Array:
	var out: Array = []
	# Vetas: sin escalera regular. En un tramo de escalera, cada fila avanza 1 px en x (45°).
	var view := BgAct1.new()
	view.room_seed = 4 * 31 + 1009
	view.cycle = 1
	view._build_veins()
	var cells: Dictionary = view._veins
	if cells.size() < 40:
		out.append("[MV vetas] muy pocas vetas (%d)" % cells.size())
	var diag := 0
	for p: Vector2i in cells:
		if cells.has(p + Vector2i(1, -1)) and cells.has(p + Vector2i(2, -2)):
			diag += 1
		elif cells.has(p + Vector2i(-1, -1)) and cells.has(p + Vector2i(-2, -2)):
			diag += 1
	if float(diag) / maxf(1.0, cells.size()) > 0.08:
		out.append("[MV vetas] demasiada escalera a 45 grados (%d de %d)" % [diag, cells.size()])
	# Muro del tiro: la pared lejana no es plana, y las galerías no son sólo fuego.
	var far_room := BgAct1.build("flue", 5, 0, false)
	var far: Image = _layer(far_room, "far")["preview"]
	var tones := {}
	for y in range(60, 200, 2):
		for x in range(290, 590, 2):
			tones[far.get_pixel(x, y).to_html()] = true
	if tones.size() < 10:
		out.append("[MV tiro] muro plano: sólo %d tonos" % tones.size())
	var idx: Image = _layer(far_room, "far")["index"]
	var fire_far := 0
	var fire_i := Palette.index(&"fire")
	for y in range(0, 205):
		for x in idx.get_width():
			var c := idx.get_pixel(x, y)
			if c.a8 != 0 and c.r8 == fire_i:
				fire_far += 1
	if fire_far > 120:
		out.append("[MV tiro] las galerías lejanas se leen como marcas rojas (%d px de fuego)" % fire_far)
	return out


func check_glow_and_wave() -> Array:
	var out: Array = []
	var st := AmbientState.new()
	var fp := ArtParticles.new()
	var bp := ArtParticles.new()
	var fl := AmbientFlue.new().setup(st, bp, fp, Rect2i(290, 40, 300, 168), Vector2i(320, 276))
	fl._apply()
	if float(fp._emitters[1]["rate"]) != 0.0:
		out.append("[MV Resplandor] motas sin Resplandor")
	st.glow = true
	fl._apply()
	if float(fp._emitters[1]["rate"]) <= 0.0:
		out.append("[MV Resplandor] sin motas con Resplandor")
	var g := AmbientGlow.new().setup(st)
	if not g.active():
		out.append("[MV Resplandor] el halo no se activa")
	g.free()
	fl.free()
	AmbientFrames.use_baked = false
	AmbientFrames.clear_cache()
	if AmbientFrames.flame(0, 0, 1.0, true, true) == AmbientFrames.flame(0, 0, 1.0, true, false):
		out.append("[MV Resplandor] la llama no pasa a oro")
	AmbientFrames.clear_cache()
	AmbientFrames.use_baked = true
	fp.free()
	bp.free()
	# Crisol: la onda tarda en llegar, y al llegar el hierro recibe luz y el crisol se balancea.
	var st2 := AmbientState.new()
	var cr := AmbientCrucible.new()
	cr.position = Vector2(444, 32)
	cr.setup(st2, 66)
	var idle: float = cr.light_info()["step"]
	st2.pulse_burn(false, false)
	if cr.ringing():
		out.append("[MV crisol] reacciona antes de llegar la onda")
	var hit_at := -1.0
	var clock := 0.0
	var peak := idle
	for i in 60:
		clock += 1.0 / 60.0
		cr._process(1.0 / 60.0)
		peak = maxf(peak, float(cr.light_info()["step"]))
		if hit_at < 0.0 and cr.ringing():
			hit_at = clock
	if hit_at < 0.25 or hit_at > 0.5:
		out.append("[MV crisol] la onda llega a %.2f s" % hit_at)
	if peak < idle + 2.0:
		out.append("[MV crisol] el hierro no reacciona a la onda")
	if cr.ringing():
		out.append("[MV crisol] la reacción no termina")
	cr.free()
	return out
