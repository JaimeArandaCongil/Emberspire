# Diario · Cartas e interfaz (UI)

## Fase 1 · Cimientos

### Qué entra en el juego
| Pieza | Archivo | Estado |
|---|---|---|
| Fuentes Pavesa (6×9, con negrita de doble trazo) y Mini (3×5) | `scripts/ui/pixel_font.gd` | En uso |
| Corrección de la `í` de Fragua (el palo quedaba a la izquierda y se leía "t/tulos") | `scripts/ui/pixel_font.gd` | En uso |
| Kit 9-slice teselado: piedra, hierro, pergamino, botón ×4, pestaña, barra, placa teñida | `scripts/art/ui_kit.gd` | En uso por el tema |
| Tema sin `StyleBoxFlat`; `UI.box()` devuelve una placa 9-slice; colores de `UI` desde `Palette` | `scripts/ui/ui.gd` | En uso |
| Marco 80×112 con todos sus estados | `scripts/art/cards/frame.gd` | En uso |
| `CardView` a ×2 con Pavesa | `scripts/ui/card_view.gd` | En uso |
| Gramática y kit de ilustración | `scripts/art/cards/illus/` | En uso |
| 12 ilustraciones (mazo inicial + 8 primeras de Base) | `scripts/art/cards/illus/set_base.gd` | En uso |
| Pruebas | `tests/art/test_ui.gd` | 0 fallos |

Las 12: strike, defend, kindling, ember_slash, heavy_hammer, sparks, cleave, iron_wall, quench, bellows, stoke, coal.
Las otras 81 cartas usan `CardIllus.fallback()`: fondo por tipo + icono v0.3 ajustado a la paleta.

### Decisiones
- **Jerarquía por debajo de 20 px.** Pavesa sólo existe a ×1, así que sin más los tamaños de 10 a 19 px quedaban iguales.
  Desde 16 px `UI.label()` usa Pavesa negrita.
- **Tamaños de fuente.** Las fuentes de mapa de bits usan `INTEGER_ONLY`. Medido: de 10 a 20 px se dibujan a ×1 y de 27 a
  30 px a ×2. Ningún `font_size` de las pantallas puede dar una escala fraccionaria.
- **Sin alfa ni mezclas.** Para aclarar u oscurecer se sube o baja de paso dentro de la rampa (`IllusPx.shifted`, `veil`).
  El brillo de rara son 6 fotogramas precalculados en vez de un shader que mezcle colores.
- **Colores de fuera.** Las pantallas siguen pasando hex a `UI.box()`. `UIKit.plate()` los ajusta al color de paleta más
  cercano (`CardPal.snap`), de modo que la salida queda en paleta sin tocar archivos ajenos.
- **Arranque sin caché.** `ui.gd` y `ui_kit.gd` precargan sus dependencias, para que un `class_name` nuevo no rompa el
  arranque antes de reimportar (aviso de DA).
- **Nombre de la carta.** Se centra salvo que choque con el orbe; entonces se apoya a su derecha ("Muro de Hierro" quedaba
  tapado). En Fragua ×2 hasta 122 px; si no cabe, Pavesa ×1.
- **Aviso de quemar.** Pasa a una placa encima de la carta, porque al subir entera ya no queda pantalla debajo.
- **Aura.** Sólo rodea el orbe si la carta lo muestra; los combustibles no tienen orbe y salía su contorno vacío.
- **Trazo de poco común.** Baja de `steel` frío 6/4 a 5/3: el punteado blanco competía con la ilustración.

### Iteraciones de ilustración
- **Defensa:** la garra era una bola oscura con barras; ahora es un antebrazo que se estrecha, con tres uñas en gancho.
- **Martillazo:** era un bloque con mango, quieto; ahora es un mazo que golpea de cara, con arcos de movimiento y polvareda.
- **Lluvia de Chispas y Barrido:** las siluetas eran rectángulos; ahora son criaturas (limo, ácaro, murciélago, urraca, gólem).
- **Enfriar:** la hoja era una línea roja; ahora mide 3 px, se enfría al sumergirse y el vapor es de bocanadas con volumen.

### Evidencia (`tests/_review_art/v04/cartas_ui/out/`)
- `p1_illus_x4.png`: las 12 ilustraciones ×4.
- `p1_frames_x2.png`: marcos con ilustración, sin texto.
- `p1_cardview_12.png`: `CardView` real a resolución de juego.
- `p1_cardview_states.png`: mejorada, Maestría, Temple, rara y auras. Las auras están superpuestas a mano, sin motor de
  combate; los estados quemable y en caliente no se han visto en una partida real.
- `p1_theme.png`: fuentes, botones, paneles y pestañas con el tema nuevo.
- Regenerar: `tests/_review_art/v04/cartas_ui/phase1_illus.gd` (headless) y `p1_cards.tscn` (con ventana).

### Pendiente
- `combat_screen.gd` (TEC, fase 2): colocar la mano con las medidas de abajo.
- Valoración de calidad: las más flojas son Barrido (criaturas pequeñas, casi tapadas por la estela) y el gólem de Golpe,
  que a tamaño real pierde lectura. Ninguna ilustración ha tenido todavía la pasada a mano que C5 pide para el nivel A, ni
  el fotograma animado de Maestría 3.
- C5: "nunca se repite fondo + encuadre + sujeto + posición" no está automatizado. `test_ui` sólo compara miniaturas 34×23
  entre las 12 existentes; hacen falta metadatos por carta para comprobar la regla.

### Medidas para la mano (TEC)
- Carta: `CardView.SIZE` = 160×224. En reposo asoman `CardView.PEEK` = 128 px, es decir y = 592 de pantalla (296 de arte).
- Al pasar el ratón sube entera: y ≤ 496 (720 − 224).
- Fuera del rectángulo de la carta: orbe 12 px arriba e izquierda; aura 18 px por cada lado; placa de quemar
  54 px por encima (`HINT_H` + 16), 30 px más ancha por cada lado.
- Mano de 10 cartas: paso de 90 px en el tramo x 150–1120 (medido en `c3_hand_10.png`).
