shader_type canvas_item;

uniform vec3 start_color : source_color;
uniform vec3 end_color : source_color;
uniform float leng_tenth : hint_range(3.2, 9.6) = 3.2;
uniform float osc_size : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	//float temp = (1-UV.y);
	float newUVy = UV.y / leng_tenth;
	float decayTop = min(0.5*newUVy, 1.0);
	float decayBot = min(9.7 - newUVy, 1.0);
	float newUVx = UV.x / 12.0;
	float pct = 1.0 - newUVx;
	vec3 gradient = mix(start_color, end_color, newUVx + decayBot*0.25 * sin(osc_size*UV.y));
	COLOR = vec4(gradient, pct*decayTop*decayBot*0.9);
}
