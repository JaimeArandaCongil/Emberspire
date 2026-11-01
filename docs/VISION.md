# EMBERSPIRE — *Tu mazo es combustible*

> Documento de visión · Dirección Creativa · v0.2

## La frase
**Un roguelike de cartas donde cada carta que sacrificas alimenta una forja que nunca se apaga.**

## El problema que resolvemos
Los deckbuilders (Slay the Spire) castigan la derrota: pierdes la partida y vuelves a cero.
Los incrementales (Cookie Clicker, Antimatter Dimensions) premian la constancia, pero sus decisiones son pobres.
EMBERSPIRE une ambos con **un único recurso compartido — las Ascuas — y una única acción nueva: QUEMAR**.

## Los tres pilares
1. **Quemar es decidir.** Cualquier carta de tu mano puede jugarse… o arrojarse al horno.
   Quemarla te da Ascuas (economía permanente) y dispara efectos *Al quemar*, pero la pierdes para el combate.
   Cada turno es una tensión entre *poder ahora* y *progreso para siempre*.
2. **Nada se pierde, todo se forja.** Las Ascuas se ingresan en la Forja al instante. Morir no es fracasar: es volver a casa
   con combustible. La Forja produce Ascuas incluso con el juego cerrado.
3. **La Torre y la Forja se alimentan mutuamente.**
   - Subir más alto enciende **Braseros** → multiplican la producción idle.
   - La producción idle compra el **Arsenal** → más vida, energía, robo y quemas en combate.
   - **Renacer en Ceniza** reinicia la Forja a cambio de Polvo Estelar → talentos que rompen las reglas.

## v0.2 — Que cada sistema toque al otro
En v0.1 la Forja era un multiplicador de estadísticas y la Torre una fuente de Ascuas: se tocaban por números,
no por decisiones. v0.2 añade **cuatro puentes** para que cada decisión de un lado cambie cómo juegas el otro:

| De la Torre a la Forja | De la Forja a la Torre |
|---|---|
| **Braseros**: +10% producción por piso récord | **Resonancias**: 10/50/100 de cada generador = ventaja de combate |
| **Reliquario**: +2% producción por reliquia encontrada | **Arsenal** y **Herencia** (reliquias del Reliquario) |
| **Polvo Estelar** de jefes, hitos y misterios | **Grimorio de la Forja**: cartas que escalan con Braseros, generadores, Polvo y producción |
| Ascuas de quemar, matar y oleadas de victoria | **Pactos de Brasa**: el Calor multiplica lo que la Torre paga |
| **QUEMAR → Maestría** de la carta, para siempre | La Maestría vuelve como +10% números y +20% Ascuas por nivel |
| Las **Urracas** roban de la Forja… | …y devuelven el doble si las matas a tiempo |

1. **Maestría — quemar es invertir en la carta.** Cada carta quemada gana Maestría para siempre. La pregunta
   «¿la juego o la quemo?» gana una tercera dimensión: quemar un Golpe hoy lo hace más fuerte en todas las
   ascensiones futuras. El mazo inicial deja de ser relleno: es la colección que vas templando.
2. **Resonancias — el idle cambia cómo juegas.** Comprar generadores ya no es sólo «más Ascuas/s»: el Fuelle a 10
   te da Bloqueo inicial, el Crisol a 10 una cuarta opción de carta, el Corazón del Mundo a 50 una Energía extra.
   Renacer ahora tiene coste táctico (pierdes las Resonancias hasta reconstruirlas).
3. **Pactos de Brasa — el jugador elige su riesgo.** Tras el primer jefe se desbloquea la dificultad opcional que
   multiplica la economía de la Torre. Ascensión de StS reinterpretada como palanca incremental.
4. **Reliquario y Crónica — coleccionar es progresar.** Cada reliquia encontrada suma producción para siempre y
   puede heredarse; 26 hitos con recompensa marcan el camino de las primeras 8 horas.

## Fantasía del jugador
Eres **la Fogonera**, última herrera de una ciudad helada. En lo alto de la Torre de Brasa late el último fuego del mundo.
Cada ascenso es una expedición; cada regreso, una forja más caliente.

## Bucle principal (30 s · 10 min · 10 h)
| Escala | Qué haces | Qué sientes |
|---|---|---|
| 30 s | Juegas o quemas cartas, lees intenciones enemigas | Tensión táctica |
| 10 min | Una ascensión: elegir puertas, construir mazo, jefe cada 10 pisos | Progreso de run |
| 10 h | Generadores, Arsenal, Grimorios, Renacer | Números que crecen, poder permanente |

## Lo que NO es (no-objetivos)
- No es un clon: no hay mapa ramificado de StS, hay **puertas** por piso con información parcial.
- No hay monetización, ni gacha, ni energía de espera.
- No hay narrativa extensa: el mundo se cuenta con nombres, arte y una línea por evento.

## Por qué tiene potencial
- **Torre infinita** con ciclos de dificultad → el incremental da techo infinito al roguelike.
- **Enemigos procedurales con semilla** → cada ciclo genera mutaciones visuales nuevas sin coste de arte.
- Arquetipos claros (Pira, Yunque, Ceniza, Solar) desbloqueables → rejugabilidad y objetivos de compra.
- Escalable a móvil (sesiones cortas + idle) y a Steam (profundidad de deckbuilder).
