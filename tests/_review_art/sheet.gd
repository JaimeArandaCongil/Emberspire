extends Node
## Revisión: hojas de los nuevos assets.
const OUT := "res://tests/_review_art/out/new_"

func img(t: Texture2D) -> Image:
	var i := t.get_image()
	i.convert(Image.FORMAT_RGBA8)
	return i

func sheet(imgs: Array, s: int, cols: int, bg: Color, pad: int = 6) -> Image:
	var cw := 0
	var ch := 0
	for i: Image in imgs:
		cw = maxi(cw, i.get_width() * s)
		ch = maxi(ch, i.get_height() * s)
	var rows := int(ceil(imgs.size() / float(cols)))
	var out := Image.create(cols * (cw + pad) + pad, rows * (ch + pad) + pad, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	for n in imgs.size():
		var i: Image = (imgs[n] as Image).duplicate()
		i.resize(i.get_width() * s, i.get_height() * s, Image.INTERPOLATE_NEAREST)
		var x := pad + (n % cols) * (cw + pad) + (cw - i.get_width()) / 2
		var y := pad + (n / cols) * (ch + pad) + (ch - i.get_height())
		out.blend_rect(i, Rect2i(0, 0, i.get_width(), i.get_height()), Vector2i(x, y))
	return out

func _ready() -> void:
	var shapes: Array = Art.BASES.keys() + Art.SHAPES.keys()
	for b in 3:
		var a: Array = []
		for sh: String in shapes:
			a.append(img(Art.monster(sh, "seedA", b)))
		sheet(a, 3, 7, Art.BIOMES[b]["wall"]).save_png(OUT + "monsters_b%d.png" % b)
	var poses: Array = []
	for p: String in ["idle", "idle_b", "windup", "smear", "strike", "recover", "cast", "toss_back", "toss", "hurt"]:
		poses.append(img(Art.player_pose(p)))
	poses.append(img(Art.player()))
	sheet(poses, 4, 6, Color("2e2226")).save_png(OUT + "hero_poses.png")
	var cards: Array = []
	for pair: Array in [["strike","attack","sword"],["defend","skill","shield"],["inner_fire","power","flame"],["coal","fuel","coal"],["ash","status","wet_ash"]]:
		var fr := img(Art.card_frame(pair[1], "rare", false, 3))
		var ca := img(Art.card_art(pair[0], pair[1], pair[2]))
		fr.blend_rect(ca, Rect2i(0, 0, 60, 30), Vector2i(7, 16))
		cards.append(fr)
	sheet(cards, 3, 5, Color("140c10")).save_png(OUT + "cards.png")
	for b in 3:
		var bg := img(Art.background(b, 7))
		bg.blend_rect(img(Art.background_near(b, 7)), Rect2i(8, 0, 320, 180), Vector2i(0, 0))
		bg.resize(640, 360, Image.INTERPOLATE_NEAREST)
		bg.save_png(OUT + "bg_%d.png" % b)
	var misc: Array = [img(Art.forge_sprite(0.2)), img(Art.forge_sprite(1.0, 1)), img(Art.furnace_small(0.5)), img(Art.bonfire(0)), img(Art.bonfire(2)), img(Art.logo())]
	sheet(misc, 4, 3, Color("2e2226")).save_png(OUT + "misc.png")
	var ev: Array = []
	for id: String in Art.EVENT_SCENES:
		ev.append(img(Art.event_art(id)))
	sheet(ev, 2, 4, Color("140c10")).save_png(OUT + "events.png")
	var doors: Array = []
	for k: String in Art.DOOR_COLORS:
		doors.append(img(Art.door_art(k, 0)))
	sheet(doors, 3, 7, Color("2e2226")).save_png(OUT + "doors.png")
	print("SHEET OK")
	get_tree().quit()
