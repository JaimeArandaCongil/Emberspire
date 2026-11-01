extends Node
## Ejecuta tests/art/test_da.gd aislado (revisión de DA). Imprime fallos y exporta la LUT.
func _ready() -> void:
	var t: RefCounted = load("res://tests/art/test_da.gd").new()
	var fails: Array = t.run()
	for f: String in fails:
		print("FALLO ", f)
	print("TEST_DA %s (%d fallos), materiales=%d colores=%d" % ["OK" if fails.is_empty() else "KO", fails.size(), Palette.count(), Palette.all_colors().size()])
	var lut := Palette.build_lut_image()
	lut.resize(lut.get_width() * 8, lut.get_height() * 8, Image.INTERPOLATE_NEAREST)
	lut.save_png("res://tests/_review_art/v04/director/palette_lut_x8.png")
	get_tree().quit()
