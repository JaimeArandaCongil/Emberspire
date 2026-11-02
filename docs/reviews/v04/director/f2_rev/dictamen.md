# F2-REV · Dictamen del corte de combate, acto 1

Revisado en juego, sin diarios de artistas. Listón: pixel art comercial premium. Objetivo: ≥ 8 por familia.

**Veredicto:** en captura fija el combate normal parece mejor de lo que es. En movimiento baja: el golpe llega antes que el martillo, el destello borra a la criatura y la Quemadura casi no se ve. **No pasa a fase 3 tal como está.** Solo la Forja llega al 8. Los bloqueos son pocos y baratos; casi todos son de sistema o de reglas, y por eso conviene cerrarlos antes de multiplicarlos por 81 ilustraciones y el resto de criaturas.

## Notas

| Familia | Nota | Por qué |
|---|---|---|
| **Heroína** | **6,5** | Silueta y materiales buenos; la estela del martillazo funciona. Resta: el martillo salta de lado, gesto de quemar hacia el lado contrario a la Forja, la cabeza del martillo en reposo parece una maleta, la muerte no se lee como muerte |
| **Criaturas** (media sin jefe) | **6,4** | Ver abajo |
| · `soot_golem` | 7,5 | La mejor pieza: barril de ladrillo, rejilla, chimenea, peso real. Resta: pose de gesto confusa, cara perdida contra el resplandor del arco en el centro 350, ataque sin alcance |
| · `ember_magpie` | 7 | Se identifica al instante; pecho y ascua claros. El pico y la cabeza se pierden contra el ladrillo |
| · `flame_moth` | 7 | Buena forma de ala, emisivo con sentido. Ataque no comprobado |
| · `cinder_bat` | 6,5 | Alas finas como trapo roto; en x 350 se funde con el arco. Ataque no comprobado |
| · `candle_mite` | 6 | La vela se lee; el cuerpo oscuro se hunde en el suelo oscuro. Ataque no comprobado |
| · `ash_slime` | 4,5 | Es una roca: cuña de aristas rectas, mate, sin ojos visibles en reposo |
| · `great_bellows` (jefe) | **2,5** | Arte antiguo. Rayas de tramado de relleno (prohibido, §6 y §15), cara de emoticono, no es un fuelle, ~120 px frente a 150–200 (§8). Es lo peor de la pantalla |
| **Sala y fondo** | **7,5** | Arco, estandartes, ventana y sala de tiro con personalidad. Resta: el ladrillo de ritmo uniforme y juntas marcadas ocupa media pantalla y compite con los actores (§4.1 pide contraste bajo); la rejilla del suelo choca con la placa de PV del primer enemigo |
| **Forja** | **8,5** | Forma propia, conducto, manómetro, rejillas de Quemas. La secuencia de quemar es lo mejor del corte |
| **Cartas e ilustraciones** | **6,5** | Marcos excelentes. Las 15 nuevas, unas 7. Las hunden los iconos ampliados en juego (Fuego Interior, Llama de Brasero, Golpe de Escudo, Guardia de Ascuas: prohibidos en §9) y los títulos: «Tajo Ígneo» choca con el orbe vecino y el cuerpo de letra cambia entre mano y recompensa |
| **HUD e intenciones** | **7** | Placas y crisol con material propio. Resta: barra de ayuda fija cruzando conducto y arco; «Turno enemigo», «+Hollín» y la intención se pisan (`10b`); los iconos de intención sin cifra piden aprendizaje |
| **Efectos** | **6** | Quemar 8,5; muertes por material 7,5 (montón de ladrillos, muy bien); estelas 7,5. Destello 4,5; Quemadura sobre la criatura 3; orbes de ascuas grandes y redondos, ajenos al estilo, 6; contorno frío de bloqueo 7 |
| **Vida y animación** | **6,5** | La sala respira bien: llamas, humo, caldero. Falla lo que más importa: orden del golpe, salto del martillo, segundo reposo nunca usado, enemigo que ataca sin moverse |
| **Conjunto** | **6,5** | Combate normal en fijo ~7,5; en movimiento ~6,5; el jefe rompe la unidad |

## Evidencia de animación

Hojas en esta carpeta (orden izquierda→derecha, arriba→abajo): `a1`, `a2` reposo · `b_quemar` · `c_golpe` · `d1`, `d2` turno enemigo · `e_muerte_criaturas` · `f_reposo_otras` · `g_muerte_heroina` · `h1–h3` jefe · `i_estado_quemadura` · `j_golem_ataca` · `z_*` recortes y Resplandor.

- **Golpe en tiempo real** (`_play` con `Golpe`, sin `--fixed-fps`): silueta de destello de t = 0 a 168 ms; `attack` fotograma 0 hasta 168 ms, estela (f1) en 174 ms, impacto (f2) en 209 ms. **La reacción termina antes de que salga la estela.** La captura `10_swing` lo confirma.
- **Causa visible en código:** `combat_screen.gd:718` llama a `swing()` y resuelve la carta en el acto.
- **Aviso sobre `c_golpe`, `e_`, `g_` y `h2`:** con `--fixed-fps 60` el destello dura el doble (~360 ms) por la interacción con el hitstop. El orden vale; la duración buena es la de tiempo real. No medí por separado la parte blanca y la de color.
- **Hitstop:** usa `Engine.time_scale = 0.05` y el tween del destello respeta esa escala, así que la fase blanca no dura los 33 ms de §12, sino que se estira con el hitstop. Deducido del código y coherente con las hojas.
- **Reposo:** 12 s, 30 Hz: media 2.062 píxeles de arte cambiados por fotograma (0,9 %), pico 18.089 (7,9 %) frente al tope de 13.800. Pico aislado, causa sin diagnosticar.
- **Martillo:** `idle` a la derecha, `cast` y `toss` a la izquierda (`hf: true`), `hurt` a la derecha. Salto de ~30 px en un fotograma, ida y vuelta.
- **`idle_shoulder`:** horneado, pero ningún script lo reproduce (Grep en `scripts/`). El segundo reposo de §8 no existe en juego.
- **Tamaños medidos en reposo (ancho×alto):** `soot_golem` 87×88 · `hollow_knight` 70×100 · `ash_slime` 39×26 · `ember_magpie` 51×48 · `candle_mite` 26×29 · `cinder_bat` 58×53 · `flame_moth` 61×42.

## Preguntas

### 1. Regla de 12 colores: se revisa a **≤ 30**, con limpieza de la cola

No se fuerza. Medí las 15 ventanas en las hojas `ciega/ilustraciones_*.png`; el recuento coincide con el 14–36 declarado.

| Ilustración | Colores | Cubren ≥ 1 % | 12 mayores | Con < 10 px | Tras limpiar |
|---|---|---|---|---|---|
| Golpe | 36 | 18 | 84,5 % | 8 | 28 |
| Defensa | 34 | 20 | 76,8 % | 5 | 29 |
| Leña | 32 | 17 | 88,7 % | 10 | 22 |
| Tajo Ígneo | 19 | 13 | 98,0 % | 6 | 13 |
| Martillazo (fila 2, 1.ª) | 32 | 12 | 89,6 % | 5 | 27 |
| Lluvia de Chispas | 14 | 8 | 99,4 % | 1 | 13 |
| Fila 2, 3.ª (chorro) | 28 | 16 | 90,0 % | 4 | 24 |
| Muro de placas | 23 | 17 | 91,4 % | 3 | 20 |
| Tina y vapor | 36 | 18 | 84,8 % | 12 | 24 |
| Fuelle | 34 | 22 | 79,1 % | 7 | 27 |
| Brasero | 21 | 16 | 92,6 % | 1 | 20 |
| Carbón | 33 | 24 | 73,9 % | 3 | 30 |
| Heroína y cartas | 36 | 18 | 82,7 % | 9 | 27 |
| Ventana y hollín | 34 | 12 | 92,1 % | 10 | 24 |
| Torre | 27 | 17 | 88,7 % | 4 | 23 |

- **El número no predice la calidad.** Carbón (33) y Fuelle (34) son de las mejores: el metal y el fuego necesitan pasos. Lluvia (14) está limpia, pero es la más pobre de volumen. La de la heroína (36) es un revoltijo, y bajar colores no arreglaría su composición.
- **A 12 se pierde lo que da nivel:** con fuego, hierro y ladrillo juntos tocan a 4 pasos por material, y los materiales se aplanan. Además, 12 de las 15 tienen más de 12 colores que cubren ≥ 1 % de la ventana: no sobran, están pintando.
- **La disciplina real ya está en otras reglas:** paleta cerrada y sin ruido (§14), más la prueba de miniatura.
- **Nueva regla para §9:** ≤ 30 colores; ningún color con menos de 10 px salvo chispa u ojo puesto a propósito (máx. 3). Todas la cumplen con la limpieza: es mecánica y no se notará.
- **Aparte:** rehacer la composición de «Heroína y cartas», suspensa a 34×23 por sí misma.

### 2. Resplandor solo en cantos: **no basta, y parece un fallo**

En `z_resplandor.png` aparece un parche rectangular de juntas amarillas alrededor del caldero colgante y trazos sueltos en el muro. Se lee como un error de textura, no como luz. Además, no sale de ninguna fuente, lo que rompe «cada cosa viva tiene una causa» (§13).

Debe verse así: la luz cálida entera sube de escalón y vira a oro **por sillar** desde la Forja; llamas, boca y cobre en oro; nervios del tiro con el halo escalonado que pide §11; y nada de oro en muros alejados sin luz próxima. No bloquea la fase 3, pero el estado actual **no debe salir a producción**.

### 3. Cambio de lado del martillo: **sí, y sin transición**

Una transición sería parchear un fallo de lógica: el martillo no tiene por qué cambiar de mano. Se corrige en las poses, y de paso se arregla otro error: en `toss` tiende la mano hacia el este, mientras la carta vuela al oeste, a la Forja. Con el martillo quieto en la mano cercana, la mano libre queda para lanzar hacia la Forja. Ver C3.

### 4. `soot_golem` y `ash_slime`

- **`soot_golem`: se queda a 88.** No cabe en «medio 48–72» de §8, pero su peso es lo que hace funcionar el combate, y bajarlo a 72 obliga a redibujar la mejor criatura del corte. Se **enmienda §8**: «pesado de acto, normal excepcional, ≤ 88, uno por acto». Riesgo real: abulta más que la élite `hollow_knight` (87×88 frente a 70×100). No he visto al caballero en juego; compararlos juntos antes de cerrar las élites.
- **`ash_slime`: el tamaño se queda; el dibujo no.** Ver C5.

## Correcciones

### Bloquean el paso a fase 3

| # | Archivo o familia | Qué se ve | Qué debe verse | Lleva a |
|---|---|---|---|---|
| C1 | `scripts/ui/screens/combat_screen.gd` (`_play`, l. 718) | Destello, número y sacudida en t = 0; estela a 174 ms | Daño y reacción en el fotograma de impacto (f2, ~200 ms), con la entrada bloqueada mientras tanto. Lo mismo en todo ataque de la heroína | Vida +1 |
| C2 | `scripts/ui/fighter_view.gd` (`flash`, l. 511) | Silueta plana blanca y luego ámbar que borra la criatura ~168 ms; en cuerpos grandes es una mancha enorme (`10_swing`, `h2`) | 1 f blanco de 33 ms reales, sin estirarse por hitstop; después, subida de pasos que **conserve el dibujo interior**, no relleno plano. En jefes, blanco solo en la pieza golpeada | Efectos +1 |
| C3 | `scripts/art/defs/hero/fogonera.gd` (poses `cast`, `toss_back`, `toss`, l. ~63–85; rehornear) | Martillo teletransportado a la izquierda; mano libre hacia el lado contrario a la Forja | Sin `hf`; martillo en la mano cercana a x ≈ 61 como en `idle`; mano lejana y mirada hacia el oeste en `toss`. Ningún salto entre `idle`, `cast`, `toss` y `hurt` | Heroína 7,5 |
| C4 | `fogonera.gd` (`death`) y `fighter_view.gd` (`die`) | El destello tapa los primeros fotogramas; 6 de 8 son casi iguales; `18b` parece alguien empujando algo | Sin destello que oculte la caída. Rodillas → caída → de costado en el suelo, martillo soltado con un rebote, silueta claramente horizontal | Heroína 8 |
| C5 | `scripts/art/defs/creatures/ash_slime.gd` (rehornear) | Cuña angular y mate, ojos solo en algunos gestos, base recta. Una roca | Domo que cede, sin rectas > 4 px; borde inferior ondulado con 2–3 lóbulos y goterón; costra de ceniza solo en el tercio superior, con grietas de brasa; **ojos siempre visibles**; brillo húmedo de 1–2 px; reposo con aplastamiento de 1–2 px y la cima retrasada | Criatura 7,5–8 |
| C6 | `scripts/ui/world/fx/status_fx.gd` | Quemadura: unos pocos píxeles en los hombros, casi invisible (`i_`). Solo la delata el icono de la placa | Mecánica central del juego: 3–5 lenguas de 3–6 px en el contorno superior, que crecen con el valor, más grietas emisivas +1 paso. Legible a 1/4 | Efectos 7,5–8 |
| C7 | `docs/ART_BIBLE.md` §9 y §8 (dirección) | Regla de 12 incumplida por todas; golem fuera de banda | Aprobar ≤ 30 con limpieza y la excepción de pesado. Sin esto las otras 81 nacen ya fuera de norma | Regla cerrada |
| C8 | Las 15 ilustraciones (`scripts/art/cards/illus/`) | Colores de menos de 10 px, hasta 12 por pieza | Limpieza mecánica según C7 | Cartas +0,3 |

### Pueden esperar

| # | Archivo o familia | Qué se ve | Qué debe verse | Lleva a |
|---|---|---|---|---|
| C9 | `great_bellows` (fase 3, **primero de la lista**) | Arte antiguo, rayas de tramado | Jefe de 150–200 px en rig, un fuelle de verdad, 4–7 partes. No es bloqueo solo porque ya está en el alcance de fase 3 | Jefe ≥ 8 |
| C10 | Ilustraciones de icono (fase 3) | Fuego Interior, Llama de Brasero, Golpe de Escudo, Guardia de Ascuas: icono sobre degradado | Composición propia según §9 | Cartas 7,5–8 |
| C11 | `scripts/art/light_rig.gd`, `shaders/palette_lit.gdshader` | Resplandor en parches de juntas | Ver pregunta 2. **Obligatorio antes de publicar** | Efectos +0,3 |
| C12 | `scripts/art/defs/creatures/soot_golem.gd` | Gesto: cara a media altura y brazo sobre la cabeza, silueta confusa (`10b`). Ataque: arco en su sitio, sin avanzar | Cabeza arriba y brazo despejado. Ataque con 6–10 px de avance y el peso cargado | Golem 8,5 |
| C13 | Criaturas: `cinder_bat`, `candle_mite` | Se funden con el arco o el suelo | Membrana con más masa; cuerpo del ácaro +2 pasos o con sel-out cálido | 7,5 |
| C14 | `fogonera.gd` | La cabeza del martillo en reposo parece una maleta | Mango visible frente al delantal; cabeza con forma de maza, menos rectangular | Heroína +0,3 |
| C15 | `fighter_view.gd` | `idle_shoulder` nunca se reproduce | Usarlo cada 6–10 s con puente de 2 fotogramas, o retirarlo y enmendar §8 | Vida +0,3 |
| C16 | `combat_screen.gd`, HUD | Barra de ayuda siempre visible; banner, «+Hollín» e intención se pisan | Ayuda que desaparece tras los primeros turnos; banner por encima de y 22 o sin tapar intenciones | HUD 8 |
| C17 | Cartas (`CardView`) | «Tajo Ígneo» choca con el orbe; títulos de tamaños distintos entre mano y recompensa | Títulos que no rocen el orbe; misma letra y tamaño en todo el juego, salvo los largos | Cartas +0,3 |
| C18 | `scripts/ui/world/fx/death_embers.gd` | Orbes grandes, redondos y lisos | Brasas de 2–4 px irregulares, con estela de 1 píxel | Efectos +0,3 |
| C19 | Fondo: `scripts/art/bg/**` | Ladrillo uniforme y juntas marcadas tras los actores | Bajar contraste de juntas 1 paso tras la zona de enemigos; grupos de sillares distintos para romper el ritmo; apartar la rejilla de la placa de PV | Sala 8 |
| C20 | Mundo vivo | Pico de 18.089 píxeles en reposo | Averiguar la causa; ≤ 13.800 | Sin cambio de nota |

### Previsión

Con los bloqueos cerrados: heroína 8, efectos 7,5–8, vida 7,5–8, conjunto ~7,5. **Sala, HUD, cartas y criaturas seguirán por debajo de 8** hasta C9–C19. El listón de PLAN_ARTE («≥ 8 por familia») **no se cumpliría del todo** al pasar de fase. Mi recomendación es pasar igualmente tras C1–C8, porque jefe e ilustraciones de icono solo se resuelven en fase 3, y volver a puntuar el corte después. Esa excepción la tiene que aprobar dirección.

## No comprobado

- **Animación no vista:** ataques de `cinder_bat`, `flame_moth`, `candle_mite`; ataque y huida de `ember_magpie`; cambio de fase del jefe; PV < 25 %; victoria; robar carta; Maestría.
- **Transición a recompensas:** `13_rewards` parece atenuada por alfa, y §12 pide bajar 2 pasos. Solo lo sospecho; no capturé el paso.
- **Otras criaturas:** `hollow_knight` y `ash_glutton` no se han visto en juego. Tampoco variantes de sala ni ciclo II.
- **Otras condiciones:** resoluciones distintas de 1280×720, arranque desde `.pck`, sonido, sensación con ratón real.
- **Límites de método:** las hojas se reducen a 640×360 sin interpolar, así que el texto Pavesa no se puede juzgar ahí. Salvo `c_golpe` medido aparte, las duraciones de las hojas con `--fixed-fps` no son fiables en torno al hitstop. Niveles A/B de las ilustraciones y número de rampas por pieza sin medir. Los títulos de la tabla de colores los deduje del dibujo.
- **Tests:** no ejecuté `tools/qa.sh`: esta revisión no toca código ni arte. Los scripts de captura están fuera del proyecto y `tests/smoke.gd` sigue intacto.
