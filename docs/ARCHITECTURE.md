# Arquitectura — Dirección Técnica

Godot 4.7 · GDScript tipado · renderer Compatibility · 1280×720 (`canvas_items`, filtro Nearest).

```
scenes/main.tscn            Raíz: scripts/ui/main.gd
scripts/
  autoload/
    game_state.gd  (Game)   Dueño único de la economía, meta-progreso, ascensión activa y guardado JSON
    art.gd         (Art)    Pixel art como datos: sprites ASCII, monstruos procedurales, fondos
    sfx.gd         (Sfx)    Audio sintetizado en arranque (SFX + 2 bucles musicales)
  core/                     Lógica pura, sin nodos → testeable headless
    combat_engine.gd        Reglas del combate; emite event(kind, data)
    run_state.gd            Estado de una ascensión (mazo, reliquias, puertas, guardado)
    card.gd · fighter.gd    Instancias
    num.gd                  Formato de números grandes
  data/                     Tablas de diseño (sin lógica)
    card_db.gd · enemy_db.gd · relic_db.gd · forge_db.gd
  ui/
    main.gd                 Gestor de pantallas, HUD, modales, selector de cartas, efectos globales
    ui.gd                   Kit: tema, widgets, texto flotante, partículas, shader de flash
    card_view.gd · fighter_view.gd
    screens/                title, forge, antesala, map, combat, rest, shop, event, summary
tests/
  test_runner.tscn          Suite QA headless (lógica, datos, economía, guardado, arte)
  balance_sim.tscn          Simulación de balance
  progression_sim.tscn      Bucle completo durante horas simuladas (ritmo de hitos)
  smoke.tscn                Recorrido visual completo con capturas → screenshots/
```

## Decisiones
1. **Motor de combate sin nodos.** `CombatEngine` muta estado y emite eventos. La pantalla de combate
   secuencia el turno enemigo con `await` y anima cada evento. QA simula combates enteros sin UI.
2. **Datos en tablas GDScript `const`.** Cartas y enemigos son operaciones (`["dmg", 6]`) interpretadas por el motor;
   el texto de las cartas se genera de las mismas operaciones → nunca hay descripciones desincronizadas.
3. **Arte y audio como código.** Cero binarios en el repositorio: todo es diffeable y revisable en Git.
4. **Un autoload por responsabilidad.** `Game` no conoce la UI; la UI escucha `embers_changed`, `forge_changed`, `embers_gained`.
5. **Guardado** en `user://emberspire_save.json` cada 15 s, al cerrar y entre pisos. Si se cierra dentro de una sala,
   el piso se repite (evita exploits de salir para esquivar combates).

6. **Resonancias como reliquias invisibles.** `RunState.perks` comparte los ganchos de las reliquias:
   `run.has_relic(id)` mira ambas listas, así una ventaja nueva es una fila en `RelicDB.PERKS` + un `if` en el motor.
7. **Maestría aplicada al leer.** `Card.effects()` escala las operaciones con `CardDB.scale_ops` según
   `Game.mastery_level(id)`: el texto de la carta, el motor y la IA ven siempre el mismo número.
8. **Valores dinámicos.** Las operaciones del Grimorio de la Forja (`dmg_braziers`, `block_gens`…) se resuelven con
   `CardDB.dyn_value(op)` tanto en la descripción como en el motor.
9. **`bank_embers = false`** aísla el motor: ni Ascuas, ni Maestría, ni estadísticas tocan `Game` en los tests puros.
10. **Shaders mínimos** en `UI`: flash, disolución pixelada (rejilla al tamaño del arte) y mezcla aditiva para halos y capas emisivas.

## Convenciones
- Tabs, tipado explícito cuando el valor viene de un `Dictionary`.
- Pantallas extienden `Screen` y construyen su UI en `build()`.
- Commits con prefijo de disciplina (`core:`, `ui:`, `balance:`…), ver `TEAM.md`.
