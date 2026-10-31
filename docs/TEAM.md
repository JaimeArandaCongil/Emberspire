# Equipo y jerarquía — Estudio Brasa

El proyecto se desarrolla como un estudio pequeño con roles claros. Cada decisión tiene un dueño.

```
                 Dirección Creativa  (visión, pilares, veto final)
                          │
          ┌───────────────┼────────────────┐
   Diseño de Juego    Dirección Técnica    Dirección de Arte
   (sistemas, balance)  (arquitectura, código)  (paleta, sprites, UI)
          │                  │                   │
   Diseño de Niveles   Ingeniería de        Game Feel / FX
   y Economía          Combate              Audio
          └──────────────────┼───────────────────┘
                             QA
                (tests headless, capturas, regresión)
```

| Rol | Dueño de | Documento |
|---|---|---|
| Dirección Creativa | Pilares, tono, alcance | `VISION.md` |
| Diseño de Juego | Cartas, enemigos, economía, curvas | `GDD.md`, `BALANCE.md` |
| Dirección Técnica | Arquitectura, convenciones, rendimiento | `ARCHITECTURE.md` |
| Dirección de Arte | Paleta cerrada, reglas de pixel art | `ART_BIBLE.md` |
| QA | Suite headless, capturas, checklist | `QA.md` |

## Reglas de trabajo
1. **La visión manda.** Una feature que no refuerza un pilar no entra en la versión.
2. **Datos, no código.** Cartas, enemigos, reliquias y mejoras son tablas en `scripts/data/`. Diseño balancea sin tocar lógica.
3. **Lógica separada de presentación.** `CombatEngine` no conoce nodos; la UI escucha sus eventos. Así QA puede testearlo headless.
4. **Commits por disciplina** con prefijo: `docs:`, `core:`, `combat:`, `forge:`, `art:`, `ui:`, `audio:`, `qa:`, `balance:`.
5. **Nada se da por hecho sin evidencia**: tests en verde y captura de pantalla para cambios visuales.
