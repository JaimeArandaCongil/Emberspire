# F2-PULIDO-C · Diario (muro del tiro y saeteras lejanas, dictamen F2-REV3 punto 6)

## Cambios (sólo `scripts/art/bg/bg_act1.gd`, capa lejana del tiro `_build_shaft`; horneado en `assets/baked/rooms/`)
La capa lejana del tiro es compartida: el cambio llega a las 2 variantes de tiro en los ciclos I y II (`far_flue_*`).
- **Escena del tiro** (`SHAFT_CALM`): cuerpo del jefe (art 326–581 × 128–207) y su lomo y grúa (440–581 × 74–127). Más
  `SHAFT_QUIET` sobre la cabeza (326–439 × 74–127). Ahí el muro se **aquieta**: no hay paños de hornada ni ladrillos sueltos
  a +1. Los de −1 se quedan. Ladrillo a paso ≥ 4 tras el cuerpo: 2.438 → 1.396 px, con paso máximo 6 → 4.
- **Saeteras legibles fuera de la escena**: si el centro de la saetera cae fuera de `SHAFT_CALM`, el marco que mira al foso
  sube a piedra 4 (clave 5), con alféizar de piedra 4/3 y una fila de sombra bajo él. Una nueva **encendida** en el
  flanco izquierdo (ángulo −0,70, x ≈ 298, y ≈ 148–178), entre la jamba y la escena.
- **Luz de las lámparas** de las saeteras encendidas sobre el muro, por pieza (ancla): +2 a < 13 px y +1 a < 22 px. La causa
  es la lámpara. Sólo hay luz si la saetera está fuera de la escena.
- **Luz fría de la cima** (la Torre): una `far_light` fría en elipse ancha (p 440,−20; r 130/184; ys 2) moja la parte alta
  del muro en dos bandas que siguen la curva de las hiladas. Tope `SHAFT_COLD_Y1` = 74, a 8 px (2 celdas a 1/4) sobre la
  grúa (y 82).
- Probado y descartado: (a) una luz fría hasta y 122, que quedaba como mancha azul con un corte recto y subía la
  desviación tras el jefe (11,95 → 12,66) mientras su separación bajaba (0,121 → 0,118); (b) dejar marcadas la saetera de
  x 513 (tras la grúa) y la luz de x 375 a r 24. También restaban separación.
- `tests/art/test_mv.gd` (`_check_shaft_slits`): la luz fría no baja de y 74; tras el cuerpo del jefe no hay ladrillo a
  paso > 4 (≤ 1.500 px a paso 4); las saeteras de x 375 y x 298 tienen ≥ 20 px de piedra ≥ 4.
- Paleta: sólo `Palette` (rampas `stone`, `brick`, `fire` y fría de `brick`). No hay fuentes vivas nuevas: todo está horneado
  y es estático, así que el presupuesto de movimiento no cambia. Sólo hay unos pocos px de `fire` más, con el pulso emisivo
  global de siempre. La prueba de ≤ 120 px de fuego lejano sigue en verde.

## Medidas (`medir_tiro.py`; `medidas_antes.json` y `medidas_despues.json`)
Las capturas del recorrido no son deterministas: el jefe cambia de pose entre recorridos (07 cambia 5.574 px sin tocar
nada). Para que la medida sea determinista, se pegan las figuras de la captura «antes» (con su luz de juego) sobre las
**4 salas de tiro** horneadas (vista previa) antes y después. Contraste: gris a 1/4, figura frente a un anillo de 2 celdas
(`test_da.thumbnail_separation`). Iguales en v0/v1 × c0/c1.

| Medida | 14 antes → después | 14a antes → después |
|---|---|---|
| Separación del jefe | 0,1211 → **0,1227** | 0,1229 → **0,1246** |
| Ácaro izq. / der. | 0,164–0,167 / 0,162–0,166, **iguales** | 0,119–0,121 / 0,136–0,139, **iguales** |
| Desv. tras el cuerpo (art 333–572 × 132–205, sin figura) | 10,59 → **9,98** | 10,64 → **10,02** |
| Desv. en el bbox del jefe con la grúa (× 82–205) | 11,95 → **11,82** | 12,01 → **11,88** |

Referencia de la sala normal: C19 = 10,13 (07, `medir.py` oficial; sin cambios en esta ronda).
Contraste con sprites horneados en las 4 salas de tiro: `hollow_knight`@466 0,137 y `candle_mite`@312/466/591
0,207/0,215/0,232, **iguales**. Vista previa sola (sin figuras): cuerpo del jefe 14,36 → 13,64; élite@466 14,59 → 13,52;
flanco izquierdo 14,3 → 16,8 y cúpula 12,1 → 13,1 (aquí sube a propósito: es el muro que queda a la vista).
Con `medir.py` sobre 07, 14 y 14a: paleta 100 %, 0 ajenos y 0 % de bloques rotos, igual que antes.

## Evidencia
- `antes_despues_14.png` y `antes_despues_14a.png`: recorrido a 1/2, arriba antes y abajo después.
- `tiro_x1_14_antes_despues.png`: el arco a ×1 (px 540–1220 × 60–430), a la izquierda antes.
- `variantes_tiro_antes_despues.png`: las 4 salas de tiro en vista previa (v0c0, v0c1, v1c0, v1c1), arriba antes.
- `tools/qa.sh bake --only=rooms`: 50 archivos, `--check` al día. `tools/qa.sh all`: juego 1745/0, arte 5 suites/0.
  Recorrido (`SHOTS_DIR=/tmp/claude-0/shots_pc`, antes en `shots_pc_antes`): sin errores, salvo el `ERR_CANT_OPEN` de audio.

## No hecho / no comprobado
- En 14 la barra de ayuda (px y ~70–100) tapa casi toda la banda fría de la cúpula. Se ve sobre todo a la derecha.
- La saetera de x 313 queda medio oculta tras la jamba del arco medio. No la he movido.
- La máscara del jefe sale de la captura (contorno + colores ajenos al fondo, con huecos rellenos) y cubre de más entre las
  patas. Antes y después se usa la misma.
- Ciclo II en juego, élites en juego (sólo con sprite pegado) y rendimiento: sin medir. Capturas por software (xvfb).
