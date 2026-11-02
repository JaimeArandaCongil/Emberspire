extends RefCounted
## ÁCARO DE VELA (`candle_mite`, acto 1) — PER · v0.4. Criatura pequeña: casi todo son LOSAS ASCII a mano con pasos forzados; el rig sólo anima.
## Concepto: un ácaro de caparazón oscuro que carga un cabo de vela al lomo y vive de su cera.
## Silueta: escarabajo bajo con seis patas de aguja y una vela chorreante encendida encima. ≈ 26×28 px; lienzo 48×48; suelo y = 42.
## Rasgo vivo: la llama parpadea (3 fotogramas), la cera gotea por el lateral, las antenas tiemblan, ojo de brasa.
## Telegrafía (cast, Fuerza): se levanta, la llama crece. Muerte: la cera se derrite y la mecha ESTALLA (anuncia su `on_death`).

static func build() -> RigDef:
	var b := RigBuilder.new(&"candle_mite", Vector2i(48, 48), Vector2i(24, 37), -1)
	b.material(&"wax", &"linen")
	b.material(&"shell", &"leather")
	b.material(&"leg", &"boot")
	b.material(&"fire", &"fire")
	b.bone(&"root", &"", Vector2.ZERO)
	for i in 3:
		b.bone(StringName("leg_f%d" % i), &"root", Vector2(-5 + i * 5, 1), {"z": -4.0, "angle": [0.7, 0.15, -0.65][i]})
		b.bone(StringName("leg_n%d" % i), &"root", Vector2(-6 + i * 6, 2), {"z": 6.0, "angle": [0.95, 0.3, -0.8][i]})
	b.bone(&"body", &"root", Vector2.ZERO)
	b.bone(&"head", &"body", Vector2(-9, 0), {"z": 2.0})
	b.bone(&"candle", &"body", Vector2(1, -4), {"z": 1.0})
	b.bone(&"wick", &"candle", Vector2(0, -11), {"z": 1.0})
	b.bone(&"antenna", &"head", Vector2(-2, -2))
	b.bone(&"drip", &"candle", Vector2(4, -4), {"z": 4.0})
	for s: String in ["f", "n"]:
		for i in 3:
			var bn := StringName("leg_%s%d" % [s, i])
			var ao := 1.5 if s == "f" else 1.0
			var kx: float = [-2.0, -1.5, 2.0][i]   # rodilla hacia fuera: ninguna pata queda recta
			b.cap(StringName("%s_a" % bn), bn, &"leg", Vector3(0, 0, 0), Vector3(0, 3, 0), 1.1, 0.9, {"ao": ao})
			b.cap(StringName("%s_b" % bn), bn, &"leg", Vector3(0, 3, 0), Vector3(kx, 6, 0), 0.9, 0.6, {"ao": ao, "line": false})
	# Caparazón: losa a mano. c/d/e = cuero oscuro → claro.
	b.slab(&"shell", &"body", [
		"....eeeeeee.....",
		"..eeedddddddd...",
		".eedddddddddddc.",
		"eedddcddddcdddcc",
		"edddddddddddddcc",
		"ddddcdddcddddccc",
		".ccccccccccccccc",
		"..cccccccccccc..",
	], Vector2(-8, -5), {"c": [&"shell", 1], "d": [&"shell", 3], "e": [&"shell", 4]}, 0.0, 1.0, 2.0)
	# Cabo de vela: cera clara con labio derretido y chorretones. 2–6 = lino.
	b.slab(&"wax_body", &"candle", [
		".6655544.",
		"666555443",
		"655544433",
		"655444332",
		".65444332",
		".55444322",
		".55444322",
		".54444322",
		"6544433226",
		"65444332.5",
		"5.44433...",
	], Vector2(-4, -10), {"6": [&"wax", 5], "5": [&"wax", 5], "4": [&"wax", 4], "3": [&"wax", 3], "2": [&"wax", 2]}, 2.0, 1.0, 1.0)
	# Cabeza pequeña de caparazón con ojo de brasa y mandíbulas.
	b.slab(&"head", &"head", [
		"..ccc.",
		".ceedc",
		"ceeddc",
		"cddddc",
		".cccc.",
	], Vector2(-4, -2), {"c": [&"shell", 1], "d": [&"shell", 3], "e": [&"shell", 4]}, 2.0, 1.0, 1.0)
	b.stamp(&"eye", &"head", Vector2(-2, 0), ["E"], {"E": [&"fire", 6]}, {"z_top": false})
	b.stamp(&"jaws", &"head", Vector2(-5, 1), ["k.", ".k"], {"k": [&"leg", 2]})
	b.stamp(&"antennae", &"antenna", Vector2.ZERO, ["k..", ".k.", "..k"], {"k": [&"leg", 3]}, {"anchor": Vector2i(2, 2), "views": {
		&"a0": ["k..", ".k.", "..k"], &"a1": [".k.", ".k.", "..k"]}})
	# Llama de la mecha (vistas); la mecha es el píxel k.
	var flame := {"k": [&"leg", 1], "r": [&"fire", 3], "o": [&"fire", 4], "y": [&"fire", 5], "w": [&"fire", 6], "W": [&"fire", 7]}
	b.stamp(&"flame", &"wick", Vector2.ZERO, [
		"..r..",
		"..o..",
		".roy.",
		".oyw.",
		".ywo.",
		"..k..",
	], flame, {"anchor": Vector2i(2, 5), "views": {
		&"f0": ["..r..", "..o..", ".roy.", ".oyw.", ".ywo.", "..k.."],
		&"f1": ["...r.", "..ro.", ".roy.", ".oww.", ".ywo.", "..k.."],
		&"f2": [".....", ".r...", ".oo..", ".oyw.", ".yWo.", "..k.."],
		&"big": ["..r..", ".ro..", ".oy..", ".oyr.", "royw.", "oywWo", "oyWWo", ".yWw.", "..k.."],
		&"small": [".....", ".....", ".....", "..r..", ".roy.", "..k.."],
		&"burst": ["r..o..r", ".o.y.o.", "..yWy..", "oyWWWyo", "..yWy..", ".o.y.o.", "r..o..r"],
		&"out": [".....", ".....", ".....", ".....", ".....", "..k.."],
	}})
	# Goterón de cera (rasgo vivo).
	b.stamp(&"drip", &"drip", Vector2.ZERO, ["5"], {"5": [&"wax", 5], "3": [&"wax", 3]}, {"views": {
		&"d0": ["5"], &"d1": ["5", "3"], &"d2": ["5", "5", "3"], &"d3": [".", ".", ".", "3"]}})
	# Charco de cera de la muerte.
	b.slab(&"puddle", &"root", [
		"...44444444...",
		".554444443333.",
		"54444433333222",
	], Vector2(-7, 1), {"5": [&"wax", 5], "4": [&"wax", 4], "3": [&"wax", 3], "2": [&"wax", 2]}, 8.0, 1.0, 1.0)
	b.socket(&"hit", &"head", Vector2(-5, 1))
	b.socket(&"intent", &"wick", Vector2(0, -8))
	b.socket(&"burst", &"wick", Vector2(0, -2))
	_anims(b)
	return b.def


static func _legs(k: Dictionary, a: float) -> void:
	# Patas alternas: trípode de insecto.
	for i in 3:
		var sg := 1.0 if i % 2 == 0 else -1.0
		k[StringName("leg_n%d" % i)] = a * sg
		k[StringName("leg_f%d" % i)] = -a * sg


## Las patas ceden hacia fuera (la punta sube, nunca atraviesa el suelo); las centrales se esconden bajo el cuerpo.
static func _splay(k: Dictionary, a: float) -> void:
	for s: String in ["f", "n"]:
		k[StringName("leg_%s0" % s)] = a
		k[StringName("leg_%s2" % s)] = -a
		if a > 0.6:
			k[StringName("hide:leg_%s1_a" % s)] = true
			k[StringName("hide:leg_%s1_b" % s)] = true
		else:
			k[StringName("leg_%s1" % s)] = a * 0.6


static func _anims(b: RigBuilder) -> void:
	var idle := {}
	for f in 6:
		var k := {}
		k[&"view:wick"] = [&"f0", &"f1", &"f0", &"f2", &"f1", &"f0"][f]
		k[&"view:antenna"] = &"a1" if f in [2, 3] else &"a0"
		k[&"view:drip"] = [&"d0", &"d0", &"d1", &"d2", &"d3", &"d0"][f]
		k[&"@root"] = Vector2i(0, 1 if f in [3, 4] else 0)
		k[&"head"] = 0.08 * sin(TAU * f / 6.0)
		k[&"candle"] = 0.03 * sin(TAU * f / 6.0)
		k[&"hide:puddle"] = true
		_legs(k, 0.06 * sin(TAU * f / 3.0))
		idle[f] = k
	b.anim(&"idle", 6, 130, idle, {"interp": &"hold"})
	# Telegrafía: se yergue, la llama crece.
	var c0 := {&"body": 0.18, &"head": -0.1, &"candle": -0.08, &"@root": Vector2i(1, -1), &"view:wick": &"big", &"view:antenna": &"a1", &"hide:puddle": true, &"view:drip": &"d1"}
	var c1 := c0.duplicate()
	c1[&"@root"] = Vector2i(1, -2)
	c1[&"emit:flame"] = 1
	b.anim(&"cast", 2, [120, 300], {0: c0, 1: c1}, {"loop": false, "interp": &"hold"})
	# Ataque: se agacha, salta y muerde.
	var a0 := {&"body": 0.2, &"@root": Vector2i(2, 1), &"view:wick": &"f1", &"hide:puddle": true, &"view:drip": &"d0"}
	var a1 := {&"body": -0.2, &"head": -0.2, &"candle": 0.2, &"@root": Vector2i(-8, -6), &"view:wick": &"small", &"hide:puddle": true, &"view:drip": &"d0"}
	var a2 := {&"body": -0.3, &"head": -0.3, &"candle": 0.15, &"@root": Vector2i(-14, 0), &"view:wick": &"f2", &"emit:eye": 1, &"hide:puddle": true, &"view:drip": &"d0"}
	var a3 := {&"body": -0.08, &"@root": Vector2i(-8, 0), &"view:wick": &"f0", &"hide:puddle": true, &"view:drip": &"d0"}
	_legs(a1, 0.3)
	_legs(a2, -0.2)
	b.anim(&"attack", 4, [100, 60, 110, 140], {0: a0, 1: a1, 2: a2, 3: a3}, {"loop": false, "interp": &"hold"})
	var h0 := {&"body": 0.25, &"head": 0.3, &"candle": 0.15, &"@root": Vector2i(3, 0), &"view:wick": &"small", &"hide:eye": true, &"hide:puddle": true, &"view:drip": &"d2"}
	var h1 := {&"body": 0.08, &"@root": Vector2i(2, 0), &"view:wick": &"f1", &"hide:puddle": true, &"view:drip": &"d0"}
	_legs(h0, 0.25)
	b.anim(&"hurt", 2, [90, 140], {0: h0, 1: h1}, {"loop": false, "interp": &"hold"})
	# Muerte: las patas ceden, la cera se derrite, la mecha estalla, queda el charco.
	var d := {}
	d[0] = h0.duplicate()
	d[1] = {&"body": 0.05, &"candle": 0.2, &"@root": Vector2i(1, 1), &"view:wick": &"big", &"hide:puddle": false, &"hide:eye": true, &"view:drip": &"d2"}
	_splay(d[1], 0.5)
	d[2] = {&"body": 0.05, &"candle": 0.3, &"@root": Vector2i(1, 2), &"view:wick": &"burst", &"emit:flame": 1, &"hide:puddle": false, &"hide:eye": true, &"view:drip": &"d3"}
	_splay(d[2], 0.8)
	d[3] = {&"candle": 0.35, &"@root": Vector2i(1, 2), &"view:wick": &"burst", &"hide:puddle": false, &"hide:eye": true, &"view:drip": &"d3", &"hide:head": true, &"hide:wax_body": true}
	_splay(d[3], 1.0)
	d[4] = {&"@root": Vector2i(1, 3), &"view:wick": &"small", &"hide:puddle": false, &"hide:eye": true, &"hide:jaws": true, &"hide:antennae": true, &"hide:head": true,
		&"hide:wax_body": true, &"hide:drip": true, &"hide:shell": true}
	d[5] = {&"@root": Vector2i(1, 3), &"view:wick": &"out", &"hide:puddle": false, &"hide:eye": true, &"hide:jaws": true, &"hide:antennae": true, &"hide:head": true,
		&"hide:wax_body": true, &"hide:drip": true, &"hide:shell": true}
	for f in [4, 5]:
		for s: String in ["f", "n"]:
			for i in 3:
				d[f][StringName("hide:leg_%s%d_a" % [s, i])] = true
				d[f][StringName("hide:leg_%s%d_b" % [s, i])] = true
	b.anim(&"death", 6, [70, 90, 90, 100, 160, 400], d, {"loop": false, "interp": &"hold"})
