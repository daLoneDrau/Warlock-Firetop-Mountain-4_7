shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 fill_color : source_color = vec4(0.078, 0.051, 0.016, 1.0);
uniform vec4 line_color : source_color = vec4(1.0, 0.702, 0.278, 1.0);
uniform float line_width : hint_range(0.5, 4.0) = 1.5;

varying vec3 barycentric;
varying vec3 edge_mask;

void vertex() {
	barycentric = COLOR.rgb;
	edge_mask = vec3(UV.x, UV.y, UV2.x);
}

void fragment() {
	vec3 d = fwidth(barycentric);
	vec3 a3 = smoothstep(vec3(0.0), d * line_width, barycentric);
	vec3 a3_masked = mix(vec3(1.0), a3, edge_mask);
	float edge_factor = min(min(a3_masked.x, a3_masked.y), a3_masked.z);
	ALBEDO = mix(line_color.rgb, fill_color.rgb, edge_factor);
}