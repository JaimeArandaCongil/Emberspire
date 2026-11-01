# Ronda 1 · Director de arte: arbitraje

## Colegas: qué tomo y qué rechazo

**TEC** (`context_x4`)
- **Tomo:** su gólem, con 3 planos grandes por masa, magma sólo en las juntas y extremidades separadas del torso. Tomo también el shader de paleta y el SubViewport.
- **Rechazo:** el gris de la piedra (≈`#7a7068`, 65 % de luminancia) sobre un muro del 25 %: todo el cuerpo compite con los ojos. Hay que bajarlo 2 pasos y añadir contorno frío.

**PER** (`fogonera_sheet_x4`)
- **Tomo:** el diseño (moño, gafas, fuelle, martillo de 17×10) y sus 7 condiciones del rig.
- **Rechazo:**
  - **Cara:** unos 9×8 px de piel plana. Las gafas se comen la ceja y el ojo no se lee ni a ×4.
  - **Pantalón:** 3 tonos de gris sin pliegue.
  - **Cadera:** saco, fogón y fuelle hacen 4 bultos marrones; en negro, la cintura es una masa.

**UI** (`cards_zoom`, `map_mockup`)
- **Tomo:** sus cartas superan a las mías. Tienen profundidad y Pavesa es nítida. Tomo también la Torre en corte como mapa.
- **Rechazo:**
  - La espada de Golpe: una línea de 1 px en escalera 1:1, sin filo; lee "vector".
  - Las puertas del mapa con damero al 50 %: es tramado de relleno.
  - La élite en magenta `#e050a0`, fuera de la paleta. La élite se marca con un objeto, no con un tono.

**MV** (`a1_contexto_x4`)
- **Tomo:** el fondo que más parece un lugar. La Torre como tiro de chimenea, la rejilla del suelo que brilla con la producción, la luz por pieza.
- **Rechazo:**
  - La escala ×4: el ladrillo de 8×4 queda en mosaico.
  - Un 25 % inferior de pantalla negro y muerto.
  - Antorchas con más presencia que la Forja.

## Dictámenes

**C1. 640×360 ×2.** Cerrado.

**C2. Modelo de luz: el shader de TEC como motor.** Lleva dentro dos reglas de los otros modelos:
- De MV, la muestra **por pieza** en los fondos: la luz cae en saltos de sillar, no en anillos.
- Mía, la **rampa doble** (cálida y fría por material), escogida según domine una u otra, para que nunca salga marrón.

Datos por píxel: `material, paso, normal`. `floor()` y `texelFetch` caben en GLES3 (`gl_compatibility`). Si falla en la semana 1, se usa mi horneado en 4 niveles de calor más un desplazamiento de ±n pasos. Los sprites aditivos de MV, con bandas duras, sólo para luces móviles.

**C3. Tamaño de carta: 80×112 con ventana de 68×46.** Concedo: 65×38 no admite planos. En reposo asoman 64 px y la carta sube entera al pasar el ratón.

**C4. Texto del cuerpo: Pavesa a ×1.** A ×2, 3×5 deja unos 13 caracteres por línea: ilegible. Es la **única** excepción a la rejilla única, y sólo para reglas y tooltips; nombres, cifras e intenciones siguen a ×2.

**C5. Acepto 93 composiciones únicas.** La gramática de UI hace escenas distintas a 45–90 min cada una (unas 100 h): compartir composición ya no se justifica. Niveles de esfuerzo:
- **A (30): inicio, raras y poderes.** Sujeto a medida, pasada a mano y fotograma animado en Maestría 3.
- **B (48).** Sujeto o pose nuevos.
- **C (15): estados.** Sujetos del kit.

Reglas:
1. Ninguna pareja comparte `fondo + sujeto + encuadre`.
2. Miniatura a 34×23 distinguible de sus hermanas de familia.
3. 2 planos, luz propia, un gesto y 12 colores como máximo.

**C6. Motor de piezas: el rig de TEC,** con las 7 condiciones de PER y mi jerarquía:
- Ninguna masa de más de 12 px lleva más de 3 planos de luz.
- Ninguna faceta mide menos de 24 px².
- Ojos, manos y remaches, siempre con sello a mano.

Mis facetas Voronoi quedan sólo para carbón, escoria y hielo.

**C7. PNG versionados, manifiesto y prueba de frescura.** El estado del juego se resuelve en el shader; no se rehornea.

**C8. Jefes: 150–200 px de cuerpo y como mucho 280 px de ancho.**
- **De dónde sale el techo de 200:**
  - HUD hasta y = 15.
  - Banda fija de intenciones de jefe en y = 22–44.
  - Suelo en y = 264.
  - Cartas en reposo desde y = 296.
  - Quedan 220 px, menos 20 de aire para leer la intención.
- **Sólo pueden invadir la banda** el humo, la corona o el vapor: piezas no sólidas, por debajo del 30 % de valor y nunca encima de la intención.
- Los 240×320 de PER ocuparían el 89 % del alto: imposible.
- La fase 2 cambia la silueta dentro de ese mismo marco.

**C9. Alcance: corte vertical primero.** Acto 1, combate y un monstruo a nivel 9 (C2 + C6 + Fogonera + sala de MV + cartas de UI); después, la aprobación del cliente; después, el resto.

## Heroína: la de PER, con tres enmiendas
1. **Cara con sello a mano:** ojo de 1×2 con brillo, ceja de 3 px y nariz que rompe la silueta, en al menos 10×10 legibles. Las gafas suben 2 px.
2. **Fuera el saco de carbón.** Queda el fogón de cinto solo en la cadera, y del fuelle sólo 2 asas sobre el hombro.
3. **Luz:** cálida por la espalda y fría por el frente. **Calor:** las puntas del pelo arden y la cara del martillo está al rojo según el **calor actual**, no sólo en el ciclo IV.

**Altura:** 66 px más el moño. Aprobada.
