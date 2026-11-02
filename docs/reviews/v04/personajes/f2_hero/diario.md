# F2-HERO · Diario (fase 2, segunda iteración)

Archivo tocado: `scripts/art/defs/hero/fogonera.gd`. Rehorneado: `assets/baked/hero/fogonera*` y la entrada `fogonera` de
`assets/baked/manifest.json`. Altura sin cambios: 74 + moño (bbox de `idle` f0: y 12–89, 78 px).

## C3 · Martillo sin teletransporte
- Fuera `hf` en `cast`, `toss_back` y `toss`. El brazo cercano repite el de `idle` (martillo en x ≈ 61). La mano lejana hace el gesto.
- `cast`: alza la mano lejana abierta. `toss_back`: mano junto al hombro oeste. `toss`: brazo tendido al oeste, la cabeza se inclina hacia atrás y la mirada va al oeste (vista nueva `w` de la cara, iris a la izquierda en los dos ojos).
- Socket `hit` (cara del martillo): `idle` 71,77 · `cast` 70,78 · `toss` 70,78→68,78 · `hurt` 67,77. Antes había un salto de ~30 px.

## C14 · Cabeza de maza
- `_hammer()`: caras ensanchadas con chaflán y cintura en el ojo del mango, en vez del bloque de 17×10. El mango es 3 px más largo y asoma delante del borde del delantal. Quito `groove`.
- `hit` y las estelas pasan a `HAMMER_HEAD = 22` (antes 21).

## C4 · Muerte (8 fotogramas, 90/110/160/110/80/90/160/500 ms)
- Secuencia: tambaleo → rodillas que ceden → de rodillas, apoyada en el martillo → lo suelta y se vence (el martillo vuelca) → cae (el martillo rebota en el aire) → de bruces y de costado → se asienta (rebote pequeño del martillo) → quieta, con el fogón apagado.
- Bbox: f0 48×78 → f2 57×68 → f4 73×49 → f5–f7 89×32–33 (incluye la sombra; sólo el cuerpo mide ~27). La silueta final queda claramente horizontal.
- Píxeles distintos entre fotogramas consecutivos: 2227, 2013, 2043, 2237, 2468, 638, 583.
- Técnica: clave `root` (gira la raíz, cadera incluida), botas con ángulo absoluto (`ft_*`, la rodilla se calcula como en el IK) y martillo soltado en una cadena sin piezas `hd1 → hd2 → hammer_d` colgada de la raíz. `_keys` la resuelve para dejar la cabeza del martillo donde caiga. Tumbado, el martillo se ve de punta (`hbox_d`).
- Los sellos no giran, así que cara (ojos cerrados), gafas y mechones tienen un duplicado `*_r` girado 90° exactos (sin remuestreo) que sustituye al original cuando `rot > 0,5`.

## Comprobado
- `tools/qa.sh bake --only=fogonera`: 0 errores. `tools/qa.sh game`: 1745 comprobaciones, 0 fallos.
- `tools/qa.sh art`: 3 fallos en `test_ui.gd` («UI.label debe usar Pavesa», «tema: fuente por defecto Pavesa»). Vienen de cambios ajenos sin cerrar en `ui.gd`/`test_ui.gd` (decisión Mini ×2), no de la heroína.
- Hoja revisada: `hoja_cast_toss_hurt_muerte_x2.png`. Recorrido `smoke.tscn` en `/tmp/claude-0/shots_hero`; copias en esta carpeta: `07_combat`, `09a_toss`, `18b_hero_death` y `recorte_heroina_07_09a_10_18b.png`.

## No comprobado / pendiente
- La muerte sólo la he visto en fotogramas y en la captura final; no en movimiento. El destello que la tapa es de F2-VIDA (`fighter_view.gd`).
- Al quemar, la mano «abierta» a escala de juego se lee casi como un puño.
- El martillo tumbado (de punta, 9×9 + mango) es pequeño. Se lee en la hoja ×2, menos a ×1.
- `tests/art/out/qa/fogonera_qa.png` lo reescribe el horneador.
