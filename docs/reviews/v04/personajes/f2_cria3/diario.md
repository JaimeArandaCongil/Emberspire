# F2-CRIA3 · Diario (C13 `cinder_bat` contra la sala, C15 puente del 2.º reposo)

Nube Linux, Godot 4.7.2, xvfb. Archivos: `scripts/art/defs/creatures/cinder_bat.gd`, `scripts/art/defs/hero/fogonera.gd`,
su horneado (`assets/baked/creatures/cinder_bat*`, `assets/baked/hero/fogonera*`) y `tests/art/out/qa/{cinder_bat,fogonera}_qa.png`.

## 1 · `cinder_bat`: contraste ≥ 0,10 en todos los fotogramas de reposo

### Método (el de F2-SALA, sin cambios)
`medir_bat.gd.txt` es el script de F2-SALA (`medir_sala.gd`) reducido al murciélago: `BgAct1.build` de las 12 variantes con
las capas en vista previa (luz dinámica 0); cada fotograma de `idle` horneado centrado como `FighterView` (centro del
rectángulo usado del f0, socket `ground` en y 264); `test_da.thumbnail_separation` (gris a 1/4, anillo de 2 celdas), sin placa
de PV; mínimo sobre las 8 salas normales en cada hueco 350/396/460/466/540/572. El «antes» reproduce el diario de F2-SALA
(0,075 en 350; 0,000–0,010 en el resto).

### Por qué no bastaba un canto sobre la membrana oscura
Desglose (figura frente a anillo, sala normal v0): en 350 el anillo es el arco claro (0,21–0,25) y la figura 0,137; en
396–572 el anillo es el muro (0,10–0,14) y la figura 0,125–0,13. Una figura oscura necesitaría ≤ 0,02–0,04 en 396–572
(imposible: la membrana ya estaba en `rock_soot` 1 y el contorno es 0,03). Una figura media no pasa en ninguno de los dos
fondos. La única salida es una figura ≥ ~0,35, por encima del arco y del muro. Lo comprobé: un canto de 1 px sobre la
membrana oscura (primera prueba) dejó 0,000–0,075, igual que antes.

### Cambio (v2, tras la revisión de dirección: membrana de ceniza)
La v1 (cuero claro cálido, `leather` 5/6) pasaba la métrica (0,118) pero dirección la rechazó: se acercaba en tono a
`flame_moth`, que comparte encuentro, y perdía el carácter de «ceniza». La v2:
- **Membrana gris ceniza claro** (ranura `membrane` → `ash`, rampa neutra): ala cercana paso 8 con zona de fuga paso 7; ala
  lejana paso 7. Es cambio de material de la pieza, no un recoloreado para crear contenido.
- **Canto cálido de 1 px**: `_rim()` pasa a `r` todo píxel de membrana que toca aire (4 vecinos, sin contar los bordes de
  la losa, que son uniones). Canto y borde de ataque en `rock_soot` 7 (cercana) y 6 (lejana), cobre: el borde quemado.
  El contorno exterior sigue siendo el sel-out del motor; no hay contorno negro añadido.
- **Brasa emisiva**: las 2–3 vetas por tramo (`hot` 3 en la cercana, 2 en la lejana) y el labio del agujero quemado
  (`hot` 4/3), como en las losas de F2-CRIA2b.
- **Cuerpo y dedos oscuros**: `soot` en el cuerpo, la cara y el núcleo sin cambios; dedos `rock_soot` 3 (cercana) y 2.
  Membrana ≈ 0,50–0,59 frente a cuerpo ≈ 0,15.
- Silueta, losas `IN`/`OUT`, huesos, poses y lienzo: sin cambios. Atlas completo revisado (`atlas_cinder_bat.png`).

### Medida (mínimo de 8 salas normales, sin placa)
| Hueco | 350 | 396 | 460 | 466 | 540 | 572 |
|---|---|---|---|---|---|---|
| Antes (F2-CRIA2b) | 0,075 | 0,000 | 0,010 | 0,010 | 0,000 | 0,001 |
| v1 cuero (rechazada) | 0,118 | 0,220 | 0,246 | 0,244 | 0,232 | 0,235 |
| **v2 ceniza** | **0,125** | **0,230** | **0,258** | **0,253** | **0,244** | **0,247** |

Por fotograma (mínimo sobre salas y huecos), antes → v2: f0–f5 0,000 · 0,000 · 0,011 · 0,006 · 0,001 · 0,001 →
**0,170 · 0,146 · 0,125 · 0,146 · 0,136 · 0,162**. Salas de tiro: 0,015 → 0,173. Iteraciones: canto sobre la membrana
oscura 0,000; `rock_soot` 6 0,024; cuero 5/4 0,090; cuero 5/5 0,118; ceniza 7/6 0,101 (justa); ceniza 8/7 (final) 0,125.

### Distinción frente a `flame_moth` (`tono_polilla.txt`)
Píxeles de ala por encaje exacto con los colores de su rampa (murciélago: `ash` 6–8 + canto `rock_soot` 6–7; polilla:
`cloth`). Tono medio circular y saturación HLS media.
| | Tono | Saturación |
|---|---|---|
| Polilla (horneado y captura 18b) | 4° (rojo) | 0,56 |
| Murciélago v1 cuero (horneado) | 26° | 0,46 (Δ 0,11) |
| Murciélago v2 ceniza (horneado / captura 18b) | 24° | **0,18 (Δ 0,38)** |
El tono medio apenas cambia (Δ 20°), porque la ceniza es un gris levemente cálido y el canto cobrizo cuenta en la media.
La distinción la da la saturación: la diferencia con la polilla pasa de 0,11 a 0,38. Visto en `oscuro_cuero_ceniza_18b.png`
(arriba F2-CRIA2b, en medio v1 y abajo v2), el murciélago se ve gris y la polilla, roja.

## 2 · `fogonera`: `shoulder_in` / `shoulder_out`
- `fighter_view._bridge()` pide exactamente `shoulder_in` y `shoulder_out`; si no existen usa `windup`. Las animaciones no
  hacen bucle porque `_on_anim_finished` encadena `idle_shoulder` (entrada) o `idle` (salida).
- Poses nuevas en `J`: `sh_lift` (mano a la cintura, martillo alzado por DELANTE en diagonal, peso −1 px) y `sh_up`
  (martillo vertical junto a la cara, sin taparla; mano en `knuckles`). `shoulder_in` = lift 90 ms → up 100 ms;
  `shoulder_out` = up 100 ms → lift 90 ms, con moño y bufanda en sentido contrario. El arco va por delante, al revés que
  `windup` (por detrás y echada atrás), así que no se lee como amago de golpe.
- Sin tocar el resto: 74 px + moño, `idle`, `idle_shoulder`, ataque, muerte. Tira en `fogonera_puente_hombro.png`
  (idle → in f0, f1 → idle_shoulder → out f0, f1 → idle → windup, para comparar).

## Evidencia
- `tools/qa.sh bake --only=cinder_bat` y `--only=fogonera`: 1 horneada cada uno, 0 errores; salas al día.
- `tools/qa.sh all`: QA 1745/0, arte 5 suites/0.
- Recorrido `SHOTS_DIR=/tmp/claude-0/shots_cria3`: SMOKE OK; sólo `ERR_CANT_OPEN` (audio).
- `antes_despues_18b.png` (arriba: recorrido de F2-SALA; abajo: v2), `oscuro_cuero_ceniza_18b.png`, `gris_1de4_18b.png`
  (gris a 1/4 ×3, arriba antes), `combate_18b.png`, `hoja_*_qa.png`, `atlas_cinder_bat.png`, `fogonera_puente_hombro.png`,
  `medir_bat.gd.txt`, `tono_polilla.txt`. La v2 se volvió a hornear sólo con `--only=cinder_bat`, y `fogonera` no cambió.

## Pendiente / no comprobado
- No hay en `Palette` una rampa gris fría lo bastante clara: `coal` y `smoke` llegan como máximo a ≈ 0,36 y no pasan en
  x 350. Por eso la ceniza es neutra-cálida y no fría.
- El puente del hombro no sale en el recorrido (salta cada 6–10 s en reposo): revisado sólo en la tira horneada, no en juego.
- Con placa de PV no medido (la métrica oficial es sin placa).
