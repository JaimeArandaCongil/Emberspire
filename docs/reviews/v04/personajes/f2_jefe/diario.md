# F2-JEFE · El Gran Fuelle (`great_bellows`) · diario

Encargo C9 (`director/f2_rev/dictamen.md`): jefe de 150–200 px en rig, un fuelle de verdad, 4–7 partes, fase 2 legible. Antes:
legado de 105×116 con rayas de tramado (nota 2,5).

## Entrega

- Definición: `scripts/art/defs/bosses/great_bellows.gd` (grupo `bosses`; el horneador y `SpriteBank` ya descubren la carpeta).
- Horneado: `assets/baked/bosses/great_bellows{,@phase2}_{idx,prev}.png` + `great_bellows.json`; entrada nueva en
  `assets/baked/manifest.json` (sólo se añade esa entrada); hoja de QA `tests/art/out/qa/great_bellows_qa.png`.
- Evidencia en esta carpeta: `hoja_revisada.png` (fotogramas clave de las dos fases, ×1), `silueta_cuarto.png` (silueta a 1/4,
  fila de arriba la fase 1 y la de abajo la fase 2), `14_boss_summon.png` (captura en combate del recorrido, 1280×720).

## Diseño

Fuelle de palanca de forja mayor, hecho criatura. Mira a la izquierda. Partes animadas (7):
1. **Caballete** de hierro con cuatro patas de garra dobladas como de bestia y travesaño.
2. **Tabla inferior + cabezal** (la cabeza): bloque en cuña herrado, ceño de hierro inclinado, dos brasas por ojos (sello con vistas
   `open/wide/squint/dead`) y rejilla al rojo.
3. **Tapa**: canto + cara en pera vista desde arriba, zunchos remachados y argolla.
4. **Cuero en 4 pliegues**: cuñas que se reparten la apertura (θ·(2k+1)/8). Siempre tapan el hueco y asoman en zigzag por detrás.
   Brasas en las juntas.
5. **Tobera** de cobre con anillos de latón apagados y boca al rojo (4 vistas: el fuego nunca repite fotograma).
6. **Balancín y cadena**: varillaje resuelto en `_mech()` con la cadena de largo fijo (52 px). El balancín gira lo justo para la
   apertura de la tapa. Los eslabones son sellos a lo largo del hueso `rod`, sin rotar píxeles.
7. **Contrapeso** de piedra zunchada que cuelga del otro brazo, siempre vertical.

Medidas (hoja `prev`, reposo f0): **252×180 px** de arte (≤ 280 de ancho; cuerpo de 180 a 185 px de alto según la respiración).
Pies en y 196 del lienzo de 340×204. 113 colores en total entre las dos fases, todos de rampas de `Palette`; ningún hex a mano.

Animaciones: 34 fotogramas por fase, 68 en total (§12 pide 50–70 por jefe):
`idle` 6, `cast` 2, `attack` 4 (impacto en f2 = `IMPACT_FRAME`), `hurt` 2, `summon` 6, `choke` 6 y `death` 8.
- Reposo: inspira despacio (la tapa sube, los pliegues se abren y el contrapeso baja) y espira con un bufido de humo. Ojos
  entornados al soplar y forja que late.
- Ataque: inspira con el peso atrás (+5), cierra de golpe avanzando 9 px con los pies plantados (las patas compensan) y escupe un
  chorro de fuego.
- Invocación: inspira hondo y escupe dos ácaros-vela que salen volando de la tobera en tres posiciones.
- Ahogo: nube de hollín de 8 masas que crece, se extiende y se queda con chispas.
- Muerte por material: la forja revienta la tapa, la tapa sale volando y el caballete cede. Queda un montón de tablas, poste y
  contrapeso con la forja apagándose.

Fase 2 (`@phase2`, misma caja y otra silueta): tapa reventada por detrás (borde dentado), cuero roto con la forja al aire y llamas
de 44×40 sobre la tapa (4 vistas que suben), contrapeso caído al suelo con la cadena rota, grietas al rojo en la tabla inferior y
ojos al blanco.

## Iteraciones (una hoja por iteración)

1. Se reconocía el fuelle, pero el hierro salía casi blanco, las patas parecían de mesa, la cara medía 2–3 px, el cuero no se
   distinguía de la madera y la fase 2 casi no cambiaba.
2. Hierro con tope de paso 5, patas en dos tramos con rodilla y garra, cuero un paso más oscuro con bisel 4 y zigzag trasero, tablas
   más gruesas y cara de la tapa más alta. Llamas de fase 2 al doble. Faltaba: tobera rayada en amarillo («zanahoria») y ojos
   pequeños.
3. Cabezal en cuña con ceño inclinado y ojos de 4–5 px. Latón con tope 3 y un anillo menos. Hollín más plano y ácaros mayores.
4. Lienzo de 340 px, porque el contrapeso rozaba el borde derecho y la nube de hollín se salía. Poste más cerca y brazo del
   contrapeso de 24. Reposo f0 sin humo, para que `body_rect` no lo cuente al centrar.

## Comprobado

- `tools/qa.sh bake --only=great_bellows`: 1 horneada, 0 con errores.
- `tools/qa.sh all`: QA de juego con 1745 comprobaciones y 0 fallos; arte con 5 suites y 0 fallos.
- Recorrido `smoke.tscn` con `SHOTS_DIR` propio: sin errores (salvo el `ERR_CANT_OPEN` de audio, ya conocido). En
  `14_boss_summon` el jefe nuevo sale con `palette_lit`, centrado y sin pisar a los dos ácaros invocados.

## No comprobado / pendiente

- **Fase 2, `summon` y `choke` no se ven en juego**: hace falta integración (abajo). Sólo están revisados en la hoja.
- Tiempos en movimiento: no los vi en vivo. Las duraciones son las de la definición.
- Los ácaros del soplo (7×8 px) son pequeños. Si en juego no se leen, conviene sincronizar el `SummonFX` con el f2 de `summon`.
- No medí la regla de ≤ 3 planos por masa ni la de facetas ≥ 24 px²: el motor las aplica al hornear.

## Necesidades de integración (no tocadas: no son de este paquete)

1. `scripts/ui/fighter_view.gd`: falta el **cambio de fase**. Al bajar de la mitad de PV (o con la señal de fase del motor, si
   existe), hay que cambiar `_anim.sprite_frames = SpriteBank.sprite_frames(_baked_id, true, &"phase2")` conservando la
   animación en curso; `SpriteBank.sprite_frames` ya acepta la variante. Se puede encadenar con `hurt` como transición.
2. `scripts/ui/screens/combat_screen.gd`, turno enemigo (~l. 818–823): toda intención que no sea ataque llama a `v.gesture()`, que
   reproduce `cast`. Falta reproducir `summon` si el movimiento lleva `summon` y `choke` si lleva `choke`. Ese movimiento también
   ataca, así que hoy entra por `lunge()`. Propuesta: `FighterView.gesture(anim := &"cast")` usando `has_animation`.
3. Banda de intención de jefe (y 22–44): la intención sigue saliendo sobre la cabeza (`_place_intent` / `_intent_y`). El jefe
   exporta el socket `intent` (punta del poste, y ≈ 14 del lienzo) por si se quiere anclar ahí, pero la banda es fija y la
   decide el HUD.
4. `scripts/art/sprite_bank.gd` `part_frames()` es un esbozo: no devuelve fotogramas. Por eso el jefe es **un único rig** con 7
   partes animadas por huesos, en una hoja que la integración actual ya pinta, y no un `part()` multiatlas. Si dirección quiere
   multiatlas de verdad, primero hay que completar `part_frames` y la composición en `fighter_view`.
