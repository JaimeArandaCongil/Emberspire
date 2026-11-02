# F2-ILUS4 · diario (card-illustrator)

Encargo: nombre corto de presentación para los 18 títulos que no cabían ni en Mini ×2, y quitar `ffe173` de la carta
jugada. Sin hornear y sin commits. Entorno: nube Linux, Godot 4.7.2, xvfb. Capturas en `/tmp/claude-0/shots_ilus4`.

## 1 · Nombre corto (`short`)

- `CardDB`: campo `short` en las 18 entradas (documentado en la cabecera). `name` no cambia.
- `CardView.title_layout(title, short := "")`: primero prueba Fragua ×2 y después Mini ×2 con el nombre completo. Si
  ninguno cabe y hay corto, dispone el corto con las mismas reglas (puede quedar en Fragua o en Mini) y devuelve
  `"short": true`. Pavesa ×1 queda sólo como respaldo para un nombre largo sin corto, y hoy no hay ninguno.
- Con «+»: se usa el corto + «+». Si así la letra cambia, se mantiene la regla de F2-ILUS3: el título va sin «+» y la
  mejora se ve en la placa de oro. Esto pasa en Templar Acero, Guardia Ígnea y Muro Dentado, que van en Fragua.
- Tooltip: si el título muestra el corto, la primera línea es el nombre completo.
- Recuento de los 99 nombres base: **62 en Fragua ×2, 37 en Mini ×2 y 0 en Pavesa ×1** (antes 55/26/18).

| Completo | Corto | Ancho Mini (px de arte) | Letra del corto |
|---|---|---|---|
| Templar el Acero | Templar Acero | 51 | Fragua |
| Embestida Blindada | Embestida | 35 | Fragua |
| Guardia de Ascuas | Guardia Ígnea | 48 | Fragua |
| Armadura de Ceniza | Cota de Ceniza | 51 | Mini |
| Banquete de Ceniza | Festín de Hollín | 55 | Mini |
| Tormenta de Cisco | Racha de Cisco | 51 | Mini |
| Postura de Yunque | Pose de Yunque | 53 | Mini |
| Ráfaga de Martillo | Martilleo | 33 | Fragua |
| Guarda del Yunque | Yunque Guardián | 56 | Mini |
| Aliento de Brasas | Vaho de Brasas | 53 | Mini |
| Mortaja de Ceniza | Velo de Ceniza | 50 | Mini |
| Tormenta de Fuego | Tormenta Ígnea | 56 | Mini |
| Punto de Ignición | Ignición | 27 | Fragua |
| Llama de Brasero | Brasero | 27 | Fragua |
| Muralla de Engranajes | Muro Dentado | 48 | Fragua |
| Canción del Hogar | Canto del Hogar | 56 | Mini |
| Eco del Reliquario | Eco de Reliquia | 52 | Mini |
| Buscar Combustible | Acopio de Leña | 51 | Mini |

Todos caben también con «+» en Mini (el más ancho es Tormenta Ígnea+, con 60). Descartes: «Incendio», que ya es
`wildfire`; «Festín de Ceniza» y «Coraza de Ceniza», porque con «+» no caben; y «Buscar Leña», porque se leía como un
tutor de la carta Leña.

- `test_ui`: `TITLES_PAVESA_MAX` = 0. El corto sólo puede existir si el completo no cabe en Mini, debe medir
  ≤ 58 (`SHORT_MAX_W`), no puede repetirse ni coincidir con otro nombre y no lleva punto. La rejilla y la placa se miden
  sobre el texto que se muestra. También se comprueba que «Muralla de Engranajes» muestra su corto y que el tooltip
  conserva el nombre completo.
- Evidencia: `18_titulos_antes_despues.png`. Columnas: antes, después, antes «+» y después «+». El «antes» sale de un
  worktree de HEAD.

## 2 · `ffe173`

- Causa: `card_view.gd` asignaba al marco `UI.dissolve_material`, un material legado que nunca avanzaba. Con
  `progress` = 0, el shader pinta `edge_a` (1, 0.88, 0.45 = `ffe173`) en las celdas donde `v` < 0.06, que son las de
  ruido bajo en el canto inferior (2 celdas de arte, 8 px). Sale en todas las cartas, pero en la mano el canto queda
  fuera de pantalla: por eso sólo se veía en la carta alzada, la jugada y el descarte.
- Arreglo: el marco va sin material en reposo, y la quema sigue usando `_burn_material`. `test_ui` comprueba que
  `_frame.material == null`.
- Píxeles `ffe173` por captura: antes 8 en 08, 8 en 10, 24 en 13, 20 en 19 y 96 en 23. Después, **0 en las 29**.
  Colores ajenos en 08, 10, 10b y 13: 0. Evidencia: `10_carta_jugada_sin_ffe173.png`.

## Tienda (19) y compendio (23)

Las dos usan `CardView`, así que aplican la misma regla. En la 19, «Embestida» va en Fragua; en la 23, «Yunque Guardián»
va en Mini. Ningún título desborda. Los muchos colores ajenos de 19 y 23 son el fondo oscurecido del modal, no
las cartas, y ya estaban.

## QA

`tools/qa.sh all`: QA 1745/0 y ARTE 5 suites/0. SMOKE OK.

Pendiente: el texto de `UI.dissolve_material` sigue en `ui.gd`, que lo usa `fighter_view.gd`; no es de mi paquete. Sin
comprobar a mano: el tooltip con el nombre completo en pantalla (sólo lo comprueba el test).
