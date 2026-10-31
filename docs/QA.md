# QA

## Suites automáticas
| Suite | Comando | Cubre |
|---|---|---|
| Lógica | `GODOT=<ruta> ./tests/run_tests.sh` | Formato numérico, integridad de datos (iconos, formas, encuentros), economía (coste geométrico, braseros, renacer), combate (daño, Vulnerable/Débil, bloqueo, quemar), 7 combates completos simulados, puertas y jefes, guardado/carga (incluida la ascensión en curso), arte (anchos de sprite, generación de monstruos) |
| Balance | `godot --headless --path . res://tests/balance_sim.tscn` | Curva de progreso por perfil (ver `BALANCE.md`) |
| Visual | `godot --path . res://tests/smoke.tscn` | Recorre título → Forja → Torre → combate (hover, quemar, turno enemigo, victoria) → jefe → actos 2 y 3 → tienda → hoguera → misterio → resumen → mazo; guarda 16 capturas |

El script falla si aparece cualquier `SCRIPT ERROR` o `Parse Error`, no sólo si fallan comprobaciones.

## Checklist manual antes de una versión
- [ ] Primera partida: modal de bienvenida, clic en horno, compra de Chispa.
- [ ] Ascensión completa hasta morir: resumen muestra braseros nuevos y la Forja produce más.
- [ ] Atacar con varios enemigos: seleccionar carta → clic en enemigo. Esc / clic derecho en vacío cancela.
- [ ] Quemar con clic derecho y con selección + horno; sin quemas restantes aparece aviso.
- [ ] Cerrar el juego dentro de un combate y reabrir: se vuelve a elegir puerta del mismo piso.
- [ ] Cerrar 2+ minutos y reabrir: modal "Mientras dormías…".
- [ ] Renacer con ≥1M Ascuas en la vida actual.
