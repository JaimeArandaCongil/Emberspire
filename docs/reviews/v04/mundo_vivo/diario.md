# Diario · Mundo vivo (MV) — v0.4

## Fase 1 — Cimientos del acto 1

### Qué hay
| Archivo | Qué es |
|---|---|
| `scripts/art/bg/bg_ramps.gd` | Enum corto de materiales sobre `Palette`. Nadie escribe hex. |
| `scripts/art/bg/bg_canvas.gd` | Lienzo material + valor + ancla + banderas. Hornea a índice (`IndexFormat.pack`) y vista previa. |
| `scripts/art/bg/bg_act1.gd` | `BgAct1.build(kind, piso, ciclo, patches)`: salas `"normal"` y `"flue"` a 640×360 en 4 capas. |
| `scripts/ui/world/art_particles.gd` | `ArtParticles`: pool de 256, simulación en arte, dibujo en `floor(pos)`, rampas de paleta, determinista. |
| `scripts/ui/world/ambient/ambient_state.gd` | Interfaz con el juego. `from_game()` es lo único que toca `Game`. |
| `scripts/ui/world/ambient/ambient_frames.gd` | Fotogramas cacheados: llama (8, con inclinación), humo (8), crisol (16 posiciones). |
| `ambient_brazier.gd`, `ambient_crucible.gd`, `ambient_flue.gd`, `ambient_soot_drip.gd`, `ambient_gauge.gd` | Nodos reutilizables de ambiente. |
| `scripts/ui/world/ambient/act1_room_view.gd` | Sala montada, con o sin shader. |
| `tests/art/test_mv.gd` | Pruebas (ver abajo). |
| `tests/_review_art/v04/mundo_vivo/fase1_export.*`, `fase1_live.*` | Exportador y escena viva de revisión. No son del juego. |

### Uso
```gdscript
var view := Act1RoomView.new()
wv.world.add_child(view)
view.build(BgAct1.build("normal", piso, ciclo, false), AmbientState.from_game(), wv.lights, wv.lit_material)
view.actors.add_child(luchador)
view.set_parallax(raton_x)        # −1..1
view.state.pulse_burn()           # al quemar
view.state.pulse_strike(danio)    # sacude el crisol si danio ≥ 20
```
Sin `wv.lights` y `wv.lit_material` usa las vistas previas en color; entonces hay que pasar `patches = true` para que la luz parpadee.

### Decisiones
1. **Formato de TEC, sin cambios pedidos.** R = `Palette.index`. CANTO: si la luz horneada en el ancla ya da ≥ 2 pasos, el +1 se hornea y la bandera se quita; si no, la bandera queda para la regla del shader (`off ≥ 1`). Nunca suma dos veces. Respuesta al aviso de TEC: su regla da el aspecto que quiero, sobre todo con la onda de quemar.
2. **Parpadeo a ±0,75 pasos, no ±1.** El shader redondea `pasos × caída`. Con ±1 saltaba un disco de 44 px con sus cantos, y el pico en reposo era 7,3 %. Con ±0,75 sólo cambian las piezas a menos de ~29 px de la llama.
3. **Mis sprites de luz aditiva quedan retirados.** Sin shader se usan parches horneados de la capa media (3 por brasero, 16 por crisol), con colores de paleta exactos.
4. **Manómetro con la aguja viva.** La esfera se hornea y la aguja la dibuja `AmbientGauge`: la presión del fuelle es calor + producción + pulso de quemar.
5. **Vetas del ciclo II.** Primero salieron escaleras regulares, luego «circuito impreso» durante el pulso. Ahora caminan por las juntas, están rotas y son rescoldos oscuros en reposo (fuego 1–2), que el pulso enciende.
6. **Humo.** Los huecos internos formaban una garra en lo alto de la columna. Ahora cada bocanada crece, adelgaza y se deshace sólo por el borde.

### Pruebas y medidas
- `test_mv.gd`: 0 fallos. Cubre determinismo, `IndexFormat.validate`, vista previa = índice decodificado, paleta cerrada (capas y fotogramas), anclas, disposición de combate, variación, parches, partículas y estado.
- **Paridad en GPU** (`fase1_live -- parity`, piso 4, ciclo II, `flicker_amp = 0`): 0 píxeles distintos entre `palette_lit` y la vista previa en las 8 capas.
- `tests/test_runner.tscn`: 1745 comprobaciones, 0 fallos.
- Píxeles en movimiento (24 fotogramas a 110 ms, 230.400 px, presupuesto 6 %):

| Sala | Reposo, media | Reposo, pico | Pico del evento quemar |
|---|---|---|---|
| normal p4, shader | 2,6 % | 4,5 % | 18,7 % |
| normal p4 ciclo II, shader | 2,6 % | 4,1 % | 18,1 % |
| tiro p10, shader | 2,2 % | 3,1 % | 16,1 % |
| normal p4, sin shader | 2,8 % | 5,4 % | 5,6 % |
| tiro p10, sin shader | 1,6 % | 3,2 % | 3,2 % |

Los luchadores de la escena son estáticos: con ellos animados, el reposo subirá.

### Evidencia (`tests/_review_art/v04/mundo_vivo/out/fase1/`)
`live_normal_p4_c0_shader_quemar_x2.png`, `live_flue_p10_c0_shader_quemar_x2.png`, `live_normal_p4_c1_shader_quemar_x2.png`, `a1_variantes_x1.png`, `anim_brasero_real_8f_x4.png`, y los GIF `live_*.gif` (24 fotogramas). `a1_*_index.png` son las capas de índice.

### Pendiente
- **Horneado:** una sala tarda unos 5 s con parches. Hay que hornearla (C7) antes de usarla en el juego; el manifiesto es de TEC.
- **Integración:** el combate sigue con el fondo v0.3. `UI.sparks`, `UI.dust` y `UI.fire_emitter` no se han sustituido en las llamadas.
- **Forja grande:** las capturas usan el sprite v0.3 ×2. El conducto termina en x 100–109, y = 200 y hay que casarlo con la Forja real.
- **Sin comprobar visualmente:** goteo de hollín, PV bajos y Resplandor. `AmbientState.glow` aún no tiene efecto visual.
- **Luces:** la sala normal gasta 3 de las 4 de `LightRig` y la de tiro 2.
- **Calidad:** el muro del tiro sigue algo plano, las saeteras lejanas se leen como marcas rojas y las vetas conservan algo de escalera.
- **Ambiente sin luz:** llamas, humo, crisol y partículas no pasan por `palette_lit`. El hierro del crisol no reacciona a la onda de quemar.
- **Brasero derecho de la sala de tiro** (x 618): cae sobre la zona de enemigos; con el tercer enemigo en x 572 hay que revisar el solape.
