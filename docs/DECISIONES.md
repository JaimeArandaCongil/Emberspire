# Decisiones vigentes (arte v0.4)
Registro breve; el razonamiento está en `docs/reviews/v04/DEBATE.md`. Dirección añade aquí cada decisión nueva en el momento de tomarla.

| Tema | Decisión |
|---|---|
| Rejilla | Mundo e interfaz 640×360 ×2. Excepción única: Pavesa 6×9 a ×1 (cuerpo de carta y tooltips). Mini 3×5 ×2 para etiquetas; Fragua 5×7 para títulos y cifras |
| Luz | Un shader `palette_lit`: textura índice + LUT + desplazamientos de paso por estado, evaluados en el centro de pieza. Sin Light2D ni halos suaves |
| Arte horneado | PNG versionados en `assets/baked/` con manifiesto y test de frescura. El estado del juego va en el shader, nunca en rehorneos |
| Carta | 80×112 nativos, ventana 68×46. En reposo asoma 64 px de arte |
| Ilustraciones | 93 composiciones únicas; niveles A (~30), B (~58), C (5). Nunca se repite fondo+encuadre+sujeto+posición |
| Personajes | Motor de rig único, piezas + sellos a mano. Ojos, manos y remaches siempre sellados. Sin recoloreados |
| Jefes | 150–200 px de cuerpo, ≤ 280 de ancho; multiparte con cambio de fase |
| Heroína | 66 px, diseño de `reviews/v04/personajes/fogonera_final.md`; pelo y martillo siguen al calor actual |
| Disposición de combate | HUD y 0–15 · banda de intención de jefe y 22–44 · suelo y 264 · cartas en reposo desde y 296 · Forja x 8–112 · heroína x 128–196 · enemigos x 300–632 (centros 1: 466; 2: 396/540; 3: 350/460/572) · intención 18 px sobre la cabeza |
| Mundo | La Torre es el tiro de la Forja. Sala normal: corredor de arcos + taller. Élite y jefe: galería abierta al tiro. El mapa es el corte de esa chimenea |
| Onda de quemar | **Aceptada** al 16–19 % de píxeles en movimiento, como evento puntual fuera del presupuesto del 6 % |
| Variantes de sala | 4 de sala normal y 2 de tiro, cada una para ciclo I y ciclo II+ (ciclos posteriores usan II). Piso → variante por hash determinista. Se hornean en `assets/baked/rooms/` |
| Brasero de la sala de tiro | Se aparta del hueco del tercer enemigo (centro x 572) |
| Flujo de agentes | Un agente nuevo por paquete, 2–3 a la vez, commit al cerrar. Modelos en `.claude/agents/` |
| Modelo para producir arte | **Opus**. Sonnet no superó la prueba ciega (criatura 4,5 frente a 6 y 7,5; ilustraciones 6 frente a 7,5; `reviews/v04/director/prueba_ciega.md`). Sonnet sólo para conexiones, tests y documentación; Haiku para QA mecánica |
