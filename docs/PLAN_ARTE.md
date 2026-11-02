# Estado del arte v0.4
Actualiza dirección al cerrar cada paquete. Fases y reparto originales: `docs/reviews/v04/PLAN.md`.

**Fase actual: 2, corte vertical del combate del acto 1.** Fase 1 cerrada.

## Paquetes de la fase 2
| Id | Paquete | Agente | Archivos | Estado |
|---|---|---|---|---|
| F2-INT | Integrar el combate: WorldView, sprites, luz por estado, partículas, mano, HUD, efectos | `art-integrator` | `scripts/ui/fighter_view.gd`, `scripts/ui/screens/combat_screen.gd`, `scripts/art/rig/**`, `scripts/art/light_rig.gd`, `scripts/art/sprite_bank.gd`, `tests/smoke.gd`, `project.godot` | pendiente |
| F2-FX | Forja de combate, salas horneadas, BurnFX, HitFX, muerte, estados, invocación | `world-artist` (opus) | `scripts/art/bg/**`, `scripts/ui/world/**` salvo `world_view.gd`, `tools/bake_rooms.gd`, `assets/baked/rooms/**`, `tests/art/test_mv.gd` | pendiente |
| F2-TRIAL | Prueba de Sonnet: 1 criatura y 3 ilustraciones | Sonnet | `ash_glutton`, `set_pyre.gd` | hecho: no superada, se rehacen en fase 3 con Opus |
| F2-REV | Revisión del corte con capturas; nota ≥ 8 por familia | `art-director` | `docs/reviews/v04/director/` | tras INT y FX |

## Hecho hasta ahora
- Paleta, biblia, rig, horneador, `palette_lit`, `LightRig`, `WorldView`, kit de UI, fuentes, marco de carta.
- Definiciones horneadas en `assets/baked/`: Fogonera y 7 criaturas (`scripts/art/defs/creatures/`).
- Widgets de HUD en `scripts/ui/hud/` (`cartas_ui/api_hud.md`), sin conectar.
- Ilustraciones: 12 de 93. Las otras 81 usan respaldo temporal.

## Pendiente conocido
- `combat_screen.gd` y `fighter_view.gd` aún muestran el arte v0.3.
- Sin probar: GPU integrada y WebGL2. Animaciones nunca vistas en juego con el shader.
- Pasada de nivel A de las ilustraciones y regla de combinación única: comprobar el estado en `tests/art/test_ui.gd`.
- `ART_BIBLE.md` debe incorporar `formato_indice.md` (o enlazarlo).
- Las notas ciegas de lo hecho con Opus (6–7,5) aún no llegan al objetivo de 8: aplicar `director/prueba_ciega.md`. Las 15 ilustraciones superan el límite de 12 colores.
- Calidad de salas: muro del tiro plano, saeteras lejanas, vetas en escalera.

## Siguientes fases
Fase 3: resto de criaturas y jefes, 81 ilustraciones, actos 2 y 3, pantallas como lugares (Forja-taller, mapa-chimenea, Antesala,
tienda, evento, título, resumen), estado del juego en todas las pantallas. Fase 4: revisión de DA pantalla a pantalla y resultado final.
