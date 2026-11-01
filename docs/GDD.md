# Game Design Document — EMBERSPIRE v0.2

## 1. Recursos
| Recurso | Ámbito | Se obtiene | Se gasta |
|---|---|---|---|
| **Ascuas** | Permanente (hasta Renacer) | Quemar cartas, matar enemigos, oleadas de victoria, generadores, clic en la forja | Generadores, Arsenal, Grimorios, Yunque Errante (tienda) |
| **Braseros** | Permanente para siempre | Récord de piso alcanzado | — (multiplican producción +10%/piso) |
| **Polvo Estelar** | Permanente para siempre | Renacer en Ceniza | Talentos (el total ganado da +10% producción cada uno) |
| PV, Energía, Quemas | Por combate / run | Arsenal, reliquias | Jugar cartas, recibir daño |

## 2. Combate
- Energía 3, robo 5, mano máx. 10. Turnos alternos con **intenciones** visibles.
- **QUEMAR** (clic derecho o seleccionar + horno): exilia la carta del combate, otorga Ascuas
  `(4 + 3·coste) · (1 + 0.2·piso + 0.02·piso²) + 3 s de producción` y ejecuta su efecto *Al quemar*. Límite: 1 por turno (ampliable).
- Cartas **Combustible**: no jugables, existen para ser quemadas (Leña, Carbón, Pólvora, Pluma de Fénix…).
- Las cartas de estado enemigas (Hollín) son combustible: el jugador convierte el ataque enemigo en economía.
- Estados: Fuerza, Débil (−25% daño), Vulnerable (+50% daño recibido), Quemadura (pierde PV al inicio de turno y baja 1).

## 3. La Torre
- Cada piso ofrece **3 puertas** (Combate, Élite, Hoguera, Yunque Errante, Misterio, Tesoro). Piso 10k = Jefe. Piso 10k−1 = descanso.
- Actos: Hollín (1–10), Escoria (11–20), Ceniza Helada (21–30). Después la torre **cicla** con enemigos mutados
  (paleta y forma nuevas por semilla) y escalado exponencial → techo infinito.
- Morir o retirarse devuelve a la Forja conservando todas las Ascuas ganadas.

## 4. La Forja (incremental)
- 7 generadores (Chispa → Corazón del Mundo), coste ×1.15 por unidad, ×2 producción a 25/50/100 unidades.
- **Arsenal**: mejoras permanentes de combate (PV, quemas, robo, energía, fuerza inicial, templado del mazo inicial…).
- **Grimorios**: desbloquean arquetipos de cartas en las recompensas (Pira, Yunque, Forja, Ceniza, Crisol, Solar).
- **Producción offline** hasta 8 h (24 h con talento).
- **Renacer en Ceniza** (requiere ≥1 de Polvo): reinicia Ascuas y generadores. Conserva Arsenal, Grimorios, Braseros.
  Polvo = ⌊√(Ascuas de esta vida / 1M) · (1 + récord/50)⌋.

## 5. Puentes entre Torre y Forja (v0.2)
### 5.1 Maestría
- Cada carta quemada en la Torre suma 1 punto de Maestría a **esa carta (por id) para siempre** (+1 con el talento
  Memoria Ígnea, ×2 con el Diario de la Herrera). Umbrales: 2 / 6 / 15 / 35 / 80 → niveles 1–5.
- Cada nivel: **+10%** a los números escalables de la carta (daño, bloqueo, quemadura, curación…, con redondeo) y
  **+20%** de Ascuas al quemarla. Nivel 5 = ×1.5 números y ×2 Ascuas.
- Visible en el marco (marcas en el lateral), en el tooltip y en el **Códice** (pestaña Archivo).
### 5.2 Resonancias
- Cada generador concede una ventaja de combate al tener **10 / 50 / 100** unidades (5/25/50 con el talento Ecos).
  21 en total (`RelicDB.PERKS`). Se aplican como reliquias invisibles en la ascensión. Renacer las apaga hasta reconstruirlas.
### 5.3 Pactos de Brasa
- Se desbloquean al llegar al piso 10. 8 pactos de Calor 1–2 (máximo 11). Cada punto: **+20%** Ascuas en la Torre.
- Ejemplos: Carne de Piedra (+25% PV enemigo), Horno Avaro (−1 Quema en el turno 1), Hambre (los jefes no curan).
### 5.4 Reliquario, Herencia y Crónica
- Cada reliquia encontrada en una ascensión entra en el Reliquario: **+2% producción** por reliquia (+4% con Códice Profundo).
- Herencia (Arsenal) permite elegir en la **Antesala** qué reliquias del Reliquario llevas.
- **26 hitos** con recompensa única (Polvo Estelar o segundos de producción), cubren Torre, Forja y colección.
### 5.5 Economía cruzada en la Torre
- **Urracas**: roban segundos de producción de la Forja; si mueren, devuelven el doble.
- **Grimorio de la Forja**: cartas cuyos números dependen de Braseros, generadores, Polvo Estelar, producción o Reliquario.
- **Dividendo Ígneo**: convierte Energía en segundos de producción.

## 6. Mecánicas nuevas de combate (v0.2)
| Mecánica | Descripción |
|---|---|
| Calor | Cartas quemadas este combate (se muestra en el horno). Escala Danza de la Pira, Piroclasto, Forja Solar, Banquete de Ceniza |
| Brasa / Etérea / Innata | Se queda en la mano / se agota si sigue en la mano / empieza en la mano |
| Mejora temporal | Reforjar, Aleación, Tenazas, Piedra Filosofal: mejoran cartas sólo este combate |
| Recuperar | Fénix de Papel devuelve cartas quemadas a la mano (quemar dos veces = doble Maestría) |
| Quema gratis | Fundir, Tarro de Hollín |
| Ahogo | Algunos enemigos reducen tus Quemas del turno siguiente |
| Ceniza Húmeda | Estado que **no se puede quemar** y se agota al final del turno: rompe la válvula de escape habitual |
| Espinas / Regeneración / Invocación / Explosión al morir | Enemigos con patrones que obligan a cambiar de plan |
| Jefes alternativos | Gran Fuelle (invoca ácaros, ahoga el horno), Hidra de Escoria (espinas y regeneración), Rey Escarcha (invoca, ahoga, Ceniza Húmeda) |
| Reliquias de jefe | Al vencer a un jefe se elige 1 de 3 reliquias de jefe con contrapartida |

## 7. Sinergias diseñadas
- Pira: quemar más (Tiro Abierto, Atizar) + castigar al quemar (Fuego Interior, Armadura de Ceniza, Danza de la Pira).
- Yunque: Fuerza y bloqueo (Postura de Yunque, Ráfaga de Martillo, Redoblar Escudo, Embestida Blindada).
- Ceniza: Quemadura masiva y detonación (Salamandra, Incendio, Detonar).
- Solar: cartas raras de alto coste (Supernova, Estrella Enana, Corona Solar, Eclipse).
- Forja: el mazo crece con la meta-progresión (Llama de Brasero, Cañón de Ascuas, Golpe Estelar, Legado).
- Crisol: manipulación de la mano (Transmutar, Reforjar, Piedra Filosofal, Buscar Combustible).

## 8. Roadmap
- ~~v0.2: guardar run a mitad, más eventos, ascensiones (modificadores de dificultad).~~ Hecho; además Maestría, Resonancias, Reliquario y Crónica.
- v0.3: segundo personaje (el Vidriero: cartas que se rompen), logros, estadísticas.
- v1.0: exportación móvil, música compuesta, localización EN.
