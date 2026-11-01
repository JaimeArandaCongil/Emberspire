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
