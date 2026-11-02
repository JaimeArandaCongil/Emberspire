# API del HUD de combate v0.4 (para TEC)

Widgets autónomos en `scripts/ui/hud/`. Cada uno es un `Control` con `class_name`: se crea con `.new()`, se añade y se
alimenta con los métodos de abajo. Ninguno mira el motor de combate salvo `StatusRow.set_fighter()` y `TopHud` (que lee `Game`).
Todo va en rejilla ×2 y en paleta. **Tras recibir estos archivos hay que reimportar una vez**
(`--headless --path . --import`) para registrar los `class_name`.

Todas las coordenadas son de pantalla (1280×720). Las posiciones son propuestas compatibles con la disposición cerrada; las
decide quien integra. Render de muestra: `tests/_review_art/v04/cartas_ui/out/p2_hud.png`.

| Widget | Tamaño | Sustituye a (combat_screen / fighter_view / main) | Posición propuesta |
|---|---|---|---|
| `TopHud` | 1280×30 | `main._build_hud()` | (0, 0) |
| `FloorLabel` | automático, 34–50 alto | etiqueta "Piso N · Acto" | y = 30, centrado en x = 640 |
| `EnergyCrucible` | 92×88 | `orb` + `_energy_label` | (26, 610) |
| `BurnPlate` | 132×30 | etiqueta "Quemas: N" | (26, 568), junto a la Forja |
| `HpPlate` | 156×22 (+30 a la izquierda con bloqueo) | barra `_draw` + `_hp_label`, `_block_*` | bajo cada luchador |
| `IntentView` | automático, 22 alto | `_intent_box` | `place_above(x_cabeza, y_cabeza − 36)` (18 px de arte) |
| `StatusRow` | celdas 30×26 | `_status_row` | bajo `HpPlate` |
| `PileCounter` | 96×46 | `_pile_button()` | robo (130, 650); descarte (1000, 662); exilio (1140, 662) |
| `EndTurnButton` | 136×40 | botón de fin de turno | (1130, 606) |

## Firmas

```gdscript
# TopHud: barra superior. Lee Game; las Ascuas ruedan solas en _process.
var hud := TopHud.new()
hud.refresh()                       # producción, Braseros, Polvo, Calor (Game.run.heat(), oculto si es 0)
hud.pulse()                         # la brasa salta al recibir Ascuas
hud.ember_anchor() -> Vector2       # destino global de las monedas-brasa
signal audio_pressed                # conectar a main._toggle_audio()

# FloorLabel: fija position.y; `center_x` (640 por defecto) centra la placa.
label.set_floor(n: int, act_name: String, extra: String = "")   # extra = "Calor de Pacto 3 · +60% Ascuas"

# EnergyCrucible
crucible.set_energy(cur: int, max_energy: int)
crucible.deny()                     # sacudida: no hay energía

# BurnPlate
plate.set_burns(cur: int, max_shown: int = 1)
plate.flash()                       # al quemar

# HpPlate: el bloqueo cuelga 30 px a la izquierda del widget.
hp.set_values(hp: int, max_hp: int, block: int = 0, scorch: int = 0)
hp.snap()                           # sin animación (al crear el luchador)

# IntentView: kind = fighter.intent["kind"]; damage/hits = engine.intent_damage(f) (x, y); damage < 0 = sin cifra.
intent.set_intent(kind: String, damage: int = -1, hits: int = 1, tip: String = "")
intent.place_above(x: float, y: float)   # llamar DESPUÉS de set_intent: depende del ancho
# Golpes de 20+ cambian solos a icono y cifra de "attack_heavy". Tipos: attack, attack_debuff, attack_defend,
# defend, buff, debuff, steal, summon; cualquier otro muestra el ojo "unknown".

# StatusRow (HBoxContainer)
row.set_fighter(f: Fighter)         # estados + Poderes si es la jugadora. Usa FighterView.STATUS_NAMES/STATUS_DESC: no las quites.
row.set_items(items: Array)         # [{"id": "scorch", "value": 3, "tooltip": "..."}] o {"texture": Texture2D, ...}

# PileCounter
var pile := PileCounter.new("draw") # "draw" | "discard" | "exhaust"
pile.set_count(n: int)
pile.enabled = false                # p. ej. mientras `busy`
pile.card_anchor() -> Vector2       # centro global, para DRAW_POS / DISCARD_POS
signal pressed

# EndTurnButton (Button): usa pressed y disabled normales. Ya hace Sfx.play("click").
button.set_hint(on: bool)           # sin jugadas: el borde late
```

## Iconos sueltos
`HudArt.intent_texture(kind)` y `HudArt.status_texture(id)` devuelven `ImageTexture` de 18×18 px.
Listas: `HudArt.INTENTS`, `HudArt.STATUSES`. Los Poderes siguen con icono v0.3 ajustado a paleta (`HudArt.legacy_icon(id)`).

## Medidas de la mano (repetidas de fase 1)
`CardView.SIZE` = 160×224. En reposo y = 592 (`PEEK` = 128 px visibles). En hover y ≤ 496. Fuera del rectángulo: orbe 12 px,
aura 18 px, placa de quemar 54 px arriba y 30 px a cada lado. 10 cartas: paso de 90 px en x 150–1120.

## Sin hacer
- `set_hint()` y `deny()` no se han visto en una partida real; sólo el render de muestra sobre el keyframe.
- Las Quemas en las rejillas del zócalo de la Forja (firma diegética de DA) son de la Forja de combate; `BurnPlate` es la lectura
  exacta del número.
