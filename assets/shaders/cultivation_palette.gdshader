shader_type canvas_item;
render_mode unshaded;

// A shared environmental grade. Alpha, atlas coordinates and geometry remain
// untouched; the original navigation shapes and water frames still read clearly.
void fragment() {
	// Fragment COLOR already includes the default texture and node modulation.
	vec4 source = COLOR;
	float luma = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 muted = mix(vec3(luma), source.rgb, 0.48);
	vec3 grade = muted * vec3(1.10, 1.01, 0.83) + vec3(0.018, 0.012, 0.004);
	float adjacent_alpha = min(min(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a),
		min(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a,
		texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a));
	float edge = (1.0 - adjacent_alpha) * smoothstep(0.2, 0.9, source.a);
	grade = mix(grade, vec3(0.17, 0.16, 0.12), edge * 0.55);
	COLOR = vec4(clamp(grade, vec3(0.0), vec3(1.0)), source.a);
}
