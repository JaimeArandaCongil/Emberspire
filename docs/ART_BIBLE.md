# Biblia de Arte — EMBERSPIRE v0.4

> Dueño: dirección de arte (DA). Es la referencia **contra la que se programa y se acepta** todo el arte. Si algo no está aquí,
> se pregunta a DA antes de inventarlo. Decisiones de origen: `docs/reviews/v04/DEBATE.md` (Resolución) y `PLAN.md`.
> Keyframe de referencia: `tests/_review_art/v04/director/keyframe_hot_1280.png` / `keyframe_cold_1280.png`.
> Datos de color: `scripts/art/palette.gd` (`Palette`). Pruebas: `tests/art/test_*.gd`.

---

## 1. Objetivo y pilares

Pixel art de 640×360 con luz de fuego y noche fría, **preciso, material y vivo**. Referentes: Blasphemous (siluetas, luz de vela
contra noche, jefes), Dead Cells (impacto, metal y piedra a gran tamaño), Eastward (dos temperaturas por escena), Children of Morta
(materiales táctiles), Slay the Spire (lectura de cartas e intenciones).

1. **Calor detrás, frío delante.** La luz cálida viene SIEMPRE del lado de la Forja; la fría, de la Torre. Todo personaje lleva las dos.
2. **La luz es el recurso.** Lo valioso emite (Ascuas, fuego, ojos, puntos débiles, cartas que se pueden quemar). Lo demás vive en
   la oscuridad. Si todo brilla, nada brilla.
3. **Materia antes que forma.** Cada píxel pertenece a un material con su rampa y su manera de reflejar (§5).
4. **El mundo responde.** Cada sistema del juego tiene firma visual en todas las pantallas (§11). Lo idle se ve, no se lee.
5. **Silueta primero.** A 32 px de alto cada criatura se reconoce en negro. El detalle se pone DENTRO, nunca en el borde.

**La Torre es el tiro de la Forja.** La Forja (abajo) es la fuente de luz del mundo; la Torre son galerías alrededor de su
chimenea. Subir = seguir el humo. Antorchas, braseros y hogueras son "de la Forja": responden a su calor.

---

## 2. Rejilla y escalas (REGLA DURA)

| Capa | Lienzo lógico | Escala a 1280×720 | Qué vive ahí |
|---|---|---|---|
| **Arte (mundo + interfaz)** | **640×360** | **×2** (×3 a 1080p, ×4 a 1440p, ×6 a 4K) | Fondos, luchadores, Forja, partículas, cartas, marcos, paneles, iconos, Fragua, Mini |
| **Texto de cuerpo** | 1280×720 | ×1 | **Sólo** Pavesa: cuerpo de carta y tooltips. ÚNICA excepción |

- El mundo se dibuja en `WorldView` (SubViewport 640×360, `snap_2d_*` activos): un píxel fuera de rejilla es **imposible**.
- Prohibido: escala no entera, `scale`/`rotation` sobre arte en reposo, posiciones de arte fuera de enteros. Excepciones: cartas
  **en vuelo** (< 300 ms) y la vuelta de robar (escala X 1→0→1, 220 ms).
- Si algo debe ser más grande, se **redibuja** (o se reencuadra por código). Nunca EPX, nunca `resize`.
- Rotaciones: sólo al **hornear**, recalculando primitivas del rig. Nada de RotSprite sobre bitmaps.

---

## 3. Paleta maestra

- **Cerrada.** Todo color sale de `Palette` (51 materiales, 475 colores). Prohibido escribir hex en otro archivo de arte. ¿Falta
  un color? Se pide a DA y se añade a `palette.gd` (los índices sólo se añaden al final).
- **Rampas por material, a mano**, de oscuro a claro, con **desplazamiento de tono**: sombras hacia violeta/azul, luces hacia
  ámbar (cálida) o cian/pizarra (fría). Prohibido generarlas por HSV o por `lerp`/`darkened`/`lightened`/`modulate`.
- Cada material tiene **rampa cálida y fría** con el **paso 0 común**. Los emisivos tienen una sola.
- **Contorno universal** `#0b080e` (`Palette.OUTLINE`): nunca negro puro.
- La prueba `tests/art/test_da.gd` falla si un PNG de `assets/baked/` o una textura registrada tiene un color fuera de paleta.

Familias (índice estable entre paréntesis; tabla completa en la cabecera de `palette.gd`):

| Familia | Materiales |
|---|---|
| Arquitectura | `stone`(1) `brick`(2) `furnace_brick`(3) `iron`(7, hierro de fondo, 11 pasos) `copper`(8) `wood`(10) `ash`(27) `smoke`(28) |
| Emisivos | `fire`(4) `hot`(31, acero al rojo) `sky`(11) `moon`(12) `slag_glow`(25) `frost_glow`(42) `ember_ui`(50) |
| Metales | `gold`(5) `brass`(9) `steel`(49, personajes y armas, con especular) |
| Tela | `cloth`(6, estandartes) `linen`(15) `wool_blue`(17, la bufanda) `canvas`(18) `burlap`(48) |
| Personajes | `skin`(13) `hair`(14) `leather`(16) `boot`(19) `soot`(20, tizne) |
| Criaturas | `rock_soot`(23) `rock_far`(21, partes lejanas) `coal`(22) `slag`(24) `ice`(26) |
| Estados | `blood`(40) `magic`(41) `heal`(33) |
| Interfaz y cartas | `parchment`(29) `parch_*`(30, 43–46) `ink`(39) `frame_*`(34–38) `plate`(47) `shadow_ui`(32) + `Palette.UI` (tintas, placas) |

Reglas de color por acto: **Hollín** = brick/stone/iron/copper/rock_soot + fire. **Escoria** = slag + slag_glow (vidrio volcánico
verdoso) + stone. **Ceniza Helada** = ice + frost_glow + ash + stone (frío). Un acto **no** es un recoloreado del anterior.

---

## 4. Valores y luz

### 4.1 Estructura de valores
| Capa | Luminancia | Contraste interno |
|---|---|---|
| Fondo lejano (corredor, cielo, tiro) | 5–35 % | 2–3 pasos |
| Fondo medio (muros, pilares) | 5–45 % (≤ 60 % junto a la Forja) | bajo |
| Suelo | 5–40 % | bajo + reflejo especular de la Forja |
| Personajes y criaturas | 8–90 % | **el más alto de la escena** |
| Emisivos | 70–100 % | el 100 % ocupa ≤ 1 % de la pantalla |
| Interfaz | placas 5–20 %, texto 85–95 % | ventana de lectura propia |

**Miniatura en grises:** a 1/4 (160×90) la heroína, cada enemigo y la Forja se separan de su entorno con **Δ ≥ 0,10** de
luminancia media (`test_da.check_separation`).

### 4.2 Las dos luces
- **Cálida = la Forja.** En combate está en x≈60, y≈228. Ganancia = calor actual de la Forja. Antorchas y braseros son luces
  cálidas secundarias **cuya llama crece con ese mismo calor**.
- **Fría = la Torre.** Entra por el fondo del arco (la cima), ventanas altas y haces de luna con polvo. Recorta a los enemigos
  (contorno frío arriba/derecha).
- Una superficie usa la rampa **cálida o fría según qué luz domine** en ella. Nunca se mezclan en un color intermedio.

### 4.3 Modelo técnico (único para todo)
- Textura de **índice** (horneada): material + **paso** (con la luz de la pieza ya horneada) + banderas (contorno/sello, emisivo,
  "mira a la Forja") + ancla de pieza. Resuelve el color el shader `palette_lit` con la LUT `Palette.build_lut()`
  (fila = índice·2 + fría).
- En tiempo real sólo **desplazamientos enteros de paso**: calor global, PV bajos, pico de quemar, 2–4 luces móviles,
  parpadeo. Se evalúan en el **centro de la pieza** (ladrillo, faceta, placa): la luz cae en saltos de sillar, no en anillos.
- Prohibido: `Light2D` multiplicativo, `PointLight2D` con caída continua, halos de degradado radial suave, bloom, CRT,
  `modulate` para iluminar. Los halos aditivos permitidos son **escalonados** (3–4 bandas de alfa fija) y sólo para luces móviles.
- Respaldo si el shader falla: hornear en 4 niveles de calor + desplazamiento de ±n pasos.

---

## 5. Materiales

| Material | Luz | Rasgo obligatorio |
|---|---|---|
| Piedra / ladrillo | paso plano por pieza; canto hacia la luz +1, canto opuesto −1 | juntas de 1 px a −3 pasos; desconchones 2–4 px; hollín que oscurece hacia arriba |
| Hierro / acero | especular: brillo de 1–2 px en el paso máximo pegado al paso 2 (sin intermedios) | remaches de 1 px (brillo arriba-izq., sombra abajo-der.); el filo refleja la Forja |
| Tela | pliegues como bandas verticales (periodo 6–8 px) | borde inferior −1; estandartes en cola de golondrina; 2 f de ondulación |
| Piel | suave: 3 pasos en la cara; máximo sólo en frente/pómulo del lado de la luz | rubor de 1 px; nariz que rompe la silueta |
| Cuero | satinado: 4 pasos + brillo de 1 px en pliegues | costuras de 1 px cada 3; quemaduras de 2 px a paso 0 |
| Fuego | emisivo; núcleo abajo (paso máximo), lenguas hacia el paso 3 | 4–8 f; lenguas suben 1 px/f; nunca dos fotogramas iguales seguidos |
| Hielo | translúcido: el interior un paso MÁS claro que el borde de sombra; facetas planas | grieta interior de 1 px; sin tramado |
| Escoria | vítrea: facetas + especular de 1 px | burbujas emisivas de 1 px; regueros que gotean |
| Roca con magma | facetas (normal constante por faceta) | magma sólo en juntas; roca a ≤ 2 px de una grieta +2 pasos (rebote); contorno frío |
| Pergamino | 4 pasos, fibras de 1 px como mucho cada 12 px | tinta `Palette.UI.ink`; nunca texto claro sobre pergamino |

**Jerarquía de volumen (errores de horneado del rig):** ninguna masa > 12 px con más de **3 planos de luz**; ninguna faceta
< **24 px²**; ninguna elipse lisa > 20 px sin aplanar ni facetar (delata "vector"); facetas Voronoi sólo para carbón, escoria y hielo.

---

## 6. Contorno, líneas, tramado y antialiasing

- **Contorno exterior** 1 px `OUTLINE`. **Sel-out**: en el borde que da a la Forja, el contorno toma el paso 1 de la rampa cálida
  del material vecino (el borde "arde"); en el que da a la Torre, el último píxel interior pasa al paso alto de la rampa fría (contorno
  de luz). Los fondos **no** llevan contorno (separan planos por valor).
- **Líneas interiores**: no se dibujan; salen de la **línea de contacto** (la pieza de detrás −2 pasos donde otra la tapa), sólo
  entre piezas declaradas y nunca alrededor de un sello.
- **Tramado**: sólo como **costura de banda** (damero 2×2 en el ~22 % superior de cada escalón) en superficies > 40 px. Prohibido en
  personajes < 48 px, en el hielo, en emisivos de UI y como relleno o textura (p. ej. puertas en damero: NO).
- **Antialiasing manual**: sólo en curvas de radio > 8 px y en el borde INTERIOR; un paso intermedio en escalones 2:1 o más.
  Emisivos: 1 px de halo al paso −2 de su rampa.
- **Agrupaciones limpias**: ninguna superficie > 6×6 px con píxeles sueltos de otro paso (sin ruido). Un detalle es un grupo ≥ 2 px
  o un píxel puesto a propósito (ojo, remache, brillo, chispa).
- **Sellos a mano obligatorios**: ojos, caras, manos, remaches, hebillas. Si un fotograma necesita > 15 px de parche, se rediseña la pose.

---

## 7. Disposición de combate (lienzo 640×360)

```
y   0–15   HUD (Ascuas, piso, Calor, Polvo, ajustes)
y  22–44   banda de intención de JEFE (fija). Intención normal: 18 px sobre la cabeza del enemigo
y      264 suelo (pies de todos los luchadores)
y 296–360  cartas en reposo (asoman 64 px; suben enteras al pasar el ratón)
x   8–112  Forja de combate (con chimenea hasta el borde superior; Quemas = rejillas del zócalo)
x 128–196  heroína (66 px + moño)
x 300–632  enemigos: 1 → centro 466 · 2 → 396 / 540 · 3 → 350 / 460 / 572
```
- Crisol de Energía abajo a la izquierda; botón "Fin de turno" placa remachada abajo a la derecha; pilas como dorsos 15×21.
- PV = placas de hierro remachadas bajo los pies; bloqueo = escudo a la izquierda de la placa.
- Nada del ambiente se anima dentro de la banda de intención ni detrás de un número.

---

## 8. Tamaños por familia

| Pieza | Tamaño (px de arte) | Notas |
|---|---|---|
| Heroína (la Fogonera, diseño PER + enmiendas DA) | **66 de alto + moño**, lienzo 96×96, 4,4 cabezas | cara sellada ≥ 10×10 legible (ojo 1×2 con brillo, ceja 3 px, nariz que rompe silueta), gafas de forja, bufanda azul, delantal, fogón de cinto, fuelle = 2 asas sobre el hombro, **sin saco de carbón**; puntas del pelo y cara del martillo siguen al calor; 2.º reposo con martillo al hombro |
| Monstruo pequeño | 24–36 | modo ASCII del rig permitido < 32 px |
| Monstruo medio | 48–72 | |
| Élite | 80–100 | **redibujado** con pieza propia (corona, armadura); nunca EPX |
| Jefe | **150–200 de cuerpo, ≤ 280 de ancho** | 4–7 partes animadas; sólo humo/corona/vapor entran en la banda 22–44, a < 30 % de valor y nunca sobre la intención; fase 2 cambia la silueta dentro del mismo marco |
| Forja de combate | 104×84 + chimenea | estados por calor; rejillas de Quemas |
| Forja del taller | ~200×180 | generadores como objetos físicos |
| Carta | **80×112**, ventana **68×46** | ver §9 |
| Dorso de pila | 15×21 | |
| Icono de interfaz | 12×12 | luz arriba-izq. cálida, sel-out, 4–5 pasos |
| Icono de reliquia | 16×16 | engarce de metal común |
| Puerta (mapa) | 40×56 | luz del destino; tipo por objeto, no por tono |
| Viñeta de evento | 240×120 | personaje del evento + luz propia |

---

## 9. Cartas

- **Anatomía 80×112**: orbe de coste (sobresale 5 px, ascua tallada), canto de material 4 px con bisel (claro arriba-izq.) y remaches
  2×2, placa de nombre (Fragua), **ventana 68×46 con silueta por tipo** (ataque: filo achaflanado; habilidad: escudo remachado;
  poder: capilla/óvalo; combustible: boca de horno; estado: mordida), cinta de tipo, pergamino 68×36 (Pavesa ×1), canto inferior
  con muescas de Maestría, gema de rareza y sello de Temple.
- **Marcos por material**: ataque `frame_attack` (hierro al rojo), habilidad `frame_skill` (acero pavonado), poder `frame_power`
  (latón/oro), combustible `frame_fuel` (hierro fundido), estado `frame_status`.
- **Estados**: mejorada (canto al rojo, cifras en `UI.upgraded`), Maestría (el marco **se calienta**: muescas → brasas incrustadas →
  metal al rojo + 1 f animado en la ilustración), Temple (sello 6×6), quemable (aura escalonada 4 f a 8 fps), en caliente, no quemable.
- **Ilustraciones: 93 composiciones únicas.** Gramática FONDO + LUZ + SUJETO + FX + ENCUADRE. Niveles A (~30: sujeto propio,
  pasada a mano, 1 f animado en Maestría 3), B (~58), C (5: estados y token). **Criterios de cada una**: ≥ 2 planos de profundidad,
  una luz clave motivada, un gesto o momento (no un objeto aislado), ≤ 12 colores, silueta legible a 68×46 y a 34×23. Nunca se repite
  la terna fondo + sujeto + encuadre (ni la posición). Prohibido "icono ampliado sobre degradado".

---

## 10. Tipografía

| Fuente | Rejilla | Uso |
|---|---|---|
| **Fragua** (5×7 proporcional, contorno horneado; `PixelFont`) | ×2 (y ×3, ×4 en títulos) | títulos, nombres de carta, cifras de combate (daño, PV, coste, energía, intención), botones cortos |
| **Pavesa** (6×9, derivada de Fragua) | **×1 de pantalla** | cuerpo de carta y tooltips; ~20 caracteres por línea; interlínea 12 px de pantalla |
| **Mini** (3×5) | ×2 | etiquetas pequeñas (contadores de pila, cinta de tipo, placas del mapa) |

- Tintas sólo de `Palette.UI`: sobre pergamino `ink`, cifras `num`, palabras clave `keyword`, mejoras `upgraded`; sobre placa `text`,
  secundario `text_dim`, títulos `title`.
- La fuente lisa del sistema queda sólo como opción de accesibilidad.

---

## 11. Mundo interconectado (firma visual del estado)

| Estado | Firma | Dónde |
|---|---|---|
| **Calor / producción de la Forja** | radio y ganancia de la luz cálida; altura de llama; antorchas; chispas del tiro (5 + 6·h); rejilla del suelo; puntas del pelo y cara del martillo de la heroína | todas las pantallas; en el mapa, la luz de la Forja sube por el tiro hasta el piso que alcance |
| **Generadores** | objetos físicos en el taller (3 estados por umbral 10/50/100) | taller; braseros de la Torre en pisos superados |
| **Quemar una carta** | aspiración (llamas inclinadas 2 f) → impacto en la boca (2 f blanco) → columna de fuego del color del tipo → conducto brida a brida → rejilla → chispas del tiro → monedas-brasa al contador | combate (todo el edificio) |
| **Quemas disponibles** | rejillas encendidas del zócalo de la Forja | combate |
| **Energía** | nivel del crisol de metal fundido | combate |
| **PV < 25 %** | la sala baja 2 pasos, braseros irregulares, latido de 1 paso a 1,1 Hz (fuera la viñeta roja continua); postura cansada | combate |
| **Acto** | material del mundo, criaturas, partículas (hollín / goteo de escoria / nieve) | todo |
| **Ciclo** | grietas emisivas en juntas (II), afijos de enemigo dibujados como capas, marco con óxido (III+) | todo |
| **Resplandor** | la luz cálida pasa a oro; halo escalonado en los nervios del tiro | taller, combate, título |
| **Maestría** | el marco de la carta se calienta (§9); la heroína gana remaches/martillo mejor por Maestría total | cartas, heroína |
| **Calor de Pacto** | cadenas en la puerta de la Antesala; braseros +1 banda; tizne en el cuello de la heroína; ojos emisivos con Calor ≥ 5 | Antesala, combate |
| **Muerte de enemigo** | sus brasas suben por el tiro hacia la Forja | combate |

Regla: una compra visible en **cinco pantallas** (p. ej. 10 Fuelles → fuelle extra en el taller → más calor → faro más alto en el
mapa → antorchas +2 px en combate → braseros encendiéndose en el resumen).

---

## 12. Animación (tiempos en ms, fotogramas horneados)

**Heroína (≈ 38–41 f):** reposo 6×150 (respiración 1 px; pelo y bufanda con 1 f de retardo) · martillazo: carga 3 (60/60/120 pausa) →
estela 1 (33) → impacto 2 (50 + hitstop) → recuperación 3 (90) · habilidad (tenazas) 5 · quemar 4 · golpe recibido 2 · muerte 8 ·
victoria 4 · andar 6 · sentada 2 · taller (martillar) 6.

**Criaturas:** reposo + rasgo vivo 4–6 (140–200) · telegrafía 2 (120 / bucle de 1 px a 400) · ataque 4: anticipación 80 → estela 33 →
impacto 60 + hitstop → recuperación 120 · gesto 3×100 · golpe recibido 2 (33 destello + 120) · muerte **por material** 6–8×80.
≈ 22 f por normal, 30 por élite, 50–70 por jefe.

**Impacto:** hitstop 50 (< 10 de daño) · 80 (10–30) · 120 (> 30); destello 1 f blanco → color del bioma; empuje 3–5 px; sacudida
direccional cuantizada a 1 px de arte, máx. 12 px de arte; números en Fragua con "pop" de escala entera.

**Cartas:** robar 220 (escalonado 40) · hover 90 (sube 24) · jugar 300 · quemar 450 · en caliente 520 · brillo de rara 500 cada 4 s ·
Maestría sube 300.

**Quemar (momento estrella, ≈ 900, interactivo a los 350):** ver §11 y `mundo_vivo/propuesta.md §4.1`.

**Transiciones:** piso→piso ascenso por capas 650 · combate→recompensa 400 (la sala baja 2 pasos, no alfa) · Torre→Forja caída por el
tiro 900 · Forja→Antesala 500 · abrir servicio: cortina de humo 300+300 · cambio de acto 1.600.

---

## 13. Presupuesto del mundo vivo

| Pantalla | Fuentes vivas (máx.) | Píxeles en movimiento por fotograma (arte) |
|---|---|---|
| Combate normal | 4 | ≤ 13.800 (≈ 6 % de 640×360) |
| Combate de jefe | 3 + el jefe | ≤ 16.000 |
| Forja (taller) | 6 | ≤ 24.000 |
| Hoguera | 5 | ≤ 18.000 |
| Mapa / tienda / evento | 3 | ≤ 10.000 |
| Modal abierto | 1 | el resto a 50 % de frecuencia |

- Ritmos desfasados y primos (100, 110, 125, 140, 180 ms) + fase aleatoria por instancia (±15 % de periodo). Nada pulsa al unísono.
- **Cada cosa viva tiene una causa** (el humo sale de un brasero; las chispas suben porque abajo está tu Forja).
- Durante el turno enemigo se congela lo opcional (rata, cuervo). Partículas sólo con `ArtParticles` en la rejilla.

---

## 14. Criterios de aceptación (toda pieza)

Una pieza **no se acepta** si falla uno:
1. **Paleta cerrada** (`test_da`): 0 colores fuera de `Palette`.
2. **Miniatura en grises**: Δ ≥ 0,10 contra su entorno a 1/4.
3. **Sin ruido**: ninguna superficie > 6×6 con píxeles sueltos.
4. **Rejilla**: sin escala no entera ni rotación en reposo; todo en `WorldView` o en la rejilla ×2 de la interfaz.
5. **Sellos**: ojos, caras, manos y remaches sellados a mano.
6. **Jerarquía de volumen** (§5) y **contorno/sel-out** (§6).
7. **Determinismo y frescura** del horneado (pruebas de TEC).

Por familia, además:
- **Heroína**: cara ≥ 10×10 legible; ≥ 6 materiales distinguibles; prueba de silueta en negro.
- **Criaturas**: silueta única a 32 px (10 evaluadores identifican ≥ 90 %); ≥ 1 punto emisivo; material del acto legible; muerte por material.
- **Jefes**: dentro del marco de §8; sin base compartida con otro jefe; cambio de fase visible.
- **Fondos**: 3 planos, ≥ 2 fuentes de luz (una de la Forja), 3–5 cosas vivas, suelo con losas y reflejo.
- **Cartas**: criterios de §9; prueba de miniatura 34×23 por grimorio.
- **Interfaz**: cero `StyleBoxFlat` visibles; 9-slice teselado; botones con 3 estados (pulsado baja 1 px).
- **Pantallas**: puntuación de DA ≥ 8/10 en la revisión por capturas.

---

## 15. Qué NO hacer

- Hex sueltos fuera de `palette.gd`; rampas por HSV, `lerp`, `darkened`, `lightened` o `modulate` para sombrear.
- Recolorear para crear actos, jefes, élites o tipos de carta.
- Escalar sprites "para darles presencia"; EPX; escalas no enteras; rotar en pantalla.
- Tramado de relleno o de textura (damero en puertas, cielos o cuerpos).
- `StyleBoxFlat`, halos de degradado suave, `Light2D` multiplicativo, bloom, CRT, viñeta roja continua.
- Elipses lisas grandes ("vector"), facetas diminutas (ruido), contorno negro puro.
- Iconos ampliados como ilustración de carta; dos cartas con la misma composición.
- Animarlo todo a la vez o dentro de la banda de intención; partículas `CPUParticles2D` sueltas fuera de la rejilla.
- IA generativa, imágenes externas, fuentes vectoriales nuevas (salvo la de accesibilidad).
- Saltarse las pruebas: lo que no pasa `tests/art/` no entra detrás de la fachada `Art`.
