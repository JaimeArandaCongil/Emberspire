# F2-BASE · Revisión verificable del estado del juego (base para la 2.ª iteración de fase 2)

Rama `main-0nvhs9`, HEAD `937cee2`. Capturas de `tests/smoke.tscn` en la nube (Godot en /opt/godot, llvmpipe: vale para imagen, no
para rendimiento). No se regeneraron. **Hay 29 capturas, no 30.**
Reproducir: `python3 -I docs/reviews/v04/director/f2_base/medir.py` (unos 8 s), que reescribe `mediciones.json`.
Coordenadas: **px** = pantalla 1280×720 (x0,y0,x1,y1) · **art** = mundo 640×360 (= px // 2).

## Capturas revisadas (md5)

| Captura | md5 | Tipo |
|---|---|---|
| 01_title | 91fc3650fd7e3893a7e1c1c066a62494 | pantalla (fase 3) |
| 02_forge | a3581c88380c29084d4d44a05f941831 | pantalla (fase 3) |
| 03_forge_archive | ba77c37476203ca6c18867b07e864dc8 | pantalla (fase 3) |
| 04_forge_chronicle | 0a0ff0f02ada58184b72203945c7ea07 | pantalla (fase 3) |
| 05_antesala | 782a0af5f103df90fe0fcf5c962cb3f4 | pantalla (fase 3) |
| 06_map | 4d2d1125ba732030245f3422a5b07c11 | pantalla (fase 3) |
| 07_combat | 89852ad7f96044fc7bbacc053ee65cc0 | **corte, acto 1** |
| 07b_glow | 877bc0a06f5e8453ad944513b27efc0d | **corte** |
| 08_combat_hover | 20a61fb7f45843b40c6a7d1955414c3d | **corte** |
| 09_burn | b272c1bb47181bd447bc937bf630e378 | **corte** |
| 09a_block_toss | 3d461eb150b4b393072bf3a3e5a99707 | **corte** |
| 09b_burn_flight | c57a288022230d992bffcc064b5b0a72 | **corte** |
| 10_swing | 8ce0bb67571007d596efc3db77e68be8 | **corte** |
| 10b_enemy_turn | 1b2fd5791cd0ab4cbe8a438474e60ed8 | **corte** |
| 11_after_enemy_turn | a682d5608618cf6d2c4f736affcb598e | **corte** |
| 12_death_dissolve | 4dfe631f22c6a5da84e5ccfc36ca2ee4 | **corte** |
| 13_rewards | de47a11a35377a1e3174bf02227de362 | **corte** (transición) |
| 14_boss_summon | 8a543649f04a11f4302a5dec4a2cc042 | corte con **jefe legado** |
| 14a_summon_reveal | 4a4dede1132e389792219af7bab63c95 | corte con **jefe legado** |
| 15_boss_relics | 70ac0e62198f3da068c176937f38be8d | pantalla (fase 3) |
| 16_act2_hydra | 81b22b97b34aa01a8c38c7a05625a6d2 | **LEGADO acto 2** |
| 17_act3 | 189ff9e423276f59b352fe081893ad29 | **LEGADO acto 3** |
| 18_frost_king | b88d0d2fa8bdbc21f51bcea5ea2f413f | **LEGADO acto 3** |
| 18b_hero_death | ad1f76c691f2e336f2732d6d7d46911f | **corte** |
| 19_shop | 0fca3d4f65572f68b76dd936535783b0 | pantalla (fase 3) |
| 20_rest | b919e4d73101d3d5ed1301ab774fb593 | pantalla (fase 3) |
| 21_event_forge_spirit | 78d6dc0ea1953dfe02df66dedc55c101 | pantalla (fase 3) |
| 22_summary | b5f73146ffb9257e1bc664e3a0ca509d | pantalla (fase 3) |
| 23_cards | 76b1f5ab625340b300d6b67efaa1479c | pantalla (fase 3) |

Las notas de familia salen **sólo del corte del acto 1** (07–14a, 18b). El legado (16–18) y las pantallas de fase 3 se miden, pero no
se puntúan junto a él.

## Método (resumen; el detalle está en las docstrings de `medir.py`)

1. **Rejilla.** Bloques 2×2 alineados (fase 0,0) con algún píxel distinto. Agrupo las roturas en celdas de 16×16 px (umbral: ≥ 3
   bloques por celda) y clasifico cada zona así: *×2 desfasado 1 px* si otra fase rompe menos de la mitad; *mezcla/filtrado* si menos
   del 50 % de sus píxeles está en paleta; *Pavesa permitida* si está dentro de una caja de pergamino detectada (cuerpo de carta) o
   de un tooltip anotado a mano (sólo el de 08); en otro caso, *detalle ×1 fuera de la excepción*.
2. **Paleta.** Leo las rampas, `UI` y `OUTLINE` de `scripts/art/palette.gd` (475 colores distintos). Cada píxel cae en una de cuatro clases:
   exacto; ±2 por canal (redondeo); mezcla alfa entre dos de los 48 colores de paleta más frecuentes de la captura, o con negro
   (±1, «mezcla esperable»); o ajeno.
3. **Legibilidad.** Zonas de texto fijadas a mano en `ZONAS_HUD` y `ZONAS_EXTRA`. El fondo es el color dominante; la tinta, el color
   (≥ 2 % de la zona) de mayor contraste con él. Doy el contraste WCAG, la altura de la tinta en px y el trazo dominante (1 = ×1, 2 = ×2).
4. **Disposición.** A resolución de mundo, la máscara es el contorno `0b080e` más los colores ausentes de la franja vacía (art x 200–289
   y 604–639). Une piezas por solape en x y clasifica como luchador lo que toca el suelo y como intención los iconos ≤ 16×16.
   Al jefe lo mido aparte, como el componente mayor.
5. **Correcciones.** Medidas específicas de C4, C6, C8, C11, C17 y C18 en `mediciones.json → correcciones` y `→ ilustraciones`.

## Tabla por eje (corte del acto 1)

| Eje | Nota | Evidencia medida |
|---|---|---|
| **Composición** | **7** | Centros de enemigo 350,0 / 461,0 / 572,0 frente a 350/460/572 (07). Heroína centrada en 160,5 (bbox art 141–180, dentro de 128–196). Los cuatro pies en y 264. Intención a 19 / 19 / 15 px sobre la cabeza (norma: 18). **Falla:** la banda de intención de jefe (y 22–44) no se usa, porque la intención del jefe sale a art y 104–118 (14) y 90–104 (18). Esa banda la ocupan el rótulo de piso y la barra de ayuda (zona px 392–891 × 36–99 = art y 18–49; aparece en las 18 capturas con combate de fondo, 07–18b) |
| **Escala** | **6** | Mundo sin roturas de rejilla en 07 y 09 (ninguna zona en «mundo»). Alturas en art: heroína **78 = 4 de moño + 74 de cuerpo** (norma: 66 + moño). El horneado `fogonera_idx.png`, fotograma 0, ocupa y 12–89 = 78: el exceso viene del arte, no del escalado. Gólem 87×89 (≤ 88; +1 dentro del error de máscara). Urraca 53×49 y `ash_slime` 45×31, en banda. **Jefe `great_bellows` 105×116** (norma: 150–200). Interfaz a medio píxel: placas de PV, «Fin de turno», Ascuas y títulos en coordenadas impares (ver consistencia) |
| **Legibilidad** | **7,5** | Contraste ≥ 4,5:1 en las 61 zonas de 07, 08, 09 y 13. Mínimos: etiqueta «QUEMAS» 4,51 (09, px 8–92 × 540–558), escudo de bloqueo 4,52 (07, px 218–244 × 524–550), etiqueta de descarte 5,08 y «+3.18K/s» 5,78. Cifras Fragua a 13–14 px (7 art): PV 13, energía 14, Ascuas 14. Pavesa a 9–10 px con trazo de 1. **Falla:** rótulo «Turno enemigo» (10b, px 548–800 × 260–292) con tinta `79392e` fuera de paleta a **2,19:1**, por debajo del 3:1 para texto grande. Pisa la cifra de intención (px 684–722 × 284–302) y «+Hollín» (px 650–720 × 300–318). En el turno propio, la intención es un icono de 13×15 art sin cifra |
| **Consistencia del pixel art** | **7** | Paleta: **98,84 % exacta**, 1,11 % mezcla alfa y 0,05 % ajena (07; 07b–12 y 18b, entre 98,5 y 98,9 %). Bloques 2×2 rotos: 1,69 % (07) a 3,66 % (10_swing, con la carta en vuelo, permitida). **Todo lo roto es interfaz:** Pavesa ×1 fuera de la excepción (0,66 % de bloques en 07); placas y textos ×2 desfasados 1 px (0,60 %); fondos de placa semitransparentes `190d0e` (8.904 px) y sombra de 1 px `020101` casi negra (1.300 px; §2 y «nunca negro puro»). Único color ajeno de 07: `1a0a04` (492 px), en el contador de Ascuas (px 30–71 × 3–20) |

Fuera del corte, sólo como dato: las pantallas de fase 3 tienen entre 4,7 % (01) y 46,8 % (23) de píxeles en paleta exacta y entre
2,9 % y 16,1 % de bloques rotos (02 y 04 bajo el modal «Reanudando»; 05 y 19, con 7,3 % y 8,2 % de paneles ×2 desfasados). El legado
(16, 17, 18) tiene un 27 % de paleta exacta y entre 6,7 % y 36,3 % de colores ajenos. Hidra 124×123 y Rey de Escarcha de 125 de alto:
ninguno llega a los 150. El ancho del Rey (215) no es fiable porque la máscara arrastra la nieve del suelo.

## Tabla por familia (corte del acto 1; comparar con `f2_rev/dictamen.md`)

| Familia | F2-REV | **F2-BASE** | Evidencia |
|---|---|---|---|
| Heroína | 6,5 | **6,5** | C3 abierta: martillo a la derecha en reposo (07, art ~165–178 × 250–264) y a la izquierda al lanzar (09a, art ~135–145). C4 abierta: en 18b la silueta mide 76×62 art (ancho/alto 1,23), de pie e inclinada; tumbada mediría ≤ ~30 de alto. C14 abierta: cabeza del martillo rectangular (07, art ~160–178 × 250–262). Nuevo: cuerpo de 74 frente a 66 |
| Criaturas (media sin jefe) | 6,4 | **6,4** | `ash_slime` 45×31 sigue siendo una cuña de dorso recto y sin ojos visibles (07, art 550–594 × 234–264): C5 abierta. Gólem 87×89 y urraca 53×49 sin cambios visibles. Murciélago, polilla y ácaro sólo aparecen en 18b; no los re-medí |
| Jefe `great_bellows` | 2,5 | **2,5** | Legado: 105×116 art (14, bbox art 303–407 × 144–259), con 1,8 % de píxeles ajenos (`a08170`, `6e5350` y `ffcf4f` en px 608–799 × 288–511) y el pie en y 259, no en 264. C9 abierta |
| Sala y fondo | 7,5 | **7,5** | En paleta y en rejilla. C19 sin tocar (F2-SALA aún no empezado); la rejilla roja del suelo sigue pegada a la placa del primer enemigo (07, px ~565–625 × 540–566, junto a la placa en x ≥ 625). Medida de ritmo del ladrillo: no hecha |
| Forja | 8,5 | **8,5** | Sin roturas de rejilla ni colores ajenos en art x 8–112 |
| Cartas e ilustraciones | 6,5 | **6,5** | C8 abierta: **7 de 21 ventanas incumplen** la regla de ≤ 30 colores con ≤ 3 de menos de 10 px. Ejemplos: 08 «Defensa», 34 colores y 5 de menos de 10 px; 23_cards, ventanas art (47,80) con 35/8 y (338,205) con 33/11. C10 abierta: «Golpe de Escudo» y «Guardia de Ascuas» (13) son iconos sobre degradado, con 11–12 colores. C17 abierta: **hueco de 0 px** entre el final de «Tajo Ígneo» (px 811) y el orbe vecino (px 812); título de 16 px con trazo 2 en mano frente a 10 px con trazo 1 en recompensa |
| HUD e intenciones | 7 | **6,5** | Legible (ver eje), pero rompe la regla de rejilla: Pavesa ×1 fuera de la excepción en la barra de ayuda (px 384–896 × 86–102), el subtítulo de piso, los contadores superiores (px 140–175, 922–973 y 1142–1167 × 10–19), el nombre del enemigo (09, px 660–742 × 512–530), «Lleva 18.6K Ascuas robadas» (11, px 852–987 × 358–383) y «¡Recuperadas ×2!» (12, px 772–971 × 320–341). Placas de PV desfasadas 1 px en vertical (borde en la fila impar px 531; zona px 298–349 × 530–549: rompe el 55 % en fase 0,0 y el 20 % en 1,0). «Fin de turno» desfasado 1 px en horizontal (fase 0,1: 0,0 %). Iconos de intención desfasados (11, px 702–723 × 284–303; 14, px 928 y 1152 × 404). C16 abierta: la barra de ayuda sigue visible en el turno 1 y el rótulo pisa la intención (10b) |
| Efectos | 6 | **6** | C6 abierta: el gólem con Quemadura (aplicada en 10, «Quemadura +3», con icono bajo su placa en 11) tiene **248 px emisivos frente a 257** sin ella en 07, sin lenguas nuevas; sólo se ve una de ~3 px en el hombro. C18 abierta: en 12 hay **34 brasas redondas ≥ 4 px de 57 componentes emisivos; 20 miden 6×6 art y algunas llegan a 8×8 o 12×12**. C11 abierta: el Resplandor añade 3.513 px de oro, el mayor parche en art 400–591 × 64–207 (trazos de junta en el muro derecho). C2: no se puede verificar en fijo; en 10_swing el gólem conserva 76 colores, sin silueta plana |
| Vida y animación | 6,5 | **6,5 (sin re-medir)** | Las capturas fijas no miden tiempos. C1 probablemente abierta: en 10_swing la cifra «10» y «Quemadura +3» ya están en pantalla con la estela a media trayectoria. C15 abierta: Grep de `idle_shoulder` en `scripts/` fuera de `defs/` da 0 resultados. C20: no medible en fijo |
| **Conjunto** | 6,5 | **6,5** | Sin cambios respecto a F2-REV: F2-VIDA, F2-HERO y F2-ILUS siguen «en curso» y no se ve su efecto en esta base |

## Correcciones C1–C20 según la evidencia

| C | Estado | Evidencia |
|---|---|---|
| C1 | abierta (indicio) | 10_swing: la cifra aparece durante la estela |
| C2 | sin verificar | ningún fotograma fijo muestra el destello |
| C3 | **abierta** | 07 frente a 09a: el martillo cambia de lado |
| C4 | **abierta** | 18b: 76×62, de pie |
| C5 | **abierta** | 07: cuña de 45×31 |
| C6 | **abierta** | 248 frente a 257 px emisivos |
| C7 | **cerrada** | `DECISIONES.md` y §8/§9 de `ART_BIBLE.md` ya recogen ≤ 30 colores y el pesado ≤ 88 |
| C8 | **abierta** | 7 de 21 ventanas fuera de regla |
| C9 | **abierta** | 105×116, legado |
| C10 | **abierta** | 13: iconos con 11–12 colores |
| C11 | **abierta** | 3.513 px de oro en parches |
| C12 | sin verificar | no medí la pose |
| C13 | sin verificar | no medí el contraste |
| C14 | **abierta** | 07: cabeza rectangular |
| C15 | **abierta** | Grep: 0 usos |
| C16 | **abierta** | barra de ayuda visible; rótulo a 2,19:1 que pisa la intención |
| C17 | **abierta** | hueco de 0 px; 16 frente a 10 px de alto |
| C18 | **abierta** | 34 brasas redondas |
| C19 | **abierta** | paquete sin empezar |
| C20 | sin verificar | requiere vídeo |

## Problemas priorizados (con paquete)

1. **Jefe legado de 105×116 (C9)** → F2-JEFE. Es la nota más baja del corte.
2. **Pavesa ×1 fuera de la excepción en 7 lugares del combate** (lista en HUD). La causa está en el código: `scripts/ui/ui.gd:188` pone
   Pavesa como fuente por defecto y `ui.gd:243-250` la aplica a toda etiqueta de menos de 20 px. **Nuevo.** Pide decisión de dirección:
   ampliar la excepción a «avisos y etiquetas de HUD» o pasarlas a Mini o Fragua ×2. `ui.gd` no está en ningún paquete → dirección,
   y después F2-VIDA (`combat_screen.gd` y `scripts/ui/hud/**`).
3. **Interfaz desfasada medio píxel de mundo y sombra de 1 px `020101`** (placas de PV, «Fin de turno», Ascuas, títulos de carta en
   fila impar con la sombra en px 346–396 × 604–619 de 07, e iconos de intención). **Nuevo.** → F2-VIDA (`scripts/ui/hud/**`,
   `combat_screen.gd`). Los títulos de carta → F2-ILUS (`CardView`).
4. **C6 Quemadura invisible** y **C18 orbes** → F2-VIDA (`status_fx.gd`, `death_embers.gd`).
5. **C3, C4 y C14, y heroína de 74 + 4 frente a 66 + moño** → F2-HERO. Lo de la altura es **nuevo**: o se corrige el rig o dirección
   enmienda la cifra de §8.
6. **C5 `ash_slime`**, después C12 y C13 → F2-CRIA2.
7. **C16: rótulo «Turno enemigo» a 2,19:1, fuera de paleta, encima de la intención** → F2-VIDA.
8. **Banda de intención de jefe sin implementar** (art y 22–44 ocupada por el rótulo de piso y la barra de ayuda). **Nuevo** → F2-VIDA,
   que coordinará con F2-JEFE.
9. **C8, C10 y C17** → F2-ILUS.
10. **13_rewards atenuada por alfa**: sólo 23,4 % de paleta exacta y 61,9 % a ±2. Así queda confirmada la sospecha de F2-REV, frente
    a §12, que pide bajar 2 pasos → F2-VIDA (`combat_screen.gd`).
11. **C11 Resplandor en parches** → F2-VIDA (`light_rig.gd`, `palette_lit`).
12. Color ajeno `1a0a04` en el contador de Ascuas (492 px) → F2-VIDA (`scripts/ui/hud/**`).
13. **C19** → F2-SALA. **C15 y C20** → F2-VIDA.
14. Pantallas de fase 3 fuera de paleta y de rejilla (01–06, 15, 19–23) y actos 2 y 3 legado → fase 3. No bloquean F2.

## No comprobado y límites

- Sólo hay capturas fijas: no medí tiempos (C1, C2, C20) ni animación. La máscara de luchador tiene un error de ±1 px; el ancho del Rey de Escarcha no es fiable.
- Zonas de texto y tooltip fijadas a mano (`ZONAS_HUD`, `ZONAS_EXTRA`, `TOOLTIPS`): si cambia la disposición, hay que actualizarlas.
- «Mezcla esperable» sólo comprueba pares entre los 48 colores más frecuentes y negro, con ±1. Un «redondeo» de ±2 en pantallas muy
  oscuras puede esconder colores ajenos.
- No ejecuté `tools/qa.sh`: esta revisión no toca código ni arte.
