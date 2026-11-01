# Debate de arte v0.4

Participantes: dirección del proyecto (yo), director de arte (DA), artista técnico (TEC), personajes y criaturas (PER),
cartas e interfaz (UI), mundo vivo / entornos / VFX (MV). Propuestas en `docs/reviews/v04/<rol>/propuesta.md`.

## Ronda 0 — consensos sin discusión
- Fuera `StyleBoxFlat`, halos radiales suaves, Light2D multiplicativo, bloom/CRT, IA generativa, imágenes externas, recoloreados
  para crear contenido, escalado/rotación de sprites en reposo, tramado de relleno.
- Luz = **pasos enteros en rampas de material** con desplazamiento de tono (los cinco, con matices de implementación).
- Personajes y criaturas: **piezas con volumen + sellos/calcas a mano** (cara, manos, remaches) + pasada a mano final.
- Cada pantalla de servicio es un **lugar** del mismo mundo (taller, Antesala, mapa-Torre en corte, tienda con mercader, eventos).
- El estado del juego (calor, generadores, ciclo, Resplandor, Maestría, PV, Quemas, Energía) tiene **firma visual** en el mundo.
- Quemar una carta es el **momento estrella** y recorre el edificio entero.
- Partículas en la rejilla de arte (`ArtParticles`), no `CPUParticles2D` sueltas.

## Ronda 1 — conflictos y posición inicial de dirección

| # | Conflicto | Posiciones | Mi posición inicial |
|---|---|---|---|
| C1 | Resolución del mundo | DA/TEC/PER/UI: **640×360 ×2** rejilla única. MV: 320×180 ×4 | 640×360. MV debe decir qué pierde su sistema al doblar y cómo se mantiene el carácter "ladrillo a ladrillo" |
| C2 | Luz: ¿horneada o en tiempo real? | TEC: shader de paleta en tiempo real con G-buffer (índice de rampa + normal) y 2–4 luces. DA: horneada en 4 niveles de calor, sólo shader de ±1 tono. MV: horneada por pieza + sprites de luz escalonada aditivos + shader de paso de rampa | **Un solo modelo de datos** (material + paso) para todo. Pregunto: ¿puede un shader único hacer (a) luz horneada por pieza como base, (b) desplazamientos globales y locales de pasos en tiempo real (parpadeo, pico de quemar, PV bajos, calor) leyendo una máscara de luz de baja resolución? Si pasa en `gl_compatibility`, ése es el estándar; si no, horneado en niveles |
| C3 | Tamaño de carta | UI: 80×112, ventana 68×46. DA: 75×105, ventana 65×38 | 80×112 (más escena). DA decide |
| C4 | Texto del cuerpo | UI: "Pavesa" 6×9 a ×1 de pantalla. DA: rejilla única ×2 | Acepto ×1 **sólo para texto** como única excepción, si DA no tiene alternativa legible a ×2 |
| C5 | Ilustraciones | UI: 93 escenas únicas por gramática. DA: 30 A + 45 B (plantilla por verbo) + 15 C | **Ninguna carta comparte ilustración.** Niveles de esfuerzo sí (A con más mano), pero composición única en las 93. El cliente pidió explícitamente cartas e ilustraciones |
| C6 | Motor de piezas | Tres prototipos distintos: rig de TEC (huesos, G-buffer, animación), partes de DA (facetas Voronoi), rig de PER (materiales + sellos) | **Uno**: el de TEC como base, con las 7 condiciones de PER y la regla de jerarquía de facetas de DA. Necesito que TEC y PER firmen la API |
| C7 | Hornear | TEC: PNG versionados + manifiesto + test de frescura. DA: hornear al compilar. MV: generar al cargar y cachear en `user://` | PNG versionados (revisables, arranque rápido); fuentes en código; test de frescura |
| C8 | Jefes | PER: 180–250 px, 4–7 partes. DA: 120–170 px | DA decide con el lienzo de 360 de alto y la franja de intenciones |
| C9 | Alcance | ~113 + 84 + 55 jornadas + 250 h | Hacemos TODO, pero con corte vertical primero: combate del acto 1 a nivel 9 → aprobación → resto |

## Ronda 1 — respuestas
(se completa con las respuestas de cada experto)
Respuestas completas en `docs/reviews/v04/<rol>/ronda1.md`. Pruebas nuevas:
- TEC: shader de paleta en `gl_compatibility`, real (`tests/_review_art/v04/tecnico/shader_test/`). Compila; coste no medible (2,13 vs 2,15 ms). Sombreado por anclas de pieza: cada ladrillo sube/baja entero.
- MV: fondo del acto 1 rehecho a 640 nativos (`mundo_vivo/out/a1_640_crop.png`). Acepta 640×360.
- UI: mano de 5 y 10 cartas 80×112 sobre el keyframe (`cartas_ui/out/c3_hand_*.png`); prueba de texto (`c4_text_test.png`): una fuente ×2 de 3×5 cabe ~55 caracteres por carta frente a los 87 de la carta más larga.
- PER: 13 funciones que exige al motor; disposición de pantalla en px.
- DA: arbitraje de C1–C9 con dictamen por colega.

## Resolución (cerrada por dirección)

| # | Decisión | Por qué |
|---|---|---|
| C1 | **Mundo 640×360 ×2, rejilla única con la interfaz.** | Unanimidad tras la prueba de MV a 640. 427×240 descartada por aritmética. |
| C2 | **Un solo shader `palette_lit`**: textura de índice (material, paso horneado por pieza, banderas, ancla de pieza) + LUT de rampas cálida/fría + desplazamientos de paso en tiempo real (calor global, PV bajos, pico de quemar, 2–4 luces móviles) evaluados en el **centro de la pieza**. Niveles horneados de DA = sólo respaldo. | Probado en `gl_compatibility`, coste nulo, paleta cerrada garantizada. Une los tres modelos. |
| C3 | **Carta 80×112, ventana 68×46.** En reposo asoma 64 px; sube entera al pasar el ratón. | DA concede; UI demostró que la mano cabe. |
| C4 | **Pavesa 6×9 a ×1** sólo para cuerpo de carta y tooltips (única excepción a la rejilla). "Mini" 3×5 a ×2 para etiquetas pequeñas. Fragua (5×7) para títulos y cifras. | Las alternativas ×2 no caben (medido). |
| C5 | **93 composiciones únicas.** Niveles A (~30, sujeto propio + pasada a mano + 1 fotograma animado en Maestría 3), B (~58), C (5: estados y token). Nunca se repite fondo+encuadre+sujeto+posición; prueba de miniatura 34×23 por grimorio. | Petición explícita del cliente; UI cuantificó el sobrecoste (+25 h). |
| C6 | **Motor único: el rig de TEC** con la API de su `ronda1.md`; las 7 condiciones de PER como **errores de horneado**; las 13 funciones de PER (material como dato, máscaras de material, calcas sin cuantizar, profundidad animable, IK de 2 huesos, losas con bisel, accesorios por estado, emisivos animables, estela en media luna, jefes multiparte con fase, parches por fotograma, test de siluetas, modo ASCII < 32 px); límites de jerarquía de DA (≤ 3 planos de luz por masa > 12 px, faceta ≥ 24 px², ojos/manos/remaches siempre con sello). Facetas Voronoi de DA sólo para carbón, escoria y hielo. | |
| C7 | **PNG versionados** en `assets/baked/` + manifiesto con hash + tests de frescura y determinismo. El estado del juego va en el shader, nunca en rehorneos. Se permite componer la sala al cargar desde capas horneadas. | Revisable en PR, arranque rápido, QA ve lo mismo que el jugador. |
| C8 | **Jefes 150–200 px de cuerpo, ≤ 280 de ancho.** Sólo humo/corona/vapor entran en la banda de intención, < 30 % de valor. | Disposición de DA (abajo). PER cede de 250 a ~200. |
| C9 | **Corte vertical primero** (combate del acto 1 a nivel 9, revisado por DA), después el resto del contenido sin parar. | |

**Disposición de combate (lienzo de arte 640×360):** HUD 0–15 · banda de intención de jefe 22–44 · suelo y = 264 ·
cartas en reposo desde y = 296 · Forja x 8–112 · heroína x 128–196 (66 px de alto) · enemigos x 300–632 (1: centro 466;
2: 396/540; 3: 350/460/572) · intención normal 18 px sobre la cabeza.

**Heroína:** diseño de PER (fogón de cinto, gafas de forja, bufanda azul, delantal, fuelle) a **66 px** con moño, y las
enmiendas de DA: cara sellada a mano ≥ 10×10 px legible (ojo 1×2 con brillo, ceja de 3 px, nariz que rompe la silueta,
gafas 2 px más arriba); fuera el saco de carbón; el fuelle sólo asoma como 2 asas sobre el hombro; puntas del pelo y cara del
martillo siguen al **calor actual**; segundo reposo con el martillo al hombro.

**La Torre es el tiro de la Forja** (MV): galerías alrededor del tiro central; la Forja grande con chimenea de ladrillo del
keyframe de DA está en la base; el conducto de cobre de MV es la toma del fuelle. Las salas normales usan el módulo de
corredor de arcos de DA; élite y jefe abren al tiro (galería con parapeto de MV). **El mapa** (UI) es el corte de esa
chimenea: tiro en el eje, galerías anulares, escalera de caracol, Forja abajo, noche helada fuera. Arquitectura del mapa: MV;
maquetación, placas, tooltips y animación de subida: UI. Fuera el tramado en damero de las puertas y el magenta fuera de paleta.

Plan de producción: `docs/reviews/v04/PLAN.md`.
