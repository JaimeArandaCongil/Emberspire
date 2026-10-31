# Game Design Document — EMBERSPIRE v0.1

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
  `(2 + 2·coste) · (1 + 0.2·piso) + 3 s de producción` y ejecuta su efecto *Al quemar*. Límite: 1 por turno (ampliable).
- Cartas **Combustible**: no jugables, existen para ser quemadas (Leña, Carbón, Pólvora, Pluma de Fénix…).
- Las cartas de estado enemigas (Hollín) son combustible: el jugador convierte el ataque enemigo en economía.
- Estados: Fuerza, Débil (−25% daño), Vulnerable (+50% daño recibido), Quemadura (pierde PV al inicio de turno y baja 1).

## 3. La Torre
- Cada piso ofrece **3 puertas** (Combate, Élite, Hoguera, Yunque Errante, Misterio, Tesoro). Piso 10k = Jefe. Piso 10k−1 = descanso.
- Actos: Hollín (1–10), Escoria (11–20), Ceniza Helada (21–30). Después la torre **cicla** con enemigos mutados
  (paleta y forma nuevas por semilla) y escalado exponencial → techo infinito.
- Morir o retirarse devuelve a la Forja conservando todas las Ascuas ganadas.

## 4. La Forja (incremental)
- 6 generadores (Chispa → Sol Enano), coste ×1.15 por unidad, ×2 producción a 25/50/100 unidades.
- **Arsenal**: mejoras permanentes de combate (PV, quemas, robo, energía, fuerza inicial, templado del mazo inicial…).
- **Grimorios**: desbloquean arquetipos de cartas en las recompensas (Pira, Yunque, Ceniza, Solar).
- **Producción offline** hasta 8 h (24 h con talento).
- **Renacer en Ceniza** (requiere ≥1 de Polvo): reinicia Ascuas y generadores. Conserva Arsenal, Grimorios, Braseros.
  Polvo = ⌊√(Ascuas de esta vida / 1M) · (1 + récord/20)⌋.

## 5. Sinergias diseñadas
- Pira: quemar más (Tiro Abierto, Atizar) + castigar al quemar (Fuego Interior, Armadura de Ceniza, Danza de la Pira).
- Yunque: Fuerza y bloqueo (Postura de Yunque, Ráfaga de Martillo, Redoblar Escudo, Embestida Blindada).
- Ceniza: Quemadura masiva y detonación (Salamandra, Incendio, Detonar).
- Solar: cartas raras de alto coste (Supernova, Estrella Enana).

## 6. Roadmap
- v0.2: guardar run a mitad, más eventos, ascensiones (modificadores de dificultad).
- v0.3: segundo personaje (el Vidriero: cartas que se rompen), logros, estadísticas.
- v1.0: exportación móvil, música compuesta, localización EN.
