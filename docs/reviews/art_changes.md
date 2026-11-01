# Cambios de arte v0.3 (implementación de la revisión)

Archivos tocados (propiedad de arte): `scripts/autoload/art.gd` (reescrito), `scripts/ui/ui.gd`, `scripts/ui/card_view.gd`,
`scripts/ui/fighter_view.gd` (reescrito), `scripts/ui/pixel_font.gd` (nuevo), `scripts/ui/screens/title_screen.gd`,
`scripts/ui/screens/rest_screen.gd`, la parte visual de `scripts/ui/screens/combat_screen.gd`, `scripts/ui/main.gd`
(sólo `shake`/`_process`, `fly_embers`, `toast`), `scripts/ui/screens/forge_screen.gd` (sólo `_build_left`), `docs/ART_BIBLE.md`.
Herramientas de revisión en `tests/_review_art/` (`sheet.tscn` exporta todas las piezas nuevas a `out/new_*.png`).

## Qué se hizo

### Fase 0 — rejilla y valores
- Regla única: **mundo ×4, interfaz ×2**. Se eliminaron las escalas ×2.5, ×5, ×6, ×7, ×8, ×9, ×10, ×0.4 y ×0.6 en las pantallas de arte.
- `FighterView`: sin `scale` ni `rotation`. El desplazamiento lógico `_off` se ajusta a 4 px cada fotograma. La respiración son 2 fotogramas
  (`crouch_image`), y los gestos van por poses.
- `main.shake(amount, dir)`: sacudida direccional con caída exponencial, cuantizada a 4 px y con un máximo de 24 px.
- Mano de cartas: sin rotación ni escalado al pasar el ratón. Abanico en arco por desplazamiento, con posiciones en pasos de 2 px. El "no" de una carta es un vaivén horizontal.
- Partículas a escala de arte (4–8 px) con rampa de fuego escalonada (`GRADIENT_INTERPOLATE_CONSTANT`).
- Valores: muros más oscuros y de bajo contraste; rampas de monstruo de 5 tonos con desplazamiento de tono y luz de fuego lateral.

### Personajes
- **Heroína** 24×36 + brazo 10×20 (ASCII de la revisión), compuesta en un lienzo 52×48 con 10 poses: `idle`, `idle_b`, `windup`, `smear`, `strike`, `recover`,
  `cast`, `toss_back`, `toss` y `hurt`. El brazo se gira **al generar** con un RotSprite simplificado (EPX ×4 → giro → muestreo). `Art.player()` devuelve
  el reposo 24×36 con el brazo incluido. `Art.player_arm()` queda obsoleto y devuelve una textura vacía.
- **Monstruos**:
  - Bases a mano mirando a la izquierda: golem, knight, hound, bird, serpent, imp y crawler.
  - Jefes a mano: boss_king, boss_bellows, boss_queen, boss_hydra, boss_heart y boss_frost. Se amplían ×2 con EPX sobre la rejilla de caracteres antes de sombrear, y quedan en 60–72 px de arte.
  - Élites: la misma base, `forma@2` (EPX ×2).
  - Simétricas redibujadas para criaturas frontales: slime, bat, eye, totem, mite, wraith, priest y moth. Mite, bat y moth se amplían ×2.
  - Semilla: piezas opcionales, grietas emisivas a lo largo de los pliegues `3` y una ligera deriva de tono.
  - Ojos de al menos 2×2 con halo de 1 px en la capa emisiva.
  - Poses `crouch` y `stretch` sin escalar, y metadato de vuelo (`monster_lift`).

### Animación y efectos (tiempos en `ART_BIBLE.md`)
- Martillazo por fotogramas (carga 140, pausa 40, estela 33, golpe 90, recuperación).
- Embestida enemiga: agachado 160 → estirado 60 → vuelta 240.
- Gesto para intenciones que no son ataque.
- Huida (`flee()`, para el evento `fled`): salta hacia atrás y se desvanece con humo gris, sin Ascuas.
- Impacto estándar:
  - destello blanco de 1 fotograma y luego el color del bioma;
  - empuje direccional de 3–5 px de arte;
  - hitstop de 50/80/120 ms;
  - sacudida direccional;
  - números en fuente pixel con "pop" de escala entera.
- Quemar: la carta vuela **por detrás** de la heroína hasta la boca del horno y arde al llegar. El horno se aplasta 1 px y su boca sube al máximo. El parámetro `hot` añade chispas y sacudida.
- Jefes: el cuarto se oscurece, aparece un halo propio y cae polvo del techo.
- Parallax del primer plano (pilares, cadenas, estalactitas y carámbanos) de 0–2 px de arte según el ratón.

### Cartas
- Ventana con forma por tipo: hoja achaflanada, rectángulo remachado, óvalo con rayos, arco con rejilla de horno y rectángulo.
- Cuerpo de **pergamino** con tinta oscura. Los colores de resalte se remapean para leerse sobre el pergamino.
- Gema de rareza de 7×7 y Maestría como ascuas abajo.
- Ilustración 60×30 a ×2: la misma rejilla que el marco, así que ya no se mezclan escalas. Fondo en bandas, efecto por tipo, icono EPX 24×24 con sombra y máscara de ventana.
- Nombre en fuente pixel ×2 si cabe; si no, fuente lisa. El coste va en fuente pixel.
- Dorso pequeño 15×21 para pilas y fantasmas.

### Mundo
- Tres composiciones de fondo distintas:
  - **Hollín**: ladrillo con hollín, arco-horno central y ventanas con brasas.
  - **Escoria**: roca irregular, goteos emisivos y jaulas.
  - **Ceniza Helada**: bloques con escarcha, carámbanos, luna, nieve en el suelo y acumulada.
- Luz de antorcha en anillos sin tramado. Suelo con punto de fuga y sin la línea central. Viñeta en escalones.
- Forja 64×56 (cúpula radial, arco de dovelas, brasas en 4 fotogramas, llamas según el calor, yunque) y horno de combate 36×34 animado.
- Hoguera 32×24 con 4 fotogramas, que sustituye al icono `log` ×10.
- Nuevas API: `Art.event_art(id)` (96×48), `Art.door_art(kind, biome)` (28×36), `Art.logo()`, `Art.icon_big(id)` y `Art.background_near()`.

### Interfaz
- Fuente pixel 5×7 proporcional generada en runtime (`PixelFont`), con acentos españoles y contorno horneado. Sólo se usa a escala entera.
- `UI.label` la aplica desde 20 px. Hay además `UI.plabel` y `UI.pixelize`, y los botones de ≤ 26 caracteres la usan.
- Logotipo dibujado y animado con un pulso en pasos.
- Bordes de panel en múltiplos de 2 px.
- Iconos rediseñados: `log`, `coal`, `smoke` (con lo que también cambian `choke`, `wet_ash` y `breath`), `lizard`, `fang` y `coin`, que ahora es un sprite propio.

## Antes → después por captura
| Captura | Antes | Después |
|---|---|---|
| 01_title | Texto de sistema con contorno; heroína ×9; horno ×5 | Logotipo pixel ×6, heroína y forja ×4 sobre el suelo, forja animada |
| 02_forge | Horno de pizza ×5 | Forja 64×56 ×4 con yunque y chimenea (tapada en la captura por un modal del tutorial nuevo) |
| 07_combat | Gólem gris sobre muro gris; heroína chibi; horno ×2.5 | Siluetas legibles con luz de fuego; heroína 3/4; horno animado ×4; parallax |
| 09_burn | La carta se disolvía delante de la cara de la heroína | Vuela por detrás y arde en la boca del horno |
| 10_swing | Brazo girando como una aguja | Pose de carga y golpe por fotogramas |
| 14/16/18 jefes | Del tamaño de la heroína | 60–72 px de arte con escenografía (oscurecido, halo, polvo) |
| 17_act3 | Ruido blanco tramado | Hielo sin tramado; élite ×2 con presencia |
| 20_rest | Icono `log` ×10 | Hoguera animada; opciones con iconos EPX |
| 23_cards | Clip-art ×4 en un marco ×2; texto claro sobre marrón | Ventanas por tipo, pergamino, misma rejilla |

## Pendiente / para el director
- **`antesala_screen.gd` y `map_screen.gd` (tuyos)** siguen escalando la heroína ×5 y deformándola a 36×48. Deberían usar
  `Art.player()` (24×36) a ×4 o `Art.player_pose("idle")`, y quitar el `player_arm()` rotado, que ya está vacío.
  Las puertas pueden usar `Art.door_art(kind, act)` a ×4 y los eventos `Art.event_art(id)` a ×4 (384×192).
- `forge_screen.gd` (fuera de `_build_left`) aplica un aplastamiento por `scale` al hacer clic en el horno. Habría que cambiarlo por un desplazamiento
  de 4 px o por `Art.forge_sprite(1.0, frame)` durante 100 ms.
- La parte visual de `combat_screen.gd` está terminada. Ya puedes añadir la quema en caliente, la vista previa y el tutorial.
- No hay monstruos únicos por élite (comparten base ×2). Si da tiempo, añadir piezas de élite (cuernos, hombreras) como capa opcional.
- Textos de carta muy largos (p. ej. "Chispa Volátil") desbordan a 11 px. Conviene acortarlos en `card_db` o subir el alto del pergamino.
- Paneles 9-slice con bisel pixel (punto 21 de la revisión) y luces `PointLight2D` (punto 26): no hechos.
- `tests/run_tests.sh`: 0 SCRIPT ERROR y todas las comprobaciones de arte pasan. Fallan 5 comprobaciones de diseño (polvo estelar, renacer, pactos de PV de jefe y
  maestría al jugar o en caliente), todas de tu área. Smoke: `SMOKE OK`.
