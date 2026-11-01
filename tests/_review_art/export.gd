extends Node
## Revisión de arte: exporta sprites ampliados a tests/_review_art/out/

const OUT := "res://tests/_review_art/out/"

func up(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c

func sheet(imgs: Array, s: int, cols: int, bg: Color, pad: int = 8) -> Image:
	var cw := 0
	var ch := 0
	for i: Image in imgs:
		cw = maxi(cw, i.get_width() * s)
		ch = maxi(ch, i.get_height() * s)
	var rows := int(ceil(imgs.size() / float(cols)))
	var out := Image.create(cols * (cw + pad) + pad, rows * (ch + pad) + pad, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	for n in imgs.size():
		var i: Image = up(imgs[n], s)
		i.convert(Image.FORMAT_RGBA8)
		var x := pad + (n % cols) * (cw + pad) + (cw - i.get_width()) / 2
		var y := pad + (n / cols) * (ch + pad) + (ch - i.get_height())
		out.blend_rect(i, Rect2i(0, 0, i.get_width(), i.get_height()), Vector2i(x, y))
	return out

func _ready() -> void:
	var bg := Color("3a2a2c")
	# Monstruos por bioma
	for b in 3:
		var imgs: Array = []
		for sh: String in Art.SHAPES.keys():
			var t := Art.monster(sh, "seedA", b)
			var g := Art.monster_glow(sh, "seedA", b)
			var im := t.get_image()
			im.convert(Image.FORMAT_RGBA8)
			imgs.append(im)
		sheet(imgs, 6, 7, Art.BIOMES[b]["wall"]).save_png(OUT + "monsters_b%d.png" % b)
	# Variación por semilla de golem y slime
	var var_imgs: Array = []
	for sh: String in ["golem", "slime", "knight", "bat"]:
		for s in 5:
			var im2 := Art.monster(sh, "s%d" % s, 0).get_image()
			im2.convert(Image.FORMAT_RGBA8)
			var_imgs.append(im2)
	sheet(var_imgs, 5, 5, bg).save_png(OUT + "monster_seeds.png")
	# Iconos
	var ids: Array = Art.SPRITES.keys()
	ids.erase("player"); ids.erase("player_arm")
	ids.append_array(Art.VARIANTS.keys())
	var icons: Array = []
	for id: String in ids:
		icons.append(Art.icon_image(id))
	sheet(icons, 6, 12, bg).save_png(OUT + "icons.png")
	# Iconos a x2 (escala real de juego) para legibilidad
	sheet(icons, 2, 12, Color("231619"), 6).save_png(OUT + "icons_x2.png")
	var f := FileAccess.open("res://tests/_review_art/out/icon_order.txt", FileAccess.WRITE)
	f.store_string(", ".join(ids))
	# Heroína compuesta
	var body := Art.icon_image("player")
	var arm := Art.icon_image("player_arm")
	var comp := Image.create(28, 34, false, Image.FORMAT_RGBA8)
	comp.fill(Color(0,0,0,0))
	comp.blend_rect(body, Rect2i(0,0,20,30), Vector2i(2,2))
	comp.blend_rect(arm, Rect2i(0,0,8,17), Vector2i(14,15))
	var hero := sheet([body, arm, comp], 12, 3, bg)
	hero.save_png(OUT + "hero.png")
	# Cartas
	var cards: Array = []
	for ty: String in ["attack", "skill", "power", "fuel", "status"]:
		var fr := Art.card_frame(ty, "rare", false, 3).get_image()
		fr.convert(Image.FORMAT_RGBA8)
		cards.append(fr)
	sheet(cards, 3, 5, bg).save_png(OUT + "card_frames.png")
	var arts: Array = []
	for pair: Array in [["strike","attack","sword"],["defend","skill","shield"],["inner_fire","power","flame"],["coal","fuel","coal"],["kindling","fuel","log"],["ash","status","wet_ash"]]:
		var a := Art.card_art(pair[0], pair[1], pair[2]).get_image()
		a.convert(Image.FORMAT_RGBA8)
		arts.append(a)
	sheet(arts, 8, 3, bg).save_png(OUT + "card_arts.png")
	var cb := Art.card_back().get_image(); cb.convert(Image.FORMAT_RGBA8)
	up(cb, 4).save_png(OUT + "card_back.png")
	# Fondos nativos x2
	for b in 3:
		var bgi := Art.background(b, 7).get_image()
		up(bgi, 2).save_png(OUT + "bg_%d.png" % b)
	var fo := Art.forge_sprite(1.0).get_image(); fo.convert(Image.FORMAT_RGBA8)
	up(fo, 10).save_png(OUT + "forge.png")
	var orb := Art.cost_orb(true, false).get_image(); orb.convert(Image.FORMAT_RGBA8)
	up(orb, 16).save_png(OUT + "orb.png")
	print("REVIEW EXPORT OK")
	get_tree().quit()
