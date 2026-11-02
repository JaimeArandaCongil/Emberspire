# F2-REV3 · Tercera revisión del corte de combate del acto 1

Rama `main-0nvhs9`, base `c5414e3`. Las 29 capturas de `screenshots/` (SMOKE OK, xvfb + llvmpipe: valen para imagen, no para
rendimiento) no se regeneraron. Coordenadas: **px** = pantalla 1280×720 · **art** = mundo 640×360 (= px // 2).

**Veredicto: PASA a fase 3.** Las diez familias llegan a ≥ 8 (tabla abajo). Cuatro lo hacen justas (criaturas, cartas, efectos y
conjunto, todas a 8). Quedan tres defectos menores sin efecto en la nota (N6, N7 y N8). Deben cerrarse en el primer paquete de fase 3
que toque esos archivos (lista al final), no en otra iteración del corte.

## Reproducir

```
REPOSO_DIR=/tmp/claude-0/shots_rev3/reposo ROTULO_DIR=/tmp/claude-0/shots_rev3/rotulo \
  python3 -I docs/reviews/v04/director/f2_rev3/medir.py
```
Tarda unos 9 s. Dos ejecuciones seguidas con las mismas variables dan el mismo `mediciones.json` (md5 `7659bf566d7186ad3122277d76496e5d`).
- `REPOSO_DIR`: opcional, para C20. Sin ella no se escribe `C20_reposo`.
- `ROTULO_DIR`: opcional, para los rótulos de turno. Sin ella no se escribe `rotulos_turno`.
- Las carpetas son capturas propias de `tests/art/vida_capturas.tscn`, con la orden de `CLAUDE.md` y `VIDA_DIR=<carpeta>` (la herramienta
  lee `VIDA_DIR`, no `SHOTS_DIR`). `reposo` va a `--fixed-fps 30`; el resto, a 60. Modos capturados en `/tmp/claude-0/shots_rev3/`:
  `reposo` (360 f), `golpe` (42), `jefe` (42), `estado` (16), `cola` (40), `rotulo` (100), `rotulo_jefe` (100), `fase2` (14) e
  `invoca` (31). Ninguno da errores salvo el `ERR_CANT_OPEN` de audio. No se versionan: si se pierden, se regeneran con la misma orden.

## Cambios en `medir.py` respecto a F2-REV2 (el método no cambia)
- **Cola de flotantes** (F2-VIDA4): en `ZONAS_EXTRA["10b_enemy_turn"]` se retiran «flotante_3» y «+Hollín sobre la cara», que ya no
  existen. Se miden «+9» (px 680–712 × 114–134), el «+Hollín» viejo (652–720 × 194–216) y el nuevo (652–748 × 240–270), los tres
  encima de la intención.
- **Rótulos de turno** (F2-VIDA5): son transitorios y no salen en el recorrido. Con `ROTULO_DIR`, `rotulos_turno` busca la placa por su
  borde `plate 5` en la banda (px y 40–91) y mide la caja, la paridad, los bloques 2×2 rotos y el contraste.
- **Jefe más grande** (F2-JEFE2): `C9_jefe_cuerpo_sin_grua` toma como lomo la fila más alta con una racha vertical de ≥ 3 px en
  art x 400–461, a la izquierda de la grúa, que empieza en x 462. Es una **cota inferior**: bajo el balancín el lomo sigue subiendo.
  La zona del jefe en `medir_disposicion` no cambia: el cuerpo entra en art x 280–604.
- La nota de C19 incluye la cifra de F2-REV2 y el objetivo (≤ 12).

## md5 de las capturas

| Captura | md5 | Tipo |
|---|---|---|
| 01_title | c26db6f23ef12549e30141c2eb99f591 | fase 3 |
| 02_forge | 9d47c5136a33e025665f654b5f6b503b | fase 3 |
| 03_forge_archive | d4c2ccfb6981fd1d86fac665db89616e | fase 3 |
| 04_forge_chronicle | e96d98136d71c5bfb8c2ed88067107b3 | fase 3 |
| 05_antesala | 39d659b06a0322159bdafad17f24979d | fase 3 |
| 06_map | 16e82a467dbcaee3cbbaeacb0465968b | fase 3 |
| 07_combat | 7b1675ef95c717cf170adf76e0b1d886 | **corte** |
| 07b_glow | ce667a52017f90a7094ac941eaa6da07 | **corte** |
| 08_combat_hover | fee478bce8bef6ef24d55ae3a2e9c5af | **corte** |
| 09_burn | 8ba4794539049d4789323a1315635500 | **corte** |
| 09a_block_toss | e89f917babca45a7431595721afef924 | **corte** |
| 09b_burn_flight | e01f08fa6491026fe937f4ddaf786148 | **corte** |
| 10_swing | b5e507f6e682a623f29651eadb8d9b02 | **corte** |
| 10b_enemy_turn | 095b8e381f1b35321018e3b001a85b4b | **corte** |
| 11_after_enemy_turn | d4c9573bcefd71d6b1f8da4c33e72ea4 | **corte** |
| 12_death_dissolve | 355f5af185d28726166a5aa168466850 | **corte** |
| 13_rewards | 47633ced4b86e9f2a90158bf90658627 | **corte** |
| 14_boss_summon | 08ab6cb73ac177cab6ccc5f670c2b9ab | **corte** |
| 14a_summon_reveal | c74956b27e7ea2460f19498917adacf1 | **corte** |
| 15_boss_relics | d0843eb1b71d6cf714c1fbddedfd4b0b | fase 3 |
| 16_act2_hydra | 6e3a23c9f45f21c64e77450ab856f4dd | legado |
| 17_act3 | f14251cb321469729d295596f14a9ea2 | legado |
| 18_frost_king | f150ed92bf17516945293427fb872dd6 | legado |
| 18b_hero_death | 522d49ef0e90e10be88df561b88ae896 | **corte** |
| 19_shop | 325b08138a66539c421012b5689fe07b | fase 3 |
| 20_rest | f73f01eabd635101ec491ba647ac6dbb | fase 3 |
| 21_event_forge_spirit | 834f198fdcb84fa1620324adb66c218c | fase 3 |
| 22_summary | 238ae5ec9f77acd23048d98281afc5c8 | fase 3 |
| 23_cards | 05180b0b33e80ff557d3280d1970b937 | fase 3 |
## Tabla por eje (corte del acto 1)

| Eje | F2-BASE | F2-REV2 | **F2-REV3** | Evidencia |
|---|---|---|---|---|
| **Composición** | 7 | 8 | **8,5** | Centros 350,0 / 461,0 / 571,5 (07). Intención a 18 / 18 / 20 px sobre la cabeza (norma 18). Jefe en art 333–572 (14), centrado entre los dos ácaros, sin pisar sus placas. Cola de flotantes encima de la intención (10b: «⚔10» en px y 286–310, «+Hollín» en 240–270 y 194–216, «+9» en 114–134); en `cola/` ningún fotograma pone un flotante sobre la cara. Rótulos de turno en art y 25–41: placa en px 568–712 × 50–82, borde medido en art y 27–38. Resta N6: la segunda barra del tutorial cruza los estandartes en 09 |
| **Escala** | 6 | 7 | **8** | Cuerpo del jefe sin la grúa **≥ 165 art** (lomo en art y 99 junto a la grúa, pie en 263; `C9_jefe_cuerpo_sin_grua`). Con la grúa, 240×187 (≤ 280 de ancho y ≤ 200 de alto). F2-JEFE2 mide 161–180 en el rig. Heroína 78 (74 + moño), gólem 87×89, urraca 53×49, limo 46×29 |
| **Legibilidad** | 7,5 | 8 | **8,5** | Todas las zonas de texto de 07, 08, 09, 10b y 13 pasan de 4,5:1. La más baja, «+9» de la cola, da 7,24. Rótulos: «Turno enemigo» 6,61 y «Tu turno» 10,56. Limo frente a suelo: 0,235 frente a 0,133 (antes 0,149 frente a 0,133). Ácaro: 0,251 frente a 0,094. Títulos largos en Mini ×2 de trazo 2 (13: 12 y 10 px de alto) |
| **Consistencia** | 7 | 8,5 | **8,5** | **Paleta al 100,000 % y 0 ajenos en las 15 capturas del corte** (antes 99,90–99,999 % en 08, 10, 10b y 13). Bloques rotos fuera de excepción: 0 % en 07, 07b, 08, 09, 09a, 10, 11, 13, 14, 14a y 18b. Quedan N7: la mano entera desfasada 1 px durante la recolocación (09b: 4,65 %, px 220–1039 × 580–719, fase 0,1 = 0,10 frente a 1,0 en la buena; antes 0,05 %). Y N8: flotantes grandes a ×3 (10b px 654–747 × 242–271; 12, tres «9999!»; 0,22–0,28 %) |

## Tabla por familia (corte del acto 1)

| Familia | F2-BASE | F2-REV2 | **F2-REV3** | Evidencia |
|---|---|---|---|---|
| **Heroína** | 6,5 | 8 | **8** | Sin cambios. C1 se mantiene: el daño cae en el f10 = `attack:2` (`golpe.log`). La reserva sigue: a ×1, en reposo, la cabeza del martillo junto a las botas (07, px ~330–352 × 488–522) |
| **Criaturas** | 6,4 | 7,5 | **8** (justo) | `soot_golem` 8,5: en el gesto la cara queda sobre el hombro y despejada, con el puño delante (10b, px 620–810 × 355–525; `f2_cria4/hoja_soot_golem_cast_ataque_x2.png`). `ash_slime` 8: tres lóbulos, labio cobrizo, brillo y cuerpo a 0,235 frente a 0,133 del suelo (07; 12 fotogramas de reposo propios: separado en todos, y el goterón no sale fuera del cuerpo en juego). Su lectura tira algo a medusa. `ember_magpie` y `candle_mite` 7,5, sin tocar. Polilla y murciélago no salen en el corte, 7,5 en hojas. Contraste a 1/4 bajo en `flame_moth` (0,093) y `soot_golem@sooty` (0,081) (`f2_sala2/diario.md`): a fase 3 |
| **Jefe `great_bellows`** | 2,5 | 7 | **8** | (a) Cuerpo ≥ 165 sin la grúa, cámara alta, patas gruesas, cabeza de 45×58 con ceño, ojos y mandíbula herrada, y tobera más corta (14; `f2_jefe2/hoja_revisada.png`). (b) El fleco pasa a 4 rollos de cuero con sombra. (c) Destello por pieza (fotogramas propios `jefe/golpe_009–016`): en el f10 la tobera sale blanca y el resto sube 1 paso; en f11–12 sólo la tobera; desde el f13, nada; las patas no se lavan. Ya he visto en combate la fase 2 en llamas (`fase2/`) y la invocación con bombeo y ácaro (`invoca/`) |
| **Sala y fondo** | 7,5 | 7,5 | **8** | C19: desviación **10,13** en px 780–1000 × 130–250 (07; antes 16,04; objetivo ≤ 12). El crisol pasa a art x 552, junto a la ventana. A ×1 el muro tras los enemigos ya no compite (07, 10b). El muro del tiro sigue plano y con saeteras (14): queda para fase 3 |
| **Forja** | 8,5 | 8,5 | **8,5** | Sin cambios. Resplandor: 3.233 de los 4.791 px de oro nuevos en art 16–223 × 48–255 (07b) |
| **Cartas e ilustraciones** | 6,5 | 7,5 | **8** (justo) | N4: Mini ×2 o nombre corto, 0 títulos en Pavesa (13: «Golpe de Escudo» y «Lluvia de Chispas» en Mini; «Guardia Ígnea» en Fragua). N2 y N3: en 08 sólo quedan rotos los bloques del cuerpo de carta en Pavesa (0,055 %); el tooltip y la cinta están en 0. `ffe173` desaparece (0 ajenos en 08 y 13). «Fuego Interior» ya es escena: hombro, antebrazo y llama sobre el muro (`f2_ilus3/fuego_interior_x3_y_34x23_antes_despues.png`), pero el brazo se pierde en sombra a ×1. Colores en pantalla 31/1 y 31/0 (±1 del recorte, como en F2-REV2) |
| **HUD e intenciones** | 6,5 | 8 | **8** | Rótulos breves en la banda superior: 450 ms; 0 fotogramas sobre flotantes, intenciones o reliquias en `rotulo` y `rotulo_jefe` (líneas `ROT`); placa en px pares y 0 bloques rotos (`rotulos_turno`). Cola sin solapes (`cola/`). Restan N6 y N8 |
| **Efectos** | 6 | 7,5 | **8** (justo) | Destello del jefe por pieza (ver jefe). Quemadura: lenguas de 5–6 px desde Q3. A 1/4, de 16 a 34 px de fuego claro en Q3 (`f2_vida4/quemadura_0_1_3_9_x2_y_1de4.png`; cifra del paquete, no la he vuelto a medir). Se distingue Q0 de Q3, pero no Q3 de Q9. Brasas: 78 componentes, 15 redondas de ≥ 4 px y una de 6×6 (12) |
| **Vida y animación** | 6,5 | 8 | **8** | C1 en `attack:2`. C20: media de 3.070 px por fotograma y pico de 9.389 frente al tope de 13.800 (`C20_reposo`). Gesto del gólem nuevo y goterón del limo |
| **Conjunto** | 6,5 | 7,5 | **8** (justo) | Por primera vez el jefe tiene masa de jefe, la sala deja respirar a las figuras y los textos no se pisan. Bajan el conjunto los restos de N6–N8 y el martillo junto a las botas |

## Correcciones de F2-REV2

| # | Estado | Prueba |
|---|---|---|
| #1 cuerpo del jefe | **cerrada** | ≥ 165 art sin la grúa (`C9_jefe_cuerpo_sin_grua`); rollos de cuero y cabeza más grande (14) |
| #2 destello del jefe | **cerrada** | `jefe/golpe_010–013`: sólo la tobera; patas sin lavar |
| #3 Quemadura a 1/4 | **cerrada** (justa) | Lenguas de 5–6 px; fuego claro a 1/4 de 16 a 34 en Q3 |
| #4 / N1 flotantes | **cerrada** | 10b y `cola/`: cola encima de la intención, sin solapes |
| #5 limo y gólem | **cerrada** | 0,235 frente a 0,133; base lobulada; cara del gólem sobre el hombro (10b) |
| #6 muro | **cerrada** | 10,13 ≤ 12 |
| #7 títulos y «Fuego Interior» | **cerrada** | 0 títulos en Pavesa; escena |
| N2 tooltip | **cerrada** | 0 bloques rotos (08) |
| N3 cinta | **cerrada** | 0 bloques rotos (08) |
| N4 títulos largos | **cerrada** | Decisión aplicada: Mini ×2 y `CardDB.short` |
| N5 dorso ajeno | **cerrada** | 0 ajenos en 10b (antes 244 px) |
| N6 segunda barra del tutorial | **abierta** | Sigue en 09: «Cada carta que quemas…» en px ~385–890 × 128–146, sobre los estandartes. Ningún paquete la tenía asignada |

## C1–C20

| C | Estado | Prueba |
|---|---|---|
| C1 | cerrada | `golpe.log`: el f10 = `attack:2`, con `damage` |
| C2 | **cerrada** (antes parcial en el jefe) | `jefe/golpe_010–013` |
| C3 | cerrada | Sin cambios (09a) |
| C4 | cerrada | 18b: 80×28 art |
| C5 | **cerrada** (antes parcial) | Base lobulada, brillo, labio y 0,235 frente a 0,133 |
| C6 | **cerrada** (justa; antes parcial) | Lenguas visibles a 1/4 en Q3; Q3 y Q9 casi iguales a esa escala |
| C7 | cerrada | — |
| C8 | cerrada | `tools/qa.sh art` en verde; 31/1 y 31/0 en pantalla, dentro del margen del recorte |
| C9 | **cerrada** (antes parcial) | Cuerpo ≥ 165; multiparte con fase 2, vista en combate (`fase2/`) |
| C10 | cerrada | «Fuego Interior», ahora escena |
| C11 | cerrada | 07b: el oro, en la Forja |
| C12 | **cerrada** (antes parcial) | 10b: cara sobre el hombro |
| C13 | cerrada | Ácaro a 0,251 frente a 0,094 |
| C14 | cerrada, con reserva | Martillo junto a las botas a ×1 (07) |
| C15 | cerrada | Sin cambios |
| C16 | cerrada | Ayuda sólo en el tutorial; ver N6 |
| C17 | cerrada | Hueco de 24 px entre «Tajo Ígneo» y el orbe |
| C18 | cerrada | 15 redondas de 78 |
| C19 | **cerrada** (antes parcial) | 10,13 en la sala normal. El muro del tiro, aparte (fase 3) |
| C20 | cerrada | Pico de 9.389 ≤ 13.800 |

## Problemas nuevos
- **N7.** La mano no se ajusta a la rejilla mientras se recoloca: en 09b las cinco cartas van desfasadas 1 px en horizontal
  (4,65 % de bloques rotos; antes 0,05 %). Sólo pasa en movimiento y a ×1 no se nota, pero rompe la regla ×2. Origen probable: la
  interpolación de posición de la mano en `combat_screen.gd` (o `card_view.gd`) sin redondear a par.
- **N8.** Los flotantes grandes salen a ×3 (`UI.float_text`: `clampi(pixel_scale(size), 2, 3)`, `ui.gd:436`). Un px de arte da
  1,5 px de mundo y se sale de la rejilla 640×360 ×2. En 10b, además, conviven en la cola un «+Hollín» ×2 y otro ×3 (px 652–748 ×
  194–270). Ya pasaba en F2-REV2 en 12 («9999!»), pero entonces no lo marqué. Corrección: tope en ×2, o ×4 para los críticos.
- **Reserva**: el «+9» de la cola sube hasta justo debajo de la barra de ayuda (`cola/full_cola_turno_063`). No la pisa.

## Veredicto: **pasa**. Pendientes para el primer paquete de fase 3 que toque estos archivos (por prioridad)

| # | Paquete sugerido | Archivo | Qué |
|---|---|---|---|
| 1 | `art-integrator` | `scripts/ui/ui.gd` (`float_text`, l. 436) | N8: flotantes como mucho a ×2 (o ×4), todos con la misma escala en la cola |
| 2 | `art-integrator` | `scripts/ui/screens/combat_screen.gd` (recolocación de la mano) y `scripts/ui/card_view.gd` | N7: posiciones de la mano redondeadas a par en cada fotograma |
| 3 | `art-integrator` | `combat_screen.gd` (barra del tutorial de quemar) | N6: unirla a la barra de ayuda (px y 94–112) |
| 4 | `creature-artist` | `scripts/art/defs/hero/**` | Reserva de C14: cabeza del martillo separada de las botas a ×1 |
| 5 | `creature-artist` | `flame_moth.gd`, `soot_golem.gd` (variante `sooty`) | Contraste a 1/4 de 0,093 y 0,081 |
| 6 | `world-artist` | `bg_act1.gd` (tiro) | Muro del tiro y saeteras |

## Fuera del veredicto
- **Legado de los actos 2 y 3** (16, 17 y 18): paleta exacta del 29,9 / 29,9 / 29,4 % y píxeles ajenos del 6,6 / 31,5 / 21,9 %.
- **Pantallas de fase 3**: paleta exacta entre el 5,2 % (01) y el 48,5 % (23); bloques rotos entre el 1,3 % (15) y el 15,0 % (04).
  `15_boss_relics` está al 100 % de paleta.

## QA
`tools/qa.sh all` sobre `c5414e3`: **QA 1745 comprobaciones, 0 fallos; ARTE 5 suites, 0 fallos.**

## No comprobado
- No he medido de nuevo la Quemadura a 1/4: cito la cifra de F2-VIDA4. Sólo he visto su hoja.
- Ataques de murciélago, polilla, ácaro y urraca en movimiento; victoria; Maestría.
- Las variantes de sala distintas de la normal v0 del ciclo I (sólo en la hoja de F2-SALA2).
- GPU real, WebGL y otras resoluciones.
- El lomo del jefe es una cota inferior medida en la captura; el alto exacto (161–180) es el de F2-JEFE2 en el rig.
