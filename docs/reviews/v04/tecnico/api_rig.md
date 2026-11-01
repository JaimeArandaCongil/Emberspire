# Motor de rig v1 — API (TEC · v0.4)

Código: `scripts/art/rig/` · ejemplo completo: `scripts/art/rig/examples/golem_example.gd` · formato de salida:
`formato_indice.md`.

## Flujo
```gdscript
# scripts/art/defs/creatures/<id>.gd   (un fichero por criatura; el horneador los descubre solo)
extends RefCounted
static func build() -> RigDef:
    var b := RigBuilder.new(&"soot_golem", Vector2i(96, 96), Vector2i(54, 59), -1)   # id, lienzo, origen del root, mira a la izq.
    ...
    return b.def
```
`RigLint.check(def) -> Array[String]` (errores = el horneado falla) · `RigRenderer.render(def, anim, frame, params) -> Frame`
(`.index` imagen de índice, `.preview` color, `.sockets`, `.errors`) · `tools/bake_art.gd -- --only=<id>`.

## RigBuilder
| Llamada | Qué hace |
|---|---|
| `material(slot, &"coal", {facet={cell_area, weight, crack, crack_slot}, texture, tex_fn, spec, planes, rim})` | Ranura de material → material de `Palette`. `texture`: `none mortar strands folds scratches soot_grain`; `tex_fn(local, paso, n) -> paso` propia |
| `mask(from, to, &"param", &"rise"\|&"noise", [huesos])` | Cambio de material por parámetro de variante 0..1 (hollín que sube, escarcha) |
| `bone(name, parent, pivot, {z, angle})` | Hueso; la raíz se coloca en `origin + pivot` |
| `ik(name, upper, lower, end_en_lower, bend)` | IK de 2 huesos; objetivo por pose `&"ik:<name>": Vector2(lienzo)` |
| `ell / cap / box / poly / slab(...)` + `{z, flat, line, ao, tags, accessory}` | Primitivas en el espacio del hueso. `slab(rows, top_left, {char: slot \| [slot, paso_forzado]}, z0, bisel, alto)` |
| `stamp(id, bone, at, rows, legend, {anchor, views, flip, z_top, accessory})` | Sello de tono forzado. Leyenda `{char: [material \| "@ranura", paso \| "LINE" \| "+1" \| "-1"]}`; con "@" el paso va en escala 0..5 (como `stamp_lib`) |
| `stamp_lib(id, bone, at, StampLib.get_stamp("face_34"), {"@hand": "@skin"})` | Usa un sello de la biblioteca de PER (voltea solo si la criatura mira a la izquierda) |
| `patch(anim, frame, bone, at, rows, legend)` | Parche a mano de un fotograma (≤ 15 px, si no → error) |
| `anim(name, frames, ms \| [ms…], {fotograma: pose}, {loop, interp, overlap})` | Claves interpoladas (`smooth linear hold`); `overlap {hueso: retraso}` = seguimiento |
| `smear(anim, frame, bone, punto, slot, ancho, front)` | Estela en media luna desde el fotograma anterior, delante o detrás |
| `socket(name, bone, punto)` | Punto exportado a metadatos (impacto, intención, humo) |
| `variant(name, params)` | Variante horneada (accesorios `{&"shackle": true}`, máscaras `{&"soot": 0.4}`, fase de jefe) |
| `part(def_parte, offset, fase)` | Jefes multiparte: cada parte con su atlas y desfase |

**Claves de pose**: `<hueso>: rad (se suma al reposo)` · `&"@root": Vector2i` · `&"z:<hueso>"` · `&"ik:<cadena>": Vector2` ·
`&"view:<hueso>": &"perfil"` (elige `views` del sello) · `&"emit:<sello|pieza>": int` (emisivo animable) · `&"hide:<id>": true`.

## Errores de horneado (`RigLint` + renderizador)
PER-1 ranura sin material de `Palette` · PER-2 pieza `face/hand/eye/rivet` sin sello en su hueso · PER-3 `ell/cap` de más de 20 px sin
`flat ≥ 0,3` ni facetas · PER-6 parche > 15 px · DA: facetas sólo en `coal/slag/ice`, celda ≥ 24 px², `planes ≤ 3` (el render
reduce cada masa > 12 px a ≤ 3 pasos de luz) · lienzo < 32 px sin modo pequeño (`def.small = true` + losas con pasos forzados) ·
huesos/ranuras/IK/claves inexistentes. PER-4 (sin línea alrededor de sellos) y PER-5 (rotar primitivas) los garantiza el motor;
PER-7 (determinismo) lo comprueba `tests/art/test_tec.gd`.

## Luz horneada
Cálida de la Forja (izquierda-arriba-delante) y fría de la Torre (derecha-arriba) por normales; gana la mayor (bandera FRÍO).
Sombra arrojada en pantalla, AO entre piezas, líneas interiores sólo entre piezas con `line = true`, luz de borde = bandera CANTO
(+1 paso horneado y otro dinámico), contorno selectivo (paso 1 del material en el lado iluminado, `void` en sombra y base).
`def.light` (`LightSpec`) se puede ajustar por criatura.
