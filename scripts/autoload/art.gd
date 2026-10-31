extends Node
## Art: banco de pixel art. Todo el arte vive como datos versionables:
##  - SPRITES: mapas ASCII dibujados a mano (heroína, iconos).
##  - SHAPES: máscaras de media silueta → monstruos simétricos generados con semilla.
##  - background(): muros de la torre generados por bioma.
## Ver docs/ART_BIBLE.md para la paleta y las reglas.

const PAL := {
	"k": Color("1a0f12"), "d": Color("3d2b2e"), "g": Color("5a4040"), "l": Color("7a5a52"),
	"r": Color("c2321e"), "o": Color("ff6a1a"), "y": Color("ffb43a"), "w": Color("ffe08a"),
	"W": Color("f4e4c8"), "b": Color("4a6a8a"), "c": Color("8ab4d0"), "p": Color("9a5ad0"),
	"G": Color("6ac46a"), "s": Color("e0a080"), "h": Color("6a3020"), "n": Color("8a5030"),
	"m": Color("9aa0a8"), "M": Color("d0d4d8"),
}

## Biomas: claro, medio, oscuro, acento, ojo, muro, brillo
const BIOMES := [
	{"light": Color("8a7a78"), "mid": Color("5a4a4c"), "dark": Color("3a2e32"), "accent": Color("ff6a1a"),
		"eye": Color("ffd040"), "wall": Color("3a2a2c"), "glow": Color("ff7a2a")},
	{"light": Color("a070c0"), "mid": Color("6a4a8a"), "dark": Color("3e2a58"), "accent": Color("7ad040"),
		"eye": Color("c8ff60"), "wall": Color("2c2238"), "glow": Color("a0e040")},
	{"light": Color("c8e0f0"), "mid": Color("7ea8c8"), "dark": Color("4a6a8a"), "accent": Color("e8f8ff"),
		"eye": Color("60d8ff"), "wall": Color("1e2a3a"), "glow": Color("70c8ff")},
]

const SPRITES := {
	"player": [
		"......kkkkkk......",
		".....khhhhhhk.....",
		"....khhhhhhhhk....",
		"....khoohhhhhk....",
		"....kooooooohk....",
		"....khssssssk.....",
		"....khskssksk.....",
		"....khssssssk.....",
		".....kssrssk......",
		"......kkssk.......",
		"....kknWWWnkk.....",
		"...knnnWWWnnnk....",
		"..knnnnnnnnnnnk...",
		"..knskddddddksnk..",
		"..ksskddddddkssk..",
		"..kkkkddddddkknk..",
		"....kdddddddkknk..",
		"....kddddddddknk..",
		"....kddkkkkddknk..",
		"....knnk..knnkknk.",
		"....knnk..knnkMMMk",
		"....knnk..knnkMmmk",
		"...kddkk..kddkkkkk",
		"...kkkk...kkkk....",
	],
	"sword": [
		"..........kk", ".........kMk", "........kMmk", ".......kMmk.", "......kMmk..", ".k...kMmk...",
		".kk.kMmk....", "..kkMmk.....", "...knk......", "..knkkk.....", ".knk..k.....", ".kk.........",
	],
	"shield": [
		"..kkkkkkkk..", ".kMMMMmmmmk.", ".kMccccbbmk.", ".kMccccbbmk.", ".kMccccbbmk.", ".kmccccbbmk.",
		"..kmccbbmk..", "..kmccbbmk..", "...kmcbmk...", "....kmmk....", ".....kk.....", "............",
	],
	"log": [
		"............", "............", "...kkkkkkkk.", "..knnnnhnnnk", ".kyknnnnnhnk", ".kykhnnnnnnk",
		".kyknnnhnnnk", "..knnnnnnnnk", "...kkkkkkkk.", "............", "............", "............",
	],
	"flame": [
		".....k......", "....kok.....", "....kook....", "...kooyok...", "..kooyyok.k.", "..koyywyokok",
		".kooywwyooyk", ".koyywwwyok.", ".koyywwwyok.", "..koywwyok..", "...kooook...", "....kkkk....",
	],
	"hammer": [
		"...kkkkkk...", "..kMMMMmmk..", "..kMmmmmdk..", "..kkkkkkkk..", ".....knk....", ".....knk....",
		".....knk....", ".....knk....", ".....khk....", ".....knk....", ".....khk....", ".....kkk....",
	],
	"sparks": [
		"..y.....w...", ".yoy...wyw..", "..y.....w...", "......o.....", "....y.......", "...ywy....o.",
		"....y...oyo.", ".........o..", "..o.........", ".oyo....y...", "..o....ywy..", "........y...",
	],
	"drop": [
		".....kk.....", "....kcck....", "....kcck....", "...kccbck...", "...kcccbk...", "..kcWccbbk..",
		"..kcWcccbk..", "..kccccbbk..", "..kbcccbbk..", "...kbbbbk...", "....kkkk....", "............",
	],
	"wind": [
		"............", ".......ccc..", "..........c.", ".cccccccccc.", "............", "WWWWWWWW....",
		"........W...", "......WW....", "............", "...cccccccc.", "..........c.", "........cc..",
	],
	"coal": [
		"............", "............", "....kkkk....", "..kkdgdgkk..", ".kdglddgdgk.", ".kgddroddgk.",
		"kdgdoyodgddk", "kddgdrddgdgk", ".kdddgdddk..", "..kkkkkkk...", "............", "............",
	],
	"smoke": [
		"............", ".....gll....", "...glllgg...", "..gllgggl...", "...gggll....", "....glllgg..",
		"..glllggggg.", ".gllggggdd..", "..gggddd....", "....dd......", "............", "............",
	],
	"heart": [
		"............", "..kkk..kkk..", ".kryrkkrrrk.", "krywrrrrrrrk", "kryrrrrrrrrk", "krrrrrrrrrrk",
		".krrrrrrrrk.", "..krrrrrrk..", "...krrrrk...", "....krrk....", ".....kk.....", "............",
	],
	"anvil": [
		"............", "............", "kkkkkkkkkk..", "kMMMMMMMMmk.", ".kmmmmmmmmk.", "..kkkmmmkk..",
		"....kmmk....", "....kmmk....", "...kmmmmk...", "..kmmmmmmk..", "..kkkkkkkk..", "............",
	],
	"bomb": [
		"........y.o.", ".......k.y..", "......k.....", "....kkkk....", "...kddddk...", "..kdlddddk..",
		"..kldddddk..", "..kddddddk..", "..kddddddk..", "...kddddk...", "....kkkk....", "............",
	],
	"feather": [
		"........kkk.", "......kwwyk.", ".....kwwyyk.", "....kwwyyok.", "...kwwyyok..", "...kwyyok...",
		"..kwyook....", "..kyook.....", ".kkok.......", ".kk.........", "k...........", "............",
	],
	"orb": [
		"............", "....kkkk....", "...kyyook...", "..kywyoook..", "..kyyooork..", "..kyooorrk..",
		"..kooorrrk..", "...koorrk...", "....kkkk....", "............", "............", "............",
	],
	"lizard": [
		"............", "........kk..", "..k....kook.", "..kk..kooyk.", "...kkkooook.", "....koooook.",
		"...kooooook.", "..koook.kk..", ".kook.......", "kok.........", "kk..........", "............",
	],
	"sun": [
		"......y.....", "..y...y...y.", "...y..y..y..", "....kkkkk...", "...kwwyyok..", "yyykwyyyokyy",
		"...kyyyook..", "...kyoooork.", "....kkkkk...", "...y..y..y..", "..y...y...y.", "......y.....",
	],
	"candle": [
		"......o.....", ".....oyo....", ".....oyo....", "......k.....", "....kWWWk...", "....kWWck...",
		"....kWWck...", "....kWWck...", "....kWWck...", "...kkkkkkk..", "..kmmmmmmmk.", "...kkkkkkk..",
	],
	"eye": [
		"............", "............", "...kkkkkk...", "..kWWWWWWk..", ".kWWbbbbWWk.", "kWWbkkbbWWWk",
		"kWWbkkbbWWWk", ".kWWbbbbWWk.", "..kWWWWWWk..", "...kkkkkk...", "............", "............",
	],
	"crown": [
		"............", "............", ".k...k...k..", "kyk.kyk.kyk.", "kyykyyykyyk.", "kyyyyryyyyk.",
		"kyyyoooyyyk.", "kooooooooook", "kkkkkkkkkkk.", "............", "............", "............",
	],
	"ember": [
		"............", "....kkkk....", "...koyyok...", "..koywwyok..", "..kyywwyyk..", "..koyyyyok..",
		"..kroyyork..", "...krooork..", "....kkkk....", "............", "............", "............",
	],
	"card": [
		"...kkkkkkk..", "...kWWWWWk..", ".kkkkkkkWk..", ".kWWWWWkWk..", ".kWoooWkWk..", ".kWoyoWkWk..",
		".kWoooWkWk..", ".kWWWWWkWk..", ".kWWWWWkkk..", ".kWWWWWk....", ".kkkkkkk....", "............",
	],
	"furnace": [
		"....kkkk....", "....kddk....", "..kkkddkkk..", ".kgglgglggk.", ".kgkkkkkkgk.", ".kgkoyyokgk.",
		".kgkowwokgk.", ".kgkroorkgk.", ".kgkkkkkkgk.", ".kglgglgglk.", ".kkkkkkkkkk.", "............",
	],
	"skull": [
		"............", "...kkkkkk...", "..kWWWWWWk..", ".kWWWWWWWWk.", ".kWkkWWkkWk.", ".kWkkWWkkWk.",
		".kWWWkkWWWk.", "..kWWWWWWk..", "..kWkWkWk...", "...kkkkkk...", "............", "............",
	],
	"chest": [
		"............", "............", "..kkkkkkkk..", ".knnnnnnnnk.", ".knhnnnnhnk.", "kkkkkyykkkkk",
		"knnnnyynnnnk", "knhnnnnnnhnk", "knnnnnnnnnnk", "kkkkkkkkkkkk", "............", "............",
	],
	"star": [
		"............", ".....kk.....", "....kwyk....", "....kyyk....", "kkkkkyyokkkk", ".kwyyyyyyok.",
		"..kyyyyyok..", "...kyyyok...", "..kyyokyok..", "..kyok.kyok.", ".kkk....kkk.", "............",
	],
	"up": [
		".....kk.....", "....kGGk....", "...kGGGGk...", "..kGGGGGGk..", ".kkkkGGkkkk.", "....kGGk....",
		"....kGGk....", "....kGGk....", "....kGGk....", "....kkkk....", "............", "............",
	],
	"down": [
		"....kkkk....", "....kppk....", "....kppk....", "....kppk....", "....kppk....", ".kkkkppkkkk.",
		"..kppppppk..", "...kppppk...", "....kppk....", ".....kk.....", "............", "............",
	],
	"unknown": [
		"...kkkkk....", "..kWWWWWk...", "..kWkkkWk...", "...k..kWk...", ".....kWk....", "....kWk.....",
		"....kWk.....", "....kkk.....", "....kWk.....", "....kkk.....", "............", "............",
	],
}

## Variantes por recoloreo de un sprite base.
const VARIANTS := {
	"flame_sword": ["sword", {"M": "y", "m": "o"}],
	"heart_gear": ["heart", {"r": "o", "y": "w"}],
	"coin": ["ember", {}],
	"str": ["sword", {"M": "o", "m": "r"}],
	"vuln": ["shield", {"M": "p", "c": "p", "b": "d", "m": "p"}],
	"door": ["chest", {"n": "g", "h": "d", "y": "o"}],
}

## Máscaras de media silueta (se reflejan). X cuerpo · o cuerpo al azar · E ojo · w esclerótica
## m boca · d sombra · a acento · ? acento al azar
const SHAPES := {
	"slime": [
		"........", "........", "......oo", "....oXXX", "...XXXXX", "..XXXXXX",
		".XXXXEXX", ".XXXXXXX", "XXXXXXmm", "XXXXXXXX", "XXXXXXXX", "oXoXXoXX",
	],
	"bat": [
		"a.........", "Xa......a.", "XXo.....Xa", "XXXo...XXX", "XXXXo.XXXX", "oXXXXXXXEX",
		".oXXXXXXXX", "..o.oXXXXm", "......oXXX", ".......oXX", "........o.",
	],
	"golem": [
		"....oXXXX", "...XXXXXX", "...XXXEXX", "...XXXXXX", "...XXmmmm", ".oXXXXXXX", "XXXXXXXXX", "XXXXdXXXX",
		"XXX.XXXXX", "XXX.XXXdX", "XXo.XXXXX", "aa..XXXXX", "....XXX.o", "....XXX..", "...XXXX..", "...XXXX..",
	],
	"knight": [
		"......aa", ".....aaX", "....XXXX", "...XXXXX", "...XXEEE", "...XXXXX", "....XXXX", ".XXXXXXX", "XXXdXXXX",
		"XXXdXXXX", "XX.dXXXX", "XX.XXXXX", "a..XXXXX", "a..XXXdd", "...XXX..", "...XXX..", "...XXX..", "..XXXX..",
	],
	"wraith": [
		".....XXX", "....XXXX", "...XXXXX", "..XXXdXX", "..XXddEd", "..XXdddd", ".oXXXddd", "oXXXXXXX",
		"XXXXXXXX", ".XXXXXXX", "oXXXXXXX", ".XXXXXXX", "..XXXXXX", "..oXXoXX", "...o.X.o", ".....o..",
	],
	"eye": [
		"....oXX", "..oXXXX", ".XXXXXX", ".XXwwww", "XXwwwww", "XXwwwEE", "XXwwwEE",
		"XXwwwww", ".XXwwww", ".XXXXXX", "..oXXXX", "..a.a.a", ".a..a.a",
	],
	"crawler": [
		"..........", "......oXXX", "....XXXXXX", "..oXXXXXEX", ".XXXXXXXXX",
		"XXXXXXXXmm", "aXoXXXXXXX", "a.a.XXoXXX", "..a.a..a.a", ".a..a..a..",
	],
	"imp": [
		"..a....", "..aa...", "...aXXX", "...XXXX", "...XEXX", "...XXmm", "....XXX", ".a.XXXX",
		"aaXXXXX", "a.oXXXX", "...XXXX", "...XX.X", "...XX..", "..XXX..", "..aa...",
	],
	"hound": [
		".a.......", ".aa......", "..XXX....", "..XEXX...", "..XXXXX..", "...mXXXXX",
		"....XXXXX", "...XXXXXX", "...XX.XXX", "...XX..XX", "...XX...o", "..aa.....",
	],
	"boss_king": [
		"....a..a..a.", "....aa.aa.aa", "....aaaaaaaa", "....XXXXXXXX", "...XXXXXXXXX", "...XXXXXEXXX",
		"...XXXXXXXXX", "...XXXmmmmmm", "....XXXXXXXX", "..oXXXXXXXXX", ".XXXXXXXXXXX", "XXXXXXdXXXXX",
		"XXXXXXdXXXXX", "XXXX.XdXXXXX", "XXXX.XXXXaXX", "aaa..XXXXaXX", "aaa..XXXXXXX", ".....XXXXXXX",
		".....XXXX..X", ".....XXXX...", "....XXXXX...", "....XXXXX...",
	],
	"boss_queen": [
		"......a....a", ".....aaa..aa", "......aaaaaa", ".......XXXXX", "......XXXXXX", "......XXEXXX",
		"......XXXXmm", ".......XXXXX", "...a...XXXXX", "..aXXXXXXXXX", ".aXXXXXXXXXX", "aXXXX.XXXXXX",
		"a.XX..XXdXXX", "..X...XXdXXX", "......XXXXXX", ".....XXXXXXX", "....XXXXXXXX", "...XXXXXXXXX",
		"..XXXXXXXXXX", ".oXXXXXXXXXX", "oXXXoXXXoXXX", "o.o..o..o.o.",
	],
	"boss_heart": [
		"............", "..aa.....a..", "...XXXX..aXX", "..XXXXXX.XXX", ".XXXXXXXXXXX", "aXXXXXXXXXXX",
		".XXXXXXXwwww", "aXXXXXXwwwEE", ".XXXXXXwwwEE", "aXXXXXXXwwww", ".XXXXXXXXXXX", "..XXXXXXXXXX",
		"..aXXXXXXXXX", "...XXXXXXXXX", "....XXXXXXXX", ".....XXXXXXX", "......aXXXXX", ".......XXXXX",
		"........XXXX", ".........aXX", "..........XX", "...........a",
	],
}

var _cache := {}


func has_icon(id: String) -> bool:
	return SPRITES.has(id) or VARIANTS.has(id)


func has_shape(id: String) -> bool:
	return SHAPES.has(id)


func icon(id: String) -> Texture2D:
	var key := "i:" + id
	if _cache.has(key):
		return _cache[key]
	var img: Image
	if VARIANTS.has(id):
		var v: Array = VARIANTS[id]
		img = image_from_rows(SPRITES[v[0]], v[1])
	elif SPRITES.has(id):
		img = image_from_rows(SPRITES[id])
	else:
		img = image_from_rows(SPRITES["unknown"])
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


func player() -> Texture2D:
	return icon("player")


static func image_from_rows(rows: Array, remap: Dictionary = {}) -> Image:
	var h := rows.size()
	var w := String(rows[0]).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in mini(w, row.length()):
			var ch := row[x]
			if remap.has(ch):
				ch = remap[ch]
			if ch != "." and PAL.has(ch):
				img.set_pixel(x, y, PAL[ch])
	return img


func biome_colors(biome: int, cycle: int = 0) -> Dictionary:
	var b: Dictionary = BIOMES[biome % BIOMES.size()]
	if cycle == 0:
		return b
	var out := {}
	for k: String in b:
		var c: Color = b[k]
		out[k] = Color.from_hsv(fposmod(c.h + 0.29 * cycle, 1.0), minf(1.0, c.s + 0.1), c.v)
	return out


## Monstruo simétrico generado por semilla a partir de una máscara de forma.
func monster(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key)
	var half: Array = SHAPES.get(shape, SHAPES["slime"])
	var hw := String(half[0]).length()
	var h := half.size()
	var w := hw * 2
	# Celdas: "" vacío o tipo de píxel
	var cells: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		row.fill("")
		cells.append(row)
	for y in h:
		var src: String = half[y]
		for x in hw:
			var ch := src[x]
			var v := ""
			match ch:
				"X": v = "body"
				"o": v = "body" if rng.randf() < 0.55 else ""
				"E": v = "eye"
				"w": v = "sclera"
				"m": v = "mouth"
				"d": v = "shade"
				"a": v = "accent"
				"?": v = "accent" if rng.randf() < 0.5 else ""
			# Pequeñas mutaciones en el cuerpo para variedad por semilla.
			if v == "body" and rng.randf() < 0.08:
				v = "shade"
			cells[y][x] = v
			cells[y][w - 1 - x] = v
	var pal := biome_colors(biome, cycle)
	var outline: Color = PAL["k"]
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var v: String = cells[y][x]
			if v == "":
				continue
			var col: Color
			match v:
				"eye": col = pal["eye"]
				"sclera": col = Color("f4e4c8")
				"mouth": col = outline
				"shade": col = pal["dark"]
				"accent": col = pal["accent"]
				_:
					var lit := (1.0 - float(y) / h) * 0.55 + (1.0 - float(x) / w) * 0.3 + rng.randf() * 0.2
					var below_empty: bool = y + 1 >= h or cells[y + 1][x] == ""
					if below_empty:
						lit -= 0.35
					col = pal["light"] if lit > 0.68 else (pal["mid"] if lit > 0.32 else pal["dark"])
			img.set_pixel(x + 1, y + 1, col)
	# Contorno de 1 px.
	var out_img := img.duplicate() as Image
	for y in h + 2:
		for x in w + 2:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w + 2 and ny < h + 2 and img.get_pixel(nx, ny).a > 0.0:
					out_img.set_pixel(x, y, outline)
					break
	var t := ImageTexture.create_from_image(out_img)
	_cache[key] = t
	return t


## Muro interior de la torre (320×180) para combate y menús.
func background(biome: int, seed_value: int, cycle: int = 0) -> Texture2D:
	var key := "bg:%d:%d:%d" % [biome, seed_value, cycle]
	if _cache.has(key):
		return _cache[key]
	var pal := biome_colors(biome, cycle)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + biome
	var W := 320
	var H := 180
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var wall: Color = pal["wall"]
	var mortar := wall.darkened(0.45)
	var floor_y := 118
	# Ladrillos
	for by in range(0, floor_y, 8):
		var row := by / 8
		var off := 0 if row % 2 == 0 else 8
		for bx in range(-off, W, 16):
			var tone := wall.lightened(rng.randf_range(-0.08, 0.12))
			if rng.randf() < 0.05:
				tone = wall.darkened(0.3)
			for y in range(by, mini(by + 8, floor_y)):
				for x in range(maxi(bx, 0), mini(bx + 16, W)):
					var edge := y == by or x == bx
					var c := mortar if edge else tone
					if not edge and y == by + 1:
						c = c.lightened(0.08)
					img.set_pixel(x, y, c)
	# Ventanas arqueadas con luz del acto
	var glow: Color = pal["glow"]
	for wx: int in [64, 248]:
		for y in range(28, 84):
			for x in range(wx - 12, wx + 12):
				var dx := x - wx
				var top := 40 - sqrt(maxf(0.0, 144.0 - dx * dx))
				if y >= top:
					var t := float(y - 28) / 56.0
					img.set_pixel(x, y, Color("120a0e").lerp(glow.darkened(0.55), 0.35 * (1.0 - t)))
		for y in range(84, 88):
			for x in range(wx - 14, wx + 14):
				img.set_pixel(x, y, wall.lightened(0.15))
	# Suelo
	for y in range(floor_y, H):
		for x in W:
			var tile := ((x / 24) + (y - floor_y) / 10) % 2 == 0
			var c := wall.lightened(0.18 if tile else 0.1)
			if y == floor_y:
				c = wall.lightened(0.35)
			elif (x % 24 == 0) or ((y - floor_y) % 10 == 0):
				c = mortar
			img.set_pixel(x, y, c)
	# Viñeta + luz cálida desde abajo
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			var dx := (float(x) - W * 0.5) / (W * 0.5)
			var dy := (float(y) - H * 0.55) / (H * 0.55)
			var vig := clampf(1.0 - (dx * dx + dy * dy) * 0.45, 0.35, 1.0)
			c = c * vig
			c.a = 1.0
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t
