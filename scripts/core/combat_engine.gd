class_name CombatEngine
extends RefCounted
## Reglas del combate. Sin nodos: emite `event(kind, data)` y la UI lo representa.
## Eventos: turn_start, draw, discard, exhaust, card_played, card_burned, damage, block,
##          status, power, heal, energy, burns, intent, enemy_died, victory, defeat, revive, shuffle

signal event(kind: String, data: Dictionary)

const HAND_MAX := 10

var run: RunState
var player: Fighter
var enemies: Array[Fighter] = []
var draw_pile: Array[Card] = []
var hand: Array[Card] = []
var discard: Array[Card] = []
var exhaust_pile: Array[Card] = []
var energy := 0
var burns_left := 0
var burned_count := 0
var turn := 0
var floor_num := 1
var kind := "combat"
var over := false
var won := false
var rng := RandomNumberGenerator.new()
## Si es false, las Ascuas no tocan el autoload (tests headless puros).
var bank_embers := true
var embers_this_combat := 0.0


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
		var e := EnemyDB.make(id, floor_num, rng)
		enemies.append(e)
	for c in run.deck:
		draw_pile.append(c)
	_shuffle(draw_pile)


func start() -> void:
	if run.start_str > 0:
		player.add_status("str", run.start_str)
	if run.has_relic("ember_ring"):
		player.add_status("str", 1)
	if run.has_relic("salamander_scale"):
		for e in enemies:
			e.add_status("scorch", 3)
	for e in enemies:
		_choose_intent(e)
	start_player_turn()


func living_enemies() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for e in enemies:
		if e.alive():
			out.append(e)
	return out


# --- Turno del jugador ----------------------------------------------------

func start_player_turn() -> void:
	if over:
		return
	turn += 1
	player.block = 0
	if turn == 1 and run.has_relic("warm_stone"):
		_gain_block(player, 6)
	_tick_scorch(player)
	if over:
		return
	energy = run.max_energy + player.pw("solar")
	if turn == 1 and run.has_relic("eternal_candle"):
		energy += 1
	burns_left = run.burns_per_turn + (1 if run.has_relic("leather_bellows") else 0)
	if player.pw("forge_block") > 0:
		_gain_block(player, player.pw("forge_block"))
	if player.pw("temper") > 0:
		_apply_status(player, "str", player.pw("temper"))
	var n := run.draw_per_turn
	if turn == 1 and run.has_relic("ash_eye"):
		n += 2
	draw_cards(n)
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
		var c: Card = draw_pile.pop_back()
		hand.append(c)
		event.emit("draw", {"card": c})


func can_play(card: Card) -> bool:
	if over or not hand.has(card) or not card.is_playable():
		return false
	if card.is_x_cost():
		return true
	return energy >= card.cost()


func can_burn(card: Card) -> bool:
	return not over and hand.has(card) and burns_left > 0


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
	event.emit("energy", {"value": energy})
	event.emit("card_played", {"card": card, "target": target})
	_run_ops(card.effects(), target, x, card)
	if card.type() == "power":
		pass  # Los poderes desaparecen al jugarse.
	elif card.exhausts():
		exhaust_pile.append(card)
		event.emit("exhaust", {"card": card})
	else:
		discard.append(card)
	_check_end()
	return true


func burn_card(card: Card) -> bool:
	if not can_burn(card):
		return false
	hand.erase(card)
	burns_left -= 1
	burned_count += 1
	run.burned += 1
	exhaust_pile.append(card)
	var mult := 1
	for op: Array in card.burn_effects():
		if op[0] == "ember_mult":
			mult = op[1]
	var value := Game.burn_value(card.cost(), mult, floor_num)
	if bank_embers:
		value = Game.gain_tower_embers(value, "burn")
	embers_this_combat += value
	event.emit("card_burned", {"card": card, "embers": value})
	event.emit("burns", {"value": burns_left})
	var alive := living_enemies()
	var tgt: Fighter = alive[rng.randi_range(0, alive.size() - 1)] if not alive.is_empty() else null
	_run_ops(card.burn_effects(), tgt, 0, card)
	if player.pw("inner_fire") > 0:
		for e in living_enemies():
			_hit(null, e, player.pw("inner_fire"))
	if player.pw("ash_armor") > 0:
		_gain_block(player, player.pw("ash_armor"))
	if run.has_relic("iron_lung"):
		_gain_block(player, 3)
	_check_end()
	return true


func end_player_turn() -> void:
	if over:
		return
	for c in hand.duplicate():
		hand.erase(c)
		if c.id == "frost":
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
	_check_end()


func enemy_act(e: Fighter) -> void:
	if over or not e.alive():
		return
	for op: Array in e.intent.get("ops", []):
		if over:
			break
		_enemy_op(e, op)
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
	for op: Array in ops:
		match op[0]:
			"atk": has_atk = true
			"block", "block_all": has_def = true
			"str", "str_all", "heal": has_buff = true
			_: has_debuff = true
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
		"scorch_p":
			_apply_status(player, "scorch", op[1])
		"weak_p":
			_apply_status(player, "weak", op[1])
		"vuln_p":
			_apply_status(player, "vuln", op[1])
		"add_card":
			for i in int(op[2]):
				var c := Card.new(op[1])
				discard.append(c)
				event.emit("card_added", {"card": c, "source": e})


# --- Operaciones de cartas ------------------------------------------------

func _run_ops(ops: Array, target: Fighter, x: int, card: Card) -> void:
	var is_attack := card != null and card.type() == "attack"
	for op: Array in ops:
		if over:
			return
		var k: String = op[0]
		match k:
			"dmg":
				_hit(player, target, _atk_base(op[1], is_attack))
			"dmg_x":
				for i in int(op[2]):
					if target == null or not target.alive():
						break
					_hit(player, target, _atk_base(op[1], is_attack))
			"dmg_all":
				for e in living_enemies():
					_hit(player, e, _atk_base(op[1], is_attack))
			"dmg_rand":
				for i in int(op[2]):
					var alive := living_enemies()
					if alive.is_empty():
						break
					_hit(player, alive[rng.randi_range(0, alive.size() - 1)], _atk_base(op[1], is_attack))
			"dmg_xcost":
				for i in x:
					if target == null or not target.alive():
						break
					_hit(player, target, _atk_base(op[1], is_attack))
			"dmg_per_burned":
				_hit(player, target, _atk_base(int(op[1]) + int(op[2]) * burned_count, is_attack))
			"block_dmg":
				_hit(player, target, _atk_base(player.block, is_attack))
			"detonate":
				if target != null and target.alive():
					_hit(null, target, target.st("scorch") * int(op[1]))
			"block":
				_gain_block(player, op[1])
			"block_per_burned":
				_gain_block(player, int(op[1]) * burned_count)
			"double_block":
				_gain_block(player, player.block)
			"draw":
				draw_cards(op[1])
			"energy":
				energy += int(op[1])
				event.emit("energy", {"value": energy})
			"burn_charge":
				burns_left += int(op[1])
				event.emit("burns", {"value": burns_left})
			"scorch":
				if target != null:
					_apply_status(target, "scorch", int(op[1]) + player.pw("salamander"))
			"scorch_all":
				for e in living_enemies():
					_apply_status(e, "scorch", int(op[1]) + player.pw("salamander"))
			"vuln":
				if target != null:
					_apply_status(target, "vuln", op[1])
			"weak":
				if target != null:
					_apply_status(target, "weak", op[1])
			"weak_all":
				for e in living_enemies():
					_apply_status(e, "weak", op[1])
			"str":
				_apply_status(player, "str", op[1])
			"heal":
				_heal(player, op[1])
			"power":
				player.powers[op[1]] = player.pw(op[1]) + int(op[2])
				event.emit("power", {"id": op[1], "value": player.pw(op[1])})
			"ember_mult":
				pass  # Se resuelve al calcular el valor de quema.


func _atk_base(base: int, is_attack: bool) -> int:
	if is_attack and run.has_relic("whetstone"):
		return base + 2
	return base


## Daño que mostraría una carta del jugador contra el primer enemigo vivo.
func preview_damage(base: int) -> int:
	var alive := living_enemies()
	return calc_damage(player, alive[0] if not alive.is_empty() else null, base)


func calc_damage(src: Fighter, dst: Fighter, base: int) -> int:
	var d := float(base)
	if src != null:
		d += src.st("str")
		if src.st("weak") > 0:
			d *= 0.75
	if dst != null and dst.st("vuln") > 0:
		d *= 1.5
	return maxi(0, int(floor(d)))


func _hit(src: Fighter, dst: Fighter, base: int) -> void:
	if dst == null or not dst.alive():
		return
	_damage(dst, calc_damage(src, dst, base), true, src)


func _damage(dst: Fighter, amount: int, blockable: bool, src: Fighter = null) -> void:
	var blocked := 0
	if blockable:
		blocked = mini(dst.block, amount)
		dst.block -= blocked
	var dealt := amount - blocked
	dst.hp = maxi(0, dst.hp - dealt)
	event.emit("damage", {"target": dst, "amount": dealt, "blocked": blocked, "source": src})
	if dst.hp <= 0:
		_on_death(dst)


func _on_death(f: Fighter) -> void:
	if f.is_player:
		if run.phoenix_available:
			run.phoenix_available = false
			f.hp = int(f.max_hp * 0.5)
			event.emit("revive", {"target": f})
			return
		over = true
		won = false
		run.hp = 0
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
	embers_this_combat += v
	event.emit("enemy_died", {"target": f, "embers": v})


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
	f.add_status(id, n)
	event.emit("status", {"target": f, "id": id, "amount": n})


func _tick_scorch(f: Fighter) -> void:
	var s := f.st("scorch")
	if s <= 0 or not f.alive():
		return
	_damage(f, s, false)
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
		event.emit("victory", {})


func _shuffle(arr: Array[Card]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := arr[i]
		arr[i] = arr[j]
		arr[j] = t


func pile_counts() -> Dictionary:
	return {"draw": draw_pile.size(), "discard": discard.size(), "exhaust": exhaust_pile.size()}
