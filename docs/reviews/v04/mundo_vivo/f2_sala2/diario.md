# F2-SALA2 · Diario (C19, corrección #6: muro tras los enemigos)

## Diagnóstico: el que movía la cifra era el crisol, no las juntas
Antes de tocar nada, `07` daba **16,12** en px 780–1000 × 130–250 (art x 390–500 × y 65–125). Al pasar a
`--only=rooms` las juntas a −1 más, la cifra bajó sólo a 15,7. Si se cambia la captura por la vista previa de la sala
(luz dinámica 0) en la zona del crisol, se ve qué falta: **el crisol colgante (pivote x 444) y su luz dinámica**
(`act1_room_view.gd:124`, +2 pasos, r 34) suman 36–51 de luminancia en mitad de la zona. Sin crisol ni luz, la
desviación es **8,6**. Por eso F2-SALA no movió la cifra (16,08 → 16,04): el foco caliente del crisol estaba justo
detrás de la urraca.

## Cambios (`scripts/art/bg/bg_act1.gd`, horneado en `assets/baked/rooms/`)
- **Crisol colgante** a x 552 (`CRUCIBLE_X`; antes 444), en el rincón caliente, entre el humo del brasero y la ventana.
  Su luz cae ahora sobre el charco del brasero. Siguen igual el péndulo, la cadena (`len` 66) y los fotogramas horneados.
  El cuenco queda en y ≤ 110, lejos de las cabezas (≥ 175) y de la banda de intención.
- **Juntas −1 paso más** (`_joint_v`, rama `_in_calm`) en art x 300–604 × **y 60–167**, en las 12 salas. Dentro de la
  escena (borde dentado de `STAGE_X`), la junta horneada va **al paso de su pieza**. Si la pieza es más oscura (pieza
  suelta −1 o paño de hornada), la junta la sigue, para que no salga un borde claro. Con luz, la bandera JUNTA sigue
  restando un paso. La hilada se lee por la fila de sombra (ry 6) y los cantos. No cambian los paños de hornada, la
  sillería, los arcos, los braseros ni los parpadeos.
- **Por qué hasta y 167 y no 250**: con la banda entera, las juntas más claras aclaran el fondo de las criaturas
  oscuras y les restan 0,001–0,002 (gólem, polilla, babosa, murciélago en la tabla de abajo). Con el corte sobre las
  cabezas, la tabla queda idéntica. Por debajo de y 167 quedan las juntas de F2-SALA, a −1.
- `tests/art/test_mv.gd` (`check_stage`): las juntas del paño central deben quedar ≤ 0,6 pasos del ladrillo (hoy 0,44;
  1,30 con F2-SALA). El crisol no puede colgar en x 380–510. `_joint_depth` admite ahora un rango de y.
- Probé y descarté varias cosas: tendel enrasado sin bandera, quitar la fila ry 6, quitar los cantos o las motas, menos
  piezas sueltas, grietas a −2 y franja de hollín más corta. Bajaban la cifra de 15,7 a 13,9, pero la pared quedaba como
  enlucido con manchas. Con el crisol movido sobran todas, así que se revirtieron.

## Medidas
Desviación de luminancia (0–255) en px 780–1000 × 130–250, captura del recorrido (xvfb, piso 4):

| Captura | Antes | Después |
|---|---|---|
| `07_combat` (medida oficial, `medir.py`) | 16,12 | **10,13** |
| `08_combat_hover` | 15,69 | 10,14 |
| `10b_enemy_turn` | 16,23 | 10,62 |
| `11_after_enemy_turn` | 16,41 | 10,13 |
| `18b_hero_death` | 16,76 | 10,15 |
| `09_burn` (onda de quemar, transitoria) | 26,79 | 23,35 |

Descomposición de `07` (caja 16×14 px): baja frecuencia 9,85 → 7,91, alta frecuencia 11,90 → 5,87.
Vista previa estática (sin crisol ni luz dinámica) en art 390–500 × 65–125, 8 salas normales: 9,7–11,9 antes y
9,7–12,1 después (las juntas aclaradas suben la media 0,5). La ganancia se ve en juego, no en la vista previa.

**Contraste mínimo de criaturas** (método del diario de F2-SALA: gris a 1/4, figura frente a un anillo de 2 celdas,
mínimo sobre los fotogramas de reposo y sobre las 8 salas normales, o las 4 de tiro para `hollow_knight`). El script
está en `contraste.py`. Las cifras absolutas no coinciden con las de F2-SALA porque las hojas de criaturas han cambiado
desde entonces y aquí se usa la criatura entera. Antes y después usan el mismo método:

| Criatura@hueco | Antes = después |
|---|---|
| `candle_mite` @350/396/460/540/572 | 0,225 / 0,250 / 0,255 / 0,221 / 0,241 |
| `ash_slime` @396/466/540 | 0,143 / 0,149 / 0,134 |
| `cinder_bat` @350/396/466/572 | 0,159 / 0,241 / 0,260 / 0,257 |
| `soot_golem@sooty` @396/466 | 0,081 / 0,092 |
| `ember_magpie` @396/466 | 0,154 / 0,157 |
| `flame_moth` @396/540 | 0,099 / 0,093 |
| `hollow_knight` @466 (tiro) | 0,137 |

Ninguna empeora. `medir.py`: la paleta sigue al 100 % en 07, 09, 11 y 18b, y `valor_cuerpo_fondo` no cambia (limo
0,235/0,133, ácaro 0,251/0,094). Las diferencias de disposición y rejilla entre recorridos son de fotograma de animación.

**Movimiento (C20)**: 360 fotogramas de reposo a 30 fps (`vida_capturas`, `VIDA_MODE=reposo`). Media de 3.078 px por
fotograma y pico de 8.271, frente a 2.984 y 8.354 en F2-REV2 (tope 13.800). No hay fuentes vivas nuevas.

## No hecho / no comprobado
- **Muro del tiro menos plano y saeteras**: no tocados. Van en la capa lejana compartida y pondrían detalle detrás del
  jefe y de los élites, justo lo que C19 quiere quitar. Hay que decidirlo aparte.
- En juego sólo medí la sala del piso 4 (normal v0, ciclo I). Las otras variantes y el ciclo II sólo se miden en vista
  previa. Capturas por software (xvfb). Sin medir rendimiento.
- El crisol en x 552 comparte rectángulo con el parche de parpadeo del brasero en el modo sin shader
  (`use_patches`). En x 444 ya lo compartía, así que el riesgo no es nuevo.

## Evidencia
- `antes_despues_07.png`, `antes_despues_18b.png`: arriba antes y abajo después (recorrido a 1/2).
- `gris_1de4_07.png`: miniatura en grises a 1/4, ampliada ×3 (arriba antes).
- `variantes_despues.png`: las 12 variantes en vista previa a 1/2. Filas: normal v0–v3 y tiro v0–v1; columnas: ciclo I
  y ciclo II.
- `tools/qa.sh bake --only=rooms`: 50 archivos, `--check` al día. `tools/qa.sh all`: juego 1745/0, arte 5 suites/0.
  Recorrido con `SHOTS_DIR=/tmp/claude-0/shots_sala2` (antes en `/tmp/claude-0/shots_sala2_antes`): sólo el
  `ERR_CANT_OPEN` de audio.
