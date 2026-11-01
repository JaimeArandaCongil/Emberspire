# Formato de textura de índice v1 (TEC · v0.4)

> Sección para `docs/ART_BIBLE.md` (dueño: DA). Código de referencia: `scripts/art/rig/index_format.gd` (`IndexFormat`).
> Shader: `shaders/palette_lit.gdshader`. Globales de luz: `scripts/art/light_rig.gd` (`LightRig`).

Todo el arte del MUNDO (personajes, criaturas, fondos, Forja, puertas) se hornea a **texturas de índice**, no de color.
El color lo pone el shader `palette_lit` con la LUT de `Palette` y la luz de la escena en tiempo real.

## Canales (RGBA8, sin filtro, sin mipmaps, sin premultiplicar)

| Canal | Contenido |
|---|---|
| **R** | Índice de material de la paleta maestra: `Palette.index(&"brick")`. 0 = `void` (contorno universal). |
| **G** bits 0–3 | **Paso** de rampa horneado (0–15), con la luz estática de la pieza ya incluida. **El paso 0 nunca se mueve** (líneas y contornos). |
| **G** bit 4 (16) | `JUNTA`: rehundida. La luz dinámica positiva le llega con un paso menos (mortero, juntas, pliegues hondos). |
| **G** bit 5 (32) | `CANTO`: arista o borde iluminable. +1 paso cuando la luz dinámica en su ancla es ≥ +1 (canto de ladrillo, luz de borde de personaje). |
| **G** bit 6 (64) | `EMISIVO`: ignora toda luz; sólo recibe el pulso emisivo global (`emit_pulse`). Usar con materiales emisivos de `Palette.EMISSIVE`. |
| **G** bit 7 (128) | `FRÍO`: en el horneado dominó la luz fría → fila fría de la LUT. Una luz dinámica cálida fuerte (≥ 2 pasos) lo devuelve a cálida; una fría lo pasa a fría. |
| **B** | `128 + (ancla.x − x)` |
| **A** | `128 + (ancla.y − y)`. **A = 0 ⇔ píxel vacío.** Un píxel lleno nunca tiene A = 0 (desplazamiento máximo ±127). |

**Ancla** = centro de la PIEZA (ladrillo, sillar, losa, miembro del personaje). La luz dinámica se evalúa en la posición de
mundo del ancla, así que una pieza entera sube o baja de paso a la vez (regla de DA "tono plano por pieza").
El paso horneado debe estar dentro de la rampa (`< Palette.steps(mat, frío)`). El shader satura arriba (la LUT repite el último
paso) y nunca baja de 1 a un píxel con paso ≥ 1.

## Cálculo en el shader (por píxel)
```
ancla_mundo = posición_mundo_del_píxel + (B−128, A−128)
d = Σ luces(ancla_mundo) + Forja(calor) + onda_de_quemar + máscara_local − PV_bajos       (en pasos, flotante)
off = round(d)                       ; JUNTA: off = max(0, off−1) si off > 0 ; CANTO: off += 1 si off ≥ 1
paso = (paso_horneado == 0) ? 0 : clamp(paso_horneado + off, 1, 15)
EMISIVO: paso = clamp(paso_horneado + emit_pulse, 0, 15)
fila = 2·R + frío ; color = LUT[fila][paso]
```

## Archivos
- `assets/baked/<grupo>/<id>_idx.png` — atlas de índices (la prueba de paleta los salta).
- `assets/baked/<grupo>/<id>_prev.png` — vista previa en color = shader con luz dinámica 0 (debe estar en paleta).
- `assets/baked/<grupo>/<id>.json` — metadatos (rectángulos por fotograma, ms, anclajes/sockets, partes).
- `assets/baked/manifest.json` — hash de las fuentes por id (prueba de frescura).

## Cómo generar
- Siempre con `IndexFormat.pack(material, paso, banderas, ancla − píxel)`; nunca escribir canales a mano.
- Vista previa y validación: `IndexFormat.preview(img)`, `IndexFormat.validate(img)`.
- Los fondos de MV (`BgCanvas`) ya usan esta disposición: sólo cambian su índice de material a `Palette.index`.
