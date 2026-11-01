extends Node
## Arte LEGADO v0.3 (congelado) — Paleta v0.3 (PAL) y rampas de bioma (BIOMES).
## Troceado de scripts/autoload/art.gd sin cambios de comportamiento: cada módulo hereda del anterior
## (cadena legacy_palette → … → legacy_events → Art). No añadir arte nuevo aquí: ver scripts/art/rig/ y SpriteBank.
## Huella de regresión: tools/legacy_snapshot.gd contra tests/art/legacy_hashes.json.

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
