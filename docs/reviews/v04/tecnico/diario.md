# Diario · Artista técnico (TEC) · Fase 1

## Fachada `Art`
- `art.gd` (2.567 líneas) pasa a ser una fachada de 15 líneas sobre una cadena de herencia en `scripts/art/legacy/`:
  `legacy_palette → sprites → monster_data → core → hero → monsters → cards → scenery → forge → events → Art`.
- **Por qué herencia y no composición:** los módulos se cortan sin tocar ni una línea de lógica, y `Art.SPRITES` y demás siguen resolviendo.
  Es una capa congelada que va a desaparecer, no un patrón para código nuevo. Único movimiento: `_hash2` pasa a `core` porque también lo usan las cartas.
- **Evidencia:** `tools/legacy_snapshot.gd` calcula el hash de 2.071 resultados de la API de `Art`. Antes y después del troceo: 0 diferencias. `test_runner`: 1745/0.
- **Capturas del smoke:** no se pueden comparar píxel a píxel porque dependen del tiempo (animaciones y partículas). Antes/después difiere un 0–12 %;
  dos ejecuciones del MISMO código difieren un 0–10,5 %. Es ruido de temporización; la prueba de equivalencia real es la huella.
- **Cambio de línea base (conviene revisarlo):** tras el trabajo de UI cambiaron los 240 `card_frame` y nada más (comparado entrada a entrada).
  Causa: `UI.TYPE_COLORS` en `ui.gd` ahora sale de `Palette`, y el marco legado lo lee. El código legado no cambió (diff contra el original).
  Regeneré `tests/art/legacy_hashes.json`. **Es un cambio visible en el juego, y es de UI, no del troceo.**

## Formato de índice
`formato_indice.md` y `IndexFormat`. Adopté la disposición que MV ya usaba (R material, G paso + banderas, BA ancla, A = 0 vacío). Único cambio para MV: R = `Palette.index`.
Diferencia de semántica con el texto de MV: CANTO suma +1 cuando la luz DINÁMICA en el ancla es ≥ +1 (el shader no conoce la luz horneada por separado).

## Motor de rig v1
API: `api_rig.md`. Ejemplos: `scripts/art/rig/examples/golem_example.gd`, `boss_example.gd`.
Coste: ~87 ms/fotograma a 96×96 con 27 piezas. Hornear el ejemplo (3 variantes × 14 fotogramas): 5 s.

| # | Función de PER | Estado |
|---|---|---|
| 1 | Material como dato, texturas sobre el paso | Hecho |
| 2 | Máscaras de material por parámetro | Hecho |
| 3 | Sellos forzados con vistas | Hecho; la vista se elige por pose (`view:<hueso>`), no por ángulo |
| 4 | z animable | Hecho (bug corregido: sin clave valía 0 y el brazo se metía en el torso) |
| 5 | IK de 2 huesos | Hecho |
| 6 | Losas y polígonos con bisel | Hecho y probado |
| 7 | Accesorios por estado | Hecho, como variantes horneadas |
| 8 | Emisivo animable | Hecho |
| 9 | Estela en media luna, delante o detrás | Hecho; en el ejemplo sólo se usa detrás |
| 10 | Jefes multiparte | Hecho: atlas por parte, desfase, variantes (fase 2), `SpriteBank.part_frames`. El desfase se guarda en metadatos; aplicarlo es cosa de la integración |
| 11 | Parches ≤ 15 px | Hecho, error si se pasa |
| 12 | QA en cada horneado | Hecho: `tests/art/out/qa/`. La prueba de siluetas aún no ha comparado criaturas reales (hace falta ≥ 2 horneadas) |
| 13 | Modo pequeño < 32 px | Hecho |

Las 7 condiciones: PER-1, 2, 3 y 6 y los límites de DA son errores de `RigLint`, cada uno con su prueba negativa. PER-4 y PER-5 los garantiza el diseño. PER-7 es la prueba de determinismo e imagen dorada.

## Shader, luz y WorldView
- `palette_lit`: LUT global, luz en el ancla, Forja, onda de quemar, PV bajos, 4 luces, cambio de rampa fría, emisivos, máscara opcional.
- Bug encontrado mirando las capturas: con la Forja baja, los ladrillos cercanos pasaban a la rampa fría (luz cálida negativa). Corregido: lo frío exige luz fría real.
- `tests/art/tec_shader_parity.tscn` (necesita ventana): 0 píxeles de diferencia entre GPU y `_prev.png`, también volteado; con luz, 1.888 píxeles cambian y 0 salen de paleta.
- Coste en `tec_world_demo`: 0,25–0,34 ms/fotograma, GPU del mundo 0,03 ms (RX 6800 XT, gl_compatibility). Son sólo 3 gólems + muro; la prueba de estrés de 64 sprites es la del prototipo de la ronda 1.

## Pendiente
- GPU integrada y WebGL2 sin probar.
- `tec_shader_parity` y `tec_world_demo` no entran en `art_tests` porque necesitan ventana.
- Los sellos no giran con el hueso (se clavan rectos en su ancla); con giros grandes hay que usar vistas o parches.
- `project.godot`: Godot lo reescribió al guardar los globales (quitó `aspect="keep"`, que es el valor por defecto).

## F2-INT: combate real con el arte nuevo (2026-11-02)
**Hecho.** `combat_screen.gd` y `fighter_view.gd` reescritos sobre `WorldView`; `sprite_bank.gd` gana `body_rect()` y `ground_y()`. `combat_engine.gd` intacto.
- **Luchador en dos mitades:** `actor` (Node2D, px de arte) en el mundo y `FighterView` (Control) en la interfaz, con `HpPlate`, `StatusRow`, `IntentView`. `place(cx)` mueve ambas. Hoja por `fighter.def_id`; sin hoja, arte legado a ×2 con su disolución.
- **Vuelo:** `ground_y()` usa el socket `ground`, que exporta la altura `HOVER` del `RigDef`. Murciélago: base en y 230, suelo 264. La polilla hace lo mismo.
- **Disposición:** centros de DECISIONES; con 4+ o cuerpos que no caben, reparto por ancho en x 300–632. Jefe con invocaciones: se reparte.
- **Columnas libres de la mano:** x < 132 y x > 1138. Las posiciones propuestas en `api_hud.md` para las pilas (130, 1000) caen bajo la mano de 10. Quedan: quemas (8, 534), crisol (26, 568), robo (18, 662), fin de turno (1138, 586), descarte (1160, 628), exilio (1160, 674).
- **HUD superior:** `main.gd` no es de este paquete. `TopHud` vive en la pantalla y se oculta `main.hud` cada fotograma, porque `_swap` lo reactiva tras `build()`. `main.fly_embers` apunta al icono oculto, casi en el mismo sitio. El Forja/mapa siguen con el HUD v0.3.
- **Efectos F2-FX:** conectados `BakedRooms`, `CombatForge`, `BurnFX`, `HitFX`, `DeathEmbers`, `StatusFX`, `SummonFX` por clase global en ejecución (`_fx_script`), porque llegaron mientras integraba. Si falta o no compila uno, entra el respaldo con `ArtParticles`. Ya pueden pasar a tipado estático.

**Pelo y martillo NO seguían al calor.** `palette_lit` declara `forge_heat` y no lo usa; las puntas (`fire`) y la cara (`hot`) son emisivos horneados que sólo reciben `emit_pulse`.
- **Arreglo sin tocar `shaders/` (fuera del paquete):** `FighterView._hero_heat_shader()` deriva en ejecución una copia del shader para la heroína. `hot`: paso horneado − 4 + round(calor × 4). `fire` a menos de 26 px del socket `head`, con calor ≤ 0,35: `hair 2`. El farol también es `fire` y por eso se separa por distancia a la cabeza. En los fotogramas de estela se desactiva.
- **Medido (`tests/smoke.gd`), píxeles de pantalla, calor 0,1 → 0,9:** martillo vivo 0 → 64, martillo frío 72 → 0, puntas y farol 4 → 32.
- **Pendiente:** llevarlo a `palette_lit` con un material propio (o un material `tip`) es más limpio. Requiere editar `shaders/` y hornear de nuevo; lo decide dirección.

**Calor según producción.** `heat = 0,2 + 0,8 × producción normalizada + 0,05 × quemas del combate`. Difiere de la fórmula de `api_vfx.md`, basada sólo en quemas, porque el encargo pide producción. Con 3,18K/s da 0,51 antes de quemar.

**Comprobado con `tests/smoke.gd` (SMOKE OK, sin errores de script).** Martillo, puntas, calor, PV bajos (borde 0,326 → 0,267), onda al quemar, 3 centros, vuelo, mano de 10 a paso 90 desde x 150 y y 592, hover a y 496, placa de quemar en pantalla, ratón real sobre carta y clic real en Fin de turno. Capturas revisadas: reposo, quema, ataque, turno enemigo, muerte, jefe con invocación.

**Defectos vistos y corregidos en capturas:** iconos de reliquia al doble (`legacy_icon` ya es ×2); carta de quemar aterrizando fuera de la boca (pivote central); contorno de bloqueo recto de `StatusFX` (faltaba pasar la máscara: `body_mask()`); carta de ataque tapando al objetivo (ahora se detiene más a la izquierda).

**No comprobado o pendiente.**
- La carta quemada no pasa por detrás de la heroína: la carta es interfaz y va sobre el mundo.
- Arte legado sin `palette_lit`: no recibe luz de escena. Actos 2 y 3 sólo vistos por no fallar en el recorrido.
- Sin probar: quema en caliente con ratón real, muerte de heroína vista sólo en `18b`, GPU integrada, WebGL2.
- `set_hint()` y `deny()` conectados, no vistos en partida.

## F2-FIX: correcciones del combate integrado (2026-11-02)
**1. Línea cian: era el contorno de BLOQUEO de `StatusFX`, no un borde de luz.** La heroína empieza con 5 de bloqueo. `_draw_block_edge` usa `frost_glow 3` y traza el borde derecho de una máscara que sólo se enviaba una vez, con el fotograma 0 de `idle`. Al pasar a `toss` el martillo cambia de lado y la línea seguía dibujando el martillo de reposo: por eso flotaba junto a la pierna. Tampoco seguía `_off` (empujones y embestidas).
- **Afecta a todo luchador con bloqueo:** en enemigos, por el lado izquierdo (visto en el gólem, `10b`). También a las llamas de quemadura, que usan la misma silueta.
- **Se conserva**, porque comunica bloqueo (`api_vfx.md`). `FighterView._sync_status_fx()` envía cada cambio de fotograma con `set_body` + `set_mask`, tal como pide la API (máscara del tamaño de `body`). `status_fx.gd` no se ha tocado.
- **Medido (`smoke`):** ninguna fila separada de la silueta en heroína (1507 filas), gólem (1322), urraca (552) y limo (358), recorriendo sus poses. Captura `09a_block_toss`.
- **Coste:** `set_mask` ~1,3 ms por cambio de fotograma (cada 150 ms en reposo), sólo con estados activos. Sin estados, cero. Con 4 luchadores en el mismo fotograma, unos 5 ms; es un escaneo con `get_pixel` en `status_fx.gd` (MV) que se podría cachear por fotograma.

**2. Un único shader.** Eliminada la copia. `palette_lit` gana `hero_heat`, `head_pos` y `tips_follow_heat`; la heroína usa el mismo shader con un material propio. `LightRig.ensure_globals` avisa si cambian los índices `MAT_*`.
- **Martillo, calor 0,1 → 0,9 (`smoke`):** vivo 0 → 64, frío 72 → 0, puntas 4 → 32. Igual que antes. Enemigos sin `hero_heat` y con el material común.
- **Coste:** 60 capas de 96 filas por atlas, con lectura del búfer para forzar la GPU: antes 1,48–1,52 ms, ahora 1,51, con `hero_heat` 1,51–1,55. Sin diferencia sobre el ruido en esta GPU; la lectura pesa en esos tiempos. GPU integrada y WebGL2 sin medir.

**3. Martillo de lado: pose prevista, con salto.** `toss` y `cast` llevan `"hf": true` (`hammer_in_far_hand`, «pose de lanzar», `fogonera_final.md`): 07 es reposo y 09 es `toss`. Pero pasa de mano sin fotograma puente, al entrar y al volver a reposo. **Es de la definición de la heroína (`scripts/art/defs/hero/fogonera.gd`), fuera de este paquete: sin corregir.** Propuesta: un fotograma de paso en `toss`/`cast`, o no cambiar de mano al quemar.

**4. Carta quemada.** Vuela como interfaz sobre la mano y, al tocar la caja de la heroína, pasa al mundo como `Sprite2D` justo bajo su actor, con la imagen de una copia de la carta en un `SubViewport`. Comprobado orden de dibujo y captura `09b_burn_flight`. La trayectoria de `flight_point` cruza a la altura de sus pies; las placas de interfaz siguen delante de la carta.

**5. Intenciones.** Placa opaca de `plate` con contorno, canto claro y punta hacia su dueño (26×30 px con icono solo, ×2), en `HudArt.intent_plate`. Escudo pasado a `frost_glow`, el color del bloqueo. Se mantiene el hueco de 18 px de DECISIONES. `api_hud.md` (de cartas_ui) no menciona la placa.
- **Punto gris bajo el escudo del tercer enemigo:** bocanada del cráter del limo (`puff_*`, material `smoke`, en el socket `smoke`). Es animación de `ash_slime` en sus fotogramas 1–6, no una intención. Es de F2-CRIA si molesta.

**6. Consejo y avisos.** Consejo sobre placa, en `UI.TEXT`. El «tooltip» de 09 era un `main.toast` a y = 60. `main.gd` no es de este paquete: `combat_screen._toast` lo sustituye en combate, desde y = 112, sin fundido y con el mismo apilado. `smoke` comprueba que no pisa el rótulo.

**7. Horneado y exportación.**
- `qa.sh bake` sin `--only`: hojas + salas. `--only=rooms`: sólo salas. `--only=ids`: esas hojas + comprobación de salas. Secuencias de los 4 casos comprobadas con un Godot simulado; las de hojas no se han ejecutado de verdad, porque tocarían `manifest.json`.
- `qa.sh bake --only=rooms` real: 50 archivos, 60,8 s, `bake_rooms --check: al día`.
- **No existía `export_presets.cfg`: lo he creado** (Windows, `include_filter="assets/baked/rooms/*.txt"`, excluye `tests`, `docs`, `screenshots`). `--export-pack` genera el `.pck` con los 14 `.txt`. No he arrancado el juego desde ese `.pck` ni exportado el `.exe`.

**8. Resplandor y SummonFX.**
- **Oro:** `LightRig.gold`, conectado en `_sync_light`, también al caducar. Sin global nuevo, porque `project.godot` no es de este paquete: `cold_bias = -1` significa oro. Los cantos con luz cálida ≥ 0,25 pasan a la rampa `gold`; Forja y luces cálidas, +1 paso. Medido: 0 → 5864 → 0 píxeles de oro en la zona de la Forja. Captura `07b_glow`. A juicio de dirección: es un cambio de cantos, no de toda la pared, y en el muro se lee como trazos de ladrillo dorados.
- **Invocación:** `FighterView.reveal(f)` con `reveal_y` en el shader; `SummonFX` la llama y `spawn()` queda como respaldo. Vuelve al material común al terminar (`smoke`, `14a_summon_reveal`). Sólo probado con `candle_mite` horneado; rama de arte legado sin ver.

**Comprobado.** `tests/smoke.tscn`: SMOKE OK, sin errores de script. `== QA: 1745 comprobaciones, 0 fallos`.
**`tools/qa.sh all` NO está en verde:** `test_tec` falla sólo en frescura de `ash_glutton`, `ember_magpie` y `hollow_knight`, cuyas definiciones está editando F2-CRIA ahora mismo (08:53–08:54; el número de fallos creció mientras medía). Se resuelve cuando hornee. Hay que repetir `qa.sh all` al cerrar ambos paquetes.
**Sin comprobar.** Quema en caliente con ratón real, GPU integrada, WebGL2, Resplandor en la sala de tiro y actos 2–3.
