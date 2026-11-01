extends Node
## Propuestas de sprites (revisión de arte). Se renderizan a out/proposal_*.png

const HERO := [
	"........kkkkk...........",
	"......kkRrroyk..........",
	".....kRrrrooyyk.........",
	"....kRrrrroooyyk........",
	"..kkRRrrrrrrooyyk.......",
	".kyRRrrWWWWWWWWWk.......",
	"kyoRrkrrrrrrrrorkk......",
	"koRrkSRrsssRrsssk.......",
	"kRRkRSsssssskssk........",
	".kRkRSSssssWksssk.......",
	"..kkRSSssssssssk........",
	"....kSSsssssRsk.........",
	".....kSSssssskk.........",
	"......kkSSSSk...........",
	".....kbbkkkkbbk.........",
	"....kbccbbbbbccbk.......",
	"...kbcbBbbbbbBbbbk......",
	"..kSkkBnnnnnnnnkBk......",
	"..kSsknnnnnnnnnhkk......",
	"..kSsknhhhnnnnnhk.......",
	"..kSsknhnhnnnnnhk.......",
	"..ksSkkkkkykkkkkk.......",
	"..kSSknhnkyknnhnk.......",
	"...kkknnnnnnnnnhk.......",
	".....knnnnhnnnnhk.......",
	".....knnhnnnnnhhk.......",
	".....kdddddkdddddk......",
	"....kdddgdk.kdgdddk.....",
	"....kddgdk...kdgddk.....",
	"....kdddk.....kdddk.....",
	"....kdgdk.....kdgddk....",
	"...kkhhhk.....kkhhhk....",
	"..khnnnhk.....khnnnhkk..",
	"..khnnnhk.....khnnnnhhk.",
	".khhhhhhk.....khhhhhhhk.",
	".kkkkkkkk.....kkkkkkkkk.",
]
const ARM := [
	"..kkkk....",
	".knnnnk...",
	".knnnhk...",
	".kSssSk...",
	".kSssSk...",
	"..kSsSk...",
	"..kSsSk...",
	"..khhhk...",
	"..kssSk...",
	"..ksSSk...",
	"...knk....",
	"...khk....",
	"...knk....",
	"...khk....",
	"...knk....",
	"kkkkhkkkk.",
	"kMMMMMmmdk",
	"kMmmmmmmdk",
	"kmmmmmmddk",
	"kkkkkkkkk.",
]

func up(img: Image, s: int) -> Image:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c

func check(name: String, rows: Array) -> void:
	var w := String(rows[0]).length()
	for i in rows.size():
		if String(rows[i]).length() != w:
			print("WIDTH MISMATCH ", name, " row ", i, " len ", String(rows[i]).length(), " expected ", w)

func _ready() -> void:
	var sets := {"hero": HERO, "arm": ARM}
	for k: String in sets:
		check(k, sets[k])
	var body := Art.image_from_rows(HERO)
	var arm := Art.image_from_rows(ARM)
	var comp := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	comp.fill(Color("3a2a2c"))
	comp.blend_rect(body, Rect2i(0, 0, body.get_width(), body.get_height()), Vector2i(4, 2))
	comp.blend_rect(arm, Rect2i(0, 0, arm.get_width(), arm.get_height()), Vector2i(4 + 12, 2 + 16))
	var old := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	old.fill(Color("3a2a2c"))
	old.blend_rect(Art.icon_image("player"), Rect2i(0, 0, 20, 30), Vector2i(4, 8))
	old.blend_rect(Art.icon_image("player_arm"), Rect2i(0, 0, 8, 17), Vector2i(16, 21))
	var out := Image.create(40 * 2 * 10 + 10, 400, false, Image.FORMAT_RGBA8)
	out.fill(Color("1a0f12"))
	out.blit_rect(up(old, 10), Rect2i(0, 0, 400, 400), Vector2i(0, 0))
	out.blit_rect(up(comp, 10), Rect2i(0, 0, 400, 400), Vector2i(410, 0))
	out.save_png(ProjectSettings.globalize_path("res://tests/_review_art/out/proposal_hero.png"))
	print("PROPOSAL OK")
	get_tree().quit()
