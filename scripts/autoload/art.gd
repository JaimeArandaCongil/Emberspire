extends Node
## Art: banco de pixel art. Todo el arte vive como datos versionables:
##  - SPRITES: mapas ASCII dibujados a mano (heroína, brazo con martillo, forja, iconos).
##  - SHAPES: máscaras de media silueta → monstruos simétricos generados con semilla,
##    sombreados con campo de distancia + luz cenital + tramado, con capa emisiva (ojos, venas).
##  - card_frame() / card_art(): marcos y escenas de carta a media resolución (×2 / ×4).
##  - background(): muros de la torre por bioma con estandartes, antorchas y cadenas.
## Ver docs/ART_BIBLE.md para la paleta y las reglas.

const PAL := {
	"k": Color("1a0f12"), "d": Color("3d2b2e"), "g": Color("5a4040"), "l": Color("7a5a52"),
	"r": Color("c2321e"), "R": Color("7a1a16"), "o": Color("ff6a1a"), "y": Color("ffb43a"), "w": Color("ffe08a"),
	"Y": Color("fff4c8"), "W": Color("f4e4c8"), "b": Color("4a6a8a"), "B": Color("2a3a5a"), "c": Color("8ab4d0"),
	"p": Color("9a5ad0"), "P": Color("d0a8ff"), "G": Color("6ac46a"), "e": Color("2e6a3a"), "s": Color("e0a080"),
	"S": Color("b07050"), "h": Color("6a3020"), "n": Color("8a5030"), "m": Color("9aa0a8"), "M": Color("d0d4d8"),
}

## Biomas: claro, medio, oscuro, acento, ojo, muro, brillo
const BIOMES := [
	{"light": Color("9a8478"), "mid": Color("64504e"), "dark": Color("3c2c32"), "accent": Color("ff6a1a"),
		"eye": Color("ffd040"), "wall": Color("3a2a2c"), "glow": Color("ff7a2a"), "banner": Color("8a2a1a")},
	{"light": Color("a878c8"), "mid": Color("6e4c90"), "dark": Color("3e2a58"), "accent": Color("7ad040"),
		"eye": Color("c8ff60"), "wall": Color("2c2238"), "glow": Color("a0e040"), "banner": Color("3a6a2a")},
	{"light": Color("d0e6f4"), "mid": Color("82aacb"), "dark": Color("4a6a8a"), "accent": Color("e8f8ff"),
		"eye": Color("60d8ff"), "wall": Color("1e2a3a"), "glow": Color("70c8ff"), "banner": Color("2a4a7a")},
]

const SPRITES := {
	# Heroína sin el brazo delantero (se dibuja aparte para animar el martillo).
	"player": [
		"......k..kk.k.......",
		".....kok.koko.k.....",
		"....koyokoyyokok....",
		"...koyyyoyyyyoyok...",
		"...koyyyyyyyyyyok...",
		"..korrooyyyyoorrk...",
		"..krrrrrrrrrrrrrk...",
		"..krWWWWWWWWWWWrk...",
		"..krksssssssssskk...",
		"..krkssksssskssk....",
		"..krksskSsssksSk....",
		"..kkksssssssssSk....",
		"....kSsssrssssk.....",
		".....kkSsssSkk......",
		"....kkddkSSkddkk....",
		"...kdddnnWWWnnddk...",
		"..kddnnnnWWWnnnnk...",
		"..kdgnnnnnnnnnnnk...",
		"..ksgnnnnnnnnnhnk...",
		"..kskhnnnnnnnnhnk...",
		"..kskhhhhyyhhhhhk...",
		"..kSkdddddddddddk...",
		"...kkddddkkddddk....",
		"....kddddkkdddk.....",
		"....kdddk..kdddk....",
		"....kdddk..kdddk....",
		"....kgggk..kgggk....",
		"...khhhhk..khhhhk...",
		"...khnnhhk.khnnhhk..",
		"...kkkkkkk.kkkkkkk..",
	],
	# Brazo delantero con martillo. Pivote del hombro en (3, 1).
	"player_arm": [
		"..kkk...",
		".kdddk..",
		".kdddk..",
		".kdgdk..",
		".kssSk..",
		".kssSk..",
		".kssSk..",
		".koyok..",
		".kowok..",
		".kooyk..",
		"..khk...",
		"..knk...",
		"..khk...",
		".kMMMk..",
		"kMMMmmk.",
		"kMmmmdk.",
		".kkkkk..",
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
		"............", "kkkkkkkkkkkk", "kRrrrrrrrrRk", ".kWkWWkWWkk.", ".kWkWWkWWk..", "..k.kWk.k...",
		"....kWk.....", ".....k......", "............", "............", "............", "............",
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
	"bird": [
		".........", "......oXX", ".....XXXX", "....XXEXX", "....XXXXa", "...XXXXXa", "a.XXXXXXX",
		"aXXXdXXXX", "aXXdXXXXX", ".aXXXXXXX", "..a.XXXXX", "....aa.Xd", "......a..",
	],
	"mite": [
		"..a...", "...a..", "..XXXX", ".XXEXX", "XXXXXX", "XdXXXm", "a.a.a.", ".a.a..",
	],
	"totem": [
		"....oXXXX", "...XXXXXX", "...XEXXXX", "...XXXmmm", ".aaXXXXXX", "aXXXXXXXX", "XXXXddddd", "XXXXdaaaa",
		"XXXXddddd", "XXo.XdaaX", "XX..XXXXX", "aa..XXXXX", "....XXX..", "....XXX..", "...XXXX..", "...XXXX..",
	],
	"serpent": [
		"......oXXX", "....oXXXXX", "...XXXXEXX", "..XXXXXXXX", "..XXXXXmmm", "...XXXXXXX", "....aXXXXd",
		".....XXXdd", "...oXXXXXX", "..XXXXXddX", ".XXXdXXXXX", "XXXXXXXXXX", "aXXXXXdXXX", ".aaaaaaaaa",
	],
	"priest": [
		".....XXX", "....XXXX", "...XXXdd", "...XXdEd", "...XXddd", "..aXXXdd", ".aXXXXXX", "aXXXXXXa", ".XXXXXXa",
		".XXXXXXa", "XXXXXXXa", "XXXXXXXa", "XXXXXXXa", "XXXXXXXX", "XXXXXXXX", "oXXXXXXX", "o.oXXoXX", "...o..o.",
	],
	"moth": [
		"aa........", "..a....XX.", "oXXX..XXXX", "XXXXX.XXEX", "XXaXXXXXXX", "XXXXXXXXXm",
		"oXXaXXXXXX", ".XXXXX.XXX", "..oXX..XXX", "...o...XX.", "........a.",
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
	"boss_bellows": [
		"............", "......aaa...", ".....aXXXXXX", "....XXXXXXXX", "...XXXXXXXXX", "...XXXEEXXXX",
		"...XXXEEXXXX", "...XXXXXXmmm", "...XXXXXXmam", "...XXXXXXmmm", "..dddddddddd", ".XXXXXXXXXXX",
		"dddddddddddd", "XXXXXXXXXXXX", "dddddddddddd", ".XXXXXXXXXXX", "..dddddddddd", "...XXXXXXXXX",
		"..aXX.XXXXXX", ".aaX..XXX.XX", "......XXX...", ".....aaaa...",
	],
	"boss_hydra": [
		".a..........", "XXa.........", "XEXX.....aa.", "XXXmX...XXXX", ".XXXX..XXEXX", "..XXX..XXXXX",
		"...XXX.XXmmm", "...XXX..XXXX", "....XXX.XXXX", ".....XXXXXXX", ".....XXXXXXX", "....XXXXXXXX",
		"...XXXXXXXXX", "..XXXXdXXXXX", "..XXXXdXXXXX", ".oXXXXdXXXXX", ".XXXXXXXXXXX", "XXXXXXXXXXXX",
		"XXXdXXXXdXXX", "aXXXXXXXXXXX", ".a.aXXa.aXXa", "....a....a..",
	],
	"boss_frost": [
		"........a..a", ".......aa.aa", ".......aaaaa", "........XXXX", ".......XXXXX", ".......XEXXX",
		".......XXXmm", "........XXXX", "....aaXXXXXX", "..aXXXXXXXXX", ".aXXXXXXdXXX", "aXXXX.XXdXXX",
		"aXXX..XXdXXX", "a.XX..XXXXXX", "a.....XXXXXX", "a....XXXXXXX", "a....XXXXXXX", "a...XXXXXXXX",
		"...XXXXXXXXX", "..XXXXXXXXXX", ".oXXXXXXXXXX", "aaaaaaaaaaaa",
	],
}

const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

var _cache := {}


func has_icon(id: String) -> bool:
	return SPRITES.has(id) or VARIANTS.has(id)


func has_shape(id: String) -> bool:
	return SHAPES.has(id)


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


func player() -> Texture2D:
	return icon("player")


func player_arm() -> Texture2D:
	return icon("player_arm")


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


func biome_colors(biome: int, cycle: int = 0) -> Dictionary:
	var b: Dictionary = BIOMES[biome % BIOMES.size()]
	if cycle == 0:
		return b
	var out := {}
	for k: String in b:
		var c: Color = b[k]
		out[k] = Color.from_hsv(fposmod(c.h + 0.29 * cycle, 1.0), minf(1.0, c.s + 0.1), c.v)
	return out


# --- Monstruos --------------------------------------------------------------

## Monstruo simétrico generado por semilla a partir de una máscara de forma.
func monster(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache[key]


## Capa emisiva del monstruo (ojos, venas, acentos) para el brillo pulsante.
func monster_glow(shape: String, seed_key: String, biome: int, cycle: int = 0) -> Texture2D:
	var key := "m:%s:%s:%d:%d" % [shape, seed_key, biome, cycle]
	if not _cache.has(key):
		_build_monster(shape, seed_key, biome, cycle, key)
	return _cache[key + ":glow"]


func _build_monster(shape: String, seed_key: String, biome: int, cycle: int, key: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key)
	var half: Array = SHAPES.get(shape, SHAPES["slime"])
	var hw := String(half[0]).length()
	var h := half.size()
	var w := hw * 2
	var cells: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		row.fill("")
		cells.append(row)
	for y in h:
		var src: String = half[y]
		for x in hw:
			var ch := src[x] if x < src.length() else "."
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
			cells[y][x] = v
			cells[y][w - 1 - x] = v
	# Campo de distancia al borde (volumen).
	var dist: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		for x in w:
			row[x] = 0 if cells[y][x] == "" else 99
		dist.append(row)
	for _pass in 4:
		for y in h:
			for x in w:
				if dist[y][x] == 0:
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
	# Venas brillantes (fuego/escoria) o escarcha: caminos aleatorios en el interior.
	var veins := {}
	var vein_count := 2 + rng.randi_range(0, 2)
	for i in vein_count:
		var vx := rng.randi_range(1, hw - 1)
		var vy := rng.randi_range(2, h - 2)
		for step in rng.randi_range(3, 7):
			if vx >= 0 and vy >= 0 and vx < hw and vy < h and cells[vy][vx] == "body" and int(dist[vy][vx]) >= 2:
				veins[Vector2i(vx, vy)] = true
				veins[Vector2i(w - 1 - vx, vy)] = true
			vx += rng.randi_range(-1, 1)
			vy += 1 if rng.randf() < 0.7 else -1
	var pal := biome_colors(biome, cycle)
	var outline: Color = PAL["k"]
	var light: Color = pal["light"]
	var mid: Color = pal["mid"]
	var dark: Color = pal["dark"]
	var deep: Color = dark.darkened(0.35)
	var hi: Color = light.lightened(0.25)
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var glow := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	glow.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var v: String = cells[y][x]
			if v == "":
				continue
			var col: Color
			var emissive := false
			match v:
				"eye":
					col = pal["eye"]
					var up_e: bool = y > 0 and cells[y - 1][x] == "eye"
					var left_e: bool = x > 0 and cells[y][x - 1] == "eye"
					if not up_e and not left_e:
						col = Color("fffbe8")
					emissive = true
				"sclera":
					col = Color("f4e4c8") if (x + y) % 5 != 0 else Color("d8c4a8")
				"mouth":
					col = outline if (x + y) % 2 == 0 or biome == 2 else pal["accent"].darkened(0.5)
				"shade":
					col = dark if dither(x, y, 0.5) else deep
				"accent":
					col = pal["accent"]
					var up_empty: bool = y == 0 or cells[y - 1][x] == ""
					if up_empty:
						col = col.lightened(0.3)
					emissive = biome != 2
				_:
					var up_empty2: bool = y == 0 or cells[y - 1][x] == ""
					var down_empty: bool = y + 1 >= h or cells[y + 1][x] == ""
					var left_empty: bool = x == 0 or cells[y][x - 1] == ""
					var right_empty: bool = x + 1 >= w or cells[y][x + 1] == ""
					var d := float(mini(int(dist[y][x]), 4))
					var lit := 0.32 + 0.09 * d - 0.30 * float(y) / h
					if up_empty2:
						lit += 0.34
					if left_empty:
						lit += 0.14
					if down_empty:
						lit -= 0.32
					if right_empty:
						lit -= 0.10
					lit += rng.randf_range(-0.04, 0.04)
					# Rampa de 5 tonos con tramado Bayer en las transiciones.
					var ramp: Array[Color] = [deep, dark, mid, light, hi]
					var f := clampf(lit, 0.0, 0.999) * 4.0
					var i0 := int(f)
					var frac := f - i0
					var pick := i0 + (1 if dither(x, y, smoothstep(0.25, 0.75, frac)) else 0)
					col = ramp[clampi(pick, 0, 4)]
					if veins.has(Vector2i(x, y)):
						col = pal["glow"] if biome != 2 else Color("e8f8ff")
						emissive = true
			img.set_pixel(x + 1, y + 1, col)
			if emissive:
				glow.set_pixel(x + 1, y + 1, col.lightened(0.2))
	# Contorno de 1 px, coloreado por el tono contiguo en la base (sel-out).
	var out_img := img.duplicate() as Image
	for y in h + 2:
		for x in w + 2:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + dd.x
				var ny: int = y + dd.y
				if nx >= 0 and ny >= 0 and nx < w + 2 and ny < h + 2 and img.get_pixel(nx, ny).a > 0.0:
					out_img.set_pixel(x, y, outline)
					break
	_cache[key] = ImageTexture.create_from_image(out_img)
	_cache[key + ":glow"] = ImageTexture.create_from_image(glow)


# --- Cartas -----------------------------------------------------------------

const TYPE_ART := {
	"attack": [Color("5a1410"), Color("b8401c"), Color("ffb060")],
	"skill": [Color("10203a"), Color("2e5a8a"), Color("a8d8ff")],
	"power": [Color("2a123a"), Color("8a5a1a"), Color("ffd870")],
	"fuel": [Color("1e1210"), Color("6a3418"), Color("ff8a2a")],
	"status": [Color("141418"), Color("3a3a44"), Color("9aa0b0")],
}
const RARITY_GEM := {"starter": Color("8a6a5a"), "common": Color("b0a8a0"), "uncommon": Color("5aa8ff"),
	"rare": Color("ffcc40"), "status": Color("6a6a74"), "token": Color("ff8a4a")}


## Marco de carta 75×105 (se muestra ×2 → 150×210).
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
	var paper := Color("2a1c20").lerp(tc, 0.10)
	var paper2 := paper.lightened(0.05)
	for y in H:
		for x in W:
			var c := paper
			var edge := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			if edge == 0:
				c = outline
			elif edge <= 3:
				# Bisel: luz arriba-izquierda, sombra abajo-derecha.
				var tl := x <= 3 or y <= 3
				var br := x >= W - 4 or y >= H - 4
				c = band
				if edge == 1:
					c = band_hi if tl and not br else band_lo
				elif edge == 3:
					c = band_lo.darkened(0.2)
			else:
				# Papel con tramado leve.
				c = paper2 if dither(x, y, 0.25 + 0.2 * float(y) / H) else paper
				if y > 52:
					c = c.lightened(0.04)
			img.set_pixel(x, y, c)
	# Banda del nombre.
	for y in range(4, 14):
		for x in range(4, W - 4):
			var c2 := band_lo.darkened(0.25)
			if y == 4:
				c2 = band.darkened(0.1)
			elif y == 13:
				c2 = outline
			img.set_pixel(x, y, c2)
	# Ventana de la ilustración (7..67 × 16..46).
	for y in range(15, 48):
		for x in range(6, 69):
			if y == 15 or y == 47 or x == 6 or x == 68:
				img.set_pixel(x, y, outline)
			elif y == 16 or x == 7:
				img.set_pixel(x, y, band_lo.darkened(0.3))
	# Cinta del tipo.
	for y in range(48, 54):
		for x in range(14, W - 14):
			var c3 := band_lo
			if y == 48:
				c3 = band
			elif y == 53:
				c3 = outline
			if x == 14 or x == W - 15:
				c3 = outline
			img.set_pixel(x, y, c3)
	# Remaches.
	for p: Vector2i in [Vector2i(5, 5), Vector2i(W - 7, 5), Vector2i(5, H - 7), Vector2i(W - 7, H - 7)]:
		img.set_pixel(p.x, p.y, band_hi)
		img.set_pixel(p.x + 1, p.y, band)
		img.set_pixel(p.x, p.y + 1, band)
		img.set_pixel(p.x + 1, p.y + 1, band_lo)
	# Gema de rareza (abajo, centro).
	var gem: Color = RARITY_GEM.get(rarity, Color("b0a8a0"))
	var gx := W / 2 - 2
	var gy := H - 5
	for y in range(gy - 1, gy + 4):
		for x in range(gx - 1, gx + 5):
			img.set_pixel(x, y, outline)
	for y in range(gy, gy + 3):
		for x in range(gx, gx + 4):
			img.set_pixel(x, y, gem if (x + y) % 3 != 0 else gem.lightened(0.4))
	# Maestría: ascuas en el lateral izquierdo.
	for i in mastery:
		var my := 58 + i * 7
		var mc := Color("ff8ad8") if mastery >= Game.MASTERY_MAX else Color("ffb43a")
		img.set_pixel(1, my, mc.lightened(0.4))
		img.set_pixel(2, my, mc)
		img.set_pixel(1, my + 1, mc)
		img.set_pixel(2, my + 1, mc.darkened(0.3))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Escena de la ilustración 30×15 (se muestra ×4 → 120×60): degradado tramado, halo, motas e icono con sombra.
func card_art(card_id: String, type: String, icon_id: String) -> Texture2D:
	var key := "ca:" + card_id
	if _cache.has(key):
		return _cache[key]
	var W := 30
	var H := 15
	var cols: Array = TYPE_ART.get(type, TYPE_ART["status"])
	var c0: Color = cols[0]
	var c1: Color = cols[1]
	var c2: Color = cols[2]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(card_id)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cx := W * 0.5 + rng.randf_range(-3.0, 3.0)
	var cy := H * 0.55
	for y in H:
		for x in W:
			var t := float(y) / H
			var base := c0.lerp(c1, 1.0 - t) if dither(x, y, 0.5) else c0.lerp(c1, clampf(0.85 - t, 0.0, 1.0))
			var dx := (x - cx) / 10.0
			var dy := (y - cy) / 6.0
			var g := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0)
			if dither(x, y, g * 0.9):
				base = base.lerp(c2, 0.35 * g + 0.1)
			img.set_pixel(x, y, base)
	# Rayos o vetas según tipo.
	match type:
		"attack":
			for i in 3:
				var sy := rng.randi_range(2, H - 3)
				for x in range(rng.randi_range(0, 6), rng.randi_range(10, W)):
					if (x + i) % 2 == 0:
						img.set_pixel(x, clampi(sy + int(x * 0.2), 0, H - 1), c1.lightened(0.15))
		"power":
			for i in 8:
				var a := TAU * i / 8.0
				for r in range(5, 14):
					var px := int(cx + cos(a) * r * 1.4)
					var py := int(cy + sin(a) * r * 0.7)
					if px >= 0 and py >= 0 and px < W and py < H and r % 2 == 0:
						img.set_pixel(px, py, c2.darkened(0.3))
		"fuel":
			for x in W:
				for y in range(H - 3, H):
					img.set_pixel(x, y, Color("2a140c") if (x + y) % 3 else Color("4a2414"))
	# Motas.
	for i in 7:
		var px := rng.randi_range(0, W - 1)
		var py := rng.randi_range(0, H - 1)
		img.set_pixel(px, py, c2 if i % 2 == 0 else c2.lightened(0.3))
	# Icono con sombra.
	var ic := icon_image(icon_id)
	var ox := int(W / 2.0 - 6)
	var oy := 2
	for y in 12:
		for x in 12:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0 and x + ox + 1 < W and y + oy + 1 < H:
				img.set_pixel(x + ox + 1, y + oy + 1, c0.darkened(0.5))
	for y in 12:
		for x in 12:
			var p2 := ic.get_pixel(x, y)
			if p2.a > 0.0:
				img.set_pixel(x + ox, y + oy, p2)
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
				elif lit > 0.15 or dither(x, y, lit + 0.4):
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
				if int(dx + dy) % 10 < 1:
					c = Color("6a2a1a")
				elif dither(x, y, clampf(1.0 - (dx + dy) / 60.0, 0.0, 1.0) * 0.5):
					c = Color("4a2018")
			img.set_pixel(x, y, c)
	var ic := icon_image("flame")
	for y in 12:
		for x in 12:
			var p := ic.get_pixel(x, y)
			if p.a > 0.0:
				for sy in 2:
					for sx in 2:
						img.set_pixel(26 + x * 2 + sx, 40 + y * 2 + sy, p)
	var t := ImageTexture.create_from_image(img)
	_cache["cb"] = t
	return t


# --- Escenarios ---------------------------------------------------------------

## Posiciones (en píxeles del fondo 320×180) de las antorchas, para que la UI ponga llamas.
const TORCHES: Array[Vector2i] = [Vector2i(22, 70), Vector2i(130, 62), Vector2i(190, 62), Vector2i(298, 70)]


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
	# Ladrillos con bisel y desgaste.
	for by in range(0, floor_y, 8):
		var row := by / 8
		var off := 0 if row % 2 == 0 else 8
		for bx in range(-off, W, 16):
			var tone := wall.lightened(rng.randf_range(-0.06, 0.10))
			if rng.randf() < 0.06:
				tone = wall.darkened(0.25)
			var cracked := rng.randf() < 0.08
			for y in range(by, mini(by + 8, floor_y)):
				for x in range(maxi(bx, 0), mini(bx + 16, W)):
					var edge := y == by or x == bx
					var c := mortar if edge else tone
					if not edge and y == by + 1:
						c = c.lightened(0.10)
					elif not edge and y == by + 7:
						c = c.darkened(0.12)
					if cracked and not edge and (x - bx) == 4 + (y - by) / 2:
						c = mortar
					img.set_pixel(x, y, c)
	# Columnas.
	for px: int in [0, 100, 220, 312]:
		for y in floor_y:
			for x in range(px, mini(px + 8, W)):
				var c := wall.lightened(0.12)
				if x == px or x == px + 7:
					c = mortar
				elif x == px + 1:
					c = wall.lightened(0.22)
				if y % 24 == 0:
					c = mortar
				img.set_pixel(x, y, c)
	# Ventanas arqueadas con luz del acto.
	var glow: Color = pal["glow"]
	for wx: int in [64, 256]:
		for y in range(26, 84):
			for x in range(wx - 13, wx + 13):
				var dx := x - wx
				var top := 40 - sqrt(maxf(0.0, 169.0 - dx * dx))
				if y >= top:
					var t := float(y - 26) / 58.0
					var c := Color("120a0e").lerp(glow.darkened(0.5), 0.45 * (1.0 - t))
					if dx == 0 or (y - 26) % 14 == 0:
						c = Color("0a0608")
					img.set_pixel(x, y, c)
		for y in range(84, 88):
			for x in range(wx - 15, wx + 15):
				img.set_pixel(x, y, wall.lightened(0.18 if y == 84 else 0.08))
	# Estandartes con emblema de llama.
	var banner: Color = pal["banner"]
	for bx: int in [150, 170]:
		for y in range(10, 58):
			for x in range(bx - 7, bx + 7):
				var tail := y > 50 and absi(x - bx) < (y - 50)
				if tail:
					continue
				var c := banner
				if x == bx - 7 or x == bx + 6:
					c = banner.darkened(0.4)
				elif x == bx - 6:
					c = banner.lightened(0.15)
				img.set_pixel(x, y, c)
		for x in range(bx - 8, bx + 8):
			img.set_pixel(x, 9, Color("8a6a3a"))
		var em := icon_image("flame")
		for y in 12:
			for x in 12:
				var p := em.get_pixel(x, y)
				if p.a > 0.0:
					img.set_pixel(bx - 6 + x, 26 + y, p.darkened(0.15))
	# Cadenas colgantes.
	for cx: int in [40, 115, 205, 280]:
		var ln := rng.randi_range(12, 30)
		for y in ln:
			var c := Color("5a5458") if y % 3 != 2 else Color("2a2428")
			img.set_pixel(cx, y, c)
			if y % 3 == 0:
				img.set_pixel(cx + 1, y, Color("3a3438"))
	# Soportes de antorcha.
	for tp: Vector2i in TORCHES:
		for y in range(tp.y, tp.y + 10):
			img.set_pixel(tp.x, y, Color("4a3a30"))
			img.set_pixel(tp.x + 1, y, Color("2a1e18"))
		for x in range(tp.x - 2, tp.x + 4):
			img.set_pixel(x, tp.y, Color("6a5040"))
			img.set_pixel(x, tp.y + 1, Color("3a2a20"))
		# Luz cálida sobre el muro.
		for y in range(tp.y - 26, tp.y + 22):
			for x in range(tp.x - 24, tp.x + 26):
				if x < 0 or y < 0 or x >= W or y >= floor_y:
					continue
				var dx := float(x - tp.x) / 24.0
				var dy := float(y - tp.y + 4) / 24.0
				var g := 1.0 - sqrt(dx * dx + dy * dy)
				if g > 0.0 and dither(x, y, g * 0.7):
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color("ff9a4a"), 0.18 * g + 0.04))
	# Suelo en perspectiva.
	for y in range(floor_y, H):
		var depth := float(y - floor_y) / float(H - floor_y)
		for x in W:
			var persp := int((x - W * 0.5) / (1.0 + depth * 1.5))
			var tile := ((persp + 400) / 20 + (y - floor_y) / 8) % 2 == 0
			var c := wall.lightened(0.16 if tile else 0.08)
			if y == floor_y:
				c = wall.lightened(0.38)
			elif y == floor_y + 1:
				c = mortar
			elif (persp + 400) % 20 == 0 or (y - floor_y) % 8 == 0:
				c = mortar
			# Charcos de luz de las ventanas.
			for wx: int in [64, 256]:
				var ddx := float(x - wx) / (30.0 + depth * 20.0)
				var ddy := (depth - 0.45) / 0.35
				var lg := 1.0 - (ddx * ddx + ddy * ddy)
				if lg > 0.0 and dither(x, y, lg * 0.6):
					c = c.lerp(glow, 0.12)
			img.set_pixel(x, y, c)
	# Escombros por bioma.
	for i in 18:
		var px := rng.randi_range(0, W - 1)
		var py := rng.randi_range(floor_y + 3, H - 2)
		var c4: Color = pal["accent"].darkened(0.45) if biome != 2 else Color("c8e0f0")
		img.set_pixel(px, py, c4)
	# Viñeta.
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			var dx := (float(x) - W * 0.5) / (W * 0.5)
			var dy := (float(y) - H * 0.55) / (H * 0.55)
			var vig := clampf(1.0 - (dx * dx + dy * dy) * 0.45, 0.35, 1.0)
			c = c * vig
			c.a = 1.0
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Forja de la pantalla principal (48×40). `heat` 0..1 aviva el color de la boca.
func forge_sprite(heat: float) -> Texture2D:
	var lvl := clampi(int(heat * 4.0), 0, 4)
	var key := "forge:%d" % lvl
	if _cache.has(key):
		return _cache[key]
	var W := 48
	var H := 40
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k: Color = PAL["k"]
	var brick := Color("6a3a30")
	var brick2 := Color("8a4a38")
	var mortar := Color("2a1418")
	var hot: Array[Color] = [Color("8a2a10"), Color("c24a1a"), Color("ff6a1a"), Color("ffb43a"), Color("ffe08a")]
	# Chimenea.
	for y in range(0, 12):
		for x in range(20, 28):
			var c := brick if (y / 3 + (x - 20) / 4) % 2 == 0 else brick2
			if x == 20 or x == 27:
				c = k
			elif y % 3 == 0:
				c = mortar
			img.set_pixel(x, y, c)
	# Cúpula.
	for y in range(8, 36):
		for x in W:
			var dx := (x - W * 0.5) / 22.0
			var dy := (y - 30.0) / 22.0
			var r := sqrt(dx * dx + dy * dy)
			if y >= 30:
				r = absf(dx)
			if r > 1.0:
				continue
			var c := brick if ((y / 4) + (x + (y / 4) % 2 * 3) / 6) % 2 == 0 else brick2
			if y % 4 == 0 or (x + (y / 4) % 2 * 3) % 6 == 0:
				c = mortar
			if r > 0.93:
				c = k
			elif dx < -0.3 and dy < 0.0:
				c = c.lightened(0.12)
			elif dx > 0.4:
				c = c.darkened(0.2)
			img.set_pixel(x, y, c)
	# Boca del horno.
	for y in range(20, 34):
		for x in range(14, 34):
			var dx := (x - 23.5) / 10.0
			var dy := (y - 27.0) / 7.0
			if y < 27 and dx * dx + dy * dy > 1.0:
				continue
			var e := 1.0 - absf(dx) * 0.6 - maxf(0.0, (27.0 - y) / 10.0)
			var idx := clampi(int(e * 3.0) + lvl - 1, 0, 4)
			var c: Color = hot[idx] if dither(x, y, 0.6) else hot[maxi(0, idx - 1)]
			if x == 14 or x == 33 or (y < 27 and dx * dx + dy * dy > 0.82):
				c = k
			img.set_pixel(x, y, c)
	# Base de piedra.
	for y in range(34, 40):
		for x in range(2, 46):
			var c := Color("4a4048") if (x / 5 + y) % 2 == 0 else Color("5a5058")
			if y == 34:
				c = Color("7a7078")
			elif y == 39 or x == 2 or x == 45:
				c = k
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t
