# EMBERSPIRE v0.4: propuesta del Director de Arte

> Rol: dirección de arte (visión de conjunto). Documento de posición para el debate con los 4 expertos.
> Prueba de concepto: `tests/_review_art/v04/director/mockup.gd` + `mockup.tscn` → `keyframe_hot_1280.png`,
> `keyframe_cold_1280.png` (y sus nativos `*_640.png` y recortes `crop_*.png` ×4).
> Para regenerarlos: `"$GODOT" --headless --path . res://tests/_review_art/v04/director/mockup.tscn` (≈60 s; después, `git checkout project.godot`).

---

## 0. Tesis en cinco líneas

1. **El problema no es de pulido, es de resolución y de luz.** A 320×180 la heroína tiene 24×36 px. Ahí no cabe una cara, una mano ni un material. Cualquier mejora sobre esa rejilla se queda en "indie correcto". **Subimos a 640×360 ×2 y usamos una sola rejilla para el mundo y la interfaz.**
2. **La Forja es el sol del juego.** Toda la iluminación del mundo sale de dos fuentes: el calor de la Forja (ámbar, detrás de la heroína, "casa") y el frío de la Torre (azul pizarra, delante, "lo desconocido"). Si una pantalla no tiene claras esas dos luces, no está terminada.
3. **El estado del juego se ve.** El calor, la producción, el acto, el ciclo, el Resplandor y la Maestría no se leen en un número: cambian la luz, el fuego, el pelo de la heroína, el marco de las cartas y el humo de los monstruos.
4. **Producción por código, pero sin aspecto de código.** Nada de "icono EPX sobre degradado". Los personajes se componen por partes con normales y se cuantizan a rampas cerradas. Las rocas se tallan por facetas. Después hay una pasada a mano obligatoria en ojos, manos y hebillas.
5. **Menos cosas, mejor hechas.** Proponemos 30 ilustraciones de carta de calidad 9 antes que 90 de calidad 5. El resto se resuelve con variantes de familia (§4.4).

---

## 1. Crítica dura del estado actual

Escala: 10 = podría salir en el tráiler de Dead Cells o Blasphemous; 7 = indie comercial competente; 5 = prototipo cuidado; 3 = placeholder.

### 1.1 Pantalla por pantalla

| Pantalla (captura) | Nota | Qué hay | Qué la separa de un 9 |
|---|---|---|---|
| **Título** (`01_title`) | **4** | Logo pixel decente, heroína ×4 pequeña a la izquierda, forja a la derecha y botones de sistema marrones en el centro del arco | No hay composición. El logo flota sobre un muro genérico, los botones son rectángulos de Godot y la heroína ocupa un 3 % del encuadre. Un 9 sería un plano general de la Torre al anochecer con la Forja encendida al pie, la heroína de espaldas mirando hacia arriba y el logo forjado en metal con brillo de calor. Y que el estado de la partida guardada cambie el plano: cuanto más calor, más ventanas de la Torre encendidas. |
| **Forja** (`02_forge`) | **3** | Es una hoja de cálculo: tres columnas de paneles planos, con la forja (un bulto marrón granulado) a 1/4 de la pantalla. Además, un modal de texto la tapa | El "juego idle" no tiene escena. Un 9 es un **taller vivo**: la Forja grande en el centro, los generadores como objetos físicos (chispas, fuelle, alto horno) que aparecen en la sala al comprarlos y la heroína trabajando. Los números van en placas de hierro. El tutorial no puede ser un modal centrado sobre todo. |
| **Antesala** (`05_antesala`) | **3** | Tres paneles con borde naranja de 1 px y un retrato de la heroína a otra escala (×3 sobre UI ×2) | Mezcla de escalas. Los botones de Resonancia son rectángulos violetas de sistema y los Pactos, una lista de filas iguales. Un 9 sería un **altar o umbral de la Torre**: los pactos como sellos de cera o cadenas que la heroína se pone, y el Calor como un brasero que crece en escena. |
| **Mapa** (`06_map`) | **2** | Una columna de "Piso N" con iconos de vela, dos tarjetas de puerta con una espada sin fondo y la heroína a escala ×1 en la base | No hay mapa. Es lo peor del juego. Un 9 sería una **sección vertical de la Torre** con parallax: escaleras, puertas reales dibujadas (la API `door_art` existe y no se usa), la heroína subiendo y la Forja visible abajo como un punto de luz cada vez más lejano. |
| **Combate** (`07`, `14`, `16`, `17`, `18`) | **5** | La mejor pantalla: el fondo tiene arco, estandartes, antorchas, horno animado y luz lateral | Se lee bien y está desierta. Los personajes son diminutos (heroína al 20 % del alto y monstruos de 12–26 px). El fondo es **la misma sala** en tres colores. El suelo es una cuadrícula vacía. La interfaz (barra superior, textos de ayuda en el cielo, barras de PV de Godot) aplasta el mundo. Tampoco hay luz con dirección: los monstruos tienen un "borde naranja" pegado, no una iluminación. |
| **Cartas** (`23_cards`, `13_rewards`) | **5** | Marcos con forma de ventana por tipo, pergamino legible y gema de rareza | Las ilustraciones son **un icono de 12 px ampliado con EPX sobre un degradado de bandas**: en todas, el mismo truco. La espada, el escudo y la llama se repiten en 30 cartas. El marco es un rectángulo de color plano con bisel de 1 px, sin material. La tipografía del nombre se corta ("mbestida Blindada"). Un 9 tiene una **escena por carta** con su propia luz, profundidad y gesto, y un marco de metal forjado que cambia con la Maestría. |
| **Evento** (`21_event_forge_spirit`) | **2** | Un modal violeta con un icono de horno de 9×9 a ×8 y texto | El evento "Espíritu de la Forja" ("una figura de humo con tu misma cara") no tiene imagen de esa figura. Es la pantalla con más potencial narrativo y la más pobre. Un 9 sería una **viñeta ilustrada de 240×120** (el 37 % del ancho) con el personaje del evento, iluminación propia y texto sobre papel. |
| **Tienda** (`19_shop`) | **4** | Cinco cartas en fila y tres paneles de servicio | No hay tendero. El "Yunque Errante" debería ser un **personaje**: un herrero ambulante con su carro, en escena. Las cartas en venta irían colgadas o apoyadas en el carro y los precios en etiquetas de cuero. |
| **Hoguera** (`20_rest`) | **5** | Hoguera animada bonita y heroína ×4 de pie | Tres paneles marrones idénticos tapan el suelo. La heroína no se sienta ni descansa. Falta luz: la hoguera debería iluminar la sala (ahora es un sprite sobre un fondo que no se entera). Un 9 sería la heroína sentada, la luz de la hoguera como fuente única y las opciones como objetos (cama de paja, yunque, la propia hoguera). |
| **Resumen** (`22_summary`) | **3** | Lista de estadísticas con iconos y partículas que tapan el texto | Sin emoción ni escena. Un 9 sería la heroína **volviendo a la Forja** derrotada pero con las ascuas que trajo, y los braseros encendiéndose uno a uno en la sala (los "18 braseros nuevos" deberían **verse**). |

### 1.2 Por familia de asset

| Familia | Nota | Diagnóstico | Qué la separa de un 9 |
|---|---|---|---|
| **Heroína** (`new_hero_poses`) | **4** | 24×36, 3,6 cabezas, ojo de 1 px y brazo pegado. Es legible, pero es un personaje de juego móvil | No hay rostro, manos ni material: el delantal es un bloque marrón. Hacen falta 60–68 px, 4,5 cabezas, materiales distintos (piel, lino, cuero, lana, hierro) y un rasgo de diseño propio: **las puntas del pelo arden como brasas y se apagan con la Forja**. |
| **Monstruos** (`new_monsters_b0..2`) | **3** | Todos comparten la misma textura granulada, el mismo marrón o violeta y el mismo "borde naranja" | Son siluetas de ASCII rellenas con ruido. No tienen material (¿roca? ¿carne? ¿cera?) ni anatomía, y casi todos son un óvalo con patas. La familia del acto 1 tiene que ser **hollín, ladrillo y ascua**, la del acto 2 **escoria, vidrio y metal fundido**, y la del acto 3 **hielo, ceniza y hueso**, no la misma forma con otra rampa. |
| **Jefes** | **3** | El Rey es un gólem con corona, la Reina es un vestido, el Rey Escarcha es la Reina recoloreada y la Hidra es una masa violeta con tramado de 50 % | Recolorear jefes está prohibido por nuestra propia biblia y se hace. Un jefe necesita entre 120 y 160 px de alto, una silueta única reconocible a 32 px, una pieza emisiva propia y escenografía (que el fondo cambie). |
| **Fondos** (`new_bg_*`) | **4** | Una sola habitación (muro de ladrillo, arco central, dos ventanas, estandartes) con tres paletas | No hay profundidad: el suelo es una retícula vacía. No hay primer plano con peso ni luz que pinte. Un 9 tiene **tres planos de profundidad** (fondo, medio, cercano), al menos 4 salas por acto y luz por fuentes. |
| **Marcos de carta** (`new_cards`) | **5** | La forma por tipo es buena idea y el pergamino se lee | El metal no parece metal (rojo plano con bisel), no hay ornamento ni remaches, y la Maestría son tres puntitos. |
| **Ilustraciones de carta** (`card_arts`) | **4** | Icono EPX centrado más degradado, en las 90 | Es la familia que más daña la percepción de calidad: el jugador las ve 500 veces por partida. |
| **Iconos** | **5** | Legibles a 12×12 | Aceptables. Les falta coherencia de luz (cada uno se ilumina distinto) y un contorno con sel-out. |
| **Paneles y menús** | **2** | `StyleBoxFlat` de Godot con borde naranja de 2 px, botones marrones y textos con fuente lisa | Es lo que más grita "prototipo". No hay ni un 9-slice dibujado. |
| **Mapa** | **2** | No existe como arte | Véase 1.1. |
| **Forja** (`new_misc`) | **5** | Cúpula radial con boca encendida, bonita a ×4 | Es pequeña (64×56) y no tiene estados visibles más allá de la llama. Tiene que ser el objeto más trabajado del juego: estados por calor, generadores acoplados y humo. |

**Nota global: 3,5/10.** Coherente y limpio (la v0.3 arregló las escalas), pero sin detalle, sin luz y sin vida.

---

## 2. Dirección visual v0.4

### 2.1 Pilares (5)

1. **"Calor detrás, frío delante".** La luz cálida viene siempre del lado de la Forja (izquierda en combate, abajo en el mapa, centro en el taller) y la fría, de la Torre (derecha, arriba). Todo personaje lleva las dos: luz principal cálida y contorno frío, o al revés. *Referentes: Blasphemous (luz de vela contra noche), Eastward (dos temperaturas por escena).*
2. **La luz es el recurso.** Todo lo que vale (Ascuas, cartas mejoradas, puntos débiles) **emite**. Lo que no emite vive entre el 5 y el 45 % de luminancia. Si todo brilla, nada brilla.
3. **Materia antes que forma.** Cada píxel pertenece a un material con su rampa y su manera de reflejar: piedra mate, metal especular, cuero satinado, tela con pliegues, fuego emisivo, hielo translúcido, escoria vítrea. *Referentes: Children of Morta (materiales táctiles), Dead Cells (metal y piedra a gran tamaño).*
4. **El mundo responde.** Cada sistema del juego tiene una manifestación visual en todas las pantallas (§3). Lo idle se ve y no se lee.
5. **Silueta primero, detalle después.** A 32 px de alto (miniatura del mapa) cada enemigo y jefe se reconoce sólo por su silueta en negro. El detalle se añade dentro, nunca en el borde.

### 2.2 Resolución del mundo: **640×360 ×2, rejilla única**

| Opción | Píxel en pantalla | Heroína (alto) | ¿Escala entera a 1080p / 1440p / 4K? | Coste por sprite | Veredicto |
|---|---|---|---|---|---|
| 320×180 ×4 (actual) | 4×4 | 36 px (no caben cara, manos ni materiales) | Sí (×6, ×8, ×12) | 1× | Techo de calidad demasiado bajo. **Descartada.** |
| 427×240 ×3 | 3×3 | 48 px | **No**: 1280/3 = 426,67 → píxeles desiguales o bandas negras, y 1920/427 no es entero | 1,8× | **Descartada** por aritmética, no por gusto. |
| 480×270 ×(8/3) | — | 54 px | No a 720p (×2,67) | 2,25× | Descartada a 1280×720 por la misma razón. |
| **640×360 ×2** | **2×2** | **64 px** | **Sí** (×3 a 1080p, ×4 a 1440p, ×6 a 4K) | **4×** | **Elegida.** |

Argumentos:
- **Detalle real:** 64 px de heroína dan una cabeza de 14 px (ojo de 1×2 con brillo, ceja, nariz que rompe la silueta, boca), manos de 6 px que agarran y un delantal con bolsillo y quemaduras. Con 36 px, no.
- **El mismo tamaño en pantalla.** La heroína ocupa en pantalla lo mismo que ahora (128 px de 720), pero con **4 veces más píxeles**. No se pierde espacio de interfaz: se gana resolución de dibujo.
- **Una sola rejilla.** Las cartas (75×105 ×2), la fuente y los iconos ya viven a ×2, así que el mundo pasa a vivir en la misma rejilla y **desaparece por completo la mezcla de tamaños de píxel** (el error número 1 de la v0.2 y la v0.3). La regla "mundo ×4 / interfaz ×2" se sustituye por "**todo ×2; el arte se dibuja a 640×360**".
- **Riesgo asumido:** el píxel de 2×2 se ve "menos retro". Lo compensamos con agrupaciones limpias (§2.6) y contorno. Es la estética de Blasphemous (640×360) o Children of Morta, no la de una Game Boy.

Tamaños objetivo (alto, en px de arte):

| Pieza | Actual | v0.4 |
|---|---|---|
| Heroína | 36 | **64** (lienzo de pose 128×96) |
| Monstruo pequeño (ácaro, murciélago) | 12–16 | **24–36** |
| Monstruo medio | 20–26 | **48–72** |
| Élite | ×2 EPX | **80–100**, redibujado (no ampliado) |
| Jefe | 60–72 | **120–170** (pueden salirse del encuadre por arriba) |
| Forja (combate) | 36×34 | **104×84** más chimenea |
| Forja (taller) | 64×56 | **200×180** |
| Carta | 75×105 | 75×105 (no cambia), ventana de ilustración **65×38** |
| Icono | 12×12 | 12×12 (UI) y **16×16** para relicarios |

### 2.3 Paleta maestra (52 colores en rampas cerradas)

Ninguna rampa usa negro puro: el tono más oscuro de todo el juego es `#0b080e` (violeta casi negro). Todas tienen **desplazamiento de tono**: las sombras van hacia violeta o azul y las luces hacia ámbar (cálidas) o cian (frías). Las rampas compartidas tienen el mismo índice 0 para que el cambio entre la parte cálida y la fría no deje costura.

| Rampa | Hex (oscuro → claro) | Uso |
|---|---|---|
| Piedra cálida | `0b080e 140e16 1e141e 2b1a26 3b222c 522c30 6e3a32 965034 c26e3c` | Muros y suelos bañados por la Forja |
| Piedra fría | `0b080e 120f1a 191826 222334 2c3044 384058 48546e 5c6c86 7a8ca4` | Los mismos muros bañados por la Torre |
| Ladrillo de horno | `0e090c 1c0f14 2e1418 44191a 5e2420 7c3222 a04626 c8642e f08c42` | Forja, chimeneas |
| Fuego | `2a0a10 5a1216 92201a cc3c1c f26a22 ffa03a ffd468 fff6d4` | Todo lo emisivo cálido; Ascuas |
| Oro | `1a0e08 4a2c10 8a5a18 c8902a f0c050 fff0a0` | Emblemas, rareza, poder |
| Tela (estandarte) | `12070c 2a0c12 4a1218 6e1a1a 98281c c43e20 e8622c` / fría `1e0c18 2e1222 401a2e 52243a` | |
| Metal | cálido `0c0a10 1e1820 382a2c 5a4038 8a6048 c48a5c f0c08a` / frío `1a1a26 2c3040 465062 687a90 9cb0c4 d8e6f0` | Martillo, yunque, armaduras |
| Cielo y luna | `0c1020 121a32 1a2846 24385a 2e486c` · `5a7088 8aa4bc b8ccdc e4eef4` | Ventanas, acto 3 |
| Piel | `24101a 4e2026 844030 b86444 e09464 ffc890` / fría `3e2430 6a4650 9a7276 c8a4a0` | |
| Pelo (heroína) | `24080e 561216 92201a cc361c f4622a ffa24e` | Las puntas pasan a la rampa de Fuego |
| Lino | `1e161c 403032 6e5648 a4846a d6b892 fbe8c4` | |
| Cuero | `1a0e12 341a18 562c20 804428 ac6634 d88c48` | |
| Lana azul (bufanda) | `0c1224 182a48 284670 3e6c9a 6496bc 9cc4d8` | **El único azul saturado de la heroína**: el frío que lleva encima |
| Roca de hollín | `0a080c 151018 221822 32222a 462e32 623c38 8a523c b46e44` / fría `…343c54 48546e 62748e 8ca2ba` | Monstruos del acto 1 |
| Escoria (acto 2) | `0c0a0a 1a1612 2a2418 3e3a1e 5a5a22 86862a` + emisivo `3aa040 8ae048 d8ff70` | Vidrio volcánico verdoso |
| Hielo (acto 3) | `0a1020 142440 1e3c64 3070a0 5aa8d0 a0e0f0 eafcff` | |
| Pergamino y tinta | `4a3020 8a6a4a c4a47a dcc49a ecdab4 f8ecd0` · tinta `2a1418` | Cuerpo de las cartas |
| Sangre / PV | `2a0a10 5c1418 9a2018 d23a22 ff6a48` | |
| Debuff / magia | `1c0e2a 3a1a5a 6a3a9a 9a5ad0 d0a8ff` | |
| Curación | `0e2414 1e4a28 3a7a3a 6ac46a b0f0a0` | |

Están implementadas tal cual en `HEX` de `mockup.gd`. **Regla:** prohibido un color que no esté en una rampa. Una prueba automática recorre los PNG generados y falla si encuentra un color fuera de paleta.

### 2.4 Estructura de valores

| Capa | Luminancia | Contraste interno |
|---|---|---|
| Fondo lejano (corredor, cielo) | 5–35 % | Muy bajo (2–3 tonos) |
| Fondo medio (muro, pilares) | 5–45 % (hasta 60 % junto a la Forja) | Bajo |
| Suelo | 5–40 % | Bajo, con un reflejo especular de la Forja |
| Personajes | 8–90 % | Alto: tienen el contraste más fuerte de la escena |
| Emisivos (fuego, ojos, Ascuas) | 70–100 % | Pocos píxeles: el 100 % no debe superar el 1 % de la pantalla |
| Interfaz | Placas en el 5–20 %, texto en el 85–95 % | Ventana de lectura propia |

**Prueba de miniatura:** a 160×90 en escala de grises, la heroína, el enemigo y la Forja tienen que leerse como tres manchas separadas del fondo. El keyframe la pasa.

### 2.5 Dirección de la luz

- **Combate:** la Forja está en el borde izquierdo (x≈62, y≈228). Ilumina con caída escalonada. Su radio depende del calor (90 px + 210 × calor) y su intensidad también (0,18 + 1,0 × calor).
- **La Torre:** su luz fría entra por el fondo del arco (la cima) y por una ventana alta a la derecha, con un haz de luna con polvo. El enemigo queda **recortado por luz fría** (contorno a la derecha y arriba) y alumbrado por un cálido débil desde la izquierda.
- **Las antorchas son de la Forja:** su llama crece con el calor. La Forja alimenta la Torre, también visualmente.
- **Implementación:** un mapa de luz por píxel (dos canales, cálido y frío) que se calcula una vez por sala y estado. El fondo se sombrea por ladrillo (tono plano por pieza y canto iluminado), no por píxel, para que se lea como dibujado a mano. Los personajes usan el mismo vector de luz por normales. Nada de `PointLight2D`: la luz va **horneada en la paleta**, y en tiempo real sólo se añade un parpadeo de ±1 tono en las bandas.

### 2.6 Contorno, tramado y antialiasing

- **Contorno exterior:** 1 px. Por defecto `#0b080e`. **Sel-out:** donde el borde da a la Forja, el contorno toma el tono 1 de la rampa cálida (`#3a1214`) y el borde "arde" en vez de cortar. Donde da a la Torre, el último píxel interior pasa a contorno de luz fría (tonos 6 y 7 de la rampa fría).
- **Líneas interiores:** no se dibujan. Salen solas: la parte que queda detrás se oscurece 2 tonos donde otra la tapa (línea de contacto). Así lo hace el keyframe y así se mantiene la coherencia en 40 enemigos.
- **Tramado:** sólo como **costura de banda**, en el 22 % superior de cada escalón (patrón 2×2 de damero), en fondos y superficies grandes de más de 40 px. Prohibido en personajes de menos de 48 px, en el hielo (allí se usan bandas limpias) y como relleno o "textura".
- **Antialiasing manual:** sólo en curvas de más de 8 px de radio y en el borde interior (nunca en el contorno exterior contra el fondo). Va un tono intermedio en los escalones de 2:1 o más. Los emisivos llevan 1 px de halo con el tono −2 de su rampa.
- **Agrupaciones:** ninguna superficie de más de 6×6 px tiene píxeles sueltos de un tono distinto (sin "ruido"). Un detalle es una agrupación de 2 px o más, o un píxel colocado a propósito (ojo, remache, brillo).

### 2.7 Materiales (cómo se pinta cada uno)

| Material | Rampa | Regla de luz | Detalle característico |
|---|---|---|---|
| **Piedra / ladrillo** | Piedra cálida o fría | Tono plano por pieza y canto superior izquierdo +1 | Llagas de 1 px (−3 tonos), desconchones de 2–4 px y hollín que oscurece hacia arriba |
| **Metal** | Metal cálido y frío | Especular: brillo de 1–2 px en el tono máximo pegado al tono 2 (contraste duro, sin pasos intermedios) | Remaches de 1 px con brillo arriba a la izquierda y sombra abajo a la derecha; el filo refleja la Forja |
| **Tela** | Tela, lino o lana | Pliegues como bandas verticales (sinusoide de periodo 7 px) | Borde inferior con 1 px más oscuro; los estandartes se cortan en cola de golondrina |
| **Piel** | Piel | Suave: 3 tonos en la cara y el tono máximo sólo en la frente o el pómulo del lado de la luz | Rubor de 1 px; la nariz rompe la silueta |
| **Cuero** | Cuero | Satinado: 4 tonos y brillo de 1 px en los pliegues | Costuras de 1 px cada 3, quemaduras como manchas de 2 px con tono 0 |
| **Fuego** | Fuego | Emisivo (no se ilumina): núcleo de tono 7 abajo y lenguas hacia el tono 3 | 4–6 fotogramas; las lenguas suben 1 px por fotograma y nunca hay dos fotogramas iguales seguidos |
| **Hielo** | Hielo | Translúcido: el interior lleva un tono MÁS claro que el borde de sombra; facetas planas | Grieta interior blanca de 1 px; sin tramado |
| **Escoria** | Escoria y su emisivo verde | Vítrea: facetas como la roca, con brillo especular de 1 px | Burbujas de 1 px emisivas y regueros que gotean (animados) |
| **Roca con magma** | Roca de hollín y fuego | **Facetas Voronoi** (normal constante por celda), el contorno frío y las juntas emisivas | La roca a 1–2 px de una grieta sube 2 tonos (rebote de la luz) |

---

## 3. Mundo interconectado: el estado del juego, visible en todas las pantallas

**Regla:** cada variable del meta-juego tiene **una firma visual única** que se repite en todas las pantallas donde tenga sentido, y siempre con el mismo lenguaje. Al jugador nunca se le explica: se le muestra.

| Estado | Firma visual | Taller (Forja) | Antesala y mapa | Combate | Cartas | Evento, tienda, hoguera | Resumen y título |
|---|---|---|---|---|---|---|---|
| **Calor de la Forja** (producción/s) | Radio e intensidad de la luz cálida; altura de la llama; **puntas del pelo** de la heroína; martillo al rojo | Toda la sala | La Forja como faro al pie de la Torre: su luz sube por las escaleras hasta el piso N (cuanto más calor, más alto llega) | Radio de luz (90–300 px), antorchas, brasas en el aire (10 → 56), reflejo en el suelo. **Hecho en el keyframe** (`hot` / `cold`) | Las cartas de combustible "humean" más | La hoguera toma el color de la Forja | En el título, ventanas encendidas de la Torre = log₁₀(producción) |
| **Generadores comprados** | Objetos físicos en el taller | Chispa = farolillos, Fuelle = fuelle animado, Alto Horno = segunda chimenea, etc. Cada umbral de 10, 50 y 100 cambia el objeto (3 estados) | Los Braseros de la Torre se encienden en los pisos ya superados | La chimenea del fondo de combate echa más o menos humo | — | — | Braseros que se encienden uno a uno |
| **Acto (Hollín, Escoria, Ceniza)** | Material del mundo y temperatura de la luz fría | Ventana del taller hacia la Torre con el acto actual | Cambio de material de la escalera | Sala, enemigos y partículas (ceniza, goteo de escoria, nieve) | Fondo de ilustración teñido por acto (un tono, nunca un recoloreado completo) | El tendero y el evento llevan ropa del acto | — |
| **Ciclo de la Torre (I, II, III…)** | **Grietas y corrupción:** cada ciclo añade grietas emisivas a los muros y un afijo visible a los enemigos (los "Ignífugos" llevan placas de escoria, los "Avaros", bolsas de Ascuas) | Una grieta en el suelo del taller que crece | El número del ciclo forjado en el dintel | Afijos dibujados como **capas de sprite**, no como iconos | Marco con "óxido" en el ciclo III+ | — | — |
| **Resplandor** (bonificación temporal) | Un halo dorado que respira (2 fotogramas, 800 ms) | Rayos dorados en la Forja | — | La luz cálida pasa de ámbar a oro mientras dura | — | — | En el título, un amanecer sobre la Torre mientras está activo |
| **Maestría de la carta** (0–3) | **El marco se calienta** | Las cartas maestras cuelgan en la pared del Archivo | — | — | Nivel 1: los remaches arden. Nivel 2: brasas incrustadas en el marco (**en el keyframe**: Tajo Ígneo). Nivel 3: el marco pasa a metal al rojo y la ilustración gana 1 fotograma animado | — | — |
| **PV de la heroína** | Postura y luz | — | — | Por debajo del 30 %: postura cansada (otro fotograma de reposo) y el pelo pierde el brillo | — | En la hoguera, sentada en vez de de pie | — |
| **Quemas disponibles** | **Rejillas de la Forja** (diegético) | — | — | Tres rejillas en el zócalo del horno, encendidas = disponibles (**en el keyframe**) | — | — | — |
| **Energía** | Crisol de metal fundido | — | — | El nivel del crisol baja al gastar (**en el keyframe**: crisol 3/3) | El orbe de coste es una gota del mismo metal | — | — |

**Ejemplo de hilo completo:** compras 10 Fuelles → en el taller aparece un segundo fuelle que bombea a 2 Hz → la Forja sube de calor → en la Antesala el faro llega un piso más alto → en combate las antorchas crecen 2 px y el pelo de la Fogonera brilla más → al morir, en el resumen el fuelle bombea los braseros recién encendidos. **Una compra, cinco pantallas.**

---

## 4. Guía de calidad por familia, con criterios de aceptación medibles

En todas las familias, el asset **no se acepta** si:
- (a) tiene un color fuera de paleta (prueba automática);
- (b) la miniatura en grises a 1/4 no separa la figura del fondo;
- (c) tiene píxeles sueltos de ruido en una superficie de más de 6×6;
- (d) usa escala no entera o rotación sobre arte en reposo;
- (e) no ha pasado la revisión a mano de ojos y manos (en personajes).

### 4.1 Heroína
- 64 px (±4) de alto y 4,5 cabezas. Cara de al menos 9×10 px de piel visible con ojo, ceja, nariz que rompe la silueta y boca.
- Al menos 6 materiales distinguibles: piel, pelo, lino, cuero, lana y hierro.
- **Animación** (en fotogramas, sin interpolar):

| Animación | Fotogramas | Tiempo |
|---|---|---|
| Reposo | 4 | 180 ms cada uno, con respiración de 1 px y ondulación de la bufanda |
| Martillazo | 6 | Carga 2 × 70, anticipación 40, estela 33, impacto 90, recuperación 2 × 60 |
| Quemar | 5 | — |
| Golpe recibido | 2 | — |
| Muerte | 6 | — |
| Victoria | 4 | — |
| Andar (mapa) | 6 | — |
| Sentada (hoguera) | 2 | — |
| Taller (martillar el yunque) | 6 | Bucle |

  Total: **unos 41 fotogramas**.
- Las puntas del pelo y la cara del martillo dependen del calor (tres niveles visibles).

### 4.2 Monstruos (40)
- **Silueta única** a 32 px: la prueba es que 10 personas distintas identifiquen el 90 % en una hoja de siluetas negras.
- Material del acto claramente legible (§2.7), **1 punto emisivo como mínimo** (ojos, núcleo o grietas) y contorno frío en el lado de la Torre.
- Fotogramas: reposo 4, ataque 4 (anticipación ≥ 160 ms), golpe recibido 2 y muerte, que es una disolución propia del material (la roca se desmorona en facetas, el hielo se quiebra, la escoria se funde), de 6 fotogramas.
- **Estructura de producción:** 12 cuerpos base por partes (cuadrúpedo, bípedo pesado, alado, reptante, flotante, enjambre…), cada uno en 3 materiales de acto y con piezas intercambiables (cabeza, brazos, cola, armadura de afijo). Así salen 40 únicos de verdad, no 40 recoloreados. Las **élites son una pieza de armadura o corona redibujada**, no un EPX.

### 4.3 Jefes (6)
- De 120 a 170 px y a mano (el sistema de partes sólo como base). Cada uno con una **mecánica visual de fase**: el Gran Fuelle se hincha y deshincha (3 estados), la Hidra pierde y regenera cabezas, el Rey Escarcha congela la mitad derecha del fondo.
- Entrada de 1,5 s (el fondo se oscurece, el jefe entra con su luz propia) y muerte de 2 s con 12 fotogramas.
- **Prohibido compartir base** entre dos jefes.

### 4.4 Cartas y sus 90 ilustraciones
- **Marco:** metal forjado 75×105 con 4 materiales por tipo (ataque: hierro al rojo; habilidad: acero pavonado azul; poder: latón y oro; combustible: hierro fundido negro con rejilla). Bisel de 2 px, remaches y una forma de ventana por tipo (ya existe y se mantiene). La Maestría, como en §3.
- **Ilustración:** 65×38 px. **Criterio de 9:** escena con (1) al menos 2 planos de profundidad, (2) una fuente de luz propia coherente con el pilar 1, (3) un gesto o momento (no un objeto aislado) y (4) como mucho 12 colores.
- **Estrategia de producción a 90 (posición firme):**
  - **Nivel A (30 cartas: inicio, raras y poderes):** escena única compuesta por código con las mismas primitivas del keyframe y una pasada a mano. Unas 2 h por carta.
  - **Nivel B (45 cartas):** una **familia de escenas** por verbo (golpear, bloquear, quemar, invocar fuego, robar, mejorar…), 10–12 plantillas parametrizadas por objeto, color de luz y encuadre. Cada carta se distingue por el objeto protagonista y el ángulo. Alrededor de 40 min por carta.
  - **Nivel C (15 estados y maldiciones):** una plantilla de "objeto en la oscuridad" con niebla. Unos 15 min.
  - Prohibido el "icono EPX ×2 centrado".
- Los textos largos siguen en fuente lisa a 1280 (11–13 px). Los nombres y las cifras van en la fuente pixel de la rejilla de 640. En el keyframe todo va en fuente pixel de 3×5 sólo por demostración: **para texto de reglas no vale** (decisión que compartiré con el experto de cartas/UI).

### 4.5 Fondos
- 3 planos (lejano a 0,5×, medio a 1×, cercano a 1,15× de parallax con el ratón y como mucho 3 px), **4 salas por acto** (12) y variantes por semilla (estandartes, cadenas, herramientas, roturas).
- Al menos 2 fuentes de luz por sala, una de ellas siempre la Forja o un brasero que dependa de ella.
- Al menos 3 elementos animados por sala y no más de 5 (pilar del ART_BIBLE: "no animar todo"): llama, polvo en el haz, estandarte (2 fotogramas a 600 ms), goteo, nieve.
- El suelo no es una cuadrícula vacía: lleva losas con perspectiva, reflejo de la Forja y suciedad junto a ella.

### 4.6 Iconos
- 12×12 de UI con la luz siempre arriba a la izquierda y cálida, sel-out y 4–5 tonos de su rampa. Los de relicario van a 16×16 y llevan un engarce de metal común.

### 4.7 Paneles y menús
- **Kit de 9-slice dibujado** sobre la rejilla de 640: placa de hierro remachada, pergamino, madera de taller y vidrio frío para la Torre. Esquinas de 6×6 con remache y borde biselado de 2 px (claro arriba a la izquierda, oscuro abajo a la derecha).
- Botones con 3 estados (reposo, encima, pulsado = baja 1 px y oscurece). Barras de PV como placas de hierro con llenado en rampa y remaches (**en el keyframe**).
- Criterio: **cero `StyleBoxFlat` visibles en el juego.**

### 4.8 Mapa
- Sección vertical de la Torre de 640×(360×3) con desplazamiento: muro exterior con el material del acto, ventanas, escaleras y puertas reales (`door_art` a 40×56) con luz del destino.
- La heroína sube animada (6 fotogramas de andar más 4 de escalera). Abajo se ve siempre la luz de la Forja (§3).
- Al menos 2 eventos ambientales: pájaros o murciélagos, y nubes o nieve.

### 4.9 Forja
- En combate: 104×84 más chimenea hasta el borde (**en el keyframe**: cúpula en colmena con hiladas en perspectiva, dovelas al rojo, lecho de carbón, lenguas de fuego, zócalo con rejillas de Quemas y reflejo en el suelo).
- En el taller: 200×180, 4 estados de calor y 6 fotogramas de fuego por estado. El soplido del fuelle se sincroniza con el pico de producción por segundo.
- Al quemar una carta, la boca se aplasta 1 px y sube un tono, y salen chispas en la dirección de la carta.

---

## 5. Prueba de concepto: el keyframe

**Archivos:**
- `tests/_review_art/v04/director/mockup.gd` (≈1.800 líneas, GDScript tipado, sin dependencias del juego) y `mockup.tscn`.
- Salidas en la misma carpeta:
  - `keyframe_hot_640.png` y `keyframe_hot_1280.png`: Forja viva (calor 1,0).
  - `keyframe_cold_640.png` y `keyframe_cold_1280.png`: Forja moribunda (calor 0,15).
  - `crop_{hot,cold}_{hero,golem,forge,cards}.png`: recortes ×4 para revisar a nivel de píxel.

**Qué demuestra:**
1. **640×360 ×2 funciona a 1280×720** con mundo e interfaz en una sola rejilla: cartas, barras de PV, crisol de energía, botón y HUD comparten tamaño de píxel con el mundo.
2. **La luz por fuentes da el salto de calidad.** El mismo muro de ladrillo (`paint_wall`) se ve ámbar junto a la Forja y pizarra junto a la ventana, sin cambiar de asset. El corredor de arcos encadenados (perspectiva por escalado al punto de fuga) da profundidad real.
3. **Los personajes por partes con normales escalan a 40 enemigos.**
   - **Heroína:** 64 px, unas 22 primitivas y 7 materiales. El pelo arde en las puntas y el martillo está al rojo.
   - **Gólem:** 15 rocas facetadas con juntas de magma, núcleo, ojos, chimenea dorsal humeante, contorno frío y extremidades traseras en una rampa "lejana".
   - Sólo cambiar la lista de partes y la rampa da otra criatura con la misma calidad de luz.
4. **El estado se ve.** `heat` cambia el radio y la intensidad de la luz, las antorchas, la llama, el lecho de carbón, las brasas en el aire, el reflejo del suelo, el pelo, el martillo, las rejillas y el magma del gólem. Compara `keyframe_hot` con `keyframe_cold`: misma escena, otro mundo.
5. **Interfaz diegética:** Quemas en las rejillas de la Forja, energía en un crisol, PV en placas de hierro remachadas y Maestría como brasas en el marco (Tajo Ígneo, nivel 2).
6. **Las ilustraciones de carta ya no son iconos:** Golpe (yunque, martillo y estallido), Defensa (escudo que refleja la Forja en el lado izquierdo), Tajo Ígneo (arco de fuego), Carbón (facetas Voronoi con vetas, la misma técnica del gólem) y Fuego Interior (llama con rayos).

**Lo que todavía NO es un 9 (honestidad):**
- **La heroína** necesita una pasada a mano: la cara (el ojo se pierde a ×2), la mano delantera y la definición de las piernas. La técnica por partes llega a un 7; el 9 pide entre 30 y 60 min de píxel a mano por pose.
- **El gólem** todavía tiene demasiadas facetas medianas de valor parecido: le falta jerarquía (tres planos grandes de luz por roca, no cinco).
- **El suelo** está vacío en la zona de las cartas. Las cartas laterales tapan sus nombres (es lo esperado en un abanico, pero hay que ajustar el desplazamiento a 58–60).
- **Sin animación:** es un fotograma clave. La demostración de las 2–3 cosas vivas por pantalla corresponde al experto de mundo vivo/VFX.

---

## 6. Riesgos y descartes

### Riesgos
| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **Coste por 4 del píxel** en personajes y fondos | Alta | Alto | Producción por partes y facetas (keyframe); plantillas de escena para las cartas de nivel B y C; la pasada a mano se limita a cara y manos |
| Que `art.gd` (2.567 líneas) se convierta en un monolito de 10.000 | Alta | Medio | Dividirlo en `art/light.gd`, `art/parts.gd`, `art/rock.gd`, `art/cards/*.gd`, `art/bg/*.gd` y hornear PNG en caché (`user://art_cache/`) con hash de parámetros |
| Tiempo de generación (el keyframe tarda unos 60 s en GDScript) | Alta | Medio | Hornear al compilar (`tests/bake_art.tscn` → `res://art_baked/*.png` con importación sin filtro). En tiempo de ejecución sólo se carga. La luz por estado de calor se hornea en 4 niveles, no en continuo |
| La luz horneada choca con la interfaz y la animación | Media | Medio | Los personajes llevan el sombreado horneado para 4 niveles de calor × 3 actos; el parpadeo se resuelve con ±1 tono por paleta (shader de intercambio de índice, el único shader permitido) |
| Que se pierda legibilidad de juego por la belleza (fondos ricos tras las intenciones) | Media | Alto | Estructura de valores de §2.4 y prueba de miniatura en gris automatizada; intenciones y números siempre con contorno y por encima del 85 % de luminancia |
| Incoherencia entre 5 expertos | Alta | Alto | Este documento y el keyframe son la **referencia**. Cualquier asset nuevo se compone junto al keyframe antes de aceptarse |

### Lo que descarto, y por qué
- **427×240 ×3:** no es entera a 1280×720 (426,67). No hay debate posible.
- **Mantener 320×180:** el cliente pide "mucho más detalle" y 36 px no lo permiten.
- **`PointLight2D`, normal maps en tiempo real, bloom y CRT:** convierten el pixel art en "pixel art iluminado por motor", con gradientes fuera de paleta y halos borrosos. La luz se hornea en paleta.
- **Recolorear para crear contenido** (jefes, actos, élites): ya lo prohibíamos y se hizo igual. Ahora habrá una prueba automática que compare las siluetas.
- **90 ilustraciones únicas a mano:** imposible con calidad uniforme. Mejor 30 excelentes y 60 de familia muy buenas que 90 mediocres.
- **IA generativa o imágenes externas:** incoherentes con la rejilla y la paleta, además del riesgo legal. Todo sigue por código y en el repositorio.
- **Tramado de relleno:** sólo costuras de banda.
- **Rotación y escalado en tiempo real de sprites en reposo:** se mantiene la regla de la v0.3.

---

## 7. Estimación por paquetes independientes

En jornadas de un artista técnico senior trabajando por código. Los paquetes se pueden paralelizar salvo donde se indica la dependencia.

| # | Paquete | Depende de | Jornadas | Entrega verificable |
|---|---|---|---|---|
| P0 | **Rejilla 640×360**: cambio de `UI.PX` a 2, lienzo de mundo, horneado y caché de arte, prueba de paleta y de miniatura | — | 4 | Todas las pantallas compilan a la nueva rejilla (con el arte antiguo ampliado ×2 como provisional) |
| P1 | **Motor de luz y materiales** (`art/light.gd`, rampas de §2.3, `shade_at`, 4 niveles de calor × 3 actos) | P0 | 4 | El keyframe reproducido dentro del juego |
| P2 | **Sistema de partes** (`art/parts.gd`: cápsulas, elipses, polígonos, rocas facetadas, contorno selectivo, líneas de contacto) | P1 | 3 | Hoja de 12 cuerpos base |
| P3 | **Heroína** a 64 px con 41 fotogramas y pasada a mano | P2 | 8 | `hero_sheet.png` y aceptación según §4.1 |
| P4 | **Monstruos** (40): 12 bases × 3 materiales más piezas y afijos | P2 | 16 | Hojas por acto y prueba de siluetas |
| P5 | **Jefes** (6) a mano con fases | P2 | 15 | 6 hojas y vídeo de entrada |
| P6 | **Fondos**: 12 salas con 3 planos y animación ambiental | P1 | 12 | 12 salas a 2 niveles de calor |
| P7 | **Forja**: combate y taller, con estados, generadores físicos y quema | P1 | 6 | Taller animado |
| P8 | **Cartas**: marco por tipo y Maestría (2 j); ilustraciones de nivel A (30 × 2 h ≈ 8 j), B (45 × 40 min ≈ 4 j) y C (15 × 15 min ≈ 0,5 j) | P1 | 15 | Hoja de 90 cartas y aceptación según §4.4 |
| P9 | **Kit de interfaz** (9-slice, botones, barras, crisol, placas, iconos con sel-out) | P0 | 6 | Cero `StyleBoxFlat` |
| P10 | **Pantallas compuestas**: título, taller, antesala, mapa, evento (12 viñetas), tienda (tendero), hoguera, resumen | P3, P6, P7, P9 | 14 | 10 capturas que puntúen ≥ 8 en esta misma tabla |
| P11 | **Mundo interconectado**: conectar `heat`, el ciclo, el Resplandor y la Maestría a todas las pantallas (§3) | P1, P10 | 5 | Vídeo de "una compra, cinco pantallas" |
| P12 | **Pulido y prueba de dirección**: revisión cruzada con el keyframe | todo | 5 | Informe con nota por pantalla |
| | **Total** | | **≈113 jornadas** | Unas 23 semanas de una persona o 8–9 semanas de un equipo de 3 |

**Orden recomendado:** primero P0, P1 y P2 (11 j). Después, P3 + P6 + P7, que dan **una pantalla de combate del acto 1 a nivel 9** como *vertical slice* (≈26 j más). Si ese corte no convence al cliente, se para antes de invertir en las 90 cartas y los 40 monstruos.

---

## 8. Posiciones firmes para el debate

1. **640×360 ×2 con rejilla única.** No acepto 427×240 (aritmética) ni seguir en 320×180 (techo de calidad).
2. **La luz va horneada en paleta**, sin luces del motor. Sí acepto un único shader de intercambio de paleta para los parpadeos.
3. **La Forja es la única fuente cálida del mundo.** Las antorchas, braseros y hogueras son "de la Forja" y responden a su calor.
4. **Las cartas van por niveles A, B y C.** Prefiero 30 excelentes a 90 iguales.
5. **La interfaz es diegética donde se pueda** (Quemas, energía, PV, Maestría) y con placas de material donde no. Fuera `StyleBoxFlat`.
6. **Partes y facetas para producir, a mano para terminar.** Ningún personaje se acepta sin pasada a mano en cara y manos.
