# Diario de PER (personajes y criaturas) — v0.4

## Fase 0 · Propuesta y debate
- `propuesta.md` y prueba de concepto en `tests/_review_art/v04/personajes/`: Fogonera en 3 poses, Gólem de Hollín en reposo y telegrafía, boceto del Carbonero.
- `ronda1.md`: crítica del gólem de TEC y del DA, 13 funciones exigidas al motor, disposición en px.
- Resolución: motor de TEC con mis 13 funciones y 7 condiciones; jefes de 150–200 px; heroína de PER con enmiendas de DA.

## Fase 1 · Trabajo independiente del motor

### Biblioteca de sellos — `scripts/art/defs/stamps/stamp_lib.gd`
- **Formato** compatible con el `Stamp` de TEC: `{rows, legend: {char: [material, paso|"LINE"|"+1"|"-1"]}, anchor, faces}`.
- **Ranuras `@x`** (`@hand`, `@metal`, `@socket`, `@mouth`, `@horn`): el mismo sello sirve para piel, tizne o roca. Los pasos se escriben en escala de 6 y se reescalan a la rampa real (`resolve_step`).
- **`MAT`:** único punto de correspondencia con los ids de `Palette`. No hay ningún hex escrito.
- **31 sellos:**
  - 4 caras de la Fogonera (¾ neutra, esfuerzo, herida, perfil);
  - 6 manos y garras (abierta, agarre, agarre visto por nudillos, puño, índice, garra de 3);
  - 7 ojos (heroína 1×2, brasa 2×1 y 2×2, urraca, rendija, ojo fundido);
  - 6 piezas de metal (remache, remache 2×2, perno, hebilla, hebilla pequeña, bisagra);
  - 4 bocas (rejilla de fuego, fila de colmillos, par de colmillos, sonrisa de diablillo);
  - 3 cuernos (rizado, cristal, carnero);
  - 7 piezas de la heroína (farol de cinto, gafas, asas del fuelle, 3 mechones).
- **Vista previa:** `img/sellos_x8.png` (orden en `img/sellos_orden.txt`). `validate()` sin errores.

### Fogonera final — `scripts/art/defs/heroine/fogonera.gd`
- **Iteración 1:** la cara de 12 px quedaba calva (la frente ocupaba la fila 0) y el rubor `fire 3` se leía como herida. La nariz era un hocico de 3 px. El martillo en `steel` (cálido) se confundía con el mango.
- **Iteración 2:**
  - el flequillo pasa a la fila 0 del sello;
  - sin rubor;
  - nariz de 2 px;
  - el ancla del ojo se mueve 2 px atrás para que la cara no sea más ancha que el cráneo;
  - martillo en `iron`, con collarín de `steel`;
  - reposo al hombro con el martillo por detrás de la cabeza (la mano tapaba la cara);
  - fuera la mancha `k` de la barbilla.
- **Resultado:** `fogonera_final.md` y las imágenes de `img/`.
- **Pruebas:** `tests/art/test_per.gd`, que comprueba sellos, caras ≥ 10×10, ojo con brillo y, en cada pose, paleta cerrada, pies en y 89–91 y alto 64–80. **Pasa (0 fallos).**

### Notas para el resto
- Los errores de compilación de `scripts/ui/ui.gd` (UIKit) y de `scripts/art/legacy/*` que salen al ejecutar las herramientas son de trabajo en curso de otros expertos. No afectan a mis scripts.
- No he tocado `project.godot`.

### Port al motor de TEC (hecho)
Definiciones en `scripts/art/defs/hero/fogonera.gd` y `scripts/art/defs/creatures/`. `proto_rig.gd` y `preview_per.gd` borrados.

| Id | Lienzo | Animaciones | Rasgo vivo |
|---|---|---|---|
| `fogonera` | 96×96 | idle, idle_shoulder, windup, smear, strike, recover, attack, cast, toss, hurt, death | respiración, moño y bufanda con retardo, farol |
| `soot_golem` | 112×112 | idle, cast, attack, hurt, death | humo de chimenea, gota de hollín, puerta que late, parpadeo |
| `ember_magpie` | 88×64 | idle, cast, attack, flee, hurt, death | gira la cabeza a saltos, guiño, cola, botín que destella |
| `ash_slime` | 72×60 | idle, cast, attack, hurt, death | respira, burbuja del cráter, brillo húmedo, goterón, parpadeo |
| `candle_mite` | 48×48 | idle, cast, attack, hurt, death | llama de 3 fotogramas, cera que gotea, antenas |
| `cinder_bat` | 104×96 (sin suelo; cuerpo en y = 54) | idle, cast, attack, hurt, death | aleteo, chispas por los agujeros, núcleo, parpadeo |

El encargo decía `ember_bat`; el id real de `enemy_db` es `cinder_bat`, y ése es el que uso.

**Decisiones por iteración (mirando las hojas):**
- **Fogonera:** el martillazo daba la vuelta por debajo del cuerpo porque el ángulo se interpolaba por el camino largo; `_unwrap()` lo manda por arriba. La estela salía a puntos con 16 muestras: uso `samples = 64`. La mano cercana tapaba la cara en la carga (sello siempre encima): se oculta en esa pose. Parche gris en la cara por la luz fría: cráneo con `flat 0.95`. La franja al rojo asomaba entre las piernas con el martillo en la mano lejana: se oculta.
- **Gólem:** el aro del codo salía blanco por especular: sin `spec`. Ladrillo con techo de paso 6 y hollín alrededor de la chimenea. Cabeza por delante del brazo. La muerte se salía del lienzo: las extremidades se ocultan por tramos y quedan escombros.
- **Limo:** la primera versión se leía como un **excremento de emoji** (lóbulos apilados, marrón, sonrisa). Rehecho como losa a mano: alquitrán de carbón con costra de ceniza, sin boca en reposo.
- **Ácaro:** salía como un huevo con patas. Ahora es un caparazón bajo que carga un cabo de vela.
- **Murciélago:** con las dos alas al mismo lado parecía un pájaro. Ahora van una a cada lado, con membrana más profunda y más clara.
- **Urraca:** cuerpo horizontal tipo paloma. Ahora va erguida, con cola larga hacia abajo, pecho blanco y filo blanco en el ala.

**Evidencia:** `img/reparto_x3.png` (siluetas), `img/<id>_sheet_x3.png`, `img/<id>_keys_x4.png`, `img/*_zoom_x8.png`. Pruebas al cerrar esta sesión: ver el informe final.

### Avisos para TEC (no he tocado `scripts/art/rig/`)
- `Smear.samples` por defecto (16) da estela a puntos en arcos largos; `RigBuilder.smear()` no lo expone por opción: lo fijo en el objeto devuelto. Convendría muestrear según la longitud del arco.
- Los sellos sólo admiten vistas por hueso (`view:<hueso>`): en el limo, ojos y brillo comparten hueso y por eso comparten clave. Sería útil una vista por sello.
- Las losas no tienen vistas: las deformaciones del limo son 4 losas que se ocultan y muestran.
- Rotar un sello no es posible (ya avisado).

### Sin revisar
- Las animaciones sólo se han visto como fotogramas en hojas, no en movimiento ni en el juego con el shader `palette_lit` y fondos reales. La integración en combate es de TEC.

## F2-CRIA: correcciones de la prueba ciega (criatura_1, 2, 3)

### Discrepancias con el encargo
- **`shape` de `ash_glutton` NO cambiado** (sigue `"slime"`). Probado: con `"shape": "ash_glutton"`, `tools/qa.sh game` da `FALLO: forma de enemigo existe: ash_glutton` (`tests/test_runner.gd:53` exige `Art.has_shape`, y `SHAPES` está en `scripts/art/legacy/`, fuera del paquete). No hace falta: `fighter_view.gd:104` elige la hoja por `def_id`, no por `shape`; `shape` sólo es el respaldo legado (CLAUDE.md pide respaldo). `monster_texture` de `SpriteBank` no tiene llamadores. Comprobado en ejecución: `SpriteBank.has(&"ash_glutton") = true` y captura de combate con el arte nuevo. Si dirección quiere el campo cambiado, hay que tocar `Art.SHAPES` o la prueba.
- **El "montículo negro" de `07_combat.png` era `ash_slime`**, no `ash_glutton`: `tests/smoke.gd:55` pide `soot_golem, ember_magpie, ash_slime`. `ash_glutton` no sale en el recorrido y sólo aparece en encuentros del **acto 2** (`enemy_db.gd:99`), no en el acto 1. Por eso también retoqué `ash_slime`: más alto (26 px), costra con grietas de brasa y alquitrán dos pasos más claro.

### Por criatura
- **`hollow_knight`** (100 px, tope de élite; lienzo 152×160). Hierro con rampa no monótona (banda oscura de reflejo), brillos a mano paso 10 pegado a paso 2, 17 remaches sellados (hombrera, gola, faldón, escudo). Capa redibujada desde la gola con pliegues cada 7 px, borde oscuro y cola de golondrina; en ataque cae detrás. Antebrazo +2 px, mano sellada. Sin recortes. Muerte: rodillas → se desarma con el yelmo rodando → piezas planas y espada visible → coraza vacía con la brasa apagándose.
- **`ember_magpie`** (48 px, medio; lienzo 124×96). Más erguida, patas con talón, cuello y collar dentado, pecho poligonal con plumas de 2 px, cola en tres puntas con dos plumas de transición, abanico de tres primarias, halo en la brasa, huida contenida. Muerte: estallido de plumas, cae de costado, el botín rueda y se apaga por pasos.
- **`ash_glutton`** rehecho sin mirar la forma anterior (72 px, medio; lienzo 168×116; se quita la variante `sooty`, sin uso, y sus PNG). Cuadrúpedo con máscara de hueso a ras de suelo, colmillos, cresta de esquirlas de escoria (material del acto 2), panza colgante con costuras de brasa. Reposo: masticar y tragar. Muerte: costuras revientan, costillas y brasas al aire, esquirlas sueltas, montón de ceniza con cráneo.
- **Reposo y muerte en el resto.** `soot_golem` 8→6 f sin mecer el cuerpo, muerte nueva (grietas, bóveda hundida, muñón de muro con la puerta apagándose). `ash_slime` y `flame_moth` 8→6 f. `cinder_bat` y `flame_moth`: el cuerpo ya no gira al caer; se consume y queda un montón de ceniza. `cinder_bat` (90→140 ms) ya tenía 6 f. `candle_mite` (130→140 ms) ya tenía 6 f y muerte por material: sólo tiempo. Lienzos ampliados en las cinco para quitar recortes medidos en ataque y muerte (`flame_moth` tenía el último fotograma vacío).

### Comprobado
`tools/qa.sh all` en verde (1745 y 5 suites), `bake_art --check` al día, `tests/smoke.tscn` sin errores, hojas revisadas (`img/*_sheet_x3.png`), medición por script de recortes en todos los fotogramas (0) y captura de combate con `hollow_knight` + `ash_glutton` y con el trío del recorrido. Script y capturas fuera del repo.

### No comprobado
- Animación en movimiento: sólo fotogramas. Tampoco vi las muertes dentro del combate real, con `HitFX` y el retiro del actor.
- Criterio de 10 evaluadores a 32 px: sólo mi propia lectura.
- `cinder_bat`, `candle_mite` y `flame_moth`: revisé hoja y métricas, no su diseño ni su aspecto en combate.
- `tests/art/out/qa/*` lo reescribe el horneador: cambia aunque esté fuera del paquete.
- El otro agente tiene cambios sin cerrar en `palette_lit` y `fighter_view`: el aspecto en combate puede variar.

### Pendiente
- `soot_golem` mide 88 px y es normal: §8 da medio ≤ 72 y élite ≥ 80. Decisión de dirección.
- `ash_slime` ahora lee más a roca que a limo; la costra pálida se aprecia poco en combate.
- El abanico de la urraca aún recuerda a una mano.
- Los sellos no giran: oculto remaches y brillos en poses muy giradas, así que el caballero pierde detalle en ataque.

### Notas que creo alcanzables (mi estimación, no un dictamen)
`hollow_knight` 8, `ember_magpie` 8, `ash_glutton` 8. Ninguna con margen.
