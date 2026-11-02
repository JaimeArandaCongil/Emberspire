# F2-PULIDO-D · Diario (contraste a 1/4 de `flame_moth` y `soot_golem@sooty`)

Nube Linux, Godot 4.7.2, xvfb. Archivos: `scripts/art/defs/creatures/flame_moth.gd`, `scripts/art/defs/creatures/soot_golem.gd`,
su horneado (`assets/baked/creatures/flame_moth*`, `soot_golem@sooty*`) y `tests/art/out/qa/flame_moth_qa.png`.
El gólem base (`soot_golem_prev/idx`, `soot_golem_qa.png`) sale idéntico byte a byte (comprobado con `cmp`).

## Método
Métrica oficial: `docs/reviews/v04/mundo_vivo/f2_sala2/contraste.py` sin cambios (gris a 1/4, figura frente a anillo de 2
celdas, mínimo sobre los 6 fotogramas de `idle` y las 8 salas normales, huecos reales del acto 1). `diag_contraste.py.txt` es
la misma cuenta con la media de figura y de anillo y el mínimo por fotograma. Antes y después se midieron contra una copia
de `assets/baked/rooms` tomada al empezar (otro agente estaba horneando salas) y otra vez con las salas vivas al terminar.
Las cifras coinciden.

## Diagnóstico
En los dos casos la figura es más clara que el anillo (muro): figura ≈ 0,19–0,21 frente a anillo ≈ 0,10–0,115. Oscurecer
no sirve (habría que bajar de 0,02). Hay que subir el valor medio de la figura unas 0,02.

## Cambios
- **`flame_moth`**: las rampas de `cloth` de las alas suben un paso. Cercanas 3/5/7 → 4/6/8 y lejanas 1/3/4 → 2/4/5.
  Ocelos (`fire`), cuerpo, silueta, poses y lienzo no cambian. Sigue siendo roja: tono medio del ala 4° → 7°, saturación
  HLS 0,56 → 0,59. El murciélago (`cinder_bat`) queda en 24° y 0,18, así que la diferencia de saturación es 0,41.
- **`soot_golem@sooty`**: la ranura `soot`, que sólo usa la máscara `brick → soot` de la variante, pasa de `rock_soot`
  (marrón oscuro) a `ash` con `soot_grain` y pasos limitados a 4–6. Es un hollín gris mate de valor medio. La máscara
  sube de 0,45 a 0,5, así que el ladrillo sigue a la vista en la joroba, en la chimenea y en la cabeza. Es un cambio de
  material de la variante, no un recoloreado. No hay ningún hex nuevo.
- Pruebas descartadas en el gólem: `ash` sin límite (0,102, el brazo queda casi blanco y parece ceniza, no hollín);
  límite en 6 (0,096) o en 5 (0,092); manchas de hollín `noise` en las piernas de carbón (0,097, queda a camuflaje);
  máscara a 0,62 (0,106, se pierde casi todo el ladrillo y con él la identidad de horno).

## Medida (métrica oficial, mínimo sobre salas y fotogramas)
| Hueco | Antes | Después |
|---|---|---|
| `flame_moth` @396 | 0,099 | **0,119** |
| `flame_moth` @540 | 0,093 | **0,113** |
| `soot_golem@sooty` @396 | 0,081 | **0,108** |
| `soot_golem@sooty` @466 | 0,092 | **0,120** |

Mínimo por fotograma, f0–f5, después: polilla @540 0,119 · 0,119 · 0,118 · 0,119 · 0,114 · 0,113; gólem tiznado @396
0,110 · 0,112 · 0,114 · 0,114 · 0,111 · 0,108. El resto de criaturas da las mismas cifras que en el diario de F2-SALA2.

## Evidencia
- `antes_despues_flame_moth.png` (@540, sala 5, f5) y `antes_despues_soot_golem_sooty.png` (@396, sala 6, f5). Son los
  peores casos. De izquierda a derecha: color antes, color después, gris a 1/4 antes y gris a 1/4 después.
- `tools/qa.sh bake --only=flame_moth,soot_golem`: 2 horneadas, 0 errores. `tools/qa.sh all`: QA 1745/0, arte 5 suites/0.
  En una pasada intermedia `bake_rooms --check` salió en rojo porque otro agente estaba cambiando las fuentes de las
  salas. No es de este paquete.
- Recorrido `SHOTS_DIR=/tmp/claude-0/shots_pd`: SMOKE OK, sin errores salvo `ERR_CANT_OPEN` (audio). Revisada la captura
  18b: la polilla se lee roja junto al murciélago gris.
- Hojas revisadas: `flame_moth_qa.png` y el atlas completo de `soot_golem@sooty` (reposo, cast, ataque, golpe y muerte).

## Pendiente / no comprobado
- `soot_golem@sooty` no sale en el recorrido. Sólo se revisó en la hoja horneada y en la composición de la métrica.
- El gólem base mide 0,078/0,089 en esos mismos huecos. No está en la lista oficial y el encargo pedía no cambiarlo, así
  que lo decide dirección.
- El hollín es gris y más claro que el ladrillo en sombra. Es una decisión de valor que conviene que confirme dirección.
