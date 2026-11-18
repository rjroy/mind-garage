shader_type canvas_item;
render_mode unshaded;

uniform float show_lights = 0.0;
uniform float curtain = 0.0;
uniform float time = 0.0;
varying vec2 rink_uv;

void vertex() {
	// Untextured Polygon2D does not supply useful UVs in Compatibility.
	rink_uv = VERTEX / vec2(1152.0, 720.0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.12, 317.91))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + 1.0), f.x), f.y);
}

float reflected_pool(vec2 p, float x, float y, float root_width, float tail, float bend) {
	float depth = max(0.0, p.y - y);
	float spread = root_width + depth * 0.17;
	float axis = x + depth * bend;
	float lateral_offset = (p.x - axis) / spread;
	return exp(-(lateral_offset * lateral_offset) - pow(depth / tail, 1.27));
}

void fragment() {
	vec2 p = rink_uv;
	vec2 pixel = floor(p * vec2(1152.0, 720.0));
	float mist = noise(p * vec2(13.0, 21.0)) * 0.56;
	mist += noise(p * vec2(34.0, 54.0)) * 0.25;
	mist += noise(p * vec2(92.0, 112.0)) * 0.14;
	float layers = noise(vec2(p.x * 9.0 + p.y * 3.0, p.y * 83.0)) * 0.22;
	float cross = abs(p.x - 0.5) * 0.94;
	float depth = smoothstep(0.40, 0.91, p.y);
	vec3 ice = mix(vec3(0.21, 0.40, 0.52), vec3(0.39, 0.61, 0.66), depth);
	ice += vec3(0.46, 0.55, 0.52) * (mist + layers - 0.56) * 0.34;
	ice -= cross * cross * vec3(0.23, 0.21, 0.19);

	float ripples = noise(vec2(p.x * 420.0 + p.y * 39.0, p.y * 45.0));
	float a = reflected_pool(p, 0.19, 0.393, 0.012, 0.28, 0.11);
	float b = reflected_pool(p, 0.407, 0.393, 0.011, 0.23, 0.03);
	float c = reflected_pool(p, 0.624, 0.393, 0.011, 0.28, -0.02);
	float d = reflected_pool(p, 0.84, 0.393, 0.012, 0.29, -0.12);
	float reflected = (a + b * 0.6 + c * 0.7 + d) * (0.45 + ripples * 0.55);
	vec3 dusk = vec3(0.123, 0.24, 0.36);
	ice = mix(ice, dusk + (ice - dusk) * 0.56, show_lights * 0.91);
	ice = mix(ice, vec3(0.91, 0.69, 0.45), reflected * mix(0.47, 0.81, show_lights));

	vec2 ellipse = vec2((p.x - 0.488) * 1.2, (p.y - 0.653) * 2.8);
	float house_spot = exp(-dot(ellipse, ellipse) * 18.0);
	vec2 drift = vec2((p.x - 0.55 - cos(time * 0.43) * 0.18) * 1.2, (p.y - 0.61 - sin(time * 0.39) * 0.08) * 2.8);
	float side_spot = exp(-dot(drift, drift) * 29.0);
	ice = mix(ice, vec3(0.79, 0.75, 0.64), (house_spot * (0.35 + curtain * 0.14) + side_spot * 0.11) * show_lights);
	ice = mix(ice, vec3(0.51, 0.37, 0.39), 0.22 * curtain);
	ice += (hash(pixel) - 0.5) * 0.031;
	COLOR = vec4(ice, 1.0);
}
