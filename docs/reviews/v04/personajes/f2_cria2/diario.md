# F2-CRIA2a · Diario (C5 `ash_slime`, C12 `soot_golem`)

## C5 · `ash_slime` (redibujo completo)
- El cuerpo es una losa con pasos forzados **generada por parámetros** (`_body`): cada deformación es una vista propia
  (`view:body`), redibujada a su tamaño; se acabó el escalado por vecino más próximo de una cuña dibujada a mano.
- Silueta: perfil por filas con punta de gota atrás (`apex`) y barriga baja que recoge (`tm`); base con 2 muescas → 3 lóbulos;
  goterón en la muesca trasera (4 estados). `_soften` rompe cualquier tramo recto de contorno > 4 px con un abombamiento de 1 px.
- Medido en la hoja horneada (tramo máx. horizontal/vertical del contorno): reposo, telegrafía, ataque y golpe **≤ 4 px**;
  sólo el charco de la muerte (f3–f5) es plano. Tamaño en reposo 46×30 (antes 45×31).
- Costra de ceniza sólo en el ~28 % superior, borde con lenguas irregulares, sombra de 1 px debajo; 15 píxeles de grieta de brasa
  (tronco al paso 5, ramas 4/3; al blanco relativo en telegrafía, apagándose en la muerte).
- Ojos sellados en una palanca (`face`) que sigue la altura de cada forma. Todas las vistas dejan brasa visible (parpadeo y
  golpe = rendija encendida); sólo desaparecen en el charco final.
- Brillo húmedo de 2 px (`tar` 5) que recorre el flanco en reposo.
- Reposo 6 f: la base se abre 1 px primero; luego el cuerpo baja 1–2 px y la punta llega un fotograma tarde y 1–2 px más atrás.
- Ataque: estirado sin lóbulos con la punta atrás → salpicón ancho. Colores: `coal`, `ash`, `fire`, `smoke`, `linen` (dientes).

## C12 · `soot_golem`
- Hueso `head` de (-27, -31) a (-21, -42): la cabeza queda sobre el hombro delantero, a la altura de la joroba.
- `cast`: brazo hacia delante y arriba (`arm_n` 1,15, `fore_n` 0,9), por detrás de la cabeza en z; el puño queda delante y
  encima de la cara sin taparla (`10b_enemy_turn.png`).
- `attack`: carga atrás (root +3, -2) → estela con el cuerpo en marcha (-5) → impacto a **-9 px**, columna inclinada hacia delante,
  pierna cercana adelantada y lejana estirada → recuperación a -4. Alto en reposo 88 (sin cambio).

## Evidencia
- `tools/qa.sh bake --only=ash_slime,soot_golem`: 0 errores. `tools/qa.sh all`: QA de juego 1745/0; arte 5 suites, 1 fallo
  **ajeno**: `test_ui.gd` «CardView.ORB_STEP no sigue al paso de la mano» (cambios de cartas sin cerrar de otro agente).
- Recorrido (`SHOTS_DIR=/tmp/claude-0/shots_cria2`): copiadas `07_combat.png`, `10b_enemy_turn.png`, `10_swing.png`,
  `recorte_07_10b.png`, y las hojas `hoja_ash_slime_x2.png`, `hoja_soot_golem.png`. El registro mostró un
  `ERROR: Condition "status < 0" ... ERR_CANT_OPEN` sin origen localizado (no parece de arte).

## No comprobado / pendiente
- El ataque del gólem y el ataque/muerte del limo sólo se vieron en hoja, no en juego.
- En juego el alquitrán del limo es oscuro sobre el suelo oscuro; lo sostiene el contorno y la costra. Si se pide más
  separación: subir un paso el flanco iluminado o añadir sel-out cálido (como C13).
- «+Hollín» se monta sobre la cabeza del gólem en `10b` (HUD, C16; no es de este paquete).
- Las grietas de losa forzada no llevan la bandera emisiva (igual que antes): no reaccionan al estado del shader.
