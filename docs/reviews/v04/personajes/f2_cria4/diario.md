# F2-CRIA4 · Diario (#5: C5 `ash_slime`, C12 `soot_golem`)

Nube Linux, Godot 4.7.2, xvfb. Archivos: `scripts/art/defs/creatures/ash_slime.gd`, `scripts/art/defs/creatures/soot_golem.gd`,
su horneado (`assets/baked/creatures/ash_slime*`, `soot_golem*`) y `tests/art/out/qa/ash_slime_qa.png`.

## 1 · `ash_slime`: limo blando y húmedo, separado del suelo

### Cambios
- **Base lobulada**: muescas de 5 px (delantera, semiancho 3,4) y 6 px (trasera, semiancho 6,2), frente a las de 2,6–3 px de
  antes. Las esquinas de la fila de apoyo de cada lóbulo se recortan, así que los 3 lóbulos acaban en bulbo y no en escalón.
- **Goterón**: ahora es un sello (`drip`, en `root`, x = `DRIP_X` 7) colgado del techo de la muesca trasera, con 4 vistas:
  bulto → lágrima colgando → lágrima larga que toca el suelo → cae y se aplasta. Usa `coal` 4/5, la chispa en `linen` 5 y el
  charco en `rock_soot` 6. Dibujado como píxeles de la losa, el sel-out del motor se lo comía (quedaba 1 px claro dentro
  de una mancha negra). Sólo se ve en las formas `i*` (reposo y rebote del golpe).
- **Alquitrán un paso más claro**: pasos 3–5 de `coal` en lugar de 1–4. El flanco iluminado va en 4, la sombra en 3, el
  canto frío de la Torre en 4 y un toque de 5 en la luz máxima. La sombra bajo la costra baja a 2.
- **Labio cálido (sel-out cálido de la base)**: la cara inferior de cada lóbulo y el techo de las muescas llevan 1 px de
  `rock_soot` 6, y 5 en el lado de sombra. Ranura nueva `lip`. El contorno exterior lo sigue poniendo el motor.
- **Brillo húmedo**: chispa de 2 px en `linen` 5 con un eco de 1 px en `linen` 4, bajo la costra y detrás de los ojos (ranura
  `wet`). Recorre la coronilla con `gloss`. Además hay un canto mojado de 1 px (`coal` 5) por dentro del flanco delantero.
- No cambian la costra, las grietas, los ojos, la boca, las formas de telegrafía, ataque, golpe y muerte, el tamaño (46×30
  en reposo) ni el lienzo. Colores: sólo de `Palette` (`coal`, `ash`, `fire`, `smoke`, `linen`, `rock_soot`).

### Medida (métrica oficial de F2-SALA, `medir_limo.gd.txt`)
Es `medir_bat.gd.txt` de F2-CRIA3 apuntado al limo: `test_da.thumbnail_separation` (gris a 1/4, anillo de 2 celdas), sin
placa, sobre las 8 salas normales (luz dinámica 0) y con cada fotograma de `idle` centrado como `FighterView`. El «antes» es
el horneado de HEAD y reproduce las cifras de F2-SALA (0,078 / 0,086 / 0,076).

| Hueco (mín. de 8 salas) | 350* | 396 | 460 | 466 | 540 | 572 |
|---|---|---|---|---|---|---|
| Antes | 0,000 | 0,078 | 0,087 | 0,086 | 0,076 | 0,082 |
| **Después** | 0,061 | **0,139** | **0,152** | **0,150** | **0,141** | **0,146** |

Por fotograma (mínimo sobre las salas y los huecos 396–572), antes → después: f0–f5 0,086 · 0,088 · 0,078 · 0,078 · 0,076 ·
0,077 → **0,152 · 0,149 · 0,139 · 0,143 · 0,141 · 0,145**.

Luminancia del cuerpo (mediana de las filas del 35 al 75 % del bbox, horneado): de 0,147 (f3 y f4: 0,233) a **0,233 en los 6
fotogramas**. En la captura 07 (sólo píxeles de `coal`, zona media): de 0,147 a **0,233**.

\* El limo nunca ocupa el hueco 350 (`combat_screen.SLOTS`: sólo los grupos de 3 lo usan, y en `enemy_db` ningún grupo de 3
lleva limo). Ahí el anillo es el arco claro (≈ 0,195) y la figura queda en 0,21–0,25: para pasar haría falta un limo de
≥ 0,30, que ya no sería alquitrán. Las salas de tiro tampoco pasan (0,000 → 0,040); el limo no aparece en ellas en el acto 1.

### Revisión
- `hoja_ash_slime_reposo_x4.png`: los 6 fotogramas de reposo. Se ven los 3 lóbulos en bulbo, el goterón que crece, toca el
  suelo y cae, el brillo que se desplaza y el labio cobrizo en la base.
- `hoja_ash_slime_resto_x3.png`: telegrafía, ataque, golpe y muerte; ninguna se rompe.
- `antes_despues_07_limo.png` (captura 07 ×2, arriba antes): la base deja de ser recta y se separa del suelo y de la placa.
- `gris_1de4_07.png` (gris a 1/4 ×6, arriba antes): el limo pasa de una mancha que se funde con el suelo a un domo más claro
  con la base dentada.

## 2 · `soot_golem`: gesto (`cast`) con la cara por encima del hombro

- Antes: brazo cercano a 2,0 rad (el brazo salía arriba y a la izquierda, a la altura de la cara) y columna a 0,10/0,14. El
  hombro y el codo quedaban junto a la cara.
- Ahora el gólem se encabrita: columna a 0,24 (f0) y 0,28 (f1), así que la cabeza sube y queda sobre el hombro. El brazo
  cercano sale casi horizontal hacia delante, por debajo de la cara (`arm_n` 0,52, ángulo total ≈ 1,5 rad), y el antebrazo
  sube con algo de inclinación hacia delante (`fore_n` 1,6). El puño queda delante, a la altura de la frente, y separado de
  la cara. La cabeza sigue en z por encima del brazo.
- Medido en el horneado (f1): los ojos están a **72 px** sobre el pie (antes 66) y a 48 px del borde superior del lienzo
  (antes 51). El bbox del gesto es 27–125 × 33–120 y cabe en el lienzo de 128.
- No cambia nada más: `idle` es idéntico píxel a píxel (bbox 25–112 × 22–120, alto 88 + 1 de máscara). Los fotogramas 1–3
  del ataque son idénticos (impacto a −9 px). El f0 del ataque es la telegrafía (`tell2`), como antes, y la estela de f1
  parte ahora del puño alzado delante (`hoja_soot_golem_cast_ataque_x2.png`).
- En juego (`antes_despues_10b_golem.png`, arriba antes; `10b_enemy_turn.png`): la cara queda arriba y despejada. «+Hollín»
  y el «⚔ 10» de la intención quedan por encima de la cabeza y ya no la tapan en esta captura.

## Evidencia
- `tools/qa.sh bake --only=ash_slime,soot_golem`: 2 horneadas, 0 errores.
- `tools/qa.sh all`: QA 1745/0, ARTE 5 suites/0.
- Recorrido: antes en `/tmp/claude-0/shots_cria4_antes` y después en `/tmp/claude-0/shots_cria4`. SMOKE OK; sólo sale
  `ERR_CANT_OPEN` (audio). Copiadas `07_combat.png` y `10b_enemy_turn.png` (después).

## Ajeno / pendiente
- **`scripts/art/bg/bg_act1.gd` lo está cambiando otro agente** mientras trabajo, y las salas horneadas aparecen modificadas
  en `git status`. En el último horneado, `bake_rooms --check` dio «las fuentes cambiaron desde el último horneado» (1 error,
  no mío); antes de ese cambio decía «al día». Mis medidas usan `BgAct1.build` del árbol de trabajo. El «antes» coincide con
  F2-SALA, así que el cambio de salas no las altera de forma apreciable, pero conviene volver a medir cuando se cierre.
- No comprobado: la lectura del limo y del gólem bajo la luz dinámica fuerte (Quemadura y destellos); el goterón y el
  brillo a ×1 sólo en la captura 07, que es un fotograma; el ataque del gólem sólo en la hoja.
- La lectura «blando, húmedo» a 1/4 es un juicio a ojo: a esa escala el brillo de 2 px se pierde y la lectura depende de la
  base dentada y del valor.
