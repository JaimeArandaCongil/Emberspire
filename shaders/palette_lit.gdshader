shader_type canvas_item;
// palette_lit v1 (TEC · v0.4). Dibuja texturas de ÍNDICE (formato: docs/reviews/v04/tecnico/formato_indice.md)
// con la LUT de la paleta maestra y la luz de escena en tiempo real, SIEMPRE en pasos enteros de rampa.
// La luz se evalúa en el ANCLA de cada pieza (centro del ladrillo / del miembro): la pieza entera sube o baja.
// Globales (project.godot [shader_globals], los escribe LightRig): ver la lista de abajo.

global uniform sampler2D palette_lut : filter_nearest, repeat_disable;
global uniform vec4 forge_light;      // x, y (mundo), radio, pasos en el centro (con parpadeo; 0 = luz nominal horneada)
global uniform float forge_heat;      // 0..1 (calor de la Forja; sólo actúa con `hero_heat`: pelo y martillo)
global uniform vec4 burn_pulse;       // x, y, radio actual, fuerza (pasos) — onda de quemar carta
global uniform float low_hp;          // 0..1 — oscurece los bordes de la escena
global uniform vec4 light_0;          // x, y, radio, pasos (negativo = sombra)
global uniform vec4 light_1;
global uniform vec4 light_2;
global uniform vec4 light_3;
global uniform vec4 light_cold;       // 1 = la luz i es fría
global uniform float cold_bias;       // temperatura: 1 = rampas frías (ambiente helado), -1 = la luz cálida pasa a oro (Resplandor)
global uniform int emit_pulse;        // pasos extra de los emisivos (quemar, Resplandor)
global uniform sampler2D light_mask : filter_linear, repeat_disable;   // R: 0.5 = 0 pasos, ±4 pasos
global uniform vec4 light_mask_rect;  // x, y, ancho, alto (mundo) que cubre la máscara
global uniform float light_mask_on;   // 0 = ignorar la máscara
global uniform vec2 world_size;       // 640×360

// 1 = este sprite no recibe luz dinámica (p. ej. interfaz dibujada con índices)
uniform bool unlit = false;
// Sólo el material de la heroína: la cara `hot` del martillo va del paso 1 al 5 con `forge_heat` y las puntas de `fire`
// junto a `head_pos` (mundo) pasan a `hair 2` con poco calor. En los demás, una sola comparación en la rama emisiva.
uniform bool hero_heat = false;
uniform vec2 head_pos = vec2(0.0);
uniform bool tips_follow_heat = true;
// Invocación: las filas de mundo por encima de esta Y no se dibujan (el luchador emerge de abajo arriba).
uniform float reveal_y = -100000.0;
// Destello de impacto por luchador (F2-VIDA, biblia §12): `flash_white` = 1 f de silueta blanca (fuego 7);
// `flash_steps` = subida de pasos de rampa que conserva el dibujo interior. `emit_boost` = pasos extra de sus emisivos
// (Quemadura: las grietas encendidas suben 1 paso).
uniform bool flash_white = false;
uniform int flash_steps = 0;
uniform int emit_boost = 0;
// Jefes (C2, F2-VIDA3): el blanco sólo en la PIEZA golpeada. x, y de mundo y radio: se ponen blancos los píxeles cuyo ANCLA
// (centro de su pieza) cae dentro del radio, así la pieza entera destella sin cortes; el resto del cuerpo sube
// `FLASH_REST_STEPS` pasos y conserva el dibujo. Radio < 0 = todo el cuerpo (criaturas y respaldo).
uniform vec3 flash_piece = vec3(0.0, 0.0, -1.0);
// Resplandor: los luchadores no viran a oro (sólo la sala, la Forja y sus llamas).
uniform bool gold_ok = true;

// Índices de `Palette`; LightRig.ensure_globals comprueba que no cambien.
const int MAT_FIRE = 4;
const int MAT_GOLD = 5;
const int MAT_HAIR = 14;
const int MAT_HOT = 31;
const float TIP_HEAT = 0.35;
const float TIP_RADIUS = 26.0;
// Resplandor (C11): la pieza entera vira a oro si recibe luz cálida de verdad (no los muros alejados).
const float GOLD_FROM = 1.0;
const float GOLD_SPREAD = 1.6;        // umbral por sillar: GOLD_FROM + azar fijo de la pieza × GOLD_SPREAD
const float GOLD_FROM_METAL = 0.35;
const int MAT_FURNACE_BRICK = 3;
const int MAT_COPPER = 8;
const int MAT_BRASS = 9;
const int FLASH_REST_STEPS = 3;

varying vec2 world_pos;
varying float flip_x;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	flip_x = MODEL_MATRIX[0].x < 0.0 ? -1.0 : 1.0;
}

float falloff(vec2 p, vec4 l) {
	return l.z <= 0.0 ? 0.0 : clamp(1.0 - distance(p, l.xy) / l.z, 0.0, 1.0);
}

void fragment() {
	vec4 d = texture(TEXTURE, UV);
	if (d.a < 0.5 / 255.0 || world_pos.y < reveal_y) {
		discard;
	}
	int mat_i = int(round(d.r * 255.0));
	int g = int(round(d.g * 255.0));
	int stp = g & 15;
	bool joint = (g & 16) != 0;
	bool bevel = (g & 32) != 0;
	bool emissive = (g & 64) != 0;
	bool cold = (g & 128) != 0;
	vec2 delta = vec2(round(d.b * 255.0) - 128.0, round(d.a * 255.0) - 128.0);
	vec2 px = floor(world_pos);
	vec2 anchor = px + vec2(delta.x * flip_x, delta.y) + 0.5;

	int s = stp;
	bool to_gold = false;
	if (emissive) {
		s = clamp(stp + emit_pulse + emit_boost, 0, 15);
		// Resplandor: llamas y boca en oro.
		to_gold = gold_ok && cold_bias < -0.5 && mat_i == MAT_FIRE && !hero_heat;
		if (hero_heat) {
			if (mat_i == MAT_HOT) {
				s = clamp(stp - 4 + int(round(forge_heat * 4.0)) + emit_pulse, 1, 15);
			} else if (mat_i == MAT_FIRE && tips_follow_heat && forge_heat <= TIP_HEAT && distance(px, head_pos) < TIP_RADIUS) {
				mat_i = MAT_HAIR;
				s = 2;
			}
		}
	} else if (!unlit && stp > 0) {
		float warm = forge_light.w * falloff(anchor, forge_light);
		float coldl = 0.0;
		vec4 ls[4] = vec4[4](light_0, light_1, light_2, light_3);
		for (int i = 0; i < 4; i++) {
			float v = ls[i].w * falloff(anchor, ls[i]);
			if (light_cold[i] > 0.5) {
				coldl += v;
			} else {
				warm += v;
			}
		}
		if (burn_pulse.w > 0.0) {
			float r = (distance(anchor, burn_pulse.xy) - burn_pulse.z) / 24.0;
			warm += burn_pulse.w * exp(-r * r);
		}
		float total = warm + coldl;
		if (light_mask_on > 0.5) {
			vec2 muv = (anchor - light_mask_rect.xy) / light_mask_rect.zw;
			if (muv.x >= 0.0 && muv.y >= 0.0 && muv.x <= 1.0 && muv.y <= 1.0) {
				total += (texture(light_mask, muv).r - 0.5) * 8.0;
			}
		}
		if (low_hp > 0.0) {
			vec2 c = (anchor / world_size) * 2.0 - 1.0;
			total -= low_hp * 2.0 * smoothstep(0.45, 1.1, length(c));
		}
		int off = int(round(total));
		if (joint && off > 0) {
			off -= 1;
		}
		if (bevel && off >= 1) {
			off += 1;
		}
		s = clamp(stp + off, 1, 15);
		if ((coldl > 0.5 && coldl > warm + 0.5) || cold_bias > 0.5) {
			cold = true;
		}
		if (warm >= 2.0 && cold_bias < 0.5) {
			cold = false;
		}
		// Resplandor (biblia §11, C11): la pieza ENTERA (mismo ancla = mismo sillar) vira a oro cuando la luz cálida
		// que recibe es real; el cobre y el latón, con menos. Las juntas se quedan en su material: el muro no se
		// convierte en una rejilla amarilla.
		// Sillar a sillar: cada pieza tiene su propio umbral fijo (hash del ancla), así el oro se deshace con la distancia
		// a la luz en piezas enteras, sin bordes rectos. El ladrillo refractario del horno conserva su material.
		if (gold_ok && cold_bias < -0.5 && !joint && mat_i != MAT_FURNACE_BRICK) {
			bool metal = mat_i == MAT_COPPER || mat_i == MAT_BRASS;
			float h = fract(sin(dot(floor(anchor), vec2(12.9898, 78.233))) * 43758.5453);
			to_gold = warm >= (metal ? GOLD_FROM_METAL : GOLD_FROM + h * GOLD_SPREAD);
		}
	}
	bool white = flash_white && (flash_piece.z < 0.0 || distance(anchor, flash_piece.xy) <= flash_piece.z);
	int fsteps = flash_steps + (flash_white && !white ? FLASH_REST_STEPS : 0);
	if (stp > 0 && fsteps != 0) {
		s = clamp(s + fsteps, 1, 15);
	}
	int row = mat_i * 2 + (cold ? 1 : 0);
	vec4 col = texelFetch(palette_lut, ivec2(s, row), 0);
	if (to_gold && stp > 0) {
		// Paso de oro de luminancia más parecida (6 pasos): sigue en la paleta y conserva el volumen.
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec4 best = col;
		float bd = 10.0;
		for (int i = 1; i < 6; i++) {
			vec4 gc = texelFetch(palette_lut, ivec2(i, MAT_GOLD * 2), 0);
			float dd = abs(dot(gc.rgb, vec3(0.299, 0.587, 0.114)) - lum);
			if (dd < bd) {
				bd = dd;
				best = gc;
			}
		}
		col = best;
	}
	if (white) {
		col = texelFetch(palette_lut, ivec2(7, MAT_FIRE * 2), 0);
	}
	COLOR = col;
}
