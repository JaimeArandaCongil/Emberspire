# Plan de producción de arte v0.4

Decisiones en `DEBATE.md` (Resolución). Este documento reparte el trabajo por fases y por **propiedad de archivos**:
nadie edita un archivo que no sea suyo; si lo necesita, lo pide a dirección.

## Reglas comunes de implementación
- Mismo checkout, sin ramas ni commits por los expertos: **sólo dirección hace commits**, al cerrar cada paquete.
- **No restaurar `project.godot`** con `git checkout`: TEC es su único dueño (globales de shader, ajustes de renderizado) y
  dirección limpia el reformateo de Godot al hacer commit. Nadie más añade autoloads ni ajustes.
- `tests/test_runner.tscn` (1.745 comprobaciones) debe seguir pasando en cada entrega. Las pruebas de arte nuevas van en
  `tests/art/` (escena `tests/art/art_tests.tscn`), que TEC crea y todos amplían en su propio archivo `tests/art/test_<rol>.gd`.
- El juego tiene que **arrancar y jugarse en todo momento**: lo nuevo entra detrás de la fachada `Art` con respaldo al arte
  v0.3 hasta que su sustituto esté aceptado.
- Toda pieza nueva pasa los criterios de aceptación de DA (`docs/ART_BIBLE.md` v0.4): paleta cerrada, miniatura en grises,
  sin ruido en superficies > 6×6, sin escala no entera, cara y manos selladas.
- Cada experto mantiene `docs/reviews/v04/<rol>/diario.md` (qué hizo, decisiones, capturas) para la documentación final.

## Fase 1 — Cimientos (en paralelo)

| Rol | Entrega | Archivos propios |
|---|---|---|
| **DA** | Paleta maestra como datos (rampas por material, cálida y fría, índice 0 común); `ART_BIBLE.md` v0.4 completa (rejilla, paleta, valores, luz, materiales, disposición de combate, criterios de aceptación, animación); pruebas automáticas de paleta y de miniatura en grises | `scripts/art/palette.gd`, `docs/ART_BIBLE.md`, `tests/art/test_da.gd` |
| **TEC** | Motor de rig (API de `tecnico/ronda1.md` + 13 funciones de PER + condiciones como errores), horneador con manifiesto, `SpriteBank` con respaldo, `palette_lit.gdshader` + `LightRig` (globales de shader), `WorldView` 640×360, escena de pruebas de arte con frescura y determinismo, fachada `Art` (troceo de `art.gd` sin cambio visual) | `scripts/art/rig/**`, `scripts/art/sprite_bank.gd`, `scripts/art/light_rig.gd`, `shaders/**`, `tools/**`, `assets/baked/**` (manifiesto), `scripts/ui/world/world_view.gd`, `scripts/autoload/art.gd` (fachada), `scripts/art/legacy/**`, `project.godot`, `tests/art/art_tests.*`, `tests/art/test_tec.gd` |
| **UI** | Fuentes Pavesa (6×9, ×1) y Mini (3×5, ×2); kit 9-slice teselado + `UI.build_theme()`; marco de carta 80×112 con todos sus estados; gramática de ilustración + kit de fondos y sujetos; primeras 12 ilustraciones (mazo inicial + Base) | `scripts/ui/pixel_font.gd`, `scripts/art/ui_kit.gd`, `scripts/art/cards/**`, `scripts/ui/card_view.gd`, `scripts/ui/ui.gd`, `tests/art/test_ui.gd` |
| **MV** | Generador de fondos por capas en formato índice (R material, G paso+banderas, BA ancla de pieza) para el **acto 1** a 640×360 (salas normal y de tiro), `ArtParticles` en la rejilla, ambientes del acto 1 (braseros, humo, chispas del tiro, crisol, goteo de hollín) | `scripts/art/bg/**`, `scripts/ui/world/art_particles.gd`, `scripts/ui/world/ambient/**`, `tests/art/test_mv.gd` |
| **PER** | Biblioteca de sellos (caras, manos, remaches, ojos) y diseño final de la Fogonera; en cuanto TEC entregue el motor v1: Fogonera (todas las poses) y criaturas del acto 1 | `scripts/art/defs/**` (heroína, criaturas, jefes, sellos), `tests/art/test_per.gd` |

TEC avisa a dirección en cuanto el motor v1 tenga API estable: dirección se lo pasa a PER y a MV.

## Fase 2 — Corte vertical: combate del acto 1 a nivel 9
- TEC integra `WorldView` en `fighter_view.gd` y en la parte de mundo de `combat_screen.gd` (dueño temporal de ambos).
- UI integra la mano de cartas 80×112 (dueño de `card_view.gd`; la colocación de la mano en `combat_screen.gd` la hace TEC
  con las medidas de UI).
- PER entrega Fogonera + Gólem de Hollín + Urraca Ígnea + Limo de Ceniza + Ácaro de Vela + Murciélago Brasa.
- MV entrega la sala del acto 1, la Forja de combate grande (con DA) y el VFX de quemar carta.
- DA revisa con capturas del smoke y puntúa; se itera hasta ≥ 8 en todas las familias del corte.

## Fase 3 — Contenido completo
- PER (+ ayudantes si hace falta): las 24 criaturas y los 6 jefes, con afijos visibles.
- UI (+ ilustrador): las 93 ilustraciones, iconos de reliquia/estado/intención, pantallas Forja-taller, mapa-chimenea,
  Antesala, tienda con mercader, evento, título, resumen.
- MV: actos 2 y 3, hoguera, entradas de jefe, transiciones, VFX de golpes y estados.
- TEC: luz conectada al estado del juego en todas las pantallas (el "mundo interconectado" de DA §3).

## Fase 4 — Pulido y aceptación
Revisión cruzada de DA pantalla a pantalla con nota; segunda ronda de correcciones; documentación final
(`ART_BIBLE.md`, `docs/reviews/v04/RESULTADO.md` con antes/después).
