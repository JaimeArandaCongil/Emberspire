extends "res://tests/progression_sim.gd"

func _ready() -> void:
	super._ready()
	var keys := Game.mastery.keys()
	keys.sort_custom(func(a, b): return Game.mastery[a] > Game.mastery[b])
	var s := ""
	for k in keys:
		s += "%s:%d(L%d) " % [k, Game.mastery[k], Game.mastery_level(k)]
	print(s)
	print("talentos comprados: %d/%d · Polvo sin gastar: %d" % [Game.talents.size(), ForgeDB.TALENTS.size(), int(Game.stardust)])
	print("arsenal: ", Game.arsenal)
	print("generadores: ", Game.generators)
