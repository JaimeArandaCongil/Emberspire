# Panel de arte v0.4 — Personajes y criaturas

**Autor:** artista sénior de personajes y criaturas · **Área:** la Fogonera, 24 enemigos y 6 jefes.
**Prueba de concepto:** `tests/_review_art/v04/personajes/` (`rig.gd` + `poc.gd`, salida en `out/`).

> Mis posiciones, en corto:
> 1. **El mundo pasa a 640×360 nativos (×2).** A ×4 (320×180) no se llega a Blasphemous ni a Eastward: la heroína tiene 24×36 px y la cara mide 6 px. Con ×2 tenemos 4 veces más píxeles por personaje y el mismo tamaño en pantalla.
> 2. **El arte se construye por código en un lienzo de materiales, no de colores.** Las primitivas con normales dan el volumen y los sellos ASCII hechos a mano ponen la intención. Acepto el *rig renderer* del artista técnico **con siete condiciones** (§4.3), que no negocio.
> 3. **No se colorean cuerpos ya existentes.** Los 3 golems, los 3 caballeros, las 2 urracas y las 2 reinas idénticas son hoy el problema número uno del bestiario. Se pueden compartir esqueletos, pero la silueta de cada criatura tiene que ser distinta.
> 4. **Cada jefe es un decorado vivo:** entre 180 y 250 px de alto, 4–7 partes animadas por separado y una telegrafía que se lee con el cuerpo, no sólo con el icono.

---

## 1. Crítica de lo actual

Capturas usadas: `screenshots/07_combat.png`, `14_boss_summon.png`, `16_act2_hydra.png`, `17_act3.png`, `18_frost_king.png`.
Hojas usadas: `tests/_review_art/out/new_monsters_b0.png`, `new_hero_poses.png`.

### 1.1 La Fogonera (`SPRITES.player` 24×36 + `player_arm` 10×20)
- **Silueta:** se lee como una figura genérica con pañuelo. No tiene ningún elemento que sea suyo: el martillo de 7 px cuelga sin peso y queda debajo de la línea de las rodillas. Si la reduces a una mancha negra, podría ser cualquier aldeana de un RPG de 16 bits.
- **Lectura:** la cara ocupa 6×7 px y el ojo es 1 px. A ×4, en 1280×720, se ve una mancha rosa con un píxel oscuro. No transmite ni expresión ni edad.
- **Diseño:** nada dice «tu mazo es combustible». No lleva fuelle, ni tenazas, ni carbón, ni nada donde arda una carta, y no tiene tizne. Es una herrera de manual, no la fogonera de *esta* torre.
- **Anatomía:** el cuerpo es un bloque de 9 px de ancho sin cintura ni cadera, y las piernas tienen el mismo grosor de arriba abajo. En la pose `strike` el brazo, girado con RotSprite, sale de un hombro que no se mueve: es un muñeco de recortable, no un golpe (`new_hero_poses.png`, fotogramas 5–6).
- **Materiales:** el cuero, el pantalón y la piel están en la misma familia de marrones con contraste parecido, así que no hay lectura de materiales. El metal del martillo son 2 tonos planos.
- **Animación:** sólo se rota el brazo y el cuerpo se desplaza 1–2 px. No hay anticipación del torso, ni seguimiento del pelo o el pañuelo, ni carga en las piernas. La estela (`_draw_smear`) está bien resuelta, pero es lo único con fuerza.

### 1.2 Enemigos por familia (`BASES`/`SHAPES` + `_build_monster`)
El motor de sombreado (campo de distancia + luz cenital + luz de fuego lateral) es ingenioso, pero **todo sale del mismo material**. Cada monstruo es una masa `X` con la rampa del bioma y grietas `a`. Por eso un gólem de ladrillo, un caballero de armadura y un limo tienen la misma textura de «arcilla con pecas naranjas» (se ve en `new_monsters_b0.png`).

| Familia | Enemigos (forma actual) | Problema |
|---|---|---|
| Amorfos | Limo de Ceniza, Devorador de Ceniza (`slime`) | Dos enemigos con la misma media máscara de 10 px reflejada. El Devorador (44–48 PV, se cura al quemar) parece un limo grande. No tiene boca que coma ni barriga que crezca. |
| Alados | Murciélago Brasa (`bat`), Polilla de Llama y Polilla de Hielo (`moth`), Urraca Ígnea y Urraca Dorada (`bird`) | Murciélago y polilla son simétricos y frontales, como *space invaders* (`17_act3.png`: la Polilla de Hielo parece un fantasma con orejas). Las urracas, que roban Ascuas, no llevan botín visible. |
| Constructos | Gólem de Hollín, Guardián de Escoria, Titán Congelado (`golem`), Bruto del Fuelle, Fuelle Rival (`totem`) | **El caso más grave:** 3 enemigos con la misma base `golem` y 2 con `totem`. El gólem de `07_combat.png` es un humanoide gris de 24 px con grietas; no hay ladrillo, ni horno, ni hollín. |
| Humanoides | Caballero Hueco, Monje Glacial, Caballero de Escarcha (`knight`); Bruja de Humo, Espectro de Escarcha (`wraith`); Sacerdote de Ceniza (`priest`) | El caballero es un muñeco de 22 px con espada de 1 px de ancho. En `17_act3.png` el Caballero de Escarcha es una figura azul sin armadura legible. Un monje y dos caballeros comparten cuerpo. |
| Alimañas | Ácaro de Vela (`mite`), Reptante de Escoria (`crawler`), Diablillo de Azufre (`imp`), Sabueso de Escarcha (`hound`), Sierpe de Escoria (`serpent`) | Siluetas correctas pero diminutas (12–15 px de alto). El ácaro, ampliado con EPX, tiene bordes de «escalera doble». Nada indica que el ácaro *explota* al morir (`on_death dmg_p 5`). |
| Flotante | Ojo Fundido (`eye`) | Bien concebido (un iris enorme), pero sin párpado ni goteo: un huevo frito. |

**Defectos transversales**
1. **Escala:** monstruos normales de 12–26 px junto a una heroína de 36. Todos son *más pequeños* que ella, incluido el Gólem, que debería pesar el doble.
2. **Una sola luz y un solo material:** no hay especular en el metal, ni facetas en el carbón, ni translucidez en el hielo, ni humo que se disuelva.
3. **Afijos invisibles:** «Ignífugo», «Templado» y «Avaro» sólo cambian el nombre. Una criatura Templada debería verse templada.
4. **Animación de recortable:** las únicas poses son `crouch` y `stretch` (quitar o duplicar una fila) más la disolución. No hay telegrafía corporal: la intención va sólo en el icono de arriba.
5. **El ciclo** desplaza el tono 0,29 de la rueda (`biome_colors`) y produce monstruos verdes o fucsias aleatorios. Eso no es diseño, es ruido.

### 1.3 Jefes
- **El Carbonero, la Reina Escoria y el Rey Escarcha son el mismo dibujo:** corona de 3–4 puntas, cara redonda, vestido acampanado y bastón. `18_frost_king.png` lo deja claro: una figura acampanada azul con bastón y la boca sonriente de un muñeco de nieve. **No es un jefe final.**
- **El Gran Fuelle** (`14_boss_summon.png`) tiene la idea correcta (el cuerpo es el fuelle), pero parece un muñeco Michelin con calcetines.
- **La Hidra** (`16_act2_hydra.png`) es una masa morada con tramado, tres cuellos de 2 px y cabezas de 5 px. El tramado Bayer en violeta saturado es lo menos profesional del juego.
- **El Corazón Frío** es un icono de corazón ampliado.
- Todos ocupan 60–72 px nativos (≈ 260 px en pantalla). Eso es el 36 % del alto, cuando un jefe de Blasphemous llena el 70–90 %.

---

## 2. Objetivo visual y referentes

| Referente | Qué tomamos | Qué NO tomamos |
|---|---|---|
| **Blasphemous** | Jefes que son arquitectura; carne y tela con 5–6 tonos con desplazamiento de tono; contorno oscuro de color, no negro. | La paleta de sangre y sepia: la nuestra es fuego sobre hollín. |
| **Eastward** | Personajes con mucho carácter en 60–70 px, accesorios que cuentan la vida del personaje, cara expresiva con 2–3 px de ojo. | Las proporciones *chibi*. |
| **Owlboy** | Animación secundaria (pelo, telas, bolsas), sensación artesanal y cálida. | Su resolución altísima, que es inviable por código. |
| **Hyper Light Drifter** | Lectura de silueta a distancia; color plano con un acento de luz. | La ausencia de contorno: nosotros lo necesitamos para leer sobre fondos oscuros. |
| **Darkest Dungeon** | Diseño de criatura con un *concepto* (qué es, de qué está hecha, qué quiere) y un rasgo vivo en reposo. Telegrafía con el cuerpo. | El contorno grueso de tinta. |

**Regla de oro del bestiario:** cada criatura es *combustible o residuo de la torre*: hollín, escoria, ceniza, brasa, ladrillo de horno, hierro, vapor y escarcha. **Ninguna es «un monstruo con colores del acto»**. En reposo, cada una tiene un rasgo vivo propio: parpadeo, brasa que palpita, goteo, humo o respiración.

---

## 3. Biblia de personajes — la Fogonera

### 3.1 Concepto
Es la última fogonera de la Torre: la encargada de que el horno no se apague nunca. No es una guerrera; es una obrera del fuego que aprendió a pelear con lo que llevaba encima. **Todo lo que lleva sirve para alimentar un fuego.** Su mazo es literalmente combustible: las cartas se queman en el **fogón de cinto**, un farol de latón con rejilla que lleva en la cadera. Cuando quemas una carta en combate, ese farol se enciende (el estado `case_glow` de la prueba) y su luz conecta con la Forja grande.

### 3.2 Silueta y proporciones (resolución nativa 640×360)
- **Alto:** 66 px de los pies a la coronilla, más 6 px de moño (≈ 132 px en pantalla, como ahora). Lienzo de pose de 96×96, pies en y = 89.
- **4,4 cabezas** (cabeza de 15 px): robusta, de hombros anchos (22 px) y cadera estrecha (15 px). Peso hacia abajo, con botas grandes de 12 px.
- **Rasgos de silueta reconocibles en negro**, de arriba abajo: moño alto atado con un trapo; dos asas del **fuelle a la espalda** que asoman por encima del hombro; **martillo de mazo grande** (cabeza de 17×10 px, el doble que ahora); delantal acampanado hasta la rodilla. Prueba de silueta superada: `fogonera_sheet_x4.png` se identifica en negro.

### 3.3 Accesorios que cuentan «tu mazo es combustible»
| Accesorio | Lectura | Uso en juego |
|---|---|---|
| **Fogón de cinto** (farol de latón 5×5 con rejilla) | Donde arde la carta quemada | Se ilumina al quemar: tono 2 → 4 durante 300 ms. Su luz aditiva tiñe el delantal. |
| **Fuelle a la espalda** (pala de madera, cuero plisado, boquilla de latón) | «Le doy aire a mi fuego» | Animación de *Quemar en caliente*: el fuelle se comprime 2 px y sopla chispas por la boquilla. |
| **Martillo con cara al rojo** | El arma es una herramienta | La cara que golpea brilla siempre (emisiva). Con Fuerza brilla más. |
| **Antebrazos tiznados** con cicatrices de chispa | Años en el horno | Las cicatrices son píxeles emisivos que laten con la respiración. |
| **Saco de carbón** a la cadera, con trozos y una brasa | Reserva de combustible | Al robar cartas cae un trozo de carbón; al *Exiliar* se le escapa humo. |
| **Tenazas** colgando del cinto | Herramienta de forja | En la pose de `cast` (habilidades) saca las tenazas con una brasa: la «carta» que sostiene. |
| **Gafas de forja** en la frente | Ojos protegidos del calor | El cristal refleja el fuego del acto (naranja / verde ácido / azul). |
| **Bufanda azul** | Es el único frío de su paleta | Ancla de color: siempre se la encuentra en pantalla. Es tela secundaria con 2 fotogramas de retardo. |

### 3.4 Paleta (rampas en `poc.gd → RAMPS`)
Cinco tonos por material, con las sombras desplazadas hacia violeta y las luces hacia amarillo:
- **Piel** `4a1e2e 843c38 bc6648 e09868 f6c890`
- **Tizne** `1a1420 2c2230 44363f 62504c 84705e`
- **Pelo cobrizo** `2c0a1c 561424 862420 b23a22 e07034`
- **Lino** `3a3048 665a6c 9a8a88 ccbaa2 eedfc0`
- **Cuero** `1e121c 3a1e26 60342c 8a5236 b07646`
- **Lona** `16141e 2a2434 40384a 584c5e 726474`
- **Acero** `14141e 2a2c3e 4a4e66 7a8298 c8d0dc`
- **Latón** `34200e 64401a a06c22 d8a440 fae088`
- **Bufanda** `161e3a 243a62 36628e 5c96be a0d0e8`
- **Al rojo** (emisivo) `6a1414 b8281a f45a18 ffa834 fff0b8`

El contorno es de color por material, nunca negro. En los bordes iluminados (arriba e izquierda) se usa *sel-out*, lo que da un contorno más suave.

### 3.5 Animación (fotogramas a 640×360; tiempos en ms)
| Estado | Fotogramas | Notas |
|---|---|---|
| Reposo | 6 × 150 | Respiración de 1 px en el torso; el pelo y la bufanda siguen con 1 fotograma de retardo; el fogón y las cicatrices laten con el fotograma 3. |
| Martillazo | carga 3 (60/60/120 de pausa) → estela 1 (33) → impacto 2 (50 + *hitstop*) → recuperación 3 (90) | Prueba: `windup` y `strike`. En la carga el brazo pasa **por detrás** de la cabeza y el torso se echa atrás 2 px; en el impacto se adelanta 6 px y la pierna trasera se estira. |
| Habilidad (tenazas) | 5 | Saca las tenazas con una brasa; el fogón se aviva. |
| Quemar | 4 | Lanza la carta al fogón de cinto, el farol estalla y el fuelle sopla. |
| Golpe recibido | 2 + vuelta | Destello, retroceso de 3 px y el moño sigue el movimiento. |
| Muerte | 8 | Cae de rodillas, el martillo se apoya y el fogón se apaga (fotograma final sostenido). |
| Victoria | 4 en bucle | Martillo al hombro y la bufanda al viento. |

**Total de la heroína:** unos 38 fotogramas generados por el rig. Ningún fotograma rota un sprite en tiempo de ejecución.

### 3.6 Cómo cambia con la progresión (todo por capas del rig, sin redibujar)
| Sistema | Cambio visual |
|---|---|
| **Maestría** (cartas dominadas en total) | El delantal gana remaches y parches: 1 remache de latón por cada 10 cartas en Maestría 5. Con la maestría total, el martillo pasa de hierro a acero y luego a **acero negro con runa al rojo**: 3 cabezas de martillo distintas. |
| **Resonancias** (generadores de la Forja) | Cada generador con Resonancia añade un detalle: *Chispa* → brasas que orbitan el fogón; *Fuelle* → el fuelle de la espalda se hace de latón; *Horno* → brazal de ladrillo refractario; *Crisol* → un crisol colgado del cinto; *Alto Horno* → hombrera de hierro remachado; *Sol Enano* → el cristal de las gafas brilla en blanco; *Corazón del Mundo* → el fogón de cinto late como un corazón. El color de la brasa de las cicatrices sigue la Resonancia dominante. |
| **Mejoras de la Forja** | *Brazo Forjado* → guantelete de forja en el brazo del martillo (1/2/3 placas). *Piel Forjada* → el tizne de los brazos sube del antebrazo al hombro. *Núcleo Ígneo* → un punto de luz en el pecho bajo el delantal. |
| **Pactos** (Calor) | El hollín le sube por el cuello y la cara: de 0 a 8 de Calor, de 0 a 8 px de tizne. Con 5 o más de Calor, sus ojos brillan en naranja (emisivo). *Mazo Empapado* → el delantal gotea agua (1 gota por segundo). |
| **Ciclo** | El ciclo II chamusca el borde de la bufanda; el ciclo III le añade una capa corta de ceniza; con el ciclo IV o más, el moño se suelta y el pelo arde en las puntas. El ciclo **no** recolorea a la heroína al azar. |

---

## 4. Técnica de producción viable por código

### 4.1 Resolución nativa: 640×360 (×2). Por qué
- En 1280×720 es el único divisor entero que da detalle de pixel art profesional. **Es la resolución nativa de Blasphemous.**
- La heroína pasa de 36 a 66 px de alto con el mismo tamaño en pantalla: una cara de 15 px, un ojo de 2×2 con brillo, manos de 5 px.
- **Tamaños de clase:** pequeño 28–40 px · mediano 48–70 · grande/élite 80–110 · jefe 180–250 (alto) × hasta 320 (ancho).
- Esto obliga a los fondos a pasar también a 640×360 (**no se mezclan resoluciones**). Lo defenderé ante el director: mezclar ×2 y ×4 en el mundo es justo el *mixel* que delata a un aficionado. La interfaz sigue a ×2, con lo que **toda la pantalla queda en la misma rejilla**: una ventaja enorme.
- **Coste:** cuatro veces más píxeles por sprite. Por eso el arte **no** puede seguir siendo ASCII completo a mano (§4.2).

### 4.2 Pipeline: lienzo de materiales + rig de piezas + sellos a mano
Implementado en `tests/_review_art/v04/personajes/rig.gd` (≈ 330 líneas):
1. **Lienzo de MATERIALES.** Cada píxel guarda `material`, `luz` (0–1), `pieza` y `tono forzado`. **No se pinta color hasta el final**, y eso permite recolorear por acto, afijo o ciclo cambiando sólo la rampa.
2. **Primitivas con normal analítica:** `ellipse` (con aplanado `zb` y **facetas** de Voronoi para carbón, roca y hielo), `capsule` (miembros cónicos), `poly` (planos con bisel, para armaduras y herramientas). La luz es fija (fuego arriba a la izquierda) con un modelo *half-Lambert* cuantizado a 5 tonos.
3. **Sellos ASCII a mano** (`stamp`) con **tono forzado**: caras, ojos, manos, remaches, rejillas y bocas. **El render propone y el artista dispone:** el sello nunca pasa por la cuantización.
4. **Texturas por material** sobre los tonos calculados: ladrillo (sólo en luz media; en sombra desaparece, que es *detalle selectivo*), mechones de pelo, pliegues del fuelle, arañazos del cuero.
5. **Pases de limpieza:** (a) huérfanos: un píxel sin vecino 4-conexo del mismo tono se funde con la mayoría; (b) **líneas internas sólo entre piezas** (la pieza de atrás se oscurece donde toca a la de delante, y nunca alrededor de un sello); (c) contorno exterior de color con *sel-out* en el lado iluminado; (d) capa emisiva separada para el brillo aditivo.
6. **Rig de piezas:** cada pose es un diccionario de articulaciones (`POSE["idle" | "windup" | "strike"]`: hombro, codo, muñeca, cadera, rodilla, tobillo y cabeza). Un fotograma nuevo cuesta unos 12 números, no 2.000 caracteres ASCII.

### 4.3 Sobre el *rig renderer* del artista técnico: sí, con 7 condiciones
Mi prueba **es** un rig renderer de primitivas con normales, y funciona. Pero he visto en mis propias iteraciones dónde se rompe, así que exijo:
1. **Lienzo de materiales, no de colores**, con rampas a mano (5 tonos con desplazamiento de tono). Prohibido generar rampas por HSV: así salen los ciclos fucsia actuales.
2. **Sellos con tono forzado obligatorios** para caras, manos y detalles de 1–3 px. Sin ellos, la cara de la Fogonera salía como una mancha (1.ª iteración: el render no sabe dibujar un ojo).
3. **Nada de elipses lisas de más de 20 px sin aplanado o facetas.** En la primera versión del boceto del jefe, las esferas grandes producían **anillos concéntricos de vector**: el tell de «esto lo hizo un programa». Los volúmenes grandes se construyen con planos (bisel) o facetas.
4. **Las líneas internas, sólo entre piezas declaradas, y nunca alrededor de un sello.** En la 2.ª iteración, los rasgos de la cara quedaron rodeados de una línea oscura porque el sello contaba como pieza delantera. Ya está arreglado en `rig.gd`: los píxeles forzados no generan línea.
5. **Rotación sólo al hornear, nunca en pantalla**, y con rig de articulaciones (se recalculan las primitivas), no rotando bitmaps. Esto elimina RotSprite.
6. **Capa de parches por fotograma:** un diccionario `{pose: [sellos]}` para corregir a mano lo que el render resuelva mal (manos en escorzo, solapes). Si un fotograma necesita más de 15 píxeles de parche, se rediseña la pose.
7. **Horneado determinista y pruebas de imagen dorada.** El código es la fuente; un paso `bake` exporta atlas PNG (para QA, diffs y para no pagar el render en cada arranque). El render de un personaje de 96×96 tarda menos de 100 ms, pero 40 criaturas × 30 fotogramas sí se notan en el arranque.

### 4.4 Esqueletos compartidos (lo que hace viable la escala)
| Esqueleto | Articulaciones | Criaturas |
|---|---|---|
| **Bípedo humano** (el de la Fogonera) | 14 | Caballero Hueco, Monje Glacial, Caballero de Escarcha, Sacerdote de Ceniza, Bruja de Humo (sin piernas: falda de humo), Espectro de Escarcha, Diablillo |
| **Bípedo pesado** (gólem) | 12 + joroba | Gólem de Hollín, Guardián de Escoria, Titán Congelado, Bruto del Fuelle, Fuelle Rival |
| **Masa blanda** (contorno por *metaball* de 3–5 bolas) | 5 bolas + boca | Limo de Ceniza, Devorador de Ceniza, Ojo Fundido (con párpado) |
| **Alado** (cuerpo + 2 alas de 3 huesos) | 8 | Murciélago Brasa, Polilla de Llama, Polilla de Hielo, Urraca Ígnea, Urraca Dorada |
| **Segmentado** (cadena de N segmentos + patas) | N + 2N | Reptante de Escoria, Sierpe de Escoria, Ácaro de Vela |
| **Cuadrúpedo** | 16 | Sabueso de Escarcha |
| **Jefes** | únicos, multiparte | 6 |

**Regla:** el esqueleto se comparte, pero **la silueta no**. Cada criatura cambia proporciones, añade piezas y tiene su propio material.

### 4.5 Animación de criaturas (estándar)
| Estado | Fotogramas | ms |
|---|---|---|
| Reposo + rasgo vivo | 4–6 | 140–200 |
| Telegrafía (pose sostenida mientras la intención esté activa) | 2 (entrada + bucle de 1 px) | 120 / bucle de 400 |
| Ataque | 4: anticipación, estela, impacto, recuperación | 80 / 33 / 60+*hitstop* / 120 |
| Gesto (bloqueo, buff, invocar) | 3 | 100 |
| Golpe recibido | 2 | 33 de destello + 120 |
| Muerte **por material** | 6–8 | 80 c/u: el carbón se desmorona en trozos, la escoria se funde en un charco, el humo se disipa, el hielo se astilla, el ladrillo se derrumba, la tela cae vacía |

Unos **22 fotogramas por enemigo normal, 30 por élite y 50–70 por jefe** (por partes).

---

## 5. Bestiario — fichas de diseño

Formato: **concepto** · *silueta en una frase* · tamaño nativo (alto × ancho) · material/paleta · anatomía · animación (reposo / telegrafía / ataque / golpe / muerte) · **rasgo vivo**.
Acto 1 = hollín y ladrillo (ocre, carbón, brasa naranja). Acto 2 = escoria y azufre (violeta oscuro, escoria verde ácida, amarillo azufre). Acto 3 = ceniza helada (pizarra azul, escarcha blanca, la brasa como único calor).

### 5.1 Acto 1 · Hollín
**Limo de Ceniza** (masa blanda) — Un charco de ceniza húmeda que ha aprendido a reptar. *Una gota de alquitrán con dos brasas por ojos y un cráter en la espalda.* 26×34. Ceniza gris cálida, con superficie mate y bordes húmedos brillantes. Sin esqueleto: 3 *metaballs*. Reposo: se hincha y deshincha 1 px y del cráter sale una burbuja de humo cada 2 s. Telegrafía: se aplana 3 px y los ojos se agrandan. Ataque: salto en arco con estiramiento ×1,3. Golpe: salpica 3 gotas. Muerte: se extiende en un charco que se seca. **Rasgo vivo:** burbujas en el cráter.

**Murciélago Brasa** (alado) — Un murciélago que anida en las chimeneas y tiene las alas quemadas. *Un triángulo de alas raídas con un núcleo encendido.* 28×44, de **perfil a ¾** (no frontal). Membrana carbonizada con agujeros que dejan ver el fondo; las venas de las alas son emisivas. Reposo: aleteo de 4 fotogramas con sacudida vertical de 2 px. Telegrafía: alas plegadas y caída en picado. Ataque: dos pasadas (2 golpes) con estela de brasas. Muerte: se desintegra en pavesas. **Rasgo vivo:** sueltan chispas por los agujeros de las alas.

**Gólem de Hollín** (bípedo pesado · **prueba de concepto**) — *Un horno de ladrillo encorvado que anda con los nudillos y lleva el fuego en la barriga.* 84×96 (más grande que la heroína: pesa). Ladrillo refractario con hollín que sube desde abajo y alrededor de la chimenea; aros de hierro remachados; extremidades de **trozos de carbón facetado** con especular azulado; cabeza de carbón bajo una visera de ladrillo, con ojos de brasa hundidos y mandíbula de rejilla. La puerta del horno del vientre es su *corazón*. Reposo: la chimenea humea (3 bocanadas en bucle) y los nudillos se apoyan. Telegrafía (golpe de 12): **alza el puño sobre la cabeza y la puerta del horno se pone al blanco** (`golem_tell_x6.png`). Ataque: puñetazo al suelo con onda de hollín. Defensa + Hollín: la puerta se abre y escupe 2 cartas de hollín. Golpe: caen ladrillos. Muerte: el carbón se desmorona y queda la puerta del horno abierta, apagándose. **Rasgo vivo:** gota de hollín bajo el vientre y humo de chimenea.

**Urraca Ígnea** (alado, posado) — Una ladrona de brasas. *Un pájaro de cola larga con algo brillante en el pico.* 34×36. Plumaje negro con reflejos iridiscentes, de pecho blanco ceniza. **Lleva visible el botín robado:** una bolsita que crece de 1 a 3 Ascuas. Reposo: picotea y mira de lado (gira la cabeza en 2 fotogramas). Telegrafía de robo: abre las alas y fija la vista en tu fogón de cinto. Huida: salto con aleteo hacia fuera. Muerte: suelta el botín, que rebota. **Rasgo vivo:** guiño, y el botín brilla.

**Ácaro de Vela** (segmentado mini) — Un insecto que vive de cera fundida. *Un cabo de vela con patas.* 18×22. Cera blanquecina translúcida con mecha encendida en el lomo. Reposo: la llama de la mecha (3 fotogramas). Telegrafía de Fuerza: la llama crece. **Muerte:** la cera se derrite y la mecha estalla en un destello (anuncia su `on_death`). **Rasgo vivo:** goteo de cera.

**Polilla de Llama** (alado) — Una polilla adicta a tu fuego. *Dos alas grandes con ojos pintados alrededor de un cuerpo peludo.* 40×48. Alas de terciopelo con ocelos que reflejan la luz del horno. **Reacciona a tus Quemas** (`on_burn str+1`): cada vez que quemas, sus ocelos se encienden un tono más. Reposo: aleteo lento de 6 fotogramas. Ataque: polvo de alas. Muerte: las alas arden hacia dentro. **Rasgo vivo:** polvo de escamas que cae.

**Caballero Hueco** (élite, bípedo humano) — Una armadura vacía que siguió guardando la torre. *Un yelmo de cubo con el visor abierto y negrura dentro, escudo torre y espadón.* 96×64. Hierro negro mellado y tela roja podrida; el interior de la armadura es **vacío** (negro con una brasa flotando). Reposo: la brasa interior respira. Telegrafía: alza el espadón (2 golpes) o planta el escudo (bloqueo). Muerte: las piezas caen por separado, con la brasa la última. **Rasgo vivo:** la capa raída se mueve con la corriente.

**Bruja de Humo** (élite, bípedo humano sin piernas) — *Una silueta encorvada con sombrero cónico que se disuelve en humo de cintura para abajo.* 90×56. Humo con 3 capas de transparencia simulada (tramado prohibido: se usan tonos), manos huesudas y pipa encendida. Reposo: la falda de humo se desplaza 1 px/fotograma en bucle de 8. Telegrafía de maldición: alza las dos manos y la pipa brilla. Muerte: el humo se dispersa y la pipa cae. **Rasgo vivo:** anillos de humo de la pipa.

**Bruto del Fuelle** (élite, bípedo pesado) — Un forzudo con un fuelle injertado en el pecho. *Un torso enorme con un acordeón de cuero en el tórax y brazos de leñador.* 92×80. Cuero plisado y piel tiznada. Telegrafía de Ahogo: inspira (el fuelle se expande 4 px) y expulsa una ráfaga de ceniza. Muerte: el fuelle se desinfla. **Rasgo vivo:** respiración del fuelle que se oye y se ve.

### 5.2 Acto 2 · Escoria
**Reptante de Escoria** (segmentado) — Un ciempiés de escoria solidificada. *Una cadena de bloques vítreos con patas de aguja.* 30×72. Escoria vítrea violeta con vetas verdes; especular de vidrio. Reposo: ola de patas (6 fotogramas). Defensa: se enrosca. Muerte: se resquebraja en cristales. **Rasgo vivo:** la escoria se enfría y se recalienta por segmentos.

**Ojo Fundido** (masa blanda flotante) — *Un ojo de metal fundido que gotea, con párpado de costra.* 40×40. Iris de oro líquido y esclerótica de escoria. **Párpado** de 3 fotogramas. Telegrafía de Vulnerable: la pupila se contrae y apunta. Muerte: se derrama. **Rasgo vivo:** gota de metal cada 1,5 s que chisporrotea en el suelo.

**Diablillo de Azufre** (bípedo humano pequeño) — *Un diablillo panzudo con cuernos de cristal de azufre y una cerilla gigante.* 36×28. Piel de azufre amarilla-verdosa y cuernos de cristal. Ataque 3×: tres pinchazos con la cerilla. Quemadura: frota la cerilla. Movimiento aleatorio (`random`): da saltitos nerviosos. **Rasgo vivo:** la cerilla humea; parpadea muy rápido.

**Sierpe de Escoria** (segmentado) — *Una serpiente erguida con escamas de esquirla.* 64×48. Escamas de escoria con **espinas visibles** (Espinas 3): el número de espinas dibujadas crece con el estado *thorns*. Reposo: se balancea en S. Muerte: se quiebra. **Rasgo vivo:** lengua bífida, y las escamas centellean.

**Sacerdote de Ceniza** (bípedo humano) — *Una túnica alta con incensario y la cara oculta tras una máscara de cenizas.* 72×36. Túnica de lino gris y máscara de cerámica agrietada. El incensario oscila (péndulo de 6 fotogramas) y suelta ceniza húmeda. Curación de todos: alza el incensario y un anillo de humo verde. **Rasgo vivo:** el humo del incensario.

**Devorador de Ceniza** (masa blanda grande) — *Una barriga con boca: un saco de escoria que engulle.* 56×64. Membrana tensa con brasas que se ven a través. **Engorda cuando te cura tu Quema** (`on_burn heal`): la barriga crece 1 px por Quema durante el combate. Ataque: mordisco vertical. **Rasgo vivo:** digestión: las brasas se mueven dentro.

**Fuelle Rival** (élite, bípedo pesado) — Un fogonero de la competencia: **la anti-Fogonera**. *La misma silueta que la heroína, pero con un fuelle gigante en lugar de martillo.* 88×60. Sus colores son el negativo de los de la heroína (pelo ceniza, bufanda naranja). Castiga no quemar (`on_no_burn`): si no quemas, sopla y su fuelle se infla. **Rasgo vivo:** mira tu fogón de cinto con envidia: los ojos siguen la carta que quemas.

**Guardián de Escoria** (élite, bípedo pesado) — Un **horno de fundición de pie** (no un gólem recoloreado). *Un crisol con piernas, con una cuchara de colada como arma.* 104×72. Hierro fundido con canal de colada encendido. Escudo a todos: vierte escoria a los pies de sus aliados. **Rasgo vivo:** el metal del crisol borbotea.

**Urraca Dorada** (élite, alado) — *La misma ladrona, pero gorda de oro, con un collar de anillos y un nido-cofre.* 70×64. Ya no vuela bien: va **posada en un nido de botín** que crece con lo que roba. Huida: carga con el nido. **Rasgo vivo:** se acicala el collar.

### 5.3 Acto 3 · Ceniza Helada
**Espectro de Escarcha** (bípedo humano sin piernas) — *Un sudario congelado con la forma de alguien que murió de frío junto al fuego.* 72×44. Tela helada rígida, translúcida en los bordes (tono claro + contorno azul, nada de transparencia real) y aliento visible. **Rasgo vivo:** su aliento es vaho que sube.

**Sabueso de Escarcha** (cuadrúpedo) — *Un lebrel esquelético con hielo en el lomo como cresta de sierra.* 40×64. Pelaje gris escarchado con carámbanos. Movimiento aleatorio: olfatea y gruñe. Ataque 3×: tres mordiscos con salto. **Rasgo vivo:** vaho del morro y cola que tiembla.

**Monje Glacial** (bípedo humano) — *Una figura encapuchada y sentada en posición de loto que flota, rodeada de un anillo de hielo.* 64×52. Tela de lana azul pizarra y piel cerúlea. Bloqueo a todos: el anillo se expande. Curación: medita y el hielo le cierra las heridas. **Rasgo vivo:** el anillo de hielo gira 1 px cada fotograma.

**Polilla de Hielo** (alado) — **No es la Polilla de Llama recoloreada:** *una polilla de cristal con alas de escarcha facetada que tintinean.* 40×52. Alas de hielo con facetas Voronoi y especular blanco. Ahogo: escarcha que apaga el fogón (el fogón de la heroína se ennegrece 1 turno: conexión directa). **Rasgo vivo:** cristales que caen como nieve.

**Titán Congelado** (élite, bípedo pesado) — *Un gigante atrapado en un bloque de hielo del que sólo salen la cabeza y un brazo.* 110×96. Hielo facetado translúcido con el cuerpo oscuro visible dentro. **Al perder PV, el hielo se agrieta en 3 estados** (el bloque 30 se ve como el hielo que se recompone). **Rasgo vivo:** el ojo de dentro parpadea a través del hielo.

**Caballero de Escarcha** (élite, bípedo humano) — *Un caballero cuya armadura ha crecido en estalactitas: púas por todas partes.* 100×64. Acero cubierto de escarcha y **espinas de hielo** que crecen con el estado *thorns*. Ataque con Ahogo: clava el espadón en el suelo y una ola de escarcha avanza. **Rasgo vivo:** escarcha que se forma y cae de la capa.

### 5.4 Jefes (180–250 px de alto, multiparte)
Todos se componen de **4–7 piezas animadas por separado** (el rig hornea cada pieza en su propio atlas y se ensamblan en escena). Telegrafía corporal **y** cambio de fase visual al 50 % de PV.

**El Carbonero** (acto 1 · boceto `carbonero_boceto_x2.png`) — *Un gigante encorvado cuya espalda es una carbonera humeante, con sombrero de ala ancha y una mano que te alcanza.* 240×320. La carbonera (montículo de leña cubierto de tierra) tiene 7 respiraderos encendidos que laten de forma desfasada. Su cara son sólo dos ojos bajo el ala del sombrero. Piezas: montículo (respira, 2 px), 7 respiraderos, cabeza y sombrero, brazo cercano con mano (4 dedos), brazo lejano con pala, humo (3 capas). Telegrafía: *Golpe ×2* → alza la pala; *Hollín ×3 + Bloqueo* → **la mano se abre hacia la heroína** y los respiraderos se avivan; *Golpe 20* → se yergue y el montículo se enciende entero; *Fuerza + Curación* → hunde la mano en la carbonera y saca brasas que se come. Fase 2: el montículo se abre y deja ver el fuego interior (cambia la silueta). **Rasgo vivo:** respiraderos y humo.

**El Gran Fuelle** (acto 1) — *Un fuelle de catedral con cara en la boquilla, sostenido por dos brazos de cadena que bombean.* 220×260. Madera de órgano, cuero plisado de 9 pliegues (cada uno, una pieza) y latón. Invocar Ácaros: los escupe por la boquilla. Ahogo: inspira (el fuelle se expande 12 px) y vacía tu fogón. **Rasgo vivo:** el bombeo constante, con los pliegues en onda.

**La Reina Escoria** (acto 2) — *Una matriarca de vidrio volcánico cuyo vestido es una colada de escoria que se solidifica a sus pies.* 240×200. Torso de obsidiana, corona de cristales de azufre creciendo y cetro-cuchara de colada. El vestido fluye en un bucle de 8 fotogramas, solidificándose. Golpe 30: inclina el cetro y vierte escoria. Fase 2: se le rompe la cara de obsidiana y aparece el fuego verde. **No usa la plantilla de las otras «reinas».**

**La Hidra de Escoria** (acto 2) — *Tres cuellos de cadena de fundición que salen de un crisol volcado.* 230×300. Cuello = cadena de segmentos con escamas de escoria; las cabezas son moldes de fundición con mandíbulas de tenaza; el cuerpo, un crisol volcado del que se derrama metal. Cada cuello es una pieza segmentada con su propio bucle (desfase de 1/3). Regeneración: el metal del crisol sube por los cuellos. **Sin tramado.**

**El Corazón Frío** (acto 3) — *Un corazón anatómico congelado dentro de una jaula de costillas de hielo, todavía latiendo.* 220×220. Músculo rojo oscuro bajo el hielo facetado; las arterias son tubos de escarcha que se clavan en el techo y el suelo. Latido de 2 fotogramas cada 900 ms, que **se acelera con la Fuerza**. Golpe 45: el latido se para (telegrafía en silencio) y estalla. Fase 2: se le rompe la jaula y el corazón expuesto **se enciende con tu fuego** (las costillas se derriten).

**El Rey Escarcha** (acto 3) — *Un trono de hielo que es también el rey: la corona se ha fundido con el respaldo y el manto llena el suelo.* 250×320. Rey sentado de 3 partes: trono-cuerpo, brazos y cabeza con corona de carámbanos. Su manto se extiende hasta el borde de la pantalla (escarcha que avanza hacia la heroína en cada turno). Invoca Polillas de Hielo desde la corona. Ahogo ×2: exhala sobre tu fogón. Fase 2: se levanta del trono (**cambio de silueta total**).

### 5.5 Afijos de ciclo (visibles)
| Afijo | Capa visual |
|---|---|
| Ignífugo | Contorno de material ignífugo (gris ceniza mate) y cero píxeles emisivos en el cuerpo. |
| Carroñero | Mandíbulas/boca más grandes (sello extra) y babeo de brasas. |
| Avaro | Monedas y Ascuas incrustadas (sello de 3–5 px) que brillan. |
| Sofocante | Halo de humo oscuro de 2 px alrededor. |
| Pegajoso | Goteo de ceniza húmeda azulada. |
| Templado | Bordes del material con brillo templado (acero azul y pajizo) y escamas de metal sobre el cuerpo. |

El **ciclo** cambia la *hora* de la torre, no el tono de los monstruos: el ciclo II añade brasas en las grietas; el ciclo III, un baño de ceniza más clara; con el ciclo IV o más, los ojos se vuelven blancos-azules (el fuego «muerto»). Las rampas son paletas a mano por ciclo (máximo 3), no rotaciones HSV.

---

## 6. Prueba de concepto — qué hay y qué demuestra

**Archivos:** `tests/_review_art/v04/personajes/rig.gd`, `poc.gd`.
**Ejecución:** `Godot --headless --path . -s res://tests/_review_art/v04/personajes/poc.gd` (seguido de `git checkout project.godot`).

| PNG (`out/`) | Contenido |
|---|---|
| `fogonera_sheet_x4.png`, `fogonera_{idle,windup,strike}_x6.png` | Fogonera rediseñada en reposo + 2 fotogramas de ataque (carga y golpe con estela y chispas) |
| `fogonera_cabeza_x12.png` | Primer plano de la cabeza: el sello de rasgos sobre el render |
| `golem_sheet_x4.png`, `golem_idle_x6.png`, `golem_tell_x6.png` | Gólem de Hollín en reposo y en telegrafía |
| `carbonero_boceto_x2.png` | Boceto de silueta del Carbonero con la heroína a escala |
| `mock_combate_1280.png`, `mock_jefe_1280.png` | Escala real en 1280×720 dentro del mundo de 640×360 |
| `*_x1.png` | Nativos |

**Qué demuestra**
1. **La resolución de 640×360 da el salto de detalle** con el mismo tamaño en pantalla (comparar `mock_combate_1280.png` con `07_combat.png`). La heroína tiene ojo, nariz, boca, gafas, moño, fuelle, saco, tenazas y fogón legibles.
2. **Materiales legibles** con el mismo pipeline: ladrillo con mortero (sólo en luz media), carbón facetado con especular frío, hierro remachado, cuero, lino, acero con arista iluminada, latón y metal al rojo emisivo.
3. **Un fotograma nuevo cuesta unos 12 números:** las 3 poses de la Fogonera son 3 diccionarios de articulaciones. El brazo pasa por detrás de la cabeza en la carga porque el rig redibuja, no rota.
4. **La telegrafía corporal es barata:** `tell` del gólem = 3 articulaciones movidas + un tono más en el horno.
5. **Los pases de limpieza funcionan:** sin huérfanos, líneas internas sólo entre piezas y *sel-out* en el contorno iluminado.

**Iteraciones (lo que aprendí y entra en la §4.3):** (1) cara ilegible: el render no sabe dibujar un ojo, así que hacen falta sellos de tono forzado; (2) los sellos generaban un anillo oscuro alrededor, porque contaban como pieza delantera (corregido en `rig.gd`); (3) el brazo de la carga tapaba la cara: el orden de piezas tiene que poder variar por pose; (4) el martillo era un bloque blanco por exceso de bisel: hace falta la normal de cara inclinada; (5) las piernas del gólem salían como pilares de plástico, así que pasaron a trozos facetados; (6) el boceto del jefe tenía anillos concéntricos en las esferas, que se corrigieron con aplanado `zb` y facetas.

**Qué NO demuestra todavía (honestidad):** las manos siguen siendo una masa de 5 px sin dedos; para el nivel de Blasphemous necesitan un sello por pose (≈ 8 sellos de mano). El pelo carece de mechones grandes con forma: necesita 2–3 sellos de mechón. La telegrafía del gólem pierde el antebrazo detrás de la cabeza. Calculo que la prueba está a un **75–80 % del acabado final**. El 20 % restante es exactamente la capa de parches a mano de la condición 6. El boceto del jefe es una silueta de valores, no un acabado.

---

## 7. Conexión con las demás áreas (mundo vivo e interconectado)
- **Forja ↔ heroína:** el fogón de cinto es una miniatura de la Forja. Al quemar, la carta viaja de la mano al fogón y de ahí sale una chispa a la Forja grande. La luz del fogón es una luz 2D aditiva que el **artista técnico** compartirá con el fondo.
- **Cartas ↔ personaje:** las ilustraciones de las cartas de ataque deben usar los **mismos sellos y materiales** (el martillo, las tenazas, la mano tiznada). Propongo al artista de cartas que hornee sus ilustraciones con este rig y mis poses de detalle, para que la Fogonera de las cartas sea *la misma* que la del combate.
- **Fondos ↔ criaturas:** la paleta de cada acto se define una vez (rampas por material) y la comparten los fondos y los monstruos. La luz de fuego lateral sale de la Forja de la escena, no de una constante.
- **Mundo vivo:** los rasgos vivos de los monstruos (humo, gotas, pavesas) usan **el mismo sistema de partículas pixeladas** que el mundo (antorchas, nieve). El humo del gólem respeta el viento del acto 3.
- **UI:** las intenciones siguen arriba, pero el icono tiene que *coincidir* con la pose de telegrafía (puño alzado ↔ icono de golpe). El retrato del enemigo en el *tooltip* es su sello de cabeza ampliado.

---

## 8. Riesgos y lo que descarto
| Riesgo | Mitigación |
|---|---|
| Que el rig produzca «arte de programador» (vectorial, anillos) | Las condiciones 2, 3 y 6; la revisión a ×6 de cada criatura antes de aceptarla; pruebas de imagen dorada. |
| Coste de render en el arranque | Paso `bake` a atlas y caché en `user://`. |
| Que los fondos se queden en 320×180 | Bloqueante: no se mezclan rejillas. Si el director no acepta 640×360, mi plan B es heroína y monstruos a 320×180 con *el mismo rig* (pierde ~50 % del detalle de cara y materiales, pero gana en materiales y animación). |
| Inflación de alcance (30 fichas) | Paquetes independientes ordenados por impacto (§9). |

**Descarto:** RotSprite en tiempo de generación (lo sustituye el rig); el tramado Bayer en personajes; el recoloreo de cuerpos para crear enemigos «nuevos»; la rotación HSV por ciclo; los monstruos frontales simétricos (salvo el Ojo, que es frontal por concepto); la escala en pantalla para dar presencia; la paleta global de 25 colores como única fuente (pasa a rampas por material).

---

## 9. Estimación por paquetes independientes
Unidades en jornadas de trabajo de un artista técnico-artístico (incluye iterar mirando PNG a ×6).

| # | Paquete | Depende de | Jornadas |
|---|---|---|---|
| P0 | **Rig de producción**: `rig.gd` → `scripts/art/pixel_rig.gd`, capa de parches, orden de piezas por pose, horneado a atlas, imagen dorada | — | 4 |
| P1 | **Fogonera completa**: 38 fotogramas, sellos de mano y pelo, integración con `fighter_view` | P0 | 5 |
| P2 | Capas de progresión de la heroína (Maestría, Resonancias, mejoras, Pactos, ciclo) | P1 | 3 |
| P3 | Esqueleto bípedo pesado + Gólem, Guardián, Titán, Bruto, Fuelle Rival (5 × 22–30 fotogramas) | P0 | 7 |
| P4 | Esqueleto humano + Caballero Hueco, Monje, Caballero de Escarcha, Sacerdote, Bruja, Espectro, Diablillo | P0, P1 | 8 |
| P5 | Masa blanda + Limo, Devorador, Ojo | P0 | 3 |
| P6 | Alados + Murciélago, 2 Polillas, 2 Urracas | P0 | 5 |
| P7 | Segmentados/cuadrúpedo + Reptante, Sierpe, Ácaro, Sabueso | P0 | 5 |
| P8 | Muertes por material (6 variantes de disolución) + afijos visibles | P0 | 3 |
| P9–P14 | **Jefes**, uno por paquete (piezas, fases, telegrafías): Carbonero 5 · Gran Fuelle 4 · Reina 5 · Hidra 5 · Corazón 4 · Rey 5 | P0 | 28 |
| P15 | Integración en combate: anclajes, luces aditivas, sincronía de intenciones con la telegrafía | P1, P3+ | 3 |

**Total: ≈ 84 jornadas.** Ruta crítica para un *vertical slice* del acto 1 (heroína + 6 normales + 3 élites + Carbonero): P0 + P1 + P3 (parcial) + P5–P7 (parciales) + P9 ≈ **28 jornadas**.

Orden recomendado: P0 → P1 → P9 (un jefe espectacular vende el cambio) → P3 → resto.
