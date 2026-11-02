class_name AmbientState
extends RefCounted
## Interfaz mínima entre el estado del juego y el ambiente (MV · v0.4). Los nodos ambientales SÓLO leen esto;
## quien lo alimenta (pantalla de combate, Forja, pruebas) decide de dónde salen los valores.
## `from_game()` es el único sitio que toca `Game`, y lo hace con comprobaciones (el juego puede no estar cargado).

## La carta entra en la boca: onda de luz (LightRig).
signal burned(hot: bool)
## El calor ha recorrido el conducto y llega al tiro: chispas y rejilla.
signal burn_reached_flue(hot: bool)
signal struck(amount: int)

## Calor del combate/pacto, 0..1 (aviva braseros y humo).
var heat := 0.3
## Producción de la Forja normalizada, 0..1 (logarítmica): chispas del tiro, rejilla, manómetro.
var production := 0.4
## Resplandor activo (bonus temporal de producción).
var glow := false
## PV bajos (< 25 %): la sala se apaga un poco.
var low_hp := false
var cycle := 0
## Pulso de quemar, 1 → 0 en ~1 s. Los braseros se inclinan hacia el horno mientras dura.
var burn_pulse := 0.0
var burn_hot := false


## Inspiración previa a quemar: las llamas se inclinan hacia el horno, sin onda de luz todavía.
func pulse_inhale() -> void:
	burn_pulse = maxf(burn_pulse, 0.8)
	burn_hot = false


## Quemar. `flue_now = false` si BurnFX va a avisar al tiro cuando el calor recorra el conducto.
func pulse_burn(hot: bool = false, flue_now: bool = true) -> void:
	burn_pulse = 1.0
	burn_hot = hot
	burned.emit(hot)
	if flue_now:
		burn_reached_flue.emit(hot)


func pulse_flue(hot: bool = false) -> void:
	burn_reached_flue.emit(hot)


func pulse_strike(amount: int) -> void:
	struck.emit(amount)


func tick(delta: float) -> void:
	burn_pulse = maxf(0.0, burn_pulse - delta * (0.8 if burn_hot else 1.1))


## Producción (Ascuas/s) → 0..1 en escala logarítmica: 10/s ≈ 0.11, 1K/s ≈ 0.33, 1M/s ≈ 0.67, 1G/s = 1.
static func normalize_production(per_second: float) -> float:
	return clampf(log(maxf(per_second, 0.0) + 1.0) / log(10.0) / 9.0, 0.0, 1.0)


## Lee el estado real del juego si existe (autoload `Game`); valores neutros si no.
static func from_game(tree: SceneTree = null) -> AmbientState:
	var s := AmbientState.new()
	var game: Object = null
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		game = tree.root.get_node_or_null(^"Game")
	if game == null:
		return s
	if game.has_method("production"):
		s.production = normalize_production(float(game.call("production")))
	if game.has_method("glow_active"):
		s.glow = float(game.call("glow_active")) > 0.0
	var run: Variant = game.get("run")
	if run is Object and run != null:
		if (run as Object).has_method("heat"):
			s.heat = clampf(float((run as Object).call("heat")) / 11.0, 0.0, 1.0) * 0.7 + 0.3
		var fl: Variant = (run as Object).get("floor_num")
		if fl != null:
			s.cycle = int((int(fl) - 1) / 30)
	return s
