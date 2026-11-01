extends Node
## Art: banco de pixel art. Todo el arte vive como datos versionables (sin binarios):
##  - SPRITES: mapas ASCII a mano (heroína 24×36 + brazo 10×20, iconos 12×12).
##  - BASES: monstruos dibujados a mano mirando a la izquierda; SHAPES: medias máscaras para
##    criaturas frontales. Ambos se sombrean (campo de distancia + luz cenital + luz de fuego lateral)
##    y varían por semilla (grietas emisivas, piezas opcionales, ligera deriva de tono).
##  - card_frame() / card_art(): marco 75×105 e ilustración 60×30, ambos a ×2 (misma rejilla).
##  - background(): composición distinta por acto; background_near(): capa de primer plano.
##  - forge_sprite(), furnace_small(), bonfire(), event_art(), door_art(), logo().
## REGLA: todo el mundo se dibuja a ×4 (UI.PX) y la interfaz a ×2. Ver docs/ART_BIBLE.md.

const PAL := {
	"k": Color("1a0f12"), "d": Color("3d2b2e"), "g": Color("5a4040"), "l": Color("7a5a52"),
	"r": Color("c2321e"), "R": Color("7a1a16"), "o": Color("ff6a1a"), "y": Color("ffb43a"), "w": Color("ffe08a"),
	"Y": Color("fff4c8"), "W": Color("f4e4c8"), "b": Color("4a6a8a"), "B": Color("2a3a5a"), "c": Color("8ab4d0"),
	"p": Color("9a5ad0"), "P": Color("d0a8ff"), "G": Color("6ac46a"), "e": Color("2e6a3a"), "s": Color("e0a080"),
	"S": Color("b07050"), "h": Color("6a3020"), "n": Color("8a5030"), "m": Color("9aa0a8"), "M": Color("d0d4d8"),
}

## Biomas: rampa de monstruo (hi→deep, con desplazamiento de tono), acento, ojo, muro, mortero, suelo, brillo.
const BIOMES := [
	{"hi": Color("ccb09a"), "light": Color("a08270"), "mid": Color("6e5450"), "dark": Color("473338"), "deep": Color("2a1c26"),
		"accent": Color("ff6a1a"), "eye": Color("ffd040"), "wall": Color("2e2226"), "mortar": Color("1c1216"),
		"floor": Color("362a2c"), "glow": Color("ff7a2a"), "banner": Color("8a2a1a")},
	{"hi": Color("d4acee"), "light": Color("a27aca"), "mid": Color("6e4c96"), "dark": Color("46306a"), "deep": Color("281a40"),
		"accent": Color("8ae048"), "eye": Color("d8ff70"), "wall": Color("241e2c"), "mortar": Color("14101a"),
		"floor": Color("2e2836"), "glow": Color("a0e040"), "banner": Color("3a6a2a")},
	{"hi": Color("f2faff"), "light": Color("b6d4ec"), "mid": Color("7a9ec6"), "dark": Color("4a6896"), "deep": Color("283a64"),
		"accent": Color("e8f8ff"), "eye": Color("ffffff"), "wall": Color("1e2a3c"), "mortar": Color("101826"),
		"floor": Color("2a3648"), "glow": Color("70c8ff"), "banner": Color("2a4a7a")},
]

const SPRITES := {
	# Heroína 24×36 sin el brazo delantero (se compone por pose; ver player_pose()).
	"player": [
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
	],
	# Brazo delantero con martillo. Hombro (pivote) en (3.5, 1.5); se pega al cuerpo en (12, 16).
	"player_arm": [
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
		"............", "............", ".........kk.", ".......kkyok", ".....kknnkyk", "...kknnhhnkk", ".kknnhhnnhk.", "kyokhnnhhk..", "kywkkhnnk...", "kook.kkk....", ".kk.........", "............"
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
		"............", "....kkk.....", "..kkdgdkk...", ".kdglgddgk..", ".kglddroddk.", "kdgdroyrdgdk", "kgddryyodddk", "kddgdrodgddk", ".kdddddddgk.", "..kkddddkk..", "....kkkk....", "............"
	],
	"smoke": [
		"............", ".....kkk....", "....kllgk...", "..kkllggk...", ".kllgggk....", ".klgggkkkk..", "..kggklllgk.", "...kkllgggk.", "..kllggggk..", ".klggddkk...", "..kkkkk.....", "............"
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
		"............", "............", "..........k.", "..kkk....kok", ".kyyokkkkkok", "kWkyoooooook", "kyyoooRooook", ".kkookkkookk", "..kok..kok..", "..kkk..kkk..", "............", "............"
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
	# --- v0.2 --------------------------------------------------------------
	"axe": [
		"..kkk.......", ".kMMMk......", "kMMmmMk.....", "kMmmmmhk....", "kMmmmkhnk...", ".kmmk.khnk..",
		"..kk...khnk.", "........khnk", ".........khk", "..........k.", "............", "............",
	],
	"wall": [
		"............", "kkkkkkkkkkkk", "kMmmkMmmmkMk", "kmggkmgggkmk", "kkkkkkkkkkkk", "kMkMmmkMmmmk",
		"kmkmggkmgggk", "kkkkkkkkkkkk", "kMmmkMmmmkMk", "kmggkmgggkmk", "kkkkkkkkkkkk", "............",
	],
	"slag": [
		"............", "....kkkk....", "...kGGGGk...", "..kGwGGGGk..", "..kGGGGGek..", "..kGGGGeek..",
		"...kGGeek...", "...kGeek....", "....kGk.....", "....kGk.....", ".....k......", "............",
	],
	"twin_swords": [
		"kk........kk", "kMk......kMk", ".kMk....kMk.", "..kMk..kMk..", "...kMkkMk...", "....kMMk....",
		"....kMMk....", "...kMkkMk...", "..knk..knk..", ".knk....knk.", "kyk......kyk", "kk........kk",
	],
	"fan": [
		"............", "..kkkkkkkk..", ".koyoyoyoyk.", "kyoyoyoyoyok", "koyoyoyoyoyk", ".koyoyoyoyk.",
		"..kkoyoyokk.", "....kkykk...", ".....khk....", ".....khk....", ".....kkk....", "............",
	],
	"fire_wall": [
		"..o....o....", ".oyo..oyo..o", ".oyyo.oyyooy", "oyywyooyywyo", "kkkkkkkkkkkk", "kMmmkMmmmkMk",
		"kmggkmgggkmk", "kkkkkkkkkkkk", "kMkMmmkMmmmk", "kmkmggkmgggk", "kkkkkkkkkkkk", "............",
	],
	"crucible": [
		"............", "............", "kk........kk", "kmkkkkkkkkmk", "kmkyywwyykmk", ".kmooyyoomk.",
		".kmmmmmmmmk.", ".kmggggggmk.", "..kmggggmk..", "...kmmmmk...", "....kkkk....", "............",
	],
	"bell": [
		".....kk.....", "....kyyk....", "...kywyyk...", "...kyyyyk...", "..kywyyyok..", "..kyyyyyok..",
		".kywyyyyyok.", ".kyyyyyyyok.", "kkkkkkkkkkkk", "kooooooooook", "kkkkkkkkkkkk", ".....kk.....",
	],
	"phoenix": [
		"y....kk....y", "oy..kook..yo", "ooy.kwok.yoo", "roooyooyooor", ".rooyyyyoor.", "..rooyyoor..",
		"...rkooork..", "....koyk....", "....kook....", "...koyyok...", "..koy..yok..", "..ko....ok..",
	],
	"armor": [
		"............", ".kk......kk.", "kMmk.kk.kmMk", "kMmmkMMkmmMk", ".kMmmMMmmMk.", ".kMmmmmmmmk.",
		".kMmmMMmmmk.", ".kMmmmmmmmk.", "..kMmmmmmk..", "..kmmyymmk..", "...kmmmmk...", "....kkkk....",
	],
	"poker": [
		"..........kk", ".........kok", "........koyk", ".......kook.", "......kmk...", ".....kmk....",
		"....kmk.....", "...kmk......", "..kmk.......", ".khk........", "khk.........", "kk..........",
	],
	"bonfire": [
		"....k.......", "...kok..k...", "..koyok.kok.", "..koyyokoyk.", ".koyywyyyyok", ".koywwwyyyok",
		".kooyywyyook", "..koooyyook.", "khnkkkkkknhk", "knnhnnnnhnnk", ".kkhnnnnhkk.", "...kkkkkk...",
	],
	"volcano": [
		".....oy.....", "....oyo.o...", "...o.ko.....", "....kook....", "...kkookk...", "...kgoogk...",
		"..kggrrggk..", "..kgggrggk..", ".kgggggrggk.", ".kgggdggrgk.", "kggddgggdggk", "kkkkkkkkkkkk",
	],
	"blood_flame": [
		".....k......", "....krk.....", "....krrk....", "...krrRrk...", "..krrRRrk.k.", "..krRRoRrkrk",
		".krrRooRrrRk", ".krRRoooRrk.", ".krRRoooRrk.", "..krRooRrk..", "...krrrrk...", "....kkkk....",
	],
	"goblet": [
		"............", ".kkkkkkkkkk.", ".kyrrrrrryk.", ".kyrrrrrryk.", "..kyrrrryk..", "...kyyyyk...",
		"....kyyk....", ".....yk.....", ".....yk.....", "....kyyk....", "...kyyyyk...", "...kkkkkk...",
	],
	"lung": [
		"............", ".....kk.....", ".....kmk....", "..kkkkmkkk..", ".krrrkmkrrk.", "krrrrkmkrrrk",
		"krswrkkkrswk", "krrrrk.krrrk", "krrrrk.krrrk", ".krrk...krk.", "..kk.....k..", "............",
	],
	"box": [
		"............", "............", "..kkkkkkkk..", ".knnnnnnnnk.", "kkkkkkkkkkkk", "knnnnyynnnnk",
		"knhnnyynnhnk", "knnnnnnnnnnk", "knhnnnnnnhnk", "kkkkkkkkkkkk", "............", "............",
	],
	"twin_shields": [
		"............", ".kkkkkk.....", ".kMccbk.....", ".kMcckkkkkk.", ".kMcckMccbk.", "..kcbkMccbk.",
		"..kcbkMccbk.", "...kkkMccbk.", "......kcbk..", "......kcbk..", ".......kk...", "............",
	],
	"weight": [
		"............", "....kkkk....", "...kk..kk...", "...k....k...", "..kkkkkkkk..", ".kgmmmmmmgk.",
		"kgmMmmmmmmgk", "kgmmmmmmmmgk", "kgmmmmmmmmgk", ".kgmmmmmmgk.", "..kkkkkkkk..", "............",
	],
	"greatsword": [
		"..........kk", ".........kMk", "........kMmk", ".......kMmk.", "......kMmk..", ".....kMmk...",
		"..k.kMmk....", "..kkMmk.....", "...kyk......", "..kykkk.....", ".kyk........", "kkk.........",
	],
	"spikes": [
		"............", "............", "..k...k...k.", ".kMk.kMk.kMk", ".kMk.kMk.kMk", "kMmmkMmmkMmk",
		"kMmmkMmmkMmk", "kkkkkkkkkkkk", "kggggggggggk", "kkkkkkkkkkkk", "............", "............",
	],
	"fortress": [
		"k.k.k..k.k.k", "kkkkk..kkkkk", "kmmmk..kmmmk", "kmgmkkkkmgmk", "kmmmmmmmmmmk", "kmgmmmmmmgmk",
		"kmmmmkkmmmmk", "kmmmk..kmmmk", "kmgmk..kmgmk", "kmmmk..kmmmk", "kkkkkkkkkkkk", "............",
	],
	"brand": [
		"............", ".kkkkk......", ".koyok......", ".kywyk......", ".koyok......", ".kkokk......",
		"...kmk......", "....kmk.....", ".....kmk....", "......khk...", ".......khk..", "........kk..",
	],
	"cloak": [
		"....kkkk....", "...kgggdk...", "..kggkkgdk..", "..kgk..kdk..", ".kggk..kgdk.", ".kggkkkkgdk.",
		".kgggggggdk.", "kggggggggddk", "kggggggggddk", "kgggggggdddk", "kgkgkgkgkdkk", "k.k.k.k.k.k.",
	],
	"moon": [
		"............", "....kkkk....", "...kWWWkk...", "..kWWWk.....", ".kWWWk......", ".kWWWk......",
		".kWWWk......", ".kWWWWk.....", "..kWWWWkkk..", "...kWWWWWk..", "....kkkkk...", "............",
	],
	"brazier": [
		"...o..o.....", "..oyo.oyo...", "..oyyoyyo...", ".koywwwyok..", "kkkkkkkkkkk.", "kmMMMMMMMmk.",
		".kmmmmmmmk..", "..kmmmmmk...", "....kmk.....", "...kmmmk....", "..kmmmmmk...", "..kkkkkkk...",
	],
	"gear": [
		"....k..k....", "...kmkkmk...", ".kkmmmmmmkk.", ".kmmmkkmmmk.", "..kmk..kmk..", "kkmk....kmkk",
		"kmmk....kmmk", "..kmk..kmk..", ".kmmmkkmmmk.", ".kkmmmmmmkk.", "...kmkkmk...", "....k..k....",
	],
	"book": [
		"............", ".kkkkkkkkk..", "kRrrrrrrrrk.", "kRryyyyyrrk.", "kRrrrrrrrrk.", "kRrrryrrrrk.",
		"kRrrrrrrrrk.", "kRrrrrrrrrk.", "kRWWWWWWWWk.", "kRkkkkkkkkk.", "kk..........", "............",
	],
	"cannon": [
		"............", "............", "......kkkkk.", "...kkkmmmmMk", ".kkmmmmmmmmk", "kmmmmmmmkkk.",
		"kmmmmkkk....", ".kkkhnhk....", "...khkkhk...", "..khnk.knk..", "..kkk..kkk..", "............",
	],
	"flask": [
		"....kkkk....", ".....kk.....", ".....kk.....", "....kcck....", "...kcWcck...", "..kGGGGGGk..",
		".kGwGGGGGGk.", ".kGGGGGGGGk.", ".kGGGGGGeGk.", "..kGGGGeek..", "...kkkkkk...", "............",
	],
	"ingot": [
		"............", "............", "............", "...kkkkkkk..", "..kwyyyyyyk.", ".kwyyyyyyyok",
		"kkkkkkkkkkok", "kyyyyyyyyyok", "kooooooooook", "kkkkkkkkkkkk", "............", "............",
	],
	"gem": [
		"............", "...kkkkkk...", "..kPWPPppk..", ".kPWPPPpppk.", "kkkkkkkkkkkk", ".kPPPPpppk..",
		"..kPPPppk...", "...kPPpk....", "....kppk....", ".....kk.....", "............", "............",
	],
	"potion": [
		"....kkkk....", "....kWWk....", ".....kk.....", "....kWWk....", "...krrrrk...", "..krwrrrrk..",
		"..krrrrrrk..", "..krrrrrRk..", "..krrrrRRk..", "...krRRRk...", "....kkkk....", "............",
	],
	"snowflake": [
		"............", ".....W......", "..W..c..W...", "...c.c.c....", "....cWc.....", "WccccWccccW.",
		"....cWc.....", "...c.c.c....", "..W..c..W...", ".....W......", "............", "............",
	],
	"ring": [
		"............", ".....kk.....", "....kook....", "....krrk....", "...kkkkkk...", "..kyykkyyk..",
		".kyk....kok.", ".kyk....kok.", ".kyk....kok.", "..kyykkyok..", "...kkkkkk...", "............",
	],
	"lens": [
		"............", "..kkkkk.....", ".kcWcccck...", "kcWccccbbk..", "kcccccccbk..", "kccccccbbk..",
		"kbcccccbbk..", ".kbbbbbbk...", "..kkkkkkyk..", ".......kyyk.", "........kyyk", ".........kk.",
	],
	"whetstone": [
		"............", "............", "............", "..kkkkkkkkk.", ".kMMMMMMMMmk", "kmmmmmmmmmgk",
		"kggggggggggk", "kkkkkkkkkkk.", "............", "............", "............", "............",
	],
	"bone": [
		"............", "............", ".kk......kk.", "kWWk....kWWk", "kWWWkkkkWWWk", ".kWWWWWWWWk.",
		"kWWWkkkkWWWk", "kWWk....kWWk", ".kk......kk.", "............", "............", "............",
	],
	"tongs": [
		"kk......kk..", "kmk....kmk..", ".kmk..kmk...", "..kmkkmk....", "...kmmk.....", "....kk......",
		"...kmmk.....", "..kmkkmk....", ".khk..khk...", "khk....khk..", "kk......kk..", "............",
	],
	"mask": [
		"............", "..kkkkkkkk..", ".krrrrrrrrk.", "krrkkrrkkrrk", "krkyykkyykrk", "krrkkrrkkrrk",
		"krrrrrrrrrrk", ".krrrkkrrrk.", ".krrkoykrrk.", "..krrkkrrk..", "...kkkkkk...", "............",
	],
	"key": [
		"............", "..kkk.......", ".kyyyk......", "kyk.kyk.....", "kyk.kyk.....", ".kyyykkkkkk.",
		"..kkkyyyyyyk", "......kykyk.", "......kk.k..", "............", "............", "............",
	],
	"scroll": [
		"............", ".kkkkkkkkk..", "kWWWWWWWWWk.", ".kWWWWWWWWk.", ".kWllllllWk.", ".kWWWWWWWWk.",
		".kWlllllWWk.", ".kWWWWWWWWk.", ".kWllllWWWk.", "kWWWWWWWWWk.", ".kkkkkkkkk..", "............",
	],
	"drum": [
		"............", "..k......k..", "...k....k...", "..kkkkkkkk..", ".kWWWWWWWWk.", "kRrrrrrrrrRk",
		"kRyrRyrRyrRk", "kRrRyrRyrRrk", "kRrrrrrrrrRk", ".kWWWWWWWWk.", "..kkkkkkkk..", "............",
	],
	"lantern": [
		".....kk.....", "....k..k....", "...kkkkkk...", "..kmmmmmmk..", "..kmyyyymk..", "..kmywwymk..",
		"..kmyoyymk..", "..kmyyyymk..", "..kmmmmmmk..", "...kkkkkk...", "............", "............",
	],
	"map": [
		"............", "kkkkkkkkkkk.", "kWlWWWlWWWk.", "kWWlWWWrWWk.", "kWWWlWrWrWk.", "kWWWWlWWrWk.",
		"kWlWWWlWWWk.", "kWWlWWWlWWk.", "kWWWlWWWlWk.", "kkkkkkkkkkk.", "............", "............",
	],
	"kettle": [
		"............", "....kkkk....", "...k....k...", "..kkkkkkkk..", ".kmMMMMmmmk.", "kkmmmmmmmmkk",
		"kkmmmmmmmmgk", ".kmmmmmmmgk.", ".kgmmmmmggk.", "..kkkkkkkk..", "..k......k..", "............",
	],
	"jar": [
		"............", "...kkkkkk...", "...khhhhk...", "..kkkkkkkk..", ".kdgddddddk.", ".kdgddddddk.",
		".kdgdlldddk.", ".kdgdllddddk", ".kdgddddddk.", ".kddddddddk.", "..kkkkkkkk..", "............",
	],
	"fang": [
		"............", ".kkkkkkkkkk.", "kRrrrrrrrrRk", "kkWkkWWkkWkk", ".kWk.kWk.kWk", ".kWk.kWk.kk.", "..kk.kWk....", ".....kWk....", "......k.....", "............", "............", "............"
	],
	"coin": [
		"....kkkk....", "..kkyyyykk..", ".kywwyyyyok.", ".kwykkkkyok.", "kyyk.yo.kyok", "kyyky..ykyok", "kyykoyyokyok", "kyyk.yo.kook", ".kyykkkkook.", ".kooyyyoook.", "..kkoooork..", "....kkkk...."
	],
}

## Variantes por recoloreo de un sprite base.
const VARIANTS := {
	"flame_sword": ["sword", {"M": "y", "m": "o"}],
	"heart_gear": ["heart", {"r": "o", "y": "w"}],
	"str": ["sword", {"M": "o", "m": "r"}],
	"vuln": ["shield", {"M": "p", "c": "p", "b": "d", "m": "p"}],
	"door": ["chest", {"n": "g", "h": "d", "y": "o"}],
	"shield_bash": ["shield", {"c": "o", "b": "r", "M": "y"}],
	"parry": ["sword", {"M": "c", "m": "b"}],
	"sledge": ["hammer", {"M": "g", "m": "d"}],
	"breath": ["smoke", {"g": "o", "l": "y", "d": "r"}],
	"corona": ["sun", {"y": "o", "w": "y"}],
	"star_sword": ["sword", {"M": "P", "m": "p"}],
	"wet_ash": ["smoke", {"g": "b", "l": "c", "d": "B"}],
	"vial": ["potion", {"r": "p", "R": "B", "w": "P"}],
	"blast": ["furnace", {"g": "m", "l": "M"}],
	"golem": ["skull", {"W": "g"}],
	"regen": ["heart", {"r": "G", "y": "w"}],
	"choke": ["smoke", {"g": "d", "l": "g"}],
}

## Bases dibujadas a mano (miran a la IZQUIERDA, hacia la heroína).
## X cuerpo (sombreado automático) · 1 2 3 4 tonos forzados (claro→profundo) · k línea/contorno
## a acento emisivo · ? acento opcional (semilla) · o cuerpo opcional (semilla) · E ojo · W hueso/dientes
## m boca · M N metal claro/medio · H h madera clara/oscura · 3 también marca grietas que pueden brillar.
const BASES := {
	"golem": [
		".........kkkkkk...........",
		"........k111111k..........",
		".......k11XXXXX1k.........",
		".......k1EXXEXXXk.........",
		".......k1XaaaaX3k.........",
		"...kkkkk1XXXXX3kkkkk......",
		"..k1111Xk2XXX2k21113k.....",
		".k11XXXXXk333kXXXXX33k....",
		"k11XXXXXXXXXXXXXXXXX33k...",
		"k1XXX?XXXXXXXXXXX?XX333k..",
		"k1XXX??XXXXXXXXX??XX3k3k..",
		"kXXXXX?XXXXXXXXXX?XX3k3k..",
		".kXXXXXXXXXXXXXXXXX33k3k..",
		".k3XXXkXXXXXXXXXkXX3k33k..",
		"..k33k.kXXX33XXXk.k3k.k33k",
		"..k33k.kXXXXX33k..kk..k3ak",
		".k1XX3kkXXkkkX33k....kaak.",
		"k11XX3k.kXXk.kX33k....kk..",
		"k1XX33k.kXXk.kX33k........",
		"kXX333k.kX3k.k333k........",
		".kaaak..k33k.k333k........",
		"..kkk..kk33k.k333kk.......",
		".......k3333k.k33333k.....",
		".......kkkkkk.kkkkkkk.....",
	],
	"knight": [
		"........kkkkk.........",
		".......k11111k........",
		"......k11XXXX3k.......",
		"......k1kkkkkXk.......",
		"......k1kEEkkXk.......",
		"......k1XXXXX3k.......",
		"....kkkk1XXX3kkkk.....",
		"...k111kkXXXkk1113k...",
		"..k11XXXkXXXkXXXX33k..",
		"..k1XXXk1XXXXkXXXX3k..",
		".kXXXk.kXXaXXk.kXXX3k.",
		".kXXk..kXaaaXk..kXX3k.",
		".kMk...kXXaXXk..kX33k.",
		".kMk...k33333k..kX33k.",
		".kMk..kXXXXkXXk.k333k.",
		".kMk..k1XXkkXXk..kkk..",
		".kMk..kXXXk.kXXk......",
		".kMk..kXXk..kXXk......",
		".kMk..kXXk..kXXk......",
		".kNk..kX3k..kX3k......",
		"..k..k1XXk..kXXXk.....",
		".....kXX3k..k3XXXk....",
		".....kkkkk..kkkkkk....",
	],
	"hound": [
		"..kk......................",
		".k1k.k....................",
		".k21kk1k..................",
		"k1112221kk................",
		"k12E22221kkkkkkkkkkk......",
		"kWW222222111111111221k....",
		".kkk2223322?22?222222k1k..",
		"..kWWk33322222222233332k1k",
		"...kk.k3332222223333332k2k",
		"......k33k33333333k3333kk.",
		".....k33k.k333kkkk.k333k..",
		".....k3k...k33k.....k33k..",
		"....k3k.....k3k......k3k..",
		"...kaak....kaak.....kaak..",
		"...kkk.....kkk......kkk...",
	],
	"bird": [
		"......kkkk.........",
		"....kk1111k........",
		"...k1112221k.......",
		"..k1E222222k.......",
		"kaak22222221k......",
		".kkk22222223k......",
		"....k222222233k....",
		"...k1122222233kk...",
		"..k11122222233a3k..",
		"..k1112222223aa33k.",
		"...k122222233a3333k",
		"....k2222333aak333k",
		".....kk33333k..kk3k",
		".......kk3k3k....kk",
		".......k3k.k3k.....",
		"......kaak.kaak....",
	],
	"serpent": [
		"....kkkk................",
		"...kXXXXk...............",
		"..kXEXXXXk..............",
		".kXXXXXXXXk.............",
		"kWkWkXXXXXXk............",
		".k.k.kXXXXXk............",
		"......kX?XXk............",
		".......kXXXXk...........",
		"........kX?Xk...........",
		"........kXXXXk..........",
		".........kX?Xk..........",
		".........kXXXXk.........",
		"......kkkkXXXXk.........",
		"....kkXXXXXXXXk.........",
		"...kXXXXXX3XXXXkk.......",
		"..kXXXkkkkk3XXXXXk......",
		"..kXXk.....k3XXXXk......",
		"..kXXk......kXXXXk..kk..",
		"..kXXXkkkkkkXXXXXk.kXk..",
		"...kXX?XXX?XXXXXk..kXk..",
		"..kkXXXXXXXXXXXkkkkXXk..",
		".kXXX33XXXXXXXXXXXXXk...",
		"kXXX3XXXXXXXXXXXXXXk....",
		"kXXXXXXXX3333XXXXkk.....",
		".kkXXXXXXXXXXXkkk.......",
		"...kkkkkkkkkkk..........",
	],
	"imp": [
		"..k.......k.....",
		".kak.....kak....",
		".kak.....kak....",
		"..kakkkkkak.....",
		"..kXXXXXXXk.....",
		".kXEXXXEXXXk....",
		".kXXXXXXXXXk....",
		".kXmWmWmXXk.....",
		"..kXXXXXXk..kk..",
		".kkXXXXXXXkkXXk.",
		"kXkXXXXXXXXkXXXk",
		"kXkXX?XXXkXXkXXk",
		".kkXXXXXXk.kXXk.",
		"...kXXXXXk..kk..",
		"...kX3XX3k...k..",
		"...kXXkXXXk..ak.",
		"..kXXk.kXXk.ka..",
		"..kXk...kXkka...",
		".kXXk...kXXk....",
		".kkkk...kkkk....",
	],
	"crawler": [
		"...kkkk.....................",
		"..kXXXXkkkk.kkkk.kkkk.......",
		".kXEXXXXXXXkXXXXkXXXXkkkk...",
		"kXXXXXXXXXXXXXXXXXXXXXXXXk..",
		"kWkWXXXXXX3XXXX3XXXX3XXXXXk.",
		".k.kXXXXX?3?XX?3?XX?3?XXXXXk",
		"...kXXXXX3XXXX3XXXX3XXXXXXk.",
		"....kkXkkkXkkkXkkkXkkkXkkk..",
		"....kXk.kXk.kXk.kXk.kXk.....",
		"...kXk.kXk.kXk.kXk.kXk......",
		"...kak.kak.kak.kak.kak......",
		"...kk..kk..kk..kk..kk.......",
	],
	"boss_king": [
		"..............a..a..a...................",
		"..............aa.aa.aa..................",
		".............kaaaaaaaaak................",
		".............k111111111k................",
		"............kXXXXXXXXXXXk...............",
		"...........kXXXXXXXXXXXXXk..............",
		"...........kXEEXXXXXEEXXXk..............",
		"...........kXEEXXXXXEEXXXk..............",
		"...........kXXXXX3XXXXXXXk..............",
		"...........kXmWmWmWmWmXXXk..............",
		"............kXmmmmmmmmXXk...............",
		"........kkkkkXXXXXXXXXXkkkkk............",
		"......kkXXXXXkXXXXXXXXkXXXXXkk..........",
		".....kXXXXXXXXkXXXXXXkXXXXXXXXk.........",
		"....kXXXXXXXXXXXXXXXXXXXXXXXXXXk........",
		"...kXXXXkXXXXXXXXXXXXXXXXkXXXXXk........",
		"...kXXXk.kXXXXXa3a3aXXXXk.kXXXXk........",
		"..kXXXk..kXXXXa3aaa3aXXXk..kXXXk........",
		"..kXXk...kXXXXXa3a3aXXXXk..kXXXXk.......",
		"..kXXk...kXXXXXXXaXXXXXXk...kXXXk.......",
		".kXXk....kXXXXXXXXXXXXXXk...kXXXk.......",
		".k11k....kXXXXXXXXXXXXXXk...kXXXXk......",
		".kHHk....kX3XXX?XXX?XX3Xk....kXXXk......",
		".kHhk....kXXXXXXXXXXXXXXk....kXXXk......",
		".kHhk....k33333333333333k....k111k......",
		".kHhk...kXXXXXXXkXXXXXXXXk...kkkk.......",
		".kHhk...kXXXXXXk.kXXXXXXXk..............",
		".kHhk...kXXXXXXk.kXXXXXXXk..............",
		".kHhk...kXXXXXk...kXXXXXXk..............",
		"kMMMMk..kXXXXXk...kXXXXXk...............",
		"kMNNNNk.kXXXXXk...kXXXXXk...............",
		"kMNNNNk.kX3XX3k...kX3XX3k...............",
		"kMNNNNk.kXXXXXk...kXXXXXk...............",
		"kNNNN4k.k3XXX3k...k3XXX3k...............",
		".kkkkk.kXXXXXXk...kXXXXXXk..............",
		".......kkkkkkkk...kkkkkkkk..............",
	],
	"boss_bellows": [
		"..........kkkkkkk.......................",
		"........kk1111111kk.....................",
		".......k11XXXXXXXX1k....................",
		"......k1XXXXXXXXXXXXk...................",
		"......k1XEEXXXXXEEXXk...................",
		"......k1XEEXXXXXEEXX3k..................",
		"......kXXXXXXXXXXXXX3k..................",
		"kkkkk.kXXmmmmmmmmXXX3k..................",
		"kMMNNkkXXmWmWmWmmXX33k..................",
		"kNNNNNkkXXmmmmmmXXX3kk..................",
		"kkkkkk.kkXXXXXXXXX3kkk..................",
		"......kXXXXXXXXXXXXXXXXXk...............",
		".....k4444444444444444444k..............",
		".....kXXXXXXXXXXXXXXXXXXXXk.............",
		"....k44444444444444444444444k...........",
		"....k1XXXXXXXXXXXXXXXXXXXXXXXk..........",
		"...k4444444444444444444444444k..........",
		"...kXXXXXXXXXXXaXaXaXXXXXXXXXXk.........",
		"...k4444444444444444444444444k..........",
		"....kXXXXXXXXXXXXXXXXXXXXXXXk...........",
		"....k44444444444444444444444k...........",
		".....kXXXXXXXXXXXXXXXXXXXXXk............",
		".....k444444444444444444444k............",
		"......kXXXXXXXXXXXXXXXXXXXk.............",
		".......kkkXXXXkkkkkXXXXkkk..............",
		".........kXXXXk...kXXXXk................",
		"........kXXX3k.....kXXX3k...............",
		"........kXX3k.......kXX3k...............",
		".......kXXX3k.......kXXX3k..............",
		"......kaaXX3k......kaaXX3k..............",
		"......kkkkkkk......kkkkkkk..............",
	],
	"boss_queen": [
		".............a...a...a.......",
		".............aa.aaa.aa.......",
		"............kaaaaaaaaak......",
		"............k111111111k......",
		"............kXXXXXXXXXk......",
		"...........kXXEXXXEXXXk......",
		"...........kXXXXXXXXX3k......",
		"............kXXmmmXX3k.......",
		".............kXXXXX3k........",
		"..........kkkkkXXXXkkkkk.....",
		"..a......kXXXXXkXXkXXXXXk....",
		"..ak....kXXXXXXXkkXXXXXXXk...",
		"..kak..kXXkXXXXXXXXXXXkXXk...",
		"..kak..kXk.kXXXX?XXXXXkkXXk..",
		"..kMk.kXk..kXXXXXXXXXXk.kXk..",
		"..kMk.kXk..kXXXX?XXXXXk.kXk..",
		"..kMkkXk...kXXXXXXXXXXk..kXk.",
		"..kMkXk....kXXX3XX3XXXk..k3k.",
		"..kMkk.....kXXXXXXXXXXk..k3k.",
		"..kMk......kXXXX3XXXXXk...kk.",
		"..kMk.....kXXXXXXXXXXXXk.....",
		"..kMk.....kXXX3XXXX3XXXk.....",
		"..kMk....kXXXXXXXXXXXXXXk....",
		"..kMk....kXXXX3XXXXX3XXXk....",
		"..kMk...kXXXXXXXXXXXXXXXXk...",
		"..kNk...kXXX3XXXXXXX3XXXXk...",
		"..kNk..kXXXXXXXXXXXXXXXXXXk..",
		"..kNk..kXX3XXXX3XXXXX3XXXXk..",
		"..kNk.kXXXXXXXXXXXXXXXXXXXXk.",
		"..kNk.kX3XXXXXX3XXXXXXX3XXXk.",
		"..kNkkXXXXXXXXXXXXXXXXXXXXXXk",
		"...kk.k?XXX?XXXX?XXXXX?XXX?k.",
		"......kkkkkkkkkkkkkkkkkkkkkk.",
	],
	"boss_hydra": [
		"..kkkk..........................",
		".kXXXXk.........kkkk............",
		"kXEXXXXk.......kXXXXk...........",
		"kWkWkXXk......kXEXXXXk..........",
		".k.k.kXk......kWkWkXXXk.........",
		".....kXk.......k.k.kXXk.........",
		"......kXk...........kXk...kkkk..",
		"......kXXk..........kXk..kXXXXk.",
		".......kXk.........kXXk.kXXXXEXk",
		".......kXXk........kXk..kXXkWkWk",
		"........kXk.......kXXk..kXXk.k.k",
		"........kXXk......kXk..kXXk.....",
		".........kXXk....kXXk..kXk......",
		".........kXXXk...kXXk.kXXk......",
		"..........kXXXk.kXXk.kXXk.......",
		"..........kXXXXkXXXkkXXk........",
		"...........kXXXXXXXXXXXk........",
		"..........kXXXXXXXXXXXXXk.......",
		".........kXXXX?XXXXX?XXXXk......",
		"........kXXXXXXXXXXXXXXXXXk.....",
		".......kXXX3XXXXXXXXXXX3XXXk....",
		"......kXXXXXXXXX?XXXXXXXXXXXk...",
		".....kXXXXXX3XXXXXXXX3XXXXXXXk..",
		".....kXXXXXXXXXXXXXXXXXXXXXXXk..",
		"....kXXXX3XXXXXX?XXXXXXX3XXXXXk.",
		"....kXXXXXXXXXXXXXXXXXXXXXXXXXk.",
		"...kXX3XXXXXX3XXXXXXX3XXXXX3XXk.",
		"...kXXXXXXXXXXXXXXXXXXXXXXXXXXk.",
		"..kXXXXkkkXXXXXkkkkXXXXXkkkXXXXk",
		"..kaXXk...kXXXk....kXXXk...kXXak",
		"..kkkk....kaakk....kkaak...kkkk.",
	],
	"boss_heart": [
		"...........kkk......kkk.........",
		"..........kWWWk....kWWWk........",
		".......kkkkWkkkkkkkkWkkkkk......",
		".....kk1111XXXXkkXXXXXXXXXkk....",
		"....k111XXXXXXXXkXXXXXXXXXX3k...",
		"...k11XXXXXXXXXXkXXXXXXXXXXX3k..",
		"..k11XXXXaXXXXXXkXXXXXXaXXXX33k.",
		"..k1XXXXXaaXXXXXXXXXXXaaXXXXX3k.",
		".k1XXXXXXXaaXXXXXXXXXaaXXXXXX33k",
		".k1XXXXXXXXaaXEEXEEXaaXXXXXXX33k",
		".kXXXXXXXXXXaaEEXEEaaXXXXXXXXX3k",
		".kXXXXXXXXXXXaaaaaaaXXXXXXXXXX3k",
		".kXXXXXXXXXXXXXaaaXXXXXXXXXXX33k",
		".kXXXXXXXXXXXXXXaXXXXXXXXXXXX33k",
		"..kXXXXXXXXXXXXXaXXXXXXXXXXX33k.",
		"..kXXXXXXXXXXXXXaXXXXXXXXXXX3k..",
		"...kXXXXXXXXXXXXaXXXXXXXXXX33k..",
		"....kXXXXXXXXXXXaXXXXXXXXX33k...",
		".....kXXXXXXXXXXaXXXXXXXX33k....",
		"......kXXXXXXXXXaXXXXXXX33k.....",
		".......kXXXXXXXXaXXXXXX33k......",
		"........kXXXXXXXaXXXXX33k.......",
		".........kXXXXXXaXXXX33k........",
		"..........kXXXXXaXXX33k.........",
		"...........kXXXXaXX33k..........",
		"............kXXXaX33k...........",
		".............kXXa33k............",
		"..............kXX3k.............",
		"...............k3k..............",
		"................k...............",
	],
	"boss_frost": [
		"...........a..a..a..a.......",
		"...........aa.aa.aa.aa......",
		"..........kaaaaaaaaaaak.....",
		"..........k11111111111k.....",
		"..........kXXXXXXXXXXXk.....",
		".........kXXEEXXXXEEXXXk....",
		".........kXXEEXXXXEEXXXk....",
		".........kXXXXXXXXXXXX3k....",
		"..........kXXWWWWWWXX3k.....",
		"..........kXXXWWWWXXX3k.....",
		"...........kXXXWWXXX3k......",
		"........kkkkkXXXXXX3kkkkk...",
		"......kk1111kkXXXXkk11111kk.",
		".....k11XXXXXXkkkkXXXXXX11k.",
		"....k1XXXkXXXXXXXXXXXXkXXX1k",
		"...k1XXXk.kXXXXX?XXXXk.kXX1k",
		"...kXXXk..kXXXXXXXXXXk..kXXk",
		"..kXXXk...kXXXX?XXXXXk..kXXk",
		"..kXXk....kXXXXXXXXXXk..kXXk",
		".kXXk.....kXXX3XX3XXXk...kXk",
		".kNk......kXXXXXXXXXXk...kak",
		".kMk.....kXXXXXXXXXXXXk..kkk",
		".kMk.....kXXX3XXXX3XXXk.....",
		".kMk....kXXXXXXXXXXXXXXk....",
		".kMk....kXXXX3XXXX3XXXXk....",
		".kMk...kXXXXXXXXXXXXXXXXk...",
		".kMk...kXX3XXXX3XXXXX3XXk...",
		".kMk..kXXXXXXXXXXXXXXXXXXk..",
		".kMk..kX3XXXXX3XXXXXX3XXXk..",
		".kNk.kXXXXXXXXXXXXXXXXXXXXk.",
		".kNk.kXXXXXXXXXXXXXXXXXXXXk.",
		"..k.kXXX3XXXXXX3XXXXXX3XXXXk",
		".....kaXXaXXXaXXXXaXXXaXXak.",
		".....kkkkkkkkkkkkkkkkkkkkkk.",
	],
}

## Máscaras de media silueta para criaturas FRONTALES (se reflejan). Mismo alfabeto que BASES,
## más: w esclerótica · d sombra forzada.
const SHAPES := {
	"slime": [
		"..........", "......oooX", "....oXXXXX", "...XXXXXXX", "..XXXXXXXX", ".XXXXXEEXX",
		".XXXXXEEXX", "XXXXXXXXXX", "XXXXXXXmmm", "XXXXXXXXmm", "XXXX?XXXXX", "XXXXXXXXXX", "oXXoXXXoXX",
	],
	"bat": [
		"a...........", "Xa......a...", "XXa.....Xa..", "XXXa....XXXX", "XXXXo..XXXXX", "XXXXXXXXEEXX",
		"oXXXXXXXEEXX", ".oXXXXXXXXXX", "..oXXXXXXXmw", "...o.oXXXXXm", "......oXXXXX", "........oXXX",
		"..........o.",
	],
	"eye": [
		"......oXXX", "....oXXXXX", "...XXXXXXX", "..XXXwwwww", ".XXwwwwwww", ".XwwwwwwEE", "XXwwwwwEEE",
		"XXwwwwwEEE", "XXwwwwwwEE", ".Xwwwwwwww", ".XXwwwwwww", "..XXXwwwww", "...XXXXXXX", "....oXXXXX",
		"...a.a.oXX", "..a..a..a.", ".a...a...a",
	],
	"totem": [
		"...aa.....", "....aoXXXX", "...XXXXXXX", "...XXEEXXX", "...XXEEXXX", "...XXXXmmm", "...ddddddd",
		".aXXXXXXXX", "aXXXXXXXXX", "XXXdXXXXXX", "XXXdXEXXXX", "XXXdXXXmmm", "XXo.dddddd", "XX..XXXXXX",
		"aa..X?aXXX", "....XXXXXX", "....XXXmmm", "....dddddd", "....XXXXXX", "...XXXXXXX", "...XXXXXXX",
		"..XXXXXXXX", "..XXXXXXXX", "..dddddddd",
	],
	"mite": [
		"..a...", "...a..", "..XXXX", ".XXXEX", "XXXXXX", "XdXXXm", "XXXXXX", "a.a.a.", ".a.a..",
	],
	"wraith": [
		"......XXXX", ".....XXXXX", "....XXXXXX", "...XXXdddd", "...XXddEEd", "...XXddddd", "...XXXdddd",
		"..oXXXXddd", ".oXXXXXXXX", "oXXXXXXXXX", "XXXXXXXXXX", "XXa.XXXXXX", "Xa..XXX?XX", "a...XXXXXX",
		"....XXXXXX", "....XXXXXX", "...XXXXXXX", "...XXXXXXX", "..oXXXXXXX", "..XXXXoXXX", "..XXoX.XXo",
		"..o..X..o.", ".....o....",
	],
	"priest": [
		".......aaa", "......XXXX", ".....XXXXX", "....XXXddd", "....XXdEEd", "....XXdddd", "....XXXddd",
		"...aXXXXdd", "..aXXXXXXX", ".aXXXXXXXa", "aXXXXXXXXa", "aXXXXXXXXa", ".XXXXXXX?a", ".XXXXXXXXa",
		"XXXXXXXXXa", "XXXXXXXXXa", "XXXXXXXXXX", "XXXXXXX?XX", "XXXXXXXXXX", "XXXXXXXXXX", "XXXXXXXXXX",
		"oXXXXXXXXX", "o.oXXoXXoX", "...o..o...",
	],
	"moth": [
		"aa..........", "..a......aXX", "oXXX....XXXX", "XXXXX..XXXEX", "XXaXXX.XXXXX", "XXXXXXXXXXXm",
		"XXaaXXXXXXXX", "oXXXXXX.XXXX", ".XXXXX..XXXX", "..oXX...XXXX", "...o....XXX.", ".........a..",
	],
}

## Metadatos: elevación en px de arte para criaturas voladoras.
const SHAPE_LIFT := {"bat": 10, "moth": 8, "eye": 6, "wraith": 3, "boss_heart": 6}


const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

## Posiciones (px de arte del fondo 320×180) de las antorchas del acto 1; ver torches(biome).
const TORCHES: Array[Vector2i] = [Vector2i(24, 70), Vector2i(86, 66), Vector2i(234, 66), Vector2i(296, 70)]
const FLOOR_Y := 118

## Poses de la heroína: [ángulo del brazo (rad, + = horario), dx cuerpo, dy cuerpo, estela desde (rad) o null]
const POSES := {
	"idle": [0.0, 0, 0, null],
	"windup": [2.45, -1, 1, null],
	"smear": [5.18, 1, 0, 2.2],
	"strike": [-1.55, 2, 0, null],
	"recover": [-0.75, 1, 0, null],
	"cast": [-2.6, 0, -1, null],
	"toss_back": [-0.9, 0, 0, null],
	"toss": [1.15, -1, 0, null],
	"hurt": [0.45, -2, 0, null],
}
const POSE_W := 52
const POSE_H := 48
const BODY_ORIGIN := Vector2i(14, 12)
const ARM_ATTACH := Vector2i(12, 16)     # dónde se pega el brazo sobre el cuerpo
const ARM_PIVOT := Vector2(3.5, 1.5)     # hombro dentro del sprite del brazo

var _cache := {}


func has_icon(id: String) -> bool:
	return SPRITES.has(id) or VARIANTS.has(id)


func has_shape(id: String) -> bool:
	var base := id.get_slice("@", 0)
	return SHAPES.has(base) or BASES.has(base)


func icon(id: String) -> Texture2D:
	var key := "i:" + id
	if _cache.has(key):
		return _cache[key]
	var t := ImageTexture.create_from_image(icon_image(id))
	_cache[key] = t
	return t


func icon_image(id: String) -> Image:
	if VARIANTS.has(id):
		var v: Array = VARIANTS[id]
		return image_from_rows(SPRITES[v[0]], v[1])
	if SPRITES.has(id):
		return image_from_rows(SPRITES[id])
	return image_from_rows(SPRITES["unknown"])


## Icono 24×24 suavizado con EPX (para ilustraciones y paneles a ×2 sin mezclar píxeles).
func icon_big(id: String) -> Texture2D:
	var key := "ib:" + id
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(scale2x(icon_image(id)))
	return _cache[key]


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


static func dither(x: int, y: int, t: float) -> bool:
	return t * 16.0 > float(BAYER4[y % 4][x % 4]) + 0.5


## Escalado ×2 EPX/Scale2x: mantiene el contorno y suaviza diagonales sin inventar colores.
static func scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := src.get_pixel(x, y)
			var a := src.get_pixel(x, y - 1) if y > 0 else p
			var b := src.get_pixel(x + 1, y) if x < w - 1 else p
			var c := src.get_pixel(x - 1, y) if x > 0 else p
			var d := src.get_pixel(x, y + 1) if y < h - 1 else p
			var e0 := p
			var e1 := p
			var e2 := p
			var e3 := p
			if not c.is_equal_approx(b) and not a.is_equal_approx(d):
				if a.is_equal_approx(c):
					e0 = a
				if a.is_equal_approx(b):
					e1 = b
				if d.is_equal_approx(c):
					e2 = c
				if d.is_equal_approx(b):
					e3 = b
			out.set_pixel(x * 2, y * 2, e0)
			out.set_pixel(x * 2 + 1, y * 2, e1)
			out.set_pixel(x * 2, y * 2 + 1, e2)
			out.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return out


## Rotación tipo RotSprite simplificada: superresolución ×4 con EPX, giro al vecino y muestreo al centro.
## Devuelve {img, pivot} donde `pivot` es la posición (px) del pivote en la imagen girada.
static func rotate_sprite(src: Image, angle: float, pivot: Vector2) -> Dictionary:
	var big := scale2x(scale2x(src))
	var bw := big.get_width()
	var bh := big.get_height()
	var r := 0.0
	for c: Vector2 in [Vector2.ZERO, Vector2(src.get_width(), 0), Vector2(0, src.get_height()), Vector2(src.get_width(), src.get_height())]:
		r = maxf(r, c.distance_to(pivot))
	var R := int(ceil(r)) + 1
	var size := R * 2 + 1
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ca := cos(-angle)
	var sa := sin(-angle)
	for y in size:
		for x in size:
			# Centro del píxel destino relativo al pivote (en px de arte).
			var vx := float(x - R)
			var vy := float(y - R)
			var sx := vx * ca - vy * sa
			var sy := vx * sa + vy * ca
			var bx := int(floor((pivot.x + sx) * 4.0))
			var by := int(floor((pivot.y + sy) * 4.0))
			if bx < 0 or by < 0 or bx >= bw or by >= bh:
				continue
			var p := big.get_pixel(bx, by)
			if p.a > 0.0:
				out.set_pixel(x, y, p)
	return {"img": out, "pivot": Vector2(R, R)}


# --- Heroína -------------------------------------------------------------------

## Heroína en reposo (24×36, brazo incluido). Para pantallas de menú.
func player() -> Texture2D:
	var key := "player_idle_small"
	if not _cache.has(key):
		var img := image_from_rows(SPRITES["player"])
		var arm := image_from_rows(SPRITES["player_arm"])
		img.blend_rect(arm, Rect2i(0, 0, arm.get_width(), arm.get_height()), ARM_ATTACH)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


## Obsoleto: el brazo ya va incluido en player(). Devuelve una textura vacía.
func player_arm() -> Texture2D:
	if not _cache.has("player_arm_empty"):
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		_cache["player_arm_empty"] = ImageTexture.create_from_image(img)
	return _cache["player_arm_empty"]


## Fotograma de la heroína en un lienzo fijo POSE_W×POSE_H (pies en la última fila).
func player_pose(pose: String) -> Texture2D:
	var key := "pp:" + pose
	if _cache.has(key):
		return _cache[key]
	var img: Image
	if pose == "idle_b":
		img = crouch_image(player_pose("idle").get_image(), BODY_ORIGIN.y + 21)
	else:
		img = _compose_pose(POSES.get(pose, POSES["idle"]))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


func _compose_pose(p: Array) -> Image:
	var canvas := Image.create(POSE_W, POSE_H, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var body := image_from_rows(SPRITES["player"])
	var bo := BODY_ORIGIN + Vector2i(int(p[1]), int(p[2]))
	canvas.blend_rect(body, Rect2i(0, 0, body.get_width(), body.get_height()), bo)
	var arm := image_from_rows(SPRITES["player_arm"])
	var angle: float = p[0]
	var shoulder := Vector2(bo) + Vector2(ARM_ATTACH) + ARM_PIVOT
	if p[3] != null:
		_draw_smear(canvas, shoulder, float(p[3]), angle)
	if absf(angle) < 0.01:
		canvas.blend_rect(arm, Rect2i(0, 0, arm.get_width(), arm.get_height()), bo + ARM_ATTACH)
	else:
		var r := rotate_sprite(arm, angle, ARM_PIVOT)
		var ri: Image = r["img"]
		var pv: Vector2 = r["pivot"]
		var dst := Vector2i(int(round(shoulder.x - pv.x - 0.5)), int(round(shoulder.y - pv.y - 0.5)))
		canvas.blend_rect(ri, Rect2i(0, 0, ri.get_width(), ri.get_height()), dst)
	return canvas


## Estela del martillo: arco de 2 px en amarillo→blanco entre dos ángulos.
func _draw_smear(canvas: Image, shoulder: Vector2, a0: float, a1: float) -> void:
	var steps := 40
	for i in steps + 1:
		var t := float(i) / steps
		var a := lerpf(a0, a1, t)
		for rr: float in [15.5, 16.5, 17.5, 18.5]:
			var v: Vector2 = Vector2(-sin(a), cos(a)) * rr
			var px := int(floor(shoulder.x + v.x))
			var py := int(floor(shoulder.y + v.y))
			if px < 0 or py < 0 or px >= POSE_W or py >= POSE_H:
				continue
			if canvas.get_pixel(px, py).a > 0.0:
				continue
			var c: Color = PAL["Y"] if t > 0.55 else (PAL["w"] if t > 0.25 else PAL["y"])
			if rr > 18.0 or rr < 16.0:
				c = PAL["o"] if t > 0.4 else PAL["r"]
			canvas.set_pixel(px, py, c)


## Aplasta 1 px: elimina la fila `row` y baja todo lo de arriba (respiración, anticipación).
static func crouch_image(src: Image, row: int) -> Image:
	var img := src.duplicate() as Image
	var w := img.get_width()
	for y in range(row, 0, -1):
		for x in w:
			img.set_pixel(x, y, src.get_pixel(x, y - 1))
	for x in w:
		img.set_pixel(x, 0, Color(0, 0, 0, 0))
	return img


## Estira 1 px: duplica la fila `row` subiendo todo lo de arriba (la fila 0 debe estar vacía).
static func stretch_image(src: Image, row: int) -> Image:
	var img := src.duplicate() as Image
	var w := img.get_width()
	for y in range(0, row):
		for x in w:
			img.set_pixel(x, y, src.get_pixel(x, y + 1))
	return img


# --- Monstruos --------------------------------------------------------------

func biome_colors(biome: int, cycle: int = 0) -> Dictionary:
	var b: Dictionary = BIOMES[biome % BIOMES.size()]
	if cycle == 0:
		return b
	var out := {}
	for k: String in b:
		var c: Color = b[k]
		out[k] = Color.from_hsv(fposmod(c.h + 0.29 * cycle, 1.0), minf(1.0, c.s + 0.1), c.v)
	return out


func monster_lift(shape: String) -> int:
	var base := shape.get_slice("@", 0)
	return int(SHAPE_LIFT.get(base, 0)) * (2 if shape.ends_with("@2") else 1)


## Monstruo: base dibujada a mano (o máscara simétrica) + sombreado + variación por semilla.
func monster(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	return monster_pose(shape, seed_key, biome, cycle, "base")


## Capa emisiva del monstruo (ojos, grietas, acentos) para el brillo pulsante aditivo.
func monster_glow(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	return monster_pose_glow(shape, seed_key, biome, cycle, "base")


## Variante de pose generada sin escalar: "base", "crouch" (−1 fila) o "stretch" (+1 fila).
func monster_pose(shape: String, seed_key: String, biome: int, cycle: int, pose: String) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key + ":base"):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache.get(key + ":" + pose, _cache[key + ":base"])


func monster_pose_glow(shape: String, seed_key: String, biome: int, cycle: int, pose: String) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key + ":base"):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache.get(key + ":" + pose + ":glow", _cache[key + ":base:glow"])


## EPX sobre la rejilla de caracteres: los jefes se dibujan a media resolución y se amplían ×2 ANTES
## de sombrear, de modo que el sombreado, el contorno y las grietas se calculan a resolución final.
static func grid_scale2x(grid: Array) -> Array:
	var h := grid.size()
	var w := String(grid[0]).length()
	var out: Array = []
	for y in h:
		var r0 := ""
		var r1 := ""
		for x in w:
			var p: String = grid[y][x]
			var a: String = grid[y - 1][x] if y > 0 else p
			var b: String = grid[y][x + 1] if x < w - 1 else p
			var c: String = grid[y][x - 1] if x > 0 else p
			var d: String = grid[y + 1][x] if y < h - 1 else p
			var e0 := p
			var e1 := p
			var e2 := p
			var e3 := p
			if c != b and a != d:
				if a == c:
					e0 = a
				if a == b:
					e1 = b
				if d == c:
					e2 = c
				if d == b:
					e3 = b
			r0 += e0 + e1
			r1 += e2 + e3
		out.append(r0)
		out.append(r1)
	return out


## `shape@2` = versión de élite: la misma base ampliada ×2 con EPX antes de sombrear.
func _monster_grid(shape: String, rng: RandomNumberGenerator) -> Array:
	if shape.ends_with("@2"):
		return grid_scale2x(_monster_grid(shape.get_slice("@", 0), rng))
	var grid: Array = []
	if BASES.has(shape) and shape.begins_with("boss_"):
		var src: Array = []
		for r: String in BASES[shape]:
			src.append(r)
		for g: String in grid_scale2x(src):
			var line := ""
			for ch in g:
				match ch:
					"o": ch = "X" if rng.randf() < 0.55 else "."
					"?": ch = "a" if rng.randf() < 0.6 else "X"
				line += ch
			grid.append(line)
		return grid
	if BASES.has(shape):
		var rows: Array = BASES[shape]
		var w := 0
		for r: String in rows:
			w = maxi(w, r.length())
		for r: String in rows:
			var line := ""
			for x in w:
				var ch := r[x] if x < r.length() else "."
				match ch:
					"o": ch = "X" if rng.randf() < 0.55 else "."
					"?": ch = "a" if rng.randf() < 0.6 else "X"
				line += ch
			grid.append(line)
		return grid
	var half: Array = SHAPES.get(shape, SHAPES["slime"])
	var hw := 0
	for r: String in half:
		hw = maxi(hw, r.length())
	for r: String in half:
		var left := ""
		for x in hw:
			var ch := r[x] if x < r.length() else "."
			match ch:
				"o": ch = "X" if rng.randf() < 0.55 else "."
				"?": ch = "a" if rng.randf() < 0.5 else "X"
				"w": ch = "W"
				"d": ch = "3"
			left += ch
		grid.append(left + left.reverse())
	# Las criaturas frontales pequeñas se amplían ×2 (EPX) para leerse a escala de juego.
	if shape in ["mite", "bat", "moth"]:
		grid = grid_scale2x(grid)
	return grid


func _build_monster(shape: String, seed_key: String, biome: int, cycle: int, key: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key + ":" + shape)
	var grid := _monster_grid(shape, rng)
	var h := grid.size()
	var w := String(grid[0]).length()
	var big := h >= 36
	var solid := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h:
			return false
		var c: String = grid[y][x]
		return c != "." and c != "k"
	# Campo de distancia al borde/contornos internos.
	var dist: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		for x in w:
			row[x] = 99 if solid.call(x, y) else 0
		dist.append(row)
	for _pass in 5:
		for y in h:
			for x in w:
				if int(dist[y][x]) == 0:
					continue
				var m := 99
				for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + dd.x
					var ny := y + dd.y
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						m = 0
					else:
						m = mini(m, int(dist[ny][nx]))
				dist[y][x] = mini(int(dist[y][x]), m + 1)
	var pal := biome_colors(biome, cycle)
	var jit_h := rng.randf_range(-0.02, 0.02)
	var jit_v := rng.randf_range(-0.03, 0.03)
	var ramp: Array[Color] = []
	for k: String in ["deep", "dark", "mid", "light", "hi"]:
		var c0: Color = pal[k]
		ramp.append(Color.from_hsv(fposmod(c0.h + jit_h, 1.0), c0.s, clampf(c0.v + jit_v, 0.0, 1.0)))
	var accent: Color = pal["accent"]
	var eye_col: Color = pal["eye"]
	var fire := Color("ff8a3a")
	var crack_rate := rng.randf_range(0.15, 0.6)
	var crack_seed := rng.randi()
	var outline: Color = PAL["k"]
	# 1 px de margen alrededor + 1 fila libre arriba para "stretch".
	var W := w + 2
	var H := h + 3
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var glow := Image.create(W, H, false, Image.FORMAT_RGBA8)
	glow.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var ch: String = grid[y][x]
			if ch == ".":
				continue
			var col: Color
			var emissive := false
			var up_e: bool = not solid.call(x, y - 1)
			var dn_e: bool = not solid.call(x, y + 1)
			var lf_e: bool = not solid.call(x - 1, y)
			var rt_e: bool = not solid.call(x + 1, y)
			match ch:
				"k":
					col = outline
				"E":
					col = eye_col
					var ue: bool = y > 0 and grid[y - 1][x] == "E"
					var le: bool = x > 0 and grid[y][x - 1] == "E"
					if not ue and not le:
						col = Color("fffbe8")
					emissive = true
				"W":
					col = PAL["W"] if not dn_e else Color("c8b498")
				"m":
					col = ramp[0].darkened(0.45)
				"M":
					col = PAL["M"]
				"N":
					col = PAL["m"]
				"H":
					col = PAL["n"]
				"h":
					col = PAL["h"]
				"a":
					col = accent.lightened(0.3) if up_e else accent
					emissive = true
				"1":
					col = ramp[4] if up_e else ramp[3]
				"2":
					col = ramp[2]
				"4":
					col = ramp[0]
				"3":
					col = ramp[1]
					# Grietas: algunas filas de pliegue brillan según la semilla.
					var n := fposmod(sin(float(x * 12.9898 + y * 78.233 + crack_seed % 997)) * 43758.5453, 1.0)
					if n < crack_rate and not dn_e:
						col = accent if biome != 2 else ramp[4]
						emissive = true
				_:
					var d := float(mini(int(dist[y][x]), 4))
					var lit := 0.30 + 0.10 * d - 0.22 * float(y) / h
					if up_e:
						lit += 0.30
					if lf_e:
						lit += 0.10
					if dn_e:
						lit -= 0.28
					if rt_e:
						lit -= 0.12
					var f := clampf(lit, 0.0, 0.999) * 5.0
					var i0 := int(f)
					var frac := f - i0
					if big and biome % 3 != 2 and frac > 0.55 and dither(x, y, 0.5):
						i0 += 1
					col = ramp[clampi(i0, 0, 4)]
			# Luz de fuego desde la izquierda (el horno y la heroína están ahí).
			if lf_e and ch in ["X", "1", "2", "3"] and not emissive:
				col = col.lerp(fire, 0.32)
			img.set_pixel(x + 1, y + 2, col)
			if emissive:
				glow.set_pixel(x + 1, y + 2, col.lightened(0.2))
	# Halo de 1 px alrededor de los ojos en la capa emisiva.
	var halo := glow.duplicate() as Image
	for y in H:
		for x in W:
			if glow.get_pixel(x, y).a > 0.0:
				continue
			for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + dd.x
				var ny := y + dd.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H:
					var gp := glow.get_pixel(nx, ny)
					if gp.a > 0.0 and gp.v > 0.85:
						halo.set_pixel(x, y, Color(gp.r, gp.g, gp.b, 0.35))
						break
	# Contorno exterior de 1 px.
	var out_img := img.duplicate() as Image
	for y in H:
		for x in W:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + dd.x
				var ny := y + dd.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H and img.get_pixel(nx, ny).a > 0.0:
					out_img.set_pixel(x, y, outline)
					break
	var mid_row := 2 + int(h * 0.55)
	_cache[key + ":base"] = ImageTexture.create_from_image(out_img)
	_cache[key + ":base:glow"] = ImageTexture.create_from_image(halo)
	_cache[key + ":crouch"] = ImageTexture.create_from_image(crouch_image(out_img, mid_row))
	_cache[key + ":crouch:glow"] = ImageTexture.create_from_image(crouch_image(halo, mid_row))
	_cache[key + ":stretch"] = ImageTexture.create_from_image(stretch_image(out_img, mid_row))
	_cache[key + ":stretch:glow"] = ImageTexture.create_from_image(stretch_image(halo, mid_row))


# --- Cartas -----------------------------------------------------------------

const TYPE_ART := {
	"attack": [Color("2a0c0c"), Color("6a1c14"), Color("c2401c"), Color("ffb060")],
	"skill": [Color("0c1428"), Color("1a3256"), Color("2e5a8a"), Color("a8d8ff")],
	"power": [Color("1e0e2e"), Color("4a2458"), Color("8a5a1a"), Color("ffd870")],
	"fuel": [Color("140a08"), Color("3a1c10"), Color("6a3418"), Color("ff8a2a")],
	"status": [Color("101014"), Color("26262e"), Color("3a3a44"), Color("9aa0b0")],
}
const RARITY_GEM := {"starter": Color("8a6a5a"), "common": Color("b0a8a0"), "uncommon": Color("5aa8ff"),
	"rare": Color("ffcc40"), "status": Color("6a6a74"), "token": Color("ff8a4a")}
const PARCHMENT := {"attack": Color("ead2b0"), "skill": Color("dcd6c4"), "power": Color("ecd8a8"),
	"fuel": Color("e4c8a0"), "status": Color("bab4ac")}
## Ventana de la ilustración dentro del marco (px del marco 75×105).
const ART_RECT := Rect2i(7, 16, 60, 30)


## ¿El píxel (lx, ly) de la ventana 60×30 pertenece a la forma de la ventana según el tipo?
static func window_mask(type: String, lx: int, ly: int) -> bool:
	match type:
		"attack":
			# Hoja: esquinas superiores achaflanadas y punta inferior.
			if lx + ly < 7 or (59 - lx) + ly < 7:
				return false
			var cx := absf(lx - 29.5)
			return ly < 26 or cx < 30.0 - (ly - 26) * 4.0
		"power":
			var dx := (lx - 29.5) / 30.0
			var dy := (ly - 14.5) / 15.2
			return dx * dx + dy * dy <= 1.0
		"fuel":
			if ly >= 11:
				return true
			var ax := (lx - 29.5) / 30.0
			var ay := (ly - 11.0) / 11.5
			return ax * ax + ay * ay <= 1.0
		"skill":
			return not ((lx < 2 or lx > 57) and (ly < 2 or ly > 27))
	return true


## Marco de carta 75×105 (se muestra ×2 → 150×210). Forma de ventana por tipo, cuerpo de pergamino.
func card_frame(type: String, rarity: String, upgraded: bool, mastery: int) -> Texture2D:
	var key := "cf:%s:%s:%s:%d" % [type, rarity, upgraded, mastery]
	if _cache.has(key):
		return _cache[key]
	var W := 75
	var H := 105
	var tc: Color = UI.TYPE_COLORS.get(type, Color("5a4040"))
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline: Color = PAL["k"]
	var band := tc
	if upgraded:
		band = tc.lerp(Color("ffcc50"), 0.45)
	var band_hi := band.lightened(0.35)
	var band_lo := band.darkened(0.4)
	var paper := Color("2a1c20").lerp(tc, 0.14)
	for y in H:
		for x in W:
			var c := paper
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			if edge == 0:
				c = outline
			elif edge <= 3:
				var tl := x <= 3 or y <= 3
				var br := x >= W - 4 or y >= H - 4
				c = band
				if edge == 1:
					c = band_hi if tl and not br else band_lo
				elif edge == 3:
					c = band_lo.darkened(0.2)
			img.set_pixel(x, y, c)
	# Banda del nombre.
	for y in range(4, 14):
		for x in range(4, W - 4):
			var c2 := band_lo.darkened(0.3)
			if y == 4:
				c2 = band.darkened(0.05)
			elif y == 13:
				c2 = outline
			img.set_pixel(x, y, c2)
	# Ventana con forma: marco de 1 px de banda + contorno.
	var ar := ART_RECT
	for y in range(ar.position.y - 2, ar.end.y + 2):
		for x in range(ar.position.x - 2, ar.end.x + 2):
			var lx := x - ar.position.x
			var ly := y - ar.position.y
			var inside := lx >= 0 and ly >= 0 and lx < ar.size.x and ly < ar.size.y and window_mask(type, lx, ly)
			if inside:
				img.set_pixel(x, y, outline)
				continue
			# Distancia a la ventana (1 → contorno, 2 → borde de banda).
			var near1 := false
			var near2 := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var qx := lx + dx
					var qy := ly + dy
					if qx >= 0 and qy >= 0 and qx < ar.size.x and qy < ar.size.y and window_mask(type, qx, qy):
						if absi(dx) <= 1 and absi(dy) <= 1:
							near1 = true
						else:
							near2 = true
			if near1:
				img.set_pixel(x, y, outline)
			elif near2:
				img.set_pixel(x, y, band if (y < ar.position.y + 4 or x < ar.position.x + 4) else band_lo)
	# Detalles por tipo.
	match type:
		"power":
			for i in 12:
				var a := TAU * i / 12.0
				for rr in range(2):
					var px := int(37 + cos(a) * (33 + rr))
					var py := int(31 + sin(a) * (17 + rr))
					if px > 4 and px < W - 5 and py > 14 and py < 48 and img.get_pixel(px, py) == paper:
						img.set_pixel(px, py, band.darkened(0.2))
		"skill":
			for p: Vector2i in [Vector2i(5, 16), Vector2i(68, 16), Vector2i(5, 45), Vector2i(68, 45)]:
				img.set_pixel(p.x, p.y, band_hi)
				img.set_pixel(p.x, p.y + 1, band_lo)
		"attack":
			for p: Vector2i in [Vector2i(5, 15), Vector2i(68, 15)]:
				for i in 3:
					img.set_pixel(p.x, p.y + i, band_hi if i == 0 else band)
	# Cinta del tipo.
	for y in range(48, 54):
		for x in range(16, W - 16):
			var c3 := band_lo
			if y == 48:
				c3 = band
			elif y == 53:
				c3 = outline
			if x == 16 or x == W - 17:
				c3 = outline
			img.set_pixel(x, y, c3)
	# Pergamino del texto.
	var parch: Color = PARCHMENT.get(type, Color("e0d0b0"))
	if upgraded:
		parch = parch.lerp(Color("fff0c0"), 0.25)
	for y in range(55, 99):
		for x in range(6, W - 6):
			var c4 := parch
			var e2 := mini(mini(x - 6, W - 7 - x), mini(y - 55, 98 - y))
			if e2 == 0:
				c4 = outline
			elif e2 == 1:
				c4 = parch.darkened(0.18)
			elif y == 56 + 1:
				c4 = parch.darkened(0.08)
			elif (x * 7 + y * 13) % 23 == 0:
				c4 = parch.darkened(0.05)
			img.set_pixel(x, y, c4)
	# Gema de rareza (rombo 5×5 en el borde inferior).
	var gem: Color = RARITY_GEM.get(rarity, Color("b0a8a0"))
	var gx := W / 2
	var gy := H - 4
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var md := absi(dx) + absi(dy)
			if md <= 3:
				var gc := outline
				if md <= 2:
					gc = gem.lightened(0.45) if (dx < 0 and dy < 0) else (gem.darkened(0.3) if dx + dy > 0 else gem)
				img.set_pixel(gx + dx, gy + dy, gc)
	# Maestría: ascuas a la izquierda de la gema.
	for i in mastery:
		var mx := 8 + i * 5
		var my := H - 5
		var mc := Color("ff8ad8") if mastery >= Game.MASTERY_MAX else Color("ffb43a")
		img.set_pixel(mx + 1, my - 1, mc.lightened(0.4))
		img.set_pixel(mx, my, mc)
		img.set_pixel(mx + 1, my, mc.lightened(0.2))
		img.set_pixel(mx + 2, my, mc)
		img.set_pixel(mx + 1, my + 1, mc.darkened(0.3))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Ilustración 60×30 (se muestra ×2 → 120×60, misma rejilla que el marco). Fondo por tipo en
## bandas, efecto por tipo e icono 24×24 suavizado con EPX. Fuera de la forma de ventana es transparente.
func card_art(card_id: String, type: String, icon_id: String) -> Texture2D:
	var key := "ca:" + card_id + ":" + type
	if _cache.has(key):
		return _cache[key]
	var W := 60
	var H := 30
	var cols: Array = TYPE_ART.get(type, TYPE_ART["status"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(card_id)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cx := W * 0.5 + rng.randf_range(-4.0, 4.0)
	var cy := H * 0.5
	for y in H:
		for x in W:
			var t := 1.0 - float(y) / H
			# Bandas verticales con una fila tramada entre bandas.
			var f := t * 2.999
			var i0 := int(f)
			if f - i0 > 0.82 and dither(x, y, 0.5):
				i0 += 1
			var base: Color = cols[clampi(i0, 0, 2)]
			# Halo central en anillos.
			var dx := (x - cx) / 22.0
			var dy := (y - cy) / 11.0
			var g := 1.0 - sqrt(dx * dx + dy * dy)
			if g > 0.55:
				base = base.lerp(cols[3], 0.30)
			elif g > 0.3:
				base = base.lerp(cols[3], 0.16)
			elif g > 0.1:
				base = base.lerp(cols[3], 0.07)
			img.set_pixel(x, y, base)
	match type:
		"attack":
			for i in 2:
				var sy := rng.randi_range(6, H - 8)
				for x in range(rng.randi_range(0, 10), rng.randi_range(36, W)):
					var yy := sy + int(x * 0.35) - 8
					if yy >= 0 and yy < H:
						img.set_pixel(x, yy, (cols[3] as Color).darkened(0.1))
						if yy + 1 < H:
							img.set_pixel(x, yy + 1, (cols[2] as Color).lightened(0.1))
		"power":
			for i in 10:
				var a := TAU * i / 10.0 + rng.randf() * 0.2
				for r in range(9, 34):
					var px := int(cx + cos(a) * r)
					var py := int(cy + sin(a) * r * 0.5)
					if px >= 0 and py >= 0 and px < W and py < H and r % 3 != 0:
						img.set_pixel(px, py, (cols[3] as Color).darkened(0.35))
		"skill":
			for r in [12, 16]:
				for i in 64:
					var a2 := TAU * i / 64.0
					var px2 := int(cx + cos(a2) * r)
					var py2 := int(cy + sin(a2) * r * 0.5)
					if px2 >= 0 and py2 >= 0 and px2 < W and py2 < H and i % 2 == 0:
						img.set_pixel(px2, py2, (cols[2] as Color).lightened(0.25))
		"fuel":
			# Lecho de brasas: guijarros de 2×1 con ruido estable por carta.
			var cs := rng.randi() % 1000
			for x in W:
				for y in range(H - 4, H):
					var n := _hash2(x / 2, y, cs)
					var c: Color = Color("2a140c")
					if n > 0.8:
						c = Color("ffb43a") if y < H - 2 else Color("ff8a2a")
					elif n > 0.55:
						c = Color("c2401c")
					elif n > 0.3:
						c = Color("5a2414")
					img.set_pixel(x, y, c)
		"status":
			for i in 3:
				var sy2 := rng.randi_range(4, H - 6)
				for x in W:
					var yy2 := sy2 + int(sin(x * 0.3 + i) * 1.5)
					if yy2 >= 0 and yy2 < H and x % 3 != 0:
						img.set_pixel(x, yy2, (cols[2] as Color).lightened(0.1))
	# Motas en la paleta del tipo.
	for i in 8:
		var px3 := rng.randi_range(1, W - 2)
		var py3 := rng.randi_range(1, H - 8)
		img.set_pixel(px3, py3, cols[3] if i % 2 == 0 else (cols[3] as Color).lightened(0.3))
	# Icono 24×24 con sombra arrojada.
	var ic := scale2x(icon_image(icon_id))
	var ox := int(W / 2.0 - 12)
	var oy := 3
	var shadow: Color = (cols[0] as Color).darkened(0.5)
	for y in 24:
		for x in 24:
			if ic.get_pixel(x, y).a > 0.0 and x + ox + 2 < W and y + oy + 2 < H:
				img.set_pixel(x + ox + 2, y + oy + 2, shadow)
	for y in 24:
		for x in 24:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0 and y + oy < H:
				img.set_pixel(x + ox, y + oy, p)
	# Rejilla de horno delante de las brasas.
	if type == "fuel":
		for x in range(3, W, 8):
			for y in range(H - 4, H):
				img.set_pixel(x, y, PAL["k"])
		for x in W:
			img.set_pixel(x, H - 5, Color("4a4048") if x % 8 != 3 else PAL["k"])
	# Máscara de la forma de ventana.
	for y in H:
		for x in W:
			if not window_mask(type, x, y):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Orbe de coste 16×16 (×2).
func cost_orb(affordable: bool, upgraded: bool) -> Texture2D:
	var key := "orb:%s:%s" % [affordable, upgraded]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Color("c24a1a") if affordable else Color("4a3a3a")
	if upgraded and affordable:
		base = Color("d07a1a")
	for y in 16:
		for x in 16:
			var dx := x - 7.5
			var dy := y - 7.5
			var r := sqrt(dx * dx + dy * dy)
			if r > 7.6:
				continue
			var c := base
			if r > 6.6:
				c = PAL["k"]
			else:
				var lit := (-dx - dy) / 10.0 + 0.3
				if lit > 0.55:
					c = base.lightened(0.45)
				elif lit > 0.15:
					c = base.lightened(0.15)
				elif lit < -0.45:
					c = base.darkened(0.35)
			img.set_pixel(x, y, c)
	img.set_pixel(5, 4, Color("fff4c8"))
	img.set_pixel(4, 5, Color("fff4c8"))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Dorso de carta 75×105 (×2), para la animación de robo.
func card_back() -> Texture2D:
	if _cache.has("cb"):
		return _cache["cb"]
	var W := 75
	var H := 105
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			var c := Color("3a1a18")
			if edge == 0:
				c = PAL["k"]
			elif edge <= 3:
				c = Color("8a4a2a") if edge == 1 else Color("5a2a1a")
			else:
				var dx := absf(x - W * 0.5)
				var dy := absf(y - H * 0.5)
				if int(dx + dy) % 12 == 0:
					c = Color("5a2418")
				elif dx + dy < 26:
					c = Color("4a2018")
			img.set_pixel(x, y, c)
	var ic := scale2x(icon_image("flame"))
	img.blend_rect(ic, Rect2i(0, 0, 24, 24), Vector2i(26, 40))
	var t := ImageTexture.create_from_image(img)
	_cache["cb"] = t
	return t


## Dorso pequeño 15×21 (×2 → 30×42) para pilas y cartas fantasma (sin escalados fraccionarios).
func card_back_small() -> Texture2D:
	if _cache.has("cbs"):
		return _cache["cbs"]
	var W := 15
	var H := 21
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			var c := Color("3a1a18")
			if edge == 0:
				c = PAL["k"]
			elif edge == 1:
				c = Color("8a4a2a") if (x <= 1 or y <= 1) else Color("5a2a1a")
			img.set_pixel(x, y, c)
	for p: Vector2i in [Vector2i(7, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(6, 9), Vector2i(7, 9),
			Vector2i(8, 9), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10),
			Vector2i(5, 11), Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11), Vector2i(6, 12),
			Vector2i(7, 12), Vector2i(8, 12)]:
		img.set_pixel(p.x, p.y, PAL["o"] if p.y < 10 else (PAL["y"] if p.x == 7 else PAL["r"]))
	var t := ImageTexture.create_from_image(img)
	_cache["cbs"] = t
	return t


# --- Escenarios ---------------------------------------------------------------

func torches(biome: int) -> Array[Vector2i]:
	match biome % 3:
		1:
			return [Vector2i(32, 72), Vector2i(88, 66), Vector2i(232, 66), Vector2i(288, 72)]
		2:
			return [Vector2i(22, 70), Vector2i(92, 66), Vector2i(228, 66), Vector2i(298, 70)]
	return TORCHES


func _hash2(x: int, y: int, s: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.17) * 43758.5453, 1.0)


## Fondo interior de la torre (320×180) para combate y menús: composición distinta por acto.
func background(biome: int, seed_value: int, cycle: int = 0) -> Texture2D:
	var key := "bg:%d:%d:%d" % [biome, seed_value, cycle]
	if _cache.has(key):
		return _cache[key]
	var pal := biome_colors(biome, cycle)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + biome
	var img := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	match biome % 3:
		0:
			_bg_brick(img, pal, rng)
		1:
			_bg_rock(img, pal, rng)
		2:
			_bg_ice(img, pal, rng)
	_bg_floor(img, pal, rng, biome % 3)
	for tp: Vector2i in torches(biome):
		_bg_torch(img, tp)
	_bg_vignette(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Capa cercana (primer plano) transparente: pilares y cadenas en silueta para el parallax.
func background_near(biome: int, seed_value: int, cycle: int = 0) -> Texture2D:
	var key := "bgn:%d:%d:%d" % [biome, seed_value, cycle]
	if _cache.has(key):
		return _cache[key]
	var pal := biome_colors(biome, cycle)
	var img := Image.create(336, 180, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color("0c0709")
	var rim: Color = (pal["wall"] as Color).lightened(0.12)
	# Pilares laterales (8 px de margen para el parallax).
	for px: int in [0, 326]:
		for y in 180:
			for x in range(px, px + 10):
				var c := dark
				if (px == 0 and x == px + 9) or (px != 0 and x == px):
					c = rim
				img.set_pixel(x, y, c)
	# Cadenas en primer plano.
	for cx: int in [20, 316]:
		var ln := 34 + (seed_value * 13 + cx) % 30
		for y in ln:
			var c2 := Color("2a2226") if y % 4 != 3 else dark
			img.set_pixel(cx, y, c2)
			if y % 4 == 1:
				img.set_pixel(cx - 1, y, dark)
				img.set_pixel(cx + 1, y, dark)
		img.set_pixel(cx, ln, Color("3a3034"))
	match biome % 3:
		1:
			# Estalactitas de escoria.
			for sx: int in [40, 70, 270, 300]:
				var l2 := 6 + (sx * 7 + seed_value) % 9
				for y in l2:
					var hw := int((l2 - y) / 4.0)
					for x in range(sx - hw, sx + hw + 1):
						img.set_pixel(x, y, dark if x != sx - hw else rim)
				img.set_pixel(sx, l2, pal["accent"])
		2:
			# Carámbanos.
			for sx2: int in [30, 46, 58, 278, 292, 306]:
				var l3 := 4 + (sx2 * 5 + seed_value) % 10
				for y in l3:
					var hw2 := int((l3 - y) / 5.0)
					for x in range(sx2 - hw2, sx2 + hw2 + 1):
						img.set_pixel(x, y, Color("d8ecf8") if x == sx2 - hw2 else Color("8ab4d0"))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


func _bg_brick(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	for by in range(0, FLOOR_Y, 8):
		var row := by / 8
		var off := 0 if row % 2 == 0 else 8
		for bx in range(-off, 320, 16):
			var tone := wall.lightened(rng.randf_range(-0.03, 0.05))
			if rng.randf() < 0.06:
				tone = wall.darkened(0.12)
			for y in range(by, mini(by + 8, FLOOR_Y)):
				for x in range(maxi(bx, 0), mini(bx + 16, 320)):
					var c := mortar if (y == by or x == bx) else tone
					if c != mortar and y == by + 1:
						c = c.lightened(0.05)
					elif c != mortar and y == by + 7:
						c = c.darkened(0.06)
					# Hollín: más oscuro arriba.
					c = c.darkened(0.30 * (1.0 - float(y) / FLOOR_Y))
					img.set_pixel(x, y, c)
	_bg_pilasters(img, pal, [100, 212])
	_bg_windows(img, pal, [52, 268], Color("1a0a10"), Color("5a2014"), false)
	# Gran arco central del horno-catedral.
	_bg_arch(img, pal, 160, 30, 26, Color("140a0c"), Color("6a2810"))
	_bg_banners(img, pal, [124, 196])
	_bg_chains(img, rng, [40, 150, 170, 280])


func _bg_rock(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	img.fill(mortar)
	var y := 0
	while y < FLOOR_Y:
		var bh := rng.randi_range(7, 12)
		var x := -rng.randi_range(0, 12)
		while x < 320:
			var bw := rng.randi_range(10, 26)
			var tone := wall.lightened(rng.randf_range(-0.04, 0.07))
			for yy in range(y + 1, mini(y + bh, FLOOR_Y)):
				for xx in range(maxi(x + 1, 0), mini(x + bw, 320)):
					var corner := (yy == y + 1 or yy == y + bh - 1) and (xx == x + 1 or xx == x + bw - 1)
					if corner:
						continue
					var c := tone
					if yy == y + 1:
						c = tone.lightened(0.06)
					elif yy == y + bh - 1:
						c = tone.darkened(0.08)
					c = c.darkened(0.25 * (1.0 - float(yy) / FLOOR_Y))
					img.set_pixel(xx, yy, c)
			x += bw
		y += bh
	_bg_pilasters(img, pal, [100, 212])
	# Goteos de escoria emisiva.
	var acc: Color = pal["accent"]
	for i in 7:
		var dx := rng.randi_range(12, 308)
		if absi(dx - 160) < 30:
			continue
		var ln := rng.randi_range(10, 46)
		for yy2 in ln:
			var c2 := acc.darkened(0.55 - 0.4 * float(yy2) / ln)
			img.set_pixel(dx, yy2, c2)
		img.set_pixel(dx, ln, acc)
		img.set_pixel(dx, ln + 1, acc.darkened(0.3))
	# Jaulas colgantes.
	for cx: int in [70, 250]:
		for yy3 in 26:
			img.set_pixel(cx, yy3, Color("3a3438") if yy3 % 3 else Color("1a1418"))
		for yy4 in range(26, 48):
			for xx2 in range(cx - 7, cx + 8):
				var bar := (xx2 - cx + 7) % 3 == 0 or yy4 == 26 or yy4 == 47
				if bar:
					img.set_pixel(xx2, yy4, Color("4a4448") if xx2 < cx else Color("2a2428"))
				elif yy4 > 40:
					img.set_pixel(xx2, yy4, img.get_pixel(xx2, yy4).lerp(acc, 0.12))
	_bg_arch(img, pal, 160, 34, 22, Color("0e0a12"), acc.darkened(0.5))
	_bg_banners(img, pal, [128, 192])


func _bg_ice(img: Image, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Color = pal["wall"]
	var mortar: Color = pal["mortar"]
	for by in range(0, FLOOR_Y, 12):
		var off := 0 if (by / 12) % 2 == 0 else 12
		for bx in range(-off, 320, 24):
			var tone := wall.lightened(rng.randf_range(-0.03, 0.06))
			for y in range(by, mini(by + 12, FLOOR_Y)):
				for x in range(maxi(bx, 0), mini(bx + 24, 320)):
					var c := mortar if (y == by or x == bx) else tone
					if c != mortar and y == by + 1:
						c = Color("b8d4e8") if _hash2(x, y, 7) < 0.35 else c.lightened(0.08)
					elif c != mortar and y == by + 11:
						c = c.darkened(0.06)
					c = c.darkened(0.22 * (1.0 - float(y) / FLOOR_Y))
					img.set_pixel(x, y, c)
	# Viga superior con carámbanos.
	for y in 6:
		for x in 320:
			img.set_pixel(x, y, Color("141c2a") if y < 5 else Color("3a5070"))
	for i in 40:
		var sx := rng.randi_range(0, 319)
		var l := rng.randi_range(2, 9)
		for y2 in l:
			if y2 < l - int(y2 / 3):
				img.set_pixel(sx, 6 + y2, Color("cfe6f6") if y2 < l - 1 else Color("8ab4d0"))
	_bg_pilasters(img, pal, [100, 212])
	_bg_windows(img, pal, [52, 268], Color("060a18"), Color("1e3456"), true)
	_bg_arch(img, pal, 160, 32, 24, Color("0a0e18"), Color("2a4a7a"))
	_bg_banners(img, pal, [124, 196])


func _bg_pilasters(img: Image, pal: Dictionary, xs: Array) -> void:
	var wall: Color = pal["wall"]
	for px: int in xs:
		for y in FLOOR_Y:
			for x in range(px, px + 8):
				var c := wall.lightened(0.10)
				if x == px or x == px + 7:
					c = pal["mortar"]
				elif x == px + 1:
					c = wall.lightened(0.18)
				elif x == px + 6:
					c = wall.darkened(0.05)
				if y < 6 or (y >= FLOOR_Y - 6):
					c = wall.lightened(0.14) if x > px and x < px + 7 else c
				c = c.darkened(0.2 * (1.0 - float(y) / FLOOR_Y))
				img.set_pixel(x, y, c)


## Ventanas arqueadas: cielo en bandas, parteluz, alféizar y (opcional) luna y nieve.
func _bg_windows(img: Image, pal: Dictionary, xs: Array, sky_top: Color, sky_bot: Color, cold: bool) -> void:
	for wx: int in xs:
		for y in range(24, 84):
			for x in range(wx - 12, wx + 13):
				var dx := x - wx
				var top := 36.0 - sqrt(maxf(0.0, 144.0 - dx * dx))
				if y < top:
					continue
				var edge := y < top + 1.0 or absi(dx) == 12
				var t := float(y - 24) / 60.0
				var band := int(t * 4.0)
				var c := sky_top.lerp(sky_bot, band / 3.0)
				if edge:
					c = pal["mortar"]
				elif dx == 0 or y == 56:
					c = Color("0a0608")
				img.set_pixel(x, y, c)
		if cold:
			# Luna y nieve.
			for dy in range(-3, 4):
				for dx2 in range(-3, 4):
					if dx2 * dx2 + dy * dy <= 9:
						img.set_pixel(wx - 6 + dx2, 38 + dy, Color("e8f0ff") if dx2 + dy < 1 else Color("b8c8e0"))
			for i in 8:
				img.set_pixel(wx - 10 + (i * 7) % 20, 44 + (i * 11) % 36, Color("d8e8f8"))
		else:
			for i in 5:
				img.set_pixel(wx - 9 + (i * 5) % 18, 40 + (i * 13) % 38, Color("ff8a3a"))
		for y in range(84, 88):
			for x in range(wx - 14, wx + 15):
				img.set_pixel(x, y, (pal["wall"] as Color).lightened(0.16 if y == 84 else 0.06))


## Arco profundo con dovelas y brillo en el fondo.
func _bg_arch(img: Image, pal: Dictionary, cx: int, top: int, half: int, inside: Color, glow: Color) -> void:
	var wall: Color = pal["wall"]
	for y in range(top, FLOOR_Y):
		for x in range(cx - half - 4, cx + half + 5):
			var dx := float(x - cx)
			var r_in := float(half)
			var r_out := float(half + 4)
			var ay := float(top + half + 4)
			var in_arch := false
			var on_ring := false
			if y < ay:
				var d := sqrt(dx * dx + (y - ay) * (y - ay))
				in_arch = d <= r_in
				on_ring = d > r_in and d <= r_out
			else:
				in_arch = absf(dx) <= r_in
				on_ring = absf(dx) > r_in and absf(dx) <= r_out
			if in_arch:
				var t := float(y - top) / float(FLOOR_Y - top)
				var c := inside
				if t > 0.8:
					c = inside.lerp(glow, 0.55)
				elif t > 0.6:
					c = inside.lerp(glow, 0.3)
				elif t > 0.4:
					c = inside.lerp(glow, 0.12)
				img.set_pixel(x, y, c)
			elif on_ring:
				var ang := atan2(float(y) - ay, dx)
				var joint := int(abs(ang) * 9.0) != int(abs(ang + 0.03) * 9.0) if y < ay else (y % 8 == 0)
				var c2 := wall.lightened(0.16 if dx < 0 else 0.06)
				if joint:
					c2 = pal["mortar"]
				img.set_pixel(x, y, c2)
	# Brasas en el fondo del arco.
	for i in 18:
		var ex := cx - half + 2 + (i * 7) % (half * 2 - 3)
		var ey := FLOOR_Y - 2 - (i * 5) % 7
		img.set_pixel(ex, ey, glow.lightened(0.4) if i % 3 == 0 else glow)


func _bg_banners(img: Image, pal: Dictionary, xs: Array) -> void:
	var banner: Color = pal["banner"]
	for bx: int in xs:
		for y in range(10, 58):
			for x in range(bx - 6, bx + 6):
				if y > 50 and absi(x - bx) < (y - 50):
					continue
				var c := banner
				if x == bx - 6 or x == bx + 5:
					c = banner.darkened(0.45)
				elif x == bx - 5:
					c = banner.lightened(0.15)
				elif x >= bx + 3:
					c = banner.darkened(0.15)
				img.set_pixel(x, y, c)
		for x in range(bx - 7, bx + 7):
			img.set_pixel(x, 9, Color("8a6a3a"))
			img.set_pixel(x, 8, Color("2a1e18"))
		var em := icon_image("flame")
		for y in 12:
			for x in 12:
				var p := em.get_pixel(x, y)
				if p.a > 0.0:
					img.set_pixel(bx - 6 + x, 24 + y, p.darkened(0.25))


func _bg_chains(img: Image, rng: RandomNumberGenerator, xs: Array) -> void:
	for cx: int in xs:
		var ln := rng.randi_range(10, 24)
		for y in ln:
			img.set_pixel(cx, y, Color("4a4448") if y % 3 != 2 else Color("221c20"))


## Soporte de antorcha + luz en anillos (sin tramado) sobre el muro.
func _bg_torch(img: Image, tp: Vector2i) -> void:
	for y in range(tp.y - 30, tp.y + 26):
		for x in range(tp.x - 30, tp.x + 31):
			if x < 0 or y < 0 or x >= 320 or y >= FLOOR_Y:
				continue
			var d := Vector2(x - tp.x, (y - tp.y + 4) * 1.15).length()
			var a := 0.0
			if d < 10:
				a = 0.16
			elif d < 18:
				a = 0.10
			elif d < 27:
				a = 0.05
			if a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color("ff9a4a"), a))
	for y in range(tp.y, tp.y + 10):
		img.set_pixel(tp.x, y, Color("4a3a30"))
		img.set_pixel(tp.x + 1, y, Color("2a1e18"))
	for x in range(tp.x - 2, tp.x + 4):
		img.set_pixel(x, tp.y, Color("6a5040"))
		img.set_pixel(x, tp.y + 1, Color("3a2a20"))


## Suelo en perspectiva (punto de fuga centrado; sin línea en el eje central).
func _bg_floor(img: Image, pal: Dictionary, rng: RandomNumberGenerator, act: int) -> void:
	var fl: Color = pal["floor"]
	var mortar: Color = pal["mortar"]
	var vy := float(FLOOR_Y - 22)
	var lights: Array = [52, 268] if act != 1 else [160]
	for y in range(FLOOR_Y, 180):
		var depth := (180.0 - vy) / (float(y) - vy)
		var row_f := depth * 1.6
		var next_f := (180.0 - vy) / (float(y + 1) - vy) * 1.6
		var hline := int(row_f) != int(next_f)
		for x in 320:
			var u := (x - 160.0) * depth / 2.0 + 12.0
			var col_i := int(floor(u / 24.0))
			var vline := fposmod(u, 24.0) < depth * 0.5
			var c := fl.lightened(0.04 if (col_i + int(row_f)) % 2 == 0 else 0.0)
			if y == FLOOR_Y:
				c = fl.lightened(0.22)
			elif y == FLOOR_Y + 1:
				c = mortar
			elif hline or vline:
				c = mortar
			# Charcos de luz (bandas, sin tramado).
			for lx: int in lights:
				var ddx := float(x - lx) / (26.0 + (y - FLOOR_Y) * 0.8)
				var ddy := float(y - FLOOR_Y - 18) / 16.0
				var lg := 1.0 - (ddx * ddx + ddy * ddy)
				if lg > 0.5:
					c = c.lerp(pal["glow"], 0.12)
				elif lg > 0.0:
					c = c.lerp(pal["glow"], 0.06)
			if act == 1 and _hash2(x, y, 3) < 0.004:
				c = pal["accent"]
			elif act == 2 and _hash2(x, y, 5) < 0.01:
				c = Color("d8ecf8")
			# Más oscuro cerca del borde inferior (allí va la mano).
			c = c.darkened(0.35 * clampf(float(y - 150) / 30.0, 0.0, 1.0))
			img.set_pixel(x, y, c)
	if act == 2:
		# Nieve acumulada al pie del muro.
		for x in 320:
			var hgt := int(2.0 + 2.0 * sin(x * 0.21) + 1.5 * sin(x * 0.07 + 1.0))
			for y in range(FLOOR_Y - hgt, FLOOR_Y + 1):
				img.set_pixel(x, y, Color("dce8f4") if y == FLOOR_Y - hgt else Color("a8c0d8"))


func _bg_vignette(img: Image) -> void:
	for y in 180:
		for x in 320:
			var dx := (float(x) - 160.0) / 160.0
			var dy := (float(y) - 99.0) / 99.0
			var v := (dx * dx + dy * dy) * 0.5
			var f := 1.0 - floorf(clampf(v, 0.0, 0.6) * 10.0) / 10.0 * 0.8
			var c := img.get_pixel(x, y) * f
			c.a = 1.0
			img.set_pixel(x, y, c)


# --- Forja ----------------------------------------------------------------------

## Forja de la pantalla principal (64×56, ×4). `heat` 0..1 aviva la boca; `frame` 0..3 anima las brasas.
func forge_sprite(heat: float, frame: int = 0) -> Texture2D:
	var lvl := clampi(int(heat * 4.0), 0, 4)
	var key := "forge:%d:%d" % [lvl, frame % 4]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_draw_forge(64, 56, lvl, frame % 4, true))
	return _cache[key]


## Horno de combate (36×34, ×4).
func furnace_small(heat: float, frame: int = 0) -> Texture2D:
	var lvl := clampi(int(heat * 4.0), 0, 4)
	var key := "furn:%d:%d" % [lvl, frame % 4]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_draw_forge(36, 34, lvl, frame % 4, false))
	return _cache[key]


func _draw_forge(W: int, H: int, lvl: int, frame: int, full: bool) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k: Color = PAL["k"]
	var brick := Color("6a3a30")
	var brick2 := Color("7e4636")
	var mortar := Color("2a1418")
	var hot: Array[Color] = [Color("5a1a0c"), Color("8a2a10"), Color("c24a1a"), Color("ff6a1a"), Color("ffb43a"), Color("ffe08a"), Color("fff4c8")]
	var plinth_y := H - 6 if full else H - 4
	var cx := 28.0 if full else 18.0
	var rx := 24.0 if full else 16.0
	var ry := 34.0 if full else 22.0
	var base_y := float(plinth_y)
	var mouth_hw := 10.0 if full else 7.0
	var mouth_cy := base_y - (10.0 if full else 7.0)
	# Chimenea.
	var chx := int(cx) + (6 if full else 4)
	var chw := 8 if full else 6
	for y in range(0, int(base_y - ry) + 6):
		for x in range(chx, chx + chw):
			var c := brick if (y / 3 + (x - chx) / 4) % 2 == 0 else brick2
			if x == chx or x == chx + chw - 1:
				c = k
			elif y % 3 == 0:
				c = mortar
			if y == 3 or y == 4:
				c = PAL["m"] if y == 3 else PAL["d"]
				if x == chx or x == chx + chw - 1:
					c = k
			if y == 0:
				c = k
			img.set_pixel(x, y, c)
	# Cúpula de ladrillo radial.
	for y in range(int(base_y - ry) - 1, int(base_y)):
		for x in W:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base_y) / ry
			var r := sqrt(dx * dx + dy * dy)
			if r > 1.0:
				continue
			var ring := int((1.0 - r) * ry / 4.0)
			var ang := atan2(dy, dx)
			var arc := ang * r * rx / 6.0 + ring * 0.5
			var ring_edge := int((1.0 - r) * ry / 4.0) != int((1.0 - (r + 1.0 / ry)) * ry / 4.0)
			var brick_edge := int(floor(arc)) != int(floor(arc + 0.17))
			var c := brick if (ring + int(floor(arc))) % 2 == 0 else brick2
			if ring_edge or brick_edge:
				c = mortar
			if r > 1.0 - 1.2 / ry or r > 1.0 - 1.2 / rx and absf(dx) > 0.9:
				c = k
			elif dx < -0.25 and dy < -0.35:
				c = c.lightened(0.12)
			elif dx > 0.45:
				c = c.darkened(0.22)
			# Resplandor de la boca sobre el ladrillo.
			var md := Vector2(x - cx, (y - mouth_cy) * 1.2).length()
			if md < mouth_hw + 5 and c != k and c != mortar:
				c = c.lerp(hot[3], 0.08 + 0.04 * lvl)
			img.set_pixel(x, y, c)
	# Boca: arco con dovelas e interior encendido.
	for y in range(int(mouth_cy - mouth_hw) - 2, int(base_y)):
		for x in range(int(cx - mouth_hw) - 3, int(cx + mouth_hw) + 3):
			var dx2 := x + 0.5 - cx
			var dy2 := y + 0.5 - mouth_cy
			var dist := sqrt(dx2 * dx2 + dy2 * dy2) if dy2 < 0.0 else absf(dx2)
			if dist <= mouth_hw:
				# Interior.
				var depth := (y - (mouth_cy - mouth_hw)) / (base_y - (mouth_cy - mouth_hw))
				var hi := clampi(int(depth * 3.0) + lvl - 1, 0, 6)
				if absf(dx2) > mouth_hw - 2.0:
					hi = maxi(0, hi - 2)
				var c2: Color = hot[hi]
				img.set_pixel(x, y, c2)
			elif dist <= mouth_hw + 2.0:
				var ang2 := atan2(dy2, dx2)
				var joint := int(floor(ang2 * 4.0)) != int(floor((ang2 + 0.08) * 4.0)) if dy2 < 0.0 else (y % 4 == 0)
				var c3 := Color("8a7a70") if dx2 < 0 else Color("6a5a58")
				if joint:
					c3 = mortar
				if dist > mouth_hw + 1.4:
					c3 = k
				img.set_pixel(x, y, c3)
	# Brasas animadas y llamas proporcionales al calor.
	var coal_y := int(base_y) - 3
	for x in range(int(cx - mouth_hw) + 1, int(cx + mouth_hw)):
		for y in range(coal_y, int(base_y)):
			var n := _hash2(x, y, frame * 31 + 7)
			var c4: Color = Color("2a1410")
			if n > 0.72:
				c4 = hot[mini(6, 3 + lvl / 2)]
			elif n > 0.45:
				c4 = hot[2 + mini(lvl, 2)]
			elif n > 0.25:
				c4 = Color("4a2418")
			img.set_pixel(x, y, c4)
		# Lenguas de fuego.
		var fh := int((1.0 + lvl) * (0.4 + 0.6 * _hash2(x, frame, 11)) * (mouth_hw / 8.0))
		for i in fh:
			var yy := coal_y - 1 - i
			if yy < mouth_cy - mouth_hw + 1:
				break
			var t := float(i) / maxf(1.0, fh)
			img.set_pixel(x, yy, hot[clampi(6 - int(t * 4.0) - (2 if lvl < 2 else 0), 2, 6)])
	# Parrilla.
	for x in range(int(cx - mouth_hw), int(cx + mouth_hw) + 1):
		img.set_pixel(x, int(base_y) - 1, k if x % 3 != 0 else Color("4a4048"))
	# Base de piedra.
	for y in range(plinth_y, H):
		for x in range(1, W - 1):
			var c5 := Color("4a4048") if ((x / 6) + (y - plinth_y) / 3) % 2 == 0 else Color("564c54")
			if y == plinth_y:
				c5 = Color("7a7078")
			elif y == H - 1 or x == 1 or x == W - 2:
				c5 = k
			elif (x % 6 == 0) and y > plinth_y:
				c5 = Color("2a2228")
			img.set_pixel(x, y, c5)
	if full:
		# Yunque junto a la forja.
		var ax := 50
		var ay := plinth_y - 9
		var anvil := ["kkkkkkkkkkkk", "kMMMMMMMMMmk", ".kmmmmmmmmk.", "..kkkmmmkk..", "....kmmk....",
			"....kmmk....", "...kmmmmk...", "..kmmmmmmk..", "..kkkkkkkk.."]
		for y in anvil.size():
			var row: String = anvil[y]
			for x in row.length():
				var ch := row[x]
				if ch != "." and ax + x < W:
					img.set_pixel(ax + x - 1, ay + y, PAL[ch])
	return img


## Hoguera grande (32×24, ×4) con 4 fotogramas de llama.
func bonfire(frame: int = 0) -> Texture2D:
	var key := "bonfire:%d" % (frame % 4)
	if _cache.has(key):
		return _cache[key]
	var W := 32
	var H := 24
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k: Color = PAL["k"]
	var ramp: Array[Color] = [PAL["R"], PAL["r"], PAL["o"], PAL["y"], PAL["w"], PAL["Y"]]
	# Llama.
	for x in range(6, 26):
		var cxd := absf(x - 15.5) / 10.0
		var hgt := (1.0 - cxd * cxd) * 17.0 * (0.75 + 0.25 * _hash2(x, frame, 3))
		hgt += 3.0 * sin(x * 0.9 + frame * 1.7)
		var top := int(19 - hgt)
		for y in range(maxi(0, top), 19):
			var t := float(y - top) / maxf(1.0, 19 - top)
			var core := 1.0 - cxd
			var idx := clampi(int(t * 3.0 + core * 2.5), 0, 5)
			img.set_pixel(x, y, ramp[idx])
	# Chispas.
	for i in 4:
		var sx := 8 + int(_hash2(i, frame, 9) * 16)
		var sy := int(_hash2(i, frame, 5) * 6)
		img.set_pixel(sx, sy, PAL["y"] if i % 2 == 0 else PAL["o"])
	# Troncos cruzados.
	var logs := [[4, 19, 27, 16], [5, 16, 27, 20]]
	for lg: Array in logs:
		for s in 24:
			var t2 := s / 23.0
			var lx := int(lerpf(lg[0], lg[2], t2))
			var ly := int(lerpf(lg[1], lg[3], t2))
			for dy in range(-1, 2):
				var c := PAL["n"] if dy < 1 else PAL["h"]
				if dy == -1:
					c = PAL["n"].lightened(0.1)
				img.set_pixel(lx, ly + dy, c)
	# Piedras alrededor.
	for i in 7:
		var px := 2 + i * 4
		for y in range(20, 24):
			for x in range(px, px + 4):
				var c2 := Color("6a6068") if y == 20 else Color("4a4048")
				if x == px or y == 23:
					c2 = k
				img.set_pixel(x, y, c2)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


# --- Viñetas de evento y puertas ----------------------------------------------

const EVENT_SCENES := {
	"altar": ["candle", Color("3a1a2a"), Color("ff8a3a")], "smith": ["anvil", Color("2a1a14"), Color("ff6a1a")],
	"well": ["drop", Color("101a2a"), Color("8ab4d0")], "mirror": ["moon", Color("1a1a2e"), Color("d0d4ff")],
	"merchant": ["chest", Color("2a1e10"), Color("ffcc40")], "forge_spirit": ["furnace", Color("1e1418"), Color("ff7a2a")],
	"gambler": ["gem", Color("201030"), Color("d0a8ff")], "hollow_shrine": ["skull", Color("14141a"), Color("9a5ad0")],
	"frozen_traveller": ["snowflake", Color("0e1a2a"), Color("8ab4d0")], "library": ["book", Color("1e1410"), Color("ffb43a")],
	"anvil_trial": ["hammer", Color("1a1414"), Color("ff6a1a")], "wind_bellows": ["wind", Color("141a22"), Color("c8e0f0")],
	"star_fall": ["star", Color("0e0e24"), Color("ffe08a")], "coal_mine": ["coal", Color("140c0a"), Color("ff6a1a")],
	"tinkerer": ["gear", Color("16161a"), Color("d0d4d8")], "burning_bridge": ["fire_wall", Color("1e0c0a"), Color("ff6a1a")],
}


## Viñeta de evento 96×48 (mostrar a ×4 → 384×192 o ×2): fondo en bandas, cono de luz, pedestal,
## protagonista a 24×24 (EPX) y velas laterales.
func event_art(id: String) -> Texture2D:
	var key := "ev:" + id
	if _cache.has(key):
		return _cache[key]
	var sc: Array = EVENT_SCENES.get(id, ["unknown", Color("1a1418"), Color("ffb43a")])
	var W := 96
	var H := 48
	var bg: Color = sc[1]
	var light: Color = sc[2]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var t := float(y) / H
			var c := bg.darkened(0.3).lerp(bg.lightened(0.08), floorf(t * 4.0) / 4.0)
			if y >= 36:
				c = bg.lightened(0.1) if (y == 36) else bg.darkened(0.1 + 0.04 * ((x / 8 + y / 3) % 2))
			# Cono de luz desde arriba.
			var half := 8.0 + y * 0.45
			if absf(x - 47.5) < half and y < 40:
				c = c.lerp(light, 0.10 if absf(x - 47.5) < half * 0.6 else 0.05)
			img.set_pixel(x, y, c)
	# Pedestal.
	for y in range(30, 38):
		for x in range(34, 62):
			var c2 := Color("5a5058") if y == 30 else Color("3a3238")
			if x == 34 or x == 61 or y == 37:
				c2 = PAL["k"]
			img.set_pixel(x, y, c2)
	# Protagonista.
	var ic := scale2x(icon_image(sc[0]))
	for y in 24:
		for x in 24:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0:
				img.set_pixel(36 + x + 1, 6 + y + 1, bg.darkened(0.6))
	img.blend_rect(ic, Rect2i(0, 0, 24, 24), Vector2i(36, 6))
	# Velas laterales.
	for vx: int in [16, 78]:
		for y in range(28, 36):
			img.set_pixel(vx, y, PAL["W"])
			img.set_pixel(vx + 1, y, Color("c8b498"))
		img.set_pixel(vx, 27, PAL["k"])
		img.set_pixel(vx, 25, PAL["y"])
		img.set_pixel(vx, 26, PAL["o"])
		img.set_pixel(vx + 1, 26, PAL["o"].darkened(0.3))
		for dy in range(-4, 3):
			for dx in range(-4, 5):
				if dx * dx + dy * dy < 14 and img.get_pixel(vx + dx, 26 + dy) != PAL["W"]:
					img.set_pixel(vx + dx, 26 + dy, img.get_pixel(vx + dx, 26 + dy).lerp(Color("ff9a4a"), 0.12))
	# Marco.
	for x in W:
		img.set_pixel(x, 0, PAL["k"])
		img.set_pixel(x, H - 1, PAL["k"])
	for y in H:
		img.set_pixel(0, y, PAL["k"])
		img.set_pixel(W - 1, y, PAL["k"])
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


const DOOR_COLORS := {"combat": Color("c2321e"), "elite": Color("b02a5a"), "rest": Color("ff8a2a"),
	"shop": Color("ffb43a"), "event": Color("9a5ad0"), "treasure": Color("ffd040"), "boss": Color("ff3a1a")}


## Puerta 28×36 (mostrar a ×4 → 112×144): arco de dovelas, interior oscuro, resplandor del destino e icono.
func door_art(kind: String, biome: int = 0) -> Texture2D:
	var key := "door:%s:%d" % [kind, biome]
	if _cache.has(key):
		return _cache[key]
	var W := 28
	var H := 36
	var pal := biome_colors(biome)
	var col: Color = DOOR_COLORS.get(kind, Color("ffb43a"))
	var stone: Color = (pal["wall"] as Color).lightened(0.22)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := 13.5
	var ay := 13.0
	for y in H:
		for x in W:
			var dx := x - cx
			var d := sqrt(dx * dx + (y - ay) * (y - ay)) if y < ay else absf(dx)
			if d <= 9.5:
				var t := float(y) / H
				var c := Color("0c0709").lerp(col.darkened(0.55), clampf((t - 0.45) * 1.6, 0.0, 1.0))
				if t > 0.82:
					c = col.darkened(0.25)
				img.set_pixel(x, y, c)
			elif d <= 13.5:
				var ang := atan2(float(y) - ay, dx)
				var joint := int(floor(ang * 3.0)) != int(floor((ang + 0.12) * 3.0)) if y < ay else (y % 6 == 0)
				var c2 := stone.lightened(0.1) if dx < 0 else stone.darkened(0.1)
				if joint:
					c2 = pal["mortar"]
				if d > 12.6 or d < 10.3:
					c2 = PAL["k"]
				img.set_pixel(x, y, c2)
	# Clave del arco.
	for y in range(0, 4):
		for x in range(12, 16):
			img.set_pixel(x, y, PAL["k"] if (y == 0 or x == 12 or x == 15) else col)
	# Escalón.
	for x in range(1, W - 1):
		img.set_pixel(x, H - 2, stone)
		img.set_pixel(x, H - 1, PAL["k"])
	var ic := icon_image(DOOR_ICONS.get(kind, "unknown"))
	img.blend_rect(ic, Rect2i(0, 0, 12, 12), Vector2i(8, 10))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


const DOOR_ICONS := {"combat": "sword", "elite": "skull", "rest": "bonfire", "shop": "anvil", "event": "eye",
	"treasure": "chest", "boss": "crown"}


## Logotipo EMBERSPIRE (≈100×18) a partir de la fuente pixel engordada ×2 con rampa de fuego.
func logo() -> Texture2D:
	if _cache.has("logo"):
		return _cache["logo"]
	var text := "EMBERSPIRE"
	var cells: Array = []
	var total := 0
	for i in text.length():
		var g := PixelFont.glyph(text[i])
		cells.append(g)
		total += int(g["w"]) * 2 + 2
	var W := total + 4
	var H := 7 * 2 + 6
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ramp: Array[Color] = [PAL["Y"], PAL["w"], PAL["y"], PAL["y"], PAL["o"], PAL["o"], PAL["r"]]
	var x0 := 2
	var on := {}
	for g: Dictionary in cells:
		var rows: Array = g["rows"]
		for gy in 7:
			var row: String = rows[gy + 2]
			for gx in int(g["w"]):
				if row[gx] == "#":
					for sy in 2:
						for sx in 2:
							on[Vector2i(x0 + gx * 2 + sx, 2 + gy * 2 + sy)] = gy
		x0 += int(g["w"]) * 2 + 2
	# Sombra y contorno.
	for p: Vector2i in on:
		for d: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]:
			var q := p + d
			if not on.has(q) and q.x < W and q.y < H:
				img.set_pixel(q.x, q.y, PAL["R"])
	for p: Vector2i in on:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var q2 := p + Vector2i(dx, dy)
				if not on.has(q2) and q2.x >= 0 and q2.y >= 0 and q2.x < W and q2.y < H:
					img.set_pixel(q2.x, q2.y, PAL["k"])
	for p: Vector2i in on:
		var gy2: int = on[p]
		var c: Color = ramp[gy2]
		if not on.has(p + Vector2i(0, -1)):
			c = c.lightened(0.25)
		img.set_pixel(p.x, p.y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache["logo"] = tex
	return tex
