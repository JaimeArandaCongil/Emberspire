# Revisión de Arte — EMBERSPIRE v0.2

> Dirección de arte / animación · revisión dura, sin anestesia.
> Material revisado: las 23 capturas de `tests/smoke.tscn` (`screenshots/01…23`), todo `scripts/autoload/art.gd`,
> `ui.gd`, `card_view.gd`, `fighter_view.gd`, `combat_screen.gd`, `rest_screen.gd`, y exportaciones ampliadas generadas en
> `tests/_review_art/out/` (escenas `export.tscn`, `anim.tscn`, `proposals.tscn`, `mon_render.tscn`, `icon_render.tscn`):
> `monsters_b0/1/2.png` (todas las formas ×6 en los 3 biomas), `monster_seeds.png` (5 semillas por forma), `icons.png` / `icons_x2.png`,
> `hero.png`, `card_frames.png`, `card_arts.png`, `bg_0/1/2.png`, `forge.png`, `anim_swing/enemy_lunge/enemy_hit/burn/death.png`
> (tiras de fotogramas a ~30 fps) y las propuestas `proposal_hero.png`, `proposal_monsters.png`, `proposal_icons.png`.

---

## 1. Veredicto general

**Hoy EMBERSPIRE parece un prototipo competente de game jam, no un juego con dirección de arte.** Hay una paleta
razonable y una idea fuerte (la luz es el recurso, quemar = disolución ígnea), pero la ejecución falla en lo que más
pesa en un deckbuilder: **los personajes, los monstruos y la coherencia de escala de píxel**.

Lo que funciona (y hay que proteger):
- La **paleta base** (`PAL`) es cálida, con contorno `k` no-negro: buena base.
- **El set de iconos** es lo mejor del juego: ~70 % son legibles y con contorno consistente (`sword`, `shield`, `heart`,
  `anvil`, `skull`, `crown`, `phoenix`, `key`, `bone`, `potion`…).
- **El shader de disolución** (`UI.DISSOLVE_SHADER`) con rejilla a resolución de arte es la mejor pieza de VFX:
  el lenguaje "todo arde" está bien elegido (`anim_death.png`, `anim_burn.png`).
- El **destello de muerte + disolución** y el **hitstop** (`_hitstop`, 60–80 ms) existen y son el esqueleto correcto.

Lo que lo hunde:
1. **Mezcla de escalas de píxel en la misma pantalla** (fondo ×4, heroína ×6, monstruos ×5/6/7/8, carta ×2 con ilustración ×4,
   horno ×2.5, dorsos ×0.4/×0.6, iconos ×2–×10) + **rotación y escalado continuo de sprites** (respiración 3 %, abanico de
   cartas rotado) → *mixels* y píxeles que tiemblan. Ningún referente (Dead Cells, Blasphemous, Celeste) lo permite.
2. **Monstruos procedurales = manchas simétricas**. La simetría vertical obligatoria mata cualquier criatura de perfil
   (sabueso, urraca, sierpe, diablillo) y la "variación infinita" por semilla sólo cambia garabatos de venas
   (`monster_seeds.png`). No hay diseño, hay máscaras.
3. **Estructura de valores rota**: el muro de fondo y los monstruos del acto 1 comparten valor (el `dark` del bioma 0 es
   `#3c2c32`, el muro `#3a2a2c`). El Gólem de Hollín y la Urraca desaparecen contra la pared (`07_combat.png`).
4. **La heroína es un chibi frontal genérico** con la cabeza casi a la mitad del cuerpo, cara de dos píxeles y un martillo
   de juguete (cabeza de 4×3 px). No transmite "última herrera de una ciudad helada".
5. **El fondo es el mismo cuarto en cada piso y acto**, solo con el tono cambiado; ladrillo-papel-pintado sin profundidad.
6. **UI vectorial con fuente sans genérica + contorno** encima de pixel art: dos juegos distintos pegados.
7. **El horno, el corazón de la fantasía, es lo más pequeño y pobre de la pantalla de combate** (48×40 a ×2.5,
   arrinconado en (0,50)); y en la Forja parece un horno de pizza.

Nota global honesta: **Arte 4/10, VFX 5/10, Animación 4/10, UI 5/10, Cohesión 3/10.**
La buena noticia: casi todo es código, así que se puede reconstruir rápido y de forma sistemática si se fijan
**reglas duras de escala** antes de redibujar nada.

---

## 2. Problemas por severidad (con evidencia)

### CRÍTICO

**C1 · Escalas de píxel incoherentes y transformaciones no enteras (mixels).**
- Fondo `background()` ×4 (`combat_screen.gd:55`), heroína ×6 (`PLAYER_SCALE`), enemigos ×6/×7/×8 y ácaro ×5
  (`combat_screen.gd:158-160`), marco de carta ×2 con ilustración ×4 **dentro de la misma carta** (`card_view.gd:63-70`),
  horno ×2.5 (`combat_screen.gd:243`, ¡no entero!), dorsos de carta ×0.4 y ×0.6 (`combat_screen.gd:298, 746, 830`),
  iconos de reposo ×10 y de evento ~×10 (`rest_screen.gd:17`, `21_event_forge_spirit.png`).
- `FighterView._start_bob()` escala el sprite entre 0.97 y 1.03 en bucle: a ×6 eso hace que filas de píxeles aparezcan y
  desaparezcan cada respiración. `lunge()`/`shake()`/`swing()` rotan el sprite entero (±0.06–0.1 rad): escalones dentados.
- El abanico de la mano rota las cartas pixeladas (`combat_screen.gd:355`): bordes de marco en escalera visibles en
  `07_combat.png`, `16_act2_hydra.png`.
- Resultado: en una misma captura conviven píxeles de 2, 2.5, 4, 5, 6, 7, 8 y 10 px. Es el error #1 de cohesión.

**C2 · Los monstruos no son criaturas diseñadas.** (`art.gd` `SHAPES` + `_build_monster`, `monsters_b0/1/2.png`)
- Todo es simétrico y frontal → `hound` parece una mariposa en X, `bird` (Urraca) es un huevo con pico central,
  `serpent` es una campana/tótem, `imp` y `moth` son la misma araña. Las criaturas "de perfil" son imposibles por diseño.
- Ojos de 1 px por lado (`E` en la máscara) y una "boca" de rayas → todas las caras son la misma carita de Space Invader.
- La semilla sólo mueve 2–4 caminos aleatorios de "venas" (`veins` en `_build_monster`) y la probabilidad de `o`:
  `monster_seeds.png` muestra que 5 gólems distintos son el mismo gólem con garabatos naranjas diferentes.
  Las venas son paseos aleatorios sin anatomía: parecen grietas al azar, no lava bajo la piel.
- Sombreado por campo de distancia + Bayer = "almohada" uniforme: todo es una pastilla gris con borde claro arriba.
  No hay planos, no hay materiales (piedra vs. carne vs. plumas vs. hielo se sombrean igual).
- El contorno es `k` puro alrededor; el comentario dice "sel-out" pero el código pinta siempre `outline` (no hay sel-out).

**C3 · Valor (luminosidad) de personajes = valor del fondo.**
- Bioma 0: monstruo `light #9a8478 / mid #64504e / dark #3c2c32` sobre muro `#3a2a2c` ± 10 %. Siluetas grises sobre ladrillo
  gris con mortero de alto contraste: el ojo no encuentra al enemigo (`07_combat.png`, `11_after_enemy_turn.png`).
- Acto 3: monstruos blanco-azulados con tramado blanco ruidoso sobre azul (`17_act3.png`, `18_frost_king.png`): el
  Rey Escarcha es una mancha de ruido; ojos azul claro sobre cuerpo azul claro → sin cara.
- Los fondos usan contraste local alto (mortero oscuro cada 8 px, ladrillos aclarados) en toda la pantalla, compitiendo
  con los sprites. Debería ser al revés: fondo de bajo contraste, personajes de alto contraste.

### ALTO

**A1 · Heroína (`SPRITES["player"]` 20×30, `player_arm` 8×17).** (`hero.png`)
- Cabeza 14/30 filas ≈ 2.1 cabezas de alto: chibi de RPG Maker, choca con el tono "última herrera" y con monstruos
  semi-realistas. Cara frontal: dos píxeles `k` como ojos, boca `r` de 1 px, sin oreja, sin mandíbula.
- El pelo es una **corona amarilla literal** (`koyokoyyokok`) + cinta blanca: lee "corona de fuego/rey", no pelo.
- Torso marrón plano (`n`) sin delantal de herrera ni volumen; el pecho `WWW` es un parche blanco sin sentido.
- Brazo: el antebrazo es la propia llama (`koyok/kowok`) → parece una antorcha, no una mano. El martillo tiene cabeza de
  4×3 px (`kMMMk / kMMMmmk`): en el golpe (`anim_swing.png`) se lee como agitar una cuchara.
- Mira de frente al jugador mientras ataca a la derecha: no hay dirección de mirada ni pose de combate.
- Sombras `S` de piel sin desplazamiento de tono (`#b07050` es la misma tinta oscurecida); nada de hue-shift.

**A2 · Jefes sin presencia.** (`14_boss_summon.png`, `16_act2_hydra.png`, `18_frost_king.png`)
- El Gran Fuelle mide lo mismo que la heroína; la Hidra es un pulpo morado simétrico con "brazos" de 1 px; el Rey Escarcha
  es un bloque de ruido. Ningún jefe tiene silueta única (todos son "mancha + corona de `a`").
- No hay escenografía de jefe: ni luz propia, ni plataforma, ni cambio de fondo, ni intro (nombre en pantalla, caída de
  polvo), ni idle distinto. Un jefe de acto debe ocupar 35–45 % del alto de la pantalla.

**A3 · Fondos: un solo cuarto para todo el juego.** (`bg_0.png`, `bg_2.png`, todas las capturas de combate)
- Misma composición (2 ventanas, 2 estandartes, 4 columnas, 4 antorchas) en combate, mapa, tienda, reposo, evento y
  resumen; los actos sólo cambian el tinte. El acto 2 (Escoria) casi no se distingue del 1.
- Ladrillo 16×8 uniforme sin variación de escala ni zonas de reposo → papel pintado.
- **Línea negra vertical en el centro del suelo** (`(persp + 400) % 20 == 0` cae exactamente en x=160): parte la pantalla en
  dos en todas las capturas (visible en `01_title.png`, `06_map.png`, `19_shop.png`).
- La "luz de antorcha" sobre el muro (`dither(x,y,g*0.7)` con `lerp 0.18`) se ve como **rectángulos grises tramados**,
  no como luz cálida (`bg_0.png`, alrededor de cada soporte). Las ventanas son agujeros negros sin luz que entre.
- Sin capas: ni primer plano, ni parallax, ni niebla, ni profundidad atmosférica. El suelo (40 % de la pantalla) está vacío
  y queda tapado por la mano.

**A4 · El horno (`forge_sprite`).** (`forge.png`, `02_forge.png`, `07_combat.png`)
- Cúpula con hileras de ladrillo horizontales que no siguen la curvatura, boca con tramado ajedrez 50 % amarillo (ruido),
  sin parrilla, sin brasas, sin herramientas, sin yunque ni fuelle: se lee como **horno de pizza**.
- En combate es diminuto (≈120×100 px) y a escala ×2.5 no entera; la carta quemada vuela por delante de la cara de la
  heroína y se disuelve en el aire antes de llegar (`anim_burn.png`), y los textos "Quemas: 0 / Calor 1" quedan tapados.

**A5 · Cartas.** (`card_frames.png`, `card_arts.png`, `23_cards.png`)
- Los 5 marcos son el mismo rectángulo recoloreado: sin lenguaje de forma por tipo (StS: ataque = ventana en punta,
  habilidad = rectángulo, poder = óvalo). A 150 px de ancho y en abanico, sólo el color distingue el tipo.
- El "papel" del cuerpo es marrón oscuro tramado: el texto blanco sobre eso necesita contorno grueso → ruido.
- La ilustración (30×15) es **un icono de 12×12 pegado en un degradado**; a ×4 contra el marco ×2 = mixel interno.
  Cinco "Golpe/Tajo/Golpe Estelar/Espada Llameante/Fuerza" son la misma espada diagonal recoloreada.
- El texto se corta en la mano ("Inflige 7 de dañ", "Gana 6 de Bloque", "Embestida Blindada" sin primera letra) en
  `07_combat.png`, `11_after_enemy_turn.png`, `19_shop.png`.
- Rareza = gema de 4×3 px abajo: invisible. Maestría = puntitos de 2 px en el canto: invisibles.

### MEDIO

**M1 · Iconos problemáticos** (`icons.png`, `icons_x2.png`; a ×2 que es la escala real del juego):
- Ilegibles/feos: `log` (rectángulo marrón), `coal` (mancha), `smoke`/`choke`/`wet_ash`/`breath` (sin contorno, borrón),
  `lizard` (palo naranja), `feather` (zanahoria), `slag` (globo verde), `lung` (dos riñones), `fang` (no se lee),
  `golem` (calavera oscura que desaparece), `cloak` (fantasma), `weight`/`kettle`/`jar` (tres ollas iguales),
  `chest`/`box`/`door` (mismo cofre).
- Duplicados semánticos: `orb`, `ember`, `coin` son la misma bola naranja → la moneda de la economía (Ascuas) no tiene icono
  propio. Siete "palos diagonales" (`sword`, `flame_sword`, `str`, `parry`, `star_sword`, `greatsword`, `poker`, `brand`).
- `str` (Fuerza) = espada naranja: no se distingue de un ataque. `down` (Débil) y `vuln` sin semántica clara a ×2.
- Inconsistencia de contorno: `sparks`, `wind`, `sun` (rayos), `snowflake`, `smoke` sin `k`; el resto con `k`.

**M2 · UI vectorial vs. pixel art.**
- Fuente por defecto de Godot (sans antialiasada) con contorno de 3–4 px en todo, incluido el logo `EMBERSPIRE`
  (`01_title.png`): el título es texto de sistema con borde, sin logotipo.
- Paneles `StyleBoxFlat` con borde 3 px y sombra 4 px (bien en la biblia) pero en coordenadas de pantalla, no de arte:
  sus "píxeles" son de 1 px mientras el fondo usa 4 px. Las cajas moradas de resonancias (`07_combat.png` arriba a la
  izquierda) son de otro juego.
- Jerarquía de HUD débil: el contador de energía (orbe ×? a la izquierda) compite con "Robo/Exilio" en texto gris; la
  intención enemiga (lo más importante del turno) es un icono ×3 y número de 22 px; la barra de vida enemiga tiene el
  mismo peso que la del jugador.
- El título de piso y las instrucciones "Clic: jugar · Clic derecho: QUEMAR…" se superponen al estandarte central.

**M3 · Animación de combate.** (`anim_swing.png`, `anim_enemy_lunge.png`, `fighter_view.gd`)
- `swing()`: anticipación 90 ms y golpe 70 ms → la anticipación es más corta que el impacto; no hay pose de carga
  sostenida ni *smear*. El cuerpo entero se desliza 42 px sin paso (patina). El brazo rota como una aguja de reloj
  separada del hombro (frames 2–6 de la tira).
- `lunge()`: 14 px de retroceso y 46 px de embestida a ×7 son 2 y 6 píxeles de arte: casi imperceptible. Sin squash/stretch.
- `shake()`: la biblia dice "nunca temblor simétrico" pero el bucle hace jitter aleatorio ±strength·0.4.
- Idle: todos los monstruos respiran igual (escala) — ver C1. No hay frames de animación reales en ningún sprite.
- Los números de daño son texto vectorial gigante que tapa al enemigo ("9999!" en `12_death_dissolve.png`).

**M4 · Pantallas secundarias.**
- Reposo (`20_rest.png`): la hoguera es el icono `log` a ×10 → un ladrillo marrón con una barra amarilla y partículas
  encima. La heroína flota sobre el muro sin suelo debajo.
- Evento (`21_event_forge_spirit.png`): el "Espíritu de la Forja" es el icono `furnace` a ×10. Ningún evento tiene ilustración.
- Mapa (`06_map.png`): "torre" = lista de botones grises; heroína de 20 px de alto pegada a "Base"; las puertas son
  marcos vacíos con la misma espada.
- Forja (`02_forge.png`): tres columnas de listas; el horno, que debería ser el protagonista, ocupa 1/6 de la pantalla.

### BAJO
- `card_back()`: patrón de rombos fino que a ×0.4 hace moiré.
- `cost_orb`: orbe de coste con tramado radial está bien, pero el número encima usa la fuente vectorial grande.
- Partículas de polvo/ascuas (`UI.dust`) son cuadrados de pantalla sin escala de arte (1–6 px) → otra escala más.
- Sombras de suelo de los luchadores (`_draw`) son rectángulos semitransparentes: OK funcional, pobre visualmente.

---

## 3. Plan de arte priorizado (26 puntos)

Leyenda de esfuerzo: **S** ≤ medio día · **M** 1–3 días · **L** 1–2 semanas.

### Fase 0 — Reglas que hacen posible todo lo demás

**1. Fijar una escala de arte única: "1 píxel de arte = 4 px de pantalla" para el mundo.** (M)
- Dónde: `combat_screen.gd` (`PLAYER_SCALE`, `_add_enemy_view` `sc`), `rest_screen.gd`, `map_screen.gd`, `title_screen.gd`.
- Técnica: renderizar todo el escenario de combate (fondo, horno, luchadores, VFX del mundo) dentro de un `SubViewport`
  de 320×180 con `canvas_item` *snap* (`snap_2d_transforms_to_pixel = true`, `snap_2d_vertices_to_pixel = true`) y escalarlo
  ×4 entero al viewport 1280×720. Los tamaños se resuelven redibujando sprites al tamaño correcto (heroína 24×36,
  normales 16–28 px, élites 28–36, jefes 40–64 px de alto), **no** escalándolos ×6/×7/×8.
- Efecto: desaparecen los mixels, las rotaciones y escalados se cuantizan a la rejilla de arte (se ven "pixel-perfect"
  como en Dead Cells/Blasphemous), todo pertenece al mismo mundo.

**2. Prohibir scale/rotation continuos sobre pixel art fuera del SubViewport.** (S)
- Dónde: `FighterView._start_bob`, `shake`, `lunge`, `swing`, `cast`; `combat_screen.gd` abanico de cartas.
- Técnica: idle = desplazamiento vertical de 1 px de arte a 2–3 fps (`position.y` en pasos enteros) o frames; las cartas
  pueden rotar porque viven en la capa UI a ×2, pero con `texture_filter = LINEAR` sólo durante el vuelo, o mejor:
  abanico con offset vertical, sin rotación (Balatro rota, pero dibuja sus cartas a resolución alta).
- Efecto: fin del temblor de píxeles.

**3. Estructura de valores: fondo en rango 15–45 % de luminancia, personajes 10–90 %.** (S)
- Dónde: `BIOMES` (`wall`), `background()` (mortero `darkened(0.45)` → `darkened(0.18)`; ladrillo ±6 % → ±3 %),
  y en `_build_monster` añadir un rim light del color `glow` del bioma en los píxeles con `right_empty`/`up_empty`.
- Técnica: comprobar en escala de grises (exportar `bg` y monstruos desaturados). El muro del acto 1 baja a `#2a1e22` con
  mortero `#221819`; los monstruos suben `light` a `#b8a090`.
- Efecto: las siluetas saltan del fondo sin tocar el diseño. Es lo más barato con mayor impacto.

### Fase 1 — Personajes

**4. Redibujar a la heroína a 24×36 en 3/4 mirando a la derecha.** (M) — ver ASCII §3.A
- Dónde: `SPRITES["player"]`, `SPRITES["player_arm"]`, pivote en `FighterView.setup` (`arm.position = Vector2(12,16)`,
  `pivot_offset = Vector2(3.5, 1.5)`).
- Técnica: 3.6 cabezas de alto, coleta-llama (`R r o y`) hacia atrás en vez de corona, cinta de trapo `W`, bufanda fría
  `b/c/B` (único acento frío del personaje = contraste complementario), delantal de cuero `n/h` con bolsillo y hebilla `y`,
  botas pesadas. Sombras con desplazamiento de tono: piel `s`→`S`→`h` (hacia rojo), cuero `n`→`h`→`k`.
- Efecto: personaje adulto, legible y con dirección; el martillo pesa.

**5. Martillo de forja real y brazo con brazal.** (S) — incluido en §3.A
- Cabeza de 9×4 (`M/m/d`) con mango de 5 px; antebrazo con brazal `h` en lugar de "antebrazo-antorcha".

**6. Animación de la heroína en frames, no sólo rotación.** (M)
- Dónde: nuevo `SPRITES["player_atk1..3"]` y `player_hurt`; `FighterView.swing()` cambia `sprite.texture` por frame.
- Técnica (a 1 px de arte = 4 px): **anticipación 140 ms** (frame de carga, martillo detrás de la cabeza, cuerpo
  agachado 1 px) → **hold 40 ms** → **smear 1 frame 33 ms** (arco de 3 px de ancho en `w/y` con el contorno `o`) →
  **impacto 50 ms + hitstop 70 ms** → recuperación 220 ms (`TRANS_BACK`). Paso adelante de 6 px de arte (24 px) con
  frame de pierna adelantada, no desliz.
- Efecto: golpe con peso; en Hyper Light Drifter/Dead Cells el 60 % del "feel" es esta curva.

**7. Monstruos: plantilla base dibujada a mano por arquetipo + variación procedural encima.** (L) — ver ASCII §3.B
- Dónde: nuevo `const MONSTER_BASES` en `art.gd` con caracteres de rampa remapeables (`1` claro, `2` medio, `3` oscuro,
  `4` profundo, `a` acento emisivo, `E` ojo, `k` contorno); `_build_monster` pasa a: (a) cargar base asimétrica,
  (b) aplicar el sombreado de distancia sólo como *modulador* (±1 escalón de rampa) en regiones `2`,
  (c) variación por semilla = **piezas intercambiables** (3 cabezas, 3 colas/cuernos, 2 patrones de placas por arquetipo,
  ancladas en puntos `@1`, `@2`) + venas que siguen **líneas de articulación** definidas en la base, no paseos aleatorios.
- Mantener la simetría sólo como opción (`"symmetric": true`) para criaturas frontales (limo, ojo, tótem).
- Efecto: criaturas reconocibles de perfil, mirando a la heroína, con variación que sí se nota.

**8. Ojos y caras.** (S)
- Dónde: `_build_monster` match `"eye"`.
- Técnica: ojos mínimo 2×2 de arte con píxel `Y` de brillo + 1 px de halo `glow` en la capa emisiva; boca con dientes
  `W` en 1 de cada 2 px en vez de rayas `k`/acento. En el acto 3 los ojos pasan a `#60d8ff` sobre cuerpo oscurecido
  (invertir: cuerpo `mid/dark`, sólo el borde superior `light`).
- Efecto: cada enemigo tiene mirada, la intención "me está mirando" llega.

**9. Rampas de material por arquetipo.** (M)
- Dónde: `BIOMES` → añadir `materials: {stone, flesh, feather, ice, slag}` con 4 tonos cada uno y desplazamiento de tono
  (sombras hacia `#2a1830` violeta en actos 1–2, hacia `#1a2a4a` en el 3; luces hacia amarillo).
- Técnica: el tramado Bayer se limita a **una** transición por material (sombra↔medio) y sólo en piezas grandes (jefes);
  en sprites <24 px, sin tramado (el ruido actual del acto 3 desaparece).
- Efecto: piedra parece piedra, hielo parece hielo.

**10. Jefes: sprites únicos, grandes, con escenografía.** (L)
- Dónde: `SHAPES["boss_*"]` → `MONSTER_BASES["boss_*"]` a mano (48–64 px de alto en arte = 190–256 px de pantalla);
  `combat_screen.gd` añade para `is_boss`: halo trasero (`UI.halo` grande del color `glow`), viñeta que oscurece el resto
  un 15 %, polvo cayendo del techo y banner de nombre de 1.2 s con el sprite apareciendo con `spawn()` desde abajo.
- Técnica: silueta reconocible en negro puro (prueba de silueta), 1 rasgo exagerado por jefe (Fuelle = fuelle-pulmón
  que se infla en el idle con 2 frames; Hidra = 3 cuellos asimétricos; Rey Escarcha = corona de carámbanos + capa).
- Efecto: momento de jefe de verdad (referencia: Blasphemous, Inscryption).

### Fase 2 — Mundo

**11. Fondos por capas con parallax y variación por acto.** (L)
- Dónde: `background()` se divide en `bg_far()` (cielo/vacío del pozo de la torre, 320×180), `bg_mid()` (muro y arcos) y
  `bg_near()` (columnas, cadenas, pilares en primer plano oscuros casi negros); `combat_screen.gd` las coloca en
  `ParallaxBackground`/`Parallax2D` con desplazamiento de 0/2/6 px de arte reaccionando a la posición del ratón o al golpe.
- Por acto: Acto 1 Hollín = muro de ladrillo con hollín, horno-catedral; Acto 2 Escoria = paredes de roca fundida con ríos
  de escoria verde emisiva; Acto 3 Ceniza Helada = piedra azul con hielo, ventanas con nieve y luz fría de luna.
  Tres composiciones distintas, no un tinte.
- Efecto: sensación de subir una torre; profundidad.

**12. Arreglar fallos concretos del fondo.** (S)
- Quitar la línea central: desplazar `persp` medio tile (`(persp + 410) % 20`) o no dibujar la línea en `x == W/2`.
- Luz de antorcha: sustituir el tramado `lerp 0.18` por 3 anillos concéntricos de tono (`#4a2a20`, `#5a3424`, `#6a3e28`)
  sin tramado, o dejarlo en la capa aditiva `UI.halo` sólo.
- Ventanas: añadir cielo con 2–3 estrellas/ascuas y una franja de luz diagonal (rayo de luz a 15 % alpha aditiva).
- Contraste: ver punto 3.

**13. Horno-protagonista.** (M)
- Dónde: `forge_sprite()` → redibujar a 64×56 a mano (cúpula con hiladas radiales, arco de dovelas, parrilla con brasas
  de 3 tonos animadas en 4 frames, chimenea con humo, yunque y fuelle al lado). En combate colocarlo a la izquierda,
  detrás de la heroína, al mismo suelo, a escala de arte (sin ×2.5). La boca usa la capa aditiva.
- Al quemar: la carta describe un arco **por detrás** de la heroína (z menor) hacia la boca; la disolución empieza al
  entrar en la boca (no a medio camino); el horno hace squash 80 ms (1.0→1.08×0.92 en frames, no en escala) y escupe
  6–10 chispas.
- Efecto: el verbo central del juego tiene un sitio en la pantalla.

**14. Hoguera, eventos y mapa con arte propio.** (M)
- `rest_screen.gd`: sustituir `UI.icon("log", 10)` por un sprite `bonfire_big` 32×32 con 4 frames de llama.
- `event_screen.gd`: una viñeta de 96×48 por evento (o 5 plantillas reutilizables: altar, herrero, pozo, espejo, mercader).
- `map_screen.gd`: dibujar la torre como columna de pisos ilustrada (sección transversal), la heroína a escala de mundo.

### Fase 3 — Cartas e iconos

**15. Marcos con lenguaje de forma por tipo.** (M)
- Dónde: `card_frame()`.
- Técnica: ventana de ilustración con forma por tipo (Ataque: arco apuntado; Habilidad: rectángulo con remaches;
  Poder: óvalo con rayos; Combustible: boca de horno con rejilla en la parte inferior; Estado: marco agrietado).
  Cuerpo de texto en pergamino claro `#e8d4b0` con texto oscuro `#2a1418` (sin contorno) → legibilidad inmediata.
  Gema de rareza 6×6 en la banda del nombre; Maestría como 1–5 muescas ígneas en el borde superior de la ilustración.
- Efecto: se reconoce el tipo por silueta incluso en abanico.

**16. Ilustraciones de carta a la misma escala que el marco.** (M)
- Dónde: `card_art()` → generar a 60×30 (×2, igual que el marco) en vez de 30×15 ×4.
- Técnica: componer escena: icono principal a 24×24 (redibujado, no el icono ×2), suelo/horizonte, 1 efecto (tajo,
  aura, chispas) y luz direccional. Familias: 1 ilustración por carta para las 20 más jugadas; el resto, plantilla.
- Efecto: fin de "clip-art sobre degradado"; la carta tiene arte.

**17. Texto de carta que cabe.** (S)
- Dónde: `card_view.gd` → `autowrap` + `fit_content` con tamaño mínimo 12, y reducir rotación del abanico; nombres largos
  con `clip_text = false` + reducción automática de fuente.

**18. Redibujar los iconos ilegibles y separar duplicados.** (S/M) — ver ASCII §3.C
- `log`, `coal`, `smoke` (+variantes `choke`, `wet_ash`, `breath` heredan el contorno), `lizard`, `coin` (moneda propia
  de Ascua, distinta de `ember`/`orb`), `fang` ya propuestos. Pendientes: `feather`, `slag`, `lung`, `golem`, `cloak`,
  `weight`, `box`/`door`, `str` (bíceps/puño en vez de espada).
- Regla: contorno `k` en todos (también `sparks`, `wind`, `sun`, `snowflake`), luz arriba-izquierda, máx. 4 tonos +`k`.

### Fase 4 — UI

**19. Fuente pixel generada en runtime.** (M)
- Dónde: nuevo `scripts/ui/pixel_font.gd` que construye un `FontFile` desde un mapa ASCII 5×7 (mayúsculas, minúsculas,
  dígitos, `áéíóúñ¿¡`) y un 8×12 para títulos; `UI.build_theme()` la asigna como `default_font`; escala entera (×2 / ×3).
- Técnica: `FontFile.set_texture_image()` + `set_glyph_uv_rect/advance/size` por glifo; sin antialias, contorno de 1 px de
  arte generado (glifo dilatado en `k`).
- Efecto: UI y mundo hablan el mismo idioma (Celeste, Dead Cells usan pixel fonts en HUD).

**20. Logotipo dibujado.** (S/M)
- `title_screen.gd`: logotipo "EMBERSPIRE" en ASCII 8×12 por letra con rampa `y→o→r` vertical, contorno `k`, una `I` como
  torre con llama; chispas emisivas animadas.

**21. Paneles en rejilla de arte.** (S)
- `UI.box()` → `StyleBoxTexture` generado desde una imagen 9-slice 12×12 pixel (borde biselado de 2 px de arte, remaches
  en esquinas) escalada ×2 o ×4; sustituir los bordes morados de resonancias por el mismo 9-slice con tinte.

**22. Jerarquía de HUD de combate.** (S)
- Intención enemiga: icono ×4 sobre placa oscura + número de 28 px con color por umbral; es lo segundo más importante tras
  la mano. Energía: orbe más grande (×3) y "Robo/Exilio" como contadores-pila con icono de carta, no texto gris.
- Mover las instrucciones de controles a un tooltip/primera partida; el título de piso a la izquierda.

### Fase 5 — VFX y juice

**23. Curva de impacto estándar ("golpe Emberspire").** (S)
- Dónde: `combat_screen.gd` donde se aplica daño (`v.shake`, `main.shake`, `_hitstop`).
- Tiempos: hitstop 50 ms (daño <10), 80 ms (10–30), 120 ms (>30); flash blanco 1 frame (33 ms) → flash del color del
  bioma 66 ms; empuje direccional 3 px de arte en 50 ms y vuelta en 150 ms con `TRANS_BACK` (sin jitter aleatorio);
  shake de cámara direccional (no circular) de 2–6 px de arte con caída exponencial 180 ms; 8–14 chispas en abanico
  en la dirección del golpe.
- Números de daño: pixel font, 2× el tamaño en críticos, salen con pop (0.6→1.2→1.0 en 120 ms) y caen con gravedad;
  máx. 40 px de pantalla de alto.

**24. Embestida enemiga con squash & stretch en frames.** (S)
- `lunge()`: anticipación 160 ms (retroceso 4 px de arte + frame "agachado" generado aplastando la base 1 fila),
  embestida 60 ms de 12 px de arte con frame estirado, impacto + hitstop, retorno 240 ms.

**25. Partículas a escala de arte y con paleta.** (S)
- `UI.sparks`, `UI.dust`, `UI.fire_emitter`: textura de partícula 1×1 / 2×2 de arte (4 / 8 px de pantalla), colores sólo de
  la rampa de fuego `r o y w Y` mediante `color_ramp` escalonada (sin degradado), vida 0.3–0.8 s; ascuas que suben con
  ondulación seno.

**26. Luz dinámica barata.** (M)
- Capa `CanvasModulate` oscura (#6a5a60) + `PointLight2D` con textura de halo cuantizada (4 anillos) en antorchas, horno y
  ojos de jefe; la intensidad del horno sube con el Calor y parpadea al quemar. Mantener la capa emisiva actual
  (`monster_glow`) como luz no afectada.
- Efecto: "la luz es el recurso" se ve en pantalla.

---

### 3.A — Heroína propuesta (24×36 cuerpo + 10×20 brazo, chars de `PAL`)

Render de comparación: `tests/_review_art/out/proposal_hero.png` (izquierda actual, derecha propuesta).
Todas las filas verificadas: cuerpo 36 filas × 24, brazo 20 filas × 10. Brazo: pivote del hombro en (3, 1); colocarlo en
el cuerpo en (12, 16). Es una base de trabajo (ritmo de formas y proporciones), pensada para pulir el detalle a mano.

```gdscript
"player": [
	"........kkkkk...........",
	"......kkRrroyk..........",
	".....kRrrrooyyk.........",
	"....kRrrrroooyyk........",
	"..kkRRrrrrrrooyyk.......",
	".kyRRrrWWWWWWWWWk.......",
	"kyoRrkrrrrrrrrorkk......",
	"koRrkSRrsssRrsssk.......",
	"kRRkRSsssssskssk........",
	".kRkRSSssssWksssk.......",
	"..kkRSSssssssssk........",
	"....kSSsssssRsk.........",
	".....kSSssssskk.........",
	"......kkSSSSk...........",
	".....kbbkkkkbbk.........",
	"....kbccbbbbbccbk.......",
	"...kbcbBbbbbbBbbbk......",
	"..kSkkBnnnnnnnnkBk......",
	"..kSsknnnnnnnnnhkk......",
	"..kSsknhhhnnnnnhk.......",
	"..kSsknhnhnnnnnhk.......",
	"..ksSkkkkkykkkkkk.......",
	"..kSSknhnkyknnhnk.......",
	"...kkknnnnnnnnnhk.......",
	".....knnnnhnnnnhk.......",
	".....knnhnnnnnhhk.......",
	".....kdddddkdddddk......",
	"....kdddgdk.kdgdddk.....",
	"....kddgdk...kdgddk.....",
	"....kdddk.....kdddk.....",
	"....kdgdk.....kdgddk....",
	"...kkhhhk.....kkhhhk....",
	"..khnnnhk.....khnnnhkk..",
	"..khnnnhk.....khnnnnhhk.",
	".khhhhhhk.....khhhhhhhk.",
	".kkkkkkkk.....kkkkkkkkk.",
],
"player_arm": [
	"..kkkk....",
	".knnnnk...",
	".knnnhk...",
	".kSssSk...",
	".kSssSk...",
	"..kSsSk...",
	"..kSsSk...",
	"..khhhk...",
	"..kssSk...",
	"..ksSSk...",
	"...knk....",
	"...khk....",
	"...knk....",
	"...khk....",
	"...knk....",
	"kkkkhkkkk.",
	"kMMMMMmmdk",
	"kMmmmmmmdk",
	"kmmmmmmddk",
	"kkkkkkkkk.",
],
```

Claves de diseño: coleta-llama con puntas `y o` hacia atrás (movimiento, lee "fuego" sin ser corona); cinta `W`
quemada; ojo de 2 px con brillo `W`; oreja/patilla `R`; bufanda fría `b c B` (contraste complementario y guiño a la
"ciudad helada"); delantal `n/h` con bolsillo y hebilla `y`; postura abierta de herrera; martillo de 9×4.
Siguiente pase recomendado: añadir 1 tono de hue-shift en la piel (`S` → un `#a85a48` nuevo) y 1 en el pelo (`R` en sombra
del flequillo).

### 3.B — Plantillas base de monstruos (asimétricas, mirando a la izquierda)

Caracteres de rampa remapeables por bioma: `1` claro, `2` medio, `3` oscuro, `4` profundo, `a` acento emisivo, `E` ojo,
`k` contorno. Render en los 3 biomas: `tests/_review_art/out/proposal_monsters.png`. Anchos verificados.
El sombreado procedural actual puede aplicarse encima como modulador ±1 tono sobre la región `2`.

**Sabueso (hound) — 26×15**, cuadrúpedo de perfil (sustituye a la máscara `hound` en X):
```gdscript
"hound": [
	"..kk......................",
	".k1k.k....................",
	".k21kk1k..................",
	"k1112221kk................",
	"k12E22221kkkkkkkkkkk......",
	"kaa222222111111111221k....",
	".kkk2223322222222222221k..",
	"..kaak33322222222233332k1k",
	"...kk.k3332222223333332k2k",
	"......k33k33333333k3333kk.",
	".....k33k.k333kkkk.k333k..",
	".....k3k...k33k.....k33k..",
	"....k3k.....k3k......k3k..",
	"...kaak....kaak.....kaak..",
	"...kkk.....kkk......kkk...",
],
```

**Gólem — 25×24**, puño izquierdo enorme (el que golpea a la heroína), hombro alto, núcleo emisivo en el pecho:
```gdscript
"golem": [
	".........kkkkkk..........",
	"........k111111k.........",
	".......k11222221k........",
	".......k1E22E222k........",
	".......k12aaaa23k........",
	"...kkkkk1222223kkkkk.....",
	"..k11112k22222k211113k...",
	".k1122222k333k22222233k..",
	"k112222222222222222233k..",
	"k1222a2222222222a222333k.",
	"k1222aa22222222aa2223k3k.",
	"k22222a222222222a2233k3k.",
	".k2222222222222222233k3k.",
	".k3222k22222222k2233k33k.",
	"..k33k.k3333333k.k3k.k33k",
	"..k33k.k2222333k.kk..k3ak",
	".k1223kk22kkk233k...kaak.",
	"k11223k.k22k.k233k...kk..",
	"k12233k.k22k.k233k.......",
	"k22333k.k23k.k333k.......",
	".kaaak..k33k.k333k.......",
	"..kkk..kk33k.k333kk......",
	".......k3333k.k33333k....",
	".......kkkkkk.kkkkkkk....",
],
```

**Urraca (bird) — 19×16**, de perfil, pico acento, cola larga con plumas `a` (sustituye al "huevo con pico"):
```gdscript
"bird": [
	"......kkkk.........",
	"....kk1111k........",
	"...k1112221k.......",
	"..k1E222222k.......",
	"kaak22222221k......",
	".kkk22222223k......",
	"....k222222233k....",
	"...k1122222233kk...",
	"..k11122222233a3k..",
	"..k1112222223aa33k.",
	"...k122222233a3333k",
	"....k2222333aak333k",
	".....kk33333k..kk3k",
	".......kk3k3k....kk",
	".......k3k.k3k.....",
	"......kaak.kaak....",
],
```

Variación por semilla sugerida sobre estas bases: (1) intercambio de cabeza/cola en anclas, (2) placas `1` extra en el
lomo, (3) 0–2 grietas emisivas siguiendo filas `3`, (4) escala ±2 px de arte en el cuerpo, nunca en cabeza ni ojos.

### 3.C — Iconos rediseñados (12×12, `PAL`)

Comparación arriba-actual / abajo-propuesta: `tests/_review_art/out/proposal_icons.png`. Todas las filas = 12.

```gdscript
"log": [
	"............", "............", ".........kk.", ".......kkyok", ".....kknnkyk", "...kknnhhnkk",
	".kknnhhnnhk.", "kyokhnnhhk..", "kywkkhnnk...", "kook.kkk....", ".kk.........", "............",
],
"coal": [
	"............", "....kkk.....", "..kkdgdkk...", ".kdglgddgk..", ".kglddroddk.", "kdgdroyrdgdk",
	"kgddryyodddk", "kddgdrodgddk", ".kdddddddgk.", "..kkddddkk..", "....kkkk....", "............",
],
"smoke": [
	"............", ".....kkk....", "....kllgk...", "..kkllggk...", ".kllgggk....", ".klgggkkkk..",
	"..kggklllgk.", "...kkllgggk.", "..kllggggk..", ".klggddkk...", "..kkkkk.....", "............",
],
"lizard": [
	"............", "............", "..........k.", "..kkk....kok", ".kyyokkkkkok", "kWkyoooooook",
	"kyyoooRooook", ".kkookkkookk", "..kok..kok..", "..kkk..kkk..", "............", "............",
],
"coin": [
	"....kkkk....", "..kkyyyykk..", ".kywwyyyyok.", ".kwykkkkyok.", "kyyk.yo.kyok", "kyyky..ykyok",
	"kyykoyyokyok", "kyyk.yo.kook", ".kyykkkkook.", ".kooyyyoook.", "..kkoooork..", "....kkkk....",
],
"fang": [
	"............", ".kkkkkkkkkk.", "kRrrrrrrrrRk", "kkWkkWWkkWkk", ".kWk.kWk.kWk", ".kWk.kWk.kk.",
	"..kk.kWk....", ".....kWk....", "......k.....", "............", "............", "............",
],
```
`coin` pasa a ser un sprite propio (quitar `"coin": ["ember", {}]` de `VARIANTS`): moneda de Ascua con agujero y llama
grabada, distinta de `ember` (bola) y `orb`. Las variantes `choke`, `wet_ash`, `breath` heredan el nuevo contorno de `smoke`.

---

## 4. Lo que NO hay que hacer

1. **No escalar más sprites para "darles presencia".** Cada ×7/×8 nuevo es otra escala de píxel. Redibujar al tamaño.
2. **No añadir más tramado Bayer.** Ya es la fuente principal de ruido (acto 3, boca del horno, papel de cartas, luz de
   antorchas). El tramado es para transiciones grandes y lentas, no para relleno.
3. **No meter shaders de bloom/CRT/aberración cromática** para "dar ambiente" antes de arreglar valores y escala:
   tapan los problemas y hacen la UI ilegible.
4. **No subir la complejidad procedural** (más reglas, más semillas) esperando que salgan criaturas diseñadas: la
   procedura sirve para variar un diseño, no para inventarlo. Diseñar primero, variar después.
5. **No mezclar imágenes externas de alta resolución, ilustraciones IA o fuentes vectoriales nuevas** con el pixel art;
   el juego debe seguir siendo 100 % pixel en rejilla de arte (y versionable en ASCII, que es una virtud del proyecto).
6. **No poner temblor aleatorio simétrico** ni rotaciones en cada golpe: dirección, hitstop y retorno con rebote.
7. **No recolorear para crear actos o cartas "nuevos"**: el recoloreo vale para variantes menores (élite/ciclo), no para
   identidad de acto, tipo de carta o jefe.
8. **No llenar el suelo vacío con UI**: el suelo es el escenario; la mano debe ocupar menos alto (cartas ×2 a 75×105 ya son
   grandes, bajar la mano 40 px y mostrarla completa sólo en hover).
9. **No animar todo a la vez** (estandartes, cadenas, polvo, antorchas, monstruos respirando, intención botando): elegir
   2–3 cosas vivas por pantalla; el resto quieto para que el movimiento comunique.
10. **No tocar la paleta `PAL` de raíz**: está bien. Ampliarla con 4–6 tonos de hue-shift (sombras violetas/azules, luces
    amarillas) y documentarlos en `ART_BIBLE.md`.

---

### Anexo — Herramientas de revisión creadas (no tocan el juego)
- `tests/_review_art/export.tscn` — exporta monstruos ×6 por bioma, semillas, iconos ×6 y ×2, heroína, marcos, ilustraciones,
  fondos ×2, horno ×10, orbe.
- `tests/_review_art/anim.tscn` — tiras de fotogramas de `swing`, golpe recibido, embestida, quemar y muerte.
- `tests/_review_art/proposals.tscn`, `mon_render.tscn`, `icon_render.tscn` — renderizan las propuestas ASCII de este documento
  con la paleta real (`monsters_src.txt`, `icons_src.txt`) y validan anchos de fila.
