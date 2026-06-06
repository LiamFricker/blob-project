shader_type canvas_item;

uniform vec3 start_color : source_color;
uniform vec3 end_color : source_color;

void fragment() {
	//float temp = (1-UV.y);
	float pct = 2.0 * UV.y;
	vec3 gradient = mix(start_color, end_color, max(2.0*(UV.y)-0.5, 0.0));
	COLOR = vec4(gradient, pct);
}
