# F2-CRIA2b · Diario (C13 `cinder_bat`, `candle_mite`)

## C13 · `cinder_bat`: membrana con masa
- Problema medido: alas de membrana fina, en rampa `rock_soot` 4/5 (valor ~0,20–0,27), casi igual que la piedra del arco y el ladrillo
  que tiene detrás (x 350). Era una figura del mismo valor que su fondo.
- Alas v2, redibujadas como losas ASCII nuevas (`IN` 19×24, `OUT` 23×21). Las saqué de un trazado de polígono con festones entre
  las puntas de los dedos y luego las retoqué a mano. La membrana está llena y baja hasta el tobillo, como en un murciélago real.
  Hay 3 dedos desde la muñeca, borde de ataque de 1 px, una vena de brasa por tramo y un agujero quemado con labio encendido.
- Valor: la membrana pasa a `rock_soot` 1, una mancha oscura, y el borde de ataque a `rock_soot` 6, un canto cálido que dibuja la
  silueta. Los dedos van en `rock_soot` 5. El ala lejana queda un paso por debajo (membrana 1, dedos y borde 3). El pelaje gris
  (`soot`), la cara, los ojos y los colmillos sellados no cambian. Así el cuerpo sigue separado de las alas.
- La envergadura no cambia en lo esencial (+4 px por ala). Atlas completo revisado (`atlas_cinder_bat.png`): reposo, telegrafía
  con alas plegadas, ataque en dos pasadas, golpe y muerte en pavesas. Nada se recorta en el lienzo de 124×128.
- Probé el pelaje en `smoke` (un paso más oscuro). Daba sólo +0,004 de Δ y se perdía la separación entre cuerpo y alas, así que
  lo revertí.

## C13 · `candle_mite`: cuerpo que se separe del suelo
- Caparazón v2: 18×10, antes 16×8. Tiene 2 filas más de lomo abombado y pasa de cuero 1/3/4 a **cuero 3/4/5 con canto cálido 6**
  en la fila superior. Es el sel-out cálido de C13 y suma +2 pasos.
- Cabeza +2 pasos (cuero 3/5/6). El ojo de brasa sigue sellado.
- La vela se retrasa 2 px (hueso `candle` (1,-4) → (3,-4)) para que el lomo se vea delante de ella; antes la cera tapaba el
  caparazón.
- Patas, mandíbulas y antenas pasan de `boot` a `leather`, un material más claro de la misma familia. Es un cambio de material de
  la pieza, no un recoloreado para crear contenido.
- Atlas revisado (`atlas_candle_mite.png`): telegrafía, salto, golpe, estallido de la mecha y charco sin roturas.

## Medida de contraste (gris, criterio de §4.1)
Método: localizo la criatura en la captura ajustando el borde de alfa de cada fotograma de reposo horneado al color `OUTLINE` de
la captura. Después repito `test_da.thumbnail_separation`: luminancia media de la figura frente a un anillo de 2 celdas a 1/4
(160×90). El anillo excluye cualquier celda que toque la figura. También mido a resolución nativa con un anillo de 3 px.
- «Antes»: `18b_hero_death` del recorrido, con el atlas de HEAD. «Después»: 12 capturas a 70 ms del mismo combate (piso 4,
  bat/moth/mite), que cubren los 6 fotogramas de reposo.

| Medida | Antes 1/4 (nativo) | Después 1/4 por fotograma f0…f5 | Después nativo |
|---|---|---|---|
| `cinder_bat` entero | **0,024** (0,047) | 0,081 · 0,108 · 0,125 · 0,108 · 0,106 · 0,089 (media **0,103**) | 0,109–0,147 |
| `candle_mite` sin cera ni llama | **0,007** (0,016) | 0,106 · 0,106 · 0,107 · 0,083 · 0,087 · 0,107 | 0,107–0,127 |
| `candle_mite` entero | 0,154 (0,184) | 0,200–0,219 | 0,232–0,253 |

El valor de la figura del murciélago queda fijo en ~0,137. Lo que oscila es el anillo: con las alas arriba (f0, f5) toca el muro
más oscuro (0,216 frente a 0,24–0,26). Para el ácaro, el «sin cera ni llama» excluye por color los píxeles de `linen` y `fire`.

## Evidencia
- `tools/qa.sh bake --only=cinder_bat,candle_mite`: 2 horneadas, 0 errores. `tools/qa.sh all`: juego 1745/0, arte 5 suites/0.
- En esta carpeta:
  - `antes_despues_combate.png`: arriba el 18b de antes, abajo el combate de después.
  - `gris_1de4_antes_despues.png`: miniatura en grises a 1/4, ampliada ×4.
  - `combate_murcielago_acaro.png`: captura completa.
  - `hoja_*_qa.png` y `atlas_*.png`.
- Recorrido completo (`SHOTS_DIR=/tmp/claude-0/shots_cria2b`): sin fallos. Sólo sale el `ERR_CANT_OPEN` de audio, ya conocido.

## No comprobado / pendiente
- A 1/4 no todo pasa de 0,10: el murciélago con alas arriba (f0 0,081; f5 0,089) y el cuerpo del ácaro en f3/f4, el fotograma
  en que baja 1 px (0,083/0,087). A resolución nativa todo pasa de 0,10. Para llegar en todos los fotogramas haría falta oscurecer
  el pelaje o la membrana hasta el paso 0, y eso borra el contorno. Otra vía es bajar 1 paso el muro tras x 350 (C19, F2-SALA).
- Sólo he medido la sala del piso 4 (variante del arco). En otras variantes de sala no está medido.
- Ataque y muerte de las dos criaturas: vistos en atlas, no en juego.
