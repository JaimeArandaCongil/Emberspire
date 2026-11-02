# F2-PULIDO-A · diario (N6, N7, N8 y BackBufferCopy de las cartas en vuelo)

Entorno: nube Linux, Godot 4.7.2 (`/opt/godot`), xvfb y llvmpipe. Antes: los archivos de `HEAD` (`ui.gd`, `combat_screen.gd`)
puestos en su sitio solo para capturar y restaurados después. `vida_capturas.tscn` a `--fixed-fps 60`. Recorridos `smoke.tscn`
con `SHOTS_DIR=/tmp/claude-0/shots_pa/{antes,despues}`. Cifras en `mediciones.json`.

Cierre: `tools/qa.sh game` QA 1745/0. `tools/qa.sh art`: `test_ui` en verde. Fallan `test_mv` (salas: `bg_act1.gd`, de F2-SALA en curso)
y `test_tec` (frescura de `soot_golem`, de otro agente que hornea). Ninguno de los dos es de este paquete. SMOKE OK, sin
errores salvo `ERR_CANT_OPEN` (audio).

## N8 · flotantes a ×2
- `UI.float_text` usa siempre `UI.FLOAT_SCALE` = 2 (antes `clampi(pixel_scale(size), 2, 3)`, y además el pop a ×s+1, es decir
  ×3 durante 60 ms en todos). El pop ahora es de color: un paso más claro de su rampa durante 60 ms. La x inicial va a px par.
  `size` ya no cambia la escala (el parámetro se llama `_size`; las llamadas no cambian).
- Legibilidad: a ×2, `blood` 3 (3,90:1 sobre el contorno `ink` 1) y `magic` 3 (4,23:1) no llegaban a 4,5. `UI.float_color`
  sube por la rampa hasta ≥ 4,5 (blood 4 = 6,61; magic 4 = 9,57). El resto ya pasaba. `test_ui` lo comprueba para todos los
  colores de flotante y sus pops.
- Cola (`VIDA_MODE=cola`, 120 f): 0 solapes, 0 sobre intención y 0 sobre cuerpo, antes y después. Bloques rotos en la zona de
  la cola: 6 capturas antes («+Hollín» ×3 en px 654–746 × 242–270, como en 10b del dictamen), 1 después (la carta en vuelo).
  `cola_turno_f51_antes_despues_x2.png`.
- 12 («9999!»): bloques rotos 0,40 % → 0,00 %. `12_antes_despues.png`. A ×2 los golpes letales pierden tamaño. Si dirección
  quiere más presencia, la opción en rejilla es ×4 solo fuera de la cola. No lo he hecho.

## N7 · mano en px pares
- `combat_screen._tween_hand_pos`: la recolocación interpola con `tween_method` y redondea a px pares en cada fotograma. También
  van redondeados el vaivén de «no» (`_deny`, solo x) y el alzado de la carta jugada (solo y).
- `VIDA_MODE=recoloca` (nuevo): se quema la primera carta y se registran las x de la mano. Antes: 40 carta·fotograma fuera de
  rejilla (x 379,52 → 312,45, desfase de medio px y de 1 px). Después: 0. La serie es 380, 366, 354, 344, 336, 328, 322, 318,
  314, 312: siempre baja, sin tirones. Bloques rotos de la mano: media del 3,22 % → 0,24 % (lo que queda es la carta que se
  quema). `mano_recoloca_f3_antes_despues_x2.png`.
- En el 09b del smoke de este entorno la mano ya estaba quieta en las dos tomas (0 %). La medida que cuenta es la de `recoloca`.

## N6 · aviso de Maestría
- `_tutorial_tip` sustituye el `_toast` de «Cada carta que quemas…»: el aviso ocupa durante 3 s la barra de ayuda (px y 92–116,
  Mini ×2, `magic` 5), que después vuelve a mostrar el consejo. Si el consejo ya se ha quitado (turno ≥ 3), sale en una placa
  igual en el mismo sitio. Ya no hay segunda barra a y 124–152 sobre los estandartes. `09_tutorial_antes_despues.png`.
- Los demás `_toast` de combate («¡En caliente!», «No tienes Energía…») siguen en `TOAST_Y` = 124 y pueden tapar los
  estandartes durante 1,9 s. No estaban en el encargo.

## BackBufferCopy en modo rect: no se cambia
- Con `COPY_MODE_RECT` y el rect de la carta (`Rect2(0, 0, cv.size)`), la carta sale negra en f7–14 de `descarte`
  (193 373 px distintos en y ≥ 534). Con un rect 5 veces mayor ocurre lo mismo. Solo un rect de 8000 px da 0 px distintos,
  y eso equivale a copiar la pantalla. Dos tomas en modo viewport dan 0 px distintos en y ≥ 534 (por encima hay ruido de
  partículas). Mi hipótesis es que en gl_compatibility el rect no se transforma bien con la carta escalada y girada (posible
  volteo en y), pero no lo he confirmado. Se queda en viewport con un comentario. `descarte_f9_viewport_arriba_rect_abajo.png`.

## No comprobado
- GPU real y WebGL (incluido el coste del modo viewport).
- La placa de aviso creada después del turno 3 (no sale en el smoke).
- `forge_screen` también usa `float_text`: ahora sus flotantes van a ×2 con pop de color. No lo he capturado.

## Ampliación N6 · todos los avisos de combate en la barra de ayuda
- `combat_screen._toast` ya no crea una placa en `TOAST_Y` (y 124, y apiladas a +48 px). Ahora pone el aviso en la barra de
  ayuda (px y 92–116, Mini ×2), que es una sola placa: muestra el consejo y, encima de él, los avisos (`_bar_show`). Los avisos
  van **en cola**: duran `NOTICE_SECS` 1,9 s, pero si hay otro esperando el actual se queda en `NOTICE_MIN` 0,8 s; no se
  repiten si son iguales y esperan como mucho 3. El de Maestría (`_tutorial_tip`) es el mismo aviso, con 3 s. Al acabar el
  combate (`engine.over`) la barra se retira. El color pasa por `UI.float_color`: `blood` 3 sube a 4 para llegar a 4,5:1 sobre la
  placa. `test_ui` lo comprueba con todos los colores de aviso.
- La barra no toca los rótulos de turno (y 50–82) ni la banda de intención del jefe (hasta y 88). Las intenciones normales van
  sobre las cabezas, mucho más abajo.
- Avisos que se movieron (todos los `_toast` de combate): «Clic derecho en la Leña para QUEMARLA…» (tutorial, piso 1), «Puerta
  avivada…», «Combustible: sólo puede QUEMARSE…», «Esta carta no se puede jugar», «No tienes energía suficiente», «Elige un
  objetivo», «La Ceniza Húmeda no prende…», «El horno necesita respirar…», «Sólo las cartas jugables de coste 1 o más…», «No
  tienes Energía para quemarla en caliente», «¡En caliente! ×2 Ascuas y Maestría», «<carta> · Maestría N», «¡Te roba … Ascuas…»
  y el de Maestría del tutorial.
- No se movieron los de la pantalla de recompensas («Obtienes …», «Primero elige una reliquia»): allí la barra ya se ha
  retirado y no hay estandartes a la vista. Pasan a `_reward_toast`, que es la placa de antes.
- Evidencia: `VIDA_MODE=avisos` (nuevo) muestra cada aviso por separado y, al final, tres a la vez («No tienes energía», «¡En
  caliente!» y «Golpe · Maestría 2», que se ven en orden). `avisos_antes_izq_despues_der.png`: 17 filas, px 160–1120 × 80–250,
  antes a la izquierda y después a la derecha.
- Cierre: QA de juego 1745/0, `test_ui` en verde y SMOKE OK. `test_tec` falla por la frescura de `soot_golem`, que hornea otro
  agente.
- Efecto a tener en cuenta: mientras se ve un aviso, el consejo del tutorial no está; vuelve en cuanto el aviso termina.
