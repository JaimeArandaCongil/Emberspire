extends Node
## ¿Es quemar una decisión o una respuesta dominante? Compara políticas de quema en ascensiones completas.

const RUNS := 60
const PROFILES := {
	"novata": {},
	"media": {"vitality": 6, "flue": 1, "temper": 5, "greed": 4},
	"veterana": {"vitality": 15, "flue": 2, "temper": 10, "arm": 1, "hands": 1},
}


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	Game.grimoires = {"pyre": true, "anvil": true, "ash": true}
	print("perfil     política   piso_medio  mediana  quemas/combate  ascuas/run  maestríaXP/run")
	for pname: String in PROFILES:
		for pol in ["never", "fuel", "leftover", "max"]:
			Game.arsenal = PROFILES[pname].duplicate()
			var floors := 0.0
			var med: Array = []
			var embers := 0.0
			var burns := 0.0
			var combats := 0.0
			var xp := 0.0
			for i in RUNS:
				Game.mastery = {}
				Game.embers = 0.0
				var bot := ReviewBot.new()
				bot.policy = pol
				var r := _simulate(i * 13 + 5, bot)
				floors += r["floor"]
				med.append(r["floor"])
				embers += Game.embers
				burns += bot.burns_done
				combats += r["combats"]
				for k in Game.mastery:
					xp += Game.mastery[k]
			med.sort()
			print("%-10s %-9s  %8.1f  %6d  %10.2f  %12s  %8.1f" % [pname, pol, floors / RUNS, med[RUNS / 2], burns / maxf(combats, 1), Num.fmt(embers / RUNS), xp / RUNS])
	get_tree().quit()


func _simulate(seed_value: int, bot: ReviewBot) -> Dictionary:
	var run := Game.start_run(seed_value)
	var combats := 0
	while run.hp > 0 and run.floor_num < 60:
		var doors := run.roll_doors()
		run.floor_num += 1
		var kind: String = doors[0]
		if doors.has("rest") and run.hp < run.max_hp * 0.55:
			kind = "rest"
		elif doors.has("elite") and run.hp > run.max_hp * 0.8 and run.act_floor() >= 4:
			kind = "elite"
		elif doors.has("combat"):
			kind = "combat"
		match kind:
			"rest":
				run.heal(int(run.max_hp * 0.3))
				continue
			"shop", "event", "treasure":
				continue
		combats += 1
		var eng := bot.fight(run, EnemyDB.pick_encounter(kind, run.floor_num, run.rng), run.floor_num, kind)
		if not eng.won:
			run.hp = 0
			break
		if kind == "boss":
			run.heal(run.max_hp)
			run.add_relic(RelicDB.random_unowned(run.relics, run.rng))
		elif kind == "elite":
			run.add_relic(RelicDB.random_unowned(run.relics, run.rng))
		var rewards := run.roll_card_rewards(Game.card_packs(), 3, kind != "combat")
		rewards.sort_custom(func(x: Card, y: Card) -> bool: return ReviewBot.card_value(x) > ReviewBot.card_value(y))
		if run.deck.size() < 22:
			run.deck.append(rewards[0])
	var f := run.floor_num
	Game.run = null
	return {"floor": f, "combats": combats}
