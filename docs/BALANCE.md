# Balance — informe de Diseño

Fuente: `tests/balance_sim.tscn` (40 ascensiones por perfil, IA voraz: quema combustible, juega poderes,
defiende si el daño entrante supera su bloqueo, coge siempre la primera carta de recompensa, no compra).
Una persona juega mejor que esta IA: los resultados son un **suelo**, no un techo.

| Perfil de Arsenal | Inversión aprox. | Piso medio | Máx | Ascuas/ascensión |
|---|---|---|---|---|
| Novata (nada) | 0 | 9.5 | 10 | 543 |
| Media (PV 6, Tiro 1, Templado 5, Codicia 4) | ~10 K | 12.8 | 20 | 2.9 K |
| Veterana (+Brazo, Manos, Herencia) | ~200 K | 17.6 | 20 | 3.1 K |
| Leyenda (+Núcleo, todo al máx. finito) | ~5 M | 24.8 | 30 | 8.9 K |
| Mítica (+25 Filo Eterno, +25 Piel Forjada) | ~2 B | 73.5 | 90 | 233 K |

## Lectura
- **El primer jefe (piso 10) es el muro intencionado** de la primera hora. La IA novata llega siempre y siempre cae:
  el jugador aprende que debe volver a la Forja, invertir y regresar.
- Cada jefe de acto actúa como escalón (10 → 20 → 30). Los ciclos posteriores escalan
  PV ×2.6 y daño ×1.7 por ciclo, compensados por las mejoras infinitas (×1.04 por nivel, coste ×1.7).
- Las Ascuas por ascensión crecen ~×400 entre novata y mítica gracias a la oleada de victoria
  (segundos de producción) → la Torre sigue siendo relevante en el late game incremental.

## Palancas principales
| Palanca | Archivo | Efecto |
|---|---|---|
| `burn_value`, `kill_value`, `victory_wave` | `game_state.gd` | Ingreso de la Torre |
| `COST_GROWTH`, `MILESTONES` | `forge_db.gd` | Ritmo idle |
| `BRAZIER_BONUS`, `STARDUST_BONUS` | `game_state.gd` | Acoplamiento Torre → Forja |
| `hp_mult`, `dmg_mult` en `EnemyDB.make` | `enemy_db.gd` | Curva de dificultad |
| `rebirth_gain` | `game_state.gd` | Ritmo de prestigio (√ de Ascuas/1M) |

## Riesgos conocidos
- Builds de Pira con Fuego Interior + Tiro Abierto pueden trivializar actos tempranos (deseable como fantasía; vigilar).
- Precios del Yunque Errante escalan con la producción: en late game comprar cartas cuesta ~25–80 s de producción.
