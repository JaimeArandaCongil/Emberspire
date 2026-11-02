# Estado del arte v0.4
Actualiza dirección al cerrar cada paquete. Fases y reparto originales: `docs/reviews/v04/PLAN.md`.

**Fase actual: 2, corte vertical del combate del acto 1, segunda iteración.** Fase 1 cerrada. Correcciones C1–C20 en `docs/reviews/v04/director/f2_rev/dictamen.md`; problemas nuevos medidos en `director/f2_base/revision.md`.
Se trabaja en la nube (Linux) desde la rama `main-0nvhs9`: ver `CLAUDE.md`.

## Paquetes de la fase 2
| Id | Paquete | Agente | Archivos | Estado |
|---|---|---|---|---|
| F2-INT | Integrar el combate: WorldView, sprites, luz por estado, partículas, mano, HUD, efectos | `art-integrator` | `scripts/ui/fighter_view.gd`, `scripts/ui/screens/combat_screen.gd`, `scripts/art/rig/**`, `scripts/art/light_rig.gd`, `scripts/art/sprite_bank.gd`, `tests/smoke.gd`, `project.godot` | hecho |
| F2-FX | Forja de combate, salas horneadas, BurnFX, HitFX, muerte, estados, invocación | `world-artist` (opus) | `scripts/art/bg/**`, `scripts/ui/world/**` salvo `world_view.gd`, `tools/bake_rooms.gd`, `assets/baked/rooms/**`, `tests/art/test_mv.gd` | hecho |
| F2-TRIAL | Prueba de Sonnet: 1 criatura y 3 ilustraciones | Sonnet | `ash_glutton`, `set_pyre.gd` | hecho: no superada, se rehacen en fase 3 con Opus |
| F2-FIX | Cian de la heroína, calor en `palette_lit`, carta quemada, intenciones, horneado de salas | `art-integrator` (opus) | ver encargo | hecho salvo salto del martillo (`fogonera.gd`) |
| F2-CRIA | Correcciones de la prueba ciega y `ash_glutton` rehecho | `creature-artist` | `scripts/art/defs/creatures/**`, `assets/baked/creatures/**`, `scripts/data/enemy_db.gd` | hecho, a falta de la nota de F2-REV |
| F2-REV | Revisión del corte con capturas; nota ≥ 8 por familia | `art-director` | `docs/reviews/v04/director/` | hecho: heroína 6,5, criaturas 6,4, jefe 2,5, sala 7,5, Forja 8,5, cartas 6,5, HUD 7, efectos 6, vida 6,5, conjunto 6,5. No pasa |
| F2-BASE | Revisión medida (composición, escala, legibilidad, pixel art) con script reproducible | `art-director` | `docs/reviews/v04/director/f2_base/` | hecho: ejes 7 / 6 / 7,5 / 7; HUD baja a 6,5 |
| F2-VIDA | Orden del golpe, destello, muerte, Quemadura, resplandor, brasas, reposo, HUD (C1, C2, C4, C6, C11, C15, C16, C18, C20) + nuevos de F2-BASE (Mini ×2, rejilla, banda de jefe, rótulos) | `art-integrator` | `combat_screen.gd`, `fighter_view.gd`, `scripts/ui/world/fx/**`, `light_rig.gd`, `palette_lit`, `scripts/ui/hud/**`, `ui.gd` | hecho (`cartas_ui/f2_vida/`); quedan alfa en `cards_box` y texto flotante, botón de música 1 px |
| F2-HERO | Poses del martillo, muerte, cabeza del martillo (C3, C4, C14); altura 74 px | `creature-artist` | `scripts/art/defs/hero/**`, su horneado | hecho (`personajes/f2_hero/`); muerte no vista en movimiento |
| F2-ILUS | Limpieza de color, iconos, composición, títulos (C8, C10, C17) y títulos a la rejilla | `card-illustrator` | `scripts/art/cards/**`, `CardView` | hecho (`cartas_ui/f2_ilus/`); mano a paso 162; `23_cards` no muestra las 4 nuevas |
| F2-CRIA2 | `ash_slime`, `soot_golem`, `cinder_bat`, `candle_mite` (C5, C12, C13) | `creature-artist` | criaturas | hecho en dos tandas (`personajes/f2_cria2/`, `f2_cria2b/`); limo oscuro sobre el suelo; murciélago y ácaro < 0,10 de contraste a 1/4 en 2 fotogramas (pide C19) |
| F2-JEFE | `great_bellows` en rig (C9) | `creature-artist` | `scripts/art/defs/bosses/**` | tras F2-CRIA2 |
| F2-SALA | Ritmo del ladrillo y rejilla (C19) | `world-artist` | `scripts/art/bg/**`, `assets/baked/rooms/**` | tras F2-JEFE |
| F2-REV2 | Segunda revisión; ≥ 8 por familia | `art-director` | `docs/reviews/v04/director/` | al final |

## Hecho hasta ahora
- Paleta, biblia, rig, horneador, `palette_lit`, `LightRig`, `WorldView`, kit de UI, fuentes, marco de carta.
- Definiciones horneadas en `assets/baked/`: Fogonera y 7 criaturas (`scripts/art/defs/creatures/`).
- Widgets de HUD en `scripts/ui/hud/` (`cartas_ui/api_hud.md`), sin conectar.
- Ilustraciones: 12 de 93. Las otras 81 usan respaldo temporal.

## Pendiente conocido
- Actos 2 y 3 siguen con arte legado sin luz. `TopHud` sólo en combate.
- Sin probar: GPU integrada y WebGL2. Quema en caliente con ratón.
- Pasada de nivel A de las ilustraciones y regla de combinación única: comprobar el estado en `tests/art/test_ui.gd`.
- `ART_BIBLE.md` debe incorporar `formato_indice.md` (o enlazarlo).
- Las notas ciegas de lo hecho con Opus (6–7,5) aún no llegan al objetivo de 8: aplicar `director/prueba_ciega.md`. Las 15 ilustraciones superan el límite de 12 colores.
- Horneado Windows/Linux: deriva de ≤ 8 px tolerada en la imagen dorada (libm).
- Martillo de la heroína: cambio de lado sin transición. `soot_golem` mide 88 px y `ash_slime` parece roca. Luz de resplandor en oro sólo en cantos. Sin comprobar: arranque desde `.pck`.
- Calidad de salas: muro del tiro plano, saeteras lejanas, vetas en escalera.

## Siguientes fases
Fase 3: resto de criaturas y jefes, 81 ilustraciones, actos 2 y 3, pantallas como lugares (Forja-taller, mapa-chimenea, Antesala,
tienda, evento, título, resumen), estado del juego en todas las pantallas. Fase 4: revisión de DA pantalla a pantalla y resultado final.
