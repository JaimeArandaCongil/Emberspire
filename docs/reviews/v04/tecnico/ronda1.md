# Ronda 1 · Artista técnico (C2, C6, C7)

He leído las otras 4 propuestas y `director/keyframe_hot_1280.png`, `mundo_vivo/out/a1_contexto_x4.png` y `personajes/out/*`.

## C2 · Luz: **un solo shader, y funciona en gl_compatibility** (probado)

Respuesta a la pregunta de dirección: **sí**. Un único shader de paleta hace (a) la luz horneada por pieza como base y (b) el desplazamiento
de pasos en tiempo real leyendo una máscara de baja resolución. Lo he probado en ventana, con el renderer real, no en headless.
Propongo que sea el estándar. **No hacen falta los "4 niveles de calor horneados"** del DA: el calor pasa a ser un desplazamiento global.

**Modelo de datos (único para personajes, fondos, Forja y cartas)**: textura de índice RGBA8 → R = paso de rampa (con la luz de la
pieza ya horneada), G = fila de material, B = banderas (fijo: contorno, línea o sello; emisivo) + "mira a la Forja" (0–1),
A = cobertura. La prueba empaqueta material y paso en R por sencillez. En producción van a R y G para tener 256 materiales.
Una LUT de 16×N (fila = rampa hecha a mano). El shader calcula `paso + floor(L·mezcla(0,35; 1; mira) + 0,5)`, recorta a la rampa y
hace `texelFetch`. **El color sale siempre de la paleta.** Los emisivos ignoran la máscara y tienen su propio `emit_boost` (pulso de quemar).
Las líneas y los sellos son "fijos": la luz no los toca (condición 4 de PER).

**Por pieza, no por píxel** (regla del DA "tono plano por ladrillo"): la primera versión muestreaba la máscara por píxel y dibujaba anillos
concéntricos que cruzaban los ladrillos (el *tell* de programa). Lo arreglé con una **textura de anclas**: cada píxel muestrea la luz en el
centro de su pieza (ladrillo, losa). Ahora cada ladrillo sube o baja entero. Con eso los fondos se leen como pintados a mano. En
los personajes basta el muestreo por píxel, porque la máscara es suave a su escala.

**La luz fría** del DA ("calor detrás, frío delante") se resuelve igual. Es lo mismo que hace el `shade_cb` del DA, pero en GPU:
- la máscara pasa a tener dos canales, R cálido y G frío;
- cada material lleva dos filas de rampa (cálida y fría);
- el shader elige la fila según el canal dominante.

Esto no está prototipado, pero sólo es una lectura más.

### Evidencia (`tests/_review_art/v04/tecnico/shader_test/`)
- `palette_lit.gdshader` (40 líneas), `shader_test.gd`, `shader_test.tscn`. SubViewport 640×360 mostrado a ×2 en 1280×720, `snap_2d_*`
  y filtro Nearest. Muro de ladrillo + suelo + Forja emisiva + 3 gólems del rig de la PoC (8 fotogramas de reposo animados).
  El rig hornea los gólems a índices por búsqueda inversa en la LUT: **0 colores fuera de la LUT**.
- Máscara de luz de 80×45 (celdas de 8 px), animada: parpadeo de la Forja (ganancia 0,72–1,3), antorcha a la derecha y **pulso de
  quemar carta** (anillo que sale de la Forja a 1.100 px/s y se apaga en 600 ms; además los emisivos suben 1–2 pasos).
- Capturas con `get_viewport().get_texture().get_image()`. Las he revisado con Read:
  - `out/montaje_estados.png`: Forja baja, Forja alta, quemar en t = 0,10 y 0,25, quemar en t = 0,40 y sin máscara;
  - `out/recorte_forja_baja_vs_quemar.png`: ×2 real, cada ladrillo cambia de paso entero;
  - `out/recorte_golem_estados.png`: el gólem se oscurece y se aclara cuando le llega la onda;
  - `out/s8_estres_64_sprites.png`.
- **Renderer**: `gl_compatibility`, OpenGL 3.3 Core, AMD RX 6800 XT. Sin errores ni avisos de compilación de shader.
- **Coste** (64 sprites de 96×84 + muro a pantalla completa, sin vsync, 400 fotogramas):

| | ms/fotograma | GPU SubViewport | CPU render |
|---|---|---|---|
| Sin shader (PNG de color) | 2,15 | 0,032 ms | 0,081 ms |
| Con shader de paleta | 2,13 | 0,030 ms | 0,089 ms |

  **El shader no cuesta nada medible**: la diferencia queda dentro del ruido. Los 1,9 ms de los dos casos son la **máscara recalculada
  en GDScript** (3.600 celdas por fotograma). Solución: actualizarla a 12 Hz, que es además la cadencia correcta para un parpadeo de
  pixel art (≈0,4 ms de media), o dibujarla en GPU en un SubViewport de 80×45 con luces como *sprites* aditivos (CPU ≈ 0).
- Falta por validar: **GPU integrada y exportación web (WebGL2)**. El shader sólo usa `texelFetch`, enteros y `SCREEN_UV`, todo de GLSL
  ES 3.0, así que espero que pase. Va en la lista de QA del corte vertical.

**Consecuencia para MV**: no hace falta rehornear L2 cuando cambia el estado ni usar *sprites* de luz escalonada aditivos. Ambos
se sustituyen por la máscara. Sus capas, el parallax y los emisores se quedan tal cual.

## C6 · Una sola API (la firmo; propongo a PER firmarla)

Base: mi rig (huesos, z-buffer, G-buffer, animación) + las 7 condiciones de PER + la jerarquía de facetas del DA.

```
class_name RigDef extends Resource            # un fichero por criatura: scripts/art/defs/creatures/<id>.gd
  skeleton: StringName                        # plantilla compartida (bípedo, pesado, masa, alado, segmentado, cuadrúpedo) o propia
  bones: Array[Bone]                          # {name, parent, pivot, z, len}  (sólo si es propia o para añadir huesos)
  materials: Array[Mat]                       # {id, ramp_warm[5..9 hex A MANO], ramp_cold, outline, emissive, spec, tex}
  pieces: Array[Piece]
  stamps: Array[Stamp]                        # calcas/sellos
  patches: Dictionary                         # {&"attack:2": Array[Stamp]}
  anims: Dictionary                           # {&"idle": Anim, …}
  sockets: Dictionary                         # {&"hit": [bone, Vector2], &"intent": …, &"ember": …} → exportados para VFX/UI
Piece  {bone, prim: ell|cap|box|poly|rock|slab|blob, mat, params, z, group, flat=0.0, facet=null, line=true, ao=1.0}
Facet  {cells=3..5, planes=3, weight=0.6, crack=0.0, crack_mat}   # DA: ≤3 planos de luz por roca (arriba/frente/lado)
Slab   prim=slab: {rows: ASCII, bevel=2, height=4}                # silueta a mano → normal por campo de distancia
Stamp  {bone, origin, rows, legend: {char: [mat, paso|LINE|+1|-1]}, flip=false}   # tono FORZADO
Anim   {frames, ms[], keys: {bone: [ángulos]}, root: [Vector2i], overlap: {bone: fase}, smear: {bone, from, to}, emit: […]}
```

Reglas del renderizador, que son *lint* y fallan el horneado:
1. Material con rampa a mano. Prohibidas las rampas HSV (PER-1).
2. Cara, manos y detalles de 1–3 px sólo con `Stamp` (PER-2).
3. `ell`/`cap` de más de 20 px sin `flat ≥ 0,3` o sin `facet` → error (PER-3).
4. Líneas internas sólo entre piezas con `line = true` y nunca alrededor de un píxel forzado. Los sellos no pasan la limpieza de huérfanos (PER-4).
5. Las poses rotan **primitivas**, nunca *bitmaps* (PER-5).
6. Más de 15 píxeles de parche en un fotograma → aviso para rediseñar la pose (PER-6).
7. El horneado es determinista y tiene imagen dorada por criatura (PER-7).

Pipeline común:

`Skeleton.solve(pose) → Rasterizer → GBuffer → Shading(luz_base) → Clean(silueta, moda, huérfanos) → Stamps/Patches → SelOut → IndexAtlas`

Para escribir cómodo, un `RigBuilder` imperativo (`b.ell(...)`, `b.stamp(...)`, como el `rig.gd` de PER) produce la misma `RigDef`.
Las partes del `mockup.gd` del DA (`ell`, `cap`, `poly`, `rock`) se convierten en primitivas con la misma firma.

## C7 · Hornear: PNG versionados

Mantengo mi posición, alineada con dirección:
- **El código es la fuente**, y los PNG son derivados.
- `tools/bake_art.gd` genera los atlas de índice + vista previa en color + `manifest.json` (hash de `RigDef` + versión del pipeline).
- Dos tests:
  - "hojas al día" (sólo hashes, sin renderizar);
  - "determinismo" (una criatura horneada dos veces da los mismos bytes).

Contra la caché en `user://` de MV:
- no se puede revisar ni comparar en PR;
- cada instalación paga el primer arranque;
- QA no ve lo mismo que el jugador.

Además, la razón de MV para generar al cargar (rehornear según el estado) desaparece con el shader de C2: la geometría se hornea
una vez y el estado se resuelve en la máscara. Excepción aceptable: el fondo final de cada sala puede componerse al cargar a partir
de capas horneadas (es un *blit*, no un render).
