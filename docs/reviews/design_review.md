# EMBERSPIRE v0.2 — Revisión de Diseño

> Revisión crítica desde la óptica de deckbuilders (Slay the Spire, Monster Train, Balatro) e incrementales
> (Antimatter Dimensions, Melvor, Cookie Clicker). Fecha: 2026-11-01.
>
> **Método.** Lectura de VISION/GDD/BALANCE y de las tablas (`card_db`, `relic_db`, `enemy_db`, `forge_db`),
> `combat_engine`, `game_state`, `run_state` y las pantallas. Ejecuté `progression_sim` (8 h), `balance_sim` y
> `smoke` (23 capturas revisadas). Escribí simulaciones propias en `tests/_review/` (no tocan nada del juego):
>
> | Script | Qué mide |
> |---|---|
> | `econ_sources.tscn` | Desglose de Ascuas por fuente durante las 8 h de `progression_sim` |
> | `burn_policy.tscn` | 4 políticas de quema × 3 perfiles de Arsenal, 60 ascensiones cada una |
> | `card_eval.tscn` / `card_eval_c2.tscn` | Valor marginal de cada carta (mazo inicial + 2 copias) en un guantelete fijo, ciclo 1 y ciclo 2 |
> | `mastery_dist.tscn` | A qué cartas va la Maestría y en qué estado acaba la meta-progresión tras 8 h |
> | `doors.tscn` | Distribución real de las puertas por piso |
>
> Las IA juegan peor que una persona; los resultados indican tendencias, no valores exactos. Cuando un número es
> derivado de fórmulas y no de una simulación, lo indico.

---

## 1. Veredicto general

**EMBERSPIRE tiene una premisa excelente y una ejecución técnica sólida, pero la acción que lo define (QUEMAR)
casi nunca es una decisión.** Hoy quemar es una casilla que se marca sola al final de cada turno: quemas la carta
que no ibas a jugar, no pierdes nada y te llevas Ascuas y Maestría. Los cuatro puentes de v0.2 están bien pensados
sobre el papel, pero la mayoría se tocan *por números* y no *por decisiones*, que es justo lo que VISION.md dice que
quería dejar atrás.

### Lo que funciona
- **La premisa vende sola.** «Tu mazo es combustible» se entiende en una frase y tiene identidad propia. El horno en
  combate, el contador de Calor y la lluvia de ascuas al quemar (captura `09_burn`) se leen bien y se sienten bien.
- **Los enemigos interactúan con el horno.** Ahogo (Bruto del Fuelle, Gran Fuelle, Polilla, Rey Escarcha), Hollín,
  Ceniza Húmeda (que no se puede quemar) y Urracas que roban de la Forja son el tipo de diseño correcto: el bestiario
  conoce la mecánica central. Pocos deckbuilders lo logran en una v0.2.
- **Los eventos cruzan los dos juegos.** Espíritu de la Forja (pagas Ascuas del banco para dar Maestría), Veta de
  Carbón (carta o Ascuas), Lluvia de Estrellas (Polvo a cambio de PV máximos): son decisiones Torre⇄Forja de verdad.
- **El ritmo del primer arco está bien trenzado.** Primer jefe ~13 min, primer muro roto ~29 min, primer Renacer a
  los 106 min: está en la franja sana de un incremental.
- **Hay arquetipos reconocibles** (Pira, Yunque, Ceniza, Forja) y cartas que leen la Forja (Llama de Brasero,
  Muralla de Engranajes, Eco del Reliquario): es la idea correcta de acoplamiento.
- **Las herramientas de balance existen.** Que haya simulaciones headless desde v0.2 es poco habitual y muy valioso.

### Lo que no funciona
1. **Quemar tiene una respuesta dominante** (quemar lo sobrante al final del turno) y no tiene coste real.
2. **La Maestría premia a las cartas equivocadas.** Va a parar a Golpe y Defensa (≈800 quemas cada una en 8 h), las
   cartas que en un deckbuilder quieres *quitar*, y a la Leña, cuyo efecto al quemar no escala.
3. **La economía está al revés de lo prometido.** La Torre produce el 83% de las Ascuas; la Forja idle, el 11%. El
   «idle» es un multiplicador del valor de la quema, no un juego paralelo.
4. **La meta-progresión se queda sin decisiones hacia las 2 h.** Los 12 talentos cuestan 41 de Polvo en total y a
   las 8 h sobran **2.678**. El Arsenal finito está comprado antes de las 3 h. Después sólo queda Filo Eterno/Piel
   Forjada ×1.04 y Renacer «cuando dobla».
5. **Las puertas no son una decisión** en más de la mitad de los pisos, y el Tesoro las domina cuando aparece.
6. **Las ascensiones largas no escalan bien.** Una ascensión de mitad de partida dura 60–95 min contra los mismos
   26 enemigos, con 4× PV por ciclo y ninguna mecánica nueva.

---

## 2. Problemas, por gravedad

### CRÍTICO

#### C1. Quemar lo sobrante es gratis y siempre correcto
- **Regla.** Quemar exilia la carta *sólo de este combate* (`CombatEngine._burn` la manda a `exhaust_pile`). Con
  3 de Energía y 5 cartas en mano casi siempre sobran 1–2 cartas que no puedes pagar. Quemar una de ellas no te
  quita nada este turno, aligera el mazo (bueno en cualquier deckbuilder) y da Ascuas, Maestría y su efecto al quemar.
- **Evidencia (`burn_policy`, 60 ascensiones por fila):**

  | Perfil | Nunca quema | Sólo Combustible | **Sobrantes al final** | Quema primero (máx.) |
  |---|---|---|---|---|
  | Novata · piso medio | 8.9 | 9.2 | **9.1** | 9.4 |
  | Novata · Ascuas/run | 373 | 544 | **1.12K** | 1.29K |
  | Media · piso medio | 10.6 | 12.1 | **13.4** | 10.6 |
  | Media · Ascuas/run | 892 | 1.84K | **6.03K** | 4.19K |
  | Veterana · piso medio | 14.0 | 15.7 | **14.7** | 6.8 |
  | Veterana · XP de Maestría/run | 1.0 | 15.3 | **85.7** | 48.5 |

  Quemar lo sobrante **no empeora la supervivencia** (incluso la mejora con perfil Medio, +1.3 pisos frente a
  «sólo Combustible») y multiplica entre ×3 y ×7 las Ascuas y entre ×5 y ×6 la Maestría. La única política que tiene
  coste («quemar antes de jugar») sólo duele cuando tienes 3 o más Quemas por turno. Con la Quema única del
  principio, «máx.» y «sobrantes» son la misma jugada: **no hay decisión en las primeras horas.**
- **Por qué importa.** Es el pilar 1 de VISION («Quemar es decidir»). Tal como está, la pregunta del turno no es
  «¿lo juego o lo quemo?», sino «¿cuál de las que sobran quemo?», y la respuesta casi siempre es «la peor».

#### C2. La Maestría va a las cartas que no quieres
- **Evidencia (`mastery_dist`, 8 h):** `defend 801 · strike 763 · kindling 561 · golden_flux 228 · ember_slash 195…`.
  Las 5 cartas con más Maestría son 3 iniciales y 2 Combustibles.
- **Dos fallos que se suman:**
  1. Se gana Maestría *quemando* (= no jugando) y escala los números *al jugar*. Las cartas que más quemas son las
     que menos juegas. Las raras que te importan casi no suben, porque quemarlas cuesta tempo.
  2. La carta más quemada del juego, la **Leña**, sólo tiene `energy`/`draw` al quemar, que no están en
     `CardDB.SCALABLE`. Su Maestría 5 sólo da ×2 Ascuas. Lo mismo con Avivar, Tiro Abierto y Flujo Áureo.
- **Efecto.** El Códice de Maestría se convierte en «Golpe y Defensa a nivel 5». El sistema ata a la Fogonera a su
  mazo inicial en lugar de animarla a construir uno.

#### C3. La Torre es la economía y la Forja idle es secundaria
- **Evidencia (`econ_sources`, 8 h de `progression_sim`):** quemar **52.5%**, oleadas de victoria **30.2%**,
  idle **10.9%**, tesoros 6.1%, matar enemigos **0.0%**, clics 0.0%. A los 30 min el idle aún es el 47%; a los
  240 min es el 8%.
- **Causa.** `burn_value` incluye `production() × 3 s` y luego lo multiplica Codicia (hasta ×3), Calor (hasta ×3.2
  con talento), Maestría (×2), Fuelle Dorado (×1.5) y los Combustibles `ember_mult` (×3 a ×7). Una quema normal de
  mitad de partida vale ~40 s de producción y una de Flujo Áureo, ~200 s (derivado de la fórmula). Un piso jugado
  produce ~75 s de idle.
- **Por qué importa.** Las dos mitades se refuerzan (más producción ⇒ quemas más valiosas), y eso está bien. Pero
  lo óptimo es *estar siempre en la Torre*: el modo «cierro el juego y vuelvo» (pilar 2) pesa poco, y comprar
  generadores sólo sube el valor de la siguiente quema. `kill_value` (8·factor de piso, sin escalar con la
  producción) es texto muerto a partir del minuto 15.

### ALTO

#### A1. La meta-progresión se queda sin decisiones a las 2–3 h
- Talentos: 12 en total, **41 de Polvo**. El bot tiene 35 de Polvo a los 106 min y 2.719 a las 8 h (2.678 sin gastar).
- Arsenal finito: todo al máximo antes de la ejecución 8 de la simulación (~4 h). Codicia 20 cuesta ~1.6e7: es
  barato frente a lo que da la Torre.
- Reliquario: 38/40 a las 5 h, 40/40 a las 6.5 h. Después, +2% fijo.
- Desde ahí, el único bucle es Filo Eterno/Piel Forjada ×1.04 y Renacer cuando se dobla el Polvo. **No queda
  ninguna decisión, sólo multiplicación.**

#### A2. Las puertas no son una decisión (y el Tesoro las domina)
- **Evidencia (`doors`, 15.333 pisos con 3 puertas):** el **53%** muestra ≥2 puertas de Combate idénticas, el
  **12.3%** sólo Combate (ninguna elección), el **19.3%** incluye Tesoro.
- La puerta no dice nada de *qué* combate ni *qué* recompensa. Dos «Combate» iguales (captura `06_map`, piso 1)
  son una elección vacía.
- El Tesoro da reliquia + 30 s de producción sin coste ni riesgo: cuando aparece, se elige siempre (la IA de
  `progression_sim` lo coge primero, y con razón). El piso 9 siempre es Hoguera/Yunque, así que el riesgo antes
  del jefe ya está resuelto.

#### A3. Ascensiones demasiado largas y repetitivas a mitad de partida
- `progression_sim`: ejecución 6 = 50 pisos (~62 min), ejecución 9 = **75 pisos (~94 min)**, ejecución 11 = 80
  pisos. Sólo **11 ascensiones en 8 h**.
- Cada ciclo reutiliza los mismos 26 enemigos, 6 jefes y 16 eventos con ×4 PV y ×2 daño. Para llegar al piso nuevo
  hay que jugar 30–60 pisos que ya no enseñan nada. En un incremental, un bucle de 90 min es un bucle lento.

#### A4. Las cartas del Grimorio de la Forja rompen el equilibrio de cartas
- **Golpe Estelar** (`stardust_strike`): `6 + min(Polvo, 30)` por **1 de Energía**. Con 30 de Polvo (≈1.5–2 h)
  hace 36 de daño; mejorada, 54. Es la carta n.º 1 en **ambos** guantaletes (`card_eval`: +66.7% de victorias en
  el ciclo 1 y n.º 1 también en el ciclo 2). El Golpe hace 6.
- **Legado** (`str_mastery`): 1 de Fuerza por cada 6 cartas con Maestría. Con las 49 cartas del bot a las 8 h:
  **+8 de Fuerza (12 mejorada) por 1 de Energía**. Al principio no hace nada (−4.7% en el guantelete).
- Muralla de Engranajes (`block_gens`, +1 por cada 20 generadores) y Eco del Reliquario (+1 por cada 2
  reliquias) llegan a ~24–29 de Bloqueo por 1 de Energía a mitad de partida.
- **Problema de forma:** valores planos que leen la Forja se desbocan, o al revés, se quedan en nada. Hacen falta
  topes y escalado logarítmico.

#### A5. Ceniza y parte de la Pira no escalan con el Arsenal
- `calc_damage(src=null)` ignora Fuerza y `run.dmg_mult` (Filo Eterno). Usan ese camino: el tic de Quemadura,
  Detonar, Punto de Ignición, Fuego Interior, Corona Solar y las espinas.
- **Evidencia (`card_eval` ciclo 1 → ciclo 2, Arsenal Mítico):** Incendio pasa del puesto 3 al 16, Tormenta de
  Fuego (rara) de +40.6% a +1.6%, Detonar a −37%. Los ataques múltiples suben (Ráfaga de Martillo del 12 al 3).
- **Efecto.** A partir del ciclo 2, el Grimorio de la Ceniza (25.000 Ascuas) es una trampa y el juego converge a
  «ataques + Fuerza + Filo Eterno».

#### A6. Autoforja es una trampa sin interruptor
- `_autobuy()` compra el generador más barato cada 0.5 s, también durante la ascensión, y no se puede desactivar.
  El banco de Ascuas nunca pasa del coste de una Chispa: no puedes ahorrar para Arsenal ni Grimorios y el Yunque
  Errante, que cobra de la Forja, queda inutilizable. Es el talento de 3 de Polvo que el bot compra antes.

### MEDIO

#### M1. Cartas muertas, débiles o rotas (guantelete del ciclo 1, Δ % de victorias frente al mazo inicial)
- **Por encima de su rareza:** Incendio (común, +64.1), Rescoldo (+60.4), Danza de la Pira (+63.5), Golpe Estelar
  (+66.7). Incendio aplica 4 de Quemadura a TODOS: unos 10 de daño por enemigo por 1 de Energía, sin bloqueo posible.
- **Por debajo:** Atizar (−25.5), Fundir (−22.4), Detonar (−20.8), Buscar Combustible (−13.5), Muro de Hierro
  (−11.5), Redoblar Escudo (−9.4), Mortaja de Ceniza (−10.4), Horno de Tiro (−5.7), Pulmón de Forja (−2.1),
  Dividendo (−3.6).
- **Fundir** quema una carta **al azar** de tu mano: puede quemar el Poder que ibas a jugar. Es aleatoriedad en
  contra del jugador sobre la acción central del juego.
- Las cartas «económicas» (Dividendo, Pulmón de Forja, Flujo Áureo, Carbón) cuestan poder de combate a cambio de
  Ascuas. **Ésa sí es una decisión buena**, pero queda tapada porque quemar lo sobrante ya es gratis (C1).
- Mejoras sin peso: Ráfaga de Martillo+ (4×3 → 5×3), Mandoble+ (sólo cambia el multiplicador de Fuerza), Legado+
  (divisor 6 → 4), Llama de Brasero+ (4 + piso/5 → 6 + piso/4).

#### M2. Las recompensas no suben con el riesgo
- La Élite da una reliquia **aleatoria** (sin elegir) y 3 cartas. El Combate da 3 cartas con menos probabilidad de
  rara (5% frente a 12%). La diferencia de recompensa es pequeña para el riesgo.
- «Quemar las ofrendas» (saltar la carta) vale `burn_value(1, 2)`, unos 6 s de producción: irrelevante.
- La Ofrenda de la Hoguera **elimina una carta y además paga** (`burn_value(2, 3)`), mientras que el Yunque cobra
  ~30 s de producción por eliminar una. Para quitar cartas, la Hoguera domina al Yunque.

#### M3. El Yunque Errante deja de tener tensión a mitad de partida
- Los precios son `base·(1 + 0.15·piso) + producción × s`, sin contar Codicia ni Calor. Captura `19_shop`: banco
  1.98M, carta 90.7K (4.6% del banco), reliquia 327K. A mitad de partida se compra todo: el Yunque es una lista de
  la compra, no un dilema.

#### M4. Reliquias y pactos con elección obvia
- **Núcleo Agrietado** (+1 Energía permanente) a cambio de 2 Cenizas Húmedas que se agotan en el turno 1: domina.
- **Ceniza de Fénix** no hace nada si ya tienes el talento Fénix: `phoenix_available` es un booleano y no se suman.
- **Mazo Escarchado** (Calor 1): la Escarcha *se puede quemar*, así que sólo ocupa la Quema sobrante. Es Calor casi
  gratis.
- **Jugador de Ascuas**: valor esperado exactamente 0. No hay decisión, sólo varianza.
- **Lluvia de Estrellas**: al principio, +1 Polvo (+10% de producción para siempre) por −6 PV máximos domina; al
  final no importa.

#### M5. Las Urracas son piñatas
- Roban `s × (producción + 2·factor de piso)`, pero tienen 14–17 PV (acto 1) y devuelven **el doble** al morir.
  Matarlas siempre sale a cuenta y en la práctica nunca amenazan. Devoluciones: 3.4% de los ingresos de los
  primeros 30 min.

#### M6. Las Resonancias son números, no decisiones
- 21 ventajas fijas: la 1.ª de cada generador a 10, la 2.ª a 50, la 3.ª a 100. Casi todas son estadísticas
  (+PV, +Bloqueo inicial, +1 de daño). No hay forma de elegirlas, así que no hay construcción. Que Renacer las
  apague es interesante, pero el jugador lo vive como pérdida, no como decisión.

#### M7. Lectura de la información (UX)
- **No se ve cuánto da una quema** antes de hacerla. El jugador no puede comparar «Golpe: +X Ascuas, +1 XP (7/15)»
  con «Leña: +Y». El momento central del juego no tiene vista previa.
- Las cartas de la mano salen cortadas por abajo (`HAND_Y = 548`): «Inflige 7 de dañ…» en `07_combat` y
  `14_boss_summon`. Hay que pasar el ratón por cada carta para leer el efecto al quemar, que es lo que más importa.
- El modal de bienvenida explica 6 conceptos de golpe (Resonancias, Maestría, Braseros, quemar, idle, muerte)
  antes de que el jugador haya hecho nada.
- Las intenciones que no son ataque (Gólem: flecha morada; Urraca: moneda) no muestran cifras sin tooltip.

### BAJO
- `kill_value` y las recompensas `secs` de los hitos (60–300 s) son despreciables después de la primera hora.
- El clic en el horno (`1 + 5%` de la producción) ya no importa después del minuto 5. Está bien, pero entonces el
  horno de la Forja podría servir para algo más.
- `str_mastery` muestra «(0)» de Fuerza en las primeras horas: es una carta rara que se ofrece cuando todavía está
  muerta.
- 18 cartas raras repartidas entre 7 paquetes: con 5% en combate normal, un mazo concreto ve muy pocas raras de su
  arquetipo.

---

## 3. Mejoras priorizadas

Esfuerzo: **S** = horas, **M** = 1–3 días, **L** = una semana o más. Las marcadas ★ son las ideas grandes de
acoplamiento quema⇄forja; el resto son ajustes.

### Prioridad 1: que quemar sea una decisión

**1. ★ Sacrificio: la quema vale más cuanto más renuncias** · `combat_engine.gd::_burn`, `game_state.gd::burn_value` · **M**
- **Qué cambiar.** Si al quemar la carta tenías Energía para jugarla («quema en caliente»), da ×2 de Ascuas y ×2
  de XP de Maestría. Si no podías pagarla («rescoldo»), da ×0.5. El Combustible siempre cuenta como «en caliente».
  En la carta en mano, un borde dorado indica «en caliente».
- **Efecto esperado.** Desaparece la jugada dominante de C1. Cada turno se compara «6 de daño ahora» con «el doble
  de progreso para siempre», que es la pregunta de VISION. Hay que repetir `burn_policy`: el objetivo es que
  «sobrantes» y «quema en caliente» queden a ±1 piso pero con Ascuas y Maestría muy distintas.

**2. ★ Temple de Maestría: ramas elegibles por carta** · `game_state.gd` (`mastery`), `card_db.gd`, Códice en `forge_screen.gd` · **L**
- **Qué cambiar.** En Maestría 2 y 4, la carta pide elegir 1 de 2 Temples permanentes:
  - **Filo** (+20% a los números al jugarla, como ahora).
  - **Brasa** (la carta gana o mejora un efecto «Al quemar»; por ejemplo, Golpe al quemar: 4 de daño a un enemigo
    al azar).
  - Para Combustibles: **Fragua** (+1 Quema la primera vez que se quema en cada combate) o **Rescoldo**
    (vuelve al mazo de descarte en vez de exiliarse).
- **Efecto esperado.** Arregla C2: la Maestría de Golpe y Defensa se convierte en una decisión de construcción
  («mis Golpes son combustible») y la de la Leña deja de ser sólo ×Ascuas. El Códice pasa a ser un árbol, no una
  barra de progreso.

**3. La Maestría también se gana jugando (menos)** · `combat_engine.gd::play_card` · **S**
- **Qué cambiar.** Jugar una carta da 0.25 de XP. Quemarla da 1 (o 2 «en caliente», ver #1).
- **Efecto esperado.** Las raras que juegas también suben, y quemar sigue siendo la vía rápida. Sin esto, la
  Maestría siempre premiará al relleno.

**4. Vista previa de la quema** · `card_view.gd`, `combat_screen.gd` · **S**
- **Qué cambiar.** Al pasar el ratón: «QUEMAR → +37.6K Ascuas · Maestría 7→8/15 · Al quemar: …». En el horno, el
  total del combate.
- **Efecto esperado.** La decisión central pasa a ser legible. Sin esto, #1 y #2 no se notan.

**5. Fundir y Tarro de Hollín: quema elegida, no aleatoria** · `combat_engine.gd` (`free_burn`), `card_db.gd` · **S**
- **Qué cambiar.** `free_burn` abre la selección («elige una carta para quemar gratis»). El bot elige la peor.
- **Efecto esperado.** Elimina aleatoriedad en contra del jugador en la acción central (Fundir: −22% en
  `card_eval`).

### Prioridad 2: que la Forja sea un juego, no un multiplicador

**6. ★ Lingotes: lo que quemas decide lo que forjas** · `game_state.gd`, `forge_db.gd` (ARSENAL), `forge_screen.gd` · **L**
- **Qué cambiar.** Además de Ascuas, cada quema deja un **lingote según el tipo** de carta: Ataque → *Hierro*,
  Habilidad → *Escoria*, Poder → *Oro*, Combustible → nada extra (sólo Ascuas ×). Las mejoras infinitas del Arsenal
  y los niveles altos del finito cuestan Ascuas **y** lingotes: Filo Eterno pide Hierro, Piel Forjada Escoria,
  Núcleo Ígneo Oro.
- **Efecto esperado.** «¿Qué carta quemo?» se convierte en planificación de la Forja («necesito Escoria para la
  Piel, este combate quemo Defensas»). Es el acoplamiento por decisión que pide VISION. Mantenerlo en 3 recursos
  como máximo.

**7. ★ Resplandor: la ascensión calienta la Forja al volver** · `game_state.gd::end_run`, `production()` · **M**
- **Qué cambiar.** Al terminar una ascensión, la Forja recibe un buff temporal de producción: `+X%` por cada carta
  quemada en la ascensión, durante `N` minutos, en tiempo real y también offline. A la vez, se reduce el término
  `production × 3 s` de `burn_value` a ~1 s.
- **Efecto esperado.** Corrige el reparto de C3: lo que haces en la Torre vuelve como *ritmo* de la Forja (la
  ventana para gastar y planificar), no como una inyección directa que deja el idle en un 10%. Objetivo para
  `econ_sources`: idle+offline ≥ 35% a las 4 h.

**8. ★ Resonancias elegibles** · `relic_db.gd` (PERKS), `game_state.gd::perk_ids`, `antesala_screen.gd` · **M**
- **Qué cambiar.** Cada umbral (10/50/100) ofrece **1 de 2** ventajas. Por ejemplo, Chispa 10: «la primera quema
  roba 1» o «la primera quema es en caliente aunque no puedas pagarla». La elección se rehace en la Antesala.
- **Efecto esperado.** Comprar generadores pasa a ser construir un mazo-forja. Renacer gana una dimensión
  táctica: reconstruyes y puedes elegir otra cosa.

**9. Grimorios como preparación por ascensión** · `game_state.gd::card_packs`, `antesala_screen.gd` · **M**
- **Qué cambiar.** El Grimorio comprado desbloquea el paquete, pero en la Antesala eliges **2 Grimorios activos**
  (3 con un nivel de Arsenal). Las recompensas sólo salen de Base + los activos.
- **Efecto esperado.** Arquetipos coherentes (con los 6 comprados, el pool es de 90 cartas y no se puede forzar
  nada) y una decisión real antes de cada ascensión, al estilo de los clanes de Monster Train.

**10. Autoforja con interruptor y reserva** · `game_state.gd::_autobuy`, `forge_screen.gd` · **S**
- **Qué cambiar.** Interruptor, «reservar X% del banco», no comprar durante la ascensión y comprar el generador
  con mejor relación coste/producción, no el más barato.
- **Efecto esperado.** Elimina la trampa de A6.

**11. Sumideros de Polvo Estelar** · `forge_db.gd` (TALENTS) · **M**
- **Qué cambiar.** Talentos con rangos (por ejemplo, Memoria Ígnea I–V, Ecos I–III) y una segunda capa,
  «Constelaciones», que cuestan cientos o miles de Polvo y **cambian reglas**: +1 Quema en caliente por turno,
  empezar en el piso de checkpoint (#13), un Temple extra por carta, un 3.er Grimorio activo.
- **Efecto esperado.** A1: el Polvo vuelve a ser una decisión tras las 2 h. Objetivo: no acumular más de 2–3
  compras de Polvo sin gastar.

**12. Escalar Codicia y Calor con su coste** · `forge_db.gd` (ARSENAL greed) · **S**
- **Qué cambiar.** Codicia growth 1.9 → 2.6, o rendimiento decreciente (+10% los 10 primeros niveles, +5% después).
- **Efecto esperado.** El multiplicador de la Torre deja de quedar resuelto antes de las 3 h y alarga la curva
  del Arsenal.

### Prioridad 3: Torre, puertas y ritmo

**13. Checkpoints de ascensión** · `game_state.gd::start_run`, `antesala_screen.gd` · **M**
- **Qué cambiar.** Puedes empezar en el primer piso de cualquier acto ya superado (máx. récord − 10). Recibes un
  draft compensatorio: 1 carta elegida por cada 3 pisos saltados, 1 reliquia por cada jefe saltado. Los pisos
  saltados no pagan Ascuas.
- **Efecto esperado.** Ascensiones de 20–40 min a mitad de partida en lugar de 90 (A3), y más bucles Forja⇄Torre
  por sesión.

**14. Puertas con información y sin duplicados** · `run_state.gd::roll_doors`, `map_screen.gd` · **M**
- **Qué cambiar.** Nunca dos puertas del mismo tipo. Cada puerta de Combate muestra un **rasgo**: «Urracas
  (+Ascuas)», «Gólem (Hollín)», «Recompensa: carta rara», «+1 Quema este combate» o «Carta de Pira garantizada».
  Opcional: ver las puertas del piso siguiente (1 piso de anticipación).
- **Efecto esperado.** El 53% de los pisos con elecciones vacías pasa a tener una elección con información
  parcial, que es lo que prometía VISION («puertas con información parcial»).

**15. Tesoro con precio** · `event_screen.gd::_treasure`, `run_state.gd` · **S**
- **Qué cambiar.** Cofre cerrado: «Forzarlo (−10% PV)», «Fundir la cerradura (quema 1 carta del mazo para
  siempre)» o «Dejarlo». Bajar su peso de 6 a 4.
- **Efecto esperado.** Deja de ser una puerta dominante y el Tesoro también usa la palabra QUEMAR.

**16. Élites: elegir reliquia y una recompensa propia** · `combat_screen.gd::_victory` · **S**
- **Qué cambiar.** Elegir 1 de 2 reliquias. Además, la élite deja 1 *Lingote* (#6) o +1 XP de Maestría a una carta
  a elección.
- **Efecto esperado.** El riesgo de la élite vuelve a valer la pena.

**17. ★ Brasas Vivas: «push your luck» opcional** · `game_state.gd::gain_tower_embers`, `map_screen.gd`, `summary_screen.gd` · **M**
- **Qué cambiar.** Las Ascuas base se ingresan al momento, como ahora (se respeta «nada se pierde»). Encima se
  acumula un **multiplicador de racha** (+5% por piso sin volver a la Forja) que **sólo se cobra** al retirarse
  o al vencer a un jefe. Si mueres, se pierde la racha, no las Ascuas.
- **Efecto esperado.** «Volver a la Forja» se convierte en una decisión a lo Balatro/Hades (hoy no tiene sentido
  retirarse) y crea tensión sin castigar la muerte.

**18. Afijos de ciclo** · `enemy_db.gd::make` · **M**
- **Qué cambiar.** En el ciclo II y siguientes, cada enemigo recibe 1 afijo de una tabla según la semilla:
  *Ignífugo* (−50% Quemadura), *Carroñero* (se cura cuando quemas), *Avaro* (roba al quemar), *Sofocante* (Ahogo
  al empezar), *Ceniciento* (añade Hollín). Bajar `HP_PER_CYCLE` de 4.0 a ~3.0 para compensar.
- **Efecto esperado.** Los ciclos dejan de ser «lo mismo ×4» y los enemigos castigan o premian *cómo* quemas,
  no sólo *si* quemas.

**19. Enemigos que reaccionan a la quema (ciclo 1)** · `enemy_db.gd`, `combat_engine.gd::_burn` · **M**
- **Qué cambiar.** 2–3 enemigos nuevos con contrajuego: *Polilla de Llama* (+2 de Fuerza por cada carta quemada
  este turno), *Devorador de Ceniza* (se cura 4 por quema), *Fuelle Rival* (si no quemas este turno, gana Bloqueo).
- **Efecto esperado.** Habrá combates en los que lo correcto es **no** quemar o quemar más, así que la decisión
  depende del contexto.

### Prioridad 4: equilibrio de cartas, reliquias y tienda

**20. Topes y logaritmos en las cartas de Forja** · `card_db.gd` (`dyn_value`, `stardust_strike`, `legacy`, `block_gens`, `block_codex`) · **S**
- **Qué cambiar.**
  - Golpe Estelar: `4 + 2·log2(1 + Polvo)` (≈14 con 30 de Polvo, ≈20 con 1.000).
  - Legado: tope de +4 de Fuerza (+6 mejorada), o +1 de Fuerza por cada carta con **Maestría 5**.
  - Muralla de Engranajes y Eco del Reliquario: +1 por cada 50 generadores y +1 por cada 4 reliquias.
- **Efecto esperado.** A4: dejan de ser la elección automática y siguen leyendo la Forja.

**21. El daño sin fuente escala con Filo Eterno** · `combat_engine.gd::calc_damage`, `_tick_scorch` · **S**
- **Qué cambiar.** Quemadura, Detonar, Fuego Interior, Corona y espinas aplican `run.dmg_mult` (sin Fuerza).
- **Efecto esperado.** A5: Ceniza y Pira siguen siendo viables en el ciclo 2. Repetir `card_eval_c2`.

**22. Pase de cartas** · `card_db.gd` · **S**
- **Qué cambiar.**
  - Incendio: `scorch_all 4 → 3`.
  - Rescoldo: `smolder 2 → 1` (mejorada 2).
  - Atizar: coste 1 → 0 (mejorada: roba 4).
  - Muro de Hierro: 13 → 16.
  - Detonar: añadir `scorch 3` antes de detonar.
  - Buscar Combustible: robar 2 **y** +1 Quema.
  - Horno de Tiro: además, +1 Quema al jugarla.
  - Ráfaga de Martillo+: 5×4.
  - Mandoble+: 18 de daño, Fuerza ×5.
- **Efecto esperado.** Comprimir la horquilla de `card_eval` (hoy de +66 a −25) a ~+35/−5 dentro de cada rareza.

**23. Reliquias** · `relic_db.gd`, `run_state.gd`, `combat_engine.gd` · **S**
- **Qué cambiar.**
  - Núcleo Agrietado: 3 Cenizas Húmedas *no etéreas*.
  - Ceniza de Fénix: si ya tienes Fénix, da un 2.º uso (`phoenix_charges: int`).
  - Jugador de Ascuas: 60% de ganar ×1.8, o apostar Maestría.
  - Mazo Escarchado: la Escarcha no se puede quemar.
- **Efecto esperado.** Elecciones de reliquia de jefe y de pacto sin respuesta obvia.

**24. Precios del Yunque con los multiplicadores de la Torre** · `shop_screen.gd::_price` · **S**
- **Qué cambiar.** Multiplicar el término `producción × s` por `(1 + 0.1·Codicia) · (1 + Calor·bonus)`, y añadir
  una 2.ª eliminación con el precio ×1.5. Igualar la Ofrenda de la Hoguera: elimina, pero sólo da Ascuas si la
  carta tiene Maestría ≥ 1.
- **Efecto esperado.** M2/M3: el Yunque vuelve a obligar a elegir.

**25. Urracas con dientes** · `enemy_db.gd` · **S**
- **Qué cambiar.** Devuelven ×1.5 en lugar de ×2. Si sobreviven 3 turnos, **huyen** con lo robado (intención
  «Huir»). Urraca Dorada: Bloqueo 12 → 18.
- **Efecto esperado.** Crean presión de tempo («mátala primero») en lugar de ser siempre una ganancia.

### Prioridad 5: onboarding y lectura

**26. Introducción por capas** · `forge_screen.gd::_show_welcome`, `combat_screen.gd` · **S**
- **Qué cambiar.** Bienvenida de 2 líneas («Compra una Chispa. Luego asciende»). Explicar Maestría en la 1.ª
  quema, Resonancias en la 1.ª décima unidad, Braseros al morir, y Pactos y Reliquario tras el primer jefe (esto
  último ya se hace).
- **Efecto esperado.** Los primeros 5 minutos sin muro de texto.

**27. Primera ascensión guiada** · `game_state.gd::start_run` (si `runs_started == 0`), `run_state.gd` · **S**
- **Qué cambiar.** Piso 1 fijo (un Limo) con una mano preparada: 3 Golpes, 1 Leña, 1 Defensa, y una indicación
  «quema la Leña: +1 Energía». Piso 2, Gólem de Hollín: el Hollín es combustible.
- **Efecto esperado.** Se enseñan las 2 ideas clave jugando, antes del minuto 3.

**28. Mano legible** · `combat_screen.gd` (`HAND_Y`), `card_view.gd` · **S**
- **Qué cambiar.** Subir `HAND_Y` ~40 px o usar un modo compacto donde el texto «Al quemar» quede siempre visible.
  Mostrar las cifras de las intenciones que no son ataque (Bloqueo, robo, Ahogo).
- **Efecto esperado.** Corrige M7 sin obligar a pasar el ratón por cada carta.

**29. Metas a largo plazo visibles** · `forge_db.gd` (HITOS), `forge_screen.gd` · **M**
- **Qué cambiar.** Una 2.ª Crónica (hitos 27–60) con recompensas que **desbloquean** cosas: el Grimorio 7, la
  2.ª ranura de Herencia, el Pacto 9–12, una variante del mazo inicial («Fogonera Pirómana: 3 Leñas en lugar de
  2 Defensas»). En lugar de segundos de producción, desbloqueos.
- **Efecto esperado.** Rejugabilidad y objetivos más allá de las 8 h, hasta que llegue el Vidriero (v0.3).

---

## 4. Lo que NO haría

- **No quitaría la regla «morir no te quita nada».** Es la promesa diferencial frente a StS. La tensión debe salir
  de algo *opcional* encima (Brasas Vivas #17, Pactos), no de castigar la base.
- **No limitaría la quema a cartas «quemables».** Que *cualquier* carta se pueda quemar es la gracia. Hay que
  cambiar el *valor* de la quema según la situación (#1), no restringir el qué.
- **No añadiría más monedas que los lingotes de #6** (y como máximo 3). La claridad de «Ascuas = todo» es un
  activo. Si los lingotes enturbian la lectura, me quedaría con #1 + #7 + #8, que no añaden monedas.
- **No subiría HP_PER_CYCLE** para frenar el avance. El problema del ciclo 2 es la monotonía, no la dificultad:
  afijos (#18) y checkpoints (#13) antes que más PV.
- **No haría la Maestría más rápida** ni bajaría los umbrales `MASTERY_XP`. El ritmo (1.ª carta a nivel 5 a los
  ~93 min) está bien. El problema es *a qué cartas va* (#2, #3).
- **No metería un mapa ramificado de StS.** Las puertas por piso son un buen formato propio. Necesitan
  información (#14), no otra estructura.
- **No equilibraría por el bot.** `progression_sim` no usa la tienda, ni los eventos con decisión, ni los Pactos
  con criterio. Sirve para encontrar extremos (Golpe Estelar, Autoforja, el Polvo sin gastar), no para afinar la
  última cifra. Cuando se toquen #1 y #2, hay que mejorar la IA (que valore Maestría y Ascuas frente a tempo)
  antes de fiarse de las curvas.
- **No pondría más cartas** hasta resolver las prioridades 1 y 2. Ya hay 90; el problema es que la mitad no
  compite (`card_eval`) y que la quema no distingue entre ellas.

---

### Apéndice: cifras clave
- `progression_sim` (8 h): 11 ascensiones; récord 80; Polvo 2.719 (2.678 sin gastar); 12/12 talentos; Arsenal finito
  al máximo; 49 cartas con Maestría y 12 a nivel 5; Reliquario 40/40 a los ~390 min.
- `balance_sim`: Novata 9.6 de piso medio (mediana 10); Mítica 62.9.
- `burn_policy`: «sobrantes» frente a «sólo Combustible», perfil Medio: +1.3 pisos, ×3.3 Ascuas, ×5.3 Maestría.
- `card_eval` (ciclo 1, Δ % de victorias): mejores Golpe Estelar +66.7, Incendio +64.1, Danza de la Pira +63.5;
  peores Atizar −25.5, Fundir −22.4, Detonar −20.8.
- `doors`: 53% de pisos con Combate duplicado, 12.3% sin elección, 19.3% con Tesoro.
- `econ_sources`: quema 52.5%, oleada 30.2%, idle 10.9%, matar 0.0%.
