class_name CombatEngine
extends RefCounted
## Reglas del combate. Sin nodos: emite `event(kind, data)` y la UI lo representa.
## Eventos: turn_start, draw, discard, exhaust, card_played, card_burned, damage, block, status, power, heal,
##          energy, burns, intent, enemy_died, victory, defeat, revive, shuffle, card_added, summon, steal,
##          refund, mastery, upgraded, embers_gain, thorns

signal event(kind: String, data: Dictionary)

const HAND_MAX := 10
const MAX_ENEMIES := 5

var run: RunState
var player: Fighter
var enemies: Array[Fighter] = []
var draw_pile: Array[Card] = []
var hand: Array[Card] = []
var discard: Array[Card] = []
var exhaust_pile: Array[Card] = []
## Cartas quemadas este combate (más reciente al final). Su número es el "Calor".
var burned_cards: Array[Card] = []
var energy := 0
var energy_next := 0
var burns_left := 0
var burned_count := 0
var burns_this_turn := 0
var attacks_played := 0
var turn := 0
var floor_num := 1
var kind := "combat"
var over := false
var won := false
var rng := RandomNumberGenerator.new()
## Si es false, nada toca el autoload Game (tests headless puros): ni Ascuas ni Maestría ni estadísticas.
var bank_embers := true
var embers_this_combat := 0.0
var _play_mult := 1.0
var _first_attack_done := false
## Quema en caliente: pagas el coste de la carta y la quema vale ×2 (Ascuas y Maestría).
var hot_burns := 0
var _free_hot := 0
var _hot_this_turn := 0
var _attacks_this_turn := 0
var _power_energy_used := false
var _energy_once_used := false
var _fuel_burned_this_turn := 0
var _below_half_done := false


func setup(p_run: RunState, enemy_ids: Array, p_floor: int, p_kind: String) -> void:
	run = p_run
	floor_num = p_floor
	kind = p_kind
	rng.seed = run.rng.randi()
	player = Fighter.new()
	player.is_player = true
	player.display_name = "La Fogonera"
	player.max_hp = run.max_hp
	player.hp = run.hp
	for id: String in enemy_ids:
		enemies.append(_make_enemy(id))
	for c in run.deck:
		c.temp_up = false
		draw_pile.append(c)
	_tutorial_order = run.tutorial and run.floor_num <= 1
	if run.has_relic("cracked_core"):
		for i in 3:
			draw_pile.append(Card.new("sodden_ash"))
	_shuffle(draw_pile)
	# Innatas arriba del mazo (se roba desde el final).
	var innate: Array[Card] = []
	for c in draw_pile:
		if c.has_kw("innate"):
			innate.append(c)
	for c in innate:
		draw_pile.erase(c)
		draw_pile.append(c)
	# Primera ascensión: la mano inicial enseña a quemar (Leña arriba del mazo).
	if _tutorial_order:
		for c in draw_pile.duplicate():
			if c.id == "kindling":
				draw_pile.erase(c)
				draw_pile.append(c)
				break


var _tutorial_order := false


func _make_enemy(id: String) -> Fighter:
	var e := EnemyDB.make(id, floor_num, rng)
	var hp_mult := 1.0
	if run.has_pact("pact_hp"):
		hp_mult *= 1.25
	if e.is_boss and run.has_pact("pact_boss"):
		hp_mult *= 1.5
	if hp_mult != 1.0:
		e.max_hp = int(round(e.max_hp * hp_mult))
		e.hp = e.max_hp
	if run.has_pact("pact_dmg"):
		e.dmg_mult *= 1.2
	return e


func start() -> void:
	var s := run.start_str
	if run.has_relic("ember_ring"):
		s += 1
	if run.has_relic("res_furnace3"):
		s += 1
	if run.has_relic("res_heart1"):
		s += 2
	if s > 0:
		player.add_status("str", s)
	for e in enemies:
		if e.affixes.has("stifling"):
			player.add_status("choke", 1)
	for e in enemies:
		_on_enemy_enter(e)
		if run.has_relic("res_heart3"):
			e.hp = maxi(1, e.hp - int(e.max_hp * 0.1))
	for e in enemies:
		_choose_intent(e)
	start_player_turn()
	if run.has_relic("bone_tinder"):
		_add_to_hand(Card.new("spark_card"))
	if run.has_relic("res_spark1b"):
		_add_to_hand(Card.new("spark_card"))
	if run.has_relic("tongs"):
		_upgrade_random(1)


func _on_enemy_enter(e: Fighter) -> void:
	if run.has_relic("salamander_scale"):
		e.add_status("scorch", 3)
	if run.has_relic("pyre_mask"):
		e.add_status("vuln", 1)
	if run.has_relic("frost_pendant"):
		e.add_status("weak", 1)
	if (e.is_elite or e.is_boss) and run.has_pact("pact_elite"):
		e.add_status("str", 3)


func living_enemies() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for e in enemies:
		if e.alive():
			out.append(e)
	return out


func heat() -> int:
	return burned_count


# --- Turno del jugador ----------------------------------------------------

func start_player_turn() -> void:
	if over:
		return
	var leftover := burns_left
	turn += 1
	burns_this_turn = 0
	_hot_this_turn = 0
	_free_hot = 0
	_attacks_this_turn = 0
	_power_energy_used = false
	_energy_once_used = false
	_fuel_burned_this_turn = 0
	player.block = 0
	if turn == 1:
		if run.has_relic("warm_stone"):
			_gain_block(player, 6)
		if run.has_relic("res_bellows1"):
			_gain_block(player, 5)
		if run.has_relic("iron_kettle"):
			_gain_block(player, int(run.max_hp / 10))
	if run.has_relic("res_bellows3"):
		_gain_block(player, 2)
	_tick_scorch(player)
	if over:
		return
	energy = run.max_energy + player.pw("solar") + energy_next
	energy_next = 0
	if turn == 2 and run.has_relic("res_sun1b"):
		energy += 2
	if turn == 1 and run.has_relic("res_bellows1b"):
		energy += 1
	if turn % 2 == 0 and run.has_relic("res_heart1b"):
		_apply_status(player, "str", 1)
	if run.has_relic("res_heart2"):
		energy += 1
	if run.has_relic("blood_coal") and player.hp * 2 <= player.max_hp:
		energy += 1
	var burns := run.burns_per_turn + player.pw("bellows_pw")
	if run.has_relic("leather_bellows"):
		burns += 1
	if run.has_relic("res_sun3"):
		burns += 1
	if turn == 1:
		if run.has_relic("eternal_candle"):
			energy += 1
		if run.has_relic("res_sun1"):
			energy += 1
		if run.has_relic("res_spark2"):
			burns += 1
		if bank_embers and Game.talents.has("twin_embers"):
			burns += 1
		if run.has_pact("pact_burn"):
			burns -= 1
	elif run.has_relic("kiln_key"):
		burns += mini(leftover, 3)
	elif run.has_relic("res_spark2b"):
		burns += mini(leftover, 1)
	if run.combat_mods.has("burn"):
		burns += 1
	burns -= player.st("choke")
	if player.st("choke") > 0:
		player.statuses.erase("choke")
		event.emit("status", {"target": player, "id": "", "amount": 0})
	burns_left = maxi(0, burns)
	if player.pw("forge_block") > 0:
		_gain_block(player, player.pw("forge_block"))
	if player.pw("temper") > 0:
		_apply_status(player, "str", player.pw("temper"))
	if player.pw("smolder") > 0:
		for e in living_enemies():
			_apply_status(e, "scorch", player.pw("smolder") + player.pw("salamander"))
	if player.pw("corona") > 0:
		for e in living_enemies():
			_hit(null, e, player.pw("corona"))
		if over:
			return
	var n := run.draw_per_turn
	if run.has_relic("res_sun3b"):
		n += 1
	if turn == 1:
		if run.has_relic("ash_eye"):
			n += 2
		if run.has_relic("res_bellows2"):
			n += 1
		if run.has_relic("res_bellows1b"):
			n -= 1
	draw_cards(n)
	if player.pw("philo") > 0:
		_upgrade_random(player.pw("philo"))
	event.emit("turn_start", {"turn": turn})
	event.emit("energy", {"value": energy})
	event.emit("burns", {"value": burns_left})


func draw_cards(n: int) -> void:
	for i in n:
		if hand.size() >= HAND_MAX:
			return
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile = discard.duplicate()
			discard.clear()
			_shuffle(draw_pile)
			event.emit("shuffle", {})
			if run.has_relic("res_bellows3b"):
				energy += 1
				event.emit("energy", {"value": energy})
		var c: Card = draw_pile.pop_back()
		hand.append(c)
		event.emit("draw", {"card": c})


func _add_to_hand(c: Card) -> void:
	if hand.size() >= HAND_MAX:
		discard.append(c)
		event.emit("card_added", {"card": c, "source": player})
		return
	hand.append(c)
	event.emit("draw", {"card": c, "created": true})


func can_play(card: Card) -> bool:
	if over or not hand.has(card) or not card.is_playable():
		return false
	if card.is_x_cost():
		return true
	return energy >= card.cost()


func _burn_is_free(card: Card) -> bool:
	return card.type() == "status" and run.has_relic("soot_jar")


func can_burn(card: Card) -> bool:
	if over or not hand.has(card) or not card.is_burnable():
		return false
	return burns_left > 0 or _burn_is_free(card) or _kiln_free(card)


func _kiln_free(card: Card) -> bool:
	return card.type() == "fuel" and _fuel_burned_this_turn == 0 and bank_embers and Game.constellations.has("c_kiln")


## La primera quema en caliente del turno es gratis (Latido Ígneo, Pira Eterna) o la siguiente (Fundir).
func _hot_is_free() -> bool:
	if _free_hot > 0:
		return true
	if _hot_this_turn == 0 and (run.has_relic("res_heart2b") or (bank_embers and Game.constellations.has("c_pyre"))):
		return true
	return false


## Energía que costaría quemar en caliente (-1 si no se puede).
func hot_burn_cost(card: Card) -> int:
	var c := card.hot_cost(energy)
	if c < 0:
		return -1
	return 0 if _hot_is_free() else c


func can_burn_hot(card: Card) -> bool:
	if not can_burn(card):
		return false
	var c := hot_burn_cost(card)
	return c >= 0 and energy >= c


func play_card(card: Card, target: Fighter = null) -> bool:
	if not can_play(card):
		return false
	if card.needs_target():
		if target == null or not target.alive():
			var alive := living_enemies()
			if alive.is_empty():
				return false
			target = alive[0]
	var x := 0
	if card.is_x_cost():
		x = energy
		energy = 0
	else:
		energy -= card.cost()
	hand.erase(card)
	var is_attack := card.type() == "attack"
	if is_attack and not _first_attack_done:
		_first_attack_done = true
		if run.has_relic("slag_hammer"):
			_play_mult = 2.0
	if is_attack:
		if _attacks_this_turn == 0 and run.has_relic("res_blast3b"):
			_play_mult *= 1.5
		_attacks_this_turn += 1
	if bank_embers:
		var lvl := Game.add_mastery(card.id, 0.25)
		if lvl > 0:
			run.mastery_ups += 1
			event.emit("mastery", {"card": card, "level": lvl})
	event.emit("energy", {"value": energy})
	event.emit("card_played", {"card": card, "target": target})
	_run_ops(card.effects(), target, x, card)
	_play_mult = 1.0
	if is_attack and not over:
		attacks_played += 1
		if player.pw("rhythm") > 0:
			_gain_block(player, player.pw("rhythm"))
		if player.pw("flame_brand") > 0:
			var tgts: Array[Fighter] = []
			if target != null:
				tgts.append(target)
			else:
				tgts = living_enemies()
			for e in tgts:
				_apply_status(e, "scorch", player.pw("flame_brand") + player.pw("salamander"))
		if run.has_relic("war_drum") and attacks_played % 4 == 0:
			_apply_status(player, "str", 1)
	if card.type() == "power":
		if run.has_relic("anvil_charm"):
			_gain_block(player, 6)
		if run.has_relic("res_sun2b") and not _power_energy_used:
			_power_energy_used = true
			energy += 1
			event.emit("energy", {"value": energy})
	elif card.exhausts():
		exhaust_pile.append(card)
		event.emit("exhaust", {"card": card})
	else:
		discard.append(card)
	_check_end()
	return true


func burn_card(card: Card, hot: bool = false) -> bool:
	if not can_burn(card):
		return false
	if hot:
		if not can_burn_hot(card):
			return false
		var c := hot_burn_cost(card)
		if c > 0:
			energy -= c
		elif _free_hot > 0:
			_free_hot -= 1
		_hot_this_turn += 1
		hot_burns += 1
		event.emit("energy", {"value": energy})
	_burn(card, false, hot)
	_check_end()
	return true


## Lo que daría una quema (para la vista previa de la UI).
func burn_preview(card: Card, hot: bool) -> Dictionary:
	var mult := 1
	for op: Array in card.burn_effects():
		if op[0] == "ember_mult":
			mult = op[1]
	var v := Game.burn_value(card.cost(), mult, floor_num, card.mastery()) * (1.5 if run.has_relic("gold_bellows") else 1.0)
	var gl := Game.arsenal_level("greed")
	v *= (1.0 + 0.10 * mini(gl, 10) + 0.05 * maxi(0, gl - 10)) * run.ember_mult * (1.0 + Game.heat_bonus_each() * run.heat())
	return {"embers": v * (2.0 if hot else 1.0), "xp": _mastery_xp() * (2.0 if hot else 1.0)}


func _mastery_xp() -> float:
	var xp := 1.0 + (1.0 if bank_embers and Game.talents.has("ember_memory") else 0.0)
	if run.has_relic("smiths_journal"):
		xp *= 2.0
	return xp


## Núcleo de QUEMAR. `free`: no gasta Quemas (Fundir, Tarro de Hollín).
func _burn(card: Card, free: bool, hot: bool = false) -> void:
	hand.erase(card)
	var kiln := _kiln_free(card)
	if not free and not _burn_is_free(card) and not kiln:
		burns_left -= 1
	if card.type() == "fuel":
		_fuel_burned_this_turn += 1
	burned_count += 1
	burns_this_turn += 1
	run.burned += 1
	# Rescoldo (Temple de Combustible): vuelve al descarte.
	if card.has_temple("rekindle"):
		discard.append(card)
	else:
		exhaust_pile.append(card)
	burned_cards.append(card)
	var mult := 1
	for op: Array in card.burn_effects():
		if op[0] == "ember_mult":
			mult = op[1]
	var value := Game.burn_value(card.cost(), mult, floor_num, card.mastery())
	if run.has_relic("gold_bellows"):
		value *= 1.5
	if hot:
		value *= 2.0
	if run.combat_mods.has("embers"):
		value *= 1.5
	if bank_embers:
		value = Game.gain_tower_embers(value, "burn")
		Game.add_stat("burns", 1)
		if hot:
			Game.add_stat("hot_burns", 1)
		var lvl := Game.add_mastery(card.id, _mastery_xp() * (2.0 if hot else 1.0))
		if lvl > 0:
			run.mastery_ups += 1
			event.emit("mastery", {"card": card, "level": lvl})
	embers_this_combat += value
	event.emit("card_burned", {"card": card, "embers": value, "hot": hot})
	event.emit("burns", {"value": burns_left})
	var alive := living_enemies()
	var tgt: Fighter = alive[rng.randi_range(0, alive.size() - 1)] if not alive.is_empty() else null
	_run_ops(card.burn_effects(), tgt, 0, card)
	if over:
		return
	if player.pw("inner_fire") > 0:
		for e in living_enemies():
			_hit(null, e, player.pw("inner_fire"))
	if player.pw("ash_armor") > 0:
		_gain_block(player, player.pw("ash_armor"))
	if run.has_relic("iron_lung"):
		_gain_block(player, 3)
	if run.has_relic("res_blast2"):
		for e in living_enemies():
			_apply_status(e, "scorch", 2 + player.pw("salamander"))
	if run.has_relic("res_spark3") and card.type() == "fuel":
		var al := living_enemies()
		if not al.is_empty():
			_hit(null, al[rng.randi_range(0, al.size() - 1)], 4)
	if run.has_relic("res_spark3b") and card.type() == "attack":
		var weakest: Fighter = null
		for e in living_enemies():
			if weakest == null or e.hp < weakest.hp:
				weakest = e
		_hit(null, weakest, 6)
	# Enemigos que reaccionan a la quema (Polilla de Llama, Devorador, afijos Carroñero y Avaro).
	for e in living_enemies():
		for op: Array in e.on_burn:
			_enemy_op(e, op)
		if e.affixes.has("scavenger"):
			_heal(e, maxi(1, int(e.max_hp * 0.03)))
		if e.affixes.has("greedy"):
			_enemy_op(e, ["steal", 2])
	if over:
		return
	if burned_count % 3 == 0:
		var e_gain := (1 if run.has_relic("cinder_heart") else 0) + (1 if run.has_relic("res_sun2") else 0)
		if e_gain > 0:
			energy += e_gain
			event.emit("energy", {"value": energy})
	var draws := player.pw("kiln")
	if burns_this_turn == 1 and run.has_relic("charred_tome"):
		draws += 1
	if burned_count == 1 and run.has_relic("res_spark1"):
		draws += 1
	if draws > 0:
		draw_cards(draws)


func end_player_turn() -> void:
	if over:
		return
	if player.pw("slag_skin") > 0:
		_gain_block(player, player.pw("slag_skin"))
	if player.block <= 0 and run.has_relic("molten_shield"):
		_gain_block(player, 5)
	if run.has_relic("res_bellows2b") and energy > 0:
		_gain_block(player, 4 * energy)
	if burns_this_turn == 0:
		for e in living_enemies():
			for op: Array in e.on_no_burn:
				_enemy_op(e, op)
	for c in hand.duplicate():
		if c.has_kw("retain"):
			continue
		hand.erase(c)
		if c.has_kw("ethereal"):
			exhaust_pile.append(c)
			event.emit("exhaust", {"card": c})
		else:
			discard.append(c)
			event.emit("discard", {"card": c})
	_decay(player)


# --- Turno enemigo (la UI lo secuencia con pausas) ------------------------

func begin_enemy_phase() -> void:
	for e in living_enemies():
		e.block = 0
		_tick_scorch(e)
		if e.alive() and e.st("regen") > 0:
			_heal(e, e.st("regen"))
	_check_end()


func enemy_act(e: Fighter) -> void:
	if over or not e.alive():
		return
	for op: Array in e.intent.get("ops", []):
		if over or not e.alive():
			break
		_enemy_op(e, op)
	if e.alive() and e.affixes.has("sticky") and turn % 2 == 0:
		_enemy_op(e, ["add_card", "wet_ash", 1])
	if e.alive():
		_choose_intent(e)


func end_enemy_phase() -> void:
	for e in living_enemies():
		_decay(e)
	if not over:
		start_player_turn()


func _choose_intent(e: Fighter) -> void:
	var idx := 0
	if e.pattern == "random" and e.moves.size() > 1:
		idx = rng.randi_range(0, e.moves.size() - 1)
		if idx == e.last_move:
			idx = (idx + 1) % e.moves.size()
	else:
		idx = e.move_idx % e.moves.size()
		e.move_idx += 1
	e.last_move = idx
	var ops: Array = e.moves[idx]
	e.intent = {"ops": ops, "kind": _intent_kind(ops)}
	event.emit("intent", {"fighter": e})


static func _intent_kind(ops: Array) -> String:
	var has_atk := false
	var has_def := false
	var has_buff := false
	var has_debuff := false
	var has_steal := false
	var has_summon := false
	for op: Array in ops:
		match op[0]:
			"atk": has_atk = true
			"block", "block_all", "thorns": has_def = true
			"str", "str_all", "heal", "heal_all", "regen": has_buff = true
			"steal", "flee": has_steal = true
			"summon": has_summon = true
			_: has_debuff = true
	if has_steal:
		return "steal"
	if has_summon:
		return "summon"
	if has_atk and has_debuff:
		return "attack_debuff"
	if has_atk and has_def:
		return "attack_defend"
	if has_atk:
		return "attack"
	if has_debuff:
		return "debuff"
	if has_def:
		return "defend"
	return "buff"


## Daño por golpe y nº de golpes de la intención, para la UI.
func intent_damage(e: Fighter) -> Vector2i:
	for op: Array in e.intent.get("ops", []):
		if op[0] == "atk":
			var base := int(round(float(op[1]) * e.dmg_mult))
			return Vector2i(calc_damage(e, player, base), int(op[2]))
	return Vector2i(-1, 0)


## Ascuas que robaría una Urraca con `secs` segundos de producción.
func steal_amount(secs: float) -> float:
	return secs * (Game.production() + 2.0 * Game.floor_factor(floor_num))


func _enemy_op(e: Fighter, op: Array) -> void:
	match op[0]:
		"atk":
			var base := int(round(float(op[1]) * e.dmg_mult))
			for i in int(op[2]):
				if not player.alive() or not e.alive():
					break
				_hit(e, player, base)
		"block":
			_gain_block(e, int(round(float(op[1]) * e.dmg_mult)))
		"block_all":
			for o in living_enemies():
				_gain_block(o, int(round(float(op[1]) * e.dmg_mult)))
		"str":
			_apply_status(e, "str", op[1])
		"str_all":
			for o in living_enemies():
				_apply_status(o, "str", op[1])
		"heal":
			_heal(e, int(round(float(op[1]) * e.dmg_mult)))
		"heal_all":
			for o in living_enemies():
				_heal(o, int(round(float(op[1]) * e.dmg_mult)))
		"thorns":
			_apply_status(e, "thorns", op[1])
		"regen":
			_apply_status(e, "regen", op[1])
		"scorch_p":
			_apply_status(player, "scorch", op[1])
		"weak_p":
			_apply_status(player, "weak", op[1])
		"vuln_p":
			_apply_status(player, "vuln", op[1])
		"choke":
			_apply_status(player, "choke", op[1])
		"add_card":
			for i in int(op[2]):
				var c := Card.new(op[1])
				discard.append(c)
				event.emit("card_added", {"card": c, "source": e})
		"steal":
			var amount := steal_amount(float(op[1]))
			if bank_embers:
				amount = Game.steal(amount)
			e.stolen += amount
			event.emit("steal", {"source": e, "amount": amount})
		"flee":
			if e.stolen > 0.0:
				e.hp = 0
				e.statuses.clear()
				event.emit("fled", {"target": e, "amount": e.stolen})
				_check_end()
		"summon":
			for i in int(op[2]):
				if living_enemies().size() >= MAX_ENEMIES:
					break
				var m := _make_enemy(op[1])
				enemies.append(m)
				_on_enemy_enter(m)
				_choose_intent(m)
				event.emit("summon", {"fighter": m, "source": e})


# --- Operaciones de cartas ------------------------------------------------

func _run_ops(ops: Array, target: Fighter, x: int, card: Card) -> void:
	var is_attack := card != null and card.type() == "attack"
	for op: Array in ops:
		if over:
			return
		var k: String = op[0]
		match k:
			"dmg":
				_hit(player, target, _atk_base(op[1], is_attack, card))
			"dmg_x":
				for i in int(op[2]):
					if target == null or not target.alive():
						break
					_hit(player, target, _atk_base(op[1], is_attack, card, true))
			"dmg_all":
				for e in living_enemies():
					_hit(player, e, _atk_base(op[1], is_attack))
			"dmg_rand":
				for i in int(op[2]):
					var alive := living_enemies()
					if alive.is_empty():
						break
					_hit(player, alive[rng.randi_range(0, alive.size() - 1)], _atk_base(op[1], is_attack, card, int(op[2]) > 1))
			"dmg_xcost":
				for i in x:
					if target == null or not target.alive():
						break
					_hit(player, target, _atk_base(op[1], is_attack, card, true))
			"dmg_per_burned":
				_hit(player, target, _atk_base(int(op[1]) + int(op[2]) * burned_count, is_attack))
			"dmg_all_per_burned":
				for e in living_enemies():
					_hit(player, e, _atk_base(int(op[1]) + int(op[2]) * burned_count, is_attack))
			"dmg_strmult":
				_hit(player, target, _atk_base(int(op[1]) + player.st("str") * (int(op[2]) - 1), is_attack))
			"dmg_hand":
				_hit(player, target, _atk_base(int(op[1]) * hand.size(), is_attack))
			"dmg_braziers", "dmg_dust", "dmg_prod":
				_hit(player, target, _atk_base(CardDB.dyn_value(op), is_attack))
			"block_dmg":
				_hit(player, target, _atk_base(player.block, is_attack))
			"detonate":
				if target != null and target.alive():
					var det := target.st("scorch") * int(op[1])
					if target.affixes.has("fireproof"):
						det = int(det / 2)
					_hit(null, target, det)
			"block":
				_gain_block(player, op[1])
			"block_per_burned":
				_gain_block(player, int(op[1]) * burned_count)
			"block_scorch":
				var total := int(op[1])
				for e in living_enemies():
					total += e.st("scorch")
				_gain_block(player, total)
			"block_gens", "block_codex":
				_gain_block(player, CardDB.dyn_value(op))
			"double_block":
				_gain_block(player, player.block)
			"draw":
				draw_cards(op[1])
			"draw_type":
				_draw_type(op[1], int(op[2]))
			"energy":
				energy += int(op[1])
				event.emit("energy", {"value": energy})
			"energy_next":
				energy_next += int(op[1])
			"burn_charge":
				burns_left += int(op[1])
				event.emit("burns", {"value": burns_left})
			"free_burn":
				for i in int(op[1]):
					var pool: Array[Card] = []
					for c in hand:
						if c.is_burnable():
							pool.append(c)
					if pool.is_empty():
						break
					_burn(pool[rng.randi_range(0, pool.size() - 1)], true)
					if over:
						return
			"recall":
				_recall(int(op[1]))
			"free_hot":
				_free_hot += int(op[1])
			"dmg_rand_hot":
				var al2 := living_enemies()
				if not al2.is_empty():
					_hit(player, al2[rng.randi_range(0, al2.size() - 1)], _atk_base(int(op[1]), true))
			"energy_once":
				if not _energy_once_used:
					_energy_once_used = true
					energy += int(op[1])
					event.emit("energy", {"value": energy})
			"add_hand":
				for i in int(op[2]):
					_add_to_hand(Card.new(op[1]))
			"upgrade_rand":
				_upgrade_random(int(op[1]))
			"upgrade_hand":
				for c in hand:
					_temp_upgrade(c)
			"transmute":
				_transmute(int(op[1]))
			"scorch":
				if target != null:
					_apply_status(target, "scorch", int(op[1]) + player.pw("salamander"))
			"scorch_all":
				for e in living_enemies():
					_apply_status(e, "scorch", int(op[1]) + player.pw("salamander"))
			"scorch_double":
				if target != null and target.st("scorch") > 0:
					_apply_status(target, "scorch", target.st("scorch"))
			"vuln":
				if target != null:
					_apply_status(target, "vuln", op[1])
			"vuln_all":
				for e in living_enemies():
					_apply_status(e, "vuln", op[1])
			"weak":
				if target != null:
					_apply_status(target, "weak", op[1])
			"weak_all":
				for e in living_enemies():
					_apply_status(e, "weak", op[1])
			"str":
				_apply_status(player, "str", op[1])
			"str_mastery":
				if bank_embers:
					_apply_status(player, "str", CardDB.str_mastery_value(op))
			"heal":
				_heal(player, op[1])
			"heal_braziers":
				_heal(player, CardDB.dyn_value(op))
			"heal_per_burned":
				_heal(player, int(op[1]) * burned_count)
			"lose_hp":
				_damage(player, int(op[1]), false)
			"embers_secs":
				var v := float(op[1]) * (Game.production() + 3.0 * Game.floor_factor(floor_num))
				if bank_embers:
					v = Game.gain_tower_embers(v, "card")
				embers_this_combat += v
				event.emit("embers_gain", {"amount": v})
			"power":
				player.powers[op[1]] = player.pw(op[1]) + int(op[2])
				event.emit("power", {"id": op[1], "value": player.pw(op[1])})
			"ember_mult":
				pass  # Se resuelve al calcular el valor de quema.


func _draw_type(t: String, n: int) -> void:
	var found := 0
	for pile: Array[Card] in [draw_pile, discard]:
		for c in pile.duplicate():
			if found >= n or hand.size() >= HAND_MAX:
				return
			if c.type() == t:
				pile.erase(c)
				hand.append(c)
				found += 1
				event.emit("draw", {"card": c})


func _recall(n: int) -> void:
	for i in n:
		if hand.size() >= HAND_MAX:
			return
		var pick: Card = null
		for j in range(burned_cards.size() - 1, -1, -1):
			var c := burned_cards[j]
			if exhaust_pile.has(c) and c.type() != "status":
				pick = c
				break
		if pick == null:
			return
		exhaust_pile.erase(pick)
		burned_cards.erase(pick)
		hand.append(pick)
		event.emit("draw", {"card": pick, "recalled": true})


func _temp_upgrade(c: Card) -> bool:
	if c.is_up() or not c.can_upgrade():
		return false
	c.temp_up = true
	event.emit("upgraded", {"card": c})
	return true


func _upgrade_random(n: int) -> void:
	var pool: Array[Card] = []
	for c in hand:
		if not c.is_up() and c.can_upgrade():
			pool.append(c)
	for i in mini(n, pool.size()):
		var idx := rng.randi_range(0, pool.size() - 1)
		_temp_upgrade(pool[idx])
		pool.remove_at(idx)


func _transmute(n: int) -> void:
	var packs: Array = Game.card_packs() if bank_embers else ["base"]
	var ids := CardDB.ids_in_packs(packs)
	for i in n:
		var pool: Array[Card] = []
		for c in hand:
			if c.type() != "status":
				pool.append(c)
		if pool.is_empty() or ids.is_empty():
			return
		var old: Card = pool[rng.randi_range(0, pool.size() - 1)]
		hand.erase(old)
		event.emit("exhaust", {"card": old})
		var nc := Card.new(ids[rng.randi_range(0, ids.size() - 1)], true)
		hand.append(nc)
		event.emit("draw", {"card": nc, "created": true})


func _atk_base(base: int, is_attack: bool, card: Card = null, multi: bool = false) -> int:
	if not is_attack:
		return base
	var b := base
	if multi and run.has_relic("res_blast2b"):
		b += 1
	if card != null and card.cost() >= 2 and run.has_relic("res_blast1b"):
		b += 3
	if run.has_relic("whetstone"):
		b += 2
	if run.has_relic("res_blast1"):
		b += 1
	if run.has_relic("res_blast3"):
		b += 2
	if run.has_relic("brazier_shard") and bank_embers:
		b += int(Game.max_floor / 20)
	return b


## Daño que mostraría una carta del jugador contra el primer enemigo vivo.
func preview_damage(base: int) -> int:
	var alive := living_enemies()
	return calc_damage(player, alive[0] if not alive.is_empty() else null, base)


func calc_damage(src: Fighter, dst: Fighter, base: int) -> int:
	var d := float(base)
	if src != null:
		d += src.st("str")
		if src.is_player:
			d *= run.dmg_mult * _play_mult
		if src.st("weak") > 0:
			d *= 0.75
	if dst != null and dst.st("vuln") > 0:
		d *= 1.5
	return maxi(0, int(floor(d)))


func _hit(src: Fighter, dst: Fighter, base: int) -> void:
	if dst == null or not dst.alive():
		return
	var amount := calc_damage(src, dst, base)
	if src == null and not dst.is_player:
		amount = int(floor(amount * run.dmg_mult))
	_damage(dst, amount, true, src)
	if src == null or not src.alive() or over:
		return
	# Espinas: quien golpea se pincha.
	var thorns := 0
	if dst.is_player:
		thorns = player.pw("thorns") + (3 if run.has_relic("thorn_ring") else 0)
	else:
		thorns = dst.st("thorns")
	if thorns > 0:
		event.emit("thorns", {"target": src, "source": dst})
		_damage(src, thorns, true, null)


func _damage(dst: Fighter, amount: int, blockable: bool, src: Fighter = null) -> void:
	if not dst.alive():
		return
	var blocked := 0
	if blockable:
		blocked = mini(dst.block, amount)
		dst.block -= blocked
	var dealt := amount - blocked
	dst.hp = maxi(0, dst.hp - dealt)
	event.emit("damage", {"target": dst, "amount": dealt, "blocked": blocked, "source": src})
	if dst.is_player and dst.alive() and not _below_half_done and dst.hp * 2 <= dst.max_hp and run.has_relic("res_furnace3b"):
		_below_half_done = true
		_apply_status(player, "str", 2)
	if dst.hp <= 0:
		_on_death(dst)


func _on_death(f: Fighter) -> void:
	if f.is_player:
		if run.phoenix_charges > 0:
			run.phoenix_charges -= 1
			f.hp = int(f.max_hp * 0.5)
			event.emit("revive", {"target": f})
			return
		over = true
		won = false
		run.hp = 0
		_cleanup()
		event.emit("defeat", {})
		return
	f.statuses.clear()
	f.block = 0
	run.kills += 1
	var v := Game.kill_value(floor_num, f.is_elite, f.is_boss)
	if f.is_elite and run.has_relic("slag_crown"):
		v *= 2.0
	if bank_embers:
		v = Game.gain_tower_embers(v, "kill")
		Game.note_kill(f.is_elite, f.is_boss, run.heat())
		if f.is_boss and run.has_relic("stardust_vial"):
			Game.add_stardust(1)
	embers_this_combat += v
	event.emit("enemy_died", {"target": f, "embers": v})
	if f.stolen > 0.0:
		var back := f.stolen * 1.5
		if bank_embers:
			Game.refund(back)
		f.stolen = 0.0
		event.emit("refund", {"source": f, "amount": back})
	if run.has_relic("volcanic_glass"):
		energy += 1
		event.emit("energy", {"value": energy})
	if f.is_elite and run.has_relic("res_furnace1b"):
		run.max_hp += 4
		player.max_hp += 4
		_heal(player, 4)
	if run.has_relic("res_heart3b"):
		for o in living_enemies():
			o.hp = maxi(1, o.hp - int(o.max_hp * 0.1))
			event.emit("damage", {"target": o, "amount": int(o.max_hp * 0.1), "blocked": 0, "source": null})
	for op: Array in f.on_death:
		if op[0] == "dmg_p" and player.alive():
			_damage(player, int(round(int(op[1]) * f.dmg_mult)), true, f)


func _gain_block(f: Fighter, n: int) -> void:
	if n <= 0:
		return
	f.block += n
	event.emit("block", {"target": f, "amount": n})


func _heal(f: Fighter, n: int) -> void:
	var before := f.hp
	f.hp = mini(f.max_hp, f.hp + n)
	if f.hp > before:
		event.emit("heal", {"target": f, "amount": f.hp - before})


func _apply_status(f: Fighter, id: String, n: int) -> void:
	if f == null or not f.alive() or n == 0:
		return
	if id == "scorch" and n > 0 and f.affixes.has("fireproof"):
		n = maxi(1, int(n / 2))
	f.add_status(id, n)
	event.emit("status", {"target": f, "id": id, "amount": n})


func _tick_scorch(f: Fighter) -> void:
	var s := f.st("scorch")
	if s <= 0 or not f.alive():
		return
	_damage(f, s if f.is_player else int(floor(s * run.dmg_mult)), false)
	f.add_status("scorch", -1)
	event.emit("status", {"target": f, "id": "scorch", "amount": -1})


func _decay(f: Fighter) -> void:
	for id in ["weak", "vuln"]:
		if f.st(id) > 0:
			f.add_status(id, -1)
	event.emit("status", {"target": f, "id": "", "amount": 0})


func _check_end() -> void:
	if over:
		return
	if living_enemies().is_empty():
		over = true
		won = true
		run.hp = player.hp
		if run.has_relic("pocket_brazier"):
			run.heal(6)
		if run.has_relic("res_furnace2"):
			run.heal(4)
		if run.has_relic("res_furnace2b") and run.hp * 2 <= run.max_hp:
			run.heal(10)
		_cleanup()
		event.emit("victory", {})


## Las mejoras temporales no sobreviven al combate.
func _cleanup() -> void:
	for c in run.deck:
		c.temp_up = false
	run.combat_mods = {}


func _shuffle(arr: Array[Card]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := arr[i]
		arr[i] = arr[j]
		arr[j] = t


func pile_counts() -> Dictionary:
	return {"draw": draw_pile.size(), "discard": discard.size(), "exhaust": exhaust_pile.size()}
