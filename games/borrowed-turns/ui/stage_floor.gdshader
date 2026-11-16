shader_type canvas_item;
render_mode unshaded;

uniform vec3 inverse_x;
uniform vec3 inverse_y;
uniform vec3 inverse_w;
uniform vec2 board_size;
uniform vec2 cell_origin;
uniform vec2 cell_span = vec2(1.0);
uniform vec4 source_crop = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 paper_tint : source_color = vec4(1.0);
uniform int quarter_turn = 0;
uniform bool apron = false;
varying vec2 plane_pixel;

void vertex() {
	plane_pixel = VERTEX;
}

void fragment() {
	vec3 pixel = vec3(plane_pixel, 1.0);
	vec2 logical = vec2(dot(inverse_x, pixel), dot(inverse_y, pixel)) / dot(inverse_w, pixel) * board_size;
	vec2 piece = (logical - cell_origin) / cell_span;
	vec2 sample_uv = clamp(piece, vec2(0.0), vec2(1.0));
	if (quarter_turn == 1) { sample_uv = vec2(sample_uv.y, 1.0 - sample_uv.x); }
	if (quarter_turn == 2) { sample_uv = vec2(1.0) - sample_uv; }
	if (quarter_turn == 3) { sample_uv = vec2(1.0 - sample_uv.y, sample_uv.x); }
	vec4 paper = texture(TEXTURE, source_crop.xy + sample_uv * source_crop.zw) * paper_tint;
	if (!apron) {
		float edge = min(min(piece.x, 1.0 - piece.x), min(piece.y, 1.0 - piece.y));
		float margin = 0.012 + 0.004 * sin(piece.y * 19.0 + piece.x * 7.0 + source_crop.x * 23.0);
		float cut = smoothstep(margin, margin + 0.006, edge);
		float rim = 1.0 - smoothstep(margin + 0.006, margin + 0.035, edge);
		paper.rgb = mix(paper.rgb, paper.rgb * 1.12 + vec3(0.025, 0.012, 0.0), rim * 0.35);
		paper.a *= cut;
	}
	COLOR = paper;
}
