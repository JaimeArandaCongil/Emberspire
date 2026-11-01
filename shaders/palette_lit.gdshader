shader_type canvas_item;
// palette_lit v1 (TEC · v0.4). Dibuja texturas de ÍNDICE (formato: docs/reviews/v04/tecnico/formato_indice.md)
// con la LUT de la paleta maestra y la luz de escena en tiempo real, SIEMPRE en pasos enteros de rampa.
// La luz se evalúa en el ANCLA de cada pieza (centro del ladrillo / del miembro): la pieza entera sube o baja.
// Globales (project.godot [shader_globals], los escribe LightRig): ver la lista de abajo.

global uniform sampler2D palette_lut : filter_nearest, repeat_disable;
global uniform vec4 forge_light;      // x, y (mundo), radio, pasos en el centro (con parpadeo; 0 = luz nominal horneada)
global uniform float forge_heat;      // 0..1 (calor de la Forja; lo leen otros shaders: pelo, martillo)
global uniform vec4 burn_pulse;       // x, y, radio actual, fuerza (pasos) — onda de quemar carta
global uniform float low_hp;          // 0..1 — oscurece los bordes de la escena
global uniform vec4 light_0;          // x, y, radio, pasos (negativo = sombra)
global uniform vec4 light_1;
global uniform vec4 light_2;
global uniform vec4 light_3;
global uniform vec4 light_cold;       // 1 = la luz i es fría
global uniform float cold_bias;       // 1 = toda la escena en rampas frías (ambiente helado)
global uniform int emit_pulse;        // pasos extra de los emisivos (quemar, Resplandor)
global uniform sampler2D light_mask : filter_linear, repeat_disable;   // R: 0.5 = 0 pasos, ±4 pasos
global uniform vec4 light_mask_rect;  // x, y, ancho, alto (mundo) que cubre la máscara
global uniform float light_mask_on;   // 0 = ignorar la máscara
global uniform vec2 world_size;       // 640×360

// 1 = este sprite no recibe luz dinámica (p. ej. interfaz dibujada con índices)
uniform bool unlit = false;

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
	if (d.a < 0.5 / 255.0) {
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
	if (emissive) {
		s = clamp(stp + emit_pulse, 0, 15);
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
	}
	int row = mat_i * 2 + (cold ? 1 : 0);
	COLOR = texelFetch(palette_lut, ivec2(s, row), 0);
}
