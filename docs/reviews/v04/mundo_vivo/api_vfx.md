# API de efectos de combate y sala (MV · v0.4, paquete F2-FX)
Firmas estables para el integrador. Todo va en **coordenadas de mundo** (px de arte 640×360). Para pasar desde la UI: `wv.ui_to_world(p)`.
Colores siempre de `Palette`; rejilla entera; un solo efecto héroe a la vez.

## Montaje (una vez por combate)
```gdscript
var room := BakedRooms.load_room(BakedRooms.kind_for(f.is_elite, f.is_boss), run.floor_num)   # {} si no está horneada
if room.is_empty(): pass                         # respaldo: fondo anterior (y no crees lo de abajo)
var state := AmbientState.from_game()
var view := Act1RoomView.new()
wv.world.add_child(view)                         # añádelo al árbol antes de build()
view.build(room, state, wv.lights, wv.lit_material)

var forge := CombatForge.new().setup(wv.lit_material)   # null = vista previa en color
view.actors.add_child(forge)                     # position (0,0): dibuja ya en x 8–112. Añádela ANTES que la heroína
var burn := BurnFX.new().setup(forge, state, wv.lights)
var hit := HitFX.new().setup(state)
var deaths := DeathEmbers.new()
var summon := SummonFX.new()
for n: Node in [burn, hit, deaths, summon]:
	view.fx_layer.add_child(n)                   # encima de actores, debajo del primer plano
```
`view.fx_layer` es nuevo. Sólo acto 1 (bioma 0): para otros biomas usa el fondo anterior.
`BakedRooms.load_room(kind, floor_num)`: `kind` = `"normal"` | `"flue"`. El ciclo sale del piso; también admite `load_room(kind, floor_num, cycle)`.

## Estado que hay que alimentar (en `_refresh_labels` / eventos `burns`, `energy`)
| Llamada | Efecto |
|---|---|
| `state.heat = 0.3 + 0.7 * clampf(engine.heat() / 11.0, 0, 1)` | Braseros y humo. El rig lo copia solo |
| `forge.set_heat(heat: float)` | 0..1. Llama de la boca (bajo / medio / alto) y humo de chimenea |
| `forge.set_burns(left: int)` | Rejillas encendidas: hasta 5. Con más de 5, las 5 encendidas y destello doble |
| `state.low_hp = bool` / `state.glow = bool` | PV bajos · Resplandor (motas doradas, llama avivada) |
| `state.pulse_strike(amount)` | En cada golpe: los ≥ 20 sacuden el crisol |

## `CombatForge` (`scripts/ui/world/combat_forge.gd`, Node2D)
```gdscript
func setup(material: ShaderMaterial = null) -> CombatForge
func set_heat(v: float) -> void
func set_burns(left: int) -> void
func swallow(duration := 0.26) -> void   # abre la boca: fotograma de tragar
func flash(frames := 2) -> void          # boca en blanco (a 30 fps de arte); lo llama BurnFX
func mouth_pos() -> Vector2              # centro de la boca
func chimney_top() -> Vector2            # salida de humo y columna
func deny() -> void                      # sin Quemas: la boca escupe un humito y las rejillas parpadean
func has_art() -> bool                   # false si falta el horneado: usa el horno anterior
```
Sustituye a `_furnace`, `_furnace_fire`, `_furnace_halo`. `_furnace_mouth()` pasa a ser `wv.world_to_ui(forge.mouth_pos())`. La etiqueta «Quemas» puede seguir como UI; las rejillas ya la muestran en el mundo.

## `BurnFX` (`scripts/ui/world/fx/burn_fx.gd`, Node2D): momento estrella
```gdscript
func setup(forge: CombatForge, state: AmbientState, rig: LightRig = null) -> BurnFX
func play(card_type: String, hot: bool, origin: Vector2, coin_target := Vector2(-1, -1), mastery_level := 0) -> void
static func flight_point(origin: Vector2, mouth: Vector2, t: float) -> Vector2   # arco en mundo, t 0..1
signal impact(hot: bool, shake_px: float, hitstop_s: float)   # t = 340 ms
signal interactive()          # t = 350 ms: devuelve el control al jugador
signal coin_arrived()         # primera moneda-brasa en el contador: enseña aquí «+N»
signal finished()             # t ≈ 900 ms (1300 con runa de Maestría)
func show_mastery(level: int) -> void   # evento `mastery` posterior: añade la runa al efecto en curso
func is_playing() -> bool
const FLIGHT_START := 0.08 ; const FLIGHT_TIME := 0.26
```
- `card_type` = `card.type()`: `attack`, `skill`, `power`, `fuel`, `status`. Elige el color de la columna.
- `origin` = centro de la carta en mundo. `coin_target` = contador de Ascuas en mundo; sin él no hay monedas y `coin_arrived` salta a los 380 ms.
- `mastery_level` > 0: runa flotante sobre el horno. Si la Maestría llega como evento aparte, usa `show_mastery(level)`.

**BurnFX hace:** inspiración, boca abierta, copos, destello, columna, conducto brida a brida, rejilla, chispas del tiro, onda de luz (`state.pulse_burn(hot, false)`, no lo llames tú).
**La pantalla hace:** subir la carta 6 px y calentar su marco (0–80 ms); volarla de `FLIGHT_START` a `FLIGHT_START + FLIGHT_TIME` por detrás de la heroína con `flight_point` (o su tween actual); `cv.queue_free` al llegar; `Sfx`; y al recibir `impact`, `main.shake(shake_px)` + `_hitstop(hitstop_s)`. Si el hitstop congela `Engine.time_scale`, BurnFX se congela con él: es lo correcto.
Una segunda quema durante la anterior reinicia el efecto. Retira `UI.sparks`, `main.fly_embers` y `float_text` de este evento.

## `HitFX` (`scripts/ui/world/fx/hit_fx.gd`, Node2D)
```gdscript
func setup(state: AmbientState = null) -> HitFX
func strike(pos: Vector2, amount: int, biome_ramp: StringName = &"fire") -> void   # normal (<20) o fuerte (≥20), elige solo
func normal(pos: Vector2, biome_ramp: StringName = &"fire") -> void
func heavy(pos: Vector2, biome_ramp: StringName = &"fire") -> void
func sweep(x0: float, x1: float, y: float) -> void    # a TODOS: arco de izquierda a derecha, 180 ms
func blocked(pos: Vector2) -> void                    # sin daño
func player_hit(pos: Vector2) -> void                 # astillas rojas. La bufanda es del rig
```
`pos` = punto de contacto en mundo. `strike` también avisa a `state.pulse_strike`. Hitstop, número y sonido siguen en la pantalla. Evento `damage`: `amt > 0` → `strike` (o `player_hit` si el objetivo es la heroína); `amt == 0 and blocked > 0` → `blocked`. Para `sweep`, una vez por carta, no por objetivo.

## `DeathEmbers` (`scripts/ui/world/fx/death_embers.gd`, Node2D)
```gdscript
func play(source: Variant, top_left: Vector2, sink: Vector2, max_embers := 40) -> void
signal first_out(world_pos: Vector2)   # primera brasa fuera: enseña aquí «+Ascuas»
signal finished()
```
- `source`: `Texture2D` o `Image` del fotograma del monstruo (índice o color) o `Rect2` si no hay. Toma los píxeles emisivos y de brasa; si hay pocos, completa con muestras del cuerpo.
- `top_left`: esquina del fotograma en mundo.
- `sink`: `view.ember_sink()`. En la sala de tiro suben al vacío; en la normal, al fondo del corredor.
- Duración 1,2 s. Lánzalo tras el destello y durante la disolución. Quita las 60 chispas y encola textos 150 ms.

## `StatusFX` (`scripts/ui/world/fx/status_fx.gd`, Node2D): uno por luchador
```gdscript
func setup(body: Rect2, is_player: bool, mask: Image = null) -> StatusFX   # body = caja del sprite en mundo
func set_body(body: Rect2) -> void      # al recolocar enemigos
func set_mask(mask: Image) -> void      # fotograma actual para seguir el contorno (opcional)
func sync(statuses: Dictionary, block: int) -> void   # en cada refresh del luchador
func scorch_tick() -> void              # al tick de daño: una llama salta
```
Claves de `fighter.statuses`: `scorch` (llamitas, 1–3), `str` (venas + 2 anillos al ganar), `weak` (gotas violeta), `vuln` (grietas + destello). `block` > 0: contorno en el borde que mira al rival, escudo al ganar, 5 esquirlas al perder. `sync` detecta por sí mismo ganancias y pérdidas: llámalo sin más. Con `is_player = true` el borde es el derecho. Una sola animación en bucle por luchador. Añádelo a `view.fx_layer`; `queue_free()` al morir.

## `SummonFX` (`scripts/ui/world/fx/summon_fx.gd`, Node2D)
```gdscript
func play(foot: Vector2, width: int, reveal: Callable = Callable()) -> void   # foot: centro de los pies en el suelo (y = 264)
signal finished()   # 400 ms
```
Grieta del suelo (3 f) y polvo lateral (4 f). `reveal.call(f)` recibe `f` 0→1 en la fase de emerger (120–400 ms): el sprite aparece de abajo arriba y esa disolución inversa es del luchador (`nv.spawn()` o el rig). Sin `Callable`, sólo suelo y polvo: llama a `nv.spawn()` junto a `play`.

## `Act1RoomView` y `AmbientState`
- Añadidos: `view.fx_layer`, `view.ember_sink() -> Vector2`.
- `state.pulse_burn` y `state.pulse_inhale` los dispara BurnFX. Sigue habiendo `view.set_parallax(mx)`.
- `view.build` admite también `BgAct1.build(...)` para pruebas, pero en juego usa siempre `BakedRooms`.

## Horneado
`godot --headless --path . -s res://tools/bake_rooms.gd` y luego `--import`. Frescura en `tests/art/test_mv.gd`. Si cambias `scripts/art/bg/**` o `ambient_frames.gd`, hay que rehornear. `tools/qa.sh bake` no lo llama.

## Luces
`LightRig` admite 4. Sala normal: 2 braseros + crisol. Tiro: 2 braseros. BurnFX toma 1 durante la columna y la suelta. Si la pantalla añade luces móviles, que no pase de 1.
