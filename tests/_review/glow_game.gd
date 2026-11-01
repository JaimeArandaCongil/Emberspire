extends "res://scripts/autoload/game_state.gd"
## Prototipo de revisión (NO es código del juego): Resplandor + término de producción reducido en la quema.
var glow := 0.0
var burn_secs := 1.0

func production() -> float:
	return super.production() * (1.0 + glow)

func burn_value(card_cost: int, mult: int, floor_num: int, mastery_lvl: int = 0) -> float:
	var v := (4.0 + 3.0 * maxi(card_cost, 0)) * floor_factor(floor_num) * mult + production() * burn_secs * mult
	return v * (1.0 + 0.2 * mastery_lvl)

var wave_scale := 1.0

func victory_wave(kind: String) -> float:
	return super.victory_wave(kind) * wave_scale
