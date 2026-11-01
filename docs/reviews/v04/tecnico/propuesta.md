# Propuesta técnica v0.4 · Artista técnico

> Rol: pipelines de pixel art generado por código. Prueba de concepto real en
> `tests/_review_art/v04/tecnico/rig_poc.gd` (escena `rig_poc.tscn`), PNG en `tests/_review_art/v04/tecnico/out/`.
> Se regenera en unos 4 s con `"$GODOT" --path . --quit-after 5 res://tests/_review_art/v04/tecnico/rig_poc.tscn`
> (y después `git checkout project.godot`).

## TL;DR (posiciones firmes)

1. **H1 (rig renderer): SÍ, pero híbrido.** Un rig de primitivas con volumen genera la masa, la luz, las sombras y **todos los fotogramas
   de animación** con una coherencia que ningún agente puede conseguir dibujando a mano 30 fotogramas por bicho. El rig **no** pone
   el encanto por sí solo: necesita **calcas ASCII a mano ancladas a huesos** (cara, nudillos, runas, grietas de autor) y, en la
   siguiente fase, **piezas "losa" dibujadas en ASCII y extruidas** para todo lo plano (alas, capas, hojas, crestas). Lo he probado: con
   sólo primitivas sale un "gólem de roca de indie competente"; con las calcas ya tiene cara y carácter.
2. **H2 (hornear a PNG): SÍ, obligatorio.** El rig cuesta 62 ms/fotograma en GDScript; 21 formas × ~40 fotogramas = ~1 min de
   CPU. Eso no puede ir al arranque. Se hornea en `tools/`, se versiona el PNG + un manifiesto con hash de la fuente y un test
   detecta hojas desactualizadas. El fallback es el `art.gd` actual.
3. **H3 (SubViewport + luz dinámica): SÍ al SubViewport; NO a la iluminación estándar de Godot (Light2D + CanvasTexture) sobre los
   colores.** Light2D multiplica color: rompe las rampas con desplazamiento de tono y produce degradados continuos (luz "de móvil").
   Propongo **un shader de paleta propio**: cada sprite lleva un mapa de **índice de rampa + normal**; el shader suma la luz de
   2–4 fuentes (Forja, antorchas, ascua de la heroína), **cuantiza a escalones de la rampa** y resuelve el color en una LUT. La prueba
   (`light_positions.png`, `forge_flicker.png`) es exactamente esa matemática ejecutada en CPU sobre el G-buffer.
4. **H4 (resolución): 640×360 ×2 para el mundo**, el mismo píxel que ya usa la interfaz (`UI_PX = 2`). 427×240 ×3 queda **descartada**
   (1280/3 = 426,67: no es entera). 320×180 ×4 se queda corta para "mucho más detalle" (heroína 24×36 = 864 px de información).
   El argumento decisivo: **con un rig, el coste de producción no escala con los píxeles**; dibujando a mano sí (×4). Con el rig, doblar
   la resolución es casi gratis; con ASCII a mano sería inasumible.

---

## 1. Crítica de lo actual (técnica)

Capturas de referencia: `screenshots/07_combat.png`, `16_act2_hydra.png`, `18_frost_king.png`, y la hoja
`tests/_review_art/out/new_monsters_b0.png`.

| Problema | Evidencia | Causa técnica |
|---|---|---|
| Los monstruos normales son manchas de 12–26 px: el Gólem de Hollín mide ~20 px de arte (80 px en pantalla) frente a una heroína de 36 | `07_combat.png`: gólem, urraca y limo ocupan menos alto que la puerta del fondo | La resolución 320×180 + ASCII a mano obliga a dibujar pequeño; cada píxel extra cuesta a mano |
| Volumen inexistente o "almohadillado" | `new_monsters_b0.png`: todas las formas se sombrean igual, de borde a centro | `_build_monster()` sombrea con un **campo de distancia al borde** (`dist`) + "arriba claro/abajo oscuro". No hay normales: una pierna delante del torso no proyecta sombra ni tiene línea interior |
| El Rey Escarcha (jefe de 60–72 px) es una silueta plana con puntos | `18_frost_king.png` | `forma@2` = EPX sobre la rejilla ASCII: se amplía el dibujo, no se añade información |
| Animación de 3 estados (`base`, `crouch`, `stretch`) | `fighter_view.gd::_set_pose()`; `art.gd:1371-1376` | `crouch_image()`/`stretch_image()` quitan o duplican una fila: es un *squash* por cizalla, no una pose. No hay ataque, golpe ni muerte dibujados |
| La "luz del fuego" es un tinte fijo del 32 % en el borde izquierdo | `art.gd:1338-1339` | La luz se hornea como color; no puede parpadear con la Forja ni cambiar cuando la Forja se calienta |
| Antorchas y Forja no iluminan nada del mundo | `07_combat.png`: halos aditivos sobre el fondo, los monstruos no cambian | Los halos son `TextureRect` aditivos; no hay datos de normal |
| Mundo y UI en rejillas distintas (×4 y ×2) | `ART_BIBLE.md` | Dos densidades de píxel en la misma pantalla: la carta (×2) parece más "HD" que el monstruo (×4) |
| `art.gd` = 2.567 líneas, un autoload con todo | `grep -n "^func"` | Iconos, héroe, monstruos, cartas, fondos, Forja, eventos, puertas, logotipo en un fichero: dos artistas = conflicto de fusión seguro |
| Todo se genera en el arranque | `_cache` en memoria | Imposible subir de complejidad sin alargar la carga |

Lo que funciona y se conserva: paleta cerrada con rampas de bioma y desplazamiento de tono (la reutilizo tal cual en la prueba),
contorno `k` no negro, disciplina de rejilla (`_off` cuantizado), el sistema de iconos 12×12, el `DISSOLVE_SHADER`.

## 2. Objetivo visual (en lo que me toca)

- **Dead Cells**: modelos 3D renderizados sin antialiasing a baja resolución, con sombreado en bandas y contorno; la lección no es "usar
  3D" sino *"la animación sale de un esqueleto, el estilo sale del post-proceso"*. Es exactamente H1.
- **Blasphemous / The Last Faith**: densidad de detalle de autor (calcas), contornos selectivos, luz de borde cálida.
- **Children of Morta / Eastward**: luz dinámica que respeta la paleta (sin degradados), pequeños emisivos que iluminan su entorno.
- **Slay the Spire**: legibilidad de intención y silueta a tamaño de combate (ninguna técnica justifica perder lectura).

Criterio de aceptación por sprite: silueta legible en negro puro; 3 masas de valor (luz, medio, sombra) + 1 acento emisivo;
ningún píxel huérfano; ningún escalón de línea de 2 px que no sea intencionado; mismo hueso → mismo detalle en todos los fotogramas.

## 3. Evaluación de hipótesis con evidencia

### H1 · Rig renderer — **aceptada en versión híbrida**

Implementado en `rig_poc.gd` (≈ 850 líneas, sin dependencias). Pipeline por fotograma:

1. **Esqueleto 2D** (12 huesos): rotación en el plano de pantalla + traslación del root en **píxeles enteros** (evita temblor).
2. **31 piezas**: elipsoides y cápsulas cónicas en el espacio de su hueso, con z hacia el espectador. Rasterizado con z-buffer a
   resolución de arte (96×84) → **G-buffer**: pieza, material, normal, profundidad, celda Voronoi, distancia al borde de celda.
3. **Facetas de roca**: Voronoi en el espacio *del hueso* (la textura viaja con la pieza: cero "hervor" entre fotogramas) y normal de
   faceta = normal analítica en la semilla (estable). Peso 0,42: se lee primero la forma grande y después los planos.
4. **Limpieza de silueta**: espolones de 1 px fuera, muescas de 1 px rellenas.
5. **Luz**: direccional o puntual con atenuación + ambiente cenital + **sombra arrojada en espacio de pantalla** (marcha de 18 pasos
   sobre el z-buffer; el brazo cercano sombrea el torso) + **AO** por piezas vecinas más cercanas.
6. **Cuantización a índice de rampa** (6 escalones, el 0 reservado a líneas) → **filtro de moda** por pieza (convierte el ruido de
   cuantización en clústeres) → **labio iluminado** de las grietas (+1 tono en el borde que mira a la luz: piedra tallada).
7. **Emisivos**: grietas de magma en celdas elegidas por hash, ojos, núcleos de chimenea; **rebote**: la roca a 1 px de un emisivo pasa a
   una rampa cálida paralela (`ROCK_WARM`), mismo valor, tono naranja.
8. **Luz de borde** 1 px sólo donde la normal es rasante y mira a la luz; **líneas interiores** donde una pieza está ≥ 3 px delante
   de otra (en el tono más oscuro de la pieza de detrás, no en negro); **calcas ASCII** ancladas a hueso; **huérfanos** fuera
   (respetando calcas); **sel-out**: el contorno exterior toma un tono oscuro de la rampa en el lado iluminado y `k` en sombra y base.
9. **Animación**: 8 fotogramas de reposo con *overlap* (cabeza, brazos y mandíbula con desfase de fase), brasas que salen de las
   chimeneas en bucle; 6 de ataque (anticipación ×2, *smear* del puño por barrido de la pose anterior a la actual, impacto con
   esquirlas y polvo, mantenimiento, recuperación). **Cero fotogramas dibujados a mano**: 14 fotogramas = ~40 números de ángulo.

**Qué demuestra** (ver §6): volumen creíble, luz coherente y relocalizable, animación de verdad (ataque con arco por encima de la
cabeza, no cizalla), y el arte vive en ~120 líneas de datos por criatura.

**Dónde falla (honesto)**: (a) las primitivas dan anatomía "de globo": hombros, puños y cabeza se leen como elipsoides; (b) las
facetas aleatorias son textura, no diseño; (c) por debajo de ~32 px de alto el rig produce papilla — la cuantización necesita área;
(d) el detalle de autor (dientes, nudillos) sólo aparece cuando un humano lo pone. Por eso **híbrido**:
- **Calcas** (ya en la prueba: cara y nudillos, `DECALS`): ASCII en el espacio del hueso, con semántica `k/W/w/h/s` (línea, dientes,
  ±1 tono). Viajan con el hueso y se iluminan con la escena.
- **Losas** (siguiente paso, no en la prueba): pieza = silueta ASCII a mano + biselado por campo de distancia → normal. Es el
  `_build_monster` actual convertido en *primitiva*: aprovecha todo lo que ya sabe dibujar el equipo y cubre alas, capas, hojas.
- **Parches por fotograma** (opcional, sólo jefes): diferencias ASCII `{frame: {x,y: char}}` para corregir 3–10 píxeles de un fotograma
  clave, como haría un pixel artist sobre un render de Dead Cells.

### H2 · Hornear a PNG — **aceptada**

Medido: **62 ms/fotograma** (96×84, 31 piezas, GDScript, Ryzen + RX 6800 XT). Presupuesto por criatura normal: reposo 8 + ataque 6 +
golpe 3 + gesto/conjuro 6 + muerte 8 = **31 fotogramas ≈ 2 s**; jefes ~60 fotogramas a 160×150 ≈ 15 s. Total del bestiario ≈ 2 min.
En el arranque sería inaceptable; en `tools/bake_art.gd` es trivial.

- Salida: `assets/baked/creatures/<shape>.png` (atlas: filas = animaciones) con **dos canales de datos**, no color:
  R = índice de material·8 + escalón de rampa *sin luz de escena*, G = emisivo, BA = normal xy codificada. Además
  `<shape>_preview.png` en color (para revisión humana y para el fallback sin shader).
- `assets/baked/manifest.json`: por hoja, hash SHA-256 de la definición del rig + versión del pipeline. Test nuevo en
  `test_runner`: "toda hoja está al día" (recalcula hashes, no renderiza).
- Determinismo: el rig ya es determinista (semillas por pieza, sin `randf()` global). Test: hornear 1 criatura dos veces → bytes idénticos.
- Esto rompe la regla "sin binarios" de `art.gd`: la fuente sigue siendo texto versionable; el PNG es un artefacto derivado comprobado.
  Prefiero esto a 2 min de arranque.

### H3 · SubViewport + luz — **aceptada con cambio de tecnología de luz**

- `WorldView` = `SubViewportContainer(stretch=true, stretch_shrink=2)` + `SubViewport` 640×360, `canvas_item_default_texture_filter = Nearest`,
  `snap_2d_transforms_to_pixel = true`, `snap_2d_vertices_to_pixel = true`. Fondo, Forja, luchadores, partículas del mundo dentro;
  cartas, barras de vida, números y tooltips fuera, a 1280×720. Resultado: **imposible** poner un píxel del mundo fuera de rejilla
  (se elimina el truco `(_off / px).round() * px` de `fighter_view.gd:200` y la cuantización manual de la sacudida).
- **Luz**: shader de ítem de lienzo `palette_lit.gdshader` (≈ 60 líneas) aplicado a luchadores, Forja, puertas y fondo (capa de
  pared con normales generadas por el propio generador de ladrillo: relieve de cada sillar). Uniforms: hasta 4 luces
  `vec4 pos_range[4]`, `vec4 color_gain[4]`, ambiente; LUT `sampler2D ramps` (1 fila por material, 8 columnas). Por fragmento:
  `v = base + Σ lambert·atten·gain` → `step = clamp(floor(v·N))` → `texelFetch(ramps, ivec2(step, mat))`. Bordes de luz y
  sel-out se resuelven en el shader leyendo 4 vecinos (ya están en el G-buffer horneado como bits).
- Por qué no Light2D: modula color en espacio lineal → los tonos intermedios salen de la paleta y la luz es un degradado continuo;
  además la heroína y los monstruos llevan rampas con desplazamiento de tono que una multiplicación destruye. La prueba
  `forge_flicker.png` muestra lo que queremos: el parpadeo **mueve fronteras de banda**, no oscurece el sprite.
- Halos aditivos (`PointLight2D` en modo `ADD` o los `TextureRect` actuales) se mantienen sólo como *atmósfera* sobre el fondo.
- Fuentes de luz conectadas al juego: Forja (ganancia = calor, `forge_flicker` 6 pasos), antorchas del bioma (`Art.torches`), ascua de la
  heroína al quemar una carta (pico de 300 ms), golpe de magma enemigo (destello de 2 fotogramas), luna fría en Ceniza Helada.

### H4 · Resolución — **640×360 ×2**

| Opción | Entera a 1280×720 / 1920×1080 | Heroína | Monstruo normal | Jefe | Coste a mano | Coste con rig |
|---|---|---|---|---|---|---|
| 320×180 ×4 (actual) | ×4 / ×6 | 24×36 | 12–26 | 60–72 | 1× | 1× |
| 427×240 ×3 | **no** (426,67) / ×4,5 **no** | — | — | — | — | descartada |
| 480×270 | ×2,67 **no** / ×4 | — | — | — | — | descartada |
| **640×360 ×2** | ×2 / ×3 | **48×72** | **36–80** | **140–170** | ~4× | **~1,1×** (datos casi iguales, más fotogramas) |

- 640×360 es además **la rejilla de la interfaz** (`UI_PX = 2`): un píxel de carta = un píxel de mundo. Fin de la doble densidad.
- La prueba está dimensionada para eso: el gólem mide 70 px → un monstruo normal grande en 640×360 (heroína de 72).
- Riesgo: a ×2 el píxel es "fino"; se compensa con contornos de 1 px y clústeres limpios (filtro de moda), como Dead Cells. Los
  iconos y partículas pequeñas pueden seguir dibujándose a ×2 sobre 320 (doble píxel) si el director de arte quiere grano: se
  permite como **excepción por capa**, nunca dentro de un mismo sprite.

## 4. Arquitectura propuesta

```
scripts/art/                         (nuevo; art.gd queda como FACHADA de 150 líneas con la misma API pública)
  palette.gd            PAL, BIOMES, rampas por material, build_lut() → ImageTexture 8×N
  pixel_ops.gd          image_from_rows, scale2x, rotate_sprite, outline/sel_out, remove_orphans, mode_filter, clean_silhouette
  rig/
    rig_def.gd          class_name RigDef extends Resource: bones, pieces, decals, slabs, anims (datos puros)
    skeleton.gd         solve(pose) → Transform2D por hueso (+ z)
    rasterizer.gd       primitivas (ell, cap, box, slab) → GBuffer
    shading.gd          GBuffer + luces → índice; misma fórmula que palette_lit.gdshader (test de paridad)
    animator.gd         claves + curvas (ease, overlap por hueso, smear, impacto) → poses por fotograma
    gbuffer.gd          empaquetado a PNG de datos / color de vista previa
  defs/                 UN fichero por cosa → nadie pisa a nadie
    creatures/golem.gd, slime.gd, bat.gd, … boss_frost.gd     (extends RigDef; 100–300 líneas de datos)
    hero/fogonera.gd
    icons/*.txt         (ASCII 12×12, uno por icono; parser trivial)
  gen/                  generadores procedurales que no son rigs
    backgrounds/act1_brick.gd, act2_rock.gd, act3_ice.gd  (+ normales de pared)
    forge.gd, bonfire.gd, doors.gd, event_vignettes.gd, logo.gd
    cards/frame.gd, cards/illustration.gd  (las ilustraciones pueden pedir renders de rigs: ver §5)
scripts/ui/world/
  world_view.gd         SubViewport 640×360 + conversión de coordenadas mundo↔UI (para objetivos, números, tooltips)
  light_rig.gd          fuentes de luz de la escena → uniforms globales (RenderingServer.global_shader_parameter_set)
  sprite_bank.gd        carga atlases horneados; fallback a la fachada Art (procedural actual)
shaders/palette_lit.gdshader
tools/bake_art.gd (+ .tscn)          hornea todo → assets/baked/ + manifest.json; --only=golem para iterar
tools/art_sheet.gd                    hojas de revisión ampliadas (lo que hace hoy tests/_review_art/)
```

API (estable, para que `screens/*.gd` y los 1.745 checks no cambien):
- `Art.monster(shape, seed, biome, cycle)`, `monster_pose(...)`, `monster_glow(...)`, `player_pose(pose)`, `card_art(...)`… se
  mantienen; internamente `SpriteBank.has(shape) ? atlas : legado`.
- Nuevo: `Art.anim(shape, anim) -> SpriteFrames` (fotogramas + duraciones), `Art.lit_material(shape) -> ShaderMaterial`.
- `FighterView` gana un `AnimatedSprite2D` dentro del `WorldView`; su `Control` sigue en la capa UI para barra/intención/clic.

Paralelismo: cada criatura, icono, fondo e ilustración es un fichero; el único fichero compartido que se toca al añadir una
criatura es una línea en un registro (`defs/creatures/_index.gd`), ordenada alfabéticamente para fusiones triviales.

## 5. Conexión con las demás áreas (mundo interconectado)

- **Luz como sistema compartido**: la Forja es la luz principal de la escena; su calor (estado idle del juego) fija la ganancia y el
  parpadeo. Quemar una carta = pico de luz que recorre a todos los monstruos (bandas que avanzan 1 escalón durante 300 ms). Los
  ataques de fuego enemigos emiten luz de 2 fotogramas sobre la heroína. En Ceniza Helada, la luna fría desde la derecha compite con
  la Forja: los monstruos quedan partidos en cálido/frío (`light_positions.png`, 1.º vs 4.º).
- **Cartas/UI**: el horneador puede renderizar cualquier rig en cualquier pose y luz a 60×30 o 120×60 para ilustraciones
  ("Golpe" = Fogonera en el fotograma `strike` iluminada por la Forja; cartas de monstruo/bestiario = su pose de ataque). Misma
  paleta, misma luz, coherencia gratis.
- **Personajes**: los artistas de criaturas escriben `RigDef` + calcas; yo mantengo el motor. La heroína es rig + calcas grandes
  (cara, pelo, bufanda como cadena de huesos con física simple horneada: 3 huesos con retardo).
- **Mundo vivo**: el mismo esqueleto da "vida secundaria" barata: respiración con overlap, brasas por emisor anclado a hueso,
  parpadeo de ojos (calca alternativa 1 de cada 40 fotogramas), reacción de los monstruos al pico de luz de la Forja (giran la cabeza
  1 fotograma: animación `flinch` de 3 fotogramas). Fondos con normales para que las antorchas iluminen los sillares.

## 6. Prueba de concepto

Ficheros: `tests/_review_art/v04/tecnico/rig_poc.gd`, `rig_poc.tscn`, salida en `tests/_review_art/v04/tecnico/out/`:

| PNG | Qué es | Qué demuestra |
|---|---|---|
| `idle_8f.png` (×5) | 8 fotogramas de reposo | Respiración con overlap, brasas de las chimeneas, pulso de magma; sin "hervor" de textura |
| `attack_6f.png` (×5) | 6 fotogramas de ataque | Anticipación, arco por encima de la cabeza con *smear* generado, impacto con esquirlas/polvo, recuperación |
| `light_positions.png` (×5) | Mismo fotograma con 4 luces: Forja izquierda, brasa baja delante, antorcha arriba detrás, luna fría derecha | Luz dinámica real desde el G-buffer, siempre en paleta; los emisivos no cambian |
| `forge_flicker.png` (×5) | 6 intensidades de la Forja | El parpadeo mueve fronteras de banda (lo que hará el shader) |
| `gbuffer.png` (×5) | Normales y celdas | Lo que se hornea para el shader de juego |
| `zoom_x8.png` | Reposo e impacto a ×8 | Clústeres, sel-out, líneas interiores, calcas de cara y nudillos |
| `context_x4.png` | Sobre el fondo real del acto 1, a ×4, junto al gólem actual | Salto de calidad en el contexto (ojo: a ×4 parece un jefe; en 640×360 ×2 es un monstruo normal grande) |

Iteraciones hechas mirando los PNG (7): v1 era un bloque facetado tipo "low-poly" con luz de borde naranja en todo el
contorno y un grillete azul que dominaba; se corrigieron con líneas interiores por profundidad, ambiente más bajo, celdas más
grandes y facetas al 42 %, borde de luz sólo rasante, rebote de magma a 1 px, rediseño de silueta (piernas abiertas = espacio
negativo, cabeza adelantada fuera del hombro, brazo lejano visible detrás), arco del ataque por encima de la cabeza (antes
pasaba por debajo) y calcas protegidas de la limpieza de huérfanos.

**Veredicto**: el rig alcanza "pixel art profesional de indie" en volumen, luz y animación — muy por encima de lo actual y por
encima de lo que un agente puede dibujar fotograma a fotograma. **No** alcanza todavía "maestro del pixel" en diseño de forma:
las primitivas dan anatomía redondeada y las facetas son genéricas. Lo que cierra esa distancia no es más proceduralidad sino
**más mano**: calcas (demostradas), losas ASCII extruidas y parches por fotograma en jefes. La alternativa pura "ASCII a mano a
mayor resolución + herramientas de sombreado" sólo la recomendaría para lo que mide < 32 px (iconos, insectos, partículas): ahí
el rig no aporta.

## 7. Presupuesto de rendimiento

| Recurso | Presupuesto | Cálculo |
|---|---|---|
| Horneado | ≤ 3 min todo el juego, ≤ 3 s por criatura | 62 ms/fotograma medido; 31 fotogramas normales, ~60 jefes |
| Arranque | sin cambios o mejor | cargar ~25 PNG por acto en vez de generar procedural |
| VRAM | ≤ 24 MB arte de mundo por acto | criatura normal 31 × 96×84 × 4 B ≈ 1 MB (datos) + 1 MB (vista previa, sólo fallback); 8 criaturas + 2 jefes (4 MB) + fondo 640×360 ×2 capas ×(color+normal) ≈ 3,7 MB |
| Disco | ≤ 10 MB | PNG de datos comprime ~6–10× |
| GPU por fotograma | < 0,3 ms | 640×360 = 230 k fragmentos × 4 luces + 4 lecturas vecinas; trivial incluso en gl_compatibility integrado |
| Draw calls mundo | ≤ 40 | fondo 2, Forja 1, luchadores ≤ 7 (×2 con capa emisiva), partículas en `GPUParticles2D`/`CPUParticles2D` 4–8 |
| CPU de animación | 0 | `AnimatedSprite2D`; nada se genera en tiempo de juego |

## 8. Plan de migración (sin romper el juego ni los 1.745 checks)

1. **M0 – Fachada** (sin cambio visual): mover el contenido de `art.gd` a `scripts/art/**` por responsabilidad; `art.gd` reexporta
   constantes (`SPRITES`, `SHAPES`, `BASES`, `BIOMES`) y funciones. Criterio: `test_runner` verde, capturas del smoke idénticas
   píxel a píxel (diff con `Image.compare`).
2. **M1 – Motor del rig** a partir de la prueba (tipado, `RigDef` como Resource, test de determinismo y de paridad CPU/shader).
3. **M2 – Horneador + SpriteBank + fallback**: `has_shape()` sigue devolviendo true para las 21 formas; una forma sin hoja usa el legado.
   Test nuevo "hojas al día".
4. **M3 – WorldView 640×360** detrás de un flag `Settings.world_v2` (por defecto apagado). Convertir posiciones de
   `combat_screen.gd`/`fighter_view.gd` vía `world_view.to_ui()`. El legado se dibuja a ×2 con EPX ×2 previo mientras tanto (los
   sprites de 320 viven en 640 sin cambiar de aspecto).
5. **M4 – Shader de paleta + LightRig**: primero sólo Forja; después antorchas y picos de quemar.
6. **M5 – Contenido**: criatura a criatura (el flag por forma decide legado/rig). Cada PR: definición + hoja + captura del smoke.
7. **M6 – Apagar el legado** cuando las 21 formas y la heroína estén migradas; actualizar `ART_BIBLE.md` (×2 único) y los checks
   que recorren `Art.SHAPES` para que recorran el registro de rigs.

## 9. Riesgos y descartes

| Riesgo | Mitigación |
|---|---|
| Look "3D barato" | Calcas + losas + filtro de moda + revisión del director de arte por hoja; prohibido aceptar un rig sin calcas de cara |
| Parpadeo de bandas entre fotogramas al rotar | Traslaciones enteras, Voronoi en espacio de hueso, normales de faceta en semillas (implementado); umbrales con histéresis en el shader |
| gl_compatibility y `texelFetch`/uniform arrays | GLSL ES 3.0 lo soporta; validar en M4 con el smoke en el portátil más débil |
| Agentes escribiendo rigs malos (proporciones) | Plantillas por arquetipo (bípedo, cuadrúpedo, volador, serpiente, masa) con huesos ya resueltos; la criatura sólo define piezas, calcas y claves |
| Coste de revisión de 2 min de horneado | `--only=<shape>` (2–3 s) y hoja de revisión automática |
| Divergencia CPU/shader | Un test de paridad renderiza 1 fotograma por ambos caminos y compara índices |

Descarto: Light2D multiplicativo sobre color; escalado fraccional para "presencia"; 427×240; generar en el arranque; renders 3D
reales con `SubViewport` 3D (añade un pipeline de mallas, materiales e importación que los agentes no controlan píxel a píxel y no
gana nada frente a las primitivas analíticas); tramado en las rampas.

## 10. Estimación en paquetes independientes

| Paquete | Contenido | Días-persona | Depende de |
|---|---|---|---|
| T0 | Fachada y troceo de `art.gd` (M0) | 2 | — |
| T1 | Motor del rig: primitivas ell/cap/box/losa, calcas, parches, animador con overlap/smear | 5 | T0 |
| T2 | Horneador, manifiesto, SpriteBank, tests de determinismo/frescura | 3 | T1 |
| T3 | WorldView 640×360 + conversión de coordenadas + flag | 4 | T0 |
| T4 | `palette_lit.gdshader`, LUT, LightRig conectado a Forja/antorchas/quemar, test de paridad | 4 | T2, T3 |
| T5 | Plantillas de arquetipo (5) | 3 | T1 |
| T6 | 15 criaturas normales (rig + calcas + 5 animaciones) | 15 × 1,5 = 22 | T5 (paralelizable ×3–4) |
| T7 | 6 jefes (rig + losas + parches + 7 animaciones) | 6 × 4 = 24 | T5 (paralelizable) |
| T8 | Heroína (rig + calcas + bufanda + 10 animaciones) | 6 | T5 |
| T9 | Fondos 640×360 con normales de pared (3 actos + capa cercana) | 6 | T3 |
| T10 | Ilustraciones de carta desde rigs (con el experto de cartas) | 4 + 0,25/carta | T2 |
| T11 | Migración final, `ART_BIBLE` v2, limpieza del legado | 2 | todo |

Camino crítico: T0 → T1 → T2 → T4 ≈ 14 días; el contenido (T6–T10, ~65 días-persona) se reparte entre 4 artistas en ~3 semanas.
