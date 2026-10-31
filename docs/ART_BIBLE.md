# Biblia de Arte — EMBERSPIRE

## Objetivo visual
Pixel art cálido sobre oscuridad. **La luz es el recurso**: todo lo valioso brilla en naranja/amarillo; el peligro frío es azul.

## Paleta cerrada (16 colores)
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

## Reglas
1. Filtro **Nearest** siempre; escalado entero (×4 iconos, ×6 personajes, ×4 fondos 320×180).
2. Luz desde arriba‑izquierda. Tres tonos por material, nunca degradados suaves en sprites.
3. Contorno `k` de 1 px en todo lo interactivo.
4. Enemigos: generados por **máscaras de forma + semilla** (simetría vertical), con tres tonos del bioma del acto y ojos brillantes.
   Esto da identidad por arquetipo y variación infinita por ciclo.
5. UI: paneles rectangulares sin redondeo, borde 3 px, sombra dura 4 px. Colores de carta por tipo:
   Ataque `r`, Habilidad `b`, Poder `y`, Combustible `g`.
6. Todo el arte vive como datos en `scripts/autoload/art.gd` (mapas ASCII) → versionable en Git, sin binarios.
