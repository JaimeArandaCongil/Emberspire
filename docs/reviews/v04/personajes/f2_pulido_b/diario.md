# F2-PULIDO-B · Diario (reserva de C14: cabeza del martillo junto a las botas)

Nube Linux, Godot 4.7.2, xvfb. Archivos: `scripts/art/defs/hero/fogonera.gd`, su horneado (`assets/baked/hero/fogonera*`,
entrada `fogonera` de `assets/baked/manifest.json`) y `tests/art/out/qa/fogonera_qa.png`.

## Causa
En `idle` la muñeca (56,5, 58,5) dejaba el centro de la cabeza en ≈ (62, 80), con el borde inferior en y ≈ 85: la cabeza tapaba la
puntera de la bota cercana (borde superior en y 80, x 50–62). Mismo brazo en `cast`, `toss_back`, `toss`.

## Cambio (sólo articulaciones de pose; sin piezas ni colores nuevos)
- Brazo cercano: el antebrazo se adelanta (muñeca 62, 55; mano a x ≈ 61) y el martillo se inclina ~26° hacia delante
  (punto 70,5, 72,5). La cabeza queda por delante y por encima de la puntera; el mango cruza en diagonal.
- Igual en `cast` y `toss_back`; `toss` con el mismo gesto 1 px más bajo; `hurt`/`hurt2` con el mismo antebrazo algo menos
  adelantado (retroceso), para no abrir salto. `die1`, ataque y hombro sin tocar.
- Se calculó antes la distancia geométrica cabeza–bota (polígonos de `_hammer` y `boot_f`): antes −1 (solapadas), ahora 5,6.
- 74 px + moño sin cambios (bbox `idle` f0: y 12–89; el ancho pasa de 73 a 83 en x por el martillo adelantado).

## Medida (hueco horizontal transparente mínimo entre pierna y martillo, filas 76–89, horneado)
| | f0 | f1 | f2 | f3 | f4 | f5 | f6 | f7 |
|---|---|---|---|---|---|---|---|---|
| `idle` antes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `idle` ahora | 6 | 4 | 3 | 2 | 3 | 3 | 5 | 7 |
`cast` 4/4 · `toss` 4/3. Una primera prueba (antebrazo 45°, martillo 24°) dejaba 1 px o contacto en f3–f4 por el vaivén del brazo.

## Socket `hit` (sin saltos)
`idle` 80,70→78,74 · `cast` 79,71 · `toss` 79,71→78,71 · `hurt` 74,73→71,76 · `death` f0 71,76 · `shoulder_in` 80,31→52,17 ·
`recover` 84,75→83,74 (ahora más cerca del reposo que antes).

## Evidencia
- `tools/qa.sh bake --only=fogonera`: 1 horneada, 0 errores.
- `tools/qa.sh all`: QA 1745/0; arte 1 fallo en `test_mv.gd` («las fuentes cambiaron desde el último horneado: ejecuta
  tools/bake_rooms.gd»): ajeno, viene de `bg_act1.gd` sin hornear del agente de salas.
- Recorrido `smoke.tscn` en `/tmp/claude-0/shots_pb` (antes en `/tmp/claude-0/shots_pb_before`): SMOKE OK.
- `recorte_07_x1_antes_despues.png` y `recorte_07_x4_antes_despues.png` (izquierda antes, derecha ahora; px 290–400 × 420–540),
  `hoja_fogonera_qa.png`, `transiciones_x3.png` (idle f0/f3, cast, toss ×2, hurt ×2, shoulder_in, shoulder_out, recover).

## Pendiente / no comprobado
- Transiciones vistas en la tira horneada y en sockets, no en movimiento en juego.
- La cabeza inclinada se lee algo más «hacha» de perfil a ×1; la cara caliente sigue visible.
- El contorno azul de selección de 07 (de `fighter_view`) pasa por el hueco; sin él el hueco es de fondo.
