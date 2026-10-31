extends Node
## Simulación de balance: ascensiones completas con una IA voraz para distintos niveles de Arsenal.
## Ejecutar: godot --headless --path . res://tests/balance_sim.tscn

const RUNS := 40
const PROFILES := {
	"novata": {},
	"media": {"vitality": 6, "flue": 1, "temper": 5, "greed": 4},
	"veterana": {"vitality": 15, "flue": 2, "temper": 10, "arm": 1, "hands": 1, "heirloom": 1},
	"leyenda": {"vitality": 25, "flue": 3, "temper": 10, "arm": 3, "hands": 2, "core": 1, "heirloom": 2},
	"mítica": {"vitality": 30, "flue": 3, "temper": 10, "arm": 3, "hands": 2, "core": 2, "heirloom": 2, "edge": 25, "skin": 25},
}


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.grimoires = {"pyre": true, "anvil": true, "ash": true}
	for pname: String in PROFILES:
		Game.arsenal = PROFILES[pname].duplicate()
		var floors: Array[int] = []
		var embers := 0.0
		for i in RUNS:
			var r := _simulate(i * 7 + 1)
			floors.append(r["floor"])
			embers += r["embers"]
		floors.sort()
		var avg := 0.0
		for f in floors:
			avg += f
		avg /= floors.size()
		print("%-10s piso medio %5.1f  mediana %3d  máx %3d  ascuas/run %s" % [pname, avg, floors[floors.size() / 2], floors[-1], Num.fmt(embers / RUNS)])
	get_tree().quit()


func _simulate(seed_value: int) -> Dictionary:
	var run := Game.start_run(seed_value)
	var before := Game.embers
	while run.hp > 0 and run.floor_num < 120:
		var doors := run.roll_doors()
		run.floor_num += 1
		var kind: String = doors[0]
		if doors.has("rest") and run.hp < run.max_hp * 0.5:
			kind = "rest"
		elif doors.has("combat"):
			kind = "combat"
		match kind:
			"rest":
				run.heal(int(run.max_hp * 0.3))
				continue
			"shop", "event", "treasure":
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
			for e in eng.enemies:
				eng.enemy_act(e)
			eng.end_enemy_phase()
		if not eng.won:
			run.hp = 0
			break
		if kind == "boss":
			run.heal(run.max_hp)
			run.add_relic(RelicDB.random_unowned(run.relics, run.rng))
		var rewards := run.roll_card_rewards(Game.card_packs())
		run.deck.append(rewards[0])
	var floor_reached := run.floor_num
	var earned := Game.embers - before
	Game.run = null
	return {"floor": floor_reached, "embers": earned}


## IA: quema combustible y estados, juega poderes, luego ataques/defensas según intención.
func _ai_turn(eng: CombatEngine) -> void:
	var progressed := true
	while progressed and not eng.over:
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
				"skill": s = 4.0 if incoming > eng.player.block else 1.0
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
