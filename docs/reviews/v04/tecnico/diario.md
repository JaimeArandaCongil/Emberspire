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
