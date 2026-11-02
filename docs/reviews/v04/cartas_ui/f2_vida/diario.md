# F2-VIDA · diario (2.ª iteración del corte de combate, acto 1)

Nube Linux, Godot 4.7.2 en /opt/godot, xvfb + llvmpipe (vale para imagen y fotogramas, no para rendimiento).
Antes = recorrido sobre `bf1bcf5` sin tocar nada; después = recorrido final. `tools/qa.sh all`: 1745 comprobaciones, 0 fallos;
arte 5 suites, 0 fallos. `tests/smoke.tscn`: SMOKE OK (29 capturas).

## Qué cambió (por corrección)

| # | Archivo | Cambio | Evidencia |
|---|---|---|---|
| C1 | `combat_screen._play`, `_end_turn`; `fighter_view.swing/cast/lunge` | `swing()`, `cast()` y `lunge()` devuelven los segundos hasta el fotograma de impacto (`attack` f2, `cast` f1, sacados de `SpriteBank.frame_ms`). La pantalla bloquea la entrada (`busy`), alza la carta y resuelve la carta o el ataque enemigo entonces. La embestida llega a su punto máximo en el mismo instante | `vida_capturas` modo golpe (60 fps fijos): el evento `damage` cae en el fotograma `attack:2`. Antes caía en `attack:0`. Ataque enemigo forzado: estela en el f50 y daño en el f51 (`c1_ataque_enemigo.png`) |
| C2 | `palette_lit` (`flash_white`, `flash_steps`), `fighter_view.flash` | 1 f de silueta en fuego 7 durante 33 ms con `set_ignore_time_scale` (el hitstop ya no lo estira). Después +3, +2 y +1 pasos de rampa durante 50 ms cada uno, que conservan el dibujo. Material propio sólo mientras dura; en reposo los enemigos comparten `lit_material` (lo exige el recorrido) | `c1_c2_golpe_f8-17.png`: blanco en f10 y gólem con el dibujo visible y más claro en f11–14 |
| C4 (mi parte) | `fighter_view.die` | Sin destello. Si el golpe mortal sigue en su fotograma blanco, éste acaba y no entra la subida de pasos. Las poses son de F2-HERO | 18b: sin silueta plana |
| C6 | `status_fx.gd`, `emit_boost` | 3/4/5 lenguas (valor 1–3/4–6/7+) de 3→6 px de alto, que se mecen. Contorno superior encendido (fuego 3/4 que corre). 2–3 grietas encendidas dentro de la silueta. Los emisivos del luchador suben 1 paso | Gólem, px de rampa `fire` en su caja: 239 (sin) → 336 (Quemadura 3) → 379 (Quemadura 9); C6 pedía ≥ ~30. A 1/4 se lee como un borde naranja (`c6_quemadura_0_3_9.png`) |
| C11 | `palette_lit` | El Resplandor pasa a oro la pieza entera, con un umbral propio por sillar: `GOLD_FROM` 1 + hash del ancla × 1,6. Así el oro se deshace pieza a pieza con la distancia. Cobre y latón desde 0,35; llamas y boca, siempre. Juntas, ladrillo refractario del horno y luchadores (`gold_ok`) no cambian | Oro nuevo: 3.473 px en parches de junta (el mayor, muro derecho, art 416–591) → 5.749, el 69 % junto a la Forja (art 16–239 × 48–255). Del muro derecho sólo quedan el caldero colgante, que es una luz, y el brasero |
| C15 | `fighter_view._tick_shoulder` | Cada 6–10 s de `idle`: puente → `idle_shoulder` 2 s → puente → `idle`. El puente es `shoulder_in`/`shoulder_out` si F2-HERO los hornea y, si no, `windup`. Cualquier acción lo cancela | Registro de 12 s: idle 128 f · windup 5 · idle_shoulder 59 · windup 5 · idle 163 |
| C16 | `combat_screen` | La ayuda desaparece al empezar el turno 3 y en recompensas. Banner opaco de paleta en arte y 76–108 (entre la banda de jefe y las intenciones), que se abre en 3 escalones de 33 ms sin fundidos. «+Hollín» sale a la altura del cuerpo, no de la intención | `10b_banner_despues_640.png` |
| C18 | `death_embers.gd`, `combat_screen._fly_embers` | Brasas de 2–4 px en 6 formas asimétricas, con estela de 1 px (2 px de largo, 2 pasos más apagada). Las Ascuas al contador vuelan como brasas del mundo en lugar de los orbes de 12×12 de `main.fly_embers` (en biomas legados se mantienen los orbes) | 12_death: redondos ≥ 4 px 35 → 11 y de 6×6 26 → 2 (los que quedan son el ascua de la urraca y su icono de intención) |
| C20 | `light_rig.gd` | Causa: el parpadeo de brasero (paso entero, `ambient_brazier`) volteaba de golpe un disco de sillares de r ≈ 50, que sumado al parpadeo de la Forja (r 320) daba el pico. Ahora la fuerza de cada luz móvil sigue a su objetivo a 7 pasos/s y el paso del parpadeo de la Forja está acotado | Reposo 12 s a 30 Hz: pico 21.506 → **8.732–11.447** (≤ 13.800); media 4.088 → 2.994 |

## Nuevos de F2-BASE

- **(a) Fuentes.** `UI.label(<20)` usa Mini ×2. El tema pone Mini ×2 por defecto y deja Pavesa ×1 sólo en `TooltipLabel` y `rich()` (cuerpo). La sombra de etiquetas y botones es de 2 px; la de tooltips y cuerpo, de 1. `test_ui.gd` está actualizado a la decisión. Recorrido completo revisado en hoja: no veo desbordes en forja, antesala, mapa, tienda, hoguera, evento, resumen ni muestra de cartas.
- **(b) Rejilla y `020101`.** La causa no era la placa: el contorno horneado de Fragua se multiplicaba por `font_color` (`1a0a04` en Ascuas, `190d0e` en texto claro y `020101` en su sombra de 1 px). `UI.fragua_material()` lo deja intacto y la sombra pasa a 2 px. `UI.snap_center()` centra el texto en par: placas de PV, crisol, bloqueo y «Fin de turno». Además corregí y −3 → −2 (PV), −1 → −2 (cifra de intención), 7 → 8 (Quemas), 1 → 2 (Ascuas) y el botón de música (×1 → ×2).
- **(c)** Banner «Turno enemigo» `ff6a48` sobre `plate 1` `120c12`: **6,81:1** (antes 2,19 por alfa); «Tu turno» 10,89:1.
- **(d)** El rótulo de piso va dentro de la barra superior (y 2–28 px) con el rasgo en Mini ×2 a su lado. La ayuda baja a y 92 (arte 46). Los avisos empiezan en y 124. La banda de arte y 22–44 queda libre.
- **(e)** Recompensas: la sala baja 1 paso y a los 200 ms 2 (`LightRig.dim`: máscara constante y `emit_pulse`). Se retira la interfaz de combate y el panel opaco aparece a los 400 ms, centrado en par. Sin sala con luz (legado) se mantiene el velo.
- **(f)** `1a0a04`: 492 px → 0 (ver b).

## Medición `medir.py` (antes → después; % de bloques 2×2 rotos, fuera de excepción, paleta exacta, ajenos)

| Captura | rejilla | fuera exc. | paleta exacta | ajenos |
|---|---|---|---|---|
| 07_combat | 1,687 → 0,034 | 1,671 → 0,034 | 98,84 → 100,0 | 0,053 → 0 |
| 08_combat_hover | 2,021 → 0,301 | 1,651 → 0,242 | 98,90 → 99,999 | 0,057 → 0,001 |
| 09_burn | 2,089 → 0,086 | 2,070 → 0,086 | 98,75 → 100,0 | 0,056 → 0 |
| 10_swing | 6,227 → 0,229 | 6,198 → 0,112 | 98,56 → 100,0 | 0,175 → 0 |
| 10b_enemy_turn | 2,385 → 0,099 | 2,367 → 0,098 | 89,42 → 99,88 | 1,218 → 0,026 |
| 11_after_enemy_turn | 1,865 → 0,096 | 1,845 → 0,096 | 98,93 → 100,0 | 0,056 → 0 |
| 12_death_dissolve | 1,756 → 0,322 | 1,734 → 0,320 | 98,55 → 100,0 | 0,270 → 0 |
| 13_rewards | 6,823 → 1,119 | 6,789 → 0,660 | **23,28 → 99,997** | 1,901 → 0,003 |
| 15_boss_relics | 11,04 → 6,49 | 11,00 → 6,45 | 20,08 → 86,24 | 3,79 → 2,79 |
| 18b_hero_death | 1,703 → 0,086 | 1,688 → 0,086 | 98,81 → 100,0 | 0,057 → 0 |

En 07 la única zona rota que queda es el botón de música (px 1240–1271 × 4–33, 78 bloques, desfase vertical). Las pantallas de
fase 3 mejoran 0,2–2 puntos de rejilla; 01_title sigue con 14 % de ajenos (`Color("6a5a58")` en `title_screen.gd`, no es mío).
JSON completo: `mediciones_despues.json`.

## Encargo añadido: `HAND_MAX_STEP` 162

Probado en captura (`mano_paso162_5_y_10.png`): la mano de 5 ocupa x 231–1039, sin tocar la Forja (≤ 224) ni «Fin de turno» (≥ 1138), y
ningún título queda bajo un orbe. **No lo dejo puesto:** `test_ui.gd` exige `CardView.ORB_STEP × 2 == HAND_MAX_STEP`, y `ORB_STEP` (66) está
en `card_view.gd`, fuera de mi paquete. Para cerrarlo basta con `HAND_MAX_STEP := 162.0` aquí y `ORB_STEP := 81` allí. Con la mano llena el paso es
90 con cualquier valor: «Golpe», «Defensa» y «Tajo Ígneo» quedan cortados por el orbe vecino. Ya pasaba antes; hace falta otra
regla (título corto en mano apretada o que el vecino no lo tape).

## Pendiente y no comprobado

- Jefe legado: el destello sigue siendo el de silueta legada (C2 «blanco sólo en la pieza golpeada» → F2-JEFE).
- Recompensas de élite/jefe: `cards_box.modulate.a = 0,35` sigue siendo alfa mientras no se elige reliquia.
- `UI.float_text` y las cartas que vuelan al descarte siguen fundiéndose con alfa (interfaz, fuera de esta lista).
- Halo escalonado de los nervios del tiro (§11) en el Resplandor: no hecho.
- El puente de `idle_shoulder` es `windup` hasta que F2-HERO hornee `shoulder_in/out`; no vi el resultado con sus poses nuevas.
- Tiempos medidos con `--fixed-fps`; en tiempo real los 33 ms de blanco dependen del reloj real (`ignore_time_scale`), no comprobado
  con ratón ni a 60 Hz reales. Sin sonido. Sólo 1280×720.
- Herramienta: `tests/art/vida_capturas.tscn` (modos golpe, turno, estado, muerte, reposo, mano). No forma parte de la QA.
