# Ronda 1 · Cartas e interfaz (UI)

Pruebas: `tests/_review_art/v04/cartas_ui/debate_gen.gd` genera `out/c3_hand_5.png`, `out/c3_hand_10.png` y
`out/c4_text_test.png` (+ `_zoom`). Las manos van montadas sobre `director/keyframe_hot_1280.png`.

Acepto C1 (640×360 ×2): la carta ya vivía a ×2 y el mapa se redibuja a la nueva rejilla.

## C3 · Tamaño: mantengo 80×112; C3 y C4 son una sola decisión

Medido sobre el keyframe, la mano dispone de 970 px de ancho.
- **5 cartas** de 160 px caben sin solaparse.
- **10 cartas** caben con un paso de 90 px; de cada una se ven el nombre y media ilustración.

En reposo la mano ocupa 126 px de alto (unos 120 en el keyframe). En hover la carta sube hasta y = 492 (la del director,
hasta y = 485). **La ocupación cambia 6–14 px.**

La ventana sí cambia: 68×46 frente a 65×38, un **27 % más de área**, casi toda en altura. Esas 8 filas permiten suelo +
sujeto + cielo en vez de un objeto recortado. Pero salen del pergamino: si el cuerpo fuera a ×2, el pergamino crecería y
la ventana bajaría de 38. Por eso **ventana grande ⇔ texto a ×1**.

Concesión: acepto 75×105 si la ventana queda en 67×44, pero sólo con Pavesa ×1.

## C4 · Texto: prueba honesta

Las cartas más largas de `card_db.gd`, medidas con un script sobre las 93: Tormenta de Cisco (87 caracteres) y
Transmutar (78). Eco del Reliquario (59) va de control.

Opciones:
- **A · Pavesa 6×9 a ×1.**
- **B · la mejor alternativa a ×2 que he podido diseñar:** "Mini" 3×5 con minúsculas (x-altura 4, acento y descendente
  propios), sobre la carta de 80×112.
- **C · Mini ×2 sobre el pergamino del director** (59×35 útiles).

| Carta | A | B | C |
|---|---|---|---|
| Tormenta de Cisco | 5 líneas, cabe | 7, **no cabe** | 7, **no cabe** |
| Transmutar | 4 líneas, cabe | 6, **no cabe** | 7, **no cabe** |
| Eco del Reliquario | 3, cabe | 4, justo | 4, justo |

Juicio:
- **La Mini ×2 se lee bien.** Su mayúscula de 10 px es mayor que la de Pavesa (9 px), y en textos cortos queda más
  "pura" porque su trazo es igual de grueso que el del mundo. **No es ilegible, es insuficiente.**
- Capacidad: a ×2 caben unos 15 caracteres por línea y 4 líneas (~55–60 caracteres). Pavesa mete unos 21 × 5 (~100).
- **10 cartas pasan de 60 caracteres**, y eso antes de sumar la línea de Temple. A 3 px tampoco cabe la negrita de los
  números.
- Lo que diferencia a Pavesa no es el tamaño, sino el trazo de 1 px. Sobre pergamino se lee como tinta impresa en un
  objeto. En `c3_hand_5.png`, la carta en hover junto al mundo no desentona.

**Posición:**
- Cuerpo de carta y tooltips en Pavesa ×1: es la **única** excepción a la rejilla ×2.
- Nombres, cifras, botones y HUD, a ×2.
- La Mini ×2 se adopta para etiquetas: cinta de tipo, intenciones y pilas.

## C5 · 93 composiciones únicas, con niveles de esfuerzo

Acepto los niveles de esfuerzo del director, pero no plantillas que se lean como repetidas. El cliente percibe
repetición cuando ve la misma silueta en el mismo sitio dentro de una mano, no cuando se reutiliza el decorado.

**Se comparte:** fondo (12), cámara del verbo, rampa de luz y sujeto base. Golpe y Tajo Ígneo comparten espada y no se
nota, porque cambian el ángulo, la víctima, la luz y el efecto.

**Nunca se comparte** la combinación fondo + encuadre + sujeto + posición.

Reglas verificables:
1. Dentro de un grimorio, dos cartas no comparten a la vez fondo y encuadre.
2. Se generan 20 manos aleatorias de 10 cartas a mitad de tamaño; si dos ilustraciones se confunden, una se rehace.
3. La carta mejorada es la misma ilustración con la capa de calor. Ahí compartir es correcto.

Niveles:
- **A, ~30 cartas** (iniciales, raras y poderes): pasada a mano y 1 fotograma vivo, unas 2 h por carta.
- **B, ~58 cartas:** gramática sin pasada a mano, unos 60 min por carta.
- **C, 5 cartas:** sólo existen 4 estados y 1 ficha; se resuelven con la plantilla "objeto en la oscuridad".

Total: unas 120 h, frente a ~95 h. **No repetir ninguna cuesta unas 25 h**, y el cliente pidió las ilustraciones
expresamente.

## Mapa ↔ Torre-chimenea (MV)

Mi corte es la sección de la chimenea de MV:
- **Centro: el tiro.** Lleva la cadena y el crisol, y sus chispas suben más cuanto más produce la Forja. Por cada piso
  récord se enciende un punto de luz en el muro del tiro: ésos son los Braseros.
- **A los lados: la galería anular cortada.** Las puertas están en su muro exterior, repartidas a izquierda y derecha,
  con placa y la luz de su tipo.
- **Escalera de caracol** alrededor del tiro: en la sección cambia de lado en cada piso, la heroína sube por ella y la
  cámara sube un piso.
- **Abajo** asoma la bóveda de la Forja; **arriba**, niebla y un tiro cada vez más frío.
- El **acto** cambia el muro de la galería y lo que sube por el tiro, según la propuesta de MV.

Reparto:
- MV dibuja la arquitectura del tiro y de las galerías.
- Yo hago la composición, las placas, la interacción (hover, tooltip anclado, subida) y la interfaz.
