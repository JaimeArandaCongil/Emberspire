extends SceneTree
func _init():
	var T = load("res://tests/art/test_per.gd").new()
	print("PER_FAILS ", T.run())
	quit()
