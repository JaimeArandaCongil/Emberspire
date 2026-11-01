# EMBERSPIRE v0.4 — Cartas e interfaz: propuesta del artista de cartas e interfaz

> Rol: artista senior de cartas e interfaz pixel. Referentes: Slay the Spire (lectura de la carta), Inscryption (la carta
> como objeto físico), Monster Train (marcos por clan), Balatro (texto pixel a otra escala que el arte, *juice*),
> Wildfrost (ilustración a sangre), Loop Hero (interfaz de hierro y pergamino), Shovel Knight (menús como escenas).
>
> Prueba de concepto real: `tests/_review_art/v04/cartas_ui/` (scripts Godot → `out/*.png`). Se ejecuta con
> `bash tests/_review_art/v04/cartas_ui/run.sh [gen.gd|kit_gen.gd|map_gen.gd]` (headless, ~10 s cada uno).

---

## 0. Posiciones firmes (para el debate)

1. **Cada carta tiene una ilustración propia, compuesta como una escena**, no un icono sobre bandas. 90 cartas = 90 escenas.
   Se hacen por código con una gramática (fondo + luz + sujeto + FX + encuadre), no con 90 dibujos sueltos.
2. **La carta crece a 80×112 nativos (×2 → 160×224)** y la ventana de ilustración pasa de 60×30 a **68×46** (+74 % de área).
   El formato 2:1 actual sólo admite iconos; 3:2 admite escenas.
3. **El texto del cuerpo deja de usar la fuente lisa con antialiasing.** Usa "Pavesa", una variante alta (6×9) de la fuente
   pixel del juego dibujada a **×1 de pantalla**. El arte vive en la rejilla ×2 y el texto en la ×1: es la misma
   convención que Balatro y Loop Hero, y es la única forma de que quepan ~20 caracteres por línea sin perder el aspecto pixel.
   La fuente lisa queda sólo como opción de accesibilidad.
4. **Toda la interfaz se construye con piezas 9-slice dibujadas a mano y TESELADAS** (piedra, hierro, pergamino, botón de
   forja). Se acaba `StyleBoxFlat` con borde liso: es lo que hace que la Forja parezca una hoja de cálculo.
5. **Las pantallas de transición son lugares, no formularios**: el mapa es la Torre en corte que se sube piso a piso;
   la tienda tiene un mercader; el evento es una escena con texto en pergamino; la Forja es un taller con los generadores
   como objetos físicos. Los datos densos se conservan, pero en paneles laterales y tooltips.
6. **La silueta de la ventana cambia con el tipo de carta** (filo, escudo, capilla, boca de horno, mordida) para que el
   tipo se lea en escala de grises y para jugadores daltónicos, no sólo por color.

---

## 1. Crítica pantalla a pantalla

### 1.1 La carta (`23_cards.png`, `07_combat.png`, `19_shop.png`)

| Problema | Evidencia | Gravedad |
|---|---|---|
| **Ilustraciones intercambiables.** `card_art()` pinta 3 bandas de color por tipo + un halo + un icono 12×12 ampliado con EPX. `flame_sword` es `sword` recoloreado (`art.gd` l. 407), `corona` es `sun` recoloreado (l. 416). Golpe y Tajo Ígneo son la misma imagen con otra paleta; Golpe de Escudo y Embestida Blindada comparten icono `shield_bash`; cinco cartas usan `anvil`, cuatro `hammer`, cuatro `flame`, tres `volcano`, tres `sparks`. | `23_cards.png`: Golpe/Tajo Ígneo/Piroclasto/Cañón comparten fondo idéntico | Crítica |
| Ventana de 60×30 (2:1): no cabe una escena, sólo un objeto centrado. El icono ampliado ×2 con EPX produce bordes redondeados "de filtro" que no casan con el pixel art a mano del resto. | todas | Alta |
| **Texto del cuerpo en fuente lisa con antialiasing** a 11–13 px sobre un marco pixel ×2: dos densidades de píxel y un suavizado que delata "UI de prototipo". El nombre cambia de fuente pixel a lisa según la longitud (Cañón de Ascuas, Embestida Blindada cortada a "mbestida Blindad"). | `19_shop.png` 3.ª carta | Alta |
| El pergamino ocupa el 42 % de la carta para una línea de texto ("Inflige 7 de daño."); la ilustración, el 17 %. La jerarquía está invertida. | `23_cards.png` | Alta |
| Marcos por tipo = sólo cambio de color de una banda plana de 3 px. Rareza = un rombo de 5×5 px que nadie ve. La rara (Corona Solar) apenas se distingue de la común. | `23_cards.png` | Media |
| Maestría = puntitos sueltos sobre el borde; Temple no se ve en la carta (sólo en la Forja). Mejorada = nombre amarillo + "+". | `23_cards.png` | Media |
| La carta en la mano está cortada por el borde inferior (y 560→720): el texto queda fuera de pantalla. El "CLIC DCHO: QUEMAR" flota en texto pequeño bajo la carta. | `07_combat.png`, `08_combat_hover.png` | Alta |
| El orbe de coste es una esfera genérica; no habla del mundo (energía = calor). | todas | Baja |

### 1.2 Título (`01_title.png`)
Buena base (heroína, horno, muro), pero el logotipo es un texto pixel con degradado plano y sin silueta (ni torre, ni
llama, ni grieta); los botones son rectángulos marrones con borde liso. No hay movimiento salvo pavesas. Nada anuncia
"torre": la heroína está en un sótano.

### 1.3 Forja (`02_forge.png`, `03_forge_archive.png`, `04_forge_chronicle.png`)
**Es una hoja de cálculo**: tres columnas de filas idénticas (icono 12×12 + nombre + número + botón con número). El horno,
que es el corazón emocional del juego, ocupa una columna estrecha a la izquierda con un desglose de multiplicadores en
texto debajo. Los generadores (Chispa, Fuelle, Horno, Crisol, Alto Horno, Sol Enano, Corazón del Mundo) son objetos
maravillosos que no existen visualmente: comprar el 50.º Fuelle no cambia nada en pantalla. Cinco pestañas con estilo de
navegador. El Reliquario es una rejilla de siluetas grises de 12×12 sin marco.

### 1.4 Antesala (`05_antesala.png`)
Tres paneles de formulario con listas de botones planos. Los Pactos de Brasa (decisión de riesgo, emocionante) se
presentan como checkboxes. La Fogonera aparece como retrato estático junto a una ficha de estadísticas.

### 1.5 Mapa (`06_map.png`)
Una columna de botones "Piso 1…6" a la izquierda y dos rectángulos con una espada idéntica dentro. **No hay torre, no hay
subida, no hay espacio.** El muro de fondo es el mismo del combate, oscurecido. Las puertas de combate y élite sólo se
distinguen por el texto. La heroína es un sprite diminuto flotando junto a "Base".

### 1.6 Tienda (`19_shop.png`)
Cartas en fila + tres cajas de servicio iguales. "Yunque Errante" es sólo un título; no hay mercader ni yunque. Los
precios son botones con número: no hay ascuas físicas, ni bolsa, ni mostrador.

### 1.7 Evento (`21_event_forge_spirit.png`)
Una caja morada centrada sobre el combate con un icono de horno 12×12 ampliado, el texto y dos botones a lo ancho.
"Una figura de humo con tu misma cara" no se ve: es la mejor línea de texto del juego y no tiene imagen.

### 1.8 Recompensas y resumen (`13_rewards.png`, `15_boss_relics.png`, `22_summary.png`)
Recompensas: correcto en estructura, pobre en ceremonia (las cartas aparecen sin entrada, la reliquia de jefe es una
caja marrón). Resumen: lista de 7 filas icono-texto-número sobre el fondo oscurecido; el texto rojo del pie se solapa con
partículas.

### 1.9 Hoguera (`20_rest.png`)
La mejor composición actual (heroína + hoguera en el mundo), pero las tres opciones son cajas marrones planas que tapan
el suelo y a la propia heroína.

---

## 2. Sistema de interfaz pixel

### 2.1 Rejillas y escalas
| Capa | Rejilla | Lienzo lógico | Uso |
|---|---|---|---|
| Mundo | ×4 | 320×180 | fondos, luchadores, escenas de mapa/tienda/evento |
| Interfaz y cartas | ×2 | 640×360 | marcos, paneles, iconos, títulos (fuente "Fragua") |
| Texto de cuerpo | ×1 | 1280×720 | descripciones, tooltips, cifras largas (fuente "Pavesa") |

Regla dura: **nada se escala por un factor no entero, nada se rota salvo cartas en vuelo** (y éstas sólo durante
≤ 200 ms de animación, nunca en reposo).

### 2.2 Kit 9-slice (dibujado a mano por código, ver `ui_kit.gd`, `out/ui_kit_x2.png`)
| Pieza | Nativo | Margen | Material | Uso |
|---|---|---|---|---|
| `stone` | 24×24 | 8 | sillares biselados de la Torre, centro liso oscuro | paneles grandes (mapa, Antesala, resumen) |
| `iron` | 16×16 | 5 | chapa con remaches y doble bisel, tintable | HUD, tooltip, ranuras de reliquia, pestaña de contenido |
| `parchment` | 16×16 | 5 | papel con borde tostado tramado | eventos, descripciones largas, Crónica |
| `button` ×4 estados | 20×14 | 6 | hierro lacado con canto inferior de 1 px (grosor) | todos los botones |
| `tab` activa/inactiva | 16×12 | 5 | activa se funde con el panel, inactiva hundida | pestañas de la Forja |
| `bar` | ancho×7 | 2 | marco de hierro, relleno con luz superior y sombra inferior | vida, bloqueo, calor, progreso de Maestría |

**Teselado, no estirado**: `UI_Kit.nine()` repite el patrón del borde. En Godot: `NinePatchRect` con
`axis_stretch_horizontal = AXIS_STRETCH_MODE_TILE_FIT` o `StyleBoxTexture` con `axis_stretch_* = TILE_FIT`, textura
importada sin filtro. Cada pieza se genera en `art.gd` → `ImageTexture`, se cachea y se envuelve en `StyleBoxTexture`
dentro de `UI.build_theme()`: **todas las pantallas actuales heredan el cambio sin tocar su lógica.**

### 2.3 Estados
| Estado | Botón | Carta | Pestaña |
|---|---|---|---|
| Normal | lacado marrón, bisel claro arriba | marco quieto | hundida, texto `#a08878` |
| Hover | borde `#ff6a1a`, brillo `#ffe08a` punteado arriba, texto `#ffe08a`; 2 px hacia arriba | sube 12 px, se endereza, sombra 4 px, *tilt* 0 | brillo superior |
| Pulsado | se hunde 1 px (desaparece el canto inferior), cara más oscura, 60 ms | — | — |
| Deshabilitado | gris frío `#2e2a30`, sin brillo, texto `#6a5a58` | orbe de coste gris, ilustración desaturada 50 % (trama) | — |
| Foco (mando) | marco de 1 px parpadeante `#ffe08a` 2 Hz | idem hover | idem |

### 2.4 Tipografía
- **Fragua** (actual `PixelFont` 5×7, contorno horneado): títulos, nombres de carta, cifras de combate. Sólo a ×2/×3/×4.
- **Pavesa** (nueva, 6×9 derivada de Fragua duplicando filas 2 y 6 y la columna 1; implementada en `px.gd::glyph(tall)`):
  cuerpo de carta, tooltips, paneles. A ×1. Interlínea 12 px. ~20 caracteres por línea en la carta.
  Para la versión de juego: generar una `FontFile` igual que `PixelFont.font()` pero con estos glifos, y que
  `UI.label()` la use para tamaños < 20 en lugar de la fuente del sistema.
- Énfasis: los números van en **falsa negrita** (doble trazo con 1 px de desfase) y color; los valores mejorados en verde
  `#1e7a1e` sobre pergamino. Palabras clave en rojo óxido `#8a1a0a` y con tooltip.
- Jerarquía: título de pantalla Fragua ×4 → título de panel Fragua ×2 ámbar `#ffb43a` → cuerpo Pavesa `#f4e4c8` →
  secundario Pavesa `#a08878`.

### 2.5 Color de interfaz
Una sola rampa de "hierro caliente" para la UI (`#1a0f12` contorno, `#221a20`/`#2e2830` chapa, `#5a4040` canto,
`#8a4a2a` latón, `#ff6a1a`/`#ffb43a`/`#ffe08a` interacción). El azul `#8ab4d0` sólo para bloqueo/frío, el violeta
`#b07ae0`/`#d0a8ff` sólo para lo estelar (Polvo, Resonancias, Maestría máx.), el verde sólo para mejoras. Hoy el violeta
se usa a la vez para Resonancias, eventos y botones de Antesala: se diluye.

### 2.6 Monedas e iconos
- **Ascua** (moneda): no una moneda dorada sino una brasa facetada 9×9 (`ui_kit.gd::ember_icon`) que late (2 fotogramas,
  0,6 s) y, al ganar, salta desde la fuente hacia el contador del HUD (arco de 300 ms, 1 partícula por cada 5 % del
  total, máx. 12).
- **Iconos de estado/intención** a 9×9 nativos (×2 = 18 px) con contorno `#0e070a` y 3 tonos + brillo; los de reliquia a
  16×16 dentro de una ranura de hierro. Hoy son 12×12 escalados ×3 (36 px), demasiado grandes y vacíos.
- Intenciones: forma + número, nunca sólo color: espada (ataque), escudo (defensa), calavera (fuerte), espiral (debilita),
  llama (quemadura), ojo (desconocido).

---

## 3. La carta v0.4

### 3.1 Anatomía (nativo 80×112, ver `out/cards_zoom.png`)
```
 (−5,−5) orbe de coste octogonal 17×17 (ascua tallada, cifra Fragua ×1 nativo)
 y 0      contorno 1 px #1a0f12
 y 1–4    canto de material (bisel claro arriba/izq., oscuro abajo/der.), remaches 2×2 en esquinas
 y 5–15   placa del nombre (achaflanada), nombre Fragua a ×1 nativo si ≤ 66 px; si no, Pavesa a ×1 de pantalla
 y 17–62  VENTANA DE ILUSTRACIÓN 68×46, silueta por tipo, marco de 1 px negro + bisel interno
 y 62–68  cinta del tipo (con colas en muesca), texto en versalitas ×1 de pantalla
 y 70–105 pergamino 68×36 (64×32 útiles a ×2 = 128×64 px de pantalla: 5 líneas de Pavesa)
 y 106–111 canto inferior: 5 muescas de Maestría (izq.), gema de rareza (centro), sello de Temple (der.)
```
En pantalla: 160×224 (antes 150×210). La mano debe subir 40 px (la carta en reposo enseña nombre + ilustración + 2
líneas; al hover sube entera). Si el combate necesita sitio, la alternativa es la carta "mini" 56×78 para pilas/visor de
mazo, con la misma ilustración reducida por código (no reescalada: reencuadrada).

### 3.2 Marcos por tipo (material + silueta de ventana)
| Tipo | Material del canto | Silueta de la ventana | Placa |
|---|---|---|---|
| Ataque | hierro lacado rojo óxido, remaches | **filo**: chaflán arriba, V suave abajo | rojo casi negro |
| Habilidad | acero azulado | **escudo**: esquinas redondas, base en arco | azul noche |
| Poder | latón dorado con punteado de filigrana | **capilla**: arco de medio punto | violeta oscuro |
| Combustible | ladrillo refractario con juntas | **boca de horno**: arco rebajado | hollín |
| Estado | piedra de ceniza agrietada | **mordida**: borde superior roto | gris |

### 3.3 Rareza
Inicial/común: canto liso, gema de piedra. Poco común: trazo plateado `#c8d4e4` en el canto interior + gema azul.
Rara: trazo dorado `#ffd84a` + remaches dorados + gema roja grande con dos destellos + **brillo animado** (banda
diagonal de 8 px que recorre el marco cada 4 s, 6 fotogramas a 12 fps, nunca sobre el texto; `out/anim_rare_shimmer.png`).

### 3.4 Mejorada (`out/card_states_x2.png`, 1.ª)
Canto superior/izquierdo al rojo `#ffe08a`, costura incandescente bajo la ventana, placa del nombre bronce, nombre en
`#ffe08a` con "+", pergamino 18 % más cálido, orbe con 4 chispas en los vértices y **los números cambiados en verde**.
Al mejorarse en combate: destello blanco 2 fotogramas + martillazo (shake 2 px, 80 ms).

### 3.5 Maestría y Temple (`card_states_x2.png`, 2.ª y 3.ª)
- Maestría: 5 muescas talladas en el canto inferior izquierdo; cada nivel enciende una (ámbar). En nivel 5 todas pasan a
  violeta `#ff8ad8` y el contorno exterior gana 1 px de brillo violeta que respira (0,4→0,8 alfa, 2 s).
- Temple: sello 6×6 a la derecha del canto inferior. **Filo** = hoja plateada; **Brasa** = carbón encendido;
  **Fragua** = yunque; **Rescoldo** = llama que vuelve. Además, Filo añade un hilo plateado en el canto izquierdo y Brasa
  dos ascuas en las esquinas inferiores del pergamino. Tooltip con la regla.

### 3.6 "Quemable" y "en caliente" (`card_states_x2.png` 3.ª y 5.ª, `anim_burnable.png`)
- **Quemable** (hay Quemas y la carta se puede quemar): aura exterior de 2–4 px en `#ff6a1a`/`#ffb43a`, tramada, que
  lame hacia arriba; 4 fotogramas a 8 fps. Sustituye al recuadro `_glow` actual y al texto "CLIC DCHO".
- **En caliente** (Mayús pulsada): aura blanca-amarilla `#fff4c8`, pavesas que suben de la carta, el orbe muestra el coste
  de energía del quemado en caliente.
- **No quemable** (Ceniza Húmeda): marco de piedra con gotas, ventana desaturada, sello "✕" de hielo.

### 3.7 Animaciones de carta (tiempos)
| Acción | Detalle | Duración |
|---|---|---|
| Robar | sale del mazo como dorso 15×21, gira en Y (escala X 1→0→1) a mitad de trayecto, entra en la mano con *overshoot* 4 px | 220 ms, 40 ms de escalonado entre cartas |
| Hover | sube 24 px, se endereza, escala ×1 (nunca fraccionaria: se cambia el sprite a la versión grande si hace falta), sombra de 4 px | 90 ms |
| Jugar | sube 40 px, pausa 60 ms, vuela al objetivo (ataque) o al centro (habilidad/poder) y se disuelve con el shader actual | 300 ms |
| Quemar | cae hacia el horno de combate con rastro de pavesas; al llegar, `burn_away` (disolución de abajo arriba) + llamarada del horno | 450 ms |
| Quemar en caliente | igual + destello blanco de 2 fotogramas, *hitstop* 60 ms, sacudida 3 px | 520 ms |
| Brillo de rara | ver 3.3 | 500 ms cada 4 s |
| Maestría sube | la muesca se enciende con 3 chispas; número en verde flota | 300 ms |
| Ilustraciones | capa "viva" opcional por carta: 2–4 fotogramas de FX (pavesas, llama, humo) dentro de la ventana | 6–8 fps |

---

## 4. Producción de ~90 ilustraciones únicas por código

### 4.1 Gramática de ilustración (implementada en `illus.gd`)
Toda ilustración = **FONDO** (decorado reutilizable) + **LUZ** (fuente, color y caída) + **SUJETO** (sprite ASCII a mano o
primitiva) + **FX** (estela, chispas, humo, aura) + **ENCUADRE** (máscara de la ventana por tipo).

Reglas de composición:
1. **Una sola fuente de luz clave por escena**, motivada (antorcha, impacto, horno, sol). Su posición la decide el FX.
2. **Sujeto en tercios, nunca centrado salvo en Poderes** (que son emblemas: simetría deliberada).
3. **Encuadre**: plano corto para ataques (acción), plano medio para habilidades (gesto), plano general para poderes
   (lugar), bodegón para combustibles (objeto en el horno).
4. **Paletas cortas con desplazamiento de tono**: sombras hacia violeta/azul, luces hacia amarillo. 5–7 colores por rampa.
5. **Trama sólo en transiciones** (`ramp_pick` con `dz` 0,3–0,5); zonas planas para que el ojo descanse.
6. **Silueta legible a 68×46 y a 34×23** (prueba de miniatura obligatoria en la hoja de revisión).
7. Contorno exterior `#0e070a` sólo en el sujeto; el fondo nunca lleva contorno (separa planos).

### 4.2 Decorados reutilizables (FONDOS) — 12
| Id | Descripción | Cartas que lo usan |
|---|---|---|
| `wall_hollin` | muro de ladrillo de la Torre con luz puntual | ataques básicos, Base |
| `forge_red` | fragua en penumbra roja con pilares a contraluz | ataques de fuego |
| `furnace_mouth` | boca de horno con dovelas radiales, lecho y rejilla | todos los Combustibles |
| `ash_plain` | llanura de ceniza con la Torre lejana y cielo de poniente | Solar, Poderes de lugar |
| `anvil_shop` | taller: yunque, banco, herramientas colgadas | Yunque |
| `alchemy` | laboratorio: alambiques, estantes, luz verdosa | Crisol |
| `pyre_altar` | pira ritual con brasas y huesos | Pira |
| `ash_storm` | tormenta de ceniza y brasas al viento | Ceniza |
| `night_sky` | cielo estrellado violeta | Solar nocturnas, Polvo Estelar |
| `forge_hall` | sala de la Forja con braseros (conecta con el idle) | Grimorio de la Forja |
| `slag_cave` | cueva de escoria verde-violeta (acto 2) | Escoria, debuffs |
| `frost_hall` | sala helada (acto 3) | Estados, Escarcha |

### 4.3 Sujetos reutilizables (kit) — ~35 sprites base
Espada, mandoble, martillo, mazo, yunque, escudo, escudo de púas, hacha, atizador, fuelle, tenazas, carbón, leña, pólvora,
pluma, fénix, salamandra, sol, luna, estrella, gema, frasco, lingote, campana, libro, cofre, brasero, engranaje, la
Fogonera (busto, mano, silueta), gólem, limo, urraca (sacados de `enemy_db` para "víctimas" de ataques).
**Variación** = misma pieza con otra pose (ángulo 45°/2:1/vertical), otra luz y otro FX, o combinada con otra
(martillo + yunque + chispas ≠ martillo + gólem).

### 4.4 Cómo se distinguen las que comparten base
- Golpe vs Tajo Ígneo (prueba de concepto): misma espada; Golpe = hierro frío a 45° contra un gólem, muro de
  ladrillo, luz blanca del impacto; Tajo Ígneo = hoja al rojo con media luna de fuego, fragua roja, quemadura en el suelo.
- Martillazo / Golpe Abrasador / Ráfaga de Martillo: un golpe vertical con onda de choque / martillo al rojo con
  marca humeante / tres martillos fantasma en abanico (estroboscopio).
- Defensa / Guardia de Ascuas / Guarda del Yunque: escudo levantado / escudo con brasas que se desprenden / escudo apoyado
  en el yunque con la llama "guardada" (Brasa = retener).
- Carbón / Rescoldo / Flujo Áureo: hulla en la rejilla / brasa bajo ceniza que respira / lingote fundiéndose en oro.

### 4.5 Coste por ilustración (medido en la prueba de concepto)
Las cuatro ilustraciones costaron ~150–200 líneas cada una *incluyendo* los fondos y utilidades. Con el kit de fondos y
sujetos hecho, una carta nueva = elegir fondo (1 línea), luz (2–3), sujeto (sprite ASCII 10–30 filas o reutilizado),
FX (5–20) ≈ **40–80 líneas y 45–90 min** con revisión ampliada. Las 90: ~70–100 h.

### 4.6 Concepto de ilustración de CADA carta de `card_db.gd`
Leyenda de encuadre: **PC** plano corto, **PM** plano medio, **PG** plano general, **B** bodegón, **E** emblema.

| id | Carta | Fondo | Encuadre · concepto | Luz / FX |
|---|---|---|---|---|
| strike | Golpe | wall_hollin | PC · espada de hierro a 45° entra en el hombro de un Gólem de Hollín | chispazo blanco del impacto, lascas de piedra **(hecho)** |
| defend | Defensa | wall_hollin | PM · la Fogonera tras un escudo redondo; una garra rebota | destello azul en el umbo, chispas frías |
| kindling | Leña | furnace_mouth | B · haz de leña atado sobre la rejilla, la corteza empieza a prender | lengua pequeña en un extremo |
| ember_slash | Tajo Ígneo | forge_red | PC · hoja al rojo con media luna de fuego | la llama ilumina todo **(hecho)** |
| heavy_hammer | Martillazo | wall_hollin | PC · martillo cayendo en vertical, onda de choque en el suelo agrietado | polvo y anillo de impacto |
| sparks | Lluvia de Chispas | forge_red | PG · tres enemigos pequeños bajo una lluvia de chispas desde arriba | puntos brillantes en diagonales |
| cleave | Barrido | wall_hollin | PC · hacha en barrido horizontal que corta tres siluetas | estela ancha horizontal |
| iron_wall | Muro de Hierro | anvil_shop | PM · placas de hierro que se encajan formando una muralla delante de la heroína | remaches que brillan uno a uno |
| quench | Enfriar | anvil_shop | B · hoja al rojo sumergida en cubo de agua, gran nube de vapor | vapor blanco tramado, gota azul |
| bellows | Fuelle | furnace_mouth | B · fuelle de cuero insuflando, las llamas se inclinan | líneas de viento |
| stoke | Avivar | furnace_mouth | PC · atizador removiendo brasas que se encienden | brasa estallando hacia arriba |
| coal | Carbón | furnace_mouth | B · hulla facetada sobre la rejilla, grietas encendidas | lecho de brasas, humo violáceo **(hecho)** |
| smother | Sofocar | slag_cave | PM · capa de ceniza cae sobre la cabeza de un enemigo, ojos apagándose | humo gris |
| forge_heart | Corazón de Forja | forge_hall | E · corazón de hierro con engranajes latiendo dentro de un horno | brillo rítmico |
| temper_steel | Templar el Acero | anvil_shop | PC · el brazo de la Fogonera alza el martillo sobre una hoja en el yunque | chispa cenital |
| slag_shot | Escupir Escoria | slag_cave | PM · gota de escoria verde volando hacia un enemigo | rastro verde viscoso |
| body_slam | Embestida Blindada | wall_hollin | PC · escudo en primer plano embistiendo, el enemigo sale despedido | líneas de velocidad |
| second_wind | Segundo Aliento | pyre_altar | PM · la Fogonera arrodillada inspira, el aire se vuelve dorado | motas cálidas ascendiendo |
| twin_strike | Doble Tajo | wall_hollin | PC · dos estelas en X sobre un enemigo | dos destellos |
| shield_bash | Golpe de Escudo | wall_hollin | PC · canto del escudo contra una mandíbula, dientes saltando | chispazo |
| ember_guard | Guardia de Ascuas | forge_red | PM · escudo del que se desprenden brasas al recibir un golpe | brasas cayendo |
| fan_flames | Abanicar | furnace_mouth | B · abanico de hierro avivando una llama que crece | ondas de calor |
| spitfire | Escupefuego | forge_red | PC · pequeño dragón-fuelle escupe una lengua de fuego | chorro de fuego |
| searing_blow | Golpe Abrasador | anvil_shop | PC · martillo al rojo deja una marca humeante en placa enemiga | marca incandescente |
| brace | Apuntalar | wall_hollin | PM · la Fogonera apuntala un escudo con el hombro, pies clavados | polvo en el suelo |
| fire_wall | Muro de Fuego | ash_storm | PG · cortina de llamas entre la heroína y una horda | llama en 3 alturas |
| smelt | Fundir | alchemy | B · crisol volcando metal fundido en un molde | chorro brillante |
| rally | Cántico de Forja | forge_hall | E · campana de bronce vibrando, ondas sonoras en anillos | anillos concéntricos |
| fireborn | Hija del Fuego | pyre_altar | E · la Fogonera de pie dentro de un fénix de llamas (pose heroica) | aura rara |
| anvil_drop | Caída del Yunque | wall_hollin | PC · yunque cayendo desde arriba sobre un enemigo encogido | sombra creciente en el suelo |
| inner_fire | Fuego Interior | pyre_altar | E · silueta de la Fogonera con una llama en el pecho | rayos internos |
| ash_armor | Armadura de Ceniza | ash_storm | PM · placas de ceniza endurecida formándose sobre su brazo | partículas que se adhieren |
| gunpowder | Pólvora | furnace_mouth | B · barril de pólvora con mecha encendida sobre la rejilla | chispa de la mecha |
| pyre_dance | Danza de la Pira | pyre_altar | PM · la Fogonera girando con la espada, espiral de cartas ardiendo | espiral de fuego |
| open_flue | Tiro Abierto | forge_hall | B · trampilla de la chimenea abriéndose, columna de aire | corriente ascendente |
| phoenix_feather | Pluma de Fénix | furnace_mouth | B · pluma roja-dorada sobre la rejilla, no se quema | brillo propio |
| rake_coals | Atizar | furnace_mouth | PC · rastrillo atizando, tres brasas saltan (3 cartas) | arcos de brasas |
| kiln | Horno de Tiro | forge_hall | E · horno de botella con tiro abierto | humo en columna |
| bonfire | Hoguera Viva | furnace_mouth | B · leños cruzados con una hoguera con cara amable | llamas en 3 capas |
| phoenix_paper | Fénix de Papel | pyre_altar | PM · un fénix de origami renace de una carta quemada | borde de papel encendido |
| pyroclasm | Piroclasto | ash_plain | PG · volcán erupcionando, bombas de lava sobre la llanura | lluvia de bombas |
| stoke_rage | Atizar la Furia | pyre_altar | PC · mano que sangra sobre las brasas, que se vuelven carmesí | llama roja oscura |
| ash_feast | Banquete de Ceniza | pyre_altar | B · copa de hierro llena de brasas líquidas | vapor dorado |
| forge_lung | Pulmón de Forja | forge_hall | E · pulmón de cobre con fuelles en lugar de alvéolos | aire caliente |
| tinder_box | Caja de Yesca | furnace_mouth | B · caja abierta de la que saltan chispas vivas (fichas) | chispas con ojos |
| cinder_storm | Tormenta de Cisco | ash_storm | PG · remolino de cisco ardiendo en la sala | espiral tramada |
| anvil_stance | Postura de Yunque | anvil_shop | PM · la Fogonera en guardia baja, firme como un yunque (silueta compartida) | luz cenital dura |
| hammer_flurry | Ráfaga de Martillo | anvil_shop | PC · tres martillos fantasma en abanico (estroboscopio) | ecos semitransparentes (trama) |
| double_shield | Redoblar Escudo | wall_hollin | PM · dos escudos superpuestos, el segundo de luz | contorno luminoso |
| counterweight | Contrapeso | anvil_shop | B · pesa de hierro colgando de una cadena que equilibra una balanza | balanceo |
| molten_core | Núcleo Fundido | forge_red | E · esfera de metal fundido flotando, gotas orbitando | órbitas |
| heavy_blade | Mandoble | wall_hollin | PM · mandoble enorme clavado en el suelo, la Fogonera tirando de él | grietas |
| iron_skin | Piel de Hierro | anvil_shop | PC · antebrazo con remaches como piel | reflejo metálico |
| spiked_shield | Escudo de Púas | wall_hollin | PM · garra enemiga atravesada por las púas del escudo | gota de icor |
| parry | Desviar | wall_hollin | PC · dos hojas cruzándose, la enemiga sale desviada | chispa en el punto de contacto |
| sledge | Mazazo | wall_hollin | PC · mazo de dos manos impactando, cráter en el suelo | onda + rocas |
| unbreakable | Inquebrantable | wall_hollin | PG · fortaleza de escudos en anillo, la heroína dentro | luz dorada |
| anvil_ward | Guarda del Yunque | anvil_shop | PM · escudo apoyado en el yunque, una brasa "guardada" bajo él | brasa quieta |
| salamander | Salamandra | ash_storm | E · salamandra enroscada en una brasa, mirando a cámara | llama en la cola |
| wildfire | Incendio | ash_storm | PG · fuego extendiéndose por un suelo de hierba seca de ceniza | frente de llamas |
| detonate | Detonar | ash_storm | PC · enemigo envuelto en quemadura que estalla | explosión radial |
| cinder_breath | Aliento de Brasas | forge_red | PC · boca de horno con forma de dragón exhalando cisco | cono de brasas |
| smoke_veil | Velo de Humo | slag_cave | PM · cortina de humo; los enemigos tosen, ojos llorosos | humo tramado |
| kindle_brand | Marca Ígnea | anvil_shop | PC · hierro de marcar al rojo con la runa de la Fogonera | runa brillante |
| conflagration | Conflagración | ash_storm | PG · un fuego pequeño se duplica en espejo hasta ser dos | simetría |
| smoldering | Rescoldo | furnace_mouth | B · brasa bajo una capa de ceniza que respira | pulso naranja |
| ashen_shroud | Mortaja de Ceniza | ash_storm | PM · capa de ceniza envuelve a la heroína | jirones |
| firestorm | Tormenta de Fuego | ash_plain | PG · tornado de fuego sobre la llanura, la Torre al fondo | columna giratoria |
| flashpoint | Punto de Ignición | forge_red | PC · una sola chispa tocando una mecha, instante antes | punto blanco |
| supernova | Supernova | night_sky | E · estrella estallando en anillos | anillos + destello total |
| dwarf_star | Estrella Enana | forge_hall | E · pequeña estrella enjaulada en el horno (= generador Sol Enano) | luz blanca |
| sunforge | Forja Solar | ash_plain | PM · yunque bajo un rayo de sol concentrado por una lente | haz de luz |
| ember_rain | Lluvia de Ascuas | night_sky | PG · lluvia de ascuas cayendo de un cielo violeta | estelas verticales |
| corona | Corona Solar | ash_plain | E · el sol se alza con llamaradas en forma de corona | rayos alternos **(hecho)** |
| star_seed | Semilla Estelar | night_sky | B · semilla luminosa en la palma de una mano | brote de luz |
| eclipse | Eclipse | ash_plain | E · luna negra tapando el sol, corona fina | anillo de luz |
| solar_flare | Fulgor | ash_plain | PG · llamarada horizontal barriendo la llanura | onda de luz |
| brazier_flame | Llama de Brasero | forge_hall | PM · fila de braseros encendidos (los Braseros de la Forja) | llamas sincronizadas |
| gen_wall | Muralla de Engranajes | forge_hall | PM · engranajes de los generadores formando un muro | dientes encajando |
| stardust_strike | Golpe Estelar | night_sky | PC · espada con polvo estelar en el filo | estela violeta |
| dividend | Dividendo Ígneo | forge_hall | B · cofre de ascuas desbordándose | ascuas saltando |
| legacy | Legado | forge_hall | E · libro abierto con nombres grabados a fuego (Maestrías) | runas |
| ember_cannon | Cañón de Ascuas | forge_hall | PC · cañón de hierro alimentado por el horno disparando | fogonazo |
| hearth_song | Canción del Hogar | forge_hall | PM · campana de la Forja sonando, braseros respondiendo | notas como chispas |
| relic_echo | Eco del Reliquario | forge_hall | B · vitrina del Reliquario con reliquias resonando | anillos sobre cada reliquia |
| transmute | Transmutar | alchemy | B · frasco donde una carta se transforma en otra | humo verde |
| quicksilver | Azogue | alchemy | B · gota de mercurio rodando, refleja dos cartas | reflejo plateado |
| alloy | Aleación | alchemy | B · dos lingotes fundiéndose en uno | costura brillante |
| philosopher | Piedra Filosofal | alchemy | E · gema roja sobre un círculo alquímico | círculo brillante |
| retort | Alambique | alchemy | PM · alambique escupiendo gota hirviendo a un enemigo | burbujas |
| fuel_search | Buscar Combustible | furnace_mouth | PM · mano hurgando en el cajón de leña | polvo |
| golden_flux | Flujo Áureo | furnace_mouth | B · lingote fundiéndose en oro líquido sobre la rejilla | brillo dorado |
| elixir | Elixir Ígneo | alchemy | B · poción roja con una llama dentro | llama dentro del vidrio |
| reforge | Reforjar | anvil_shop | PC · espada rota soldándose en el yunque | chispas + costura |
| spark_card | Chispa Volátil | furnace_mouth | B · chispa con ojos, inestable | parpadeo |
| soot | Hollín | wall_hollin | B · montón de hollín con huellas de dedos | — (desaturada) |
| frost | Escarcha | frost_hall | B · cristal de escarcha creciendo sobre una carta | brillo frío |
| sodden_ash | Ceniza Empapada | frost_hall | B · ceniza mojada goteando, no prende | gotas |
| wet_ash | Ceniza Húmeda | frost_hall | B · charco de ceniza con vapor débil | vapor tramado |

*(93 entradas: 4 iniciales, 26 base, 16 Pira, 12 Yunque, 11 Ceniza, 8 Solar, 8 Forja, 9 Crisol, 1 ficha, 4 estados.)*

### 4.7 Integración técnica
- Nuevo `scripts/art/card_illus.gd` (no en `art.gd`, que ya tiene 2.567 líneas): `static func illus(id) -> Image`
  con `match id` → función por carta; utilidades de `px.gd` (ramp_pick, outline, sprite, mask, tint) en
  `scripts/art/px.gd`. Fondos en `scripts/art/card_backdrops.gd`.
- Campo nuevo en `card_db.gd`: `"art": "strike"` (por defecto = id) para que dos ids puedan compartir ilustración sólo
  si diseño lo decide explícitamente.
- Caché: generar las 93 al arrancar cuesta ~1,5 s (medido: 4 ilustraciones + marcos ≈ 60 ms). Generar perezosamente
  la primera vez que se ve cada carta y cachear en `user://art_cache/*.png` con hash del script.
- Test de regresión visual: `tests/_review_art/v04/cartas_ui/gen.gd` ampliado a "hoja de todas las cartas" (13×8) que
  se revisa en cada PR de arte, incluyendo una fila a ½ tamaño (prueba de silueta).

---

## 5. Pantallas como escenas vivas

### 5.1 Mapa: la Torre en corte (`out/map_mockup_1280x720.png`)
La Torre se ve **en sección**, 4 pisos en pantalla (44 px nativos cada uno a ×4):
- **Piso cruzado** (abajo): braseros encendidos (los Braseros de la Forja se ven aquí: conexión directa con el idle),
  la puerta usada abierta, montón de ceniza del enemigo, estandarte.
- **Piso actual**: la Fogonera junto a la escalera de caracol, antorcha.
- **Piso siguiente**: 2–4 puertas en arco **con placa emblemática** (espadas cruzadas, calavera con cuernos, hoguera,
  yunque, ojo) y la luz de su interior derramándose en el muro con el color del tipo. La élite asoma dos ojos. Hover: la
  puerta se ensancha 2 px, la placa se vuelve dorada, tooltip de hierro anclado con flecha.
- **Piso desconocido** (arriba): niebla tramada, "?" y un resplandor violeta si el jefe está cerca.
- Exterior: muro con contrafuertes iluminado por el poniente del acto, agujas lejanas con ventanas, ceniza cayendo.
- **Al elegir puerta**: la heroína sube la escalera (8 fotogramas de andar, 0,8 s), la cámara se desplaza 44×4 px hacia
  arriba con *ease-out* 0,6 s, la puerta elegida se abre (3 fotogramas) y fundido al combate. Al volver de un combate
  ganado, el piso se ilumina: los braseros se encienden uno tras otro (120 ms cada uno).
- Interfaz: estandarte del acto colgando (izq.), panel de piedra con la expedición (der.), rastro de pisos del acto abajo.
- Cada acto cambia el exterior (Hollín: poniente rojizo; Escoria: neblina verde, tuberías; Ceniza Helada: nieve, aurora).

### 5.2 Forja: el taller
Plano general del taller (mundo ×4) con el horno grande en el centro-izquierda. **Cada generador es un objeto que
aparece y se multiplica en la escena**: Chispa = enjambre de chispas que orbitan el horno (1 por cada 10, máx. 24);
Fuelle = fuelles en la pared que bombean al ritmo de la producción; Horno = hornos secundarios al fondo; Crisol = crisol
colgante que vierte; Alto Horno = torre de ladrillo al fondo a la derecha; Sol Enano = estrella en una jaula sobre el
horno; Corazón del Mundo = latido que hace vibrar el suelo. Las Resonancias (10/50/100) añaden un detalle visible al
objeto (anilla de latón, segunda boca, etc.).
La columna de compra se mantiene (densidad incremental) pero como **estantería de hierro** a la derecha con fichas de
generador (icono 16×16 propio, nombre Fragua, coste con brasa, barra de ×2). Las pestañas Arsenal/Grimorios/Archivo/
Crónica/Renacer son **objetos del taller** que abren paneles: armero, estantería de grimorios, vitrina del Reliquario,
libro de la Crónica, altar del Renacer. El botón "Ascender a la Torre" es la **puerta de la torre** en el fondo,
iluminada cuando puedes subir.

### 5.3 Antesala
El rellano previo a la primera puerta de la torre: la Fogonera de cuerpo entero preparándose; a la izquierda un
**armero** con sus Resonancias (dos versiones colgadas en ganchos; elegir = descolgar); en el centro un **brasero de
pactos**: cada Pacto es una tablilla que se echa al fuego y el fuego crece (el Calor se ve como altura de llama y color);
a la derecha un **cofre de herencia** abierto con las reliquias. El botón Ascender = abrir la puerta.

### 5.4 Tienda: el Yunque Errante
Un mercader (un herrero ambulante con un yunque a la espalda y la cara tiznada) tras un mostrador: cartas expuestas en
un tendedero con pinzas, reliquias en ganchos, servicios como herramientas (Fundir = crisol, Templar = martillo). Las
ascuas se pagan echándolas en la boca de su yunque-horno (animación de monedas-brasa). Diálogo en bocadillo de
pergamino. 4 fotogramas de idle del mercader + reacción al comprar.

### 5.5 Evento
Ilustración de evento 160×90 nativos a ×4 (media pantalla) con la escena descrita (la figura de humo con la cara de la
Fogonera), texto en pergamino debajo, opciones como **tiras de pergamino** con icono de coste a la izquierda. Una escena
por evento, con 2–3 capas animadas (humo, llama, parpadeo). Reutiliza los fondos del mundo del acto.

### 5.6 Título
La Torre vista desde la base, de noche, recortada contra un cielo de brasas; la Fogonera de espaldas frente a la puerta.
Logotipo nuevo: "EMBERSPIRE" en letras de hierro forjado con una grieta incandescente que recorre la palabra y una
aguja (la torre) como la "I". Opciones como **placas de hierro clavadas en la puerta**. Pavesas, ventana que se
enciende y apaga en lo alto de la torre, humo.

### 5.7 Resumen y recompensas
Resumen = los braseros nuevos encendiéndose uno a uno en el horno grande mientras las cifras suben (contador con ruido
de brasas), sin solapar partículas sobre texto. Recompensas = las cartas salen del cofre del enemigo boca abajo y se
voltean en abanico (80 ms de escalonado); la reliquia de jefe se presenta en un pedestal con luz cenital.

### 5.8 Legibilidad
Toda escena tiene una **zona tranquila** (valor bajo, poca textura) donde vive la información; los textos siempre sobre
pieza 9-slice; contraste mínimo 4,5:1 para cuerpo; nunca partículas por delante del texto (`z_index` de texto > FX).

---

## 6. Conexión con las demás áreas (mundo interconectado)
- **Forja ↔ Torre**: los Braseros encendidos en la Forja aparecen en los pisos cruzados del mapa; el Sol Enano comprado
  aparece en la carta Estrella Enana y en el fondo `forge_hall`; Llama de Brasero muestra tantos braseros como tengas
  (la ilustración puede leer `Game.max_floor` para variar el número: 1–7).
- **Cartas ↔ enemigos**: las "víctimas" de las ilustraciones de ataque son los enemigos reales del acto (gólem, limo,
  urraca) con su paleta: el artista de criaturas entrega los sprites, yo los reencuadro.
- **Cartas ↔ mundo**: los fondos de carta reutilizan materiales del mundo (ladrillo de la Torre, dovelas del horno);
  el artista del mundo y yo compartimos paletas (`PAL`/`BIOMES` → rampas de 6–7).
- **Carta ↔ combate**: al quemar, la carta vuela al horno de combate que ya existe; la llama del horno crece con la
  Maestría de la carta quemada (conexión con el VFX del artista técnico).
- **Heroína**: la Fogonera aparece en ~12 ilustraciones (busto, mano, silueta) con su paleta exacta (pelo `#c2321e`,
  diadema `#f4e4c8`, delantal `#8a5030`): coherencia con el artista de personajes.

## 7. Riesgos y lo que descarto
| Riesgo | Mitigación |
|---|---|
| 90 ilustraciones procedurales "parecidas entre sí" | gramática con 12 fondos × 5 encuadres × luces distintas; revisión en hoja de miniaturas; ningún par puede compartir fondo + encuadre + sujeto |
| Texto a ×1 demasiado pequeño en pantallas grandes | Pavesa 6×9 = cap 9 px a 720p (≈ al actual), escala entera a 1440p (×2); opción de fuente lisa |
| Carta más alta → mano tapa el combate | mano en reposo hundida 40 px; hover sube la carta entera |
| Coste de rendimiento al generar | caché perezosa en disco; ~15 ms por carta |
| Código de arte inmanejable | separar `art.gd` en módulos (`px`, `card_frame`, `card_illus`, `ui_kit`, `scenes`) |

**Descarto**: ilustraciones a sangre completa (rompe la lectura del texto en 160 px de ancho); rotación de cartas en
reposo en la mano (rompe la rejilla); texto del cuerpo a ×2 (12 caracteres por línea); una fuente lisa nueva "bonita";
marcos distintos por grimorio (demasiadas variantes: el grimorio va como pequeño sello en la cinta, no como marco).

## 8. Prueba de concepto: qué hay y qué demuestra
Scripts: `px.gd` (primitivas), `illus.gd` (4 ilustraciones + fondos/sujetos), `cards.gd` (marco, coste, texto rico),
`ui_kit.gd` (9-slice), `gen.gd`, `kit_gen.gd`, `map_gen.gd`, `run.sh`. Salida en `out/`:
| PNG | Demuestra |
|---|---|
| `cards_game_res.png` / `cards_zoom.png` | 4 cartas a resolución de juego y ×2: anatomía 80×112, 4 siluetas de ventana, marcos por tipo y rareza, orbe octogonal, texto Pavesa con números en negrita |
| `illustrations_x6.png` | 4 ilustraciones únicas 68×46: Golpe y Tajo Ígneo comparten espada y aun así son escenas distintas (fondo, luz, FX, ángulo) |
| `card_states_x2.png` | mejorada, Maestría 3 + Filo, quemable + Fragua, rara con brillo, en caliente + Rescoldo |
| `anim_rare_shimmer.png`, `anim_burnable.png` | fotogramas de las animaciones de rara y de "quemable" |
| `ui_kit_x2.png`, `ui_kit_x4.png` | piezas 9-slice nativas y compuestas por teselado: panel de piedra, tooltip de hierro, pergamino, 4 estados de botón, pestañas, barras, iconos de Ascua/vida/bloqueo |
| `map_mockup_1280x720.png` | el mapa como Torre en corte: pisos cruzado/actual/siguiente/desconocido, puertas con placa y luz, interfaz con el kit |

Limitaciones honestas: el mapa es un boceto (la heroína es una ficha de 9×14, no el sprite real; los interiores de las
puertas son planos); la Forja no está bocetada (prioricé el mapa porque hoy es la pantalla más pobre); las puertas aún
no tienen la luz "volumétrica" que tendrán con una capa aditiva.

## 9. Estimación por paquetes independientes
| # | Paquete | Depende de | Horas |
|---|---|---|---|
| P1 | Módulos `px.gd`, separación de `art.gd`, fuente Pavesa como `FontFile` y adopción en `UI.label/rich` | — | 10 |
| P2 | Marco de carta v0.4 (80×112, siluetas, rareza, mejorada, Maestría, Temple, orbe) + `card_view.gd` adaptado | P1 | 16 |
| P3 | Estados y animaciones de carta (quemable, en caliente, brillo de rara, robar/jugar/quemar con tiempos de §3.7) | P2 | 14 |
| P4 | Kit 9-slice como `StyleBoxTexture` en `UI.build_theme()` (todas las pantallas heredan) + iconos 9×9 | P1 | 12 |
| P5 | Fondos de ilustración (12) + sujetos base (~35) | P1 | 24 |
| P6 | 93 ilustraciones en 4 tandas (iniciales+base 30, Pira+Yunque 28, Ceniza+Solar 19, Forja+Crisol+fichas+estados 22) | P5 | 75 |
| P7 | Mapa: Torre en corte + subida animada + variantes por acto | P4 | 22 |
| P8 | Forja como taller con generadores visibles y estantería | P4 | 30 |
| P9 | Antesala, Tienda (mercader), Evento (escenas 160×90 por evento) | P4 | 28 (+3 por evento) |
| P10 | Título + logotipo de hierro forjado + resumen/recompensas | P4 | 14 |
| P11 | Hoja de regresión visual de todas las cartas y pantallas | P2, P6 | 5 |
| | **Total** | | **≈ 250 h** |

Orden recomendado: P1 → P2 → P4 (gran cambio visible con poco riesgo) → P5/P6 en paralelo con P7 → P3 → P8 → P9 → P10.

---

## Resumen (≤ 300 palabras)
La carta actual es un icono genérico 12×12 recoloreado sobre bandas (Golpe y Tajo Ígneo son la misma espada; Corona
Solar es el sol recoloreado) dentro de una ventana 60×30 que no admite escenas, con texto en fuente lisa antialiasada
que rompe el pixel art. La interfaz usa `StyleBoxFlat`: la Forja parece una hoja de cálculo y el mapa es una lista de
botones.

Propongo: carta de 80×112 nativos (×2) con ventana de 68×46 cuya silueta cambia por tipo; marcos de material (hierro
lacado, acero, latón, ladrillo, ceniza), rareza con trazo y brillo animado, mejorada al rojo, Maestría en muescas y
Temple como sello; texto en "Pavesa" 6×9 a ×1 de pantalla (como Balatro). 93 ilustraciones únicas por código con una
gramática fondo + luz + sujeto + FX + encuadre, 12 fondos y ~35 sujetos reutilizables; tabla con el concepto de cada
carta. Kit 9-slice teselado (piedra, hierro, pergamino, botón de 4 estados, pestañas, barras) aplicado vía tema para que
todas las pantallas lo hereden. Mapa como Torre en corte que se sube de verdad; Forja como taller donde cada generador
existe; Antesala con brasero de pactos; tienda con mercader; eventos con escena.

Prueba de concepto real (`tests/_review_art/v04/cartas_ui/`): 4 cartas nuevas con ilustración única, estados
(mejorada, Maestría + Temple, quemable, en caliente, rara), tiras de animación, kit 9-slice y boceto del mapa a 1280×720.

Estimación: ≈ 250 h en 11 paquetes; primero P1 (fuente y módulos), P2 (marco) y P4 (tema 9-slice).
