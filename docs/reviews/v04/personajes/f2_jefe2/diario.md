# F2-JEFE2 · El Gran Fuelle (`great_bellows`) · diario

Encargo: corrección #1 de F2-REV2 (`director/f2_rev2/dictamen.md`). Cuerpo ≥ 150 de arte sin contar la grúa (≤ 200, ancho ≤ 280),
cámara más alta, patas más gruesas, pliegues con pasos y sombra en reposo (sin fleco) y cabeza con más masa que el pico.

## Método de medida (reproducible)

`medir_jefe.gd` (en esta carpeta) construye la `RigDef`, muestrea cada fotograma de `idle` de las dos fases y renderiza el
`preview` con `RigRenderer.render_pose` dos veces: completo y ocultando la grúa (`hide:` de poste, horquilla, balancín, tirante,
contrapeso, contrapeso caído y todos los eslabones de las dos cadenas; la argolla de la tapa sí cuenta como cuerpo). Mide la caja de
píxeles con alfa > 0,5. Ejecutar:
`/opt/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . -s <ruta absoluta>/medir_jefe.gd 2>&1 | grep MEDIDA`.
Los pies están en la fila 196 del lienzo (= suelo, art y 264); la fila 197 es la sombra arrojada.

## Medidas (px de arte, alto hasta la fila 196)

| | Antes (F2-JEFE) | **Después** |
|---|---|---|
| Fase 1, reposo f0, total con grúa | 242×179 | **241×182** |
| Fase 1, reposo f0, cuerpo sin grúa | 219×**129** (lomo en lienzo y 68 = art 136) | 220×**161** (lomo en y 36 = art 104) |
| Fase 1, reposo f0–f5, cuerpo sin grúa | 129–149 | **161–180** |
| Fase 2, reposo f0–f5, cuerpo sin grúa | 129–148 | **154–166** |
| Total con grúa, máximo del reposo | 186 | 191 (≤ 200) |
| Ancho de `body_rect` (reposo f0) | 242 | 241 (sin cambio para `_boss_centers`) |

La estimación del revisor (~135) cae dentro del rango real anterior (129–149, según el fotograma de respiración).

## Cambios en `great_bellows.gd`

- **Cámara más alta**: bisagra de y −68 a −78; apertura mínima `TH0 = 0,1` sumada a toda pose (el reposo va de 0,30 a 0,48 rad en vez
  de 0,20–0,38); cara de la tapa en pera más alta (cumbre −48 en vez de −36), zunchos y remaches alargados.
- **Patas**: arrancan en `LEG_Y = −64` (antes −54); muslo de radio 7,5/6 (antes 5,5/4,2), caña 6/4,8, rodilla 7, pie de garra más
  ancho y cuatro uñas. Cuna, travesaño (2,5) y tirante bajados 10 px.
- **Pliegues**: 4 rollos de cuero redondeados (sin punta) y más gruesos (semigrosor 10) para que tapen el hueco hasta 0,58 rad.
  Textura nueva `_leather`: sombra −2 bajo el rollo de arriba, cara iluminada y canto −1 que se mete debajo; costura sólo en la cara.
- **Cabeza**: bloque de 45×58 (antes 36×45), ceño mayor, mandíbula herrada con 5 remaches, ojos 20×8 en las 4 vistas, rejilla de
  13×4. **Tobera** acortada de 36 a 28 px y adelgazada (radio 6,5 → 3,6).
- **Grúa**: argolla `RING` en (78, −44), cadena de la tapa de 32 px y 8 eslabones (antes 52 y 15) para que el balancín no se salga del
  lienzo con la cámara más alta.
- **Muerte**: el montón baja 32 (antes 18) y las patas se abren 1,1 rad; restos en el suelo ajustados.
- Lienzo (340×204) y origen (206, 196) sin cambio. 7 partes, fase 2, animaciones y sockets se conservan.

**Socket `hit` (tobera)**: de (79, 136) a **(80, 126)** del lienzo en reposo f0 (sube 10 px con la cámara). `intent` (283, 14),
`smoke` (84, 126), `heart` (238, 108).

## Iteraciones

1. Geometría nueva: cuerpo 161, pliegues ya en rollos pero muy oscuros; los ojos se perdían en el bloque.
2. Cuero +1 paso en la cara iluminada, ojos 20×8 y montón de muerte más bajo. Hoja: `hoja_revisada.png` (fase 1: reposo f0 y f3,
   ataque f2, invocación f3, ahogo f4, muerte f2 y f7; fase 2: reposo f0 y f3, golpe f0, gesto f1, ataque f0).

## Evidencia

`antes_despues_reposo_f0_x2.png`, `hoja_revisada.png`, `14_boss_summon.png`, `14a_summon_reveal.png` (recorrido `smoke.tscn` con
`SHOTS_DIR` propio). En 14 el jefe queda centrado con un ácaro a cada lado, sin solaparse con sus placas.

## Comprobado

- `tools/qa.sh bake --only=great_bellows`: 1 horneada, 0 con errores. En `manifest.json` sólo cambia el hash de `great_bellows`.
- `tools/qa.sh all`: QA de juego con 1745 comprobaciones y 0 fallos; arte con 5 suites y 0 fallos.
- Recorrido `smoke.tscn`: sin `ERROR` (salvo `ERR_CANT_OPEN` de audio).

## No comprobado / pendiente

- Las animaciones en movimiento en juego (sólo hoja y capturas fijas); fase 2, `summon` y `choke` siguen sin verse en combate
  (integración pendiente desde F2-JEFE).
- El destello por pieza (corrección #2) es de F2-VIDA4: si usa `hit`, la coordenada nueva es (80, 126).
- Los ácaros del soplo (7×8) siguen siendo pequeños.
- Paleta de las capturas no medida con `medir.py`; todos los colores salen de rampas de `Palette` (sin hex en el fichero).
