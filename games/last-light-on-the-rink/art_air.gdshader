shader_type canvas_item;
render_mode unshaded;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(41.73, 119.48))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * 1.6, uv.y);
	vec3 ink = vec3(0.079, 0.101, 0.205);
	vec3 plum = vec3(0.35, 0.296, 0.423);
	vec3 rose = vec3(0.79, 0.51, 0.462);
	float horizon_offset = (p.y - 0.31) * 7.2;
	float horizon = exp(-(horizon_offset * horizon_offset));
	float east = smoothstep(0.32, 1.32, p.x);
	vec3 sky = mix(ink, plum, smoothstep(0.0, 0.35, p.y));
	sky = mix(sky, rose, horizon * (0.08 + 0.63 * east));
	float cloud = sin(p.x * 23.0 + cos(p.x * 8.2)) * 0.006 + sin(p.x * 49.0) * 0.0016;
	float wisps = pow(max(0.0, sin(188.0 * (p.y + cloud + 0.013 * cos(p.x * 3.0)))), 8.0);
	sky += vec3(0.12, 0.065, 0.049) * wisps * horizon * east * (0.3 + 0.7 * sin(p.x * 14.0 + 2.0) * sin(p.x * 14.0 + 2.0));
	vec2 moon = p - vec2(1.333, 0.1333);
	float radius = length(moon);
	sky += vec3(0.23, 0.147, 0.102) * exp(-radius * 17.0);
	float disc = 1.0 - smoothstep(0.034, 0.0355, radius);
	float relief = smoothstep(-0.2, 1.0, sin(moon.x * 81.0 - moon.y * 34.0 + sin(moon.y * 149.0)) * cos(moon.y * 87.0));
	sky = mix(sky, vec3(1.0, 0.87, 0.668) - vec3(0.077, 0.104, 0.102) * relief, disc);
	sky += (grain(floor(uv * vec2(1152.0, 720.0))) - 0.5) * 0.038;
	COLOR = vec4(sky, 1.0);
}
