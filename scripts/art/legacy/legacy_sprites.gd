extends "res://scripts/art/legacy/legacy_palette.gd"
## Arte LEGADO v0.3 (congelado) — Iconos 12×12 y heroína 24×36 en ASCII (SPRITES) + variantes por recoloreo (VARIANTS).
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

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
