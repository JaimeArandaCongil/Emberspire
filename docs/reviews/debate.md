# Debate de revisión — v0.3 (en curso)

Participantes: dirección (implementación), agente de game design (`design_review.md`), agente de arte (`art_review.md`).

## Diseño: acuerdos
| Tema | Propuesta original | Objeción de dirección | Acuerdo |
|---|---|---|---|
| Quema en caliente | ×2 si podías pagarla, ×0.5 si no | Sin coste: la Energía sobrante al final del turno la hace gratis | **Pagas el coste de la carta → ×2 Ascuas y ×2 Maestría**; normal ×1; Combustible/coste 0 no |
| Temple | Ramas en Maestría 2 y 4 por carta | Demasiado texto para 90 cartas | **Una elección en Maestría 3**; Brasa genérica por tipo (40% del número, mín. 3); re-temple por 10 min de producción |
| Lingotes | 3 monedas nuevas | Enturbia «Ascuas = todo» | **Fuera de esta versión** |
| Resplandor | Buff tras ascender | Pedida fórmula | Medido en sim: quema 1.5 s, oleadas 6/20/90 s, tesoro 15 s, +2.5%/carta (tope 250%), 30 min + 1/piso (máx. 90) |
| Ciclos | HP ×3 con afijos | 2.6 rompía la curva | **×3.5 sólo con afijos** (6 afijos) |
| Checkpoints + Brasas Vivas | — | ¿Se pisan? | No: racha +4%/piso (tope 100%) en bote aparte, se cobra al retirarse o en Hoguera |

## Arte: acuerdos
- Sin SubViewport: **regla dura ×4** para todo el mundo, sprites redibujados a tamaño nativo, posiciones cuantizadas, nada de scale/rotation sobre pixel art.
- Fuente pixel para títulos, números, HUD y nombres; fuente lisa sobre pergamino para cuerpos de carta.
- Monstruos: plantillas a mano por bloques de prioridad (gólem, caballero, urraca, sabueso, murciélago, jefes acto 1 → acto 2 → acto 3); formas frontales siguen simétricas.
- Reparto de archivos: el agente de arte implementa `art.gd`, `ui.gd`, `card_view.gd`, `fighter_view.gd`, título, hoguera y la parte visual del combate.

## Estado
Implementado (diseño): quema en caliente, Temple, Maestría al jugar, Resplandor, Brasas Vivas, Resonancias elegibles (21 nuevas), Constelaciones (8), Grimorios activos, checkpoints, puertas con encuentro y rasgo, tesoro con precio, afijos, 3 enemigos reactivos, topes de cartas de Forja, Ceniza escalando con Filo Eterno, pase de cartas y reliquias, Urracas que huyen, Autoforja con reserva, introducción por capas. 1737 comprobaciones en verde.

Pendiente:
- **Rebalance**: la simulación de 8 h tras los cambios da idle 35% (objetivo cumplido) pero la progresión se acelera demasiado (récord 13 → 50 en una ascensión; Polvo sin gastar ~480K). Hay que endurecer y re-medir.
- UI de combate (tras el pase de arte): Mayús+clic derecho para quemar en caliente con vista previa, aviso de huida de Urraca, pista del tutorial, élite con 1 de 2 reliquias, Purga, opción «Enviar Brasas Vivas» en la Hoguera.
- Pase de arte del agente de arte (en curso; resumen en `art_changes.md` al terminar).
