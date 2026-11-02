# F2-ILUS · diario (card-illustrator)

Encargo: C8, C10, C17 y títulos desfasados de F2-BASE. Sin hornear, sin commits.

## C8 · limpieza de color (regla ≤ 30; ninguno < 10 px salvo 3 chispas u ojos)
- `IllusPx.tidy()` (`scripts/art/cards/illus/illus_px.gd`): cuenta los colores **visibles en la ventana del tipo**
  (`CardFrame.window_mask`). Los de menos de 10 px se funden con el color conservado más parecido de entre sus
  8 vecinos (conserva material y valor); si no hay ninguno, con el más parecido de la pieza. Se salvan hasta 3
  pasos altos de `fire`/`ember_ui`/`hot` (chispas y ojos). No crea colores. Tope de 30.
- Lo aplica `CardIllus.image()` a toda ilustración (también al respaldo). Prueba nueva en `tests/art/test_ui.gd`.
- Medición en la ventana (colores / con < 10 px), antes → después:

| Id | Antes | Después |
|---|---|---|
| strike | 36 / 9 | 27 / 0 |
| defend | 34 / 5 | 30 / 0 |
| kindling | 31 / 10 | 24 / 3 |
| ember_slash | 15 / 3 | 12 / 0 |
| heavy_hammer | 32 / 5 | 27 / 0 |
| sparks | 14 / 1 | 13 / 0 |
| cleave | 27 / 4 | 26 / 3 |
| iron_wall | 22 / 3 | 21 / 2 |
| quench | 36 / 14 | 24 / 2 |
| bellows | 33 / 7 | 26 / 0 |
| stoke | 20 / 1 | 20 / 1 |
| coal | 32 / 3 | 29 / 0 |
| pyre_dance | 36 / 9 | 27 / 0 |
| open_flue | 34 / 11 | 24 / 1 |
| kiln | 27 / 4 | 24 / 1 |

- Revisada la hoja `ilustraciones_x3.png`: la limpieza no se nota.
- Las cartas mejoradas añaden la costura `ember_ui 4` del marco dentro de la ventana (+1 color en pantalla).

## C10 · composición propia (`scripts/art/cards/illus/set_icon.gd`)
| Carta | Fondo · luz | Encuadre | Sujeto · posición | Colores |
|---|---|---|---|---|
| Fuego Interior | muro de la Torre que sólo ilumina la llama | capilla | mano abierta, palma arriba, con la llama que nace de ella · centro, de abajo arriba | 18 / 1 |
| Llama de Brasero | muro cálido/frío + losas | filo | tres braseros en fuga cuyas llamas se trenzan en un latigazo contra un murciélago · diagonal | 24 / 0 |
| Golpe de Escudo | penumbra de fragua + losas; chispazo del choque | filo | rodela de perfil empujada por el brazo, con estela, aplasta un limo de ceniza · izq. → der. | 30 / 0 |
| Guardia de Ascuas | muro frío de la Torre; brasas dentro | escudo | cúpula de ascuas sobre un montón de brasas; dardos de hollín de un murciélago se rompen · izq.-centro | 24 / 1 |

- Ningún fondo + encuadre + sujeto + posición repetido; la prueba de miniatura 34×23 pasa con las 19.
- Iteración: la 1.ª Fuego Interior (manos en cuenco) se leía como brasero; la 2.ª (mano de frente) tapaba la llama.
  La rodela se veía negra y el limo como roca: cara de acero frío, brillo húmedo, ojos, boca y charco.

## C17 y rejilla de títulos (`scripts/ui/card_view.gd`)
- `CardView.title_layout()`: Fragua ×2 si el glifo y su contorno, con 1 px de placa libre en cruz, no tocan el rombo
  del orbe propio ni el del vecino de la mano (`ORB_STEP` = 66 px de arte = `HAND_MAX_STEP` / 2, comprobado en la
  prueba). Se elige la posición válida más cercana al centro, siempre en x par. Si no cabe, Pavesa ×1 (los largos).
  Disposición idéntica en mano, recompensa y tienda.
- Si el nombre cabe en Fragua pero el «+» no, se omite el «+»: la placa de oro y la tinta de ascua ya marcan la
  mejora, y así la carta no cambia de letra al mejorarse («Tajo Ígneo+»).
- Fragua sin sombra: la de 1 px de pantalla quedaba a medio píxel de arte y daba `020101` (sombra del contorno).
  `_name.y` = 8 (antes 7, impar). La cifra del coste también se centraba a medio píxel: ahora va en columna par y sin sombra.
- Evidencia (07_combat): 426 bloques 2×2 con tinta de título o coste, 0 mezclados; `020101` = 0 px en 07, 13, 19 y 23.
  «Tajo Ígneo» en x 28–120 de la carta (contorno), con 1 px de placa hasta los dos orbes.

## Pendientes y límites
- **Paso de la mano**: con `HAND_MAX_STEP` 132 el orbe vecino tapa la placa desde x 122. Sólo 35 de 99 nombres caben en
  Fragua; el resto va en Pavesa. Con un paso de 162 (sin solape hasta 6 cartas; `combat_screen.gd`, no es mío) cabrían
  55 de 99. Basta con cambiar `CardView.ORB_STEP` a la vez (lo vigila la prueba).
- Los nombres en Pavesa de más de 92 px (≈ 15, p. ej. «Muralla de Engranajes») siguen pasando bajo el orbe vecino en
  manos de 5.
- `23_cards` no incluye las 4 nuevas (la elige `smoke.gd`); se ven en `13_rewards` y en `ilustraciones_x3.png`.
- `tools/qa.sh all` en verde (1745 comprobaciones de juego, 5 suites de arte, 0 fallos).
- Sin comprobar: los 81 respaldos con la limpieza, uno por uno (la prueba sólo recorre las ilustraciones propias).
