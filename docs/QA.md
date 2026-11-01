# QA

## Suites automáticas
| Suite | Comando | Cubre |
|---|---|---|
| Lógica | `GODOT=<ruta> ./tests/run_tests.sh` | Formato numérico, integridad de datos (iconos, formas, encuentros), economía (coste geométrico, braseros, renacer), combate (daño, Vulnerable/Débil, bloqueo, quemar), 7 combates completos simulados, **cada carta jugada y quemada (normal y mejorada)**, cada enemigo actuando 5 turnos, cada Poder combinado con cada tipo de ataque, Maestría, Resonancias, Pactos, robo/devolución, ahogo, invocación, recuperar, transmutar, espinas, Brasa/Etérea, Reliquario, hitos, guardado v2, puertas y jefes, guardado/carga (incluida la ascensión en curso), arte (anchos de sprite, generación de monstruos) |
| Balance | `godot --headless --path . res://tests/balance_sim.tscn` | Curva de progreso por perfil (ver `BALANCE.md`) |
| Progresión | `godot --headless --path . res://tests/progression_sim.tscn -- 8` | Bucle completo durante N horas simuladas: minuto de cada hito (ver `BALANCE.md`) |
| Visual | `godot --path . res://tests/smoke.tscn` | Recorre título → Forja (Archivo, Crónica) → Antesala → Torre → combate (hover, quemar a media disolución, martillazo, turno enemigo, muertes, victoria) → jefe con invocación → reliquias de jefe → jefes alternativos de los actos 2 y 3 → tienda → hoguera → misterio → resumen → muestrario de cartas; guarda 23 capturas |

El script falla si aparece cualquier `SCRIPT ERROR` o `Parse Error`, no sólo si fallan comprobaciones.

## Checklist manual antes de una versión
- [ ] Primera partida: modal de bienvenida, clic en horno, compra de Chispa.
- [ ] Ascensión completa hasta morir: resumen muestra braseros nuevos y la Forja produce más.
- [ ] Atacar con varios enemigos: seleccionar carta → clic en enemigo. Esc / clic derecho en vacío cancela.
- [ ] Quemar con clic derecho y con selección + horno; sin quemas restantes aparece aviso.
- [ ] Cerrar el juego dentro de un combate y reabrir: se vuelve a elegir puerta del mismo piso.
- [ ] Cerrar 2+ minutos y reabrir: modal "Mientras dormías…".
- [ ] Renacer con ≥1M Ascuas en la vida actual: las Resonancias se apagan, la Maestría y el Reliquario se conservan.
- [ ] Quemar la misma carta hasta subir de Maestría: aviso en combate, marco actualizado, Códice actualizado.
- [ ] Comprar el décimo generador de un tipo: aviso de Resonancia y la ventaja aparece en la barra de combate.
- [ ] Tras el piso 10: aviso de Pactos; firmar Pactos en la Antesala cambia el Calor mostrado en combate y en la Torre.
- [ ] Una Urraca roba Ascuas (el contador baja) y al matarla se recuperan dobles.
- [ ] Ceniza Húmeda no se puede quemar (aviso) y desaparece al acabar el turno.

## Evidencia de esta versión
- `tests/run_tests.sh`: **1581 comprobaciones, 0 fallos**.
- `tests/smoke.tscn`: 23 capturas en `screenshots/`, `SMOKE OK`, sin errores de script.
- `tests/progression_sim.tscn`: 8 h simuladas sin errores de script.
- Limitación: el input con ratón se ejercita por script (`_try_burn`, `_play`, `_on_enter`), no con clics reales.
