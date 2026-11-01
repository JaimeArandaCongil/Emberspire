# Ronda 1 · Mundo vivo (MV)

## C1 · Resolución: **acepto 640×360 ×2**

**Motivo.** En el keyframe del director y en el mock de personajes, los personajes son lienzos de 96 px a 640. Un fondo a 320 ×4 a su lado tendría la mitad de densidad: dos rejillas en pantalla. Y a 320 no cabe detalle *dentro* de cada pieza.

**Prueba.** `tests/_review_art/v04/mundo_vivo/poc_640.gd` hereda mi motor y redibuja de forma nativa la mitad izquierda del Acto 1 (400×272):
- `out/a1_640_crop.png`: a ×2, como se verá a 1280×720.
- `out/a1_320_vs_640.png`: ambas versiones a la misma escala de pantalla.
- `out/anim_brasero640_8f_x3.png`: el brasero en 8 fotogramas.

**Qué se conserva**
- **Material + paso**, que no depende de la resolución: las mismas 9 rampas de 11 pasos.
- **Luz pieza a pieza**: se muestrea en el centro de cada ladrillo (16×7), sillar (32×20) o losa (44). El brasero da ahora 6 bandas, hasta 88 px, y cada salto sigue cayendo ladrillo a ladrillo.
- **La torre-chimenea**, intacta. A 640 se gana un tiro con ladrillo de 5 px, nervios, pasarela con celosía y un caldero que ya se lee como objeto.

**Qué cambia (reglas nuevas)**
1. **Detalle sólo donde llega la luz.**
   - El canto iluminado (+1) sólo aparece si la pieza recibe 2 pasos o más.
   - Los desconchones de 2–4 px y el grano son estables y no superan el 5 %.
   - La sombra queda plana. Es la defensa contra el ruido a 640.
2. **Tamaños.**
   - Llama: de 13×18 a 27×38, con 4 lenguas y contorno `7a1a16`.
   - Cuenco del brasero: de 11 a 23 px, con labio.
   - Conducto: de 5 a 10 px, con juntas, hollín y bridas con tornillos.
   - Herramientero: con sombra proyectada a −2 px.
3. **Fotogramas.** Se mantienen: brasero en 8 a 100 ms, escena en bucle de 16 a 110 ms. Sube la amplitud:
   - crisol de ±3 a ±7 px, más suave;
   - humo en 6 bocanadas que forman columna;
   - 5 pavesas por brasero, con estela de 2 px las rápidas.
4. **Parallax.** L0 +1, L1 +2 y L4 −4 px de arte: el mismo recorrido en pantalla, en pasos la mitad de bruscos.
5. **Presupuesto en movimiento.** El mismo 6 % de pantalla (unos 13.800 de 230.400 px de arte). Una chispa de 1 px de arte mide ahora 2 px de pantalla: más fina.
6. **Coste.** Un fondo a 640 cuesta unos 1,5 s por estado en GDScript, así que **también cedo en C7: PNG versionados** con test de frescura.

## C2 · Luz: **acepto el shader único de TEC, con mi muestreo por pieza como dato**

Respuesta al director: **sí**, un shader cumple (a) y (b) en `gl_compatibility` (GLSL ES 3.0, `texelFetch`, arrays de uniforms), siempre que **lea el centro de la pieza y no el píxel**.

Textura del fondo (RGBA8):
- **R** = fila de material en la LUT.
- **G** = paso base, con las luces estáticas de la sala ya horneadas por pieza. Los 2 bits altos marcan junta (−1) y canto (+1 si hay 2 pasos o más).
- **B/A** = desplazamiento con signo al centro de la pieza.

El shader calcula `paso = G + global + dinámico(uv + BA)`:
- *dinámico* son 2–4 luces en uniforms (antorcha, pico de quemar, crisol, ascua de la heroína), cuantizadas y evaluadas en el centro de la pieza;
- *global* cubre el calor, los PV bajos y la victoria;
- si los pasos fríos superan a los cálidos, usa la fila COLD.

Así el ladrillo se ilumina pieza a pieza también en tiempo real, por una lectura extra por fragmento.

- **Los 4 niveles de calor horneados del director:** sobran en fondos (el calor es `global` más el radio de la luz del tiro). Quedan **sólo como respaldo** si falla el portátil más débil.
- **Mis sprites de luz aditiva escalonada:** **los retiro**. Las luces móviles y los VFX de quemar pasan al shader.

## Mapa de UI (Torre en corte)

Es la mejor idea del panel para mi concepto. Es mi transición vertical convertida en pantalla, así que la adopto: el paso de piso es la cámara subiendo por el corte. Para que *sea* la torre-chimenea necesita:
1. **El tiro en el eje.** Una columna central que brilla desde abajo según la producción de la Forja, con las galerías y puertas a su alrededor.
2. **La Forja en la base** y un calor que se apaga al subir: los actos 1, 2 y 3 se leen como gradiente de temperatura.
3. **Exterior en noche helada**, no atardecer violeta. El contraste cálido/frío es el tema.

Objeción: los brillos tramados en ajedrez de las puertas contradicen el «sin tramado de relleno». Mejor bandas por pasos.

## Keyframe del director

Su estructura de valores es la que defiendo, y su **horno con chimenea de ladrillo hasta el techo es literalmente la torre-chimenea**. Propuesta de fusión:
- Adopto su horno grande. Mi conducto de cobre pasa a ser la toma del fuelle que entra en él.
- Su corredor de arcos en perspectiva sería un **módulo** para las salas de paso. La sala insignia (élites y jefes) se asoma al tiro: la galería con parapeto de mi prueba, donde el jefe sale del vacío.
- Sus estandartes llevan el icono de la UI: deberían ser emblemas tejidos del mundo.
