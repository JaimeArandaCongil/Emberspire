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
