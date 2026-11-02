# F2-VIDA5 · diario (rótulo «Turno enemigo» breve en la banda superior)

Entorno: nube Linux, Godot 4.7.2, xvfb y llvmpipe. El **antes** es `combat_screen.gd` de `HEAD`; el **después**, el actual. Cifras
en `mediciones.json`; tira en `turno_enemigo_antes_despues.png`.

Cierre: `tools/qa.sh all` da QA 1745/0 y ARTE 5 suites/0. `smoke.tscn` da SMOKE OK con 29 capturas y ningún error salvo
`ERR_CANT_OPEN` (audio).

## Cambio (`scripts/ui/screens/combat_screen.gd`)

- `_end_turn` ya no llama a `_banner` (Fragua ×4, pantalla y 152–216, 633 ms). Llama a `_enemy_turn_tag()`:
  - placa opaca `plate 1` con borde `plate 5`, texto Fragua ×2 en `blood 4` (contraste ≈ 6,6:1);
  - pantalla y 50–82 = arte y 25–41, dentro de la banda 22–44; 144×32 px; posiciones pares;
  - entra en 2 pasos (media altura 33 ms → entera) y sale igual; texto sólo a altura entera; sin alfa;
    mantiene `TAG_HOLD` = 0,4 s; total medido **450 ms** (antes 633).
- Colocación: el primer centro libre de `TAG_CENTERS` (640, 496, 784, 352, 928, 1072) que no pise flotantes (`z_index` 100 de
  `_fx_layer`), intenciones de enemigos (la del jefe incluida, x ≈ 932) ni la fila de reliquias (`_relic_row`, y 34, que ya
  invade la banda por la izquierda). Si no hay hueco, no sale.
- Guarda: durante la espera, `_tag_guard` comprueba cada fotograma; si un flotante o intención lo alcanza, se quita de golpe.
- Los demás banners (jefe, Élite, Tu turno, Fénix, Derrota) no cambian.

## Medición (120 f del turno enemigo, 60 fps)

| Caso | Antes: f con flotante / intención | Después |
|---|---|---|
| 3 enemigos | 27 / 0 | **0 / 0** |
| Jefe | 0 / 0 | **0 / 0** |
| 3 enemigos + estrés (flotantes extra cada 4 f) | 37 / 0 | **0 / 0** |
| Jefe + estrés | 0 / 0 | **0 / 0** |

## Tests (`tests/art/test_ui.gd`, al final)

Banda (44–88 de pantalla), rejilla ×2, duración ≤ 0,6 s, que «Turno enemigo» no vuelva a `_banner` y contraste ≥ 4,5:1.

## Pendiente y no comprobado

- La herramienta de medida vive fuera del repo (no es mi archivo `vida_capturas.gd`); conviene añadirla como modo `rotulo`.
- La guarda no se ha visto disparar: en ningún caso medido llegó un flotante a la banda mientras estaba el rótulo. En la 10b
  del recorrido un «+9» llega a y ≈ 120, ya sin rótulo.
- «Tu turno» sigue en el banner grande (y 152–216); no medido contra flotantes.
- Ajeno: en el jefe, un flotante «6» pisa la barra de ayuda (ya pasaba antes).
- No visto en GPU real ni con jefe en fase 2 o con 4+ reliquias más anchas que la fila medida.
