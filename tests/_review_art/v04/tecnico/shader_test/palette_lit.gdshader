shader_type canvas_item;
// Shader de paleta (prueba v0.4, artista técnico).
// TEXTURE = mapa de ÍNDICE horneado, no color:
//   R = material*16 + paso de rampa (paso con la luz ya horneada por pieza)
//   G = "mira a la Forja" 0..1 (de la normal horneada: cuánto le afecta la luz de escena)
//   B = 1 → píxel fijo (contorno, línea, emisivo): no recibe la máscara de luz
//   A = cobertura
// La máscara de luz es de BAJA resolución (80×45 sobre 640×360) y la anima la CPU.
// Resultado: color = LUT[material][paso + desplazamiento ENTERO]. Nunca sale de la paleta.

uniform sampler2D lut : filter_nearest;
uniform sampler2D light_mask : filter_linear;
uniform int emissive_row = 5;
uniform int emit_boost = 0;
uniform bool use_mask = true;
// Luz por PIEZA (regla del DA: tono plano por ladrillo): la máscara se muestrea en el ancla de la pieza.
uniform bool use_anchor = false;
uniform sampler2D anchor_tex : filter_nearest;

void fragment() {
	vec4 d = texture(TEXTURE, UV);
	if (d.a < 0.5) {
		discard;
	}
	int code = int(round(d.r * 255.0));
	int row = code / 16;
	int stp = code - row * 16;
	bool fixed_px = d.b > 0.5;
	int s = stp;
	if (row == emissive_row) {
		s = clamp(stp + emit_boost, 0, 15);
	} else if (use_mask && !fixed_px && stp > 0) {
		vec2 muv = use_anchor ? texture(anchor_tex, UV).rg : SCREEN_UV;
		float L = texture(light_mask, muv).r * 6.0 - 2.0;   // -2..+4 pasos
		int off = int(floor(L * mix(0.35, 1.0, d.g) + 0.5));
		s = clamp(stp + off, 1, 15);
	}
	COLOR = texelFetch(lut, ivec2(s, row), 0);
}
