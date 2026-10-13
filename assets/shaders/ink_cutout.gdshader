shader_type canvas_item;
render_mode unshaded;

uniform vec4 ink_color : source_color = vec4(0.16, 0.135, 0.12, 1.0);
uniform float ink_width_texels : hint_range(0.0, 12.0) = 6.0;
uniform float paper_strength : hint_range(0.0, 0.1) = 0.024;
varying vec4 piece_tint;

void vertex() {
	piece_tint = COLOR;
}

void fragment() {
	// COLOR already contains the texture and modulation. Preserve its alpha.
	vec4 source = COLOR;
	float pressure = 0.78 + 0.22 * sin(UV.y * 29.0 + UV.x * 17.0);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * ink_width_texels * pressure;
	float inner_alpha = min(min(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
		min(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a,
		texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a));
	float edge = (1.0 - inner_alpha) * smoothstep(0.1, 0.85, source.a);
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE / 4.0);
	float grain = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 paper = source.rgb * (1.0 - paper_strength * step(0.78, grain));
	COLOR = vec4(mix(paper, ink_color.rgb * piece_tint.rgb, edge * 0.88), source.a);
}
