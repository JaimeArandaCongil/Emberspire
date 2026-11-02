# F2-VIDA4 · diario (destello del jefe por pieza, Quemadura a 1/4, cola de flotantes y dorso en paleta)

Entorno: nube Linux, Godot 4.7.2, xvfb y llvmpipe. Herramienta: `tests/art/vida_capturas.tscn` a `--fixed-fps 60` con los modos
`jefe`, `estado` (ahora Q0/1/3/9 con el reposo congelado), `cola` (nuevo) y `descarte`. El **antes** se hizo con mis cinco archivos de
código de `HEAD` y el atlas nuevo de F2-JEFE2 (`b51a8ba`); el **después**, con los actuales. Cifras en `mediciones.json`.

Cierre: `tools/qa.sh all` da QA 1745/0 y ARTE 5 suites/0. `smoke.tscn` da SMOKE OK con 29 capturas y ningún error salvo
`ERR_CANT_OPEN` (audio).

## 1 · #2: destello del jefe sólo en la pieza golpeada (`jefe_destello_antes_despues_f9-16.png`, `jefe_tobera_x3_f9-13.png`)

- **Causa 1: el lavado.** Tras el blanco, `flash_steps` (+3, +2, +1 durante 150 ms) se aplicaba a todo el cuerpo. Medido en el antes,
  la luminancia de la caja pasa de 66 a 123 y la de las patas de 64 a 84, y el lavado dura 9 fotogramas.
- **Causa 2: el blanco sólo pillaba media tobera.** `flash()` fijaba el punto con el socket de `idle`, pero `shake()` cambia a `hurt`
  justo después, así que el blanco quedaba desplazado unos 4 px. Ahora `shake()` y `_process` lo recalculan.
- **Shader** (`palette_lit`): `in_piece` decide el blanco y la subida. Fuera de la pieza sólo hay `flash_rest_steps` (1) mientras dura
  el blanco. Las criaturas (radio < 0) se comportan igual que antes.
- **Jefe** (`FLASH_BOSS_STEPS` = +2 durante 33 ms): en el f10 la tobera sale blanca y el resto sube 1 paso; en f11 y f12 sólo la
  tobera sube 2 pasos; desde el f13 no queda nada. Las patas se quedan en 63 (frente a 84 en el antes).
- **Atlas de F2-JEFE2**: medí las anclas en el atlas. Las de la tobera están a 1, 10, 20 y 30,3 px del socket; la siguiente es un
  remache a ≥ 36 y la cabeza empieza a ≥ 52. Subí `FLASH_PIECE_R` de 26 a **34**: 380 px blancos (la tobera entera) frente a 227.

## 2 · #3: Quemadura legible a 1/4 (`quemadura_0_1_3_9_x2_y_1de4.png`)

- Desde `StatusFX.SCORCH_HOT` = 3:
  - las lenguas miden 5 px (Q3–5) y 6 px (Q6+) y tienen forma de gota de 4 → 3 → 2 → 1 px, con los flancos 1 paso más claros;
  - el borde superior y las grietas dibujadas suben 1 paso;
  - `emit_boost` pasa a 2, así que las grietas del cuerpo suben 1 paso más (la parrilla de la cara llega a blanco cálido).
- Q1 y Q2 no cambian; Q1 da cifras idénticas a las del antes.
- **Medición.** El reposo está congelado en el f0 y cada Quemadura se resta de Q0 en el mismo fotograma. A 1/4, los píxeles de fuego
  claro pasan de **16 a 34** en Q3 y de **22 a 40** en Q9; los píxeles distintos, de 78 a 129 en Q3. A ×1, el fuego claro pasa de
  52 a 116 en Q3.

## 3 · #4 / N1: flotantes en cola por encima de la cabeza (`cola_flotantes_antes_despues.png`, `10b_antes_despues.png`)

- **`FighterView.float_anchor()`**: base de la cola por encima de la caja del cuerpo, de la intención (con su vaivén) y del aviso de
  robo. **`float_ceiling()`**: límite superior, que es la banda del jefe o la barra superior.
- **`combat_screen._float_over()`**: los 12 flotantes ligados a un luchador (daño, bloqueo, estados, curación, «+Hollín», Ascuas,
  Espinas) pasan por la cola.
  - Salen de uno en uno cada 150 ms.
  - El nuevo entra abajo y los anteriores saltan arriba lo justo para dejar 4 px de aire.
  - Si uno no cabe bajo el techo, se retira el más viejo.
- **`UI.float_text`** devuelve la etiqueta y admite anclaje inferior, `lift` y `ceil`. En la cola sube de forma lineal, para que un
  texto nuevo no alcance al anterior. Las llamadas antiguas funcionan igual.
- **Medición** (rectángulos de las etiquetas, 120 fotogramas): en el antes, 50 fotogramas con solape y 205 flotantes sobre el
  cuerpo; en el después, **0 y 0**, y 0 sobre la intención en ambos casos.

## 4 · N5: 0 colores ajenos

- La causa no era el filtrado: el proyecto ya muestrea en nearest. Era el dorso fantasma `card_back_small` del arte legado, pintado
  con `8a4a2a` y `5a2a1a` (el «+Hollín» que vuela al descarte).
- Ahora se usa el dorso de la pila (`HudArt.pile_image`), que está en paleta. El giro se mantiene: con nearest sólo elige píxeles.
- Resultado: la 10b del recorrido pasa de 249 px ajenos a **0** (100 % de paleta). El barajado usa el mismo dorso.

## Tests

`test_ui.gd` (sólo añado líneas al final) comprueba:
- `flash_rest_steps` y que la subida del jefe sea ≤ 2 f;
- lenguas de 5–6 px en Q3 y Q9;
- que no queden flotantes sobre el centro del cuerpo ni `card_back_small` en el combate.

## Pendiente y no comprobado

- `ffe173` (6–8 px) viaja con la carta jugada y aparece también en el descarte. Es una mezcla de `card_view.gd`, fuera de mi paquete,
  y ya estaba en el antes.
- El rótulo «Turno enemigo» (`combat_screen.gd:907`) sigue saliendo, aunque el dictamen lo daba por retirado. Tapa la cola unos
  300 ms si sube mucho. No lo he quitado: es una decisión de dirección.
- El dorso fantasma ahora es el gris de la pila (17×23 frente a 15×21): cambia de aspecto.
- No he visto el destello del jefe en fase 2 ni con el jefe volteado, ni la cola con el jefe y dos ácaros en GPU real.
- Los flotantes de las pantallas fuera del combate (Forja, recompensas) no cambian.
