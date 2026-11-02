# F2-ILUS2 · diario (quema de carta sin alfa)

Entorno: nube Linux, Godot 4.7.2 (`/opt/godot`), xvfb y llvmpipe. Cierre: `tools/qa.sh all` da QA 1745/0 y ARTE 5 suites/0;
`smoke.tscn` (con `SHOTS_DIR=/tmp/claude-0/shots_ilus2`) da SMOKE OK y ningún error salvo `ERR_CANT_OPEN` (audio).

## Qué cambia

`CardView.burn_away(duration)` (`scripts/ui/card_view.gd`) ya no usa `modulate:a` ni el `DISSOLVE_SHADER` de `UI`
(éste fundía con ruido de un píxel y dejaba el texto a medio alfa). Ahora pone a marco, nombre, tipo, texto, orbe y cifra un
material propio (`BURN_SHADER`) que comparte una rejilla de celdas de arte (2×2 px de pantalla) en coordenadas de la carta:

- **Pasos de rampa**: la misma LUT del descarte (`UI.dim_lut(-2)`, sin memoria nueva). En el 10 % de la duración la carta
  baja 2 pasos y en el 35 % baja otros 2 (la LUT se aplica dos veces).
- **Frente de brasa**: ruido de valor a 1/9 de celda (88 %) más un poco de ruido por celda (12 %), y un gradiente de
  abajo arriba (55 %). La llama sube desde el pie. Desde el 12 % de la duración el frente avanza en `BURN_STAGES` = 12
  saltos. Las celdas que quedan detrás del frente se descartan de golpe. Justo delante van fuego 6, luego fuego 4 y luego
  una franja chamuscada (otros −2 pasos).
- **Sin transparencia parcial**: todo píxel con alfa < 0,5 se descarta y el resto sale opaco. Así también se recortan las
  sombras de alfa 0.
- **Fragua**: el nombre y la cifra usaban `UI.fragua_material`. El shader reproduce su regla (el contorno horneado `UI.k` no
  se tiñe). Sin ella, el nombre y la cifra sacaban unos 570 px fuera de paleta.
- La duración no cambia (0,35 / 0,4 / 0,45 s según quién llama) y se devuelve el mismo `Tween` paralelo, así que las cadenas
  `.chain().tween_callback(cv.queue_free)` de `combat_screen` funcionan igual. Al llegar a t = 1 la carta queda oculta.
- No hay escala ni giro nuevos. Los que hay son los del vuelo de `combat_screen`, que son movimiento.

## Dónde se usa `burn_away` (hallazgo)

La quema normal y la quema en caliente con `BurnFX` activo **no llaman a `burn_away`**. Usan `_fly_card_to_forge`: la
carta vuela como `Sprite2D` y desaparece de golpe en la boca, sin alfa. `burn_away` se llama al **agotar** una carta (desde
la mano, 0,45 s, o tras jugarla, 0,4 s) y en el **respaldo sin BurnFX** (quema normal o en caliente, 0,35 s, a escala 0,5
y girada).

## Evidencia

Medí con un arnés temporal (`--script`, en el scratchpad y no en el repo) a `--fixed-fps 60`. Hace esto:
1. Lanza un combate del acto 1, piso 4 (semilla 1234).
2. Captura el fondo con la carta oculta.
3. En cada fotograma cuenta los píxeles que difieren de ese fondo en un recorte de 240×320 alrededor de la carta y cuántos
   de ellos son de paleta exacta (`Palette.all_colors()`).

Los píxeles de otras cosas que se mueven también entran en la cuenta (unos 6 000 al final, todos de paleta).

| Fotograma (agotar, 0,45 s) | f0 | f4 | f8 | f12 | f16 | f20 | f24 | total 28 f |
|---|---|---|---|---|---|---|---|---|
| Antes: % paleta exacta | 92,5 | 92,0 | 88,5 | **67,1** | 80,3 | 100 | 100 | 88,58 % |
| Después: % paleta exacta | 100 | 100 | 100 | 100 | 100 | 100 | 100 | **100,00 %** (417 520/417 520) |

Otros casos (después):
- Quema normal con BurnFX: 99,999 % (4 px fuera de 605 092).
- Quema en caliente con BurnFX: 99,999 % (4 px fuera de 620 187).
- Respaldo normal: 99,997 %.
- Respaldo en caliente: 99,998 %.
- Respaldo en caliente medido a pantalla completa: 100,00 % (38 px fuera de 10,9 M).

Los pocos píxeles fuera vienen del vuelo o de otros efectos. No los he aislado.

- `agota_antes_despues_f0_4_8_12_16_20_24.png`: arriba, el antes (texto translúcido y moteado de un píxel); abajo, el
  después (baja pasos, el frente sube y la carta se consume por celdas).
- `caliente_respaldo_f14_20_24_28_32.png`: quema en caliente sin BurnFX (Mayús + clic dcho. vía `_try_burn(cv, true)`),
  a ½. La carta llega girada a la boca de la Forja y se consume.
- `test_ui` comprueba ahora que `card_view.gd` no contiene `modulate:a` ni `modulate.a`, que la quema pone el material en
  los seis nodos y que en t = 1 la carta queda oculta.

## Pendiente y no comprobado

- La carta en reposo en la mano no está en la cuenta de «antes». Su f0 ya tenía la primera bajada de alfa.
- La quema en caliente con el teclado real no la probé. Llamé a `_try_burn(cv, true)`, que es lo que hace el clic.
- Rendimiento: no lo he medido en GPU. Se usan seis materiales durante menos de 0,5 s. Es un evento puntual, dentro de la
  carta (≤ 80×112 px de arte), y queda bajo el presupuesto.
- `UI.DISSOLVE_SHADER` sigue en `ui.gd` (fuera de mi paquete) y `_frame_mat` sigue creándose. Si nadie más los usa, se
  pueden retirar.
