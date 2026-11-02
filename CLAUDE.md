# EMBERSPIRE
Roguelike de cartas + incremental en Godot 4.7.2 (GDScript tipado, `gl_compatibility`, 1280×720). Documentos en español.

## Comandos
- QA (salida filtrada, úsala siempre): `tools/qa.sh [game|art|all]`
- Hornear: `tools/qa.sh bake --only=id1,id2` (sin `--only` hornea todo)
- Binario, para capturas o escenas con ventana: `/c/Users/Jaime/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`
- Recorrido con capturas: `<binario> --path . res://tests/smoke.tscn` → `screenshots/`
- Nunca vuelques registros completos de Godot: filtra con `grep -E "ERROR|fallos"` y `tail`.

## Qué leer (y sólo esto)
| Para | Lee |
|---|---|
| Estado y paquete actual | `docs/PLAN_ARTE.md` |
| Decisiones vigentes | `docs/DECISIONES.md` |
| Reglas de arte, paleta, disposición | `docs/ART_BIBLE.md` (la sección que toque) |
| Rig | `docs/reviews/v04/tecnico/api_rig.md` y un ejemplo en `scripts/art/defs/` |
| Textura índice | `docs/reviews/v04/tecnico/formato_indice.md` |
| Interfaz de combate | `docs/reviews/v04/cartas_ui/api_hud.md` |
| Efectos | `docs/reviews/v04/mundo_vivo/api_vfx.md` |
| Sistemas y arquitectura | `docs/GDD.md`, `docs/ARCHITECTURE.md` |

**No leas** `docs/reviews/v04/*/propuesta.md`, `ronda1.md` ni el `diario.md` de otros, salvo que el encargo lo pida: son histórico
y sus conclusiones ya están arriba. No abras el arte legado (`scripts/art/legacy/`) salvo para migrar esa pieza.

## Reglas
- Sólo editas los archivos de tu paquete. Si necesitas otro, dilo en tu informe.
- Sin commits: los hace dirección al cerrar cada paquete. `project.godot` sólo lo cambia quien tenga el paquete de integración.
- Nada de hex a mano: colores de `Palette` (`scripts/art/palette.gd`); si falta uno, dilo en tu informe.
- Sin escala no entera ni rotación de arte en reposo; todo en la rejilla 640×360 ×2. Sin recolorear para crear contenido.
- El juego arranca y se juega siempre; lo nuevo entra con respaldo al arte anterior.
- Hecho = `tools/qa.sh all` en verde + captura o hoja revisada. Di con honestidad lo no comprobado.
- Archivos de más de 300 líneas (`combat_screen.gd`, `fighter_view.gd`, `bg_act1.gd`): localiza con Grep y lee rangos. No releas lo que ya tienes.
- Revisa imágenes con moderación: una hoja por iteración y a la escala menor que permita juzgar.
- Informe final: máximo 150 palabras, con rutas, evidencia y pendientes. Lo detallado va a `docs/reviews/v04/<rol>/diario.md`.
