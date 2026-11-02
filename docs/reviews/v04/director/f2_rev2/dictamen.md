# F2-REV2 · Segunda revisión del corte de combate del acto 1

Rama `main-0nvhs9`, base `fe7d6bd`. Las capturas de `screenshots/` son de `tests/smoke.tscn` en la nube (llvmpipe: valen para imagen,
no para rendimiento) y no se regeneraron. Para reproducir:
`REPOSO_DIR=<carpeta> python3 -I docs/reviews/v04/director/f2_rev2/medir.py` (unos 8 s) reescribe `mediciones.json`. `REPOSO_DIR`
es opcional y sólo hace falta para C20.
Coordenadas: **px** = pantalla 1280×720 · **art** = mundo 640×360 (= px // 2).

**Veredicto: NO PASA a fase 3.** Llegan a ≥ 8 la heroína, la Forja, el HUD y la vida. Se quedan por debajo las criaturas (7,5), el jefe (7),
la sala (7,5), las cartas (7,5), los efectos (7,5) y el conjunto (7,5). El salto desde F2-BASE es grande y medible: la paleta pasa de
98,8 % a 100 % y los bloques rotos de 1,69 % a 0 % (07). Lo que falta es poco y está localizado (lista al final).

## Capturas propias (fuera de `screenshots/`)
- `/tmp/claude-0/shots_rev2/golpe/`: `vida_capturas` en modo golpe a 60 fps fijos. La línea de registro del fotograma 10 dice
  `héroe=attack:2 eventos=energy,card_played,damage`; los fotogramas 0–7 son `attack:0` y el 8 y el 9 son `attack:1`.
- `/tmp/claude-0/shots_rev2/reposo/`: modo reposo, 360 fotogramas a 30 fps (C20).

## md5 de las capturas

| Captura | md5 | Tipo |
|---|---|---|
| 01_title | b6c89b69e57e90f85bc994c60f65153f | fase 3 |
| 02_forge | 21bac0ce68ebcc12624af68465428ea8 | fase 3 |
| 03_forge_archive | 8dc66d65f929e88218052d6f03179498 | fase 3 |
| 04_forge_chronicle | 55f2be0e3e1f831606ba074f2a4aff23 | fase 3 |
| 05_antesala | a7e051e94c2709713f90e4a401b04708 | fase 3 |
| 06_map | cff0e635bffe3ed8ee1b01d30cba5646 | fase 3 |
| 07_combat | 46b8259635fd1e22d87ee678a8403372 | **corte** |
| 07b_glow | dc482cd8a9c52f6beed10d96fed74d77 | **corte** |
| 08_combat_hover | afa84b37abe99b49d88a87dd38a9d0b1 | **corte** |
| 09_burn | 4040fd6cbdf183ba4f03b80a784bde4c | **corte** |
| 09a_block_toss | 1346902a39d748af338f91cee866df20 | **corte** |
| 09b_burn_flight | e09f951a7e02d882571f65cb0080d979 | **corte** |
| 10_swing | d1f06a6462f25dfcf13ec1c7bd90fe73 | **corte** |
| 10b_enemy_turn | 930823c4035065c9d4cbf9a0af012f24 | **corte** |
| 11_after_enemy_turn | c95b9fea6c54a6129ed42a809988a2e1 | **corte** |
| 12_death_dissolve | 5ab03ed016cb00abf06cca30df1f65fb | **corte** |
| 13_rewards | 1801f612fb741baa88f103a28194b16a | **corte** (transición) |
| 14_boss_summon | fff3e95748aa3519967d2f736b8dc5ed | **corte, jefe en rig** |
| 14a_summon_reveal | 7deba6a9fdd3377f1ea9a0b2ee22eeaa | **corte, jefe en rig** |
| 15_boss_relics | 4cb7d5a48950a2f8113d36724991dbe3 | fase 3 |
| 16_act2_hydra | a448f19acb675218876e53a6e9c9d369 | legado, acto 2 |
| 17_act3 | ed714d1e614408a29e3f178828c3c121 | legado, acto 3 |
| 18_frost_king | 0bf3dc1cee36f5cdb863cb90b226c924 | legado, acto 3 |
| 18b_hero_death | e06b102fdfd9d4ee10b6bf81fcfb080c | **corte** |
| 19_shop | ec7939c7421ba3a78e54a9ebeacd1679 | fase 3 |
| 20_rest | 333041d1f68f24be7fd705f9e01d6581 | fase 3 |
| 21_event_forge_spirit | 6a0d879ab29b4cf62242bef4d9eaa441 | fase 3 |
| 22_summary | 238ae5ec9f77acd23048d98281afc5c8 | fase 3 |
| 23_cards | 087a0f461f3e63034271a749c08da824 | fase 3 |

## Cambios en `medir.py` respecto a F2-BASE
- `ZONAS_HUD` y `ZONAS_EXTRA` se rehicieron para la disposición nueva:
  - rótulo de piso en la barra superior, px 462–818 × 3–24;
  - barra de ayuda en px 254–1026 × 94–112;
  - placas de PV en px y 530–552;
  - mano a paso 162: «Golpe» en px 282–342 y «Tajo Ígneo» en px 746–850;
  - zonas nuevas: contador superior, etiqueta de robo y, en 13, «VICTORIA» y el botón de quemar ofrendas.
  - En 10b ya no hay rótulo «Turno enemigo»; se miden la intención, los flotantes y el nombre.
- `zona_layout` separa ahora la banda de jefe (art y 22–44) de la barra de ayuda (art y 47–57).
- La disposición se mide también en 10b, 11, 14a y 18b.
- Medidas nuevas en `correcciones`:
  - `valor_cuerpo_fondo`: mediana de luminancia del limo y del ácaro frente a su suelo;
  - `C19_muro_tras_enemigos`: desviación de luminancia del muro tras los enemigos;
  - `C20_reposo`: píxeles cambiados por fotograma (sólo con `REPOSO_DIR`).
- El resto del método no cambia, para que las cifras sean comparables.

## Tabla por eje (corte del acto 1)

| Eje | F2-BASE | **F2-REV2** | Evidencia |
|---|---|---|---|
| **Composición** | 7 | **8** | Centros de enemigo 350,0 / 460,5 / 571,5 (07; norma 350/460/572). Heroína en 160,5 (art 141–180). Los pies en y 264. Intención a 19 / 19 / 21 px sobre la cabeza (07; norma 18; el limo encoge en reposo de 33 a 29 de alto). La intención del jefe está en la banda: calavera en px 897–913 × 52–72 = art y 26–36 (14). La barra de ayuda sólo sale en el tutorial y se borra al pasar `HINT_TURNS` (`combat_screen.gd:479`, `:1345`). Resta: «+Hollín» y otro flotante se apilan sobre la cara del gólem (10b, px 652–720 × 380–420), y en 09 hay una segunda barra de tutorial que cruza los estandartes (px ~385–890 × 128–146) |
| **Escala** | 6 | **7** | Heroína 78 = 74 + moño (decisión vigente). Gólem 87×89 (≤ 88 +1 de máscara). Urraca 52×49, limo 46×29. **Jefe 241×179 art (14, bbox 332–572 × 85–263)**: el ancho cumple (≤ 280), pero el alto incluye la grúa del contrapeso. **El cuerpo del fuelle mide ~135** (estimación a ojo: lomo en px y ≈ 255, pie en 527), por debajo de los 150–200 de cuerpo de la decisión. En la interfaz no queda ningún bloque roto en 07 |
| **Legibilidad** | 7,5 | **8** | 75 zonas de texto en 07, 08, 09, 10b y 13. Todas ≥ 4,5:1 salvo el flotante «3» de 10b (`8a7048` sobre `1a0f12`, 4,01:1 y 14 px de alto, válido para texto grande). Mínimos: «QUEMAS» apagado 4,51 (09), escudo de bloqueo 4,52, etiquetas Mini 5,34–5,78. Todas las tintas están en paleta (antes, `79392e` a 2,19:1). Sobra el rótulo «Turno enemigo». Resta: la base del limo se funde con el suelo (luminancia del cuerpo 0,149 frente a 0,133 del suelo, 07). El ácaro ya se separa (0,251 frente a 0,094, 18b) |
| **Consistencia** | 7 | **8,5** | **Paleta 100,000 %** en 07, 07b, 09, 09a, 09b, 11, 12, 14, 14a y 18b, y 99,90–99,999 % en 08, 10, 10b y 13 (en F2-BASE, 98,5–98,9 %). Bloques 2×2 rotos: 0,0 % (07, antes 1,69 %), 0,05–0,29 % en el resto del corte. Quedan cuatro restos: el tooltip QUEMAR desfasado 1 px en horizontal (08, px 552–765 × 444–457: fase 0,1 = 0,0); la cinta «HABILIDAD» de la carta alzada, 1 px en vertical (08, px 600–671 × 624–635: fase 1,0 = 0,16); títulos de carta largos en Pavesa ×1 (09, px 926–995 × 608–619; 13, tres títulos de recompensa); y la carta que vuela al descarte, rotada, con 244 px ajenos (`8a4a2a`, `5a2a1a`; 10b, px 948–999 × 544–591) |

## Tabla por familia (corte del acto 1)

| Familia | F2-REV | F2-BASE | **F2-REV2** | Evidencia |
|---|---|---|---|---|
| **Heroína** | 6,5 | 6,5 | **8** | C3: el martillo se queda en la mano cercana en `cast`, `toss` y `hurt`, y la mano libre apunta al oeste, hacia la Forja (`personajes/f2_hero/hoja_cast_toss_hurt_muerte_x2.png`, 09a). C4: tendida de rodillas al suelo, 80×28 art en 18b (antes 76×62). C14: maza biselada con mango visible (`f2_cria3/fogonera_puente_hombro.png`). Reserva: a ×1, en reposo, la cabeza del martillo queda a la altura de las botas y se lee como una tercera bota (07, px ~320–352 × 488–522) |
| **Criaturas** (media sin jefe) | 6,4 | 6,4 | **7,5** | `soot_golem` 8: ataque con preparación, estela y avance (`cartas_ui/f2_vida/c1_ataque_enemigo.png`); en el gesto la cara sigue a media altura y la tapa un flotante (10b). `ember_magpie` 7,5. `flame_moth` 7,5. `cinder_bat` 7,5: membrana gris con venas de brasa, se separa del arco a 1/4 (`f2_cria3/gris_1de4_18b.png`). `candle_mite` 7,5: cuerpo tostado de luminancia 0,251 frente a 0,094 (18b). `ash_slime` 7: ya es un domo con costra de ceniza, grietas y ojos siempre visibles (07, px 1100–1190 × 470–525), pero el borde inferior es recto, no se ve el brillo húmedo y la base se pierde en el suelo (0,149 frente a 0,133) |
| **Jefe `great_bellows`** | 2,5 | 2,5 | **7** | Ya está en rig (`personajes/f2_jefe/hoja_revisada.png`): fuelle de verdad, con tablas, pliegues que se abren, grúa de contrapeso que bombea, bocanada de hollín, fase 2 en llamas y muerte que se desploma. En paleta al 100 % (14). Resta para el 8: (a) cuerpo de ~135 sin la grúa, una cuña baja sobre patas finas con poca masa de jefe; (b) en reposo los pliegues comprimidos parecen un fleco de cerdas (14, px ~1040–1090 × 300–390); (c) el destello lava el jefe entero durante ~5 fotogramas, con las patas casi blancas (`cartas_ui/f2_vida3/jefe_destello_antes_despues_f9_10_11_12_14.png`, fila inferior). C2 pedía blanco sólo en la pieza golpeada |
| **Sala y fondo** | 7,5 | 7,5 | **7,5** | La rejilla del suelo se apartó de la placa (px 455–545 frente a la placa en x ≥ 625, 07). Hay variantes (`mundo_vivo/f2_sala/variantes_despues.png`). Pero la textura del muro tras los enemigos no baja: desviación de luminancia **16,04** en px 780–1000 × 130–250, frente a 16,08–16,23 antes de F2-SALA. A 1/4 el ladrillo sigue compitiendo (`f2_sala/gris_1de4_07.png`) |
| **Forja** | 8,5 | 8,5 | **8,5** | En paleta y en rejilla. El Resplandor sale ahora de ella: 3.180 de los 4.455 px de oro nuevos están en art 16–223 × 48–255 (07b) |
| **Cartas e ilustraciones** | 6,5 | 6,5 | **7,5** | C8: `tools/qa.sh art` en verde, con la regla de ≤ 30 colores verificada sobre el arte fuente; en pantalla, 31/1 (08 «Defensa») y 31/0 (13 «Golpe de Escudo»), dentro del ±1 del recorte. C10: las 4 nuevas son escenas (`cartas_ui/f2_ilus/ilustraciones_x3.png`, fila 4): «Golpe de Escudo» es la mejor; «Fuego Interior» sigue cerca de icono. C17: hueco de 24 px entre «Tajo Ígneo» (px 843) y el orbe (px 868). Restan los títulos largos en Pavesa ×1 de 10 px («Fuego Interior», 14; recompensas de 13) frente a Fragua ×2 de 16 px: contradice ART_BIBLE (Fragua para nombres de carta) y DECISIONES (Pavesa sólo en cuerpo y tooltips) |
| **HUD e intenciones** | 7 | 6,5 | **8** | Mini ×2 en todas las etiquetas (trazo 2 en las 19 zonas de 07). 0 % de bloques rotos en 07. Ascuas sin el color ajeno `1a0a04`. La intención del jefe está en su banda. Se retira el rótulo «Turno enemigo». Las recompensas (13) se apagan por pasos: paleta 99,997 % (antes, 23,4 %). Restan los flotantes apilados sobre el cuerpo (10b) y los desfases de 1 px del tooltip y de la cinta de la carta alzada (08) |
| **Efectos** | 6 | 6 | **7,5** | C2: un fotograma blanco y después el dibujo interior se conserva (`f2_vida/c1_c2_golpe_f8-17.png`). C18: brasas de 2–4 px, 12 redondas ≥ 4 de 84 componentes (antes, 34 de 57) y una sola de 6×6 (antes, 20) (12). C11 cerrada (ver Forja). C6: +90 px emisivos (317 → 407, gólem en 11) y lenguas visibles a ×1 en Quemadura 3 y 9 (`f2_vida/c6_quemadura_0_3_9.png`), pero **casi invisibles a 1/4** (miniaturas de esa hoja). Más el destello del jefe |
| **Vida y animación** | 6,5 | 6,5 | **8** | C1: el daño cae en `attack:2`, a ~167 ms de juego (captura propia en `golpe/`). C15: segundo reposo con puente (`fighter_view.gd:447–480`, `fogonera_puente_hombro.png`). C20: en 12 s de reposo, media de 2.984 px por fotograma (1,29 %) y pico de 8.354 frente al tope de 13.800. El enemigo ataca con avance y estela. Hay un descarte animado (`f2_vida3/`) |
| **Conjunto** | 6,5 | 6,5 | **7,5** | El combate normal ya tiene una sola mano y un solo sistema. Lo bajan el jefe, el limo, la Quemadura a distancia y el muro que compite |

## Correcciones C1–C20

| C | Estado | Prueba |
|---|---|---|
| C1 | **cerrada** | Daño en el fotograma 10 = `attack:2` (registro propio); antes, en `attack:0` |
| C2 | **cerrada** (heroína y criaturas) · **parcial** (jefe) | `c1_c2_golpe_f8-17.png`: un fotograma blanco y después el interior conservado. En el jefe, tinte pálido en todo el cuerpo durante ~5 fotogramas (`f2_vida3`) |
| C3 | **cerrada** | `hoja_cast_toss_hurt_muerte_x2.png`: sin cambio de mano; la mano libre apunta al oeste |
| C4 | **cerrada** | 18b: 80×28 art, horizontal; secuencia rodillas → caída → suelo en la hoja |
| C5 | **parcial** | Domo y ojos, sí. Brillo húmedo, borde lobulado y separación del suelo, no (0,149 frente a 0,133) |
| C6 | **parcial** | +90 px emisivos; lenguas visibles a ×1 y no a 1/4 |
| C7 | **cerrada** | Ya lo estaba (DECISIONES) |
| C8 | **cerrada** | `tools/qa.sh art`: «5 suites, 0 fallos» (test de color en `tests/art/test_ui.gd:217–225`). En pantalla, 31 colores en 08 y en 13, dentro del margen del recorte |
| C9 | **parcial** | Rig multiparte con fase 2 (`hoja_revisada.png`); cuerpo de ~135 sin la grúa (< 150) |
| C10 | **cerrada** | 4 escenas en `ilustraciones_x3.png`, fila 4 |
| C11 | **cerrada** | 07b: oro concentrado en la Forja y las tuberías; sin parches de juntas en el muro |
| C12 | **parcial** | Ataque con avance y estela, sí; en el gesto (10b) la cara sigue a media altura |
| C13 | **cerrada** | Murciélago separado del arco a 1/4; ácaro con 0,251 frente a 0,094 |
| C14 | **cerrada** (con reserva) | Maza biselada y mango visibles; a ×1, en reposo, la cabeza se confunde con las botas |
| C15 | **cerrada** | `fighter_view.gd:453` reproduce `idle_shoulder` con puente |
| C16 | **cerrada** | Ayuda sólo en tutorial y se retira al pasar `HINT_TURNS`; sin rótulo sobre la intención. Ver el problema nuevo N1 |
| C17 | **cerrada** | Hueco de 24 px; los títulos largos son la excepción que admite C17 (ver N4) |
| C18 | **cerrada** | 12 redondas de 84 frente a 34 de 57 |
| C19 | **parcial** | Rejilla apartada; muro tras los enemigos con 16,04 frente a 16,08 de desviación, sin cambio |
| C20 | **cerrada** | Pico de 8.354 ≤ 13.800 (360 fotogramas propios) |

## Problemas nuevos

- **N1.** «+Hollín» se coloca a la altura del cuerpo (`combat_screen.gd:1329`) y tapa la cara del gólem. Otro flotante queda debajo y se lee
  como basura (10b, px 652–720 × 380–420).
- **N2.** Tooltip QUEMAR de la carta alzada desfasado 1 px en horizontal (08, px 552–765 × 444–457).
- **N3.** Cinta de tipo de la carta alzada desfasada 1 px en vertical (08, px 600–671 × 624–635).
- **N4.** Títulos de carta largos en Pavesa ×1 de 10 px (09, px 926–995 × 608–619; 13, px 404–494 / 590–682 / 776–870 × 292–309). Chocan con
  ART_BIBLE (tabla de fuentes: Fragua ×2 para nombres de carta) y con DECISIONES. Necesita una decisión de dirección: Mini ×2 para los largos
  («Fuego Interior»: 14 × 8 px = 112 px, cabe en la cinta).
- **N5.** La carta que vuela al descarte rota con filtrado: 244 px ajenos (10b). Es en movimiento y menor, pero es el único color ajeno del
  combate.
- **N6.** Segunda barra de tutorial en 09 («Cada carta que quemas…», px ~385–890 × 128–146) sobre los estandartes. Es sólo del tutorial;
  conviene unirla a la barra de ayuda.

## Veredicto: **no pasa**. Correcciones mínimas, por prioridad

| # | Paquete | Archivo | Qué | Familia |
|---|---|---|---|---|
| 1 | F2-JEFE2 (`creature-artist`) | `scripts/art/defs/bosses/great_bellows.gd` y su horneado | Cuerpo ≥ 150 art **sin contar la grúa**: cámara del fuelle más alta (lomo hasta art y ≈ 110), patas más gruesas, pliegues de cuero con 2–3 pasos y sombra entre ellos en reposo en vez del fleco, cabeza con más masa que el pico | Jefe 7 → 8 |
| 2 | F2-VIDA4 (`art-integrator`) | `scripts/ui/fighter_view.gd` (`flash`) | Destello del jefe sólo en la pieza golpeada, y ≤ 2 fotogramas de subida de pasos; no lavar las patas | Jefe y efectos +0,5 |
| 3 | F2-VIDA4 | `scripts/ui/world/fx/status_fx.gd` | Quemadura legible a 1/4: a partir de Quemadura 3, lenguas de 5–6 px y +1 paso en las grietas del cuerpo | Efectos 7,5 → 8 |
| 4 | F2-VIDA4 | `scripts/ui/screens/combat_screen.gd:1329` y `UI.float_text` | Flotantes en cola vertical por encima de la cabeza y nunca encima de la cara (N1); de paso, x e y pares en la carta alzada (N2, N3, `scripts/ui/card_view.gd`) | HUD y conjunto |
| 5 | F2-CRIA4 (`creature-artist`) | `scripts/art/defs/creatures/ash_slime.gd` | Borde inferior lobulado con goterón, brillo húmedo de 1–2 px y sel-out cálido en la base para separarlo del suelo (luminancia ≥ 0,20). Gesto del gólem (`soot_golem.gd`) con la cara por encima del hombro | Criaturas 7,5 → 8 |
| 6 | F2-SALA2 (`world-artist`) | `scripts/art/bg/bg_act1.gd` y `assets/baked/rooms/**` | Juntas −1 paso en art x 300–604 × y 60–250 en todas las variantes; objetivo de desviación de luminancia ≤ 12 en px 780–1000 × 130–250 | Sala 7,5 → 8 |
| 7 | Dirección y F2-ILUS3 (`card-illustrator`) | `DECISIONES.md`; `scripts/ui/card_view.gd` | Decidir N4 (recomiendo Mini ×2 para títulos largos) y aplicarlo; «Fuego Interior» (`set_icon.gd:65`) con más escena (muro y antebrazo en contexto) | Cartas 7,5 → 8 |

Orden recomendado: 1 → 5 (una sola tanda de horneado; comparten `manifest.json`), con 2–4 y 6 en paralelo y 7 en cuanto dirección decida.
Después, una revisión corta con este mismo `medir.py`.

## Fuera del veredicto (legado y fase 3)
- **Legado, actos 2 y 3** (16, 17, 18): paleta exacta del 29,9 / 29,9 / 29,4 %; píxeles ajenos del 6,65 / 30,23 / 14,85 %. La hidra y el Rey de
  Escarcha siguen por debajo de 150 de alto.
- **Pantallas de fase 3**: paleta exacta entre 5,2 % (01) y 48,5 % (23); bloques rotos entre 2,4 % (22) y 15,0 % (04). `15_boss_relics` ya
  está al 99,997 % de paleta (F2-VIDA2).
- «Danza de la Pira», la de la heroína con cartas (`set_pyre.gd:38`), sigue siendo un revoltijo; ya está asignada a fase 3 (F2-TRIAL).

## No comprobado
- No he visto en movimiento los ataques de murciélago, polilla, ácaro ni urraca, ni la victoria, ni el robo, ni la Maestría. El jefe lo juzgo con las
  hojas de F2-JEFE y F2-VIDA2/3, no con un combate completo propio.
- El cuerpo de ~135 del jefe es una estimación a ojo: la máscara une la grúa. El ±1 de color de las ventanas de ilustración en pantalla no lo he
  separado del recorte.
- Sólo he ejecutado `tools/qa.sh art`, que salió verde; `game` no. No probé GPU real, WebGL ni otras resoluciones.
