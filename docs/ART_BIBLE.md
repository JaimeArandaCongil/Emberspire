# Biblia de Arte — EMBERSPIRE

## Objetivo visual
Pixel art cálido sobre oscuridad. **La luz es el recurso**: todo lo valioso brilla en naranja/amarillo; el peligro frío es azul.
Referentes: Dead Cells (rejilla limpia, impacto), Blasphemous (siluetas, presencia de jefes), Slay the Spire (lectura de cartas).

## Rejilla y escalas (REGLA DURA desde v0.3)
| Capa | Escala | Qué vive ahí |
|---|---|---|
| **Mundo** | **×4** (`UI.PX`) | Fondos 320×180, heroína, monstruos, horno, hoguera, partículas del mundo |
| **Interfaz** | **×2** (`UI.UI_PX`) o múltiplos (×4, ×6) | Cartas (marco **e** ilustración), iconos, paneles, logotipo, fuente pixel |

Prohibido:
1. **Escalas fraccionarias** sobre pixel art (×2.5, ×0.4…). Si algo debe ser más grande, se **redibuja** o se amplía con EPX en la rejilla de arte.
2. **`scale`/`rotation` continuos sobre sprites del mundo** (respiración por escala, temblor rotado). Respiración = 2 fotogramas
   (`crouch_image` quita 1 fila); golpes = fotogramas (`player_pose`, `monster_pose`).
3. Posiciones del mundo fuera de la rejilla: `FighterView._off` se ajusta a múltiplos de 4 px cada fotograma; la sacudida de
   pantalla (`main.shake`) también. Las cartas en reposo no rotan (abanico por desplazamiento en arco).
4. Excepciones aceptadas: halos aditivos y luces (suaves); cartas en **vuelo** (<300 ms: robar, jugar, quemar, descartar) pueden
   escalar/rotar.
5. Nada de tramado Bayer como relleno: sólo una transición por material y sólo en sprites ≥ 36 px de alto (nunca en el acto de hielo).

## Paleta cerrada (25 colores `PAL`) + rampas de bioma
| Char | Hex | Uso |
|---|---|---|
| `k` | `#1a0f12` | Contorno universal (1 px, nunca negro puro) |
| `d` `g` `l` | `#3d2b2e` `#5a4040` `#7a5a52` | Piedra, sombras cálidas |
| `r` `o` `y` `w` | `#c2321e` `#ff6a1a` `#ffb43a` `#ffe08a` | Rampa de fuego |
| `W` | `#f4e4c8` | Hueso / texto |
| `b` `c` | `#4a6a8a` `#8ab4d0` | Frío (bloqueo, acto 3, bufanda de la heroína) |
| `p` | `#9a5ad0` | Debuffs |
| `G` | `#6ac46a` | Curación |
| `s` `h` `n` | `#e0a080` `#6a3020` `#8a5030` | Piel, pelo/cuero oscuro, cuero |
| `m` `M` | `#9aa0a8` `#d0d4d8` | Metal |
| `R` `Y` | `#7a1a16` `#fff4c8` | Sangre/pelo en sombra, brillo máximo |
| `B` `P` `e` `S` | `#2a3a5a` `#d0a8ff` `#2e6a3a` `#b07050` | Azul profundo, magia, escoria verde, piel en sombra |

Rampas de monstruo por bioma (`BIOMES`: `hi light mid dark deep`) con **desplazamiento de tono**: sombras hacia violeta/azul,
luces hacia amarillo. Estructura de valores: **fondo en 15–45 % de luminancia y bajo contraste; personajes de 10 a 90 %**.
Los monstruos reciben **luz de fuego lateral** (`#ff8a3a`, 32 %) en su borde izquierdo: el horno y la heroína están ahí.

## Piezas
| Pieza | Resolución | Escala | Técnica |
|---|---|---|---|
| Iconos (≈95) | 12×12 | ×2 (UI) | ASCII a mano, contorno `k`, 3–4 tonos. `icon_big()` = EPX 24×24 para ilustraciones/paneles |
| Heroína | 24×36 cuerpo + 10×20 brazo | ×4 | 3/4 a la derecha, 3,6 cabezas. Poses compuestas en lienzo 52×48: el brazo se gira con RotSprite simplificado (EPX ×4 → giro → muestreo) **al generar**, nunca en pantalla |
| Monstruos normales | 12–26 px | ×4 | `BASES` a mano mirando a la izquierda (`X` sombreado auto, `1–4` tonos forzados, `k` líneas internas, `3` pliegues que pueden brillar, `a` acento, `E` ojo ≥ 2×2) o `SHAPES` simétricas para criaturas frontales |
| Élites | base ×2 | ×4 | Misma base ampliada con EPX **antes** de sombrear (`forma@2`) |
| Jefes | 30–36 a media resolución → 60–72 | ×4 | Base a mano + EPX sobre la rejilla de caracteres + sombreado a resolución final |
| Marco de carta | 75×105 | ×2 | Ventana con **forma por tipo** (ataque: hoja achaflanada; habilidad: rectángulo remachado; poder: óvalo con rayos; combustible: arco con rejilla; estado: rectángulo), cuerpo de **pergamino** con tinta oscura |
| Ilustración de carta | 60×30 | ×2 | Fondo en bandas por tipo, efecto por tipo, icono EPX 24×24 con sombra, máscara de la ventana |
| Forja | 64×56 (combate 36×34) | ×4 | Cúpula de ladrillo radial, arco de dovelas, brasas en 4 fotogramas, llamas según calor, yunque |
| Hoguera | 32×24 | ×4 | 4 fotogramas de llama procedural, troncos cruzados, piedras |
| Fondos | 320×180 + capa cercana 336×180 | ×4 | Composición por acto (ladrillo con hollín y arco-horno / roca con goteos de escoria y jaulas / bloques helados con carámbanos, luna y nieve). Luz en anillos sin tramado. Suelo con punto de fuga sin línea central. Primer plano con parallax de 0–2 px de arte |
| Viñeta de evento | 96×48 | ×2 o ×4 | `event_art(id)`: fondo en bandas, cono de luz, pedestal, protagonista EPX, velas |
| Puerta | 28×36 | ×4 | `door_art(kind, biome)`: arco de dovelas, resplandor del destino, icono |

## Tipografía
- **Fuente pixel** (`scripts/ui/pixel_font.gd`): 5×7 proporcional generada en runtime, con acentos españoles y contorno horneado.
  Sólo a escala entera: `UI.plabel(texto, escala)` o `PixelFont.px_size(escala)`. `UI.label()` la usa automáticamente desde 20 px.
- Uso: títulos, cifras (daño, PV, coste, energía, intención, contadores), botones cortos, nombres de carta (si caben en 114 px).
- **Fuente lisa** (por defecto) para cuerpos largos: texto de carta (13→11 px, tinta `#2a1418` sobre pergamino, sin contorno), tooltips,
  descripciones de la Forja y eventos.

## Animación (tiempos en ms)
| Acción | Secuencia |
|---|---|
| Martillazo | carga `windup` 140 (−2 px arte) → pausa 40 → `smear` 33 (estela de 4 px) → `strike` 90 (+6 px) → `recover` 120 → reposo, vuelta con `TRANS_BACK` 220 |
| Golpe recibido | destello blanco 33 → color del bioma 100; empuje direccional 3–5 px de arte en 50, vuelta 150 con rebote; pose `hurt`/`crouch` |
| Hitstop | 50 (daño < 10) · 80 (10–30) · 120 (> 30) |
| Embestida enemiga | `crouch` 160 (−4 px) → `stretch` 60 (+12 px) → pausa 60 → vuelta 240 |
| Gesto (sin ataque) | `crouch` 100 → `stretch` 120 (−1 px) |
| Respiración | 2 fotogramas cada 550–800 ms (fase aleatoria por luchador) |
| Muerte | destello → `crouch` → disolución pixelada 700 (rejilla del arte) → hundimiento 2 px |
| Quemar | la carta vuela por **detrás** de la heroína (260) y arde al entrar en la boca (350); el horno se aplasta 1 px y su boca sube al máximo 300 |
| Sacudida de pantalla | direccional, caída exponencial ~180, cuantizada a 4 px, máx. 24 px |
| Números | fuente pixel, "pop" de escala entera ×(s+1) → ×s en 60, suben 70 px en 800 |

## Qué NO hacer
- Escalar sprites para "darles presencia"; añadir tramado de relleno; shaders de bloom/CRT antes de arreglar valores.
- Recolorear para crear actos, tipos de carta o jefes nuevos (sólo para variantes de ciclo).
- Animar todo a la vez: 2–3 cosas vivas por pantalla.
- Mezclar imágenes externas, ilustraciones de otra resolución o fuentes vectoriales nuevas.
