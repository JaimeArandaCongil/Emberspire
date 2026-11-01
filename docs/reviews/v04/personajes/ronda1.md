# Ronda 1 — Personajes y criaturas (PER)

## C6 · Un solo motor: el de TEC, si añade lo que falta

**Gólem de TEC (`zoom_x8`, `attack_6f`)**
- Bien: esqueleto, z-buffer, AO, facetas en el espacio del hueso (no tiemblan) y 62 ms por fotograma.
- Mal: es un gólem de *roca*, no de Hollín. Un solo material, sin ladrillo, hollín ni horno.
- Mal: facetas del mismo peso en todas las piezas, así que se leen como camuflaje. Clústeres de 1–2 px con tonos casi iguales.
- Mal: la luz de borde naranja recorre casi todo el contorno (en el fotograma 2, también el derecho) y parece una pegatina.
- Mal: hocico de oso, ojo de 2×1 y cadera sin línea interior.
- Animación: los pies no se mueven en los 6 fotogramas (no hay traspaso de peso) y los fotogramas 4–6 son casi iguales. La estela es una banda de grosor constante, no una media luna, y tapa la cabeza.

**Gólem del DA:** la mejor jerarquía de facetas (planos grandes) y buenas grietas de magma. Pero las piedras flotan sin articulación y el valor se confunde con el muro (pizarra azul sobre ladrillo azul).

**Lo que debe añadir el motor de TEC** (además de mis 7 condiciones):
1. **Material de primera clase**, con texturas procedimentales sobre el escalón ya cuantizado (mortero sólo en luz media, mechones, pliegues, arañazos). Las facetas son una propiedad *del material*: carbón fuerte con especular frío, roca media, piel y ladrillo nada. Eso cumple la jerarquía del DA.
2. **Máscaras de cambio de material** por región y parámetro: hollín que sube, tizne según el Calor de Pacto, escarcha según los PV.
3. **Calcas con escalón forzado**: no se cuantizan, no generan línea interior y tienen **variantes por vista** (¾, perfil, espalda) según el ángulo de la cabeza.
4. **z animable por clave**: en la carga, el brazo pasa por detrás de la cabeza.
5. **IK de dos huesos**: pies plantados y mano fija al mango para agarrar a dos manos.
6. **Losas y polígonos con bisel ya**, no «en la siguiente fase»: martillo, puertas, placas. Sin bisel el martillo sale como un bloque blanco.
7. **Accesorios enchufables** a hueso según el estado del juego (Resonancias, mejoras, afijos).
8. **Emisivo animable** por calca: fogón de cinto, ojos, puerta del horno en la telegrafía.
9. **Estela** en media luna que se afila, colocable delante o detrás.
10. **Jefes multiparte**: un atlas por parte con anclajes, bucles desfasados y cambio de silueta en la fase 2.
11. **Parches por fotograma** (máximo 15 px).
12. **QA automático en cada horneado**: silueta en negro, miniatura a 32 px, recortes ×8 y prueba de siluetas distintas.
13. **Modo pequeño (menos de 32 px)**: la losa ASCII manda y el rig sólo anima.

Con eso firmo la API de TEC y migro mis rampas, sellos y poses a su formato.

## C8 · Jefes: 190–210 px visibles

Lienzo de 640×360:
- **Bandas verticales:**
  - recursos: y 0–22;
  - **suelo (pies): y 228**;
  - PV y nombre: y 230–239;
  - mano de cartas: y 240–360 (en hover suben a 228).
- **Lado izquierdo:**
  - Forja: x 8–112;
  - heroína (66 px): x 128–196, cabeza en y 162.
- **Enemigos** (x 300–632):
  - 1 enemigo: centro en 466;
  - 2 enemigos: 396 y 540;
  - 3 enemigos: 350, 460 y 572 (casillas de 110 px).
  - Intención 18 px sobre la cabeza: normal de 70 px → y 140; élite de 110 → y 100.
- **Jefe:**
  - cuerpo: x 330–630 × y 18–228, cabeza en el tercio izquierdo (y 40–90);
  - intención **al lado** de la cabeza (x ≈ 300, y ≈ 60);
  - barra de PV ancha en y 230–239;
  - invocaciones delante, en x 300–360.

**Argumento:** hay 206 px útiles entre la barra superior y el suelo. Un jefe de 120 px mide 1,8 veces la heroína, lo mismo que una élite (80–110), y se rompe la escala de clases (normal 28–70 · élite 80–110 · jefe 190+). 3 × 66 ≈ 200 px es la proporción de Slay the Spire.

**Cedo** el máximo de 250 px: la cabeza tiene que verse entera para leer la telegrafía. Por arriba sólo se sale lo secundario (humo, chimenea, corona, la cima del montículo).

## 3 · Heroína base: la mía, con tres aportaciones del DA

**La del DA**
- Bien: está integrada en la luz de la escena, el martillo al hombro le da una silueta muy reconocible y las **puntas del pelo arden según el Calor**.
- Mal: la sombra de la mandíbula se lee como **barba**.
- Mal: lleva tramado en damero en el martillo, que el consenso prohíbe.
- Mal: el delantal es una mancha de 2 tonos, la diadema blanca compite con la cara y las manos son masas.
- Mal: nada dice «mazo = combustible».

**La mía**
- Bien: el concepto se cuenta con accesorios (fogón de cinto, fuelle, saco, tenazas, gafas), los 6 materiales se separan y ya tiene 3 poses articuladas.
- Mal: las manos son masas y no hay mechones con forma.

**Base: la mía**, porque el concepto y las poses son lo caro de rehacer.

**Tomo del DA:**
1. Las puntas del pelo ligadas al Calor de la Forja.
2. Un segundo reposo con el martillo al hombro para la Antesala, la Hoguera y la victoria. En combate se queda bajo, para que la carga contraste.
3. La luz de escena del G-buffer de TEC, en lugar de mi luz fija.

**Corrijo en la mía:** 8 sellos de mano (uno por pose), 2–3 sellos de mechón, la mandíbula sin sombra inferior (para no repetir la barba) y la altura a 64 px, la del DA, para que la biblia tenga una sola cifra.
