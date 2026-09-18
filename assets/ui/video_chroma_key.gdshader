shader_type canvas_item;
render_mode unshaded, blend_mix;

// Keys out the near-white / checkerboard plate behind the bible
// while keeping the gold halo (saturated yellow).
uniform float luma_cut : hint_range(0.7, 1.0) = 0.82;
uniform float sat_cut : hint_range(0.0, 0.4) = 0.12;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(col.r, max(col.g, col.b)) - min(col.r, min(col.g, col.b));
	float hide = smoothstep(luma_cut - 0.06, luma_cut + 0.04, luma)
			* (1.0 - smoothstep(sat_cut, sat_cut + 0.08, sat));
	COLOR = vec4(col.rgb, col.a * (1.0 - hide));
}
