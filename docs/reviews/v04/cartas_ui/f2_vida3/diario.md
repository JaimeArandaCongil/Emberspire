# F2-VIDA3 · diario (destello por pieza del jefe, invocaciones junto al jefe y descarte sin alfa)

Entorno: nube Linux, Godot 4.7.2 (`/opt/godot`), xvfb y llvmpipe. Para el antes usé los tres archivos de código de `HEAD`
(`palette_lit`, `fighter_view`, `combat_screen`) y para el después, los actuales. Herramienta: `tests/art/vida_capturas.tscn`
a `--fixed-fps 60` con los modos `jefe`, `invoca` y `descarte` (este último es nuevo). Los recorridos `smoke.tscn` del antes
y del después se hicieron con un `SHOTS_DIR` propio.

Cierre: `tools/qa.sh all` da QA 1745/0 y ARTE 5 suites/0. `smoke.tscn` da SMOKE OK con 29 capturas y ningún error salvo
`ERR_CANT_OPEN` (audio). En esta pasada `test_mv` salió en verde, a pesar de que F2-SALA tiene cambios sin cerrar en
`bg_act1.gd` y `rooms/`.

## 1 · C2 en el jefe: blanco sólo en la pieza golpeada

- `shaders/palette_lit.gdshader` declara ahora `uniform vec3 flash_piece` (x e y de mundo y un radio; un radio negativo
  significa todo el cuerpo). Mientras dura `flash_white`, sólo pasan a fuego 7 los píxeles cuya **ancla** (el centro de su
  pieza, según el formato índice) cae dentro del radio. Así la pieza destella entera y sin cortes. El resto del cuerpo sube
  `FLASH_REST_STEPS` = 3 pasos y conserva el dibujo. Después siguen +3, +2 y +1 pasos, como antes. Las criaturas reciben
  `(0, 0, −1)` y se comportan igual que antes.
- `fighter_view.FLASH_PIECE_R`: 10 → **26**. El jefe es un único rig sin máscara de piezas y su socket `hit` está en la boca de
  la tobera. Medí en el atlas las anclas cercanas a `hit` (idle f3, hurt f0–1, summon f3): la boca está a 1 px, el anillo de
  latón a 10 y el tubo de cobre a 24. La siguiente pieza, el cabezal, está a ≥ 38 px. Con 26 px destella la tobera completa
  (≈ 340 px de los ≈ 30 000 del cuerpo). En `attack` f2 también destella el chorro de fuego, porque está pegado a la boca.
- Problema que encontré al medir: la carta de ataque se colocaba en el centro del blanco −200 px y **tapaba la tobera** justo
  en el fotograma del destello. `combat_screen` coloca ahora la carta a la izquierda del cuerpo del blanco
  (`left − ancho − 8`), sin bajar de x 400 de pantalla (`CARD_STAGE_MIN_X`, donde acaba la heroína). Con criaturas normales
  la posición no cambia.
- Evidencia: `jefe_destello_antes_despues_f9_10_11_12_14.png`. Arriba está el antes: el f10 es una silueta blanca entera.
  Abajo, el después: en el f10 la tobera sale blanca, el resto sube 3 pasos y se sigue viendo el dibujo; f11–14 bajan por pasos.

## 2 · Ácaros invocados junto al jefe

Medidas: El Gran Fuelle ocupa 242 px de 332 y cada ácaro, 26. Las placas miden 78 px más 2 de margen. **No caben dos ácaros
con su placa a un mismo lado** del jefe dentro de x 300–632. La versión anterior metía uno bajo la tobera, encima del jefe.

La solución que apliqué, que me parece la menos mala, es **desplazar al jefe**. `_boss_centers()` reescrito:
- Prueba cada reparto izquierda/derecha. Las invocaciones de la izquierda empiezan en x 300, delante de la tobera. Las de la
  derecha llegan como mucho a x 632, con el cuerpo y la placa dentro. El jefe ocupa el hueco del medio, con
  `SUMMON_GAP` = 4 px de aire a cada lado. Las placas quedan separadas al menos su ancho.
- Elige primero el reparto con menos cambios de lado (cada invocación recuerda su lado en `_summon_side`, así que no cruza por
  detrás del jefe cuando muere la otra), después el más equilibrado y por último el de más holgura. Si no cabe ninguno, se usa
  el reparto general de antes.
- Resultado con 2 ácaros: ácaro en 313, jefe con el centro en 452 (cuerpo 331–573) y ácaro en 592. Placas en pantalla:
  548–704, 826–982 y 1106–1262. Están enteras y no se pisan.
- Arreglo que va junto: `_enemy_centers()` usaba los huecos de DECISIONES si no se solapaban *entre sí*, pero no comprobaba los
  bordes. Con el jefe y un solo ácaro, el jefe quedaba en 396, con el cuerpo desde x 275, fuera de 300–632. Ahora también se
  comprueban los bordes, y el jefe con un ácaro pasa por `_boss_centers`.
- Por qué lo elegí: el ácaro se lee delante de la tobera, de donde sale al invocarlo, y entre la heroína y el jefe. La otra
  opción, ponerlo en un plano más bajo delante del jefe, lo solapaba con las patas y exigía mover su placa.
- Evidencia: `14_invocacion_antes_despues.png` (la captura `14_boss_summon` del recorrido; a la izquierda el antes, a la
  derecha el después).
- `fighter_view.ground_gaps()` queda sin uso. No lo borré, por si dirección quiere volver a esa opción.

## 3 · Cartas al descarte sin alfa

Fuera los tres `modulate:a` de `combat_screen`: el descarte de fin de turno y las cartas jugadas que van al descarte o, si son
poderes, a la heroína. A mitad del vuelo (`CARD_DIM_AT` = 0,5) `_card_dim()` pone encima de la carta un `UI.dim_cover(−2)`. Es
hijo de la carta, no `top_level`, así que hereda su escala y su giro de vuelo. Usa la misma LUT que las recompensas y no gasta
memoria nueva. Al llegar al montón la carta desaparece de golpe.
- Encontré que la pantalla se copia una sola vez por fotograma y que la viñeta de combate ya la había usado: el atenuado pintaba
  el fondo sin la carta. Lo resolví con un `BackBufferCopy` de modo viewport justo antes de cada cubierta. El modo rect dejaba la
  carta en negro.
- Evidencia: `descarte_antes_despues_f0_4_7_9_11_13_15_17.png`. Arriba, el antes: las cartas se vuelven translúcidas. Abajo, el
  después: son opacas, bajan 2 pasos y desaparecen.
- `test_ui` comprueba ahora que `combat_screen` no tiene ningún `"modulate:a"` y que `palette_lit` declara `flash_piece`.

## Pendiente y no comprobado

- **Rendimiento**: cada carta en vuelo hace una copia de la pantalla completa durante unos 7 fotogramas (5 cartas al acabar el
  turno). No lo he medido en GPU real; en llvmpipe no se nota.
- Sólo he comprobado que el atenuado de la carta queda en la paleta a ojo. La escala de vuelo (0,15–0,25) remuestrea la carta
  y puede dejar colores intermedios que la LUT no cambia. La escala y el giro de vuelo vienen de antes: es movimiento, no
  reposo. Siguen igual que al robar.
- Las cartas que se agotan (`CardView.burn_away`, en `card_view.gd`, **fuera de mi paquete**) siguen fundiendo nombre, texto y
  orbe con `modulate:a`.
- En `attack` el jefe avanza 9 px y su chorro de fuego pasa por encima del ácaro de la izquierda durante 1–2 fotogramas.
- El ácaro de la derecha está junto al brasero del pilar derecho. Se lee, pero queda cerca.
- No he visto el destello por pieza en fase 2 ni con el jefe volteado. El shader ya contempla `flip_x` en el ancla.
- Multiatlas (`part_frames`): no aplica. No toqué `sprite_bank.gd` ni `light_rig.gd`.
