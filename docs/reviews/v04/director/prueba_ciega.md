# Prueba ciega: criaturas e ilustraciones

Revisadas sólo las cinco hojas de `docs/reviews/v04/director/ciega/`, contra `docs/ART_BIBLE.md` (§5, §6, §8, §9, §12, §14, §15).
No se ha consultado código, git, diarios ni origen de las piezas. Por eso cada corrección se asigna a la **hoja** y a su celda, no a
un archivo fuente.

**Convenciones.** F = fila y C = columna, desde 1. Las coordenadas son aproximadas, en px de arte dentro de la celda. Celdas medidas:
`criatura_1` 120×112, `criatura_2` 104×96, `criatura_3` 88×64 (las tres a ×3); ilustraciones 68×46 (a ×4).

## Resumen

| Hoja | Silueta y lectura | Materiales | Anatomía o composición | Acabado | **Global** |
|---|---|---|---|---|---|
| `criatura_1` | 7 | 5 | 6 | 6 | **6** |
| `criatura_2` | 5 | 4 | 4 | 5 | **4,5** |
| `criatura_3` | 8 | 7,5 | 7 | 7 | **7,5** |
| `ilustraciones_1` | 7,5 | 8 | 7 | 7 | **7,5** |
| `ilustraciones_2` | 6 | 6,5 | 6 | 6 | **6** |

Ninguna hoja llega a 8. **Hoja claramente por debajo: `criatura_2`** (ver su apartado). Entre las ilustraciones, `ilustraciones_2`
queda por debajo de `ilustraciones_1` por dos de sus tres viñetas. La tercera, la torre, es de las mejores de la prueba.

### Problemas comunes

- **Recortes en el borde de celda** en las tres criaturas (detalle abajo): la pose se sale del lienzo.
- **Reposo de 8 fotogramas**, cuando §12 pide 4–6. Además, las diferencias entre ellos son mínimas: casi no hay rasgo vivo.
- **Muerte por material** (§14) sin resolver en `criatura_1` y `criatura_2`: es un colapso del cuerpo girado, no una rotura propia del material.
- **Más de 12 colores por ilustración** (§9) en las 15 viñetas (ver tabla de `ilustraciones_1`). Es un fallo objetivo y medido, no de gusto.

## `criatura_1`: caballero de escudo y espada

**Lo que funciona.** Yelmo con cresta, escudo con cruz y espada se leen a 32 px, y la silueta en negro es la de un caballero. La brasa
del pecho es un punto emisivo claro y bien situado.

**Lo que falla.**
- **Metal que no parece metal.** Todo el cuerpo es un gris violáceo mate: se lee como goma o tela. No hay el especular de 1–2 px ni
  apenas remaches que exige §5.
- **Masa roja ambigua.** La pieza roja tras el brazo (x78–87, y40–65) parece un saco en reposo. En el ataque (F3C2–C5) se separa y
  parece un segundo brazo con dedos.
- **Muerte discontinua.** De F5C4 (arrodillado) a F5C5 (bulto plano) el salto ocurre en un solo fotograma. El cadáver es irreconocible, y
  F5C5–C8 son prácticamente iguales.
- **Recortes.** Espada en F2C1–C2 (arriba), estela en F3C2 (arriba) y espada en F5C2–C3 y F5C5–C8 (abajo).
- **Tamaño.** Unos 102 px de alto con la cresta. Si es élite, supera el máximo de 100 (§8); si es normal, queda muy por encima de 72.

**Correcciones para llegar a 9.**
1. Hombrera (x63–82, y28–47), yelmo y muslos: un brillo de 1–2 px al paso máximo arriba-izquierda, pegado al paso 2, sin intermedios.
2. Remaches de 1 px con brillo y sombra en la gola, el borde de la hombrera y el canto del escudo (mínimo 8 visibles). Sel-out cálido en el borde hacia la Forja.
3. Masa roja: redibujarla como capa con bandas verticales (periodo 6–8 px), borde inferior −1 y cola de golondrina, unida al hombro. En F3C2–C5, que caiga detrás en vez de sobresalir con dedos.
4. Separar brazo de torso con una línea de contacto de −2 pasos. Engrosar el antebrazo de la espada en 2 px, y añadir mano sellada en la empuñadura.
5. Muerte: insertar un fotograma intermedio entre F5C4 y F5C5, y que el cuerpo se desarme por piezas (yelmo que rueda, placas planas, espada visible). Usar los fotogramas de espera para que la brasa se apague por pasos, no para repetir.
6. Reencuadrar para que nada se recorte: bajar el sprite o ampliar la celda 12 px arriba y 8 abajo. Fijar la familia y ajustar a ≤ 100 px si es élite.

## `criatura_2`: coloso esférico de chapas o vendas

**Hoja claramente por debajo del resto.** Incumple a la vez la jerarquía de volumen, la lectura de material y la coherencia del punto
emisivo, y son defectos de diseño: no se arreglan retocando píxeles. Las otras dos criaturas sólo necesitan pulido.

**Lo que falla.**
- **Elipses lisas.** El cuerpo (x25–77, y32–72, unos 52 px) y la joroba (x60–83, y14–37) son lo que §15 prohíbe: elipses grandes de
  aspecto "vector", con degradado por bandas. Rompen §5 (ninguna elipse lisa > 20 px sin aplanar ni facetar).
- **Material indescifrable.** Las bandas diagonales pueden ser piedra, vendas o masa de pan. Las facetas y juntas que pide §5 no aparecen.
- **Silueta genérica.** En negro a 32 px queda un bulto con dos lóbulos; la cabeza desaparece. No alcanza el criterio de silueta única.
- **Anatomía sin peso.** Cabeza diminuta (x38–55, y13–30), sólo un brazo legible, brazo como tubo y pies pegados sin carga.
- **Emisivo plano.** En telegrafía y ataque, la ranura se vuelve un rectángulo claro (F2C3, F3C1–C2) que parece una ventana de interfaz: no sigue la curva del cuerpo y sus dientes negros flotan desalineados (F3C3).
- **Muerte y recortes.** De F5C5 (bola girada entera) a F5C6 (torta plana) no hay rotura. El brazo se recorta en F2C3, F3C2 y F3C3, y el papel toca el borde derecho de la celda en reposo.

**Correcciones para llegar a 9.**
1. Rediseñar el torso como 5–7 bloques facetados con normal constante por faceta y un máximo de 3 planos de luz (§5). Juntas de 1 px a −3 pasos y 2–3 desconchones de 2–4 px.
2. Sustituir la joroba por una pieza asimétrica de perfil anguloso que rompa la silueta (por ejemplo, un bloque quebrado), para que la silueta a 32 px sea única.
3. Agrandar la cabeza hasta unos 24 px de ancho o hundirla entre los hombros con un rasgo de frente reconocible. Añadir un segundo brazo visible y un puño facetado en lugar de la espiral (x12–23, y62–77).
4. Convertir el emisivo en una grieta irregular que siga las juntas, con roca a ≤ 2 px en +2 pasos de rebote y 1 px de halo al paso −2. Sin rectángulos. En telegrafía, ensanchar la grieta en vez de encender una placa.
5. Muerte de 6–8 fotogramas: la grieta se extiende, los bloques se separan, caen y quedan como escombro reconocible. Eliminar el giro de la bola entera.
6. Colocar el sprite con 6 px de margen en cada lado, o ampliar la celda 20 px de ancho, para que brazo y papel no se recorten. Ajustar el alto de 75 px a su familia (medio ≤ 72, élite ≥ 80).

## `criatura_3`: urraca con brasa

**Lo que funciona.** Es la mejor criatura de la prueba. Se reconoce como ave en negro a 32 px. El contraste entre pecho claro y plumaje
oscuro, las iridiscencias azules del ala y la cola, el ojo amarillo y la brasa del buche dan una personalidad inmediata con pocos
elementos. El picotazo de F3C3 es la mejor pose de las tres hojas.

**Lo que falla.**
- **Cabeza como gorro.** La cabeza (x20–37, y21–33) parece una pieza encajada sobre el pecho, sin cuello.
- **Cola y ala rígidas.** En la telegrafía y el gesto se leen como dos palos que salen del cuerpo, y la cola se ve despegada en su base.
- **Recorte grave.** En F4C4 falta la cabeza por salirse de la celda por arriba, y la cola toca el borde derecho. El desplazamiento lateral de F4C2–C4 no está contenido.
- **Pecho liso.** La masa blanca está muy poco trabajada, sin plumas; se acerca al aspecto de elipse.
- **Tamaño.** Con unos 39 px de alto queda entre pequeño (≤ 36) y medio (≥ 48) según §8.

**Correcciones para llegar a 9.**
1. Corregir el encuadre de F4C2–C4: recentrar o ampliar la celda 12 px arriba y 12 a la derecha, para recuperar la cabeza de F4C4.
2. Fundir cabeza y pecho con un collar de 2–3 px de plumaje oscuro bajando sobre el blanco, en borde dentado irregular. Inclinar la cabeza 1 px en los fotogramas de reposo como rasgo vivo.
3. Unir la cola al cuerpo con 2 plumas cortas de transición, y abrir su extremo en dos o tres puntas en lugar del remate romo.
4. Abanicar el ala en telegrafía: 3 plumas primarias separadas por muescas de 1 px, en lugar de una sola pala.
5. Pecho: 2 o 3 grupos de plumas de 2 px en el paso inferior del blanco, sin ruido. Añadir 1 px de halo cálido a la brasa sobre el plumaje.
6. Muerte: rematarla con plumas que caen y brasa que se apaga por pasos, en vez de un simple vuelco en F6C5–C6. Fijar la familia y ajustar a ≤ 36 o ≥ 48 px.

## `ilustraciones_1`: 12 viñetas de forja

**Lo que funciona.** La hoja es coherente: ladrillo, hierro, madera y fuego se distinguen con claridad, la luz cálida está motivada, y a 34×23 la mayoría
aún se reconoce. F1C4 (arco de fuego), F3C2 (fuelle), F3C3 (brasero) y F3C4 (horno) son nivel de producción.

**Lo que falla.**
- **Colores.** Medidos por viñeta (muestreo a la rejilla ×4; admiten un margen de ±2):

| | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| F1 | 36 | 34 | 31 | 16 |
| F2 | 32 | 14 | 27 | 22 |
| F3 | 35 | 33 | 20 | 32 |

  Límite de §9: 12. Ninguna lo cumple.
- **Objeto aislado.** F1C2 (escudo), F1C3 (troncos) y F2C4 (muro de placas) son más icono que momento. F2C4, además, no tiene luz clave.
- **Lectura ambigua.** En F2C1 la cabeza del martillo parece una olla. En F2C3 la herramienta no se identifica. En F2C2 los bultos del suelo son ilegibles a 34×23.
- **Vapor.** Los pompones de F3C1 parecen lana o coliflor, con el borde tramado (§6 prohíbe el tramado de textura).
- **Fondo.** Los fondos azules de F1C2 y F2C2 parecen llevar tramado de relleno, a confirmar con la prueba de arte.

**Correcciones para llegar a 9.**
1. Reducir toda la hoja a ≤ 12 colores por viñeta, fundiendo pasos vecinos de ladrillo y fuego. Es lo más urgente, porque por sí solo impide la aceptación.
2. F1C3: fuego real en el extremo derecho (x45–62, y8–38) con los troncos prendiendo y una mano o unas tenazas que añaden uno. La llama actual es un adorno.
3. F2C4: abrir la junta central (x23–43, y22–26) con brillo emisivo que sea la luz clave, proyectar sus reflejos sobre los remaches, y añadir la mano que coloca la placa.
4. F1C2: mostrar el impacto (abolladura en el centro, chispas saliendo en abanico, escudo inclinado por el golpe) y romper la simetría frontal.
5. F2C1: estrechar la cabeza a unos 16 px de ancho, con caras achatadas y cuña visible, y añadir chispas en el punto de impacto.
6. F2C2: subir los personajes a ≥ 10 px de alto y quitar la mitad de las líneas de chispas. F2C3: redibujar la herramienta con perfil inequívoco.
7. F3C1: redibujar el vapor en 3 masas planas con borde limpio y 2 valores, sin tramado.

## `ilustraciones_2`: 3 viñetas con miniaturas

**Por debajo de `ilustraciones_1`.** La mejor viñeta aguanta, pero las otras dos suspenden la prueba de miniatura o la lectura del sujeto.
Colores medidos: 36, 34 y 27 (límite: 12).

- **C1, heroína con cartas y anillos de fuego: 5.** La más débil. Fuego, cartas y suelo compiten en el mismo valor, la figura no tiene cara y la falda es un triángulo plano. A 34×23 es ruido naranja. La línea discontinua inferior parece un elemento de interfaz.
- **C2, interior con ventana y chispas: 6.** El objeto de arriba a la izquierda, cortado por el encuadre, no se identifica, y la perspectiva del suelo no converge con la ventana. La columna de chispas es lo mejor, pero se dispersa.
- **C3, torre piramidal de noche: 8.** Silueta potente, contraste frío y cálido excelente, y se lee perfectamente a 34×23. Sólo le falta un segundo plano y romper su simetría.

**Correcciones para llegar a 9.**
1. Reducir las tres a ≤ 12 colores.
2. C1: pasar de 5 cartas a 3, dejar el fuego en un único arco detrás de la figura a un valor inferior, oscurecer el fondo para separarla, y sellar una cara con ojo y nariz. Falda con pliegues verticales. Eliminar la línea inferior.
3. C2: sacar por completo el objeto de la esquina (x9–24, y1–14) o redibujarlo entero y reconocible. Hacer converger las juntas del suelo en un punto bajo la ventana. Agrupar las chispas en 10–12 grupos de ≥ 2 px, densos arriba y dispersos abajo.
4. C3: añadir un plano lejano de cresta o murallas al fondo, y humo asimétrico o una grieta en un costado. Quitar el tramado del cielo si lo confirma la prueba de arte.

## No comprobado

Paleta cerrada contra `Palette`, tramado medido, criterio de 10 evaluadores, tiempos de animación y comportamiento en juego. No conozco
la familia ni el acto de cada criatura, así que las observaciones de tamaño y de material del acto son condicionales. La prueba de
silueta a 32 px y la miniatura de `ilustraciones_1` son mías, por muestreo sin suavizado del reposo y de la hoja.

## Correspondencia (añadida por dirección tras el dictamen)
| Hoja | Origen | Modelo |
|---|---|---|
| `criatura_1` | `hollow_knight` | Opus |
| `criatura_2` | `ash_glutton` | Sonnet |
| `criatura_3` | `ember_magpie` | Opus |
| `ilustraciones_1` | 12 de la fase 1 | Opus |
| `ilustraciones_2` | `pyre_dance`, `open_flue`, `kiln` | Sonnet |

Muestra pequeña: una criatura y tres ilustraciones. Conclusión: el arte sigue en Opus. `ash_glutton` y las tres ilustraciones quedan para rehacer en la fase 3.
