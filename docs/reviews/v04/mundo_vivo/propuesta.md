# Mundo vivo — Propuesta de entornos, ambiente y VFX (v0.4)

> Rol: Artista de entornos y animador/VFX sénior. Referentes: **Blasphemous** (arquitectura como relato, siluetas), **Eastward**
> (densidad de atrezo, luz cálida de interiores), **Sea of Stars** (luz dinámica sobre pixel art sin perder la rejilla),
> **Dead Cells** (VFX legibles con paleta corta), **Owlboy** (parallax profundo y aire), **Kingdom Two Crowns** (el mundo
> reacciona a tu economía: la luz *es* tu progreso).
>
> Prueba de concepto: `tests/_review_art/v04/mundo_vivo/poc_mundo_vivo.gd` (+ `.tscn`) → `tests/_review_art/v04/mundo_vivo/out/`.

---

## 0. Tesis (posición firme)

1. **Hoy los actos son colores, no lugares.** Los tres fondos son la *misma maqueta* (pilastras en x=100/212, dos ventanas en
   x=52/268, arco central, dos estandartes, cuatro antorchas) recoloreada. La biblia lo prohíbe («No recolorear para crear actos»)
   y el código lo hace (`_bg_brick`/`_bg_rock`/`_bg_ice` comparten `_bg_pilasters`, `_bg_windows`, `_bg_arch`, `_bg_banners`).
2. **La Torre debe ser una chimenea.** EMBERSPIRE ya tiene la metáfora y no la dibuja: *la Forja está abajo, la Torre es su
   tiro*. Cada piso es una galería alrededor del gran tiro central; subir es seguir el humo. Eso conecta TODO: la Forja idle
   (abajo) ilumina literalmente la Torre (arriba). El jugador ve su economía en las paredes.
3. **La luz es el recurso — también en el fondo.** El ambiente no es decoración: es la *interfaz pasiva* del estado del juego
   (Calor, producción, Resplandor, Brasas Vivas, PV bajos). Si el jugador produce más, la rejilla del suelo brilla más, el tiro
   sube más chispas y se encienden más ventanas de otras galerías. Es el «Kingdom Two Crowns» de un roguelike de cartas.
4. **Luz por pasos de rampa, no por mezcla.** Rebato una parte de la biblia: los halos aditivos suaves (`UI.halo`, degradado
   radial continuo de 64 px escalado a 180–520 px) **son el principal motivo por el que el juego parece prototipo**. Toda la luz del
   mundo pasa a ser *escalonada en la paleta del material* (demostrado en la prueba).

---

## 1. Crítica de lo actual (con capturas)

### 1.1 Fondos
| Problema | Dónde se ve | Por qué importa |
|---|---|---|
| **Misma composición en los 3 actos.** Sólo cambian la textura del muro (ladrillo / bloques irregulares / bloques grandes) y la rampa. | `07_combat` vs `16_act2_hydra` vs `17_act3` | El jugador no «viaja». 30 pisos se sienten como uno solo. |
| **El foco cae en un hueco vacío.** El arco central (52 px de ancho, interior `#140a0c` con brasas en la base) es el elemento de mayor contraste del fondo y está *entre* la heroína y los enemigos, donde no pasa nada. | `07_combat`, `01_title` | Compite con la lectura del combate; en jefes (`14_boss_summon`) el jefe queda *dentro* del arco y se aplana. |
| **Muro de un solo plano.** Ladrillo uniforme de 16×8 con luz en anillos concéntricos idénticos para las 4 antorchas. | todas | Sin profundidad, sin historia. Los anillos perfectos se leen como «degradado de programador». |
| **Parallax decorativo.** `background_near` = 2 pilares negros de 10 px y 2 cadenas de 1 px; desplazamiento 0–2 px con el ratón. | `07_combat` (bordes) | Ocupa 20 px de pantalla útil y no aporta profundidad (no hay capa lejana). |
| **Ventanas sin exterior.** Cielo en 4 bandas con 5 puntos naranjas (acto 1) o luna 7×7 (acto 3). | `07_combat`, `17_act3` | Desaprovecha el gran contraste del juego: *dentro arde, fuera se congela* (la Fogonera viene de una ciudad helada). |
| **Estandartes con el icono de llama de la UI** (`icon_image("flame")` pegado). | `07_combat` | Mezcla la gramática de interfaz con la del mundo. |
| **El suelo ocupa el 35 % de la pantalla y es una cuadrícula**, más clara que el muro en el centro (charcos de luz en bandas). | `07_combat`, `20_rest` | La mitad inferior está tapada por cartas: ese esfuerzo no se ve, y lo que se ve compite con la mano. |
| **Todas las pantallas reutilizan `background()`** con otra semilla: Forja (`02_forge`), Antesala (`05`), mapa (`06`), tienda (`19`), hoguera (`20`), evento (`21`), resumen (`22`). | todas | Ningún lugar tiene identidad. La tienda («Yunque Errante») y la hoguera son el mismo pasillo. La Forja —el corazón del juego— es un panel sobre un muro. |

### 1.2 Ambiente
- **Antorchas = 12 partículas `CPUParticles2D` de 4–8 px** que suben a posiciones subpíxel (no se ajustan a la rejilla ×4) sobre un
  soporte de 3 px sin cuenco. En `07_combat` las llamas parecen chispas sueltas flotando junto a la pared, no fuego.
- **Halos aditivos** de 180 px (`UI.halo`) parpadeando con tween de alfa: neblinas circulares suaves sobre pixel art duro
  (`07_combat`, a ambos lados de cada ventana). Es la textura más «no pixel art» de la pantalla.
- **Polvo** (`UI.dust`, 26 motas de 4×4 px en 1280×420) sin relación con las fuentes de luz: ni se iluminan cerca de la antorcha ni
  caen del techo salvo en jefes.
- **No hay nada que se mueva por sí mismo** (cadenas, humo, goteos, criaturas). La biblia dice «2–3 cosas vivas por pantalla» y
  hoy hay 2 *sistemas de partículas genéricos*, no cosas vivas.

### 1.3 VFX de combate
- **Quemar** (`09_burn`): la carta vuela 260 ms, `burn_away` (shader de disolución, bien) y luego `UI.sparks` 40–60 partículas de
  4–8 px con gravedad 500 → una fuente genérica de confeti naranja idéntica a la del golpe, la muerte, la invocación y la maestría.
  El momento central del juego no tiene firma propia.
- **Muerte** (`12_death_dissolve`): la disolución es correcta, pero se ahoga en **3 × 60 chispas + 3 textos «9999!» + «+32»**.
  Hay más píxeles de VFX que de escenario: ilegible.
- **Estados** (Quemadura, Bloqueo, Fuerza, Débil…) sólo existen como icono 12×12 bajo la barra y un texto flotante. Un enemigo
  con Quemadura 9 se ve igual que uno sin ella.
- **Invocación de jefe** (`14_boss_summon`): `ColorRect` 28 % negro + halo + polvo cayendo. No hay entrada, ni silueta, ni
  reacción del escenario.
- **Golpe**: destello + empuje + hitstop está bien resuelto (mérito de v0.3). Falta el **arco de impacto** (smear del martillo
  existe en la heroína, pero no hay marca de impacto en el objetivo).

### 1.4 Transiciones
- Un único fundido a negro de 180 + 250 ms (`main.go`) entre todas las pantallas. Subir un piso, entrar en la tienda, morir y volver
  a la Forja se sienten igual. No hay sensación de *ascenso*.

---

## 2. La Torre como LUGAR

### 2.1 Qué es la Torre
**La Torre de Brasa es la chimenea de la última forja del mundo.** En la base está la Forja (la pantalla idle). Encima, un tiro
cilíndrico de 30 pisos; cada piso es una **galería anular** alrededor del tiro: un pasillo con muro exterior (ventanas a la ciudad
helada) y un parapeto interior que se asoma al vacío del tiro, por el que suben calor, humo y chispas *desde tu Forja*.

Sección vertical (lo que vende cada acto):

```
            ░░ cielo helado, estrellas ░░
   ┌───────────── corona rota ─────────────┐   Piso 30: el Rey Escarcha (el tiro está tapado de hielo)
   │  ACTO 3 · CENIZA HELADA  (21–30)       │   el calor ya no llega: ceniza que se congela en el aire
   │  campanario / observatorio abandonado  │
   ├───────────────────────────────────────┤
   │  ACTO 2 · ESCORIA (11–20)              │   fundición: crisoles, canales de escoria, jaulas de los
   │  la fundición: donde se vertía metal   │   fundidores; la escoria verde (accent 8ae048) sigue viva
   ├───────────────────────────────────────┤
   │  ACTO 1 · HOLLÍN (1–10)                │   herrería y salas de fogones: ladrillo tiznado, conductos
   │  sala de fogones, conductos de fuelle  │   de cobre que bajan a los hornos, el humo lo ennegrece todo
   ├───────────────────────────────────────┤
   │  ANTESALA (la puerta de la Torre)       │
   └──────────────  LA FORJA  ─────────────┘   el corazón: el fuego que alimenta todo
```

Regla de lectura: **cuanto más arriba, menos calor llega**: el acto 1 está sobrecalentado y tiznado; el acto 2 es industrial y
tóxico; el acto 3 es el lugar donde la Torre se está muriendo de frío. *Subir es llevar el fuego hasta arriba.* El ciclo (II, III…)
significa que la Forja ha empujado su calor un tramo más: los mismos lugares, **recalentados** (vetas de brasa, hielo fundiéndose,
escoria más brillante), no recoloreados al azar.

### 2.2 Capas comunes (320×180 nativos, ×4)

| Capa | Ancho | Parallax (ratón ±1) | Valor (luminancia) | Contenido |
|---|---|---|---|---|
| L0 Cielo / exterior | 324 | +1 px | 3–15 % (frío) | Noche helada, luna, montañas, tejados con nieve (ciudad de la Fogonera). Sólo se ve por ventanas/brechas. |
| L1 Lejos (el tiro) | 324 | +1 px | 5–25 % (cálido abajo) | Muro curvo del tiro a **media escala de ladrillo** (3 px), nervios, pasarelas, la gran cadena, ventanas de otras galerías, luz que sube. |
| L2 Medio (plano de juego) | 320 | 0 (fijo, como los luchadores) | 10–40 % | Muro de la galería, pilastras, el gran vano al tiro con parapeto y barandilla, atrezo narrativo, braseros, ventana. Suelo. |
| L3 Suelo | (en L2) | 0 | 8–30 %, oscuro bajo la mano | Losas en perspectiva con luz por losa, rejilla de calor, ceniza, cascotes. |
| L4 Primer plano | 328 | −2 px | 0–12 % (silueta) | Riostras, cadenas y poleas en silueta casi negra; nunca tapa la franja y=13…135 de juego. |
| VIVO (sprites) | — | según capa | — | Llamas, humo, chispas del tiro, nieve tras el cristal, cadena con crisol, motas. |

Además del parallax por ratón, **la transición entre pisos** usa estas capas en vertical (ver §3.5): es donde el parallax paga.

### 2.3 Acto 1 · HOLLÍN — «Las Salas de Fogones» (pisos 1–10) — *demostrado en la prueba*
- **Arquitectura:** galería de ladrillo a soga 12×5 tiznado (más negro arriba: −2 pasos y<20, −1 y<32), pilastras de sillar 16 px
  con capitel y basa, gran vano en arco de 15 dovelas hacia el tiro, parapeto de piedra con barandilla de hierro.
- **Historia ambiental:** fue una herrería. Conducto de cobre del fuelle con bridas cada 22 px y volante de válvula que **baja
  hasta la chimenea de tu horno de combate** (el horno no está «puesto encima»: está conectado al edificio). Herramientero con
  tenazas, martillo y cazo. Columnas de hollín encima de cada brasero (el humo lleva años subiendo por ahí). Nieve que ha entrado
  por la ventana en el alféizar.
- **Puntos de luz (4):** 2 braseros de pared (cálidos, 6 bandas), el tiro (cálido desde abajo, ∝ producción de la Forja), la luna
  por la ventana (fría: alféizar + mancha en el suelo). Más 1 móvil: el crisol que oscila.
- **Variación por piso:** grietas/desconchones `0.03 + 0.006·piso`; cascotes en el suelo = nº de piso; desde el piso 7 cae
  polvo del techo (anticipa al jefe). Pisos 9–10: barandilla rota, una pilastra apuntalada.
- **Jefe (El Carbonero / El Gran Fuelle):** la sala del jefe es la *Boca de Fogones*: el vano central se convierte en el morro de un
  horno gigante; el jefe sale de ahí (ver §4.6).

### 2.4 Acto 2 · ESCORIA — «La Fundición»
- **Arquitectura:** roca labrada y hierro remachado; el muro exterior es **una pared de escoria vitrificada** (bloques irregulares
  ya existentes, pero con brillo vítreo: 1 px de reflejo frío `#8ae048` a 30 % en la arista superior).
- **Lugar:** canales de colada colgados (grandes crisoles basculantes en L1, canalones con escoria verde que gotea en L2), jaulas
  de fundidores (las de hoy, pero colgadas *sobre el tiro*), grúa-pescante con contrapeso.
- **Luz:** escoria verde (accent bioma) como fuente secundaria baja y tóxica; el tiro aquí sube **naranja y verde** (la escoria
  contamina el humo). Exterior: no hay ventanas — estamos dentro del corazón del edificio; en su lugar, **rejillas de ventilación**
  por las que entra luz cálida en rayas.
- **Vida:** goteo de escoria (8 f), crisol basculando cada ~6 s (12 f), vapor de enfriamiento (6 f), burbujas en el canal.
- **Por piso:** el nivel de escoria en los canales sube con el piso; el jefe (Reina de Escoria / Hidra) emerge de una balsa.

### 2.5 Acto 3 · CENIZA HELADA — «La Corona Fría»
- **Arquitectura:** sillares grandes (24×12) con hielo en las juntas, arcos rotos **abiertos al cielo** (L0 ocupa ~30 % de la
  pantalla: es el único acto donde el exterior domina), tejado de cobre verdigris hundido, campana caída.
- **Lugar:** el observatorio/campanario: el último punto al que llegaba el humo. El tiro está **taponado de ceniza congelada**
  (L1 = una columna de ceniza helada estratificada, con brasas atrapadas dentro como insectos en ámbar).
- **Luz:** la fuente principal es FRÍA (luna/aurora, rampa COLD); el fuego es escaso: braseros casi apagados (llama de 2 bandas)
  que **se avivan cuando la heroína quema cartas** (§3.4). Sin tramado (regla de la biblia para hielo).
- **Vida:** nieve en 3 profundidades (L0 lenta 1 px/3 f, L2 1 px/f, L4 2 px/f grande), vaho de respiración de la heroína (4 f
  cada ~3 s), carámbanos que gotean cerca de braseros encendidos, cuervos de ceniza en la cornisa de L1.
- **Por piso:** escarcha que avanza desde los bordes (máscara por piso); piso 30: la corona del tiro abierta al cielo.

### 2.6 Los lugares de servicio (mismo mundo)
| Pantalla | Lugar | Clave visual |
|---|---|---|
| **Forja** (idle) | **El fondo del tiro.** Cámara de bóveda radial; el horno de 64×56 es el centro y por encima se ve el tiro subiendo hasta perderse (L1 vertical). | **Cada generador comprado añade algo físico**: Chispa → braseros pequeños en nichos (1 por 10 unidades, máx. 8); Fuelle → fuelle de cuero que respira (4 f); Crisol → crisol en el yunque; Alto Horno → segunda boca. Los **Braseros** (piso récord) se ven como luces encendidas *subiendo por el tiro* (1 punto de luz por piso alcanzado en L1). |
| **Antesala** | Pie de la escalera de caracol: puerta de la Torre con los **Pactos de Brasa como cadenas/candados** sobre la puerta (1 por pacto activo). Calor 0 = puerta abierta y limpia; Calor 11 = puerta encadenada y al rojo. | |
| **Mapa (puertas)** | El **rellano del piso**: las puertas son arcos reales en el muro del acto (no cajas de UI). La puerta de élite tiene marcas de garras; la de tienda, el letrero del yunque; la de hoguera, luz cálida bajo el umbral; el misterio, niebla violeta. La columna de pisos de la izquierda pasa a ser **una sección de la Torre** con la Fogonera subiendo. | |
| **Hoguera** | **Nicho de descanso** de la galería: un banco, una manta, la hoguera en un brasero de suelo. Única pantalla sin enemigos → la más viva (5 cosas vivas permitidas). | |
| **Tienda (Yunque Errante)** | Un **carromato-forja** del mercader detenido en la galería: toldo, yunque, género colgado. Las cartas en venta están **clavadas en un tablón** (mismo marco, en el mundo). | |
| **Eventos** | Viñetas a pantalla completa del lugar del evento (no un icono de 32 px en una caja). Ej.: Espíritu de la Forja = el humo del tiro forma una figura con la cara de la heroína. | |
| **Resumen** | Caída por el tiro: la Fogonera vuelve a la Forja; los braseros nuevos se **encienden en secuencia** subiendo por el tiro (1 por piso, 80 ms cada uno). | |

---

## 3. Sistema «mundo vivo»

### 3.1 Principios
1. **Todo lo vivo está en la rejilla de arte.** Posiciones enteras en px de arte (×4), animación por fotogramas, sin
   escala/rotación en pantalla. Las partículas también: se pintan como píxeles de arte (§5.4).
2. **Cada cosa viva tiene una causa.** El humo sale de un brasero; las chispas suben por el tiro *porque* abajo está tu Forja; la
   nieve entra por la ventana.
3. **Ritmos desfasados y primos** (100, 125, 140, 180 ms; periodos 0,8 / 1,76 / 6 s) + aleatoriedad por instancia (fase y
   ±15 % de periodo), para que nada pulse al unísono.
4. **Presupuesto** (abajo). El combate es para leer cartas e intenciones: el ambiente nunca debe superar el 6 % de los píxeles en
   movimiento en un fotograma, ni estar en la franja de intenciones (y=60…84 de arte sobre los enemigos).

### 3.2 Catálogo por escena (fotogramas · ritmo · aleatoriedad)

**Comunes a todos los actos**
| Elemento | Tamaño | Fotogramas | Ritmo | Aleatoriedad |
|---|---|---|---|---|
| Llama de brasero de pared | 13×18 | 8 (bucle) | 100 ms | fase por brasero (k+3); variante «débil» (acto 3) de 2 bandas |
| Humo de brasero | 12×26 | 8 (4 bocanadas) | 100 ms | deriva hacia el tiro; huecos estables por bocanada |
| Pavesas | 1 px | 8 | 100 ms | 3 por brasero, desfase 0,37 |
| Luz del brasero | — | 3 radios precalculados | cambia cada 100–200 ms | secuencia `FLICK = [0,1,0,−1,1,0,1,−1]` desfasada |
| Chispas del tiro | 1 px | 16 | 110 ms | nº = 5 + 6·calor; trayectorias con oscilación senoidal ±2 px |
| Motas de polvo | 1 px | 16 (órbita 1,6 px) | 110 ms | se tiñen de fuego dentro de 26 px de un brasero |
| Cadena con crisol | 9×50 | 16 posiciones (péndulo ±3 px) | 110 ms (periodo 1,76 s) | amplitud 3–4 px; se **sacude** (amplitud ×2, 6 f) en golpes > 20 de daño |

**Acto 1 · Hollín**: goteo de hollín del techo (copo 1 px cada 2–5 s, 12 f de caída), escape de vapor en una brida del conducto
(6 f cada 8–14 s), rata que cruza el parapeto (10 f, 1 vez cada 40–90 s, nunca durante el turno enemigo).
**Acto 2 · Escoria**: goteo de escoria (8 f + salpicadura 4 f), crisol basculando (12 f cada ~6 s), burbujas en el canal (4 f), vapor
de enfriamiento (6 f).
**Acto 3 · Ceniza Helada**: nieve en 3 capas (velocidades 1/3, 1, 2 px/f), vaho de la heroína (4 f cada ~3 s), cuervo de ceniza
en cornisa de L1 (idle 2 f, sacude alas 6 f, vuela 8 f si hay un golpe crítico), carámbano que gotea cerca de braseros (6 f).
**Forja**: fuelle (4 f a 180 ms, ritmo ∝ nivel del Fuelle), brasas del horno (4 f ya existentes), chispas de yunque al hacer clic
(5 f), luces del tiro encendiéndose (1 por piso récord).
**Hoguera**: llama de suelo 32×24 (4 f actuales → 8 f), chispas, manta que se mueve con la respiración (2 f), sombra de la
heroína proyectada en el muro que oscila con la llama (2 variantes).
**Tienda**: toldo con 3 f de ondulación cada 4 s, martillazo del mercader (6 f cada 5–8 s) con chispa, género colgado oscilando.
**Mapa**: el humo/brillo bajo cada puerta según su tipo (4 f), antorchas a los lados de las puertas.

### 3.3 Presupuesto de «cosas vivas» por pantalla
| Pantalla | Fuentes vivas (máx.) | Píxeles en movimiento / fotograma (arte) | Notas |
|---|---|---|---|
| Combate normal | 4 (2 braseros+humo, tiro, 1 propia del acto) | ≤ 3.400 (≈6 %) | Durante el turno enemigo se congela todo lo opcional (rata, cuervo) |
| Combate de jefe | 3 + escenografía del jefe | ≤ 4.000 | El jefe ES el ambiente: braseros bajan una banda |
| Forja | 6 (la pantalla idle debe hipnotizar) | ≤ 6.000 | Es donde el jugador mira «sin hacer nada» |
| Hoguera | 5 | ≤ 4.500 | |
| Mapa / tienda / evento | 3 | ≤ 2.500 | |
| Modal abierto | 1 (sólo la llama más cercana sigue) | — | Atenuar lo demás a 50 % de frecuencia |

### 3.4 El estado del juego alimenta el ambiente
| Estado | Dónde se ve | Cómo (concreto) |
|---|---|---|
| **Producción de la Forja (Ascuas/s)** | Tiro (L1) y rejilla del suelo | Radio de la luz ascendente ×(0,75 + 0,5·h); nº de chispas 5+6·h; brillo de la rejilla de 2 a 5 pasos; ventanas de otras galerías encendidas ∝ h. Con h = log10(producción) normalizado por ciclo. *Demostrado en `a1_variaciones_x2.png`.* |
| **Calor de Pacto** | Antesala, braseros, viñeta | Cada punto de Calor: +1 cadena en la puerta de la Antesala; en combate, los braseros arden una banda más altos y el humo es más denso; Calor ≥ 8 = ondas de calor (shader §5.3) en la boca del horno. |
| **Quemar una carta** | Toda la sala | Los braseros **inclinan la llama hacia el horno** 2 f (el aire es aspirado), el tiro escupe una racha de chispas 300 ms, la rejilla del suelo destella 1 paso. En el acto 3 los braseros apagados se avivan 4 s. |
| **Resplandor** (bonus temporal de producción) | Forja y combate | Halo escalonado dorado sobre los nervios del tiro; en combate, 1 brasero extra encendido en el piso. |
| **Brasas Vivas** (racha de pisos) | Mapa / combate | Una brasa por piso de racha en el alféizar/parapeto (máx. 10), que se enfrían si vuelves a la Forja. |
| **Ciclo** | Todo el acto | Ciclo II: vetas de brasa en las juntas (`a1_variaciones`, cuadrante inferior derecho); ciclo III: el hielo del acto 3 se derrite en hilos de agua, la escoria del acto 2 brilla en la paleta de fuego. Nunca solo recolorear. |
| **Tipo de puerta** | Transición | Élite: la sala se oscurece 1 paso y la barandilla tiene marcas de garras; hoguera: luz cálida bajo el umbral; misterio: niebla violeta a ras de suelo (6 f). |
| **PV bajos (<25 %)** | Luz de la sala | Sustituir la viñeta roja pulsante (shader continuo) por: braseros **bajan 2 bandas** y parpadean irregular, el tiro se enfría (chispas a la mitad), latido = la luz de la sala pulsa 1 paso a 1,1 Hz. El mundo se apaga contigo. |
| **Muerte de enemigo** | Sala | Sus brasas suben por el tiro (las Ascuas «van a la Forja» de forma física, no sólo hacia el contador). |

### 3.5 Transiciones
| Paso | Transición | Tiempo |
|---|---|---|
| Piso → piso | **Ascenso vertical por capas**: L0 baja 4 px de arte, L1 24 px, L2 180 px (sale la galería, entra la siguiente); la heroína sube por una escalera de caracol en silueta en L4. | 650 ms (ease in-out), cuantizado a 4 px |
| Combate → recompensa | La sala se oscurece 2 pasos de rampa (no alfa), las brasas de los muertos suben por el tiro. | 400 ms |
| Torre → Forja (morir/volver) | **Caída por el tiro** (L1 en scroll inverso rápido con chispas) → la boca del horno ocupa la pantalla → abre la Forja. | 900 ms |
| Forja → Antesala | La cámara sube por el tiro hasta la puerta. | 500 ms |
| Abrir tienda/hoguera/evento | Barrido en diagonal de una «cortina de humo» (6 f de humo pixelado que tapa y destapa). | 300 + 300 ms |
| Cambio de acto | Tarjeta de título del acto sobre el exterior (L0) del nuevo acto, 1,6 s. | |

---

## 4. VFX de combate

Reglas: VFX del mundo en la rejilla ×4; **máximo 1 efecto «héroe» a la vez**; colores sólo de la rampa FIRE/COLD/estado;
cada efecto tiene 3 tiempos: **anticipación → impacto (1–2 f a valor máximo) → resto que se disipa en la paleta del lugar**.
Las chispas genéricas (`UI.sparks`) se retiran: cada evento tiene su firma.

### 4.1 QUEMAR UNA CARTA — momento estrella (≈ 900 ms totales, interactivo a los 350 ms)
| t (ms) | Capa | Qué ocurre |
|---|---|---|
| 0–80 | Carta (UI ×2) | La carta se eleva 6 px y su borde se calienta: el marco pasa por 3 pasos (color tipo → `ffb43a` → `fff4c8`) en 3 f. |
| 0–80 | Sala | **Inspiración**: la llama de los braseros se inclina 2 px hacia el horno; el horno abre la boca (fotograma «tragar»). |
| 80–340 | Carta | Vuelo por detrás de la heroína en arco (existente, 260 ms). Estela de **4 copos de papel ardiendo** (2×2 px, FIRE 5→3) soltados cada 60 ms. |
| 340 | Horno | **Fotograma de impacto (2 f, 66 ms)**: boca del horno a blanco `fff4c8`, contorno de la carta en silueta blanca 1 f dentro de la boca. Hitstop de 60 ms global. Sacudida 4 px (8 en caliente). |
| 340–700 | Horno | **Columna de fuego** 16×40 px de arte, 8 f a 45 ms, que sale de la chimenea del horno. Color de la columna = tipo de carta (ataque: rojo `c2321e`, habilidad: `8ab4d0` en el corazón, poder: dorado, combustible: naranja máximo). |
| 340–900 | Sala | El conducto de cobre se ilumina **brida a brida** hasta el muro (6 pasos, 60 ms cada uno) → la rejilla del suelo destella → el tiro escupe 12 chispas. *La carta alimenta el edificio entero: el lazo central del juego, visible.* |
| 380–900 | UI | Las Ascuas salen de la chimenea como **monedas-brasa de 3×3** (no confeti) en una curva hacia el contador; el número aparece al llegar la primera. |
| Quemar en caliente | + | Columna doble, sacudida 8 px, la boca queda en blanco 4 f, aparece 1 f la silueta del Espíritu de la Forja en el humo. |
| Maestría sube | + | La columna de fuego deja **una runa de 8×8** que queda 600 ms flotando sobre el horno con el número de nivel. |

### 4.2 Golpes
| Efecto | Fotogramas | Colores | Tiempo |
|---|---|---|---|
| Golpe de martillo (normal) | Marca de impacto en el objetivo: 3 f (estrella de 4 puntas 9 px → aro 13 px → 4 esquirlas) | `fff4c8` → `ffb43a` → color del bioma | 33/50/66 ms, sincronizado con el `strike` existente |
| Golpe fuerte (≥ 20) | 5 f, aro de 21 px + líneas de velocidad horizontales 1 f | + `c2321e` en las esquirlas | + hitstop 120 ms existente |
| Golpe a TODOS (Barrido) | arco horizontal de 4 f que barre de izquierda a derecha por encima de los enemigos | rampa de fuego | 180 ms |
| Golpe recibido (heroína) | astillas rojas `ff5a4a` 3 f + **la bufanda** sale volando 2 px | | |
| Bloqueado | aro hexagonal azul 3 f, `8ab4d0`→`4a6a8a`, chispa blanca 1 f en el punto de contacto, sin daño | | 100 ms |

### 4.3 Estados (persistentes sobre el sprite, presupuesto: 1 animación de estado por luchador)
| Estado | VFX | Fotogramas |
|---|---|---|
| **Quemadura** | Llamitas de 3×5 px en el contorno superior del sprite; nº = min(3, ceil(valor/3)); al tick de daño: la llama salta al número | 4 f a 120 ms |
| **Bloqueo** | Contorno de 1 px `8ab4d0` en el borde que mira al rival + escudo 7×8 que gira 4 f al ganar Bloqueo; se rompe en 5 esquirlas al perderlo | 4 f / 5 f |
| **Fuerza** | Venas de brasa (`3` de la base) pulsan 1 paso más; al ganar: 2 anillos ascendentes de 1 px | 2 f bucle / 6 f |
| **Débil / Vulnerable** | Gotas violeta `9a5ad0` que caen del sprite (Débil) / grietas blancas 1 px sobre el sprite (Vulnerable) | 6 f / estático + destello |
| **Ahogo (choke)** | Humo negro sale de **la boca del horno** del jugador | 6 f |
| **Espinas / Regeneración** | púas 1 px en el contorno / motas verdes `6ac46a` subiendo | 2 f / 8 f |

### 4.4 Muerte de monstruo
Destello amarillo (existente) → disolución pixelada (existente, 700 ms) → **las brasas del monstruo (los píxeles `3`/`a` de su
base) se desprenden y suben por el tiro**, 1 px cada una, 1,2 s → «+Ascuas» sólo cuando la primera brasa sale de pantalla. Se
eliminan las 60 chispas. Una sola cifra por muerte, nunca «9999!» + «+32» + «¡Recuperadas!» a la vez (encolar textos 150 ms).

### 4.5 Invocaciones
El suelo se agrieta 3 f bajo el punto de aparición (`1a0f12` + rampa del bioma), el invocado emerge con la disolución inversa
(existente) **de abajo arriba**, polvo de ceniza 4 f en los lados. 400 ms.

### 4.6 Entrada de jefe (2,2 s, saltable)
1. Los braseros se apagan uno a uno (2 × 150 ms) → sólo queda la luz del tiro.
2. El tiro se ilumina de abajo arriba con el color del jefe; silueta del jefe en L1 (sólo contorno `k` + ojos) 600 ms.
3. El jefe salta/sale del vano al plano L2 (6 f), aterriza: sacudida 16 px, polvo del techo, la barandilla se dobla (sprite
   alternativo del parapeto que se queda el resto del combate).
4. Braseros se reencienden en el color del jefe (Carbonero: brasa roja; Hidra: verde escoria; Rey Escarcha: llama azul fría).
5. Rótulo del nombre (existente).

---

## 5. Técnica

### 5.1 Fondos: por capas, generados por código y horneados a imagen en la carga
- **Sí a capas horneadas**, no a PNG versionados. El proyecto es «todo el arte como datos versionables»; mantengo esa regla:
  cada capa se genera en `Art` al entrar en el acto (≈ 0,3–0,6 s por fondo en GDScript; la prueba hace 16 composiciones completas +
  4 variantes en 10 s) y se cachea como `ImageTexture`. Si el tiempo de carga molesta: generar en un hilo durante la transición, o
  hornear a `user://cache/*.png` con hash de la versión.
- **Modelo de datos (el aporte técnico clave, probado):** cada píxel guarda `(material, valor)`, y opcionalmente un punto de
  muestreo. La iluminación **suma pasos enteros en la rampa del material** (11 tonos por material con desplazamiento de tono:
  sombras a violeta, luces a naranja) en lugar de mezclar colores. Consecuencias:
  1. paleta cerrada garantizada (la prueba usa 9 rampas, ~90 colores, y el GIF entra en 256 sin cuantizar);
  2. **luz ladrillo a ladrillo**: la luz se evalúa en el centro de cada pieza, así que el degradado cae en saltos de pieza (lo que
     hace un pixel artist a mano), sin tramado ni anillos perfectos;
  3. **juntas rehundidas**: reciben un paso menos → la textura se revela con la luz y desaparece en la sombra (mata el «ruido de
     ladrillo uniforme» actual);
  4. la luz fría usa una rampa propia (COLD), por lo que frío y cálido no se mezclan en marrón;
  5. el estado del juego cambia luces → **re-horneo barato** (sólo L2; en la prueba se rehornea por fotograma para el crisol).
- **Escala:** 320×180 + márgenes de parallax (2/4 px). Nada de fondos a mayor resolución.

### 5.2 Luces 2D
- **No a `PointLight2D`** (gl_compatibility, coste por luz, y su atenuación continua rompe el pixel art). Las luces del mundo son
  **horneadas en 2–3 variantes de radio** (parpadeo = cambiar de variante), y las luces móviles (crisol, columna de fuego del horno,
  golpes) se resuelven con **sprites de luz escalonada** de 3–4 bandas en modo aditivo con alfa fija por banda (ya permitido por la
  biblia como «halos», pero con bandas duras, nunca degradado). Sustituye a `UI.halo_texture()` (GradientTexture2D radial suave).

### 5.3 Shaders (pocos, justificados)
| Shader | Uso | Regla |
|---|---|---|
| **Ondas de calor** | Boca del horno con Calor ≥ 8 y columna de quemar | desplazamiento UV **cuantizado a 1 px de arte** (×4), sólo filas pares, amplitud 1 px, 6 f |
| **Rampa por paso** (palette swap) | Parpadeo de luz global (PV bajos, entrada de jefe, oscurecer al ganar) | desplaza ±n pasos de la rampa con una LUT de paleta: no `modulate` |
| Disolución | Existente: mantener | ya está en la rejilla |
| ~~Viñeta continua~~ | Retirar `VIGNETTE_SHADER` de PV bajos | se sustituye por §3.4 |
| ~~Bloom/CRT~~ | No | de acuerdo con la biblia |

### 5.4 Partículas pixel-perfect
`CPUParticles2D` con escala 4–8 px a posiciones flotantes produce cuadrados desalineados con la rejilla (hoy en antorchas,
polvo, chispas). Propuesta: un único nodo `ArtParticles` (Node2D con `_draw`) que simula en coordenadas de **arte** (floats) y dibuja
`draw_rect` en `floor(pos)·4` con color de rampa por edad (escalonado). Pool fijo de 256 partículas por pantalla, sin asignaciones.
Las chispas del tiro, motas, pavesas, nieve y monedas-brasa usan esto. Es menos código que configurar 6 emisores.

### 5.5 Frente a la biblia de arte
- **Respeto:** ×4 mundo / ×2 UI; nada de escala ni rotación sobre sprites del mundo (la cadena de la prueba se *redibuja* por
  fotograma, no se gira); sin tramado de relleno (la prueba no tiene ni un píxel tramado); paleta cerrada (la extiendo a rampas
  de material de 11 pasos, todas derivadas de `PAL`).
- **Rebato:**
  1. «Halos aditivos y luces (suaves)» → **escalonados**. Lo suave es lo que hoy delata al prototipo.
  2. «Fondo en 15–45 % de luminancia» → **5–40 %** y con estructura: oscuro arriba (hollín/HUD), oscuro abajo (mano), las luces
     son islas. En la prueba, los personajes recuperan el contraste que perdían (el Limo desaparecía contra el muro gris).
  3. «2–3 cosas vivas por pantalla» → **presupuesto por píxeles en movimiento** (§3.3): 4 fuentes pequeñas y causales molestan
     menos que 2 emisores grandes y arbitrarios.
  4. Composición por acto con *otra arquitectura*, no con otra textura.

---

## 6. Prueba de concepto

**Script:** `tests/_review_art/v04/mundo_vivo/poc_mundo_vivo.gd` (escena `poc_mundo_vivo.tscn`; ejecutar con ventana:
`Godot --path . res://tests/_review_art/v04/mundo_vivo/poc_mundo_vivo.tscn`, ~10 s; restaurar `project.godot` después).
Sin assets externos: todo por código, usando `Art` sólo para los luchadores de contexto.

**Salidas (`tests/_review_art/v04/mundo_vivo/out/`):**
| Archivo | Qué demuestra |
|---|---|
| `a1_fondo_x4.png` (1280×720) | Acto 1 «Salas de Fogones» completo: 4 capas, luz por pasos, tiro con luz ascendente, ventana a la ciudad helada. |
| `a1_contexto_x4.png` | Lo mismo con horno, heroína y 3 enemigos reales del juego, y las franjas de HUD/mano atenuadas: **legibilidad**. |
| `a1_capas_x2.png` | Las capas L0 (exterior), L1 (tiro), L2 (muro+suelo) y L4 (primer plano) por separado sobre damero. |
| `a1_antes_despues_x2.png` | Fondo actual (izq.) vs propuesta (der.), mismos luchadores. *Nota justa: en el «antes» faltan las llamas en partículas de ejecución.* |
| `anim_brasero_8f_x5.png` | Tira de 8 f (100 ms): llama (base en gota + 3 lenguas que suben y se separan), humo en 4 bocanadas que se erosionan, pavesas, luz que parpadea sobre el ladrillo (3 radios). |
| `anim_crisol_8f_x5.png` | Cadena con crisol: péndulo **redibujado** (sin rotar), 8 de sus 16 posiciones, metal fundido que pulsa y su **luz móvil** sobre el muro. |
| `a1_hoja_8f_x1.png` | 8 fotogramas de la escena entera viva (hoja equivalente a un GIF). |
| `a1_vivo_x2.gif` | **GIF animado real** (640×360, 16 f, 110 ms, bucle) escrito por un codificador GIF89a propio en GDScript: braseros, humo, chispas del tiro, nieve tras el cristal, crisol, motas, respiración de luchadores, horno. |
| `a1_variaciones_x2.png` | El estado del juego en el escenario: piso 1 con Forja fría · piso 9 (cascotes, grietas) · Forja al máximo (rejilla amarilla, tiro encendido, más ventanas lejanas encendidas) · ciclo II (vetas de brasa en las juntas). |

**Qué demuestra:** (1) que un fondo de calidad profesional *por código* es viable en este proyecto sin PNGs; (2) que el modelo
material+pasos de rampa resuelve la luz sin degradados ni tramado; (3) que el acto 1 puede ser un **lugar** con historia (la
herrería conectada al horno, el tiro de la Forja, la ciudad helada fuera) en vez de un muro con color; (4) que el ambiente puede
leer el estado del juego; (5) que el «mundo vivo» cabe en pocas fuentes causales pixel-perfect.

**Limitaciones honestas que quedan para producción:** el humo aún es tímido (aumentar 1 paso de valor y 20 % de radio); los
nervios del tiro (L1) son algo claros y compiten con la gran cadena; las saeteras lejanas se leen como marcas rojas a ×1 (pasar a
2×3 con dintel iluminado); la luz por losa del suelo deja bandas diagonales a ×4 en las losas grandes del primer término (oculto
por la mano, pero corregible muestreando por media losa); las vetas del ciclo II forman escalones demasiado regulares.

---

## 7. Conexión con las demás áreas
- **Dirección de arte:** propongo que las *rampas de material* de 11 pasos sean la paleta oficial de mundo (derivada de `PAL`);
  la UI sigue con su paleta. Pido acordar la estructura de valores 5–40 % del fondo.
- **Personajes y criaturas:** los monstruos ya reciben luz lateral de fuego (32 %); con braseros reales propongo que reciban **la
  luz del acto** en 2 pasos (cálida por la izquierda + fría de la ventana/cielo por la derecha en el acto 3) y que sus píxeles de
  brasa alimenten la muerte (§4.4). La heroína necesita 2 sprites de reacción ambiental: vaho (acto 3) y bufanda al viento.
- **Artista técnico:** necesito `ArtParticles` (§5.4), el sistema de capas `WorldStage` (L0–L4 + slots de sprites vivos +
  luces horneadas por variante) y el shader de rampa por paso. Hornear en hilo durante la transición de piso.
- **Cartas/UI:** la carta quemada se integra con el mundo (§4.1: el marco se calienta, copos de papel, columna de fuego del color
  del tipo). Las cartas de la tienda pasan a estar clavadas en un tablón del mundo; el mapa deja de ser cajas. Pido que el HUD
  superior deje libres y=13…20 de arte (las vigas y capiteles son lo que da escala al lugar).

## 8. Riesgos y lo que descarto
| Riesgo | Mitigación |
|---|---|
| Ruido visual que tape cartas/intenciones | Presupuesto §3.3; prohibido animar en la franja de intenciones; todo opcional se pausa en el turno enemigo. |
| Tiempo de generación al cargar | Generar en hilo durante la transición (650 ms disponibles) o caché en disco. |
| 3 actos × 10 pisos × ciclos = explosión de contenido | Arquitectura fija por acto + **módulos** intercambiables (6–8 por acto: ventana, herramientero, jaula, crisol…) elegidos por semilla del piso; variación por piso = deterioro paramétrico, no dibujos nuevos. |
| Accesibilidad (parpadeo, movimiento) | Opción «Ambiente reducido»: congela la luz, quita chispas y sacudidas de escenario; 0 destellos > 3 Hz. |

**Descarto:** `PointLight2D`/normal maps sobre pixel art; bloom; parallax por scroll continuo (no hay cámara que se mueva:
sólo ratón ±1/−2 y transiciones); fondos distintos para *cada* piso (no escala; módulos sí); animar el suelo; nubes/niebla con alfa
suave; criaturas de fondo durante el turno enemigo; mantener `UI.sparks` como respuesta genérica a todo.

## 9. Estimación por paquetes independientes
Jornadas de 1 artista-técnico que domine GDScript (el arte es código). Cada paquete se puede entregar y probar solo.

| # | Paquete | Contenido | Depende de | Jornadas |
|---|---|---|---|---|
| P1 | **Motor de escenario** | `WorldStage` (capas L0–L4, márgenes, parallax por ratón cuantizado), modelo material+pasos de rampa, luces horneadas en variantes, re-horneo de L2 en hilo; migrar la prueba a `Art` | — | 4 |
| P2 | **ArtParticles** | Partículas en rejilla de arte, pool 256, rampas por edad; sustituir `UI.dust`, `fire_emitter`, `sparks` | — | 2 |
| P3 | **Acto 1 completo** | Composición de la prueba + 6 módulos + deterioro por piso + sala del jefe (Boca de Fogones) + vida (braseros, humo, crisol, tiro, hollín, vapor, rata) | P1, P2 | 6 |
| P4 | **Acto 2 Fundición** | Arquitectura nueva, canales/crisoles, rejillas de ventilación, escoria viva, 6 módulos, vida | P1, P2 | 7 |
| P5 | **Acto 3 Corona Fría** | Arcos abiertos al cielo (L0 grande), tiro taponado, nieve 3 capas, cuervos, vaho, 6 módulos | P1, P2 | 7 |
| P6 | **Lugares de servicio** | Forja (tiro + generadores físicos), Antesala (cadenas de pacto), Hoguera, Tienda (carromato), mapa (rellano + puertas reales + sección de la Torre), viñetas de evento a pantalla | P1 | 9 |
| P7 | **Estado → ambiente** | Producción, Calor, Resplandor, Brasas Vivas, ciclo, tipo de puerta, PV bajos (§3.4) | P1, P3 | 3 |
| P8 | **VFX quemar carta** | §4.1 completo (inspiración, copos, impacto, columna por tipo, conducto, monedas-brasa, caliente, maestría) | P2 | 3 |
| P9 | **VFX combate** | Marcas de impacto, bloqueo, estados persistentes, muerte con brasas al tiro, invocación, cola de textos | P2 | 5 |
| P10 | **Entradas de jefe** | 6 jefes × secuencia §4.6 + parapeto roto | P3–P5 | 4 |
| P11 | **Transiciones** | Ascenso por capas, caída por el tiro, cortina de humo, tarjetas de acto | P1 | 3 |
| P12 | **Pulido y accesibilidad** | Presupuestos medidos, «Ambiente reducido», revisión de capturas de todas las pantallas | todos | 2 |
| | **Total** | | | **55 jornadas** (≈ 11 semanas de 1 persona; ≈ 6 con 2 en paralelo: P3/P8/P9 ‖ P4/P5/P6) |

**Orden recomendado:** P1 → P2 → P8 (el momento estrella, máximo impacto por jornada) → P3 → P7 → P9 → P11 → P4 → P5 → P6 → P10 → P12.
