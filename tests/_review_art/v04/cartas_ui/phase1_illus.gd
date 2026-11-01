extends SceneTree
## Fase 1 · hoja de las 12 ilustraciones (×4) y de los marcos con ilustración (×2), sin texto.
## godot --headless --path . --script res://tests/_review_art/v04/cartas_ui/phase1_illus.gd

const OUT := "res://tests/_review_art/v04/cartas_ui/out/"
const _Px := preload("res://scripts/art/cards/illus/illus_px.gd")
const _Ill := preload("res://scripts/art/cards/illus/card_illus.gd")
const _Fr := preload("res://scripts/art/cards/frame.gd")


func _init() -> void:
	var ids := _Ill.ids()
	var types := {"strike": "attack", "defend": "skill", "kindling": "fuel", "ember_slash": "attack", "heavy_hammer": "attack",
		"sparks": "attack", "cleave": "attack", "iron_wall": "skill", "quench": "skill", "bellows": "skill", "stoke": "skill", "coal": "fuel"}
	var bg := Palette.color(&"plate", 1)
	var s := 4
	var cols := 4
	var sheet := _Px.new_img(cols * (68 * s + 8) + 8, 3 * (46 * s + 8) + 8)
	sheet.fill(bg)
	var off := 0
	for i in ids.size():
		var img: Image = _Ill.image(ids[i], types[ids[i]])
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0 and not Palette.is_palette_color(p):
					off += 1
		_Px.blit(sheet, _Px.scaled(img, s), 8 + (i % cols) * (68 * s + 8), 8 + (i / cols) * (46 * s + 8))
	sheet.save_png(OUT + "p1_illus_x4.png")
	# Marcos con ilustración.
	var fs := _Px.new_img(6 * 184 + 8, 2 * 248 + 8)
	fs.fill(bg)
	var rar := {"strike": "starter", "defend": "starter", "kindling": "starter", "ember_slash": "starter", "stoke": "uncommon"}
	for i in ids.size():
		var st := {"type": types[ids[i]], "rarity": rar.get(ids[i], "common")}
		var fr := _Fr.build(st, _Ill.image(ids[i], types[ids[i]]))
		_Px.blit(fs, _Px.scaled(fr, 2), 8 + (i % 6) * 184, 4 + (i / 6) * 248)
	fs.save_png(OUT + "p1_frames_x2.png")
	print("off-palette px: ", off)
	quit()
