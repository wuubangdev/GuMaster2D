shader_type canvas_item;
render_mode unshaded;
uniform vec4 outfit_pigment : source_color = vec4(0.0);
uniform sampler2D original_color : source_color, filter_nearest, repeat_disable;
uniform sampler2D directions_color : source_color, filter_nearest, repeat_disable;
uniform sampler2D original_matte : filter_nearest, repeat_disable;
uniform sampler2D directions_matte : filter_nearest, repeat_disable;
uniform sampler2D original_layers : filter_nearest, repeat_disable;
uniform sampler2D directions_layers : filter_nearest, repeat_disable;
uniform sampler2D directional_atlas : source_color, filter_linear, repeat_disable;
uniform sampler2D cloth_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 eye_left = vec4(0.0);
uniform vec4 eye_right = vec4(0.0);
uniform float blink : hint_range(0.0, 1.0) = 0.0;
varying vec4 piece_tint;

void vertex() {
	piece_tint = COLOR;
}

vec4 pigment_tap(sampler2D atlas, sampler2D owners, sampler2D matte, ivec2 at, float part) {
	ivec2 coord = clamp(at, ivec2(0), textureSize(atlas, 0) - ivec2(1));
	float owner = texelFetch(owners, coord, 0).r * 255.0 / 32.0;
	float alpha = (1.0 - step(0.25, abs(owner - part))) * texelFetch(matte, coord, 0).r;
	// Discard paper and adjacent parts BEFORE filtering colors. Otherwise
	// their light RGB bleeds into the edge even when alpha is later removed.
	return vec4(texelFetch(atlas, coord, 0).rgb * alpha, alpha);
}

vec4 bilinear_pigment(sampler2D atlas, sampler2D owners, sampler2D matte, vec2 uv, float part) {
	vec2 pixel = uv * vec2(textureSize(atlas, 0)) - vec2(0.5);
	ivec2 base = ivec2(floor(pixel));
	vec2 fraction = fract(pixel);
	vec4 top = mix(pigment_tap(atlas, owners, matte, base, part), pigment_tap(atlas, owners, matte, base + ivec2(1, 0), part), fraction.x);
	vec4 bottom = mix(pigment_tap(atlas, owners, matte, base + ivec2(0, 1), part), pigment_tap(atlas, owners, matte, base + ivec2(1, 1), part), fraction.x);
	return mix(top, bottom, fraction.y);
}

vec4 filtered_pigment(sampler2D atlas, sampler2D owners, sampler2D matte, vec2 uv, float part) {
	vec4 pigment = bilinear_pigment(atlas, owners, matte, uv, part);
	// The atlas has much finer sketch marks than a world-sized sleeve. A
	// single bilinear tap aliases those marks into moving speckles. Average
	// the actual screen footprint, still rejecting other owners and paper
	// before filtering. Native-size details and opaque vector ink stay sharp.
	vec2 dimensions = vec2(textureSize(atlas, 0));
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	float footprint = max(length(dx * dimensions), length(dy * dimensions));
	if (part > 1.5 && footprint > 1.25) {
		vec2 a = dx * 0.28;
		vec2 b = dy * 0.28;
		vec4 average = (bilinear_pigment(atlas, owners, matte, uv-a-b, part)
			+ bilinear_pigment(atlas, owners, matte, uv+a-b, part)
			+ bilinear_pigment(atlas, owners, matte, uv-a+b, part)
			+ bilinear_pigment(atlas, owners, matte, uv+a+b, part)) * 0.25;
		pigment = mix(pigment, average, smoothstep(1.25, 2.2, footprint));
	}
	return vec4(pigment.rgb / max(pigment.a, 0.00001), pigment.a);
}

vec3 closed_eye(vec3 pigment, vec4 region, vec2 source_uv, vec3 skin) {
	if (region.z < 0.000001 || region.w < 0.000001 || blink < 0.001) {
		return pigment;
	}
	vec2 local = (source_uv - region.xy) / region.zw;
	float coverage = 1.0 - smoothstep(0.83, 1.04, dot(local, local));
	float line = (1.0 - smoothstep(0.045, 0.13, abs(local.y - (0.12 - 0.14 * local.x * local.x))))
		* (1.0 - smoothstep(0.7, 0.98, abs(local.x)));
	vec3 eyelid = mix(skin, vec3(0.18, 0.15, 0.12) * piece_tint.rgb, line);
	return mix(pigment, eyelid, coverage * smoothstep(0.45, 0.9, blink));
}

void fragment() {
	vec4 source = COLOR;
	float source_width = 1.0 / TEXTURE_PIXEL_SIZE.x;
	// Carry the layer in the UV page, independent of opacity/modulate.
	// Alpha may change during UI fades, damage, death and dash afterimages.
	float part = floor(UV.x / 2.0);
	vec2 source_uv = vec2(UV.x - part * 2.0, UV.y);
	bool from_original = abs(source_width - 1586.0) < 0.5;
	bool from_directions = abs(source_width - 1774.0) < 0.5;
	if (part >= 9.0) source = texture(directional_atlas, source_uv) * piece_tint;
	else if (part >= 8.0) source = texture(cloth_atlas, source_uv) * piece_tint;
	else if (from_original) source = filtered_pigment(original_color, original_layers, original_matte, source_uv, part) * piece_tint;
	else if (from_directions) source = filtered_pigment(directions_color, directions_layers, directions_matte, source_uv, part) * piece_tint;
	else source = texture(TEXTURE, UV) * piece_tint;
	if ((from_original || from_directions) && abs(part - 1.0) < 0.25) {
		vec3 left_skin = texture(TEXTURE, eye_left.xy + vec2(eye_left.z * 0.3, eye_left.w * 1.36)).rgb * piece_tint.rgb;
		vec3 right_skin = texture(TEXTURE, eye_right.xy + vec2(eye_right.z * 0.3, eye_right.w * 1.36)).rgb * piece_tint.rgb;
		source.rgb = closed_eye(closed_eye(source.rgb, eye_left, source_uv, left_skin), eye_right, source_uv, right_skin);
	}
	// Source art is untouched for jade. Optional dyes retain its ink and wash,
	// and leave skin, ivory lapels, hair and the gold fittings alone.
	float green = smoothstep(-0.006, 0.04, source.g - source.r)
		* smoothstep(0.025, 0.09, source.g - source.b)
		* smoothstep(0.16, 0.3, max(source.r, max(source.g, source.b)));
	float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float dye_value = dot(outfit_pigment.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dyed = outfit_pigment.rgb * value / max(0.01, dye_value);
	COLOR = vec4(mix(source.rgb, dyed, green * outfit_pigment.a), source.a);
}
