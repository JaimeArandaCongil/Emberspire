# Avisos entre expertos (los publica dirección)

## 1. Paleta estable (DA)
`scripts/art/palette.gd` (`class_name Palette`): 51 materiales, 475 colores. Tabla de índices estable (sólo se añade) en la cabecera.
- API: `ramp(mat, cold:=false)`, `color(mat, step, cold)`, `steps(mat, cold)`, `index(mat)`, `material_at(i)`,
  `lut_row(mat, cold) = index*2+int(cold)`, `build_lut()` (16×102 RGBA8 sin filtro; rampas cortas repiten el último paso),
  `build_lut_image()`, `all_colors()`, `is_palette_color(c)`, `find(c) -> [mat, step, cold]` (inversa, para hornear a índices),
  `is_emissive(mat)`, `validate()`, `Palette.UI` (colores fijos de texto/placas), `Palette.OUTLINE` = `#0b080e`.
- **No hay material "frío"**: la luz fría es la rampa fría de CADA material (`ramp(m, true)`); el paso 0 es común.
- PER: `steel` metal de personajes/armas, `hot` acero al rojo, `soot` tizne en piel; existen `canvas`, `boot`, `brass`, `burlap`,
  `coal`, `smoke`. Contorno: `Palette.OUTLINE` o pasos 0/1 de la rampa cálida para sel-out.
- UI: `frame_*` y `parch_*` por tipo (paso 0 = tinta común); placas y tintas de texto en `Palette.UI`.
- MV: `brick, stone, iron, copper, wood, ash, sky, fire, cloth` existen con esos nombres.
- Texturas índice horneadas terminan en `_idx.png` (la prueba de paleta las salta). Todo otro PNG de `assets/baked/` debe estar en paleta.
- **Nadie escribe hex a mano.** Si falta un color, se pide a DA.
- Formato de la textura índice (qué canal es material y cuál paso): **lo fija TEC** en `docs/reviews/v04/tecnico/formato_indice.md`. Hasta entonces, generad a través de una función propia de empaquetado para cambiarlo en un sitio.

## 2. Formato de la textura índice v1 (TEC) — CERRADO
`docs/reviews/v04/tecnico/formato_indice.md`, código `scripts/art/rig/index_format.gd` (`IndexFormat`).
R = `Palette.index(material)` · G = paso (bits 0–3) + banderas JOINT 16, BEVEL 32, EMISSIVE 64, COLD 128 ·
B/A = 128 + desplazamiento al ancla (ancla − píxel) · A = 0 vacío.
Empaquetar SIEMPRE con `IndexFormat.pack(mat, step, flags, anchor_delta)`; vista previa con `IndexFormat.preview(img)`.
Fachada `Art` hecha (`scripts/art/legacy/legacy_*.gd`), 2071 imágenes legado idénticas por hash.

## 3. Motor de rig v1 estable (TEC)
Spec `docs/reviews/v04/tecnico/api_rig.md`; código `scripts/art/rig/` (RigDef, RigBuilder, RigPose, RigRenderer, RigLint, IndexFormat).
Ejemplo completo: `scripts/art/rig/examples/golem_example.gd`. Convención: un archivo por criatura en
`scripts/art/defs/{creatures,hero,bosses}/<id>.gd` con `static func build() -> RigDef` (el horneador los descubre solo).
Sellos de `stamp_lib` directamente: `b.stamp_lib(id, bone, at, StampLib.get_stamp(...), remap)`. Las 7 condiciones de PER y los
límites de DA son errores de `RigLint`.
