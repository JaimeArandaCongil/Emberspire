# F2-VIDA2 · diario (restos de F2-VIDA + integración del jefe en rig)

Nube Linux, Godot 4.7.2 (/opt/godot), xvfb + llvmpipe. Antes = recorrido sobre `ad56294` sin cambios
(`mediciones_antes.json`); después = recorrido final (`mediciones_despues.json`). Herramienta: `tests/art/vida_capturas.tscn`
(modos nuevos: `jefe`, `recompensa`, `flotante` con `VIDA_OLD=1` para el antes, `fase2` e `invoca`).

Cierre: `tools/qa.sh all` → QA 1745/0. Arte: 4 de 5 suites en verde. Falla `test_mv` («[MV horneado] las fuentes cambiaron»):
lo provoca el agente de salas, que tiene sin hornear `scripts/art/bg/bg_act1.gd` y `assets/baked/rooms/*`. No es de este
paquete. Antes, con F2-JEFE en curso, falló `test_tec` (frescura de `great_bellows`) y quedó resuelto al cerrar F2-JEFE.
`smoke.tscn`: SMOKE OK, 29 capturas, sin errores salvo `ERR_CANT_OPEN` (audio).

## Encargo

| # | Cambio | Evidencia (antes → después) |
|---|---|---|
| 1a | `cards_box` de las recompensas con reliquia: fuera `modulate.a = 0,35`. `UI.dim_cover(control, −2, keep)` pone encima un rectángulo con shader de pantalla que sustituye cada color de paleta por el mismo color 2 pasos más abajo de su rampa. Usa una LUT de 64³ celdas con 4 capas de origen y destino (0 colisiones; lo comprueba `test_ui`). Lo que no es de paleta no cambia. La cara del panel (`UI.PANEL`) se conserva para que no se vea la caja. La reliquia elegida queda con su estilo «hover» y las demás, inhabilitadas (antes era `modulate` 1,3, fuera de paleta) | 15_boss_relics: paleta exacta **86,24 → 99,997 %**, ajenos 2,79 → 0,003 %. `15_reliquias_antes_despues.png`, `reliquia_sin_elegir_y_elegida.png` |
| 1b | `UI.float_text`: en vez de fundirse con alfa, baja −1, −2 y −3 pasos de su rampa cada 90 ms desde los 450 ms. `UI.step_color()`: los colores fijos de `Palette.UI` (texto, tenue) usan la rampa cálida más parecida | Fotogramas 30–45 del modo `flotante`: 99,83–99,88 → **100,0 %**. `flotante_alfa_arriba_pasos_abajo.png` |
| 1c | Recompensas: el hex `#ffd36a` del nombre de la reliquia pasa a `Palette.UI.title`. Filas de la columna en múltiplos de 4 px, centradas como caja (`_grid_rows`). Botón «Quemar ofrendas» de 362×46. Icono de reliquia a ×4 (antes ×5) | Rejilla de 15: **6,48 → 1,44 %**; de 13: 1,12 → 0,65 % |
| 2 | Botón de música: el texto del `Button` le daba 31 px de alto mínimo, con el borde inferior en fila impar. Ahora es una caja 32×28 sin texto y la nota va como etiqueta Fragua ×2 en coordenadas pares | 07_combat: rejilla **0,034 → 0,000 %**. `musica_antes_despues_x4.png` |
| 3 | `fogonera.json` (F2-HERO) tiene `idle, idle_shoulder, windup, smear, strike, recover, attack, cast, toss, hurt, death`. **No tiene `shoulder_in` ni `shoulder_out`.** Mantengo el puente con `windup` | Ver «Para el artista» |
| 4 | C2 en el jefe. El jefe actual es el rig de F2-JEFE, de una sola hoja: el blanco cubre toda la silueta 1 fotograma y luego sube +3, +2 y +1 pasos con el dibujo visible, igual que en las criaturas. Dejo preparado el blanco por pieza: `fighter_view` comprueba si `palette_lit` declara `flash_piece` y, si lo declara, le pasa el socket `hit` del fotograma (el jefe lo exporta) con radio 10. Si no, sigue el respaldo actual | `jefe_rig_destello_f9_10_11_12_14.png` |
| 5 | Recorrido 01–06, 15 y 19–23 revisado en 3 hojas a ½ y con recortes a ×1 de forja, hoguera y evento: **ningún desborde con Mini ×2** | Ver «Fase 3» |

## Ampliación de dirección (jefe en rig)

| # | Cambio | Evidencia |
|---|---|---|
| J1 | `fighter_view._check_phase()`: por debajo del 50 % de PV, el jefe cambia a `sprite_frames(id, true, &"phase2")` y conserva la animación y el fotograma. El cambio cae bajo el blanco del golpe que lo provoca y después entra `hurt`. Sin variante horneada, no hace nada | `jefe_intencion_fase2_invocacion.png`, arriba a la derecha y tira de abajo a la derecha (golpe → fase 2) |
| J2 | `combat_screen._move_anim()`: si el movimiento invoca (`summon`) o ahoga (`choke`) y el rig tiene esa animación, `gesture(anim)` la reproduce y el efecto se resuelve en su f2. Aunque el movimiento también ataque, ya no entra por `lunge` | Modo `invoca`: el fuelle se abre en `summon` y los ácaros salen en el f63 |
| J3 | Intención del jefe fija y quieta (sin vaivén, §15) con la base en y 78 de pantalla (arte 28–39, dentro de 22–44) | Las tres capturas completas del jefe |
| J4 | `_boss_centers()`: el jefe apoya su borde izquierdo en x 300 y se desliza al invocar. Las invocaciones ocupan los huecos libres a su derecha, hasta x 632 (cuerpo y placa), o a ras de suelo bajo su cuerpo (`ground_gaps()`: bajo la tobera). Las placas quedan separadas por su ancho + 2. Si no caben, se usa el reparto general | 14: antes, ácaros en arte 572/610 con las placas solapadas y cortadas en el borde. Ahora, ácaros bajo la tobera (~330) y a ~593, placas 12/12 · 206/206 · 14/14 separadas. `14_invocacion_antes_despues.png` |
| J5 | `sprite_bank.gd`: no lo toqué. El jefe es un único rig y nada de lo anterior necesita `part_frames` | Ver pendientes |

## Para el artista (heroína)
El segundo reposo necesita `shoulder_in` y `shoulder_out` (2–3 f, ~80 ms): el martillo sube de la mano al hombro y vuelve.
`fighter_view._bridge()` los usa en cuanto existan; hoy el puente es `windup` (1 f), que se lee como amago de golpe.

## Para el shader (`shaders/palette_lit.gdshader`, fuera de mi paquete)
Para que el blanco salga sólo en la pieza golpeada del jefe:
```glsl
uniform vec3 flash_piece = vec3(0.0, 0.0, -1.0); // x, y de mundo y radio; radio < 0 = todo el cuerpo
...
if (flash_white && (flash_piece.z < 0.0 || distance(anchor, flash_piece.xy) <= flash_piece.z)) { col = ...fuego 7...; }
```
Opcional: que los píxeles fuera del radio reciban `flash_steps = 3` mientras dura el blanco. `fighter_view` ya rellena el
uniforme. **No lo he comprobado en ejecución**, porque el shader no es mío.

## Fase 3 (no es del combate)
- Pavesa ×1 fuera de la excepción en los cuerpos de pantalla: descripciones de la forja, la antesala, los nodos del mapa, la hoguera, el texto del evento y el pie del resumen. También en el texto de las reliquias de jefe (dentro de botones).
- 01_title: 14 % de ajenos (`title_screen.gd`). 02 y 04: rejilla 14–15 % bajo el modal «Resonancia». 05 y 19: paneles desfasados (10,6 y 9,6 %).
- Títulos largos de carta en Pavesa (CardView, F2-ILUS): «Empujón leñoso» en recompensas y 3 en 23_cards.

## Pendiente y no comprobado
- Las cartas que vuelan al descarte o al exilio siguen con `modulate:a` (`combat_screen` l. ~1067–1101). No estaba en el encargo.
- `part_frames`: el código parece completo, pero sin un jefe multiatlas no se puede probar. Para multiatlas faltan además la composición de partes y el destello por parte en `fighter_view`.
- El ácaro de la izquierda tiene su icono de intención junto a la punta de la tobera. Se lee, pero va justo.
- Arte legado (actos 2–3): el destello sigue mezclando con `flash_color` (fuera de paleta).
- `dim_cover` usa una LUT de 1024×2048 (8 MB) mientras está abierta. No he medido su rendimiento en GPU real.
