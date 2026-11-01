# Diario de DA · v0.4

## Fase 0: propuesta y debate
- `propuesta.md`: crítica por pantalla y familia (nota global 3,5/10), dirección v0.4, keyframe
  `tests/_review_art/v04/director/keyframe_{hot,cold}_1280.png` generado por `mockup.gd`.
- `ronda1.md`: arbitraje de C1–C9.
  - Concedo C3 (80×112) y C4 (Pavesa ×1) y acepto C5 (93 composiciones únicas).
  - Fijo C8 en jefes de 150–200 px por la disposición de combate.
  - Adopto la heroína de PER con 3 enmiendas.

## Fase 1: cimientos

### 1. `scripts/art/palette.gd` (`class_name Palette`): HECHO
- 51 materiales, 475 colores, rampas cálida y fría a mano con el paso 0 común; los emisivos tienen una sola rampa.
- **Índice estable sólo para añadir al final**, con la tabla en la cabecera del archivo.
- Fila de la LUT = índice·2 + fría. La LUT mide 16 × 102 y las rampas cortas repiten su último paso.
- API:
  - Rampas y colores: `ramp`, `color`, `steps`.
  - Índices: `index`, `material_at`, `lut_row`.
  - LUT: `build_lut`, `build_lut_image`.
  - Comprobación de colores: `all_colors`, `key8`, `is_palette_color`, `find` (búsqueda inversa para hornear a índices), `is_emissive`, `validate`.
  - Constantes: `UI` (tintas y placas), `OUTLINE`.
- Fuentes de cada rampa:
  - Arquitectura: las rampas de 11 pasos de MV, con fría hecha a mano.
  - Personajes: las de PER (5–7 pasos).
  - Cartas: las de UI, con el paso 0 de tinta común.
  - Criaturas y fuego: las del keyframe de DA.
- Nombres alineados con el respaldo `BgRamps` de MV (`brick`, `stone`, `iron`, `copper`, `wood`, `ash`, `sky`, `fire`, `cloth`). MV toma mi paleta sin tocar su código.
  - `iron` = hierro de fondo (11 pasos).
  - `steel` = acero de personajes (7 pasos).
  - No hay material "cold": la luz fría es la rampa fría de cada material.
- Aviso enviado a main (SendMessage) con la API y las notas para cada experto.
- Vista de la LUT: `tests/_review_art/v04/director/palette_lut_x8.png`.

### 2. `docs/ART_BIBLE.md` v0.4: HECHO
Reescrita entera en 15 secciones:
1. Pilares.
2. Rejilla 640×360 ×2, con Pavesa ×1 como única excepción.
3. Paleta.
4. Valores y las dos luces, con el modelo `palette_lit`.
5. Materiales y jerarquía de volumen.
6. Contorno, sel-out, tramado y antialiasing.
7. Disposición de combate.
8. Tamaños por familia.
9. Cartas.
10. Fuentes: Fragua, Pavesa y Mini.
11. Mundo interconectado.
12. Animación.
13. Presupuesto vivo.
14. Criterios de aceptación.
15. Lo que NO se hace.

El presupuesto de píxeles vivos de MV (que estaba en 320×180) se ha reescalado a 640×360 (≈ 6 % del lienzo).

### 3. `tests/art/test_da.gd`: HECHO (0 fallos)
- `run() -> Array` con los fallos. Comprueba:
  - `Palette.validate()`: paso 0 común, máximo 16 pasos, rampas que suben de luminancia, índices completos y ≤ 256 filas.
  - La LUT.
  - **Paleta cerrada** de todos los PNG de `assets/baked/`. Se excluyen los `*_idx.png` (texturas de índice) y las carpetas `_ref/` y `_tmp/`; se ignora alfa < 0,02.
  - La lista `ART_CALLS` (llamadas a `Art` que cada experto registra).
  - Autoprueba de los ayudantes.
- Ayudantes para los demás: `off_palette(img)`, `check_image(img, name)`, `gray_thumb`, `thumbnail_separation(scene, mask, factor=4)`, `check_separation(name, scene, mask)` (Δ ≥ 0,10) y `compose(bg, sprite, at)`.
- Ejecutor aislado mientras TEC no cree `tests/art/art_tests.tscn`: `tests/_review_art/v04/director/run_test_da.tscn`.

## Pendientes y avisos
1. **UI usa colores fuera de paleta en su propuesta**: Maestría 5 en violeta `#ff8ad8`, plata de poco común `#c8d4e4` y oro de rara `#ffd84a`. Mi propuesta:
   - Maestría 5 → `magic` paso 4 (`#d0a8ff`).
   - Plata → `steel` en rampa fría, paso 5 (`#9cb0c4`) o 6.
   - Oro → `gold` paso 4 (`#f0c050`) o 5.
   - Si los necesita exactos, que los pida y los añado.
2. **MV** tiene la rampa `COLD` y su `fire` antiguo (`2a0a0a…`). Con la paleta maestra cambian levemente: `fire` pasa a `2a0a10…fff6d4`. Hay que revisar su horneado.
3. **PER** usaba un contorno de color por material; la biblia fija `OUTLINE` y sel-out. Hay que confirmarlo con él.
4. `ART_CALLS` está vacía porque todavía no hay arte v0.4 detrás de la fachada. Cada experto debe registrar sus llamadas.
5. **No existe `assets/baked/`**, así que el control de PNG horneados aún no comprueba nada.
6. Al ejecutar headless, `scripts/ui/ui.gd` (UI, en curso) da `Identifier "UIKit" not declared`. Lo más probable es que falte registrar la clase en la caché de clases (`--import`) o que el trabajo esté a medias. No es de DA, pero rompe el arranque si no se resuelve.
7. La prueba de miniatura todavía no se aplica a capturas reales. Se aplicará en la fase 2, con las capturas del smoke y las máscaras de los luchadores.
