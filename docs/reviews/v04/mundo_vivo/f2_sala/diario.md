# F2-SALA · Diario (C19 y lectura de criaturas contra la sala)

## Cambios (todo en `scripts/art/bg/bg_act1.gd`, horneado en `assets/baked/rooms/`)
- **Escena de los enemigos** (`STAGE_X = 300`, borde dentado por hiladas): las juntas quedan a −1 paso del ladrillo vecino
  (`_joint_v` compensa el paso de luz que la junta pierde al hornear). Medida en el índice: tendeles a 0,97–1,12 pasos del
  ladrillo tras los enemigos, frente a 2,16–2,55 en el muro de la heroína (6 variantes, ciclo I). Prueba nueva en
  `tests/art/test_mv.gd` (`check_stage`).
- **Zócalo de sillería** (y 218–248, 3 hiladas de 10 px, sillares de 24–32 px, extremos dentados) en las dos paredes. Tras
  los enemigos queda 1 paso en sombra y con juntas a −1. Rompe el ritmo del ladrillo justo donde están los pies.
- **Grupos de ladrillo de otra hornada**: paños de ~3×3 piezas, −1 (o +1 fuera de la escena), con borde dentado.
- **Suelo y zócalo tras los enemigos −1** (canto del zócalo y del suelo, −2). El charco de los braseros de la escena es menor
  y ya no ilumina el canto del suelo. Los montones de ceniza salen de los huecos x 320–602. El pie del pilar de x 360 queda
  en sombra sólo por debajo de y 240, para no restar al murciélago en x 350.
- **Rejilla del suelo** a x 256 (`GRATE_X`, ancho 221–291): queda entre la placa de la heroína (≤ 201) y la primera de
  enemigo (≥ 311). Se mueven también su luz y el ancla `grate`, de la que salen las brasas de `AmbientFlue`.
- **Vetas del ciclo II**: los focos salen de detrás de los enemigos (de 470,244 y 556,160 a 614,244 y 436,146).
- No cambia: paleta (sólo `Palette`), fuentes vivas, parpadeos ni presupuesto de movimiento. Las capas lejana y de cielo
  tampoco se tocan.

## Medida de contraste (gris a 1/4, `test_da.thumbnail_separation`)
Método: `BgAct1.build` de las 12 variantes (4 normales y 2 de tiro × ciclos I y II), con las capas compuestas en vista previa
(luz dinámica 0). Encima, cada fotograma de reposo horneado de la criatura, centrado como `FighterView` (centro del
rectángulo usado del f0, socket `ground` en y 264). Se toma el **mínimo sobre los fotogramas** en los huecos reales de
`enemy_db` (acto 1). `mite*` es el cuerpo sin cera ni llama, como en F2-CRIA2b. «Con placa»: la misma escena con la placa
de PV recortada de la captura y pegada bajo los pies.

| Criatura@hueco | Sin placa: antes → después (mín. de 8 salas) | Con placa: antes → después |
|---|---|---|
| `candle_mite*` @350/396/460/540/572 | 0,048 / 0,061 / 0,059 / 0,043 / 0,045 → **0,079 / 0,094 / 0,099 / 0,082 / 0,070** | 0,02 → 0,04–0,05 |
| `candle_mite` entero @350/572 | 0,174 / 0,213 → 0,201 / 0,248 | 0,15 / 0,19 → 0,17 / 0,21 |
| `ash_slime` @396/466/540 | 0,043 / 0,042 / 0,033 → **0,078 / 0,086 / 0,076** | 0,01–0,02 → 0,03–0,05 |
| `cinder_bat` @350 | 0,075 → 0,075 | igual |
| `cinder_bat` @396–572 | 0,000–0,007 → 0,000–0,010 | igual |
| `soot_golem` @396/466 | 0,044 / 0,043 → 0,061 / 0,074 | 0,03 → 0,04–0,05 |
| `ember_magpie` @396/466 | 0,104 / 0,118 → 0,138 / 0,156 | 0,08 / 0,10 → 0,11 / 0,13 |
| `flame_moth` @396/540 | 0,076 / 0,092 → 0,084 / 0,098 | igual |
| `hollow_knight` @466 (tiro) | 0,097 → 0,102 | 0,084 → 0,085 |

En capturas reales del recorrido (piso 4; fotograma localizado por encaje exacto de color):

| Captura | Antes | Después |
|---|---|---|
| `07` gólem@350 · urraca@460 · babosa@572 | 0,027 · 0,114 · 0,030 | 0,013 · 0,147 · 0,062 |
| `18b` murciélago@350 · polilla@460 · ácaro*@572 · ácaro@572 | 0,101 · 0,106 · 0,068 · 0,226 | 0,101 · 0,113 · 0,097 · 0,252 |

## Por qué no llega todo a 0,10 (pendiente honesto)
- **El murciélago no se arregla desde la sala.** Su media es 0,125, la misma que el muro, y sus alas finas dejan ~30 % de
  fondo dentro de sus celdas de figura. Así Δ ≈ 0,7·|muro − 0,125|, y pasar pide un muro ≥ 0,27 (ladrillo paso 7). Lo
  simulé con el muro superior a 0,28–0,36 y el zócalo a 0,06. El murciélago pasa en 396–572, pero el gólem, la babosa y la
  polilla caen a 0,00–0,06. Con criaturas de medias 0,125 (murciélago), 0,19–0,20 (gólem, babosa, polilla) y 0,26–0,29
  (urraca, ácaro), ningún valor de fondo las separa a todas. Hace falta luz de recorte o canto en la criatura (C13 sigue
  abierta para el murciélago, archivos de criaturas).
- **Ácaro y babosa** quedan en 0,07–0,10. Lo que falta lo ponen su propia base oscura (filas de sombra dentro de la figura)
  y el arco o el pilar en x 350/396. Bajar más el zócalo y el suelo los deja casi negros: es aplanar la sala.
- **La placa de PV** pesa mucho: barra roja 0,53 y cifras 0,90 dentro del anillo. Con placa casi nada llega a 0,10. Si el
  criterio §4.1 se aplica en juego, hay que decidir si la placa cuenta como entorno (dirección/HUD).
- **Gólem en x 350** (sólo en el recorrido; en `enemy_db` el gólem va a 396/466) baja de 0,027 a 0,013: allí el arco es más
  claro que él y el pie del pilar, más oscuro, le resta.

## No hecho / no comprobado
- Muro del tiro menos plano y saeteras lejanas: no tocados (capa lejana). `check_room_quality` sigue en verde.
- Vetas: sólo cambié los focos. El trazado en escalera sigue igual.
- Ciclos II en juego, rendimiento y el pico C20: sin medir. Las capturas son por software (xvfb).

## Evidencia
- `antes_despues_07.png`, `antes_despues_18b.png`: arriba antes y abajo después (capturas del recorrido, a 1/2).
- `gris_1de4_07.png`, `gris_1de4_18b.png`: miniatura en grises a 1/4, ampliada ×3 (arriba antes).
- `variantes_despues.png`: las 12 variantes (vista previa). Filas: normal v0–v3 × c0/c1 y tiro v0–v1 × c0/c1.
- `tools/qa.sh bake --only=rooms`: 50 archivos, `--check` al día. `tools/qa.sh all`: juego 1745/0, arte 5 suites/0.
  Recorrido con `SHOTS_DIR=/tmp/claude-0/shots_sala`: sin fallos (sólo el `ERR_CANT_OPEN` de audio).
