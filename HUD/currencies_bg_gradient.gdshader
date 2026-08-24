shader_type canvas_item;

uniform vec4 start_color : source_color;
uniform vec4 end_color : source_color = vec4(0,0,0,0);

void fragment() {
	//float temp = (1-UV.y);
	float pct = UV.x;
	COLOR = mix(start_color, end_color, pct);
}
