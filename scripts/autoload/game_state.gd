extends Node
## Game: estado persistente (Forja incremental, Arsenal, meta-progreso) y guardado.
## Único dueño de las Ascuas. La run activa vive aquí para sobrevivir cambios de pantalla.

signal embers_changed(value: float)
signal forge_changed
signal embers_gained(amount: float, source: String)
signal hito_unlocked(hito: Dictionary)
signal mastery_changed(card_id: String, level: int)

const SAVE_PATH := "user://emberspire_save.json"
const SAVE_VERSION := 2
const BRAZIER_BONUS := 0.10
const STARDUST_BONUS := 0.10
## Maestría: Quemas acumuladas de una carta para alcanzar cada nivel (1..5).
const MASTERY_XP: Array[int] = [2, 6, 15, 35, 80]
const MASTERY_MAX := 5

var embers := 0.0
var life_embers := 0.0          # desde el último Renacer
var total_embers := 0.0         # histórico
var generators := {}            # id -> int
var arsenal := {}               # id -> nivel
var grimoires := {}             # id -> true
var talents := {}               # id -> true
var stardust := 0.0             # sin gastar
var stardust_total := 0.0       # ganado en total
var max_floor := 0
var runs_started := 0
var rebirths := 0
var best_kills := 0
var last_seen_unix := 0.0
var offline_report := {}
var buy_mode := 1               # 1, 10, -1 (máx)
var sfx_volume := 0.8
var music_volume := 0.5
var seen_intro := false
## Maestría por carta: id -> Quemas acumuladas.
var mastery := {}
## Reliquario: reliquias encontradas alguna vez (+2% producción cada una).
var relic_codex := {}
var stats := {}                 # burns, kills, elites, bosses, heat_boss
var hitos := {}                 # id -> true (reclamados)
var active_pacts: Array[String] = []
var heirloom_picks: Array[String] = []

var run: RunState = null
var _record_at_start := 0
var _save_timer := 0.0
var _auto_timer := 0.0
var _hito_timer := 0.0
var autosave_enabled := true


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	var p := production()
	if p > 0.0:
		_add(p * delta, "idle", false)
	if talents.has("autoforge"):
		_auto_timer += delta
		if _auto_timer >= 0.5:
			_auto_timer = 0.0
			_autobuy()
	_hito_timer += delta
	if _hito_timer >= 1.0:
		_hito_timer = 0.0
		check_hitos()
	_save_timer += delta
	if _save_timer >= 15.0:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


# --- Economía -------------------------------------------------------------

func global_mult() -> float:
	return (1.0 + BRAZIER_BONUS * max_floor) * (1.0 + STARDUST_BONUS * stardust_total) * codex_mult()


func codex_bonus_each() -> float:
	return 0.04 if talents.has("deep_codex") else 0.02


func codex_mult() -> float:
	return 1.0 + codex_bonus_each() * relic_codex.size()


func heat_bonus_each() -> float:
	return 0.40 if talents.has("heat_lover") else 0.25


func generator_rate(g: Dictionary) -> float:
	var n: int = generators.get(g["id"], 0)
	return float(g["rate"]) * n * ForgeDB.milestone_mult(n) * global_mult()


func production() -> float:
	var total := 0.0
	for g in ForgeDB.GENERATORS:
		total += generator_rate(g)
	return total


func click_value() -> float:
	return 1.0 + production() * 0.05


func _add(amount: float, source: String, notify := true) -> void:
	if amount <= 0.0:
		return
	embers += amount
	life_embers += amount
	total_embers += amount
	embers_changed.emit(embers)
	if notify:
		embers_gained.emit(amount, source)


## Ascuas ganadas en la Torre (aplica Codicia y multiplicadores de la run).
func gain_tower_embers(amount: float, source: String) -> float:
	var mult := 1.0 + 0.25 * arsenal_level("greed")
	if run != null:
		mult *= run.ember_mult * (1.0 + heat_bonus_each() * run.heat())
	var v := amount * mult
	if run != null:
		run.embers_earned += v
	_add(v, source)
	return v


func spend(amount: float) -> bool:
	if amount > embers + 0.0001:
		return false
	embers -= amount
	embers_changed.emit(embers)
	return true


func click_forge() -> float:
	var v := click_value()
	_add(v, "click")
	return v


func floor_factor(floor_num: int) -> float:
	return 1.0 + 0.2 * floor_num + 0.02 * floor_num * floor_num


func burn_value(card_cost: int, mult: int, floor_num: int, mastery_lvl: int = 0) -> float:
	var v := (4.0 + 3.0 * maxi(card_cost, 0)) * floor_factor(floor_num) * mult + production() * 3.0 * mult
	return v * (1.0 + 0.2 * mastery_lvl)


func kill_value(floor_num: int, elite: bool, boss: bool) -> float:
	var v := 8.0 * floor_factor(floor_num)
	if elite:
		v *= 4.0
	if boss:
		v *= 15.0
	return v


func victory_wave(kind: String) -> float:
	var secs := 12.0
	match kind:
		"elite": secs = 40.0
		"boss": secs = 180.0
	if run != null and run.has_relic("ledger"):
		secs += 10.0
	return production() * secs


## La Urraca roba Ascuas de la Forja (nunca más de las que tienes).
func steal(amount: float) -> float:
	var v := minf(maxf(amount, 0.0), embers)
	embers -= v
	embers_changed.emit(embers)
	return v


func refund(amount: float) -> void:
	_add(amount, "refund")


func add_stardust(n: int) -> void:
	stardust += n
	stardust_total += n
	forge_changed.emit()


# --- Maestría -------------------------------------------------------------

func mastery_level(card_id: String) -> int:
	var xp: int = mastery.get(card_id, 0)
	var lvl := 0
	for t in MASTERY_XP:
		if xp >= t:
			lvl += 1
	return lvl


## Suma Maestría. Devuelve el nuevo nivel si sube, 0 si no.
func add_mastery(card_id: String, xp: int) -> int:
	if not CardDB.CARDS.has(card_id) or CardDB.get_def(card_id)["rarity"] in ["status", "token"]:
		return 0
	var before := mastery_level(card_id)
	mastery[card_id] = int(mastery.get(card_id, 0)) + xp
	var after := mastery_level(card_id)
	if after > before:
		mastery_changed.emit(card_id, after)
		return after
	return 0


func mastery_progress(card_id: String) -> Vector2i:
	var xp: int = mastery.get(card_id, 0)
	var lvl := mastery_level(card_id)
	if lvl >= MASTERY_MAX:
		return Vector2i(xp, xp)
	return Vector2i(xp, MASTERY_XP[lvl])


func mastered_count(min_level: int) -> int:
	var n := 0
	for id: String in mastery:
		if mastery_level(id) >= min_level:
			n += 1
	return n


# --- Reliquario, estadísticas y Crónica ------------------------------------

func collect_relic(id: String) -> void:
	if id == "" or RelicDB.is_perk(id) or relic_codex.has(id):
		return
	relic_codex[id] = true
	forge_changed.emit()


func add_stat(key: String, n: int) -> void:
	stats[key] = int(stats.get(key, 0)) + n


func note_kill(elite: bool, boss: bool, heat: int) -> void:
	add_stat("kills", 1)
	if elite:
		add_stat("elites", 1)
	if boss:
		add_stat("bosses", 1)
		stats["heat_boss"] = maxi(int(stats.get("heat_boss", 0)), heat)


func total_generators() -> int:
	var n := 0
	for k: String in generators:
		n += int(generators[k])
	return n


func stat_value(key: String) -> float:
	match key:
		"max_floor": return max_floor
		"relics": return relic_codex.size()
		"mastered": return mastered_count(1)
		"mastered_max": return mastered_count(MASTERY_MAX)
		"gens": return total_generators()
		"prod": return production()
		"rebirths": return rebirths
		"grimoires": return grimoires.size()
	return float(stats.get(key, 0))


func hito_reward_text(h: Dictionary) -> String:
	if h.has("dust"):
		return "+%d Polvo Estelar" % h["dust"]
	return "+%d s de producción" % h["secs"]


func check_hitos() -> void:
	for h in ForgeDB.HITOS:
		if hitos.has(h["id"]):
			continue
		if stat_value(h["stat"]) >= float(h["goal"]):
			hitos[h["id"]] = true
			if h.has("dust"):
				add_stardust(int(h["dust"]))
			else:
				_add(production() * float(h["secs"]) + 5.0 * float(h["secs"]), "hito")
			hito_unlocked.emit(h)


# --- Pactos y Resonancias --------------------------------------------------

func pacts_unlocked() -> bool:
	return max_floor >= 10


func pact_heat(ids: Array) -> int:
	var h := 0
	for id: String in ids:
		h += int(ForgeDB.pact(id).get("heat", 0))
	return h


func resonance_threshold(tier: int) -> int:
	var t: int = RelicDB.RESONANCE_TIERS[tier]
	return t / 2 if talents.has("echoes") else t


## Resonancias activas según los generadores que tienes ahora.
func perk_ids() -> Array[String]:
	var out: Array[String] = []
	for g in ForgeDB.GENERATORS:
		for tier in RelicDB.RESONANCE_TIERS.size():
			if gen_count(g["id"]) >= resonance_threshold(tier):
				var id := RelicDB.perk_for(g["id"], tier)
				if id != "":
					out.append(id)
	return out


# --- Generadores ----------------------------------------------------------

func gen_count(id: String) -> int:
	return generators.get(id, 0)


func gen_cost_mult() -> float:
	return 0.85 if talents.has("star_forge") else 1.0


func gen_cost(g: Dictionary, amount: int) -> float:
	return ForgeDB.generator_cost(g, gen_count(g["id"]), amount) * gen_cost_mult()


func buy_amount_for(g: Dictionary) -> int:
	if buy_mode > 0:
		return buy_mode
	return maxi(1, ForgeDB.max_affordable(g, gen_count(g["id"]), embers / gen_cost_mult()))


func buy_generator(id: String, amount: int = 1) -> bool:
	var g := ForgeDB.generator(id)
	var cost := gen_cost(g, amount)
	if not spend(cost):
		return false
	generators[id] = gen_count(id) + amount
	forge_changed.emit()
	return true


func generator_visible(index: int) -> bool:
	if index == 0:
		return true
	var prev: Dictionary = ForgeDB.GENERATORS[index - 1]
	return gen_count(prev["id"]) > 0 or gen_count(ForgeDB.GENERATORS[index]["id"]) > 0


func _autobuy() -> void:
	var best := ""
	var best_cost := INF
	for g in ForgeDB.GENERATORS:
		var c := gen_cost(g, 1)
		if c < best_cost:
			best_cost = c
			best = g["id"]
	if best != "" and embers >= best_cost:
		buy_generator(best, 1)


# --- Arsenal / Grimorios / Talentos ---------------------------------------

func arsenal_level(id: String) -> int:
	return arsenal.get(id, 0)


func buy_arsenal(id: String) -> bool:
	var a := ForgeDB.arsenal(id)
	var lvl := arsenal_level(id)
	if lvl >= int(a["max"]):
		return false
	if not spend(ForgeDB.arsenal_cost(a, lvl)):
		return false
	arsenal[id] = lvl + 1
	forge_changed.emit()
	return true


func buy_grimoire(id: String) -> bool:
	if grimoires.has(id):
		return false
	if not spend(float(ForgeDB.grimoire(id)["cost"])):
		return false
	grimoires[id] = true
	forge_changed.emit()
	return true


func card_packs() -> Array:
	var packs := ["base"]
	for k: String in grimoires:
		packs.append(k)
	return packs


func buy_talent(id: String) -> bool:
	if talents.has(id):
		return false
	var cost := float(ForgeDB.talent(id)["cost"])
	if stardust < cost:
		return false
	stardust -= cost
	talents[id] = true
	forge_changed.emit()
	return true


# --- Renacer --------------------------------------------------------------

func rebirth_gain() -> int:
	var g := sqrt(life_embers / 1.0e6) * (1.0 + max_floor / 20.0)
	if talents.has("stellar_greed"):
		g *= 1.5
	return int(floor(g))


func rebirth() -> bool:
	var gain := rebirth_gain()
	if gain < 1:
		return false
	stardust += gain
	stardust_total += gain
	rebirths += 1
	embers = 0.0
	life_embers = 0.0
	generators.clear()
	if talents.has("memory"):
		generators["spark"] = 10
		embers = 1000.0
	embers_changed.emit(embers)
	forge_changed.emit()
	save_game()
	return true


# --- Ascensión ------------------------------------------------------------

func start_run(seed_value: int = -1) -> RunState:
	var r := RunState.new()
	if seed_value >= 0:
		r.rng.seed = seed_value
	else:
		r.rng.randomize()
	r.max_hp = int((60 + 6 * arsenal_level("vitality")) * pow(1.04, arsenal_level("skin")))
	r.hp = r.max_hp
	r.max_energy = 3 + arsenal_level("core")
	r.draw_per_turn = 5 + arsenal_level("hands")
	r.burns_per_turn = 1 + arsenal_level("flue")
	r.start_str = arsenal_level("arm")
	r.dmg_mult = pow(1.04, arsenal_level("edge"))
	r.phoenix_available = talents.has("phoenix")
	run = r
	r.perks = perk_ids()
	if r.has_relic("res_furnace1"):
		r.max_hp += 8
		r.hp = r.max_hp
	if pacts_unlocked():
		for id in active_pacts:
			r.pacts.append(id)
	var tempered := arsenal_level("temper")
	# Orden de templado: variedad primero (Tajo, Leña, Golpe, Defensa...).
	var order := [4, 9, 0, 5, 1, 6, 2, 7, 3, 8]
	var up_idx := {}
	for i in mini(tempered, order.size()):
		up_idx[order[i]] = true
	for i in CardDB.STARTER_DECK.size():
		r.deck.append(Card.new(CardDB.STARTER_DECK[i], up_idx.has(i)))
	if r.has_pact("pact_frost"):
		r.deck.append(Card.new("frost"))
		r.deck.append(Card.new("frost"))
	if r.has_relic("res_crucible3"):
		var rares := CardDB.ids_in_packs(card_packs(), "rare")
		if not rares.is_empty():
			r.deck.append(Card.new(rares[r.rng.randi_range(0, rares.size() - 1)]))
	var slots := arsenal_level("heirloom")
	var picked := 0
	for id in heirloom_picks:
		if picked >= slots:
			break
		if relic_codex.has(id) and not r.relics.has(id):
			r.add_relic(id)
			picked += 1
	for i in slots - picked:
		r.add_relic(RelicDB.random_unowned(r.relics, r.rng))
	_record_at_start = max_floor
	runs_started += 1
	save_game()
	return r


func end_run() -> Dictionary:
	if run == null:
		return {}
	var prev_record := _record_at_start
	max_floor = maxi(max_floor, run.floor_num)
	best_kills = maxi(best_kills, run.kills)
	var summary := {"floor": run.floor_num, "embers": run.embers_earned, "kills": run.kills,
		"burned": run.burned, "new_braziers": max_floor - prev_record,
		"mastery_ups": run.mastery_ups, "relics": run.relics.size(), "heat": run.heat()}
	run = null
	check_hitos()
	forge_changed.emit()
	save_game()
	return summary


## Récord provisional durante la run (los braseros se encienden al llegar).
func reach_floor(floor_num: int) -> void:
	if floor_num > max_floor:
		max_floor = floor_num
		forge_changed.emit()


# --- Guardado -------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"v": SAVE_VERSION, "embers": embers, "life_embers": life_embers, "total_embers": total_embers,
		"generators": generators, "arsenal": arsenal, "grimoires": grimoires.keys(), "talents": talents.keys(),
		"stardust": stardust, "stardust_total": stardust_total, "max_floor": max_floor,
		"runs_started": runs_started, "rebirths": rebirths, "best_kills": best_kills,
		"last_seen": Time.get_unix_time_from_system(), "buy_mode": buy_mode,
		"sfx_volume": sfx_volume, "music_volume": music_volume, "seen_intro": seen_intro,
		"mastery": mastery, "relic_codex": relic_codex.keys(), "stats": stats, "hitos": hitos.keys(),
		"active_pacts": active_pacts, "heirloom_picks": heirloom_picks,
		"run": run.to_dict() if run != null else {}, "record_at_start": _record_at_start}


func from_dict(d: Dictionary) -> void:
	embers = float(d.get("embers", 0.0))
	life_embers = float(d.get("life_embers", 0.0))
	total_embers = float(d.get("total_embers", 0.0))
	generators = {}
	for k: String in d.get("generators", {}):
		generators[k] = int(d["generators"][k])
	arsenal = {}
	for k: String in d.get("arsenal", {}):
		arsenal[k] = int(d["arsenal"][k])
	grimoires = {}
	for k in d.get("grimoires", []):
		grimoires[str(k)] = true
	talents = {}
	for k in d.get("talents", []):
		talents[str(k)] = true
	stardust = float(d.get("stardust", 0.0))
	stardust_total = float(d.get("stardust_total", 0.0))
	max_floor = int(d.get("max_floor", 0))
	runs_started = int(d.get("runs_started", 0))
	rebirths = int(d.get("rebirths", 0))
	best_kills = int(d.get("best_kills", 0))
	last_seen_unix = float(d.get("last_seen", 0.0))
	buy_mode = int(d.get("buy_mode", 1))
	sfx_volume = float(d.get("sfx_volume", 0.8))
	music_volume = float(d.get("music_volume", 0.5))
	seen_intro = bool(d.get("seen_intro", false))
	mastery = {}
	var md: Variant = d.get("mastery", {})
	if md is Dictionary:
		for k: String in md:
			mastery[k] = int(md[k])
	relic_codex = {}
	for k in d.get("relic_codex", []):
		relic_codex[str(k)] = true
	stats = {}
	var sd: Variant = d.get("stats", {})
	if sd is Dictionary:
		for k: String in sd:
			stats[k] = int(sd[k])
	hitos = {}
	for k in d.get("hitos", []):
		hitos[str(k)] = true
	active_pacts.clear()
	for k in d.get("active_pacts", []):
		active_pacts.append(str(k))
	heirloom_picks.clear()
	for k in d.get("heirloom_picks", []):
		heirloom_picks.append(str(k))
	var rd: Variant = d.get("run", {})
	run = RunState.from_dict(rd) if rd is Dictionary and not (rd as Dictionary).is_empty() else null
	_record_at_start = int(d.get("record_at_start", max_floor))


func save_game() -> void:
	if not autosave_enabled:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(to_dict()))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Partida guardada corrupta; se ignora.")
		return
	from_dict(parsed)
	_apply_offline()


func _apply_offline() -> void:
	if last_seen_unix <= 0.0:
		return
	var cap := (24.0 if talents.has("eternal") else 8.0) * 3600.0
	var elapsed := clampf(Time.get_unix_time_from_system() - last_seen_unix, 0.0, cap)
	var gained := production() * elapsed
	if elapsed > 60.0 and gained > 0.0:
		_add(gained, "offline", false)
		offline_report = {"seconds": elapsed, "embers": gained}


func reset_all() -> void:
	from_dict({})
	run = null
	offline_report = {}
	save_game()
	embers_changed.emit(embers)
	forge_changed.emit()
