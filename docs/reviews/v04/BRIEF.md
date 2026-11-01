# Brief del panel de arte v0.4

## Petición del cliente (literal)
> Quiero que discutas mucho con el experto en arte de cómo elevar el arte del juego para llegar a un resultado de artista pro pixel art.
> Quiero que el conjunto sea precioso y con mucho más detalle. Las cartas y sus ilustraciones, los enemigos, los fondos, los menús,
> los protagonistas. Despliega todos los expertos que necesites, planifica y busca la manera de llegar a algo increíble.
> No tomes caminos rápidos, no me des un resultado mediocre por entregar algo. Dame algo top. Documenta todo.
> E intenta que el mundo se sienta vivo con animaciones. Plantea todo de manera interconectada.

## El juego
EMBERSPIRE: roguelike de cartas (tipo Slay the Spire) + incremental. "Tu mazo es combustible": quemas cartas en tu Forja
para ganar Ascuas, que alimentan una Forja idle que a su vez te hace más fuerte en la Torre. Protagonista: la Fogonera.
3 actos (Hollín, Escoria, Ceniza Helada) que se repiten en ciclos. ~90 cartas, ~40 enemigos, 6 jefes, eventos, tienda, hoguera.

## Estado técnico
- Godot 4.7.2, GDScript tipado, renderer gl_compatibility, 1280×720, `canvas_items`, filtro Nearest.
- Binario: `/c/Users/Jaime/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`
  (en Bash, la variable no persiste entre llamadas: usa la ruta completa). Godot reescribe `project.godot` al ejecutarse:
  restáuralo con `git checkout project.godot`.
- TODO el arte se genera por código en `scripts/autoload/art.gd` (2.567 líneas: ASCII a mano + sombreado procedural).
  No hay PNGs de juego. No hay PIL en Python; Godot sí puede leer/escribir PNG (`Image.save_png`).
- Regla actual (`docs/ART_BIBLE.md`): mundo ×4 (lienzo 320×180), interfaz ×2. Heroína 24×36, monstruos 12–26 px, jefes 60–72.
- Pantallas: `scripts/ui/screens/*.gd` (título, forja, antesala, mapa, combate, evento, tienda, hoguera, resumen).
  Vista de carta `scripts/ui/card_view.gd`, luchadores `scripts/ui/fighter_view.gd`, utilidades `scripts/ui/ui.gd`,
  fuente pixel `scripts/ui/pixel_font.gd`.
- Datos: `scripts/data/card_db.gd` (cartas, campo `icon`), `enemy_db.gd` (enemigos, campo de forma), `relic_db.gd`.
- Capturas del recorrido completo: ejecuta `"$GODOT" --path . res://tests/smoke.tscn` (con ventana) → `screenshots/*.png`.
  Ya están generadas las del estado actual en `screenshots/`. Míralas TODAS con la herramienta Read.
- Revisión anterior: `docs/reviews/art_review.md`, `docs/reviews/art_changes.md`. Herramientas de hojas de sprites: `tests/_review_art/`.

## Reglas para esta fase (crítica + propuesta + prueba de concepto)
- NO modifiques ningún archivo existente del juego (`scripts/`, `scenes/`, `project.godot`, `docs/` salvo tu carpeta).
- Escribe sólo en `docs/reviews/v04/<tu_rol>/` (documento) y `tests/_review_art/v04/<tu_rol>/` (escenas/scripts/PNG de prueba).
- Tu prueba de concepto debe ser **real**: un script de Godot que genere PNG(s) y que mires con Read. Itera sobre ella
  hasta que la consideres de calidad profesional; no entregues una prueba mediocre. Guarda los PNG finales.
- Escribe en español. Sé exigente y concreto: píxeles, tamaños, paletas, tiempos, número de fotogramas, coste de producción.
- Tu documento `propuesta.md` debe incluir: (1) crítica de lo actual con referencias a capturas; (2) objetivo visual con
  referentes concretos; (3) propuesta técnica y de producción (cómo se hace en este proyecto, por código, a escala de 90 cartas
  y 40 enemigos); (4) cómo conecta tu área con las demás (el mundo debe sentirse vivo e interconectado); (5) riesgos y lo que
  descartarías; (6) prueba de concepto y qué demuestra; (7) estimación de trabajo dividida en paquetes independientes.
- Termina con un resumen de ≤ 300 palabras en tu respuesta final.
