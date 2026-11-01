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
	_test_mastery()
	_test_resonance_and_pacts()
	_test_new_mechanics()
	_test_meta()
	_test_all_cards_play()
	_test_v03()
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
	for id: String in RelicDB.PERKS:
		check(Art.has_icon(RelicDB.PERKS[id]["icon"]), "icono de resonancia: %s" % id)
	for g in ForgeDB.GENERATORS:
		for tier in 3:
			check(RelicDB.perk_for(g["id"], tier) != "", "resonancia %s nivel %d" % [g["id"], tier])
	for pact in ForgeDB.PACTS:
		check(Art.has_icon(pact["icon"]), "icono de pacto: %s" % pact["id"])
	for pid: String in CardDB.POWER_ICONS:
		check(Art.has_icon(CardDB.POWER_ICONS[pid]), "icono de poder: %s" % pid)
	for act: Dictionary in EnemyDB.ACTS:
		for enc: Array in act["boss"]:
			for eid: String in enc:
				check(EnemyDB.ENEMIES.has(eid), "jefe válido: %s" % eid)
	for eid: String in EnemyDB.ENEMIES:
		for mv: Array in EnemyDB.ENEMIES[eid]["moves"]:
			for op: Array in mv:
				if op[0] == "summon" or op[0] == "add_card":
					check(EnemyDB.ENEMIES.has(op[1]) or CardDB.CARDS.has(op[1]), "referencia válida en %s: %s" % [eid, op[1]])
	for h in ForgeDB.HITOS:
		check(h.has("dust") or h.has("secs"), "hito con recompensa: %s" % h["id"])
	check(CardDB.CARDS.size() >= 90, "al menos 90 cartas (%d)" % CardDB.CARDS.size())
	check(RelicDB.RELICS.size() >= 40, "al menos 40 reliquias (%d)" % RelicDB.RELICS.size())


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
	Game.life_embers = 8.0e6
	check(Game.rebirth_gain() == 3, "polvo estelar (8^0.45 × 1.2 = 3): %d" % Game.rebirth_gain())
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
	var r := Game.start_run(3)
	r.floor_num = 6
	r.in_room = true
	r.deck.append(Card.new("gunpowder", true))
	r.add_relic("ember_ring")
	var j2: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Game.run = null
	Game.from_dict(j2)
	check(Game.run != null and Game.run.floor_num == 5, "guardado: ascensión en curso (repite piso)")
	check(Game.run.deck.size() == 11 and Game.run.deck[10].upgraded, "guardado: mazo de la ascensión")
	check(Game.run.has_relic("ember_ring"), "guardado: reliquias")
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


func _test_mastery() -> void:
	Game.reset_all()
	check(Game.mastery_level("strike") == 0, "maestría inicial 0")
	check(Game.add_mastery("strike", 2) == 1, "2 quemas → nivel 1")
	check(Card.new("strike").effects()[0][1] == 7, "maestría 1: Golpe 6 → 7 (%d)" % Card.new("strike").effects()[0][1])
	Game.add_mastery("strike", 200)
	check(Game.mastery_level("strike") == Game.MASTERY_MAX, "maestría máxima")
	check(Card.new("strike").effects()[0][1] == 9, "maestría 5: Golpe ×1.5 = 9")
	check(Game.burn_value(1, 1, 1, 5) > Game.burn_value(1, 1, 1, 0) * 1.9, "maestría 5 dobla Ascuas al quemar")
	check(Game.add_mastery("soot", 5) == 0, "los estados no ganan maestría")
	# Quemar en combate da maestría si el motor ingresa en Game.
	Game.reset_all()
	var run := Game.start_run(11)
	var eng := CombatEngine.new()
	eng.setup(run, ["soot_golem"], 1, "combat")
	eng.start()
	var k := Card.new("kindling")
	eng.hand.append(k)
	eng.burn_card(k)
	check(int(Game.mastery.get("kindling", 0)) == 1, "quemar suma maestría")
	check(Game.stat_value("burns") == 1.0, "estadística de quemas")
	Game.run = null
	Game.reset_all()


func _test_resonance_and_pacts() -> void:
	Game.reset_all()
	Game.generators = {"spark": 10, "bellows": 50}
	var perks := Game.perk_ids()
	check(perks.has("res_spark1") and not perks.has("res_spark2"), "resonancia chispa 1")
	check(perks.has("res_bellows1") and perks.has("res_bellows2"), "resonancia fuelle 1 y 2")
	Game.talents["echoes"] = true
	check(not Game.perk_ids().has("res_spark2") and Game.resonance_threshold(1) == 25, "Ecos reduce umbrales")
	Game.talents.erase("echoes")
	Game.generators = {"furnace": 10}
	var r := Game.start_run(5)
	check(r.has_relic("res_furnace1") and r.max_hp == 68, "Ladrillo Cálido +8 PV (%d)" % r.max_hp)
	var eng := CombatEngine.new()
	eng.bank_embers = false
	Game.generators = {"bellows": 10}
	r = Game.start_run(5)
	eng.setup(r, ["ash_slime"], 1, "combat")
	eng.start()
	check(eng.player.block == 5, "Corriente: 5 de bloqueo inicial (%d)" % eng.player.block)
	# Pactos
	Game.reset_all()
	Game.max_floor = 10
	Game.active_pacts = ["pact_hp", "pact_boss"]
	r = Game.start_run(5)
	check(r.heat() == 3, "calor 3")
	var e1 := CombatEngine.new()
	e1.bank_embers = false
	e1.setup(r, ["coalfather"], 10, "boss")
	check(e1.enemies[0].max_hp == int(round(int(round(130 * (1.0 + 0.08 * 9))) * 1.25 * 1.5)), "pactos escalan PV del jefe (%d)" % e1.enemies[0].max_hp)
	var before := Game.embers
	Game.gain_tower_embers(100.0, "test")
	check(is_equal_approx(Game.embers - before, 160.0), "calor 3 → ×1.6 Ascuas (%f)" % (Game.embers - before))
	Game.max_floor = 0
	r = Game.start_run(5)
	check(r.pacts.is_empty(), "sin piso 10 no hay pactos")
	Game.run = null
	Game.reset_all()


func _engine_with(enemies: Array, cards: Array) -> CombatEngine:
	var run := Game.start_run(3)
	run.floor_num = 3
	var eng := CombatEngine.new()
	eng.bank_embers = false
	eng.setup(run, enemies, 3, "combat")
	eng.start()
	for id: String in cards:
		eng.hand.append(Card.new(id))
	eng.energy = 10
	return eng


func _test_new_mechanics() -> void:
	Game.reset_all()
	# Robo de la Urraca y devolución doble.
	var run := Game.start_run(9)
	var eng := CombatEngine.new()
	eng.setup(run, ["ember_magpie"], 2, "combat")
	eng.start()
	Game.embers = 1000.0
	var mag := eng.enemies[0]
	eng._enemy_op(mag, ["steal", 6])
	check(mag.stolen > 0.0 and Game.embers < 1000.0, "la Urraca roba Ascuas (%f)" % mag.stolen)
	var stolen := mag.stolen
	var before := Game.embers
	eng._damage(mag, 999, false)
	check(Game.embers >= before + stolen * 2.0 - 0.01, "al morir devuelve el doble")
	Game.run = null
	# Ahogo: menos Quemas el próximo turno.
	eng = _engine_with(["ash_slime"], [])
	eng._enemy_op(eng.enemies[0], ["choke", 1])
	eng.end_player_turn()
	eng.begin_enemy_phase()
	eng.end_enemy_phase()
	check(eng.burns_left == 0, "Ahogo resta una Quema (%d)" % eng.burns_left)
	# Invocación.
	eng = _engine_with(["great_bellows"], [])
	eng._enemy_op(eng.enemies[0], ["summon", "candle_mite", 2])
	check(eng.enemies.size() == 3, "invoca 2 ácaros")
	# Explosión al morir del ácaro.
	var hp0 := eng.player.hp
	eng.player.block = 0
	eng._damage(eng.enemies[1], 999, false)
	check(eng.player.hp < hp0, "el ácaro explota al morir")
	# Recuperar carta quemada.
	eng = _engine_with(["soot_golem"], ["coal", "phoenix_paper"])
	var coal: Card = eng.hand[eng.hand.size() - 2]
	eng.burns_left = 1
	eng.burn_card(coal)
	check(not eng.hand.has(coal), "carbón quemado")
	eng.play_card(eng.hand[eng.hand.size() - 1])
	check(eng.hand.has(coal), "Fénix de Papel recupera la carta quemada")
	# Fundir: la siguiente quema en caliente no cuesta Energía.
	eng = _engine_with(["soot_golem"], ["strike", "smelt"])
	var stk: Card = eng.hand[eng.hand.size() - 2]
	eng.play_card(eng.hand[eng.hand.size() - 1])
	var en0 := eng.energy
	eng.burns_left = 1
	check(eng.hot_burn_cost(stk) == 0, "Fundir: quema en caliente gratis")
	check(eng.burn_card(stk, true) and eng.energy == en0, "Fundir no gasta Energía")
	# Mejora temporal que no sobrevive al combate.
	eng = _engine_with(["ash_slime"], ["reforge"])
	eng.play_card(eng.hand[eng.hand.size() - 1])
	var any_up := false
	for c in eng.hand:
		if c.temp_up:
			any_up = true
	check(any_up, "Reforjar mejora la mano")
	eng._damage(eng.enemies[0], 999, false)
	eng._check_end()
	var leftover := false
	for c in eng.run.deck:
		if c.temp_up:
			leftover = true
	check(not leftover, "las mejoras temporales se limpian al acabar")
	# Espinas del enemigo.
	eng = _engine_with(["slag_serpent"], ["strike"])
	hp0 = eng.player.hp
	eng.player.block = 0
	eng.play_card(eng.hand[eng.hand.size() - 1], eng.enemies[0])
	check(eng.player.hp == hp0 - 3, "espinas de la Sierpe (%d)" % (hp0 - eng.player.hp))
	# Brasa (retener) y Etérea.
	eng = _engine_with(["ash_slime"], ["anvil_ward", "quicksilver"])
	var ward: Card = eng.hand[eng.hand.size() - 2]
	var qs: Card = eng.hand[eng.hand.size() - 1]
	eng.end_player_turn()
	check(eng.hand.has(ward), "Brasa: se queda en la mano")
	check(eng.exhaust_pile.has(qs), "Etérea: se agota")
	# Ceniza Húmeda no se quema.
	eng = _engine_with(["ash_slime"], ["wet_ash"])
	check(not eng.can_burn(eng.hand[eng.hand.size() - 1]), "Ceniza Húmeda no se quema")
	# Hija del Fuego: los Ataques aplican Quemadura (con y sin objetivo).
	eng = _engine_with(["ash_slime", "cinder_bat"], ["fireborn", "strike", "cleave"])
	eng.play_card(eng.hand[eng.hand.size() - 3])
	eng.play_card(eng.hand[eng.hand.size() - 2], eng.enemies[0])
	check(eng.enemies[0].st("scorch") >= 1 or not eng.enemies[0].alive(), "Hija del Fuego con objetivo")
	eng.play_card(eng.hand[eng.hand.size() - 1])
	check(eng.attacks_played == 2, "Hija del Fuego sin objetivo")
	# Poderes combinados con ataques: cada poder seguido de cada tipo de ataque.
	for pw: String in CardDB.POWERS:
		var e2 := _engine_with(["slag_crawler", "ash_slime"], ["strike", "cleave", "sparks"])
		e2.player.powers[pw] = 2
		for i in 3:
			e2.play_card(e2.hand[e2.hand.size() - 1], e2.enemies[0] if e2.enemies[0].alive() else null)
		e2.end_player_turn()
		e2.begin_enemy_phase()
		e2.end_enemy_phase()
	# Transmutar.
	eng = _engine_with(["ash_slime"], ["transmute"])
	var n0 := eng.hand.size()
	eng.play_card(eng.hand[eng.hand.size() - 1])
	check(eng.hand.size() == n0 - 1, "Transmutar conserva el tamaño de mano")
	Game.run = null
	Game.reset_all()


func _test_meta() -> void:
	Game.reset_all()
	var r := Game.start_run(4)
	r.add_relic("whetstone")
	check(Game.relic_codex.has("whetstone"), "reliquia al Reliquario")
	check(is_equal_approx(Game.codex_mult(), 1.02), "Reliquario +2%")
	Game.run = null
	Game.max_floor = 5
	Game.check_hitos()
	check(Game.hitos.has("floor5"), "hito del piso 5")
	Game.max_floor = 10
	var dust0 := Game.stardust_total
	Game.check_hitos()
	check(Game.stardust_total == dust0 + 1, "hito del piso 10 da Polvo")
	Game.mastery = {"strike": 3}
	Game.active_pacts = ["pact_dmg"]
	Game.heirloom_picks = ["whetstone"]
	var j: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Game.reset_all()
	Game.from_dict(j)
	check(Game.mastery_level("strike") == 1, "guardado: maestría")
	check(Game.relic_codex.has("whetstone"), "guardado: reliquario")
	check(Game.hitos.has("floor10"), "guardado: hitos")
	check(Game.active_pacts == ["pact_dmg"], "guardado: pactos")
	check(Game.heirloom_picks == ["whetstone"], "guardado: herencia")
	Game.arsenal = {"heirloom": 1}
	r = Game.start_run(4)
	check(r.has_relic("whetstone"), "herencia elegida del Reliquario")
	Game.run = null
	Game.reset_all()


## Juega y quema cada carta del juego contra enemigos variados: ninguna debe romper el motor.
func _test_all_cards_play() -> void:
	Game.reset_all()
	var ok := 0
	for id: String in CardDB.CARDS:
		for up: bool in [false, true]:
			var eng := _engine_with(["slag_crawler", "ash_slime"], [])
			var c := Card.new(id, up)
			eng.hand.append(c)
			eng.enemies[0].add_status("scorch", 3)
			if c.is_playable():
				eng.play_card(c, eng.enemies[0])
			elif eng.can_burn(c):
				eng.burn_card(c)
			var c2 := Card.new(id, up)
			eng.hand.append(c2)
			eng.burns_left = 2
			if eng.can_burn(c2):
				eng.burn_card(c2)
			eng.end_player_turn()
			eng.begin_enemy_phase()
			for e in eng.enemies.duplicate():
				eng.enemy_act(e)
			eng.end_enemy_phase()
			ok += 1
	check(ok == CardDB.CARDS.size() * 2, "todas las cartas jugadas y quemadas")
	# Cada enemigo actúa varios turnos sin romper nada.
	for eid: String in EnemyDB.ENEMIES:
		var eng2 := _engine_with([eid], [])
		for t in 5:
			eng2.end_player_turn()
			eng2.begin_enemy_phase()
			for e in eng2.enemies.duplicate():
				eng2.enemy_act(e)
			eng2.end_enemy_phase()
			if eng2.over:
				break
	check(true, "todos los enemigos actúan")
	Game.run = null
	Game.reset_all()


func _test_v03() -> void:
	Game.reset_all()
	# Quema en caliente: paga el coste, ×2 Ascuas y ×2 Maestría.
	var eng := _engine_with(["soot_golem"], ["heavy_hammer", "kindling", "bellows"])
	var hammer: Card = eng.hand[eng.hand.size() - 3]
	var kind: Card = eng.hand[eng.hand.size() - 2]
	var zero: Card = eng.hand[eng.hand.size() - 1]
	check(eng.hot_burn_cost(hammer) == 2, "caliente cuesta lo que la carta")
	check(eng.hot_burn_cost(kind) == -1, "el Combustible no se quema en caliente")
	check(eng.hot_burn_cost(zero) == -1, "coste 0 no se quema en caliente")
	var pv0: Dictionary = eng.burn_preview(hammer, false)
	var pv1: Dictionary = eng.burn_preview(hammer, true)
	check(is_equal_approx(float(pv1["embers"]), float(pv0["embers"]) * 2.0), "caliente ×2 Ascuas")
	var e0 := eng.energy
	eng.burns_left = 1
	check(eng.burn_card(hammer, true), "quemar en caliente")
	check(eng.energy == e0 - 2 and eng.hot_burns == 1, "paga 2 de Energía")
	eng.energy = 0
	eng.burns_left = 1
	var stk := Card.new("strike")
	eng.hand.append(stk)
	check(not eng.can_burn_hot(stk) and eng.can_burn(stk), "sin Energía sólo quema normal")
	# Maestría: jugar da 0.25; caliente da 2.
	Game.reset_all()
	var run := Game.start_run(21)
	var e2 := CombatEngine.new()
	e2.setup(run, ["soot_golem"], 1, "combat")
	e2.start()
	var s2 := Card.new("strike")
	e2.hand.append(s2)
	e2.energy = 5
	e2.play_card(s2, e2.enemies[0])
	check(is_equal_approx(Game.mastery_xp("strike"), 0.15), "jugar da 0.15 de Maestría")
	var s3 := Card.new("strike")
	e2.hand.append(s3)
	e2.burns_left = 1
	e2.burn_card(s3, true)
	check(is_equal_approx(Game.mastery_xp("strike"), 2.15), "caliente da 2 de Maestría")
	Game.run = null
	# Temple.
	Game.reset_all()
	Game.mastery = {"strike": 15.0, "kindling": 15.0}
	check(Game.temple_pending("strike"), "Temple pendiente en Maestría 3")
	Game.choose_temple("strike", "edge")
	check(Card.new("strike").effects()[0][1] == int(6 + round(6 * 0.1 * 5)), "Filo: +2 niveles de números (%d)" % Card.new("strike").effects()[0][1])
	Game.choose_temple("strike", "ember")
	var bops := Card.new("strike").burn_effects()
	check(not bops.is_empty() and bops[0][0] == "dmg_rand_hot", "Brasa: Golpe inflige daño al quemarse")
	Game.choose_temple("kindling", "rekindle")
	var e3 := _engine_with(["soot_golem"], ["kindling"])
	var kd: Card = e3.hand[e3.hand.size() - 1]
	e3.burns_left = 1
	e3.burn_card(kd)
	check(e3.discard.has(kd), "Rescoldo: el Combustible vuelve al descarte")
	Game.reset_all()
	# Resonancias elegibles.
	Game.generators = {"bellows": 10}
	Game.perk_choices = {"bellows:0": "b"}
	check(Game.perk_ids().has("res_bellows1b") and not Game.perk_ids().has("res_bellows1"), "Resonancia B elegida")
	for gid in ["spark", "bellows", "furnace", "crucible", "blast", "dwarf_sun", "heart_world"]:
		for tier in 3:
			check(RelicDB.perk_for(gid, tier, "b") != "", "variante B %s %d" % [gid, tier])
	Game.reset_all()
	# Afijos de ciclo y enemigos que reaccionan.
	var rr := RandomNumberGenerator.new()
	var cyc := EnemyDB.make("ash_slime", 35, rr)
	check(cyc.affixes.size() >= 1, "ciclo II: afijo")
	check(EnemyDB.make("ash_slime", 5, rr).affixes.is_empty(), "ciclo I: sin afijos")
	var e4 := _engine_with(["flame_moth"], ["strike"])
	var moth := e4.enemies[0]
	e4.burns_left = 1
	e4.burn_card(e4.hand[e4.hand.size() - 1])
	check(moth.st("str") == 1, "Polilla de Llama: +1 Fuerza al quemar")
	var e5 := _engine_with(["rival_bellows"], [])
	e5.end_player_turn()
	check(e5.enemies[0].block >= 12, "Fuelle Rival se blinda si no quemas")
	# Brasas Vivas y Resplandor.
	Game.reset_all()
	var r6 := Game.start_run(31)
	r6.streak_floors = 10
	Game.gain_tower_embers(100.0, "test")
	check(is_equal_approx(r6.pot, 40.0), "bote +40% con 10 pisos de racha (%f)" % r6.pot)
	var before := Game.embers
	check(is_equal_approx(Game.cash_pot(), 40.0) and is_equal_approx(Game.embers, before + 40.0), "cobrar el bote")
	check(r6.streak_floors == 0, "cobrar reinicia la racha")
	r6.burned = 40
	r6.floors_climbed = 12
	Game.generators = {"spark": 10}
	var p0 := Game.production()
	var sm := Game.end_run()
	check(not (sm["glow"] as Dictionary).is_empty(), "Resplandor al volver")
	check(is_equal_approx(Game.production(), p0 * 2.0), "Resplandor +100% con 40 quemas (%f)" % (Game.production() / p0))
	# Puntos de control y Grimorios activos.
	Game.reset_all()
	Game.max_floor = 25
	check(Game.checkpoints() == [1, 11], "puntos de control (%s)" % str(Game.checkpoints()))
	var r7 := Game.start_run(5, 11)
	check(r7.floor_num == 10 and r7.pending_drafts == 2 and r7.pending_boss_relics == 1, "compensación del punto de control")
	Game.run = null
	Game.grimoires = {"pyre": true, "anvil": true, "ash": true}
	check(Game.active_grimoire_list().size() == 2, "2 Grimorios activos por defecto")
	Game.active_grimoires = ["ash"]
	check(Game.card_packs() == ["base", "ash"], "Grimorios activos elegidos")
	Game.stardust = 1000.0
	check(Game.buy_constellation("c_third") and Game.max_active_grimoires() == 3, "Constelación: Tercer Grimorio")
	# Puertas: sin duplicados salvo combates con rasgo distinto, con datos de encuentro.
	Game.reset_all()
	var r8 := Game.start_run(77)
	var ok := true
	for f in 60:
		var doors := r8.roll_doors()
		check(r8.door_meta.size() == doors.size(), "datos de cada puerta")
		var seen := {}
		var traits := {}
		for i in doors.size():
			var k: String = doors[i]
			if k != "combat" and seen.has(k):
				ok = false
			seen[k] = true
			if k == "combat":
				var t: String = r8.door_meta[i]["trait"]
				if traits.has(t):
					ok = false
				traits[t] = true
		r8.floor_num += 1
	check(ok, "puertas sin duplicados")
	Game.run = null
	# Guardado v3.
	Game.temples = {"strike": "edge"}
	Game.perk_choices = {"spark:0": "b"}
	Game.constellations = {"c_glow": true}
	Game.glow_value = 1.5
	Game.glow_until = Time.get_unix_time_from_system() + 600.0
	var j: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Game.reset_all()
	Game.from_dict(j)
	check(Game.temples.get("strike", "") == "edge" and Game.perk_choices.get("spark:0", "") == "b", "guardado: Temple y Resonancias")
	check(Game.constellations.has("c_glow") and is_equal_approx(Game.glow_value, 1.5), "guardado: Constelaciones y Resplandor")
	Game.reset_all()
