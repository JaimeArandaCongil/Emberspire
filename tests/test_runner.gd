extends Node
## Suite headless de QA: lógica pura de combate, economía y datos.
## Ejecutar: godot --headless --path . res://tests/test_runner.tscn

var _fails := 0
var _checks := 0


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	_test_numbers()
	_test_data_integrity()
	_test_economy()
	_test_combat_basic()
	_test_burn()
	_test_full_fights()
	_test_doors()
	_test_save_roundtrip()
	_test_art()
	print("\n== QA: %d comprobaciones, %d fallos ==" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func check(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("  FALLO: ", label)


func _test_numbers() -> void:
	check(Num.fmt(999) == "999", "fmt 999")
	check(Num.fmt(1500) == "1.50K", "fmt 1.5K -> %s" % Num.fmt(1500))
	check(Num.fmt(2.5e9) == "2.50B", "fmt 2.5B -> %s" % Num.fmt(2.5e9))


func _test_data_integrity() -> void:
	for id: String in CardDB.CARDS:
		var c := Card.new(id)
		check(Art.has_icon(c.def()["icon"]), "icono de carta existe: %s" % id)
		check(CardDB.describe(c) != "" or c.type() == "status", "descripción no vacía: %s" % id)
		var up := Card.new(id, true)
		CardDB.describe(up)
	for id: String in EnemyDB.ENEMIES:
		var d: Dictionary = EnemyDB.ENEMIES[id]
		check(Art.has_shape(d["shape"]), "forma de enemigo existe: %s" % id)
	for act: Dictionary in EnemyDB.ACTS:
		for key in ["normal", "easy", "elite"]:
			for enc: Array in act[key]:
				for eid: String in enc:
					check(EnemyDB.ENEMIES.has(eid), "encuentro referencia enemigo válido: %s" % eid)
	for id: String in RelicDB.RELICS:
		check(Art.has_icon(RelicDB.RELICS[id]["icon"]), "icono de reliquia: %s" % id)


func _test_economy() -> void:
	Game.embers = 0.0
	check(not Game.buy_generator("spark"), "no se compra sin Ascuas")
	Game.embers = 100.0
	check(Game.buy_generator("spark"), "compra chispa")
	check(Game.gen_count("spark") == 1, "1 chispa")
	check(is_equal_approx(Game.production(), 0.5), "producción 0.5/s -> %f" % Game.production())
	var g := ForgeDB.generator("spark")
	var c10 := ForgeDB.generator_cost(g, 0, 10)
	var sum := 0.0
	for i in 10:
		sum += ForgeDB.generator_cost(g, i, 1)
	check(absf(c10 - sum) < 0.01, "coste geométrico x10 coincide")
	check(ForgeDB.max_affordable(g, 0, sum) == 10, "max asequible = 10")
	Game.max_floor = 10
	check(is_equal_approx(Game.production(), 0.5 * 2.0), "braseros duplican a piso 10")
	Game.life_embers = 4.0e6
	check(Game.rebirth_gain() == 3, "polvo estelar: %d" % Game.rebirth_gain())
	check(Game.rebirth(), "renacer")
	check(Game.gen_count("spark") == 0 and Game.stardust_total == 3.0, "renacer reinicia y otorga polvo")
	Game.reset_all()


func _new_engine(enemies: Array, floor_num := 1) -> CombatEngine:
	var run := Game.start_run(42)
	run.floor_num = floor_num
	var eng := CombatEngine.new()
	eng.bank_embers = false
	eng.setup(run, enemies, floor_num, "combat")
	eng.start()
	return eng


func _test_combat_basic() -> void:
	var eng := _new_engine(["ash_slime"])
	check(eng.hand.size() == 5, "mano inicial 5")
	check(eng.energy == 3, "energía 3")
	var e := eng.enemies[0]
	var hp0 := e.hp
	var strike := Card.new("strike")
	eng.hand.append(strike)
	check(eng.play_card(strike, e), "jugar Golpe")
	check(e.hp == hp0 - 6 or not e.alive(), "Golpe hace 6")
	e.add_status("vuln", 1)
	check(eng.calc_damage(eng.player, e, 10) == 15, "vulnerable x1.5")
	eng.player.add_status("weak", 1)
	check(eng.calc_damage(eng.player, e, 10) == 11, "débil+vulnerable = 11")
	var def := Card.new("defend")
	eng.hand.append(def)
	eng.energy = 3
	eng.play_card(def)
	check(eng.player.block == 5, "Defensa da 5 bloqueo")
	var unplay := Card.new("kindling")
	eng.hand.append(unplay)
	check(not eng.play_card(unplay), "Leña no se juega")


func _test_burn() -> void:
	var eng := _new_engine(["soot_golem"])
	var k := Card.new("kindling")
	eng.hand.append(k)
	var e0 := eng.energy
	var h0 := eng.hand.size()
	check(eng.burn_card(k), "quemar Leña")
	check(eng.energy == e0 + 1, "Leña da energía")
	check(eng.hand.size() == h0, "Leña roba 1 (mano igual)")
	check(eng.burns_left == 0, "quemas agotadas")
	var c := eng.hand[0]
	check(not eng.burn_card(c), "no se puede quemar sin cargas")
	check(eng.burned_count == 1 and eng.exhaust_pile.has(k), "carta exiliada")
	check(eng.embers_this_combat > 0.0, "quemar produce Ascuas")


## Simula combates completos con una IA simple para detectar bloqueos/excepciones.
func _test_full_fights() -> void:
	var wins := 0
	for fl in [1, 5, 10, 15, 20, 30, 35]:
		var kind := "boss" if fl % 10 == 0 else "combat"
		var run := Game.start_run(fl)
		run.floor_num = fl
		var ids := EnemyDB.pick_encounter(kind, fl, run.rng)
		var eng := CombatEngine.new()
		eng.bank_embers = false
		eng.setup(run, ids, fl, kind)
		eng.start()
		var guard := 0
		while not eng.over and guard < 60:
			guard += 1
			var progressed := true
			while progressed and not eng.over:
				progressed = false
				for c in eng.hand.duplicate():
					if not c.is_playable() and eng.can_burn(c):
						eng.burn_card(c)
						progressed = true
						break
					if eng.can_play(c):
						var alive := eng.living_enemies()
						eng.play_card(c, alive[0] if not alive.is_empty() else null)
						progressed = true
						break
			if eng.over:
				break
			eng.end_player_turn()
			eng.begin_enemy_phase()
			for e in eng.enemies:
				eng.enemy_act(e)
			eng.end_enemy_phase()
		check(eng.over, "combate termina (piso %d, %d turnos)" % [fl, guard])
		if eng.won:
			wins += 1
		print("  piso %d %s: %s en %d turnos, PV %d" % [fl, ids, "victoria" if eng.won else "derrota", eng.turn, eng.player.hp])
	check(wins >= 1, "la IA simple gana algún combate temprano")


func _test_doors() -> void:
	var run := Game.start_run(7)
	for f in 40:
		var doors := run.roll_doors()
		check(doors.size() >= 1, "puertas generadas")
		run.floor_num += 1
		if run.floor_num % 10 == 0:
			check(doors == ["boss"], "jefe en piso %d" % run.floor_num)
	var rewards := run.roll_card_rewards(["base", "pyre"])
	check(rewards.size() == 3, "3 cartas de recompensa")


func _test_save_roundtrip() -> void:
	Game.embers = 1234.0
	Game.generators = {"spark": 3}
	Game.arsenal = {"vitality": 2}
	Game.grimoires = {"pyre": true}
	var d := Game.to_dict()
	var j: Dictionary = JSON.parse_string(JSON.stringify(d))
	Game.reset_all()
	Game.from_dict(j)
	check(is_equal_approx(Game.embers, 1234.0), "guardado: ascuas")
	check(Game.gen_count("spark") == 3, "guardado: generadores")
	check(Game.arsenal_level("vitality") == 2, "guardado: arsenal")
	check(Game.grimoires.has("pyre"), "guardado: grimorios")
	Game.reset_all()


func _test_art() -> void:
	for id: String in Art.SPRITES:
		var rows: Array = Art.SPRITES[id]
		var w := String(rows[0]).length()
		for r in rows:
			check(String(r).length() == w, "sprite %s filas de igual ancho (%d vs %d)" % [id, String(r).length(), w])
	for s: String in Art.SHAPES:
		var t := Art.monster(s, "test", 0)
		check(t != null and t.get_width() > 8, "monstruo generado: %s" % s)
	check(Art.background(0, 1) != null, "fondo generado")
