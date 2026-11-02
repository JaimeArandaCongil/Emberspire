# F2-ILUS3 · diario (card-illustrator)

Encargo: N4 (títulos), N2 y N3 (carta alzada en la rejilla ×2) y #7 («Fuego Interior» con más escena). Sin hornear y sin
commits. Entorno: nube Linux, Godot 4.7.2 (`/opt/godot`), xvfb. Capturas «antes» en `/tmp/claude-0/shots_ilus3_antes` y
«después» en `/tmp/claude-0/shots_ilus3`. Las dos tandas dan SMOKE OK.

## N4 · títulos: Fragua ×2 → Mini ×2 (`scripts/ui/card_view.gd`)

`CardView.title_layout()` devuelve `{"font": "fragua" | "mini" | "pavesa", "big", "x", "text", "fits"}`.

- **Fragua ×2**: la misma prueba píxel a píxel de antes (glifo + contorno + 1 px de placa en cruz contra el rombo del orbe
  propio y el del vecino, con `ORB_STEP` = 81).
- **Mini ×2**: celda en la fila de arte 7 (las mayúsculas en 8–12, la sombra `k` de 1 px de arte hasta la 13 y los
  descendentes hasta la 14). Se prueba glifo + sombra + 1 px en cruz contra los dos orbes y con 1 px libre hasta el canto de
  la placa (x 7–72). Va en columna par y sin material Fragua.
- El «+» se omite si el nombre base cabe en una letra mejor (no cambia de letra al mejorarse).
- **Recuento de los 99 nombres base**: 55 en Fragua ×2, 26 en Mini ×2 y **18 en Pavesa ×1**. Ninguno roza un orbe ni se
  sale de la placa. La prueba recorre los 198 nombres (con y sin «+»).
- **Bloqueo, decisión de dirección**: Mini ×2 no cabe físicamente en esos 18. Entre el orbe propio y el canto quedan unos
  61 px de arte, y los nombres miden hasta 80 («Muralla de Engranajes»). La placa entera mide 68. Sin la sombra cabrían 4
  más, y aun así quedarían 14. Para no romper el juego, esos 18 conservan Pavesa ×1 como último recurso. `test_ui` lo fija
  con `TITLES_PAVESA_MAX` = 18 (sólo puede bajar). Los 18 son: Templar el Acero, Embestida Blindada, Guardia de Ascuas,
  Armadura de Ceniza, Banquete de Ceniza, Tormenta de Cisco, Postura de Yunque, Ráfaga de Martillo, Guarda del Yunque,
  Aliento de Brasas, Mortaja de Ceniza, Tormenta de Fuego, Punto de Ignición, Llama de Brasero, Muralla de Engranajes,
  Canción del Hogar, Eco del Reliquario y Buscar Combustible.
  Propuesta: un nombre corto en `CardDB` (campo `short`, ≤ 58 px en Mini) para esos 18, o aceptar la excepción en DECISIONES.
- Evidencia: `13_titulos_antes_despues_x2.png`. Bloques 2×2 rotos en la rejilla par: en 13 «Golpe de Escudo», de 150 a 0;
  en 13 «Lluvia de Chispas», de 158 a 0; en 09 «Fuego Interior» (px 900–1020 × 604–622), de 119 a 0. «Guardia de Ascuas»
  sigue con 151, porque es Pavesa. En la placa de 13 no hay ningún color fuera de paleta.

## N2 y N3 · carta alzada en la rejilla ×2

- **N2.** La placa QUEMAR es ahora un Label vacío con dos líneas Mini ×2 hijas. `set_burn_hint()` centra cada línea en
  columna par (`_snap_mini`, que usa el ancho exacto de Mini) y en fila par (con una línea, y = 10; con dos, 2 y 20).
- **N3.** La cinta de tipo pasa a celda de 16 px, alineada arriba y centrada en columna par. Las mayúsculas quedan en las
  filas de arte 63–67.
- Bloques 2×2 rotos (08, con la rejilla par):

| Zona | Antes | Después |
|---|---|---|
| Tooltip, px 552–765 × 444–457 | 392 / 749 | **0** / 749 |
| Cinta, px 600–671 × 624–635 | 98 / 216 | **0** / 216 |

- Fuera de paleta en la carta alzada y la placa (px 540–780 × 440–640): 0 antes y 0 después. Evidencia:
  `08_hover_antes_despues.png` (izquierda, antes) y `08_combat_hover.png`.

## #7 · «Fuego Interior» (`scripts/art/cards/illus/set_icon.gd`, `inner_fire`)

- **Antes**: una mano centrada sobre el muro, casi un icono.
- **Ahora**: la heroína, de espaldas en la esquina inferior izquierda (pelo y hombro casi en silueta), apoya el codo en un
  antepecho de losas. El antebrazo lleva un brazal de cuero con correas y una hebilla de latón. La palma está arriba y los
  dedos se curvan alrededor de la llama.
- **Luz**: sólo la llama. Enciende el muro de la Torre en un halo tramado, pone al rojo los cantos que la miran y alumbra
  el antepecho, donde cae la sombra del brazo.
- **Planos**: muro, antepecho y figura.
- **Combinación** (registro de la cabecera): muro de la Torre + antepecho de losas · capilla · hombro, brazo y mano con la
  llama · el brazo entra desde abajo a la izquierda y la llama sube en el centro-derecha. No se repite en ninguna otra carta;
  la prueba de miniatura 34×23 pasa.
- **Colores** en la ventana: 18/1 antes, 29/0 ahora (tope de 30).
- Evidencia: `fuego_interior_x3_y_34x23_antes_despues.png` (×3 y miniatura 34×23) y
  `09_fuego_interior_antes_despues_x2.png` (en mano). Hubo 3 iteraciones: la mano se leía como un cuenco, y lo resolví con
  dedos abiertos y un paso de sombra entre ellos.

## QA y pendientes

- `tools/qa.sh all` en el cierre: QA 1745/0 y ARTE 5 suites/0. En pasadas intermedias fallaron dos comprobaciones de
  F2-VIDA4 en `test_ui`: el «dorso fantasma» (N5, de `combat_screen.gd`) y las «lenguas de Quemadura» (de `status_fx.gd`).
  Las dos eran de trabajo en curso de otro agente y no las toqué.
- Pendiente de dirección: los 18 títulos que ni en Mini ×2 caben (ver arriba).
- Sin comprobar: la placa QUEMAR con una sola línea (en las capturas siempre salen dos). `test_ui` sí comprueba que su origen, con una y con dos líneas, y el de la cinta caen en x e y pares.
- `NAME_X0` y `NAME_X1` se retiraron de `CardView` (los sustituyen `PLATE_X0/X1` y `PAVESA_X0`).
