# Biblia de Arte — EMBERSPIRE

## Objetivo visual
Pixel art cálido sobre oscuridad. **La luz es el recurso**: todo lo valioso brilla en naranja/amarillo; el peligro frío es azul.

## Paleta cerrada (25 colores desde v0.2)
| Char | Hex | Uso |
|---|---|---|
| `k` | `#1a0f12` | Contorno universal (1 px, nunca negro puro) |
| `d` `g` `l` | `#3d2b2e` `#5a4040` `#7a5a52` | Piedra, sombras cálidas |
| `r` `o` `y` `w` | `#c2321e` `#ff6a1a` `#ffb43a` `#ffe08a` | Rampa de fuego (valor, ascuas, ataques) |
| `W` | `#f4e4c8` | Hueso / texto |
| `b` `c` | `#4a6a8a` `#8ab4d0` | Frío (bloqueo, acto 3) |
| `p` | `#9a5ad0` | Debuffs |
| `G` | `#6ac46a` | Curación |
| `s` `h` `n` | `#e0a080` `#6a3020` `#8a5030` | Piel, pelo, cuero |
| `m` `M` | `#9aa0a8` `#d0d4d8` | Metal |
| `R` `Y` | `#7a1a16` `#fff4c8` | Sangre oscura, brillo máximo |
| `B` `P` `e` `S` | `#2a3a5a` `#d0a8ff` `#2e6a3a` `#b07050` | Azul profundo, magia, escoria verde, piel en sombra |

## Reglas
1. Filtro **Nearest** siempre; escalado entero (×4 iconos, ×6 personajes, ×4 fondos 320×180).
2. Luz desde arriba‑izquierda. Tres tonos por material, nunca degradados suaves en sprites.
3. Contorno `k` de 1 px en todo lo interactivo.
4. Enemigos: generados por **máscaras de forma + semilla** (simetría vertical), con tres tonos del bioma del acto y ojos brillantes.
   Esto da identidad por arquetipo y variación infinita por ciclo.
5. UI: paneles rectangulares sin redondeo, borde 3 px, sombra dura 4 px. Colores de carta por tipo:
   Ataque `r`, Habilidad `b`, Poder `y`, Combustible `g`.
6. Todo el arte vive como datos en `scripts/autoload/art.gd` (mapas ASCII) → versionable en Git, sin binarios.


## v0.2 — Técnicas
| Pieza | Resolución | Escala | Técnica |
|---|---|---|---|
| Iconos (93) | 12×12 | ×2–×5 | ASCII a mano, contorno `k`, 3–4 tonos por material |
| Heroína | 20×30 + brazo 8×17 | ×6 | Cuerpo y brazo con martillo separados: el brazo rota sobre el hombro (golpe, lanzar, alzar) |
| Monstruos | máscara ×2 simétrica | ×5–×8 | **Campo de distancia** al borde → volumen; luz cenital; rampa de 5 tonos con **tramado Bayer 4×4** en las transiciones; venas brillantes por semilla; **capa emisiva** aparte (ojos, venas, acentos) que late con mezcla aditiva |
| Marco de carta | 75×105 | ×2 | Bisel por tipo, banda de nombre, ventana de ilustración, cinta de tipo, remaches, gema de rareza, marcas de Maestría |
| Ilustración de carta | 30×15 | ×4 | Degradado tramado por tipo, halo radial, vetas/rayos según tipo, motas sembradas por id, icono con sombra |
| Forja | 48×40 | ×2.5–×5 | Cúpula de ladrillo; la boca usa más tonos calientes cuanto mayor es la producción |
| Fondos | 320×180 | ×4 | Ladrillo biselado y agrietado, columnas, estandartes del acto, cadenas, soportes de antorcha con luz tramada, suelo en perspectiva con charcos de luz |

## Reglas de animación (Dirección de animación)
- **Anticipación antes de cada golpe enemigo** (retroceso de 14 px y giro), embestida rápida, vuelta con rebote.
- **Retroceso en la dirección del impacto**, nunca temblor simétrico.
- **Quemar** se ve como quemar: la carta vuela hacia el horno mientras un shader de disolución pixelada (rejilla al
  tamaño del arte, no de la pantalla) la consume desde abajo con un borde amarillo→naranja. El horno se aplasta y se ilumina.
- Las muertes usan el mismo shader: el lenguaje visual del fuego es coherente en todo el juego.
- La luz es animada pero sutil: halos aditivos en antorchas y horno, motas de ceniza flotando.
