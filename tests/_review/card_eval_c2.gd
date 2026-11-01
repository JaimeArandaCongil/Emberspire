extends Node
## Valor de cada carta: mazo inicial + 2 copias de X contra un guantelete fijo (élites y jefes de los actos 1 y 2).
## Métrica: % victorias y PV medios restantes. Comparado con el mazo inicial sin añadidos (baseline).

const SEEDS := 24
var results: Array = []


func _ready() -> void:
	Game.autosave_enabled = false
	Game.reset_all()
	for g in ["pyre", "anvil", "ash", "solar", "forge", "crucible"]:
		Game.grimoires[g] = true
	# Estado de Forja "a mitad de partida" para las cartas del Grimorio de la Forja.
	Game.max_floor = 60
	Game.stardust_total = 140
	Game.generators = {"spark": 60, "bellows": 50, "furnace": 40, "crucible": 20}
	for i in 15:
		Game.relic_codex[RelicDB.RELICS.keys()[i]] = true
	Game.arsenal = {"vitality": 30, "edge": 25, "skin": 25, "arm": 3, "flue": 2, "core": 1}
	var base := _eval("")
	print("baseline (sin carta): win %.0f%%  pv %.1f" % [base.x * 100, base.y])
	var ids := CardDB.ids_in_packs(["base", "pyre", "anvil", "ash", "solar", "forge", "crucible"])
	for id in ids:
		var r := _eval(id)
		results.append([id, r.x - base.x, r.y - base.y, CardDB.get_def(id)["rarity"], CardDB.get_def(id)["pack"]])
	results.sort_custom(func(a, b): return a[1] * 100 + a[2] * 0.5 > b[1] * 100 + b[2] * 0.5)
	print("carta                pack      rareza     Δwin%   ΔPV")
	for r in results:
		print("%-20s %-9s %-10s %+6.1f  %+6.1f" % [r[0], r[4], r[3], r[1] * 100, r[2]])
	get_tree().quit()


func _eval(extra: String) -> Vector2:
	var wins := 0.0
	var hp := 0.0
	var n := 0.0
	var gauntlet := [["hollow_knight"], ["smoke_witch"], ["bellows_brute"], ["coalfather"], ["great_bellows"],
		["slag_crawler", "brimstone_imp"], ["molten_eye", "molten_eye"], ["ash_priest", "molten_eye", "brimstone_imp"]]
	var floors := [37, 37, 37, 40, 40, 43, 43, 43]
	for s in SEEDS:
		for gi in gauntlet.size():
			Game.mastery = {}
			var run := Game.start_run(s * 31 + gi)
			Game.run = null  # sin Reliquario
			if extra != "":
				run.deck.append(Card.new(extra))
				run.deck.append(Card.new(extra))
			var bot := ReviewBot.new()
			bot.policy = "leftover"
			var eng := bot.fight(run, gauntlet[gi], floors[gi], "elite")
			n += 1
			if eng.won:
				wins += 1
				hp += eng.player.hp
	return Vector2(wins / n, hp / n)
