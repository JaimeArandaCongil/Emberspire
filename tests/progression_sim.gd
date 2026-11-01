extends Node
## Simulación de progresión: una IA juega el bucle completo durante horas simuladas
## (ascender → morir → invertir en la Forja → renacer) y registra cuándo llega cada hito.
## Mide el ritmo real del juego: tiempo hasta cada jefe, al primer Renacer, Maestrías, Resonancias...
## Ejecutar: godot --headless --path . res://tests/progression_sim.tscn [-- horas]

const SECS_PER_FLOOR := 75.0      # duración media de un piso jugado por una persona
const FORGE_PAUSE := 45.0         # tiempo en la Forja entre ascensiones
const CLICKS_PER_SEC := 2.0       # clics en el horno durante la pausa (sólo importa al principio)

var hours := 6.0
var t := 0.0
var marks := {}
var runs := 0


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if not a.is_empty():
		hours = float(a[0])
	Game.autosave_enabled = false
	Game.reset_all()
	print("run   t(min)  piso  récord  prod/s      Polvo  Reson. Maestr. Reliq.  Calor")
	while t < hours * 3600.0:
		runs += 1
		_spend()
		var floor_reached := _ascend()
		_mark_progress()
		if runs <= 12 or runs % 5 == 0:
			print("%3d  %7.1f  %4d  %6d  %-10s %5d  %6d  %6d  %5d  %5d" % [runs, t / 60.0, floor_reached, Game.max_floor,
				Num.fmt(Game.production()), int(Game.stardust_total), Game.perk_ids().size(), Game.mastered_count(1),
				Game.relic_codex.size(), Game.pact_heat(Game.active_pacts)])
	print("\n== Hitos de progresión (minutos de juego) ==")
	var keys := marks.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return float(marks[x]) < float(marks[y]))
	for k: String in keys:
		print("  %-34s %6.1f min" % [k, float(marks[k]) / 60.0])
	print("Crónica: %d/%d hitos · Maestría 5: %d cartas · Renacimientos: %d" % [Game.hitos.size(), ForgeDB.HITOS.size(),
		Game.mastered_count(Game.MASTERY_MAX), Game.rebirths])
	get_tree().quit()


func _mark(key: String) -> void:
	if not marks.has(key):
		marks[key] = t


func _mark_progress() -> void:
	for f: int in [5, 10, 20, 30, 40, 50, 60]:
		if Game.max_floor >= f:
			_mark("Récord piso %d" % f)
	for p: float in [10.0, 100.0, 1000.0, 1.0e4, 1.0e5, 1.0e6, 1.0e7]:
		if Game.production() >= p:
			_mark("Producción %s/s" % Num.fmt(p))
	for g: String in ["pyre", "anvil", "forge", "ash", "crucible", "solar"]:
		if Game.grimoires.has(g):
			_mark("Grimorio %s" % g)
	if Game.rebirths >= 1:
		_mark("Primer Renacer")
	if Game.rebirths >= 3:
		_mark("Tercer Renacer")
	if Game.perk_ids().size() >= 1:
		_mark("Primera Resonancia")
	if Game.perk_ids().size() >= 7:
		_mark("7 Resonancias")
	if Game.mastered_count(Game.MASTERY_MAX) >= 1:
		_mark("Primera carta con Maestría 5")
	if Game.relic_codex.size() >= 10:
		_mark("Reliquario 10")
	if Game.pact_heat(Game.active_pacts) >= 3:
		_mark("Calor de Pacto 3")


# --- Forja: la IA invierte con una política sencilla --------------------------

const ARSENAL_WEIGHT := {"vitality": 0.9, "greed": 1.0, "flue": 0.8, "temper": 0.9, "hearth": 3.0, "arm": 1.0,
	"heirloom": 1.4, "hands": 1.1, "edge": 1.3, "skin": 1.3, "core": 1.0}


func _spend() -> void:
	# Clics en el horno mientras se decide (relevante sólo al principio).
	Game._add(Game.click_value() * CLICKS_PER_SEC * FORGE_PAUSE * (1.0 if Game.production() < 50.0 else 0.2), "click")
	Game._add(Game.production() * FORGE_PAUSE, "idle")
	t += FORGE_PAUSE
	# Renacer cuando dobla el Polvo total (o da 3 la primera vez).
	var gain := Game.rebirth_gain()
	if gain >= maxi(3, int(Game.stardust_total)):
		Game.rebirth()
	for talent in ForgeDB.TALENTS:
		Game.buy_talent(talent["id"])
	var guard := 0
	while guard < 400:
		guard += 1
		var best_kind := ""
		var best_id := ""
		var best_eff := INF
		var best_cost := INF
		# Mejor generador por coste / producción añadida.
		for i in ForgeDB.GENERATORS.size():
			if not Game.generator_visible(i):
				continue
			var g: Dictionary = ForgeDB.GENERATORS[i]
			var cost := Game.gen_cost(g, 1)
			var n := Game.gen_count(g["id"])
			var gain_rate := float(g["rate"]) * ((n + 1) * ForgeDB.milestone_mult(n + 1) - n * ForgeDB.milestone_mult(n))
			var eff := cost / maxf(gain_rate, 0.0001) / 400.0
			if eff < best_eff:
				best_eff = eff
				best_kind = "gen"
				best_id = g["id"]
				best_cost = cost
		for ar in ForgeDB.ARSENAL:
			var lvl := Game.arsenal_level(ar["id"])
			if lvl >= int(ar["max"]):
				continue
			var c := ForgeDB.arsenal_cost(ar, lvl)
			var eff2: float = c * float(ARSENAL_WEIGHT.get(ar["id"], 1.0)) / maxf(1.0, Game.production() * 60.0)
			if eff2 < best_eff:
				best_eff = eff2
				best_kind = "ars"
				best_id = ar["id"]
				best_cost = c
		for gr in ForgeDB.GRIMOIRES:
			if Game.grimoires.has(gr["id"]):
				continue
			var eff3: float = float(gr["cost"]) * 1.2 / maxf(1.0, Game.production() * 60.0)
			if eff3 < best_eff:
				best_eff = eff3
				best_kind = "grim"
				best_id = gr["id"]
				best_cost = float(gr["cost"])
		if best_kind == "" or best_cost > Game.embers:
			break
		match best_kind:
			"gen": Game.buy_generator(best_id, 1)
			"ars": Game.buy_arsenal(best_id)
			"grim": Game.buy_grimoire(best_id)
	# Pactos: la IA sube el Calor poco a poco cuando supera con holgura su récord.
	Game.active_pacts.clear()
	if Game.pacts_unlocked():
		var budget := clampi(int((Game.max_floor - 10) / 8), 0, 11)
		for p in ForgeDB.PACTS:
			if Game.pact_heat(Game.active_pacts) + int(p["heat"]) <= budget:
				Game.active_pacts.append(p["id"])
	Game.heirloom_picks.clear()
	for id: String in ["gold_bellows", "whetstone", "ember_lantern", "slag_hammer", "iron_kettle"]:
		if Game.relic_codex.has(id):
			Game.heirloom_picks.append(id)


# --- Torre ------------------------------------------------------------------

func _ascend() -> int:
	var run := Game.start_run(runs * 7919 + 13)
	var floors := 0
	while run.hp > 0 and run.floor_num < 200:
		var doors := run.roll_doors(1 if Game.talents.has("star_map") else 0)
		run.floor_num += 1
		Game.reach_floor(run.floor_num)
		floors += 1
		var kind := _choose_door(run, doors)
		match kind:
			"rest":
				var pct := 30 + 10 * Game.arsenal_level("hearth")
				if run.has_pact("pact_rest"):
					pct /= 2
				if run.hp < run.max_hp * 0.75:
					run.heal(int(run.max_hp * pct / 100.0) + (10 if run.has_relic("healing_salve") else 0))
				else:
					var ups: Array = run.deck.filter(func(c: Card) -> bool: return c.can_upgrade())
					if not ups.is_empty():
						(ups[run.rng.randi_range(0, ups.size() - 1)] as Card).upgraded = true
				continue
			"treasure":
				run.add_relic(RelicDB.random_unowned(run.relics, run.rng))
				Game.gain_tower_embers(Game.production() * 30.0, "treasure")
				continue
			"event":
				Game.gain_tower_embers(Game.production() * 45.0 + 30.0 * Game.floor_factor(run.floor_num), "event")
				continue
			"shop":
				continue
		var eng := CombatEngine.new()
		eng.setup(run, EnemyDB.pick_encounter(kind, run.floor_num, run.rng), run.floor_num, kind)
		eng.start()
		var guard := 0
		while not eng.over and guard < 80:
			guard += 1
			_ai_turn(eng)
			if eng.over:
				break
			eng.end_player_turn()
			eng.begin_enemy_phase()
			for e in eng.enemies.duplicate():
				eng.enemy_act(e)
			eng.end_enemy_phase()
		if not eng.won:
			run.hp = 0
			break
		Game.gain_tower_embers(Game.victory_wave(kind), "wave")
		if kind == "boss":
			if not run.has_pact("pact_hunger"):
				run.heal(run.max_hp)
			var choices := RelicDB.choices(run.relics, run.rng, 3, "boss")
			if not choices.is_empty():
				run.add_relic(choices[0])
		elif kind == "elite":
			run.add_relic(RelicDB.random_unowned(run.relics, run.rng))
		var rewards := run.roll_card_rewards(Game.card_packs(), 3, kind != "combat")
		if run.deck.size() < 22:
			rewards.sort_custom(func(x: Card, y: Card) -> bool: return _card_score(x) > _card_score(y))
			run.deck.append(rewards[0])
	var reached := run.floor_num
	# Tiempo de la ascensión: la Forja sigue produciendo mientras tanto.
	var dur := floors * SECS_PER_FLOOR
	Game._add(Game.production() * dur, "idle")
	t += dur
	Game.end_run()
	return reached


func _choose_door(run: RunState, doors: Array[String]) -> String:
	if doors.size() == 1:
		return doors[0]
	if doors.has("rest") and run.hp < run.max_hp * 0.55:
		return "rest"
	if doors.has("treasure"):
		return "treasure"
	if doors.has("elite") and run.hp > run.max_hp * 0.8 and run.act_floor() >= 4:
		return "elite"
	if doors.has("event") and run.hp < run.max_hp * 0.7:
		return "event"
	if doors.has("combat"):
		return "combat"
	return doors[0]


func _card_score(c: Card) -> float:
	var s := {"common": 1.0, "uncommon": 2.0, "rare": 3.0}.get(c.rarity(), 0.5) as float
	if c.type() == "power":
		s += 1.0
	if c.type() == "fuel":
		s += 0.5
	if c.upgraded:
		s += 0.5
	return s


## IA: quema combustible/estados, juega poderes y luego ataques/defensas según la intención;
## con Quemas sobrantes quema la carta menos útil (como haría una persona: alimentar la Forja y la Maestría).
func _ai_turn(eng: CombatEngine) -> void:
	var progressed := true
	var actions := 0
	while progressed and not eng.over and actions < 40:
		actions += 1
		progressed = false
		var incoming := 0
		for e in eng.living_enemies():
			var d := eng.intent_damage(e)
			if d.x > 0:
				incoming += d.x * d.y
		var best: Card = null
		var best_score := -999.0
		for c in eng.hand:
			if not c.is_playable():
				if eng.can_burn(c):
					best = c
					best_score = 999.0
					break
				continue
			if not eng.can_play(c):
				continue
			var s := 1.0
			match c.type():
				"power": s = 5.0
				"attack": s = 3.0
				"skill": s = 4.0 if incoming > eng.player.block else 1.5
			if s > best_score:
				best_score = s
				best = c
		if best == null:
			break
		if not best.is_playable():
			eng.burn_card(best)
		else:
			var alive := eng.living_enemies()
			var tgt: Fighter = null
			for e in alive:
				if tgt == null or e.hp < tgt.hp:
					tgt = e
			eng.play_card(best, tgt)
		progressed = true
	# Quemas sobrantes: la carta que no se puede pagar (o la más barata) al horno.
	while not eng.over and eng.burns_left > 0:
		var victim: Card = null
		for c in eng.hand:
			if eng.can_burn(c) and (victim == null or (not eng.can_play(c) and eng.can_play(victim))):
				victim = c
		if victim == null:
			break
		eng.burn_card(victim)
