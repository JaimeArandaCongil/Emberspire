# Balance — informe de Diseño (v0.2)

Dos simulaciones headless. Las IA juegan peor que una persona (no compran en la tienda, eligen cartas por rareza):
los resultados son un **suelo**, no un techo.

## 1. Progresión completa (`tests/progression_sim.tscn`)
Una IA juega el bucle entero durante 8 h simuladas: invierte en la Forja con una política de rentabilidad,
asciende, elige puertas, quema las cartas sobrantes (gana Maestría), firma Pactos al superar su récord
y Renace cuando duplica su Polvo. Supuestos: 75 s por piso, 45 s en la Forja entre ascensiones.

| Hito | Minuto |
|---|---|
| Muere en el primer jefe (piso 10) | 13 |
| Primera Resonancia · Reliquario 10 · Grimorios Pira/Yunque/Forja | 55 |
| Récord piso 20 (segundo jefe) | 55 |
| Récord piso 30 · primera carta con Maestría 5 | 93 |
| Primer Renacer | 106 |
| Récord piso 50 | 170 |
| Calor de Pacto 3 | 233 |
| Récord piso 60 | 390 |
| Producción 1M/s · tercer Renacer | 390–416 |
| Al cabo de 8 h: 21/26 hitos, 12 cartas con Maestría 5, Reliquario completo (40/40) | 517 |

### Lectura
- **Cada jefe es un muro de 30–60 min** que se rompe volviendo a la Forja: el ritmo de los dos bucles queda trenzado.
- Tras el primer Renacer la producción cae a la cuarta parte, pero las ascensiones siguen avanzando porque
  Maestría, Reliquario y Arsenal no se pierden: el prestigio nunca se siente como retroceso.
- El tramo 50 → 60 (acto 3 del segundo ciclo) es el muro intencionado del mid-game: pide Pactos, Renacer y Maestría.

### Ajustes hechos gracias a esta simulación (iteración 1 → 2)
| Problema detectado | Causa | Cambio |
|---|---|---|
| Una sola ascensión pasaba del piso 30 al 83 | El ciclo ×2.6 PV hacía el acto 1 del ciclo 2 más débil que el jefe del piso 30 | `HP_PER_CYCLE` 2.6 → **4.0**, `DMG_PER_CYCLE` 1.7 → **2.0** (`enemy_db.gd`) |
| La Torre pagaba ~10× la Forja en late game | Codicia +25%/nivel × 25 niveles, Calor +25%/punto | Codicia **+10%/nivel, máx. 20**; Calor **+20%** (+30% con talento) |
| El Polvo Estelar se disparaba (516 → 20.650) | Factor de récord ×(1+piso/20) | Factor **×(1+piso/50)** |
| Bucle infinito de la IA con Azogue (0 de coste, roba 2) | Combo legítimo para el jugador, no para la IA | Límite de 40 acciones por turno en las IA |
| Error al atacar con Hija del Fuego activa | Ternario sin tipo asignado a `Array[Fighter]` | Corregido + prueba de regresión que combina cada Poder con cada tipo de ataque |

## 2. Perfiles de Arsenal (`tests/balance_sim.tscn`)
40 ascensiones por perfil, sin Resonancias ni Maestría (aísla el efecto del Arsenal).

| Perfil de Arsenal | Inversión aprox. | Piso medio | Máx | Ascuas/ascensión |
|---|---|---|---|---|
| Novata (nada) | 0 | 9.6 | 14 | 704 |
| Media (PV 6, Tiro 1, Templado 5, Codicia 4) | ~10 K | 11.6 | 20 | 1.95 K |
| Veterana (+Brazo, Manos, Herencia) | ~200 K | 18.9 | 20 | 4.65 K |
| Leyenda (+Núcleo, todo al máx. finito) | ~5 M | 26.3 | 45 | 14.6 K |
| Mítica (+25 Filo Eterno, +25 Piel Forjada) | ~2 B | 62.9 | 77 | 196 K |

## Palancas principales
| Palanca | Archivo | Efecto |
|---|---|---|
| `HP_PER_CYCLE`, `DMG_PER_CYCLE` | `enemy_db.gd` | Dureza de cada vuelta a la Torre |
| `burn_value`, `kill_value`, `victory_wave` | `game_state.gd` | Ingreso de la Torre |
| `MASTERY_XP`, `CardDB.scale_ops` | `game_state.gd`, `card_db.gd` | Ritmo y fuerza de la Maestría |
| `RESONANCE_TIERS`, `PERKS` | `relic_db.gd` | Cuándo y cuánto cambia el combate al comprar generadores |
| `heat_bonus_each`, `PACTS` | `game_state.gd`, `forge_db.gd` | Riesgo ⇄ recompensa |
| `codex_bonus_each` | `game_state.gd` | Valor de coleccionar reliquias |
| `COST_GROWTH`, `MILESTONES` | `forge_db.gd` | Ritmo idle |
| `rebirth_gain` | `game_state.gd` | Ritmo de prestigio |

## Riesgos conocidos
- **Combos infinitos** (Azogue + mazo muy delgado, Fénix de Papel + Fundir): deseables como fantasía de deckbuilder,
  vigilar que no rompan la economía (cada quema cuesta una Quema; la Maestría no tiene atajo infinito).
- El Reliquario se completa hacia las 3 h en la simulación: valorar más reliquias o un segundo nivel de colección.
- La IA no usa la tienda: con ella, una persona llega antes a cada muro (deseable).
