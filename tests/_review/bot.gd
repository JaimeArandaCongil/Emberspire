class_name ReviewBot
extends RefCounted
## Bot de revisión: juega combates con distintas políticas de quema.
## policy: "never" (nunca quema), "fuel" (sólo Combustible/Estado), "leftover" (fuel + sobrantes al final),
##         "max" (quema todo lo que pueda, empezando por lo peor, antes de jugar)

var policy := "leftover"
var burns_done := 0
var turns := 0


static func card_value(c: Card) -> float:
	# Valor aproximado de conservar la carta en mano este turno.
	match c.type():
		"status": return -5.0
		"fuel": return 0.5
		"power": return 6.0
	var v := {"starter": 1.0, "common": 2.0, "uncommon": 3.0, "rare": 4.0}.get(c.rarity(), 1.0) as float
	if c.is_up():
		v += 0.5
	return v


func play_turn(eng: CombatEngine) -> void:
	turns += 1
	if policy == "max":
		_burn_worst(eng, 99)
	var actions := 0
	var progressed := true
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
				if policy != "never" and eng.can_burn(c) and c.type() in ["fuel", "status"]:
					best = c
					best_score = 999.0
					break
				continue
			if not eng.can_play(c):
				continue
			var s := 1.0
			match c.type():
				"power": s = 5.0
				"attack": s = 3.0 + 0.1 * card_value(c)
				"skill": s = (4.0 if incoming > eng.player.block else 1.5) + 0.1 * card_value(c)
			if s > best_score:
				best_score = s
				best = c
		if best == null:
			break
		if not best.is_playable():
			eng.burn_card(best)
			burns_done += 1
		else:
			var alive := eng.living_enemies()
			var tgt: Fighter = null
			for e in alive:
				if tgt == null or e.hp < tgt.hp:
					tgt = e
			eng.play_card(best, tgt)
		progressed = true
	if policy in ["leftover", "max"]:
		_burn_worst(eng, 99)


func _burn_worst(eng: CombatEngine, n: int) -> void:
	for i in n:
		if eng.over or eng.burns_left <= 0:
			return
		var victim: Card = null
		for c in eng.hand:
			if not eng.can_burn(c):
				continue
			if victim == null or card_value(c) < card_value(victim):
				victim = c
		if victim == null:
			return
		eng.burn_card(victim)
		burns_done += 1


func fight(run: RunState, ids: Array, floor_num: int, kind: String) -> CombatEngine:
	var eng := CombatEngine.new()
	eng.setup(run, ids, floor_num, kind)
	eng.start()
	var guard := 0
	while not eng.over and guard < 60:
		guard += 1
		play_turn(eng)
		if eng.over:
			break
		eng.end_player_turn()
		eng.begin_enemy_phase()
		for e in eng.enemies.duplicate():
			eng.enemy_act(e)
		eng.end_enemy_phase()
	return eng
